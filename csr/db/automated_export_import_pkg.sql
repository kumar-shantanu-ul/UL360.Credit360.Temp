CREATE OR REPLACE PACKAGE csr.automated_export_import_pkg AS

FTP_HOST	CONSTANT VARCHAR2(128) := 'CYANOXANTHA';

PROCEDURE ScheduleRun;

FUNCTION GetNextScheduledDtm(
	in_schedule_xml			IN automated_import_class.schedule_xml%TYPE,
	in_last_scheduled_dtm	IN automated_import_class.last_scheduled_dtm%TYPE
)
RETURN DATE;

PROCEDURE WriteExportInstanceMessage(
	in_instance_id			IN 	automated_export_instance.automated_export_instance_id%TYPE,
	in_message				IN  auto_impexp_instance_msg.message%TYPE,
	in_severity				IN  auto_impexp_instance_msg.severity%TYPE
);

PROCEDURE WriteImportInstanceMessage(
	in_instance_id			IN 	automated_export_instance.automated_export_instance_id%TYPE,
	in_message				IN  auto_impexp_instance_msg.message%TYPE,
	in_severity				IN  auto_impexp_instance_msg.severity%TYPE
);

PROCEDURE WriteImportInstanceStepMessage(
	in_instance_id			IN 	automated_import_instance.automated_import_instance_id%TYPE,
	in_instance_step_id		IN 	automated_import_instance_step.auto_import_instance_step_id%TYPE,
	in_message				IN  auto_impexp_instance_msg.message%TYPE,
	in_severity				IN  auto_impexp_instance_msg.severity%TYPE
);

PROCEDURE WriteInstanceMessage(
	in_message				IN	auto_impexp_instance_msg.message%TYPE,
	in_severity				IN	auto_impexp_instance_msg.severity%TYPE,
	out_message_id			OUT	auto_impexp_instance_msg.message_id%TYPE
);

PROCEDURE GetMostRecentInstances(
	in_parent_sid			IN	security_pkg.T_SID_ID,
	out_export_cur			OUT SYS_REFCURSOR,
	out_import_cur			OUT	SYS_REFCURSOR
);

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
);

PROCEDURE MakeFtpProfile(
	in_label				IN	ftp_profile.label%TYPE,
	in_host_name			IN	ftp_profile.host_name%TYPE,
	in_fingerprint			IN	ftp_profile.fingerprint%TYPE,
	in_username				IN	ftp_profile.username%TYPE,
	in_password				IN	ftp_profile.password%TYPE,
	in_port_number			IN	ftp_profile.port_number%TYPE,
	out_ftp_profile_id		OUT	ftp_profile.ftp_profile_id%TYPE
);

PROCEDURE MakeFtpsProfile(
	in_label				IN	ftp_profile.label%TYPE,
	in_host_name			IN	ftp_profile.host_name%TYPE,
	in_fingerprint			IN	ftp_profile.fingerprint%TYPE,
	in_username				IN	ftp_profile.username%TYPE,
	in_password				IN	ftp_profile.password%TYPE,
	in_port_number			IN	ftp_profile.port_number%TYPE,
	out_ftp_profile_id		OUT	ftp_profile.ftp_profile_id%TYPE
);

PROCEDURE MakeSFtpProfile(
	in_label				IN	ftp_profile.label%TYPE,
	in_host_name			IN	ftp_profile.host_name%TYPE,
	in_secure_creds			IN	ftp_profile.secure_credentials%TYPE,
	in_fingerprint			IN	ftp_profile.fingerprint%TYPE,
	in_username				IN	ftp_profile.username%TYPE,
	in_password				IN	ftp_profile.password%TYPE,
	in_port_number			IN	ftp_profile.port_number%TYPE,
	out_ftp_profile_id		OUT	ftp_profile.ftp_profile_id%TYPE
);

FUNCTION CreateCr360FTPProfile(
	in_label			ftp_profile.label%TYPE DEFAULT 'Cr360 SFTP'
)
RETURN ftp_profile.ftp_profile_id%TYPE;

PROCEDURE GetFtpProtocols(
	out_cur							OUT SYS_REFCURSOR
);

FUNCTION IsFtpProfileInUse(
	in_ftp_profile_id		IN	ftp_profile.ftp_profile_id%TYPE
) RETURN NUMBER;

PROCEDURE GetFtpProfiles(
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetFtpProfile(
	in_ftp_profile_id		IN	ftp_profile.ftp_profile_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE DeleteFtpProfile(
	in_ftp_profile_id		IN	ftp_profile.ftp_profile_id%TYPE
);

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
	in_use_username_password_auth	IN	ftp_profile.use_username_password_auth%TYPE DEFAULT 0
);

PROCEDURE GetDelimiters(
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE AuditFtpValue(
	in_ftp_profile_id		IN	NUMBER,
	in_field				IN	VARCHAR2,
	in_new_val				IN	VARCHAR2,
	in_old_val				IN	VARCHAR2
);

PROCEDURE AuditFtpWithMsg(
	in_ftp_profile_id		IN	NUMBER,
	in_msg					IN	VARCHAR2
);

PROCEDURE GetPublicKeys(
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetPublicKey(
	in_public_key_id		IN	auto_impexp_public_key.public_key_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE DeletePublicKey(
	in_public_key_id		IN	auto_impexp_public_key.public_key_id%TYPE
);

FUNCTION CreatePublicKey(
	in_label				IN	auto_impexp_public_key.label%TYPE,
	in_key					IN	auto_impexp_public_key.key_blob%TYPE
) RETURN auto_impexp_public_key.public_key_id%TYPE;

PROCEDURE EditPublicKey(
	in_public_key_id		IN	auto_impexp_public_key.public_key_id%TYPE,
	in_label				IN	auto_impexp_public_key.label%TYPE
);

END;
/
