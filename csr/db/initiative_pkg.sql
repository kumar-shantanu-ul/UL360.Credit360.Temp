CREATE OR REPLACE PACKAGE CSR.initiative_pkg
IS

TYPE T_DATES IS TABLE OF DATE INDEX BY PLS_INTEGER;
TYPE T_TEAM_NAMES IS TABLE OF initiative_project_team.name%TYPE INDEX BY PLS_INTEGER;
TYPE T_TEAM_EMAILS IS TABLE OF initiative_project_team.email%TYPE INDEX BY PLS_INTEGER;

-- The user is not allowed to set an initiative to a given status
ERR_SET_STATUS_DENIED			CONSTANT NUMBER := -20751;
SET_STATUS_DENIED				EXCEPTION;
PRAGMA EXCEPTION_INIT(SET_STATUS_DENIED, -20751);

-- Mandatory fileds not filled in ans status is changing to non-draft
ERR_MANDATORY_FIELDS			CONSTANT NUMBER := -20752;
MANDATORY_FIELDS				EXCEPTION;
PRAGMA EXCEPTION_INIT(MANDATORY_FIELDS, -20752);

-- Can't assign an aggregate region to an initiative
ERR_AGGR_REGION_ASSIGN			CONSTANT NUMBER := -20753;
AGGR_REGION_ASSIGN				EXCEPTION;
PRAGMA EXCEPTION_INIT(AGGR_REGION_ASSIGN, -20753);

-- Reference should be unique
ERR_DUP_REFERENCE				CONSTANT NUMBER := -20754;
DUP_REFERENCE					EXCEPTION;
PRAGMA EXCEPTION_INIT(DUP_REFERENCE, -20754);

FUNCTION INIT_EmptySidIds
RETURN security_pkg.T_SID_IDS;

FUNCTION INIT_EmptyTeamNames
RETURN T_TEAM_NAMES;

FUNCTION INIT_EmptyTeamEmails
RETURN T_TEAM_EMAILS;

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
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid		IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

PROCEDURE TrashObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE GetOptions(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetOptions(
	in_initiative_name_gen_proc		IN	initiatives_options.initiative_name_gen_proc%TYPE		DEFAULT NULL,
	in_initiative_reminder_alerts	IN	initiatives_options.initiative_reminder_alerts%TYPE		DEFAULT 0,
	in_initiative_new_days			IN	initiatives_options.initiative_new_days%TYPE			DEFAULT 5,
	in_gantt_period_colour			IN	initiatives_options.gantt_period_colour%TYPE			DEFAULT 0,
	in_initiatives_host				IN	initiatives_options.initiatives_host%TYPE				DEFAULT NULL,
	in_my_initiatives_options		IN	initiatives_options.my_initiatives_options%TYPE			DEFAULT NULL,
	in_auto_complete_date			IN	initiatives_options.auto_complete_date%TYPE				DEFAULT 1,
	in_update_ref_on_amend			IN	initiatives_options.update_ref_on_amend%TYPE			DEFAULT 0,
	in_current_report_date			IN	initiatives_options.current_report_date%TYPE			DEFAULT NULL,
	in_metrics_start_year			IN	initiatives_options.metrics_start_year%TYPE				DEFAULT 2012,
	in_metrics_end_year				IN	initiatives_options.metrics_end_year%TYPE				DEFAULT 2030
);

FUNCTION GetCreatePageUrl 
RETURN VARCHAR2;

PROCEDURE SetRegions(
	in_initiative_sid 			IN	security_pkg.T_SID_ID,
	in_region_sids				IN	security_pkg.T_SID_IDS
);

PROCEDURE SetUsers(
	in_initiative_sid 			IN	security_pkg.T_SID_ID,
	in_initiative_user_group_id IN  initiative_user_group.initiative_user_group_id%TYPE,
	in_user_sids				IN	security_pkg.T_SID_IDS
);

PROCEDURE SetTags(
	in_initiative_sid 			IN	security_pkg.T_SID_ID,
	in_tag_ids					IN	security_pkg.T_SID_IDS
);

PROCEDURE SetTeamAndSponsor(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	in_project_team_names		IN	T_TEAM_NAMES,
	in_project_team_emails		IN	T_TEAM_EMAILS,
	in_sponsor_names			IN	T_TEAM_NAMES,
	in_sponsor_emails			IN	T_TEAM_EMAILS
);

PROCEDURE SetExtraInfoValue(
	in_initiative_sid	IN	security_pkg.T_SID_ID,
	in_key		    	IN	VARCHAR2,		
	in_value	    	IN	VARCHAR2
);

PROCEDURE AutoGenerateRef(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	out_ref						OUT	initiative.internal_ref%TYPE
);

PROCEDURE CreateDocLib(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	out_doc_lib_sid				OUT	security_pkg.T_SID_ID
);

PROCEDURE CreateInitiative(
	in_project_sid				IN	security_pkg.T_SID_ID,
	in_parent_initiative_sid	IN	security_pkg.T_SID_ID,

	in_name						IN	initiative.name%TYPE,
	in_ref						IN	initiative.internal_ref%TYPE  DEFAULT NULL,
	in_flow_state_id			IN	flow_state.flow_state_id%TYPE DEFAULT NULL,

	in_project_start_dtm		IN	initiative.project_start_dtm%TYPE,
	in_project_end_dtm			IN	initiative.project_end_dtm%TYPE,
	in_running_start_dtm		IN 	initiative.running_start_dtm%TYPE,
	in_running_end_dtm			IN 	initiative.running_end_dtm%TYPE,

	in_period_duration	        IN	initiative.period_duration%TYPE DEFAULT 1,
	in_created_by_sid			IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_created_dtm				IN	initiative.created_dtm%TYPE DEFAULT NULL,
	in_is_ramped				IN 	initiative.is_ramped%TYPE DEFAULT 0,
	in_saving_type_id			IN	initiative.saving_type_id%TYPE,

	in_fields_xml				IN	initiative.fields_xml%TYPE DEFAULT NULL,
	in_region_sids				IN	security_pkg.T_SID_IDS DEFAULT INIT_EmptySidIds,
	in_tags						IN	security_pkg.T_SID_IDS DEFAULT INIT_EmptySidIds,

	in_measured_ids				IN	security_pkg.T_SID_IDS DEFAULT INIT_EmptySidIds,
	in_proposed_ids				IN	security_pkg.T_SID_IDS DEFAULT INIT_EmptySidIds,
	in_proposed_vals			IN	initiative_metric_pkg.T_METRIC_VALS DEFAULT initiative_metric_pkg.INIT_EmptyMetricVals,
	in_proposed_uoms			IN	security_pkg.T_SID_IDS DEFAULT INIT_EmptySidIds,

	in_project_team_names		IN	T_TEAM_NAMES DEFAULT INIT_EmptyTeamNames,
	in_project_team_emails		IN	T_TEAM_EMAILS DEFAULT INIT_EmptyTeamEmails,
	in_sponsor_names			IN	T_TEAM_NAMES DEFAULT INIT_EmptyTeamNames,
	in_sponsor_emails			IN	T_TEAM_EMAILS DEFAULT INIT_EmptyTeamEmails,

	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE AmendInitiative(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	in_project_sid				IN	security_pkg.T_SID_ID,
	in_parent_initiative_sid	IN	security_pkg.T_SID_ID,

	in_name						IN	initiative.name%TYPE,
	in_ref						IN	initiative.internal_ref%TYPE  DEFAULT NULL,
	in_flow_state_id			IN	flow_state.flow_state_id%TYPE DEFAULT NULL,

	in_project_start_dtm		IN	initiative.project_start_dtm%TYPE,
	in_project_end_dtm			IN	initiative.project_end_dtm%TYPE,
	in_running_start_dtm		IN 	initiative.running_start_dtm%TYPE,
	in_running_end_dtm			IN 	initiative.running_end_dtm%TYPE,

	in_period_duration	        IN	initiative.period_duration%TYPE DEFAULT 1,
	in_created_by_sid			IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_created_dtm				IN	initiative.created_dtm%TYPE DEFAULT NULL,
	in_is_ramped				IN 	initiative.is_ramped%TYPE DEFAULT 0,
	in_saving_type_id			IN	initiative.saving_type_id%TYPE,

	in_fields_xml				IN	initiative.fields_xml%TYPE DEFAULT NULL,
	in_region_sids				IN	security_pkg.T_SID_IDS DEFAULT INIT_EmptySidIds,
	in_tags						IN	security_pkg.T_SID_IDS DEFAULT INIT_EmptySidIds,

	in_measured_valid			IN	NUMBER DEFAULT 0,
	in_measured_ids				IN	security_pkg.T_SID_IDS DEFAULT INIT_EmptySidIds,

	in_proposed_valid			IN	NUMBER DEFAULT 0,
	in_proposed_ids				IN	security_pkg.T_SID_IDS DEFAULT INIT_EmptySidIds,
	in_proposed_vals			IN	initiative_metric_pkg.T_METRIC_VALS DEFAULT initiative_metric_pkg.INIT_EmptyMetricVals,
	in_proposed_uoms			IN	security_pkg.T_SID_IDS DEFAULT INIT_EmptySidIds,

	in_project_team_valid		IN	NUMBER DEFAULT 0,
	in_project_team_names		IN	T_TEAM_NAMES DEFAULT INIT_EmptyTeamNames,
	in_project_team_emails		IN	T_TEAM_EMAILS DEFAULT INIT_EmptyTeamEmails,

	in_sponsor_valid			IN	NUMBER DEFAULT 0,
	in_sponsor_names			IN	T_TEAM_NAMES DEFAULT INIT_EmptyTeamNames,
	in_sponsor_emails			IN	T_TEAM_EMAILS DEFAULT INIT_EmptyTeamEmails,

	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInitiativeDetails(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveComment(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	in_comment_text			IN  initiative_comment.comment_text%TYPE
);

PROCEDURE GetInitiativeComments(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInitiativeRegions(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetUserGroups(
	out_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetTagGroups(
	out_cur		OUT	SYS_REFCURSOR,
	out_members OUT SYS_REFCURSOR
);

PROCEDURE GetInitiativeTags(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInitiativeUsers(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_users_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_groups_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInitiativeTeam(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInitiativeIssues(
	in_initiative_sid	IN	initiative.initiative_sid%TYPE,
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE GetIssuesByDueDtm (
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	issue.due_dtm%TYPE,
	in_end_dtm					IN	issue.due_dtm%TYPE,
	in_my_issues				IN	NUMBER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInitiativeSponsors(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInitiative(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_initiative			OUT	security_pkg.T_OUTPUT_CUR,
	out_regions				OUT	security_pkg.T_OUTPUT_CUR,
	out_tags				OUT	security_pkg.T_OUTPUT_CUR,
	out_users				OUT	security_pkg.T_OUTPUT_CUR,
	out_user_groups			OUT security_pkg.T_OUTPUT_CUR,
	out_metrics				OUT	security_pkg.T_OUTPUT_CUR,
	out_uoms				OUT	security_pkg.T_OUTPUT_CUR,
	out_assoc				OUT	security_pkg.T_OUTPUT_CUR,
	out_team				OUT	security_pkg.T_OUTPUT_CUR,
	out_sponsor				OUT	security_pkg.T_OUTPUT_CUR,
	out_issues				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllowedTransitions(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetState(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	in_transition_id		IN	flow_state_transition.flow_state_transition_id%TYPE,
	in_comment				IN	flow_state_log.comment_text%TYPE
);

PROCEDURE SetState(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	in_transition_id		IN	flow_state_transition.flow_state_transition_id%TYPE,
	in_comment				IN	flow_state_log.comment_text%TYPE,
	out_to_state_id			OUT	flow_state.flow_state_id%TYPE,
	out_to_state_label		OUT	flow_state.label%TYPE
);

PROCEDURE AddIssue(
	in_initiative_sid				IN initiative.initiative_sid%TYPE,
	in_label						IN	issue.label%TYPE,
	in_description					IN	issue_log.message%TYPE,
	in_issue_type_id				IN	issue.issue_type_id%TYPE,
	in_due_dtm						IN	issue.due_dtm%TYPE,
	in_source_url					IN	issue.source_url%TYPE,
	in_assigned_to_user_sid			IN	issue.assigned_to_user_sid%TYPE,
	in_is_urgent					IN	NUMBER,
	in_is_critical					IN	issue.is_critical%TYPE DEFAULT 0,
	out_issue_id					OUT issue.issue_id%TYPE
);

PROCEDURE GetSavingTypes (
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetUpcomingEvents(
	in_initiative_sid	IN 	security_pkg.T_SID_ID,
	in_max_events		IN	NUMBER,	
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetEvents(
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE,
	in_initiative_sid 	IN 	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddEvent(
	in_initiative_sid 		IN  security_pkg.T_SID_ID,
	in_description			IN  initiative_event.description%TYPE,
	in_start_dtm			IN	initiative_event.start_dtm%TYPE,
	in_end_dtm				IN	initiative_event.end_dtm%TYPE,
	in_location				IN  initiative_event.location%TYPE
);

PROCEDURE AmendEvent(
	in_initiative_sid 		IN  security_pkg.T_SID_ID,
	in_initiative_event_id 	IN  initiative_event.initiative_event_id%TYPE,
	in_description			IN  initiative_event.description%TYPE,
	in_start_dtm			IN	initiative_event.start_dtm%TYPE,
	in_end_dtm				IN	initiative_event.end_dtm%TYPE,
	in_location				IN  initiative_event.location%TYPE
);

PROCEDURE DeleteEvent(
	in_initiative_sid 		IN  security_pkg.T_SID_ID,
	in_initiative_event_id 	IN  initiative_event.initiative_event_id%TYPE
);

PROCEDURE GetCalendars(
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION HasProjectTabs RETURN NUMBER;

-- Initiative tab procedures
PROCEDURE GetInitiativeTabs (
	in_project_sid				 	IN  security_pkg.T_SID_ID,
	in_initiative_sid 		IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE InsertTab(
	in_project_sid					IN  security_pkg.T_SID_ID,
	in_js_class 		 			IN 	plugin.js_class%TYPE,
	in_tab_label					IN  initiative_project_tab.tab_label%TYPE,
	in_pos 							IN  initiative_project_tab.pos%TYPE
);

PROCEDURE SaveInitiativeTab (
	in_project_sid					IN  security_pkg.T_SID_ID,
	in_plugin_id 		 			IN  plugin.plugin_id%TYPE,
	in_tab_label					IN  initiative_project_tab.tab_label%TYPE,
	in_pos 							IN  initiative_project_tab.pos%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE RemoveInitiativeTab(
	in_project_sid					IN  security_pkg.T_SID_ID,
	in_plugin_id					IN  meter_tab.plugin_id%TYPE
);
-- End of initiative tab procedures

PROCEDURE GetRagOptions (
	in_initiative_sid 		IN 	 security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetRagStatus(
	in_initiative_sid 			IN 	 security_pkg.T_SID_ID,
	in_rag_status_id			IN  issue.rag_status_id%TYPE
);

PROCEDURE GetUserMsgReplies(
	in_reply_to_msg_id			IN  user_msg.user_msg_id%TYPE,
	in_no_of_replies			IN	NUMBER DEFAULT NULL,
	out_msgs_cur 				OUT SYS_REFCURSOR,
	out_files_cur  				OUT SYS_REFCURSOR,
	out_likes_cur				OUT SYS_REFCURSOR
);

PROCEDURE AddUserMsgReply(
	in_reply_to_msg_id 		IN  user_msg.user_msg_id%TYPE,
	in_msg_text				IN  user_msg.msg_text%TYPE,
	in_cache_keys			IN	security_pkg.T_VARCHAR2_ARRAY,
	out_msg_cur 			OUT SYS_REFCURSOR,
	out_files_cur  			OUT SYS_REFCURSOR
);

PROCEDURE GetUserMsgs(
	in_initiative_sid 			IN  security_pkg.T_SID_ID, 
	out_msgs_cur 				OUT SYS_REFCURSOR,
	out_files_cur  				OUT SYS_REFCURSOR,
	out_likes_cur				OUT SYS_REFCURSOR
);

PROCEDURE AddUserMsg(
	in_initiative_sid 		IN  security_pkg.T_SID_ID,
	in_msg_text				IN  user_msg.msg_text%TYPE,
	in_cache_keys			IN	security_pkg.T_VARCHAR2_ARRAY,
	out_msg_cur 			OUT SYS_REFCURSOR,
	out_files_cur  			OUT SYS_REFCURSOR
);

-- Create tab element procedures.
PROCEDURE SaveTabElement (
	in_element_id		IN	init_tab_element_layout.element_id%TYPE,
	in_plugin_id		IN	init_tab_element_layout.plugin_id%TYPE,
	in_tag_group_id		IN  init_tab_element_layout.tag_group_id%TYPE,
	in_xml_field_id		IN	init_tab_element_layout.xml_field_id%TYPE,
	in_pos				IN	init_tab_element_layout.pos%TYPE
);

PROCEDURE DeleteTabElement (
	in_element_id		IN	init_tab_element_layout.element_id%TYPE
);

PROCEDURE GetTabElements (
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);
-- End tab element procedures.

-- Create page element procedures.
PROCEDURE SaveCreatePageElement (
	in_element_id		IN	init_create_page_el_layout.element_id%TYPE,
	in_tag_group_id		IN  init_create_page_el_layout.tag_group_id%TYPE,
	in_xml_field_id		IN	init_create_page_el_layout.xml_field_id%TYPE,
	in_pos				IN	init_create_page_el_layout.pos%TYPE,
	in_section_id		IN	init_create_page_el_layout.section_id%TYPE
);

PROCEDURE DeleteCreatePageElement (
	in_element_id		IN	init_create_page_el_layout.element_id%TYPE
);

PROCEDURE GetCreatePageElements (
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);
-- End create page element procedures.

-- Header element procedures
PROCEDURE GetHeaderElements (
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE SaveHeaderElement (
	in_init_header_element_id		IN	initiative_header_element.initiative_header_element_id%TYPE DEFAULT NULL,
	in_pos							IN	initiative_header_element.pos%TYPE,
	in_col							IN	initiative_header_element.col%TYPE,
	in_initiative_metric_id			IN  initiative_header_element.initiative_metric_id%TYPE DEFAULT NULL,
	in_tag_group_id					IN  initiative_header_element.tag_group_id%TYPE DEFAULT NULL,
	in_init_header_core_element_id	IN  initiative_header_element.init_header_core_element_id%TYPE DEFAULT NULL,
	out_init_header_element_id		OUT	initiative_header_element.initiative_header_element_id%TYPE
);

PROCEDURE DeleteHeaderElement (
	in_init_header_element_id		IN	initiative_header_element.initiative_header_element_id%TYPE
);

-- End of header element procedures

PROCEDURE GetAuditLogPaged(
	in_initiative_sid	IN	security_pkg.T_SID_ID,
	in_order_by			IN	VARCHAR2, -- redundant but needed for quick list output
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	in_start_date		IN	DATE,
	in_end_date			IN	DATE,
	out_total			OUT	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
);

END initiative_pkg;
/
