CREATE OR REPLACE PACKAGE  CHAIN.flow_form_pkg
IS

PROCEDURE GetQuestionnaireFlowMappings(
	out_cur		OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION GetQuestionnaireTypeId(
	in_flow_sid				IN security_pkg.T_SID_ID
)RETURN questionnaire_type.questionnaire_type_id%TYPE;

PROCEDURE GetQuestionnaireType(
	in_flow_sid		IN security.security_pkg.T_SID_ID,
	out_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE FillOracleSchemaTableName(
	in_flow_sid  			 IN security.security_pkg.T_SID_ID,
	out_oracle_schema		 OUT cms.tab.oracle_schema%TYPE,
	out_oracle_table		 OUT cms.tab.oracle_table%TYPE
);

PROCEDURE StartFlow(
	in_company_sids		IN security_pkg.T_SID_IDS,
	in_flow_sid 			IN security.security_pkg.T_SID_ID
);

PROCEDURE StartWorkflowForRegion(
	in_region_sid 				IN security.security_pkg.T_SID_ID, 
	in_flow_sid  				IN security.security_pkg.T_SID_ID,
	out_item_id					OUT security_pkg.T_SID_ID,
	out_flow_item_id 			OUT csr.flow_item.flow_item_id%TYPE
);

PROCEDURE GetFlowData(
	in_flow_sid 				IN security.security_pkg.T_SID_ID,
	in_compound_filter_id		IN chain.compound_filter.compound_filter_id%TYPE DEFAULT NULL,
	out_flow_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_user_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFlowUsers(
	in_flow_sid 					IN 	security.security_pkg.T_SID_ID,
	out_user_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSupplierFlowUsers(
	in_flow_sid 					IN 	security.security_pkg.T_SID_ID,
	in_supplier_company_sid		IN 	security.security_pkg.T_SID_ID,
	out_user_cur				OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION GetSupplierSid(
	in_flow_sid			IN 	security.security_pkg.T_SID_ID,
	in_flow_item_id 	IN 	csr.flow_item.flow_item_id%TYPE
) RETURN security.security_pkg.T_SID_ID;

PROCEDURE GetWorkFlowFilters(
	out_filters		OUT SYS_REFCURSOR
);

END flow_form_pkg;
/

