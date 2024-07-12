CREATE OR REPLACE PACKAGE BODY CHAIN.flow_form_pkg
IS

PROCEDURE GetQuestionnaireFlowMappings(
	out_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	
	OPEN out_cur FOR
		SELECT questionnaire_type_id, flow_sid
		  FROM flow_questionnaire_type
		 WHERE app_sid = security_pkg.getApp;
END;

FUNCTION GetQuestionnaireTypeId(
	in_flow_sid				IN security_pkg.T_SID_ID
)RETURN questionnaire_type.questionnaire_type_id%TYPE
AS
	v_qnr_type_id 	questionnaire_type.questionnaire_type_id%TYPE;
BEGIN

	BEGIN
		SELECT questionnaire_type_id
		  INTO v_qnr_type_id
		  FROM flow_questionnaire_type
		 WHERE app_sid = security_pkg.getApp
		   AND flow_sid = in_flow_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'No questionnaire types found for the workflow with sid:' || in_flow_sid ||' '||dbms_utility.format_error_backtrace);
	END;
	RETURN v_qnr_type_id;
END;

PROCEDURE GetQuestionnaireType(
	in_flow_sid		IN security.security_pkg.T_SID_ID,
	out_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_qnr_type_id 	questionnaire_type.questionnaire_type_id%TYPE DEFAULT GetQuestionnaireTypeId(in_flow_sid);
BEGIN
	
	OPEN out_cur FOR
		SELECT questionnaire_type_id, name
		  FROM questionnaire_type
		 WHERE app_sid = security_pkg.getApp
		   AND questionnaire_type_id = v_qnr_type_id;
END;

PROCEDURE FillOracleSchemaTableName(
	in_flow_sid  			 IN security.security_pkg.T_SID_ID,
	out_oracle_schema		 OUT cms.tab.oracle_schema%TYPE,
	out_oracle_table		 OUT cms.tab.oracle_table%TYPE
)
AS 
BEGIN

	SELECT oracle_schema, oracle_table
	  INTO out_oracle_schema, out_oracle_table
	  FROM cms.tab
	 WHERE flow_sid = in_flow_sid;
	 
END;

PROCEDURE StartWorkflowForRegion(
	in_region_sid 				IN security.security_pkg.T_SID_ID, 
	in_flow_sid  				IN security.security_pkg.T_SID_ID,
	out_item_id					OUT security_pkg.T_SID_ID,
	out_flow_item_id 			OUT csr.flow_item.flow_item_id%TYPE
)
AS
	v_oracle_schema		    cms.tab.oracle_schema%TYPE;
	v_oracle_table		 	cms.tab.oracle_table%TYPE;
	v_company_sid			security_pkg.T_SID_ID DEFAULT csr.supplier_pkg.GetCompanySid(in_region_sid);
BEGIN
	
	IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.MANAGE_WORKFLOWS)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You don''t have permissions starting a workflow for company with sid: '||v_company_sid);
	END IF;
	
	FillOracleSchemaTableName(in_flow_sid, v_oracle_schema, v_oracle_table);
		
	csr.flow_pkg.AddCmsItem(in_flow_sid, in_region_sid, out_flow_item_id);
	
	cms.cms_tab_pkg.InsertItem(
		in_oracle_schema => v_oracle_schema,
		in_oracle_table	 => v_oracle_table,
		in_title		 => NULL,
		in_region_sid	 => in_region_sid, 
		in_flow_item_id  => out_flow_item_id,
		out_item_Id		 => out_item_id
	);	
	
	chain.chain_link_pkg.StartWorkflowForRegion(in_region_sid, in_flow_sid, v_oracle_schema, v_oracle_table, out_flow_item_id);
END;

PROCEDURE StartFlow(
	in_company_sids		IN	security_pkg.T_SID_IDS,
	in_flow_sid  	    IN 	security.security_pkg.T_SID_ID
)
AS
	v_company_sids_table	security.T_SID_TABLE;
	v_item_id				security.security_pkg.T_SID_ID;
	v_flow_item_id 			csr.flow_item.flow_item_id%TYPE;
BEGIN

	v_company_sids_table := security_pkg.SidArrayToTable(in_company_sids);
	--start a form for each selected region
	FOR r IN (
		SELECT s.region_sid 
		  FROM csr.supplier s
		  JOIN TABLE(v_company_sids_table) fs ON s.company_sid = fs.column_value 
	 ) 
	LOOP
		StartWorkflowForRegion(r.region_sid, in_flow_sid, v_item_id, v_flow_item_id);
	END LOOP;
END;

PROCEDURE GetFlowData(
	in_flow_sid  				IN 	security.security_pkg.T_SID_ID,
	in_compound_filter_id		IN	chain.compound_filter.compound_filter_id%TYPE DEFAULT NULL,
	out_flow_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_user_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_filtered_sids		T_FILTERED_OBJECT_TABLE;
	v_oracle_schema		cms.tab.oracle_schema%TYPE;
	v_oracle_table		cms.tab.oracle_table%TYPE;
BEGIN

	FillOracleSchemaTableName(in_flow_sid, v_oracle_schema, v_oracle_table);
	
	IF in_compound_filter_id IS NOT NULL THEN
		company_filter_pkg.GetFilteredIds(
			in_compound_filter_id => in_compound_filter_id,
			in_id_list				=> NULL,
			out_id_list				=> v_filtered_sids);

		OPEN out_flow_cur FOR
			'SELECT c.name, c.company_sid, cnt.name country_name, fs.label current_state, fsl.set_dtm last_updated, fs.is_final, fi.flow_item_id
			   FROM company c 
			   JOIN csr.supplier s ON s.company_sid = c.company_sid
			   JOIN chain.supplier_relationship sr ON sr.purchaser_company_sid = SYS_CONTEXT(''SECURITY'', ''CHAIN_COMPANY'') AND sr.supplier_company_sid = c.company_sid AND sr.active = 1
			   LEFT JOIN v$country cnt ON c.country_code = cnt.country_code
			   LEFT JOIN ' || v_oracle_schema || '.' || v_oracle_table || ' t ON t.region_sid = s.region_sid
			   LEFT JOIN csr.flow_item fi ON fi.flow_item_id = t.flow_item_id
			   LEFT JOIN csr.flow_state fs  ON fi.current_state_id = fs.flow_state_id
			   LEFT JOIN csr.flow_state_log fsl ON fsl.flow_state_log_id = fi.last_flow_state_log_id 
			   JOIN TABLE(:filter) filter ON s.company_sid = filter.object_id
			  WHERE c.deleted = 0
			    AND c.pending = 0
			  ORDER BY c.name, fi.flow_item_id DESC'
			USING v_filtered_sids;
	ELSE

		OPEN out_flow_cur FOR
			'SELECT c.name, c.company_sid, cnt.name country_name, fs.label current_state, fsl.set_dtm last_updated, fs.is_final, fi.flow_item_id
			   FROM company c 
			   JOIN csr.supplier s ON s.company_sid = c.company_sid
			   JOIN chain.supplier_relationship sr ON sr.purchaser_company_sid = SYS_CONTEXT(''SECURITY'', ''CHAIN_COMPANY'') AND sr.supplier_company_sid = c.company_sid AND sr.active = 1
			   LEFT JOIN v$country cnt ON c.country_code = cnt.country_code
			   LEFT JOIN ' || v_oracle_schema || '.' || v_oracle_table || ' t ON t.region_sid = s.region_sid
			   LEFT JOIN csr.flow_item fi ON fi.flow_item_id = t.flow_item_id
			   LEFT JOIN csr.flow_state fs  ON fi.current_state_id = fs.flow_state_id
			   LEFT JOIN csr.flow_state_log fsl ON fsl.flow_state_log_id = fi.last_flow_state_log_id 
			  WHERE c.deleted = 0
			    AND c.pending = 0
			  ORDER BY c.name, fi.flow_item_id DESC';
	END IF;
	
	GetFlowUsers(in_flow_sid, out_user_cur);	
END;

/* returns the supplier users who are role members with editable permission on the workflow default state */
PROCEDURE GetSupplierFlowUsers(
	in_flow_sid  				IN 	security.security_pkg.T_SID_ID,
	in_supplier_company_sid		IN 	security.security_pkg.T_SID_ID,
	out_user_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_user_cur FOR
		SELECT DISTINCT s.company_sid, cu.full_name, cu.email, cu.user_sid
		  FROM csr.flow f
		  JOIN csr.flow_state_role fsr ON f.default_state_id = fsr.flow_state_id
		  JOIN csr.region_role_member rrm ON fsr.role_sid = rrm.role_sid
		  JOIN csr.supplier s ON rrm.region_sid = s.region_sid 
		  JOIN company c ON s.company_sid = c.company_sid
		  JOIN v$company_user cu ON c.company_sid = cu.company_sid AND rrm.user_sid = cu.user_sid
		  JOIN v$supplier_relationship sr ON sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') AND sr.supplier_company_sid = c.company_sid
		 WHERE f.flow_sid = in_flow_sid
		   AND fsr.is_editable = 1 /* returns only the region role members with an editable role in the worklfow default state */
		   AND cu.account_enabled = 1
		   AND c.deleted = 0
		   AND c.pending = 0
		   AND (in_supplier_company_sid IS NULL OR c.company_sid = in_supplier_company_sid);

END;

/* returns all users that are role members with editable permission for the workflow default state */
PROCEDURE GetFlowUsers(
	in_flow_sid 	IN 	security.security_pkg.T_SID_ID,
	out_user_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetSupplierFlowUsers(in_flow_sid, NULL, out_user_cur);
END;

FUNCTION GetSupplierSid(
	in_flow_sid			IN 	security.security_pkg.T_SID_ID,
	in_flow_item_id 	IN 	csr.flow_item.flow_item_id%TYPE
) RETURN security.security_pkg.T_SID_ID
AS
	v_oracle_schema		    cms.tab.oracle_schema%TYPE;
	v_oracle_table		 	cms.tab.oracle_table%TYPE;
	v_supplier_sid		security.security_pkg.T_SID_ID;
BEGIN

	FillOracleSchemaTableName(in_flow_sid, v_oracle_schema, v_oracle_table);
	
	EXECUTE IMMEDIATE 'SELECT s.company_sid
						 FROM csr.supplier s 
					     JOIN '|| v_oracle_schema || '.' || v_oracle_table || ' t ON t.region_sid = s.region_sid
						WHERE t.flow_item_id = ' || in_flow_item_id
						INTO v_supplier_sid;
	
	RETURN v_supplier_sid;
END;

PROCEDURE GetWorkFlowFilters(
	out_filters		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_filters FOR
		SELECT flow_sid, saved_filter_sid
		  FROM flow_filter
		 WHERE app_sid = security_pkg.GetApp;
END;

END flow_form_pkg;
/
