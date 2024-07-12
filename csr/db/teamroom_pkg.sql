CREATE OR REPLACE PACKAGE CSR.teamroom_pkg IS

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

PROCEDURE InsertTab(
	in_teamroom_type_id		IN  teamroom_type.teamroom_type_id%TYPE,
	in_js_class 		 	IN 	plugin.js_class%TYPE,
	in_tab_label			IN  teamroom_type_tab.tab_label%TYPE,
	in_pos 					IN  teamroom_type_tab.pos%TYPE
);

PROCEDURE CreateTeamroomType(
	in_label				IN  teamroom_type.label%TYPE,
	in_base_css_class		IN  teamroom_type.base_css_class%TYPE,
	out_teamroom_type_id	OUT teamroom_type.teamroom_type_id%TYPE
);

-- we do this because we want to call this from the ASHX where ACT not available
PROCEDURE IsReadAccessAllowed(
	in_teamroom_sid			IN	security_pkg.T_SID_ID,
	out_result				OUT NUMBER
);

PROCEDURE GetTeamroomTypes(
	out_teamroom_type_cur		OUT SYS_REFCURSOR
);

PROCEDURE GetTeamroomTabs (
	in_teamroom_sid 	IN 	 security_pkg.T_SID_ID,
	out_cur				OUT  SYS_REFCURSOR
);

PROCEDURE ClearImg(
	in_teamroom_sid 				IN  security_pkg.T_SID_ID
);

PROCEDURE SetImg(
	in_teamroom_sid 				IN  security_pkg.T_SID_ID,
	in_cache_key 				IN  VARCHAR2
);

PROCEDURE AmendTeamroom(
	in_teamroom_sid 			IN  security_pkg.T_SID_ID,
	in_teamroom_type_id			IN  teamroom.teamroom_type_id%TYPE,
	in_name						IN  teamroom.name%TYPE,
	in_description				IN  teamroom.description%TYPE
);

PROCEDURE CreateTeamroom(	
	in_teamroom_type_id			IN  teamroom.teamroom_type_id%TYPE,
	in_name						IN  teamroom.name%TYPE,
	in_description				IN  teamroom.description%TYPE,
	in_parent_sid 				IN  security_pkg.T_SID_ID DEFAULT NULL,
	out_teamroom_sid			OUT security_pkg.T_SID_ID
);

PROCEDURE InviteMembers(
	in_teamroom_sid			IN  security_pkg.T_SID_ID,
	in_user_sids			IN 	security_pkg.T_SID_IDS,
	in_msg					IN  VARCHAR2,
	out_active_members_cur	OUT SYS_REFCURSOR
);

PROCEDURE AcceptInvitation(
	in_teamroom_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN 	security_pkg.T_SID_ID,
	out_accepted			OUT NUMBER
);

PROCEDURE DeactivateMember(
	in_teamroom_sid 	IN  security_pkg.T_SID_ID,
	in_user_sid 		IN  security_pkg.T_SID_ID
);

-- get the basics for editing
PROCEDURE GetSimpleTeamroom(
	in_teamroom_sid 		IN  security_pkg.T_SID_ID, 
	out_cur 				OUT SYS_REFCURSOR
);

PROCEDURE GetTeamroom(
	in_teamroom_sid 			IN  security_pkg.T_SID_ID, 
	out_teamroom_cur 			OUT SYS_REFCURSOR,
	out_active_members_cur  	OUT SYS_REFCURSOR	
);

PROCEDURE GetUserMsgs(
	in_teamroom_sid 			IN  security_pkg.T_SID_ID, 
	out_msgs_cur 				OUT SYS_REFCURSOR,
	out_files_cur  				OUT SYS_REFCURSOR,
	out_likes_cur				OUT SYS_REFCURSOR
);


PROCEDURE AddUserMsg(
	in_teamroom_sid 		IN  security_pkg.T_SID_ID,
	in_msg_text				IN  user_msg.msg_text%TYPE,
	in_cache_keys			IN	security_pkg.T_VARCHAR2_ARRAY,
	out_msg_cur 			OUT SYS_REFCURSOR,
	out_files_cur  			OUT SYS_REFCURSOR
);

FUNCTION CanViewUserMsgImage(
	in_user_msg_file_Id		IN 	user_msg_file.user_msg_file_id%TYPE,
	in_sha1					IN	user_msg_file.sha1%TYPE
) RETURN NUMBER;

PROCEDURE GetTeamrooms(
	out_cur 				OUT SYS_REFCURSOR,
	out_open_invitations	OUT SYS_REFCURSOR
);

PROCEDURE GetTeamroomImage(
	in_teamroom_sid	IN 	security_pkg.T_SID_ID,
	out_cur			OUT  SYS_REFCURSOR
);

PROCEDURE IsTeamroomImageFresh(
	in_teamroom_sid			IN 	security_pkg.T_SID_ID,
	in_cached_image_mtime	IN DATE,
	out_image_fresh			OUT	NUMBER
);

PROCEDURE GetUserMsgImage(
	in_user_msg_file_Id		IN 	user_msg_file.user_msg_file_id%TYPE,
	in_sha1					IN	user_msg_file.sha1%TYPE,
	out_cur					OUT  SYS_REFCURSOR
);

PROCEDURE GetIssues(
	in_teamroom_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE GetIssuesByDueDtm (
	in_teamroom_sid				IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	issue.due_dtm%TYPE,
	in_end_dtm					IN	issue.due_dtm%TYPE,
	in_my_issues				IN	NUMBER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddIssue(
	in_teamroom_sid 				IN 	security_pkg.T_SID_ID,
	in_label						IN	issue.label%TYPE,
	in_description					IN	issue_log.message%TYPE,
	in_assign_to					IN	issue.assigned_to_user_sid%TYPE,
	in_due_dtm						IN	issue.due_dtm%TYPE,
	in_source_url					IN	issue.source_url%TYPE,
	in_is_urgent					IN	NUMBER,
	in_is_critical					IN	issue.is_critical%TYPE DEFAULT 0,
	out_issue_id					OUT issue.issue_id%TYPE
);

PROCEDURE GetCalendars(
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetEvents(
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE,
	in_teamroom_sid 	IN 	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetEventUsers(
	in_event_id			IN	NUMBER,
	out_owner_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_attendee_cur	OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetUpcomingEvents(
	in_teamroom_sid 	IN 	security_pkg.T_SID_ID,
	in_max_events		IN	NUMBER,	
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddEvent(
	in_teamroom_sid 		IN  security_pkg.T_SID_ID,
	in_description			IN  calendar_event.description%TYPE,
	in_start_dtm			IN	calendar_event.start_dtm%TYPE,
	in_end_dtm				IN	calendar_event.end_dtm%TYPE,
	in_location				IN  calendar_event.location%TYPE,
	in_owner_ids			IN	security.security_pkg.T_SID_IDS,
	in_invited_ids			IN	security.security_pkg.T_SID_IDS
);

PROCEDURE AmendEvent(
	in_teamroom_sid 		IN  security_pkg.T_SID_ID,
	in_calendar_event_id 	IN  teamroom_event.calendar_event_id%TYPE,
	in_description			IN  calendar_event.description%TYPE,
	in_start_dtm			IN	calendar_event.start_dtm%TYPE,
	in_end_dtm				IN	calendar_event.end_dtm%TYPE,
	in_location				IN  calendar_event.location%TYPE,
	in_owner_ids			IN	security.security_pkg.T_SID_IDS,
	in_invited_ids			IN	security.security_pkg.T_SID_IDS
);

PROCEDURE DeleteEvent(
	in_teamroom_sid 		IN  security_pkg.T_SID_ID,
	in_calendar_event_id 	IN  teamroom_event.calendar_event_id%TYPE
);

PROCEDURE DeleteTeamroom(
	in_teamroom_sid			IN  security_pkg.T_SID_ID
);

PROCEDURE LinkInitiative(
	in_teamroom_sid			IN  security_pkg.T_SID_ID,
	in_initiative_sid		IN  security_pkg.T_SID_ID
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

PROCEDURE GetIssueAssignables(  
	in_issue_id					IN  teamroom_issue.issue_id%TYPE,
	in_filter					IN	VARCHAR2,
	in_include_inactive			IN	NUMBER DEFAULT 0,
	out_cur						OUT SYS_REFCURSOR,
	out_total_num_users			OUT SYS_REFCURSOR
);

PROCEDURE FilterMembers(
	in_teamroom_sid				IN  security_pkg.T_SID_ID,
	in_filter					IN	VARCHAR2,
	in_include_inactive			IN	NUMBER DEFAULT 0,
	out_cur						OUT Security_Pkg.T_OUTPUT_CUR
);

FUNCTION IsChainEnabled
RETURN NUMBER;

PROCEDURE GetDefaultTeamroomCompanies(
	out_cur 				OUT SYS_REFCURSOR
);

PROCEDURE GetTeamroomCompanies(
	in_teamroom_sid 		IN  security_pkg.T_SID_ID, 
	out_cur 				OUT SYS_REFCURSOR
);

PROCEDURE SetTeamroomCompanies(
	in_teamroom_sid 		IN  security_pkg.T_SID_ID, 
	in_company_sids			IN	security_pkg.T_SID_IDS
);

PROCEDURE GetTeamroomSuppliers(
	in_teamroom_sid 		IN  security_pkg.T_SID_ID,
	out_cur 				OUT SYS_REFCURSOR
);

PROCEDURE FilterUsers(  
	in_teamroom_sid 			IN  security_pkg.T_SID_ID,
	in_filter					IN	VARCHAR2,
	in_include_inactive			IN	NUMBER DEFAULT 0,
	in_exclude_user_sids		IN  security_pkg.T_SID_IDS, -- mainly for finding users except user X - e.g. on a user edit page.
	out_cur						OUT Security_Pkg.T_OUTPUT_CUR,
	out_total_num_users			OUT Security_Pkg.T_OUTPUT_CUR
);

PROCEDURE CreateUserForApproval(
  	in_user_name				IN	CSR_USER.user_NAME%TYPE,
	in_password 				IN	VARCHAR2, -- nullable
   	in_full_name				IN	CSR_USER.full_NAME%TYPE,
	in_email		 			IN	CSR_USER.email%TYPE,
	in_job_title				IN	CSR_USER.job_title%TYPE,
	in_phone_number				IN	CSR_USER.phone_number%TYPE,
	in_chain_company_sid 		IN	security_pkg.T_SID_ID,
	in_redirect_to_url			IN	autocreate_user.redirect_to_url%TYPE,
	in_teamroom_sid				IN	security_pkg.T_SID_ID,
	out_sid_id					OUT	security_pkg.T_SID_ID,
	out_guid					OUT	security_pkg.T_ACT_ID
);

END;
/