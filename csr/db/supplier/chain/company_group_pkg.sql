CREATE OR REPLACE PACKAGE SUPPLIER.company_group_pkg
IS

SUBTYPE T_GROUP_TYPE				IS NUMBER(10);
GT_COMPANY_ADMIN					CONSTANT T_GROUP_TYPE := 1;

SUBTYPE T_GROUP_NAME				IS SECURITY_PKG.T_SO_NAME;
GN_COMPANY_ADMIN					CONSTANT T_GROUP_NAME := 'Company Admins';


PROCEDURE GetGroupSid (
	in_group_type			IN  T_GROUP_TYPE,
	out_group_sid			OUT security_pkg.T_SID_ID
);

PROCEDURE GetGroupSid (
	in_group_type			IN  T_GROUP_TYPE,
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_group_sid			OUT	security_pkg.T_SID_ID
); 

FUNCTION UserIsMember (
	in_group_type			IN  T_GROUP_TYPE
) RETURN BOOLEAN;

PROCEDURE AddUserToGroup (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_group_type			IN  T_GROUP_TYPE
);

PROCEDURE RemoveUserFromGroup (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_group_type			IN  T_GROUP_TYPE
);

PROCEDURE GetCompanyAdmins (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetUserGroupTypes (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateGroups (
	in_company_sid			IN  security_pkg.T_SID_ID
);

END company_group_pkg;
/