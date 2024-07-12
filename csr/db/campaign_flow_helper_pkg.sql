CREATE OR REPLACE PACKAGE csr.campaign_flow_helper_pkg AS

PROCEDURE GenerateInvolmTypeAlertEntries(
	in_flow_item_id 				IN flow_item.flow_item_id%TYPE,
	in_set_by_user_sid				IN security.security_pkg.T_SID_ID,
	in_flow_transition_alert_id  	IN flow_transition_alert.flow_transition_alert_id%TYPE,
	in_flow_involvement_type_id  	IN flow_involvement_type.flow_involvement_type_id%TYPE,
	in_flow_state_log_id 			IN flow_state_log.flow_state_log_id%TYPE,
	in_subject_override				IN flow_item_generated_alert.subject_override%TYPE DEFAULT NULL,
	in_body_override				IN flow_item_generated_alert.body_override%TYPE DEFAULT NULL
);

FUNCTION GetFlowRegionSids(
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE
)RETURN security.T_SID_TABLE;

END campaign_flow_helper_pkg;
/
