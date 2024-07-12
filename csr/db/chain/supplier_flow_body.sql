CREATE OR REPLACE PACKAGE BODY CHAIN.supplier_flow_pkg
IS

PROCEDURE RelationshipActivated (
	in_purchaser_company_sid		IN	security_pkg.T_SID_ID,
	in_supplier_company_sid			IN	security_pkg.T_SID_ID
)
AS
	v_flow_sid							security_pkg.T_SID_ID;
	v_flow_item_id						chain.supplier_relationship.flow_item_id%TYPE;
	v_new_item_created					NUMBER(1) := 0;
	v_create_one_flow_item_comp			customer_options.create_one_flow_item_for_comp%TYPE;
BEGIN
	BEGIN
		SELECT flow_item_id
		  INTO v_flow_item_id
		  FROM chain.supplier_relationship
		 WHERE purchaser_company_sid = in_purchaser_company_sid
		   AND supplier_company_sid = in_supplier_company_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_flow_item_id := NULL;
	END;

	IF v_flow_item_id IS NOT NULL THEN
		-- nothing to do, already has flow item
		RETURN;
	END IF;
	
	-- find the flow for this relationship type
	BEGIN
		SELECT flow_sid
		  INTO v_flow_sid
		  FROM company_type_relationship ctr,
			   company pc, company sc
		 WHERE pc.company_type_id = ctr.primary_company_type_id
		   AND pc.company_sid = in_purchaser_company_sid
		   AND sc.company_type_id = ctr.secondary_company_type_id
		   AND sc.company_sid = in_supplier_company_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_flow_sid := NULL;
	END;

	IF v_flow_sid IS NULL THEN
		-- company type relationship has no flow
		RETURN;
	END IF;

	-- the customer may have their own logic for flow item IDs
	-- e.g. to share a single flow item id between supplier companies
	chain_link_pkg.FindSupplierRelFlowItemId(in_purchaser_company_sid, in_supplier_company_sid, v_flow_sid, v_flow_item_id);

	IF v_flow_item_id IS NULL THEN
		SELECT create_one_flow_item_for_comp
		  INTO v_create_one_flow_item_comp
		  FROM customer_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
		  
		IF v_create_one_flow_item_comp = 1 THEN
			v_flow_item_id := GetSingleFlowItemForSupplier(in_supplier_company_sid, v_flow_sid);
		END IF;
	END IF;	

	IF v_flow_item_id IS NULL THEN
		csr.flow_pkg.AddFlowItem(v_flow_sid, v_flow_item_id);
		v_new_item_created := 1;
	END IF;

	UPDATE supplier_relationship
	   SET flow_item_id = v_flow_item_id
	 WHERE purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid;
		
	chain_link_pkg.AfterRelFlowItemActivate(v_new_item_created, in_purchaser_company_sid, in_supplier_company_sid, v_flow_sid, v_flow_item_id);
END;

FUNCTION GetSingleFlowItemForSupplier(
	in_supplier_company_sid			IN	security_pkg.T_SID_ID,
	in_flow_sid						IN	security_pkg.T_SID_ID
) RETURN supplier_relationship.flow_item_id%TYPE
AS
	v_flow_item_id						supplier_relationship.flow_item_id%TYPE;
BEGIN
	-- get exactly one existing flow item for supplier_sid and flow_sid
	BEGIN
		SELECT DISTINCT sr.flow_item_id
		  INTO v_flow_item_id
		  FROM supplier_relationship sr
		  JOIN csr.flow_item fi ON sr.flow_item_id = fi.flow_item_id
		 WHERE fi.flow_sid = in_flow_sid
		   AND sr.supplier_company_sid = in_supplier_company_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_flow_item_id := NULL;
		WHEN TOO_MANY_ROWS THEN
			v_flow_item_id := NULL;
	END;
	RETURN v_flow_item_id;
END;

FUNCTION GetFlowRegionSids(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN security.T_SID_TABLE
AS
	v_region_sids_t			security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
BEGIN
	SELECT s.region_sid
	  BULK COLLECT INTO v_region_sids_t
	  FROM supplier_relationship sr
	  JOIN csr.supplier s ON sr.supplier_company_sid = s.company_sid
	 WHERE sr.app_sid = security_pkg.getApp
	   AND flow_item_id = in_flow_item_id
	   AND sr.active = 1
	   AND sr.deleted = 0;
	
	RETURN v_region_sids_t;
END;

FUNCTION FlowItemRecordExists(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN NUMBER
AS
	v_count					NUMBER;
BEGIN
	
	SELECT DECODE(count(*), 0, 0, 1)
	  INTO v_count
	  FROM supplier_relationship sr
	  JOIN csr.supplier s ON sr.supplier_company_sid = s.company_sid
	 WHERE sr.app_sid = security_pkg.getApp
	   AND flow_item_id = in_flow_item_id
	   AND sr.active = 1
	   AND sr.deleted = 0;
	   
	RETURN v_count;
END;

PROCEDURE GenerateInvolmTypeAlertEntries(
	in_flow_item_id 				IN csr.flow_item.flow_item_id%TYPE, 
	in_set_by_user_sid				IN security_pkg.T_SID_ID,
	in_flow_transition_alert_id  	IN csr.flow_transition_alert.flow_transition_alert_id%TYPE,
	in_flow_involvement_type_id  	IN csr.flow_involvement_type.flow_involvement_type_id%TYPE,
	in_flow_state_log_id 			IN csr.flow_state_log.flow_state_log_id%TYPE,
	in_subject_override				IN csr.flow_item_generated_alert.subject_override%TYPE DEFAULT NULL, --needed for dynamic call
	in_body_override				IN csr.flow_item_generated_alert.body_override%TYPE DEFAULT NULL --needed for dynamic call
)
AS
BEGIN
	IF in_flow_involvement_type_id = csr.csr_data_pkg.FLOW_INV_TYPE_SUPPLIER THEN
		INSERT INTO csr.flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id, 
			from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id)
		SELECT app_sid, csr.flow_item_gen_alert_id_seq.nextval, in_flow_transition_alert_id, 
			in_set_by_user_sid, to_user_sid, NULL, in_flow_item_id, in_flow_state_log_id
		  FROM (
			SELECT DISTINCT sr.app_sid, cu.user_sid to_user_sid
			  FROM supplier_relationship sr
			  JOIN v$company_user cu ON sr.supplier_company_sid = cu.company_sid
			 WHERE sr.flow_item_id = in_flow_item_id
			   AND sr.active = 1
			   AND sr.deleted = 0
			   AND NOT EXISTS(
				SELECT 1 
				  FROM csr.flow_item_generated_alert figa
				 WHERE figa.app_sid = sr.app_sid
				   AND figa.flow_transition_alert_id = in_flow_transition_alert_id
				   AND figa.flow_state_log_id = in_flow_state_log_id
				   AND figa.to_user_sid = cu.user_sid
			  )
		 );
	ELSE
		--non restricted purchaser pseudo-roles
		INSERT INTO csr.flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id, 
			from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id)
		SELECT app_sid, csr.flow_item_gen_alert_id_seq.nextval, in_flow_transition_alert_id, 
			in_set_by_user_sid, to_user_sid, NULL, in_flow_item_id, in_flow_state_log_id
		  FROM (
			SELECT DISTINCT sr.app_sid, cu.user_sid to_user_sid
			  FROM supplier_relationship sr
			  JOIN company pc ON pc.company_sid = sr.purchaser_company_sid
			  JOIN company sc ON sc.company_sid = sr.supplier_company_sid
	  		  JOIN supplier_involvement_type sit
			    ON (sit.user_company_type_id IS NULL OR sit.user_company_type_id = pc.company_type_id)
			   AND (sit.page_company_type_id IS NULL OR sit.page_company_type_id = sc.company_type_id)
			   AND (sit.purchaser_type = chain_pkg.PURCHASER_TYPE_ANY
			    OR (sit.purchaser_type = chain_pkg.PURCHASER_TYPE_PRIMARY AND sr.is_primary = 1)
			    OR (sit.purchaser_type = chain_pkg.PURCHASER_TYPE_OWNER AND pc.company_sid = sc.parent_sid)
				)
			  JOIN v$company_user cu ON sr.purchaser_company_sid = cu.company_sid   
			 WHERE sr.flow_item_id = in_flow_item_id
			   AND sit.flow_involvement_type_id = in_flow_involvement_type_id
			   AND sr.active = 1
			   AND sr.deleted = 0
			   AND sit.restrict_to_role_sid IS NULL
			   AND NOT EXISTS(
				SELECT 1 
				  FROM csr.flow_item_generated_alert figa
				 WHERE figa.app_sid = sr.app_sid
				   AND figa.flow_transition_alert_id = in_flow_transition_alert_id
				   AND figa.flow_state_log_id = in_flow_state_log_id
				   AND figa.to_user_sid = cu.user_sid
			  )
		 );
		
		--RRM (on purchaser region) restricted purchaser pseudo-roles
		INSERT INTO csr.flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id, 
			from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id)
		SELECT app_sid, csr.flow_item_gen_alert_id_seq.nextval, in_flow_transition_alert_id, 
			in_set_by_user_sid, to_user_sid, NULL, in_flow_item_id, in_flow_state_log_id
		  FROM (
			SELECT DISTINCT sr.app_sid, cu.user_sid to_user_sid
			  FROM supplier_relationship sr
			  JOIN company pc ON pc.company_sid = sr.purchaser_company_sid
			  JOIN company sc ON sc.company_sid = sr.supplier_company_sid
	  		  JOIN supplier_involvement_type sit
			    ON (sit.user_company_type_id IS NULL OR sit.user_company_type_id = pc.company_type_id)
			   AND (sit.page_company_type_id IS NULL OR sit.page_company_type_id = sc.company_type_id)
			   AND (sit.purchaser_type = chain_pkg.PURCHASER_TYPE_ANY
			    OR (sit.purchaser_type = chain_pkg.PURCHASER_TYPE_PRIMARY AND sr.is_primary = 1)
			    OR (sit.purchaser_type = chain_pkg.PURCHASER_TYPE_OWNER AND pc.company_sid = sc.parent_sid)
				)
			  JOIN csr.supplier ps ON ps.company_sid = sr.purchaser_company_sid
			  JOIN v$company_user cu ON sr.purchaser_company_sid = cu.company_sid
			  JOIN csr.region_role_member rrm
				ON rrm.region_sid = ps.region_sid
			   AND rrm.user_sid = cu.user_sid
			   AND rrm.role_sid = sit.restrict_to_role_sid
			 WHERE sr.flow_item_id = in_flow_item_id
			   AND sit.flow_involvement_type_id = in_flow_involvement_type_id
			   AND sr.active = 1
			   AND sr.deleted = 0
			   AND sit.restrict_to_role_sid IS NOT NULL
			   AND NOT EXISTS(
				SELECT 1 
				  FROM csr.flow_item_generated_alert figa
				 WHERE figa.app_sid = sr.app_sid
				   AND figa.flow_transition_alert_id = in_flow_transition_alert_id
				   AND figa.flow_state_log_id = in_flow_state_log_id
				   AND figa.to_user_sid = cu.user_sid
			  )
		 );
	END IF;
END;

PROCEDURE GetFlowAlerts(
	out_flow_alerts				OUT	security_pkg.T_OUTPUT_CUR,
	out_primary_purchasers		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_supplier_company_sids			security.T_SID_TABLE;
BEGIN

	OPEN out_flow_alerts FOR
		SELECT x.app_sid, x.flow_item_id, x.flow_item_generated_alert_id, x.to_user_sid, x.customer_alert_type_id, 
			x.from_state_label, x.to_state_label, 
			x.set_by_user_sid, x.set_by_full_name, x.set_by_email, x.set_by_user_name,
			x.to_user_sid, x.to_full_name, x.to_email, x.to_friendly_name, x.to_user_name,
			s.region_sid, x.comment_text, flow_alert_helper, 
			x.to_initiator, x.flow_item_id,
			c.name company_name, c.company_sid, c.phone, c.fax, c.website, c.address_1, c.address_2, c.address_3, c.address_4,
			c.city, c.postcode, c.state, c.country_code, cnt.name country_name, c.company_type_id, ct.lookup_key company_type_lookup,
			pc.company_sid parent_company_sid, pc.name parent_company_name
		  FROM( 
				SELECT figa.app_sid, figa.flow_item_id, sr.supplier_company_Sid, Figa.To_User_Sid, Figa.Flow_State_Log_Id, figa.customer_alert_type_id, 
					figa.to_initiator, figa.flow_alert_helper, figa.comment_text, figa.to_user_name, figa.to_friendly_name, figa.to_email,
					figa.to_full_name, figa.set_by_user_sid, figa.set_by_full_name, figa.set_by_user_name, figa.set_by_email, figa.to_state_label,
					figa.from_state_label, figa.flow_item_generated_alert_id,
				  ROW_NUMBER() over (PARTITION BY flow_item_generated_alert_id ORDER BY flow_state_log_id, supplier_company_sid) rn
				  FROM csr.v$open_flow_item_gen_alert figa
				  JOIN supplier_relationship sr ON figa.flow_item_id = sr.flow_item_id AND figa.app_sid = sr.app_sid 
				 WHERE sr.active = 1
				   AND sr.deleted = 0            
			)x 
		  JOIN csr.supplier s ON x.supplier_company_sid = s.company_sid AND x.app_sid = s.app_sid
		  JOIN company c ON s.company_sid = c.company_sid AND c.app_sid = s.app_sid
		  JOIN company_type ct ON c.company_type_id = ct.company_type_id
		  JOIN v$country cnt ON c.country_code = cnt.country_code
		  LEFT JOIN company pc ON c.parent_sid = pc.company_sid AND c.app_sid = pc.app_sid
		 WHERE x.rn = 1 --1 flow_item_gener might be associated to multiple supplier_relationship records - could have used distinct instead re-joining with flow_state_log
		 ORDER BY x.app_sid, x.customer_alert_type_id, x.to_user_sid, x.flow_item_id;

	SELECT DISTINCT supplier_company_sid
	  BULK COLLECT INTO v_supplier_company_sids
	  FROM csr.v$open_flow_item_gen_alert figa
	  JOIN supplier_relationship sr ON figa.flow_item_id = sr.flow_item_id AND figa.app_sid = sr.app_sid
	 WHERE sr.active = 1
	   AND sr.deleted = 0;

	OPEN out_primary_purchasers FOR
		SELECT DISTINCT sr.supplier_company_sid company_sid, pc.company_sid purchaser_company_sid,
			   pc.name purchaser_company_name, pc.company_type_id purchaser_type_id, ct.lookup_key purchaser_type_lookup_key
		  FROM TABLE(v_supplier_company_sids) s
		  JOIN supplier_relationship sr ON s.column_value = sr.supplier_company_sid
		  JOIN company pc ON sr.purchaser_company_sid = pc.company_sid
		  JOIN company_type ct ON pc.company_type_id = ct.company_type_id
		 WHERE sr.is_primary = 1
		   AND sr.deleted = 0
		   AND sr.active = 1; 
END;

PROCEDURE GetSupplierCurrentState(
	in_supplier_company_sid 	IN	security_pkg.T_SID_ID,
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	--v_purchaser_company_sid 	security_pkg.T_SID_ID := NVL(in_purchaser_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
BEGIN

-- IF v_purchaser_company_sid IS NULL THEN
	-- RAISE_APPLICATION_ERROR(-20001, 'No purchaser company provided or none set in session.');
-- END IF;

OPEN out_cur FOR
	SELECT fs.flow_state_id, fs.label, fs.state_colour, fs.lookup_key, fi.flow_item_id, sr.purchaser_company_sid
	  FROM supplier_relationship sr
	  JOIN csr.flow_item fi
		ON sr.flow_item_id = fi.flow_item_id
	  JOIN csr.flow_state fs
		ON fi.current_state_id = fs.flow_state_id
	 WHERE sr.supplier_company_sid = in_supplier_company_sid
	   AND in_purchaser_company_sid IS NULL OR sr.purchaser_company_sid = in_purchaser_company_sid;
END;

PROCEDURE GetAllSupplierFlowStates(
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_type_id		company_type.company_type_id%TYPE;
BEGIN
	SELECT vc.company_type_id 
	  INTO v_company_type_id
	  FROM company vc 
	 WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');

	OPEN out_cur FOR
		SELECT DISTINCT fs.flow_sid, fs.flow_state_id, fs.label, fs.state_colour, fs.lookup_key
		  FROM company_type_relationship ctr
		  JOIN csr.flow_state fs
			ON fs.flow_sid = ctr.flow_sid
		 WHERE (ctr.primary_company_type_id = v_company_type_id
		    OR ctr.secondary_company_type_id = v_company_type_id)
		   AND fs.is_deleted = 0
		 ORDER BY fs.flow_sid;
END;

PROCEDURE  GetAllPurchrCntxtFlowsStates (
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_type_id		company_type.company_type_id%TYPE;
BEGIN
	-- base data, only context security required
	SELECT vc.company_type_id 
	  INTO v_company_type_id
	  FROM company vc 
	 WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');

	OPEN out_cur FOR
		SELECT DISTINCT fs.flow_sid, fs.flow_state_id, fs.label, fs.state_colour, fs.lookup_key
		  FROM company_type_relationship ctr
		  JOIN csr.flow_state fs ON fs.flow_sid = ctr.flow_sid
		 WHERE (ctr.primary_company_type_id = v_company_type_id)
		   AND fs.is_deleted = 0
		 ORDER BY fs.flow_sid;

END;

PROCEDURE GetSupplierInvolvementTypes (
	out_cur							OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT flow_involvement_type_id, user_company_type_id company_type_id, page_company_type_id,
			purchaser_type, restrict_to_role_sid
		  FROM supplier_involvement_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE SetSupplierInvolvementType(
	in_involvement_type_id			IN	csr.flow_involvement_type.flow_involvement_type_id%TYPE,
	in_user_company_type_id			IN	supplier_involvement_type.user_company_type_id%TYPE,
	in_page_company_type_id			IN	supplier_involvement_type.page_company_type_id%TYPE,
	in_purchaser_type				IN	supplier_involvement_type.purchaser_type%TYPE,
	in_restrict_to_role_sid			IN	supplier_involvement_type.restrict_to_role_sid%TYPE
)
AS
	v_cnt							NUMBER;
	v_dup_error						VARCHAR2(100) := 'The pseudo-role of this configuration already exists.';
BEGIN
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM supplier_involvement_type
	 WHERE flow_involvement_type_id = in_involvement_type_id;

	IF v_cnt = 0 THEN
		BEGIN
			INSERT INTO supplier_involvement_type (flow_involvement_type_id, user_company_type_id, page_company_type_id, purchaser_type, restrict_to_role_sid)
			VALUES (in_involvement_type_id, in_user_company_type_id, in_page_company_type_id, in_purchaser_type, in_restrict_to_role_sid);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				RAISE_APPLICATION_ERROR(-20001, v_dup_error);
		END;
	ELSE
		BEGIN
			UPDATE supplier_involvement_type
			   SET user_company_type_id = in_user_company_type_id,
				   page_company_type_id = in_page_company_type_id,
				   purchaser_type = in_purchaser_type,
				   restrict_to_role_sid = in_restrict_to_role_sid
			 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
			   AND flow_involvement_type_id = in_involvement_type_id;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				RAISE_APPLICATION_ERROR(-20001, v_dup_error);
		END;
	END IF;
END;

PROCEDURE DeleteSupplierInvolvementType (
	in_involvement_type_id			IN	csr.flow_involvement_type.flow_involvement_type_id%TYPE
)
AS
BEGIN
	DELETE FROM supplier_involvement_type
	 WHERE flow_involvement_type_id = in_involvement_type_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
END;

END supplier_flow_pkg;
/
