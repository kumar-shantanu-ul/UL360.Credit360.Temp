CREATE OR REPLACE PACKAGE ACTIONS.role_pkg AS

PROCEDURE GetRoles(
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRoleMembers(
	in_role_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRoleMembers(
	in_role_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllRoleMembers(
	in_role_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddProjectRoleMember(
	in_role_sid		IN	security_pkg.T_SID_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_project_sid	IN	security_pkg.T_SID_ID,
	in_user_sid 	IN	security_pkg.T_SID_ID
);

PROCEDURE DeleteProjectRoleMember(
	in_role_sid		IN	security_pkg.T_SID_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_project_sid	IN	security_pkg.T_SID_ID,
	in_user_sid 	IN	security_pkg.T_SID_ID
);

PROCEDURE SetProjectRoleMembers(
	in_role_sid		IN	security_pkg.T_SID_ID,
	in_region_sids	IN	security_pkg.T_SID_IDS,
	in_project_sids	IN	security_pkg.T_SID_IDS,
	in_user_sids	IN	security_pkg.T_SID_IDS
);


END role_pkg;
/
