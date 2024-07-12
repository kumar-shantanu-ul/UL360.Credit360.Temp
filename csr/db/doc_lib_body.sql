CREATE OR REPLACE PACKAGE BODY CSR.doc_lib_pkg AS

-- security interface procs
PROCEDURE CreateObject(
	in_act					IN security_pkg.T_ACT_ID, 
	in_sid_id				IN security_pkg.T_SID_ID, 
	in_class_id				IN security_pkg.T_CLASS_ID, 
	in_name					IN security_pkg.T_SO_NAME, 
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act					IN security_pkg.T_ACT_ID, 
	in_sid_id				IN security_pkg.T_SID_ID, 
	in_new_name				IN security_pkg.T_SO_NAME
)
AS
BEGIN
	NULL;
END;

-- delete
PROCEDURE DeleteObject(
	in_act					IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
	v_documents_sid				security_pkg.T_SID_ID;
	v_trash_folder_sid			security_pkg.T_SID_ID;
BEGIN
	-- Note we just orphan documents, basically in case somebody ends up
	-- wanting them back after destruction time.

	-- Grab the special folders for later clean up
	SELECT documents_sid, trash_folder_sid
	  INTO v_documents_sid, v_trash_folder_sid
	  FROM doc_library
	 WHERE doc_library_sid = in_sid_id;

	UPDATE teamroom
	   SET doc_library_sid = null
	 WHERE doc_library_sid = in_sid_id;

	UPDATE initiative
	   SET doc_library_sid = null
	 WHERE doc_library_sid = in_sid_id;
	 
	DELETE FROM doc_type
	 WHERE doc_library_sid = in_sid_id;

	-- Kill the library
	DELETE FROM doc_library
	 WHERE doc_library_sid = in_sid_id;

	UPDATE section_module
	   SET library_sid = null
	 WHERE library_sid = v_documents_sid;
	 
	-- And finally clean up the special folders
	DELETE FROM doc_folder_name_translation
	 WHERE doc_folder_sid IN (v_documents_sid, v_trash_folder_sid);

	 DELETE FROM doc_folder
	 WHERE doc_folder_sid IN (v_documents_sid, v_trash_folder_sid);
END;

PROCEDURE MoveObject(
	in_act					IN security_pkg.T_ACT_ID, 
	in_sid_id				IN security_pkg.T_SID_ID, 
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE CreateLibrary(
	in_parent_sid_id			IN	security_pkg.T_SID_ID,
	in_library_name				IN	security_pkg.T_SO_NAME,
	in_documents_name			IN	security_pkg.T_SO_NAME,
	in_trash_name				IN	security_pkg.T_SO_NAME,
	in_app_sid				IN	security_pkg.T_SID_ID,
	out_doc_library_sid			OUT	security_pkg.T_SID_ID
)
AS
	v_documents_sid				security_pkg.T_SID_ID;
	v_trash_folder_sid			security_pkg.T_SID_ID;
BEGIN
	securableObject_pkg.CreateSO(security_pkg.GetACT(), in_parent_sid_id, 
		class_pkg.GetClassId('DocLibrary'), in_library_name, out_doc_library_sid);
	
	doc_folder_pkg.CreateFolder(
		in_parent_sid			=> out_doc_library_sid, 
		in_name					=> in_documents_name,
		in_is_system_managed	=> 1,
		out_sid_id				=> v_documents_sid
	);

	doc_folder_pkg.CreateFolder(
		in_parent_sid			=> out_doc_library_sid, 
		in_name					=> in_trash_name,
		in_is_system_managed	=> 1,
		out_sid_id				=> v_trash_folder_sid
	);

	INSERT INTO doc_library (app_sid, doc_library_sid, documents_sid, trash_folder_sid)
	VALUES (in_app_sid, out_doc_library_sid, v_documents_sid, v_trash_folder_sid);
END;

PROCEDURE GetLibraries(
	in_app_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT dl.doc_library_sid, dl.documents_sid, dl.trash_folder_sid, so.name
		  FROM doc_library dl
		  JOIN security.securable_object so
		    ON so.sid_id = dl.doc_library_sid
		 WHERE app_sid = in_app_sid AND 
		 	   security_pkg.SQL_IsAccessAllowedSid(security_pkg.GetACT(), doc_library_sid, security_pkg.PERMISSION_READ) = 1;
END;

PROCEDURE GetLibrary(
	in_doc_library_sid	IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT(), in_doc_library_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 
			'Access denied reading the document library with sid '||in_doc_library_sid);
	END IF;
	OPEN out_cur FOR
		SELECT doc_library_sid, documents_sid, trash_folder_sid, app_sid
		  FROM doc_library
		 WHERE doc_library_sid = in_doc_library_sid;
END;

PROCEDURE GetDefaultDocLib(
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_def_doc_lib_sid		security_pkg.T_SID_ID;
BEGIN
	v_def_doc_lib_sid := security.securableobject_pkg.GetSidFromPath(
							security.security_pkg.GetAct,
							security.security_pkg.GetApp,
							'Documents'
						 );
	GetLibrary(v_def_doc_lib_sid, out_cur);
END;

PROCEDURE GetDocumentTypes(
	in_doc_library_sid				IN	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT doc_type_id, name 
		  FROM doc_type
		 WHERE doc_library_sid = in_doc_library_sid;
END;

PROCEDURE AssertCanManageDocTypes
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin != 1 THEN
		RAISE_APPLICATION_ERROR(
			security.security_pkg.ERR_ACCESS_DENIED, 
			'Access denied configuring document types. This feature is only available to super admins.'
		);
	END IF;
END;

PROCEDURE CreateDocumentType(
	in_doc_library_sid				IN	security_pkg.T_SID_ID,
	in_name							IN doc_type.name%TYPE,
	out_doc_type_id					OUT doc_type.doc_type_id%TYPE
)
AS
BEGIN
	AssertCanManageDocTypes;

	INSERT INTO doc_type (doc_type_id, name, doc_library_sid)
	VALUES (doc_type_id_seq.NEXTVAL, in_name, in_doc_library_sid)
	RETURNING doc_type_id INTO out_doc_type_id;
END;

PROCEDURE UpdateDocumentType(
	in_doc_type_id					IN doc_type.doc_type_id%TYPE,
	in_name							IN doc_type.name%TYPE
)
AS
BEGIN
	AssertCanManageDocTypes;

	UPDATE doc_type 
	   SET name = in_name
	 WHERE doc_type_id = in_doc_type_id;
END;

PROCEDURE DeleteDocumentType(
	in_doc_type_id					IN doc_type.doc_type_id%TYPE
)
AS
BEGIN
	AssertCanManageDocTypes;

	DELETE FROM doc_type 
	 WHERE doc_type_id = in_doc_type_id;
END;

END doc_lib_pkg;
/
