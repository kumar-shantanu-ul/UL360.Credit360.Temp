CREATE OR REPLACE PACKAGE CSR.feed_pkg AS

DEFAULT_FEED_TYPE			CONSTANT	NUMBER(10) := 1;
INTERVAL_FEED_TYPE			CONSTANT	NUMBER(10) := 2;
CHAIN_FEED_TYPE				CONSTANT	NUMBER(10) := 3;
LOGGING_FORMS_FEED_TYPE		CONSTANT	NUMBER(10) := 4;

/**
 * CreateFeed
 * 
 * @param in_act_id				Access token
 * @param in_app_sid		The sid of the Application/CSR object
 * @param in_name				The name of the feed object
 * @param in_label				A longer text description of the feed
 * @param in_xsl_doc      XSLT used to transform the XML in the feed_request
 * @param in_feed_type_id Type of the feed
 * @param in_url        URL of an external data source
 * @param in_protocol   Protocol needed to connect to the external data source
 * @param in_interval   Polling interval of the external data source (in days)
 * @param out_feed_sid			The new feed sid
 */
PROCEDURE CreateFeed(
	in_act_id			IN security_pkg.T_ACT_ID, 
	in_app_sid			IN security_pkg.T_SID_ID,
	in_name				IN security_pkg.T_SO_NAME,
	in_label			IN feed.label%TYPE,
	in_xsl_doc			IN feed.xsl_doc%TYPE,
	in_response_xsl_doc	IN feed.response_xsl_doc%TYPE,
	in_mapping_xml		IN feed.mapping_xml%TYPE,
	in_feed_type_id		IN feed.feed_type_id%TYPE,
	in_url				IN feed.url%TYPE,
	in_username			IN feed.username%TYPE,
	in_protocol			IN feed.protocol%TYPE,
	in_host_key			IN feed.host_key%TYPE,
	in_interval			IN feed.interval%TYPE,
	out_feed_sid		OUT security_pkg.T_SID_ID
);

/**
 * CreateFeed
 * 
 * @param in_act_id				Access token
 * @param in_app_sid		The sid of the Application/CSR object
 * @param in_name				The name of the feed object
 * @param in_label				A longer text description of the feed
 * @param out_feed_sid			The new feed sid
 */
PROCEDURE CreateFeed(
	in_act_id			IN security_pkg.T_ACT_ID, 
	in_app_sid			IN security_pkg.T_SID_ID,
	in_name				IN security_pkg.T_SO_NAME,
	in_label			IN feed.label%TYPE,
	in_xsl_doc			IN feed.xsl_doc%TYPE,
	in_response_xsl_doc	IN feed.response_xsl_doc%TYPE,
	in_mapping_xml		IN feed.mapping_xml%TYPE,
	in_feed_type_id    	IN feed.feed_type_id%TYPE,
	out_feed_sid		OUT security_pkg.T_SID_ID
);

PROCEDURE AmendFeed(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_feed_sid			IN security_pkg.T_SID_ID,
	in_name				IN security_pkg.T_SO_NAME,
	in_label			IN feed.label%TYPE,
	in_xsl_doc			IN feed.xsl_doc%TYPE,
	in_response_xsl_doc	IN feed.response_xsl_doc%TYPE,
	in_mapping_xml		IN feed.mapping_xml%TYPE,
	in_feed_type_id    	IN feed.feed_type_id%TYPE
);


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


PROCEDURE GetFeed(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_feed_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetFeedList(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);



PROCEDURE GetFeedDetails(
    in_act_id       IN	security_pkg.T_ACT_ID,
	in_feed_sid		IN	security_pkg.T_SID_ID,
    in_start_row    IN	number,
    in_end_row      IN	number,
    out_cur         OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFeedRequest(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_feed_request_id	IN	feed_request.feed_request_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveFeedSummary(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_feed_request_id	IN	feed_request.feed_request_id%TYPE,
	in_summary_xml		IN	feed_request.summary_xml%TYPE,
	in_error_data		IN	feed_request.error_data%TYPE
);

PROCEDURE CallHelperPkg(
	in_procedure_name	IN	VARCHAR2,
	in_feed_sid			IN	security_pkg.T_SID_ID,
	in_feed_request_id	IN	feed_request.feed_request_id%TYPE
);

/**
 * Logs freshly POSTed data to a feed ready for processing
 * 
 * @param in_act_id					Access token
 * @param in_feed_sid				Feed Sid
 * @param in_response_code			HTTP Response Code
 * @param in_remote_addr			Remote IP address
 * @param in_file_data				Sent file
 * @param in_file_type				File type
 * @param out_feed_request_id		The new feed request id
 */
PROCEDURE LogRequest(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_feed_sid			IN	security_pkg.T_SID_ID,
	in_response_code	IN	feed_request.http_response_code%TYPE,
	in_remote_addr		IN	feed_request.remote_addr%TYPE,
	in_file_data		IN	feed_request.file_data%TYPE,
	in_file_type		IN	feed_request.file_type%TYPE,
	out_feed_request_id	OUT	feed_request.feed_request_id%TYPE
);

PROCEDURE UNSEC_GetAppsToProcessFeedsFor(
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UNSEC_GetAppsToProcessIntFeeds(
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UNSEC_GetIntervalFeedsForApp(
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * Returns data about open feed requests (i.e. where imp_session_sid is null)
 * 
 * @param in_app_sid			App Sid
 * @param out_cur				The rowset
 */
PROCEDURE UNSEC_GetOpenRequestsForApp(
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);


/**
 * Updates the feed_request, setting the imp_session_sid
 * 
 * @param in_act_id				Access token
 * @param in_feed_request_id	Feed Request id
 * @param in_imp_session_sid	Imp Session Sid
 */
PROCEDURE SetFeedRequestSessionSid(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_feed_request_id	IN	feed_request.feed_request_id%TYPE,
	in_imp_session_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE SetFeedTimestamps(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_feed_sid	IN	feed.feed_sid%TYPE,
	in_last_good_attempt_dtm IN feed.last_good_attempt_dtm%TYPE,
	in_last_attempt_dtm IN feed.last_attempt_dtm%TYPE
);
PROCEDURE GetFeedTypes(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInboundFeedAccounts(
	out_cur		OUT	SYS_REFCURSOR
);

PROCEDURE SaveInboundFeedAttachment(
	in_mailbox_sid	IN	security_pkg.T_SID_ID, 
	in_message_uid	IN	security_pkg.T_SID_ID, 
	in_name			IN	VARCHAR2, 
	in_date			IN	DATE, 
    in_file_data	IN	BLOB
);

END feed_Pkg;
/
