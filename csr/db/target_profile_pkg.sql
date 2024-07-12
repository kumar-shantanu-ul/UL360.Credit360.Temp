CREATE OR REPLACE PACKAGE csr.target_profile_pkg AS

-- Target Profiles
PROCEDURE GetTargetProfiles (
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE DeleteTargetProfile(
	in_target_profile_id			IN  external_target_profile.target_profile_id%TYPE
);

PROCEDURE CreateTargetProfile(
	in_profile_label				IN	external_target_profile.label%TYPE,
	in_profile_type_id				IN  external_target_profile.profile_type_id%TYPE,
	in_sharepoint_site				IN  external_target_profile.sharepoint_site%TYPE,
	in_sharepoint_folder			IN  external_target_profile.sharepoint_folder%TYPE,
	in_credential_profile_id		IN  external_target_profile.credential_profile_id%TYPE,
	in_onedrive_folder				IN  external_target_profile.onedrive_folder%TYPE,
	in_storage_acc_name				IN  external_target_profile.storage_acc_name%TYPE,
	in_storage_acc_container		IN  external_target_profile.storage_acc_container%TYPE
);

PROCEDURE EditTargetProfile(
	in_target_profile_id			IN  external_target_profile.target_profile_id%TYPE,
	in_profile_label				IN	external_target_profile.label%TYPE,
	in_profile_type_id				IN  external_target_profile.profile_type_id%TYPE,
	in_sharepoint_site				IN  external_target_profile.sharepoint_site%TYPE,
	in_sharepoint_folder			IN  external_target_profile.sharepoint_folder%TYPE,
	in_credential_profile_id		IN  external_target_profile.credential_profile_id%TYPE,
	in_onedrive_folder				IN  external_target_profile.onedrive_folder%TYPE,
	in_storage_acc_name				IN  external_target_profile.storage_acc_name%TYPE,
	in_storage_acc_container		IN  external_target_profile.storage_acc_container%TYPE
);
-- End Target Profiles

-- Target Profile Types
PROCEDURE GetTargetProfileTypes (
	out_cur							OUT SYS_REFCURSOR
);
-- End Target Profile Types
END;
/
