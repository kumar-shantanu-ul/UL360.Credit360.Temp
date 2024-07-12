CREATE OR REPLACE PACKAGE CSR.export_feed_pkg
AS

-- Securable object callbacks
/**
 * CreateObject
 *
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 * @param in_class_id				The class Id of the object
 * @param in_name					The name
 * @param in_parent_sid_id			The sid of the parent object
 */
PROCEDURE CreateObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_class_id						IN security_pkg.T_CLASS_ID,
	in_name							IN security_pkg.T_SO_NAME,
	in_parent_sid_id				IN security_pkg.T_SID_ID
);

/**
 * RenameObject
 *
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 * @param in_new_name				The name
 */
PROCEDURE RenameObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_new_name						IN security_pkg.T_SO_NAME
);

/**
 * DeleteObject
 *
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 */
PROCEDURE DeleteObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID
);

/**
 * MoveObject
 *
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 * @param in_new_parent_sid_id		.
 */
PROCEDURE MoveObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN security_pkg.T_SID_ID,
	in_old_parent_sid_id			IN security_pkg.T_SID_ID
);

/**
 * TrashObject
 *

 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 */
PROCEDURE TrashObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN  security_pkg.T_SID_ID
);


/**
 * CreateSecureFeed is used by Credit360.Export.CredentialStore
 */
PROCEDURE CreateSecureFeed(
	in_name							IN	security_pkg.T_SO_NAME,
	in_protocol						IN	export_feed.protocol%TYPE,
	in_url							IN	export_feed.url%TYPE,
	in_secure_creds					IN  export_feed.secure_creds%TYPE,
	in_interval						IN	export_feed.interval%TYPE,
	in_start_dtm					IN	export_feed.start_dtm%TYPE,
	out_feed_sid					OUT	security_pkg.T_SID_ID
);

PROCEDURE CreateFeed(
	in_name							IN	security_pkg.T_SO_NAME,
	in_protocol						IN	export_feed.protocol%TYPE,
	in_url							IN	export_feed.url%TYPE,
	in_interval						IN	export_feed.interval%TYPE,
	in_start_dtm					IN	export_feed.start_dtm%TYPE,
	out_feed_sid					OUT	security_pkg.T_SID_ID
);

PROCEDURE GetExportFeed(
	in_export_feed_sid				IN	security_pkg.T_SID_ID,
	out_export_feed_cur				OUT	SYS_REFCURSOR
);

PROCEDURE UNSEC_GetAppsToProcessExpFeeds(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE UNSEC_GetExportFeedsForApp(
	out_export_feed_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetJobsForExportFeed(
	in_export_feed_sid				IN	security_pkg.T_SID_ID,
	out_dataview_cur				OUT	SYS_REFCURSOR,
	out_cms_form_cur				OUT SYS_REFCURSOR,
	out_stored_proc_cur				OUT SYS_REFCURSOR
);

PROCEDURE UNSEC_SetTimestamps(
	in_export_feed_sid				IN	export_feed.export_feed_sid%TYPE,
	in_last_success_attempt_dtm		IN	export_feed.last_success_attempt_dtm%TYPE,
	in_last_attempt_dtm				IN	export_feed.last_attempt_dtm%TYPE
);

PROCEDURE UNSEC_SetTimestampOnError(
	in_export_feed_sid				IN	export_feed.export_feed_sid%TYPE,
	in_last_attempt_dtm				IN	export_feed.last_attempt_dtm%TYPE
);

FUNCTION GetStartDtmTimes(
	in_date							IN  DATE
) RETURN NUMBER;

END export_feed_pkg;
/
