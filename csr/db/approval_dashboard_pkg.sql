CREATE OR REPLACE PACKAGE CSR.approval_dashboard_pkg AS

PORTAL_GROUP_NAME			CONSTANT VARCHAR2(50) := 'ApprovalDashboard';

-- Securable object callbacks
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

PROCEDURE CreateDashboard(
	in_label				IN	approval_dashboard.label%TYPE,
	out_dashboard_sid		OUT	security_pkg.T_SID_ID
);

PROCEDURE CreateDashboard(
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_label						IN	approval_dashboard.label%TYPE,
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	in_ind_pos						IN  security_pkg.T_SID_IDS,
	in_ind_allow_est				IN	security_pkg.T_SID_IDS,
	in_ind_is_hidden				IN	security_pkg.T_SID_IDS,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_period_start					IN	approval_dashboard.start_dtm%TYPE,
	in_period_end					IN	approval_dashboard.end_dtm%TYPE,
	in_period_set_id				IN	approval_dashboard.period_set_id%TYPE,
	in_period_interval_id			IN	approval_dashboard.period_interval_id%TYPE,
	in_workflow_sid					IN	approval_dashboard.flow_sid%TYPE,
	in_instance_schedule			IN	XMLType,
	in_publish_doc_folder_sid		IN	approval_dashboard.publish_doc_folder_sid%TYPE,
	in_active_period_scenario_run	IN	approval_dashboard.active_period_scenario_run_sid%TYPE,
	in_signed_off_scenario_run		IN	approval_dashboard.signed_off_scenario_run_sid%TYPE,
	in_source_scenario_run			IN	approval_dashboard.source_scenario_run_sid%TYPE,
	out_dashboard_sid				OUT	approval_dashboard.approval_dashboard_sid%TYPE
);

PROCEDURE GetOutputScenarioRuns(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE DeleteRegion(
	in_dashboard_sid	IN		approval_dashboard_instance.approval_dashboard_sid%TYPE,
	in_region_sid		IN		approval_dashboard_instance.region_sid%TYPE
);

 PROCEDURE UpdateDashboard(
 	in_approval_dashboard_sid		IN 	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
 	in_label						IN	APPROVAL_DASHBOARD.label%TYPE,
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	in_ind_pos						IN  security_pkg.T_SID_IDS,
	in_ind_allow_est				IN	security_pkg.T_SID_IDS,
	in_ind_is_inactive				IN	security_pkg.T_SID_IDS,
	in_ind_is_hidden				IN	security_pkg.T_SID_IDS,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_end_dtm						IN	APPROVAL_DASHBOARD.start_dtm%TYPE,
	in_instance_schedule			IN	XMLType,
	in_publish_doc_folder_sid		IN	approval_dashboard.publish_doc_folder_sid%TYPE,
	in_active_period_scenario_run	IN	APPROVAL_DASHBOARD.active_period_scenario_run_sid%TYPE,
	in_signed_off_scenario_run		IN	APPROVAL_DASHBOARD.signed_off_scenario_run_sid%TYPE,
	in_source_scenario_run			IN	approval_dashboard.source_scenario_run_sid%TYPE
);

--PROCEDURE SetRegions
-- TODO: what happens if there are regions in approval_dashboard_instance and we try and remove them?

PROCEDURE CheckForNewInstances(
	in_dashboard_sid				IN	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE
);

PROCEDURE CreateInstance(
	in_dashboard_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	approval_dashboard_instance.start_dtm%TYPE,
	in_end_dtm			IN	approval_dashboard_instance.end_dtm%TYPE
);

PROCEDURE CreateNextInstance(
	in_dashboard_sid		IN	security_pkg.T_SID_ID,
	out_instance_id			OUT	approval_dashboard_instance.dashboard_instance_id%TYPE
);

PROCEDURE CreateInstance(
	in_dashboard_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	approval_dashboard_instance.start_dtm%TYPE,
	in_end_dtm			IN	approval_dashboard_instance.end_dtm%TYPE,
	out_instance_id		OUT	approval_dashboard_instance.dashboard_instance_id%TYPE
);

PROCEDURE AddTab(
	in_dashboard_sid	IN	security_pkg.T_SID_ID,
	in_tab_name		IN	tab.name%TYPE,
	in_is_shared 	IN	tab.is_shared%TYPE,
	in_is_hideable 	IN	tab.is_hideable%TYPE,
	in_layout		IN	tab.layout%TYPE,
	in_portal_group	IN	tab.portal_group%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddTab(
	in_dashboard_sid	IN	security_pkg.T_SID_ID,
	in_tab_id			IN	security_pkg.T_SID_ID,
	in_pos				IN	NUMBER DEFAULT NULL
);


PROCEDURE UpdateTabPosition(
	in_dashboard_sid	IN	security_pkg.T_SID_ID,
	in_tab_ids			IN	security_pkg.T_SID_IDS
);

PROCEDURE GetDashboards(
	out_cur_dashboard	OUT	SYS_REFCURSOR
);

PROCEDURE GetDashboardList(
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetFolderPath(
	in_folder_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetChildDashboards(
	in_parent_sid	IN security_pkg.T_SID_ID,
	out_cur			OUT SYS_REFCURSOR
);

PROCEDURE NewFlowAlertType(
	in_flow_sid					IN	security_pkg.T_SID_ID,
	in_customer_alert_type_id	IN	customer_alert_type.customer_alert_type_Id%TYPE
);

PROCEDURE GetDashboardDetail(
	in_dashboard_sid	IN	security_pkg.T_SID_ID,
	out_cur_dashboard	OUT	SYS_REFCURSOR,
	out_cur_periods		OUT	SYS_REFCURSOR,
	out_cur_regions 	OUT	SYS_REFCURSOR,
	out_cur_users 		OUT	SYS_REFCURSOR,
	out_cur_inds		OUT	SYS_REFCURSOR
);

PROCEDURE GetDashboardFromValId(
	in_val_id						IN	NUMBER,
	out_cur							OUT security_pkg.T_OUTPUT_CUR,
	out_regions_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_inds_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_capability_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_instance_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetDashboard(
	in_dashboard_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	approval_dashboard_instance.start_dtm%TYPE,
	in_end_dtm			IN	approval_dashboard_instance.end_dtm%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_regions_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_inds_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_capability_cur	OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetDashboardStateCapabilities(
	in_dashboard_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	approval_dashboard_instance.start_dtm%TYPE,
	in_end_dtm			IN	approval_dashboard_instance.end_dtm%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetDashboardInds(
	in_dashboard_sid	IN	security_pkg.T_SID_ID,
	out_inds_cur		OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetDashboardSettings(
	in_dashboard_sid	IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_regions_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_inds_cur		OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTransitions(
	in_dashboard_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	approval_dashboard_instance.start_dtm%TYPE,
	in_end_dtm			IN	approval_dashboard_instance.end_dtm%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION GetFlowRegionSids(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN security.T_SID_TABLE;

FUNCTION FlowItemRecordExists(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN NUMBER;

PROCEDURE GetFlowAlerts(
	out_cur		OUT		security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMyDashboards(
	out_cur		OUT		security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMyDashboardsBasicFiltered(
	in_num_months					IN 	NUMBER,
	in_include_final_state			IN 	NUMBER,
	in_include_no_transitions		IN 	NUMBER,
	in_group_by						IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetMyFilteredDashboards(
	in_text_search					IN	VARCHAR2,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_include_final_state			IN	NUMBER DEFAULT 0,
	in_action_state					IN 	NUMBER,
	in_group_by						IN	VARCHAR2,
	in_workflow_state				IN	VARCHAR2,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetUserWorkflowStates(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTabs(
	in_dashboard_sid	IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInstanceId(
	in_approval_dashboard_sid		IN	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_sid					IN	APPROVAL_DASHBOARD_INSTANCE.region_sid%TYPE,
	out_instance_id					OUT	APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE
);

PROCEDURE GetMostRecentInstance(
	in_approval_dashboard_sid			IN  APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_region_sid						IN	APPROVAL_DASHBOARD_INSTANCE.region_sid%TYPE,
	in_is_locked						IN  APPROVAL_DASHBOARD_INSTANCE.is_locked%TYPE,
	out_dashboard_instance_id			OUT APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE
);

PROCEDURE UpdateDashboardIndicators(
	in_dashboard_sid		IN	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_indicators			IN	security_pkg.T_SID_IDS
);

PROCEDURE CompareInstances(
	in_instance_id_a	IN	APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE,
	in_instance_id_b	IN	APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetValsForComparePortlet(
	in_approval_dashboard_sid		IN	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_sid					IN	APPROVAL_DASHBOARD_INSTANCE.region_sid%TYPE,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_compare_cur					OUT	SYS_REFCURSOR,
	out_livedata_cur				OUT SYS_REFCURSOR,
	out_instance_cur				OUT SYS_REFCURSOR
);

FUNCTION GetIds(
	in_val_id					IN	NUMBER
) RETURN CLOB;

PROCEDURE TransitionLockInstance(
    in_flow_sid                 IN  security_pkg.T_SID_ID,
    in_flow_item_id             IN  csr_data_pkg.T_FLOW_ITEM_ID,
    in_from_state_id            IN  csr_data_pkg.T_FLOW_STATE_ID,
    in_to_state_id              IN  csr_data_pkg.T_FLOW_STATE_ID,
    in_transition_lookup_key    IN  csr_data_pkg.T_LOOKUP_KEY,
    in_comment_text             IN  flow_state_log.comment_text%TYPE,
    in_user_sid                 IN  security_pkg.T_SID_ID
);

PROCEDURE LockInstance(
	in_dashboard_instance_id		IN APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE
);

PROCEDURE TransitionUnlockInstance(
    in_flow_sid                 IN  security_pkg.T_SID_ID,
    in_flow_item_id             IN  csr_data_pkg.T_FLOW_ITEM_ID,
    in_from_state_id            IN  csr_data_pkg.T_FLOW_STATE_ID,
    in_to_state_id              IN  csr_data_pkg.T_FLOW_STATE_ID,
    in_transition_lookup_key    IN  csr_data_pkg.T_LOOKUP_KEY,
    in_comment_text             IN  flow_state_log.comment_text%TYPE,
    in_user_sid                 IN  security_pkg.T_SID_ID
);

PROCEDURE UnlockInstance(
	in_dashboard_instance_id		IN APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE
);

PROCEDURE TransitionSignOffInstance(
	in_in_flow_sid              IN  security_pkg.T_SID_ID,
    in_flow_item_id             IN  csr_data_pkg.T_FLOW_ITEM_ID,
    in_from_state_id            IN  csr_data_pkg.T_FLOW_STATE_ID,
    in_to_state_id              IN  csr_data_pkg.T_FLOW_STATE_ID,
    in_transition_lookup_key    IN  csr_data_pkg.T_LOOKUP_KEY,
    in_comment_text             IN  flow_state_log.comment_text%TYPE,
    in_user_sid                 IN  security_pkg.T_SID_ID
);

PROCEDURE TransitionReopenSignedOffInst(
	in_in_flow_sid              IN  security_pkg.T_SID_ID,
    in_flow_item_id             IN  csr_data_pkg.T_FLOW_ITEM_ID,
    in_from_state_id            IN  csr_data_pkg.T_FLOW_STATE_ID,
    in_to_state_id              IN  csr_data_pkg.T_FLOW_STATE_ID,
    in_transition_lookup_key    IN  csr_data_pkg.T_LOOKUP_KEY,
    in_comment_text             IN  flow_state_log.comment_text%TYPE,
    in_user_sid                 IN  security_pkg.T_SID_ID
);

PROCEDURE TransitionPublish(
	in_in_flow_sid				IN  security_pkg.T_SID_ID,
    in_flow_item_id             IN  csr_data_pkg.T_FLOW_ITEM_ID,
    in_from_state_id            IN  csr_data_pkg.T_FLOW_STATE_ID,
    in_to_state_id              IN  csr_data_pkg.T_FLOW_STATE_ID,
    in_transition_lookup_key    IN  csr_data_pkg.T_LOOKUP_KEY,
    in_comment_text             IN  flow_state_log.comment_text%TYPE,
    in_user_sid                 IN  security_pkg.T_SID_ID
);

PROCEDURE GetScenariosForPortlet(
	in_tab_portlet_id					IN	TAB_PORTLET.tab_portlet_id%TYPE,
	out_active_period_scen_run_sid		OUT	APPROVAL_DASHBOARD.active_period_scenario_run_sid%TYPE,
	out_signed_off_scen_run_sid			OUT	APPROVAL_DASHBOARD.signed_off_scenario_run_sid%TYPE
);

PROCEDURE GetValueHistory(
	in_current_val_id				IN	APPROVAL_DASHBOARD_VAL.approval_dashboard_val_id%TYPE,
	in_previous_val_id				IN	APPROVAL_DASHBOARD_VAL.approval_dashboard_val_id%TYPE,
	in_region						IN	REGION.region_sid%TYPE,
	out_ind_type					OUT	SYS_REFCURSOR,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetPeriodValueHistory(
	in_dashboard_instance_id		IN	APPROVAL_DASHBOARD_VAL.dashboard_instance_id%TYPE,
	in_ind_sid						IN	APPROVAL_DASHBOARD_VAL.ind_sid%TYPE,
	in_ytd_value					IN	NUMBER,
	out_ind_type					OUT	SYS_REFCURSOR,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE SetValueNote(
	in_approval_dashboard_val_id	IN	APPROVAL_DASHBOARD_VAL.approval_dashboard_val_id%TYPE,
	in_note							IN	APPROVAL_DASHBOARD_VAL.note%TYPE,
	in_note_added_by_sid			IN	APPROVAL_DASHBOARD_VAL.note_added_by_sid%TYPE,
	out_result						OUT	NUMBER
);

PROCEDURE GetDataForRefreshBatchJob(
	in_batch_job_id					IN 	BATCH_JOB_APPROVAL_DASH_VALS.batch_job_id%TYPE,
	out_dashboard_cur				OUT	SYS_REFCURSOR,
	out_ind_cur						OUT SYS_REFCURSOR,
	out_descendant_region_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetDataForRefresh(
	in_dashboard_instance_id		IN 	APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE,
	out_dashboard_cur				OUT	SYS_REFCURSOR,
	out_ind_cur						OUT SYS_REFCURSOR	
);

PROCEDURE CreateDataRefreshBatchJob(
	in_dashboard_instance_id		IN 	APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE,
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE UpsertInstanceValue(
	in_approval_dashboard_sid		IN  APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_dashboard_instance_id		IN 	APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE,
	in_ind_sid						IN 	APPROVAL_DASHBOARD_VAL.ind_sid%TYPE,
	in_start_dtm					IN 	APPROVAL_DASHBOARD_VAL.start_dtm%TYPE,
	in_end_dtm						IN 	APPROVAL_DASHBOARD_VAL.end_dtm%TYPE,
	in_val_number					IN 	APPROVAL_DASHBOARD_VAL.val_number%TYPE,
	in_ytd_number					IN 	APPROVAL_DASHBOARD_VAL.ytd_val_number%TYPE
);

PROCEDURE InsertSourceValue(
	in_instance_id					IN	APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE,
	in_src_id						IN	APPROVAL_DASHBOARD_VAL_SRC.id%TYPE,
	in_src_desc						IN	APPROVAL_DASHBOARD_VAL_SRC.description%TYPE,
	in_src_detail					IN	APPROVAL_DASHBOARD_VAL_SRC.source_detail%TYPE,
	in_ind_sid						IN	APPROVAL_DASHBOARD_VAL.ind_sid%TYPE,
	in_start_dtm					IN	APPROVAL_DASHBOARD_VAL.start_dtm%TYPE,
	in_end_dtm						IN	APPROVAL_DASHBOARD_VAL.end_dtm%TYPE
);

PROCEDURE PrepForValueInserts(
	in_dashboard_instance_id		IN 	APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE
);

PROCEDURE QueueActiveDataScenarioRefresh(
	in_dashboard_instance_id		IN 	APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE
);

PROCEDURE GetActivePeriodVals(
	in_start_dtm					IN  DATE,
    in_end_dtm						IN  DATE,
	in_scenario_run_sid				IN	csr.scenario_run.scenario_run_sid%TYPE,
    out_val_cur						OUT SYS_REFCURSOR,
	out_note_cur					OUT SYS_REFCURSOR,
    out_file_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetSignedOffVals(
	in_start_dtm					IN  DATE,
    in_end_dtm						IN  DATE,
	in_scenario_run_sid				IN	csr.scenario_run.scenario_run_sid%TYPE,
    out_val_cur						OUT SYS_REFCURSOR,
	out_note_cur					OUT SYS_REFCURSOR,
    out_file_cur					OUT	SYS_REFCURSOR
);

FUNCTION IsApprovalDashboardScenario(
	in_scenario_run_sid				IN	APPROVAL_DASHBOARD.active_period_scenario_run_sid%TYPE
) RETURN NUMBER;

PROCEDURE GetAggregateApprovalVals(
	in_scenario_run_sid				IN	APPROVAL_DASHBOARD.active_period_scenario_run_sid%TYPE,
	in_aggregate_ind_group_id		IN	NUMBER,
	out_value_cur					OUT SYS_REFCURSOR,
	out_source_detail_cur			OUT SYS_REFCURSOR
);

/*
	PROCEDURES USED IN REPORTING SECTION
*/

PROCEDURE GetReportablePortlets(
	in_approval_dashboard_sid		IN  APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE UpdateDashboardReportSid(
	in_approval_dashboard_sid		IN  APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_tpl_report_sid				IN	APPROVAL_DASHBOARD.tpl_report_sid%TYPE
);

PROCEDURE GetDashboardReportDetails(
	in_approval_dashboard_sid		IN	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

/*
	PROCEDURES USED BY APPROVAL NOTE PORTLET
*/

PROCEDURE GetApprovalNotePortletNote(
	in_approval_dashboard_sid		IN	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_sid					IN	APPROVAL_DASHBOARD_INSTANCE.region_sid%TYPE,
	in_tab_portlet_id				IN	APPROVAL_NOTE_PORTLET_NOTE.tab_portlet_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE SaveApprovalNotePortletNote(
	in_approval_dashboard_sid		IN	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_sid					IN	APPROVAL_DASHBOARD_INSTANCE.region_sid%TYPE,
	in_tab_portlet_id				IN	APPROVAL_NOTE_PORTLET_NOTE.tab_portlet_id%TYPE,
	in_note							IN	APPROVAL_NOTE_PORTLET_NOTE.note%TYPE,
	in_added_by_sid					IN	APPROVAL_NOTE_PORTLET_NOTE.added_by_sid%TYPE
);

PROCEDURE GetApprovalNotePortletNoteVers(
	in_approval_dashboard_sid		IN	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_instance_id					IN	APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE,
	in_region_sid					IN	APPROVAL_DASHBOARD_INSTANCE.region_sid%TYPE,
	in_tab_portlet_id				IN	APPROVAL_NOTE_PORTLET_NOTE.tab_portlet_id%TYPE,
	out_version						OUT APPROVAL_NOTE_PORTLET_NOTE.version%TYPE
);

PROCEDURE GetApprovalNotePortletNoteHist(
	in_approval_dashboard_sid		IN	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_sid					IN	APPROVAL_DASHBOARD_INSTANCE.region_sid%TYPE,
	in_tab_portlet_id				IN	APPROVAL_NOTE_PORTLET_NOTE.tab_portlet_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetApprovalNotePortletNoteDiff(
	in_approval_dashboard_sid		IN	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_sid					IN	APPROVAL_DASHBOARD_INSTANCE.region_sid%TYPE,
	in_tab_portlet_id				IN	APPROVAL_NOTE_PORTLET_NOTE.tab_portlet_id%TYPE,
	in_version_a					IN	APPROVAL_NOTE_PORTLET_NOTE.version%TYPE,
	in_version_b					IN	APPROVAL_NOTE_PORTLET_NOTE.version%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

FUNCTION GetApprovalNoteAtVer(
	in_approval_dashboard_sid		IN	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_region_sid					IN	APPROVAL_DASHBOARD_INSTANCE.region_sid%TYPE,
	in_tab_portlet_id				IN	APPROVAL_NOTE_PORTLET_NOTE.tab_portlet_id%TYPE,
	in_instance_id					IN	APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE,
	in_version						IN	APPROVAL_NOTE_PORTLET_NOTE.version%TYPE
) RETURN VARCHAR2;

PROCEDURE ScheduledInstanceCreator;

END;
/
