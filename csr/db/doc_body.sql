CREATE OR REPLACE PACKAGE BODY CSR.doc_pkg AS

PROCEDURE GetDocFolder(
	in_doc_id				IN	doc.doc_id%TYPE,
	out_parent_sid			OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	BEGIN
		SELECT parent_sid
		  INTO out_parent_sid
		  FROM doc_current
		 WHERE doc_id = in_doc_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND,
				'The document with id '||in_doc_id||' could not be found');
	END;
END;

PROCEDURE Notify(
	in_doc_id				IN	doc_version.doc_id%TYPE,
	in_version				IN	doc_version.version%TYPE,
	in_reason				IN	doc_notification.reason%TYPE
)
AS
BEGIN
	-- people watching individual docs
	INSERT INTO doc_notification (doc_notification_id, doc_id, version, notify_sid, reason)
		SELECT doc_notification_id_seq.nextval, in_doc_id, in_version, notify_sid, in_reason
		  FROM doc_subscription
		 WHERE doc_id = in_doc_id;
	-- people watching folders (be careful on deletes! i.e. this expects something in doc_current)
	INSERT INTO doc_notification (doc_notification_id, doc_id, version, notify_sid, reason)
		SELECT doc_notification_id_seq.nextval, in_doc_id, in_version, notify_sid, in_reason
		  FROM doc_current dc 
			JOIN doc_folder_subscription dfs ON dc.parent_sid = dfs.doc_folder_sid AND dc.app_sid = dfs.app_sid
		 WHERE dc.doc_id = in_doc_id;
END;

PROCEDURE NotifyApprover(
	in_doc_id				IN	doc_version.doc_id%TYPE
)
AS
BEGIN
	INSERT INTO doc_notification (doc_notification_id, doc_id, version, notify_sid, reason)
		SELECT doc_notification_id_seq.nextval, in_doc_id, pending_version, approver_sid, 'FOR_APPROVAL'
		  FROM doc_current dc
			JOIN doc_folder df ON dc.parent_sid = df.doc_folder_sid AND dc.app_sid = df.app_sid
		 WHERE doc_id = in_doc_id
		   AND pending_version IS NOT NULL; -- make sure the doc is actually pending approval
END;

PROCEDURE FinaliseSaveOrMoveDoc(
	in_doc_id				IN	doc.doc_id%TYPE,
	in_parent_sid			IN  security_pkg.T_SID_ID,
	in_prev_version			IN	doc_version.version%TYPE,
	in_this_version			IN	doc_version.version%TYPE
)
AS
	v_version				doc_version.version%TYPE;
	v_pending_version		doc_version.version%TYPE;
	v_approver_sid			security_pkg.T_SID_ID;
	v_locked_by_sid			security_pkg.T_SID_ID;
BEGIN
	
		
	-- find out if there is an approver for this folder
	SELECT approver_sid 
	  INTO v_approver_sid
	  FROM doc_folder
	 WHERE doc_folder_sid = in_parent_sid;
	 
	-- This logic is a bit more complex. Basically if there's no approver OR this
	-- is being uploaded by the approver, then just let it through as normal.
	-- If however there's an approver, then we fiddle with version numbers so
	-- that most users can't see the new version until it's approved.
	IF v_approver_sid IS NULL OR v_approver_sid = SYS_CONTEXT('SECURITY', 'SID') THEN		
		-- if there is NO approver for the folder OR if this user is the approver
		v_locked_by_sid := null;
		v_version := in_this_version;
		v_pending_version := null; -- set version to this version and pending_version to null
	ELSE
		-- if there is an approver for the folder:
		v_locked_by_sid := v_approver_sid; -- locked by (i.e. editable by) the approver
		v_pending_version := in_this_version; -- set pending_version to this version
		v_version := in_prev_version; -- leave version alone (i.e. we're not changing what users can see yet)
		-- if it's a new upload then in_prev_version will be null (i.e nobody else can see it)
	END IF;
		
	BEGIN
		INSERT INTO doc_current
			(doc_id, parent_sid, version, pending_version, locked_by_sid)
		VALUES
			(in_doc_id, in_parent_sid, v_version, v_pending_version, v_locked_by_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE doc_current
			   SET version = v_version, pending_version = v_pending_version, locked_by_sid = v_locked_by_sid
			 WHERE doc_id = in_doc_id;
	END;
	
	IF v_approver_sid IS NULL OR v_approver_sid = SYS_CONTEXT('SECURITY', 'SID') THEN			
		-- Send alert mails if there's a new approved document visible
		Notify(in_doc_id, v_version, 'NEW_VERSION');	
	ELSE
		-- notify the approver (they don't need to be subscribed)
		NotifyApprover(in_doc_id);	
	END IF;

END;

PROCEDURE GetDocFolderAndLibrary(
	in_doc_id				IN	doc.doc_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_folder				security_pkg.T_SID_ID;
BEGIN
	--Make sure the doc exists
	BEGIN
		SELECT parent_sid
		  INTO v_folder
		  FROM doc_current
		 WHERE doc_id = in_doc_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND,
				'The document with id '||in_doc_id||' could not be found');
	END;
	
	OPEN out_cur FOR
		SELECT doc_folder_sid, doc_library_sid
		  FROM v$doc_folder_root
		 WHERE doc_folder_sid = v_folder;
END;
	
PROCEDURE SaveDoc(		  
	in_doc_id				IN	doc.doc_id%TYPE,
	in_parent_sid			IN	security_pkg.T_SID_ID,
	in_filename				IN	doc_version.filename%TYPE,
	in_mime_type			IN	doc_data.mime_type%TYPE,
	in_data					IN	doc_data.data%TYPE,
	in_description			IN	doc_version.description%TYPE,
	in_change_description	IN	doc_version.change_description%TYPE,
	in_document_type		IN	doc_version.doc_type_id%TYPE,
	out_doc_id				OUT	doc.doc_id%TYPE
)
AS
	v_doc_data_id			doc_data.doc_data_id%TYPE;
	v_parent_sid			security_pkg.T_SID_ID := in_parent_sid;
	v_prev_version			doc_version.version%TYPE := null;
	v_this_version			doc_version.version%TYPE := 1;
BEGIN
	IF in_doc_id IS NOT NULL THEN
		BEGIN
			SELECT parent_sid, version, (SELECT NVL(MAX(version), 0)+1 FROM doc_version WHERE doc_id = in_doc_id)
			  INTO v_parent_sid, v_prev_version, v_this_version
			  FROM doc_current
			 WHERE doc_id = in_doc_id FOR UPDATE;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND,
					'The document with id '||in_doc_id||' could not be found');
		END;
		
		-- makes things easier to update it now
		out_doc_id := in_doc_id;
	END IF;
	
	doc_folder_pkg.CheckFolderAccess(v_parent_sid, security_pkg.PERMISSION_ADD_CONTENTS);
	
	IF in_doc_id IS NULL THEN
		-- Create a new document		  
		INSERT INTO doc (doc_id) VALUES (doc_id_seq.nextval)
		RETURNING doc_id INTO out_doc_id;
	END IF;
	
	INSERT INTO doc_data
		(doc_data_id, data, sha1, mime_type)
	VALUES
		(doc_data_id_seq.NEXTVAL, in_data, dbms_crypto.hash(in_data, dbms_crypto.hash_sh1), in_mime_type)
	RETURNING
		doc_data_id
	INTO
		v_doc_data_id;

	INSERT INTO doc_version
		(doc_id, version, filename, description, change_description, 
		 changed_by_sid, changed_dtm, doc_data_id, doc_type_id)
	VALUES
		(out_doc_id, v_this_version, in_filename, in_description, in_change_description, 
		 security_pkg.GetSID(), systimestamp, v_doc_data_id, in_document_type);
		 
	FinaliseSaveOrMoveDoc(out_doc_id, v_parent_sid, v_prev_version, v_this_version);
	doc_folder_pkg.FinaliseSave(v_parent_sid, in_filename);
END;

PROCEDURE CheckDocWritePermissions(
	in_doc_id			IN	doc.doc_id%TYPE
)
AS
	v_parent_sid	security_pkg.T_SID_ID;
BEGIN
	GetDocFolder(in_doc_id, v_parent_sid);

	-- check permission on folder 		   	
	doc_folder_pkg.CheckFolderAccess(v_parent_sid, security_pkg.PERMISSION_WRITE);
END;

PROCEDURE CheckDocReadPermissions(
	in_doc_id			IN	doc.doc_id%TYPE
)
AS
	v_parent_sid	security_pkg.T_SID_ID;
BEGIN
	GetDocFolder(in_doc_id, v_parent_sid);

	-- check permission on folder 		   	
	IF doc_folder_pkg.SQL_IsAccessAllowed(v_parent_sid, security_pkg.PERMISSION_READ) = 0 THEN
		csr_data_pkg.WriteAuditLogEntry_AT(
			in_audit_type_id => csr_data_pkg.AUDIT_TYPE_SUSPICIOUS,
			in_object_sid => v_parent_sid,
			in_description => 'Permission denied attempting to download file {0}',
			in_param_1 => in_doc_id
		);
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Read access denied on the parent folder with sid '||v_parent_sid||' of the document with id '||in_doc_id);
	END IF;
END;

PROCEDURE PrepareDownload(
	in_doc_id			IN		doc_version.doc_id%TYPE,
	io_version			IN OUT	doc_version.version%TYPE
)
AS
BEGIN
	CheckDocReadPermissions(in_doc_id);
	
	-- Use the current version if none supplied
	IF io_version IS NULL THEN
		SELECT COALESCE(version, pending_version)
		  INTO io_version 
	      FROM doc_current 
		 WHERE doc_id = in_doc_id;
	END IF;

	-- Record the download
	INSERT INTO doc_download
		(doc_id, version, downloaded_by_sid)
	VALUES
		(in_doc_id, io_version, security_pkg.GetSID());
END;
	
PROCEDURE GetDownloadData(
	in_doc_id			IN	doc_version.doc_id%TYPE,
	in_version			IN	doc_version.version%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN		
	OPEN out_cur FOR
		SELECT dd.mime_type, dv.filename, dv.changed_dtm, dd.data
		  FROM doc_version dv, doc_data dd
		 WHERE dv.doc_data_id = dd.doc_data_id AND 
		 	   dv.doc_id = in_doc_id AND dv.version = in_version;
END;

-- private
PROCEDURE SetLockedBySid(
	in_doc_id			IN	doc.doc_id%TYPE,
	in_locked_by_sid	IN	security_pkg.T_SID_ID -- new
)
AS
	v_locked_by_sid		security_pkg.T_SID_ID; -- current
	v_my_sid			security_pkg.T_SID_ID;
BEGIN
	CheckDocWritePermissions(in_doc_id);

	SELECT locked_by_sid
	  INTO v_locked_by_sid
	  FROM doc_current
	 WHERE doc_id = in_doc_id FOR UPDATE;

	v_my_sid := security_pkg.GetSID();

	IF v_locked_by_sid IS NOT NULL AND v_locked_by_sid <> v_my_sid THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_DOC_ALREADY_LOCKED, 'Document is locked for editing by '||v_locked_by_sid); -- avoids races
	END IF;

	UPDATE doc_current
	   SET locked_by_sid = in_locked_by_sid
	 WHERE doc_id = in_doc_id;
END;

PROCEDURE StartEditing(
	in_doc_id			IN	doc.doc_id%TYPE
)
AS
BEGIN
	SetLockedBySid(in_doc_id, security_pkg.GetSID());
END;
	
PROCEDURE CancelEditing(
	in_doc_id			IN	doc.doc_id%TYPE
)
AS
BEGIN
	SetLockedBySid(in_doc_id, NULL);
END;

PROCEDURE Approve(
	in_doc_id			IN	doc.doc_id%TYPE
)
AS
	v_locked_by_sid		security_pkg.T_SID_ID;
	v_my_sid			security_pkg.T_SID_ID;
	v_version			doc_version.version%TYPE;
	v_pending_version	doc_version.version%TYPE;
BEGIN
	CheckDocWritePermissions(in_doc_id);
	
	SELECT locked_by_sid, pending_version
	  INTO v_locked_by_sid, v_pending_version
	  FROM doc_current
	 WHERE doc_id = in_doc_id
	   FOR UPDATE;
	   
	v_my_sid := security_pkg.GetSID();
	
	IF v_locked_by_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Document cannot be approved because it is not locked by a user');
	ELSIF v_locked_by_sid != v_my_sid THEN
		RAISE_APPLICATION_ERROR(-20001, 'Document is locked for editing by '||v_locked_by_sid);
	END IF;
	
	-- XXX: why are we writing this row?
	
	--INSERT INTO doc_version (app_sid, doc_id, version, filename, description, change_description, changed_by_sid, changed_dtm, doc_data_id)
	--	SELECT dv.app_sid, dv.doc_id, v_pending_version version, dv.filename, dv.description, 'Approved', v_my_sid changed_by_sid, sysdate changed_dtm, dv.doc_data_id
	--	  FROM doc_version dv
	--	 WHERE doc_id = in_doc_id
	--	   AND version = in_version;

	UPDATE doc_current
	   SET version = v_pending_version, locked_by_sid = NULL, pending_version = NULL
	 WHERE doc_id = in_doc_id;
END;

PROCEDURE Reject(
	in_doc_id			IN	doc.doc_id%TYPE,
	in_message			IN	doc_version.change_description%TYPE
)
AS
	v_locked_by_sid		security_pkg.T_SID_ID;
	v_my_sid			security_pkg.T_SID_ID;
	v_pending_version	doc_version.version%TYPE;
	v_new_version		doc_version.version%TYPE;
BEGIN
	CheckDocWritePermissions(in_doc_id);
	
	SELECT locked_by_sid, pending_version, (SELECT NVL(MAX(version), 0)+1 FROM doc_version WHERE doc_id = in_doc_id)
	  INTO v_locked_by_sid, v_pending_version, v_new_version
	  FROM doc_current
	 WHERE doc_id = in_doc_id
	   FOR UPDATE;
	   
	v_my_sid := security_pkg.GetSID();
	
	IF v_locked_by_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Document cannot be rejected because it is not locked by a user');
	ELSIF v_locked_by_sid != v_my_sid THEN
		RAISE_APPLICATION_ERROR(-20001, 'Document is locked for editing by '||v_locked_by_sid);
	END IF;
		
	-- XXX: what do we do with the version we're rejecting?
	/*
	INSERT INTO doc_version (app_sid, doc_id, version, filename, description, change_description, changed_by_sid, changed_dtm, doc_data_id)
		SELECT dv.app_sid, dv.doc_id, (in_version+1) version, dv.filename, dv.description, 'Rejected', v_my_sid changed_by_sid, sysdate changed_dtm, dv.doc_data_id
		  FROM doc_version dv
		 WHERE doc_id = in_doc_id
		   AND version = in_version - 1;
	*/
	
	
	-- stuff in a revision that tells who rejected the document and why
	INSERT INTO doc_version (doc_id, version, filename, description, change_description, 
		changed_by_sid, changed_dtm, doc_data_id)
		SELECT doc_id, v_new_version, filename, description, in_message, 
			   security_pkg.GetSID(), SYSTIMESTAMP, doc_data_id
		  FROM doc_version
		 WHERE doc_id = in_doc_id AND version = v_pending_version;
		 
	
	UPDATE doc_current
	   SET locked_by_sid = NULL, pending_version = NULL
	 WHERE doc_id = in_doc_id;
END;

PROCEDURE GetDocuments(
	in_folder_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_documents_folder_name		doc_folder_name_translation.translated%TYPE;
	v_can_edit					NUMBER := doc_folder_pkg.SQL_IsAccessAllowed(in_folder_sid, security_pkg.PERMISSION_WRITE);
BEGIN
	doc_folder_pkg.CheckFolderAccess(in_folder_sid, security_pkg.PERMISSION_LIST_CONTENTS);

	OPEN out_cur FOR
		SELECT d.parent_sid, d.doc_id, d.version, d.mime_type, d.sha1, d.filename, 
			   d.description, d.change_description, d.changed_dtm, d.changed_by_sid, 
			   cu1.full_name changed_by, cu1.email changed_by_email,
			   d.locked_by_sid, d.pending_version, d.lifespan, d.expiry_status, d.locked_by_me,
			   d.doc_type_id, d.doc_type_name,
			   cu2.full_name locked_by, cu2.email locked_by_email,
			   NVL2(dn.notify_sid, 1, 0) notify_me,
			   null folder_path, -- we don't display the folder_path for a single folder, so no need to calculate it
			   v_can_edit can_edit
		  FROM v$doc_current_status d
		  JOIN csr_user cu1 ON d.changed_by_sid = cu1.csr_user_sid
		  LEFT JOIN doc_subscription dn ON d.doc_id = dn.doc_id AND dn.notify_sid = security_pkg.GetSID()
		  LEFT JOIN csr_user cu2 ON d.locked_by_sid = cu2.csr_user_sid
		 WHERE d.parent_sid = in_folder_sid
		 ORDER BY d.doc_id;
END;

PROCEDURE GetTrash(
	in_folder_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_sid_id				security_pkg.T_SID_ID := security_pkg.GetSID();
	v_trash_folder_sid		security_pkg.T_SID_ID;
	v_trash_folder_name		doc_folder_name_translation.translated%TYPE;
	v_trash_admin			NUMBER := doc_folder_pkg.SQL_IsAccessAllowed(in_folder_sid, security_pkg.PERMISSION_DELETE);
BEGIN
	doc_folder_pkg.CheckFolderAccess(in_folder_sid, security_pkg.PERMISSION_READ);
	
	v_trash_folder_sid := doc_folder_pkg.GetTrashFolder(in_folder_sid);
	doc_folder_pkg.PopulateTempTreeWithFolders(
		in_parent_sid		=> v_trash_folder_sid
	);
	
	v_trash_folder_name := doc_folder_pkg.GetFolderName(
		in_folder_sid	=> v_trash_folder_sid
	);

	OPEN out_cur FOR
		SELECT d.parent_sid, d.doc_id, d.version, d.mime_type, d.sha1, d.filename, 
			   d.description, d.change_description, d.changed_dtm, d.changed_by_sid, 
			   cu1.full_name changed_by, cu1.email changed_by_email,
			   d.locked_by_sid, d.pending_version, d.lifespan, d.expiry_status,
			   d.locked_by_me, d.doc_type_id, d.doc_type_name,
			   cu2.full_name locked_by, cu2.email locked_by_email,
			   NVL2(dn.notify_sid, 1, 0) notify_me,
			   SUBSTR(tt.path, LENGTH(v_trash_folder_name) + 3) folder_path,
			   v_trash_admin can_edit
		  FROM v$doc_current_status d
		  JOIN temp_tree tt ON d.parent_sid = tt.sid_id
		  JOIN csr_user cu1 ON d.changed_by_sid = cu1.csr_user_sid
		  LEFT JOIN doc_subscription dn ON d.doc_id = dn.doc_id AND dn.notify_sid = v_sid_id
		  LEFT JOIN csr_user cu2 ON d.locked_by_sid = cu2.csr_user_sid
		 WHERE d.parent_sid = in_folder_sid
		   AND (v_trash_admin = 1 OR d.locked_by_sid = v_sid_id)
		 ORDER BY d.doc_id;
END;

PROCEDURE DeleteDocsINTERNAL
AS
BEGIN
	DELETE FROM doc_notification
	 WHERE doc_id IN (SELECT doc_id FROM temp_doc_id);
	 
	DELETE FROM doc_download
	 WHERE doc_id IN (SELECT doc_id FROM temp_doc_id);
	 
	DELETE FROM doc_subscription
	 WHERE doc_id IN (SELECT doc_id FROM temp_doc_id);
	 
	DELETE FROM doc_current
	 WHERE doc_id IN (SELECT doc_id FROM temp_doc_id);

	DELETE FROM doc_version
	 WHERE doc_id IN (SELECT doc_id FROM temp_doc_id);

	DELETE FROM attachment_history
	 WHERE attachment_id IN (SELECT attachment_id FROM attachment a JOIN temp_doc_id d ON a.doc_id = d.doc_id);
	 
	DELETE FROM section_fact_attach
	 WHERE attachment_id IN (SELECT attachment_id FROM attachment a JOIN temp_doc_id d ON a.doc_id = d.doc_id);
	 
	DELETE FROM attachment
	 WHERE doc_id IN (SELECT doc_id FROM temp_doc_id);
	
	DELETE FROM section_content_doc_wait
	 WHERE doc_id IN (SELECT doc_id FROM temp_doc_id);
	
	DELETE FROM section_content_doc
	 WHERE doc_id IN (SELECT doc_id FROM temp_doc_id);
	
	DELETE FROM tpl_report_sched_saved_doc
	 WHERE doc_id IN (SELECT doc_id FROM temp_doc_id);
	
	DELETE FROM doc
	 WHERE doc_id IN (SELECT doc_id FROM temp_doc_id);

	-- This is a bit scrappy -- we really need to revise the data structure
	DELETE FROM doc_data
	 WHERE doc_data_id NOT IN (SELECT doc_data_id
	 						     FROM doc_version);
END;

PROCEDURE EmptyTrash(
	in_folder_sid			IN	security_pkg.T_SID_ID
)
AS
	v_doc_library_sid		security_pkg.T_SID_ID;
	v_sid_id				security_pkg.T_SID_ID;
	v_trash_admin			BINARY_INTEGER;
BEGIN
	IF in_folder_sid <> doc_folder_pkg.GetTrashFolder(in_folder_sid) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'The folder with sid '||in_folder_sid||' is not a trash folder');
	END IF;
	v_trash_admin := security_pkg.SQL_IsAccessAllowedSID(security_pkg.GetACT(), in_folder_sid, security_pkg.PERMISSION_DELETE);
	v_doc_library_sid := doc_folder_pkg.GetLibraryContainer(in_folder_sid);
	v_sid_id := security_pkg.GetSID();
	
	-- let's actually clean it up
	DELETE FROM temp_doc_id;
	INSERT INTO temp_doc_id (doc_id)
		SELECT doc_id
	 	  FROM doc_current
	 	 WHERE parent_sid = in_folder_sid AND (v_trash_admin = 1 OR locked_by_sid = v_sid_id);
	DeleteDocsINTERNAL;
END;

PROCEDURE GetMyDocuments(
	in_documents_sid				IN	security_pkg.T_SID_ID,
	in_pending_approval				IN	NUMBER, -- NULL => anything; 1 = just pending_approval; 0 = not pending_approval
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_documents_folder_name				doc_folder_name_translation.translated%TYPE;
	v_sid_id							security_pkg.T_SID_ID := security_pkg.GetSID();
BEGIN
	doc_folder_pkg.PopulateTempTreeWithFolders(
		in_parent_sid		=> in_documents_sid
	);

	v_documents_folder_name := doc_folder_pkg.GetFolderName(
		in_folder_sid	=> in_documents_sid
	);

	OPEN out_cur FOR
		SELECT d.parent_sid, d.doc_id, d.version, d.mime_type, d.sha1, d.filename, 
			   d.description, d.change_description, d.changed_dtm, d.changed_by_sid, 
			   cu1.full_name changed_by, cu1.email changed_by_email,
			   d.locked_by_sid, cu2.full_name locked_by, cu2.email locked_by_email,
			   1 locked_by_me, d.pending_version, NVL2(dn.notify_sid, 1, 0) notify_me,
			   d.expiry_status,  -- XXX: previously benny always showed this as "in date" -- not sure why...?
			   SUBSTR(tt.path, LENGTH(v_documents_folder_name) + 3) folder_path,
			   d.doc_type_id, d.doc_type_name,
		       doc_folder_pkg.SQL_IsAccessAllowed(tt.sid_id, security_pkg.PERMISSION_WRITE) can_edit
		  FROM v$doc_current_status d, csr_user cu1, csr_user cu2, doc_subscription dn,
		  	   temp_tree tt
		 WHERE d.changed_by_sid = cu1.csr_user_sid AND
		 	   d.locked_by_sid = v_sid_id AND d.locked_by_sid = cu2.csr_user_sid AND
		 	   d.doc_id = dn.doc_id(+) AND dn.notify_sid(+) = v_sid_id AND
		 	   d.parent_sid = tt.sid_id AND 
		 	   (in_pending_approval IS NULL OR NVL2(d.pending_version, 1, 0) = in_pending_approval)
	  ORDER BY d.doc_id;
END;

PROCEDURE SearchAddMimeType(
	in_mime_type		IN	temp_mime_types.mime_type%TYPE
)
AS
BEGIN
	INSERT INTO temp_mime_types (mime_type) VALUES (in_mime_type);
END;

PROCEDURE SearchDocuments(
	in_documents_sid				IN	security_pkg.T_SID_ID,
	in_phrase						IN	VARCHAR2,
	in_since						IN	DATE,
	in_use_mime						IN	NUMBER,	
	in_limit						IN	NUMBER,
	out_count						OUT	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_documents_folder_name				doc_folder_name_translation.translated%TYPE;
	v_sid_id							security_pkg.T_SID_ID := security_pkg.GetSID();
BEGIN
	out_count:=100;
	
	-- This hack works around the fact that Oracle crashes if you use a user function
	-- in a query containing CONTAINS:
	-- https://metalink.oracle.com/metalink/plsql/f?p=130:14:8256320231539974957::::p14_database_id,p14_docid,p14_show_header,p14_show_help,p14_black_frame,p14_font:NOT,6685261.8,1,0,1,helvetica
	-- bug 6685261
	-- there is a patch for linux-x86 but not for amd64
	-- NOTE: IF COMPILING THIS FAILS, CHECK YOU HAVE ORACLE TEXT, SEE https://fogbugz.credit360.com/default.asp?W289	
	doc_folder_pkg.PopulateTempTreeWithFolders(
		in_parent_sid	=> in_documents_sid
	);
	v_documents_folder_name := doc_folder_pkg.GetFolderName(
		in_folder_sid	=> in_documents_sid
	);
	
	OPEN out_cur FOR
		SELECT *
		  FROM (SELECT d.parent_sid, d.doc_id, d.version, d.mime_type, d.sha1, d.filename, 
					   d.description, d.change_description, d.changed_dtm, d.changed_by_sid, 
					   cu1.full_name changed_by, cu1.email changed_by_email,
					   d.locked_by_sid, d.pending_version, d.lifespan, SCORE(1) score,
					   ctx_doc.snippet('ix_doc_search', ctx_doc.pkencode(d.app_sid, d.doc_data_id), in_phrase) summary,
					   d.expiry_status, d.locked_by_me, d.doc_type_id, d.doc_type_name,
					   cu2.full_name locked_by, cu2.email locked_by_email,
					   NVL2(dn.notify_sid, 1, 0) notify_me,
					   SUBSTR(f.path, LENGTH(v_documents_folder_name) + 3) folder_path
				  FROM v$doc_approved d
				  JOIN csr_user cu1 ON d.changed_by_sid = cu1.csr_user_sid
				  JOIN temp_tree f ON d.parent_sid = f.sid_id
				  LEFT JOIN doc_subscription dn ON d.doc_id = dn.doc_id AND dn.notify_sid = v_sid_id
				  LEFT JOIN csr_user cu2 ON d.locked_by_sid = cu2.csr_user_sid
				 WHERE (CONTAINS(d.data, in_phrase, 1) > 0 OR LOWER(d.filename) LIKE '%'||LOWER(in_phrase)||'%')
				   AND (in_since IS NULL OR d.changed_dtm >= in_since)
				   AND (in_use_mime = 0 OR LOWER(d.mime_type) IN (SELECT mime_type FROM temp_mime_types))
				 ORDER BY score DESC  
				)
		 WHERE ROWNUM <= in_limit;
END;

PROCEDURE GetRecentlyChanged(
	in_documents_sid				IN	security_pkg.T_SID_ID,
	in_since						IN	DATE,
	in_limit						IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_documents_folder_name				doc_folder_name_translation.translated%TYPE;
	v_sid_id							security_pkg.T_SID_ID := security_pkg.GetSID();
	v_act_id							security_pkg.T_ACT_ID := security_pkg.GetACT();
BEGIN	
	doc_folder_pkg.PopulateTempTreeWithFolders(
		in_parent_sid		=> in_documents_sid
	);

	v_documents_folder_name := doc_folder_pkg.GetFolderName(
		in_folder_sid	=> in_documents_sid
	);	
	
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/*
		  FROM (SELECT d.parent_sid, d.doc_id, d.version, d.mime_type, d.sha1, d.filename, 
					   d.description, d.change_description, d.changed_dtm, d.changed_by_sid, 
					   cu1.full_name changed_by, cu1.email changed_by_email,
					   d.locked_by_sid, d.pending_version, d.lifespan, d.expiry_status, d.locked_by_me, 
					   d.doc_type_id, d.doc_type_name,
					   doc_folder_pkg.SQL_IsAccessAllowed(tt.sid_id, security_pkg.PERMISSION_WRITE) can_edit,
					   cu2.full_name locked_by, cu2.email locked_by_email,
					   NVL2(dn.notify_sid, 1, 0) notify_me,
					   SUBSTR(tt.path, LENGTH(v_documents_folder_name) + 3) folder_path
				  FROM v$doc_current_status d
				  JOIN csr_user cu1 ON d.changed_by_sid = cu1.csr_user_sid
				  JOIN temp_tree tt ON d.parent_sid = tt.sid_id
				  LEFT JOIN doc_subscription dn ON d.doc_id = dn.doc_id AND dn.notify_sid = v_sid_id
				  LEFT JOIN csr_user cu2 ON d.locked_by_sid = cu2.csr_user_sid
				 WHERE (in_since IS NULL OR d.changed_dtm >= in_since)
				 ORDER BY d.changed_dtm DESC 
			   )
		 WHERE ROWNUM <= in_limit;
END;

PROCEDURE SubscribeToFolder(
	in_folder_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	-- you just need read permissions for subscriptions
	doc_folder_pkg.CheckFolderAccess(in_folder_sid, security_pkg.PERMISSION_READ);
	
	BEGIN
		INSERT INTO doc_folder_subscription (doc_folder_sid, notify_sid)
		VALUES (in_folder_sid, security_pkg.GetSID());
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE UnsubscribeFromFolder(
	in_folder_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	-- you just need read permissions for subscriptions
	doc_folder_pkg.CheckFolderAccess(in_folder_sid, security_pkg.PERMISSION_READ);
	
	DELETE FROM doc_folder_subscription
	 WHERE doc_folder_sid = in_folder_sid 
	   AND notify_sid = security_pkg.GetSID();
END;


PROCEDURE Subscribe(
	in_doc_id			IN	doc.doc_id%TYPE
)
AS
BEGIN
	CheckDocReadPermissions(in_doc_id);
	BEGIN
		INSERT INTO doc_subscription (doc_id, notify_sid)
		VALUES (in_doc_id, security_pkg.GetSID());
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE Unsubscribe(
	in_doc_id			IN	doc.doc_id%TYPE
)
AS
BEGIN
	CheckDocReadPermissions(in_doc_id);
	DELETE FROM doc_subscription
	 WHERE doc_id = in_doc_id AND notify_sid = security_pkg.GetSID();
END;

PROCEDURE DeleteDoc(
	in_doc_id				IN	doc.doc_id%TYPE,
	in_change_description	IN	doc_version.change_description%TYPE
)
AS
	v_parent_sid		security_pkg.T_SID_ID;
	v_version			doc_version.version%TYPE;
	v_doc_filename		doc_version.filename%TYPE;
BEGIN
	BEGIN
		SELECT parent_sid, CASE WHEN version IS NOT NULL AND version >= NVL(pending_version, 0) THEN version ELSE pending_version END + 1
		  INTO v_parent_sid, v_version
		  FROM doc_current
		 WHERE doc_id = in_doc_id AND (SELECT MAX(version) FROM doc_version WHERE doc_id = in_doc_id) IN (pending_version, version) FOR UPDATE;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 
				'The document with id '||in_doc_id||' could not be found.');
	END;
		
	doc_folder_pkg.CheckFolderAccess(v_parent_sid, security_pkg.PERMISSION_WRITE);
	
	-- TODO: check if the folder is owned by someone -- if so then only they can delete [or maybe stuff in some capability for admins ?] 
	
	
	-- stuff in a revision that tells who deleted the document
	INSERT INTO doc_version (doc_id, version, filename, description, change_description, 
		changed_by_sid, changed_dtm, doc_data_id)
		SELECT doc_id, v_version, filename, description, in_change_description, 
			   security_pkg.GetSID(), systimestamp, doc_data_id
		  FROM doc_version
		 WHERE doc_id = in_doc_id AND version = v_version - 1;
	
	-- Send alert mails -- we have to do this before we move the file to the
	-- trash since the query looks at folders people are subscribed to, so we need the
	-- doc_current to point to the folder BEFORE we deleted for the query to work.
	Notify(in_doc_id, v_version, 'DELETED');
			
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

	doc_folder_pkg.FinaliseDelete(v_parent_sid, v_doc_filename);
END;

PROCEDURE MoveDoc(
	in_doc_id				IN	doc.doc_id%TYPE,
	in_new_parent_sid		IN	doc_folder.doc_folder_sid%TYPE,
	in_change_description	IN	doc_version.change_description%TYPE
)
AS
	v_old_parent_sid		security_pkg.T_SID_ID;
	v_prev_version			doc_version.version%TYPE;
	v_this_version			doc_version.version%TYPE;
	v_pending_version		doc_version.version%TYPE;
BEGIN
	BEGIN
		SELECT parent_sid, version, (SELECT NVL(MAX(version), 0)+1 FROM doc_version WHERE doc_id = in_doc_id), pending_version
		  INTO v_old_parent_sid, v_prev_version, v_this_version, v_pending_version
		  FROM doc_current
		 WHERE doc_id = in_doc_id FOR UPDATE;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND,
				'The document with id '||in_doc_id||' could not be found');
	END;
	
	-- write on parent is required to delete the file from that folder
	IF doc_folder_pkg.SQL_IsAccessAllowed(in_new_parent_sid, security_pkg.PERMISSION_ADD_CONTENTS) = 0 OR
	   doc_folder_pkg.SQL_IsAccessAllowed(v_old_parent_sid, security_pkg.PERMISSION_WRITE) = 0 
	THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Access denied moving the document with id '||in_doc_id||' under the folder with sid '||in_new_parent_sid);
	END IF;
	
	UPDATE doc_current
	   SET parent_sid = in_new_parent_sid
	 WHERE doc_id = in_doc_id;

	-- stuff in a revision that tells who moved the document
	INSERT INTO doc_version (doc_id, version, filename, description, change_description, 
		changed_by_sid, changed_dtm, doc_data_id)
		SELECT doc_id, v_this_version, filename, description, in_change_description,
			   security_pkg.GetSID(), systimestamp, doc_data_id
		  FROM doc_version
		 WHERE doc_id = in_doc_id AND version = v_prev_version;
	 
	FinaliseSaveOrMoveDoc(in_doc_id, in_new_parent_sid, null, v_this_version);
END;

PROCEDURE GetDocHistory(
	in_doc_id			IN	doc.doc_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	CheckDocReadPermissions(in_doc_id);
	OPEN out_cur FOR
		SELECT dv.doc_id, dv.version, dv.filename, dv.description,
			   dv.change_description, dv.changed_dtm, dv.changed_by_sid, 
			   cu.full_name changed_by, cu.email changed_by_email,
			   dt.doc_type_id, dt.name doc_type_name
		  FROM doc_version dv
		  JOIN csr_user cu ON dv.changed_by_sid = cu.csr_user_sid 
		  LEFT JOIN doc_type dt ON dt.doc_type_id = dv.doc_type_id
		 WHERE doc_id = in_doc_id
	  ORDER BY version DESC;
END;

PROCEDURE GetDownloadHistory(
	in_doc_id			IN	doc.doc_id%TYPE,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	CheckDocReadPermissions(in_doc_id);
	OPEN out_cur FOR
		SELECT dd.doc_id, dd.version, dv.filename, dv.description, dd.downloaded_by_sid,
			   cu.full_name downloaded_by, cu.email downloaded_by_email, dd.downloaded_dtm
		  FROM doc_download dd, doc_version dv, csr_user cu
		 WHERE dd.doc_id = in_doc_id AND dv.doc_id = in_doc_id AND 
		 	   dd.doc_id = dv.doc_id AND dd.version = dv.version AND 
		 	   dd.downloaded_by_sid = cu.csr_user_sid
	  ORDER BY dd.downloaded_dtm DESC;
END;

PROCEDURE RestoreDocument(
	in_doc_id				IN	doc.doc_id%TYPE,
	in_folder_sid			IN	doc_folder.doc_folder_sid%TYPE,
	in_change_description	IN	doc_version.change_description%TYPE
)
AS
	v_act_id				security_pkg.T_ACT_ID := security_pkg.GetACT();
	v_sid_id				security_pkg.T_SID_ID := security_pkg.GetSID();
	v_doc_folder_sid		security_pkg.T_SID_ID;
	v_trash_folder_sid		security_pkg.T_SID_ID;
	v_locked_by_sid			security_pkg.T_SID_ID;
	v_version				doc_version.version%TYPE;
BEGIN	
	-- Check that the restore to folder can be written
	IF doc_folder_pkg.SQL_IsAccessAllowed(in_folder_sid, security_pkg.PERMISSION_ADD_CONTENTS) = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 
			'Access denied restoring '||in_doc_id||' when writing to the folder with '||in_folder_sid);
	END IF;
	
	-- Check that the document actually is in the trash
	BEGIN
		SELECT parent_sid, locked_by_sid, version + 1
		  INTO v_doc_folder_sid, v_locked_by_sid, v_version
		  FROM doc_current
		 WHERE doc_id = in_doc_id FOR UPDATE;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND,
				'The document with id '||in_doc_id||' was not found');
	END;
	v_trash_folder_sid := doc_folder_pkg.GetTrashFolder(v_doc_folder_sid);
	IF v_trash_folder_sid <> v_doc_folder_sid THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Access denied trying to restore '||in_doc_id||' because it is in the folder with sid '||
			v_doc_folder_sid||' which isn''t in the trash folder with sid '||v_trash_folder_sid);
	END IF;
	
	-- If we haven't got it locked, we need delete permission on the trash
	IF v_locked_by_sid <> v_sid_id THEN
		IF NOT security_pkg.IsAccessAllowedSID(v_act_id, v_trash_folder_sid, security_pkg.PERMISSION_DELETE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
				'Access denied restoring '||in_doc_id||' when deleting from the trash folder with sid '||v_trash_folder_sid);
		END IF;
	END IF;
	
	-- stuff in a revision that tells who deleted the document
	INSERT INTO doc_version (doc_id, version, filename, description, change_description, 
		changed_by_sid, changed_dtm, doc_data_id)
		SELECT doc_id, v_version, filename, description, in_change_description,
			   security_pkg.GetSID(), systimestamp, doc_data_id
		  FROM doc_version
		 WHERE doc_id = in_doc_id AND version = v_version - 1;

	-- Ok, good to restore
	UPDATE doc_current
	   SET parent_sid = in_folder_sid, locked_by_sid = null, version = v_version
	 WHERE doc_id = in_doc_id;

	-- Send alert mails
	Notify(in_doc_id, v_version, 'RESTORED');
END;

PROCEDURE GetNotifications(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT c.app_sid, c.app_sid, dl.doc_library_sid,
			   dn.doc_notification_id, d.parent_sid doc_folder_sid, dn.doc_id, dn.version, 
		       dn.notify_sid, tou.full_name notify_full_name, tou.email notify_email,
		       dv.changed_by_sid, fromu.full_name changed_by, fromu.email changed_by_email,
		       dv.filename, dv.description, dv.change_description, dv.changed_dtm, c.scheduled_tasks_disabled,
			   dn.reason -- TODO: fix up notifcation code to do something sensible with this
		  FROM doc_current d, doc_notification dn, doc_version dv, csr_user tou, csr_user fromu,
           	   v$doc_folder_root dr, doc_library dl, customer c
		 WHERE dn.app_sid = dv.app_sid AND dn.doc_id = dv.doc_id AND dn.version = dv.version AND
		 	   dn.app_sid = tou.app_sid AND dn.notify_sid = tou.csr_user_sid AND
		 	   dv.app_sid = fromu.app_sid AND dv.changed_by_sid = fromu.csr_user_sid AND 
		 	   dn.sent_dtm IS NULL AND
           	   d.app_sid = dv.app_sid AND d.doc_id = dv.doc_id AND 
           	   d.app_sid = dn.app_sid AND d.doc_id = dn.doc_id AND
           	   d.parent_sid = dr.doc_folder_sid AND dr.doc_library_sid = dl.doc_library_sid AND
           	   dl.app_sid = c.app_sid
	  ORDER BY doc_notification_id;
END;

PROCEDURE MarkNotificationSent(
	in_doc_notification_id	IN	doc_notification.doc_notification_id%TYPE
)
AS
BEGIN
	UPDATE doc_notification
	   SET sent_dtm = SYSDATE
	 WHERE doc_notification_id = in_doc_notification_id;
	IF SQL%ROWCOUNT = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND,
			'The notification with id '||in_doc_notification_id||' was not found');
	END IF;
END;

PROCEDURE GetDocumentTree(
	in_folder_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_sid_id			security_pkg.T_SID_ID;
	v_act_id			security_pkg.T_ACT_ID;
	v_parents_table		security.T_SO_TABLE;
	v_has_doclib_parent	NUMBER(10);
	v_is_docfolder		NUMBER(10);
BEGIN
	v_act_id := security_pkg.GetACT();
	v_sid_id := security_pkg.GetSID();
	
	-- Ensure we are a document folder under a document library, otherwise passing an
	-- arbitrary SID could expose other parts of the Securable Object hierarchy
	v_parents_table	:= securableobject_pkg.GetParentsAsTable(v_act_id, in_folder_sid);

	SELECT COUNT(*) INTO v_has_doclib_parent
	  FROM TABLE(v_parents_table)
	 WHERE class_id = class_pkg.GetClassID('DocLibrary');

	SELECT COUNT(*) INTO v_is_docfolder
	  FROM TABLE(v_parents_table)
	 WHERE sid_id = in_folder_sid
	   AND class_id = class_pkg.GetClassID('DocFolder');

	IF v_has_doclib_parent = 0 OR v_is_docfolder = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - must be a document folder below a document library: ' || in_folder_sid);
	END IF;
	
	doc_folder_pkg.PopulateTempTreeWithFolders(in_folder_sid);
	
	INSERT INTO doc_download (APP_SID, DOC_ID, VERSION, DOWNLOADED_DTM, DOWNLOADED_BY_SID)
	SELECT doc.app_sid, d.doc_id, d.version, SYSDATE, v_sid_id
	  FROM v$doc_current d, temp_tree t, doc doc
	 WHERE t.sid_id = d.parent_sid(+)
	   AND d.doc_id = doc.doc_id
	   AND d.doc_id IS NOT NULL
	   AND d.data IS NOT NULL;
	
	OPEN out_cur FOR
		SELECT t.path, d.filename, d.changed_dtm, d.data, d.doc_id
		  FROM v$doc_current d, temp_tree t
		 WHERE t.sid_id = d.parent_sid(+);
END;

END doc_pkg;
/
