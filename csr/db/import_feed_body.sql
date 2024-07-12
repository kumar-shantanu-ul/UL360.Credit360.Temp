CREATE OR REPLACE PACKAGE BODY CSR.IMPORT_FEED_PKG
AS

PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
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
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
)
AS
BEGIN
	UPDATE import_feed
	   SET name = in_new_name
	 WHERE import_feed_sid = in_sid_id;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE FROM import_feed_request
	 WHERE import_feed_sid = in_sid_id;
	 
	DELETE FROM import_feed
	 WHERE import_feed_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE TrashObject(
	in_act_id	IN	security_pkg.T_ACT_ID,	
	in_sid_id	IN 	security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE CreateFeed(
	in_name				IN	security_pkg.T_SO_NAME,
	out_feed_sid		OUT	security_pkg.T_SID_ID
)
AS
	v_act	security.security_pkg.T_ACT_ID := security_pkg.GetACT;
	v_app	security.security_pkg.T_SID_ID := security_pkg.GetApp;
BEGIN
	group_pkg.CreateGroupWithClass(v_act, security.securableobject_pkg.GetSIDFromPath(v_act, v_app, 'ImportFeeds'), security_pkg.GROUP_TYPE_SECURITY,
		Replace(in_name,'/','\'), class_pkg.getClassID('CSRImportFeed'), out_feed_sid); --'
	
	acl_pkg.AddACE(v_act, acl_pkg.GetDACLIDForSID(out_feed_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
	security_pkg.ACE_FLAG_DEFAULT, out_feed_sid, security_pkg.PERMISSION_STANDARD_READ);

	INSERT INTO import_feed (import_feed_sid, app_sid, name)
	VALUES (out_feed_sid, v_app, in_name);

	csr_data_pkg.WriteAuditLogEntry(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app, out_feed_sid,
		'Created "{0}"', in_name);
END;

PROCEDURE GetImportFeed(
	in_import_feed_sid		IN	security_pkg.T_SID_ID,
	out_import_feed_cur		OUT	security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getact, in_import_feed_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the import feed with sid ' || in_import_feed_sid);
	END IF;	
		
	OPEN out_import_feed_cur FOR
		SELECT import_feed_sid, name
		  FROM import_feed
		 WHERE import_feed_sid = in_import_feed_sid;
END;

PROCEDURE UNSEC_GetUnprocessedRequests(
	in_import_feed_sid		IN	security_pkg.T_SID_ID,
	out_requests_cur		OUT	security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_requests_cur FOR
		SELECT import_feed_sid, import_feed_request_id, file_data, filename, mime_type, created_dtm
		  FROM import_feed_request
		 WHERE import_feed_sid = in_import_feed_sid
		   AND processed_dtm IS NULL;
END;

PROCEDURE GetImportFeedSid(
	in_name				IN	security_pkg.T_SO_NAME,
	out_feed_sid		OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	SELECT import_feed_sid
	  INTO out_feed_sid
	  FROM import_feed
	 WHERE name = in_name;
	 
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, out_feed_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the import feed with sid ' || out_feed_sid);
	END IF;
END;

PROCEDURE CreateImportFeedRequest(
	in_import_feed_sid			IN	security_pkg.T_SID_ID,
	in_file_data				IN	import_feed_request.file_data%TYPE,
	in_filename					IN	import_feed_request.filename%TYPE,
	in_mime_type				IN	import_feed_request.mime_type%TYPE,
	out_import_feed_request_id	OUT	import_feed_request.import_feed_request_id%TYPE
)
AS
BEGIN
	INSERT INTO import_feed_request (import_feed_sid, import_feed_request_id, file_data, filename, mime_type, created_dtm) 
		 VALUES (in_import_feed_sid, import_feed_request_id_seq.nextval, in_file_data, in_filename, in_mime_type, SYSDATE) 
	  RETURNING import_feed_request_id INTO out_import_feed_request_id;
END;

PROCEDURE UpdateImportFeedRequest(
	in_import_feed_request_id	IN	import_feed_request.import_feed_request_id%TYPE,
	in_failed_data				IN	import_feed_request.failed_data%TYPE,
	in_failed_filename			IN	import_feed_request.failed_filename%TYPE,
	in_failed_mime_type			IN	import_feed_request.failed_mime_type%TYPE,
	in_process_dtm				IN	import_feed_request.processed_dtm%TYPE,
	in_rows_imported			IN	import_feed_request.rows_imported%TYPE,
	in_rows_updated				IN	import_feed_request.rows_updated%TYPE,
	in_errors					IN	import_feed_request.errors%TYPE
)
AS
BEGIN
	UPDATE import_feed_request
	   SET failed_data = in_failed_data, failed_filename = in_failed_filename,
		   failed_mime_type = in_failed_mime_type, processed_dtm = in_process_dtm,
		   rows_imported = in_rows_imported, rows_updated = in_rows_updated, errors = in_errors
	 WHERE import_feed_request_id = in_import_feed_request_id;
END;

END IMPORT_FEED_PKG;
/
