CREATE OR REPLACE PACKAGE BODY CSR.tag_Pkg AS

PROCEDURE DeleteTagGroup(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_tag_group_id		IN tag_group.tag_group_id%TYPE
) 
AS
	v_app_sid 	security_pkg.T_SID_ID;
BEGIN
	SELECT app_sid 
	  INTO v_app_sid 
	  FROM tag_group 
	 WHERE tag_group_id = in_tag_group_id;
	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_app_sid,  csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to app');
	END IF;

	-- First let's see if Tags of the Group are in use. If at least one of them is in use then the group itself is not allowed to be deleted.
	-- To see if each tag are being used just go ahead and try to delete them to see whether it throws an exception or not.
	--      (Note: first you have to delete the tag from the TAG_GROUP_MEMBER table)
	-- When all tags under the group have been deleted then the group itself can be deleted as well
	FOR r IN (
		SELECT DISTINCT tgm.tag_id
		  FROM TAG_GROUP_MEMBER tgm
		 WHERE tgm.tag_group_id = in_tag_group_id
	)
    LOOP
		RemoveTagFromGroup(in_act_id, in_tag_group_id, r.tag_id);
    END LOOP;
	
	DELETE FROM region_type_tag_group
     WHERE tag_group_Id = in_tag_group_id;
	
	DELETE FROM project_tag_group
	 WHERE tag_group_Id = in_tag_group_id;

	DELETE FROM donations.region_filter_tag_group
	 WHERE region_tag_group_Id = in_tag_group_id;
	 
	DELETE FROM property_element_layout
	 WHERE tag_group_id = in_tag_group_id;
	 
	DELETE FROM property_character_layout
	 WHERE tag_group_id = in_tag_group_id;
	 
	DELETE FROM meter_element_layout
	 WHERE tag_group_id = in_tag_group_id;
	 
	DELETE FROM meter_header_element
	 WHERE tag_group_id = in_tag_group_id;

	DELETE FROM internal_audit_type_tag_group
	 WHERE tag_group_id = in_tag_group_id;
	 
	DELETE FROM chain.company_type_tag_group
	 WHERE tag_group_id = in_tag_group_id;
	 
	DELETE FROM non_compliance_type_tag_group
	 WHERE tag_group_id = in_tag_group_id;
	 
	DELETE FROM benchmark_dashboard_char
	 WHERE tag_group_id = in_tag_group_id;

	DELETE FROM tag_group_description
	 WHERE tag_group_id = in_tag_group_id;

	DELETE FROM tag_group
	 WHERE tag_group_id = in_tag_group_id;
END;

PROCEDURE SetTagGroup(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_name							IN  tag_group_description.name%TYPE,
	in_multi_select					IN	tag_group.multi_select%TYPE,
	in_mandatory					IN	tag_group.mandatory%TYPE,
	in_applies_to_inds				IN	tag_group.applies_to_inds%TYPE,
	in_applies_to_regions			IN	tag_group.applies_to_regions%TYPE,
	in_is_hierarchical				IN	tag_group.is_hierarchical%TYPE DEFAULT 0,
	out_tag_group_id				OUT	tag_group.tag_group_id%TYPE
)
AS
BEGIN
	SetTagGroup(
		in_act_id => in_act_id, 
		in_app_sid => in_app_sid, 
		in_name => in_name, 
		in_multi_select => in_multi_select, 
		in_mandatory => in_mandatory, 
		in_applies_to_inds => in_applies_to_inds, 
		in_applies_to_regions => in_applies_to_regions, 
		in_applies_to_non_comp => 0,
		in_is_hierarchical => in_is_hierarchical,
		out_tag_group_id => out_tag_group_id
	);
END;

PROCEDURE SetTagGroupByName(
	in_act_id						IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
	in_app_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	in_name							IN	tag_group_description.name%TYPE,
	in_applies_to_inds				IN	tag_group.applies_to_inds%TYPE,
	in_applies_to_regions			IN	tag_group.applies_to_regions%TYPE,
	in_applies_to_suppliers			IN	tag_group.applies_to_suppliers%TYPE,
	in_excel_import					IN	NUMBER,
	out_tag_group_id				OUT	tag_group.tag_group_id%TYPE
)
AS
	v_tag_group_id					tag_group.tag_group_id%TYPE;
	v_multi_select					tag_group.multi_select%TYPE;
	v_mandatory						tag_group.mandatory%TYPE;
	v_applies_to_inds				tag_group.applies_to_inds%TYPE;
	v_applies_to_regions			tag_group.applies_to_regions%TYPE;
	v_applies_to_suppliers			tag_group.applies_to_suppliers%TYPE;
	v_applies_to_non_comp			tag_group.applies_to_non_compliances%TYPE;
	v_applies_to_chain				tag_group.applies_to_chain%TYPE;
	v_applies_to_chain_activities	tag_group.applies_to_chain_activities%TYPE;
	v_applies_to_initiatives		tag_group.applies_to_initiatives%TYPE;
	v_applies_to_chain_prod_types	tag_group.applies_to_chain_product_types%TYPE;
	v_applies_to_chain_products		tag_group.applies_to_chain_products%TYPE;
	v_applies_to_chain_prod_supps	tag_group.applies_to_chain_product_supps%TYPE;
	v_applies_to_quick_survey		tag_group.applies_to_quick_survey%TYPE;
	v_applies_to_audits				tag_group.applies_to_audits%TYPE;
	v_applies_to_compliances		tag_group.applies_to_compliances%TYPE;
	v_lookup_key					tag_group.lookup_key%TYPE;
	v_is_hierarchical				tag_group.is_hierarchical%TYPE;
BEGIN
	BEGIN
		SELECT tag_group_id, multi_select, mandatory, NVL(in_applies_to_inds, applies_to_inds),
			   NVL(in_applies_to_regions, applies_to_regions), NVL(in_applies_to_suppliers, applies_to_suppliers),
			   applies_to_non_compliances, applies_to_chain, applies_to_chain_activities, applies_to_initiatives,
			   applies_to_chain_product_types, applies_to_chain_products, applies_to_chain_product_supps,
			   applies_to_quick_survey, applies_to_audits, applies_to_compliances, lookup_key, is_hierarchical
		  INTO v_tag_group_id, v_multi_select, v_mandatory, v_applies_to_inds,
			   v_applies_to_regions, v_applies_to_suppliers, 
			   v_applies_to_non_comp, v_applies_to_chain, v_applies_to_chain_activities, v_applies_to_initiatives,
			   v_applies_to_chain_prod_types, v_applies_to_chain_products, v_applies_to_chain_prod_supps,
			   v_applies_to_quick_survey, v_applies_to_audits, v_applies_to_compliances, v_lookup_key, v_is_hierarchical
		  FROM v$tag_group
		 WHERE UPPER(name) = UPPER(in_name)
		   AND app_sid = SYS_CONTEXT('SECURITY','APP');
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
			SetTagGroup(
				in_act_id					=> in_act_id,
				in_app_sid					=> in_app_sid,
				in_name						=> in_name,
				in_applies_to_inds			=> in_applies_to_inds,
				in_applies_to_regions		=> in_applies_to_regions,
				in_applies_to_suppliers		=> in_applies_to_suppliers,
				in_excel_import				=> in_excel_import,
				out_tag_group_id			=> out_tag_group_id
			);
			RETURN;
	END;
	
	SetTagGroup(
		in_act_id						=> in_act_id,
		in_app_sid						=> in_app_sid,
		in_tag_group_id					=> v_tag_group_id,
		in_name							=> in_name,
		in_multi_select					=> v_multi_select,
		in_mandatory					=> v_mandatory,
		in_applies_to_inds				=> v_applies_to_inds,
		in_applies_to_regions			=> v_applies_to_regions,
		in_applies_to_suppliers			=> v_applies_to_suppliers,
		in_excel_import					=> in_excel_import,
		in_applies_to_chain				=> v_applies_to_chain,
		in_applies_to_chain_activities	=> v_applies_to_chain_activities,
		in_applies_to_initiatives		=> v_applies_to_initiatives,
		in_applies_to_chain_prod_types	=> v_applies_to_chain_prod_types,
		in_applies_to_chain_products	=> v_applies_to_chain_products,
		in_applies_to_chain_prod_supps	=> v_applies_to_chain_prod_supps,
		in_applies_to_quick_survey		=> v_applies_to_quick_survey,
		in_applies_to_audits			=> v_applies_to_audits,
		in_applies_to_compliances		=> v_applies_to_compliances,
		in_lookup_key					=> v_lookup_key,
		in_is_hierarchical				=> v_is_hierarchical,
		out_tag_group_id				=> out_tag_group_id
	);
END;

-- creates or amends a tag_group
PROCEDURE SetTagGroup(
	in_act_id						IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
	in_app_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	in_tag_group_id					IN	tag_group.tag_group_id%TYPE DEFAULT NULL,
	in_name							IN  tag_group_description.name%TYPE,
	in_multi_select					IN	tag_group.multi_select%TYPE DEFAULT 0,
	in_mandatory					IN	tag_group.mandatory%TYPE DEFAULT 0,
	in_applies_to_inds				IN	tag_group.applies_to_inds%TYPE DEFAULT 0,
	in_applies_to_regions			IN	tag_group.applies_to_regions%TYPE DEFAULT 0,
	in_applies_to_non_comp			IN	tag_group.applies_to_non_compliances%TYPE DEFAULT 0,
	in_applies_to_suppliers			IN	tag_group.applies_to_suppliers%TYPE DEFAULT 0,
	in_applies_to_chain				IN	tag_group.applies_to_chain%TYPE DEFAULT 0,
	in_applies_to_chain_activities	IN	tag_group.applies_to_chain_activities%TYPE DEFAULT 0,
	in_applies_to_initiatives		IN	tag_group.applies_to_initiatives%TYPE DEFAULT 0,
	in_applies_to_chain_prod_types	IN	tag_group.applies_to_chain_product_types%TYPE DEFAULT 0,
	in_applies_to_chain_products	IN	tag_group.applies_to_chain_products%TYPE DEFAULT 0,
	in_applies_to_chain_prod_supps	IN	tag_group.applies_to_chain_product_supps%TYPE DEFAULT 0,
	in_applies_to_quick_survey		IN	tag_group.applies_to_quick_survey%TYPE DEFAULT 0,
	in_applies_to_audits			IN	tag_group.applies_to_audits%TYPE DEFAULT 0,
	in_applies_to_compliances		IN	tag_group.applies_to_compliances%TYPE DEFAULT 0,
	in_excel_import					IN  NUMBER DEFAULT 0,
	in_lookup_key					IN	tag_group.lookup_key%TYPE DEFAULT NULL,
	in_is_hierarchical				IN	tag_group.is_hierarchical%TYPE DEFAULT 0,
	out_tag_group_id				OUT	tag_group.tag_group_id%TYPE
)
AS
	v_applies_to_non_comp			tag_group.applies_to_non_compliances%TYPE;
	v_count_non_comp				NUMBER;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid,  csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to app');
	END IF;
	
	IF in_tag_group_id IS NULL THEN
		BEGIN
			CreateTagGroup(
				in_act_id						=>	in_act_id,
				in_app_sid						=>	in_app_sid,
				in_name							=>	in_name,
				in_multi_select					=>	in_multi_select,
				in_mandatory					=>	CASE in_excel_import WHEN 1 THEN 0 ELSE in_mandatory END,
				in_applies_to_inds				=>	in_applies_to_inds,
				in_applies_to_regions			=>	in_applies_to_regions,
				in_applies_to_non_comp			=>	in_applies_to_non_comp,
				in_applies_to_suppliers			=>	in_applies_to_suppliers,
				in_applies_to_chain				=>	in_applies_to_chain,
				in_applies_to_chain_activities	=>	in_applies_to_chain_activities,
				in_applies_to_initiatives		=>	in_applies_to_initiatives,
				in_applies_to_chain_prod_types	=>	in_applies_to_chain_prod_types,
				in_applies_to_chain_products	=>	in_applies_to_chain_products,
				in_applies_to_chain_prod_supps	=>	in_applies_to_chain_prod_supps,
				in_applies_to_quick_survey		=>	in_applies_to_quick_survey,
				in_applies_to_audits			=>	in_applies_to_audits,
				in_applies_to_compliances		=>	in_applies_to_compliances,
				in_excel_import					=>	in_excel_import,
				in_lookup_key					=>	in_lookup_key,
				in_is_hierarchical				=>	in_is_hierarchical,
				out_tag_group_id				=>	out_tag_group_id
			);
		EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			BEGIN
				SELECT tag_group_id
				  INTO out_tag_group_id
				  FROM tag_group
				 WHERE app_sid = in_app_sid
				   AND UPPER(lookup_key) = UPPER(in_lookup_key);
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					SELECT tag_group_id
					  INTO out_tag_group_id
					  FROM v$tag_group
					 WHERE app_sid = in_app_sid
					   AND UPPER(name) = UPPER(in_name);
			END;
		END;
	ELSE
		-- Force a NO_DATA_FOUND exception if the supplied id is not valid.
		SELECT applies_to_non_compliances
		  INTO v_applies_to_non_comp
		  FROM tag_group
		 WHERE tag_group_id = in_tag_group_id;
		
		-- only check non-compliances atm, don't want to blindly apply to all applies to options, but raise a generic error, so it can be extended
		IF v_applies_to_non_comp = 1 AND in_applies_to_non_comp = 0 THEN
			SELECT COUNT(*)
			  INTO v_count_non_comp
			  FROM tag_group_ir_member nct
		      JOIN audit_non_compliance anc ON anc.non_compliance_id = nct.non_compliance_id
			 WHERE tag_group_id = in_tag_group_id;
			 
			IF v_count_non_comp > 0 THEN
				RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_INVALID_TAG_APPLIES_CHANGE, 'Cannot change what a Tag Group applies to after it has been used.');
			END IF;			
		END IF;
		
		UPDATE tag_group
		   SET multi_select = in_multi_select,
			 mandatory = CASE WHEN in_excel_import = 1 THEN mandatory ELSE in_mandatory END, 
			 applies_to_inds = in_applies_to_inds,
			 applies_to_regions = in_applies_to_regions,
			 applies_to_non_compliances = in_applies_to_non_comp,
			 applies_to_suppliers = in_applies_to_suppliers,
			 applies_to_chain = in_applies_to_chain,
			 applies_to_chain_activities = in_applies_to_chain_activities,
			 applies_to_initiatives = in_applies_to_initiatives,
			 applies_to_chain_product_types = in_applies_to_chain_prod_types,
			 applies_to_chain_products = in_applies_to_chain_products,
			 applies_to_chain_product_supps = in_applies_to_chain_prod_supps,
			 applies_to_quick_survey = in_applies_to_quick_survey,
			 applies_to_audits = in_applies_to_audits,
			 applies_to_compliances = in_applies_to_compliances,
			 lookup_key = in_lookup_key,
			 is_hierarchical = in_is_hierarchical
		 WHERE tag_group_id = in_tag_group_id
		   AND app_sid = in_app_sid;
		
		BEGIN
			UPDATE tag_group_description
			   SET name = NVL(in_name, 'Tag Group '||in_tag_group_id)
			 WHERE tag_group_id = in_tag_group_id 
			   AND lang = 'en'
			   AND app_sid = in_app_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				INSERT INTO tag_group_description
					(app_sid, tag_group_id, lang, name)
				VALUES (in_app_sid, in_tag_group_id, 'en', NVL(in_name, 'Tag Group '||in_tag_group_id));
		END;

		out_tag_group_id := in_tag_group_id;
	END IF;
END;

-- creates a tag_group
PROCEDURE CreateTagGroup(
	in_act_id						IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
	in_app_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	in_name							IN	tag_group_description.name%TYPE,
	in_multi_select					IN	tag_group.multi_select%TYPE DEFAULT 0,
	in_mandatory					IN	tag_group.mandatory%TYPE DEFAULT 0,
	in_applies_to_inds				IN	tag_group.applies_to_inds%TYPE DEFAULT 0,
	in_applies_to_regions			IN	tag_group.applies_to_regions%TYPE DEFAULT 0,
	in_applies_to_non_comp			IN	tag_group.applies_to_non_compliances%TYPE DEFAULT 0,
	in_applies_to_suppliers			IN	tag_group.applies_to_suppliers%TYPE DEFAULT 0,
	in_applies_to_chain				IN	tag_group.applies_to_chain%TYPE DEFAULT 0,
	in_applies_to_chain_activities	IN	tag_group.applies_to_chain_activities%TYPE DEFAULT 0,
	in_applies_to_initiatives		IN	tag_group.applies_to_initiatives%TYPE DEFAULT 0,
	in_applies_to_chain_prod_types	IN	tag_group.applies_to_chain_product_types%TYPE DEFAULT 0,
	in_applies_to_chain_products	IN	tag_group.applies_to_chain_products%TYPE DEFAULT 0,
	in_applies_to_chain_prod_supps	IN	tag_group.applies_to_chain_product_supps%TYPE DEFAULT 0,
	in_applies_to_quick_survey		IN	tag_group.applies_to_quick_survey%TYPE DEFAULT 0,
	in_applies_to_audits			IN	tag_group.applies_to_audits%TYPE DEFAULT 0,
	in_applies_to_compliances		IN	tag_group.applies_to_compliances%TYPE DEFAULT 0,
	in_excel_import					IN	NUMBER DEFAULT 0,
	in_lookup_key					IN	tag_group.lookup_key%TYPE DEFAULT NULL,
	in_is_hierarchical				IN	tag_group.is_hierarchical%TYPE DEFAULT 0,
	out_tag_group_id				OUT	tag_group.tag_group_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid,  csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to app');
	END IF;
	
	INSERT INTO tag_group
		(app_sid, tag_group_id, multi_select, mandatory, 
		applies_to_inds, applies_to_regions, applies_to_non_compliances,
		applies_to_suppliers, applies_to_chain, applies_to_chain_activities, applies_to_initiatives, 
		applies_to_chain_product_types, applies_to_chain_products, applies_to_chain_product_supps,
		applies_to_quick_survey, applies_to_audits, applies_to_compliances, lookup_key, is_hierarchical)
	VALUES (in_app_sid, tag_group_id_seq.nextval, in_multi_select, CASE in_excel_import WHEN 1 THEN 0 ELSE in_mandatory END,
		in_applies_to_inds, in_applies_to_regions, in_applies_to_non_comp,
		in_applies_to_suppliers, in_applies_to_chain, in_applies_to_chain_activities, in_applies_to_initiatives,
		in_applies_to_chain_prod_types, in_applies_to_chain_products, in_applies_to_chain_prod_supps,
		in_applies_to_quick_survey, in_applies_to_audits, in_applies_to_compliances, in_lookup_key, in_is_hierarchical)
	RETURNING tag_group_id INTO out_tag_group_id;

	INSERT INTO tag_group_description
		(app_sid, tag_group_id, lang, name)
	VALUES (in_app_sid, out_tag_group_id, 'en', NVL(in_name, 'Tag Group '||out_tag_group_id));
END;

PROCEDURE SetTagGroupRegionTypes(
	in_tag_group_id					IN	tag_group.tag_group_id%TYPE DEFAULT NULL,
	in_region_type_ids				IN	security_pkg.T_SID_IDS
)
AS
	v_region_type_t	security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(in_region_type_ids);
BEGIN
	--clear old values and re-insert
	DELETE FROM region_type_tag_group
	  WHERE tag_group_id = in_tag_group_id;
	  
	INSERT INTO region_type_tag_group (region_type, tag_group_id)
	SELECT column_value, in_tag_group_id
	  FROM TABLE(v_region_type_t);
END;

PROCEDURE SetTagGroupCompanyTypes(
	in_tag_group_id					IN	tag_group.tag_group_id%TYPE DEFAULT NULL,
	in_company_type_ids				IN	security_pkg.T_SID_IDS
)
AS
	v_ct_type_t	security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(in_company_type_ids);
BEGIN
	--clear old values and re-insert
	DELETE FROM chain.company_type_tag_group
	  WHERE tag_group_id = in_tag_group_id;
	  
	INSERT INTO chain.company_type_tag_group (company_type_id, tag_group_id)
	SELECT column_value, in_tag_group_id
	  FROM TABLE(v_ct_type_t);
END;

PROCEDURE SetTagGroupNCTypes(
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE DEFAULT NULL,
	in_nc_ids				IN	security_pkg.T_SID_IDS
)
AS
	v_nc_type_t	security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(in_nc_ids);
BEGIN
	--clear old values and re-insert
	DELETE FROM non_compliance_type_tag_group
	  WHERE tag_group_id = in_tag_group_id;
	  
	INSERT INTO non_compliance_type_tag_group (non_compliance_type_id, tag_group_id)
	SELECT column_value, in_tag_group_id
	  FROM TABLE(v_nc_type_t);
END;

PROCEDURE SetTagGroupIATypes(
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE DEFAULT NULL,
	in_ia_ids				IN	security_pkg.T_SID_IDS
)
AS
	v_ia_type_t	security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(in_ia_ids);
BEGIN
	--clear old values and re-insert
	DELETE FROM internal_audit_type_tag_group
	  WHERE tag_group_id = in_tag_group_id;
	  
	INSERT INTO internal_audit_type_tag_group (internal_audit_type_id, tag_group_id)
	SELECT column_value, in_tag_group_id
	  FROM TABLE(v_ia_type_t);
END;

PROCEDURE SetTagGroupInitiativeTypes(
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE DEFAULT NULL,
	in_init_type_ids		IN	security_pkg.T_SID_IDS
)
AS
	v_init_type_t	security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(in_init_type_ids);
BEGIN
	--Clear old values and re-insert
	DELETE FROM project_tag_group
	  WHERE tag_group_id = in_tag_group_id;
	 
	INSERT INTO project_tag_group (project_sid, tag_group_id)
	SELECT column_value, in_tag_group_id
	  FROM TABLE(v_init_type_t);
END;

PROCEDURE SetTagGroupDescription(
	in_tag_group_id					IN	tag_group_description.tag_group_id%TYPE,
	in_langs						IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_descriptions					IN	security.security_pkg.T_VARCHAR2_ARRAY
)
AS
	v_app			security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act			security_pkg.T_ACT_ID := security_pkg.GetACT;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(v_act, v_app, csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	IF in_langs.COUNT != in_descriptions.COUNT THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_UNEXPECTED, 'Data mismatch');
	END IF;

	FOR i IN 1..in_langs.COUNT
	LOOP
		SetTagGroupDescription(in_tag_group_id, in_langs(i), in_descriptions(i));
	END LOOP;
END;

PROCEDURE SetTagGroupDescription(
	in_tag_group_id					IN	tag_group_description.tag_group_id%TYPE,
	in_lang							IN	tag_group_description.lang%TYPE,
	in_description					IN	tag_group_description.name%TYPE
)
AS
	v_app			security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act			security_pkg.T_ACT_ID := security_pkg.GetACT;
	v_description	region_description.description%TYPE;
	v_current_name	tag_group_description.name%TYPE;
	v_action		VARCHAR2(50);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(v_act, v_app, csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	BEGIN
		SELECT name
		  INTO v_current_name
		  FROM tag_group_description
		 WHERE app_sid = v_app
		   AND tag_group_id = in_tag_group_id
		   AND lang = in_lang;

		IF in_description IS NULL THEN
			DELETE FROM tag_group_description
			 WHERE app_sid = v_app
			   AND tag_group_id = in_tag_group_id
			   AND lang = in_lang;
			
			v_action := 'deleted';
		END IF;

		IF in_description IS NOT NULL AND v_current_name != in_description THEN
			UPDATE tag_group_description
			   SET name = in_description, last_changed_dtm = SYSDATE
			 WHERE app_sid = v_app
			   AND tag_group_id = in_tag_group_id
			   AND lang = in_lang;
			
			v_action := 'updated';
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			IF in_description IS NOT NULL THEN
				INSERT INTO tag_group_description (app_sid, tag_group_id, lang, name, last_changed_dtm)
				VALUES (v_app, in_tag_group_id, in_lang, in_description, SYSDATE);
			
				v_action := 'created';
			END IF;
	END;
	
	IF v_action IS NOT NULL THEN
		csr_data_pkg.WriteAuditLogEntry(
			v_act,
			csr_data_pkg.AUDIT_TYPE_TAG_DESC_CHANGED,
			v_app,
			NULL,
			'Category Description '||v_action||' ('||in_tag_group_id||')',
			in_lang,
			v_current_name,
			in_description,
			in_tag_group_id
			);
	END IF;
END;

PROCEDURE INTERNAL_TryCreateTag(
	in_tag_group_name				IN	tag_group_description.name%TYPE,
	in_tag							IN	tag_description.tag%TYPE,
	in_applies_to_inds				IN	tag_group.applies_to_inds%TYPE DEFAULT 0,
	in_applies_to_regions			IN	tag_group.applies_to_regions%TYPE DEFAULT 0,
	in_applies_to_non_comp			IN	tag_group.applies_to_non_compliances%TYPE DEFAULT 0,
	in_applies_to_suppliers			IN	tag_group.applies_to_suppliers%TYPE DEFAULT 0,
	in_applies_to_chain				IN	tag_group.applies_to_chain%TYPE DEFAULT 0,
	in_applies_to_chain_activities	IN	tag_group.applies_to_chain_activities%TYPE DEFAULT 0,
	in_applies_to_initiatives		IN	tag_group.applies_to_initiatives%TYPE DEFAULT 0,
	in_applies_to_chain_prod_types	IN	tag_group.applies_to_chain_product_types%TYPE DEFAULT 0,
	in_applies_to_chain_products	IN	tag_group.applies_to_chain_products%TYPE DEFAULT 0,
	in_applies_to_chain_prod_supps	IN	tag_group.applies_to_chain_product_supps%TYPE DEFAULT 0,
	in_applies_to_quick_survey		IN	tag_group.applies_to_quick_survey%TYPE DEFAULT 0,
	in_applies_to_audits			IN	tag_group.applies_to_audits%TYPE DEFAULT 0,
	in_applies_to_compliances		IN	tag_group.applies_to_compliances%TYPE DEFAULT 0,
	in_is_hierarchical				IN	tag_group.is_hierarchical%TYPE DEFAULT 0,
	out_tag_id						OUT	tag.tag_id%TYPE
)
AS
	v_pos				tag_group_member.pos%TYPE;
	v_tag_group_id		tag_group.tag_group_id%TYPE;
BEGIN
	-- try read, or create tag_group
	BEGIN
		SELECT tag_group_id
		  INTO v_tag_group_id
		  FROM v$tag_group
		 WHERE app_sid = security_pkg.getApp
		   AND LOWER(name) = LOWER(in_tag_group_name)
		   FOR UPDATE; -- lock
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO tag_group 
				(app_sid, tag_group_id, multi_select, mandatory, 
				applies_to_inds, applies_to_regions, applies_to_non_compliances, applies_to_suppliers, 
				applies_to_chain, applies_to_chain_activities, applies_to_initiatives,
				applies_to_chain_product_types, applies_to_chain_products, applies_to_chain_product_supps,
				applies_to_quick_survey, applies_to_audits, applies_to_compliances, is_hierarchical)
			VALUES 
				(security_pkg.getApp, tag_group_id_seq.nextval, 1, 0,
				in_applies_to_inds, in_applies_to_regions, in_applies_to_non_comp, in_applies_to_suppliers,
				in_applies_to_chain, in_applies_to_chain_activities, in_applies_to_initiatives, 
				in_applies_to_chain_prod_types, in_applies_to_chain_products, in_applies_to_chain_prod_supps,
				in_applies_to_quick_survey, in_applies_to_audits, in_applies_to_compliances, in_is_hierarchical)
			RETURNING tag_group_id INTO v_tag_group_id;
			
			INSERT INTO tag_group_description
				(tag_group_id, lang, name)
			VALUES (v_tag_group_id, 'en', NVL(in_tag_group_name, 'Tag Group '||v_tag_group_id));
	END;
	
	-- try read or create tag
	BEGIN
		SELECT t.tag_id
		  INTO out_tag_id
		  FROM v$tag t, tag_group_member tgm
		 WHERE t.tag_id = tgm.tag_id
		   AND LOWER(t.tag) = LOWER(in_tag)
		   AND tgm.tag_group_id = v_tag_group_id
		   AND UPPER(tag) = UPPER(in_tag)
		   FOR UPDATE; -- lock
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO tag 
				(tag_id)
			VALUES
				(tag_id_seq.nextval)
			RETURNING tag_id INTO out_tag_id;
			
			INSERT INTO tag_description 
				(tag_id, lang, tag, explanation)
			VALUES
				(out_tag_id, 'en', NVL(in_tag, 'Tag '||out_tag_id), null);
			
			BEGIN
				SELECT NVL(MAX(pos),0)
				  INTO v_pos
				  FROM tag_group_member
				 WHERE tag_group_id = v_tag_group_id
				 GROUP BY tag_group_Id;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					v_pos := 0;
			END;
			INSERT INTO tag_group_member
				(tag_group_id, tag_id, pos)
			VALUES (v_tag_group_id, out_tag_id, v_pos+1);
	END;
END;

/**
 * Useful for quickly importing things from Excel since it
 * takes names not ids, and will automatically create things
 * that don't exist.
 */
PROCEDURE SetIndicatorTag(
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_tag_group_name	IN	tag_group_description.name%TYPE,
	in_tag				IN	tag_description.tag%TYPE
)
AS
	v_tag_id			tag.tag_id%TYPE;
	v_pos				tag_group_member.pos%TYPE;
	v_tag_group_id		tag_group.tag_group_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_ind_sid, csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	INTERNAL_TryCreateTag(
		in_tag_group_name 	=> in_tag_group_name, 
		in_tag				=> in_tag, 
		in_applies_to_inds	=> 1,
		out_tag_id			=> v_tag_id);
	
	-- assign tag to indicator
	BEGIN
		INSERT INTO IND_TAG (tag_id, ind_sid) VALUES (v_tag_id, in_ind_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN	
			NULL;
	END;
END;

PROCEDURE INTERNAL_AddCalcJobs(
	in_tag_id		tag.tag_id%TYPE
)
AS
BEGIN
	FOR r IN (
		SELECT DISTINCT calc_ind_sid
		  FROM calc_tag_dependency
		 WHERE tag_id = in_tag_id
	 ) LOOP
		calc_pkg.AddJobsForCalc(r.calc_ind_sid);
	 END LOOP;
END;

PROCEDURE INTERNAL_RegionTagChangeAudit(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_tag_id 			IN	tag.tag_id%TYPE,
	in_log_msg			IN	VARCHAR2
)
AS
	v_tag_name			tag_description.tag%TYPE;
	v_tag_group_name	tag_group_description.name%TYPE;
BEGIN
	BEGIN
		SELECT tag, name
		  INTO v_tag_name, v_tag_group_name
		  FROM v$tag t, v$tag_group tg
		 WHERE t.tag_id = in_tag_id 
		   AND tag_group_id = (
					SELECT tag_group_id
					  FROM tag_group_member
					 WHERE tag_id = in_tag_id);
					 
		csr_data_pkg.WriteAuditLogEntry(
			security_pkg.GetACT,
			csr_data_pkg.AUDIT_TYPE_REGION_TAG_CHANGED,
			security_pkg.GetAPP,
			in_region_sid,
			in_log_msg,
			v_tag_group_name,
			v_tag_name);
	EXCEPTION 
	 WHEN NO_DATA_FOUND THEN
		NULL;
	END;
END;

/**
 * Useful for quickly importing things from Excel since it
 * takes names not ids, and will automatically create things
 * that don't exist.
 */
PROCEDURE SetRegionTag(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_tag_group_name	IN	tag_group_description.name%TYPE,
	in_tag				IN	tag_description.tag%TYPE
)
AS
	v_tag_id			tag.tag_id%TYPE;
	v_plan_created		NUMBER;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_region_sid, csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	INTERNAL_TryCreateTag(
		in_tag_group_name 		=> in_tag_group_name, 
		in_tag					=> in_tag, 
		in_applies_to_regions	=> 1,
		out_tag_id				=> v_tag_id);
	
	-- assign tag to region
	BEGIN
		INSERT INTO region_tag (tag_id, region_sid) 
		VALUES (v_tag_id, in_region_sid);
		
		INTERNAL_RegionTagChangeAudit(in_region_sid, v_tag_id, 'Added "{1}" to category "{0}"');
			
		-- Update any dynamic delegation plans that depend on this region
		region_pkg.ApplyDynamicPlans(in_region_sid, 'Region tags changed');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN	
			NULL;
	END;
	
	INTERNAL_AddCalcJobs(v_tag_id);
END;

PROCEDURE UNSEC_SetRegionTag(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_tag_id			IN 	tag.tag_id%TYPE
)
AS
BEGIN
	-- assign tag to region
	BEGIN
		INSERT INTO region_tag (tag_id, region_sid) 
		VALUES (in_tag_id, in_region_sid);
		
		INTERNAL_RegionTagChangeAudit(in_region_sid, in_tag_id, 'Added "{1}" to category "{0}"');
			
		-- Update any dynamic delegation plans that depend on this region
		region_pkg.ApplyDynamicPlans(in_region_sid, 'Region tags changed');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN	
			NULL;
	END;
	
	INTERNAL_AddCalcJobs(in_tag_id);
END;

PROCEDURE SetNonComplianceTag(
	in_non_compliance_id	IN	non_compliance.non_compliance_id%TYPE,
	in_tag_group_name		IN	tag_group_description.name%TYPE,
	in_tag					IN	tag_description.tag%TYPE
)
AS
	v_tag_id			tag.tag_id%TYPE;
BEGIN
	audit_pkg.CheckNonComplianceAccess(in_non_compliance_id, security_pkg.PERMISSION_WRITE, 'Access denied setting tags to non-compliance with id: '||in_non_compliance_id);
	
	INTERNAL_TryCreateTag(
		in_tag_group_name 		=> in_tag_group_name, 
		in_tag					=> in_tag, 
		in_applies_to_non_comp	=> 1,
		out_tag_id				=> v_tag_id);
	
	-- assign tag to region
	BEGIN
		INSERT INTO NON_COMPLIANCE_TAG (tag_id, non_compliance_id) VALUES (v_tag_id, in_non_compliance_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN	
			NULL;
	END;
END;

/**
 * Sort tag group members alphabetically - useful if you
 * import a load of things with SetIndicatorTag from Excel
 */
PROCEDURE SortTagGroupMembers(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_tag_group_id		IN	tag_group.tag_group_id%TYPE
)
AS
	v_app_sid		security_pkg.T_SID_ID;
BEGIN
	SELECT app_sid INTO v_app_sid FROM tag_group WHERE tag_group_id = in_tag_group_id;

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_app_sid,  csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	FOR r IN (
		SELECT rownum rn, x.*
   		  FROM (
			SELECT t.tag_id, tgm.tag_group_id 
			  FROM tag_group_member tgm, v$tag t 
			 WHERE tgm.tag_id = t.tag_id 
			   AND tag_group_id IN (in_tag_group_Id) 
			 ORDER BY tag
		)x
	)
	LOOP
		UPDATE tag_group_member SET pos = r.rn WHERE tag_id = r.tag_id AND tag_group_id = r.tag_group_id;
	END LOOP;
END;

-- update or insert tag 
PROCEDURE SetTag(
	in_act_id				IN	security_pkg.T_ACT_ID				DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE,
	in_tag_id				IN	tag.tag_id%TYPE						DEFAULT NULL,
	in_tag					IN	tag_description.tag%TYPE,
	in_explanation			IN	tag_description.explanation%TYPE	DEFAULT NULL,
	in_pos					IN	tag_group_member.pos%TYPE			DEFAULT NULL,
	in_lookup_key			IN	tag.lookup_key%TYPE					DEFAULT NULL,
	in_parent_id			IN	tag.parent_id%TYPE					DEFAULT NULL,
	in_parent_lookup_key	IN	VARCHAR2							DEFAULT NULL,
	out_tag_id				OUT	tag.tag_id%TYPE
)
AS
BEGIN
	SetTag(
		in_act_id => in_act_id, 
		in_tag_group_id => in_tag_group_id,
		in_tag_id => in_tag_id,
		in_tag => in_tag,
		in_explanation => in_explanation,
		in_pos => in_pos,
		in_lookup_key => in_lookup_key,
		in_active => 1,
		in_parent_id => in_parent_id,
		in_parent_lookup_key => in_parent_lookup_key,
		out_tag_id => out_tag_id
	);
END;

-- update or insert tag 
PROCEDURE SetTag(
	in_act_id				IN	security_pkg.T_ACT_ID				DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE,
	in_tag_id				IN	tag.tag_id%TYPE						DEFAULT NULL,
	in_tag					IN	tag_description.tag%TYPE,
	in_explanation			IN	tag_description.explanation%TYPE	DEFAULT NULL,
	in_pos					IN	tag_group_member.pos%TYPE			DEFAULT NULL,
	in_lookup_key			IN	tag.lookup_key%TYPE					DEFAULT NULL,
	in_active				IN	tag_group_member.active%TYPE,
	in_parent_id			IN	tag.parent_id%TYPE					DEFAULT NULL,
	in_parent_lookup_key	IN	VARCHAR2							DEFAULT NULL,
	out_tag_id				OUT	tag.tag_id%TYPE
)
AS
	v_app_sid			security_pkg.T_SID_ID;
	v_tag_id			tag.tag_id%TYPE;
	v_parent_id			tag.parent_id%TYPE;
	v_existing_tag_id	tag.tag_id%TYPE;
BEGIN
	SELECT app_sid INTO v_app_sid FROM tag_group WHERE tag_group_id = in_tag_group_id;

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_app_sid,  csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	IF in_parent_lookup_key IS NOT NULL THEN
		SELECT tag_id
		  INTO v_parent_id
		  FROM tag
		 WHERE lookup_key = in_parent_lookup_key;
	ELSE
		v_parent_id := in_parent_id;
	END IF;
	

	v_tag_id := in_tag_id;
	IF NVL(v_tag_id, -1) = -1 THEN
		BEGIN
			SELECT MIN(t.tag_id) INTO v_tag_id
			  FROM v$tag t, tag_group_member tgm
			 WHERE t.app_sid = v_app_sid
			   AND t.tag_id = tgm.tag_id
			   AND tgm.tag_group_id = in_tag_group_id
			   AND t.tag = in_tag
			 ORDER BY t.tag_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_tag_id := NULL;
		END;
	ELSE -- v_tag_id is not NULL or -1
		BEGIN
			SELECT tag_id
			  INTO v_tag_id
			  FROM tag
			 WHERE app_sid = v_app_sid
			   AND tag_id = v_tag_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_tag_id := NULL;
		END;
	END IF;
	
	IF v_tag_id IS NULL THEN
		-- If we have an orphaned tag record (i.e. has no tag membership) that is the same as the incoming one, reuse it.
		SELECT MIN(t.tag_id)
		  INTO v_existing_tag_id
		  FROM tag t
		  LEFT JOIN tag_group_member tgm ON tgm.tag_id = t.tag_id AND tgm.tag_group_id = in_tag_group_id AND tgm.app_sid = v_app_sid
		 WHERE t.lookup_key = in_lookup_key
		   AND t.app_sid = v_app_sid
		   AND tgm.tag_group_id IS NULL;
		
		IF v_existing_tag_id IS NOT NULL THEN
			v_tag_id := v_existing_tag_id;
			UPDATE tag_description
			   SET tag = NVL(in_tag, 'Tag '||v_tag_id), explanation = in_explanation
			 WHERE tag_id = v_tag_id
			   AND lang = 'en';
		ELSE
			INSERT INTO tag (tag_id, lookup_key, parent_id)
			VALUES (tag_id_seq.nextval, in_lookup_key, v_parent_id)
			RETURNING tag_id into v_tag_id;
			
			INSERT INTO tag_description (tag_id, lang, tag, explanation)
			VALUES (v_tag_id, 'en', NVL(in_tag, 'Tag '||out_tag_id), in_explanation);
		END IF;

		INSERT INTO tag_group_member (tag_group_id, tag_id, pos, active)
		SELECT in_tag_group_id, v_tag_id, NVL(in_pos, NVL(MAX(POS),0)+1), in_active
		  FROM tag_group_member;
		
		out_tag_id := v_tag_id;
	ELSE
		UPDATE tag
		   SET lookup_key = in_lookup_key,
			   parent_id = v_parent_id
		 WHERE tag_id = v_tag_id;
		
		UPDATE tag_description
		   SET tag = NVL(in_tag, 'Tag '||v_tag_id), explanation = in_explanation
		 WHERE tag_id = v_tag_id
		   AND lang = 'en';
		
		BEGIN
			SELECT tag_id INTO v_tag_id FROM tag_group_member
			 WHERE tag_id = v_tag_id 
			   AND tag_group_id = in_tag_group_id
			FOR UPDATE;
			
			UPDATE tag_group_member
			   SET active = in_active
			 WHERE tag_id = v_tag_id 
			   AND tag_group_id = in_tag_group_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				INSERT INTO tag_group_member
					(tag_group_id, tag_id, pos, active)
				SELECT in_tag_group_id, v_tag_id, NVL(in_pos, NVL(MAX(POS),0)+1), in_active
				  FROM tag_group_member;
		END;
		
		IF in_pos IS NOT NULL THEN
			UPDATE tag_group_member
			   SET pos = in_pos, active = in_active
			 WHERE tag_id = v_tag_id 
			   AND tag_group_id = in_tag_group_id;
		END IF;
		
		out_tag_id := v_tag_id;
	END IF;
END;

PROCEDURE SetTagDescription(
	in_tag_id						IN	tag_description.tag_id%TYPE,
	in_langs						IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_descriptions					IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_explanations					IN	security.security_pkg.T_VARCHAR2_ARRAY
)
AS
	v_app				security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act				security_pkg.T_ACT_ID := security_pkg.GetACT;
	v_current_tag		tag_description.tag%TYPE;
	v_current_expl		tag_description.explanation%TYPE;
	v_action			VARCHAR2(50);
	v_target1			VARCHAR2(50);
	v_target2			VARCHAR2(50);
	v_targetseparator	VARCHAR2(50);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(v_act, v_app, csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	IF in_langs.COUNT != in_descriptions.COUNT AND in_langs.COUNT != in_explanations.COUNT THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_UNEXPECTED, 'Data mismatch');
	END IF;

	FOR i IN 1..in_langs.COUNT
	LOOP
		SetTagDescription(in_tag_id, in_langs(i), in_descriptions(i), in_explanations(i));
	END LOOP;
END;

PROCEDURE SetTagDescription(
	in_tag_id						IN	tag_description.tag_id%TYPE,
	in_lang							IN	tag_description.lang%TYPE,
	in_description					IN	tag_description.tag%TYPE,
	in_explanation					IN	tag_description.explanation%TYPE,
	in_set_tag						IN  NUMBER DEFAULT 1,
	in_set_explanation				IN  NUMBER DEFAULT 1
)
AS
	v_app				security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act				security_pkg.T_ACT_ID := security_pkg.GetACT;
	v_current_tag		tag_description.tag%TYPE;
	v_current_expl		tag_description.explanation%TYPE;
	v_action			VARCHAR2(50);
	v_target1			VARCHAR2(50);
	v_target2			VARCHAR2(50);
	v_targetseparator	VARCHAR2(50);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(v_act, v_app, csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	BEGIN
		SELECT tag, explanation
		  INTO v_current_tag, v_current_expl
		  FROM tag_description
		 WHERE app_sid = v_app
		   AND tag_id = in_tag_id
		   AND lang = in_lang;

		IF in_set_tag = 1 AND 
		   in_description IS NULL AND in_explanation IS NULL
		THEN
			DELETE FROM tag_description
			 WHERE app_sid = v_app
			   AND tag_id = in_tag_id
			   AND lang = in_lang;
			
			v_action := 'deleted';
		END IF;
		
		IF in_set_tag = 1 AND
		   in_description IS NOT NULL AND 
		   (v_current_tag IS NULL OR v_current_tag != in_description)
		THEN
			UPDATE tag_description
			   SET tag = in_description, last_changed_dtm = SYSDATE
			 WHERE app_sid = v_app
			   AND tag_id = in_tag_id
			   AND lang = in_lang;
			
			v_action := 'updated';
			v_target1 := 'name ';
		END IF;

		IF in_set_explanation = 1 AND 
		   in_explanation IS NOT NULL AND
		   (v_current_expl IS NULL OR v_current_expl != in_explanation)
		THEN
			UPDATE tag_description
			   SET explanation = in_explanation, last_changed_dtm = SYSDATE
			 WHERE app_sid = v_app
			   AND tag_id = in_tag_id
			   AND lang = in_lang;
			v_action := 'updated';
			v_target2 := 'explanation ';
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN 
			IF in_description IS NOT NULL THEN
				INSERT INTO tag_description (app_sid, tag_id, lang, tag, explanation, last_changed_dtm)
				VALUES (v_app, in_tag_id, in_lang, in_description, in_explanation, SYSDATE);
			
				v_action := 'created';
				v_target1 := 'name ';
			END IF;
	END;

	IF v_action IS NOT NULL THEN
		IF v_target1 IS NOT NULL AND v_target2 IS NOT NULL THEN
			v_targetseparator := 'and ';
		END IF;
		
		csr_data_pkg.WriteAuditLogEntry(
			v_act,
			csr_data_pkg.AUDIT_TYPE_TAG_DESC_CHANGED,
			v_app,
			NULL,
			'Tag Description '||v_target1||v_targetseparator||v_target2||v_action||' ('||in_tag_id||')',
			in_lang,
			v_current_tag,
			in_description,
			in_tag_id
			);
	END IF;
END;

PROCEDURE SetTagDescriptionTag(
	in_tag_id						IN	tag_description.tag_id%TYPE,
	in_lang							IN	tag_description.lang%TYPE,
	in_description					IN	tag_description.tag%TYPE
)
AS
BEGIN
	SetTagDescription(in_tag_id, in_lang, in_description, NULL, 1, 0);
END;

PROCEDURE SetTagDescriptionExplanation(
	in_tag_id						IN	tag_description.tag_id%TYPE,
	in_lang							IN	tag_description.lang%TYPE,
	in_description					IN	tag_description.explanation%TYPE
)
AS
BEGIN
	SetTagDescription(in_tag_id, in_lang, NULL, in_description, 0, 1);
END;

PROCEDURE RemoveTagFromGroup(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_tag_group_id	IN	tag_group.tag_group_id%TYPE,
	in_tag_id				IN	tag.tag_id%TYPE
)
AS
	v_in_use	NUMBER(10);
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT app_sid INTO v_app_sid FROM tag_group WHERE tag_group_id = in_tag_group_id;

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_app_sid,  csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	FOR r IN (
		SELECT tag_id
		  FROM tag
		 WHERE parent_id = in_tag_id
	)
	LOOP
		RemoveTagFromGroup(
			in_act_id => in_act_id,
			in_tag_group_id => in_tag_group_id,
			in_tag_id => r.tag_id
		);
	END LOOP;

/*
	-- check to see if tag is in use for this tag_group_id
	SELECT COUNT(*) INTO v_in_use
	  FROM TASK t, TASK_TAG tt, project_tag_group ptg
	 WHERE tt.tag_id = in_tag_id	-- donations where tag is in use
	   AND tt.task_sid = t.task_sid -- join to task
	   AND t.project_sid = ptg.project_sid -- join to project_tag_group
	   AND ptg.tag_group_id = in_tag_group_id; -- in our tag group
	
	IF v_in_use > 0 THEN 
		RAISE_APPLICATION_ERROR(project_pkg.ERR_TAG_IN_USE, 'Tag in use');
	END IF;
*/
	DELETE FROM tag_group_member
	 WHERE tag_group_id = in_tag_group_id
	   AND tag_id = in_tag_id;
	
	SELECT COUNT(tag_group_id)
	  INTO v_in_use
	  FROM tag_group_member
	 WHERE tag_id = in_tag_id;
	
	IF v_in_use = 0 THEN
		DELETE FROM compliance_region_tag
		 WHERE tag_id = in_tag_id;
	END IF;
	
	-- try deleting the tag and any descriptions.
	BEGIN
		DELETE FROM tag_description
		 WHERE tag_id = in_tag_id;
		 
		DELETE FROM tag
		 WHERE tag_id = in_tag_id;
	EXCEPTION
		WHEN csr_data_pkg.CHILD_RECORD_FOUND THEN
			RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_VALUES_EXIST, 'Tag id '||in_tag_id||' in use');
	END;
END;

PROCEDURE GetIndTags(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_ind_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on ind '||in_ind_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT tgir.tag_group_id, tgir.pos, tgir.tag_id, tgir.tag, tgir.region_sid,
			   tgir.ind_sid, tgir.non_compliance_id, tg.name tag_group_name
		  FROM tag_group_ir_member tgir, v$tag_group tg 
		 WHERE tgir.ind_sid = in_ind_sid
		   AND tgir.tag_group_id = tg.tag_group_id
		 ORDER BY tgir.tag_group_id, tgir.pos, tgir.tag_id, LOWER(tg.name);
END;

PROCEDURE GetMultipleIndTags(
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_ind_sids						security.T_SID_TABLE;
	v_total_sids					NUMBER;
	v_readable_sids					NUMBER;
BEGIN
	v_ind_sids := security_pkg.SidArrayToTable(in_ind_sids);
	
	SELECT COUNT(DISTINCT column_value) total_sids
	  INTO v_total_sids
	  FROM TABLE(v_ind_sids);

	SELECT COUNT(DISTINCT sid_id) readable_sids
	  INTO v_readable_sids
	  FROM TABLE(securableobject_pkg.GetSIDsWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'),
					v_ind_sids, security_pkg.PERMISSION_READ));

	IF v_total_sids != v_readable_sids THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on one or more indicators');
	END IF;

	OPEN out_cur FOR
		SELECT tgir.tag_group_id, tgir.pos, tgir.tag_id, tgir.tag, tgir.region_sid,
			   tgir.ind_sid, tgir.non_compliance_id, tg.name tag_group_name
		  FROM TABLE(v_ind_sids) i,
			   tag_group_ir_member tgir, v$tag_group tg
		 WHERE tgir.ind_sid = i.column_value
		   AND tgir.tag_group_id = tg.tag_group_id
		 ORDER BY tgir.tag_group_id, tgir.pos, tgir.tag_id, LOWER(tg.name);
END;

PROCEDURE Internal_AuditIndTag(
	in_ind_sid		IN	security_pkg.T_SID_ID,
	in_tag_id		IN	IND_TAG.tag_id%TYPE,
	in_audit_action	IN  CHAR
)
AS	
	v_tag_name			tag_description.tag%TYPE;
	v_tag_group_name	tag_group_description.name%TYPE := '<None>';
BEGIN
	SELECT tag
	  INTO v_tag_name
	  FROM v$tag
	 WHERE tag_id = in_tag_id;

	BEGIN
		SELECT name
		  INTO v_tag_group_name
		  FROM v$tag_group
		 WHERE tag_group_id = (
			SELECT tag_group_id
			  FROM tag_group_member
			 WHERE tag_id = in_tag_id
		);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN NULL;
	END;

	csr_data_pkg.WriteAuditLogEntry(
			security_pkg.GetACT,
			csr_data_pkg.AUDIT_TYPE_IND_TAG_CHANGED,
			security_pkg.GetAPP,
			in_ind_sid,
			CASE in_audit_action
				WHEN 'D' THEN 'Deleted {0} / {1}'
				WHEN 'I' THEN 'Added {0} / {1}'
			END,
			v_tag_group_name,
			v_tag_name
	);
END;

PROCEDURE SetIndTags(
	in_act_id	IN	security_pkg.T_ACT_ID,
	in_ind_sid	IN	security_pkg.T_SID_ID,
	in_set_tag_ids	IN	security_pkg.T_SID_IDS
)
AS
	v_app_sid	security_pkg.T_SID_ID;	
	v_current_tag_ids	security_pkg.T_SID_IDS;
BEGIN
	SELECT app_sid 
	  INTO v_app_sid
	  FROM ind
	 WHERE ind_sid = in_ind_sid;

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_ind_sid, csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	--Add current tag_ids into an associative array
	FOR r IN (
		SELECT tag_id
		  FROM IND_TAG
		 WHERE IND_SID = in_ind_sid
	)	
	LOOP
		v_current_tag_ids(r.tag_id) := r.tag_id;--The v_current_tag_ids is going to be sparse when iterating
	END LOOP;	

	-- hack for ODP.NET which doesn't support empty arrays
	IF NOT (in_set_tag_ids.COUNT = 1 AND in_set_tag_ids(1) IS NULL) THEN
		IF in_set_tag_ids.COUNT>0 THEN
			FOR i IN in_set_tag_ids.FIRST..in_set_tag_ids.LAST 	-- Go through each ID that we want to set
			LOOP
				IF  v_current_tag_ids.EXISTS(in_set_tag_ids(i)) THEN  --(this is a key exists, too pity that there is no check for value exists)
					-- remove from current_ids so we don't try to delete
					v_current_tag_ids.DELETE(in_set_tag_ids(i));					
				ELSE
					-- insert and audit 
					INSERT INTO IND_TAG
						(ind_sid, tag_id)
					VALUES
						(in_ind_sid, in_set_tag_ids(i));			
					--log record		
					Internal_AuditIndTag(in_ind_sid, in_set_tag_ids(i), 'I');					
				END IF;
			END LOOP;
		END IF;
	END IF;	
	
	--Delete and audit, v_current_tag_ids contains records marked for deletion. I can't use FORALL because I want to call Internal_AuditIndTag too
	IF v_current_tag_ids.COUNT>0 THEN
		FOR i IN v_current_tag_ids.FIRST..v_current_tag_ids.LAST
		LOOP
			IF v_current_tag_ids.EXISTS(i) THEN --Remember the v_current_tag_ids is sparse
				DELETE FROM IND_TAG			  
				 WHERE IND_SID = in_ind_sid
				   AND tag_id = v_current_tag_ids(i);			
				--log record
				Internal_AuditIndTag(in_ind_sid, v_current_tag_ids(i), 'D');
			END IF;
		END LOOP;
	END IF;
END;

PROCEDURE RemoveIndicatorTag(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_tag_id			IN	NUMBER,
	out_rows_updated	OUT	NUMBER
)
AS
BEGIN
	DELETE FROM ind_tag
	 WHERE ind_sid = in_ind_sid
	   AND tag_id = in_tag_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	out_rows_updated := SQL%ROWCOUNT;
	
	IF out_rows_updated > 0 THEN
		Internal_AuditIndTag(in_ind_sid, in_tag_id, 'D');
	END IF;
	
END;

PROCEDURE RemoveIndicatorTagGroup(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_tag_group_id		IN	NUMBER,
	out_rows_updated	OUT	NUMBER
)
AS
BEGIN
	FOR r IN (
		SELECT tag_id 
		  FROM ind_tag
		 WHERE ind_sid = in_ind_sid
		   AND tag_id IN (
				SELECT tag_id 
				  FROM tag_group_member 
				 WHERE tag_group_id = in_tag_group_id
				   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   )
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	)
	LOOP
		Internal_AuditIndTag(in_ind_sid, r.tag_id, 'D');
	END LOOP;
	
	DELETE
	  FROM ind_tag
	 WHERE ind_sid = in_ind_sid
	   AND tag_id IN (
			SELECT tag_id 
			  FROM tag_group_member 
			 WHERE tag_group_id = in_tag_group_id
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   )
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	out_rows_updated := SQL%ROWCOUNT;
	
END;

--Its functionality plus auditing merged with the above one
/*
PROCEDURE SetIndTags(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_ind_sid		IN	security_pkg.T_SID_ID,
	in_tag_ids			IN	security_pkg.T_SID_IDS -- they're not sids, but it'll do
)
AS
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT app_sid 
	  INTO v_app_sid
	  FROM ind
	 WHERE ind_sid = in_ind_sid;
	 
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_ind_sid, csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	DELETE FROM IND_TAG
	 WHERE IND_SID = in_ind_sid;
	
    -- crap hack for ODP.NET
    IF in_tag_ids.COUNT = 1 AND in_tag_ids(1) IS NULL THEN
        NULL; -- collection is null by default
    ELSE
        FORALL i IN in_tag_ids.FIRST..in_tag_ids.LAST
            INSERT INTO IND_TAG
                (ind_sid, tag_id)
            VALUES
                (in_ind_sid, in_tag_ids(i));	 		 
    END IF;	     
END;
*/

PROCEDURE GetRegionTags(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_region_sid					IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_Pkg.PERMISSION_READ) THEN
		-- Leak no data but throw no error (return empty cursor)
		-- 	RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to region ' || in_region_sid);
		OPEN out_cur FOR
			SELECT tgir.tag_group_id, tgir.tag_id, tgir.pos, tgir.tag, tgir.region_sid,
			       tgir.ind_sid, tgir.non_compliance_id, tg.name tag_group_name
			  FROM tag_group_ir_member tgir, v$tag_group tg 
			 WHERE 0 = 1;
	ELSE
		OPEN out_cur FOR
			SELECT tgir.tag_group_id, tgir.tag_id, tgir.pos, tgir.tag, tgir.region_sid,
			       tgir.ind_sid, tgir.non_compliance_id, tg.name tag_group_name
			  FROM tag_group_ir_member tgir, v$tag_group tg 
			 WHERE tgir.region_sid = in_region_sid
			   AND tgir.tag_group_id = tg.tag_group_id
			 ORDER BY tgir.TAG_GROUP_ID;
	END IF;
END;

PROCEDURE GetMultipleRegionTags(
	in_region_sids					IN	security_pkg.T_SID_IDS,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_region_sids					security.T_SID_TABLE;
BEGIN
	v_region_sids := security_pkg.SidArrayToTable(in_region_sids);

	-- as for GetRegionTags -- return tags for regions, but only where read permission is granted
	-- if read permission is denied then no tag information is returned and no error is reported
	-- this seems a bit odd, but I'm keeping the existing behaviour for now
	OPEN out_cur FOR
		SELECT tgir.tag_group_id, tgir.pos, tgir.tag_id, tgir.tag, tgir.region_sid,
			   tgir.ind_sid, tgir.non_compliance_id, tg.name tag_group_name, tg.lookup_key
		  FROM TABLE(securableobject_pkg.GetSIDsWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), 
						v_region_sids, security_pkg.PERMISSION_READ)) r,
			   tag_group_ir_member tgir, v$tag_group tg
		 WHERE tgir.region_sid = r.sid_id
		   AND tgir.tag_group_id = tg.tag_group_id
		 ORDER BY tgir.tag_group_id;
END;

PROCEDURE UNSEC_GetRegionTags(
	in_id_list						IN  security.T_ORDERED_SID_TABLE,
	out_tags_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_tags_cur FOR
		SELECT rt.region_sid, tg.tag_group_id, tg.name tag_group_name, t.tag_id, t.tag, tgm.pos
		  FROM TABLE(in_id_list) fil_list
		  JOIN region_tag rt ON fil_list.sid_id = rt.region_sid
		  JOIN tag_group_member tgm ON rt.tag_id = tgm.tag_id AND rt.app_sid = tgm.app_sid
		  JOIN v$tag t ON tgm.tag_id = t.tag_id AND tgm.app_sid = t.app_sid
		  JOIN v$tag_group tg ON tgm.tag_group_id = tg.tag_group_id AND tgm.app_sid = tg.app_sid
		 WHERE tg.applies_to_regions = 1
		 ORDER BY tgm.tag_group_id, tgm.pos;
END;

PROCEDURE INTERNAL_DeleteRegionTags(
	in_region_sid		IN	security_pkg.T_SID_ID
)
AS
	v_current_tags		NUMBER;
BEGIN
	DELETE FROM region_tag
	 WHERE region_sid = in_region_sid;
END;

PROCEDURE INTERNAL_GetAuditRegTagChgs(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_tag_ids			IN	VARCHAR2,
	out_added_tags		OUT	SYS_REFCURSOR,
	out_removed_tags	OUT	SYS_REFCURSOR
)
AS
	v_app_sid			security_pkg.T_SID_ID;
	v_current_tags  	security.T_SID_TABLE := security.T_SID_TABLE();
	v_index 			NUMBER;
	v_input_tags  		security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	SELECT app_sid 
	  INTO v_app_sid
	  FROM csr.region
	 WHERE region_sid = in_region_sid;
	 
	v_index := 1;
	FOR r IN (
		SELECT tag_id
		  FROM csr.region_tag
		 WHERE region_sid = in_region_sid
	) LOOP
		v_current_tags.Extend(1);
		v_current_tags(v_index) := r.tag_id;
		v_index := v_index + 1;
	END LOOP;
   
	v_index := 1;
	FOR r IN (
		SELECT t.item tag_id
		  FROM TABLE(csr.utils_pkg.splitstring(in_tag_ids,',')) t
	) LOOP
		v_input_tags.Extend(1);
		v_input_tags(v_index) := r.tag_id;
		v_index := v_index + 1;
	END LOOP;
  
	OPEN out_added_tags FOR
		SELECT column_value tag_id from TABLE(v_input_tags) MINUS SELECT column_value from TABLE(v_current_tags);
	
	OPEN out_removed_tags FOR
		SELECT column_value tag_id from TABLE(v_current_tags) MINUS SELECT column_value from TABLE(v_input_tags);
END;

PROCEDURE INTERNAL_AuditRegionTagChanges(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_added_tags		IN	SYS_REFCURSOR,
	in_removed_tags		IN	SYS_REFCURSOR
)
AS
	v_tag_id 			NUMBER;
BEGIN
	LOOP
		FETCH in_added_tags INTO v_tag_id;
		EXIT WHEN in_added_tags%NOTFOUND;
		INTERNAL_RegionTagChangeAudit(in_region_sid, v_tag_id, 'Added "{1}" to category "{0}"');
	END LOOP;	
	
	LOOP
		FETCH in_removed_tags INTO v_tag_id;
		EXIT WHEN in_removed_tags%NOTFOUND;
		INTERNAL_RegionTagChangeAudit(in_region_sid, v_tag_id, 'Removed "{1}" from category "{0}"');
	END LOOP;	
END;


PROCEDURE SetRegionTags(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_tag_ids			IN	VARCHAR2
)
AS
	v_app_sid			security_pkg.T_SID_ID;
	v_added_tags		SYS_REFCURSOR;
	v_removed_tags		SYS_REFCURSOR;
BEGIN
	SELECT app_sid 
	  INTO v_app_sid
	  FROM region
	 WHERE region_sid = in_region_sid;
	 
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, csr_data_Pkg.PERMISSION_ALTER_SCHEMA) AND NOT csr_data_pkg.CheckCapability('Edit region categories') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	INTERNAL_GetAuditRegTagChgs(in_region_sid, in_tag_ids, v_added_tags, v_removed_tags);
	
	INTERNAL_DeleteRegionTags(in_region_sid);
	
	INSERT INTO region_tag (region_sid, tag_id)
		SELECT in_region_sid, t.item
		  FROM TABLE(csr.utils_pkg.splitstring(in_tag_ids,','))t;
	  
	-- Update any dynamic delegation plans that depend on this region
	region_pkg.ApplyDynamicPlans(in_region_sid, 'Region tags changed');

	
	FOR r IN (
		SELECT t.item tag_id
		  FROM TABLE(csr.utils_pkg.splitstring(in_tag_ids,',')) t
	) LOOP
		INTERNAL_AddCalcJobs(r.tag_id);
	END LOOP;
	
	INTERNAL_AuditRegionTagChanges(in_region_sid, v_added_tags, v_removed_tags);
END;

FUNCTION INTERNAL_GetTagList(
	in_tag_ids			IN	security_pkg.T_SID_IDS
) RETURN VARCHAR2
AS
	v_tag_ids 			VARCHAR2(2000);
BEGIN
	FOR i IN in_tag_ids.FIRST..in_tag_ids.LAST LOOP
		IF LENGTH(v_tag_ids) > 0 THEN
			v_tag_ids := v_tag_ids||',';
		END IF;
		v_tag_ids := v_tag_ids||in_tag_ids(i);
	END LOOP;
	RETURN v_tag_ids;
END;

PROCEDURE SetRegionTags(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_tag_ids			IN	security_pkg.T_SID_IDS -- they're not sids, but it'll do
)
AS
	v_app_sid			security_pkg.T_SID_ID;
	v_tag_ids 			VARCHAR2(2000);
	v_added_tags		SYS_REFCURSOR;
	v_removed_tags		SYS_REFCURSOR;
BEGIN
	SELECT app_sid 
	  INTO v_app_sid
	  FROM region
	 WHERE region_sid = in_region_sid;
	 
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	v_tag_ids := INTERNAL_GetTagList(in_tag_ids);
	
	INTERNAL_GetAuditRegTagChgs(in_region_sid, v_tag_ids, v_added_tags, v_removed_tags);

	INTERNAL_DeleteRegionTags(in_region_sid);

	-- crap hack for ODP.NET
    IF in_tag_ids.COUNT = 1 AND in_tag_ids(1) IS NULL THEN
        NULL; -- collection is null by default
    ELSE
        FOR i IN in_tag_ids.FIRST..in_tag_ids.LAST LOOP
            INSERT INTO region_TAG
                (region_sid, tag_id)
            VALUES
                (in_region_sid, in_tag_ids(i));
                
			INTERNAL_AddCalcJobs(in_tag_ids(i));
        END LOOP;
    END IF;	     

	INTERNAL_AuditRegionTagChanges(in_region_sid, v_added_tags, v_removed_tags);

	region_pkg.ApplyDynamicPlans(in_region_sid, 'Region tags changed');
END;

-- Fast because it skips auditing when there is presence of prior auditing (?).
-- Currently used by Heineken (SPM), NetworkRail.
PROCEDURE SetRegionTagsFast(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_tag_ids			IN	security_pkg.T_SID_IDS -- they're not sids, but it'll do
)
AS
	v_app_sid			security_pkg.T_SID_ID;
	v_audit_logs		NUMBER;
	v_tag_ids 			VARCHAR2(2000);
	v_added_tags		SYS_REFCURSOR;
	v_removed_tags		SYS_REFCURSOR;
BEGIN
	SELECT app_sid 
	  INTO v_app_sid
	  FROM region
	 WHERE region_sid = in_region_sid;
	 
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_audit_logs
	  FROM audit_log
	 WHERE object_sid = in_region_sid;

	--useful for testing
	--v_audit_logs:=1;
	
	IF v_audit_logs = 1 THEN
		v_tag_ids := INTERNAL_GetTagList(in_tag_ids);
		INTERNAL_GetAuditRegTagChgs(in_region_sid, v_tag_ids, v_added_tags, v_removed_tags);
	END IF;

	INTERNAL_DeleteRegionTags(in_region_sid);
	
	-- crap hack for ODP.NET
	IF in_tag_ids.COUNT = 1 AND in_tag_ids(1) IS NULL THEN
		NULL; -- collection is null by default
	ELSE
		FOR i IN in_tag_ids.FIRST..in_tag_ids.LAST LOOP
			INSERT INTO region_TAG
				(region_sid, tag_id)
			VALUES
				(in_region_sid, in_tag_ids(i));
			
			INTERNAL_AddCalcJobs(in_tag_ids(i));
		END LOOP;
	END IF;

	IF v_audit_logs = 1 THEN
		INTERNAL_AuditRegionTagChanges(in_region_sid, v_added_tags, v_removed_tags);
	END IF;
END;

PROCEDURE RemoveRegionTag(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_tag_id				IN	NUMBER,
	in_apply_dynamic_plans	IN	NUMBER DEFAULT 1,
	out_rows_updated		OUT	NUMBER
)
AS
	v_added_tags		SYS_REFCURSOR;
	v_removed_tags		SYS_REFCURSOR;
BEGIN

	-- Get an empty cursor for added tags, as we're not adding any.
	OPEN v_added_tags FOR
		SELECT NULL tag_id
		  FROM DUAL
		 WHERE 0 = 1;
	
	OPEN v_removed_tags FOR
		SELECT in_tag_id
		  FROM region_tag
		 WHERE tag_id = in_tag_id
		   AND region_sid = in_region_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	DELETE
	  FROM region_tag
	 WHERE region_sid = in_region_sid
	   AND tag_id = in_tag_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	out_rows_updated := SQL%ROWCOUNT;

	IF in_apply_dynamic_plans = 1 THEN
		-- Update any dynamic delegation plans that depend on this region
		region_pkg.ApplyDynamicPlans(in_region_sid, 'Region tags changed');
	END IF;

	FOR r IN (
		SELECT tag_id
		  FROM region_tag
		 WHERE region_sid = in_region_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	) LOOP
		INTERNAL_AddCalcJobs(r.tag_id);
	END LOOP;

	INTERNAL_AuditRegionTagChanges(in_region_sid, v_added_tags, v_removed_tags);
END;

PROCEDURE RemoveRegionTagGroup(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_tag_group_id			IN	NUMBER,
	in_apply_dynamic_plans	IN	NUMBER DEFAULT 1,
	out_rows_updated		OUT	NUMBER
)
AS
	v_added_tags		SYS_REFCURSOR;
	v_removed_tags		SYS_REFCURSOR;
BEGIN
	
	-- Get an empty cursor for added tags, as we're not adding any.
	OPEN v_added_tags FOR
		SELECT NULL tag_id
		  FROM DUAL
		 WHERE 0 = 1;
	
	OPEN v_removed_tags FOR
		SELECT tag_id 
		  FROM region_tag
		 WHERE region_sid = in_region_sid
		   AND tag_id IN (
				SELECT tag_id 
				  FROM tag_group_member 
				 WHERE tag_group_id = in_tag_group_id
				   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   )
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	DELETE
	  FROM region_tag
	 WHERE region_sid = in_region_sid
	   AND tag_id IN (
			SELECT tag_id 
			  FROM tag_group_member 
			 WHERE tag_group_id = in_tag_group_id
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   )
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	out_rows_updated := SQL%ROWCOUNT;

	IF in_apply_dynamic_plans = 1 THEN 
		-- Update any dynamic delegation plans that depend on this region
		region_pkg.ApplyDynamicPlans(in_region_sid, 'Region tags changed');
	END IF;

	FOR r IN (
		SELECT tag_id
		  FROM region_tag
		 WHERE region_sid = in_region_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	) LOOP
		INTERNAL_AddCalcJobs(r.tag_id);
	END LOOP;

	INTERNAL_AuditRegionTagChanges(in_region_sid, v_added_tags, v_removed_tags);
END;

PROCEDURE GetNonComplianceTags(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_non_compliance_id	IN	non_compliance.non_compliance_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	audit_pkg.CheckNonComplianceAccess(in_non_compliance_id, security_pkg.PERMISSION_READ, 'Access denied reading tags on non-compliance with id: '||in_non_compliance_id);
	audit_pkg.CheckNonComplianceTagAccess(in_non_compliance_id, security_pkg.PERMISSION_READ, 'Access denined reading tags to non-compliance with id: '||in_non_compliance_id);
	
	OPEN out_cur FOR
		SELECT tgir.*, tg.name tag_group_name
		  FROM tag_group_ir_member tgir, v$tag_group tg 
		 WHERE non_compliance_id = in_non_compliance_id
		   AND tgir.tag_group_id = tg.tag_group_id
		 ORDER BY tgir.tag_group_id;
END;

PROCEDURE SetNonComplianceTags(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_non_compliance_id	IN	non_compliance.non_compliance_id%TYPE,
	in_tag_ids				IN	VARCHAR2
)
AS
	v_app_sid			security_pkg.T_SID_ID;
BEGIN
	audit_pkg.CheckNonComplianceAccess(in_non_compliance_id, security_pkg.PERMISSION_WRITE, 'Access denied setting tags to non-compliance with id: '||in_non_compliance_id);
	audit_pkg.CheckNonComplianceTagAccess(in_non_compliance_id, security_pkg.PERMISSION_WRITE, 'Access denined setting tags to non-compliance with id: '||in_non_compliance_id);
	
	/* check it's valid for non-compliances? */
	DELETE FROM non_compliance_tag
	 WHERE non_compliance_id = in_non_compliance_id;
	 
	INSERT INTO non_compliance_tag
		(non_compliance_id, tag_id)
	SELECT in_non_compliance_id, t.item
	  FROM TABLE(CSR.UTILS_PKG.SPLITSTRING(in_tag_ids,','))t;
END;

PROCEDURE SetNonComplianceTags(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_non_compliance_id	IN	non_compliance.non_compliance_id%TYPE,
	in_tag_ids				IN	security_pkg.T_SID_IDS -- they're not sids, but it'll do
)
AS
	v_app_sid			security_pkg.T_SID_ID;
BEGIN
	audit_pkg.CheckNonComplianceAccess(in_non_compliance_id, security_pkg.PERMISSION_WRITE, 'Access denied setting tags to non-compliance with id: '||in_non_compliance_id);
	audit_pkg.CheckNonComplianceTagAccess(in_non_compliance_id, security_pkg.PERMISSION_WRITE, 'Access denined setting tags to non-compliance with id: '||in_non_compliance_id);
	
	/* check it's valid for non-compliances? */
	DELETE FROM non_compliance_tag
	 WHERE non_compliance_id = in_non_compliance_id;
	
	-- crap hack for ODP.NET
	IF in_tag_ids.COUNT = 1 AND in_tag_ids(1) IS NULL THEN
		NULL; -- collection is null by default
	ELSE
		FORALL i IN in_tag_ids.FIRST..in_tag_ids.LAST
			INSERT INTO non_compliance_tag
				(non_compliance_id, tag_id)
			VALUES
				(in_non_compliance_id, in_tag_ids(i));
	END IF;
END;

-- only called by audit_pkg when copying default findings
PROCEDURE UNSEC_SetNonComplianceTags(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_non_compliance_id	IN	non_compliance.non_compliance_id%TYPE,
	in_tag_ids				IN	security_pkg.T_SID_IDS -- they're not sids, but it'll do
)
AS
	v_app_sid			security_pkg.T_SID_ID;
BEGIN
	/* check it's valid for non-compliances? */
	DELETE FROM non_compliance_tag
	 WHERE non_compliance_id = in_non_compliance_id;
	
	-- crap hack for ODP.NET
	IF in_tag_ids.COUNT = 1 AND in_tag_ids(1) IS NULL THEN
		NULL; -- collection is null by default
	ELSE
		FORALL i IN in_tag_ids.FIRST..in_tag_ids.LAST
			INSERT INTO non_compliance_tag
				(non_compliance_id, tag_id)
			VALUES
				(in_non_compliance_id, in_tag_ids(i));
	END IF;
END;

-- returns the tag groups this user can see 
PROCEDURE GetTagGroups(
	in_act_id		IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
	in_app_sid		IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
		SELECT tg.tag_group_id, tg.name, tg.mandatory, tg.multi_select, tg.applies_to_inds,
				tg.applies_to_regions, tg.applies_to_non_compliances, tg.applies_to_suppliers,
				tg.applies_to_chain, tg.applies_to_chain_activities, tg.applies_to_initiatives,
				tg.applies_to_chain_product_types, tg.applies_to_chain_products, tg.applies_to_chain_product_supps,
				tg.applies_to_quick_survey, tg.applies_to_audits, 
				tg.applies_to_compliances, tg.lookup_key, tg.is_hierarchical
		  FROM v$tag_group tg
		 WHERE tg.app_sid = in_app_sid
		 ORDER BY tg.name;
END;

-- returns the tag group descriptions
PROCEDURE GetTagGroupDescriptions(
	in_act_id		IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
	in_app_sid		IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetTagGroupDescriptions(
		in_act_id => in_act_id,
		in_app_sid => in_app_sid,
		in_tag_group_id => NULL,
		out_cur => out_cur);
END;

PROCEDURE GetTagGroupDescriptions(
	in_act_id		IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
	in_app_sid		IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	in_tag_group_id	IN	tag_group.tag_group_id%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
		SELECT tgd.tag_group_id, tgd.lang, tgd.name, tgd.last_changed_dtm
		  FROM tag_group_description tgd
		 WHERE tgd.app_sid = in_app_sid
		   AND tgd.tag_group_id = NVL(in_tag_group_id, tgd.tag_group_id)
		 ORDER BY tgd.tag_group_id, lang;
END;

-- returns basic details of specified tag_group 
PROCEDURE GetTagGroup(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_tag_name			IN	tag_group_description.name%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_tag_group_id		tag_group.tag_group_id%TYPE;
BEGIN
	SELECT tag_group_id
	  INTO v_tag_group_id
	  FROM v$tag_group
	 WHERE name = in_tag_name;
	
	GetTagGroup(in_act_id, v_tag_group_id, out_cur);
END;

-- returns basic details of specified tag_group 
PROCEDURE GetTagGroup(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_tag_group_id		IN	tag_group.tag_group_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT app_sid INTO v_app_sid FROM tag_group WHERE tag_group_id = in_tag_group_id;
	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT tag_group_id, name, lookup_key, mandatory, multi_select,
				applies_to_inds, applies_to_regions, applies_to_non_compliances, applies_to_suppliers,
				applies_to_chain, applies_to_chain_activities, applies_to_initiatives,
				applies_to_chain_product_types, applies_to_chain_products, applies_to_chain_product_supps,
				applies_to_quick_survey, applies_to_audits, applies_to_compliances, is_hierarchical
		  FROM v$tag_group
		 WHERE tag_group_id = in_tag_group_id;
END;

PROCEDURE GetTagGroupMembers(
	in_act_id					IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
	in_tag_group_id				IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT app_sid INTO v_app_sid FROM tag_group WHERE tag_group_id = in_tag_group_id;

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT t.tag_id, t.tag, t.explanation, tgm.pos, t.lookup_key, t.exclude_from_dataview_grouping, tgm.active, tgm.tag_group_id, t.parent_id
		  FROM tag_group_member tgm, v$tag t
		 WHERE tgm.tag_id = t.tag_id
		   AND tgm.tag_group_id = in_tag_group_id
		 ORDER BY pos;
END;

PROCEDURE GetTagGroupMembersByGroupLookup(
	in_tag_group_lookup			IN	tag_group.lookup_key%TYPE,
	out_tg_members				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_tag_group_id				tag_group.tag_group_id%TYPE;
BEGIN
	SELECT tag_group_id
	  INTO v_tag_group_id
	  FROM tag_group
	 WHERE lookup_key = in_tag_group_lookup;
	 
	GetTagGroupMembers(
		in_act_id => SYS_CONTEXT('SECURITY', 'ACT'),
		in_tag_group_id => v_tag_group_id,
		out_cur => out_tg_members
	);
END;

-- returns the tag descriptions
PROCEDURE GetTagGroupMemberDescriptions(
	in_act_id		IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
	in_app_sid		IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetTagGroupMemberDescriptions(
		in_act_id => in_act_id,
		in_app_sid => in_app_sid,
		in_tag_group_id => NULL,
		out_cur => out_cur);
END;

PROCEDURE GetTagGroupMemberDescriptions(
	in_act_id		IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
	in_app_sid		IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	in_tag_group_id	IN	tag_group.tag_group_id%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT td.tag_id, td.lang, td.tag, td.explanation, td.last_changed_dtm
		  FROM tag_group_member tgm
		  LEFT JOIN tag_description td ON td.TAG_ID = tgm.TAG_ID
		 WHERE td.app_sid = security.security_pkg.getapp
		   AND tgm.tag_group_id = NVL(in_tag_group_id, tgm.tag_group_id)
		 ORDER BY td.tag_id, lang;
END;

PROCEDURE GetAllTagGroupsAndMembers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
   		SELECT tg.tag_group_id, tg.name, tg.multi_select, tg.mandatory, tgm.tag_Id, tgm.pos, t.tag, t.explanation, t.lookup_key
		  FROM v$tag_group tg, tag_group_member tgm, v$tag t
		 WHERE tg.tag_group_id = tgm.tag_group_id(+)
		   AND tgm.tag_id = t.tag_id(+)
           AND tg.app_sid = in_app_sid 
		 ORDER BY tg.tag_group_id, tgm.pos, NLSSORT(t.tag, 'NLS_SORT=generic_m');
END;

PROCEDURE GetAllTagGroupsAndMembersInd(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
   		SELECT tg.tag_group_id, tg.name, tg.multi_select, tg.mandatory, tgm.tag_Id, tgm.pos, t.tag, t.explanation, 
        	CASE WHEN it.ind_sid IS NOT NULL THEN 1 ELSE 0 END selected
		  FROM v$tag_group tg, tag_group_member tgm, v$tag t, ind_tag it
		 WHERE tg.tag_group_id = tgm.tag_group_id
		   AND tgm.tag_id = t.tag_id
		   AND tg.applies_to_inds = 1
           AND tg.app_sid = in_app_sid
           AND it.tag_id(+) = tgm.tag_id
           AND it.ind_sid(+) = in_ind_sid
		 ORDER BY tg.tag_group_id, tgm.pos, NLSSORT(t.tag, 'NLS_SORT=generic_m');
END;

PROCEDURE GetAllTagGroupsAndMembersReg(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
   		SELECT tg.tag_group_id, tg.name, tg.multi_select, tg.mandatory, tgm.tag_id, tgm.pos, t.tag, t.explanation, 
        	   CASE WHEN rt.region_sid IS NOT NULL THEN 1 ELSE 0 END selected
		  FROM v$tag_group tg, tag_group_member tgm, v$tag t, region_tag rt
		 WHERE tg.tag_group_id = tgm.tag_group_id
		   AND tgm.tag_id = t.tag_id
		   AND applies_to_regions = 1
           AND tg.app_sid = in_app_sid
           AND rt.tag_id(+) = tgm.tag_id
           AND rt.region_sid(+) = in_region_sid
           AND tgm.active = 1
		 ORDER BY tg.tag_group_id, tgm.pos, NLSSORT(t.tag, 'NLS_SORT=generic_m');
END;

FUNCTION ConcatTagGroupMembers(
	in_tag_group_id		IN	tag_group.tag_group_id%TYPE,
	in_max_length			IN 	INTEGER
) RETURN VARCHAR2
AS
	v_s	VARCHAR2(512);
	v_sep VARCHAR2(10);
BEGIN
	v_s := '';
	v_sep := '';

	FOR r IN (
		SELECT tag
		  FROM tag_group_member tgm, v$tag t
		 WHERE tgm.tag_id = t.tag_id
		   AND tgm.tag_group_id = in_tag_group_id)
	LOOP
		IF LENGTH(v_s) + LENGTH(r.tag) + 3 >= in_max_length THEN
			v_s := v_s || '...';
			EXIT;
		END IF;
		v_s := v_s || v_sep || r.tag;
		v_sep := ', ';
	END LOOP;

	RETURN v_s;
END;

PROCEDURE GetTagGroupsSummary(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT tag_group_id, name,
			(SELECT count(*) FROM tag_group_member tgm WHERE tag_group_id = tg.tag_group_id) member_count,
		    tag_pkg.ConcatTagGroupMembers(tg.tag_group_id, 30) MEMBERS
		  FROM v$tag_group tg
		 WHERE app_sid = in_app_sid;
END;

PROCEDURE GetTagGroupRegionMembers(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_tag_group_id	IN	tag_group.tag_group_id%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ r.region_sid, r.name, r.description, r.parent_sid, r.pos, r.info_xml,
			   r.active, r.link_to_region_sid, t.tag, t.tag_id
		  FROM tag_group_member tgm, region_tag rt, v$tag t, v$region r 
		 WHERE tgm.tag_group_id = in_tag_group_id AND tgm.tag_id = rt.tag_id AND tgm.tag_id = t.tag_id AND 
		 	   rt.tag_id = t.tag_id AND rt.region_sid = r.region_sid
		 ORDER BY r.region_sid, t.tag;
END;

PROCEDURE GetTagGroupIndMembers(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_tag_group_id	IN	tag_group.tag_group_id%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ i.ind_sid, i.name, i.description, i.parent_sid, i.pos, i.active,
			   t.tag, t.tag_id
		  FROM tag_group_member tgm, ind_tag it, v$tag t, v$ind i 
		 WHERE tgm.tag_group_id = in_tag_group_id AND tgm.tag_id = it.tag_id AND tgm.tag_id = t.tag_id AND
		 	   it.tag_id = t.tag_id AND it.ind_sid = i.ind_sid
		 ORDER BY i.ind_sid, t.tag;
END;

PROCEDURE GetTagGroupNCMembers(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_tag_group_id	IN	tag_group.tag_group_id%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ nc.non_compliance_id, nc.label, nc.detail,
			   t.tag, t.tag_id
		  FROM tag_group_member tgm, non_compliance_tag nct, v$tag t, non_compliance nc
		 WHERE tgm.tag_group_id = in_tag_group_id AND tgm.tag_id = nct.tag_id AND tgm.tag_id = t.tag_id AND
		 	   nct.tag_id = t.tag_id AND nct.non_compliance_id = nc.non_compliance_id
		 ORDER BY nc.non_compliance_id, t.tag;
END;

PROCEDURE DeactivateTag(
	in_tag_id				IN	tag.tag_id%TYPE,
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE
)
AS
BEGIN
	-- XXX: no security!
	
	UPDATE tag_group_member
	   SET active = 0
	 WHERE tag_id = in_tag_id
	   AND tag_group_id = in_tag_group_id;
END;

PROCEDURE ActivateTag(
	in_tag_id				IN	tag.tag_id%TYPE,
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE
)
AS
BEGIN
	-- XXX: no security!
	
	UPDATE tag_group_member
	   SET active = 1
	 WHERE tag_id = in_tag_id
	   AND tag_group_id = in_tag_group_id;
END;

PROCEDURE GetTag(
	in_tag_id						IN	tag.tag_id%TYPE,
	out_tag_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- bit pointless?
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_tag_cur FOR
		SELECT t.tag, t.explanation, t.lookup_key, tgm.tag_group_id, t.parent_id
		  FROM v$tag t
		  JOIN tag_group_member tgm ON tgm.tag_id = t.tag_id
		 WHERE t.tag_id = in_tag_id;
END;

PROCEDURE GetTagGroupRegionTypes(
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT rttg.tag_group_id, rttg.region_type, rt.label region_type_label
		  FROM region_type_tag_group rttg
		  JOIN region_type rt on rt.region_type = rttg.region_type
		 WHERE rttg.tag_group_id = in_tag_group_id;
END;

PROCEDURE GetTagGroupInternalAuditTypes(
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT iattg.tag_group_id, iattg.internal_audit_type_id, iat.label, iat.lookup_key, iat.flow_sid, iat.tab_sid, iat.active
		  FROM internal_audit_type_tag_group iattg
		  JOIN internal_audit_type iat on iattg.internal_audit_type_id = iat.internal_audit_type_id
		 WHERE iattg.tag_group_id = in_tag_group_id;
END;

PROCEDURE GetTagGroupNCTypes(
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT ncttg.tag_group_id, ncttg.non_compliance_type_id, nct.label, nct.lookup_key
		  FROM non_compliance_type_tag_group ncttg
		  JOIN non_compliance_type nct on nct.non_compliance_type_id = ncttg.non_compliance_type_id
		 WHERE ncttg.tag_group_id = in_tag_group_id;
END;


PROCEDURE GetTagGroupCompanyTypes(
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT cttg.tag_group_id, cttg.company_type_id, ct.singular, ct.plural, ct.is_default, ct.is_top_company, ct.lookup_key
		  FROM chain.company_type_tag_group cttg
		  JOIN chain.company_type ct on ct.company_type_id = cttg.company_type_id
		 WHERE cttg.tag_group_id = in_tag_group_id;
END;

PROCEDURE GetTagGroupInitiativeTypes(
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT pttg.tag_group_id, pttg.project_sid, ip.name
		  FROM project_tag_group pttg
		  JOIN initiative_project ip on pttg.project_sid = ip.project_sid
		 WHERE pttg.tag_group_id = in_tag_group_id;
END;

PROCEDURE GetAllTagGroups (
	out_tag_group_cur		OUT	SYS_REFCURSOR,
	out_tag_group_text_cur	OUT	SYS_REFCURSOR,
	out_tag_cur				OUT	SYS_REFCURSOR,
	out_tag_text_cur		OUT	SYS_REFCURSOR,
	out_region_types_cur	OUT	SYS_REFCURSOR,
	out_audit_types_cur		OUT	SYS_REFCURSOR,
	out_company_types_cur	OUT	SYS_REFCURSOR,
	out_non_compl_types_cur	OUT	SYS_REFCURSOR
)
AS
	v_act_id				security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_app_sid				security_pkg.T_SID_ID := security_pkg.GetApp;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, v_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_tag_group_cur FOR
		SELECT tag_group_id, lookup_key, mandatory, multi_select, applies_to_inds,
			   applies_to_regions, applies_to_non_compliances, applies_to_suppliers,
			   applies_to_chain, applies_to_initiatives, applies_to_chain_activities,
			   applies_to_chain_product_types, applies_to_chain_products, applies_to_chain_product_supps,
			   applies_to_quick_survey, applies_to_audits, applies_to_compliances, is_hierarchical
		  FROM tag_group
		 WHERE app_sid = v_app_sid;
	
	OPEN out_tag_group_text_cur FOR
		SELECT tag_group_id, 'default' AS lang, name
		  FROM v$tag_group
		 WHERE app_sid = v_app_sid;
	
	OPEN out_tag_cur FOR
		SELECT tgm.tag_group_id, tgm.tag_id, tgm.pos, tgm.active, t.lookup_key, t.parent_id
		  FROM tag_group_member tgm
		  JOIN tag t ON tgm.app_sid = t.app_sid AND tgm.tag_id = t.tag_id
		 WHERE tgm.app_sid = v_app_sid;
	
	OPEN out_tag_text_cur FOR
		SELECT tag_id, 'default' AS lang, tag, explanation
		  FROM v$tag
		 WHERE app_sid = v_app_sid;
	
	OPEN out_region_types_cur FOR 
		SELECT tag_group_id, region_type
		  FROM region_type_tag_group
		 WHERE app_sid = v_app_sid;
	
	OPEN out_audit_types_cur FOR 
		SELECT tag_group_id, internal_audit_type_id
		  FROM internal_audit_type_tag_group
		 WHERE app_sid = v_app_sid;
	
	OPEN out_company_types_cur FOR 
		SELECT tag_group_id, company_type_id
		  FROM chain.company_type_tag_group
		 WHERE app_sid = v_app_sid;
	
	OPEN out_non_compl_types_cur FOR 
		SELECT tag_group_id, non_compliance_type_id
		  FROM non_compliance_type_tag_group
		 WHERE app_sid = v_app_sid;
END;

PROCEDURE GetAllCatTranslations(
	in_validation_lang		IN	tag_group_description.lang%TYPE,
	in_changed_since		IN	DATE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_app_sid					security.security_pkg.T_SID_ID := security_pkg.GetApp;
BEGIN
	OPEN out_cur FOR
		SELECT tgd.tag_group_id sid, tgd.name description, tgd.lang,
			   CASE WHEN tgd.last_changed_dtm > in_changed_since THEN 1 ELSE 0 END has_changed
		  FROM tag_group_description tgd
		  JOIN aspen2.translation_set ts ON v_app_sid = ts.application_sid
		 WHERE ts.lang = tgd.lang
		 ORDER BY 
			   CASE WHEN ts.lang = NVL(in_validation_lang, 'en') THEN 0 ELSE 1 END,
			   LOWER(ts.lang);
END;

PROCEDURE ValidateCatTranslations(
	in_tag_group_ids		IN	security.security_pkg.T_SID_IDS,
	in_descriptions			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_validation_lang		IN	tag_group_description.lang%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_app_sid				security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act					security_pkg.T_ACT_ID := security_pkg.GetACT;
	v_tg_id_desc_tbl		T_SID_AND_DESCRIPTION_TABLE := T_SID_AND_DESCRIPTION_TABLE();
BEGIN
	IF in_tag_group_ids.COUNT != in_descriptions.COUNT THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_ARRAY_SIZE_MISMATCH, 'Number of ids do not match number of descriptions.');
	END IF;
	
	IF in_tag_group_ids.COUNT = 0 THEN
		RETURN;
	END IF;

	v_tg_id_desc_tbl.EXTEND(in_tag_group_ids.COUNT);

	FOR i IN 1..in_tag_group_ids.COUNT
	LOOP
		v_tg_id_desc_tbl(i) := T_SID_AND_DESCRIPTION_ROW(i, in_tag_group_ids(i), in_descriptions(i));
	END LOOP;

	OPEN out_cur FOR
		SELECT tgd.tag_group_id sid,
			   CASE tgd.name WHEN tgt.description THEN 0 ELSE 1 END has_changed,
			   security_pkg.SQL_IsAccessAllowedSID(v_act, v_app_sid, security_pkg.PERMISSION_WRITE) can_write
		  FROM tag_group_description tgd
		  JOIN TABLE(v_tg_id_desc_tbl) tgt ON tgd.tag_group_id = tgt.sid_id
		 WHERE app_sid = v_app_sid
		   AND lang = in_validation_lang;
END;

PROCEDURE GetAllTagTranslations(
	in_validation_lang		IN	tag_description.lang%TYPE,
	in_changed_since		IN	DATE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_app_sid					security.security_pkg.T_SID_ID := security_pkg.GetApp;
BEGIN
	OPEN out_cur FOR
		SELECT td.tag_id sid, td.tag description, td.lang,
			   CASE WHEN td.last_changed_dtm > in_changed_since THEN 1 ELSE 0 END has_changed
		  FROM tag_description td
		  JOIN aspen2.translation_set ts ON v_app_sid = ts.application_sid
		 WHERE ts.lang = td.lang
		 ORDER BY 
			   CASE WHEN ts.lang = NVL(in_validation_lang, 'en') THEN 0 ELSE 1 END,
			   LOWER(ts.lang);
END;

PROCEDURE GetAllTagExplTranslations(
	in_validation_lang		IN	tag_description.lang%TYPE,
	in_changed_since		IN	DATE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_app_sid					security.security_pkg.T_SID_ID := security_pkg.GetApp;
BEGIN
	OPEN out_cur FOR
		SELECT td.tag_id sid, td.explanation description, td.lang,
			   CASE WHEN td.last_changed_dtm > in_changed_since THEN 1 ELSE 0 END has_changed
		  FROM tag_description td
		  JOIN aspen2.translation_set ts ON v_app_sid = ts.application_sid
		 WHERE ts.lang = td.lang
		 ORDER BY 
			   CASE WHEN ts.lang = NVL(in_validation_lang, 'en') THEN 0 ELSE 1 END,
			   LOWER(ts.lang);
END;

PROCEDURE ValidateTagTranslations(
	in_tag_ids				IN	security.security_pkg.T_SID_IDS,
	in_descriptions			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_validation_lang		IN	tag_description.lang%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_app_sid				security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act					security_pkg.T_ACT_ID := security_pkg.GetACT;
	v_t_id_desc_tbl			T_SID_AND_DESCRIPTION_TABLE := T_SID_AND_DESCRIPTION_TABLE();
BEGIN
	IF in_tag_ids.COUNT != in_descriptions.COUNT THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_ARRAY_SIZE_MISMATCH, 'Number of ids do not match number of descriptions.');
	END IF;
	
	IF in_tag_ids.COUNT = 0 THEN
		RETURN;
	END IF;

	v_t_id_desc_tbl.EXTEND(in_tag_ids.COUNT);

	FOR i IN 1..in_tag_ids.COUNT
	LOOP
		v_t_id_desc_tbl(i) := T_SID_AND_DESCRIPTION_ROW(i, in_tag_ids(i), in_descriptions(i));
	END LOOP;

	OPEN out_cur FOR
		SELECT td.tag_id sid,
			   CASE td.tag WHEN tgt.description THEN 0 ELSE 1 END has_changed,
			   security_pkg.SQL_IsAccessAllowedSID(v_act, v_app_sid, security_pkg.PERMISSION_WRITE) can_write
		  FROM tag_description td
		  JOIN TABLE(v_t_id_desc_tbl) tgt ON td.tag_id = tgt.sid_id
		 WHERE app_sid = v_app_sid
		   AND lang = in_validation_lang;
END;

PROCEDURE ValidateTagExplTranslations(
	in_tag_ids				IN	security.security_pkg.T_SID_IDS,
	in_descriptions			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_validation_lang		IN	tag_description.lang%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_app_sid				security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act					security_pkg.T_ACT_ID := security_pkg.GetACT;
	v_t_id_desc_tbl			T_SID_AND_DESCRIPTION_TABLE := T_SID_AND_DESCRIPTION_TABLE();
BEGIN
	IF in_tag_ids.COUNT != in_descriptions.COUNT THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_ARRAY_SIZE_MISMATCH, 'Number of ids do not match number of descriptions.');
	END IF;

	IF in_tag_ids.COUNT = 0 THEN
		RETURN;
	END IF;

	v_t_id_desc_tbl.EXTEND(in_tag_ids.COUNT);

	FOR i IN 1..in_tag_ids.COUNT
	LOOP
		v_t_id_desc_tbl(i) := T_SID_AND_DESCRIPTION_ROW(i, in_tag_ids(i), NVL(in_descriptions(i), 'NULL'));
	END LOOP;

	OPEN out_cur FOR
		SELECT td.tag_id sid,
			   CASE NVL(td.explanation, 'NULL') WHEN tgt.description THEN 0 ELSE 1 END has_changed,
			   security_pkg.SQL_IsAccessAllowedSID(v_act, v_app_sid, security_pkg.PERMISSION_WRITE) can_write
		  FROM tag_description td
		  JOIN TABLE(v_t_id_desc_tbl) tgt ON td.tag_id = tgt.sid_id
		 WHERE app_sid = v_app_sid
		   AND lang = in_validation_lang;
END;

PROCEDURE GetTagGroups(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_tag_group_cur				OUT	SYS_REFCURSOR,
	out_tag_group_tr_cur			OUT	SYS_REFCURSOR,
	out_tag_cur						OUT	SYS_REFCURSOR,
	out_tag_tr_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_tag_group_cur FOR
		SELECT tag_group_id, multi_select, applies_to_audits, applies_to_chain, applies_to_chain_activities, applies_to_chain_product_supps,
			   applies_to_chain_product_types, applies_to_chain_products, applies_to_compliances, applies_to_inds, applies_to_initiatives,
			   applies_to_non_compliances, applies_to_quick_survey, applies_to_regions, applies_to_suppliers
		  FROM tag_group
		 WHERE app_sid = in_app_sid;

	OPEN out_tag_group_tr_cur FOR
		SELECT tag_group_id, lang, name
		  FROM tag_group_description
		 WHERE app_sid = in_app_sid;

	OPEN out_tag_cur FOR
		SELECT tag_group_id, tag_id, pos, active
		  FROM tag_group_member
		 WHERE app_sid = in_app_sid;

	OPEN out_tag_tr_cur FOR
		SELECT tag_id, lang, tag
		  FROM tag_description
		 WHERE app_sid = in_app_sid;
END;

PROCEDURE GetTagFromLookup(
	in_lookup_key		IN	csr.tag.lookup_key%TYPE,
	out_tag_id			OUT	csr.tag.tag_id%TYPE
)
AS
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	UNSEC_GetTagFromLookup(
		in_lookup_key		=> in_lookup_key,
		out_tag_id			=> out_tag_id
	);

END;

PROCEDURE UNSEC_GetTagFromLookup(
	in_lookup_key		IN	csr.tag.lookup_key%TYPE,
	out_tag_id			OUT	csr.tag.tag_id%TYPE
)
AS
BEGIN

	SELECT tag_id
	  INTO out_tag_id
	  FROM csr.tag
	 WHERE LOWER(lookup_key) = LOWER(in_lookup_key)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetTagFromName(
	in_tag_name			IN	csr.tag_description.tag%TYPE,
	in_lang				IN	csr.tag_description.lang%TYPE  := 'en',
	out_tag_id			OUT	csr.tag.tag_id%TYPE
)
AS
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	UNSEC_GetTagFromName(
		in_tag_name			=> in_tag_name,
		in_lang				=> in_lang,
		out_tag_id			=> out_tag_id
	);

END;

PROCEDURE UNSEC_GetTagFromName(
	in_tag_name			IN	csr.tag_description.tag%TYPE,
	in_lang				IN	csr.tag_description.lang%TYPE  := 'en',
	out_tag_id			OUT	csr.tag.tag_id%TYPE
)
AS
BEGIN

	SELECT tag_id
	  INTO out_tag_id
	  FROM csr.tag_description
	 WHERE LOWER(tag) = LOWER(in_tag_name)
	   AND LOWER(lang) = LOWER(NVL(in_lang, 'en'))
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

END;
/
