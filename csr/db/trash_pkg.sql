CREATE OR REPLACE PACKAGE CSR.trash_pkg AS

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


-- returns 1 or 0 
FUNCTION IsInTrash(
	in_act_id			IN	security_pkg.T_ACT_ID,
    in_object_sid		IN	security_pkg.T_SID_ID
)  RETURN NUMBER;

-- returns 1 or 0 
-- Checks for the object sid or one of the parent containers of object sid being in the trash.
FUNCTION IsInTrashHierarchical(
	in_act_id			IN	security_pkg.T_ACT_ID,
    in_object_sid		IN	security_pkg.T_SID_ID
)  RETURN NUMBER;


/**
 * TrashObject
 * 
 * @param in_act_id				Access token
 * @param in_object_sid			.
 * @param in_trash_can_sid		.
 * @param in_description		The description
 */
PROCEDURE TrashObject(
	in_act_id			IN	security_pkg.T_ACT_ID,
    in_object_sid		IN	security_pkg.T_SID_ID,
    in_trash_can_sid	IN	security_pkg.T_SID_ID,
    in_description		IN	trash.description%TYPE
);


/**
 * Restore the given objects from the trash
 * 
 * @param in_object_sids			Sids of the objects to restore	.
 */
PROCEDURE RestoreObjects(
    in_object_sids					IN	security_pkg.T_SID_IDS
);

/**
 * List the contents of a trash can
 *
 * @param in_trash_can_sid			Sid of the trash can to list the contents of
 * @param in_class_id				SO class id to filter to
 * @param in_order_by				Columns to order by
 * @param in_start_row				First row to return
 * @param in_page_size				Number of rows to return
 * @param out_total_rows			The total number of rows that match the filter
 * @param out_cur					The trash can contents
 */
PROCEDURE GetTrashList(
    in_trash_can_sid				IN	security_pkg.T_SID_ID,
	in_class_name					IN  security_pkg.T_CLASS_NAME,
	in_order_by 					IN 	VARCHAR2,
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	out_total_rows					OUT	NUMBER,
    out_cur							OUT	SYS_REFCURSOR
);

/**
 * Empties the trash (absolutely deleting stuff - no going back)
 * 
 * @param in_act_id					Access token
 * @param in_app_sid			Root sid
 */
PROCEDURE EmptyTrash(
	in_act_id				IN	security_pkg.T_ACT_ID,
    in_app_sid				IN	security_pkg.T_SID_ID,
	in_commit_every_rec		IN	NUMBER	DEFAULT 0
);

PROCEDURE RemoveTagGroupFromRegion (
	in_sid						IN	NUMBER,
	in_tag_group_id				IN	NUMBER,
	out_rows_updated			OUT	NUMBER
);

PROCEDURE RemoveTagGroupFromRegions (
	in_tag_group_id				IN	NUMBER,
	out_rows_updated			OUT	NUMBER
);

PROCEDURE RemoveTagFromRegion (
	in_sid						IN	NUMBER,
	in_tag_group_id				IN	NUMBER,
	in_tag_id					IN	NUMBER,
	out_rows_updated			OUT	NUMBER
);

PROCEDURE RemoveTagFromRegions (
	in_tag_group_id				IN	NUMBER,
	in_tag_id					IN	NUMBER,
	out_rows_updated			OUT	NUMBER
);

PROCEDURE RemoveLookupKeyFromRegions (
	in_lookup_key			IN	region.lookup_key%TYPE,
	out_rows_updated		OUT	NUMBER
);

PROCEDURE RemoveTagGroupFromIndicator (
	in_sid						IN	NUMBER,
	in_tag_group_id				IN	NUMBER,
	out_rows_updated			OUT	NUMBER
);

PROCEDURE RemoveTagGroupFromIndicators (
	in_tag_group_id				IN	NUMBER,
	out_rows_updated			OUT	NUMBER
);

PROCEDURE RemoveTagFromIndicator (
	in_sid						IN	NUMBER,
	in_tag_group_id				IN	NUMBER,
	in_tag_id					IN	NUMBER,
	out_rows_updated			OUT	NUMBER
);

PROCEDURE RemoveTagFromIndicators (
	in_tag_group_id				IN	NUMBER,
	in_tag_id					IN	NUMBER,
	out_rows_updated			OUT	NUMBER
);

PROCEDURE RemoveLookupKeyFromIndicators (
	in_lookup_key			IN	ind.lookup_key%TYPE,
	out_rows_updated		OUT	NUMBER
);

END trash_pkg;
/
