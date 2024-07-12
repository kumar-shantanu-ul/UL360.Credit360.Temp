CREATE OR REPLACE PACKAGE BODY csr.target_profile_pkg AS

PROCEDURE AuditValue(in_target_profile_id IN NUMBER, in_field IN VARCHAR2, in_new_val IN VARCHAR2, in_old_val IN VARCHAR2);
PROCEDURE AuditWithMsg(in_target_profile_id IN NUMBER, in_msg IN VARCHAR2);

PROCEDURE GetTargetProfiles (
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can run this procedure.');
	END IF;

	OPEN out_cur FOR
		SELECT 	etp.target_profile_id, etp.label profile_label, etp.profile_type_id, etpt.label profile_type_label, 
				etp.sharepoint_site, etp.sharepoint_folder, etp.credential_profile_id, cm.label credential_profile_label,
				etp.onedrive_folder, etp.storage_acc_name, etp.storage_acc_container
		  FROM 	external_target_profile etp
		  JOIN 	external_target_profile_type etpt ON etp.profile_type_id = etpt.profile_type_id
		  JOIN 	credential_management cm ON etp.credential_profile_id = cm.credential_id
		 WHERE 	etp.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE DeleteTargetProfile(
	in_target_profile_id			IN  external_target_profile.target_profile_id%TYPE
)
AS
	v_profile_label						external_target_profile.label%TYPE;
	v_profile_type_id					external_target_profile.profile_type_id%TYPE;
	v_sharepoint_site					external_target_profile.sharepoint_site%TYPE;
	v_sharepoint_folder					external_target_profile.sharepoint_folder%TYPE;
	v_credential_profile_id				external_target_profile.credential_profile_id%TYPE;
	v_onedrive_folder					external_target_profile.onedrive_folder%TYPE;
	v_storage_acc_name					external_target_profile.storage_acc_name%TYPE;
	v_storage_acc_container				external_target_profile.storage_acc_container%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can delete external target profiles.');
	END IF;
	
	SELECT label, profile_type_id, sharepoint_site, sharepoint_folder, credential_profile_id, onedrive_folder, storage_acc_name, storage_acc_container
	  INTO v_profile_label, v_profile_type_id, v_sharepoint_site, v_sharepoint_folder, v_credential_profile_id, v_onedrive_folder, v_storage_acc_name, v_storage_acc_container
	  FROM external_target_profile
	 WHERE target_profile_id = in_target_profile_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	BEGIN
		DELETE FROM external_target_profile
		 WHERE target_profile_id = in_target_profile_id;
	EXCEPTION
		WHEN OTHERS THEN
			RAISE_APPLICATION_ERROR(-20001, 'Target profile cannot be deleted.');
	END;

	AuditWithMsg(in_target_profile_id, 'Deleted profile named ' || v_profile_label);
	AuditValue(in_target_profile_id, 'Type', 'Empty', v_profile_type_id);
	AuditValue(in_target_profile_id, 'Library Url', 'Empty', v_sharepoint_site);
	AuditValue(in_target_profile_id, 'Library Folder', 'Empty', v_sharepoint_folder);
	AuditValue(in_target_profile_id, 'Credential Profile', 'Empty', v_credential_profile_id);
	AuditValue(in_target_profile_id, 'OneDrive Folder', 'Empty', v_onedrive_folder);
	AuditValue(in_target_profile_id, 'Storage Account Name', 'Empty', v_storage_acc_name);
	AuditValue(in_target_profile_id, 'Storage Account Container', 'Empty', v_storage_acc_container);
END;

PROCEDURE CreateTargetProfile(
	in_profile_label					IN	external_target_profile.label%TYPE,
	in_profile_type_id					IN  external_target_profile.profile_type_id%TYPE,
	in_sharepoint_site					IN  external_target_profile.sharepoint_site%TYPE,
	in_sharepoint_folder				IN  external_target_profile.sharepoint_folder%TYPE,
	in_credential_profile_id			IN  external_target_profile.credential_profile_id%TYPE,
	in_onedrive_folder					IN  external_target_profile.onedrive_folder%TYPE,
	in_storage_acc_name					IN  external_target_profile.storage_acc_name%TYPE,
	in_storage_acc_container			IN  external_target_profile.storage_acc_container%TYPE
)
AS
	v_target_profile_id			external_target_profile.target_profile_id%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can edit external target profiles.');
	END IF;
	
	v_target_profile_id := external_target_profile_seq.nextval;
	
	INSERT INTO external_target_profile (target_profile_id, label, profile_type_id, sharepoint_site, sharepoint_folder, credential_profile_id, onedrive_folder, storage_acc_name, storage_acc_container)
	VALUES (v_target_profile_id, in_profile_label, in_profile_type_id, in_sharepoint_site, in_sharepoint_folder, in_credential_profile_id, in_onedrive_folder, in_storage_acc_name, in_storage_acc_container);
	
	AuditWithMsg(v_target_profile_id, 'Created profile named ' || in_profile_label);
	AuditValue(v_target_profile_id, 'Type', in_profile_type_id, 'Empty');
	AuditValue(v_target_profile_id, 'Library Url', in_sharepoint_site, 'Empty');
	AuditValue(v_target_profile_id, 'Library Folder', in_sharepoint_folder, 'Empty');
	AuditValue(v_target_profile_id, 'Credential Profile', in_credential_profile_id, 'Empty');
	AuditValue(v_target_profile_id, 'OneDrive Folder', in_onedrive_folder, 'Empty');
	AuditValue(v_target_profile_id, 'Storage Account Name', in_storage_acc_name, 'Empty');
	AuditValue(v_target_profile_id, 'Storage Account Container', in_storage_acc_container, 'Empty');
END;

PROCEDURE EditTargetProfile(
	in_target_profile_id				IN  external_target_profile.target_profile_id%TYPE,
	in_profile_label					IN	external_target_profile.label%TYPE,
	in_profile_type_id					IN  external_target_profile.profile_type_id%TYPE,
	in_sharepoint_site					IN  external_target_profile.sharepoint_site%TYPE,
	in_sharepoint_folder				IN  external_target_profile.sharepoint_folder%TYPE,
	in_credential_profile_id			IN  external_target_profile.credential_profile_id%TYPE,
	in_onedrive_folder					IN  external_target_profile.onedrive_folder%TYPE,
	in_storage_acc_name					IN  external_target_profile.storage_acc_name%TYPE,
	in_storage_acc_container			IN  external_target_profile.storage_acc_container%TYPE
)
AS
	v_profile_label					external_target_profile.label%TYPE;
	v_profile_type_id				external_target_profile.profile_type_id%TYPE;
	v_sharepoint_site				external_target_profile.sharepoint_site%TYPE;
	v_sharepoint_folder				external_target_profile.sharepoint_folder%TYPE;
	v_credential_profile_id			external_target_profile.credential_profile_id%TYPE;
	v_onedrive_folder				external_target_profile.onedrive_folder%TYPE;
	v_storage_acc_name				external_target_profile.storage_acc_name%TYPE;
	v_storage_acc_container			external_target_profile.storage_acc_container%TYPE;
BEGIN

	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can edit external target profiles.');
	END IF;
	
	SELECT label, profile_type_id, sharepoint_site, sharepoint_folder, credential_profile_id, onedrive_folder, storage_acc_name, storage_acc_container
	  INTO v_profile_label, v_profile_type_id, v_sharepoint_site, v_sharepoint_folder, v_credential_profile_id, v_onedrive_folder, v_storage_acc_name, v_storage_acc_container
	  FROM external_target_profile
	 WHERE target_profile_id = in_target_profile_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	UPDATE external_target_profile
	   SET	label = in_profile_label,
			profile_type_id = in_profile_type_id,
			sharepoint_site = in_sharepoint_site,
			sharepoint_folder = in_sharepoint_folder,
			credential_profile_id = in_credential_profile_id,
			onedrive_folder = in_onedrive_folder,
			storage_acc_name = in_storage_acc_name,
			storage_acc_container = in_storage_acc_container
	 WHERE target_profile_id = in_target_profile_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	AuditValue(in_target_profile_id, 'Label', in_profile_label, v_profile_label);
	AuditValue(in_target_profile_id, 'Type', in_profile_type_id, v_profile_type_id);
	AuditValue(in_target_profile_id, 'Library Url', in_sharepoint_site, v_sharepoint_site);
	AuditValue(in_target_profile_id, 'Library Folder', in_sharepoint_folder, v_sharepoint_folder);
	AuditValue(in_target_profile_id, 'Credential Profile', in_credential_profile_id, v_credential_profile_id);
	AuditValue(in_target_profile_id, 'OneDrive Folder', in_onedrive_folder, v_onedrive_folder);
	AuditValue(in_target_profile_id, 'Storage Account Name', in_storage_acc_name, v_storage_acc_name);
	AuditValue(in_target_profile_id, 'Storage Account Container', in_storage_acc_container, v_storage_acc_container);
END;

-- End Target Profiles

-- Target Profile AUDIT LOGGING

PROCEDURE AuditValue(
	in_target_profile_id	IN	NUMBER,
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

	AuditWithMsg(
		in_target_profile_id	=> in_target_profile_id,
		in_msg					=> v_msg
	);

END;

PROCEDURE AuditWithMsg(
	in_target_profile_id	IN	NUMBER,
	in_msg					IN	VARCHAR2
)
AS
BEGIN

	INSERT INTO external_target_profile_log
		(target_profile_id, changed_dtm, changed_by_user_sid, message)
	VALUES
		(in_target_profile_id, SYSDATE, SYS_CONTEXT('SECURITY', 'SID'), in_msg);

END;

-- END Target Profile AUDIT LOGGING

-- Target Profile Types
PROCEDURE GetTargetProfileTypes (
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can run this procedure.');
	END IF;

	OPEN out_cur FOR
		SELECT profile_type_id, label profile_type_label
		  FROM external_target_profile_type;
END;
-- End Target Profile Types

END;

/