CREATE OR REPLACE PACKAGE csr.workflow_api_pkg AS

PROCEDURE GetPermissibleTransitions(
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE,
	out_transitions_cur		OUT	SYS_REFCURSOR
);

PROCEDURE SetItemState_SEC(
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE,
	in_transition_id		IN	flow_state_transition.flow_state_transition_id%TYPE,
	in_comment_text			IN	flow_state_log.comment_text%TYPE,
	out_flow_state_log_cur	OUT	SYS_REFCURSOR,
	out_flow_state_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetStateTransitionDetail(
	in_flow_transition_id			IN	flow_state_transition.flow_state_transition_id%TYPE,
	out_detail						OUT	SYS_REFCURSOR
);

PROCEDURE GetFlowStateSurveyTags_UNSEC(
	in_flow_item_id				IN	flow_item.flow_item_id%TYPE,
	out_flow_state_tags_cur		OUT	SYS_REFCURSOR
);

FUNCTION GetItemCapabilityPermission (
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	in_capability_id	IN	flow_capability.flow_capability_id%TYPE
) RETURN security_pkg.T_PERMISSION;

PROCEDURE GetFlowState_UNSEC(
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE,
	out_flow_state_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetPermissibleIds (
	in_capability_id			IN	flow_capability.flow_capability_id%TYPE,
	in_region_sid				IN	flow_item_region.region_sid%TYPE,
	out_permissible_ids_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetFlowStateLogs (
	in_flow_item_id				IN	flow_state_log.flow_item_id%TYPE,
	out_flow_state_logs_cur		OUT	SYS_REFCURSOR
);

END;
/

