CREATE OR REPLACE PACKAGE CSR.flow_pkg AS

CUSTOMER_INV_TYPE_MIN		CONSTANT NUMBER(10)	:= 10000;

AUTO_TRANS_NEVER			CONSTANT NUMBER(1)	:= 0;
AUTO_TRANS_HOURS			CONSTANT NUMBER(1)	:= 1;
AUTO_TRANS_SCHEDULE			CONSTANT NUMBER(1)	:= 2;

PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

PROCEDURE TrashFlow(
	in_flow_sid		IN security_pkg.T_SID_ID
);

PROCEDURE CreateFlow(
	in_label			IN	flow.label%TYPE,
	in_parent_sid		IN	security_pkg.T_SID_ID,
	out_flow_sid		OUT	security_pkg.T_SID_ID
);

PROCEDURE CreateFlow(
	in_label			IN	flow.label%TYPE,
	in_parent_sid		IN	security_pkg.T_SID_ID,
	in_flow_alert_class	IN  flow.flow_alert_class%TYPE,
	out_flow_sid		OUT	security_pkg.T_SID_ID
);

PROCEDURE RenameFlow(
	in_flow_sid		IN	security_pkg.T_SID_ID,
	in_label		IN	flow.label%TYPE
);

PROCEDURE GetFlows(
	in_parent_sid		IN		security_pkg.T_SID_ID,
	out_flow_cur		OUT		SYS_REFCURSOR
);

PROCEDURE GetFlows(
	in_parent_sid		IN		security_pkg.T_SID_ID,
	in_flow_type		IN      flow.flow_alert_class%TYPE,
	out_flow_cur		OUT		SYS_REFCURSOR
);

PROCEDURE GetFlowsAndStates(
	in_parent_sid		IN		security_pkg.T_SID_ID,
	in_flow_type		IN      flow.flow_alert_class%TYPE,
	out_flow_cur		OUT		SYS_REFCURSOR,
	out_state_cur		OUT		SYS_REFCURSOR
);

PROCEDURE GetFlowsWithForms(
	in_parent_sid		IN		security_pkg.T_SID_ID,
	out_flow_cur		OUT		SYS_REFCURSOR
);

PROCEDURE GetFlow(
	in_flow_sid						IN		security_pkg.T_SID_ID,
	out_flow_cur					OUT		SYS_REFCURSOR,
	out_state_cur					OUT		SYS_REFCURSOR,
	out_state_role_cur				OUT		SYS_REFCURSOR,
	out_state_group_cur				OUT		SYS_REFCURSOR,
	out_state_col_cur				OUT		SYS_REFCURSOR,
	out_state_inv_cur				OUT		SYS_REFCURSOR,
	out_state_inv_cap_cur			OUT		SYS_REFCURSOR,
	out_trans_cur					OUT		SYS_REFCURSOR,
	out_trans_role_cur				OUT		SYS_REFCURSOR,
	out_trans_group_cur				OUT		SYS_REFCURSOR,
	out_trans_cms_user_cur			OUT		SYS_REFCURSOR,
	out_trans_inv_cur				OUT		SYS_REFCURSOR,
	out_trans_helper_cur			OUT		SYS_REFCURSOR,
	out_transition_alert_cur        OUT		SYS_REFCURSOR,
	out_transition_alert_role_cur	OUT		SYS_REFCURSOR,
	out_transition_alert_grp_cur	OUT		SYS_REFCURSOR,
	out_transition_alert_user_cur	OUT		SYS_REFCURSOR,
	out_trans_alert_cc_role_cur		OUT		SYS_REFCURSOR,
	out_trans_alert_cc_grp_cur		OUT		SYS_REFCURSOR,
	out_trans_alert_cc_user_cur		OUT		SYS_REFCURSOR,
	out_tsition_alert_cms_col_cur	OUT		SYS_REFCURSOR,
	out_transition_alert_inv_cur	OUT		SYS_REFCURSOR,
	out_state_alert_cur        		OUT		SYS_REFCURSOR,
	out_state_alert_role_cur		OUT		SYS_REFCURSOR,
	out_state_alert_group_cur		OUT		SYS_REFCURSOR,
	out_state_alert_user_cur		OUT		SYS_REFCURSOR,
	out_flow_state_group_cur		OUT		SYS_REFCURSOR,
	out_survey_tag_cur				OUT		SYS_REFCURSOR
);

PROCEDURE GetFlowStates(
	in_flow_sid 	IN 	security_pkg.T_SID_ID,
	out_cur 		OUT SYS_REFCURSOR,
	out_transitions OUT SYS_REFCURSOR
);

PROCEDURE GetFlowItem(
	in_flow_item_id				IN  flow_item.flow_item_id%TYPE,
	out_cur						OUT SYS_REFCURSOR,
	out_transition_cur 			OUT SYS_REFCURSOR,
	out_capability_cur			OUT SYS_REFCURSOR,
	out_survey_tag_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetFlowItemTransitions(
	in_flow_item_id		IN  flow_item.flow_item_id%TYPE,
	in_region_sids		IN  security_pkg.T_SID_IDS,
	out_cur 			OUT SYS_REFCURSOR
);

PROCEDURE GetFlowItemTransitions(
	in_flow_item_ids	IN  security_pkg.T_SID_IDS,
	in_region_sids		IN  security_pkg.T_SID_IDS,
	out_cur 			OUT SYS_REFCURSOR
);

PROCEDURE CreateState(
	in_flow_sid				IN	security_pkg.T_SID_ID,
	in_label				IN	flow_state.label%TYPE,
	in_lookup_key			IN	flow_state.lookup_key%TYPE DEFAULT NULL,
	in_flow_state_nature_id	IN	flow_state.flow_state_nature_id%TYPE,
	in_survey_editable		IN	flow_state.survey_editable%TYPE DEFAULT 1,
	out_flow_state_id		OUT	flow_state.flow_state_id%TYPE
);

PROCEDURE SetStateTransHelper(	
	in_flow_sid		IN 	security_pkg.T_SID_ID,
	in_helper_sp	IN	flow_state_trans_helper.helper_sp%TYPE,
	in_label		IN	flow_state_trans_helper.label%TYPE
);

PROCEDURE SetAlertHelper(	
	in_helper_sp	IN	flow_alert_helper.flow_alert_helper%TYPE,
	in_label		IN	flow_alert_helper.label%TYPE
);

PROCEDURE SetCmsAlertHelper(	
	in_tab_sid		IN	cms_alert_helper.tab_sid%TYPE,
	in_helper_sp	IN	cms_alert_helper.helper_sp%TYPE,
	in_label		IN	cms_alert_helper.description%TYPE
);

PROCEDURE RemoveStateTransHelper(	
	in_flow_sid		IN 	security_pkg.T_SID_ID,
	in_helper_sp	IN	flow_state_trans_helper.helper_sp%TYPE
);

PROCEDURE SetStateRoles(
	in_state_id					IN	flow_state.flow_state_id%TYPE,
	in_editable_role_sids		IN	security_pkg.T_SID_IDS,
	in_non_editable_role_sids	IN	security_pkg.T_SID_IDS,
	in_editable_col_sids		IN	security_pkg.T_SID_IDS,
	in_non_editable_col_sids	IN	security_pkg.T_SID_IDS,
	in_involved_type_ids		IN	security_pkg.T_SID_IDS,
	in_editable_group_sids		IN	security_pkg.T_SID_IDS,
	in_non_editable_group_sids	IN	security_pkg.T_SID_IDS
);

PROCEDURE DeleteState(
	in_flow_state_id	IN	flow_state.flow_state_id%TYPE,
	in_move_items_to	IN	flow_state.flow_state_id%TYPE DEFAULT NULL 
);

PROCEDURE AmendState(
	in_flow_state_id		IN	flow_state.flow_state_id%TYPE,
	in_label				IN	flow_state.label%TYPE,
	in_final				IN 	NUMBER,
	in_lookup_key			IN	flow_state.lookup_key%TYPE,
	in_state_colour			IN	flow_state.state_colour%TYPE,
	in_pos					IN	flow_state.pos%TYPE DEFAULT NULL,
	in_flow_state_nature_id	IN	flow_state.flow_state_nature_id%TYPE DEFAULT NULL,
	in_survey_editable		IN	flow_state.survey_editable%TYPE DEFAULT 1
);

PROCEDURE RemoveTransition(
	in_from_state_id	IN	flow_state_transition.from_state_id%TYPE,
	in_to_state_id		IN	flow_state_transition.to_state_id%TYPE
);

FUNCTION GetStateId(
	in_flow_sid		IN	security_pkg.T_SID_ID,
	in_lookup_key	IN	flow_state.lookup_key%TYPE
) RETURN security_pkg.T_SID_ID;

FUNCTION GetNextStateID
RETURN flow_state.flow_state_id%TYPE;

FUNCTION GetNextStateGroupID
RETURN flow_state_group.flow_state_group_id%TYPE;

PROCEDURE SetTempFlowState(
	in_flow_sid					IN	t_flow_state.flow_sid%TYPE,
	in_pos						IN	t_flow_state.pos%TYPE,
	in_flow_state_id			IN	t_flow_state.flow_state_id%TYPE,
	in_label					IN	t_flow_state.label%TYPE,
	in_lookup_key				IN	t_flow_state.lookup_key%TYPE,
	in_is_final					IN	t_flow_state.is_final%TYPE,
	in_state_colour				IN	t_flow_state.state_colour%TYPE,
	in_editable_role_sids		IN	t_flow_state.editable_role_sids%TYPE,
	in_non_editable_role_sids	IN	t_flow_state.non_editable_role_sids%TYPE,
	in_editable_col_sids		IN	t_flow_state.editable_col_sids%TYPE,
	in_non_editable_col_sids	IN	t_flow_state.non_editable_col_sids%TYPE,
	in_involved_type_ids		IN	t_flow_state.involved_type_ids%TYPE,
	in_editable_group_sids		IN	t_flow_state.editable_group_sids%TYPE,
	in_non_editable_group_sids	IN	t_flow_state.non_editable_group_sids%TYPE,
	in_move_from_flow_state_id 	IN  t_flow_state.move_from_flow_state_id%TYPE DEFAULT NULL,
	in_flow_state_group_ids		IN	t_flow_state.flow_state_group_ids%TYPE DEFAULT NULL,
	in_attributes_xml			IN	VARCHAR2,
	in_flow_state_nature_id		IN	t_flow_state.flow_state_nature_id%TYPE DEFAULT NULL,
	in_survey_editable			IN	t_flow_state.survey_editable%TYPE DEFAULT 1,
	in_survey_tag_ids			IN	t_flow_state.survey_tag_ids%TYPE DEFAULT NULL
);

PROCEDURE SetTempFlowStateAlert(
	in_flow_sid					IN	t_flow_state_alert.flow_sid%TYPE,
	in_flow_state_id			IN	t_flow_state_alert.flow_state_id%TYPE,
	in_customer_alert_type_id	IN	t_flow_state_alert.customer_alert_type_id%TYPE,
	in_flow_state_alert_id		IN	t_flow_state_alert.flow_state_alert_id%TYPE,
	in_flow_alert_description	IN	t_flow_state_alert.flow_alert_description%TYPE,
	in_helper_sp				IN	t_flow_state_alert.helper_sp%TYPE,
	in_role_sids				IN	t_flow_state_alert.role_sids%TYPE,
	in_group_sids				IN	t_flow_state_alert.group_sids%TYPE,
	in_user_sids				IN	t_flow_state_alert.user_sids%TYPE,
	in_recurrence_xml			IN	t_flow_state_alert.recurrence_xml%TYPE
);

PROCEDURE SetTempFlowStateRoleCap(
	in_flow_sid						IN	t_flow_state_role_cap.flow_sid%TYPE,
	in_flow_state_id				IN	t_flow_state_role_cap.flow_state_id%TYPE,
	in_flow_capability_id			IN	t_flow_state_role_cap.flow_capability_id%TYPE,
	in_role_sid						IN	t_flow_state_role_cap.role_sid%TYPE,
	in_flow_involvement_type_id		IN	t_flow_state_role_cap.flow_involvement_type_id%TYPE,
	in_permission_set				IN	t_flow_state_role_cap.permission_set%TYPE,
	in_group_sid					IN	t_flow_state_role_cap.group_sid%TYPE
);

PROCEDURE SetTempFlowStateTrans(
	in_flow_sid						IN	t_flow_state_trans.flow_sid%TYPE,
	in_pos							IN	t_flow_state_trans.pos%TYPE,
	in_flow_state_transition_id		IN	t_flow_state_trans.flow_state_transition_id%TYPE,
	in_from_state_id				IN	t_flow_state_trans.from_state_id%TYPE,
	in_to_state_id					IN	t_flow_state_trans.to_state_id%TYPE,
	in_ask_for_comment				IN	t_flow_state_trans.ask_for_comment%TYPE,
	in_mandatory_fields_message		IN	t_flow_state_trans.mandatory_fields_message%TYPE,
	in_auto_trans_type				IN	t_flow_state_trans.auto_trans_type%TYPE  DEFAULT 0,
	in_hours_before_auto_tran		IN	t_flow_state_trans.hours_before_auto_tran%TYPE,
	in_auto_schedule_xml			IN	VARCHAR2 DEFAULT NULL,
	in_button_icon_path				IN	t_flow_state_trans.button_icon_path%TYPE,
	in_verb							IN	t_flow_state_trans.verb%TYPE,
	in_lookup_key					IN	t_flow_state_trans.lookup_key%TYPE,
	in_helper_sp					IN	t_flow_state_trans.helper_sp%TYPE,
	in_role_sids					IN	t_flow_state_trans.role_sids%TYPE,
	in_column_sids					IN	t_flow_state_trans.column_sids%TYPE,
	in_involved_type_ids			IN	t_flow_state_trans.involved_type_ids%TYPE,
	in_group_sids					IN	t_flow_state_trans.group_sids%TYPE,
	in_attributes_xml				IN	VARCHAR2,
	in_enforce_validation			IN	t_flow_state_trans.enforce_validation%TYPE DEFAULT 0,
	out_flow_state_transition_id	OUT	t_flow_state_trans.flow_state_transition_id%TYPE
);

PROCEDURE SetTempFlowTransAlert(
	in_flow_sid						IN	t_flow_trans_alert.flow_sid%TYPE,
	in_flow_transition_alert_id		IN	t_flow_trans_alert.flow_transition_alert_id%TYPE,
	in_flow_state_transition_id		IN	t_flow_trans_alert.flow_state_transition_id%TYPE,
	in_customer_alert_type_id		IN	t_flow_trans_alert.customer_alert_type_id%TYPE,
	in_description					IN	t_flow_trans_alert.description%TYPE,
	in_to_initiator					IN	t_flow_trans_alert.to_initiator%TYPE,
	in_can_edit_before_send			IN	t_flow_trans_alert.can_be_edited_before_sending%TYPE,
	in_helper_sp					IN	t_flow_trans_alert.helper_sp%TYPE,
	in_flow_cms_cols				IN	t_flow_trans_alert.flow_cms_cols%TYPE,
	in_user_sids					IN	t_flow_trans_alert.user_sids%TYPE,
	in_role_sids					IN	t_flow_trans_alert.role_sids%TYPE,
	in_group_sids					IN	t_flow_trans_alert.group_sids%TYPE,
	in_cc_user_sids					IN	t_flow_trans_alert.cc_user_sids%TYPE DEFAULT NULL,
	in_cc_role_sids					IN	t_flow_trans_alert.cc_role_sids%TYPE DEFAULT NULL,
	in_cc_group_sids				IN	t_flow_trans_alert.cc_group_sids%TYPE DEFAULT NULL,
	in_alert_manager_flags			IN	t_flow_trans_alert.alert_manager_flags%TYPE,
	in_involved_type_ids			IN	t_flow_trans_alert.involved_type_ids%TYPE
);

PROCEDURE SetFlowFromTempTables(
	in_flow_sid				IN	flow.flow_sid%TYPE,
	in_flow_label			IN	flow.label%TYPE,
	in_flow_alert_class		IN	flow.flow_alert_class%TYPE,
	in_cms_tab_sid			IN	cms.tab.tab_sid%TYPE,
	in_default_state_id		IN	flow_state.flow_state_id%TYPE
);

PROCEDURE GetCCUsersForFlowTranAlert(
	in_flow_transition_alert_id		IN	flow_transition_alert.flow_transition_alert_id%TYPE,
	in_region_sid					IN	flow_transition_alert.flow_transition_alert_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE NewFlowAlertType(
	in_flow_sid					IN	security_pkg.T_SID_ID,
	in_label					IN	flow_alert_type.label%TYPE,
	out_customer_alert_type_id	OUT	customer_alert_type.customer_alert_type_Id%TYPE
);

FUNCTION AddToLog(
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE,
	in_comment_text			IN	flow_state_log.comment_text%TYPE DEFAULT NULL,
	in_user_sid				IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY','SID')
) RETURN flow_state_log.flow_state_log_id%TYPE;

FUNCTION AddToLog(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	in_comment_text		IN	flow_state_log.comment_text%TYPE DEFAULT NULL,
	in_cache_keys		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_user_sid			IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY','SID')
) RETURN flow_state_log.flow_state_log_id%TYPE;


PROCEDURE AddApprovalDashboardInstance(
	in_dashboard_instance_id	IN	approval_dashboard_instance.dashboard_instance_id%TYPE,
	out_flow_item_id			OUT	flow_item.flow_item_id%TYPE
);

PROCEDURE AddQuickSurveyResponse(
	in_survey_response_id	IN	flow_item.survey_response_id%TYPE,
	in_flow_sid				IN	security_pkg.T_SID_ID,
	out_flow_item_id		OUT	flow_item.flow_item_id%TYPE
);

PROCEDURE GetInboundCmsAccounts(
	out_cur		OUT	SYS_REFCURSOR
);

PROCEDURE AddInboundCmsItem(
	in_flow_sid					IN	flow.flow_sid%TYPE,
	in_region_sid				IN	region.region_sid%TYPE,	
	in_comment_text				IN	flow_state_log.comment_text%TYPE,
	in_flow_state_id			IN  flow_state.flow_state_Id%TYPE DEFAULT NULL,
	out_flow_item_id			OUT	flow_item.flow_item_id%TYPE
);

FUNCTION CanSeeDefaultState(
	in_flow_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID
) RETURN NUMBER;

FUNCTION CanSeeDefaultState(
	in_flow_sid			IN	security_pkg.T_SID_ID,
	in_region_sids		IN	security_pkg.T_SID_IDS
) RETURN NUMBER;

FUNCTION CanAccessDefaultState(
	in_flow_sid					IN	security_pkg.T_SID_ID,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_can_edit					IN	NUMBER DEFAULT 0
) RETURN NUMBER;

FUNCTION CanAccessDefaultState(
	in_flow_sid					IN	security_pkg.T_SID_ID,
	in_region_sids				IN	security_pkg.T_SID_IDS,
	in_can_edit					IN	NUMBER DEFAULT 0
) RETURN NUMBER;

PROCEDURE AddFlowItem(
	in_flow_sid					IN	flow.flow_sid%TYPE,
	out_flow_item_id			OUT	flow_item.flow_item_id%TYPE
);

PROCEDURE AddOrGetFlowItem(
	in_flow_sid					IN	flow.flow_sid%TYPE,
	in_resource_uuid			IN	flow_item.resource_uuid%TYPE,
	out_flow_item_id			OUT	flow_item.flow_item_id%TYPE
);

PROCEDURE AddCmsItem(
	in_flow_sid					IN	flow.flow_sid%TYPE,
	in_region_sid				IN	region.region_sid%TYPE,	
	out_flow_item_id			OUT	flow_item.flow_item_id%TYPE
);

PROCEDURE AddCmsItem(
	in_flow_sid					IN	flow.flow_sid%TYPE,
	in_region_sids				IN	security_pkg.T_SID_IDS,	
	out_flow_item_id			OUT	flow_item.flow_item_id%TYPE
);

PROCEDURE AddCmsItemByComp(
	in_flow_sid					IN	flow.flow_sid%TYPE,
	in_company_sids				IN	security_pkg.T_SID_IDS,
	out_flow_item_id			OUT	flow_item.flow_item_id%TYPE
);

PROCEDURE AddSectionItem(
	in_section_sid				IN  section.section_sid%TYPE,
	out_flow_item_id			OUT	flow_item.flow_item_id%TYPE
);

PROCEDURE AddAuditItem(
	in_audit_sid				IN  internal_audit.internal_audit_sid%TYPE,
	out_flow_item_id			OUT	flow_item.flow_item_id%TYPE
);

PROCEDURE GenerateRecipientAlerts (
	in_flow_item_id					IN	flow_item.flow_item_id%TYPE,
	in_set_by_user_sid				IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_flow_state_log_id			IN	flow_state_log.flow_state_log_id%TYPE,
	in_flow_transition_alert_id		IN	flow_transition_alert.flow_transition_alert_id%TYPE,
	in_user_sids					IN	security.security_pkg.T_SID_IDS,
	in_role_sids					IN	security.security_pkg.T_SID_IDS,
	in_group_sids					IN	security.security_pkg.T_SID_IDS,
	in_inv_type_ids					IN	security.security_pkg.T_SID_IDS,
	in_subject_override				IN	flow_item_generated_alert.subject_override%TYPE DEFAULT NULL,
	in_body_override				IN	flow_item_generated_alert.body_override%TYPE DEFAULT NULL
);

--expose it for running the migrate flow_item_alert script
PROCEDURE GenerateAlertEntries(
	in_flow_item_id				IN	flow_item.flow_item_id%TYPE,
	in_set_by_user_sid			IN 	security_pkg.T_SID_ID,
	in_flow_state_log_id		IN	flow_state_log.flow_state_log_id%TYPE,
	in_flow_state_transition_id	IN flow_state_transition.flow_state_transition_id%TYPE
);

FUNCTION TryTransitionToNatureOrForce(
	in_flow_item_id					IN	flow_item.flow_item_id%TYPE,
	in_to_nature					IN	flow_state_nature.flow_state_nature_id%TYPE,
	in_comment						IN	flow_state_log.comment_text%TYPE,
	in_user_sid						IN	security_pkg.T_SID_ID
)
RETURN flow_state.flow_state_id%TYPE;

FUNCTION SetItemStateNature(
	in_flow_item_id					IN	flow_item.flow_item_id%TYPE,
	in_to_nature					IN	flow_state_nature.flow_state_nature_id%TYPE,
	in_comment						IN	flow_state_log.comment_text%TYPE,
	in_user_sid						IN	security_pkg.T_SID_ID	DEFAULT SYS_CONTEXT('SECURITY','SID'),
	in_force						IN	NUMBER DEFAULT 0
)
RETURN flow_state.flow_state_id%TYPE;

PROCEDURE SetItemStateNature(
	in_flow_item_id					IN	flow_item.flow_item_id%TYPE,
	in_to_nature					IN	flow_state_nature.flow_state_nature_id%TYPE,
	in_comment						IN	flow_state_log.comment_text%TYPE,
	in_user_sid						IN	security_pkg.T_SID_ID	DEFAULT SYS_CONTEXT('SECURITY','SID'),
	in_force						IN	NUMBER	DEFAULT 0
);

PROCEDURE SetItemState(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	in_to_state_Id		IN	flow_state.flow_state_id%TYPE,
	in_comment_text		IN	flow_state_log.comment_text%TYPE,
	in_user_sid			IN	security_pkg.T_SID_ID	DEFAULT SYS_CONTEXT('SECURITY','SID')
);

PROCEDURE SetItemState(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	in_to_state_Id		IN	flow_state.flow_state_id%TYPE,
	in_comment_text		IN	flow_state_log.comment_text%TYPE,
	in_cache_keys		IN	security_pkg.T_VARCHAR2_ARRAY,	
	in_user_sid			IN	security_pkg.T_SID_ID	DEFAULT SYS_CONTEXT('SECURITY','SID'),
	in_force			IN	NUMBER	DEFAULT 0
);

PROCEDURE SetItemState(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	in_to_state_Id		IN	flow_state.flow_state_id%TYPE,
	in_comment_text		IN	flow_state_log.comment_text%TYPE,
	in_cache_keys		IN	security_pkg.T_VARCHAR2_ARRAY,	
	in_user_sid			IN	security_pkg.T_SID_ID	DEFAULT SYS_CONTEXT('SECURITY','SID'),
	in_force			IN	NUMBER,
	in_cancel_alerts	IN	NUMBER
);

PROCEDURE SetItemState(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	in_to_state_Id		IN	flow_state.flow_state_id%TYPE,
	in_comment_text		IN	flow_state_log.comment_text%TYPE,
	in_cache_keys		IN	security_pkg.T_VARCHAR2_ARRAY,	
	in_user_sid			IN	security_pkg.T_SID_ID	DEFAULT SYS_CONTEXT('SECURITY','SID'),
	in_force			IN	NUMBER,
	in_cancel_alerts	IN	NUMBER,
	out_flow_state_log_id	OUT flow_state_log.flow_state_log_id%TYPE
);

PROCEDURE AutonomouslyIncreaseFailureCnt(
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE
);

PROCEDURE MarkFlowItemGeneratedAlert(
	in_flow_item_gen_alert_id	IN flow_item_generated_alert.flow_item_generated_alert_id%TYPE
);

PROCEDURE MarkFlowItemGeneratedAlert(
	in_flow_item_gen_alert_ids	IN security_pkg.T_SID_IDS
);

PROCEDURE GetFile(
	in_flow_state_log_file_id	IN	flow_state_log_file.flow_state_log_file_id%TYPE,
	in_sha1						IN	VARCHAR2,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION GetToStateIdFromLookupKey(
	in_from_state_id	IN	csr_data_pkg.T_FLOW_STATE_ID,
	in_lookup_key		IN	csr_data_pkg.T_LOOKUP_KEY
) RETURN csr_data_pkg.T_FLOW_STATE_ID;

FUNCTION GetStateLookupKey(
	in_state_id	IN	csr_data_pkg.T_FLOW_STATE_ID
) RETURN csr_data_pkg.T_LOOKUP_KEY;

FUNCTION GetCurrentStateLookupKey(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE
) RETURN csr_data_pkg.T_LOOKUP_KEY;

FUNCTION SQL_HasRoleMembersForRegion(
    in_flow_state_id    IN  csr_data_pkg.T_FLOW_STATE_ID,
    in_region_sid       IN  security_pkg.T_SID_ID
) RETURN NUMBER;

FUNCTION SQL_HasRoleMembersForRegion(
    in_flow_state_id    IN  csr_data_pkg.T_FLOW_STATE_ID,
    in_region_sids      IN  security_pkg.T_SID_IDS
) RETURN NUMBER;

-- will anyone be able to see thing in this state, for the given region?
FUNCTION HasRoleMembersForRegion(
    in_flow_state_id    IN  csr_data_pkg.T_FLOW_STATE_ID,
    in_region_sid       IN  security_pkg.T_SID_ID,
    in_role_sid			IN  role.role_sid%TYPE := NULL
) RETURN BOOLEAN;

FUNCTION HasRoleMembersForRegions(
    in_flow_state_id    			IN  csr_data_pkg.T_FLOW_STATE_ID,
    in_region_sids       			IN  security_pkg.T_SID_IDS
) RETURN BOOLEAN;

PROCEDURE GetRolesForRegions(
	in_region_sids		IN  security_pkg.T_SID_IDS,
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE GetRolesForCompanies(
	in_company_sids		IN  security_pkg.T_SID_IDS,
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE GetChangeLog(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR,
	out_files			OUT	SYS_REFCURSOR
);

PROCEDURE GetLastChangeLog_UNSEC(
	in_flow_item_ids		IN	security.security_pkg.T_SID_IDS,
	in_flow_state_nature_id	IN	flow_state.flow_state_nature_id%TYPE DEFAULT NULL,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetFlowItemsBasicInfo_UNSEC(
	in_flow_item_ids		IN	security.security_pkg.T_SID_IDS,
	out_cur					OUT	SYS_REFCURSOR
);

FUNCTION GetFlowItemIsEditable(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE
) RETURN NUMBER;

FUNCTION GetFlowItemIsEditable(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	in_region_sid		IN	security.security_pkg.T_SID_ID
) RETURN NUMBER;

FUNCTION GetFlowItemIsEditable(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	in_region_sids		IN	security.security_pkg.T_SID_IDS
) RETURN NUMBER;

PROCEDURE GetFlowItemStatePermissions(
	in_flow_item_id				IN	flow_item.flow_item_id%TYPE,
	in_state_id					IN	flow_state.flow_state_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
);

FUNCTION GetPermissibleRegionItems(
	in_capability_id				IN	flow_capability.flow_capability_id%TYPE,
	in_region_sid					IN  region.region_sid%TYPE
) RETURN security.T_SID_TABLE;

PROCEDURE GetItemCapabilityPermissions (
	in_capability_id	IN	flow_capability.flow_capability_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE GetItemCapabilityPermissions (
	in_flow_item_ids	IN  security.security_pkg.T_SID_IDS,
	in_capability_id	IN	flow_capability.flow_capability_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
);

FUNCTION GetItemCapabilityPermission (
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	in_capability_id	IN	flow_capability.flow_capability_id%TYPE
) RETURN security_pkg.T_PERMISSION;

PROCEDURE GetAlertTemplates(
	in_flow_sid						IN	security_pkg.T_SID_ID,
	out_alert_type_cur				OUT	SYS_REFCURSOR,
	out_alert_tpl_cur				OUT	SYS_REFCURSOR,
	out_alert_tpl_body_cur			OUT	SYS_REFCURSOR,
	out_alert_helper_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetEditableFlowAlerts(
	in_flow_state_transition_id IN  flow_state_transition.flow_state_transition_id%TYPE,
	in_lang						IN  alert_template_body.lang%TYPE,
	out_alerts_cur 				OUT SYS_REFCURSOR
);

PROCEDURE GetEditableAlertsRecipients(
	in_flow_item_id				IN 	csr.flow_item.flow_item_id%TYPE,
	in_flow_state_transition_id IN  flow_state_transition.flow_state_transition_id%TYPE,
	out_user_cur 				OUT SYS_REFCURSOR,
	out_roles_cur 				OUT SYS_REFCURSOR,
	out_groups_cur 				OUT SYS_REFCURSOR,
	out_involm_type_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetCmsAlertTemplates(
	out_cms_alert_type_cur			OUT	SYS_REFCURSOR,
	out_alert_tpl_cur				OUT	SYS_REFCURSOR,
	out_alert_tpl_body_cur			OUT	SYS_REFCURSOR,
	out_alert_helper_cur			OUT	SYS_REFCURSOR
);

PROCEDURE SaveFlowAlertTemplate(
	in_flow_sid						IN	security_pkg.T_SID_ID,
	in_customer_alert_type_id		IN	flow_alert_type.customer_alert_type_id%TYPE,
	in_description					IN	flow_alert_type.label%TYPE,
	in_lookup_key					IN	flow_alert_type.lookup_key%TYPE,
	in_alert_frame_id				IN	alert_template.alert_frame_id%TYPE,
	in_send_type					IN	alert_template.send_type%TYPE,
	in_reply_to_name				IN	alert_template.reply_to_name%TYPE,
	in_reply_to_email				IN	alert_template.reply_to_email%TYPE,
	in_deleted						IN	flow_alert_type.deleted%TYPE,
	out_customer_alert_type_id		OUT flow_alert_type.customer_alert_type_id%TYPE
);

PROCEDURE SaveCmsAlertTemplate(
	in_tab_sid						IN	cms_alert_type.tab_sid%TYPE,
	in_customer_alert_type_id		IN	cms_alert_type.customer_alert_type_id%TYPE,
	in_description					IN	cms_alert_type.description%TYPE,
	in_lookup_key					IN	cms_alert_type.lookup_key%TYPE,
	in_alert_frame_id				IN	alert_template.alert_frame_id%TYPE,
	in_send_type					IN	alert_template.send_type%TYPE,
	in_reply_to_name				IN	alert_template.reply_to_name%TYPE,
	in_reply_to_email				IN	alert_template.reply_to_email%TYPE,
	out_customer_alert_type_id		OUT cms_alert_type.customer_alert_type_id%TYPE
);

PROCEDURE SaveCmsAlertTemplate(
	in_tab_sid						IN	cms_alert_type.tab_sid%TYPE,
	in_customer_alert_type_id		IN	cms_alert_type.customer_alert_type_id%TYPE,
	in_description					IN	cms_alert_type.description%TYPE,
	in_lookup_key					IN	cms_alert_type.lookup_key%TYPE,
	in_alert_frame_id				IN	alert_template.alert_frame_id%TYPE,
	in_send_type					IN	alert_template.send_type%TYPE,
	in_reply_to_name				IN	alert_template.reply_to_name%TYPE,
	in_reply_to_email				IN	alert_template.reply_to_email%TYPE,
	in_deleted						IN	cms_alert_type.deleted%TYPE,
	in_is_batched					IN	cms_alert_type.is_batched%TYPE DEFAULT 0,
	out_customer_alert_type_id		OUT cms_alert_type.customer_alert_type_id%TYPE
);

PROCEDURE SaveCmsAlertTemplateBody(
	in_customer_alert_type_id		IN	alert_template_body.customer_alert_type_id%TYPE,
	in_lang							IN	alert_template_body.lang%TYPE,
	in_subject						IN	alert_template_body.subject%TYPE,
	in_body_html					IN	alert_template_body.body_html%TYPE,
	in_item_html					IN	alert_template_body.item_html%TYPE
);

PROCEDURE SaveFlowAlertTemplateBody(
	in_customer_alert_type_id		IN	alert_template_body.customer_alert_type_id%TYPE,
	in_lang							IN	alert_template_body.lang%TYPE,
	in_subject						IN	alert_template_body.subject%TYPE,
	in_body_html					IN	alert_template_body.body_html%TYPE,
	in_item_html					IN	alert_template_body.item_html%TYPE
);

PROCEDURE GetPendingCmsAlerts(
	in_is_batched				IN cms_alert_type.is_batched%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetOpenGeneratedAlerts(
	in_flow_transition_alert_id IN flow_transition_alert.flow_transition_alert_id %TYPE,
	in_is_batched				IN cms_alert_type.is_batched%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetItemsNeedImmediateProgress(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetItemsNeedScheduledProgress(
	out_cur							OUT	SYS_REFCURSOR
);

FUNCTION IsFinalState(
	in_flow_sid     IN	security.security_pkg.T_SID_ID,
	in_state_id		IN	csr_data_pkg.T_FLOW_STATE_ID
) RETURN NUMBER;

FUNCTION IsDefaultState(
	in_flow_sid     IN	security.security_pkg.T_SID_ID,
	in_state_id		IN	csr_data_pkg.T_FLOW_STATE_ID
) RETURN NUMBER;

FUNCTION GetPreviousState(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE
) RETURN NUMBER;

PROCEDURE GetCustomerFlowTypes(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetInvolvmentTypes(
	in_flow_class					IN	flow_alert_class.flow_alert_class%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetInvolvementTypesByWorkflow(
	in_flow_sid		IN flow_state.flow_sid%TYPE,
	out_cur		 	OUT SYS_REFCURSOR
);

PROCEDURE GetInvolvementTypesByAlertClass(
	in_flow_alert_class	IN	flow_alert_class.flow_alert_class%TYPE,
	out_cur		 		OUT SYS_REFCURSOR
);

PROCEDURE GetCapabilities(
	in_flow_class					IN	flow_alert_class.flow_alert_class%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE BeginAlertBatchRun(
	in_flow_sid					IN	security_pkg.T_SID_ID,
	in_customer_alert_type_id	IN	flow_alert_type.customer_alert_type_id%TYPE
);

PROCEDURE RecordUserBatchRun(
	in_flow_sid					IN	security_pkg.T_SID_ID,
	in_user_sid					IN	security_pkg.T_SID_ID,
	in_flow_state_alert_id		IN	flow_state_alert.flow_state_alert_id%TYPE
);

PROCEDURE EndAlertBatchRun(
	in_flow_sid					IN	security_pkg.T_SID_ID,
	in_customer_alert_type_id	IN	flow_alert_type.customer_alert_type_id%TYPE
);

PROCEDURE SetFlowStateMoveToId(
	in_flow_sid					IN	security_pkg.T_SID_ID,
	in_from_flow_state_id		IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_flow_state_id			IN  csr_data_pkg.T_FLOW_STATE_ID
);

PROCEDURE GetAvailableUsersForState(
	in_state_id					IN	flow_state.flow_state_id%TYPE,
	in_section_sid				IN	security_pkg.T_SID_ID,
	in_filter					IN	VARCHAR2,
	in_include_inactive			IN	NUMBER DEFAULT 0,
	out_cur						OUT	SYS_REFCURSOR,
	out_total_num_users			OUT SYS_REFCURSOR
);

PROCEDURE OnCreateAppDashFlow(
	in_flow_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE OnCreateAuditFlow(
	in_flow_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE OnCreateCampaignFlow(
	in_flow_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE SetGroup(
	in_group_name		IN	security.securable_object.name%TYPE,
	out_group_sid		OUT	security_pkg.T_SID_ID
);

PROCEDURE SetFlowFromXml(
	in_flow_sid		IN	security_pkg.T_SID_ID,
	in_xml			IN	XMLType
);

PROCEDURE GetCustomerInvolvementTypes (
	out_cur							OUT	security.security_pkg.T_OUTPUT_CUR,
	out_flow_alert_cls_cur			OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveCustomerInvolvementType (
	in_involvement_type_id			IN	flow_involvement_type.flow_involvement_type_id%TYPE,
	in_label						IN	flow_involvement_type.label%TYPE,
	in_product_area					IN	flow_involvement_type.product_area%TYPE,
	in_flow_alert_classes			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_css_class					IN	flow_involvement_type.css_class%TYPE DEFAULT 'CSRUser',
	in_lookup_key					IN	flow_involvement_type.lookup_key%TYPE,
	out_involvement_type_id			OUT	flow_involvement_type.flow_involvement_type_id%TYPE
);

PROCEDURE DeleteCustomerInvolvementType (
	in_involvement_type_id			IN	flow_involvement_type.flow_involvement_type_id%TYPE
);

PROCEDURE SetInvolvementType (
	in_flow_sid						IN	security.security_pkg.T_SID_ID,
	in_label						IN	flow_involvement_type.label%TYPE,
	in_css_class					IN	flow_involvement_type.css_class%TYPE,
	out_flow_involvement_type_id	OUT	flow_involvement_type.flow_involvement_type_id%TYPE
);

PROCEDURE GetCustomerFlowCapabilities(
	in_flow_alert_class				IN	customer_flow_capability.flow_alert_class%TYPE DEFAULT NULL,
	out_cur							OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveCustomerFlowCapability(
	in_flow_capability_id			IN	customer_flow_capability.flow_capability_id%TYPE,
	in_flow_alert_class				IN	customer_flow_capability.flow_alert_class%TYPE DEFAULT NULL,
	in_description					IN	customer_flow_capability.description%TYPE DEFAULT NULL,
	in_perm_type					IN	customer_flow_capability.perm_type%TYPE DEFAULT NULL,
	in_default_permission_set		IN	customer_flow_capability.default_permission_set%TYPE DEFAULT NULL,
	in_copy_capability_id			IN	customer_flow_capability.flow_capability_id%TYPE DEFAULT NULL,
	in_is_system_managed			IN	customer_flow_capability.is_system_managed%TYPE DEFAULT 0,
	out_flow_capability_id			OUT	customer_flow_capability.flow_capability_id%TYPE
);

PROCEDURE DeleteCustomerFlowCapability(
	in_flow_capability_id			IN	customer_flow_capability.flow_capability_id%TYPE
);

PROCEDURE GetFlowStateNatures(
	in_flow_alert_class		IN flow_state_nature.flow_alert_class%TYPE,
	out_cur					OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetStateGroups(
	out_cur	OUT security.security_pkg.T_OUTPUT_CUR
);

/**
 * Upsert a flow_state_group. These are customer specific categories attached to flow states.
 *
 * @param    in_flow_state_group_id		For updates: ID of existing record. For inserts: NULL or pre-requested flow_state_group_id_seq.NEXTVAL (via FUNCTION GetNextStateGroupID)
 * @param    in_label					Label
 * @param    in_lookup_key				Lookup key
 * @param    out_flow_state_group_id	New or existing flow_state_group_id
 */
PROCEDURE SaveStateGroup (
	in_flow_state_group_id	IN	flow_state_group.flow_state_group_id%TYPE,
	in_label				IN	flow_state_group.label%TYPE,
	in_lookup_key			IN	flow_state_group.lookup_key%TYPE,
	out_flow_state_group_id	OUT	flow_state_group.flow_state_group_id%TYPE
);

PROCEDURE SetStateGroupMembers(
	in_state_id					IN	flow_state.flow_state_id%TYPE,
	in_flow_state_group_ids		IN	security_pkg.T_SID_IDS
);

PROCEDURE SaveSurveyTag (
	in_tag_group_name			IN	tag_group_description.name%TYPE,
	in_tag_label				IN	tag_description.tag%TYPE,
	out_tag_id					OUT	tag.tag_id%TYPE
);

PROCEDURE SetStateSurveyTags(
	in_state_id					IN	flow_state.flow_state_id%TYPE,
	in_survey_tag_ids			IN	security_pkg.T_SID_IDS
);

PROCEDURE GetFlowAlertHelpers(
	in_flow_sid						IN		security_pkg.T_SID_ID,
	out_flow_alert_helpers_cur		OUT		SYS_REFCURSOR
);

PROCEDURE GetCmsAlertHelpers(
	in_flow_sid						IN		security_pkg.T_SID_ID,
	in_tab_sid						IN		security_pkg.T_SID_ID,
	out_cms_alert_helpers_cur		OUT		SYS_REFCURSOR
);

PROCEDURE OnCreateSupplierFlowHelpers(
	in_flow_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE UNFINISHED_GetFlowItemIds(
	in_flow_sid					IN  security_pkg.T_SID_ID,
	out_flow_item_ids			OUT SYS_REFCURSOR
);

PROCEDURE GetPermissibleTransitions(
	in_flow_item_id		IN flow_item.flow_item_id%TYPE,
	out_transitions_cur	OUT SYS_REFCURSOR 
);

FUNCTION GetToStateId(
	in_transition_id	IN flow_state_transition.flow_state_transition_id%TYPE
) RETURN NUMBER;

FUNCTION GetNatureOfState(
	in_flow_state_id	IN flow_state.flow_state_id%TYPE
) RETURN NUMBER;

PROCEDURE GetCurStateTransitions_UNSEC(
	in_flow_item_id 		IN flow_item.flow_item_id%TYPE,
	out_transitions_cur		OUT SYS_REFCURSOR,
	out_roles_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetCurStateCapabilities_UNSEC(
	in_flow_item_id 		IN flow_item.flow_item_id%TYPE,
	out_capabilities_cur	OUT SYS_REFCURSOR
);

PROCEDURE SetItemState_SEC(
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE,
	in_transition_id		IN	flow_state_transition.flow_state_transition_id%TYPE,
	in_comment_text			IN	flow_state_log.comment_text%TYPE,
	out_flow_state_log_id	OUT flow_state_log.flow_state_log_id%TYPE
);

PROCEDURE AddFlowItemRegion(
	in_flow_item_id		IN flow_item.flow_item_id%TYPE,
	in_region_sid		IN security_pkg.T_SID_ID
);

PROCEDURE GetStateTransitionDetail(
	in_flow_transition_id			IN	flow_state_transition.flow_state_transition_id%TYPE,
	out_detail						OUT	SYS_REFCURSOR
);

PROCEDURE GetFlowStateSurveyTags_UNSEC(
	in_flow_item_id				IN	flow_item.flow_item_id%TYPE,
	out_flow_state_tags_cur		OUT	SYS_REFCURSOR
);

FUNCTION GetFlowIsSurveyEditable(
	in_flow_item_id	IN	flow_item.flow_item_id%TYPE
) RETURN NUMBER;

PROCEDURE GetFlowState_UNSEC(
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE,
	out_flow_state_cur		OUT	SYS_REFCURSOR
);
PROCEDURE GetStateByFlowItemIds_UNSEC(
	in_flow_item_ids				IN	security_pkg.T_SID_IDS,
	out_cur							OUT	SYS_REFCURSOR
);

FUNCTION GetFlowAlerts(
	in_flow_alert_class		IN	flow.flow_alert_class%TYPE
)
RETURN T_FLOW_ALERT_TABLE;

PROCEDURE GetCampaignFlows(
	in_parent_sid		IN		security.security_pkg.T_SID_ID,
	out_flow_cur		OUT		SYS_REFCURSOR
);

PROCEDURE ArchiveOldFlowItemGenEntries;

FUNCTION GetOrCreateFlow (
	in_workflow_label		IN	flow.label%TYPE,
	in_flow_alert_class		IN	flow.flow_alert_class%TYPE
) RETURN security_pkg.T_SID_ID;

END;
/
