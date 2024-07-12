CREATE OR REPLACE PACKAGE CSR.notification_pkg AS

PROCEDURE CreateNotificationType(
	in_notification_type_id		IN	csr.notification_type.notification_type_id%TYPE,
	in_description				IN	csr.notification_type.description%TYPE,
	in_send_trigger				IN	csr.notification_type.send_trigger%TYPE,
	in_sent_from				IN	csr.notification_type.sent_from%TYPE,
	in_group_name				IN	csr.notification_type.group_name%TYPE
);

PROCEDURE UpdateNotificationType(
	in_notification_type_id		IN	csr.notification_type.notification_type_id%TYPE,
	in_description				IN	csr.notification_type.description%TYPE,
	in_send_trigger				IN	csr.notification_type.send_trigger%TYPE,
	in_sent_from				IN	csr.notification_type.sent_from%TYPE,
	in_group_name				IN	csr.notification_type.group_name%TYPE
);

PROCEDURE UpsertParamToNotificationType(
	in_notification_type_id		IN	csr.notification_type.notification_type_id%TYPE,
	in_field_name				IN	csr.notification_type_param.field_name%TYPE,
	in_description				IN	csr.notification_type_param.description%TYPE,
	in_help_text				IN	csr.notification_type_param.help_text%TYPE,
	in_repeats					IN	csr.notification_type_param.repeats%TYPE,
	in_display_pos				IN	csr.notification_type_param.display_pos%TYPE
);

PROCEDURE GetNotificationTypes(
	in_group_name			IN	csr.notification_type.group_name%TYPE DEFAULT NULL,
	out_cur					OUT	SYS_REFCURSOR,
	out_params_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetNotificationType(
	in_notification_type_id		IN	csr.notification_type.notification_type_id%TYPE,
	out_cur						OUT	SYS_REFCURSOR,
	out_params_cur				OUT	SYS_REFCURSOR
);

PROCEDURE DeleteParamFromNotificationType(
	in_notification_type_id		IN	csr.notification_type.notification_type_id%TYPE,
	in_field_name				IN	csr.notification_type_param.field_name%TYPE
);

PROCEDURE DeleteParamsFromNotificationType(
	in_notification_type_id		IN	csr.notification_type.notification_type_id%TYPE
);

PROCEDURE DeleteNotificationType(
	in_notification_type_id		IN	csr.notification_type.notification_type_id%TYPE
);

PROCEDURE GetAlertTypes(
	out_alert_cur						OUT	SYS_REFCURSOR,
	out_param_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetAlertTypeParams(
	in_customer_alert_type_id		IN csr.customer_alert_type.customer_alert_type_id%TYPE,
	out_param_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetCustomerAlertTypeId(
	in_notification_type_id			IN	csr.notification_type.notification_type_id%TYPE,
	out_customer_alert_type_id  	OUT	csr.customer_alert_type.customer_alert_type_id%TYPE
);

--------------------------
-- FAILED NOTIFICATIONS --
--------------------------
FAILURE_ARCHIVED_SENT				CONSTANT csr.failed_notification_archive.archive_reason%TYPE := 0;
FAILURE_ARCHIVED_EXPIRED			CONSTANT csr.failed_notification_archive.archive_reason%TYPE := 1;
FAILURE_ARCHIVED_DELETED			CONSTANT csr.failed_notification_archive.archive_reason%TYPE := 2;

FAILURE_PENDING_NONE				CONSTANT csr.failed_notification.action%TYPE := 0;
FAILURE_PENDING_DELETE				CONSTANT csr.failed_notification.action%TYPE := 1;
FAILURE_PENDING_RETRY				CONSTANT csr.failed_notification.action%TYPE := 2;

PROCEDURE GetFailedNotifications(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE CreateFailedNotification(
	in_notification_type_id			IN	csr.failed_notification.notification_type_id%TYPE,
	in_to_user						IN  csr.failed_notification.to_user%TYPE,
	in_channel						IN	csr.failed_notification.channel%TYPE,
	in_failure_code					IN	csr.failed_notification.failure_code%TYPE,
	in_failure_exception			IN	csr.failed_notification.failure_exception%TYPE,
	in_failure_detail				IN	csr.failed_notification.failure_detail%TYPE,
	in_from_user					IN	csr.failed_notification.from_user%TYPE,
	in_merge_fields					IN	csr.failed_notification.merge_fields%TYPE,
	in_repeating_merge_fields		IN	csr.failed_notification.repeating_merge_fields%TYPE,
	out_failed_notification_id		OUT	csr.failed_notification.failed_notification_id%TYPE
);

PROCEDURE UpdateFailureReason(
	in_failed_notification_id		IN	csr.failed_notification.notification_type_id%TYPE,
	in_failure_code					IN	csr.failed_notification.failure_code%TYPE,
	in_failure_exception			IN	csr.failed_notification.failure_exception%TYPE,
	in_failure_detail				IN	csr.failed_notification.failure_detail%TYPE
);

PROCEDURE SetFailureAction(
	in_failed_notification_id		IN	csr.failed_notification.notification_type_id%TYPE,
	in_action						IN	csr.failed_notification.action%TYPE,
	out_success						OUT NUMBER
);

PROCEDURE GetPendingFailureTenants(
	in_max_age_hours				IN NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetPendingResend(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE ArchiveDeletedFailures;

PROCEDURE ArchiveExpiredFailures(
	in_max_age_hours				IN NUMBER
);

PROCEDURE ArchiveSentFailures(
	in_ids							IN	security.security_pkg.T_SID_IDS
);

END;
/
