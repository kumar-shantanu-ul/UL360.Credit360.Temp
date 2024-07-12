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

-- Filter users limit constant:
MAX_USERS CONSTANT NUMBER := 500;

-- security interface procs
PROCEDURE CreateObject(
	in_act							IN	security_pkg.T_ACT_ID,
	in_club_sid						IN	security_pkg.T_SID_ID,
	in_class_id						IN	security_pkg.T_CLASS_ID,
	in_name							IN	security_pkg.T_SO_NAME,
	in_parent_sid_id				IN	security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act							IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_name						IN	security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act							IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act						IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_parent_sid_id		IN security_pkg.T_SID_ID,
	in_old_parent_sid_id		IN security_pkg.T_SID_ID
);

PROCEDURE RestoreFromTrash(
	in_object_sids					IN	security.T_SID_TABLE
);


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

PROCEDURE DisableAccount(
	in_act_id						IN	Security_Pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID
);

PROCEDURE UNSEC_DelRolesFromUserIfNeeded(
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_user_sid		 				IN	security_pkg.T_SID_ID
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
	in_info_xml						IN  csr_user.info_xml%TYPE,
	in_send_alerts					IN	csr_user.send_alerts%TYPE,
	in_enable_aria					IN  csr_user.enable_aria%TYPE,	
	in_line_manager_sid				IN  security_pkg.T_SID_ID,
	in_primary_region_sid			IN  security_pkg.T_SID_ID,
	in_user_ref						IN  csr_user.user_ref%TYPE,
	in_account_expiry_enabled		IN	security.user_table.account_expiry_enabled%TYPE,
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
 * @param in_info_xml					Random extra user info
 * @param in_send_alerts				1 if alerts should be sent for the user, otherwise 0
 * @param in_enable_aria				1 to enable aria accessability for the user
 * @param in_line_manager_sid			Optional line manager sid of the user, used for user hierarchies
 * @param in_chain_company_sid			Optional company sid of the user, used by supply chain
 * @param in_primary_region_sid			Optional primary region sid of the user
 * @param in_user_ref					Optional user reference
 * @param out_user_sid					SID of user that was created
 */
PROCEDURE createUser(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
   	in_user_name					IN	CSR_USER.user_NAME%TYPE,
	in_password 					IN	VARCHAR2,
   	in_full_name					IN	CSR_USER.full_NAME%TYPE,
   	in_friendly_name				IN	CSR_USER.friendly_NAME%TYPE DEFAULT NULL,
	in_email		 				IN	CSR_USER.email%TYPE,
	in_job_title					IN  CSR_USER.job_title%TYPE DEFAULT NULL,
	in_phone_number					IN  CSR_USER.phone_number%TYPE DEFAULT NULL,
	in_info_xml						IN  csr_user.info_xml%TYPE,
	in_send_alerts					IN	csr_user.send_alerts%TYPE,
	in_enable_aria					IN	csr_user.enable_aria%TYPE DEFAULT 0,	
	in_line_manager_sid				IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_chain_company_sid			IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_primary_region_sid			IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_user_ref						IN  csr_user.user_ref%TYPE DEFAULT NULL,
	in_account_expiry_enabled		IN	security.user_table.account_expiry_enabled%TYPE DEFAULT 1,
	out_user_sid 					OUT security_pkg.T_SID_ID
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
	out_sid_id					OUT	security_pkg.T_SID_ID,
	out_guid					OUT	security_pkg.T_ACT_ID
);

PROCEDURE SetUserRef(
	in_csr_user_sid				IN security_pkg.T_SID_ID,
	in_user_ref					IN csr_user.user_ref%TYPE
);

PROCEDURE SetHiddenStatus(
	in_csr_user_sid					IN security_pkg.T_SID_ID,
	in_hidden						IN csr_user.hidden%TYPE
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
 * Check if the specified user is a superadmin
 *
 * @return								1 if the user is a superadmin, otherwise 0
 */
FUNCTION IsSuperAdmin (
	in_user_sid						IN  security_pkg.T_SID_ID
) RETURN NUMBER;


/**
 * Check if the logged on user is an aria user
 *
 * @return								1 if the user has enhanced aria enabled, otherwise 0
 */
FUNCTION IsAriaUser
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
	in_info_xml                     IN  CSR_USER.info_xml%TYPE,
	in_job_title					IN  CSR_USER.job_title%TYPE,
	in_phone_number					IN  CSR_USER.phone_number%TYPE
);

/**
 * Updates a user's details in csr_user table, treating null as no change - uses the existing value where a null is supplied
 *
 * @param in_act						Access token
 * @param in_user_sid					User Sid
 * @param in_user_name					User name
 * @param in_full_name					Their real Name (e.g. 'Fred Bloggs')	
 * @param in_email						Email address
 * @param in_job_title					Job title
 * @param in_phone_number				Phone number
 * @param in_active						Active (can be null - use current state)
 * @param in_info_xml					Random extra user info
 * @param in_send_alerts				1 if alerts should be sent for the user, otherwise 0
 * @param in_enable_aria				1 to enable aria accessibility for the user
 * @param in_line_manager_sid			Optional line manager sid of the user, used for user hierarchies
 * @param in_remove_roles_on_deact		Optional, will drop all user roles on deactivation on specific date
 */

PROCEDURE amendUserWhereInputNotNull(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_user_sid		 				IN	security_pkg.T_SID_ID,
	in_user_name					IN	CSR_USER.user_NAME%TYPE,
	in_full_name					IN	CSR_USER.full_NAME%TYPE,
	in_friendly_name				IN	CSR_USER.friendly_NAME%TYPE,
	in_email		 				IN	CSR_USER.email%TYPE,
	in_job_title					IN  CSR_USER.job_title%TYPE,
	in_phone_number					IN  CSR_USER.phone_number%TYPE,
	in_active						IN  security_pkg.T_USER_ACCOUNT_ENABLED,
	in_info_xml						IN  csr_user.info_xml%TYPE,
	in_send_alerts					IN	csr_user.send_alerts%TYPE,
	in_enable_aria					IN  csr_user.enable_aria%TYPE,
	in_line_manager_sid				IN  security_pkg.T_SID_ID,
	in_primary_user_sid				IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_remove_roles_on_deact		IN	csr_user.remove_roles_on_deactivation%TYPE DEFAULT 0
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
 * @param in_active						Active (can be null - use current state)
 * @param in_info_xml					Random extra user info
 * @param in_send_alerts				1 if alerts should be sent for the user, otherwise 0
 * @param in_enable_aria				1 to enable aria accessability for the user
 * @param in_line_manager_sid			Optional line manager sid of the user, used for user hierarchies
 * @param in_primary_region_sid			Optional primary region for the user
 * @param in_remove_roles_on_deact		Optional will drop all roles from the user on deactivation.
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
	in_active						IN  security_pkg.T_USER_ACCOUNT_ENABLED,
	in_info_xml						IN  csr_user.info_xml%TYPE,
	in_send_alerts					IN	csr_user.send_alerts%TYPE,
	in_enable_aria					IN  csr_user.enable_aria%TYPE					DEFAULT 0,
	in_line_manager_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_primary_region_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_remove_roles_on_deact		IN	csr_user.remove_roles_on_deactivation%TYPE	DEFAULT 0
);

PROCEDURE SetUserEmail(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_user_sid		 				IN	security_pkg.T_SID_ID,
	in_email		 				IN	CSR_USER.email%TYPE
);
 
PROCEDURE SetIndStartPoints(
    in_user_sid						IN  security_pkg.T_SID_ID,
    in_ind_sids		    			IN	security_pkg.T_SID_IDS
);

PROCEDURE SetRegionStartPoints(
	in_user_sid						IN  security_pkg.T_SID_ID,
	in_region_sids					IN	security_pkg.T_SID_IDS
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
 * @param in_disable_alerts				If nonzero, prevents the user from receiving future alerts by
 *										clearing the send_alerts flag on the csr_user table.
 * @param in_remove_from_roles			optional, will drop all roles from the user.
 */
PROCEDURE deactivateUser(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_user_sid		 				IN	security_pkg.T_SID_ID,
	in_disable_alerts				IN	NUMBER DEFAULT 0,
	in_raise_user_inactive_alert	IN	NUMBER DEFAULT 1,
	in_remove_from_roles			IN	NUMBER DEFAULT 0
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
	in_created_user_sid		IN  security_pkg.T_SID_ID,
	in_require_new_password	IN	autocreate_user.require_new_password%TYPE,
	in_redirect_to_url		IN	autocreate_user.redirect_to_url%TYPE
);

PROCEDURE AddAutoCreateUser(
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_user_name			IN	autocreate_user.user_name%TYPE,
	out_guid 				OUT Security_Pkg.T_ACT_ID
);

PROCEDURE GetAutoCreateUser(
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_guid					IN	autocreate_user.guid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
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
 * user_name, full_name, email, last_logon_dtm, app_sid
 */
PROCEDURE GetUser(
	in_act 							IN	security_pkg.T_ACT_ID,
	in_user_sid 					IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * Gets general data about a user
 *
 * @param in_user_sid					The user SID
 * @param out_user_cur					The user details
 * @param out_isp_cur					The indicator start point
 * @param out_rsp_cur					The region start point
 *
 * The output rowset is of the form:
 * user_name, full_name, email, last_logon_dtm, app_sid
 */
PROCEDURE GetUserAndStartPoints(
	in_user_sid 					IN  security_pkg.T_SID_ID,
	out_user_cur					OUT SYS_REFCURSOR,
	out_isp_cur						OUT SYS_REFCURSOR,
	out_rsp_cur						OUT SYS_REFCURSOR
);

/**
 * Gets general data about the current user
 *
 * @param out_user_cur					The user details
 * @param out_isp_cur					The indicator start point
 * @param out_rsp_cur					The region start point
 *
 * The output rowset is of the form:
 * user_name, full_name, email, last_logon_dtm, app_sid
 */
PROCEDURE GetCurrentUserAndStartPoints(
	out_user_cur					OUT SYS_REFCURSOR,
	out_isp_cur						OUT SYS_REFCURSOR,
	out_rsp_cur						OUT SYS_REFCURSOR
);

/**
 * Gets general data about a user (as for GetUser but with no security check)
 *
 * @param in_user_sid					The user SID
 * @param out_cur						The output rowset
 *
 * The output rowset is of the form:
 * user_name, full_name, email, last_logon_dtm, app_sid
 */
PROCEDURE GetUser_INSECURE(
	in_user_sid 					IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * Gets basic data about multiple user
 *
 * @param	in_user_sids		The user sids
 * @param	in_skip_missing		Just skip missing users (otherwise raises security_pkg.OBJECT_NOT_FOUND)
 * @param	in_skip_denid		Just skip users without read permission (otherwise raises security_pkg.ACCESS_DENIED)
 * @param	out_user_cur		User details
 *
 * This is more permissive than GetUser but tells you less, the idea being
 * that if you can see a user in the output of FilterUsers, then you can see
 * the same data here.
 */
PROCEDURE GetUsers(
	in_user_sids					IN	security_pkg.T_SID_IDS,
	in_skip_missing					IN	NUMBER DEFAULT 0,
	in_skip_denied					IN	NUMBER DEFAULT 0,
	out_user_cur					OUT	SYS_REFCURSOR
);

/**
 * Gets basic data about a user
 *
 * @param in_user_sid					The user SID
 * @param out_cur						The output rowset
 *
 * This is more permissive than GetUser but tells you less, the idea being
 * that if you can see a user in the output of FilterUsers, then you can see
 * the same data here.
 */
PROCEDURE GetUserBasicDetails(
	in_user_sid 					IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetUserBasicDetails(
	in_user_sid 					IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR,
	out_groups_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetUserLineManager(
	in_act							IN	security_pkg.T_ACT_ID,
	in_user_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Return region start points for the given user, no security checks
 *
 * @param in_user_sid				The user to fetch start points for
 * @return							The user's start points
 */
FUNCTION UNSEC_GetRegStartPointsAsTable(
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT NULL
)
RETURN security.T_SID_TABLE;

/**
 * Return region start points for the given user, checking for read permissions
 * on the user SO
 *
 * @param in_user_sid				The user to fetch start points for
 * @return							The user's start points
 */
FUNCTION GetRegionStartPointsAsTable(
	in_user_sid						IN	security_pkg.T_SID_ID
)
RETURN security.T_SID_TABLE;

/**
 * Return region start points for the current user (no security checks needed)
 *
 * @return							The user's start points
 */
FUNCTION GetRegionStartPointsAsTable
RETURN security.T_SID_TABLE;

/**
 * Gets list of all users in the users container for a given application sid
 * Active and non-active.
 *
 * @param in_act						Access token
 * @param in_app_sid					The application sid (saves additional db lookup from most code)
 * @param in_group_sid					The group to restrict to (optional)
 * @param in_filter_name				A string that must appear in users' full names or user names (optional)
 * @param in_role_sid					A role to restrict the to (optional)
 * @param in_region_sid					A A region to restrict to (role membership) (optional)
 * @param in_include_forms				True to populate out_forms; False to ignore it
 * @param out_users						The user details
 * @param out_groups					Groups for each user
 * @param out_regions					Regions owned by each user
 * @param out_roles						Roles for each user
 * @param out_ind_start_points			Indicator start points for each user
 * @param out_region_start_points		Region start points for each user
 * @param out_extra_fields				Extra fields for each user
 * @param out_forms						Details about delegations per user
 */
PROCEDURE GetAllUsers(
	in_act_id						IN  security_pkg.T_ACT_ID,
	in_app_sid						IN  security_pkg.T_SID_ID,
	in_group_sid					IN 	security_pkg.T_SID_ID,
	in_filter_name					IN  csr_user.full_name%TYPE,
	in_role_sid						IN 	security_pkg.T_SID_ID,
	in_region_sid					IN 	security_pkg.T_SID_ID,
	in_include_forms				IN  INTEGER,
	in_menu_permissions				IN  INTEGER,
	out_users						OUT SYS_REFCURSOR,
	out_groups						OUT SYS_REFCURSOR,
	out_regions						OUT SYS_REFCURSOR,
	out_roles						OUT SYS_REFCURSOR,
	out_ind_start_points			OUT SYS_REFCURSOR,
	out_region_start_points			OUT SYS_REFCURSOR,
	out_extra_fields				OUT SYS_REFCURSOR,
	out_forms						OUT SYS_REFCURSOR,
	out_menu						OUT SYS_REFCURSOR,
	out_user_groups					OUT SYS_REFCURSOR,
	out_group_members				OUT SYS_REFCURSOR,
	out_menu_permissions			OUT SYS_REFCURSOR
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
	out_cur			OUT SYS_REFCURSOR
);

/**
 * GetUsers: this gets all users including ones that have been move to the trash
 * 
 * @param in_act_id				Access token
 * @param in_app_sid			The sid of the Application/CSR object
 * @param out_cur				The rowset
 */
PROCEDURE GetUsers(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_app_sid 	IN  security_pkg.T_SID_ID,	 
	out_cur			OUT SYS_REFCURSOR
);

/**
 * GetUsers_ASP: this gets all users including ones that have been move to the trash
 * This is a copy of GetUsers: However appearantly .asp pages fail to detect which 
 * overloaded GetUsers function to choose from. 
 * Adding a renamed function solves this issue.
 *  
 * @param in_act_id				Access token
 * @param in_app_sid			The sid of the Application/CSR object
 * @param out_cur				The rowset
 */
PROCEDURE GetUsers_ASP(
	in_act_id	IN 	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur		OUT SYS_REFCURSOR
);

/**
 * GetUsersInGroup
 * 
 * @param in_act_id				Access token
 * @param in_app_sid			The sid of the Application/CSR object
 * @param in_group_sid.
 * @param out_cur				The rowset
 */
PROCEDURE GetUsersInGroup(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_app_sid IN  security_pkg.T_SID_ID,
	in_group_sid	IN 	security_pkg.T_SID_ID, 	 
	out_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetUsersWithGroupsAndRoles(
	out_user_cur		OUT	SYS_REFCURSOR,
	out_roles_cur		OUT	SYS_REFCURSOR,
	out_groups_cur		OUT	SYS_REFCURSOR
);

/**
 * Search
 * 
 * @param in_act_id				Access token
 * @param in_app_sid			The sid of the Application/CSR object
 * @param in_group_sid.
 * @param in_filter_name.
 * @param in_order_by.
 * @param out_cur				The rowset
 */
PROCEDURE Search(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_app_sid IN  security_pkg.T_SID_ID,	 
	in_group_sid	IN 	security_pkg.T_SID_ID, 
	in_filter_name	IN	csr_user.full_name%TYPE,
	in_order_by 	IN	VARCHAR2, 
	out_cur			OUT SYS_REFCURSOR
);

/**
 * Gets a list of users matching specified search criteria.
 * 
 * @param in_act_id				The requesting user's access token.
 *
 *								Required permissions:
 *									- PERMISSION_LIST_CONTENTS on in_app_sid/Users
 *									- PERMISSION_READ on in_group_sid (if specified)
 *									- PERMISSION_READ on in_region_sid (if specified)
 *									- PERMISSION_READ on in_role_sid (if specified)
 *
 * @param in_app_sid			The sid of the application/CSR object to search under.
 *
 * @param in_group_sid			The sid of the group to filter users by, or null.
 *
 * @param in_role_sid			The sid of the role to filter users by, or null. 
 *
 * @param in_region_sid			The sid of the region to filter users by, or null. Users in a role for the specified 
 *								region either explicitly or by inheritance (or any region not specified) are returned.
 *
 * @param in_filter_name		A case-insensitive string to filter full names by, or null.
 *
 * @param in_order_by			A string containing the comma-delimited list of columns to order the results by, or 
 *								null to use the default order (last_logon_dtm desc). Any valid ORDER BY clause can be
 *								used here, but must be limited to sorting on the following columns: csr_user_sid, 
 *								active, user_name, full_name, email, last_logon_dtm, created_dtm.
 *
 * @param out_cur				A cursor that yields the result set:
 *
 *							 		Name                                      Null?    Type
 *							 		----------------------------------------- -------- ----------------------------
 *							 		CSR_USER_SID                              NOT NULL NUMBER(10)
 *							 		ACTIVE                                    NOT NULL NUMBER(1)
 *							 		USER_NAME                                 NOT NULL VARCHAR2(256)
 *							 		FULL_NAME                                          VARCHAR2(256)
 *							 		EMAIL                                              VARCHAR2(256)
 *							 		LAST_LOGON_DTM                            NOT NULL DATE
 *							 		LAST_LOGON_FORMATTED                               VARCHAR2(19)
 *							 		CREATED_DTM                               NOT NULL DATE
 *							 		CREATED_FORMATTED                                  VARCHAR2(19)
 *							 		SEND_ALERTS                               NOT NULL NUMBER(1)
 */
PROCEDURE Search(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,	 
	in_group_sid	IN	security_pkg.T_SID_ID DEFAULT NULL,	
	in_role_sid		IN	security_pkg.T_SID_ID DEFAULT NULL,	
	in_region_sid	IN	security_pkg.T_SID_ID DEFAULT NULL,	
	in_filter_name	IN	csr_user.full_name%TYPE DEFAULT NULL,
	in_order_by 	IN	VARCHAR2 DEFAULT NULL, 
	out_cur			OUT	SYS_REFCURSOR
);

/**
 * FilterUsers
 * 
 * @param in_filter.
 * @param out_cur				The rowset
 * @param out_total_num_users	Total number of users we are filtering from
 */
PROCEDURE FilterUsers(  
	in_filter			IN	VARCHAR2,
	out_cur				OUT SYS_REFCURSOR,
	out_total_num_users	OUT SYS_REFCURSOR
);

/**
 * FilterUsers
 * 
 * @param in_filter.
 * @param in_include_inactive
 * @param out_cur				The rowset
 * @param out_total_num_users	Total number of users we are filtering from
 */
PROCEDURE FilterUsers(  
	in_filter			IN	VARCHAR2,
	in_include_inactive	IN	NUMBER DEFAULT 0,
	out_cur				OUT SYS_REFCURSOR,
	out_total_num_users	OUT SYS_REFCURSOR
);

-- For RestAPI to specify user limit/max size (it needs all users).
/**
 * FilterUsers
 *
 * @param in_filter.
 * @param in_include_inactive
 * @param in_exclude_user_sids  A list of user sids to exclude from the search 
 * @param in_max_size			The number of records to limit to.
 * @param out_cur				The rowset
 * @param out_total_num_users	Total number of users we are filtering from
 */
PROCEDURE FilterUsers(  
	in_filter			IN	VARCHAR2,
	in_include_inactive	IN	NUMBER DEFAULT 0,
	in_max_size			IN	NUMBER,
	out_cur				OUT SYS_REFCURSOR,
	out_total_num_users	OUT SYS_REFCURSOR
);

/**
 * FilterUsers
 * 
 * @param in_filter.
 * @param in_include_inactive
 * @param in_exclude_user_sids  A list of user sids to exclude from the search 
 * @param out_cur				The rowset
 * @param out_total_num_users	Total number of users we are filtering from
 */
PROCEDURE FilterUsers(  
	in_filter					IN	VARCHAR2,
	in_include_inactive			IN	NUMBER DEFAULT 0,
	in_exclude_user_sids		IN  security_pkg.T_SID_IDS, -- mainly for finding users except user X - e.g. on a user edit page
	out_cur						OUT SYS_REFCURSOR,
	out_total_num_users			OUT SYS_REFCURSOR
);

/**
 * FilterUsers
 * @param in_filter.
 * @param in_include_inactive
 * @param in_exclude_user_sids  A list of user sids to exclude from the search 
 * @param out_cur				The rowset
 * @param out_total_num_users	Total number of users we are filtering from
 */
PROCEDURE FilterUsers(  
	in_filter					IN	VARCHAR2,
	in_include_inactive			IN	NUMBER DEFAULT 0,
	in_exclude_user_sids		IN  security_pkg.T_SID_IDS, -- mainly for finding users except user X - e.g. on a user edit page
	in_max_size					IN	NUMBER,
	out_cur						OUT SYS_REFCURSOR,
	out_total_num_users			OUT SYS_REFCURSOR
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
 * FilterUsersSinceDate
 * 
 * @param in_filter				.
 * @param in_include_inactive
 * @param in_modified_since_dtm Only users modified since this date will be included
 * @param out_users_cur			The users
 * @param out_user_groups_cur	The users' groups
 */
PROCEDURE FilterUsersSinceDate(  
	in_filter				IN	VARCHAR2,
	in_include_inactive		IN	NUMBER DEFAULT 0,
    in_modified_since_dtm	IN	audit_log.audit_date%TYPE,
	out_users_cur			OUT SYS_REFCURSOR,
	out_user_groups_cur		OUT SYS_REFCURSOR,
	out_groups_cur			OUT SYS_REFCURSOR
);

/**
 *	FilterUsersInRole
 *
 *	@param	in_act_id
 *	@param	in_role_name	Role Name.
 *	@param	in_filter
 *	@param	out_users		The rowset.
 */
PROCEDURE FilterUsersInRole(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_role_name					IN	role.name%TYPE,
	in_region_sid					IN	region.region_sid%TYPE	DEFAULT NULL,
	in_filter						IN	VARCHAR2,
	out_users						OUT	SYS_REFCURSOR,
	out_total_num_users				OUT	SYS_REFCURSOR
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
	out_cursor			OUT SYS_REFCURSOR 
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

FUNCTION IsLogonAsUserAllowedSQL(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_user_sid 		IN 	security_pkg.T_SID_ID
)
RETURN BINARY_INTEGER;

PROCEDURE LogonAsUser(					
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_sid_id			IN	security_pkg.T_SID_ID,
	out_act_id			OUT Security_Pkg.T_ACT_ID
);

/**
 * Issue a temporary ACT for SSO authentication.  Suppresses auditing when
 * creating the ACT to prevent noise in the audit log (we want one entry
 * per SSO login).
 *
 * XXX: This isn't a good design; the temporary ACT is issued to be replaced
 * as it travels around in a query string.  In that case we should be
 * ensuring that the ACT can only be used to log the user on.  Oh well.
 *
 * @param in_sid_id					The sid of the user to issue a temporary ACT for
 * @param out_act_id				The issued ACT
 */
PROCEDURE IssueTemporarySSOACT(
	in_sid_id						IN	security_pkg.T_SID_ID,
	out_act_id						OUT	security_pkg.T_ACT_ID
);

/**
 * Destroy a temporary ACT issues by IssueTemporarySSOACT.  Suppresses auditing
 * to prevent a spurious logged off entry in the audit log.
 *
 * @param in_act_id					The issued ACT
 */
PROCEDURE DestroyTemporarySSOACT(
	in_act_id						IN security_pkg.T_ACT_ID
);

/**
 * Logs on a user via SSO.  The timeout is taken from the primary website
 * (i.e. customer.host).
 *
 * @param in_sid_id					The sid of the user to log on
 * @param out_act_id				The issues ACT
 */
PROCEDURE LogonSSOUser(
	in_sid_id						IN	security_pkg.T_SID_ID,
	out_act_id						OUT	security_pkg.T_ACT_ID
);

/**
 * Logs on a user via SSO with the given timeout
 *
 * @param in_sid_id					The sid of the user to log on
 * @param in_app_sid				The sid of the application the user belongs to
 * @param in_timeout				The ACT timeout
 * @param out_act_id				The issues ACT
 */
PROCEDURE LogonSSOUser(
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_timeout						IN	security.website.act_timeout%TYPE,
	out_act_id						OUT	security_pkg.T_ACT_ID
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
	out_cur			OUT	SYS_REFCURSOR
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
	out_cur					OUT	SYS_REFCURSOR
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

PROCEDURE GetShowSaveChartWarning(
	out_show_warning			OUT csr_user.show_save_chart_warning%TYPE
);

PROCEDURE SetShowSaveChartWarning(
	in_show_save_chart_warning 		IN csr_user.show_save_chart_warning%TYPE
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

/**
 * Fetch user full_name and friendly_name to check against password
 *
 * @param out_full_name					The full name
 * @param out_friendly_name				The friendly name
 */
PROCEDURE GetUserNames(
	in_user_sid				IN	security_pkg.T_SID_ID,
	out_full_name			OUT	VARCHAR2,
	out_friendly_name		OUT	VARCHAR2
);

/**
 * Fetch user directory type, which defines how some search
 * controls will search for users (csr users/LDAP)
 *
 * @param in_user_directory_type_id    The directory type id
 * @param out_cur                      The user directory type
 */
PROCEDURE GetUserDirectoryType(
	in_user_directory_type_id		IN  user_directory_type.user_directory_type_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * Fetch the 'friendly name' for a specific e-mail address,
 * used to header automated batch export e-mails.
 *
 * @param in_email_address             The e-mail address
 */
FUNCTION GetFriendlyNameFromEmail(
	in_email_address			IN	csr.csr_user.email%TYPE
) RETURN VARCHAR2;

/**
 * Fetch the user_sid for a specific e-mail address,
 * used to match received emails to their users.
 *
 * @param in_email_address             The e-mail address
 */
FUNCTION GetUserSidFromEmail(
	in_email_address			IN	csr.csr_user.email%TYPE
) RETURN security_pkg.T_SID_ID;

/**
 * Check whether the last login type was SSO for a specific user
 *
 * @param in_user_sid			The user SID
 */
FUNCTION IsLastLoginSso (
  in_user_sid				IN	security_pkg.T_SID_ID
) RETURN NUMBER;

/**
 * Check if users have a valid language. If their language is unavailable 
 *  we will assign them the site's default language.
 *
 * @param in_act_id				The access token.
 */
PROCEDURE EnsureUserLanguagesAreValid(
	in_act_id				IN	security_pkg.T_ACT_ID
);

PROCEDURE GetUserRelationshipTypes(
	out_cur OUT SYS_REFCURSOR
);

PROCEDURE SaveUserRelationshipType(
	in_user_relationship_type_id	IN csr.user_relationship_type.user_relationship_type_id%TYPE,
	in_label						IN csr.user_relationship_type.label%TYPE,
	out_user_relationship_type_id	OUT csr.user_relationship_type.user_relationship_type_id%TYPE
);

PROCEDURE DeleteUserRelationshipType(
	in_user_relationship_type_id	IN csr.user_relationship_type.user_relationship_type_id%TYPE
);

PROCEDURE GetUserRelationshipsForUser(
	in_child_user_sid	IN csr.user_relationship.child_user_sid%TYPE,
	out_cur OUT SYS_REFCURSOR
);

PROCEDURE ClearUserRelationshipsForUser(
	in_child_user_sid	IN csr.user_relationship.child_user_sid%TYPE
);

PROCEDURE AddUserRelationship(
	in_child_user_sid				IN csr.user_relationship.child_user_sid%TYPE,
	in_parent_user_sid				IN csr.user_relationship.parent_user_sid%TYPE,
	in_user_relationship_type_id	IN csr.user_relationship.user_relationship_type_id%TYPE
);

PROCEDURE DeleteUserRelationship(
	in_child_user_sid				IN csr.user_relationship.child_user_sid%TYPE,
	in_parent_user_sid				IN csr.user_relationship.parent_user_sid%TYPE,
	in_user_relationship_type_id	IN csr.user_relationship.user_relationship_type_id%TYPE
);

PROCEDURE GetJobFunctions(
	out_cur OUT SYS_REFCURSOR
);

PROCEDURE SaveFunction(
	in_function_id	IN csr.function.function_id%TYPE,
	in_label		IN csr.function.label%TYPE,
	out_function_id	OUT csr.function.function_id%TYPE
);

PROCEDURE DeleteFunction(
	in_function_id	IN csr.function.function_id%TYPE
);

PROCEDURE GetUserJobFunctions(
	in_csr_user_sid	IN csr.user_function.csr_user_sid%TYPE,
	out_cur 		OUT SYS_REFCURSOR
);

PROCEDURE ClearFunctionsForUser(
	in_csr_user_sid	IN csr.user_function.csr_user_sid%TYPE
);

PROCEDURE AddUserFunction(
	in_csr_user_sid	IN csr.user_function.csr_user_sid%TYPE,
	in_function_id	IN csr.user_function.function_id%TYPE
);

/**
 * Raises user inactive reminder alert when user account has been inactive 
 * and about to be disabled
 *
 * @param in_user_sid			User sid
 * @param in_app_sid			Application sid
 */
PROCEDURE RaiseUserInactiveReminderAlert(
	in_user_sid				IN	user_inactive_rem_alert.notify_user_sid%TYPE,
	in_app_sid				IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP')
);

/**
 * Gets user inactive reminder alerts to send
 */
PROCEDURE GetUserInactiveReminderAlerts(
	out_cur					OUT	SYS_REFCURSOR
);

/**
 * Sets user inactive reminder alert as sent/processed
 *
 * @param in_alert_id			User inactive reminder alert id
 * @param in_user_sid			User sid
 */
PROCEDURE RecordUserInactiveReminderSent(
	in_alert_id				IN	user_inactive_rem_alert.user_inactive_rem_alert_id%TYPE,
	in_user_sid				IN	user_inactive_rem_alert.notify_user_sid%TYPE
);

/**
 * Raises user inactive alert when account is disabled automatically
 * for being inactive for n days (Account policy)
 *
 * @param in_user_sid			User sid
 * @param in_app_sid			Application sid
 */
PROCEDURE RaiseUserInactiveSysAlert(
	in_user_sid				IN	user_inactive_sys_alert.notify_user_sid%TYPE,
	in_app_sid				IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP')
);

/**
 * Gets automatically generated user inactive alerts to send
 */
PROCEDURE GetUserInactiveSysAlerts(
	out_cur					OUT	SYS_REFCURSOR
);

/**
 * Sets automatically generated user inactive alert as sent/processed
 *
 * @param in_alert_id			User inactive system alert id
 * @param in_user_sid			User sid
 */
PROCEDURE RecordUserInactiveSysAlertSent(
	in_alert_id				IN	user_inactive_sys_alert.user_inactive_sys_alert_id%TYPE,
	in_user_sid				IN	user_inactive_sys_alert.notify_user_sid%TYPE
);

/**
 * Raises user inactive alert when account is disabled manually
 *
 * @param in_user_sid			User sid
 * @param in_app_sid			Application sid
 */
PROCEDURE RaiseUserInactiveManAlert(
	in_user_sid				IN	user_inactive_man_alert.notify_user_sid%TYPE,
	in_app_sid				IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP')
);

/**
 * Gets manually generated user inactive alerts to send
 */
PROCEDURE GetUserInactiveManAlerts(
	out_cur					OUT	SYS_REFCURSOR
);

/**
 * Sets manually generated user inactive alert as sent/processed
 *
 * @param in_alert_id			User inactive manual alert id
 * @param in_user_sid			User sid
 */
PROCEDURE RecordUserInactiveManAlertSent(
	in_alert_id				IN	user_inactive_man_alert.user_inactive_man_alert_id%TYPE,
	in_user_sid				IN	user_inactive_man_alert.notify_user_sid%TYPE
);

PROCEDURE RaiseUserInactiveRemAlerts;

FUNCTION GetUserAdminHelperPkg RETURN customer.user_admin_helper_pkg%TYPE;

/**
 * Returns ind start points for the given user, checking for read permissions
 * on the user SO
 *
 * @param in_user_sid				The user to fetch start points for
 * @return							The user's start points
 */
FUNCTION GetIndStartPointsAsTable(
	in_user_sid						IN	security.security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID')
)
RETURN security.T_SID_TABLE;

PROCEDURE AddUserToGroupLogged(
	in_user_sid						IN	security.security_pkg.T_SID_ID,
	in_group_sid					IN	security.security_pkg.T_SID_ID,
	in_group_name					IN	VARCHAR2
);

PROCEDURE GetLogonTypes(
	out_cur OUT SYS_REFCURSOR
);

PROCEDURE GetGroupMemberGroupsForExport(
	in_parent_sid					IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
);

FUNCTION UsersWithReferenceCount RETURN NUMBER;

PROCEDURE GetGroups(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE SetCookieConsent(
	in_accept		NUMBER
);

PROCEDURE GetUserBasicInfo(
	in_user_sids	IN security.security_pkg.T_SID_IDS,
	out_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetUserBasicInfoByUuids(
	in_guids		IN security.security_pkg.T_VARCHAR2_ARRAY,
	out_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetUserExtendedInfo(
	in_guids		IN security_pkg.T_VARCHAR2_ARRAY,
	out_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetIdentityDetails(
	in_user_sid		IN security_pkg.T_SID_ID DEFAULT security.security_pkg.GetSid,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetIdentityDetailsWithGroups(
	out_user_cur		OUT	SYS_REFCURSOR,
	out_groups_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetIdentityDetailsWithGroups(
	in_act_id			IN	security_pkg.T_ACT_ID,
	out_user_cur		OUT	SYS_REFCURSOR,
	out_groups_cur		OUT	SYS_REFCURSOR
);

PROCEDURE DoImpersonationForJwt(
	in_jwt_id			IN	security.act_timeout.jwt_id%TYPE,
	in_user_guid		IN	csr.csr_user.guid%TYPE,
	in_tenant_id		IN	security.tenant.tenant_id%TYPE,
	out_user_cur		OUT	SYS_REFCURSOR,
	out_groups_cur		OUT	SYS_REFCURSOR
);

PROCEDURE IssueServiceLevelIdentity(
	in_jwt_id					IN	security.act_timeout.jwt_id%TYPE,
	in_service_identifier		IN	service_user_map.service_identifier%TYPE,
	in_tenant_id				IN	security.tenant.tenant_id%TYPE,
	out_user_cur				OUT	SYS_REFCURSOR,
	out_groups_cur				OUT	SYS_REFCURSOR
);

PROCEDURE ExchangeJwtForAct(
	in_jwt_id			IN	security.act_timeout.jwt_id%TYPE,
	in_user_guid		IN	csr.csr_user.guid%TYPE,
	in_tenant_id		IN	security.tenant.tenant_id%TYPE,
	out_act				OUT	Security_Pkg.T_ACT_ID,
	out_app_sid			OUT	security.tenant.application_sid_id%TYPE,
	out_host			OUT	csr.customer.host%TYPE
);

PROCEDURE GetUserByGuid(
	in_user_guid		IN	csr.csr_user.guid%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);

FUNCTION GetUserSidFromGuid(
	in_user_guid		IN	csr.csr_user.guid%TYPE
)
RETURN NUMBER;

PROCEDURE GetUserSidFromGuidBatch(
	in_user_guids					IN	security.security_pkg.T_VARCHAR2_ARRAY,
	out_cur							OUT	SYS_REFCURSOR
);

-- Returns a list of users that cannot be structure imported against.
-- Essentially superadmins and special users
PROCEDURE GetBlockedStructureImportUsers(
	out_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetUserRecordBySid(
	in_csr_user_sid			IN	csr.csr_user.csr_user_sid%TYPE,
	out_user				OUT	CSR.T_USER
);

PROCEDURE GetUserRecordByUserName(
	in_user_name			IN  csr.csr_user.user_name%TYPE,
	out_user				OUT CSR.T_USER
);

PROCEDURE UNSEC_GetUserRecordBySid(
	in_csr_user_sid			IN	csr.csr_user.csr_user_sid%TYPE,
	out_user				OUT	CSR.T_USER
);

PROCEDURE GetUserRecordByRef(
	in_user_ref				IN	csr.csr_user.user_ref%TYPE,
	out_user				OUT	CSR.T_USER
);

PROCEDURE UNSEC_GetUserRecordByRef(
	in_user_ref				IN	csr.csr_user.user_ref%TYPE,
	out_user				OUT	CSR.T_USER
);

PROCEDURE AnonymiseUsersBatchJob(
	in_user_sids					IN	security_pkg.T_SID_IDS,
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE ProcessAnonymiseUsersBatchJob (
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	out_result_desc					OUT	batch_job.result%TYPE,
	out_result_url					OUT	batch_job.result_url%TYPE
);

PROCEDURE anonymiseUser(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_user_sid		 				IN	security_pkg.T_SID_ID,
	in_user_name					IN	CSR_USER.user_NAME%TYPE						DEFAULT SYS_GUID(),
	in_full_name					IN	CSR_USER.full_NAME%TYPE						DEFAULT SYS_GUID(),
	in_friendly_name				IN	CSR_USER.friendly_NAME%TYPE					DEFAULT SYS_GUID(),
	in_job_title					IN  CSR_USER.job_title%TYPE						DEFAULT SYS_GUID(),
	in_info_xml						IN  csr_user.info_xml%TYPE						DEFAULT NULL
);

PROCEDURE DeleteAuditLogsAfterAnonymisation(
	in_object_sid		IN	security.security_pkg.T_SID_ID
);

PROCEDURE UNSEC_SitesEnabledForAnonymisation(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE UsersEligibleForAnonymisation(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE CountOfUsersEligibleForAnonymisation(
	in_number_of_days			IN	NUMBER,
	out_number_of_users			OUT NUMBER
);

END Csr_User_Pkg;
/

