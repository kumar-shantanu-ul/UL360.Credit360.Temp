-- Please update version.sql too -- this keeps clean builds in sync
define version=785
@update_header

ALTER TABLE CSR.CUSTOMER ADD ENABLE_SAVE_CHART_WARNING NUMBER(1) DEFAULT 1 NOT NULL;
UPDATE CSR.CUSTOMER SET ENABLE_SAVE_CHART_WARNING = 0;

ALTER TABLE CSR.CSR_USER ADD SHOW_SAVE_CHART_WARNING NUMBER(1) DEFAULT 1 NOT NULL;

CREATE OR REPLACE PACKAGE CSR.Csr_User_Pkg
IS

ERR_NOT_ACTIVATED CONSTANT NUMBER := -02301;
NOT_ACTIVATED EXCEPTION;
PRAGMA EXCEPTION_INIT(NOT_ACTIVATED, -02301);

ERR_ALREADY_REJECTED CONSTANT NUMBER := -02302;
ALREADY_REJECTED EXCEPTION;
PRAGMA EXCEPTION_INIT(ALREADY_REJECTED, -02302);

ERR_ALREADY_APPROVED CONSTANT NUMBER := -02303;
ALREADY_APPROVED EXCEPTION;
PRAGMA EXCEPTION_INIT(ALREADY_APPROVED, -02303);

-- security interface procs
PROCEDURE CreateObject(
	in_act security_pkg.T_ACT_ID,
	in_club_sid security_pkg.T_SID_ID,
	in_class_id security_pkg.T_CLASS_ID,
	in_name security_pkg.T_SO_NAME,
	in_parent_sid_id security_pkg.T_SID_ID);

PROCEDURE RenameObject(
	in_act security_pkg.T_ACT_ID,
	in_sid_id security_pkg.T_SID_ID,
	in_new_name security_pkg.T_SO_NAME);

PROCEDURE DeleteObject(
	in_act security_pkg.T_ACT_ID,
	in_sid_id security_pkg.T_SID_ID);

PROCEDURE MoveObject(
	in_act security_pkg.T_ACT_ID,
	in_sid_id security_pkg.T_SID_ID,
	in_new_parent_sid_id security_pkg.T_SID_ID);

/**
 * LOGOFF
 * 
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 */
PROCEDURE Logoff(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sid_id				IN 	security_pkg.T_SID_ID
);

/**
 * LOGON
 * 
 * @param in_act_id			Access token
 * @param in_sid_id			The sid of the object
 * @param in_act_timeout	.
 * @param in_logon_type		.
 * @param attributes		.
 */
PROCEDURE Logon(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sid_id				IN	security_pkg.T_SID_ID,
	in_act_timeout			IN	security_pkg.T_ACT_TIMEOUT,
	in_logon_type			IN	security_pkg.T_LOGON_TYPE
);


PROCEDURE LogonFailed(
	in_sid_id				IN security_pkg.T_SID_ID,
	in_error_code			IN NUMBER,
	in_message			    IN VARCHAR2
);

/**
 * Return the SID of an account policy to use for the given user
 */
PROCEDURE GetAccountPolicy(
	in_sid_id				IN	security_pkg.T_SID_ID,
	out_policy_sid			OUT security_pkg.T_SID_ID
);

-- does all the hard work of creating a user, but doesn't 
-- call external triggers (e.g. supplier_pkg)
PROCEDURE INTERNAL_CreateUser(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
   	in_user_name					IN	CSR_USER.user_NAME%TYPE,
	in_password 					IN	VARCHAR2,
   	in_full_name					IN	CSR_USER.full_NAME%TYPE,
   	in_friendly_name				IN	CSR_USER.friendly_NAME%TYPE,
	in_email		 				IN	CSR_USER.email%TYPE,
	in_job_title					IN  CSR_USER.job_title%TYPE,
	in_phone_number					IN  CSR_USER.phone_number%TYPE,
	in_region_mount_point_sid	 	IN 	security_pkg.T_SID_ID,
	in_info_xml						IN  csr_user.info_xml%TYPE,
	in_send_alerts					IN	csr_user.send_alerts%TYPE,
	out_user_sid 					OUT security_pkg.T_SID_ID
);


/**
 * Creates a user <app>/Users, assigns them to the RegisteredUsers group
 * and sets up user attributes in csr_user table
 *
 * @param in_act						Access token.
 * @param in_app_sid					Application SID
 * @param in_user_name					User name
 * @param in_password					Password
 * @param in_full_name					Their real Name (e.g. 'Fred Bloggs')	
 * @param in_friendly_name              A friendly name or null to autogenerate from in_full_name
 * @param in_email						Email address
 * @param in_job_title					Job title
 * @param in_phone_number				Phone number
 * @param in_region_mount_point_sid		Region Mount point for this user
 * @param in_info_xml					Random extra user info
 * @param in_send_alerts				1 if alerts should be sent for the user, otherwise 0
 * @param out_user_sid					SID of user that was created
 */
PROCEDURE createUser(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
   	in_user_name					IN	CSR_USER.user_NAME%TYPE,
	in_password 					IN	VARCHAR2,
   	in_full_name					IN	CSR_USER.full_NAME%TYPE,
   	in_friendly_name				IN	CSR_USER.friendly_NAME%TYPE,
	in_email		 				IN	CSR_USER.email%TYPE,
	in_job_title					IN  CSR_USER.job_title%TYPE,
	in_phone_number					IN  CSR_USER.phone_number%TYPE,
	in_region_mount_point_sid	 	IN 	security_pkg.T_SID_ID,
	in_info_xml						IN  csr_user.info_xml%TYPE,
	in_send_alerts					IN	csr_user.send_alerts%TYPE,
	out_user_sid 					OUT security_pkg.T_SID_ID
);

PROCEDURE CreateUserForApproval(
  	in_user_name		IN	CSR_USER.user_NAME%TYPE,
	in_password 		IN	VARCHAR2, -- nullable
   	in_full_name		IN	CSR_USER.full_NAME%TYPE,
	in_email		 	IN	CSR_USER.email%TYPE,
	out_sid_id			OUT	security_pkg.T_SID_ID,
	out_guid			OUT	security_pkg.T_ACT_ID
);

/**
 * Creates a user under //csr/Users, assigns them to the //csr/SuperAdmins group
 * and sets up user attributes in csr_user table
 *
 * @param in_act						Access token
 * @param in_user_name					User name
 * @param in_password					Password
 * @param in_full_name					Their real Name (e.g. 'Fred Bloggs')	
 * @param in_email						Email address
 * @param out_user_sid					SID of user that was created
 */
PROCEDURE createSuperAdmin(
	in_act			 				IN	security_pkg.T_ACT_ID,
   	in_user_name					IN	CSR_USER.user_NAME%TYPE,
	in_password 					IN	VARCHAR2,
   	in_full_name					IN	CSR_USER.full_NAME%TYPE,
   	in_friendly_name				IN	CSR_USER.friendly_NAME%TYPE,
	in_email		 				IN	CSR_USER.email%TYPE,
	out_user_sid 					OUT security_pkg.T_SID_ID
);

/**
 * Check if the logged on user is a superadmin
 *
 * @return								1 if the user is a superadmin, otherwise 0
 */
FUNCTION IsSuperAdmin
RETURN NUMBER;

/**
 * Set some basic details (called by userSettings)
 *
 * @param in_act						Access token
 * @param in_user_sid					User Sid
 * @param in_full_name					Their real Name (e.g. 'Fred Bloggs')	
 * @param in_email						Email address
 */
PROCEDURE setBasicDetails(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_user_sid		 				IN	security_pkg.T_SID_ID,
   	in_full_name					IN	CSR_USER.full_NAME%TYPE,
   	in_friendly_name				IN	CSR_USER.friendly_NAME%TYPE,
	in_email		 				IN	CSR_USER.email%TYPE,
	in_info_xml                     IN  CSR_USER.info_xml%TYPE
);

/**
 * Updates a user's details in csr_user table
 *
 * @param in_act						Access token
 * @param in_user_sid					User Sid
 * @param in_user_name					User name
 * @param in_full_name					Their real Name (e.g. 'Fred Bloggs')	
 * @param in_email						Email address
 * @param in_job_title					Job title
 * @param in_phone_number				Phone number
 * @param in_region_mount_point_sid		Region Mount point for this user  (can be null - use current state)
 * @param in_active						Active (can be null - use current state)
 * @param in_info_xml					Random extra user info
 */
PROCEDURE amendUser(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_user_sid		 				IN	security_pkg.T_SID_ID,
   	in_user_name					IN	CSR_USER.user_NAME%TYPE,
   	in_full_name					IN	CSR_USER.full_NAME%TYPE,
   	in_friendly_name				IN	CSR_USER.friendly_NAME%TYPE,
	in_email		 				IN	CSR_USER.email%TYPE,
	in_job_title					IN  CSR_USER.job_title%TYPE,
	in_phone_number					IN  CSR_USER.phone_number%TYPE,
	in_region_mount_point_sid	 	IN 	security_pkg.T_SID_ID,
	in_active						IN  security_pkg.T_USER_ACCOUNT_ENABLED,
	in_info_xml						IN  csr_user.info_xml%TYPE,
	in_send_alerts					IN	csr_user.send_alerts%TYPE
);

 
PROCEDURE SetIndStartPoints(
    in_user_sid                 IN  security_pkg.T_SID_ID,
    in_ind_sids		    	    IN	security_pkg.T_SID_IDS
);

PROCEDURE SetExtraInfoValue(
	in_act		IN	security_pkg.T_ACT_ID,
	in_user_sid	IN	security_pkg.T_SID_ID,
	in_key		IN	VARCHAR2,		
	in_value	IN	VARCHAR2
);

/**
 * Activates a user's account
 *
 * @param in_act						Access token
 * @param in_user_sid					User sid
 */
PROCEDURE activateUser(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_user_sid		 				IN	security_pkg.T_SID_ID
);

/**
 * Deactivates a user's account
 *
 * @param in_act						Access token
 * @param in_user_sid					User sid
 */
PROCEDURE deactivateUser(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_user_sid		 				IN	security_pkg.T_SID_ID
);

/**
 * Deletes (deactivates and puts in trash) user's account
 *
 * @param in_act						Access token
 * @param in_user_sid					User Sid
 */
PROCEDURE DeleteUser(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_user_sid		 				IN	security_pkg.T_SID_ID
);

PROCEDURE AddAutoAccount(
	in_user_name			IN	autocreate_user.user_name%TYPE,
	in_guid					IN	autocreate_user.guid%TYPE,	
	in_created_user_sid		IN  security_pkg.T_SID_ID
);

PROCEDURE AddAutoCreateUser(
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_user_name			IN	autocreate_user.user_name%TYPE,
	out_guid 				OUT Security_Pkg.T_ACT_ID
);

PROCEDURE GetAutoCreateUser(
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_guid					IN	autocreate_user.guid%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * Get the guid of an autocreated user from the user sid
 *
 * @param in_user_sid					User sid
 * @param out_cur						A rowset of the form: guid
 */
PROCEDURE GetAutoCreateUserBySid(
	in_user_sid				IN	autocreate_user.created_user_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

/**
 * Gets general data about a user
 *
 * @param in_act						Access token.
 * @param in_user_sid					The user SID
 * @param out_cur						The output rowset
 *
 * The output rowset is of the form:
 * user_name, full_name, email, last_logon_dtm, region_mount_point_sid, indicator_mount_point_sid, app_sid
 */
PROCEDURE GetUser(
	in_act 							IN	security_pkg.T_ACT_ID,
	in_user_sid 					IN  security_pkg.T_SID_ID,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Gets general data about a user (as for GetUser but with no security check)
 *
 * @param in_user_sid					The user SID
 * @param out_cur						The output rowset
 *
 * The output rowset is of the form:
 * user_name, full_name, email, last_logon_dtm, region_mount_point_sid, indicator_mount_point_sid, app_sid
 */
PROCEDURE GetUser_INSECURE(
	in_user_sid 					IN  security_pkg.T_SID_ID,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetUserAndStartPoints(
	in_act 				IN security_pkg.T_ACT_ID,
	in_user_sid 		IN  security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR,
	out_isp_cur         OUT Security_Pkg.T_OUTPUT_CUR
);

/**
 * Gets list of all users in the users container for a give application sid
 * Active and non-active.
 *
 * @param in_act					Access token.
 * @param in_app_sid				The application sid (saves additional db lookup from most code)
 * @param in_order_by       		Order results (unused)
 * @param out_users					The user details
 * @param out_groups				Groups for each user
 * 
 * The output rowset is of the form:
 * csr_user_sid, active, user_name, full_name, friendly_name, email, last_logon_dtm, last_logon_formatted'
 */
PROCEDURE GetAllUsers(
	in_act_id       				IN  security_pkg.T_ACT_ID,
	in_app_sid    					IN  security_pkg.T_SID_ID,
	in_order_by   					IN	VARCHAR2, -- not used
	out_users     					OUT SYS_REFCURSOR,
	out_groups						OUT SYS_REFCURSOR,
	out_regions						OUT SYS_REFCURSOR,
	out_roles						OUT SYS_REFCURSOR,
	out_indicator_mount_points		OUT SYS_REFCURSOR
);

/**
 * Gets list of all active users
 *
 * @param in_act			Access token.
 * @param in_parent_sid		The sid of parent container
 * @group_sid               Filter result by group members (optional)
 * @order by                Order results (optional)
 * 
 * The output rowset is of the form:
 * csr_user_sid, active, user_name, full_name, friendly_name, email, last_logon_dtm, last_logon_formatted'
 */
PROCEDURE GetAllActiveUsers(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_parent_sid 	IN  security_pkg.T_SID_ID,
	in_group_sid	IN 	security_pkg.T_SID_ID,
	in_order_by 	IN VARCHAR2,
	out_cur			OUT security_pkg.T_OUTPUT_CUR
);

/**
 * GetUsers: this gets all users including ones that have been move to the trash
 * 
 * @param in_act_id				Access token
 * @param in_app_sid		The sid of the Application/CSR object
 * @param out_cur				The rowset
 */
PROCEDURE GetUsers(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_app_sid IN  security_pkg.T_SID_ID,	 
	out_cur			OUT security_pkg.T_OUTPUT_CUR
);

/**
 * GetUsersInGroup
 * 
 * @param in_act_id				Access token
 * @param in_app_sid		The sid of the Application/CSR object
 * @param in_group_sid			.
 * @param out_cur				The rowset
 */
PROCEDURE GetUsersInGroup(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_app_sid IN  security_pkg.T_SID_ID,
	in_group_sid	IN 	security_pkg.T_SID_ID, 	 
	out_cur			OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Search
 * 
 * @param in_act_id				Access token
 * @param in_app_sid		The sid of the Application/CSR object
 * @param in_group_sid			.
 * @param in_filter_name		.
 * @param in_order_by			.
 * @param out_cur				The rowset
 */
PROCEDURE Search(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_app_sid IN  security_pkg.T_SID_ID,	 
	in_group_sid	IN 	security_pkg.T_SID_ID, 
	in_filter_name	IN	csr_user.full_name%TYPE,
	in_order_by 	IN	VARCHAR2, 
	out_cur			OUT security_pkg.T_OUTPUT_CUR
);


/**
 * FilterUsers
 * 
 * @param in_filter				.
 * @param out_cur				The rowset
 */
PROCEDURE FilterUsers(  
	in_filter			IN	VARCHAR2,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
);

/**
 * FilterUsers
 * 
 * @param in_filter				.
 * @param in_include_inactive
 * @param out_cur				The rowset
 */
PROCEDURE FilterUsers(  
	in_filter			IN	VARCHAR2,
	in_include_inactive	IN	NUMBER DEFAULT 0,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
);

/**
 * FilterUsers into a table
 * 
 * @param in_filter			
 * @param in_include_inactive.
 * @param out_cur				The rowset
 */
PROCEDURE FilterUsersToTable (
	in_filter			IN	VARCHAR2,
	in_include_inactive	IN	NUMBER DEFAULT 0,
	out_table			OUT T_USER_FILTER_TABLE
);
	  
/**
 * GetDACL
 * 
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 * @param out_cursor	.
 */
PROCEDURE GetDACL(
	in_act_id			IN security_pkg.T_ACT_ID,
    in_sid_id			IN security_pkg.T_SID_ID,
	out_cursor			OUT security_pkg.T_OUTPUT_CUR 
);	
	
/**
 * IsLogonAsUserAllowed
 * 
 * @param in_act_id			Access token
 * @param in_user_sid		.
 * @param out_result		.
 */
PROCEDURE IsLogonAsUserAllowed(					
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_user_sid 		IN 	security_pkg.T_SID_ID,
	out_result			OUT	BINARY_INTEGER
);

PROCEDURE LogonAsUser(					
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_sid_id			IN	security_pkg.T_SID_ID,
	out_act_id			OUT Security_Pkg.T_ACT_ID
);

-- use with appropriate care!! Doesn't write back to Oracle session
FUNCTION LogonUserCreatorDaemon
RETURN security_pkg.T_ACT_ID;


/**
 * GetUsersForList
 * 
 * @param in_act_id			Access token
 * @param in_user_list		.
 * @param out_cur			The rowset
 */
PROCEDURE GetUsersForList(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_user_list	IN	VARCHAR2,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * CreateGroup
 * 
 * @param in_act_id			Access token
 * @param in_parent_sid		The sid of the parent object
 * @param in_group_name		.
 * @param out_group_sid		.
 */
PROCEDURE CreateGroup(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_parent_sid	IN	security_pkg.T_ACT_ID,
	in_group_name	IN	security_pkg.T_SO_NAME,
	out_group_sid	OUT	security_pkg.T_SID_ID
);


/**
 * GetUserNameFromSid
 * 
 * @param in_act_id			Access token
 * @param in_parent_sid		The sid of the user 
 */
FUNCTION GetUserNameFromSid(
    in_act_id				IN	security_Pkg.T_ACT_ID,
	in_user_sid				IN	security_pkg.T_SID_ID
) RETURN VARCHAR2;

PROCEDURE GetUserApprovalList(
	in_start_row			IN	NUMBER,
	in_end_row				IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ApproveAutoAccount(
	in_user_sid				IN security_pkg.T_SID_ID
);

PROCEDURE ActivateAutoAccount(
	in_user_sid				IN security_pkg.T_SID_ID
);

PROCEDURE RejectAutoAccount(
	in_user_sid				IN security_pkg.T_SID_ID
);

/**
 * Get the details of an auto-created user account
 * 
 * @param in_guid			The auto-created user guid
 * @param out_cur			A rowset of the form created_user_sid, user_name, full_name, email
 */
PROCEDURE GetAutoAccountDetails(
	in_guid					IN	autocreate_user.guid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

/**
 * Get the self registration configuration for the current application
 * 
 * @param out_cur			A rowset of the form self_reg_group_sid, self_reg_needs_approval
 */
 PROCEDURE GetSelfRegDetails(
	out_cur					OUT	SYS_REFCURSOR
);

/**
 * Mark an autocreated account has having been activated by clicking
 * on the email and filling out the form
 *
 * @param in_guid			The auto-created user guid
 */
PROCEDURE MarkAutoAccountActivated(
	in_guid					IN	autocreate_user.guid%TYPE
);

/**
 * Set the sid of the created user for an auto-created user account
 *
 * @param in_guid			The auto-created user guid
 * @param in_user_sid		The user sid to set
 */ 
PROCEDURE SetAutoAccountUser(
	in_guid					IN	autocreate_user.guid%TYPE,
	in_user_sid				IN	autocreate_user.created_user_sid%TYPE
);

/**
 * Get the donations reports filter id for the current user
 *
 * @param out_filter_id		The filter id
 */
PROCEDURE GetDonationsReportsFilterId(
	out_filter_id			OUT	csr_user.donations_reports_filter_id%TYPE
);

PROCEDURE GetEnableSaveChartWarning(
	out_enable_warning			OUT customer.enable_save_chart_warning%TYPE
);

PROCEDURE GetShowSaveChartWarning(
	out_show_warning			OUT csr_user.show_save_chart_warning%TYPE
);

PROCEDURE SetShowSaveChartWarning(
	in_show_save_chart_warning 		IN csr_user.show_save_chart_warning%TYPE
);

/**
 * Set the donations reports filter id for the current user
 *
 * @param in_filter_id		The filter id
 */
PROCEDURE SetDonationsReportsFilterId(
	in_filter_id			IN	csr_user.donations_reports_filter_id%TYPE
);

/**
 * Get the donations brwose filter id for the current user
 *
 * @param out_filter_id		The filter id
 */
PROCEDURE GetDonationsBrowseFilterId(
	out_filter_id			OUT	csr_user.donations_browse_filter_id%TYPE
);

/**
 * Set the donations browse filter id for the current user
 *
 * @param in_filter_id		The filter id
 */
PROCEDURE SetDonationsBrowseFilterId(
	in_filter_id			IN	csr_user.donations_browse_filter_id%TYPE
);

/**
 * Set localisation settings for a user
 * 
 * @param in_act_id			The access token.
 * @param in_user_sid		The user's sid.
 * @param out_language		The user's language
 * @param out_culture		The user's culture
 * @param out_timezone		The user's timezone
 */
PROCEDURE SetLocalisationSettings(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_language				IN	security.user_table.language%TYPE,
	in_culture				IN	security.user_table.culture%TYPE,
	in_timezone				IN	security.user_table.timezone%TYPE
);

/**
 * Raise a user message alert
 *
 * @param in_notify_user_sid		The user to notify
 * @param in_message				The message to send
 */
PROCEDURE RaiseUserMessageAlert(
	in_notify_user_sid				IN	user_message_alert.notify_user_sid%TYPE,
	in_message						IN	user_message_alert.message%TYPE
);

/**
 * Fetch user message alerts to send
 *
 * @param out_cur					The alert details
 */
PROCEDURE GetUserMessageAlerts(
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Record that a user message alert has been sent
 *
 * @param in_user_message_alert_id	The alert id
 */
PROCEDURE RecordUserMessageAlertSent(
	in_user_message_alert_id		IN	user_message_alert.user_message_alert_id%TYPE
);

END Csr_User_Pkg;
/

CREATE OR REPLACE PACKAGE BODY CSR.Csr_User_Pkg
IS

-- security interface procs
PROCEDURE CreateObject(
	in_act security_pkg.T_ACT_ID,
	in_club_sid security_pkg.T_SID_ID,
	in_class_id security_pkg.T_CLASS_ID,
	in_name security_pkg.T_SO_NAME,
	in_parent_sid_id security_pkg.T_SID_ID)
IS
	v_sid security_pkg.T_SID_ID;
BEGIN
	-- create container for my charts
	securableobject_pkg.createSO(in_act, in_club_sid, security_pkg.SO_CONTAINER, 'Charts',v_sid);			
	securableobject_pkg.createSO(in_act, in_club_sid, security_pkg.SO_CONTAINER, 'Workspace',v_sid);			
END CreateObject;


PROCEDURE RenameObject(
	in_act security_pkg.T_ACT_ID,
	in_sid_id security_pkg.T_SID_ID,
	in_new_name security_pkg.T_SO_NAME)
IS
BEGIN
	-- when we trash stuff the SO gets renamed to NULL (to avoid dupe obj names when we
	-- move the securable object). We don't really want to rename our objects tho.
	IF in_new_name IS NOT NULL THEN
		update csr_user set user_name = lower(in_new_name) where csr_user_sid = in_sid_id;
	END IF;
END RenameObject;


PROCEDURE DeleteObject(
	in_act security_pkg.T_ACT_ID,
	in_sid_id security_pkg.T_SID_ID)
IS
BEGIN
	chain.company_user_pkg.DeleteObject(in_act, in_sid_id);
	
	DELETE FROM audit_log 
	 WHERE object_sid = in_sid_id;

	DELETE FROM audit_log 
	 WHERE user_sid = in_sid_id;

	DELETE FROM pending_val_log 
	 WHERE set_by_user_sid = in_sid_id;

	DELETE FROM root_section_user
	 WHERE csr_user_sid = in_sid_id;

	DELETE FROM region_owner 
	 WHERE user_sid = in_sid_id;
	DELETE FROM ind_start_point 
	 WHERE user_sid = in_sid_id;
	DELETE FROM delegation_user 
	 WHERE user_sid = in_sid_id;
	DELETE FROM region_role_member 
	 WHERE user_sid = in_sid_id;
	
	DELETE FROM sheet_alert
	 WHERE user_sid = in_sid_id;
	DELETE FROM approval_step_sheet_alert
	 WHERE user_sid = in_sid_id;
	DELETE FROM delegation_terminated_alert
	 WHERE notify_user_sid = in_sid_id;
	DELETE FROM delegation_terminated_alert
	 WHERE raised_by_user_sid = in_sid_id;
	DELETE FROM user_message_alert
	 WHERE notify_user_sid = in_sid_id;
	DELETE FROM user_message_alert
	 WHERE raised_by_user_sid = in_sid_id;	
	DELETE FROM new_delegation_alert
	 WHERE notify_user_sid = in_sid_id;
	DELETE FROM new_delegation_alert
	 WHERE raised_by_user_sid = in_sid_id;
	DELETE FROM delegation_change_alert
	 WHERE notify_user_sid = in_sid_id;
	DELETE FROM delegation_change_alert
	 WHERE raised_by_user_sid = in_sid_id;

	DELETE FROM issue_user 
	 WHERE user_sid = in_sid_id;
	DELETE FROM tab_user 
	 WHERE user_sid = in_sid_id;
	
	DELETE FROM alert_batch_run 
	 WHERE csr_user_sid = in_sid_id;
	DELETE FROM autocreate_user 
	 WHERE created_user_sid = in_sid_id;
	
	DELETE FROM job 
	 WHERE requested_by_user_sid = in_sid_id;
	UPDATE trash 
	   SET trashed_by_sid = NULL 
	 WHERE trashed_by_sid = in_sid_id;
	DELETE FROM form_allocation_user 
	 WHERE user_sid = in_sid_id;
	DELETE FROM superadmin 
	 WHERE csr_user_sid = in_sid_id;
	DELETE FROM tab_portlet_user_state 
     WHERE csr_user_sid = in_sid_id;
	DELETE FROM csr_user 
	 WHERE csr_user_sid = in_sid_id;

END DeleteObject;


PROCEDURE MoveObject(
	in_act security_pkg.T_ACT_ID,
	in_sid_id security_pkg.T_SID_ID,
	in_new_parent_sid_id security_pkg.T_SID_ID)
IS
BEGIN
	NULL;
END MoveObject;


-- User callbacks
PROCEDURE LogOff(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	-- write to audit log
	SELECT app_sid 
	  INTO v_app_sid
	  FROM csr_user
	 WHERE csr_user_sid = in_sid_id;
	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_LOGOFF, v_app_sid, in_sid_id, 'Logged off');
END;


PROCEDURE LogOn(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_act_timeout			IN security_pkg.T_ACT_TIMEOUT,
	in_logon_type			IN security_pkg.T_LOGON_TYPE
)
AS
	v_app_sid	security_pkg.T_SID_ID;
	v_superadmin NUMBER;
BEGIN
	-- write to audit log
	SELECT app_sid 
	  INTO v_app_sid
	  FROM csr_user
	 WHERE csr_user_sid = in_sid_id;
	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_LOGON, v_app_sid, in_sid_id, 'Logged on');
	
	-- check if user is superadmin
	SELECT COUNT(*)
	INTO v_superadmin
	FROM superadmin
	WHERE csr_user_sid = in_sid_id;
	IF v_superadmin=1 THEN
		security_pkg.SetContext('IS_SUPERADMIN', 1);
	END IF;
END;



PROCEDURE LogonFailed(
	in_sid_id				IN security_pkg.T_SID_ID,
	in_error_code			IN NUMBER,
	in_message			    IN VARCHAR2
)
AS
    PRAGMA AUTONOMOUS_TRANSACTION;  -- have to do this as we're certain to get rolled back with RAISE_APPLICATION_ERROR later
 	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	-- write to audit log
	BEGIN
        SELECT app_sid 
          INTO v_app_sid
          FROM csr_user
         WHERE csr_user_sid = in_sid_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN; -- ignore
    END;
	csr_data_pkg.WriteAuditLogEntryForSid(in_sid_id, csr_data_pkg.AUDIT_TYPE_LOGON_FAILED, v_app_sid, in_sid_id, in_message);
    COMMIT;
END;


PROCEDURE GetAccountPolicy(
	in_sid_id				IN	security_pkg.T_SID_ID,
	out_policy_sid			OUT security_pkg.T_SID_ID
)
AS
BEGIN
	SELECT MIN(val)
	  INTO out_policy_sid
	  FROM transaction_context
	 WHERE key = 'account_policy_sid';
	IF out_policy_sid IS NULL THEN
		SELECT MIN(account_policy_sid)
		  INTO out_policy_sid
		  FROM customer c, csr_user cu
		 WHERE cu.app_sid = c.app_sid AND cu.csr_user_sid = in_sid_id AND cu.hidden = 0;
	END IF;
END;


PROCEDURE CheckRegisteredUser
IS
	v_act_id	security_pkg.T_ACT_ID;
BEGIN
	v_act_id := security_pkg.GetACT();
	IF user_pkg.IsUserInGroup(
		v_act_id, 
		securableobject_pkg.GetSIDFromPath(v_act_id, security_pkg.GetApp(), 'Groups/RegisteredUsers')) = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 
			'Access denied due to lack of membership in Groups/RegisteredUsers '||
			'for the application with sid '||security_pkg.GetApp()||
			' using the act '||v_act_id);
	END IF;
END;

PROCEDURE CreateUserForApproval(
  	in_user_name		IN	CSR_USER.user_NAME%TYPE,
	in_password 		IN	VARCHAR2, -- nullable
   	in_full_name		IN	CSR_USER.full_NAME%TYPE,
	in_email		 	IN	CSR_USER.email%TYPE,
	out_sid_id			OUT	security_pkg.T_SID_ID,
	out_guid			OUT	security_pkg.T_ACT_ID
)
AS
	v_uid_act 	security_pkg.T_ACT_ID;
	v_old_act	security_pkg.T_ACT_ID;
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Create users for approval') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permissions on the "Create users for approval" capability');
	END IF;
	
	-- do this as the user creator daemon
	v_uid_act := LogonUserCreatorDaemon;
	
	-- umm mailbox stuff needs things in Oracle session
	v_old_act := SYS_CONTEXT('SECURITY','ACT');
	security_pkg.SetContext('ACT', v_uid_act);
	
	BEGIN
		createUser(v_uid_act, security_pkg.getapp, in_user_name, in_password, in_full_name, null, 
			in_email, null, null, 
			null, -- region mount point
			null, -- info_xml
			1, -- send alerts (hmmm)
			out_sid_id);
		
		-- restore context ASAP
		security_pkg.SetContext('ACT', v_old_act);

		deactivateUser(v_uid_act, out_sid_id);				
		-- Add an entry into the autocreate_user table, we'll 
		-- use this guid to validate the user's e-mail account
		out_guid := user_pkg.generateACT;
		AddAutoAccount(in_user_name, out_guid, out_sid_id);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			-- restore context
			security_pkg.SetContext('ACT', v_old_act);
			out_sid_id := securableobject_pkg.getSidFromPath(v_uid_act, security_pkg.getApp, 'users/'||in_user_name);
			-- check if they're in the auto approve magic table
			-- first of all we might have rejected them before, so give them another chance
			UPDATE autocreate_user
			   SET rejected_dtm = null
			 WHERE created_user_sid = out_sid_id;
			 
			BEGIN
				SELECT guid
				  INTO out_guid
				  FROM autocreate_user
				 WHERE created_user_sid = out_sid_id
				   AND approved_dtm IS NULL;
			EXCEPTION	
				WHEN NO_DATA_FOUND THEN
					RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'An active user already exists with this user name');
			END;			
		WHEN OTHERS THEN
			-- restore context
			security_pkg.SetContext('ACT', v_old_act);
			RAISE;
	END;
	
	
END;

PROCEDURE CreateUser(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
   	in_user_name					IN	CSR_USER.user_NAME%TYPE,
	in_password 					IN	VARCHAR2,
   	in_full_name					IN	CSR_USER.full_NAME%TYPE,
   	in_friendly_name				IN	CSR_USER.friendly_NAME%TYPE,
	in_email		 				IN	CSR_USER.email%TYPE,
	in_job_title					IN  CSR_USER.job_title%TYPE,
	in_phone_number					IN  CSR_USER.phone_number%TYPE,
	in_region_mount_point_sid	 	IN 	security_pkg.T_SID_ID,
	in_info_xml						IN  csr_user.info_xml%TYPE,
	in_send_alerts					IN	csr_user.send_alerts%TYPE,
	out_user_sid 					OUT security_pkg.T_SID_ID
)
AS
BEGIN
	INTERNAL_CreateUser(in_act, in_app_sid, in_user_name, in_password, in_full_name, in_friendly_name, in_email,
		in_job_title, in_phone_number, in_region_mount_point_sid, in_info_xml, in_send_alerts, out_user_sid);
	-- now call supplier hooks. We do it this way round because we still want top-co users to be managed
	-- with the normal CR360 user functionality, i.e. default behaviour for creating users is that they're
	-- top co users.
	-- XXX: ugh -- chain dependency. CSR won't compile without chain now
	supplier_pkg.TopCompanyUserCreated(out_user_sid);
END;

PROCEDURE INTERNAL_CreateUser(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
   	in_user_name					IN	CSR_USER.user_NAME%TYPE,
	in_password 					IN	VARCHAR2,
   	in_full_name					IN	CSR_USER.full_NAME%TYPE,
   	in_friendly_name				IN	CSR_USER.friendly_NAME%TYPE,
	in_email		 				IN	CSR_USER.email%TYPE,
	in_job_title					IN  CSR_USER.job_title%TYPE,
	in_phone_number					IN  CSR_USER.phone_number%TYPE,
	in_region_mount_point_sid	 	IN 	security_pkg.T_SID_ID,
	in_info_xml						IN  csr_user.info_xml%TYPE,
	in_send_alerts					IN	csr_user.send_alerts%TYPE,
	out_user_sid 					OUT security_pkg.T_SID_ID
)
AS
    v_user_sid 				security_pkg.T_SID_ID;
    v_group_sid 			security_pkg.T_SID_ID;
    v_user_guid				security_pkg.T_ACT_ID;
    v_start_points			security_pkg.T_SID_IDS;
    v_user_mailbox_sid		security_pkg.T_SID_ID;
    v_users_mailbox_sid		security_pkg.T_SID_ID;
BEGIN	
	INSERT INTO transaction_context (key, val)
		SELECT 'account_policy_sid', account_policy_sid
		  FROM customer
		 WHERE app_sid = in_app_sid;
	
	user_pkg.CreateUser(in_act, securableobject_pkg.GetSIDFromPath(in_act, in_app_sid, 'Users'),
		LOWER(in_user_name), NVL(in_password, user_pkg.GenerateACT), class_pkg.GetClassID('CSRUser'), v_user_sid);
	v_group_sid := securableobject_pkg.GetSIDFromPath(in_act, in_app_sid, 'Groups/RegisteredUsers');
	-- add user to group
	security.Group_Pkg.addMember(in_act, v_user_sid, v_group_sid);
	
	v_user_guid := user_pkg.GenerateACT;
	
	INSERT INTO CSR_USER 
		(app_sid, csr_user_sid, user_name, full_NAME, 
		friendly_name, 
		email, 
		job_title, phone_number, 
		region_mount_point_sid, 
		info_xml, 
		guid)
	VALUES (
		in_app_sid, v_user_sid, LOWER(in_user_name), in_full_name, 
		NVL(in_friendly_name, REGEXP_SUBSTR(in_full_name,'[^ ]+', 1, 1)), 
		TRIM(in_email), -- just in case
		in_job_title, in_phone_number,
		in_region_mount_point_sid, 
		in_info_xml, 
		v_user_guid);
	out_user_sid := v_user_sid;

	-- create a mailbox
	v_users_mailbox_sid := alert_pkg.GetSystemMailbox('Users');
	mail.mail_pkg.createMailbox(v_users_mailbox_sid, v_user_sid, v_user_mailbox_sid);
	acl_pkg.AddACE(in_act, acl_pkg.GetDACLIDForSID(v_user_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_group_sid, security_pkg.PERMISSION_ADD_CONTENTS);
	acl_pkg.AddACE(in_act, acl_pkg.GetDACLIDForSID(v_user_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_user_sid, security_pkg.PERMISSION_STANDARD_ALL);
	
	-- add to group...
	IF in_region_mount_point_sid IS NOT NULL THEN
		group_pkg.AddMember(in_act, v_user_sid, in_region_mount_point_sid);
	END IF;
		
	csr_data_pkg.WriteAuditLogEntry(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, in_app_sid, out_user_sid, 'User created');

    -- make sure they have some kind of ind start point
	SetIndStartPoints(v_user_sid, v_start_points);
END;

PROCEDURE createSuperAdmin(
	in_act			 				IN	security_pkg.T_ACT_ID,
   	in_user_name					IN	CSR_USER.user_NAME%TYPE,
	in_password 					IN	VARCHAR2,
   	in_full_name					IN	CSR_USER.full_NAME%TYPE,
   	in_friendly_name				IN	CSR_USER.friendly_NAME%TYPE,
	in_email		 				IN	CSR_USER.email%TYPE,
	out_user_sid 					OUT security_pkg.T_SID_ID
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_csr_sid				security_pkg.T_SID_ID;
	v_group_sid				security_pkg.T_SID_ID;
	v_registered_users_sid	security_pkg.T_SID_ID;
    v_user_guid				security_pkg.T_ACT_ID;
    v_user_mailbox_sid		security_pkg.T_SID_ID;
    v_users_mailbox_sid		security_pkg.T_SID_ID;
    v_stored_app_sid		security_pkg.T_SID_ID;
    v_stored_act			security_pkg.T_ACT_ID;
    v_builtin_admin_act		security_pkg.T_ACT_ID;
    v_dacl_id				security_pkg.T_ACL_ID;
BEGIN
	-- we fiddle with this, so just keep track of it for now
	v_stored_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	v_stored_act := SYS_CONTEXT('SECURITY', 'ACT');
	
	-- clear this down -- superadmmin stuff doesn't want
	-- to be constrainted by RLS
	security_pkg.SetApp(NULL);

	-- clear out policy too for superadmins
	DELETE FROM transaction_context
	 WHERE key = 'account_policy_sid';
	
	v_csr_sid := securableobject_pkg.GetSIDFromPath(in_act,0,'csr');
	user_pkg.CreateUser(in_act, securableobject_pkg.GetSIDFromPath(in_act, 0, 'csr/Users'),
		LOWER(in_user_name), in_password, class_pkg.GetClassID('CSRUser'), v_user_sid);
	     
	v_group_sid := securableobject_pkg.GetSIDFromPath(in_act, 0, 'csr/SuperAdmins');
	-- add user to group
	security.Group_Pkg.addMember(in_act, v_user_sid, v_group_sid);
	v_user_guid := user_pkg.GenerateACT;

	-- save into the superadmins table
	INSERT INTO superadmin (csr_user_sid, user_name, full_name, friendly_name, email, guid)
	VALUES (v_user_sid, LOWER(in_user_name), in_full_name, in_friendly_name, in_email, v_user_guid);

	-- superadmins belong to all applications
	INSERT INTO csr_user (app_sid, csr_user_sid, user_name, full_name, friendly_name, email, region_mount_point_sid, guid, hidden)
		SELECT c.app_sid, v_user_sid, LOWER(in_user_name), in_full_name, in_friendly_name, in_email, NULL, v_user_guid, 1
		  FROM customer c;

	-- superadmins therefore have to have mailboxes in all applications
	-- We'll login as builtin/administrator for this bit...
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 100000, v_builtin_admin_act);
	security_pkg.SetACT(v_builtin_admin_act);
	FOR r IN (
		SELECT app_sid FROM customer
	) 
	LOOP
		security_pkg.SetApp(r.app_sid);
		v_registered_users_sid := securableobject_pkg.GetSIDFromPath(v_builtin_admin_act, r.app_sid, 'Groups/RegisteredUsers');
		BEGIN
			v_users_mailbox_sid := alert_pkg.GetSystemMailbox('Users');
			-- ought not be null
			IF v_users_mailbox_sid IS NULL THEN
				RAISE_APPLICATION_ERROR(-20001, 'The application with sid '||r.app_sid||' does not have a Users mailbox');
			END IF;
		EXCEPTION
			WHEN mail.mail_pkg.MAILBOX_NOT_FOUND OR mail.mail_pkg.PATH_NOT_FOUND THEN
				RAISE_APPLICATION_ERROR(-20001, 'The application with sid '||r.app_sid||' does not have a Users mailbox');
		END;
		mail.mail_pkg.createMailbox(v_users_mailbox_sid, v_user_sid, v_user_mailbox_sid);
		v_dacl_id := acl_pkg.GetDACLIDForSID(v_user_mailbox_sid);
		IF v_dacl_id IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'The user mailbox with sid '||v_user_mailbox_sid||' and parent '||v_users_mailbox_sid||' does not have a dacl id');
		END IF;
		acl_pkg.AddACE(v_builtin_admin_act, v_dacl_id, security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, v_registered_users_sid, security_pkg.PERMISSION_ADD_CONTENTS);
		acl_pkg.AddACE(v_builtin_admin_act, v_dacl_id, security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, v_user_sid, security_pkg.PERMISSION_STANDARD_ALL);
	END LOOP;
	security_pkg.SetApp(NULL);
	
    -- backfill startpoints
    INSERT INTO ind_start_point (app_sid, user_sid, ind_sid)
        SELECT app_sid, v_user_sid, ind_root_sid
          FROM customer;

	security_pkg.SetACT(v_stored_act, v_stored_app_sid);

	out_user_sid := v_user_sid;		
END;

FUNCTION IsSuperAdmin
RETURN NUMBER
AS
	v_cnt	NUMBER;
BEGIN
	SELECT DECODE(COUNT(*), 0, 0, 1)
	  INTO v_cnt
	  FROM superadmin
	 WHERE csr_user_sid = SYS_CONTEXT('SECURITY','SID');
	RETURN v_cnt;
END;

/**
 * Set some basic details (called by userSettings). We deliberately don't let them set the
 * username since the user shouldn't fiddle with their own name (from a security perspective).
 *
 * @param in_act						Access token
 * @param in_user_sid					User Sid
 * @param in_full_name					Their real Name (e.g. 'Fred Bloggs')	
 * @param in_email						Email address
 */
PROCEDURE setBasicDetails(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_user_sid		 				IN	security_pkg.T_SID_ID,
   	in_full_name					IN	CSR_USER.full_NAME%TYPE,
   	in_friendly_name				IN	CSR_USER.friendly_NAME%TYPE,
	in_email		 				IN	CSR_USER.email%TYPE,
	in_info_xml                     IN  CSR_USER.info_xml%TYPE
)
AS
BEGIN
	-- this will barf if it fails or if act has wrong permissions on user
	UPDATE CSR_USER SET
		full_NAME = in_full_name,
		friendly_name = in_friendly_name,
		email = TRIM(in_email), -- just in case
		info_xml = in_info_xml
	 WHERE csr_user_sid = in_user_sid;
END;


PROCEDURE SetExtraInfoValue(
	in_act		IN	security_pkg.T_ACT_ID,
	in_user_sid	IN	security_pkg.T_SID_ID,
	in_key		IN	VARCHAR2,		
	in_value	IN	VARCHAR2
)
AS
	v_path 			VARCHAR2(255) := '/fields/field[@name="'||in_key||'"]';
	v_new_node 		VARCHAR2(1024) := '<field name="'||in_key||'">'||htf.escape_sc(in_value)||'</field>';
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act, in_user_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing user information');
	END IF;
	
	UPDATE CSR_USER
	   SET INFO_XML = 
			CASE
				WHEN info_xml IS NULL THEN
					APPENDCHILDXML(XMLType('<fields/>'), '/fields',  XmlType(v_new_node))
		    	WHEN EXISTSNODE(info_xml, v_path||'/text()') = 1 THEN
		    		UPDATEXML(info_xml, v_path||'/text()', htf.escape_sc(in_value))
		    	WHEN EXISTSNODE(info_xml, v_path) = 1 THEN
		    		UPDATEXML(info_xml, v_path, XmlType(v_new_node))
		    	ELSE
		    		APPENDCHILDXML(info_xml, '/fields', XmlType(v_new_node))
			END
	WHERE csr_user_sid = in_user_sid
	RETURNING app_sid INTO v_app_sid;
	
	csr_data_pkg.WriteAuditLogEntry(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, v_app_sid, in_user_sid, 'Set {0} to {1}', in_key, in_value);
END;

PROCEDURE amendUser(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_user_sid		 				IN	security_pkg.T_SID_ID,
   	in_user_name					IN	CSR_USER.user_NAME%TYPE,
   	in_full_name					IN	CSR_USER.full_NAME%TYPE,
   	in_friendly_name				IN	CSR_USER.friendly_NAME%TYPE,
	in_email		 				IN	CSR_USER.email%TYPE,
	in_job_title					IN  CSR_USER.job_title%TYPE,
	in_phone_number					IN  CSR_USER.phone_number%TYPE,
	in_region_mount_point_sid	 	IN 	security_pkg.T_SID_ID,
	in_active						IN  security_pkg.T_USER_ACCOUNT_ENABLED,
	in_info_xml						IN  csr_user.info_xml%TYPE,
	in_send_alerts					IN	csr_user.send_alerts%TYPE
)
AS		  
	CURSOR c IS 
		SELECT cu.app_sid, cu.user_name, cu.full_name, cu.email, cu.job_title, cu.phone_number, cu.friendly_name, 
			   cu.region_mount_point_sid, cu.info_xml, c.user_info_xml_fields, cu.send_alerts
		  FROM csr_user cu, customer c
		 WHERE cu.csr_user_sid = in_user_sid
		   AND cu.app_sid = c.app_sid;
	r c%ROWTYPE;
	v_active	Security_pkg.T_USER_ACCOUNT_ENABLED;
	v_current_so_name   security_pkg.T_SID_ID;
BEGIN
	-- this will barf if it fails or if act has wrong permissions on user
	-- if they're in the trash then don't try and rename
	IF securableobject_pkg.GetName(in_act, in_user_sid) is not null and trash_pkg.IsInTrash(in_act, in_user_sid) = 0 THEN
		securableobject_pkg.renameSo(in_act, in_user_sid, LOWER(in_user_name));
	END IF;
	
	-- read some bits about the old user
	OPEN c;
	FETCH c INTO r;
	IF c%NOTFOUND THEN
		CLOSE c;
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The user with sid '||in_user_sid||'  was not found');
	END IF;
	CLOSE c;
		
	-- if region mount point sid changed...
	IF NVL(in_region_mount_point_sid,-1) != NVL(r.region_mount_point_sid,-1) THEN
		IF r.region_mount_point_sid IS NOT NULL THEN
			group_pkg.DeleteMember(in_act, in_user_sid, r.region_mount_point_sid);
		END IF;
		IF in_region_mount_point_sid IS NOT NULL THEN
			group_pkg.AddMember(in_act, in_user_sid, in_region_mount_point_sid);
		END IF;
	END IF; 	
	
	UPDATE csr_user 
	   SET user_name = LOWER(in_user_name),
		   full_name = in_full_name,
		   friendly_name =  NVL(in_friendly_name, REGEXP_SUBSTR(in_FULL_NAME,'[^ ]+', 1, 1)),
		   email = TRIM(in_email), -- just in case
		   job_title = in_job_title,
		   phone_number = in_phone_number,
		   region_mount_point_sid = in_region_mount_point_sid, 
		   info_xml = in_info_xml,
		   send_alerts = in_send_alerts
	 WHERE csr_user_sid = in_user_sid;
	
	-- audit changes
	csr_data_pkg.AuditValueChange(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, r.app_sid, 
		in_user_sid, 'User name', r.user_name, in_user_name);
	csr_data_pkg.AuditValueChange(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, r.app_sid, 
		in_user_sid, 'Full name', r.full_name, in_full_name);
	csr_data_pkg.AuditValueChange(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, r.app_sid, 
		in_user_sid, 'Email', r.email, in_email);
	csr_data_pkg.AuditValueChange(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, r.app_sid, 
		in_user_sid, 'Job title', r.job_title, in_job_title);
	csr_data_pkg.AuditValueChange(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, r.app_sid, 
		in_user_sid, 'Phone number', r.phone_number, in_phone_number);
	csr_data_pkg.AuditValueChange(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, r.app_sid, 
		in_user_sid, 'Friendly name', r.friendly_name, in_friendly_name);
	csr_data_pkg.AuditValueChange(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, r.app_sid, 
		in_user_sid, 'Region mount point', 
		region_pkg.INTERNAL_GetRegionPathString(r.region_mount_point_sid), 
		region_pkg.INTERNAL_GetRegionPathString(in_region_mount_point_sid));
	-- info xml
	csr_data_pkg.AuditInfoXmlChanges(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, r.app_sid, 
		in_user_sid, r.user_info_xml_fields, r.info_xml, in_info_xml);
	csr_data_pkg.AuditValueChange(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, r.app_sid, 
		in_user_sid, 'Send alerts', r.send_alerts, in_send_alerts);
		
	-- Change the active flag (if it isn't null)
	IF in_active = 1 THEN
		activateUser(in_act, in_user_sid);
	ELSIF in_active = 0 THEN
		deactivateUser(in_act, in_user_sid);
	END IF;
END amendUser;
 
PROCEDURE SetIndStartPoints(
    in_user_sid                 IN  security_pkg.T_SID_ID,
    in_ind_sids		    	    IN	security_pkg.T_SID_IDS
)
AS
    t_ind_sids 		security.T_SID_TABLE;
    v_act       	security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
    v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
    v_ind_root_sid	security_pkg.T_SID_ID;
    v_cnt			NUMBER;
BEGIN
    t_ind_sids := security_pkg.SidArrayToTable(in_ind_sids);
    -- delete old
    FOR r in (
        SELECT isp.user_sid, isp.ind_sid 
          FROM ind_start_point isp, ind i
         WHERE isp.user_sid = in_user_sid 
           AND isp.ind_sid = i.ind_sid 
           AND isp.app_sid = i.app_sid 
           AND i.app_sid = v_app_sid
           ANd isp.app_sid = v_app_sid
         MINUS
        SELECT in_user_sid, COLUMN_VALUE ind_sid FROM TABLE(t_ind_sids)
    )
    LOOP
        DELETE FROM ind_start_point WHERE user_sid = in_user_sid and ind_sid = r.ind_sid;
        group_pkg.DeleteMember(v_act, in_user_sid, r.ind_sid);
        csr_data_pkg.WriteAuditLogEntry(v_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, v_app_sid, in_user_sid, 
            'Removed start point "{0}"', 
            indicator_pkg.INTERNAL_GetIndPathString(r.ind_sid));
    END LOOP;
    
    -- insert new
    FOR r IN (
        SELECT in_user_sid, COLUMN_VALUE ind_sid FROM TABLE(t_ind_sids)
         MINUS
        SELECT isp.user_sid, isp.ind_sid 
          FROM ind_start_point isp, ind i
         WHERE isp.user_sid = in_user_sid 
           AND isp.ind_sid = i.ind_sid
           AND isp.app_sid = i.app_sid 
           AND i.app_sid = v_app_sid
           ANd isp.app_sid = v_app_sid
    )
    LOOP
        INSERT INTO ind_start_point (user_sid, ind_sid) VALUES (in_user_sid, r.ind_sid);
        group_pkg.AddMember(v_act, in_user_sid, r.ind_sid);
        csr_data_pkg.WriteAuditLogEntry(v_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, v_app_sid, in_user_sid, 
            'Added start point "{0}"', 
            indicator_pkg.INTERNAL_GetIndPathString(r.ind_sid));
    END LOOP;
    
    -- lock the user row so the count is accurate
    SELECT 1
      INTO v_cnt
      FROM csr_user
     WHERE app_sid = v_app_sid AND csr_user_sid = in_user_sid FOR UPDATE;
     	   
    SELECT COUNT(*)
      INTO v_cnt
      FROM ind_start_point
     WHERE app_sid = v_app_sid AND user_sid = in_user_sid;
     
	-- poke the root sid in as we must always have an ind start point
	IF v_cnt = 0 THEN
		SELECT ind_root_sid
		  INTO v_ind_root_sid
		  FROM customer
		 WHERE app_sid = v_app_sid;
		 
        INSERT INTO ind_start_point (app_sid, user_sid, ind_sid)
        VALUES (v_app_sid, in_user_sid, v_ind_root_sid);
        	   
        group_pkg.AddMember(v_act, in_user_sid, v_ind_root_sid);
        csr_data_pkg.WriteAuditLogEntry(v_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, v_app_sid, in_user_sid, 
            'Added start point "{0}"', 
            indicator_pkg.INTERNAL_GetIndPathString(v_ind_root_sid));
	END IF;
END;


/**
 * Activates a user's account
 *
 * @param in_act						Access token
 * @param in_user_sid					User Sid
 */
PROCEDURE activateUser(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_user_sid		 				IN	security_pkg.T_SID_ID
)
AS
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	-- Check the old active flag and only do this once to prevent excess audit log entries
	IF User_pkg.GetAccountEnabled(in_act, in_user_sid) = 1 THEN
		RETURN;
	END IF;
	
	SELECT app_sid 
	  INTO v_app_sid
	  FROM csr_user
	 WHERE csr_user_sid = in_user_sid;

	UPDATE chain.chain_user
	   SET deleted = 0
	 WHERE user_sid = in_user_sid;

	User_pkg.EnableAccount(in_act, in_user_sid);
	csr_data_pkg.WriteAuditLogEntry(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, v_app_sid, in_user_sid, 'Activated');
END;

/**
 * Deactivates a user's account
 *
 * @param in_act						Access token
 * @param in_user_sid					User Sid
 */
PROCEDURE deactivateUser(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_user_sid		 				IN	security_pkg.T_SID_ID
)
AS		  
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	-- Check the old active flag and only do this once to prevent excess audit log entries
	IF User_pkg.GetAccountEnabled(in_act, in_user_sid) = 0 THEN
		RETURN;
	END IF;
	
	SELECT app_sid 
	  INTO v_app_sid
	  FROM csr_user
	 WHERE csr_user_sid = in_user_sid;
	 
	user_pkg.DisableAccount(in_act, in_user_sid);
	csr_data_pkg.WriteAuditLogEntry(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, v_app_sid, in_user_sid, 'Deactivated');
END;

/**
 * Deletes (deactivates and puts in trash) user's account
 *
 * @param in_act						Access token
 * @param in_user_sid					User Sid
 */
PROCEDURE DeleteUser(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_user_sid		 				IN	security_pkg.T_SID_ID
)
AS		  
	v_app_sid		security_pkg.T_SID_ID;
	v_user_name		csr_user.user_name%TYPE;
BEGIN

	SELECT app_sid, user_name
	  INTO v_app_sid, v_user_name
	  FROM csr_user
	 WHERE csr_user_sid = in_user_sid;

	csr_user_pkg.deactivateUser(in_act, in_user_sid);
	
	-- don't continue if already in trash prevent excess audit log entries
	IF trash_pkg.IsInTrash(in_act, in_user_sid) = 1 THEN
		RETURN;
	END IF;

	trash_pkg.TrashObject(in_act, in_user_sid, 
		securableobject_pkg.GetSIDFromPath(in_act, v_app_sid, 'Trash'), v_user_name);

	-- make sure we turn off their alerts too
	UPDATE csr_user
	   SET send_alerts = 0
	 WHERE csr_user_sid = in_user_sid;
	
	UPDATE chain.chain_user
	   SET deleted = 1
	 WHERE user_sid = in_user_sid;

	csr_data_pkg.WriteAuditLogEntry(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, v_app_sid, in_user_sid, 'Deleted');
END;

PROCEDURE AddAutoCreateUser(
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_user_name			IN	autocreate_user.user_name%TYPE,
	out_guid 				OUT Security_Pkg.T_ACT_ID
)
AS
BEGIN
	-- we send back a GUID so that the client's intranet server can get their
	-- client to forward the GUID to us and we know it's really them
	out_guid := user_pkg.GenerateACT;
	
	BEGIN
		INSERT INTO autocreate_user 
			(app_sid, user_name, guid, requested_dtm) 
		VALUES
			(in_app_sid, LOWER(in_user_name), TRIM(out_guid), SYSDATE);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- just update the requested date, keep the GUID just in case they request 
			-- twice in quick succession or something
			UPDATE autocreate_user
			   SET requested_dtm = SYSDATE
			 WHERE app_sid = in_app_sid
		       AND user_name = LOWER(in_user_name)
		  RETURNING guid INTO out_guid;
	END;
END AddAutoCreateUser;

PROCEDURE GetAutoCreateUser(
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_guid					IN	autocreate_user.guid%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT created_user_sid, user_name 
		  FROM autocreate_user
		 WHERE guid = in_guid
           AND app_sid = in_app_sid;
END;

PROCEDURE GetAutoCreateUserBySid(
	in_user_sid				IN	autocreate_user.created_user_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- TODO: there is no security here, moved from the web page
	OPEN out_cur FOR
		SELECT guid
		  FROM autocreate_user
		 WHERE created_user_sid = in_user_sid;
	
END;

PROCEDURE GetUser(
	in_act 							IN	security_pkg.T_ACT_ID,
	in_user_sid 					IN  security_pkg.T_SID_ID,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN 
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act, in_user_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading information for the user with sid '||in_user_sid);
	END IF;
	GetUser_INSECURE(in_user_sid, out_cur);
END;

PROCEDURE GetUser_INSECURE(
	in_user_sid 					IN  security_pkg.T_SID_ID,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
        -- TODO: remove last_logon_dtm_fmt??
		SELECT cu.csr_user_sid, cu.user_name, cu.full_name, cu.friendly_name, cu.email, ut.last_logon last_logon_dtm, cu.region_mount_point_sid,
			   TO_CHAR(ut.last_but_one_logon, 'Dy, dd Mon yyyy hh24:mi')||' GMT' last_logon_dtm_fmt,
			   cu.app_sid, ut.account_enabled active, extract(cu.info_xml,'/').getClobVal() info_xml, ut.last_but_one_logon, ut.expiration_dtm,
			   cu.send_alerts, cu.job_title, cu.email,
			   (SELECT region_sid 
			      FROM (
					SELECT region_sid, rownum rn FROM region_owner WHERE user_sid = in_user_sid
				  ) 
				 WHERE rn = 1
				) default_region_sid -- TODO: alter UI to set this in a column (and drop region_owner table in favour of roles...)
		  FROM csr_user cu, security.user_table ut
		 WHERE cu.csr_user_sid = in_user_sid AND cu.csr_user_sid = ut.sid_id AND ut.sid_id = in_user_sid;
END;

-- gets list of things that the user is involved with (and that they might want to know about before deleting them!)
PROCEDURE GetDependencies(
	in_act 				IN security_pkg.T_ACT_ID,
	in_user_sid 		IN  security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act, in_user_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading user information');
	END IF;

	OPEN out_cur FOR
		SELECT 'Delegation form' type, name || ' (' ||val_pkg.FormatPeriod(d.start_dtm, d.end_dtm, d.interval) ||')' label,
			'/csr/site/delegation/editDeleg.acds?delegationSid='||d.delegation_sid url
		  FROM delegation_user du, delegation d
		 WHERE du.delegation_sid = d.delegation_sid
		   AND user_sid = in_user_sid;   
END;


PROCEDURE GetUserAndStartPoints(
	in_act 				IN security_pkg.T_ACT_ID,
	in_user_sid 		IN  security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR,
	out_isp_cur         OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN 
    GetUser(in_act, in_user_sid, out_cur);
    OPEN out_isp_cur FOR
        SELECT isp.ind_sid, i.description
          FROM ind_start_point isp, ind i
         WHERE user_sid = in_user_sid
           AND isp.ind_sid = i.ind_sid
           AND i.app_sid = SYS_CONTEXT('SECURITY','APP');
END;

/**
 * Gets list of all users in the users container for a give application sid
 * Active and non-active.
 *
 * @param in_act				Access token.
 * @param in_app_sid		The application sid (saves additional db lookup from most code)
 * @order by            Order results (optional) NOT WORKING! LEFT FOR BACKWARD COMPATIBILITY
 ** 
 * The output rowset is of the form:
 * csr_user_sid, active, user_name, full_name, friendly_name, email, last_logon_dtm, last_logon_formatted, region_mount_point, region_mount_point
 */
PROCEDURE GetAllUsers(
	in_act_id       				IN  security_pkg.T_ACT_ID,
	in_app_sid    					IN  security_pkg.T_SID_ID,
	in_order_by   					IN	VARCHAR2, -- not used
	out_users     					OUT SYS_REFCURSOR,
	out_groups						OUT SYS_REFCURSOR,
	out_regions						OUT SYS_REFCURSOR,
	out_roles						OUT SYS_REFCURSOR,
	out_indicator_mount_points		OUT SYS_REFCURSOR
)
IS	   
	v_order_by	VARCHAR2(1000);
	v_users_sid	security_pkg.T_SID_ID;
BEGIN				   		
	v_users_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Users');

	-- don't think it's in use anywhere
	-- c:\cvs\csr\web\site\users\userExport.aspx.cs sends null always
	-- not aware of any other method that uses this SP

	OPEN out_users FOR
    	SELECT /*+ALL_ROWS*/ cu.csr_user_sid, cu.active, cu.user_name, cu.full_name, cu.friendly_name, cu.email, 
    		   cu.last_logon last_logon_dtm, r.description region_mount_point, cu.expiration_dtm, cu.language, cu.culture, cu.timezone
-- hmm, don't know how to deal with secondary structure so commented for now, instead display raw name (without path)
/*    	(
			 SELECT SYS_CONNECT_BY_PATH(description, ' > ') 
				 FROM region
				WHERE region_sid = cu.region_mount_point_sid
				 START WITH parent_sid = in_app_sid
			CONNECT BY PRIOR  region_sid  = parent_sid 
			) REGION_MOUNT_POINT, 
			(       
			 SELECT SYS_CONNECT_BY_PATH(name, ' > ')
				 FROM ind
				WHERE ind_sid = cu.indicator_mount_point_sid
				 START WITH parent_sid = in_app_sid
			CONNECT BY PRIOR ind_sid = parent_sid
			) INDICATOR_MOUNT_POINT */
    	  FROM v$csr_user cu
    	  LEFT JOIN region r ON cu.app_sid = r.app_sid AND cu.region_mount_point_sid = r.region_sid
         ORDER BY cu.user_name;
         
	OPEN out_groups FOR
		SELECT so.sid_id group_sid, so.class_id, so.name, cu.csr_user_sid
		  FROM security.securable_object so, security.group_members gm, v$csr_user cu
		 WHERE so.sid_id = gm.group_sid_id
		   AND gm.member_sid_id = cu.csr_user_sid
		   AND so.application_sid_id = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_regions FOR
		SELECT cu.csr_user_sid, r.region_sid, r.description 
		  FROM region r, region_owner ro, v$csr_user cu
		 WHERE r.region_sid = ro.region_sid
		   AND ro.user_sid = cu.csr_user_sid
		   AND r.app_sid = SYS_CONTEXT('SECURITY', 'APP');
		   
	OPEN out_roles FOR
		SELECT r.name role_name, reg.description region_description, cu.csr_user_sid
		  FROM role r, region_role_member rrm, region reg, v$csr_user cu
		 WHERE r.role_sid = rrm.role_sid
		   AND rrm.user_Sid = cu.csr_user_sid
		   AND rrm.region_sid = reg.region_sid
		   AND rrm.inherited_from_sid = rrm.region_sid -- and NOT inherited
		   AND reg.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY role_name, region_description;
	 		
	OPEN out_indicator_mount_points FOR
    	SELECT /*+ALL_ROWS*/ cu.csr_user_sid, i.ind_sid, i.description
    	  FROM v$csr_user cu, ind_start_point isp, ind i
    	 WHERE isp.app_sid = cu.app_sid AND isp.user_sid = cu.csr_user_sid 
		   AND isp.app_sid = i.app_sid AND isp.ind_sid = i.ind_sid            
         ORDER BY cu.csr_user_sid;
END;

/**
 * Gets list of all users
 *
 * @param in_act						Access token.
 * @param in_app_sid				THe CSR schema
 * 
 * The output rowset is of the form:
 * csr_user_sid, user_name, full_name, email, last_logon_dtm
 *
 * WHAT IS THE PURPOSE OF in_parent_sid
 */
-- seems to be just called by \site\forms\allocateUsers.xml
-- TODO: try to can at some point?
PROCEDURE GetAllActiveUsers(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_parent_sid 	IN  security_pkg.T_SID_ID,	 
	in_group_sid	IN 	security_pkg.T_SID_ID, 
	in_order_by 	IN VARCHAR2, 
	out_cur			OUT security_pkg.T_OUTPUT_CUR
)
IS	   
	v_order_by	VARCHAR2(1000);
BEGIN				   		
	IF in_order_by IS NOT NULL THEN
		utils_pkg.ValidateOrderBy(in_order_by, 'csr_user_sid,active,user_name,full_name,friendly_name,email,last_logon_dtm');
		v_order_by := ' ORDER BY ' || in_order_by;
	END IF;


	IF in_group_sid IS NULL OR in_group_sid=-1 THEN
		OPEN out_cur FOR
			'SELECT cu.csr_user_sid, ut.account_enabled active, cu.user_name, cu.full_name, cu.friendly_name, cu.email, ut.last_logon last_logon_dtm, TO_CHAR(ut.last_logon,''Dy dd-Mon-yyyy hh24:mi'')||'' GMT'' last_logon_formatted' 
			||' FROM CSR_USER cu,'
            ||' TABLE(security.securableobject_Pkg.GetChildrenAsTable(:act_id, :parent_sid))t, security.user_table ut '
			||' WHERE t.sid_id = cu.csr_user_sid AND t.sid_id = ut.sid_id AND ut.sid_id = cu.csr_user_sid AND ut.account_enabled = 1 AND cu.hidden = 0'||v_order_by USING in_act_id, in_parent_sid;
	ELSE						
		OPEN out_cur FOR
			'SELECT cu.csr_user_sid, ut.account_enabled active, cu.user_name, cu.full_name, cu.friendly_name, cu.email, ut.last_logon last_logon_dtm, TO_CHAR(ut.last_logon,''Dy dd-Mon-yyyy hh24:mi'')||'' GMT'' last_logon_formatted' 
			||' FROM CSR_USER cu, '
			||' TABLE(security.Group_Pkg.GetMembersAsTable(:act_id, :group_sid))g, security.user_table ut '
			||' WHERE g.sid_id = cu.csr_user_sid AND g.sid_id = ut.sid_id AND ut.sid_id = cu.csr_user_sid AND ut.account_enabled = 1 AND cu.hidden = 0'||v_order_by USING in_act_id, in_group_sid;
	END IF;	
	-- 
  
END;


/*
just called by:
site\delegation\auditTrail.xml
site\objectives\objectivePane.xml
site\schema\editIndicatorPane.xml

XXX: try to can this 
*/
PROCEDURE GetUsers(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_app_sid 		IN  security_pkg.T_SID_ID,	 
	out_cur			OUT security_pkg.T_OUTPUT_CUR
)
IS
	v_users_sid	security_pkg.T_SID_ID;
BEGIN
	-- find /users
	v_users_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Users');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_users_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
		SELECT cu.csr_user_sid, ut.account_enabled active, cu.user_name, cu.full_name, cu.email, ut.last_logon last_logon_dtm, 
			TO_CHAR(ut.last_logon,'Dy dd-Mon-yyyy hh24:mi')||' GMT' last_logon_formatted
		  FROM csr_user cu, security.user_table ut
		 WHERE app_sid = in_app_sid AND ut.sid_id = cu.csr_user_sid AND cu.hidden = 0;
END;


-- appears to be unused
-- XXX: try to can this
PROCEDURE GetUsersInGroup(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_app_sid 		IN  security_pkg.T_SID_ID,
	in_group_sid	IN 	security_pkg.T_SID_ID, 	 
	out_cur			OUT security_pkg.T_OUTPUT_CUR
)
IS
	v_users_sid	security_pkg.T_SID_ID;
BEGIN
	-- find /users
	v_users_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Users');
	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_users_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
		SELECT cu.csr_user_sid, ut.account_enabled active, cu.user_name, cu.full_name, cu.email, ut.last_logon last_logon_dtm, 
			   TO_CHAR(ut.last_logon,'Dy dd-Mon-yyyy hh24:mi')|| ' GMT' last_logon_formatted
		  FROM csr_user cu, security.user_table ut, TABLE(security.Group_Pkg.GetMembersAsTable(in_act_id, in_group_sid))g
		 WHERE app_sid = in_app_sid 
		   AND g.sid_id = cu.csr_user_sid AND g.sid_id = ut.sid_id AND cu.csr_user_sid = ut.sid_id AND cu.hidden = 0;
END;


PROCEDURE Search(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_app_sid 		IN  security_pkg.T_SID_ID,	 
	in_group_sid	IN 	security_pkg.T_SID_ID, 
	in_filter_name	IN	csr_user.full_name%TYPE,
	in_order_by 	IN	VARCHAR2, 
	out_cur			OUT security_pkg.T_OUTPUT_CUR
)
IS	   
	v_users_sid	security_pkg.T_SID_ID;
	v_order_by	VARCHAR2(1000);
	v_where		VARCHAR2(1000);
BEGIN				   		
	IF in_order_by IS NOT NULL THEN
		utils_pkg.ValidateOrderBy(in_order_by, 'csr_user_sid,active,user_name,full_name,email,last_logon_dtm');
		v_order_by := ' ORDER BY ' || in_order_by;
	END IF;

	-- find /users
	v_users_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Users');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_users_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- we always want to include the filter so we can use bind variables
	IF in_filter_name IS NULL THEN
		v_where := ' AND :in_filter_name IS NULL  AND :in_filter_name IS NULL';
	ELSE
		v_where := ' AND ( lower(full_name) LIKE ''%''||:in_filter_name||''%'' OR lower(user_name) LIKE ''%''||:in_filter_name||''%'' ) ';
	END IF;

	IF in_group_sid IS NULL OR in_group_sid=-1 THEN
		OPEN out_cur FOR
			'SELECT cu.csr_user_sid, ut.account_enabled active, cu.user_name, cu.full_name, cu.email, ut.last_logon last_logon_dtm, REPLACE(TO_CHAR(ut.last_logon,''yyyy-mm-dd hh24:mi:ss''),'' '',''T'') last_logon_formatted' 
			||' FROM csr_user cu, security.securable_object so, security.user_table ut '
			||' WHERE cu.hidden = 0 AND so.name != ''UserCreatorDaemon'' AND ut.sid_id = cu.csr_user_sid AND so.sid_id = ut.sid_id AND cu.csr_user_sid = so.sid_id AND so.parent_sid_id = :v_parent_sid AND app_sid = :in_app_sid'
				||v_where||v_order_by USING v_users_sid, in_app_sid, LOWER(in_filter_name), LOWER(in_filter_name);
	ELSE						
		OPEN out_cur FOR
			'SELECT cu.csr_user_sid, ut.account_enabled active, cu.user_name, cu.full_name, cu.email, ut.last_logon last_logon_dtm, REPLACE(TO_CHAR(ut.last_logon,''yyyy-mm-dd hh24:mi:ss''),'' '',''T'') last_logon_formatted' 
			||' FROM csr_user cu, security.securable_object so, '
			||' TABLE(security.Group_Pkg.GetMembersAsTable(:act_id, :group_sid))g, security.user_table ut '
			||' WHERE cu.hidden = 0 AND so.name != ''UserCreatorDaemon'' AND ut.sid_id = cu.csr_user_sid AND so.sid_id = ut.sid_id AND cu.csr_user_sid = so.sid_id AND so.parent_sid_id = :v_parent_sid AND g.sid_id = cu.csr_user_sid'
			||v_where||v_order_by USING in_act_id, in_group_sid, v_users_sid, LOWER(in_filter_name), LOWER(in_filter_name);
	END IF;	
	--   
END;


PROCEDURE FilterUsers(  
	in_filter			IN	VARCHAR2,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	FilterUsers(in_filter, 0, out_cur);
END;

PROCEDURE FilterUsers(  
	in_filter			IN	VARCHAR2,
	in_include_inactive	IN	NUMBER DEFAULT 0,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
)      
IS
	v_table				T_USER_FILTER_TABLE;
BEGIN
	
	FilterUsersToTable(in_filter, in_include_inactive, v_table);
	
	OPEN out_cur FOR
		SELECT cu.csr_user_sid, cu.full_name, cu.email, cu.user_name, t.account_enabled
		  FROM csr_user cu, TABLE(v_table) t
		  -- first name, or last name (space separator)
		 WHERE cu.app_sid = security_pkg.GetApp() 
		   AND cu.csr_user_sid = t.csr_user_sid
	  ORDER BY t.account_enabled DESC, 
				CASE WHEN in_filter IS NULL OR LOWER(TRIM(cu.full_name)) LIKE LOWER(in_filter) || '%' THEN 0 ELSE 1 END, -- Favour names that start with the provided filter.
			   CASE WHEN in_filter IS NULL OR LOWER(TRIM(cu.full_name)) || ' ' LIKE '% ' || LOWER(in_filter) || ' %' THEN 0 ELSE 1 END, -- Favour whole words over prefixes.
			   LOWER(TRIM(cu.full_name));
END;

PROCEDURE FilterUsersToTable (
	in_filter			IN	VARCHAR2,
	in_include_inactive	IN	NUMBER DEFAULT 0,
	out_table			OUT T_USER_FILTER_TABLE
)
AS
	v_sa_cnt 		NUMBER(10);
	v_topco_sid		security_pkg.T_SID_ID;
BEGIN
	CheckRegisteredUser();
		
	-- ok -- we exclude all non top-co users for chain stuff
	-- XXX: ugh -- chain dependency
	SELECT MIN(top_company_sid)
	  INTO v_topco_sid
	  FROM chain.customer_options
	 WHERE app_sid = security_pkg.GetApp;

	SELECT COUNT(*) 
	  INTO v_sa_cnt
	  FROM superadmin
	 WHERE csr_user_sid = SYS_CONTEXT('SECURITY','SID');

	SELECT T_USER_FILTER_ROW(cu.csr_user_sid, ut.account_enabled, CASE WHEN sa.csr_user_sid IS NOT NULL THEN 1 ELSE 0 END)
	  BULK COLLECT INTO out_table
	  FROM csr_user cu, security.user_table ut, customer c, superadmin sa
	  -- first name, or last name (space separator)
	 WHERE (LOWER(TRIM(cu.full_name)) LIKE LOWER(in_filter) || '%' OR LOWER(TRIM(cu.full_name)) LIKE '% ' || LOWER(in_filter) || '%') 
	   AND cu.app_sid = c.app_sid
	   AND ut.sid_id = cu.csr_user_sid 
	   AND cu.csr_user_sid = sa.csr_user_sid(+)
	   AND (ut.account_enabled = 1 OR in_include_inactive = 1) -- Only show active users.
	   AND (sa.csr_user_sid IS NULL OR v_sa_cnt > 0)
	   AND c.app_sid = security_pkg.GetApp() 
	   AND cu.hidden = 0  -- hidden is for excluding things like UserCreatorDaemon
	   AND (
			v_topco_sid IS NULL OR cu.csr_user_sid IN (
				SELECT user_sid FROM chain.v$company_user WHERE company_sid = v_topco_sid
			)
	   );
END;

PROCEDURE GetDACL(
	in_act_id			IN security_pkg.T_ACT_ID,
    in_sid_id			IN security_pkg.T_SID_ID,
	out_cursor			OUT security_pkg.T_OUTPUT_CUR 
)
AS 
	v_dacl_id security_pkg.T_ACL_ID;
BEGIN 
	-- Check read permissions permission first
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_sid_id, security_pkg.PERMISSION_READ_PERMISSIONS) THEN
	    RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
    v_dacl_id := security.acl_pkg.GetDACLIdForSID(in_sid_id);
	
	OPEN out_cursor FOR	
	    SELECT acl_id, acl_index, ace_type, ace_flags, a.sid_id, permission_set,
				NVL(u.full_name, so.name) name
	      FROM security.acl a, csr_user u, security.securable_object so
	     WHERE acl_id = v_dacl_id
		   AND u.csr_user_sid(+) = a.sid_id
		   AND so.sid_id = a.sid_id
	  ORDER BY acl_index;
END;


-- TODO: change to do this based on groups
PROCEDURE IsLogonAsUserAllowed(					
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_user_sid 		IN 	security_pkg.T_SID_ID,
	out_result			OUT	BINARY_INTEGER
)
IS														   
	v_result		NUMBER(10);
	v_sid_id		security_pkg.T_SID_ID;
	v_parent_sid_id	security_pkg.T_SID_ID;
	v_dacl_id		security_pkg.T_ACL_ID;
	v_class_id		security_pkg.T_CLASS_ID;
	v_name			security_pkg.T_SO_NAME;
	v_flags			security_pkg.T_SO_FLAGS;
	v_owner			security_pkg.T_SID_ID;
	v_cur			security_pkg.T_OUTPUT_CUR;
	v_cug_class_id	security_pkg.T_CLASS_ID;
	v_cr_class_id	security_pkg.T_CLASS_ID;
	v_cu_class_id	security_pkg.T_CLASS_ID;
BEGIN	
	v_cug_class_id := class_pkg.GetClassID('CSRUserGroup');	
	v_cr_class_id := class_pkg.GetClassID('CSRRole');	
	out_result := 0;
	
	-- which groups is this user in? Check each one...(also check the group object is of the right type)
	security.Group_Pkg.GetGroupsOfWhichSOIsMember(in_act_id, in_user_sid, v_cur);
	WHILE TRUE LOOP
		FETCH v_cur INTO v_sid_id, v_parent_sid_id, v_dacl_id, v_class_id, v_name, v_flags, v_owner;
		EXIT WHEN v_cur%NOTFOUND;
		IF v_class_id IN (v_cug_class_id, v_cr_class_id) AND Security_pkg.IsAccessAllowedSID(in_act_id, v_sid_id, Csr_Data_Pkg.PERMISSION_LOGON_AS_USER) THEN
			out_result := 1;
			RETURN;
		END IF;
	END LOOP;
	
	-- try the user directly
	v_cu_class_id := class_pkg.GetClassID('CSRUser');	
	securableobject_pkg.GetSO(in_act_id, in_user_sid, v_cur);
	FETCH v_cur INTO v_sid_id, v_parent_sid_id, v_dacl_id, v_class_id, v_name, v_flags, v_owner;
	IF v_class_id = v_cu_class_id AND Security_pkg.IsAccessAllowedSID(in_act_id, in_user_sid, Csr_Data_Pkg.PERMISSION_LOGON_AS_USER) THEN
		out_result := 1;
		RETURN;
	END IF;
END;

PROCEDURE LogonAsUser(					
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_sid_id			IN	security_pkg.T_SID_ID,
	out_act_id			OUT Security_Pkg.T_ACT_ID
)
AS	
	v_app_sid		security_pkg.T_SID_ID;
	v_user_name		varchar2(255);
	v_timeout		NUMBER(10);
BEGIN
	-- write to audit log
	SELECT app_sid, full_name||' ('||user_name||')'
	  INTO v_app_sid, v_user_name
	  FROM csr_user
	 WHERE csr_user_sid = in_sid_id;
	 
	 
	 SELECT act_timeout 
	   INTO v_timeout
	   FROM security.website w, customer c
	  WHERE LOWER(website_name)= c.host
	    AND c.app_sid = v_app_sid;
	 
	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_LOGON_SU, v_app_sid, in_sid_id, 'Logged on as {0}', v_user_name);
	
	user_pkg.LogonAuthenticated(in_sid_id, v_timeout, out_act_id);
END;

-- use with appropriate care!! Doesn't write back to Oracle session
FUNCTION LogonUserCreatorDaemon
RETURN security_pkg.T_ACT_ID
AS
	v_user_sid	security_pkg.T_SID_ID;
	v_act		security_pkg.T_ACT_ID;
BEGIN
	v_user_sid := SecurableObject_Pkg.GetSIDFromPath(Security_Pkg.ACT_GUEST, SYS_CONTEXT('SECURITY','APP'), 'users/UserCreatorDaemon');
			 
	-- we don't want to set the security context
	v_act := user_pkg.GenerateACT(); 
	Act_Pkg.Issue(v_user_sid, v_act, 3600, SYS_CONTEXT('SECURITY','APP'));
	RETURN v_act;
END;


PROCEDURE GetUsersForList(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_user_list	IN	VARCHAR2,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT cu.csr_user_sid, cu.full_name, cu.email, ut.account_enabled active, cu.user_name,
			   cu.friendly_name, cu.email, cu.region_mount_point_sid
		  FROM TABLE(Utils_Pkg.SplitString(in_user_list,','))l, csr_user cu, security.user_table ut
		 WHERE l.item = cu.csr_user_sid AND l.item = ut.sid_id AND ut.sid_id = cu.csr_user_sid AND 
		 	   ut.account_enabled = 1 AND
		   	   security_pkg.SQL_IsAccessAllowedSID(in_act_id, l.item, security_pkg.PERMISSION_READ) = 1
	  ORDER BY l.pos;
END;


PROCEDURE CreateGroup(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_parent_sid	IN	security_pkg.T_ACT_ID,
	in_group_name	IN	security_pkg.T_SO_NAME,
	out_group_sid	OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	GROUP_pkg.CreateGroupWithClass(in_act_id, in_parent_sid, security_pkg.GROUP_TYPE_SECURITY, in_group_name,
		class_pkg.GetClassId('CSRUserGroup'), out_group_sid);	
END;

FUNCTION GetUserNameFromSid(
    in_act_id				IN	security_Pkg.T_ACT_ID,
	in_user_sid				IN	security_pkg.T_SID_ID
) RETURN VARCHAR2
IS
	v_username				csr_user.user_name%TYPE;
BEGIN
	SELECT user_name INTO v_username FROM csr.csr_user
		WHERE csr_user_sid = in_user_sid;

	RETURN v_username;
END;

PROCEDURE GetUserApprovalList(
	in_start_row			IN	NUMBER,
	in_end_row				IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	 OPEN out_cur FOR
		SELECT total_rows, rn, guid, requested_dtm, activated_dtm, approved_dtm,
			   req_user_sid, req_user_name, req_full_name, email req_email,
			   app_user_sid, app_user_name, app_full_name
		  FROM (
	        SELECT COUNT(*) OVER () AS total_rows, rownum rn, x.*
	          FROM (
	            SELECT au.guid, au.requested_dtm, au.activated_dtm, au.approved_dtm,
	                 requ.csr_user_sid req_user_sid, requ.user_name req_user_name, requ.full_name req_full_name, requ.email,
	                 appu.csr_user_sid app_user_sid, appu.user_name app_user_name, appu.full_name app_full_name
	            FROM v$autocreate_user au, csr_user requ, csr_user appu
	           WHERE au.app_sid = security_pkg.GetApp
	             AND requ.csr_user_sid = au.created_user_sid
	             AND appu.csr_user_sid(+) = au.approved_by_user_sid
	           ORDER BY requested_dtm DESC
	        ) x
		 )
		 WHERE rn > in_start_row 
		   AND rn <= in_end_row
		   AND security_pkg.SQL_IsAccessAllowedSID(security_pkg.GetAct, req_user_sid, security_pkg.PERMISSION_READ)=1
		;
END;

PROCEDURE AddAutoAccount(
	in_user_name			IN	autocreate_user.user_name%TYPE,
	in_guid					IN	autocreate_user.guid%TYPE,	
	in_created_user_sid		IN  security_pkg.T_SID_ID
)
AS
BEGIN
	INSERT INTO autocreate_user (
		user_name, app_sid, guid, created_user_sid
	) VALUES(
		in_user_name, SYS_CONTEXT('SECURITY','APP'), in_guid, in_created_user_sid
	);
END;
	

PROCEDURE ApproveAutoAccount(
	in_user_sid				IN security_pkg.T_SID_ID
)
AS
	v_activated_dtm			autocreate_user.activated_dtm%TYPE;
	v_rejected_dtm			autocreate_user.rejected_dtm%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_user_sid, security_pkg.PERMISSION_WRITE) THEN
	    RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- Check the request has not been rejected and that the 
	-- request has been 'activated' via the e-mail link
	SELECT activated_dtm, rejected_dtm
	  INTO v_activated_dtm, v_rejected_dtm
	  FROM autocreate_user
	 WHERE created_user_sid = in_user_sid;
	
	IF v_activated_dtm IS NULL THEN
		RAISE_APPLICATION_ERROR(ERR_NOT_ACTIVATED, 'The auto create user request for user with sid '||in_user_sid||' has not been activated by the user');
	END IF;
	
	IF v_rejected_dtm IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(ERR_ALREADY_REJECTED, 'The auto create user request for user with sid '||in_user_sid||' has already been rejected');
	END IF;
	
	UPDATE autocreate_user
	   SET approved_dtm = SYSDATE,
	   	   approved_by_user_sid = security_pkg.GetSid
	 WHERE app_sid = security_pkg.GetApp
	   AND created_user_sid = in_user_sid;
	   	   
	-- Activate the account
	ActivateAutoAccount(in_user_sid);
END;

PROCEDURE ActivateAutoAccount(
	in_user_sid				IN security_pkg.T_SID_ID
)
AS
	v_group_sid				security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_user_sid, security_pkg.PERMISSION_WRITE) THEN
	    RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- Activate the account
	ActivateUser(security_pkg.GetAct, in_user_sid);
	
	-- Add the user to the default group
	SELECT self_reg_group_sid
	  INTO v_group_sid
	  FROM customer
	 WHERE app_Sid = security_pkg.GetApp;
	 
	group_pkg.AddMember(security_pkg.GetAct, in_user_sid, v_group_sid);	
END;

PROCEDURE RejectAutoAccount(
	in_user_sid				IN security_pkg.T_SID_ID
)
AS
	v_approved_dtm			autocreate_user.approved_dtm%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_user_sid, security_pkg.PERMISSION_WRITE) THEN
	    RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- Check the request has not already been approved
	SELECT approved_dtm
	  INTO v_approved_dtm
	  FROM autocreate_user
	 WHERE created_user_sid = in_user_sid;
	
	IF v_approved_dtm IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(ERR_NOT_ACTIVATED, 'The auto create user request for user with sid '||in_user_sid||' has already been approved');
	END IF;
	
	-- Ensure the account is deactivated
	DeactivateUser(security_pkg.GetAct, in_user_sid);
	
	-- Reject the request
	UPDATE autocreate_user
	   SET rejected_dtm = SYSDATE
	 WHERE created_user_sid = in_user_sid;
END;

PROCEDURE GetAutoAccountDetails(
	in_guid					IN	autocreate_user.guid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- TODO: there is no security here, moved from the web page
	OPEN out_cur FOR
		SELECT au.created_user_sid, cu.user_name, cu.full_name, cu.email
		  FROM autocreate_user au, csr_user cu
		 WHERE cu.csr_user_sid = au.created_user_sid AND cu.app_sid = au.app_sid AND
		 	   au.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND cu.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND
		   	   au.guid = in_guid;
END;

PROCEDURE GetSelfRegDetails(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- TODO: there is no security here, moved from the web page
	OPEN out_cur FOR
		SELECT self_reg_group_sid, self_reg_needs_approval, self_reg_approver_sid
		  FROM customer
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE MarkAutoAccountActivated(
	in_guid					IN	autocreate_user.guid%TYPE
)
AS
BEGIN
	-- TODO: there is no security here, moved from the web page
	UPDATE autocreate_user
	   SET activated_dtm = SYSDATE
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND guid = in_guid;
END;

PROCEDURE SetAutoAccountUser(
	in_guid					IN	autocreate_user.guid%TYPE,
	in_user_sid				IN	autocreate_user.created_user_sid%TYPE
)
AS
BEGIN
	-- TODO: there is no security here, moved from the web page
	UPDATE autocreate_user
	   SET created_user_sid = in_user_sid
	 WHERE guid = in_guid AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetDonationsReportsFilterId(
	out_filter_id			OUT	csr_user.donations_reports_filter_id%TYPE
)
AS
BEGIN
	-- Data for current user only, so no security check required
	SELECT NVL(donations_reports_filter_id, -1)
	  INTO out_filter_id
	  FROM csr_user
	 WHERE csr_user_sid = SYS_CONTEXT('SECURITY', 'SID');
END;

PROCEDURE GetEnableSaveChartWarning(
	out_enable_warning			OUT customer.enable_save_chart_warning%TYPE
)
AS
BEGIN
	SELECT enable_save_chart_warning
	  INTO out_enable_warning
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetShowSaveChartWarning(
	out_show_warning			OUT	csr_user.show_save_chart_warning%TYPE
)
AS
BEGIN
	-- Data for current user only, so no security check required
	SELECT show_save_chart_warning
	  INTO out_show_warning
	  FROM csr_user
	 WHERE csr_user_sid = SYS_CONTEXT('SECURITY', 'SID');
END;

PROCEDURE SetShowSaveChartWarning(
	in_show_save_chart_warning 		IN csr_user.show_save_chart_warning%TYPE
)
AS
BEGIN
	UPDATE csr_user SET show_save_chart_warning = in_show_save_chart_warning WHERE csr_user.csr_user_sid = SYS_CONTEXT('SECURITY', 'SID');
END;
	
PROCEDURE SetDonationsReportsFilterId(
	in_filter_id			IN	csr_user.donations_reports_filter_id%TYPE
)
AS
BEGIN
	-- Data for current user only, so no security check required
	UPDATE csr_user
	   SET donations_reports_filter_id = null
	 WHERE csr_user_sid = SYS_CONTEXT('SECURITY', 'SID');
END;

PROCEDURE GetDonationsBrowseFilterId(
	out_filter_id			OUT	csr_user.donations_browse_filter_id%TYPE
)
AS
BEGIN
	-- Data for current user only, so no security check required
	SELECT NVL(donations_browse_filter_id, -1)
	  INTO out_filter_id
	  FROM csr_user
	 WHERE csr_user_sid = SYS_CONTEXT('SECURITY', 'SID');
END;

PROCEDURE SetDonationsBrowseFilterId(
	in_filter_id			IN	csr_user.donations_browse_filter_id%TYPE
)
AS
BEGIN
	-- Data for current user only, so no security check required
	UPDATE csr_user
	   SET donations_browse_filter_id = null
	 WHERE csr_user_sid = SYS_CONTEXT('SECURITY', 'SID');
END;

PROCEDURE SetLocalisationSettings(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_language				IN	security.user_table.language%TYPE,
	in_culture				IN	security.user_table.culture%TYPE,
	in_timezone				IN	security.user_table.timezone%TYPE
)
AS
BEGIN
	-- this checks security for us
	security.user_pkg.SetLocalisationSettings(in_act_id, in_user_sid, in_language, in_culture, in_timezone);
	
	-- now update the user's batch run times in case we changed timezone
	UPDATE alert_batch_run
	   SET next_fire_time = (SELECT next_fire_time_gmt
	   						   FROM v$alert_batch_run_time abrt
	   						  WHERE abrt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   						    AND abrt.csr_user_sid = in_user_sid)
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND csr_user_sid = in_user_sid;
END;

PROCEDURE RaiseUserMessageAlert(
	in_notify_user_sid				IN	user_message_alert.notify_user_sid%TYPE,
	in_message						IN	user_message_alert.message%TYPE
)
AS
BEGIN
	INSERT INTO user_message_alert (user_message_alert_id, raised_by_user_sid, notify_user_sid, message)
	VALUES (user_message_alert_id_seq.nextval, SYS_CONTEXT('SECURITY', 'SID'), in_notify_user_sid, in_message);
END;

PROCEDURE GetUserMessageAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ uma.user_message_alert_id, uma.notify_user_sid, cu.full_name, cu.friendly_name, cu.email, 
			   cu.user_name, uma.message, cu.csr_user_sid, uma.app_sid, uma.raised_by_user_sid
		  FROM user_message_alert uma, csr_user cu
		 WHERE uma.app_sid = cu.app_sid AND uma.notify_user_sid = cu.csr_user_sid 
         ORDER BY cu.app_sid, cu.csr_user_sid;        
END;

PROCEDURE RecordUserMessageAlertSent(
	in_user_message_alert_id		IN	user_message_alert.user_message_alert_id%TYPE
)
AS
BEGIN
	DELETE FROM user_message_alert
	 WHERE user_message_alert_id = in_user_message_alert_id;
END;

END;
/

@update_tail
