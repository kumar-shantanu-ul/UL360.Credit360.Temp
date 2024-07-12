CREATE OR REPLACE PACKAGE CSR.Alert_Pkg AS

/**
 * Get the sid of a system mailbox
 * 
 * @param in_mailbox_name			The name of the mailbox to retrieve
 * @returns							The sid of the mailbox
 */
FUNCTION GetSystemMailbox(
	in_mailbox_name					IN	VARCHAR2
) RETURN NUMBER;

/**
 * Get the sid of a tracker mailbox
 *
 * @param in_mailbox_name			The name of the mailbox to retrieve
 * @returns							The sid of the mailbox
 */
FUNCTION GetTrackerMailbox(
	in_mailbox_name					IN	VARCHAR2
) RETURN NUMBER;

/**
 * Get the sid of the current user's private mailbox
 * 
 * @returns							The sid of the logged on user's mailbox
 */
FUNCTION GetUserMailbox
RETURN NUMBER;

/**
 * Get the sid of the given user's private mailbox
 * 
 * @returns							The sid of the given user's mailbox
 */
FUNCTION GetUserMailbox(
	in_user_sid						IN	csr_user.csr_user_sid%TYPE
)
RETURN NUMBER;

/**
 * Send a copy of an alert to the user's personal messages folder
 *
 * @param in_mailbox_sid			The mailbox to copy the message from
 * @param in_message_uid			The message to copy
 * @param in_user_sid				The user to copy to
 */
PROCEDURE CopyAlertToUser(
	in_mailbox_sid					IN	security_pkg.T_SID_ID,
	in_message_uid					IN	security_pkg.T_SID_ID,
	in_user_sid						IN 	csr_user.csr_user_sid%TYPE
);

/**
 * Delete an alert template to delete templates form
 * 
 * @param in_std_alert_type_id			The alert type
 */
PROCEDURE DeleteTemplate(
	in_customer_alert_type_id		IN	customer_alert_type.customer_alert_type_id%TYPE	
);

/**
 * Get an alert template along with the frame + template bodies in all languages based on std_alert_type_Id
 * 
 * @param in_std_alert_type_id		The alert type
 * @param out_cur					The alert type details
 * @param out_frames_cur			Frame details
 * @param out_bodies_cur			Template details
 */
PROCEDURE GetTemplateForStdAlertType(
	in_std_alert_type_id			IN	std_alert_type.std_alert_type_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_frames_cur					OUT	SYS_REFCURSOR,
	out_bodies_cur					OUT	SYS_REFCURSOR,
	out_params_cur					OUT	SYS_REFCURSOR
);

/**
 * Get an alert template along with the frame + template bodies in all languages based on customer_alert_type_Id
 * 
 * @param in_customer_alert_type_id	The alert type
 * @param out_cur					The alert type details
 * @param out_frames_cur			Frame details
 * @param out_bodies_cur			Template details
 */
PROCEDURE GetTemplate(
	in_customer_alert_type_id		IN	customer_alert_type.customer_alert_type_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_frames_cur					OUT	SYS_REFCURSOR,
	out_bodies_cur					OUT	SYS_REFCURSOR,
	out_params_cur					OUT	SYS_REFCURSOR
);

/**
 * GetStdAlertTypes
 * 
 * @param out_cur					The alert types / configuration status for the customer
 * @param out_params_cur			Parameters for the alert types
 */
PROCEDURE GetStdAlertTypes(
	out_alert_cur	            	OUT	SYS_REFCURSOR,
	out_params_cur					OUT SYS_REFCURSOR
);

/**
 * GetStdAlertType
 * 
 * @param in_std_alert_type_id		The std alert type to get
 * @param out_std_alert_cur			Attributes for the alert type
 */
PROCEDURE GetStdAlertType(
	in_std_alert_type_id			IN	std_alert_type.std_alert_type_id%TYPE,
	out_std_alert_cur	            OUT	SYS_REFCURSOR
);

/**
 * GetAlertTypeParams
 * 
 * @param in_std_alert_type_id		The std alert type to get parameters for
 * @param out_cur					Parameters for the alert type
 */
PROCEDURE GetStdAlertTypeParams(
	in_std_alert_type_id			IN	std_alert_type_param.std_alert_type_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * GetCustomerAlertTypeParams
 * 
 * @param in_customer_alert_type_id	The customeralert type to get parameters for
 * @param out_cur					Parameters for the alert type
 */
PROCEDURE GetCustomerAlertTypeParams(
	in_customer_alert_type_id		IN	customer_alert_type_param.customer_alert_type_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Fetch all frame names/ids
 * 
 * @param out_cur					The rowset
 */
PROCEDURE GetFrames(
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Create a new frame with the given name
 *
 * @param in_name					The frame's name/description
 * @param out_alert_frame_id		The id of the created frame
 */
PROCEDURE CreateFrame(
	in_name							IN	alert_frame.name%TYPE,
	out_alert_frame_id				OUT	alert_frame.alert_frame_id%TYPE
);

/**
 * Gets a frame with the given name or creates a new one if it doesn't exist
 *
 * @param in_name					The frame's name/description
 * @param out_alert_frame_id		The id of the created frame
 */
PROCEDURE GetOrCreateFrame(
	in_name							IN	alert_frame.name%TYPE,
	out_alert_frame_id				OUT	alert_frame.alert_frame_id%TYPE
);

/**
 * Get a frame body for the given frame/language
 *
 * @param in_alert_frame_id			The frame's id
 * @param in_lang					The language to get the body for
 * @param out_cur					The rowset
 */
PROCEDURE GetFrameBody( 
	in_alert_frame_id				IN	alert_frame_body.alert_frame_id%TYPE,
	in_lang							IN	alert_frame_body.lang%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Get all frame bodies for the given frame
 *
 * @param in_alert_frame_id			The frame's id
 * @param out_cur					The rowset
 */
PROCEDURE GetFrameBodies( 
	in_alert_frame_id				IN	alert_frame_body.alert_frame_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Save a frame body for the given frame/language
 *
 * @param in_alert_frame_id			The frame's id
 * @param in_lang					The language to set the body for
 * @param in_html					The HTML body to set
 */
PROCEDURE SaveFrameBody(
	in_alert_frame_id				IN	alert_frame_body.alert_frame_id%TYPE,
	in_lang							IN	alert_frame_body.lang%TYPE,
	in_html							IN	alert_frame_body.html%TYPE
);

/**
 * Delete a frame.  Raises csr_data_pkg.OBJECT_IN_USE if it's set for any alert templates.
 *
 * @param in_alert_frame_id			The frame's id
 */ 
PROCEDURE DeleteFrame(
	in_alert_frame_id				IN	alert_frame.alert_frame_id%TYPE
);

/**
 * Get a template body for the given template/language
 *
 * @param in_std_alert_type_id			The alert type
 * @param in_lang					The language to get the body for
 * @param out_cur					The rowset
 */
PROCEDURE GetTemplateAndBodyAndParams(
	in_customer_alert_type_id		IN	customer_alert_type.customer_alert_type_id%TYPE,
	in_lang							IN	alert_template_body.lang%TYPE,
	out_body_cur					OUT	SYS_REFCURSOR,
	out_params_cur					OUT SYS_REFCURSOR
);

/**
 * Save a template body for the given template/language
 *
 * @param in_customer_alert_type_id	The customer alert type
 * @param in_alert_frame_id			The selected frame
 * @param in_send_type				Automatic/manual send
 * @param in_reply_to_name			Name for the Reply-To header
 * @param in_reply_to_email			E-mail address for the Reply-To header
 * @param in_lang					The language to set the body for
 * @param in_subject				The subject template
 * @param in_body_html				The body template
 * @param in_item_html				The item template
 */
PROCEDURE SaveTemplateAndBody(
	in_customer_alert_type_id		IN	alert_template.customer_alert_type_id%TYPE,
	in_alert_frame_id				IN	alert_template.alert_frame_id%TYPE,
	in_send_type					IN	alert_template.send_type%TYPE,
	in_reply_to_name				IN	alert_template.reply_to_name%TYPE,
	in_reply_to_email				IN	alert_template.reply_to_email%TYPE,
	in_lang							IN	alert_template_body.lang%TYPE,
	in_subject						IN	alert_template_body.subject%TYPE,
	in_body_html					IN	alert_template_body.body_html%TYPE,
	in_item_html					IN	alert_template_body.item_html%TYPE
);

/**
 * Begin a batch run for the given std alert type.  Computes and records next trigger
 * firing times for those users who don't have this recorded already.
 *
 * @param in_std_alert_type_id			The type of std alert being processed
 */
PROCEDURE BeginStdAlertBatchRun(
	in_std_alert_type_id		IN	std_alert_type.std_alert_type_id%TYPE,
	in_alert_pivot_dtm			IN	DATE DEFAULT systimestamp
);

/**
 * Begin a batch run for the given customer alert type.  Computes and records next trigger
 * firing times for those users who don't have this recorded already.
 *
 * @param in_customer_alert_type_id		The type of customer alert being processed
 */
PROCEDURE BeginCustomerAlertBatchRun(
	in_customer_alert_type_id		IN	customer_alert_type.customer_alert_type_id%TYPE
);

/**
 * Called from user batch code to record the time the last run for
 * the given std alert type occurred at
 *
 * @param in_app_sid				The application that was processed
 * @param in_csr_user_sid			The user that was processed
 * @param in_std_alert_type_id		The type of alert that was processed
 */
PROCEDURE RecordUserBatchRun(
	in_app_sid						IN	alert_batch_run.app_sid%TYPE,
	in_csr_user_sid					IN	alert_batch_run.csr_user_sid%TYPE,
	in_std_alert_type_id			IN	std_alert_type.std_alert_type_id%TYPE
);

/**
 * Called from user batch code to record the time the last run for
 * the given customer alert type occurred at
 *
 * @param in_customer_alert_type_id The type of alert that was processed
 * @param in_csr_user_sid			The user that was processed
 */
PROCEDURE RecordUserBatchRun(
	in_customer_alert_type_id		IN	customer_alert_type.customer_alert_type_id%TYPE,
	in_csr_user_sid					IN	alert_batch_run.csr_user_sid%TYPE
);

/**
 * End a batch run based on std_alert_type_id.  This marks all users who 
 * RecordUserBatchRun wasn't explicitly called for (because there was no work to do) as 
 * having being processed (so we know we didn't miss the tick for them).
 */
PROCEDURE EndStdAlertBatchRun(
	in_std_alert_type_id			IN	std_alert_type.std_alert_type_id%TYPE
);

/**
 * End a batch run based on customer_alert_type_Id.  This marks all users who 
 * RecordUserBatchRun wasn't explicitly called for (because there was no work to do) as 
 * having being processed (so we know we didn't miss the tick for them).
 */
PROCEDURE EndCustomerAlertBatchRun(
	in_customer_alert_type_id		IN	customer_alert_type.customer_alert_type_id%TYPE
);

/**
 * Associate images in outgoing alerts with a key that allows the user that
 * the image is sent to to view it without logging on.
 *
 * This is fairly numpty security, but OTOH it's just images in mails.
 *
 * @param in_image_ids				Images to associate pass keys with
 * @param in_pass_keys				Keys to associate the image with
 */
PROCEDURE SetImages(
	in_image_ids					IN	security_pkg.T_SID_IDS,
	in_pass_keys					IN	security_pkg.T_VARCHAR2_ARRAY
);

/**
 * Get an image by pass key
 *
 * This is fairly numpty security, but OTOH it's just images in mails.
 *
 * @param in_pass_key				The pass key to retrieve
 * @param out_cur					The image data
 */
PROCEDURE GetImage(
	in_pass_key						IN	alert_image.pass_key%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Copy alert templates from the current site to the defaults
 * You need to be logged on as a superadmin or //builtin/administrator to do this
 */
PROCEDURE CopyTemplatesToDefault;


/**
 * Fetches information about CMS alerts that might need to be checked for. It 
 * has no security and is intended to be called from the alert batch code.
 */
PROCEDURE GetCmsAlertTypes(
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Fetches pending cms field change alerts to be sent to users.
 */
PROCEDURE GetCmsFieldChangeAlerts(
	in_customer_alert_type_id		IN	cms_field_change_alert.customer_alert_type_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Fetches pending cms field change alerts to be sent to users.
 */
PROCEDURE GetBatchedCmsFieldChangeAlerts(
	in_customer_alert_type_id		IN	cms_field_change_alert.customer_alert_type_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Marks cms field change alerts in batch alert as sent. Note that this SP commits after it has updated all the alerts in the batch.
 */
PROCEDURE MarkBatchCmsFieldChangeSent(
	in_cms_field_change_alert_ids	IN	security_pkg.T_SID_IDS
);

/**
 * Marks cms field change alerts that are unconfigured/inactive as sent.
 */
PROCEDURE MarkUnconfiguredCmsFieldChangeSent;

/**
 * Marks a cms field change alert as being sent. Note that this SP commits after it has updated the alert.
 */
PROCEDURE MarkCmsFieldChangeAlertSent(
	in_cms_field_change_alert_id	IN	cms_field_change_alert.cms_field_change_alert_id%TYPE
);

/**
 * Fetches information about CMS tab alerts that might need to be checked for. It 
 * has no security and is intended to be called from the alert batch code.
 */
PROCEDURE GetCmsTabAlertTypes(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE SaveMessage(
	in_std_alert_type_id			IN	alert_mail.std_alert_type_id%TYPE,
	in_message						IN	alert_mail.message%TYPE
);

PROCEDURE DeleteMessage(
	in_alert_mail_id				IN	alert_mail.alert_mail_id%TYPE
);

PROCEDURE GetAppsWithMessages(
	in_std_alert_type_id			IN	alert_mail.std_alert_type_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetMessages(
	in_std_alert_type_id			IN	alert_mail.std_alert_type_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Record an outgoing alert for bounce tracking
 *
 * @param in_to_user_sid			The SID of the user the mail is being sent to (if known)
 * @param in_to_email_address		The mail address the alert is being sent to
 * @param in_subject				The message's subject
 * @param in_message				The message
 * @param out_alert_id				The assigned alert id
 */
PROCEDURE RecordAlert(
	in_to_user_sid					IN	alert.to_user_sid%TYPE,
	in_to_email_address				IN	alert.to_email_address%TYPE,
	in_subject						IN	alert.subject%TYPE,
	in_message						IN	alert.message%TYPE,
	out_alert_id					OUT	alert.alert_id%TYPE
);

/**
 * Record a bounce mail
 *
 * @param in_alert_id				The ID of the alert
 * @param in_message				The bounce message
 */
PROCEDURE RecordBounce(
	in_alert_id						IN	alert.alert_id%TYPE,
	in_message						IN	alert_bounce.message%TYPE
);

/**
 * Fetch a list of bounced alerts
 *
 * @param in_start_row				First row to fetch
 * @param in_page_size				Items per page
 * @param out_total					Total number of bounces
 * @param out_cur					Alert bounce data
 */
PROCEDURE GetBouncedAlerts(
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	out_total						OUT	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Fetch all bounced alerts
 *
 * @param out_cur					Alert bounce data
 */
PROCEDURE GetAllBouncedAlerts(
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Get a sent alert for the bounce list
 *
 * @param in_alert_id				ID of the alert to fetch
 * @param out_cur					Sent alert details
 */
PROCEDURE GetSentAlert(
	in_alert_id						IN	alert.alert_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Get a bounce for the bounce list
 *
 * @param in_alert_bounce_id		ID of the alert bounce to fetch
 * @param out_cur					Bounce details
 */
PROCEDURE GetAlertBounce(
	in_alert_bounce_id				IN	alert_bounce.alert_bounce_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * A helper procedure to create/update a cms alert.
 */
PROCEDURE SetCmsAlert (
	in_tab_sid						IN  security.security_pkg.T_SID_ID,
	in_lookup_key					IN  cms_alert_type.lookup_key%TYPE,
	in_description					IN  cms_alert_type.description%TYPE,
	in_subject						IN  alert_template_body.subject%TYPE,
	in_body_html					IN  alert_template_body.body_html%TYPE,
	in_is_batched					IN	cms_alert_type.is_batched%TYPE DEFAULT 0,
	out_customer_alert_type_id		OUT customer_alert_type.customer_alert_type_id%TYPE
);

/**
 * Adds a cms field change alert for the batch process to pickup and send.
 */
PROCEDURE AddCmsFieldChangeAlert(
	in_lookup_key					IN  cms_alert_type.lookup_key%TYPE, 
	in_item_id						IN  cms_field_change_alert.item_id%TYPE, 	
	in_user_sid						IN  cms_field_change_alert.user_sid%TYPE, 
	in_version_number				IN  cms_field_change_alert.version_number%TYPE
);

/**
 * Get the corresponding customer alert type of the std input alert type
 *
 * @param in_std_alert_type			Standard alert type id
 * @returns							Customer alert type id
 */
FUNCTION GetCustomerAlertType(
	in_std_alert_type				IN	NUMBER
) RETURN NUMBER;

/**
 * Returns true if alert template exists and is not inactive else false
 *
 * @param in_std_alert_type			Standard alert type id
 * @returns							true/false
 */
FUNCTION IsAlertEnabled(
	in_std_alert_type				IN	std_alert_type.std_alert_type_id%TYPE,
	in_app_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP')
) RETURN BOOLEAN;

/**
 * Returns 1 if alert template exists and is not inactive else 0
 *
 * @param in_std_alert_type			Standard alert type id
 * @returns							1/0
 */
FUNCTION SQL_IsAlertEnabled(
	in_std_alert_type				IN	std_alert_type.std_alert_type_id%TYPE,
	in_app_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP')
) RETURN NUMBER;

/**
 * Returns app_sids which have alert template template configured and it is not inactive
 *
 * @param in_std_alert_type			Standard alert type id
 * @returns							app_sids table
 */
FUNCTION GetAppSidsForAlert(
	in_std_alert_type				IN	std_alert_type.std_alert_type_id%TYPE
) RETURN security.T_SID_TABLE;

/**
 * GetStdAlertTypeGroups
 * 
 * @param out_alert_group_cur				The standard alert type groups for the customer
 */
PROCEDURE GetStdAlertTypeGroups(
	out_alert_group_cur	            OUT	SYS_REFCURSOR
);

/**
 * GetStdAlertTypesAndGroups
 * 
 * @param out_alert_group_cur				The standard alert type groups for the customer
 * @param out_cur							The alert types / configuration status for the customer
 * @param out_params_cur					Parameters for the alert types
 */
PROCEDURE GetStdAlertTypesAndGroups(
	out_alert_group_cur	            OUT	SYS_REFCURSOR,
	out_alert_cur	            	OUT	SYS_REFCURSOR,
	out_params_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetAllAlertTemplates(
	out_cur				OUT	SYS_REFCURSOR
);

END Alert_Pkg;
/
