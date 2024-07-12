CREATE OR REPLACE PACKAGE CSR.role_pkg AS


-- Securable object callbacks
/**
 * CreateObject
 * 
 * @param in_act_id				Access token
 * @param in_sid_id				The sid of the object
 * @param in_class_id			The class Id of the object
 * @param in_name				The name
 * @param in_parent_sid_id		The sid of the parent object
 */
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

/**
 * RenameObject
 * 
 * @param in_act_id			Access token
 * @param in_sid_id			The sid of the object
 * @param in_new_name		The name
 */
PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

/**
 * DeleteObject
 * 
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 */
PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

/**
 * MoveObject
 * 
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 * @param in_new_parent_sid_id		.
 */
PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

FUNCTION WriteAccessAllowed(
	in_role_sid		IN	security_pkg.T_SID_ID
) RETURN NUMBER;

FUNCTION WriteAccessAllowed(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_role_sid		IN	security_pkg.T_SID_ID
) RETURN NUMBER;

PROCEDURE GrantRole(
	in_role_sid				IN	security_pkg.T_SID_ID,
	in_grant_role_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE GetRoleGrants(
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRoles(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRoles(
	in_is_metering			IN	role.is_metering%TYPE,
	in_is_property_manager	IN	role.is_property_manager%TYPE,
	in_is_supplier			IN	role.is_supplier%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRole(
	in_role_sid				IN	security_pkg.T_SID_ID,
	out_role_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_roots_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRoleMembersForRegion(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllRoleMembersForRegion(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRoleMembersForUser(
	in_user_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRoleMembersForUser(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_user_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetGrantRoleMembersForUser(
	in_user_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllRoleMembersForUser(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_user_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetRoleID(
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_role_name		IN	role.name%TYPE
) RETURN role.role_sId%TYPE;

FUNCTION GetRoleIdByKey (
	in_lookup_key					IN  role.lookup_key%TYPE
) RETURN role.role_sid%TYPE;

PROCEDURE GetAllRoleMemberships(
	out_cur		OUT SYS_REFCURSOR
);

PROCEDURE SetRole(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_role_name		IN	role.name%TYPE,
	out_role_sid			OUT	role.role_sid%TYPE
);

PROCEDURE SetRole(
	in_role_name					IN 	role.name%TYPE,
	out_role_sid					OUT	role.role_sid%TYPE
);

PROCEDURE SetRole(
	in_role_name					IN 	role.name%TYPE,
	in_lookup_key					IN 	role.lookup_key%TYPE,
	out_role_sid					OUT	role.role_sid%TYPE
);

PROCEDURE SetRole(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		    IN	security_pkg.T_SID_ID,
	in_role_name		IN	role.name%TYPE,
	in_lookup_key		IN 	role.lookup_key%TYPE,
	out_role_sid		OUT	role.role_sid%TYPE
);

PROCEDURE UpdateRole(
	in_role_sid		IN	security_pkg.T_SID_ID,
	in_new_name		IN	security_pkg.T_SO_NAME,
	in_lookup_key	IN	csr.role.lookup_key%TYPE,
	in_grant_sids	IN	security_pkg.T_SID_IDS
);

PROCEDURE UpdateRole(
	in_role_sid						IN	role.role_sid%TYPE,
	in_role_name					IN	role.name%TYPE,
	in_lookup_key					IN	role.lookup_key%TYPE
);

PROCEDURE SetRoleFlags(
	in_role_sid					IN	role.role_sid%TYPE,
	in_is_metering					IN	role.is_metering%TYPE DEFAULT NULL,
	in_is_property_manager			IN	role.is_property_manager%TYPE DEFAULT NULL,
	in_is_delegation				IN	role.is_delegation%TYPE DEFAULT NULL,
	in_is_supplier					IN	role.is_supplier%TYPE DEFAULT NULL
);

PROCEDURE ResynchACEs(
	in_act_id		security_pkg.T_ACT_ID,
	in_role_sid		security_pkg.T_SID_ID
);

PROCEDURE AddRoleMemberForRegion(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_role_sid		IN	role.role_sid%TYPE,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_user_sid 	IN	security_pkg.T_SID_ID,
	in_log			IN  NUMBER DEFAULT 0,
	in_force_alter_system_managed	IN NUMBER DEFAULT 0,
	in_inherited_from_sid		IN	security_pkg.T_SID_ID DEFAULT NULL
);

PROCEDURE AddRoleMemberForRegion(
	in_role_sid		IN	role.role_sid%TYPE,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_user_sid 	IN	security_pkg.T_SID_ID,
	in_log			IN  NUMBER DEFAULT 0
);

PROCEDURE AddRoleMemberForRegion_UNSEC(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_role_sid		IN	role.role_sid%TYPE,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_user_sid 	IN	security_pkg.T_SID_ID,
	in_log			IN  NUMBER DEFAULT 0,
	in_force_alter_system_managed	IN NUMBER DEFAULT 0,
	in_inherited_from_sid		IN	security_pkg.T_SID_ID DEFAULT NULL
);

PROCEDURE UNSEC_DeleteRegionRoleMember(
	in_act_id		IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_role_sid		IN	role.role_sid%TYPE,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_user_sid		IN	security_pkg.T_SID_ID,
	in_log			IN	NUMBER DEFAULT 0,
	in_check_permissions	IN	BOOLEAN DEFAULT FALSE
);

PROCEDURE DeleteRegionRoleMember(
	in_act_id		IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_role_sid		IN	role.role_sid%TYPE,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_user_sid		IN	security_pkg.T_SID_ID,
	in_log			IN	NUMBER DEFAULT 0,
	in_force_alter_system_managed IN NUMBER DEFAULT 0
);

-- Removes all of the user's roles for the specified region
PROCEDURE DeleteRolesFromRegionForUser(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_user_sid		IN	security_pkg.T_SID_ID,
	in_region_sid	IN	security_pkg.T_SID_ID
);

-- Removes all of the user's role memberships for the specified role
PROCEDURE DeleteRegionsFromRoleForUser(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_user_sid		IN	security_pkg.T_SID_ID,
	in_role_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE UNSEC_DeleteAllRolesFromUser(
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_user_sid					IN	security_pkg.T_SID_ID,
	in_include_system_managed	IN NUMBER DEFAULT 0
);

PROCEDURE DeleteAllRolesFromUser(
	in_user_sid					IN	security_pkg.T_SID_ID,
	in_include_system_managed	IN NUMBER DEFAULT 0
);

PROCEDURE SetRoleMembersForRegion(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_role_sid		IN	role.role_sid%TYPE,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_user_sids	IN	security_pkg.T_SID_IDS
);

/* takes a string of comma separated sids */
PROCEDURE SetRoleMembersForUser(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_role_sid		IN	role.role_sid%TYPE,
	in_user_sid		IN	security_pkg.T_SID_ID,
	in_region_sids	IN	VARCHAR2
);

PROCEDURE SetRoleMembersForUser(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_role_sid		IN	role.role_sid%TYPE,
	in_user_sid	IN	security_pkg.T_SID_ID,
	in_region_sids	IN	security_pkg.T_SID_IDS
);

PROCEDURE GetUserRoles(
	in_user_sid			IN	csr_user.csr_user_sid%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetUserRoleRegions(
	in_role_name		IN	role.name%TYPE,
	in_roots_only		IN  NUMBER DEFAULT 0,	
	out_cur				OUT	SYS_REFCURSOR
);

-- another version -- this is sid based and uses region_type
PROCEDURE GetUserRoleRegions(
	in_role_sid		IN	security_pkg.T_SID_ID,
	in_region_type	IN	region.region_type%TYPE,
	in_roots_only	IN  NUMBER DEFAULT 0,	
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE PropagateRoleMembership (
	in_role_sid		IN	security_pkg.T_SID_ID,
	in_region_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE GetPropertyManagerRoleRegions(
	out_role_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AssignToTaggedRoleDelegations(
	in_role_name		IN	role.name%TYPE,
	in_tag_group_name	IN	tag_group_description.name%TYPE,
	in_region_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE GetRoleGrantedRoleMembers(
	in_role_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetRoleGrantedRoleMembers(
	in_role_sid		IN	security_pkg.T_SID_ID,
	in_grant_sids   IN  security_pkg.T_SID_IDS
);

PROCEDURE GetGroupMemberRolesAndGroups(
	in_group_sid_id		IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetGroupGrantedRoleMembers(
	in_group_sid_id		IN	security_pkg.T_SID_ID,
	in_role_sids		IN  security_pkg.T_SID_IDS
);

PROCEDURE GetRoleUserRegions(
	in_role_sid			IN	security_pkg.T_SID_ID,
	in_grp_sid			IN	security_pkg.T_SID_ID,
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	out_total_rows		OUT	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
);

FUNCTION IsUserInRole(
	in_role_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION Sql_IsUserInRole(
	in_role_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID
) RETURN NUMBER;

PROCEDURE GetRoleGrantsForExport(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetAllMembersForRegionByRole (
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_region_sid				IN  security_pkg.T_SID_ID,
	in_role_sids				IN  security_pkg.T_SID_IDS,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE AllowAlterSystemManagedRole;

END role_pkg;
/
