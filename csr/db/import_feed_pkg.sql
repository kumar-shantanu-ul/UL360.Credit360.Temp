CREATE OR REPLACE PACKAGE CSR.IMPORT_FEED_PKG
AS

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

/**
 * TrashObject
 * 

 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 */
PROCEDURE TrashObject(
	in_act_id	IN	security_pkg.T_ACT_ID,	
	in_sid_id	IN  security_pkg.T_SID_ID
);

PROCEDURE CreateFeed(
	in_name				IN security_pkg.T_SO_NAME,
	out_feed_sid		OUT security_pkg.T_SID_ID
);

PROCEDURE GetImportFeed(
	in_import_feed_sid		IN	security_pkg.T_SID_ID,
	out_import_feed_cur		OUT	security_Pkg.T_OUTPUT_CUR
);

PROCEDURE UNSEC_GetUnprocessedRequests(
	in_import_feed_sid		IN	security_pkg.T_SID_ID,
	out_requests_cur		OUT	security_Pkg.T_OUTPUT_CUR
);

PROCEDURE GetImportFeedSid(
	in_name				IN	security_pkg.T_SO_NAME,
	out_feed_sid		OUT	security_pkg.T_SID_ID
);

PROCEDURE CreateImportFeedRequest(
	in_import_feed_sid			IN	security_pkg.T_SID_ID,
	in_file_data				IN	import_feed_request.file_data%TYPE,
	in_filename					IN	import_feed_request.filename%TYPE,
	in_mime_type				IN	import_feed_request.mime_type%TYPE,
	out_import_feed_request_id	OUT	import_feed_request.import_feed_request_id%TYPE
);

PROCEDURE UpdateImportFeedRequest(
	in_import_feed_request_id	IN	import_feed_request.import_feed_request_id%TYPE,
	in_failed_data				IN	import_feed_request.failed_data%TYPE,
	in_failed_filename			IN	import_feed_request.failed_filename%TYPE,
	in_failed_mime_type			IN	import_feed_request.failed_mime_type%TYPE,
	in_process_dtm				IN	import_feed_request.processed_dtm%TYPE,
	in_rows_imported			IN	import_feed_request.rows_imported%TYPE,
	in_rows_updated				IN	import_feed_request.rows_updated%TYPE,
	in_errors					IN	import_feed_request.errors%TYPE
);

END IMPORT_FEED_PKG;
/
