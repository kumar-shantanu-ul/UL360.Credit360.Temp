CREATE OR REPLACE PACKAGE SUPPLIER.company_user_pkg
IS

SUBTYPE T_CU_AUTHORIZED_STATE	IS COMPANY_USER.PENDING_COMPANY_AUTHORIZATION%TYPE;
USER_IS_AUTHORIZED				CONSTANT T_CU_AUTHORIZED_STATE := 0;
USER_IS_NOT_AUTHORIZED			CONSTANT T_CU_AUTHORIZED_STATE := 1;

SUBTYPE T_CU_VISIBILITY_STATE	IS COMPANY_USER.USER_PROFILE_VISIBILITY_ID%TYPE;
FULLY_HIDDEN					CONSTANT T_CU_VISIBILITY_STATE := 0;
HIDDEN							CONSTANT T_CU_VISIBILITY_STATE := 1;
SHOW_JOB_TITLE					CONSTANT T_CU_VISIBILITY_STATE := 2;
SHOW_NAME_JOB_TITLE				CONSTANT T_CU_VISIBILITY_STATE := 3;
SHOW_ALL						CONSTANT T_CU_VISIBILITY_STATE := 4;


PROCEDURE AddSuperUsersToAllCompanies;

PROCEDURE AddSuperUsersToCompany (
	in_company_sid			IN security_pkg.T_SID_ID
);

FUNCTION UserIsAuthorized (
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_company_sid				IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

PROCEDURE AuthorizeUser (
	in_user_sid					IN  security_pkg.T_SID_ID
);

PROCEDURE GetUser (
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetUser (
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetUserCompanies (
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddUserToCompany (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_pending_authorization	IN  T_CU_AUTHORIZED_STATE
);

PROCEDURE GetCompanyUsers (
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE AmendUser (
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_full_name				IN  csr.csr_user.full_name%TYPE,
	in_email					IN  csr.csr_user.email%TYPE,
	in_job_title				IN  csr.csr_user.job_title%TYPE,
	in_phone_number				IN  csr.csr_user.phone_number%TYPE
);

PROCEDURE SetPrivacy (
	in_visibility				IN  T_CU_VISIBILITY_STATE
);

PROCEDURE SetPrivacy (
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_visibility				IN  T_CU_VISIBILITY_STATE
);

PROCEDURE AddUserToAllCompanies (
	in_user_sid					IN security_pkg.T_SID_ID DEFAULT security_pkg.GetSid()
);

END company_user_pkg;
/


