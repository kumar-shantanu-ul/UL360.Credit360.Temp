CREATE OR REPLACE PACKAGE CSR.initiative_project_pkg
IS

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

PROCEDURE MoveObject(
	in_act					IN security_pkg.T_ACT_ID,
	in_task_sid				IN security_pkg.T_SID_ID,
	in_new_parent_sid		IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

PROCEDURE TrashObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_task_sid		IN security_pkg.T_SID_ID
);

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE CreateProject (
	in_name					IN	initiative_project.name%TYPE,
	in_flow_sid				IN	security_pkg.T_SID_ID,
	in_live_flow_state_id	IN	initiative_project.live_flow_state_id%TYPE DEFAULT NULL,
	in_start_dtm			IN	initiative_project.start_dtm%TYPE DEFAULT NULL,
	in_end_dtm				IN	initiative_project.end_dtm%TYPE DEFAULT NULL,
	in_icon					IN	initiative_project.icon%TYPE DEFAULT NULL,
	in_abbreviation			IN	initiative_project.abbreviation%TYPE DEFAULT NULL,
	in_fields_xml			IN	initiative_project.fields_xml%TYPE DEFAULT XMLType('<fields/>'),
	in_period_fields_xml	IN	initiative_project.period_fields_xml%TYPE DEFAULT XMLType('<fields/>'),
	in_pos_group			IN	initiative_project.pos_group%TYPE DEFAULT NULL,
	in_pos					IN	initiative_project.pos%TYPE DEFAULT NULL,
	out_project_sid			OUT	security_pkg.T_SID_ID
);

PROCEDURE SetProject (
	in_project_sid					IN	security_pkg.T_SID_ID,
	in_name							IN	initiative_project.name%TYPE,
	in_flow_sid						IN	security_pkg.T_SID_ID,
	in_icon							IN	initiative_project.icon%TYPE DEFAULT NULL,
	in_abbreviation					IN	initiative_project.abbreviation%TYPE DEFAULT NULL,
	in_fields_xml					IN	initiative_project.fields_xml%TYPE DEFAULT XMLType('<fields/>'),
	in_pos							IN	initiative_project.pos%TYPE DEFAULT NULL,
	out_project_sid					OUT	security_pkg.T_SID_ID
);

PROCEDURE TryDeleteProject( 
	in_project_sid					IN  security_pkg.T_SID_ID
);

PROCEDURE DeleteRemainingMetricGroups (
	in_project_sid					IN	security_pkg.T_SID_ID,
	in_pos_groups_to_keep			IN	security_pkg.T_SID_IDS
);

PROCEDURE EmptyTempMetricTables;

PROCEDURE AddTempInitiativeMetric (
	in_initiative_metric_id			IN  temp_project_initiative_metric.initiative_metric_id%TYPE,
	in_pos							IN  temp_project_initiative_metric.pos%TYPE,
	in_input_dp						IN  temp_project_initiative_metric.input_dp	%TYPE,
	in_info_text					IN  temp_project_initiative_metric.info_text%TYPE
);

PROCEDURE AddTempInitiativeMetricState (
	in_initiative_metric_id			IN  temp_init_metric_flow_state.initiative_metric_id%TYPE,
	in_flow_state_id				IN  temp_init_metric_flow_state.flow_state_id%TYPE,
	in_mandatory					IN  temp_init_metric_flow_state.mandatory%TYPE,
	in_visible						IN  temp_init_metric_flow_state.visible%TYPE
);

PROCEDURE SetProjectMetricGroup (
	in_project_sid					IN	security_pkg.T_SID_ID,
	in_pos_group					IN  initiative_metric_group.pos_group%TYPE,
	in_is_group_mandatory			IN  initiative_metric_group.is_group_mandatory%TYPE,
	in_label						IN  initiative_metric_group.label%TYPE,
	in_info_text					IN  initiative_metric_group.info_text%TYPE,
	out_pos_group					OUT initiative_metric_group.pos_group%TYPE
);

PROCEDURE GetProject(
	in_project_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProjects(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProjectSidsUsedForInitiatives(
	out_projectsids_cur	OUT SYS_REFCURSOR
);

PROCEDURE GetProjectsAndMetrics(
	out_projects_cur				OUT SYS_REFCURSOR,
	out_metric_group_cur			OUT SYS_REFCURSOR,
	out_metric_cur					OUT SYS_REFCURSOR,
	out_metric_flow_state_cur		OUT SYS_REFCURSOR
);

PROCEDURE GetTagGroups(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTagGroupsForProject(
	in_project_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTagFilters(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTagGroupMembers(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_group_id				IN	tag_group.tag_group_id%TYPE,
	in_project_sid				IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

END initiative_project_pkg;
/
