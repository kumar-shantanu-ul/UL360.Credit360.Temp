CREATE OR REPLACE PACKAGE  CHAIN.company_user_pkg
IS

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

FUNCTION GetPasswordResetUsername (
	in_guid					IN  security_pkg.T_ACT_ID
) RETURN security_pkg.T_SO_NAME;

FUNCTION CreateUserForInvitation (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE
) RETURN security_pkg.T_SID_ID;

FUNCTION CreateUserForInvitation (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE,
	in_user_name			IN  csr.csr_user.user_name%TYPE
) RETURN security_pkg.T_SID_ID;

FUNCTION CreateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE,
	in_user_name			IN  csr.csr_user.user_name%TYPE,
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_visibility_id		IN  chain_user.visibility_id%TYPE DEFAULT chain_pkg.FULL
) RETURN security_pkg.T_SID_ID;

FUNCTION CreateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE,
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_visibility_id		IN  chain_user.visibility_id%TYPE
) RETURN security_pkg.T_SID_ID;

FUNCTION CreateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_password				IN	Security_Pkg.T_USER_PASSWORD, 	
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE
) RETURN security_pkg.T_SID_ID;

FUNCTION CreateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_name			IN	csr.csr_user.user_name%TYPE,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_password				IN	Security_Pkg.T_USER_PASSWORD, 	
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE
) RETURN security_pkg.T_SID_ID;

FUNCTION CreateUserFromApi (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE,
	in_user_name			IN  csr.csr_user.user_name%TYPE,
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_send_alerts			IN  NUMBER
) RETURN security_pkg.T_SID_ID;

PROCEDURE SetMergedStatus (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_merged_to_user_sid	IN  security_pkg.T_SID_ID
);

PROCEDURE SetRegistrationStatus (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_status				IN  chain_pkg.T_REGISTRATION_STATUS,
	in_force_pending		IN  NUMBER DEFAULT 0
);

PROCEDURE AddUserToCompany_UNSEC (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_force_admin			IN NUMBER DEFAULT 1
);

PROCEDURE AddUserToCompany (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE RemoveUserFromCompany (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_company_sid			IN  security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('COMPANY', 'CHAIN_COMPANY'),
	in_remove_last_admin	IN	NUMBER DEFAULT 0
);

PROCEDURE UNSEC_RemoveUserFromCompany (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_company_sid			IN  security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('COMPANY', 'CHAIN_COMPANY'),
	in_remove_last_admin	IN	NUMBER DEFAULT 0
);

PROCEDURE GetUserSid (
	in_user_name			IN  security_pkg.T_SO_NAME,
	out_user_sid			OUT security_pkg.T_SID_ID
);

PROCEDURE SetVisibility (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_visibility			IN  chain_pkg.T_VISIBILITY
);

PROCEDURE SearchNonFollowerUsers(
	in_supplier_sid			IN security_pkg.T_SID_ID,
	in_search_term  		IN varchar2,
	in_include_inactive		IN	NUMBER DEFAULT 0,
	in_exclude_user_sids	IN  security_pkg.T_SID_IDS,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_total_num_users		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchUsersToAddToCompany(
	in_company_sid			IN security_pkg.T_SID_ID,
	in_search_term  		IN VARCHAR2,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_total_num_users		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchAllCompanyUsers ( 
	in_search_term  		IN  varchar2,
	in_show_inactive 		IN  NUMBER DEFAULT 0,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchCompanyUsers ( 
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_search_term  		IN  VARCHAR2,
	in_show_inactive 		IN  NUMBER DEFAULT 0,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRegisteredUsers (
	in_company_sid			IN security_pkg.T_SID_ID,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION IsRegisteredUserForCompany (
	in_company_sid			IN security_pkg.T_SID_ID,
	in_user_sid				IN security_pkg.T_SID_ID
) RETURN NUMBER;

PROCEDURE SearchSupplierUsersNoRelation(
	in_supplier_sid			IN security_pkg.T_SID_ID,
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	in_show_inactive 		IN  NUMBER DEFAULT 0,
	in_show_user_companies  IN  NUMBER DEFAULT 0,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_role_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_companies_cur 		OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchAllCompanyUsers ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	in_show_inactive 		IN  NUMBER DEFAULT 0,
	in_show_user_companies  IN  NUMBER DEFAULT 0,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_role_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_companies_cur 		OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchCompanyUsers ( 
	in_company_sid			IN security_pkg.T_SID_ID,
	in_show_inactive 		IN  NUMBER DEFAULT 0,
	in_search_term  		IN  VARCHAR2,
	out_filtered_t			OUT csr.T_USER_FILTER_TABLE,
	out_show_admins			OUT BOOLEAN
);

PROCEDURE SearchCompanyUsers ( 
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_page   				IN  NUMBER,
	in_page_size    		IN  NUMBER,
	in_search_term  		IN  VARCHAR2,
	in_show_inactive 		IN 	NUMBER DEFAULT 0,
	in_show_user_companies  IN  NUMBER DEFAULT 0,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_role_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_companies_cur 		OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchSupplierFollowers (
	in_supplier_sid			IN  security_pkg.T_SID_ID,
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetPrimarySupplierFollower (
	in_supplier_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION GetPrimarySupplierFollower (
	in_supplier_sid			IN  security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID;

PROCEDURE SetPrimarySupplierFollower (
	in_supplier_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
);

FUNCTION UserIsFollower (
	in_supplier_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN NUMBER;

FUNCTION UserIsPrimaryFollower (
	in_supplier_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

PROCEDURE GetAllCompanyUsers (
	in_company_sid_array	IN  security_pkg.T_SID_IDS,
	in_dummy				IN  NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ApproveUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE MakeAdmin (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
);

FUNCTION RemoveAdmin (
	in_company_sid				IN security_pkg.T_SID_ID,
	in_user_sid					IN security_pkg.T_SID_ID,
	in_force_remove_last_admin	IN NUMBER DEFAULT 0
) RETURN NUMBER;

PROCEDURE CheckPasswordComplexity (
	in_email				IN  security_pkg.T_SO_NAME,
	in_password				IN  security_pkg.T_USER_PASSWORD
);

PROCEDURE CompleteRegistration (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE, 
	in_password				IN  Security_Pkg.T_USER_PASSWORD
);

PROCEDURE BeginUpdateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE, 
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE, 
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_visibility_id		IN  chain_user.visibility_id%TYPE, 
	in_email				IN  csr.csr_user.email%TYPE,
	in_send_alerts			IN  csr.csr_user.send_alerts%TYPE,
	in_user_name			IN  csr.csr_user.user_name%TYPE
);

PROCEDURE EndUpdateUser (
	in_user_sid				 IN  security_pkg.T_SID_ID,
	in_modifiied_by_user_sid IN  security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID')
);

FUNCTION IsEmailDomainAllowed(
	in_user_sid		IN  security_pkg.T_SID_ID,
	in_company_sid	IN  security_pkg.T_SID_ID,
	in_email_domain	IN  csr.csr_user.email%TYPE
) RETURN NUMBER;

PROCEDURE UNSEC_SetBusinessUnits (
	in_user_sid						IN	security_pkg.T_SID_ID, 
	in_business_unit_ids			IN	helper_pkg.T_NUMBER_ARRAY
);

PROCEDURE UNSEC_UpdateUser (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE, 
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE, 
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_email				IN  csr.csr_user.email%TYPE,
	in_send_alerts 			IN  csr.csr_user.send_alerts%TYPE,
	in_user_name			IN	csr.csr_user.user_name%TYPE
);

/* Only for batch jobs*/
PROCEDURE AddCompanyTypeRoleToUser(
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID,
	in_role_sid						IN	security_pkg.T_SID_ID
);

PROCEDURE UNSEC_AddCompanyTypeRoleToUser(
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID,
	in_role_sid						IN	security_pkg.T_SID_ID
);

/* Only for batch jobs*/
PROCEDURE RemoveCompanyTypeRoleFromUser(
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID,
	in_role_sid						IN	security_pkg.T_SID_ID
);

PROCEDURE UNSEC_RemoveComTypeRoleFromUsr(
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID,
	in_role_sid						IN	security_pkg.T_SID_ID
);

PROCEDURE SetCompanyTypeRoles (
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID,
	in_role_sids					IN	helper_pkg.T_NUMBER_ARRAY
);

FUNCTION IsUserMarkedAsDeleted(
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN NUMBER;

PROCEDURE DeleteUser (
	in_act					IN	security_pkg.T_ACT_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE DeleteUser (
	in_user_sid				IN  security_pkg.T_SID_ID
);

FUNCTION GetRegistrationStatus (
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN chain_pkg.T_REGISTRATION_STATUS;

FUNCTION GetRegistrationStatusNoCheck (
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN chain_pkg.T_REGISTRATION_STATUS;

PROCEDURE GetUser (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_bu_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_role_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetUser (
	in_user_sid				IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_bu_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_role_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE PreparePasswordReset (
	in_param				IN  VARCHAR2,
	in_accept_guid			IN  security_pkg.T_ACT_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE StartPasswordReset (
	in_guid					IN  security_pkg.T_ACT_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ResetPassword (
	in_guid					IN  security_pkg.T_ACT_ID,
	in_password				IN  Security_pkg.T_USER_PASSWORD,
	out_state_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ResetPassword (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_password				IN  Security_pkg.T_USER_PASSWORD
);

FUNCTION IsUsernameUsed (
	in_user_name				IN	security_pkg.T_SO_NAME,
	in_exclude_user_sid			IN	security_pkg.T_SID_ID DEFAULT NULL
) RETURN NUMBER;

PROCEDURE CheckUsernameAvailability (
	in_user_name			IN	security_pkg.T_SO_NAME,
	in_exclude_user_sid		IN  security_pkg.T_SID_ID DEFAULT NULL
);

FUNCTION IsEmailUsed (
	in_email					IN	csr.csr_user.email%TYPE,
	in_exclude_user_sid			IN	security_pkg.T_SID_ID DEFAULT NULL
) RETURN NUMBER;

PROCEDURE ActivateUser (
	in_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE DeactivateUser (
	in_user_sid				IN  security_pkg.T_SID_ID
);


PROCEDURE ConfirmUserDetails (
	in_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE GetRegUsersForCompany (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE UNSEC_GetAdminsForCompany (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR	
);

FUNCTION IsCompanyAdmin
RETURN NUMBER;

FUNCTION IsCompanyAdmin (
	in_company_sid			IN security_pkg.T_SID_ID,
	in_user_sid				IN security_pkg.T_SID_ID
) RETURN NUMBER;


/*
	[out_result_cur] Returns users by the most significant invitation status
	[out_obo_cur] Returns on behalf of companies for the in_company_sids (case: MnS holding companies)
*/
PROCEDURE GetUsersByInvitationStatus(
	in_company_sids			IN  security_pkg.T_SID_IDS,
	in_is_accepted  		IN NUMBER,
	in_is_active  			IN NUMBER,
	in_is_expired  			IN NUMBER,
	in_is_cancelled 		IN NUMBER,
	in_is_not_invited 		IN NUMBER,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_obo_cur				OUT	security_pkg.T_OUTPUT_CUR
);

/* Used by structured import - supported only for superadmins/built-in admins*/
PROCEDURE GetUserCompaniesAndRoles(
	in_user_sid				IN	security_pkg.T_SID_ID,
	out_companies_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_roles_cur			OUT	security_pkg.T_OUTPUT_CUR
);

END company_user_pkg;
/
