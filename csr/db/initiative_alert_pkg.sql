CREATE OR REPLACE PACKAGE CSR.initiative_alert_pkg
IS

PROCEDURE GenerateExtraFLowAlertEntries(
	in_flow_item_id					IN	flow_item.flow_item_id%TYPE,
	in_set_by_user_sid				IN	security_pkg.T_SID_ID,
	in_flow_state_transition_id 	IN  flow_state_transition.flow_state_transition_id%TYPE,
	in_flow_state_log_id			IN	flow_state_log.flow_state_log_id%TYPE
);

FUNCTION GetFlowRegionSids(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN security.T_SID_TABLE;

FUNCTION FlowItemRecordExists(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN NUMBER;

PROCEDURE GetFlowAlerts(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

-- Get all flows that are classified as initiatives
PROCEDURE GetFlowAlertTypes(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

-- Have to run flow_pkg.BeginAlertBatchRun before calling this
PROCEDURE GetPeriodicFlowAlerts(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

END initiative_alert_pkg;
/
