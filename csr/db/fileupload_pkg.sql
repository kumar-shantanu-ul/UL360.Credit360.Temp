CREATE OR REPLACE PACKAGE CSR.Fileupload_Pkg AS

-- Securable object callbacks
/**
 * CreateObject
 * 
 * @param in_act_id				Access token
 * @param in_sid_id				The sid of the object
 * @param in_class_id			The class Id of the object
 * @param in_name				The name
 * @param in_parent_sid_id		The sid of the parent object
 */
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

/**
 * RenameObject
 * 
 * @param in_act_id			Access token
 * @param in_sid_id			The sid of the object
 * @param in_new_name		The name
 */
PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

/**
 * DeleteObject
 * 
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 */
PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

/**
 * MoveObject
 * 
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 * @param in_new_parent_sid_id		.
 */
PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
); 
	  
/**
 * CreateFileUpload
 * 
 * @param in_act_id					Access token
 * @param in_filename				.
 * @param in_mime_type				.
 * @param in_parent_sid				The sid of the parent object
 * @param in_data					.
 * @param out_file_upload_sid		.
 */
PROCEDURE CreateFileUpload(		  
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_filename			IN 	FILE_UPLOAD.filename%TYPE,
	in_mime_type		IN	FILE_UPLOAD.MIME_TYPE%TYPE,
	in_parent_sid		IN	security_pkg.T_SID_ID,
	in_data				IN	FILE_UPLOAD.data%TYPE,		  	
	out_file_upload_sid	OUT	security_pkg.T_SID_ID
);

/**
 * CreateFileUploadFromCache
 * 
 * @param in_act_id					Access token
 * @param in_parent_sid				The sid of the parent object
 * @param in_cache_key				.
 * @param out_file_upload_sid		.
 */
PROCEDURE CreateFileUploadFromCache(		  
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_parent_sid		IN	security_pkg.T_SID_ID,
    in_cache_key		IN	aspen2.filecache.cache_key%type,
	out_file_upload_sid	OUT	security_pkg.T_SID_ID
);

/**
 * UpdateFileUploadFromCache
 * 
 * @param in_act_id					Access token
 * @param in_file_upload_sid		The sid of the object
 * @param in_cache_key				.
 */
PROCEDURE UpdateFileUploadFromCache(		  
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_file_upload_sid	IN	security_pkg.T_SID_ID,
    in_cache_key		IN	aspen2.filecache.cache_key%type
);
 					
/**
 * getFileUpload
 * 
 * @param in_act_id				Access token
 * @param in_file_upload_sid	.
 * @param out_cur				The rowset
 */
PROCEDURE getFileUpload(
	in_act_id			IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_file_upload_sid	IN	security_pkg.T_SID_ID,			
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);	  

/**
 * GetDelegationFileUpload
 * 
 * @param in_act_id				Access token
 * @param in_file_upload_sid	.
 * @param out_cur				The rowset
 */
PROCEDURE GetDelegationFileUpload(
	in_act_id			IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_file_upload_sid	IN	security_pkg.T_SID_ID,			
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);	

/**
 * getFileUploadWithoutData
 * 
 * @param in_act_id				Access token
 * @param in_file_upload_sid	.
 * @param out_cur				The rowset
 */
PROCEDURE getFileUploadWithoutData(
	in_act_id			IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_file_upload_sid	IN	security_pkg.T_SID_ID,			
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFileUploads(
	in_act_id				IN	security.security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_file_upload_sids		IN	security.security_pkg.T_SID_IDS,			
	out_cur					OUT security.security_pkg.T_OUTPUT_CUR
);

END Fileupload_Pkg;
/
