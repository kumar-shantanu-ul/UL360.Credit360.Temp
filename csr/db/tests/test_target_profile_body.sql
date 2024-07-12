CREATE OR REPLACE PACKAGE BODY csr.test_target_profile_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	security.user_pkg.logonadmin(in_site_name);

	DELETE FROM external_target_profile
	 WHERE label LIKE 'TestTargetProfile%';
END;

PROCEDURE SetUp AS
	v_target_profile_label		VARCHAR2(255) := 'TestTargetProfileLabel';
	v_profile_type_id			NUMBER := 1;
	v_sharepoint_site			VARCHAR2(255) := 'TestTargetProfileSharePointSite';
	v_sharepoint_folder			VARCHAR2(255) := 'TestTargetProfileFolder';
	v_credential_profile_id		NUMBER;
	v_credential_label			VARCHAR2(255) := 'TestCredentialManagementLabel';
	v_onedrive_folder			VARCHAR2(255) := 'TestTargetProfileOneDriveFolder';
	v_app_sid					NUMBER;
BEGIN
	credentials_pkg.AddCredential(
		in_label => v_credential_label,
		in_auth_type_id => 1,
		in_auth_scope_id => 1
	);

	v_app_sid := security.security_pkg.GetApp();
	SELECT credential_Id INTO v_credential_profile_id FROM csr.credential_management WHERE rownum = 1 and app_sid = v_app_sid ;

	target_profile_pkg.CreateTargetProfile(
		in_profile_label			=> v_target_profile_label,
		in_profile_type_id			=> v_profile_type_id,
		in_sharepoint_site			=> v_sharepoint_site,
		in_sharepoint_folder		=> v_sharepoint_folder,
		in_credential_profile_id	=> v_credential_profile_id,
		in_onedrive_folder			=> v_onedrive_folder,
		in_storage_acc_name			=> NULL,
		in_storage_acc_container	=> NULL
	);
END;

PROCEDURE TestGetTargetProfiles AS
	v_target_profile_label		VARCHAR2(255);
	v_assert_label				VARCHAR2(255) := 'TestTargetProfileLabel';
	v_profile_type_id			NUMBER;
	v_sharepoint_site			VARCHAR2(255);
	v_sharepoint_folder			VARCHAR2(255);
	v_credential_profile_id		NUMBER;
	v_target_profile_id			NUMBER;
	v_profile_type_label		VARCHAR2(255);
	v_credential_profile_label	VARCHAR2(255);
	v_onedrive_folder			VARCHAR2(255);
	v_storage_acc_name			VARCHAR2(400);
	v_storage_acc_container		VARCHAR2(400);
	v_out_cur					SYS_REFCURSOR;
	v_count						NUMBER:= 0;
BEGIN
	target_profile_pkg.GetTargetProfiles(
		out_cur		 => v_out_cur
	);

  	LOOP
    	FETCH 	v_out_cur INTO
				v_target_profile_id, v_target_profile_label, v_profile_type_id, v_profile_type_label, 
				v_sharepoint_site, v_sharepoint_folder, v_credential_profile_id, v_credential_profile_label,
				v_onedrive_folder, v_storage_acc_name, v_storage_acc_container;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count +1;
  	END LOOP;
	unit_test_pkg.AssertAreEqual(v_target_profile_label, v_assert_label, 'Should match the label');
	unit_test_pkg.AssertIsTrue(v_count >=1, 'Number of saved profile should be more than one');
END;

PROCEDURE TestDeleteTargetProfile AS
	v_target_profile_label		VARCHAR2(255) := 'TestTargetProfileLabel';
	v_target_profile_id			NUMBER;
	v_count						NUMBER:= 0;
BEGIN
	SELECT Target_profile_id INTO v_target_profile_id FROM CSR.external_target_profile WHERE label = v_target_profile_label ;

	target_profile_pkg.DeleteTargetProfile (
		in_target_profile_id 	=> v_target_profile_id
	);
	 SELECT count(*) INTO v_count FROM external_target_profile
	  WHERE target_profile_id = v_target_profile_id;
	unit_test_pkg.AssertAreEqual(0, v_count, 'Deleted record should not be found');
END;

PROCEDURE TestEditTargetProfile AS
	v_target_profile_id			NUMBER;
	v_target_profile_label		VARCHAR2(255) := 'TestTargetProfileLabel';
	v_updated_label				VARCHAR2(255) := 'TestTargetProfile_Updated_Label';
	v_result_label				VARCHAR2(255);
	v_profile_type_id			NUMBER := 1;
	v_sharepoint_site			VARCHAR2(255) := 'TestTargetProfileSharePointSite';
	v_sharepoint_folder			VARCHAR2(255) := 'TestTargetProfileFolder';
	v_credential_profile_id		NUMBER;
	v_onedrive_folder			VARCHAR2(255) := 'TestTargetProfileOneDriveFolder';
	v_app_sid					NUMBER;
BEGIN
	v_app_sid := security.security_pkg.GetApp();
	SELECT credential_Id INTO v_credential_profile_id FROM csr.credential_management WHERE rownum = 1 and app_sid = v_app_sid ;

	SELECT Target_profile_id INTO v_target_profile_id FROM CSR.external_target_profile WHERE label = v_target_profile_label ;

	target_profile_pkg.EditTargetProfile (
		in_target_profile_id		=> v_target_profile_id,
		in_profile_label			=> v_updated_label,
		in_profile_type_id			=> v_profile_type_id,
		in_sharepoint_site			=> v_sharepoint_site,
		in_sharepoint_folder		=> v_sharepoint_folder,
		in_credential_profile_id	=> v_credential_profile_id,
		in_onedrive_folder			=> v_onedrive_folder,
		in_storage_acc_name			=> NULL,
		in_storage_acc_container	=> NULL
	);
	SELECT label INTO v_result_label FROM external_target_profile
	 WHERE target_profile_id = v_target_profile_id;
	unit_test_pkg.AssertAreEqual(v_updated_label, v_result_label, 'Updated Label should match');
END;

PROCEDURE TestGetTargetProfileTypes AS
	v_profile_type_id			NUMBER;
	v_profile_Type_label		VARCHAR2(255);
	v_count						NUMBER:= 0;
	v_out_cur					SYS_REFCURSOR;
BEGIN
	target_profile_pkg.GetTargetProfileTypes(
		out_cur 		 => v_out_cur
	);

  	LOOP
    	FETCH v_out_cur INTO v_profile_type_id, v_profile_Type_label;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count +1;
  	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count >= 1, 'There should be atleast one Target Profile Type');
END;

PROCEDURE TearDown
AS
BEGIN
	DELETE FROM external_target_profile_log;

	DELETE FROM external_target_profile
	 WHERE label LIKE 'TestTargetProfile%';

	DELETE FROM credential_management
	 WHERE label LIKE 'TestCredentialManagement%';
END;

END test_target_profile_pkg;
/