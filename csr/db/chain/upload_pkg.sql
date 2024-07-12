CREATE OR REPLACE PACKAGE chain.upload_pkg
IS

PROCEDURE CreateObject(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_sid_id					IN  security_pkg.T_SID_ID,
	in_class_id					IN  security_pkg.T_CLASS_ID,
	in_name						IN  security_pkg.T_SO_NAME,
	in_parent_sid_id			IN  security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_sid_id					IN  security_pkg.T_SID_ID,
	in_new_name					IN  security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_sid_id					IN  security_pkg.T_SID_ID
); 

PROCEDURE MoveObject(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_sid_id					IN  security_pkg.T_SID_ID,
	in_new_parent_sid_id		IN  security_pkg.T_SID_ID,
	in_old_parent_sid_id		IN security_pkg.T_SID_ID
); 

FUNCTION GetCompanySid(
	in_file_sid					IN	security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID;

PROCEDURE CreateFileUploadFromCache(		  
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_parent_sid				IN	security_pkg.T_SID_ID,
	in_cache_key				IN	aspen2.filecache.cache_key%TYPE,
	out_file_sid				OUT	security_pkg.T_SID_ID
);

PROCEDURE CreateFileUploadFromCache(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_parent_sid				IN	security_pkg.T_SID_ID,
	in_cache_key				IN	aspen2.filecache.cache_key%type,
	in_download_permission_id	IN	file_upload.download_permission_id%type,
	out_file_sid				OUT	security_pkg.T_SID_ID
);

FUNCTION IsChainUpload(
	in_file_sid					IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;


PROCEDURE GetFile(
	in_file_sid					IN	security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE DownloadFile (
	in_file_sid					IN	security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE DownloadFiles (
	in_file_sids					IN	security_pkg.T_SID_IDS,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetParentLang(
	in_lang						IN	aspen2.lang.lang%TYPE
)
RETURN aspen2.lang.lang%TYPE;

PROCEDURE GetParentLang(
	in_lang						IN	aspen2.lang.lang%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE DownloadGroupFile (
	in_group_id					IN  file_group.file_group_id%TYPE,
	in_lang						IN	file_upload.lang%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
) ;

FUNCTION SecureFile (
	in_cache_key				IN	aspen2.filecache.cache_key%TYPE
) RETURN security_pkg.T_SID_ID;

FUNCTION SecureFile (
	in_cache_key				IN	aspen2.filecache.cache_key%TYPE, 
	in_download_permission_id	IN  file_upload.download_permission_id%TYPE
) RETURN security_pkg.T_SID_ID;

PROCEDURE SecureFile (
	in_cache_key				IN	aspen2.filecache.cache_key%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SecureFile (
	in_cache_key				IN	aspen2.filecache.cache_key%TYPE,
	in_download_permission_id	IN  file_upload.download_permission_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteFile (
	in_file_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE RegisterGroup (
	in_guid						IN  file_group.guid%TYPE,
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_title					IN  file_group.title%TYPE,
	in_description				IN  file_group.description%TYPE,
	in_group_model				IN  chain_pkg.T_FILE_GROUP_MODEL,
	in_download_permission 		IN  chain_pkg.T_DOWNLOAD_PERMISSION
);
	
PROCEDURE SecureGroupFile (
	in_group_id					IN  file_group.file_group_id%TYPE,
	in_cache_key				IN	aspen2.filecache.cache_key%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetDefaultGroupFile (
	in_group_id					IN	file_group.file_group_id%TYPE,
	in_file_upload_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE SetGroupPermission (
	in_group_id					IN  file_group.file_group_id%TYPE,
	in_permission				IN  chain_pkg.T_DOWNLOAD_PERMISSION
);

PROCEDURE SetFilePermission (
	in_file_sid					IN  security_pkg.T_SID_ID,
	in_permission				IN  chain_pkg.T_DOWNLOAD_PERMISSION
);

PROCEDURE SetFileLang (
	in_file_sid					IN  security_pkg.T_SID_ID,
	in_lang						IN  file_upload.lang%TYPE
);

PROCEDURE GetGroups (
	out_groups_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_group_files_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_files_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetGroupsForLang (
	out_groups_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_group_files_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_files_cur				OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetGroupId (
	in_guid						IN  file_group.guid%TYPE
) RETURN file_group.file_group_id%TYPE;

PROCEDURE SetGroupDefaultFile (
	in_group_id					IN	file_group.file_group_id%TYPE,
	in_file_upload_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE GenerateCompanyUploadsData (
	in_company_sid						IN security.security_pkg.T_SID_ID,
	in_get_supplier_uploads			IN NUMBER DEFAULT 0,
	in_cascade								IN NUMBER DEFAULT 0,
	in_get_inactive_deleted			IN NUMBER DEFAULT 0,
	out_file_metadata					OUT security.security_pkg.T_OUTPUT_CUR
);

--TODO: Add a proc for getting a file given a cache key that will take from cache if it hasn't
--      been saved yet or from upload table - this can then be shared between sourcing and wood
--      Will need to add a cache_key column to file_upload
-- edit (casey): you could use Chain.panel.UploadedFiles instead - it does everything that you need to

END upload_pkg;
/
