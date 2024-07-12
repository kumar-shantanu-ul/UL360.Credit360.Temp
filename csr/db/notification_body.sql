CREATE OR REPLACE PACKAGE BODY CSR.notification_pkg AS

PROCEDURE AssertHasManagmentCapability
AS
BEGIN
	IF (NOT security.security_pkg.IsAdmin(security.security_pkg.GetAct) AND
		NOT csr.csr_data_pkg.CheckCapability('Can manage custom notification templates'))
	THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'User does not have the "Can manage custom notification templates" capability.');
	END IF;
END;

PROCEDURE AssertHasFailureManagementCapability
AS
BEGIN
	IF (NOT csr.csr_user_pkg.IsSuperAdmin = 1 AND
		NOT csr.csr_data_pkg.CheckCapability('Can manage notification failures')
		)
	THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'User does not have the "Can manage notification failures" capability.');
	END IF;
END;

PROCEDURE CreateNotificationType(
	in_notification_type_id		IN	csr.notification_type.notification_type_id%TYPE,
	in_description				IN	csr.notification_type.description%TYPE,
	in_send_trigger				IN	csr.notification_type.send_trigger%TYPE,
	in_sent_from				IN	csr.notification_type.sent_from%TYPE,
	in_group_name				IN	csr.notification_type.group_name%TYPE
)
AS
BEGIN
	AssertHasManagmentCapability();
	
	INSERT INTO notification_type
		(notification_type_id, description, send_trigger, sent_from, 
		group_name)
	VALUES
		(in_notification_type_id, in_description, in_send_trigger, in_sent_from, 
		in_group_name);

	INSERT INTO customer_alert_type (customer_alert_type_id, notification_type_id)
	VALUES (customer_alert_type_Id_seq.nextval, in_notification_type_id);
	
END;

PROCEDURE UpdateNotificationType(
	in_notification_type_id		IN	csr.notification_type.notification_type_id%TYPE,
	in_description				IN	csr.notification_type.description%TYPE,
	in_send_trigger				IN	csr.notification_type.send_trigger%TYPE,
	in_sent_from				IN	csr.notification_type.sent_from%TYPE,
	in_group_name				IN	csr.notification_type.group_name%TYPE
)
AS
BEGIN
	AssertHasManagmentCapability();
	
	UPDATE notification_type
	   SET description = in_description, 
	   	   send_trigger = in_send_trigger, 
		   sent_from = in_sent_from, 
		   group_name = in_group_name
	 WHERE notification_type_id = in_notification_type_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE UpsertParamToNotificationType(
	in_notification_type_id		IN	csr.notification_type.notification_type_id%TYPE,
	in_field_name				IN	csr.notification_type_param.field_name%TYPE,
	in_description				IN	csr.notification_type_param.description%TYPE,
	in_help_text				IN	csr.notification_type_param.help_text%TYPE,
	in_repeats					IN	csr.notification_type_param.repeats%TYPE,
	in_display_pos				IN	csr.notification_type_param.display_pos%TYPE
)
AS
BEGIN
	AssertHasManagmentCapability();

	BEGIN
		INSERT INTO notification_type_param
			(notification_type_id, field_name, description, help_text, 
			 repeats, display_pos)
		VALUES
			(in_notification_type_id, UPPER(in_field_name), in_description, in_help_text,
			 in_repeats, in_display_pos);
	EXCEPTION 
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE notification_type_param
			   SET help_text = in_help_text,
				   description = in_description,
				   repeats = in_repeats,
				   display_pos = in_display_pos
			 WHERE notification_type_id = in_notification_type_id
			   AND UPPER(field_name) = UPPER(in_field_name)
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END;

END;

PROCEDURE GetNotificationTypes(
	in_group_name			IN	csr.notification_type.group_name%TYPE DEFAULT NULL,
	out_cur					OUT	SYS_REFCURSOR,
	out_params_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT nt.notification_type_id, description, send_trigger, sent_from, group_name, customer_alert_type_id
		  FROM notification_type nt
		  JOIN customer_alert_type cat ON nt.notification_type_id = cat.notification_type_id
		 WHERE (in_group_name IS NULL OR LOWER(group_name) = LOWER(in_group_name))
		   AND nt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY nt.notification_type_id;
	
	OPEN out_params_cur FOR
		SELECT ntp.notification_type_id, field_name, ntp.description, help_text, repeats, display_pos
		  FROM notification_type_param ntp
		  JOIN notification_type nt on ntp.notification_type_id = nt.notification_type_id
		 WHERE (in_group_name IS NULL OR LOWER(nt.group_name) = LOWER(in_group_name))
		   AND ntp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY ntp.notification_type_id, display_pos, field_name;

END;

PROCEDURE GetNotificationType(
	in_notification_type_id		IN	csr.notification_type.notification_type_id%TYPE,
	out_cur						OUT	SYS_REFCURSOR,
	out_params_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT nt.notification_type_id, description, send_trigger, sent_from, group_name, customer_alert_type_id
		  FROM notification_type nt
		  JOIN customer_alert_type cat ON nt.notification_type_id = cat.notification_type_id
		 WHERE nt.notification_type_id = in_notification_type_id
		   AND nt.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	OPEN out_params_cur FOR
		SELECT notification_type_id, field_name, description, help_text, repeats, display_pos
		  FROM notification_type_param
		 WHERE notification_type_id = in_notification_type_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY display_pos, field_name;

END;

PROCEDURE DeleteParamFromNotificationType(
	in_notification_type_id		IN	csr.notification_type.notification_type_id%TYPE,
	in_field_name				IN	csr.notification_type_param.field_name%TYPE
)
AS
BEGIN
	AssertHasManagmentCapability();

	DELETE FROM notification_type_param
	 WHERE notification_type_id = in_notification_type_id
	   AND UPPER(field_name) = UPPER(in_field_name)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE DeleteParamsFromNotificationType(
	in_notification_type_id		IN	csr.notification_type.notification_type_id%TYPE
)
AS
BEGIN
	AssertHasManagmentCapability();

	DELETE FROM notification_type_param
	 WHERE notification_type_id = in_notification_type_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

-- Not plumbed in, but useful for local and rounds it out
PROCEDURE DeleteNotificationType(
	in_notification_type_id		IN	csr.notification_type.notification_type_id%TYPE
)
AS
	v_customer_alert_type_id	customer_alert_type.customer_alert_type_Id%TYPE;
BEGIN
	AssertHasManagmentCapability();
	
	BEGIN
		SELECT customer_alert_type_id
		  INTO v_customer_alert_type_id
		  FROM customer_alert_type
		 WHERE notification_type_id = in_notification_type_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		
		DELETE FROM alert_template_body
		 WHERE customer_alert_type_id = v_customer_alert_type_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		
		DELETE FROM alert_template
		 WHERE customer_alert_type_id = v_customer_alert_type_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		
		DELETE FROM notification_type_param
		 WHERE notification_type_id = in_notification_type_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

		DELETE FROM customer_alert_type
		 WHERE customer_alert_type_id = v_customer_alert_type_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

		DELETE FROM notification_type
		 WHERE notification_type_id = in_notification_type_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			-- Doesn't exist, so... do nothing.
			NULL;
	END;

END;

-- This could live in alert_pkg but I figured it was better off here. I'd rather tie notifications to
-- the monolith through this SP than the other way around. If we ever migrate Notifications out then
-- we know we need a solution for this SP (and other joins, etc, above) rather than the other way
-- around.
-- So notification tables should only be in this file (except, perhaps, for deleteapp).
PROCEDURE GetAlertTypes(
	out_alert_cur						OUT	SYS_REFCURSOR,
	out_param_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_alert_cur FOR
		SELECT cat.customer_alert_type_id, description, send_trigger, sent_from, group_name, NVL(at.send_type, 'unconfigured') status
		  FROM notification_type nt
		  JOIN customer_alert_type cat ON nt.notification_type_id = cat.notification_type_id
	 LEFT JOIN alert_template at ON cat.customer_alert_type_id = at.customer_alert_type_id
	 	 WHERE cat.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY group_name, description;

	OPEN out_param_cur FOR
		SELECT cat.customer_alert_type_id, ntp.field_name, ntp.description, ntp.help_text, ntp.repeats, ntp.display_pos
		  FROM notification_type_param ntp
		  JOIN customer_alert_type cat on ntp.notification_type_id = cat.notification_type_id
	 	 WHERE cat.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY cat.customer_alert_type_id, ntp.display_pos;
END;

PROCEDURE GetAlertTypeParams(
	in_customer_alert_type_id		IN csr.customer_alert_type.customer_alert_type_id%TYPE,
	out_param_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_param_cur FOR
		SELECT cat.customer_alert_type_id, ntp.field_name, ntp.description, ntp.help_text, ntp.repeats, ntp.display_pos
		  FROM notification_type_param ntp
		  JOIN customer_alert_type cat ON ntp.notification_type_id = cat.notification_type_id
	 	 WHERE cat.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cat.customer_alert_type_id = in_customer_alert_type_id
		 ORDER BY ntp.display_pos;
END;

PROCEDURE GetCustomerAlertTypeId(
	in_notification_type_id			IN	csr.notification_type.notification_type_id%TYPE,
	out_customer_alert_type_id  	OUT	csr.customer_alert_type.customer_alert_type_id%TYPE
)
AS
BEGIN
	SELECT customer_alert_type_id
	  INTO out_customer_alert_type_id
	  FROM csr.customer_alert_type
	 WHERE notification_type_id = in_notification_type_id;
END;

PROCEDURE GetFailedNotifications(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	AssertHasFailureManagementCapability();

	OPEN out_cur FOR
		SELECT
			fn.failed_notification_id,
			fn.notification_type_id,
			fn.to_user,
			fn.channel,
			fn.failure_code,
			fn.from_user,
			fn.merge_fields,
			fn.repeating_merge_fields,
			fn.action,
			fn.create_dtm,
			fn.retry_count,
			tcu.full_name to_full_name
		  FROM csr.failed_notification fn
		  JOIN csr.csr_user tcu ON lower(fn.to_user) = lower(tcu.guid) AND tcu.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

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
)
AS
BEGIN
	AssertHasFailureManagementCapability();

	INSERT INTO failed_notification
	   (failed_notification_id,
		notification_type_id,
		to_user,
		channel,
		failure_code,
		failure_exception,
		failure_detail,
		from_user,
		merge_fields,
		repeating_merge_fields)
	VALUES
	   (failed_notification_id_seq.NEXTVAL,
		in_notification_type_id,
		in_to_user,
		in_channel,
		in_failure_code,
		in_failure_exception,
		in_failure_detail,
		in_from_user,
		in_merge_fields,
		in_repeating_merge_fields)
	RETURNING failed_notification_id INTO out_failed_notification_id;
END;

PROCEDURE UpdateFailureReason(
	in_failed_notification_id		IN	csr.failed_notification.notification_type_id%TYPE,
	in_failure_code					IN	csr.failed_notification.failure_code%TYPE,
	in_failure_exception			IN	csr.failed_notification.failure_exception%TYPE,
	in_failure_detail				IN	csr.failed_notification.failure_detail%TYPE
)
AS
BEGIN
	AssertHasFailureManagementCapability();

	UPDATE failed_notification
	   SET failure_code = in_failure_code,
		   failure_exception = in_failure_exception,
		   failure_detail = in_failure_detail,
		   retry_count = retry_count + 1,
		   action = FAILURE_PENDING_NONE
	 WHERE failed_notification_id = in_failed_notification_id;
END;

PROCEDURE SetFailureAction(
	in_failed_notification_id		IN	csr.failed_notification.notification_type_id%TYPE,
	in_action						IN	csr.failed_notification.action%TYPE,
	out_success						OUT NUMBER
)
AS
	v_exists						NUMBER;
BEGIN
	AssertHasFailureManagementCapability();

	SELECT COUNT(failed_notification_id)
	  INTO v_exists
	  FROM failed_notification
	 WHERE failed_notification_id = in_failed_notification_id
	   AND ROWNUM = 1;

	IF v_exists = 0 THEN
		RAISE NO_DATA_FOUND;
	END IF;

	-- To maintain a consistent state, once a pending action has been set it can only be cleared
	-- with `UpdateFailureReason` or by archiving the failure.
	UPDATE failed_notification
	   SET create_dtm = SYSDATE,
		   action = in_action
	 WHERE failed_notification_id = in_failed_notification_id
	   AND action IN (FAILURE_PENDING_NONE, in_action);

	IF SQL%ROWCOUNT > 0 THEN
		out_success := 1;
	ELSE
		out_success := 0;
	END IF;
END;

PROCEDURE GetPendingFailureTenants(
	in_max_age_hours				IN NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT t.tenant_id
		  FROM security.tenant t
		  JOIN csr.failed_notification fn
		    ON fn.app_sid = t.application_sid_id
		 WHERE fn.action <> FAILURE_PENDING_NONE
		    OR fn.create_dtm <= SYSDATE - (in_max_age_hours / 24);
END;

PROCEDURE GetPendingResend(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	AssertHasFailureManagementCapability();

	OPEN out_cur FOR
		SELECT
			fn.failed_notification_id,
			fn.notification_type_id,
			fn.to_user,
			fn.channel,
			fn.failure_code,
			fn.from_user,
			fn.merge_fields,
			fn.repeating_merge_fields,
			fn.action,
			fn.create_dtm,
			fn.retry_count
		  FROM csr.failed_notification fn
		 WHERE fn.action = FAILURE_PENDING_RETRY;
END;

PROCEDURE ArchiveFailures(
	in_ids							IN	security.security_pkg.T_SID_IDS,
	in_archive_reason				IN	failed_notification_archive.archive_reason%TYPE
)
AS
	v_ids							security.T_SID_TABLE := security.security_pkg.SidArrayToTable(in_ids);
BEGIN
	INSERT INTO failed_notification_archive (
		failed_notification_id,
		create_dtm,
		archive_reason,
		notification_type_id,
		to_user,
		channel,
		failure_code,
		failure_exception,
		failure_detail,
		from_user,
		merge_fields,
		repeating_merge_fields,
		retry_count
	)
		SELECT
			failed_notification_id,
			create_dtm,
			in_archive_reason,
			notification_type_id,
			to_user,
			channel,
			failure_code,
			failure_exception,
			failure_detail,
			from_user,
			merge_fields,
			repeating_merge_fields,
			retry_count
		FROM
			failed_notification
		WHERE
			failed_notification_id IN (SELECT column_value FROM TABLE(v_ids));

	DELETE FROM failed_notification
	 WHERE failed_notification_id IN (SELECT column_value FROM TABLE(v_ids));

END;

PROCEDURE ArchiveDeletedFailures
AS
	expired_ids						security.security_pkg.T_SID_IDS;
BEGIN
	AssertHasFailureManagementCapability();

	SELECT failed_notification_id
	  BULK COLLECT INTO expired_ids
	  FROM failed_notification
	 WHERE action = FAILURE_PENDING_DELETE;

	ArchiveFailures(expired_ids, FAILURE_ARCHIVED_DELETED);
END;

PROCEDURE ArchiveExpiredFailures(
	in_max_age_hours				IN	NUMBER
)
AS
	expired_ids						security.security_pkg.T_SID_IDS;
BEGIN
	AssertHasFailureManagementCapability();

	SELECT failed_notification_id
	  BULK COLLECT INTO expired_ids
	  FROM failed_notification
	 WHERE create_dtm <= SYSDATE - (in_max_age_hours / 24);

	ArchiveFailures(expired_ids, FAILURE_ARCHIVED_EXPIRED);
END;

PROCEDURE ArchiveSentFailures(
	in_ids							IN	security.security_pkg.T_SID_IDS
)
AS
	v_ids							security.T_SID_TABLE := security.security_pkg.SidArrayToTable(in_ids);
BEGIN
	AssertHasFailureManagementCapability();

	-- Increment retry count
	UPDATE failed_notification
	   SET retry_count = retry_count + 1
	 WHERE failed_notification_id IN (SELECT column_value FROM TABLE(v_ids));

	ArchiveFailures(in_ids, FAILURE_ARCHIVED_SENT);
END;

END;
/
