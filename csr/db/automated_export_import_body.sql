CREATE OR REPLACE PACKAGE BODY csr.automated_export_import_pkg AS

PROCEDURE ScheduleRun
AS
BEGIN

	automated_import_pkg.ScheduleRun();
	automated_export_pkg.ScheduleRun();

END;

FUNCTION GetNextScheduledDtm(
	in_schedule_xml			IN automated_import_class.schedule_xml%TYPE,
	in_last_scheduled_dtm	IN automated_import_class.last_scheduled_dtm%TYPE
)
RETURN DATE
AS
	v_next_scheduled_dtm	DATE;
	v_schedule 				RECURRENCE_PATTERN;
BEGIN
	BEGIN
		IF in_schedule_xml IS NOT NULL AND in_last_scheduled_dtm IS NOT NULL THEN
			v_next_scheduled_dtm := recurrence_pattern_pkg.getnextoccurrence(in_schedule_xml, NVL(in_last_scheduled_dtm, SYSDATE));

			v_schedule := RECURRENCE_PATTERN(in_schedule_xml);
			IF v_schedule.repeat_period = 'hourly' THEN
				RETURN v_next_scheduled_dtm;
			ELSE
				-- persist last scheduled time component
				RETURN TO_DATE(TO_CHAR(v_next_scheduled_dtm, 'dd/mm/yyyy ') || TO_CHAR(in_last_scheduled_dtm, 'HH24:MI:SS'), 'dd/mm/yyyy HH24:MI:SS');
			END IF;
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			-- There's something wrong with the schedule but we don't want to break ALL the schedules.
			RETURN SYSDATE;
	END;

	RETURN SYSDATE;

END;

PROCEDURE WriteExportInstanceMessage(
	in_instance_id			IN 	automated_export_instance.automated_export_instance_id%TYPE,
	in_message				IN  auto_impexp_instance_msg.message%TYPE,
	in_severity				IN  auto_impexp_instance_msg.severity%TYPE
)
AS
	v_message_id				auto_impexp_instance_msg.message_id%TYPE;
BEGIN

	WriteInstanceMessage(in_message, in_severity, v_message_id);
	INSERT INTO auto_export_message_map (export_instance_id, message_id)
	VALUES (in_instance_id, v_message_id);

END;

PROCEDURE WriteImportInstanceMessage(
	in_instance_id			IN 	automated_export_instance.automated_export_instance_id%TYPE,
	in_message				IN  auto_impexp_instance_msg.message%TYPE,
	in_severity				IN  auto_impexp_instance_msg.severity%TYPE
)
AS
BEGIN

	WriteImportInstanceStepMessage(in_instance_id, NULL, in_message, in_severity);

END;

PROCEDURE WriteImportInstanceStepMessage(
	in_instance_id			IN 	automated_import_instance.automated_import_instance_id%TYPE,
	in_instance_step_id		IN 	automated_import_instance_step.auto_import_instance_step_id%TYPE,
	in_message				IN  auto_impexp_instance_msg.message%TYPE,
	in_severity				IN  auto_impexp_instance_msg.severity%TYPE
)
AS
	v_message_id				auto_impexp_instance_msg.message_id%TYPE;
BEGIN

	WriteInstanceMessage(in_message, in_severity, v_message_id);
	INSERT INTO auto_import_message_map (import_instance_id, import_instance_step_id, message_id)
	VALUES (in_instance_id, in_instance_step_id, v_message_id);

END;

PROCEDURE WriteInstanceMessage(
	in_message				IN	auto_impexp_instance_msg.message%TYPE,
	in_severity				IN	auto_impexp_instance_msg.severity%TYPE,
	out_message_id			OUT	auto_impexp_instance_msg.message_id%TYPE
)
AS
BEGIN

	INSERT INTO auto_impexp_instance_msg (message_id, message, severity, msg_dtm)
	VALUES (auto_impexp_instance_msg_seq.nextval, in_message, in_severity, SYSDATE)
	RETURNING message_id INTO out_message_id;

END;

PROCEDURE GetMostRecentInstances(
	in_parent_sid			IN	security_pkg.T_SID_ID,
	out_export_cur			OUT SYS_REFCURSOR,
	out_import_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	automated_export_pkg.GetMostRecentInstances(in_parent_sid, out_export_cur);
	automated_import_pkg.GetMostRecentInstances(in_parent_sid, out_import_cur);
END;


/* SETUP SCRIPTS*/

PROCEDURE MakeFtpProfile(
	in_label				IN	ftp_profile.label%TYPE,
	in_host_name			IN	ftp_profile.host_name%TYPE,
	in_secure_creds			IN	ftp_profile.secure_credentials%TYPE DEFAULT NULL,
	in_fingerprint			IN	ftp_profile.fingerprint%TYPE,
	in_username				IN	ftp_profile.username%TYPE,
	in_password				IN	ftp_profile.password%TYPE DEFAULT NULL,
	in_port_number			IN	ftp_profile.port_number%TYPE,
	in_ftp_protocol_id		IN	ftp_profile.ftp_protocol_id%TYPE,
	out_ftp_profile_id		OUT	ftp_profile.ftp_profile_id%TYPE
)
AS
BEGIN

	SELECT ftp_profile_id_seq.nextval
	  INTO out_ftp_profile_id
	  FROM dual;

	INSERT INTO ftp_profile (ftp_profile_id, label, host_name, secure_credentials, fingerprint, username, password, port_number, ftp_protocol_id)
	VALUES (out_ftp_profile_id, in_label, in_host_name, in_secure_creds, in_fingerprint, in_username, in_password, in_port_number, in_ftp_protocol_id);

END;

PROCEDURE MakeFtpProfile(
	in_label				IN	ftp_profile.label%TYPE,
	in_host_name			IN	ftp_profile.host_name%TYPE,
	in_fingerprint			IN	ftp_profile.fingerprint%TYPE,
	in_username				IN	ftp_profile.username%TYPE,
	in_password				IN	ftp_profile.password%TYPE,
	in_port_number			IN	ftp_profile.port_number%TYPE,
	out_ftp_profile_id		OUT	ftp_profile.ftp_profile_id%TYPE
)
AS
BEGIN

	-- FTP is 0 (select * from FTP_PROTOCOL;)
	automated_export_import_pkg.MakeFtpProfile(in_label, in_host_name, null, in_fingerprint, in_username, in_password, in_port_number, 0, out_ftp_profile_id);

END;

PROCEDURE MakeFtpsProfile(
	in_label				IN	ftp_profile.label%TYPE,
	in_host_name			IN	ftp_profile.host_name%TYPE,
	in_fingerprint			IN	ftp_profile.fingerprint%TYPE,
	in_username				IN	ftp_profile.username%TYPE,
	in_password				IN	ftp_profile.password%TYPE,
	in_port_number			IN	ftp_profile.port_number%TYPE,
	out_ftp_profile_id		OUT	ftp_profile.ftp_profile_id%TYPE
)
AS
BEGIN

	-- FTPS is 1 (select * from FTP_PROTOCOL;)
	automated_export_import_pkg.MakeFtpProfile(in_label, in_host_name, null, in_fingerprint, in_username, in_password, in_port_number, 1, out_ftp_profile_id);

END;

PROCEDURE MakeSFtpProfile(
	in_label				IN	ftp_profile.label%TYPE,
	in_host_name			IN	ftp_profile.host_name%TYPE,
	in_secure_creds			IN	ftp_profile.secure_credentials%TYPE,
	in_fingerprint			IN	ftp_profile.fingerprint%TYPE,
	in_username				IN	ftp_profile.username%TYPE,
	in_password				IN	ftp_profile.password%TYPE,
	in_port_number			IN	ftp_profile.port_number%TYPE,
	out_ftp_profile_id		OUT	ftp_profile.ftp_profile_id%TYPE
)
AS
BEGIN

	-- FTP is 2 (select * from FTP_PROTOCOL;)
	automated_export_import_pkg.MakeFtpProfile(in_label, in_host_name, in_secure_creds, in_fingerprint, in_username, in_password, in_port_number, 2, out_ftp_profile_id);

END;

FUNCTION CreateCr360FTPProfile(
	in_label			ftp_profile.label%TYPE DEFAULT 'Cr360 SFTP'
)
RETURN ftp_profile.ftp_profile_id%TYPE
AS
	v_ftp_profile_id				ftp_profile.ftp_profile_id%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied creating FTP profile, only BuiltinAdministrator or super admins can run this.');
	END IF;

	BEGIN
		MakeFtpProfile(
			in_label						=> in_label,
			in_host_name					=> automated_export_import_pkg.FTP_HOST,
			in_fingerprint					=> 'ssh-rsa 2048 f8:34:18:03:83:5f:9d:95:13:b4:85:4d:d0:71:85:57',
			in_username						=> 'cmsimport',
			in_port_number					=> 2222,
			in_ftp_protocol_id				=> 2,
			out_ftp_profile_id				=> v_ftp_profile_id
		);
		AuditFtpWithMsg(v_ftp_profile_id, 'Profile created.');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- Note: SetupAutoCreateMeters in meter_monitor_body relies on this error in this situation.
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'An FTP profile with that name already exists.');
	END;

	RETURN v_ftp_profile_id;
END;

PROCEDURE GetFtpProtocols(
	out_cur						 	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT protocol_id, label
		  FROM csr.ftp_protocol;
END;

FUNCTION IsFtpProfileInUse(
	in_ftp_profile_id		IN	ftp_profile.ftp_profile_id%TYPE
) RETURN NUMBER
AS
	v_import_cnt	NUMBER;
	v_export_cnt	NUMBER;
BEGIN

	SELECT COUNT(*)
	  INTO v_import_cnt
	  FROM auto_imp_fileread_ftp
	 WHERE ftp_profile_id = in_ftp_profile_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	SELECT COUNT(*)
	  INTO v_export_cnt
	  FROM auto_exp_filewrite_ftp
	 WHERE ftp_profile_id = in_ftp_profile_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF v_import_cnt + v_export_cnt > 0 THEN
		RETURN 1;
	END IF;

	RETURN 0;

END;

PROCEDURE GetFtpProfiles(
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN

	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can run this procedure.');
	END IF;

	OPEN out_cur FOR
		SELECT ftp_profile_id, label, host_name, CASE WHEN secure_credentials IS NULL THEN 1 ELSE 0 END app_server_auth, IsFtpProfileInUse(ftp_profile_id) in_use, preserve_timestamp, enable_debug_log, use_username_password_auth
		  FROM ftp_profile
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetFtpProfile(
	in_ftp_profile_id		IN	ftp_profile.ftp_profile_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT ftp_profile_id, label, host_name, fingerprint, username, CASE WHEN password IS NULL THEN 0 ELSE 1 END has_password, port_number, ftp_protocol_id,
			   CASE WHEN secure_credentials IS NULL THEN 1 ELSE 0 END app_server_auth, IsFtpProfileInUse(ftp_profile_id) in_use, preserve_timestamp, enable_debug_log, use_username_password_auth
		  FROM ftp_profile fp
		 WHERE ftp_profile_id = in_ftp_profile_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE DeleteFtpProfile(
	in_ftp_profile_id		IN	ftp_profile.ftp_profile_id%TYPE
)
AS
BEGIN

	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can delete FTP profiles.');
	END IF;

	BEGIN
		DELETE FROM ftp_profile
		 WHERE ftp_profile_id = in_ftp_profile_id;

		 AuditFtpWithMsg(in_ftp_profile_id, 'Profile deleted.');
	EXCEPTION
		WHEN OTHERS THEN
			RAISE_APPLICATION_ERROR(-20001, 'FTP profile cannot be deleted.');
	END;

END;

PROCEDURE EditFtpProfile(
	in_ftp_profile_id				IN	ftp_profile.ftp_profile_id%TYPE,
	in_label						IN	ftp_profile.label%TYPE,
	in_host_name					IN	ftp_profile.host_name%TYPE,
	in_port_number					IN	ftp_profile.port_number%TYPE,
	in_fingerprint					IN	ftp_profile.fingerprint%TYPE,
	in_username						IN	ftp_profile.username%TYPE,
	in_password						IN	ftp_profile.password%TYPE,
	in_change_password				IN	NUMBER,
	in_preserve_timestamp			IN	ftp_profile.preserve_timestamp%TYPE,
	in_enable_debug_log				IN	ftp_profile.enable_debug_log%TYPE,
	in_use_username_password_auth	in	ftp_profile.use_username_password_auth%type
)
AS
	v_password						ftp_profile.password%TYPE;
	v_label							ftp_profile.label%TYPE;
	v_host_name						ftp_profile.host_name%TYPE;
	v_port_number					ftp_profile.port_number%TYPE;
	v_fingerprint					ftp_profile.fingerprint%TYPE;
	v_username						ftp_profile.username%TYPE;
	v_preserve_timestamp			ftp_profile.preserve_timestamp%TYPE;
	v_enable_debug_log				ftp_profile.enable_debug_log%TYPE;
	v_use_username_password_auth	ftp_profile.use_username_password_auth%type;
BEGIN

	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can edit FTP profiles.');
	END IF;

	SELECT CASE in_change_password WHEN 1 THEN in_password ELSE password END pwd, label, host_name, port_number, fingerprint, username, preserve_timestamp, enable_debug_log, use_username_password_auth
	  INTO v_password, v_label, v_host_name, v_port_number, v_fingerprint, v_username, v_preserve_timestamp, v_enable_debug_log, v_use_username_password_auth
	  FROM ftp_profile
	 WHERE ftp_profile_id = in_ftp_profile_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	BEGIN
		UPDATE ftp_profile
		   SET label = in_label,
			   host_name = in_host_name,
			   port_number = in_port_number,
			   fingerprint = in_fingerprint,
			   username = in_username,
			   password = v_password,
			   preserve_timestamp = in_preserve_timestamp,
			   enable_debug_log = in_enable_debug_log,
			   use_username_password_auth = in_use_username_password_auth
		 WHERE ftp_profile_id = in_ftp_profile_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'An FTP profile with that name already exists.');
	END;

	AuditFtpValue(in_ftp_profile_id, 'label', in_label, v_label);
	AuditFtpValue(in_ftp_profile_id, 'host name', in_host_name, v_host_name);
	AuditFtpValue(in_ftp_profile_id, 'port number', in_port_number, v_port_number);
	AuditFtpValue(in_ftp_profile_id, 'fingerprint', in_fingerprint, v_fingerprint);
	AuditFtpValue(in_ftp_profile_id, 'username', in_username, v_username);
	AuditFtpValue(in_ftp_profile_id, 'preserve_timestamp', in_preserve_timestamp, v_preserve_timestamp);
	AuditFtpValue(in_ftp_profile_id, 'enable_debug_log', in_enable_debug_log, v_enable_debug_log);
	AuditFtpValue(in_ftp_profile_id, 'use_username_password_auth', in_use_username_password_auth, v_use_username_password_auth);
	IF in_change_password = 1 THEN
		AuditFtpWithMsg(in_ftp_profile_id, 'Password changed.');
	END IF;

END;

PROCEDURE GetDelimiters(
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN

	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can run this procedure.');
	END IF;

	OPEN out_cur FOR
		SELECT delimiter_id, label
		  FROM auto_exp_imp_dsv_delimiters;

END;

-- FTP AUDIT LOGGING

PROCEDURE AuditFtpValue(
	in_ftp_profile_id		IN	NUMBER,
	in_field				IN	VARCHAR2,
	in_new_val				IN	VARCHAR2,
	in_old_val				IN	VARCHAR2
)
AS
	v_msg					VARCHAR2(1024);
BEGIN

	IF in_new_val = in_old_val THEN
		RETURN;
	END IF;

	v_msg := 'Changed '||in_field||' from "'||in_old_val||'" to "'||in_new_val||'"';

	AuditFtpWithMsg(
		in_ftp_profile_id		=> in_ftp_profile_id,
		in_msg					=> v_msg
	);

END;

PROCEDURE AuditFtpWithMsg(
	in_ftp_profile_id		IN	NUMBER,
	in_msg					IN	VARCHAR2
)
AS
BEGIN

	INSERT INTO ftp_profile_log
		(ftp_profile_id, changed_dtm, changed_by_user_sid, message)
	VALUES
		(in_ftp_profile_id, SYSDATE, SYS_CONTEXT('SECURITY', 'SID'), in_msg);

END;

-- END FTP AUDIT LOGGING

-- Public Keys

PROCEDURE AuditPublicKeyWithMsg(
	in_public_key_id		IN	NUMBER,
	in_msg					IN	VARCHAR2,
	in_new_key				IN	auto_impexp_public_key.key_blob%TYPE,
	in_old_key				IN	auto_impexp_public_key.key_blob%TYPE
)
AS
BEGIN

	INSERT INTO public_key_log
		(public_key_id, changed_dtm, changed_by_user_sid, message, from_key_blob, to_key_blob)
	VALUES
		(in_public_key_id, SYSDATE, SYS_CONTEXT('SECURITY', 'SID'), in_msg, in_old_key, in_new_key);

END;

PROCEDURE AuditPublicKeyValue(
	in_public_key_id		IN	NUMBER,
	in_field				IN	VARCHAR2,
	in_new_val				IN	VARCHAR2,
	in_old_val				IN	VARCHAR2,
	in_new_key				IN	auto_impexp_public_key.key_blob%TYPE,
	in_old_key				IN	auto_impexp_public_key.key_blob%TYPE
)
AS
	v_msg					VARCHAR2(1024) := '';
BEGIN

	IF in_old_val IS NULL OR in_new_val != in_old_val THEN
		IF in_old_val IS NOT NULL THEN
			v_msg := v_msg||'Changed '||in_field||' from "'||in_old_val||'" to "'||in_new_val||'"';
		ELSE
			v_msg := v_msg||'Added '||in_field||' "'||in_new_val||'"';
		END IF;
	END IF;

	IF in_old_key IS NULL OR dbms_lob.compare(in_old_key, in_new_key) != 0 THEN
		IF LENGTH(v_msg) <> 0 THEN
			v_msg := v_msg||'; ';
		END IF;
		IF in_old_key IS NOT NULL THEN
			v_msg := v_msg||'Updated key';
		ELSE
			v_msg := v_msg||'Created key';
		END IF;
	END IF;

	AuditPublicKeyWithMsg(
		in_public_key_id		=> in_public_key_id,
		in_msg					=> v_msg,
		in_new_key				=> in_new_key,
		in_old_key				=> in_old_key
	);

END;

PROCEDURE GetPublicKeys(
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN

	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can run this procedure.');
	END IF;

	OPEN out_cur FOR
		SELECT public_key_id, label, key_blob --utl_raw.cast_to_varchar2(dbms_lob.substr(key_blob)) key
		  FROM auto_impexp_public_key
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetPublicKey(
	in_public_key_id		IN	auto_impexp_public_key.public_key_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT public_key_id, label, key_blob --utl_raw.cast_to_varchar2(dbms_lob.substr(key_blob)) key
		  FROM auto_impexp_public_key
		 WHERE public_key_id = in_public_key_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE DeletePublicKey(
	in_public_key_id		IN	auto_impexp_public_key.public_key_id%TYPE
)
AS
	v_label					auto_impexp_public_key.label%TYPE;
	v_key_blob				auto_impexp_public_key.key_blob%TYPE;
BEGIN

	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can delete public keys.');
	END IF;

	SELECT label, key_blob
	  INTO v_label, v_key_blob
	  FROM auto_impexp_public_key
	 WHERE public_key_id = in_public_key_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	BEGIN
		DELETE FROM auto_impexp_public_key
		 WHERE public_key_id = in_public_key_id;

		 AuditPublicKeyWithMsg(in_public_key_id, 'Public key "'||v_label||'" deleted.', NULL, v_key_blob);
	EXCEPTION
		WHEN OTHERS THEN
			RAISE_APPLICATION_ERROR(-20001, 'Public key cannot be deleted.');
	END;

END;

FUNCTION CreatePublicKey(
	in_label				IN	auto_impexp_public_key.label%TYPE,
	in_key					IN	auto_impexp_public_key.key_blob%TYPE
) RETURN auto_impexp_public_key.public_key_id%TYPE
AS
	v_public_key_id			auto_impexp_public_key.public_key_id%TYPE;
	v_label					auto_impexp_public_key.label%TYPE;
	v_key_blob				auto_impexp_public_key.key_blob%TYPE;
BEGIN

	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can create public keys.');
	END IF;

	SELECT auto_impexp_public_key_id_seq.nextval
	  INTO v_public_key_id
	  FROM DUAL;

	BEGIN
		INSERT INTO auto_impexp_public_key (public_key_id, label, key_blob)
		VALUES (v_public_key_id, in_label, in_key);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'A public key with that name already exists.');
	END;

	AuditPublicKeyValue(v_public_key_id, 'label', in_label, NULL, in_key, NULL);

	RETURN v_public_key_id;
END;

PROCEDURE EditPublicKey(
	in_public_key_id		IN	auto_impexp_public_key.public_key_id%TYPE,
	in_label				IN	auto_impexp_public_key.label%TYPE
)
AS
	v_label					auto_impexp_public_key.label%TYPE;
	v_key_blob				auto_impexp_public_key.key_blob%TYPE;
BEGIN

	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can edit public keys.');
	END IF;

	SELECT label, key_blob
	  INTO v_label, v_key_blob
	  FROM auto_impexp_public_key
	 WHERE public_key_id = in_public_key_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	BEGIN
		UPDATE auto_impexp_public_key
		   SET label = in_label
		 WHERE public_key_id = in_public_key_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'A public key with that name already exists.');
	END;

	AuditPublicKeyValue(in_public_key_id, 'label', in_label, v_label, v_key_blob, v_key_blob);

END;

-- End Public Keys
END;

/
