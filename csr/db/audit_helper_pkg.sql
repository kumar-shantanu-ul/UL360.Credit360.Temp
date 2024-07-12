create or replace PACKAGE csr.audit_helper_pkg AS

PROCEDURE ReaggregateAllIndicators(
	in_flow_sid					IN  security.security_pkg.T_SID_ID,
	in_flow_item_id				IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id			IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id				IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key	IN  csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text				IN  flow_state_log.comment_text%TYPE,
	in_user_sid					IN  security.security_pkg.T_SID_ID
);

PROCEDURE PublishSurveyScoresToSupplier(
	in_flow_sid					IN  security.security_pkg.T_SID_ID,
	in_flow_item_id				IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id			IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id				IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key	IN  csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text				IN  flow_state_log.comment_text%TYPE,
	in_user_sid					IN  security.security_pkg.T_SID_ID
);

PROCEDURE PublishSurveyScoresToProperty(
	in_flow_sid					IN  security.security_pkg.T_SID_ID,
	in_flow_item_id				IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id			IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id				IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key	IN  csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text				IN  flow_state_log.comment_text%TYPE,
	in_user_sid					IN  security.security_pkg.T_SID_ID
);

PROCEDURE PublishSurveyScoresToPermit(
	in_flow_sid					IN  security.security_pkg.T_SID_ID,
	in_flow_item_id				IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id			IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id				IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key	IN  csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text				IN  flow_state_log.comment_text%TYPE,
	in_user_sid					IN  security.security_pkg.T_SID_ID
);

PROCEDURE ApplyAuditScoresToSupplier(
	in_flow_sid					IN  security.security_pkg.T_SID_ID,
	in_flow_item_id				IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id			IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id				IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key	IN  csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text				IN  flow_state_log.comment_text%TYPE,
	in_user_sid					IN  security.security_pkg.T_SID_ID
);

PROCEDURE ApplyAuditNCScoreToSupplier(
	in_flow_sid					IN  security.security_pkg.T_SID_ID,
	in_flow_item_id				IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id			IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id				IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key	IN  csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text				IN  flow_state_log.comment_text%TYPE,
	in_user_sid					IN  security.security_pkg.T_SID_ID
);

PROCEDURE SetMatchingSupplierFlowState(
	in_flow_sid					IN  security.security_pkg.T_SID_ID,
	in_flow_item_id				IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id			IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id				IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key	IN  csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text				IN  csr_data_pkg.T_FLOW_COMMENT_TEXT,
	in_user_sid					IN  security.security_pkg.T_SID_ID
);

PROCEDURE CheckSurveySubmission(
	in_flow_sid					IN  security.security_pkg.T_SID_ID,
	in_flow_item_id				IN  csr.csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id			IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id				IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key	IN  csr.csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text				IN  csr.csr_data_pkg.T_FLOW_COMMENT_TEXT,
	in_user_sid					IN  security.security_pkg.T_SID_ID
);

PROCEDURE CheckForFindingsCreated(
	in_flow_sid						IN  security.security_pkg.T_SID_ID,
	in_flow_item_id					IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id				IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id					IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key		IN  csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text					IN  csr_data_pkg.T_FLOW_COMMENT_TEXT,
	in_user_sid						IN  security.security_pkg.T_SID_ID
);

END audit_helper_pkg;
/
