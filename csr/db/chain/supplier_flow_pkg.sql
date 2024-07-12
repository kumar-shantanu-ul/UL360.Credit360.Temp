CREATE OR REPLACE PACKAGE CHAIN.supplier_flow_pkg
IS

PROCEDURE RelationshipActivated (
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID,
	in_supplier_company_sid 	IN	security_pkg.T_SID_ID
);

PROCEDURE GenerateInvolmTypeAlertEntries(
	in_flow_item_id 				IN csr.flow_item.flow_item_id%TYPE, 
	in_set_by_user_sid				IN security_pkg.T_SID_ID,
	in_flow_transition_alert_id  	IN csr.flow_transition_alert.flow_transition_alert_id%TYPE,
	in_flow_involvement_type_id  	IN csr.flow_involvement_type.flow_involvement_type_id%TYPE,
	in_flow_state_log_id 			IN csr.flow_state_log.flow_state_log_id%TYPE,
	in_subject_override				IN csr.flow_item_generated_alert.subject_override%TYPE DEFAULT NULL,
	in_body_override				IN csr.flow_item_generated_alert.body_override%TYPE DEFAULT NULL
);

FUNCTION GetFlowRegionSids(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN security.T_SID_TABLE;

FUNCTION FlowItemRecordExists(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN NUMBER;

PROCEDURE GetFlowAlerts(
	out_flow_alerts				OUT	security_pkg.T_OUTPUT_CUR,
	out_primary_purchasers		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSupplierCurrentState(
	in_supplier_company_sid 	IN	security_pkg.T_SID_ID,
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllSupplierFlowStates(
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE  GetAllPurchrCntxtFlowsStates (
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION GetSingleFlowItemForSupplier(
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_flow_sid					IN	security_pkg.T_SID_ID
) RETURN supplier_relationship.flow_item_id%TYPE;

PROCEDURE GetSupplierInvolvementTypes (
	out_cur							OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetSupplierInvolvementType(
	in_involvement_type_id			IN	csr.flow_involvement_type.flow_involvement_type_id%TYPE,
	in_user_company_type_id			IN	supplier_involvement_type.user_company_type_id%TYPE,
	in_page_company_type_id			IN	supplier_involvement_type.page_company_type_id%TYPE,
	in_purchaser_type				IN	supplier_involvement_type.purchaser_type%TYPE,
	in_restrict_to_role_sid			IN	supplier_involvement_type.restrict_to_role_sid%TYPE
);

PROCEDURE DeleteSupplierInvolvementType (
	in_involvement_type_id			IN	csr.flow_involvement_type.flow_involvement_type_id%TYPE
);

END supplier_flow_pkg;
/
