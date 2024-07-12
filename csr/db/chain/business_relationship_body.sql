CREATE OR REPLACE PACKAGE BODY CHAIN.business_relationship_pkg
IS

PROCEDURE GetBusinessRelationshipTypes (
	out_bus_rel_type_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_tier_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_tier_comp_type_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_view_company_type_ids		security.T_SID_TABLE := type_capability_pkg.GetCapableCompanyTypeIds(chain_pkg.VIEW_BUSINESS_RELATIONSHIPS, chain_pkg.VIEW_BUS_REL_REVERSED);
	v_add_company_type_ids		security.T_SID_TABLE := type_capability_pkg.GetCapableCompanyTypeIds(chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS, chain_pkg.ADD_TO_BUS_REL_REVERSED);
	v_upd_company_type_ids		security.T_SID_TABLE := type_capability_pkg.GetCapableCompanyTypeIds(chain_pkg.UPDATE_BUSINESS_REL_PERIODS, chain_pkg.UPDATE_BUS_REL_PERDS_REVERSED);
BEGIN
	
	OPEN out_bus_rel_type_cur FOR
		SELECT business_relationship_type_id,
			   label,
			   form_path, tab_sid, column_sid,
			   use_specific_dates, period_set_id, period_interval_id
		  FROM business_relationship_type
		 ORDER BY label;

	OPEN out_bus_rel_tier_cur FOR
		SELECT business_relationship_type_id,
			   business_relationship_tier_id,
			   tier,
			   label,
			   direct_from_previous_tier,
			   create_supplier_relationship,
			   create_new_company,
			   allow_multiple_companies,
			   create_sup_rels_w_lower_tiers
		  FROM business_relationship_tier
		 ORDER BY tier;
		 
	OPEN out_bus_rel_tier_comp_type_cur FOR
		SELECT brt.business_relationship_type_id,
			   brtct.business_relationship_tier_id,
			   brtct.company_type_id,
			   CASE WHEN view_cts.column_value IS NOT NULL
				    THEN 1
					ELSE 0
			   END can_view,
			   CASE WHEN add_cts.column_value IS NOT NULL
				    THEN 1
					ELSE 0
			   END can_add,
			   CASE WHEN add_cts.column_value IS NOT NULL OR upd_cts.column_value IS NOT NULL
				    THEN 1
					ELSE 0
			   END can_update_periods
		  FROM business_rel_tier_company_type brtct
		  JOIN business_relationship_tier brt ON brt.business_relationship_tier_id = brtct.business_relationship_tier_id
		  LEFT JOIN TABLE(v_view_company_type_ids) view_cts ON view_cts.column_value = brtct.company_type_id
		  LEFT JOIN TABLE(v_add_company_type_ids) add_cts ON add_cts.column_value = brtct.company_type_id
		  LEFT JOIN TABLE(v_upd_company_type_ids) upd_cts ON upd_cts.column_value = brtct.company_type_id
		 ORDER BY brt.business_relationship_type_id, brt.tier;

END;

PROCEDURE SaveBusinessRelationshipType(
	in_bus_rel_type_id			IN	business_relationship_type.business_relationship_type_id%TYPE,
	in_label					IN	business_relationship_type.label%TYPE,
	in_form_path				IN	business_relationship_type.form_path%TYPE,
	in_tab_sid					IN	business_relationship_type.tab_sid%TYPE,
	in_column_sid				IN	business_relationship_type.column_sid%TYPE,
	in_use_specific_dates		IN	business_relationship_type.use_specific_dates%TYPE, 
	in_period_set_id			IN	business_relationship_type.period_set_id%TYPE, 
	in_period_interval_id		IN	business_relationship_type.period_interval_id%TYPE,
	out_bus_rel_type_id			OUT	business_relationship_type.business_relationship_type_id%TYPE
) AS
BEGIN
	IF security.user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only super admins can configure business relationship types');
	END IF;

	IF in_bus_rel_type_id IS NULL THEN
		INSERT INTO business_relationship_type (business_relationship_type_id, label, form_path, tab_sid, column_sid, use_specific_dates, period_set_id, period_interval_id)
		VALUES (business_rel_type_id_seq.nextval, in_label, in_form_path, in_tab_sid, in_column_sid, in_use_specific_dates, in_period_set_id, in_period_interval_id)
		RETURNING business_relationship_type_id INTO out_bus_rel_type_id;
	ELSE
		UPDATE business_relationship_type
		SET label = in_label,
			form_path = in_form_path,
			tab_sid = in_tab_sid,
			column_sid = in_column_sid,
			use_specific_dates = in_use_specific_dates, 
			period_set_id = in_period_set_id, 
			period_interval_id = in_period_interval_id
		WHERE business_relationship_type_id = in_bus_rel_type_id;

		out_bus_rel_type_id := in_bus_rel_type_id;
	END IF;
END;

PROCEDURE SaveBusinessRelationshipTier(
	in_bus_rel_type_id			IN	business_relationship_tier.business_relationship_type_id%TYPE,
	in_bus_rel_tier_id			IN	business_relationship_tier.business_relationship_tier_id%TYPE,
	in_tier						IN	business_relationship_tier.tier%TYPE,
	in_label					IN	business_relationship_tier.label%TYPE,
	in_direct					IN	business_relationship_tier.direct_from_previous_tier%TYPE,
	in_create_supplier_rel		IN  business_relationship_tier.create_supplier_relationship%TYPE,
	in_create_new_company		IN  business_relationship_tier.create_new_company%TYPE,
	in_allow_multiple_companies	IN	business_relationship_tier.allow_multiple_companies%TYPE,
	in_crt_sup_rels_w_lower_tiers	IN business_relationship_tier.create_sup_rels_w_lower_tiers%TYPE,
	in_company_type_ids			IN	security_pkg.T_SID_IDS,
	out_bus_rel_tier_id			OUT	business_relationship_tier.business_relationship_tier_id%TYPE
)
AS
	v_bus_rel_tier_id			business_relationship_tier.business_relationship_tier_id%TYPE;
	v_direct					business_relationship_tier.direct_from_previous_tier%TYPE := CASE WHEN in_tier = 1 THEN NULL ELSE in_direct END;
	v_create_supplier_rel		business_relationship_tier.create_supplier_relationship%TYPE := CASE WHEN in_tier = 1 THEN NULL ELSE in_create_supplier_rel END;
	v_company_type_ids			security.T_SID_TABLE;
BEGIN
	IF security.user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only super admins can configure business relationship types');
	END IF;
	
	IF in_bus_rel_tier_id IS NULL THEN
		INSERT INTO business_relationship_tier (business_relationship_type_id, business_relationship_tier_id,
											    tier, label, 
												direct_from_previous_tier, create_supplier_relationship,
												create_new_company, allow_multiple_companies, create_sup_rels_w_lower_tiers)
		VALUES (in_bus_rel_type_id, business_rel_tier_id_seq.nextval,
				in_tier, in_label, 
				v_direct, v_create_supplier_rel,
				in_create_new_company, in_allow_multiple_companies, in_crt_sup_rels_w_lower_tiers)
		RETURNING business_relationship_tier_id INTO v_bus_rel_tier_id;
	ELSE
		-- make sure the two match
		SELECT business_relationship_tier_id
		  INTO v_bus_rel_tier_id
		  FROM business_relationship_tier
		 WHERE business_relationship_type_id = in_bus_rel_type_id
		   AND business_relationship_tier_id = in_bus_rel_tier_id;

		UPDATE business_relationship_tier
		   SET tier = in_tier,
			   label = in_label,
			   direct_from_previous_tier = v_direct,
			   create_supplier_relationship = v_create_supplier_rel,
			   create_new_company = in_create_new_company,
			   allow_multiple_companies = in_allow_multiple_companies,
			   create_sup_rels_w_lower_tiers = in_crt_sup_rels_w_lower_tiers
		 WHERE business_relationship_type_id = in_bus_rel_type_id
		   AND business_relationship_tier_id = in_bus_rel_tier_id;
	END IF;

	-- crap hack for ODP.NET
	IF in_company_type_ids IS NULL OR (in_company_type_ids.COUNT = 1 AND in_company_type_ids(1) IS NULL) THEN
	
		DELETE FROM business_rel_tier_company_type
		 WHERE business_relationship_tier_id = v_bus_rel_tier_id;		

	ELSE

		v_company_type_ids := security_pkg.SidArrayToTable(in_company_type_ids);

		DELETE FROM business_rel_tier_company_type
		 WHERE business_relationship_tier_id = v_bus_rel_tier_id
		   AND company_type_id NOT IN (
			SELECT column_value FROM TABLE(v_company_type_ids)
		   );

		FOR r IN (
			SELECT column_value FROM TABLE(v_company_type_ids)
		) LOOP
			BEGIN
				INSERT INTO business_rel_tier_company_type (business_relationship_tier_id, company_type_id)
				VALUES (v_bus_rel_tier_id, r.column_value);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL;
			END;
		END LOOP;

	END IF;

	out_bus_rel_tier_id	:= v_bus_rel_tier_id;
END;

PROCEDURE DeleteBusRelTiers(
	in_bus_rel_type_id			IN	business_relationship_tier.business_relationship_type_id%TYPE,
	in_from_tier				IN	business_relationship_tier.tier%TYPE
)
AS
	v_tier_ids					security.T_SID_TABLE;
BEGIN
	IF security.user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only super admins can configure business relationship types');
	END IF;

	SELECT business_relationship_tier_id
	  BULK COLLECT INTO v_tier_ids
	  FROM business_relationship_tier
	 WHERE business_relationship_type_id = in_bus_rel_type_id
	   AND tier >= in_from_tier;

	DELETE FROM business_rel_tier_company_type
	WHERE business_relationship_tier_id IN (
		SELECT column_value FROM TABLE(v_tier_ids)
	  );
	  
	DELETE FROM business_relationship_tier
	WHERE business_relationship_tier_id IN (
		SELECT column_value FROM TABLE(v_tier_ids)
	  );
END;

PROCEDURE DeleteBusinessRelationshipType(
	in_bus_rel_type_id			IN	business_relationship_type.business_relationship_type_id%TYPE
)
AS
	v_tier_ids					security.T_SID_TABLE;
BEGIN
	IF security.user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only super admins can configure business relationship types');
	END IF;
	
	SELECT business_relationship_tier_id
	  BULK COLLECT INTO v_tier_ids
	  FROM business_relationship_tier
	 WHERE business_relationship_type_id = in_bus_rel_type_id;
	
	DELETE FROM business_rel_tier_company_type
	WHERE business_relationship_tier_id IN (
		SELECT column_value FROM TABLE(v_tier_ids)
	  );
	
	DELETE FROM business_relationship_tier
	WHERE business_relationship_tier_id IN (
		SELECT column_value FROM TABLE(v_tier_ids)
	  );
	
	DELETE FROM business_relationship_type
	WHERE business_relationship_type_id = in_bus_rel_type_id;
END;

FUNCTION GetSignature(
	in_bus_rel_id				IN	business_relationship.business_relationship_id%TYPE
)
RETURN business_relationship.signature%TYPE
AS
	v_signature					business_relationship.signature%TYPE;
BEGIN
	SELECT br.business_relationship_type_id || ':' || listagg(brc.company_sid, ',') WITHIN GROUP (order by brt.tier, brc.pos) signature
	  INTO v_signature
	  FROM chain.business_relationship br
	  JOIN chain.business_relationship_company brc ON brc.business_relationship_id = br.business_relationship_id AND brc.app_sid = br.app_sid
	  JOIN chain.business_relationship_tier brt ON brt.business_relationship_tier_id = brc.business_relationship_tier_id AND brt.app_sid = brc.app_sid
	 WHERE br.business_relationship_id = in_bus_rel_id
	 GROUP BY br.business_relationship_type_id;

	RETURN v_signature;
END;

PROCEDURE CheckCreateAccess
AS
	v_company_sid			security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.CREATE_BUSINESS_RELATIONSHIPS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Create business relationships access denied to company with sid '||v_company_sid);
	END IF;
END;

PROCEDURE CreateBusinessRelationship(
	in_bus_rel_type_id			IN	business_relationship.business_relationship_type_id%TYPE,
	out_bus_rel_id				OUT	business_relationship.business_relationship_id%TYPE
)
AS
BEGIN
	CheckCreateAccess();

	INSERT INTO business_relationship (business_relationship_id,
									   business_relationship_type_id)
							   VALUES (business_relationship_id_seq.nextval,
									   in_bus_rel_type_id)
	RETURNING business_relationship_id INTO out_bus_rel_id;

	csr.csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), 
										csr.csr_data_pkg.AUDIT_TYPE_CHAIN_BUS_REL,
										SYS_CONTEXT('SECURITY', 'APP'), 
										out_bus_rel_id,
										'Business relationship {0} creation started', 
										out_bus_rel_id);
END;

PROCEDURE CheckDeleteBusinessRelAccess(
	in_bus_rel_id				IN	business_relationship.business_relationship_id%TYPE
)
AS
	v_primary_company_sid			security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_supplier_company_type_id		company.company_type_id%TYPE;
	v_cnt_other						NUMBER;
	v_cnt_prev						NUMBER;
BEGIN
	CheckCreateAccess;

	FOR r IN (
		SELECT brc.company_sid
		  FROM business_relationship_company brc
		  JOIN company c ON c.company_sid = brc.company_sid
		 WHERE brc.business_relationship_id = in_bus_rel_id
		   AND c.deleted = 0
	) LOOP
		IF v_primary_company_sid = r.company_sid THEN
			IF NOT type_capability_pkg.CheckCapability(v_primary_company_sid, chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS) THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'To delete business relationship, add to business relationships access denied to company '||v_primary_company_sid);
			END IF;
		ELSE
			IF NOT type_capability_pkg.CheckCapability(v_primary_company_sid, r.company_sid, chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS)
				AND NOT type_capability_pkg.CheckCapability(v_primary_company_sid, r.company_sid, chain_pkg.ADD_TO_BUS_REL_REVERSED)
			THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'To delete business relationship, add to business relationships on company '||r.company_sid||' access denied to company '||v_primary_company_sid);
			END IF;
		END IF;
	END LOOP;

	FOR r IN (
		SELECT brtr.business_relationship_tier_id, brtr.tier,
			   LAG(brtr.business_relationship_tier_id) OVER (ORDER BY brtr.tier) AS prev_bus_rel_tier_id
		  FROM business_relationship br
		  JOIN business_relationship_tier brtr ON brtr.business_relationship_type_id = br.business_relationship_type_id
		 WHERE br.business_relationship_id = in_bus_rel_id
		 ORDER BY brtr.tier
	)
	LOOP
		IF r.prev_bus_rel_tier_id IS NULL THEN
			CONTINUE;
		END IF;

		FOR p IN (
			SELECT company_sid
			  FROM business_relationship_company
			 WHERE business_relationship_id = in_bus_rel_id
			   AND business_relationship_tier_id = r.prev_bus_rel_tier_id
		)
		LOOP
			FOR s IN (
				SELECT company_sid
				  FROM business_relationship_company
				 WHERE business_relationship_id = in_bus_rel_id
				   AND business_relationship_tier_id = r.business_relationship_tier_id
			)
			LOOP
				SELECT COUNT(*)
				  INTO v_cnt_prev
				  FROM supplier_relationship_source
				 WHERE purchaser_company_sid = p.company_sid
				   AND supplier_company_sid = s.company_sid
				   AND object_id = in_bus_rel_id
				   AND source_type = chain_pkg.BUS_REL_REL_SRC_PREV;

				SELECT COUNT(*)
				  INTO v_cnt_other
				  FROM supplier_relationship_source
				 WHERE purchaser_company_sid = p.company_sid
				   AND supplier_company_sid = s.company_sid
				   AND (source_type NOT IN (chain_pkg.BUS_REL_REL_SRC_PREV, chain_pkg.BUS_REL_REL_SRC_FOLLOW) OR object_id IS NULL OR object_id != in_bus_rel_id);

				IF v_cnt_prev > 0 AND v_cnt_other = 0 THEN
					v_supplier_company_type_id := company_type_pkg.GetCompanyTypeId(s.company_sid);
					IF v_primary_company_sid = p.company_sid THEN
						IF NOT type_capability_pkg.CheckCapabilityBySupplierType(p.company_sid, v_supplier_company_type_id, chain_pkg.CREATE_RELATIONSHIP) THEN
							RAISE_APPLICATION_ERROR(chain_pkg.ERR_BUS_REL_DELETE_FAILED, 'You cannot delete this business relationship because you do not have permission to delete its supplier relationships');
						END IF;
					ELSE
						IF NOT type_capability_pkg.CheckCapabilityByTertiaryType(v_primary_company_sid, p.company_sid, v_supplier_company_type_id, chain_pkg.ADD_REMOVE_RELATIONSHIPS) THEN
							RAISE_APPLICATION_ERROR(chain_pkg.ERR_BUS_REL_DELETE_FAILED, 'You cannot delete this business relationship because you do not have permission to delete its supplier relationships');
						END IF;
					END IF;
				END IF;
			END LOOP;
		END LOOP;
	END LOOP;	
END;

PROCEDURE DeleteBusinessRelationship(
	in_bus_rel_id				IN	business_relationship.business_relationship_id%TYPE
)
AS
BEGIN
	CheckDeleteBusinessRelAccess(
		in_bus_rel_id		=> in_bus_rel_id
	);

	DELETE FROM business_relationship_period
	 WHERE business_relationship_id = in_bus_rel_id;

	DELETE FROM business_relationship_company
	 WHERE business_relationship_id = in_bus_rel_id;

	DELETE FROM business_relationship
	 WHERE business_relationship_id = in_bus_rel_id;

	company_pkg.DeleteSupplierRelationshipSrc(
		in_object_id		=> in_bus_rel_id,
		in_source_type		=> chain_pkg.BUS_REL_REL_SRC_PREV
	);

	company_pkg.DeleteSupplierRelationshipSrc(
		in_object_id		=> in_bus_rel_id,
		in_source_type		=> chain_pkg.BUS_REL_REL_SRC_FOLLOW
	);

	csr.csr_data_pkg.WriteAuditLogEntry(
		in_act_id			=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_audit_type_id	=> csr.csr_data_pkg.AUDIT_TYPE_CHAIN_BUS_REL,
		in_app_sid			=> SYS_CONTEXT('SECURITY', 'APP'),
		in_object_sid		=> in_bus_rel_id,
		in_description		=> 'Business relationship {0} deleted',
		in_param_1			=> in_bus_rel_id
	);
END;

PROCEDURE AddBusinessRelationshipCompany(
	in_bus_rel_id				IN	business_relationship_company.business_relationship_id%TYPE,
	in_bus_rel_tier_id			IN	business_relationship_company.business_relationship_tier_id%TYPE,
	in_pos						IN	business_relationship_company.pos%TYPE,
	in_company_sid				IN	business_relationship_company.company_sid%TYPE,
	in_allow_inactive			IN	NUMBER DEFAULT 0,
	in_allow_admin				IN	NUMBER DEFAULT 0
)
AS
	v_company_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_active					company.active%TYPE;
	v_tier						business_relationship_tier.tier%TYPE;
	v_prev_tier					business_relationship_tier.tier%TYPE;
	v_direct					business_relationship_tier.direct_from_previous_tier%TYPE;
	v_create_supplier_rel		business_relationship_tier.create_supplier_relationship%TYPE;
	v_cnt						NUMBER;
	v_relationships				T_COMPANY_REL_SIDS_TABLE;
BEGIN
	IF v_company_sid = in_company_sid THEN
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Add to business relationships access denied to company '||v_company_sid);
		END IF;
	ELSE
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, in_company_sid, chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS)
		AND NOT type_capability_pkg.CheckCapability(v_company_sid, in_company_sid, chain_pkg.ADD_TO_BUS_REL_REVERSED) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Add to business relationships on company '||in_company_sid||' access denied to company '||v_company_sid);
		END IF;
	END IF;

	IF in_allow_inactive = 0 THEN
		SELECT active
		  INTO v_active
		  FROM v$company
		 WHERE company_sid = in_company_sid;

		IF v_active <> chain_pkg.ACTIVE THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot add inactive company '||in_company_sid||' to a business relationship');
		END IF;
	END IF;
	
	SELECT brt.tier, brt.direct_from_previous_tier, brt.create_supplier_relationship
	  INTO v_tier, v_direct, v_create_supplier_rel
	  FROM business_relationship br
	  JOIN business_relationship_tier brt ON brt.business_relationship_type_id = br.business_relationship_type_id
	 WHERE br.business_relationship_id = in_bus_rel_id
	   AND brt.business_relationship_tier_id = in_bus_rel_tier_id;

	IF v_tier > 1 THEN
		SELECT brt.business_relationship_tier_id
		  INTO v_prev_tier
		  FROM business_relationship br
		  JOIN business_relationship_tier brt ON brt.business_relationship_type_id = br.business_relationship_type_id
		 WHERE br.business_relationship_id = in_bus_rel_id
		   AND brt.tier = v_tier - 1;
			
		FOR r IN (
			SELECT company_sid
			  FROM business_relationship_company
			 WHERE business_relationship_id = in_bus_rel_id
			   AND business_relationship_tier_id = v_prev_tier
		) LOOP
		
			v_relationships := company_pkg.GetVisibleRelationships(
				in_include_inactive_rels => 1,
				in_allow_admin => in_allow_admin
			);

			IF v_direct = 1 THEN
				SELECT count(*) INTO v_cnt
				  FROM TABLE(v_relationships)
				 WHERE primary_company_sid = r.company_sid
				   AND secondary_company_sid = in_company_sid;
			ELSE
				SELECT count(*) INTO v_cnt
					FROM (
						SELECT secondary_company_sid
						  FROM TABLE(v_relationships)
							   CONNECT BY primary_company_sid = PRIOR secondary_company_sid
							   START WITH primary_company_sid = r.company_sid
					) x
				   WHERE x.secondary_company_sid = in_company_sid;
			END IF;

			IF v_cnt = 0 THEN
				IF v_create_supplier_rel = 1 THEN
					company_pkg.EstablishRelationship(
						in_purchaser_company_sid		=> r.company_sid,
						in_supplier_company_sid			=> in_company_sid,
						in_source_type					=> chain_pkg.BUS_REL_REL_SRC_PREV,
						in_object_id					=> in_bus_rel_id
					);
				ELSE
					RAISE_APPLICATION_ERROR(-20001, 'No connection found between companies with sids '||r.company_sid||' and '||in_company_sid);
				END IF;
			END IF;

		END LOOP;
	END IF;

	INSERT INTO business_relationship_company(business_relationship_id,
											  business_relationship_tier_id,
											  pos,
											  company_sid)
									  VALUES (in_bus_rel_id,
											  in_bus_rel_tier_id,
											  in_pos,
											  in_company_sid);
											  
	csr.csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), 
										csr.csr_data_pkg.AUDIT_TYPE_CHAIN_BUS_REL,
										SYS_CONTEXT('SECURITY', 'APP'), 
										in_bus_rel_id,
										in_bus_rel_tier_id,
										'Company {0} added to business relationship {1} tier {2}',
										in_company_sid,
										in_bus_rel_id,
										v_tier);
END;

PROCEDURE CheckUpdatePeriodAccess(
	in_bus_rel_id				IN	business_relationship_period.business_relationship_id%TYPE
)
AS
	v_company_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
BEGIN
	-- The capability to add implies the capability to update, because you
	-- can create a new one and merge them, which is effectively an update.
	FOR r IN (
		SELECT company_sid
		  FROM business_relationship_company
		 WHERE business_relationship_id = in_bus_rel_id
	) LOOP
		IF v_company_sid = r.company_sid THEN
			IF NOT type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS) 
			AND NOT type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.UPDATE_BUSINESS_REL_PERIODS) THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Update business relationship periods access denied to company '||v_company_sid);
			END IF;
		ELSE
			IF NOT type_capability_pkg.CheckCapability(v_company_sid, r.company_sid, chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS)
			AND NOT type_capability_pkg.CheckCapability(v_company_sid, r.company_sid, chain_pkg.UPDATE_BUSINESS_REL_PERIODS)
			AND NOT type_capability_pkg.CheckCapability(v_company_sid, r.company_sid, chain_pkg.ADD_TO_BUS_REL_REVERSED)
			AND NOT type_capability_pkg.CheckCapability(v_company_sid, r.company_sid, chain_pkg.UPDATE_BUS_REL_PERDS_REVERSED) THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Update business relationship periods on company '||r.company_sid||' access denied to company '||v_company_sid);
			END IF;
		END IF;
	END LOOP;
END;

PROCEDURE SetBusinessRelationshipPeriods(
	in_bus_rel_id				IN	business_relationship_period.business_relationship_id%TYPE,
	in_keep_bus_rel_perd_ids	IN	security_pkg.T_SID_IDS
)
AS
	v_keep_bus_rel_perd_tbl		security.T_SID_TABLE;
BEGIN
	CheckUpdatePeriodAccess(in_bus_rel_id);

	IF in_keep_bus_rel_perd_ids IS NULL OR (in_keep_bus_rel_perd_ids.COUNT = 1 AND in_keep_bus_rel_perd_ids(1) IS NULL) THEN
		DELETE FROM business_relationship_period
		 WHERE business_relationship_id = in_bus_rel_id;
	ELSE
		v_keep_bus_rel_perd_tbl := security_pkg.SidArrayToTable(in_keep_bus_rel_perd_ids);
		DELETE FROM business_relationship_period
		 WHERE business_relationship_id = in_bus_rel_id
		   AND business_rel_period_id NOT IN (
			SELECT column_value FROM TABLE(v_keep_bus_rel_perd_tbl)
		   );
	END IF;
END;

PROCEDURE SaveBusinessRelationshipPeriod(
	in_bus_rel_id				IN	business_relationship_period.business_relationship_id%TYPE,
	in_bus_rel_period_id		IN	business_relationship_period.business_rel_period_id%TYPE,
	in_start_dtm				IN	business_relationship_period.start_dtm%TYPE,
	in_end_dtm					IN	business_relationship_period.end_dtm%TYPE,
	out_bus_rel_period_id		OUT	business_relationship_period.business_rel_period_id%TYPE
)
AS
BEGIN
	CheckUpdatePeriodAccess(in_bus_rel_id);

	IF in_bus_rel_period_id IS NULL THEN
		INSERT INTO business_relationship_period (
			business_relationship_id, business_rel_period_id, start_dtm, end_dtm
		) VALUES (
			in_bus_rel_id, business_rel_period_id_seq.NEXTVAL, in_start_dtm, in_end_dtm
		) RETURNING business_rel_period_id INTO out_bus_rel_period_id;
	ELSE
		UPDATE business_relationship_period
		   SET start_dtm = in_start_dtm,
			   end_dtm = in_end_dtm
		 WHERE business_relationship_id = in_bus_rel_id
		   AND business_rel_period_id = in_bus_rel_period_id;

		out_bus_rel_period_id := in_bus_rel_period_id;
	END IF;
END;

PROCEDURE MergeOverlappingPeriods(
	in_bus_rel_id				IN	business_relationship.business_relationship_id%TYPE	
)
AS
	v_cnt						NUMBER;
	v_end_dtm					DATE;
	v_did_extend				NUMBER;
BEGIN
	SELECT count(*)
	  INTO v_cnt
	  FROM business_relationship_period
	 WHERE business_relationship_id = in_bus_rel_id;
	 
	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Business relationship '||in_bus_rel_id||' has no business relationship periods');
	END IF;

	FOR r IN (
		SELECT business_rel_period_id, start_dtm, end_dtm
		  FROM business_relationship_period
		 WHERE business_relationship_id = in_bus_rel_id
		 ORDER BY start_dtm, business_rel_period_id
	) LOOP
		SELECT count(*)
		  INTO v_cnt
		  FROM business_relationship_period
		 WHERE business_rel_period_id = r.business_rel_period_id;

		IF v_cnt = 0 THEN
			-- we've already deleted this one. skip it.
			CONTINUE;
		END IF;
		
		v_end_dtm := r.end_dtm;
		v_did_extend := 0;

		FOR s IN (
			SELECT business_rel_period_id, start_dtm, end_dtm
			  FROM business_relationship_period
			 WHERE business_relationship_id = in_bus_rel_id
			   AND (start_dtm > r.start_dtm
					OR (start_dtm = r.start_dtm AND business_rel_period_id > r.business_rel_period_id))
			 ORDER BY start_dtm, business_rel_period_id
		) LOOP
			IF v_end_dtm IS NOT NULL THEN
				IF s.start_dtm <= v_end_dtm THEN
					IF s.end_dtm IS NULL OR s.end_dtm > v_end_dtm THEN
						-- period s extends past period r, so we should extend period r
						v_end_dtm := s.end_dtm;
						v_did_extend := 1;
					END IF;
					
					-- period s overlaps period r, so we should delete period s
					DELETE FROM business_relationship_period
					 WHERE business_rel_period_id = s.business_rel_period_id;
				ELSE
					-- period s starts after period r, so so will all of the rest.
					EXIT;
				END IF;
			ELSE
				-- period r is open-ended, so period s doesn't matter.
				DELETE FROM business_relationship_period
				 WHERE business_rel_period_id = s.business_rel_period_id;
			END IF;
		END LOOP;
		
		IF v_did_extend = 1 THEN
			UPDATE business_relationship_period
			   SET end_dtm = v_end_dtm
			 WHERE business_rel_period_id = r.business_rel_period_id;
		END IF;

	END LOOP;
END;

PROCEDURE DidCreateBusinessRelationship(
	in_bus_rel_id				IN	business_relationship.business_relationship_id%TYPE,
	in_merge_if_duplicate		IN	NUMBER DEFAULT 0,
	out_bus_rel_id				OUT	business_relationship.business_relationship_id%TYPE
)
AS
	v_pos						NUMBER;
	v_cnt						NUMBER;
	v_bus_rel_type_id			business_relationship.business_relationship_type_id%TYPE;
	v_signature					business_relationship.signature%TYPE;
BEGIN
	CheckCreateAccess();

	MergeOverlappingPeriods(in_bus_rel_id);

	SELECT business_relationship_type_id
	  INTO v_bus_rel_type_id
	  FROM business_relationship
	 WHERE business_relationship_id = in_bus_rel_id;

	FOR r IN (
		SELECT business_relationship_tier_id, allow_multiple_companies
		  FROM business_relationship_tier
		 WHERE business_relationship_type_id = v_bus_rel_type_id
	) LOOP
		v_pos := 0;

		FOR s IN (
			SELECT pos, company_sid
			  FROM business_relationship_company brc
			 WHERE brc.business_relationship_id = in_bus_rel_id
			   AND brc.business_relationship_tier_id = r.business_relationship_tier_id
			 ORDER BY pos
		) LOOP
			IF s.pos <> v_pos THEN
				RAISE_APPLICATION_ERROR(-20001, 'Business relationship '||in_bus_rel_id||' is missing company at position '||v_pos||' companies for tier '||r.business_relationship_tier_id);
			END IF;

			SELECT count(*)
			  INTO v_cnt
			  FROM v$company c
			  JOIN business_rel_tier_company_type brtct ON brtct.company_type_id = c.company_type_id
			 WHERE c.company_sid = s.company_sid
			   AND brtct.business_relationship_tier_id = r.business_relationship_tier_id;

			IF v_cnt <> 1 THEN
				RAISE_APPLICATION_ERROR(-20001, 'Business relationship '||in_bus_rel_id||' has company '||s.company_sid||' of invalid type for tier '||r.business_relationship_tier_id);
			END IF;

			v_pos := v_pos + 1;
		END LOOP;

		IF (r.allow_multiple_companies = 0 AND v_pos <> 1) OR (r.allow_multiple_companies = 1 AND v_pos = 0) THEN
			RAISE_APPLICATION_ERROR(-20001, 'Business relationship '||in_bus_rel_id||' has '||v_pos||' companies for tier '||r.business_relationship_tier_id);
		END IF;
	END LOOP;

	v_signature := GetSignature(in_bus_rel_id);

	SELECT count(*)
	  INTO v_cnt
	  FROM business_relationship
	 WHERE signature = v_signature;

	IF v_cnt <> 1 THEN

		UPDATE business_relationship
		   SET signature = v_signature
		 WHERE business_relationship_id = in_bus_rel_id;

		FOR r IN (
			SELECT brc.company_sid, brt.tier, c.company_type_id
			  FROM business_relationship_company brc
			  JOIN business_relationship_tier brt ON brt.business_relationship_tier_id = brc.business_relationship_tier_id
			  JOIN company c ON c.company_sid = brc.company_sid
			 WHERE brc.business_relationship_id = in_bus_rel_id
			   AND brt.create_sup_rels_w_lower_tiers = 1
			 ORDER BY brt.tier, brc.pos
		) LOOP
			FOR s IN (
				SELECT brc.company_sid
					FROM business_relationship_company brc
					JOIN business_relationship_tier brt ON brt.business_relationship_tier_id = brc.business_relationship_tier_id
					JOIN company c ON c.company_sid = brc.company_sid
					JOIN company_type_relationship crt ON crt.primary_company_type_id = r.company_type_id AND crt.secondary_company_type_id = c.company_type_id
					WHERE brc.business_relationship_id = in_bus_rel_id
					AND brt.tier > r.tier
					ORDER BY brt.tier, brc.pos
			) LOOP
				-- EstablishRelationship checks for the ADD_REMOVE_RELATIONSHIPS capability, which we don't want to require
				-- Start/Activate doesn't, and therefore probably should be private, but they aren't.
				chain.company_pkg.StartRelationship(
					in_purchaser_company_sid		=> r.company_sid,
					in_supplier_company_sid			=> s.company_sid,
					in_source_type					=> chain_pkg.BUS_REL_REL_SRC_FOLLOW,
					in_object_id					=> in_bus_rel_id
				);
				chain.company_pkg.ActivateRelationship(r.company_sid, s.company_sid);
			END LOOP;
		END LOOP;
	
		chain_link_pkg.BusinessRelationshipCreated(in_bus_rel_id);

		csr.csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), 
											csr.csr_data_pkg.AUDIT_TYPE_CHAIN_BUS_REL,
											SYS_CONTEXT('SECURITY', 'APP'), 
											in_bus_rel_id,
											'Business relationship {0} creation finished', 
											in_bus_rel_id);

		out_bus_rel_id := in_bus_rel_id;

	ELSE

		SELECT business_relationship_id
		  INTO out_bus_rel_id
		  FROM business_relationship
		 WHERE signature = v_signature;

		IF in_merge_if_duplicate = 1 THEN

			UPDATE business_relationship_period
			   SET business_relationship_id = out_bus_rel_id
			 WHERE business_relationship_id = in_bus_rel_id;

			DELETE FROM business_relationship_company
			 WHERE business_relationship_id = in_bus_rel_id;

			DELETE FROM business_relationship
			 WHERE business_relationship_id = in_bus_rel_id;

			DidUpdateBusinessRelationship(out_bus_rel_id);

		END IF;
		
	END IF;
END;

PROCEDURE DidUpdateBusinessRelationship(
	in_bus_rel_id				IN	business_relationship.business_relationship_id%TYPE	
)
AS
BEGIN
	MergeOverlappingPeriods(in_bus_rel_id);
	
	chain_link_pkg.BusinessRelationshipUpdated(in_bus_rel_id);

	csr.csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), 
										csr.csr_data_pkg.AUDIT_TYPE_CHAIN_BUS_REL,
										SYS_CONTEXT('SECURITY', 'APP'), 
										in_bus_rel_id,
										'Business relationship {0} updated', 
										in_bus_rel_id);
END;

PROCEDURE EmitBusinessRelationships(
	in_bus_rel_comps			T_BUS_REL_COMP_TABLE,
	in_visible_company_sids		security.T_SID_TABLE,
	in_viewable_company_sids	security.T_SID_TABLE,
	in_addable_company_sids		security.T_SID_TABLE,
	in_updatable_company_sids	security.T_SID_TABLE,
	in_ordering					security.T_ORDERED_SID_TABLE DEFAULT security.T_ORDERED_SID_TABLE(),
	out_bus_rel_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_period_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_comp_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_bus_rel_ids				security.T_SID_TABLE;
	v_can_not_upd_bus_rel_ids	security.T_SID_TABLE;
	v_can_not_del_bus_rel_ids	security.T_SID_TABLE;
	v_create_bus_rel_cap		NUMBER := 0;
BEGIN
	IF capability_pkg.CheckCapability(chain_pkg.CREATE_BUSINESS_RELATIONSHIPS) THEN
		v_create_bus_rel_cap := 1;
	END IF;

	SELECT DISTINCT business_relationship_id
	  BULK COLLECT INTO v_bus_rel_ids
	  FROM TABLE(in_bus_rel_comps);

	SELECT DISTINCT brids.column_value
	  BULK COLLECT INTO v_can_not_upd_bus_rel_ids
	  FROM TABLE(v_bus_rel_ids) brids
	  JOIN business_relationship_company brc ON brids.column_value = brc.business_relationship_id
	  LEFT JOIN TABLE(in_addable_company_sids) add_cts ON brc.company_sid = add_cts.column_value
	  LEFT JOIN TABLE(in_updatable_company_sids) upd_cts ON brc.company_sid = upd_cts.column_value
	 WHERE add_cts.column_value IS NULL AND upd_cts.column_value IS NULL;

	 SELECT DISTINCT brids.column_value
	  BULK COLLECT INTO v_can_not_del_bus_rel_ids
	  FROM TABLE(v_bus_rel_ids) brids
	  JOIN business_relationship_company brc ON brids.column_value = brc.business_relationship_id
	  JOIN company c ON c.company_sid = brc.company_sid
	  LEFT JOIN TABLE(in_addable_company_sids) add_cts ON brc.company_sid = add_cts.column_value
	 WHERE add_cts.column_value IS NULL AND c.deleted = 0;

	OPEN out_bus_rel_cur FOR
		SELECT br.business_relationship_id, br.business_relationship_type_id, 
			   brt.label type_label,
			   CASE WHEN EXISTS (
					SELECT NULL
					  FROM business_relationship_period brp
					 WHERE br.business_relationship_id = brp.business_relationship_id
					   AND brp.start_dtm <= SYSDATE
					   AND (brp.end_dtm IS NULL OR brp.end_dtm > SYSDATE)
			   ) THEN 1 ELSE 0 END active,
			   CASE WHEN upd_n.column_value IS NULL THEN 1 ELSE 0 END can_update_periods,
			   CASE WHEN v_create_bus_rel_cap = 1 AND del_n.column_value IS NULL THEN 1 ELSE 0 END can_delete
		  FROM business_relationship br
		  JOIN TABLE(v_bus_rel_ids) brids ON br.business_relationship_id = brids.column_value
		  JOIN business_relationship_type brt ON brt.business_relationship_type_id = br.business_relationship_type_id
		  LEFT JOIN TABLE(v_can_not_upd_bus_rel_ids) upd_n ON br.business_relationship_id = upd_n.column_value
		  LEFT JOIN TABLE(v_can_not_del_bus_rel_ids) del_n ON br.business_relationship_id = del_n.column_value
		  LEFT JOIN TABLE(in_ordering) ord ON br.business_relationship_id = ord.sid_id
		 ORDER BY ord.pos NULLS LAST, br.business_relationship_id;

	OPEN out_bus_rel_period_cur FOR
		SELECT brp.business_relationship_id, brp.business_rel_period_id,
			   brp.start_dtm, brp.end_dtm
		  FROM business_relationship_period brp
		  JOIN TABLE(v_bus_rel_ids) brids ON brp.business_relationship_id = brids.column_value
		 ORDER BY brp.start_dtm;

	OPEN out_bus_rel_comp_cur FOR
		SELECT t.business_relationship_id, t.business_relationship_tier_id, t.pos, t.company_sid,
			   c.name company_name, c.company_type_id,
			   brt.tier
		  FROM TABLE(in_bus_rel_comps) t
		  JOIN company c ON c.company_sid = t.company_sid
		  JOIN business_relationship_tier brt ON brt.business_relationship_tier_id = t.business_relationship_tier_id
		 WHERE c.deleted = 0
		   AND c.pending = 0
		 ORDER BY t.business_relationship_id, brt.tier, t.pos;
END;

PROCEDURE GetBusinessRelationship (
	in_bus_rel_id				IN	business_relationship.business_relationship_id%TYPE,
	out_bus_rel_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_period_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_comp_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_visible_company_sids		security.T_SID_TABLE := company_pkg.GetVisibleCompanySids;
	v_viewable_company_sids		security.T_SID_TABLE := type_capability_pkg.GetCapableCompanySids(v_visible_company_sids, chain_pkg.VIEW_BUSINESS_RELATIONSHIPS, chain_pkg.VIEW_BUS_REL_REVERSED);
	v_addable_company_sids		security.T_SID_TABLE := type_capability_pkg.GetCapableCompanySids(v_viewable_company_sids, chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS, chain_pkg.ADD_TO_BUS_REL_REVERSED);
	v_updatable_company_sids	security.T_SID_TABLE := type_capability_pkg.GetCapableCompanySids(v_viewable_company_sids, chain_pkg.UPDATE_BUSINESS_REL_PERIODS, chain_pkg.UPDATE_BUS_REL_PERDS_REVERSED);
	v_bus_rel_comps				T_BUS_REL_COMP_TABLE;
BEGIN
	SELECT T_BUS_REL_COMP_ROW(t.company_sid, t.business_relationship_id, t.business_relationship_tier_id, t.pos, t.company_sid)
	  BULK COLLECT INTO v_bus_rel_comps
	  FROM (
		   SELECT brc.business_relationship_id, brc.business_relationship_tier_id, brc.pos, brc.company_sid
		     FROM business_relationship_company brc
			 JOIN TABLE(v_viewable_company_sids) vis ON vis.column_value = brc.company_sid
			WHERE brc.business_relationship_id = in_bus_rel_id
	  ) t;
	
	IF v_bus_rel_comps.COUNT = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'No access to business relationship ' || in_bus_rel_id || ' for user with sid ' || SYS_CONTEXT('SECURITY', 'SID'));
	END IF;

	EmitBusinessRelationships(
		in_bus_rel_comps			=> v_bus_rel_comps,
		in_visible_company_sids		=> v_visible_company_sids,
		in_viewable_company_sids	=> v_viewable_company_sids,
		in_addable_company_sids		=> v_addable_company_sids,
		in_updatable_company_sids	=> v_updatable_company_sids,
		out_bus_rel_cur				=> out_bus_rel_cur,
		out_bus_rel_period_cur		=> out_bus_rel_period_cur,
		out_bus_rel_comp_cur		=> out_bus_rel_comp_cur
	);
END;

PROCEDURE GetBusinessRelationships(
	in_bus_rel_ids				security.T_ORDERED_SID_TABLE,
	out_bus_rel_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_period_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_comp_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_visible_company_sids		security.T_SID_TABLE := company_pkg.GetVisibleCompanySids;
	v_viewable_company_sids		security.T_SID_TABLE := type_capability_pkg.GetCapableCompanySids(v_visible_company_sids, chain_pkg.VIEW_BUSINESS_RELATIONSHIPS, chain_pkg.VIEW_BUS_REL_REVERSED);
	v_addable_company_sids		security.T_SID_TABLE := type_capability_pkg.GetCapableCompanySids(v_viewable_company_sids, chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS, chain_pkg.ADD_TO_BUS_REL_REVERSED);
	v_updatable_company_sids	security.T_SID_TABLE := type_capability_pkg.GetCapableCompanySids(v_viewable_company_sids, chain_pkg.UPDATE_BUSINESS_REL_PERIODS, chain_pkg.UPDATE_BUS_REL_PERDS_REVERSED);
	v_bus_rel_comps				T_BUS_REL_COMP_TABLE;
BEGIN
	SELECT T_BUS_REL_COMP_ROW(t.company_sid, t.business_relationship_id, t.business_relationship_tier_id, t.pos, t.company_sid)
	  BULK COLLECT INTO v_bus_rel_comps
	  FROM (
		   SELECT brc.business_relationship_id, brc.business_relationship_tier_id, brc.pos, brc.company_sid
		     FROM business_relationship_company brc
			 JOIN (SELECT column_value FROM TABLE(v_viewable_company_sids) ORDER BY column_value) vis ON vis.column_value = brc.company_sid
			 JOIN TABLE(in_bus_rel_ids) ids ON ids.sid_id = brc.business_relationship_id
	  ) t;

	EmitBusinessRelationships(
		in_bus_rel_comps			=> v_bus_rel_comps,
		in_visible_company_sids		=> v_visible_company_sids,
		in_viewable_company_sids	=> v_viewable_company_sids,
		in_addable_company_sids		=> v_addable_company_sids,
		in_updatable_company_sids	=> v_updatable_company_sids,
		in_ordering					=> in_bus_rel_ids,
		out_bus_rel_cur				=> out_bus_rel_cur,
		out_bus_rel_period_cur		=> out_bus_rel_period_cur,
		out_bus_rel_comp_cur		=> out_bus_rel_comp_cur
	);
END;

PROCEDURE INTERNAL_GetBusRelComps(
	in_starting_company_sids		IN	security.T_SID_TABLE,
	in_bus_rel_type_id				IN	business_relationship.business_relationship_type_id%TYPE,
	in_viewable_company_sids		IN	security.T_SID_TABLE,
	in_include_inactive				IN	NUMBER,
	out_bus_rel_comps				OUT T_BUS_REL_COMP_TABLE
)
AS
	v_bus_rel_ids					security.T_SID_TABLE;
BEGIN
	SELECT DISTINCT br.business_relationship_id
	  BULK COLLECT INTO v_bus_rel_ids
		  FROM business_relationship br
		  JOIN business_relationship_company brc ON br.business_relationship_id = brc.business_relationship_id
		  JOIN TABLE(in_viewable_company_sids) vis ON vis.column_value = brc.company_sid
		 WHERE brc.company_sid IN (SELECT column_value FROM TABLE(in_starting_company_sids))
		   AND (in_include_inactive = 1 OR EXISTS (
				SELECT NULL
				  FROM business_relationship_period brp
				 WHERE br.business_relationship_id = brp.business_relationship_id
				   AND brp.start_dtm <= SYSDATE
				   AND (brp.end_dtm IS NULL OR brp.end_dtm > SYSDATE)
		   ))
		   AND (in_bus_rel_type_id IS NULL OR br.business_relationship_type_id = in_bus_rel_type_id);

	WITH tiers_t AS (
		SELECT brc.business_relationship_id, brt.business_relationship_tier_id, brt.tier, count(*) company_count
		  FROM business_relationship_company brc
		  JOIN TABLE(v_bus_rel_ids) ids ON brc.business_relationship_id = ids.column_value
		  JOIN business_relationship_tier brt ON brt.business_relationship_tier_id = brc.business_relationship_tier_id
		 GROUP BY brc.business_relationship_id, brt.business_relationship_tier_id, brt.tier
	), companies_t AS (
		SELECT brc.business_relationship_id, brc.business_relationship_tier_id, brc.pos, brc.company_sid,
			   tiers_t.tier, tiers_t.company_count
		  FROM business_relationship_company brc
		  JOIN tiers_t ON tiers_t.business_relationship_id = brc.business_relationship_id AND tiers_t.business_relationship_tier_id = brc.business_relationship_tier_id
		  JOIN TABLE(in_viewable_company_sids) vis ON vis.column_value = brc.company_sid
	)
	SELECT T_BUS_REL_COMP_ROW(t.starting_company_sid, t.business_relationship_id, t.business_relationship_tier_id, t.pos, t.company_sid)
	  BULK COLLECT INTO out_bus_rel_comps
		  FROM (
				-- the starting companies
			   SELECT companies_t.company_sid starting_company_sid, companies_t.business_relationship_id, companies_t.business_relationship_tier_id, companies_t.pos, companies_t.company_sid
				 FROM companies_t
				WHERE companies_t.company_sid IN (SELECT column_value FROM TABLE(in_starting_company_sids))
			   -- predecessors we're allowed to see
			   UNION
			   SELECT CONNECT_BY_ROOT companies_t.company_sid starting_company_sid, companies_t.business_relationship_id, companies_t.business_relationship_tier_id, companies_t.pos, companies_t.company_sid
				 FROM companies_t
				START WITH companies_t.company_sid IN (SELECT column_value FROM TABLE(in_starting_company_sids))
					CONNECT BY companies_t.business_relationship_id = PRIOR companies_t.business_relationship_id AND (
						(
							companies_t.tier = PRIOR companies_t.tier - 1
							AND companies_t.pos = companies_t.company_count - 1
							AND PRIOR companies_t.pos = 0
						) OR (
							companies_t.tier = PRIOR companies_t.tier 
							AND companies_t.pos = PRIOR companies_t.pos - 1
						)
					)
			   -- successors we're allowed to see
			   UNION
			   SELECT CONNECT_BY_ROOT companies_t.company_sid starting_company_sid, companies_t.business_relationship_id, companies_t.business_relationship_tier_id, companies_t.pos, companies_t.company_sid
				 FROM companies_t
				START WITH companies_t.company_sid IN (SELECT column_value FROM TABLE(in_starting_company_sids))
					CONNECT BY companies_t.business_relationship_id = PRIOR companies_t.business_relationship_id AND (
						(
							companies_t.tier = PRIOR companies_t.tier + 1
							AND companies_t.pos = 0
							AND PRIOR companies_t.pos = PRIOR companies_t.company_count - 1
						) OR (
							companies_t.tier = PRIOR companies_t.tier 
							AND companies_t.pos = PRIOR companies_t.pos + 1
						)
					)
			) t;
END;

PROCEDURE FilterBusinessRelationships(
	in_company_sid				IN	business_relationship_company.company_sid%TYPE,
	in_search_term  			IN  VARCHAR2 DEFAULT NULL,
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE DEFAULT NULL,
	in_include_inactive			IN	NUMBER,
	in_bus_rel_type_id			IN	business_relationship.business_relationship_type_id%TYPE DEFAULT NULL,
	out_bus_rel_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_period_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_comp_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_company_type_id			security_pkg.T_SID_ID := company_type_pkg.GetCompanyTypeId(v_company_sid);
	v_results					T_FILTERED_OBJECT_TABLE := T_FILTERED_OBJECT_TABLE();
	v_starting_company_sids		security.T_SID_TABLE;
	v_visible_company_sids		security.T_SID_TABLE := company_pkg.GetVisibleCompanySids;
	v_viewable_company_sids		security.T_SID_TABLE := type_capability_pkg.GetCapableCompanySids(v_visible_company_sids, chain_pkg.VIEW_BUSINESS_RELATIONSHIPS, chain_pkg.VIEW_BUS_REL_REVERSED);
	v_addable_company_sids		security.T_SID_TABLE := type_capability_pkg.GetCapableCompanySids(v_viewable_company_sids, chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS, chain_pkg.ADD_TO_BUS_REL_REVERSED);
	v_updatable_company_sids	security.T_SID_TABLE := type_capability_pkg.GetCapableCompanySids(v_viewable_company_sids, chain_pkg.UPDATE_BUSINESS_REL_PERIODS, chain_pkg.UPDATE_BUS_REL_PERDS_REVERSED);
	v_bus_rel_comps				T_BUS_REL_COMP_TABLE;
	v_filtered_comps			T_BUS_REL_COMP_TABLE;
BEGIN	
	IF v_company_sid = in_company_sid THEN
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.VIEW_BUSINESS_RELATIONSHIPS) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'View own business relationships access denied to company '||v_company_sid);
		END IF;
	ELSIF company_pkg.IsSupplier(v_company_sid, in_company_sid) THEN
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, in_company_sid, chain_pkg.VIEW_BUSINESS_RELATIONSHIPS)
		AND NOT type_capability_pkg.CheckCapability(v_company_sid, in_company_sid, chain_pkg.VIEW_BUS_REL_REVERSED) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'View business relationships on company '||in_company_sid||' access denied to company '||v_company_sid);
		END IF;
	END IF;

	SELECT in_company_sid
	  BULK COLLECT INTO v_starting_company_sids
	  FROM dual;

	INTERNAL_GetBusRelComps(
		in_starting_company_sids => v_starting_company_sids,
		in_bus_rel_type_id => in_bus_rel_type_id,
		in_viewable_company_sids => v_viewable_company_sids,
		in_include_inactive => in_include_inactive,
		out_bus_rel_comps => v_bus_rel_comps
	);

	IF in_search_term IS NOT NULL OR in_compound_filter_id IS NOT NULL THEN

		SELECT T_FILTERED_OBJECT_ROW (t.company_sid, NULL, NULL)
		  BULK COLLECT INTO v_results
		  FROM TABLE (v_bus_rel_comps) t;
		
		company_filter_pkg.GetFilteredIds(
			in_search				=> in_search_term,
			in_compound_filter_id	=> in_compound_filter_id,
			in_id_list				=> v_results,
			out_id_list				=> v_results);
		
		SELECT T_BUS_REL_COMP_ROW(t.starting_company_sid, t.business_relationship_id, t.business_relationship_tier_id, t.pos, t.company_sid)
		  BULK COLLECT INTO v_filtered_comps
		  FROM TABLE(v_bus_rel_comps) t
		 WHERE EXISTS(
			SELECT 1 
			  FROM TABLE(v_bus_rel_comps) v 
			  JOIN TABLE(v_results) r ON v.company_sid = r.object_id
			  WHERE v.business_relationship_id = t.business_relationship_id
		 ) GROUP BY t.starting_company_sid, t.business_relationship_id, t.business_relationship_tier_id, t.pos, t.company_sid;

		 v_bus_rel_comps := v_filtered_comps;

	END IF;

	EmitBusinessRelationships(
		in_bus_rel_comps			=> v_bus_rel_comps,
		in_visible_company_sids		=> v_visible_company_sids,
		in_viewable_company_sids	=> v_viewable_company_sids,
		in_addable_company_sids		=> v_addable_company_sids,
		in_updatable_company_sids	=> v_updatable_company_sids,
		out_bus_rel_cur				=> out_bus_rel_cur,
		out_bus_rel_period_cur		=> out_bus_rel_period_cur,
		out_bus_rel_comp_cur		=> out_bus_rel_comp_cur
	);
END;

PROCEDURE FindPotentialCompaniesForTier(
	in_bus_rel_type_id			IN	business_relationship_company.business_relationship_id%TYPE,
	in_bus_rel_tier_id			IN	business_relationship_company.business_relationship_tier_id%TYPE,
	in_company_sids				IN	security.T_SID_TABLE,
	in_search_term  			IN  VARCHAR2,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_company_sids				security.T_SID_TABLE := type_capability_pkg.GetCapableCompanySids(in_company_sids, chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS, chain_pkg.ADD_TO_BUS_REL_REVERSED);
	v_search_in_ids				chain.T_FILTERED_OBJECT_TABLE;
	v_search_out_ids			chain.T_FILTERED_OBJECT_TABLE;
BEGIN
	
	IF in_search_term IS NOT NULL THEN
		SELECT chain.T_FILTERED_OBJECT_ROW(column_value, NULL, NULL)
		  BULK COLLECT INTO v_search_in_ids
		  FROM TABLE(v_company_sids);

		company_filter_pkg.Search(in_search_term, v_search_in_ids, v_search_out_ids);

		SELECT object_id
		  BULK COLLECT INTO v_company_sids
		  FROM TABLE(v_search_out_ids);
	END IF;

	OPEN out_cur FOR
		SELECT c.company_sid, c.name, c.company_type_id
		  FROM v$company c
		  JOIN TABLE(v_company_sids) t ON c.company_sid = t.column_value
		  JOIN business_rel_tier_company_type brtct ON c.company_type_id = brtct.company_type_id
		 WHERE brtct.business_relationship_tier_id = in_bus_rel_tier_id
		   AND c.active = chain_pkg.ACTIVE
	     ORDER BY c.name;
END;

PROCEDURE FindAncestorsForTier(
	in_bus_rel_type_id			IN	business_relationship_company.business_relationship_id%TYPE,
	in_bus_rel_tier_id			IN	business_relationship_company.business_relationship_tier_id%TYPE,
	in_company_sids				IN	security_pkg.T_SID_IDS,
	in_search_term  			IN  VARCHAR2 DEFAULT NULL,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sids				security.T_SID_TABLE := security.security_pkg.SidArrayToTable(in_company_sids);
	v_companies_count			NUMBER;
	v_relationships				T_COMPANY_REL_SIDS_TABLE;
	v_tier						business_relationship_tier.tier%TYPE;
	v_next_tier_id				business_relationship_tier.business_relationship_tier_id%TYPE;
	v_direct					business_relationship_tier.direct_from_previous_tier%TYPE;
	v_create_supplier_rel		business_relationship_tier.create_supplier_relationship%TYPE;
	v_permissible_types			T_PERMISSIBLE_TYPES_TABLE;
	v_visible_company_sids		security.T_SID_TABLE;
	v_ancestors					security.T_SID_TABLE;
	v_ancestors_as_rel			T_COMPANY_REL_SIDS_TABLE;
	v_all_ancestors_as_rel		T_COMPANY_REL_SIDS_TABLE := NULL;
BEGIN
	SELECT tier INTO v_tier
	  FROM business_relationship_tier
	 WHERE business_relationship_type_id = in_bus_rel_type_id
	   AND business_relationship_tier_id = in_bus_rel_tier_id;

	SELECT business_relationship_tier_id INTO v_next_tier_id
	  FROM business_relationship_tier
	 WHERE business_relationship_type_id = in_bus_rel_type_id
	   AND tier = v_tier + 1;
	 
	SELECT direct_from_previous_tier, create_supplier_relationship
	  INTO v_direct, v_create_supplier_rel
	  FROM business_relationship_tier
	 WHERE business_relationship_type_id = in_bus_rel_type_id
	   AND business_relationship_tier_id = v_next_tier_id;
	   
	IF v_create_supplier_rel = 1 THEN
		v_permissible_types := type_capability_pkg.GetPermissibleCompanyTypes(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.ADD_REMOVE_RELATIONSHIPS);
		v_visible_company_sids := company_pkg.GetVisibleCompanySids;
	END IF;

	FOR r IN (
		SELECT column_value company_sid FROM TABLE(v_company_sids)
	) LOOP
		BEGIN
			v_relationships := company_pkg.GetConnectedRelationships(r.company_sid);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_relationships := T_COMPANY_REL_SIDS_TABLE();
			WHEN OTHERS THEN
				IF SQLCODE = security_pkg.ERR_ACCESS_DENIED THEN
					v_relationships := T_COMPANY_REL_SIDS_TABLE();
				ELSE
					RAISE;
				END IF;
		END;
		
		IF v_direct = 1 THEN
			SELECT primary_company_sid
			  BULK COLLECT INTO v_ancestors
			  FROM TABLE(v_relationships)
			 WHERE secondary_company_sid = r.company_sid;
		ELSE
			SELECT primary_company_sid
			  BULK COLLECT INTO v_ancestors
			  FROM TABLE(v_relationships)
				   CONNECT BY secondary_company_sid = PRIOR primary_company_sid
				   START WITH secondary_company_sid = r.company_sid;
		END IF;

		IF v_create_supplier_rel = 1 THEN
			DECLARE
				v_related_ancestors		security.T_SID_TABLE := v_ancestors;
				v_relatable_ancestors	security.T_SID_TABLE;
			BEGIN
				SELECT sc.company_sid
				  BULK COLLECT INTO v_relatable_ancestors
				  FROM TABLE(v_permissible_types) pt
				  JOIN v$company sc ON sc.company_type_id = pt.secondary_company_type_id
				  JOIN v$company tc ON tc.company_type_id = pt.tertiary_company_type_id
				  JOIN TABLE(v_visible_company_sids) vc ON vc.column_value = sc.company_sid
				  LEFT JOIN TABLE(v_related_ancestors) rc ON rc.column_value = sc.company_sid
				 WHERE tc.company_sid = r.company_sid
				   AND rc.column_value IS NULL;

				v_ancestors := v_related_ancestors MULTISET UNION v_relatable_ancestors;
			END;
		END IF;

		SELECT chain.T_COMPANY_RELATIONSHIP_SIDS(r.company_sid, t.column_value, 1)
		  BULK COLLECT INTO v_ancestors_as_rel
		  FROM TABLE(v_ancestors) t;

		IF v_all_ancestors_as_rel IS NULL THEN
			v_all_ancestors_as_rel := v_ancestors_as_rel;
		ELSE
			v_all_ancestors_as_rel := v_ancestors_as_rel MULTISET UNION v_all_ancestors_as_rel;
		END IF;
	END LOOP;

	-- We do this because MULTISET INTERSECT is known to be slow.
	-- This may also be slow, but if so, we don't know it yet.
	IF v_all_ancestors_as_rel IS NULL THEN
		v_ancestors := security.T_SID_TABLE();
	ELSE
		SELECT COUNT(distinct column_value)
		  INTO v_companies_count
		  FROM TABLE(v_company_sids);

		SELECT secondary_company_sid
		  BULK COLLECT INTO v_ancestors
		  FROM (
				SELECT secondary_company_sid
				  FROM TABLE (v_all_ancestors_as_rel)
				 GROUP BY secondary_company_sid
				HAVING COUNT(distinct primary_company_sid) = v_companies_count
		  );
	END IF;

	FindPotentialCompaniesForTier(in_bus_rel_type_id, in_bus_rel_tier_id, v_ancestors, in_search_term, out_cur);
END;

PROCEDURE FindSiblingsForTier(
	in_bus_rel_type_id			IN	business_relationship_company.business_relationship_id%TYPE,
	in_bus_rel_tier_id			IN	business_relationship_company.business_relationship_tier_id%TYPE,
	in_company_sids				IN	security_pkg.T_SID_IDS,
	in_search_term  			IN  VARCHAR2 DEFAULT NULL,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_visible_company_sids		security.T_SID_TABLE := company_pkg.GetVisibleCompanySids;
BEGIN
	FindPotentialCompaniesForTier(in_bus_rel_type_id, in_bus_rel_tier_id, v_visible_company_sids, in_search_term, out_cur);
END;

PROCEDURE FindDescendantsForTier(
	in_bus_rel_type_id			IN	business_relationship_company.business_relationship_id%TYPE,
	in_bus_rel_tier_id			IN	business_relationship_company.business_relationship_tier_id%TYPE,
	in_company_sids				IN	security_pkg.T_SID_IDS,
	in_search_term  			IN  VARCHAR2 DEFAULT NULL,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sids				security.T_SID_TABLE := security.security_pkg.SidArrayToTable(in_company_sids);
	v_companies_count			NUMBER;
	v_relationships				T_COMPANY_REL_SIDS_TABLE;
	v_direct					business_relationship_tier.direct_from_previous_tier%TYPE;
	v_create_supplier_rel		business_relationship_tier.create_supplier_relationship%TYPE;
	v_permissible_types			T_PERMISSIBLE_TYPES_TABLE;
	v_visible_company_sids		security.T_SID_TABLE;
	v_descendants				security.T_SID_TABLE;
	v_descendants_as_rel		T_COMPANY_REL_SIDS_TABLE;
	v_all_descendants_as_rel	T_COMPANY_REL_SIDS_TABLE := NULL;
BEGIN
	SELECT direct_from_previous_tier, create_supplier_relationship
	  INTO v_direct, v_create_supplier_rel
	  FROM business_relationship_tier
	 WHERE business_relationship_type_id = in_bus_rel_type_id
	   AND business_relationship_tier_id = in_bus_rel_tier_id;
	   
	IF v_create_supplier_rel = 1 THEN
		v_permissible_types := type_capability_pkg.GetPermissibleCompanyTypes(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.ADD_REMOVE_RELATIONSHIPS);
		v_visible_company_sids := company_pkg.GetVisibleCompanySids;
	END IF;

	FOR r IN (
		SELECT column_value company_sid FROM TABLE(v_company_sids)
	) LOOP

		BEGIN
			v_relationships := company_pkg.GetConnectedRelationships(r.company_sid);
		
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_relationships := T_COMPANY_REL_SIDS_TABLE();
			WHEN OTHERS THEN
				IF SQLCODE = security_pkg.ERR_ACCESS_DENIED THEN
					v_relationships := T_COMPANY_REL_SIDS_TABLE();
				ELSE
					RAISE;
				END IF;
		END;

		IF v_direct = 1 THEN
			SELECT secondary_company_sid
			  BULK COLLECT INTO v_descendants
			  FROM TABLE(v_relationships)
			 WHERE primary_company_sid = r.company_sid;
		 
		ELSE
			SELECT secondary_company_sid
			  BULK COLLECT INTO v_descendants
			  FROM TABLE(v_relationships)
				   CONNECT BY primary_company_sid = PRIOR secondary_company_sid
				   START WITH primary_company_sid = r.company_sid;
		END IF;
	
		IF v_create_supplier_rel = 1 THEN
			DECLARE
				v_permissible_types		T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.ADD_REMOVE_RELATIONSHIPS);
				v_visible_company_sids	security.T_SID_TABLE := company_pkg.GetVisibleCompanySids;
				v_related_descendants	security.T_SID_TABLE;
				v_relatable_descendants	security.T_SID_TABLE;
			BEGIN
				v_related_descendants := v_descendants;
			
				SELECT tc.company_sid
				  BULK COLLECT INTO v_relatable_descendants
				  FROM TABLE(v_permissible_types) pt
				  JOIN v$company sc ON sc.company_type_id = pt.secondary_company_type_id
				  JOIN v$company tc ON tc.company_type_id = pt.tertiary_company_type_id
				  JOIN TABLE(v_visible_company_sids) vc ON vc.column_value = tc.company_sid
				  LEFT JOIN TABLE(v_related_descendants) rc ON rc.column_value = tc.company_sid
				 WHERE sc.company_sid = r.company_sid
				   AND rc.column_value IS NULL;

				v_descendants := v_related_descendants MULTISET UNION v_relatable_descendants;
			END;
		END IF;
		
		SELECT chain.T_COMPANY_RELATIONSHIP_SIDS(r.company_sid, t.column_value, 1)
		  BULK COLLECT INTO v_descendants_as_rel
		  FROM TABLE(v_descendants) t;

		IF v_all_descendants_as_rel IS NULL THEN
			v_all_descendants_as_rel := v_descendants_as_rel;
		ELSE
			v_all_descendants_as_rel := v_descendants_as_rel MULTISET UNION v_all_descendants_as_rel;
		END IF;
	END LOOP;
	
	-- We do this because MULTISET INTERSECT is known to be slow.
	-- This may also be slow, but if so, we don't know it yet.
	IF v_all_descendants_as_rel IS NULL THEN
		v_descendants := security.T_SID_TABLE();
	ELSE
		SELECT COUNT(distinct column_value)
		  INTO v_companies_count
		  FROM TABLE(v_company_sids);

		SELECT secondary_company_sid
		  BULK COLLECT INTO v_descendants
		  FROM (
				SELECT secondary_company_sid
				  FROM TABLE (v_all_descendants_as_rel)
				 GROUP BY secondary_company_sid
				HAVING COUNT(distinct primary_company_sid) = v_companies_count
		  );
	END IF;

	FindPotentialCompaniesForTier(in_bus_rel_type_id, in_bus_rel_tier_id, v_descendants, in_search_term, out_cur);
END;

PROCEDURE GetGraphCompanies(
	in_bus_rel_type_id			IN	business_relationship_company.business_relationship_id%TYPE,
	in_company_sids				IN	T_FILTERED_OBJECT_TABLE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_visible_company_sids		security.T_SID_TABLE := company_pkg.GetVisibleCompanySids;
	v_viewable_company_sids		security.T_SID_TABLE := type_capability_pkg.GetCapableCompanySids(v_visible_company_sids, chain_pkg.VIEW_BUSINESS_RELATIONSHIPS, chain_pkg.VIEW_BUS_REL_REVERSED);
	v_company_sids				security.T_SID_TABLE;
	v_bus_rel_ids				security.T_SID_TABLE;
	v_bus_rel_comps				T_BUS_REL_COMP_TABLE;
BEGIN
	SELECT object_id
	  BULK COLLECT INTO v_company_sids
	  FROM TABLE(in_company_sids);

	INTERNAL_GetBusRelComps(
		in_starting_company_sids => v_company_sids,
		in_bus_rel_type_id => in_bus_rel_type_id,
		in_viewable_company_sids => v_viewable_company_sids,
		in_include_inactive => 0,
		out_bus_rel_comps => v_bus_rel_comps		
	);

	OPEN out_cur FOR
		SELECT t.business_relationship_id, brt.tier, t.pos, t.company_sid
		  FROM TABLE(v_bus_rel_comps) t
		  JOIN company c ON c.company_sid = t.company_sid
		  JOIN business_relationship_tier brt ON brt.business_relationship_tier_id = t.business_relationship_tier_id
		 WHERE c.deleted = 0
		   AND c.pending = 0
		 GROUP BY t.business_relationship_id, brt.tier, t.pos, t.company_sid
		 ORDER BY t.business_relationship_id, brt.tier, t.pos;
END;

PROCEDURE SearchCompaniesByBusRelType(
	in_bus_rel_type_id			IN	business_relationship.business_relationship_type_id%TYPE,
	in_search_term 				IN  VARCHAR2,
	in_page   					IN  NUMBER,
	in_page_size    			IN  NUMBER,
	out_count_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_bus_rel_ids				security.T_SID_TABLE;
	v_results					security.T_SID_TABLE;
	v_viewable_company_sids		security.T_SID_TABLE := type_capability_pkg.GetCapableCompanySids(NULL, chain_pkg.VIEW_BUSINESS_RELATIONSHIPS, chain_pkg.VIEW_BUS_REL_REVERSED);
BEGIN
	SELECT br.business_relationship_id
	  BULK COLLECT INTO v_bus_rel_ids
		  FROM business_relationship br
		 WHERE br.business_relationship_type_id = in_bus_rel_type_id
		   AND EXISTS (
				SELECT NULL
				  FROM business_relationship_period brp
				 WHERE br.business_relationship_id = brp.business_relationship_id
				   AND brp.start_dtm <= SYSDATE
				   AND (brp.end_dtm IS NULL OR brp.end_dtm > SYSDATE)
		   );

	SELECT brc.company_sid
	  BULK COLLECT INTO v_results
	  FROM business_relationship_company brc
	  JOIN company c ON c.company_sid = brc.company_sid
	  JOIN TABLE(v_viewable_company_sids) view_cts ON view_cts.column_value = c.company_sid
	  JOIN TABLE(v_bus_rel_ids) ids ON ids.column_value = brc.business_relationship_id
	 WHERE c.deleted = 0
	   AND c.pending = 0
	   AND ((in_search_term IS NULL OR LOWER(c.name) LIKE '%'||LOWER(TRIM(in_search_term)) || '%')
			OR (
				SELECT COUNT(*) 
					  FROM company_reference compref
					 WHERE compref.app_sid = c.app_sid
					   AND compref.company_sid = c.company_sid
					   AND LOWER(compref.value) = LOWER(TRIM(in_search_term))
			   ) > 0
		)
	GROUP BY brc.company_sid;
		
	company_pkg.CollectSearchResults(v_results, in_page, in_page_size, out_count_cur, out_result_cur);
END;

END;
/
