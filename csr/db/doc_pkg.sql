CREATE OR REPLACE PACKAGE CSR.doc_pkg AS

PROCEDURE GetDocFolderAndLibrary(
	in_doc_id				IN	doc.doc_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE SaveDoc(
	in_doc_id				IN	doc.doc_id%TYPE,
	in_parent_sid			IN	security_pkg.T_SID_ID,
	in_filename				IN	doc_version.filename%TYPE,
	in_mime_type			IN	doc_data.mime_type%TYPE,
	in_data					IN	doc_data.data%TYPE,
	in_description			IN	doc_version.description%TYPE,
	in_change_description	IN	doc_version.change_description%TYPE,
	in_document_type		IN	doc_version.doc_type_id%TYPE DEFAULT NULL,
	out_doc_id				OUT	doc.doc_id%TYPE
);

PROCEDURE CheckDocReadPermissions(
	in_doc_id			IN	doc.doc_id%TYPE
);

PROCEDURE PrepareDownload(
	in_doc_id			IN		doc_version.doc_id%TYPE,
	io_version			IN OUT	doc_version.version%TYPE
);

/**
 * Retrieve a document with no security checks.
 * You need to call PrepareDownload first!
 *
 * This is only done like this because you can't do INSERTs, etc
 * in a stored procedure where the output is being registered for 
 * Oracle change notifications (throws an ORA-29973: Unsupported query or 
 * operation during change notification registration).
 *
 * This includes security checks -- the error is thrown when running
 * the last_used update statement in the ACT table).
 */
PROCEDURE GetDownloadData(
	in_doc_id			IN	doc_version.doc_id%TYPE,
	in_version			IN	doc_version.version%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE StartEditing(
	in_doc_id			IN	doc.doc_id%TYPE
);

PROCEDURE CancelEditing(
	in_doc_id			IN	doc.doc_id%TYPE
);

PROCEDURE Approve(
	in_doc_id			IN	doc.doc_id%TYPE
);

PROCEDURE Reject(
	in_doc_id			IN	doc.doc_id%TYPE,
	in_message			IN	doc_version.change_description%TYPE
);

PROCEDURE GetDocuments(
	in_folder_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetMyDocuments(
	in_documents_sid	IN	security_pkg.T_SID_ID,
	in_pending_approval	IN	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetTrash(
	in_folder_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE SearchAddMimeType(
	in_mime_type		IN	temp_mime_types.mime_type%TYPE
);

PROCEDURE SearchDocuments(
	in_documents_sid	IN	security_pkg.T_SID_ID,
	in_phrase			IN	VARCHAR2,
	in_since			IN	DATE,
	in_use_mime			IN	NUMBER,
	in_limit			IN	NUMBER,
	out_count			OUT	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetRecentlyChanged(
	in_documents_sid	IN	security_pkg.T_SID_ID,
	in_since			IN	DATE,
	in_limit			IN	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE SubscribeToFolder(
	in_folder_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE UnsubscribeFromFolder(
	in_folder_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE Subscribe(
	in_doc_id			IN	doc.doc_id%TYPE
);

PROCEDURE Unsubscribe(
	in_doc_id			IN	doc.doc_id%TYPE
);

PROCEDURE DeleteDoc(
	in_doc_id				IN	doc.doc_id%TYPE,
	in_change_description	IN	doc_version.change_description%TYPE
);

PROCEDURE MoveDoc(
	in_doc_id				IN	doc.doc_id%TYPE,
	in_new_parent_sid		IN	doc_folder.doc_folder_sid%TYPE,
	in_change_description	IN	doc_version.change_description%TYPE
);

PROCEDURE GetDocHistory(
	in_doc_id			IN	doc.doc_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetDownloadHistory(
	in_doc_id			IN	doc.doc_id%TYPE,
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE RestoreDocument(
	in_doc_id				IN	doc.doc_id%TYPE,
	in_folder_sid			IN	doc_folder.doc_folder_sid%TYPE,
	in_change_description	IN	doc_version.change_description%TYPE
);

PROCEDURE DeleteDocsINTERNAL;

PROCEDURE EmptyTrash(
	in_folder_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE GetNotifications(
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE MarkNotificationSent(
	in_doc_notification_id	IN	doc_notification.doc_notification_id%TYPE
);

PROCEDURE GetDocumentTree(
	in_folder_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

END doc_pkg;
/
