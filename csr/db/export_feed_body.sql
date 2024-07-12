CREATE OR REPLACE PACKAGE BODY CSR.export_feed_pkg
AS

PROCEDURE CreateObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_class_id						IN security_pkg.T_CLASS_ID,
	in_name							IN security_pkg.T_SO_NAME,
	in_parent_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_new_name						IN security_pkg.T_SO_NAME
)
AS
BEGIN
	UPDATE export_feed
	   SET name = in_new_name
	 WHERE export_feed_sid = in_sid_id;
END;

PROCEDURE DeleteObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE FROM export_feed_dataview
	 WHERE export_feed_sid = in_sid_id;

	DELETE FROM export_feed
	 WHERE export_feed_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN security_pkg.T_SID_ID,
	in_old_parent_sid_id			IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE TrashObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN  security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE CreateSecureFeed(
	in_name							IN	security_pkg.T_SO_NAME,
	in_protocol						IN	export_feed.protocol%TYPE,
	in_url							IN	export_feed.url%TYPE,
	in_secure_creds					IN  export_feed.secure_creds%TYPE,
	in_interval						IN	export_feed.interval%TYPE,
	in_start_dtm					IN	export_feed.start_dtm%TYPE,
	out_feed_sid					OUT	security_pkg.T_SID_ID
)
AS
	v_act	security.security_pkg.T_ACT_ID := security_pkg.getact;
	v_app	security.security_pkg.T_SID_ID := security_pkg.getapp;
BEGIN
	group_pkg.CreateGroupWithClass(v_act, v_app, security_pkg.GROUP_TYPE_SECURITY,
		Replace(in_name,'/','\'), class_pkg.getClassID('CSRExportFeed'), out_feed_sid); --'

	acl_pkg.AddACE(v_act, acl_pkg.GetDACLIDForSID(out_feed_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
	security_pkg.ACE_FLAG_DEFAULT, out_feed_sid, security_pkg.PERMISSION_STANDARD_READ);

	INSERT INTO export_feed(export_feed_sid, app_sid, name, protocol, url, secure_creds, interval, start_dtm)
		 VALUES (out_feed_sid, v_app, in_name, in_protocol, in_url, in_secure_creds, in_interval, in_start_dtm);

	csr_data_pkg.WriteAuditLogEntry(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app, out_feed_sid,
		'Created "{0}"', in_name);
END;

PROCEDURE CreateFeed(
	in_name							IN	security_pkg.T_SO_NAME,
	in_protocol						IN	export_feed.protocol%TYPE,
	in_url							IN	export_feed.url%TYPE,
	in_interval						IN	export_feed.interval%TYPE,
	in_start_dtm					IN	export_feed.start_dtm%TYPE,
	out_feed_sid					OUT	security_pkg.T_SID_ID
)
AS
	v_act	security.security_pkg.T_ACT_ID := security_pkg.getact;
	v_app	security.security_pkg.T_SID_ID := security_pkg.getapp;
BEGIN
	group_pkg.CreateGroupWithClass(v_act, v_app, security_pkg.GROUP_TYPE_SECURITY,
		Replace(in_name,'/','\'), class_pkg.getClassID('CSRExportFeed'), out_feed_sid); --'

	acl_pkg.AddACE(v_act, acl_pkg.GetDACLIDForSID(out_feed_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
	security_pkg.ACE_FLAG_DEFAULT, out_feed_sid, security_pkg.PERMISSION_STANDARD_READ);

	INSERT INTO export_feed (export_feed_Sid, app_sid, name, protocol, url, interval, start_dtm)
		VALUES (out_feed_sid, v_app, in_name, in_protocol, in_url, in_interval, in_start_dtm);

	csr_data_pkg.WriteAuditLogEntry(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app, out_feed_sid,
		'Created "{0}"', in_name);
END;

PROCEDURE GetExportFeed(
	in_export_feed_sid				IN	security_pkg.T_SID_ID,
	out_export_feed_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getact, in_export_feed_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the export feed with sid '||in_export_feed_sid);
	END IF;

	OPEN out_export_feed_cur FOR
		SELECT app_sid, export_feed_sid, name, url, secure_creds, interval, start_dtm, end_dtm,
			   protocol, last_success_attempt_dtm, last_attempt_dtm
		  FROM export_feed
		 WHERE export_feed_sid = in_export_feed_sid;
END;

PROCEDURE UNSEC_GetAppsToProcessExpFeeds(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security as this is called by batch
	OPEN out_cur FOR
		SELECT DISTINCT app_sid
		  FROM export_feed
		 WHERE start_dtm < SYSDATE
		   AND (end_dtm IS NULL OR end_dtm > SYSDATE)
		   AND (last_success_attempt_dtm IS NULL OR
				interval = '-' OR
				last_success_attempt_dtm < CASE INTERVAL
					-- get date of latest scheduled run
					WHEN 'd' THEN start_dtm + floor(SYSDATE - start_dtm)
					WHEN 'm' THEN add_months(start_dtm, floor(months_between(SYSDATE, start_dtm))) 
					WHEN 'q' THEN add_months(start_dtm, floor(months_between(SYSDATE, start_dtm)/3)*3) 
					WHEN 'h' THEN add_months(start_dtm, floor(months_between(SYSDATE, start_dtm)/6)*6) 
					WHEN 'y' THEN add_months(start_dtm, floor(months_between(SYSDATE, start_dtm)/12)*12)
				END);
END;


PROCEDURE UNSEC_GetExportFeedsForApp(
	out_export_feed_cur				OUT	SYS_REFCURSOR
)
AS
	v_app		security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	OPEN out_export_feed_cur FOR
		SELECT app_sid, export_feed_sid, name, url, secure_creds, interval, start_dtm, end_dtm,
			   protocol, last_success_attempt_dtm, last_attempt_dtm, alert_recipients
		  FROM export_feed
		 WHERE start_dtm < SYSDATE
		   AND app_sid = v_app
		   AND (end_dtm IS NULL OR end_dtm > SYSDATE)
		   AND (last_success_attempt_dtm IS NULL OR
				interval = '-' OR
				last_success_attempt_dtm < CASE INTERVAL
					-- get date of latest scheduled run
					WHEN 'd' THEN start_dtm + floor(SYSDATE - start_dtm)
					WHEN 'm' THEN add_months(start_dtm, floor(months_between(SYSDATE, start_dtm))) 
					WHEN 'q' THEN add_months(start_dtm, floor(months_between(SYSDATE, start_dtm)/3)*3) 
					WHEN 'h' THEN add_months(start_dtm, floor(months_between(SYSDATE, start_dtm)/6)*6) 
					WHEN 'y' THEN add_months(start_dtm, floor(months_between(SYSDATE, start_dtm)/12)*12)
				END);
END;

FUNCTION GetStartDtmTimes(
	in_date							IN  DATE
) RETURN NUMBER
AS
BEGIN
	RETURN (EXTRACT (HOUR FROM to_timestamp(in_date))/24) + (EXTRACT (MINUTE FROM to_timestamp(in_date))/1440);
END;

PROCEDURE GetJobsForExportFeed(
	in_export_feed_sid				IN	security_pkg.T_SID_ID,
	out_dataview_cur				OUT	SYS_REFCURSOR,
	out_cms_form_cur				OUT SYS_REFCURSOR,
	out_stored_proc_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getact, in_export_feed_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the export feed with sid '||in_export_feed_sid);
	END IF;

	OPEN out_dataview_cur FOR
    -- Parameters must be in the correct order!
		SELECT dataview_sid, export_feed_sid, filename_mask, format "export_format", assembly_name
		  FROM export_feed_dataview
		 WHERE export_feed_sid = in_export_feed_sid;

	OPEN out_cms_form_cur FOR
    -- Parameters must be in the correct order!
		SELECT ef.last_success_attempt_dtm, ef.export_feed_sid, cf.app_sid, cf.incremental, cf.form_sid, cf.filename_mask, cf.format
		  FROM export_feed_cms_form cf
		  JOIN export_feed ef ON ef.export_feed_sid = cf.export_feed_sid
		 WHERE cf.export_feed_sid = in_export_feed_sid;

  	OPEN out_stored_proc_cur FOR
    
    -- Parameters must be in the correct order!
		SELECT ef.last_success_attempt_dtm, sp.export_feed_sid, sp.app_sid, sp.sp_params, sp.sp_name, sp.filename_mask, sp.format
		  FROM export_feed_stored_proc sp
		  JOIN export_feed ef ON ef.export_feed_sid = sp.export_feed_sid
		 WHERE sp.export_feed_sid = in_export_feed_sid;
END;


PROCEDURE UNSEC_SetTimestamps(
	in_export_feed_sid				IN	export_feed.export_feed_sid%TYPE,
	in_last_success_attempt_dtm		IN	export_feed.last_success_attempt_dtm%TYPE,
	in_last_attempt_dtm				IN	export_feed.last_attempt_dtm%TYPE
)
AS
BEGIN
	UPDATE export_feed
	   SET last_success_attempt_dtm = in_last_success_attempt_dtm, last_attempt_dtm = in_last_attempt_dtm
	 WHERE export_feed_sid = in_export_feed_sid;
END;

PROCEDURE UNSEC_SetTimestampOnError(
	in_export_feed_sid				IN	export_feed.export_feed_sid%TYPE,
	in_last_attempt_dtm				IN	export_feed.last_attempt_dtm%TYPE
)
AS
BEGIN
	UPDATE export_feed
	   SET last_attempt_dtm = in_last_attempt_dtm
	 WHERE export_feed_sid = in_export_feed_sid;
END;

END export_feed_pkg;
/
