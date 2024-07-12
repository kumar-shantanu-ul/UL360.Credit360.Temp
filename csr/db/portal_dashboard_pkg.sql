CREATE OR REPLACE PACKAGE CSR.portal_dashboard_pkg AS

/**
 * CreateObject helper
 * 
 * @param in_act_id			Access token
 * @param in_sid_id			The sid of the object
 * @param in_class_id		The class Id of the object
 * @param in_name			The name
 * @param in_parent_sid_id	The sid of the parent object
 */
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

/**
 * RenameObject helper
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
 * DeleteObject helper
 * 
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 */
PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

/**
 * MoveObject helper
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

PROCEDURE GetFolderPath(
	in_folder_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetChildDashboards(
	in_parent_sid	IN security_pkg.T_SID_ID,
	out_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetDashboardList(
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetDashboard(
	in_portal_sid			IN	PORTAL_DASHBOARD.portal_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetGroups(
	in_sid					IN	security_pkg.T_SID_ID,
	out_groups_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetDashboardAndMenu(
	in_portal_sid				IN	PORTAL_DASHBOARD.portal_sid%TYPE,
	out_dashboard_cur			OUT	SYS_REFCURSOR,
	out_menu_cur				OUT	SYS_REFCURSOR,
	out_menu_groups_cur			OUT SYS_REFCURSOR,
	out_dashboard_groups_cur	OUT SYS_REFCURSOR
);

PROCEDURE CreateDashboard(
	in_dashboard_container_sid		IN	security_pkg.T_SID_ID,
	in_label						IN	PORTAL_DASHBOARD.portal_group%TYPE,
	in_message						IN	PORTAL_DASHBOARD.message%TYPE,
	in_parent_menu_sid				IN	PORTAL_DASHBOARD.menu_sid%TYPE,
	in_menu_label					IN	VARCHAR2,
	in_menu_group_sids				IN	security_pkg.T_SID_IDS,
	in_dashboard_group_sids			IN	security_pkg.T_SID_IDS,
	out_dashboard_sid				OUT	PORTAL_DASHBOARD.portal_sid%TYPE
);

PROCEDURE UpdateDashboard(
	in_dashboard_sid				IN	PORTAL_DASHBOARD.portal_sid%TYPE,
	in_label						IN	PORTAL_DASHBOARD.portal_group%TYPE,
	in_message						IN	PORTAL_DASHBOARD.message%TYPE,
	in_parent_menu_sid				IN	PORTAL_DASHBOARD.menu_sid%TYPE,
	in_menu_label					IN	VARCHAR2,
	in_menu_group_sids				IN	security_pkg.T_SID_IDS,
	in_dashboard_group_sids			IN	security_pkg.T_SID_IDS
);

PROCEDURE UpdateDashboardContainerPerms(
	in_dashboard_container_sid		IN	security_pkg.T_SID_ID,
	in_dashboard_group_sids			IN	security_pkg.T_SID_IDS
);
PROCEDURE ClearMenuPerms(
	in_menu_sid						IN	security_pkg.T_SID_ID,
	in_dashboard_sid				IN	security_pkg.T_SID_ID,
	in_menu_group_sids				IN	security_pkg.T_SID_IDS
);
PROCEDURE ClearAllPerms(
	in_sid							IN	security_pkg.T_SID_ID
);
PROCEDURE AddDashboardPerms(
	in_dashboard_sid				IN	PORTAL_DASHBOARD.portal_sid%TYPE,
	v_menu_sid						IN	security_pkg.T_SID_ID
);
PROCEDURE RemoveDashboardPerms(
	in_dashboard_sid				IN	PORTAL_DASHBOARD.portal_sid%TYPE,
	v_menu_sid						IN	security_pkg.T_SID_ID
);
PROCEDURE AddGroupPerms(
	in_sid							IN	security_pkg.T_SID_ID,
	in_group_sids					IN	security_pkg.T_SID_IDS
);

FUNCTION MakeMenuObjectName(
	in_portal_group				IN	VARCHAR2
) RETURN VARCHAR2;

FUNCTION MakeMenuURL(
	in_dashboard_sid				IN	PORTAL_DASHBOARD.portal_sid%TYPE
) RETURN VARCHAR2;

END;
/
