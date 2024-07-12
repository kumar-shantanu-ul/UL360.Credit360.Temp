CREATE OR REPLACE PACKAGE BODY CSR.doc_folder_pkg 
IS

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

-- not public, used by DeleteSO
PROCEDURE DeleteDocUNSECURE(
	in_doc_id				IN	doc.doc_id%TYPE
)
AS
	v_parent_sid		security_pkg.T_SID_ID;
	v_version			doc_version.version%TYPE;
	v_doc_filename		VARCHAR2(255);
BEGIN
	BEGIN
		SELECT parent_sid, 1 + version
		  INTO v_parent_sid, v_version
		  FROM doc_current
		 WHERE doc_id = in_doc_id FOR UPDATE;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 
				'The document with id '||in_doc_id||' could not be found.');
	END;
	
	-- stuff in a revision that tells who deleted the document
	INSERT INTO doc_version (doc_id, version, filename, description, change_description, 
		changed_by_sid, changed_dtm, doc_data_id)
		SELECT doc_id, v_version, filename, description, GetTranslation('Deleted'), security_pkg.GetSID(), 
		       systimestamp, doc_data_id
		  FROM doc_version
		 WHERE doc_id = in_doc_id AND version = v_version - 1;
			
	-- Move the document to the trash + unlock
	UPDATE doc_current
	   SET parent_sid = doc_folder_pkg.GetTrashFolder(parent_sid),
		   version = v_version, locked_by_sid = security_pkg.GetSID()
	 WHERE doc_id = in_doc_id;
	 
	SELECT filename
	  INTO v_doc_filename
	  FROM doc_version
	 WHERE doc_id = in_doc_id
	   AND version = v_version;
	 
	FinaliseDelete(
 		in_parent_sid			=>  v_parent_sid, 
 		in_filename				=>  v_doc_filename
 	);
END;

-- delete
PROCEDURE DeleteObject(
	in_act					IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN
	-- if we are deleting the trash folder (and probably the whole library therefore)
	-- then we empty it instead of trying to move documents to the trash.
	IF GetTrashFolder(in_sid_id) = in_sid_id THEN
		DELETE FROM temp_doc_id;
		INSERT INTO temp_doc_id (doc_id)
			SELECT doc_id
			  FROM doc_current
		 	 WHERE parent_sid = in_sid_id;
		doc_pkg.DeleteDocsINTERNAL;
	ELSE
		FOR r IN (SELECT doc_id
					FROM doc_current
				   WHERE parent_Sid = in_sid_id) LOOP
			DeleteDocUNSECURE(r.doc_id);
		END LOOP;
	END IF;
	-- We can't delete this if it's a special folder, so just leave the row
	-- hanging around.  Generally this occurs when deleting a library,
	-- and the library will clean up the residual folders.
	IF NOT IsSpecialFolder(in_sid_id) THEN
		DELETE FROM doc_folder_subscription
		 WHERE doc_folder_sid = in_sid_id;			
		UPDATE tpl_report_schedule
		   SET doc_folder_sid = null
		 WHERE doc_folder_sid = in_sid_id;
		DELETE FROM doc_folder_name_translation
		 WHERE doc_folder_sid = in_sid_id;
		DELETE FROM doc_folder
		 WHERE doc_folder_sid = in_sid_id;
	END IF;
END;

PROCEDURE MoveObject(
	in_act					IN security_pkg.T_ACT_ID, 
	in_sid_id				IN security_pkg.T_SID_ID, 
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
	v_new_company_sid		security_pkg.T_SID_ID;
	v_new_property_sid		security_pkg.T_SID_ID;
	v_new_permit_item_id	security_pkg.T_SID_ID;
BEGIN
	BEGIN
		UPDATE doc_folder_name_translation
		   SET parent_sid = in_new_parent_sid_id
		 WHERE doc_folder_sid = in_sid_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN 
			RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, '');
	END;
	
	BEGIN
		SELECT company_sid, property_sid, permit_item_id
		  INTO v_new_company_sid, v_new_property_sid, v_new_permit_item_id
		  FROM doc_folder
		 WHERE doc_folder_sid = in_new_parent_sid_id;
		 
		IF v_new_company_sid IS NOT NULL AND v_new_property_sid IS NOT NULL AND v_new_permit_item_id IS NOT NULL THEN
			UPDATE doc_folder
			   SET company_sid = v_new_company_sid,
				   property_sid = v_new_property_sid,
				   permit_item_id = v_new_permit_item_id
			 WHERE doc_folder_sid = in_sid_id;
		END IF;
	EXCEPTION
		WHEN no_data_found THEN
			NULL;
	END;
END;

FUNCTION SQL_IsAccessAllowed (
	in_folder_sid					IN  security_pkg.T_SID_ID,
	in_permission_set				IN  security_Pkg.T_PERMISSION	
) RETURN NUMBER
AS
	v_company_sid					security_pkg.T_SID_ID;
	v_property_sid					security_pkg.T_SID_ID;
	v_permit_item_id				security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT company_sid, property_sid, permit_item_id
		  INTO v_company_sid, v_property_sid, v_permit_item_id
		  FROM doc_folder
		 WHERE doc_folder_sid = in_folder_sid;
	EXCEPTION
		WHEN no_data_found THEN
			NULL;
	END;
	
	IF v_company_sid IS NOT NULL THEN
		IF security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_folder_sid, security_pkg.PERMISSION_READ) AND
			supplier_pkg.CheckDocumentPermissions(v_company_sid, in_permission_set)
		THEN
			RETURN 1;
		ELSE
			RETURN 0;
		END IF;
	END IF;

	IF (v_property_sid IS NOT NULL AND 
		security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_folder_sid, security_pkg.PERMISSION_READ) AND
		property_pkg.CheckDocumentPermissions(v_property_sid, in_permission_set))
	THEN
		RETURN 1;
	END IF;

	IF (v_permit_item_id IS NOT NULL AND 
		security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_folder_sid, security_pkg.PERMISSION_READ) AND
		permit_pkg.CheckDocumentPermissions(v_permit_item_id, in_permission_set))
	THEN
		RETURN 1;
	END IF;

	IF security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_folder_sid, in_permission_set) THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END;

FUNCTION IsSystemManaged (
	in_folder_sid					IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_is_system_managed				doc_folder.is_system_managed%TYPE;
BEGIN
	SELECT is_system_managed
	  INTO v_is_system_managed
	  FROM doc_folder
	 WHERE doc_folder_sid = in_folder_sid;

	RETURN v_is_system_managed = 1;
END;

PROCEDURE GetFolders(
	in_folder_sid			IN	security_pkg.T_SID_ID,
	out_documents_sid		OUT	security_pkg.T_SID_ID,
	out_trash_folder_sid	OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	SELECT documents_sid, trash_folder_sid
	  INTO out_documents_sid, out_trash_folder_sid
	  FROM v$doc_folder_root
	 WHERE doc_folder_sid = in_folder_sid;
END;

PROCEDURE CheckFolderAccess (
	in_folder_sid					IN  security_pkg.T_SID_ID,
	in_permission_set				IN  security_pkg.T_PERMISSION	
)
AS
BEGIN	
	IF SQL_IsAccessAllowed(in_folder_sid, in_permission_set) = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the document folder with sid '||in_folder_sid);
	END IF;
END;

PROCEDURE PopulateTempTreeWithFolders (
	in_parent_sid					IN  security_pkg.T_SID_ID,
	in_fetch_depth					IN  NUMBER DEFAULT NULL,
	in_limit						IN  NUMBER DEFAULT NULL,
	in_hide_root					IN  NUMBER DEFAULT 0
)
AS
	v_library_sid					security_pkg.T_SID_ID := GetLibraryContainer(in_parent_sid);
	v_company_folder_sids			security.T_SID_TABLE := supplier_pkg.GetPermissibleDocumentFolders(v_library_sid);
	v_property_folder_sids			security.T_SID_TABLE := property_pkg.GetPermissibleDocumentFolders(v_library_sid);
	v_permit_folder_sids			security.T_SID_TABLE := permit_pkg.GetPermissibleDocumentFolders(v_library_sid);
	v_tree							security.T_SO_TREE_TABLE;
BEGIN
	-- just in case
	DELETE FROM temp_tree;
	
	v_tree := securableobject_pkg.GetTreeWithPermAsTable(
		in_act_id			=> security_pkg.GetACT(), 
		in_sid_id			=> in_parent_sid, 
		in_permission_set 	=> security_pkg.PERMISSION_READ,
		in_fetch_depth		=> in_fetch_depth,
		in_limit			=> in_limit,
		in_hide_root		=> in_hide_root
	);

	-- ************* N.B. that's a literal 0x1 character in SYS_CONNECT_BY_PATH, not a space **************
	INSERT INTO temp_tree (sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner, so_level, is_leaf, path)
		SELECT sid_id, parent_sid_id, dacl_id, class_id, df.translated AS name, flags, owner, so_level, is_leaf,
			   REPLACE(SYS_CONNECT_BY_PATH(df.translated, ''), CHR(1), '/') path
		  FROM TABLE(v_tree) t
		  JOIN v$doc_folder df ON t.sid_id = df.doc_folder_sid
		  LEFT JOIN (SELECT DISTINCT column_value FROM TABLE(v_company_folder_sids)) cfs ON t.sid_id = cfs.column_value
		  LEFT JOIN (SELECT DISTINCT column_value FROM TABLE(v_property_folder_sids)) pfs ON t.sid_id = pfs.column_value
		  LEFT JOIN (SELECT DISTINCT column_value FROM TABLE(v_permit_folder_sids)) pfs2 ON t.sid_id = pfs2.column_value
		 WHERE (df.company_sid IS NULL OR cfs.column_value IS NOT NULL)
		   AND (df.property_sid IS NULL OR pfs.column_value IS NOT NULL)
		   AND (df.permit_item_id IS NULL OR pfs2.column_value IS NOT NULL)
		 START WITH (in_hide_root = 0 AND t.sid_id = in_parent_sid) OR (in_hide_root = 1 AND t.parent_sid_id = in_parent_sid)
	   CONNECT BY PRIOR t.sid_id = t.parent_sid_id;
END;

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
)
AS
	v_lifespan						doc_folder.lifespan%TYPE;
	v_approver_sid					security_pkg.T_SID_ID;
	v_company_sid					security_pkg.T_SID_ID;
	v_property_sid					security_pkg.T_SID_ID;
	v_parent_is_doc_lib				security_pkg.T_SID_ID;
	v_name							security_pkg.T_SO_NAME := in_name;
	v_permit_item_id				security_pkg.T_SID_ID;
	v_is_ucd						boolean := FALSE;
BEGIN
	-- do extra checks for company folders
	CheckFolderAccess(in_parent_sid, security_pkg.PERMISSION_ADD_CONTENTS);

	-- For system managed folders e.g. Documents, Recycle bin keep so name else set so name to null
	IF in_is_system_managed = 0 THEN
		v_name := NULL;
	END IF;
	
	BEGIN
		SELECT lifespan, approver_sid, company_sid, property_sid, permit_item_id
		  INTO v_lifespan, v_approver_sid, v_company_sid, v_property_sid, v_permit_item_id
		  FROM doc_folder
		 WHERE doc_folder_sid = in_parent_sid;
	EXCEPTION	
		WHEN NO_DATA_FOUND THEN
			NULL; -- ignore - probably this is under the root
	END;
	
	IF NVL(in_company_sid, v_company_sid) IS NOT NULL THEN
		v_is_ucd := TRUE;
		chain.helper_pkg.LogonUCD(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	Securableobject_Pkg.CreateSO(security_pkg.GetACT(), in_parent_sid, 
		class_pkg.GetClassId('DocFolder'), v_name, out_sid_id);
	
	IF v_is_ucd = TRUE THEN
		chain.helper_pkg.RevertLogonUCD;
	END IF;

	INSERT INTO doc_folder (doc_folder_sid, description, lifespan, approver_sid, company_sid, 
							property_sid, is_system_managed, permit_item_id)		  
		SELECT out_sid_id doc_folder_sid, in_description description, 
			CASE WHEN in_lifespan_is_override = 1 THEN in_lifespan ELSE v_lifespan END, 
			CASE WHEN in_approver_is_override = 1 THEN in_approver_sid ELSE v_approver_sid END,
			NVL(in_company_sid, v_company_sid), NVL(in_property_sid, v_property_sid), in_is_system_managed,
			NVL(in_permit_item_id, v_permit_item_id)
		  FROM dual;
		  
	BEGIN
		INSERT INTO doc_folder_name_translation (doc_folder_sid, parent_sid, lang, translated)
		SELECT out_sid_id, in_parent_sid, lang, in_name
		  FROM v$customer_lang;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN 
			RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'There is already a folder named ' || in_name);
	END;
END;

PROCEDURE CreateFolderTree(
	in_parent_sid_id		IN	security_pkg.T_SID_ID,
	in_path					IN	VARCHAR2,
	out_sid_id				OUT security_pkg.T_SID_ID
)
AS
	v_parent_sid_id Security_Pkg.T_SID_ID;
	v_path 			VARCHAR2(4000);
	v_sid_id 		Security_Pkg.T_SID_ID;
	v_sep_pos 		NUMBER;
	v_level_name 	VARCHAR2(4000);
BEGIN
	v_path := in_path;
	v_parent_sid_id := in_parent_sid_id;
	-- Repeat for each component in the path
	LOOP
		-- Compress /s to nothing
		LOOP
			-- Stop now if we run out of path components
			IF v_path IS NULL THEN
				EXIT;
			END IF;
			IF SUBSTR(v_path, 1, 1) <> '/' THEN
			   EXIT;
			END IF;
			v_path := SUBSTR(v_path, 2);
		END LOOP;
		-- Split out the name of the object at the current level
		v_sep_pos := INSTR(v_path, '/');
		-- if no /s left, the whole string is the object name
		IF v_sep_pos = 0 THEN
			v_level_name := v_path;
		-- otherwise, chop out up to the slash
		ELSE
			v_level_name := SUBSTR(v_path, 1, v_sep_pos - 1);
			v_path := SUBSTR(v_path, v_sep_pos + 1);
		END IF;

		BEGIN
			SELECT NVL(so.link_sid_id, so.sid_id) INTO v_sid_id
			  FROM security.securable_object so
			  JOIN v$doc_folder df ON so.sid_id = df.doc_folder_sid
			 WHERE LOWER(df.translated) = LOWER(v_level_name)
			   AND parent_sid_id = v_parent_sid_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				CreateFolder(
					in_parent_sid => v_parent_sid_id, 
					in_name => v_level_name,
					out_sid_id => v_sid_id);
		END;
		-- If we have run out of path components, or we didn't
		-- find a component with the given name at this level, return
		IF v_sep_pos = 0 OR v_sid_id IS NULL THEN
			EXIT;
		END IF;
		-- Loop around for the next level, this level because the parent
		v_parent_sid_id := v_sid_id;
	END LOOP;
	out_sid_id := v_sid_id;
END;

PROCEDURE UpdateFolder(
	in_folder_sid			IN	security_pkg.T_SID_ID,
	in_folder_name			IN	security_pkg.T_SO_NAME,
	in_description			IN	doc_folder.description%TYPE,
	in_approver_is_override	IN	doc_folder.approver_is_override%TYPE,
	in_approver_sid			IN	security_pkg.T_SID_ID,
	in_lifespan_is_override	IN	doc_folder.lifespan_is_override%TYPE,
	in_lifespan				IN	doc_folder.lifespan%TYPE
)
AS
	v_is_ucd						boolean := FALSE;
	v_folder_company_sid			security_pkg.T_SID_ID;
	CURSOR c IS
		SELECT df.approver_is_override, df.lifespan_is_override, df.approver_sid, 
		       df.lifespan, df.is_system_managed, so.name
		  FROM doc_folder df
		  JOIN security.securable_object so ON df.app_sid = so.application_sid_id AND df.doc_folder_sid = sid_id
		 WHERE df.doc_folder_sid = in_folder_sid;
	r c%ROWTYPE;
	v_approver_sid				security_pkg.T_SID_ID := in_approver_sid;
	v_lifespan					doc_folder.lifespan%TYPE := in_lifespan;
BEGIN
	-- do extra checks for company folders
	CheckFolderAccess(in_folder_sid, security_pkg.PERMISSION_WRITE);
	
	-- TODO: audit changes	
	OPEN c;
	FETCH c INTO r;
	CLOSE c;
	
	SELECT company_sid
	  INTO v_folder_company_sid
	  FROM doc_folder
	 WHERE doc_folder_sid = in_folder_sid;
	
	IF v_folder_company_sid IS NOT NULL THEN
		v_is_ucd := TRUE;
		chain.helper_pkg.LogonUCD(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	IF null_pkg.ne(in_folder_name, r.name) THEN
		IF r.is_system_managed = 1 THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied renaming the system managed document folder with sid '||in_folder_sid);
		END IF;

		IF NOT IsSpecialFolder(in_folder_sid) THEN
			-- rename SO to null, in case another folder has different translation you see in UI but same so name
			SecurableObject_pkg.RenameSO(security_pkg.GetACT(), in_folder_sid, NULL);
		END IF;
	END IF;
	
	IF v_is_ucd = TRUE THEN
		chain.helper_pkg.RevertLogonUCD;
	END IF;
	
	-- get lifespan from parent if clearing
	IF in_lifespan_is_override = 0 THEN 
		SELECT lifespan
		  INTO v_lifespan
		  FROM security.securable_object so
			LEFT JOIN doc_folder ON so.parent_sid_id = doc_folder.doc_folder_sid
		 WHERE sid_id = in_folder_sid;
	END IF;

	-- get approver from parent if clearing
	IF in_approver_is_override = 0 THEN 
		SELECT approver_sid 
		  INTO v_approver_sid
		  FROM security.securable_object so
			LEFT JOIN doc_folder ON so.parent_sid_id = doc_folder.doc_folder_sid
		 WHERE sid_id = in_folder_sid;
	END IF;
	
	-- change this folder
	UPDATE doc_folder
	   SET description = in_description,
		approver_is_override = in_approver_is_override, approver_sid = v_approver_sid,
		lifespan_is_override = in_lifespan_is_override, lifespan = v_lifespan
	 WHERE doc_folder_sid = in_folder_sid;
	
	-- propagate down if approver changed
	IF r.approver_is_override != in_approver_is_override OR
		null_pkg.ne(r.approver_sid, in_approver_sid) THEN
	
		
		-- if the approver has changed, then make sure we switch locked_by_sid over
		UPDATE doc_current
		   SET locked_by_sid = v_approver_sid
		 WHERE pending_version IS NOT NULL -- i.e. where they're about to approve
		   AND parent_sid IN (
				SELECT in_folder_sid
				  FROM dual
				 UNION ALL
				SELECT df.doc_folder_sid
				  FROM doc_folder df
				  JOIN security.securable_object so ON df.doc_folder_sid = so.sid_id
				 START WITH so.parent_sid_id = in_folder_sid AND df.approver_is_override = 0
				CONNECT BY PRIOR so.sid_id = so.parent_sid_id AND df.approver_is_override = 0
		   );
		
		UPDATE doc_folder
	       SET approver_sid = v_approver_sid
	     WHERE doc_folder_sid IN (
				SELECT df.doc_folder_sid
				  FROM doc_folder df
				  JOIN security.securable_object so ON df.doc_folder_sid = so.sid_id
				 START WITH so.parent_sid_id = in_folder_sid AND df.approver_is_override = 0
				CONNECT BY PRIOR so.sid_id = so.parent_sid_id AND df.approver_is_override = 0
		  );
	
		
	END IF;
	
	
	-- propagate down if lifespan changed
	IF r.lifespan_is_override != in_lifespan_is_override OR
		null_pkg.ne(r.lifespan, in_lifespan) THEN

	
		UPDATE doc_folder
		   SET lifespan = v_lifespan
		 WHERE doc_folder_sid IN (
				SELECT df.doc_folder_sid
				  FROM doc_folder df
				  JOIN security.securable_object so ON df.doc_folder_sid = so.sid_id
				 START WITH so.parent_sid_id = in_folder_sid AND df.lifespan_is_override = 0
				CONNECT BY PRIOR so.sid_id = so.parent_sid_id AND df.lifespan_is_override = 0
		);

	END IF;
END;

FUNCTION GetDocumentsFolder(
	in_doc_library_sid				IN	security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
AS
	v_documents_sid					security_pkg.T_SID_ID;
BEGIN
	SELECT documents_sid
	  INTO v_documents_sid
	  FROM doc_library
	 WHERE doc_library_sid = in_doc_library_sid;
	 
	RETURN v_documents_sid;
END;

FUNCTION GetRootFolder(
	in_folder_sid			IN	security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
AS
	v_documents_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT documents_sid
	  INTO v_documents_sid
	  FROM v$doc_folder_root
	 WHERE doc_folder_sid = in_folder_sid;
	RETURN v_documents_sid;
END;

FUNCTION GetLibraryContainer(
	in_folder_sid			IN	security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
AS
	v_doc_library_sid		security_pkg.T_SID_ID;
BEGIN
	SELECT doc_library_sid
	  INTO v_doc_library_sid
	  FROM v$doc_folder_root
	 WHERE doc_folder_sid = in_folder_sid;
	RETURN v_doc_library_sid;
END;

FUNCTION GetTrashFolder(
	in_folder_sid			IN	security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
AS
	v_trash_folder_sid		security_pkg.T_SID_ID;
BEGIN
	SELECT trash_folder_sid
	  INTO v_trash_folder_sid
	  FROM v$doc_folder_root
	 WHERE doc_folder_sid = in_folder_sid;
	RETURN v_trash_folder_sid;
END;

FUNCTION GetTrashCount(
	in_trash_folder_sid		IN	security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_trash_admin	BINARY_INTEGER;
	v_trash_count	NUMBER;
	v_sid_id		security_pkg.T_SID_ID;
BEGIN
	v_trash_admin := security_pkg.SQL_IsAccessAllowedSID(security_pkg.GetACT(), in_trash_folder_sid, security_pkg.PERMISSION_DELETE);
	v_sid_id := security_pkg.GetSID();

	SELECT COUNT(*)
	  INTO v_trash_count
	  FROM doc_current
	 WHERE parent_sid = in_trash_folder_sid AND (v_trash_admin = 1 OR locked_by_sid = v_sid_id);
	RETURN v_trash_count;
END;

FUNCTION GetTrashIcon(
	in_trash_folder_sid		IN	security_pkg.T_SID_ID
) RETURN VARCHAR2
AS
BEGIN
	IF GetTrashCount(in_trash_folder_sid) > 0 THEN
		RETURN 'TrashFull';
	END IF;
	RETURN 'TrashEmpty';
END;

FUNCTION IsSpecialFolder(
	in_folder_sid			IN	security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_num				BINARY_INTEGER;
BEGIN
	SELECT COUNT(*)
	  INTO v_num
	  FROM v$doc_folder_root
	 WHERE doc_folder_sid = in_folder_sid AND (trash_folder_sid = in_folder_sid OR doc_library_sid = in_folder_sid OR documents_sid = in_folder_sid);
	RETURN v_num > 0;
END;

PROCEDURE UNSEC_DeleteFolder(
	in_folder_sid			IN	security_pkg.T_SID_ID,
	in_deleted_text			IN	VARCHAR2,
	out_trash_count			OUT	NUMBER
)
AS
	v_documents_sid			security_pkg.T_SID_ID;
	v_trash_folder_sid		security_pkg.T_SID_ID;
BEGIN
	GetFolders(in_folder_sid, v_documents_sid, v_trash_folder_sid);

	IF in_folder_sid IN (v_documents_sid, v_trash_folder_sid) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Access denied deleting the folder with sid '||in_folder_sid);
	END IF;	
	
	INSERT INTO temp_translations (original, translated)
	VALUES ('Deleted', in_deleted_text);
	SecurableObject_pkg.DeleteSO(security_pkg.GetACT(), in_folder_sid);
	out_trash_count := GetTrashCount(v_trash_folder_sid);
END;

PROCEDURE DeleteFolder(
	in_folder_sid			IN	security_pkg.T_SID_ID,
	in_deleted_text			IN	VARCHAR2,
	out_trash_count			OUT	NUMBER
)
AS
	v_is_ucd						boolean := FALSE;
	v_folder_company_sid			security_pkg.T_SID_ID;
BEGIN
	IF IsSystemManaged(in_folder_sid) AND NOT csr_data_pkg.CheckCapability('System management') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Access denied deleting the folder with sid '||in_folder_sid);
	END IF;	
	
	-- do extra checks for company folders
	CheckFolderAccess(in_folder_sid, security_pkg.PERMISSION_DELETE);
	
	SELECT company_sid
	  INTO v_folder_company_sid
	  FROM doc_folder
	 WHERE doc_folder_sid = in_folder_sid;
	
	IF v_folder_company_sid IS NOT NULL THEN
		v_is_ucd := TRUE;
		chain.helper_pkg.LogonUCD(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	UNSEC_DeleteFolder(
		in_folder_sid		=> in_folder_sid,
		in_deleted_text		=> in_deleted_text,
		out_trash_count		=> out_trash_count
	);
		
	IF v_is_ucd = TRUE THEN
		chain.helper_pkg.RevertLogonUCD;
	END IF;
END;

PROCEDURE MoveFolder(
	in_folder_sid			IN	security_pkg.T_SID_ID,
	in_new_parent_sid		IN	security_pkg.T_SID_ID
)
AS
	v_documents_sid					security_pkg.T_SID_ID;
	v_folder_company_sid			security_pkg.T_SID_ID;
	v_parent_folder_company_sid		security_pkg.T_SID_ID;
	v_is_ucd						boolean := FALSE;
	CURSOR c IS
		SELECT doc_folder_sid, name, description, 
			approver_is_override, approver_sid,
			lifespan_is_override, lifespan
		  FROM doc_folder df
			JOIN security.securable_object so ON df.doc_folder_sid = so.sid_id
		 WHERE df.doc_folder_sid = in_folder_sid;
	r c%ROWTYPE;
BEGIN
	IF IsSpecialFolder(in_folder_sid) OR IsSystemManaged(in_folder_sid) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Access denied moving the folder with sid '||in_folder_sid||' under the folder with sid '||in_new_parent_sid);
	END IF;
	
	-- do extra checks for company folders
	CheckFolderAccess(in_folder_sid, security_pkg.PERMISSION_DELETE);
	CheckFolderAccess(in_new_parent_sid, security_pkg.PERMISSION_ADD_CONTENTS);

	-- if both of these folders have company sids we need to promote to ucd to do the move as the user will not have so permissions
	SELECT company_sid
	  INTO v_folder_company_sid
	  FROM doc_folder
	 WHERE doc_folder_sid = in_folder_sid;

	SELECT company_sid
	  INTO v_parent_folder_company_sid
	  FROM doc_folder
	 WHERE doc_folder_sid = in_new_parent_sid;
	
	IF v_folder_company_sid IS NOT NULL AND
	   v_parent_folder_company_sid IS NOT NULL THEN
		v_is_ucd := TRUE;
		chain.helper_pkg.LogonUCD(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	-- set so name to null, new parent folder may have folder with same name but different translation
	SecurableObject_pkg.RenameSO(security_pkg.GetACT(), in_folder_sid, NULL);
	SecurableObject_pkg.MoveSO(security_pkg.GetACT(), in_folder_sid, in_new_parent_sid);
		
	IF v_is_ucd = TRUE THEN
		chain.helper_pkg.RevertLogonUCD;
	END IF;
	
	OPEN c;
	FETCH c INTO r;
	CLOSE c;

	-- inherit permissions (just call update)
	UpdateFolder(r.doc_folder_sid, r.name, r.description, 
		r.approver_is_override, r.approver_sid,
		r.lifespan_is_override, r.lifespan);
END;

PROCEDURE GetDetails(
	in_folder_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
)
AS
	v_can_edit				NUMBER;
	v_can_delete			NUMBER;
	v_can_add_contents		NUMBER;
	v_can_add_folders		NUMBER;
	v_company_sid			security_pkg.T_SID_ID;
	v_property_sid			security_pkg.T_SID_ID;
	v_permit_item_id		security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT company_sid, property_sid, permit_item_id
		  INTO v_company_sid, v_property_sid, v_permit_item_id
		  FROM doc_folder
		 WHERE doc_folder_sid = in_folder_sid;
	EXCEPTION
		WHEN no_data_found THEN
			NULL;
	END;
	
	CheckFolderAccess(in_folder_sid, security_pkg.PERMISSION_READ);	
	
	v_can_edit := SQL_IsAccessAllowed(in_folder_sid, security_pkg.PERMISSION_WRITE);
	v_can_delete := SQL_IsAccessAllowed(in_folder_sid, security_pkg.PERMISSION_DELETE);
	v_can_add_contents := SQL_IsAccessAllowed(in_folder_sid, security_pkg.PERMISSION_ADD_CONTENTS);	
	-- adding folders is based on both SO and company checks
	-- when adding a chain folder it will promote to UCD so don't do an SO check
	IF security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_folder_sid, security_pkg.PERMISSION_ADD_CONTENTS) OR
	   (v_can_add_contents = 1 AND v_company_sid IS NOT NULL) THEN
		v_can_add_folders := v_can_add_contents;
	ELSE
		v_can_add_folders := 0;
	END IF;
	
	IF IsSystemManaged(in_folder_sid) THEN
		v_can_delete := 0;
	END IF;
	
	OPEN out_cur FOR
		SELECT so.parent_sid_id, df.translated AS name,
			   v_can_edit can_edit, v_can_add_contents can_add_contents, 
			   v_can_delete can_delete, v_can_add_folders can_add_folders,
			   df.doc_folder_sid, df.description, df.lifespan_is_override, 
			   df.lifespan, df.approver_is_override, 
			   df.approver_sid, cu.user_name approver_user_name, 
			   cu.full_name approver_full_name, cu.email approver_email,
			   NVL2(dfs.doc_folder_sid, 1, 0) is_subscribed, df.is_system_managed
		  FROM v$doc_folder df
		  LEFT JOIN security.securable_object so ON df.doc_folder_sid = so.sid_id
		  LEFT JOIN csr_user cu ON df.approver_sid = cu.csr_user_sid
		  LEFT JOIN doc_folder_subscription dfs ON df.doc_folder_sid = dfs.doc_folder_sid AND dfs.notify_sid = SYS_CONTEXT('SECURITY','SID')
		 WHERE df.doc_folder_sid = in_folder_sid;
END;

PROCEDURE GetTreeWithDepth(
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_trash_folder_sid				security_pkg.T_SID_ID;
	v_documents_sid					security_pkg.T_SID_ID;
BEGIN
	GetFolders(in_parent_sid, v_documents_sid, v_trash_folder_sid);
	
	PopulateTempTreeWithFolders(
		in_parent_sid				=> in_parent_sid,
		in_fetch_depth				=> in_fetch_depth,
		in_hide_root				=> 1
	);
	
	OPEN out_cur FOR
		SELECT tt.sid_id, tt.parent_sid_id, tt.name, tt.so_level, tt.is_leaf, 1 is_match,
			   CASE WHEN tt.sid_id = v_trash_folder_sid THEN GetTrashIcon(v_trash_folder_sid) 
			   		WHEN tt.sid_id = v_documents_sid THEN 'Library'
			   		ELSE 'Container' END class_name
		  FROM temp_tree tt;
END;

PROCEDURE GetTreeWithSelect(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_select_sid					IN	security_pkg.T_SID_ID,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_trash_folder_sid				security_pkg.T_SID_ID;
	v_documents_sid					security_pkg.T_SID_ID;
BEGIN
	GetFolders(in_parent_sid, v_documents_sid, v_trash_folder_sid);
	
	PopulateTempTreeWithFolders(
		in_parent_sid				=> in_parent_sid,
		in_hide_root				=> 1
	);
	
	OPEN out_cur FOR
		SELECT tt.sid_id, tt.parent_sid_id, tt.name, tt.so_level, tt.is_leaf, 1 is_match,
			   CASE WHEN tt.sid_id = v_trash_folder_sid THEN GetTrashIcon(v_trash_folder_sid) 
			   		WHEN tt.sid_id = v_documents_sid THEN 'Library'
			   		ELSE 'Container' END class_name
		  FROM temp_tree tt
		 WHERE (tt.so_level <= in_fetch_depth 
		 	OR tt.sid_id IN (
				SELECT sid_id
		 		  FROM security.securable_object
		 			   START WITH sid_id = in_select_sid
		 			   CONNECT BY PRIOR parent_sid_id = sid_id
		 	)
		 	OR tt.parent_sid_id IN (
				SELECT sid_id
		 		  FROM security.securable_object
		 			   START WITH sid_id = in_select_sid
		 			   CONNECT BY PRIOR parent_sid_id = sid_id
		 	));
END;
	
PROCEDURE GetTreeTextFiltered(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_search_phrase				IN	VARCHAR2,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_trash_folder_sid				security_pkg.T_SID_ID;
	v_documents_sid					security_pkg.T_SID_ID;
	v_company_folder_sids			security.T_SID_TABLE := supplier_pkg.GetPermissibleDocumentFolders(GetLibraryContainer(in_parent_sid));
BEGIN
	GetFolders(in_parent_sid, v_documents_sid, v_trash_folder_sid);
	-- XXX: this reads the whole tree, should we add an explicit tree text filter too?
	OPEN out_cur FOR
		SELECT t.sid_id, t.parent_sid_id, df.translated AS name, t.so_level, t.is_leaf, NVL(mt.is_match,0) is_match,
			   CASE WHEN t.sid_id = v_trash_folder_sid THEN GetTrashIcon(v_trash_folder_sid) 
			   		WHEN t.sid_id = v_documents_sid THEN 'Library'
			   		ELSE 'Container' END class_name
		  FROM (
		  	SELECT rownum rn, x.*
		  	  FROM TABLE ( SecurableObject_pkg.GetTreeWithPermAsTable(security_pkg.GetACT(), in_parent_sid, 
				  		   security_pkg.PERMISSION_READ, null, null, 1) ) x
		  ) t
		  JOIN (
			SELECT DISTINCT sid_id
			  FROM security.securable_object
			 START WITH sid_id IN (
				   SELECT so.sid_id
		      		 FROM security.securable_object so
					 JOIN v$doc_folder df ON so.sid_id = df.doc_folder_sid
		      	    WHERE LOWER(df.translated) LIKE '%'||LOWER(in_search_phrase)||'%'
			        START WITH sid_id = in_parent_sid
			  CONNECT BY PRIOR sid_id = parent_sid_id)
		    CONNECT BY PRIOR parent_sid_id = sid_id
		  ) ti ON t.sid_id = ti.sid_id 
		  LEFT JOIN (
			 SELECT so.sid_id, 1 is_match
      		  FROM security.securable_object so
			  JOIN v$doc_folder df ON so.sid_id = df.doc_folder_sid
      	     WHERE LOWER(df.translated) LIKE '%'||LOWER(in_search_phrase)||'%'
	         START WITH sid_id = in_parent_sid
		   CONNECT BY PRIOR sid_id = parent_sid_id
		  ) mt ON  t.sid_id = mt.sid_id
		  JOIN v$doc_folder df ON t.sid_id = df.doc_folder_sid
		  LEFT JOIN TABLE(v_company_folder_sids) cfs ON t.sid_id = cfs.column_value
		 WHERE df.company_sid IS NULL OR cfs.column_value IS NOT NULL
     ORDER BY t.rn;
END;

PROCEDURE GetList(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_documents_sid				IN	security_pkg.T_SID_ID,
	in_limit						IN	NUMBER,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_trash_folder_sid				security_pkg.T_SID_ID;
	v_documents_sid					security_pkg.T_SID_ID;
BEGIN
	GetFolders(in_documents_sid, v_documents_sid, v_trash_folder_sid);
	
	PopulateTempTreeWithFolders(
		in_parent_sid	=> in_documents_sid,
		in_limit		=> in_limit + 1,
		in_hide_root	=> 1
	);
	
	OPEN out_cur FOR
		SELECT tt.sid_id, tt.parent_sid_id, tt.name, tt.so_level, tt.is_leaf, SUBSTR(tt.path, 2) path, 1 is_match,
			   CASE WHEN tt.sid_id = v_trash_folder_sid THEN GetTrashIcon(v_trash_folder_sid)
			   		WHEN tt.sid_id = v_documents_sid THEN 'Library'
			   		ELSE 'Container' END class_name
		  FROM temp_tree tt
		 WHERE tt.sid_id <> in_documents_sid AND rownum <= in_limit;
END;

PROCEDURE GetListTextFiltered(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_documents_sid				IN	security_pkg.T_SID_ID,
	in_search_phrase				IN	VARCHAR2,
	in_limit						IN	NUMBER,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_trash_folder_sid				security_pkg.T_SID_ID;
	v_documents_sid					security_pkg.T_SID_ID;
BEGIN
	GetFolders(in_documents_sid, v_documents_sid, v_trash_folder_sid);
	
	PopulateTempTreeWithFolders(
		in_parent_sid	=> in_documents_sid,
		in_hide_root	=> 1
	);
	
	-- XXX: this reads the whole tree, should we add an explicit list filter?
	OPEN out_cur FOR
		SELECT tt.sid_id, tt.parent_sid_id, tt.name, tt.so_level, tt.is_leaf, SUBSTR(tt.path, 2) path, 1 is_match,
			   CASE WHEN tt.sid_id = v_trash_folder_sid THEN GetTrashIcon(v_trash_folder_sid) 
			   		WHEN tt.sid_id = v_documents_sid THEN 'Library'
			   		ELSE 'Container' END class_name
		  FROM temp_tree tt
		 WHERE tt.sid_id <> in_documents_sid AND LOWER(tt.name) LIKE '%'||LOWER(in_search_phrase)||'%' AND rownum <= in_limit;
END;

PROCEDURE GetFolderTranslation(
	in_folder_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	CheckFolderAccess(in_folder_sid, security_pkg.PERMISSION_READ);	

	OPEN out_cur FOR
		SELECT dfnt.doc_folder_sid, dfnt.lang, dfnt.translated
		  FROM doc_folder_name_translation dfnt
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND dfnt.doc_folder_sid = in_folder_sid;
END;

PROCEDURE SetFolderTranslation(
	in_folder_sid			IN	security_pkg.T_SID_ID,
	in_lang					IN	aspen2.tr_pkg.T_LANG,
	in_translated			IN	VARCHAR2
)
AS
BEGIN
	CheckFolderAccess(in_folder_sid, security_pkg.PERMISSION_WRITE);

	-- NB doc_folder_name_translation must have translations for ALL customer languages
	BEGIN
		UPDATE doc_folder_name_translation
		   SET translated = in_translated
		 WHERE doc_folder_sid = in_folder_sid
		   AND lang = in_lang;

		IF SQL%ROWCOUNT = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Missing folder name translation for the language '||in_lang||
				' and the folder with sid '||in_folder_sid);
		END IF;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN 
			RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'There is already a folder named ' || in_translated || 'in lang ' || in_lang);
	END;
END;

FUNCTION GetFolderName(
	in_folder_sid			IN	security_pkg.T_SID_ID
) RETURN VARCHAR2
AS
	v_folder_name				doc_folder_name_translation.translated%TYPE;
BEGIN
	SELECT translated
	  INTO v_folder_name
	  FROM v$doc_folder
	 WHERE doc_folder_sid = in_folder_sid;

	RETURN v_folder_name;
END;

FUNCTION GetTranslation(
	in_text					IN	VARCHAR2
) RETURN VARCHAR2
AS
BEGIN
	FOR r IN (SELECT translated
	  			FROM temp_translations
	  		   WHERE original = in_text) LOOP
		RETURN r.translated;
	END LOOP;
	RETURN in_text;
END;

/* keeping this junk code here so its not in doc_pkg */
PROCEDURE FinaliseSave(
	in_parent_sid			IN  security_pkg.T_SID_ID, 
	in_filename				IN  VARCHAR2
)
AS
	v_permit_item_id		NUMBER;
BEGIN
	BEGIN
		SELECT permit_item_id 
		  INTO v_permit_item_id
		  FROM doc_folder 
		 WHERE doc_folder_sid = in_parent_sid;
		
		IF v_permit_item_id IS NOT NULL THEN
			permit_pkg.DocSaved(v_permit_item_id, in_filename);
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN 
			NULL;
	END;
END;

PROCEDURE FinaliseDelete(
	in_parent_sid			IN  security_pkg.T_SID_ID, 
	in_filename				IN  VARCHAR2
)
AS
	v_permit_item_id		NUMBER;
BEGIN
	BEGIN
		SELECT permit_item_id 
		  INTO v_permit_item_id
		  FROM doc_folder 
		 WHERE doc_folder_sid = in_parent_sid;
		
		IF v_permit_item_id IS NOT NULL THEN
			permit_pkg.DocDeleted(v_permit_item_id, in_filename);
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN 
			NULL;
	END;
END;

END doc_folder_pkg;
/
