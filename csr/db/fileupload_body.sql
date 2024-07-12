CREATE OR REPLACE PACKAGE BODY CSR.Fileupload_Pkg AS
-- Securable object callbacks

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;


PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
) AS
BEGIN
	UPDATE file_upload 
	   SET filename = in_new_name 
	 WHERE file_upload_sid = in_sid_id;
END;


PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS 
BEGIN
	DELETE FROM val_file
	 WHERE file_upload_sid = in_sid_id;
	
	DELETE FROM sheet_value_file_hidden_cache
	 WHERE file_upload_sid = in_sid_id;
	
	DELETE FROM sheet_value_file
	 WHERE file_upload_sid = in_sid_id;

	DELETE FROM sheet_value_change_file
	 WHERE file_upload_sid = in_sid_id;

	Imp_Pkg.deleteFileData(in_act_id, in_sid_id);

	DELETE FROM file_upload 
	 WHERE file_upload_sid= in_sid_id;
END;


PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS
BEGIN
	UPDATE file_upload
	   SET parent_sid = in_new_parent_sid_id
	 WHERE file_upload_sid = in_sid_id; 
END;	


PROCEDURE CreateFileUpload(		  
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_filename			IN 	file_upload.filename%TYPE,
	in_mime_type		IN	file_upload.mime_type%type,
	in_parent_sid		IN	security_pkg.T_SID_ID,
	in_data				IN	file_upload.data%TYPE,
	out_file_upload_sid	OUT	security_pkg.T_SID_ID
) AS
BEGIN
	SecurableObject_pkg.CreateSO(in_act_id, in_parent_sid, class_pkg.GetClassID('CSRFileUpload'),
		in_filename, out_file_upload_sid);			  
		
	INSERT INTO file_upload
		(file_upload_sid, parent_sid, filename, mime_type, data, sha1)
	VALUES
		(out_file_upload_sid, in_parent_sid, in_filename, in_mime_type, in_data, 
		 dbms_crypto.hash(in_data, dbms_crypto.hash_sh1)); 
END;	


PROCEDURE CreateFileUploadFromCache(		  
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_parent_sid		IN	security_pkg.T_SID_ID,
    in_cache_key		IN	aspen2.filecache.cache_key%type,
	out_file_upload_sid	OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	SecurableObject_pkg.CreateSO(in_act_id, in_parent_sid, class_pkg.GetClassID('CSRFileUpload'),
		null, out_file_upload_sid);			  
		
	INSERT INTO file_upload
		(file_upload_sid, parent_sid, filename, mime_type, data, sha1) 
    	SELECT out_file_upload_sid, in_parent_sid, filename, mime_type, object, 
    		   dbms_crypto.hash(object, dbms_crypto.hash_sh1)
          FROM aspen2.filecache 
         WHERE cache_key = in_cache_key;
    
    IF SQL%ROWCOUNT = 0 THEN
    	-- pah! not found
        RAISE_APPLICATION_ERROR(-20001, 'Cache Key "'||in_cache_key||'" not found');
    END IF; 
END;	

PROCEDURE UpdateFileUploadFromCache(		  
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_file_upload_sid	IN	security_pkg.T_SID_ID,
    in_cache_key		IN	aspen2.filecache.cache_key%type
)
AS
	v_parent_sid	NUMBER(10);
	v_parent_class	VARCHAR2(4000);
BEGIN
	SELECT parent_sid, class_name
	  INTO v_parent_sid, v_parent_class
	  FROM file_upload fu
	  LEFT JOIN security.securable_object so ON fu.parent_sid = so.sid_id
	  LEFT JOIN security.securable_object_class soc ON so.class_id = soc.class_id
	 WHERE file_upload_sid = in_file_upload_sid;
	
	-- check permission on file	   	
	IF (NOT security_pkg.IsAccessAllowedSID(in_act_id, in_file_upload_sid, security_pkg.PERMISSION_WRITE) 
		AND 
		(v_parent_class = 'CSRDelegation' AND NOT csr.delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, v_parent_sid, delegation_pkg.DELEG_PERMISSION_WRITE))
	)
	THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to sid '||in_file_upload_sid);
	END IF;
		
	UPDATE file_upload
	   SET (filename, mime_type, data, sha1) = (
			SELECT filename, mime_type, object, dbms_crypto.hash(object, dbms_crypto.hash_sh1)
		      FROM aspen2.filecache 
             WHERE cache_key = in_cache_key
        )
     WHERE file_upload_sid = in_file_upload_sid;    
END;	


PROCEDURE GetFileUpload(
	in_act_id			IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_file_upload_sid	IN	security_pkg.T_SID_ID,			
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_parent_class	VARCHAR2(255);
BEGIN
	SELECT MIN(soc.class_name)
	  INTO v_parent_class
	  FROM file_upload fu
	  LEFT JOIN security.securable_object so ON fu.parent_sid = so.sid_id
	  LEFT JOIN security.securable_object_class soc ON so.class_id = soc.class_id
	 WHERE fu.file_upload_sid = in_file_upload_sid;
	 
	IF v_parent_class = 'CSRDelegation' THEN
		fileupload_pkg.GetDelegationFileUpload(in_act_id, in_file_upload_sid, out_cur);
	ELSE
		-- check permission on file	   	
		IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_file_upload_sid, security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
		END IF;
		
		OPEN out_cur FOR
			SELECT file_upload_sid, parent_sid, filename, mime_type, last_modified_dtm, data 
			  FROM file_upload
			 WHERE file_upload_sid = in_file_upload_sid;
	END IF;
END; 

PROCEDURE GetDelegationFileUpload(
	in_act_id			IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_file_upload_sid	IN	security_pkg.T_SID_ID,			
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_is_access_allowed	NUMBER(10); 
BEGIN
	-- check permission on file	
	-- files may be shared between several delegations as a result of copy forward action	
	v_is_access_allowed := 0;
	FOR r IN (
		SELECT s.delegation_sid 
		  FROM sheet_value_file svf
		  JOIN sheet_value sv ON sv.app_sid = svf.app_sid AND sv.sheet_value_id = svf.sheet_value_id
		  JOIN sheet s ON s.app_sid = sv.app_sid AND s.sheet_id = sv.sheet_id
		 WHERE svf.file_upload_sid = in_file_upload_sid	
	)
    LOOP
		IF delegation_pkg.CheckDelegationPermission(in_act_id, r.delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
			v_is_access_allowed := 1;
			EXIT;
		END IF;	
	END LOOP;
	   	
	IF v_is_access_allowed = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
		SELECT file_upload_sid, parent_sid, filename, mime_type, last_modified_dtm, data 
		  FROM file_upload
		 WHERE file_upload_sid = in_file_upload_sid; 	   			   
END; 


PROCEDURE GetFileUploadWithoutData(
	in_act_id			IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_file_upload_sid	IN	security_pkg.T_SID_ID,			
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check permission on file	   	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_file_upload_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to sid '||in_file_upload_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT file_upload_sid, parent_sid, filename, mime_type, last_modified_dtm
		  FROM file_upload
		 WHERE file_upload_sid = in_file_upload_sid; 	   			   
END;

PROCEDURE GetFileUploads(
	in_act_id				IN	security.security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_file_upload_sids		IN	security.security_pkg.T_SID_IDS,
	out_cur					OUT security.security_pkg.T_OUTPUT_CUR
)
AS
	t_file_uploads_sids			security.T_SID_TABLE;
BEGIN
	t_file_uploads_sids := security.security_pkg.SidArrayToTable(in_file_upload_sids);

	OPEN out_cur FOR
		SELECT file_upload_sid, parent_sid, filename, mime_type, last_modified_dtm, data 
		  FROM file_upload
		 WHERE file_upload_sid IN (
			SELECT column_value
			  FROM TABLE(t_file_uploads_sids)
			 WHERE security.security_pkg.SQL_IsAccessAllowedSID(in_act_id, column_value, security_pkg.PERMISSION_READ) = 1
		);
END;

END;
/
