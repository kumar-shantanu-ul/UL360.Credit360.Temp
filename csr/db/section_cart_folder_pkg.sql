CREATE OR REPLACE PACKAGE CSR.section_cart_folder_pkg
IS

FUNCTION GetRootFolderId
RETURN NUMBER;

PROCEDURE GetRootFolder(
	out_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetFolderTreeWithDepth(
	in_parent_id	IN	section_cart_folder.section_cart_folder_id%TYPE,
	in_fetch_depth	IN	NUMBER,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFolderTreeTextFiltered(
	in_parent_id		IN	section_cart_folder.section_cart_folder_id%TYPE,
	in_search_phrase	IN	VARCHAR2,
	in_fetch_depth		IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

-- Get tree with depth OR child is selected
PROCEDURE GetFolderTreeWithSelect(
	in_parent_id	IN	section_cart_folder.section_cart_folder_id%TYPE,
	in_select_id	IN	section_cart_folder.section_cart_folder_id%TYPE,
	in_fetch_depth	IN	NUMBER,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFolderList(
	in_parent_id		IN	section_cart_folder.section_cart_folder_id%TYPE,
	in_search_phrase	IN	VARCHAR2,
	in_fetch_depth		IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateFolder(
	in_parent_id	IN section_cart_folder.parent_id%TYPE,
	in_name			IN section_cart_folder.name%TYPE,
	out_folder_id	OUT section_cart_folder.section_cart_folder_id%TYPE
);

PROCEDURE RenameFolder(
	in_folder_id	IN section_cart_folder.section_cart_folder_id%TYPE,
	in_name			IN section_cart_folder.name%TYPE
);

PROCEDURE MoveFolder(
	in_folder_id	IN section_cart_folder.section_cart_folder_id%TYPE,
	in_parent_id	IN section_cart_folder.parent_id%TYPE
);

PROCEDURE SetFolderVisibility(
	in_folder_id	IN section_cart_folder.section_cart_folder_id%TYPE,
	in_is_visible	IN section_cart_folder.is_visible%TYPE
);

PROCEDURE DeleteFolder(
	in_folder_id	IN section_cart_folder.section_cart_folder_id%TYPE
);

PROCEDURE MoveSectionCart(
	in_cart_id		IN section_cart.section_cart_id%TYPE,
	in_folder_id	IN section_cart.section_cart_folder_id%TYPE
);

PROCEDURE GetCarts(
	in_folder_id	IN section_cart.section_cart_folder_id%TYPE,
	out_cur			OUT	SYS_REFCURSOR
);

END section_cart_folder_pkg;
/