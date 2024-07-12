CREATE OR REPLACE PACKAGE BODY CHAIN.dedupe_admin_pkg
IS

PROCEDURE GetImportSources(
	out_cur		 OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT s.import_source_id, s.name, s.position, s.dedupe_no_match_action_id no_match_action_id, s.lookup_key,
			   s.is_owned_by_system, s.override_company_active, dsl.dedupe_staging_link_id system_staging_link_id
		  FROM import_source s
		  LEFT JOIN dedupe_staging_link dsl ON s.import_source_id = dsl.import_source_id AND s.is_owned_by_system = 1
		 WHERE s.app_sid = security_pkg.getapp
		 ORDER BY s.position;
END;

PROCEDURE SyncImportSourcesPositions
AS
	v_sorted_sources_ids 		security_pkg.T_SID_IDS;
BEGIN
	--sync import sources positions to be 0 based
	SELECT import_source_id
	  BULK COLLECT INTO  v_sorted_sources_ids
	  FROM import_source
	 WHERE app_sid = security_pkg.getapp
	 ORDER BY position;
	 
	SetImportSourcesPositions(v_sorted_sources_ids);
END;

PROCEDURE SaveImportSource(
	in_import_source_id				IN import_source.import_source_id%TYPE,
	in_name							IN import_source.name%TYPE,
	in_position						IN import_source.position%TYPE,
	in_no_match_action_id			IN import_source.dedupe_no_match_action_id%TYPE,
	in_lookup_key					IN import_source.lookup_key%TYPE,
	in_override_company_active		IN import_source.override_company_active%TYPE DEFAULT 0,
	out_import_source_id			OUT import_source.import_source_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SaveImportSource can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;

	IF NVL(in_import_source_id, 0) < 1 THEN
		INSERT INTO import_source(import_source_id, name, position, dedupe_no_match_action_id, lookup_key, override_company_active)
			 VALUES (import_source_id_seq.nextval, in_name, in_position, in_no_match_action_id, in_lookup_key, in_override_company_active)
		  RETURNING import_source_id INTO out_import_source_id;

		INSERT INTO chain.import_source_lock (import_source_id)
			VALUES(out_import_source_id);
	ELSE 
		IF dedupe_helper_pkg.IsOwnedBySystem(in_import_source_id) THEN
			RAISE_APPLICATION_ERROR(-20001, 'Import source with id:'||in_import_source_id||' is owned by the system and cannot be edited.');
		END IF;
		
		UPDATE import_source
		   SET name = in_name, 
			   position = in_position,
			   dedupe_no_match_action_id = in_no_match_action_id,
			   lookup_key = in_lookup_key,
			   override_company_active = in_override_company_active
		 WHERE import_source_id = in_import_source_id;
		
		out_import_source_id := in_import_source_id;
	END IF;
	
	SyncImportSourcesPositions;
END;

PROCEDURE DeleteImportSource(
	in_import_source_id		IN import_source.import_source_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DeleteImportSource can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;
	
	IF dedupe_helper_pkg.IsOwnedBySystem(in_import_source_id) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Import source with id:'||in_import_source_id||' is owned by the system and cannot be deleted.');
	END IF;

	DELETE FROM import_source_lock
	 WHERE import_source_id = in_import_source_id;

	DELETE FROM import_source
	 WHERE import_source_id = in_import_source_id;

	SyncImportSourcesPositions;
END;

PROCEDURE GetMappings(
	in_dedupe_staging_link_id		IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	out_mapping_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_mapping_cur FOR 
		SELECT dedupe_mapping_id, tab_sid, col_sid, dedupe_field_id, reference_id, dedupe_staging_link_id, tag_group_id, destination_tab_sid,
			destination_col_sid, role_sid, is_owned_by_system, allow_create_alt_company_name, fill_nulls_under_ui_source
		  FROM dedupe_mapping
		 WHERE app_sid = security_pkg.getapp
		   AND dedupe_staging_link_id = in_dedupe_staging_link_id
		 ORDER BY dedupe_mapping_id;
		 
END;

PROCEDURE GetRuleSets(
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	out_rule_sets_cur 			OUT SYS_REFCURSOR,
	out_rules_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_rule_sets_cur FOR 
		SELECT dedupe_rule_set_id, dedupe_staging_link_id, position, dedupe_match_type_id, description
		  FROM dedupe_rule_set
		 WHERE app_sid = security_pkg.getapp
		   AND dedupe_staging_link_id = in_dedupe_staging_link_id
		 ORDER BY position;
		 
	OPEN out_rules_cur FOR 
		SELECT dedupe_rule_id, dedupe_rule_set_id, dedupe_mapping_id, position,  match_threshold, dedupe_rule_type_id
		  FROM dedupe_rule
		 WHERE app_sid = security_pkg.getapp
		   AND dedupe_rule_set_id IN ( 
			SELECT dedupe_rule_set_id
			  FROM dedupe_rule_set
			 WHERE app_sid = security_pkg.getapp
			   AND dedupe_staging_link_id = in_dedupe_staging_link_id
		   )
		 ORDER BY dedupe_rule_set_id, position;
END;

PROCEDURE SyncRuleSetsPositions(
	in_dedupe_staging_link_id		IN dedupe_rule_set.dedupe_staging_link_id%TYPE
)
AS
	v_sorted_rule_set_ids 		security_pkg.T_SID_IDS;
BEGIN
	--sync rules positions to be 1 based
	SELECT dedupe_rule_set_id
	  BULK COLLECT INTO v_sorted_rule_set_ids
	  FROM dedupe_rule_set
	 WHERE dedupe_staging_link_id = in_dedupe_staging_link_id
	 ORDER BY position;
	 
	SetRuleSetsPositions(v_sorted_rule_set_ids);
END;

-- in_mapping_ids, in_rule_type_ids, in_match_thresholds are expected to be in sync
PROCEDURE SaveRuleSet(
	in_dedupe_rule_set_id			IN dedupe_rule_set.dedupe_rule_set_id%TYPE,
	in_description					IN dedupe_rule_set.description%TYPE,
	in_dedupe_staging_link_id		IN dedupe_rule_set.dedupe_staging_link_id%TYPE,
	in_dedupe_match_type_id			IN dedupe_rule_set.dedupe_match_type_id%TYPE,
	in_rule_set_position			IN dedupe_rule_set.position%TYPE,
	in_rule_ids						IN security_pkg.T_SID_IDS, 
	in_mapping_ids					IN security_pkg.T_SID_IDS, 
	in_rule_type_ids				IN security_pkg.T_SID_IDS,
	in_match_thresholds				IN helper_pkg.T_NUMBER_ARRAY,
	out_dedupe_rule_set_id			OUT dedupe_rule_set.dedupe_rule_set_id%TYPE
)
AS
	v_rule_ids_t					security.T_SID_TABLE DEFAULT security.security_pkg.SidArrayToTable(in_rule_ids);
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SaveRuleMappings can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;
	
	IF NOT ((in_rule_ids.count = in_mapping_ids.count) AND (in_mapping_ids.count = in_rule_type_ids.count) AND (in_mapping_ids.count = in_match_thresholds.count)) THEN
		RAISE_APPLICATION_ERROR(-20001, 'SaveRuleMappings expects array parameters to be the same length');
	END IF;
	
	IF NVL(in_dedupe_rule_set_id, 0) < 1 THEN --new rule
	INSERT INTO dedupe_rule_set(dedupe_rule_set_id, description, dedupe_staging_link_id, dedupe_match_type_id, position)
			 VALUES (dedupe_rule_set_id_seq.nextval, in_description, in_dedupe_staging_link_id, in_dedupe_match_type_id, in_rule_set_position)
		  RETURNING dedupe_rule_set_id INTO out_dedupe_rule_set_id;
	ELSE
		UPDATE dedupe_rule_set
		   SET description = in_description,
			   position = in_rule_set_position,
			   dedupe_match_type_id = in_dedupe_match_type_id
		 WHERE dedupe_rule_set_id = in_dedupe_rule_set_id;
		
		out_dedupe_rule_set_id := in_dedupe_rule_set_id;
		
		DELETE FROM dedupe_rule
		 WHERE dedupe_rule_set_id = in_dedupe_rule_set_id
		   AND dedupe_rule_id NOT IN (
			    SELECT column_value
				  FROM TABLE(v_rule_ids_t)
		   );
	END IF;
	
	-- crap hack for ODP.NET
	IF in_rule_ids.count > 0 AND in_rule_ids(1) IS NOT NULL THEN
		FOR i IN in_rule_ids.FIRST .. in_rule_ids.LAST LOOP	
			BEGIN
				INSERT INTO dedupe_rule(dedupe_rule_id, dedupe_rule_set_id, dedupe_mapping_id, dedupe_rule_type_id, match_threshold, position)
					VALUES(DECODE(in_rule_ids(i), 0, dedupe_rule_id_seq.nextval, in_rule_ids(i)), out_dedupe_rule_set_id, in_mapping_ids(i), in_rule_type_ids(i), in_match_thresholds(i), i);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					
					-- can't change rule set ID
					UPDATE dedupe_rule
					   SET dedupe_mapping_id = in_mapping_ids(i),
						   dedupe_rule_type_id = in_rule_type_ids(i),
						   match_threshold = in_match_thresholds(i),
						   position = i
					 WHERE dedupe_rule_id = in_rule_ids(i)
					   AND dedupe_rule_set_id = in_dedupe_rule_set_id;
			END;
		END LOOP;
	END IF;

	SyncRuleSetsPositions(in_dedupe_staging_link_id);
END;

/* used for unit tests */
PROCEDURE TestSaveRuleSetForExactMatches(
	in_dedupe_rule_set_id			IN dedupe_rule_set.dedupe_rule_set_id%TYPE,
	in_description					IN dedupe_rule_set.description%TYPE,
	in_dedupe_staging_link_id		IN dedupe_rule_set.dedupe_staging_link_id%TYPE,
	in_rule_set_position			IN dedupe_rule_set.position%TYPE,
	in_rule_ids						IN security_pkg.T_SID_IDS, 
	in_mapping_ids					IN security_pkg.T_SID_IDS, 
	out_dedupe_rule_set_id			OUT dedupe_rule_set.dedupe_rule_set_id%TYPE
)
AS
	v_rule_type_ids		security_pkg.T_SID_IDS;
	v_match_thresholds	helper_pkg.T_NUMBER_ARRAY;
BEGIN
	FOR i IN in_rule_ids.FIRST .. in_rule_ids.LAST LOOP
		v_rule_type_ids(i) := chain_pkg.RULE_TYPE_EXACT;
		v_match_thresholds(i) := 100;
	END LOOP;
	
	SaveRuleSet(
		in_dedupe_rule_set_id		=> in_dedupe_rule_set_id,
		in_description				=> in_description,
		in_dedupe_staging_link_id	=> in_dedupe_staging_link_id,
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_AUTO,
		in_rule_set_position		=> in_rule_set_position,
		in_rule_ids					=> in_rule_ids,
		in_mapping_ids				=> in_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> out_dedupe_rule_set_id
	);
END;

PROCEDURE SetRuleSetsPositions(
	in_dedupe_rule_set_ids		IN	security_pkg.T_SID_IDS
)
AS	
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetRuleSetsPositions can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;
	
	FOR i IN 1 .. in_dedupe_rule_set_ids.COUNT LOOP
		UPDATE dedupe_rule_set
		   SET position = i
		 WHERE app_sid = security_pkg.getapp
		   AND dedupe_rule_set_id = in_dedupe_rule_set_ids(i);
	END LOOP;
END;

PROCEDURE SetRulesPositions(
	in_dedupe_rule_ids		IN	security_pkg.T_SID_IDS
)
AS	
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetRulesPositions can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;
	
	FOR i IN 1 .. in_dedupe_rule_ids.COUNT LOOP
		UPDATE dedupe_rule
		   SET position = i
		 WHERE app_sid = security_pkg.getapp
		   AND dedupe_rule_id = in_dedupe_rule_ids(i);
	END LOOP;
END;

PROCEDURE SetImportSourcesPositions(
	in_import_source_ids		IN	security_pkg.T_SID_IDS
)
AS	
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetImportSourcesPositions can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;
	
	--zero based
	FOR i IN 1 .. in_import_source_ids.COUNT LOOP
		UPDATE import_source
		   SET position = i - 1
		 WHERE app_sid = security_pkg.getapp
		   AND import_source_id = in_import_source_ids(i);
	END LOOP;
END;

PROCEDURE SyncStagingLinksPositions
AS
	v_sorted_links_ids 		security_pkg.T_SID_IDS;
BEGIN
	--sync rules positions to be 1 based
	SELECT dedupe_staging_link_id
	  BULK COLLECT INTO  v_sorted_links_ids
	  FROM dedupe_staging_link
	 WHERE app_sid = security_pkg.getapp
	 ORDER BY position;
	
	SetStagingLinksPositions(v_sorted_links_ids);
END;

PROCEDURE SetStagingLinksPositions(
	in_staging_link_ids		IN	security_pkg.T_SID_IDS
)
AS	
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetStagingLinksPositions can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;
	
	FOR i IN 1 .. in_staging_link_ids.COUNT LOOP
		UPDATE dedupe_staging_link
		   SET position = i
		 WHERE app_sid = security_pkg.getapp
		   AND dedupe_staging_link_id = in_staging_link_ids(i);
	END LOOP;
END;

PROCEDURE DeleteRuleSet(
	in_dedupe_rule_set_id		IN dedupe_rule_set.dedupe_rule_set_id%TYPE
)
AS
	v_dedupe_staging_link_id	dedupe_rule_set.dedupe_staging_link_id%TYPE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DeleteRuleSet can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;
		 
	SELECT dedupe_staging_link_id
	  INTO v_dedupe_staging_link_id
	  FROM dedupe_rule_set
	 WHERE dedupe_rule_set_id = in_dedupe_rule_set_id;
	 
	DELETE FROM dedupe_rule
	 WHERE dedupe_rule_set_id = in_dedupe_rule_set_id;
	 
	DELETE FROM dedupe_rule_set
	 WHERE dedupe_rule_set_id = in_dedupe_rule_set_id;

	SyncRuleSetsPositions(v_dedupe_staging_link_id);
END;

PROCEDURE GetDedupeRuleTypes(
	out_cur	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT dedupe_rule_type_id, threshold_default, description 
		  FROM dedupe_rule_type
		 ORDER BY dedupe_rule_type_id;
END;

PROCEDURE GetDedupeMatchTypes(
	out_cur	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT dedupe_match_type_id, label 
		  FROM dedupe_match_type;
END;

PROCEDURE GetFields(
	out_cur	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR 
		SELECT dedupe_field_id, entity, field, description
		  FROM dedupe_field
		 ORDER BY entity, description;
END;

PROCEDURE GetPreProcFields(
	out_cur	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR 
		SELECT dedupe_field_id, entity, field, description
		  FROM dedupe_field
		 WHERE dedupe_field_id IN (
			chain_pkg.FLD_COMPANY_NAME,			
			chain_pkg.FLD_COMPANY_ADDRESS,		
			chain_pkg.FLD_COMPANY_CITY,			
			chain_pkg.FLD_COMPANY_STATE,			
			chain_pkg.FLD_COMPANY_POSTCODE,		
			chain_pkg.FLD_COMPANY_WEBSITE,		
			chain_pkg.FLD_COMPANY_PHONE,			
			chain_pkg.FLD_COMPANY_EMAIL	
		 )
		 ORDER BY entity, description;
END;

PROCEDURE SaveMapping(
	in_dedupe_mapping_id			IN dedupe_mapping.dedupe_mapping_id%TYPE,
	in_dedupe_staging_link_id 		IN dedupe_mapping.dedupe_staging_link_id%TYPE,
	in_tab_sid 						IN dedupe_mapping.tab_sid%TYPE,
	in_col_sid 						IN dedupe_mapping.col_sid%TYPE,
	in_dedupe_field_id 				IN dedupe_mapping.dedupe_field_id%TYPE DEFAULT NULL,
	in_reference_id		 			IN dedupe_mapping.reference_id%TYPE DEFAULT NULL,
	in_tag_group_id		 			IN dedupe_mapping.tag_group_id%TYPE DEFAULT NULL,
	in_role_sid			 			IN security_pkg.T_SID_ID DEFAULT NULL,
	in_destination_tab_sid			IN dedupe_mapping.destination_tab_sid%TYPE DEFAULT NULL,
	in_destination_col_sid			IN dedupe_mapping.destination_col_sid%TYPE DEFAULT NULL,
	in_allow_create_alt_comp_name	IN dedupe_mapping.allow_create_alt_company_name%TYPE DEFAULT NULL,
	in_fill_nulls_under_ui_source	IN dedupe_mapping.fill_nulls_under_ui_source%TYPE DEFAULT 0,
	out_dedupe_mapping_id			OUT dedupe_mapping.dedupe_mapping_id%TYPE
)
AS
	v_is_owned_by_system	dedupe_mapping.is_owned_by_system%TYPE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SaveMapping can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;

	--inherit from the staging
	SELECT is_owned_by_system
	  INTO v_is_owned_by_system
	  FROM dedupe_staging_link
	 WHERE app_sid = security_pkg.getApp
	   AND dedupe_staging_link_id = in_dedupe_staging_link_id;
	
	IF NVL(in_dedupe_mapping_id, 0) < 1 THEN
		INSERT INTO dedupe_mapping(dedupe_mapping_id, dedupe_staging_link_id, tab_sid, col_sid, dedupe_field_id, reference_id, tag_group_id, role_sid,
			destination_tab_sid, destination_col_sid, is_owned_by_system, allow_create_alt_company_name, fill_nulls_under_ui_source)
			VALUES(dedupe_mapping_id_seq.nextval, in_dedupe_staging_link_id, in_tab_sid, in_col_sid, in_dedupe_field_id, in_reference_id, in_tag_group_id, in_role_sid,
			in_destination_tab_sid, in_destination_col_sid, v_is_owned_by_system, in_allow_create_alt_comp_name, in_fill_nulls_under_ui_source)
		RETURNING dedupe_mapping_id INTO out_dedupe_mapping_id;
	ELSE 
		UPDATE dedupe_mapping
		   SET tab_sid = in_tab_sid,
			col_sid = in_col_sid, 
			dedupe_field_id = in_dedupe_field_id,
			reference_id = in_reference_id,
			tag_group_id = in_tag_group_id,
			destination_tab_sid = in_destination_tab_sid,
			destination_col_sid = in_destination_col_sid,
			role_sid = in_role_sid,
			allow_create_alt_company_name = in_allow_create_alt_comp_name,
			fill_nulls_under_ui_source = in_fill_nulls_under_ui_source,
			is_owned_by_system = v_is_owned_by_system
		 WHERE dedupe_mapping_id = in_dedupe_mapping_id;
		
		out_dedupe_mapping_id := in_dedupe_mapping_id;
	END IF;
END;

PROCEDURE DeleteMapping(
	in_dedupe_mapping_id		IN dedupe_mapping.dedupe_mapping_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DeleteMapping can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;
	
	DELETE FROM dedupe_mapping
	 WHERE dedupe_mapping_id = in_dedupe_mapping_id;
END;

PROCEDURE GetStagingLink(
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	out_staging_link_cur 		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_staging_link_cur FOR
		SELECT dedupe_staging_link_id, dsl.import_source_id, dsl.description, dsl.position, staging_tab_sid,
			   staging_id_col_sid, staging_batch_num_col_sid, parent_staging_link_id, destination_tab_sid,
			   staging_source_lookup_col_sid, s.lookup_key import_source_lookup, dsl.is_owned_by_system
		  FROM dedupe_staging_link dsl
		  JOIN import_source s ON dsl.import_source_id = s.import_source_id
		 WHERE dsl.app_sid = security_pkg.getapp
		   AND dedupe_staging_link_id = in_dedupe_staging_link_id;
END;

PROCEDURE GetStagingLinks(
	in_import_source_id		IN import_source.import_source_id%TYPE,
	out_staging_link_cur 	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_staging_link_cur FOR
		SELECT dedupe_staging_link_id, dsl.import_source_id, dsl.description, dsl.position, staging_tab_sid,
			   staging_id_col_sid, staging_batch_num_col_sid, parent_staging_link_id, destination_tab_sid,
			   staging_source_lookup_col_sid, s.lookup_key import_source_lookup
		  FROM dedupe_staging_link dsl
		  JOIN import_source s ON dsl.import_source_id = s.import_source_id
		 WHERE dsl.app_sid = security_pkg.getapp
		   AND dsl.import_source_id = in_import_source_id
		 ORDER BY dedupe_staging_link_id;
END;

PROCEDURE SaveStagingLink(
	in_dedupe_staging_link_id 		IN  dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_import_source_id 			IN  dedupe_staging_link.import_source_id%TYPE,
	in_description 					IN  dedupe_staging_link.description%TYPE,
	in_staging_tab_sid 				IN  dedupe_staging_link.staging_tab_sid%TYPE,
	in_position 					IN  dedupe_staging_link.position%TYPE,
	in_staging_id_col_sid 			IN  dedupe_staging_link.staging_id_col_sid%TYPE,
	in_staging_batch_num_col_sid 	IN  dedupe_staging_link.staging_batch_num_col_sid%TYPE DEFAULT NULL,
	in_staging_src_lookup_col_sid 	IN  dedupe_staging_link.staging_source_lookup_col_sid%TYPE DEFAULT NULL,
	in_parent_staging_link_id 		IN  dedupe_staging_link.parent_staging_link_id%TYPE DEFAULT NULL,
	in_destination_tab_sid 			IN  dedupe_staging_link.destination_tab_sid%TYPE DEFAULT NULL,
	out_dedupe_staging_link_id 		OUT dedupe_staging_link.dedupe_staging_link_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SaveMapping can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;

	IF NVL(in_dedupe_staging_link_id, 0) < 1 THEN
		INSERT INTO dedupe_staging_link(dedupe_staging_link_id, import_source_id, description, position,
					staging_tab_sid, staging_id_col_sid, staging_batch_num_col_sid, parent_staging_link_id, destination_tab_sid,
					staging_source_lookup_col_sid)
			 VALUES (dedupe_staging_link_id_seq.nextval, in_import_source_id, in_description, in_position, 
			 		in_staging_tab_sid, in_staging_id_col_sid, in_staging_batch_num_col_sid, in_parent_staging_link_id, in_destination_tab_sid,
					in_staging_src_lookup_col_sid)
		RETURNING dedupe_staging_link_id INTO out_dedupe_staging_link_id;
	ELSE
		UPDATE dedupe_staging_link
		   SET import_source_id = in_import_source_id,
		   	   description = in_description,
		   	   position = in_position,
		   	   staging_tab_sid = in_staging_tab_sid,
		   	   staging_id_col_sid = in_staging_id_col_sid,
		   	   staging_batch_num_col_sid = in_staging_batch_num_col_sid,
			   staging_source_lookup_col_sid = in_staging_src_lookup_col_sid,
		   	   parent_staging_link_id = in_parent_staging_link_id,
		   	   destination_tab_sid = in_destination_tab_sid
		 WHERE dedupe_staging_link_id = in_dedupe_staging_link_id;

		 out_dedupe_staging_link_id := in_dedupe_staging_link_id;
	END IF;

	SyncStagingLinksPositions;
END;

PROCEDURE DeleteStagingLink(
	in_dedupe_staging_link_id 		IN dedupe_staging_link.dedupe_staging_link_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DeleteStagingLink can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;
	
	DELETE FROM dedupe_staging_link
	 WHERE dedupe_staging_link_id = in_dedupe_staging_link_id;

	SyncStagingLinksPositions;
END;

PROCEDURE GetPotentialParentStagings(
	in_import_source_id 			IN  dedupe_staging_link.import_source_id%TYPE,
	in_dedupe_staging_link_id 		IN  dedupe_staging_link.dedupe_staging_link_id%TYPE,
	out_dedupe_staging_link_cur 	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_dedupe_staging_link_cur FOR
		SELECT dedupe_staging_link_id, import_source_id, description, position, staging_tab_sid,
			   staging_id_col_sid, staging_batch_num_col_sid, parent_staging_link_id, destination_tab_sid,
			   staging_source_lookup_col_sid
		  FROM dedupe_staging_link
		 WHERE app_sid = security_pkg.getapp
		   AND import_source_id = in_import_source_id
		   AND dedupe_staging_link_id <> NVL(in_dedupe_staging_link_id, -1)
		 ORDER BY dedupe_staging_link_id;
END;

PROCEDURE GetLockedCompanyTabs(
	in_company_sid					IN security.security_pkg.T_SID_ID,
	in_company_tab_ids				IN security.security_pkg.T_SID_IDS,
	out_cur							OUT security.security_pkg.T_OUTPUT_CUR
)
AS
	v_sys_import_src_pos			NUMBER;
	v_company_tab_t					security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(in_company_tab_ids);
BEGIN
	SELECT position
	  INTO v_sys_import_src_pos
	  FROM import_source
	 WHERE is_owned_by_system = 1;
	
	OPEN out_cur FOR
		SELECT company_tab_id
		  FROM company_tab ct
		  JOIN csr.plugin p ON p.plugin_id = ct.plugin_id
		 WHERE company_tab_id IN (SELECT column_value FROM TABLE(v_company_tab_t))
		   AND p.tab_sid IN (
			SELECT dml.destination_tab_sid
			  FROM dedupe_processed_record dpr
			  JOIN dedupe_staging_link dsl ON dsl.dedupe_staging_link_id = dpr.dedupe_staging_link_id
			  JOIN import_source s ON s.import_source_id = dsl.import_source_id
			  JOIN dedupe_merge_log dml ON dml.dedupe_processed_record_id = dpr.dedupe_processed_record_id
			 WHERE dml.error_message IS NULL
			   AND dml.destination_tab_sid IS NOT NULL
			   AND in_company_sid IN (dpr.matched_to_company_sid, dpr.created_company_sid)
			   AND s.position < v_sys_import_src_pos
			);
END;

FUNCTION HasProcessedRecordAccess
RETURN BOOLEAN
AS
BEGIN
	RETURN security.user_pkg.IsSuperAdmin = 1 OR (helper_pkg.IsTopCompany = 1 AND company_user_pkg.IsCompanyAdmin = 1);
END;

PROCEDURE GetProcessedRecords(
	in_import_source_id				IN import_source.import_source_id%TYPE,
	in_start						IN NUMBER,
	in_page_size					IN NUMBER,
	out_cur 						OUT SYS_REFCURSOR,

	out_matches_cur					OUT SYS_REFCURSOR,
	out_staging_links_cur			OUT SYS_REFCURSOR
)
AS
	v_total_rows					NUMBER;
BEGIN
	IF NOT HasProcessedRecordAccess THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'GetProcessedRecords can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;
	
	DELETE FROM TT_DEDUPE_PROCESSED_ROW;
	
	INSERT INTO TT_DEDUPE_PROCESSED_ROW(
		dedupe_processed_record_id, dedupe_staging_link_id, staging_link_description, iteration_num, reference, processed_dtm,
		matched_to_company_sid, dedupe_action_type_id, matched_by_user_sid,
		matched_to_company_name, import_source_name, created_company_sid, created_company_name, data_merged, batch_num, cms_record_id, 
		imported_user_sid, imported_user_name, merge_status, error_message, form_lookup_key, dedupe_action)
	SELECT dedupe_processed_record_id, dsl.dedupe_staging_link_id, dsl.description, iteration_num, reference, dpr.processed_dtm, 
		dpr.matched_to_company_sid, dpr.dedupe_action_type_id, dpr.matched_by_user_sid,
		c.name matched_to_company_name, s.name import_source_name, cr.company_sid, cr.name, dpr.data_merged, dpr.batch_num, dpr.cms_record_id, 
		dpr.imported_user_sid, cu.user_name, dpr.merge_status_id, dpr.error_message, f.lookup_key, dpr.dedupe_action
	  FROM dedupe_processed_record dpr
	  JOIN dedupe_staging_link dsl ON dsl.dedupe_staging_link_id = dpr.dedupe_staging_link_id
	  JOIN import_source s ON s.import_source_id = dsl.import_source_id
	  LEFT JOIN company c ON c.company_sid = dpr.matched_to_company_sid
	  LEFT JOIN company cr ON cr.company_sid = dpr.created_company_sid
	  LEFT JOIN csr.csr_user cu ON cu.csr_user_sid = dpr.imported_user_sid
	  LEFT JOIN cms.v$form f ON f.lookup_key = s.lookup_key
	 WHERE (in_import_source_id IS NULL OR dsl.import_source_id = in_import_source_id)
	   AND dsl.parent_staging_link_id IS NULL
	   AND dpr.parent_processed_record_id IS NULL
	 ORDER BY dsl.import_source_id, dsl.position, iteration_num DESC, reference;
	
	SELECT COUNT(*)
	  INTO v_total_rows
	  FROM TT_DEDUPE_PROCESSED_ROW;
	  
	--apply paging
	DELETE FROM TT_DEDUPE_PROCESSED_ROW
	 WHERE dedupe_processed_record_id IN (
		SELECT dedupe_processed_record_id
		  FROM (SELECT dedupe_processed_record_id, ROWNUM rn FROM TT_DEDUPE_PROCESSED_ROW)
		 WHERE rn <= in_start OR rn > (in_start + in_page_size)
	);

	OPEN out_cur FOR 
		SELECT pr.dedupe_processed_record_id, pr.dedupe_staging_link_id, pr.staging_link_description, pr.iteration_num, pr.reference company_ref, pr.processed_dtm, 
			pr.matched_to_company_sid, pr.dedupe_action_type_id, pr.matched_by_user_sid, pr.matched_to_company_name,
			pr.import_source_name, pr.created_company_sid, pr.created_company_name, pr.data_merged company_data_merged,
			v_total_rows total_rows, DECODE(e.error_count, NULL, 0, 1) has_errors, pr.batch_num, pr.cms_record_id,
			pr.imported_user_sid, pr.imported_user_name, pr.form_lookup_key, pr.dedupe_action
		  FROM TT_DEDUPE_PROCESSED_ROW pr
		  LEFT JOIN (
			SELECT dedupe_processed_record_id, COUNT(*) error_count
			  FROM dedupe_merge_log
			 WHERE error_message IS NOT NULL
			 GROUP BY dedupe_processed_record_id
		  ) e ON e.dedupe_processed_record_id = pr.dedupe_processed_record_id
		 ORDER BY pr.dedupe_processed_record_id DESC;
		 
	OPEN out_matches_cur FOR 
		SELECT m.dedupe_match_id, m.dedupe_processed_record_id, m.matched_to_company_sid, m.dedupe_rule_set_id,
			c.name matched_company_name, x.mappings_short_descr
		  FROM TT_DEDUPE_PROCESSED_ROW tt
		  JOIN dedupe_match m ON tt.dedupe_processed_record_id = m.dedupe_processed_record_id
		  JOIN company c ON c.company_sid = m.matched_to_company_sid
		  JOIN (
			SELECT dedupe_rule_set_id, listagg(COALESCE(f.description, r.label, tg.name), ' AND ') WITHIN GROUP (ORDER BY m2.dedupe_mapping_id) mappings_short_descr
			  FROM dedupe_rule dr
			  JOIN dedupe_mapping m2 ON m2.dedupe_mapping_id = dr.dedupe_mapping_id
			  LEFT JOIN dedupe_field f ON f.dedupe_field_id = m2.dedupe_field_id
			  LEFT JOIN reference r ON r.reference_id = m2.reference_id
			  LEFT JOIN csr.v$tag_group tg ON tg.tag_group_id = m2.tag_group_id
			 GROUP BY dedupe_rule_set_id
		  )x ON m.dedupe_rule_set_id = x.dedupe_rule_set_id;
	
	OPEN out_staging_links_cur FOR
		SELECT dsl.dedupe_staging_link_id, dsl.import_source_id, dsl.description, dsl.position, dsl.staging_tab_sid,
			   dsl.staging_id_col_sid, dsl.staging_batch_num_col_sid, dsl.parent_staging_link_id, dsl.destination_tab_sid,
			   nm.col_sid company_name_col_sid, cm.col_sid country_col_sid,
			   dsl.staging_source_lookup_col_sid, s.lookup_key import_source_lookup
		  FROM dedupe_staging_link dsl
		  JOIN import_source s ON dsl.import_source_id = s.import_source_id
		  LEFT JOIN dedupe_mapping nm /* company name mapping */
			ON nm.dedupe_staging_link_id = dsl.dedupe_staging_link_id 
		   AND nm.dedupe_field_id = chain_pkg.FLD_COMPANY_NAME
		  LEFT JOIN dedupe_mapping cm /* company country mapping */
			ON cm.dedupe_staging_link_id = dsl.dedupe_staging_link_id
		   AND cm.dedupe_field_id = chain_pkg.FLD_COMPANY_COUNTRY
		 WHERE dsl.dedupe_staging_link_id IN (
			SELECT dedupe_staging_link_id
			  FROM TT_DEDUPE_PROCESSED_ROW
		   );
END;

PROCEDURE GetRecordMatches(
	in_dedupe_processed_record_id	IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	out_matches_cur					OUT SYS_REFCURSOR,
	out_tags_cur					OUT SYS_REFCURSOR,
	out_refs_cur					OUT SYS_REFCURSOR,
	out_alt_comp_names				OUT SYS_REFCURSOR
)
AS
	v_match_sids		security.T_SID_TABLE;
BEGIN
	IF NOT HasProcessedRecordAccess THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'GetMatches can be run by top company admins or superadmins only');
	END IF;

	SELECT matched_to_company_sid
	  BULK COLLECT INTO v_match_sids
	  FROM dedupe_match
	 WHERE dedupe_processed_record_id = in_dedupe_processed_record_id;
	 
	OPEN out_matches_cur FOR 
		SELECT c.company_sid, c.company_type_id, created_dtm, c.name, active, address_1, address_2, address_3, address_4, state, 
			postcode, country_code, phone, website, email, city, ct.singular company_type_description
		  FROM company c
		  JOIN company_type ct ON ct.company_type_id = c.company_type_id
		  JOIN TABLE(v_match_sids) m ON m.column_value = c.company_sid;
		  
	OPEN out_tags_cur FOR 
		SELECT ct.tag_group_id, ct.tag_id, ct.tag, ct.company_sid
		  FROM v$company_tag ct
		  JOIN TABLE(v_match_sids) m ON m.column_value = ct.company_sid;
	
	OPEN out_refs_cur FOR 
		SELECT cr.company_sid, value, reference_id
		  FROM company_reference cr
		  JOIN TABLE(v_match_sids) m ON m.column_value = cr.company_sid;

	OPEN out_alt_comp_names FOR
		SELECT alt_company_name_id, company_sid, name
		  FROM alt_company_name
		  JOIN TABLE(v_match_sids) m ON m.column_value = company_sid;
END;

PROCEDURE GetMergedDataDetails(
	in_dedupe_processed_record_id	IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_get_errors					IN NUMBER,
	out_cur 						OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT HasProcessedRecordAccess THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'GetMergedDataDetails can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;
	
	OPEN out_cur FOR
		SELECT dml.dedupe_processed_record_id, df.description field_description, tg.name tag_group_name, r.label reference_label,
			CASE WHEN dml.destination_tab_sid IS NOT NULL THEN dt.oracle_table||'.'||dtc.oracle_column ELSE NULL END cms_column,
			dml.old_val, dml.new_val, dml.error_message, dml.current_desc_val, dml.new_raw_val, dml.new_translated_val,
			r.name role_name, r.role_sid
		  FROM dedupe_merge_log dml
		  LEFT JOIN dedupe_field df ON dml.dedupe_field_id = df.dedupe_field_id
		  LEFT JOIN csr.v$tag_group tg ON dml.tag_group_id = tg.tag_group_id
		  LEFT JOIN reference r ON dml.reference_id = r.reference_id
		  LEFT JOIN cms.tab dt ON dt.tab_sid = dml.destination_tab_sid
		  LEFT JOIN cms.tab_column dtc
		    ON dml.destination_tab_sid = dtc.tab_sid
		   AND dml.destination_col_sid = dtc.column_sid
		   LEFT JOIN csr.role r ON r.role_sid = dml.role_sid
		 WHERE dedupe_processed_record_id = in_dedupe_processed_record_id
		   AND ((in_get_errors = 1 AND dml.error_message IS NOT NULL) OR (in_get_errors = 0 AND dml.error_message IS NULL))
		 ORDER BY dedupe_merge_log_id;
END;

PROCEDURE ClearPreProcDatesOnRuleChange
AS
BEGIN
	-- we've changed the rules so at least clear the last updated date from the pre-proc table
	UPDATE dedupe_preproc_comp SET updated_dtm = NULL WHERE app_sid = security_pkg.GetApp;
	UPDATE dedupe_sub SET updated_dtm = NULL WHERE app_sid = security_pkg.GetApp;
END;

PROCEDURE SyncPreProcRulesPositions
AS
	v_sorted_preproc_rule_ids 		security_pkg.T_SID_IDS;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SyncPreProcRulesPositions can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;

	--sync rules positions to be 1 based
	SELECT dedupe_preproc_rule_id
	  BULK COLLECT INTO v_sorted_preproc_rule_ids
	  FROM dedupe_preproc_rule
	 ORDER BY run_order;
	 
	SetPreProcRulesPositions(v_sorted_preproc_rule_ids);
END;

PROCEDURE SetPreProcRulesPositions(
	in_dedupe_preproc_rule_ids		IN	security_pkg.T_SID_IDS
)
AS	
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetPreProcRulesPositions can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;
	
	FOR i IN 1 .. in_dedupe_preproc_rule_ids.COUNT LOOP
		UPDATE dedupe_preproc_rule
		   SET run_order = i
		 WHERE app_sid = security_pkg.getapp
		   AND dedupe_preproc_rule_id = in_dedupe_preproc_rule_ids(i);
	END LOOP;
	
	-- we've changed the rules so at least clear the last updated date from the pre-proc table
	ClearPreProcDatesOnRuleChange;
	
END;

PROCEDURE SyncPreProcFieldCountryPairs(
	in_dedupe_preproc_rule_id		IN dedupe_pp_field_cntry.dedupe_preproc_rule_id%TYPE,
	in_dedupe_field_ids				IN security_pkg.T_SID_IDS,
	in_countries					IN security_pkg.T_VARCHAR2_ARRAY
)
AS
	v_dedupe_field_id_tab			security.T_SID_TABLE;
	v_countries_tab					security.T_VARCHAR2_TABLE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SyncPreProcFieldCountryPairs can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;
	
	v_dedupe_field_id_tab := security_pkg.SidArrayToTable(in_dedupe_field_ids);
	v_countries_tab := security_pkg.Varchar2ArrayToTable(in_countries);	
	
	DELETE FROM dedupe_pp_field_cntry 
	 WHERE  dedupe_preproc_rule_id = in_dedupe_preproc_rule_id
	 AND (NVL(dedupe_field_id, -1), NVL(country_code, -1)) NOT IN (
		SELECT NVL(f.column_value, -1), NVL(c.value, -1)
		  FROM TABLE(v_dedupe_field_id_tab) f
		 CROSS JOIN TABLE(v_countries_tab) c
	 );
	
	INSERT INTO dedupe_pp_field_cntry (dedupe_preproc_rule_id, dedupe_field_id, country_code) 
		 SELECT in_dedupe_preproc_rule_id, f.column_value, c.value 
		   FROM TABLE(v_dedupe_field_id_tab) f
		   FULL JOIN TABLE(v_countries_tab) c ON 1=1
		  WHERE (in_dedupe_preproc_rule_id, NVL(f.column_value, -1), NVL(c.value, -1)) NOT IN (
			SELECT dedupe_preproc_rule_id, NVL(dedupe_field_id, -1), NVL(country_code, -1) 
			  FROM dedupe_pp_field_cntry
			 WHERE dedupe_preproc_rule_id = in_dedupe_preproc_rule_id
		 );
END;

PROCEDURE SavePreProcRule(
	in_dedupe_preproc_rule_id	    IN dedupe_preproc_rule.dedupe_preproc_rule_id%TYPE, 
	in_pattern               	    IN dedupe_preproc_rule.pattern%TYPE, 
	in_replacement                  IN dedupe_preproc_rule.replacement%TYPE, 
	in_run_order            	    IN dedupe_preproc_rule.run_order%TYPE, 
	in_dedupe_field_ids				IN security_pkg.T_SID_IDS,
	in_countries					IN security_pkg.T_VARCHAR2_ARRAY,
	out_dedupe_preproc_rule_id	    OUT dedupe_preproc_rule.dedupe_preproc_rule_id%TYPE
)
AS
BEGIN 
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SavePreProcRule can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;

	-- create the rule if it doesn't exist
	IF NVL(in_dedupe_preproc_rule_id, 0) < 1 THEN
		INSERT INTO dedupe_preproc_rule (dedupe_preproc_rule_id, pattern, replacement, run_order) 
			VALUES (dedupe_preproc_rule_id_seq.nextval, in_pattern, in_replacement, in_run_order) 
			RETURNING dedupe_preproc_rule_id INTO out_dedupe_preproc_rule_id;       
    ELSE
        UPDATE dedupe_preproc_rule
		   SET pattern = in_pattern, 
			   replacement = in_replacement, 
		       run_order = in_run_order
		 WHERE dedupe_preproc_rule_id = in_dedupe_preproc_rule_id;
		 
		out_dedupe_preproc_rule_id := in_dedupe_preproc_rule_id;
    END IF;
	
	-- we've changed the rules so at least clear the last updated date from the pre-proc table
	ClearPreProcDatesOnRuleChange;
    
	SyncPreProcFieldCountryPairs(out_dedupe_preproc_rule_id, in_dedupe_field_ids, in_countries);
	SyncPreProcRulesPositions;
END;

PROCEDURE DeletePreProcRule(
	in_dedupe_preproc_rule_id	    IN dedupe_preproc_rule.dedupe_preproc_rule_id%TYPE
)
AS
BEGIN 
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DeletePreProcRule can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;

	DELETE FROM dedupe_pp_field_cntry WHERE dedupe_preproc_rule_id = in_dedupe_preproc_rule_id;
	DELETE FROM dedupe_preproc_rule WHERE dedupe_preproc_rule_id = in_dedupe_preproc_rule_id;
	
	-- we've changed the rules so at least clear the last updated date from the pre-proc table
	ClearPreProcDatesOnRuleChange;
	
	SyncPreProcRulesPositions;
END;

PROCEDURE GetPreProcRules(
	out_rules	 					OUT security_pkg.T_OUTPUT_CUR, 
	out_fields	 					OUT security_pkg.T_OUTPUT_CUR, 
	out_countries	 				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'GetPreProcRules can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;
	
	OPEN out_rules FOR 
		SELECT dedupe_preproc_rule_id, pattern, replacement, run_order 
		  FROM dedupe_preproc_rule;
	
	OPEN out_fields FOR 
		SELECT DISTINCT dedupe_preproc_rule_id, fc.dedupe_field_id, f.entity, f.field, f.description
		  FROM dedupe_pp_field_cntry fc
		  JOIN dedupe_field f ON fc.dedupe_field_id = f.dedupe_field_id;
	
	OPEN out_countries FOR 
		SELECT DISTINCT dedupe_preproc_rule_id, fc.country_code, c.name country
		  FROM dedupe_pp_field_cntry fc
		  JOIN postcode.country c ON fc.country_code = c.country;
	
END;

PROCEDURE SetSystemDefaultMapAndRules(
	in_try_reset	IN NUMBER DEFAULT 0
)
AS
	v_import_source_id			import_source.import_source_id%TYPE;
	v_dedupe_rule_set_id		dedupe_rule_set.dedupe_rule_set_id%TYPE;
	v_dedupe_staging_link_id	dedupe_staging_link.dedupe_staging_link_id%TYPE;
	v_count						NUMBER;
	v_mapping_ids				security.security_pkg.T_SID_IDS;
	v_rule_ids					security.security_pkg.T_SID_IDS;
	v_rule_type_ids				security.security_pkg.T_SID_IDS;
	v_match_thresholds			helper_pkg.T_NUMBER_ARRAY;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetSystemDefaultMapAndRules can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;
	
	IF in_try_reset = 0 THEN
		SELECT COUNT(*)
		  INTO v_count
		  FROM dedupe_mapping
		 WHERE app_sid = security_pkg.getApp
		   AND is_owned_by_system = 1;
		
		IF v_count > 0 THEN
			RETURN;
		END IF;
	ELSE 
		--let if fail if we have other child records, a different SP should be responsible to clear those
		DELETE FROM dedupe_rule
		 WHERE dedupe_mapping_id IN(
			SELECT dedupe_mapping_id
			  FROM dedupe_mapping
			 WHERE app_sid = security_pkg.getApp
			   AND is_owned_by_system = 1
		 );
		 
		DELETE FROM dedupe_rule_set
		 WHERE dedupe_staging_link_id IN(
			SELECT dedupe_staging_link_id
			  FROM dedupe_staging_link
			 WHERE app_sid = security_pkg.getApp
			   AND is_owned_by_system = 1
		 );
		 
		DELETE FROM dedupe_mapping
		 WHERE is_owned_by_system = 1;
	END IF;
	 
	SELECT import_source_id
	  INTO v_import_source_id
	  FROM import_source
	 WHERE is_owned_by_system = 1;
	 
	BEGIN
		INSERT INTO dedupe_staging_link (dedupe_staging_link_id, import_source_id, description, position, is_owned_by_system)
			VALUES (dedupe_staging_link_id_seq.nextval, v_import_source_id, 'System managed staging', 1, 1)
			RETURNING dedupe_staging_link_id INTO v_dedupe_staging_link_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT dedupe_staging_link_id
			  INTO v_dedupe_staging_link_id
			  FROM dedupe_staging_link
			 WHERE is_owned_by_system = 1;
	END;
	
	SaveMapping(
		in_dedupe_mapping_id		=> NULL,
		in_dedupe_staging_link_id 	=> v_dedupe_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_dedupe_field_id 			=> chain_pkg.FLD_COMPANY_NAME,
		out_dedupe_mapping_id		=> v_mapping_ids(1)
	);
		
	SaveMapping(
		in_dedupe_mapping_id		=> NULL,
		in_dedupe_staging_link_id 	=> v_dedupe_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_dedupe_field_id 			=> chain_pkg.FLD_COMPANY_COUNTRY,
		out_dedupe_mapping_id		=> v_mapping_ids(2)
	);
	
	v_rule_ids(1) := 0;
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_LEVENSHTEIN;
	v_match_thresholds(1) := 50;
	
	v_rule_ids(2) := 0;
	v_rule_type_ids(2) := chain_pkg.RULE_TYPE_EXACT;
	v_match_thresholds(2) := 100;
	  
	SaveRuleSet(
		in_dedupe_rule_set_id		=> NULL,
		in_description				=> 'System Default Match Rule',
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id,
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_MANUAL,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);
END;

END dedupe_admin_pkg;
/
