CREATE OR REPLACE PACKAGE CSR.doc_folder_pkg
IS

-- security interface procs
PROCEDURE CreateObject(
	in_act					IN security_pkg.T_ACT_ID, 
	in_sid_id				IN security_pkg.T_SID_ID, 
	in_class_id				IN security_pkg.T_CLASS_ID, 
	in_name					IN security_pkg.T_SO_NAME, 
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act					IN security_pkg.T_ACT_ID, 
	in_sid_id				IN security_pkg.T_SID_ID, 
	in_new_name				IN security_pkg.T_SO_NAME
);

-- delete
PROCEDURE DeleteObject(
	in_act					IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act					IN security_pkg.T_ACT_ID, 
	in_sid_id				IN security_pkg.T_SID_ID, 
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

FUNCTION SQL_IsAccessAllowed (
	in_folder_sid					IN  security_pkg.T_SID_ID,
	in_permission_set				IN  security_Pkg.T_PERMISSION	
) RETURN NUMBER;

PROCEDURE CheckFolderAccess (
	in_folder_sid					IN  security_pkg.T_SID_ID,
	in_permission_set				IN  security_Pkg.T_PERMISSION	
);

PROCEDURE PopulateTempTreeWithFolders (
	in_parent_sid					IN  security_pkg.T_SID_ID,
	in_fetch_depth					IN  NUMBER DEFAULT NULL,
	in_limit						IN  NUMBER DEFAULT NULL,
	in_hide_root					IN  NUMBER DEFAULT 0
);

PROCEDURE CreateFolder(
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_name							IN	security_pkg.T_SO_NAME,
	in_description					IN	doc_folder.description%TYPE DEFAULT EMPTY_CLOB(),
	in_approver_is_override			IN	doc_folder.approver_is_override%TYPE DEFAULT 0,
	in_approver_sid					IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_lifespan_is_override			IN	doc_folder.lifespan_is_override%TYPE DEFAULT 0,
	in_lifespan						IN	doc_folder.lifespan%TYPE DEFAULT NULL,
	in_company_sid					IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_property_sid					IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_is_system_managed			IN	doc_folder.is_system_managed%TYPE DEFAULT 0,
	in_permit_item_id				IN  security_pkg.T_SID_ID DEFAULT NULL,
	out_sid_id						OUT	security_pkg.T_SID_ID
);

PROCEDURE CreateFolderTree(
	in_parent_sid_id		IN	security_pkg.T_SID_ID,
	in_path					IN	VARCHAR2,
	out_sid_id				OUT security_pkg.T_SID_ID
);

PROCEDURE UpdateFolder(
	in_folder_sid			IN	security_pkg.T_SID_ID,
	in_folder_name			IN	security_pkg.T_SO_NAME,
	in_description			IN	doc_folder.description%TYPE,
	in_approver_is_override	IN	doc_folder.approver_is_override%TYPE,
	in_approver_sid			IN	security_pkg.T_SID_ID,
	in_lifespan_is_override	IN	doc_folder.lifespan_is_override%TYPE,
	in_lifespan				IN	doc_folder.lifespan%TYPE
);

FUNCTION GetDocumentsFolder(
	in_doc_library_sid				IN	security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID;

PROCEDURE UNSEC_DeleteFolder(
	in_folder_sid			IN	security_pkg.T_SID_ID,
	in_deleted_text			IN	VARCHAR2,
	out_trash_count			OUT	NUMBER
);

PROCEDURE DeleteFolder(
	in_folder_sid			IN	security_pkg.T_SID_ID,
	in_deleted_text			IN	VARCHAR2,
	out_trash_count			OUT	NUMBER
);

PROCEDURE MoveFolder(
	in_folder_sid			IN	security_pkg.T_SID_ID,
	in_new_parent_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE GetDetails(
	in_folder_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetTreeWithDepth(
	in_parent_sid	IN	security_pkg.T_SID_ID,
	in_fetch_depth	IN	NUMBER,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTreeWithSelect(
	in_act_id   	IN  security_pkg.T_ACT_ID,
	in_parent_sid	IN	security_pkg.T_SID_ID,
	in_select_sid	IN	security_pkg.T_SID_ID,
	in_fetch_depth	IN	NUMBER,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION GetRootFolder(
	in_folder_sid			IN	security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID;
PRAGMA RESTRICT_REFERENCES(GetRootFolder, WNDS, WNPS, RNPS);

FUNCTION GetTrashFolder(
	in_folder_sid			IN	security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID;
PRAGMA RESTRICT_REFERENCES(GetTrashFolder, WNDS, WNPS, RNPS);

FUNCTION GetLibraryContainer(
	in_folder_sid			IN	security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID;
PRAGMA RESTRICT_REFERENCES(GetLibraryContainer, WNDS, WNPS, RNPS);

FUNCTION IsSpecialFolder(
	in_folder_sid			IN	security_pkg.T_SID_ID
) RETURN BOOLEAN;
PRAGMA RESTRICT_REFERENCES(IsSpecialFolder, WNDS, WNPS, RNPS);

FUNCTION GetTrashIcon(
	in_trash_folder_sid		IN	security_pkg.T_SID_ID
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(GetTrashIcon, WNDS, WNPS);

FUNCTION GetTrashCount(
	in_trash_folder_sid		IN	security_pkg.T_SID_ID
) RETURN NUMBER;
PRAGMA RESTRICT_REFERENCES(GetTrashCount, WNDS, WNPS);

PROCEDURE GetTreeTextFiltered(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_parent_sid		IN	security_pkg.T_SID_ID,
	in_search_phrase	IN	VARCHAR2,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetList(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_documents_sid	IN	security_pkg.T_SID_ID,
	in_limit			IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetListTextFiltered(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_documents_sid	IN	security_pkg.T_SID_ID,
	in_search_phrase	IN	VARCHAR2,
	in_limit			IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFolderTranslation(
	in_folder_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE SetFolderTranslation(
	in_folder_sid			IN	security_pkg.T_SID_ID,
	in_lang					IN	aspen2.tr_pkg.T_LANG,
	in_translated			IN	VARCHAR2
);

FUNCTION GetFolderName(
	in_folder_sid			IN	security_pkg.T_SID_ID
) RETURN VARCHAR2;

-- only here for restrict_references
FUNCTION GetTranslation(
	in_text					IN	VARCHAR2
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(GetTranslation, RNPS, WNDS, WNPS);

PROCEDURE FinaliseSave(
	in_parent_sid			IN  security_pkg.T_SID_ID, 
	in_filename				IN  VARCHAR2
);

PROCEDURE FinaliseDelete(
	in_parent_sid			IN  security_pkg.T_SID_ID, 
	in_filename				IN  VARCHAR2
);

END doc_folder_pkg;
/
