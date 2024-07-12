CREATE OR REPLACE PACKAGE CSR.doc_lib_pkg AS

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

PROCEDURE CreateLibrary(
	in_parent_sid_id			IN	security_pkg.T_SID_ID,
	in_library_name				IN	security_pkg.T_SO_NAME,
	in_documents_name			IN	security_pkg.T_SO_NAME,
	in_trash_name				IN	security_pkg.T_SO_NAME,
	in_app_sid				IN	security_pkg.T_SID_ID,
	out_doc_library_sid			OUT	security_pkg.T_SID_ID
);

PROCEDURE GetLibraries(
	in_app_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetLibrary(
	in_doc_library_sid	IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetDefaultDocLib(
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetDocumentTypes(
	in_doc_library_sid				IN	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE CreateDocumentType(
	in_doc_library_sid				IN	security_pkg.T_SID_ID,
	in_name							IN doc_type.name%TYPE,
	out_doc_type_id					OUT doc_type.doc_type_id%TYPE
);

PROCEDURE UpdateDocumentType(
	in_doc_type_id					IN doc_type.doc_type_id%TYPE,
	in_name							IN doc_type.name%TYPE
);

PROCEDURE DeleteDocumentType(
	in_doc_type_id					IN doc_type.doc_type_id%TYPE
);

END doc_lib_pkg;
/
