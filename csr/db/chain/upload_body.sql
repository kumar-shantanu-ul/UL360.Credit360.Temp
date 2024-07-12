CREATE OR REPLACE PACKAGE BODY chain.upload_pkg
IS

PROCEDURE GetFiles (
	in_file_sids				IN	security.T_SID_TABLE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT file_upload_sid, filename, mime_type, last_modified_dtm, NULL description, lang, download_permission_id,
			   NULL charset, last_modified_dtm creation_dtm, last_modified_dtm last_accessed_dtm, length(data) bytes
		  FROM chain.file_upload
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND file_upload_sid IN (SELECT column_value FROM TABLE(in_file_sids));
END;

FUNCTION GetGroupCompanySid(
	in_file_group_id			IN	security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
AS
	v_company_sid				security_pkg.T_SID_ID;
BEGIN
	SELECT MIN(company_sid)
	  INTO v_company_sid
	  FROM file_group
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND file_group_id = in_file_group_id;

	RETURN v_company_sid;
END;


PROCEDURE CreateObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_class_id					IN security_pkg.T_CLASS_ID,
	in_name						IN security_pkg.T_SO_NAME,
	in_parent_sid_id			IN security_pkg.T_SID_ID
)
AS
BEGIN
	-- Only require ACLs to lock down this method we don't have a row in file_upload
	-- Capability checks must be performed before any insert to file_upload (or call to createSO)
	NULL;
END;


PROCEDURE RenameObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_name					IN security_pkg.T_SO_NAME
) AS	
	v_company_sid				security_pkg.T_SID_ID DEFAULT GetCompanySid(in_sid_id);
BEGIN
	IF in_new_name IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting a name');
	END IF;
END;


PROCEDURE DeleteObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID
) AS 
BEGIN
	IF NOT capability_pkg.CheckCapability(GetCompanySid(in_sid_id), chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to (deleting) upload files for company with sid '||GetCompanySid(in_sid_id));
	END IF;
	
	DELETE FROM component_document  
	 WHERE file_upload_sid = in_sid_id;
	
	DELETE FROM file_group_file
	 WHERE file_upload_sid = in_sid_id;

	-- Allow clients to delete references to this object
	chain_link_pkg.DeleteUpload(in_sid_id);

	DELETE FROM worksheet_file_upload
	 WHERE file_upload_sid = in_sid_id;

	DELETE FROM file_upload 
	 WHERE file_upload_sid = in_sid_id;
END;


PROCEDURE MoveObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_parent_sid_id		IN security_pkg.T_SID_ID,
	in_old_parent_sid_id		IN security_pkg.T_SID_ID
) AS
	v_company_sid				security_pkg.T_SID_ID DEFAULT GetCompanySid(in_sid_id);
BEGIN
	-- don't allow move
	RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied moving object');
END;

FUNCTION GetCompanySid(
	in_file_sid					IN	security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
AS
	v_company_sid				security_pkg.T_SID_ID;
BEGIN
	SELECT MIN(company_sid)
	  INTO v_company_sid
	  FROM file_upload
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND file_upload_sid = in_file_sid;

	RETURN v_company_sid;
END;

PROCEDURE CreateFileUploadFromCache(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_parent_sid				IN	security_pkg.T_SID_ID,
	in_cache_key				IN	aspen2.filecache.cache_key%type,
	out_file_sid				OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	CreateFileUploadFromCache(in_act_id, in_parent_sid, in_cache_key, chain_pkg.DOWNLOAD_PERM_STANDARD, out_file_sid);
END;


PROCEDURE CreateFileUploadFromCache(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_parent_sid				IN	security_pkg.T_SID_ID,
	in_cache_key				IN	aspen2.filecache.cache_key%type,
	in_download_permission_id	IN	file_upload.download_permission_id%type,
	out_file_sid				OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to uploaded files');
	END IF;

	SecurableObject_pkg.CreateSO(in_act_id, in_parent_sid, class_pkg.GetClassID('ChainFileUpload'), NULL, out_file_sid);

	INSERT INTO file_upload
	(file_upload_sid, filename, mime_type, data, sha1, download_permission_id, last_modified_by_sid) 
	SELECT out_file_sid, filename, mime_type, object, 
		   dbms_crypto.hash(object, dbms_crypto.hash_sh1), in_download_permission_id,
		   security.security_pkg.getSID
	  FROM aspen2.filecache 
	 WHERE cache_key = in_cache_key;

	IF SQL%ROWCOUNT = 0 THEN
		-- pah! not found
		RAISE_APPLICATION_ERROR(-20001, 'Cache Key "'||in_cache_key||'" not found');
	END IF; 
END;

FUNCTION IsChainUpload(
	in_file_sid			IN security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_exists	number(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_exists
	  FROM file_upload
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND file_upload_sid = in_file_sid;
	
	RETURN v_exists = 1;
END;

FUNCTION CanDownloadFile (
	in_file_sid					IN	security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_permision					chain_pkg.T_DOWNLOAD_PERMISSION;
	v_company_sid				security_pkg.T_SID_ID;
	v_allow_access				BOOLEAN DEFAULT FALSE;
	v_key								supplier_relationship.virtually_active_key%TYPE;
BEGIN
	
	BEGIN
		SELECT download_permission_id, company_sid
		  INTO v_permision, v_company_sid
		  FROM file_upload
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND file_upload_sid = in_file_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN		
			RETURN FALSE;	
	END;
	
	CASE
		WHEN v_permision = chain_pkg.DOWNLOAD_PERM_STANDARD THEN
			v_allow_access := capability_pkg.CheckCapability(v_company_sid, chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_READ);		
		WHEN v_permision = chain_pkg.DOWNLOAD_PERM_EVERYONE THEN		
			v_allow_access := TRUE;		
			
		WHEN v_permision = chain_pkg.DOWNLOAD_PERM_SUPPLIERS THEN			

			IF SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') IS NOT NULL THEN			
				IF v_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
					v_allow_access := TRUE;
				ELSE
					company_pkg.ActivateVirtualRelationship(v_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), v_key);					
					v_allow_access := company_pkg.IsSupplier(v_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));					
					company_pkg.DeactivateVirtualRelationship(v_key);
				END IF;			
			END IF;	
				

		WHEN ((v_permision = chain_pkg.DOWNLOAD_PERM_STND_TRANS) OR (v_permision = chain_pkg.DOWNLOAD_PERM_PRTCTD_TRANS)) THEN
			-- whether user can download this file is based on the transparency settings for the application and
			-- 		if it belongs to their company
			-- 		if "transparency" is turned on for the site and this gives the logged on company the permission to see the owner company  
			--		normal capabilities don't give you permissions here for DOWNLOAD_PERM_PRTCTD_TRANS but do for DOWNLOAD_PERM_STND_TRANS

			IF SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') IS NOT NULL THEN	
				
				-- can always look at your own files
				IF v_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
					v_allow_access := TRUE;
				END IF;
				
				-- normal capabilities don't give you permissions here for DOWNLOAD_PERM_PRTCTD_TRANS but do for DOWNLOAD_PERM_STND_TRANS
				IF v_permision = chain_pkg.DOWNLOAD_PERM_STND_TRANS THEN 
					v_allow_access := capability_pkg.CheckCapability(v_company_sid, chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_READ);	
				END IF;
				
				-- Can look at this file if transparency is on and you can see the 
				IF company_pkg.CanSeeCompanyAsChainTrnsprnt(v_company_sid) THEN 
					v_allow_access := TRUE;
				END IF;
			
			END IF;				
			
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown permission type '''||v_permision||'''');
	
	END CASE;
	
	IF NOT v_allow_access THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied downloading files from company with sid '||v_company_sid);
	END IF;
	
	RETURN TRUE;
END;

PROCEDURE DownloadFile (
	in_file_sid					IN	security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF CanDownloadFile(in_file_sid) THEN
		OPEN out_cur FOR
			SELECT mime_type, filename, last_modified_dtm, data
			  FROM file_upload
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND file_upload_sid = in_file_sid;
	END IF;
END;

--checks all files to confirm they can be downloaded, then returns the file data cursor
PROCEDURE DownloadFiles (
	in_file_sids					IN	security_pkg.T_SID_IDS,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_file_sid_table			security.T_SID_TABLE;
BEGIN

	FOR i IN 1..in_file_sids.COUNT LOOP
		IF NOT CanDownloadFile(in_file_sids(i)) THEN
			RETURN;
		END IF;
	END LOOP;

	v_file_sid_table := security.security_pkg.SidArrayToTable(in_file_sids);
	
		   OPEN out_cur FOR
	   SELECT file_upload_sid, mime_type, filename, last_modified_dtm, data
		  FROM file_upload
			JOIN TABLE(v_file_sid_table) fst
			   ON fst.column_value = file_upload_sid
	   WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
RETURN;
END;

FUNCTION GetParentLang(
	in_lang						IN	aspen2.lang.lang%TYPE
)
RETURN aspen2.lang.lang%TYPE
AS
	v_parent_lang			aspen2.lang.lang%TYPE;
BEGIN
	BEGIN
		SELECT parent.lang
		  INTO v_parent_lang
		  FROM aspen2.lang l
		  JOIN aspen2.lang parent ON l.parent_lang_id = parent.lang_id
		 WHERE l.lang = in_lang;
	EXCEPTION
		WHEN no_data_found THEN v_parent_lang := NULL;
	END;
	
	RETURN v_parent_lang;
END;

PROCEDURE GetParentLang(
	in_lang						IN	aspen2.lang.lang%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT lang_id, lang, description
		  FROM aspen2.lang
		 WHERE lang = GetParentLang(in_lang);
END;

-- Private
PROCEDURE GetFileGroupFileIDsForLang (
	in_group_id					IN	file_group.file_group_id%TYPE,
	in_lang						IN	file_upload.lang%TYPE,
	out_file_group_file_ids		OUT	security.T_SID_TABLE
)
AS
BEGIN

	SELECT NVL(ful_file_group_file_id, NVL(fupl_file_group_file_id, fud_file_group_file_id))
	  BULK COLLECT INTO out_file_group_file_ids
	  FROM (
		SELECT fg.file_group_id,
			   MAX(CASE WHEN ful.file_upload_sid IS NOT NULL THEN fgf.file_group_file_id ELSE NULL END) ful_file_group_file_id,
			   MAX(CASE WHEN fupl.file_upload_sid IS NOT NULL THEN fgf.file_group_file_id ELSE NULL END) fupl_file_group_file_id,
			   MAX(CASE WHEN fud.file_upload_sid IS NOT NULL THEN fgf.file_group_file_id ELSE NULL END) fud_file_group_file_id
		  FROM file_group fg
		  JOIN file_group_file fgf ON fg.app_sid = fgf.app_sid AND fg.file_group_id = fgf.file_group_id
		  LEFT JOIN file_upload ful ON fgf.app_sid = ful.app_sid AND fgf.file_upload_sid = ful.file_upload_sid AND ful.lang = in_lang
		  LEFT JOIN file_upload fupl ON fgf.app_sid = fupl.app_sid AND fgf.file_upload_sid = fupl.file_upload_sid AND fupl.lang = upload_pkg.GetParentLang(in_lang)
		  LEFT JOIN file_upload fud ON fgf.app_sid = fud.app_sid AND fgf.file_upload_sid = fud.file_upload_sid AND fg.default_file_group_file_id = fgf.file_group_file_id
		 WHERE fg.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ((fg.download_permission_id = chain_pkg.DOWNLOAD_PERM_EVERYONE) OR (fg.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')))
		   AND (in_group_id IS NULL OR fg.file_group_id = in_group_id)
		 GROUP BY fg.file_group_id
	  );
	  
END;

PROCEDURE DownloadGroupFile (
	in_group_id					IN  file_group.file_group_id%TYPE,
	in_lang						IN	file_upload.lang%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
) 
AS
	v_file_sid					security_pkg.T_SID_ID;
	v_file_group_file_ids		security.T_SID_TABLE;
	v_model_id					file_group.file_group_model_id%TYPE;
BEGIN
	-- TODO: this is a basic implementation - if the exact file that they need isn't found, they don't get anything
	-- it would be worthwhile to set a default group file or something like that.	
	
	SELECT file_group_model_id
	  INTO v_model_id
	  FROM file_group
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND file_group_id = in_group_id;
	
	CASE
		WHEN v_model_id = chain_pkg.LANGUAGE_GROUP THEN
			-- try to get the file with the language that they want
			BEGIN
				GetFileGroupFileIDsForLang(in_group_id, in_lang, v_file_group_file_ids);
				
				IF v_file_group_file_ids.COUNT = 0  THEN 
					RAISE_APPLICATION_ERROR(-20001, 'No file found for user sid ' || SYS_CONTEXT('SECURITY', 'SID') || ' group id ' || in_group_id || ' and lang ' || SYS_CONTEXT('SECURITY', 'LANGUAGE'));
				END IF;
				
				SELECT file_upload_sid
				  INTO v_file_sid
				  FROM file_group_file
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND file_group_file_id = v_file_group_file_ids(1);
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					RAISE_APPLICATION_ERROR(-20001, 'File not found for group='||in_group_id||' and lang='||NVL(GetParentLang(SYS_CONTEXT('SECURITY', 'LANGUAGE')), 'LANG NOT SET'));
				WHEN TOO_MANY_ROWS THEN
					RAISE_APPLICATION_ERROR(-20001, 'Too many matches found for group='||in_group_id||' and lang='||NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'LANG NOT SET'));
			END;
		
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unhandled file group model type with id '||v_model_id);
	END CASE;
	
	DownloadFile(v_file_sid, out_cur);
END;

PROCEDURE GetFile (
	in_file_sid					IN	security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid				security_pkg.T_SID_ID DEFAULT GetCompanySid(in_file_sid);
	v_file_sids					security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
BEGIN
	-- If we didn't find the file, we don't want an access denied, let it go through and return nothing
	IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading file uploads for company with sid '||v_company_sid);
	END IF;

	v_file_sids.extend(1);
	v_file_sids(1) := in_file_sid;

	GetFiles(v_file_sids, out_cur);
END;

PROCEDURE SecureFile (
	in_cache_key				IN	aspen2.filecache.cache_key%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	SecureFile(in_cache_key, chain_pkg.DOWNLOAD_PERM_STANDARD, out_cur);
END;

PROCEDURE SecureFile (
	in_cache_key				IN	aspen2.filecache.cache_key%TYPE,
	in_download_permission_id	IN  file_upload.download_permission_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_file_sid					security_pkg.T_SID_ID DEFAULT SecureFile(in_cache_key, in_download_permission_id);
BEGIN
	GetFile(v_file_sid, out_cur);
END;

FUNCTION SecureFile (
	in_cache_key				IN	aspen2.filecache.cache_key%TYPE
) RETURN security_pkg.T_SID_ID
AS
BEGIN
	RETURN SecureFile(in_cache_key, chain_pkg.DOWNLOAD_PERM_STANDARD);
END;


FUNCTION SecureFile (
	in_cache_key				IN	aspen2.filecache.cache_key%TYPE, 
	in_download_permission_id	IN  file_upload.download_permission_id%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_file_sid					security_pkg.T_SID_ID;
BEGIN
	CreateFileUploadFromCache(security_pkg.GetAct, securableobject_pkg.GetSidFromPath(security_pkg.GetAct, company_pkg.GetCompany, chain_pkg.COMPANY_UPLOADS), in_cache_key, in_download_permission_id, v_file_sid);
	
	aspen2.filecache_pkg.DeleteEntry(in_cache_key);
	
	RETURN v_file_sid;
END;


PROCEDURE DeleteFile (
	in_file_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	DeleteObject(security_pkg.GetAct, in_file_sid);
END;

PROCEDURE RegisterGroup (
	in_guid						IN  file_group.guid%TYPE,
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_title					IN  file_group.title%TYPE,
	in_description				IN  file_group.description%TYPE,
	in_group_model				IN  chain_pkg.T_FILE_GROUP_MODEL,
	in_download_permission 		IN  chain_pkg.T_DOWNLOAD_PERMISSION
)
AS
BEGIN
	
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'RegisterGroup can only be run as BuiltIn/Administrator');
	END IF;

	BEGIN
		INSERT INTO file_group
		(file_group_id, company_sid, title, description, file_group_model_id, download_permission_id, guid)
		VALUES
		(file_group_id_seq.NEXTVAL, in_company_sid, in_title, in_description, in_group_model, in_download_permission, LOWER(in_guid));
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			
			UPDATE file_group
			   SET company_sid = in_company_sid,
			       title = in_title,
			       description = in_description,
			       file_group_model_id = in_group_model,
			       download_permission_id = in_download_permission
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND guid = LOWER(in_guid);
			   
			-- update download_permission_id on any existing files in the group
			UPDATE file_upload
			   SET download_permission_id = in_download_permission
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND file_upload_sid IN (
			   SELECT file_upload_sid 
				 FROM file_group fg
				 JOIN file_group_file fgf ON fg.app_sid = fgf.app_sid and fg.file_group_id = fgf.file_group_id
				WHERE fg.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				  AND guid = lower(in_guid) 			 
			 );
	END;
END;

PROCEDURE SecureGroupFile (
	in_group_id					IN  file_group.file_group_id%TYPE,
	in_cache_key				IN	aspen2.filecache.cache_key%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_file_sid					security_pkg.T_SID_ID DEFAULT SecureFile(in_cache_key);
	v_company_sid 				security_pkg.T_SID_ID DEFAULT GetGroupCompanySid(in_group_id);
	v_perm						chain_pkg.T_DOWNLOAD_PERMISSION;
BEGIN
	IF v_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Group company mismatch ('||v_company_sid||')');
	END IF;
	
	INSERT INTO file_group_file
	(file_group_id, file_upload_sid, file_group_file_id)
	SELECT in_group_id, v_file_sid, file_group_file_id_seq.NEXTVAL
	  FROM dual;
	
	SELECT download_permission_id
	  INTO v_perm
	  FROM file_group
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND file_group_id = in_group_id;
	
	UPDATE file_upload
	   SET download_permission_id = v_perm
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND file_upload_sid = v_file_sid;
	
	GetFile(v_file_sid, out_cur);
END;

PROCEDURE SetDefaultGroupFile (
	in_group_id					IN	file_group.file_group_id%TYPE,
	in_file_upload_sid			IN	security_pkg.T_SID_ID
)
AS
	v_file_group_file_id		file_group_file.file_group_file_id%TYPE;
BEGIN
	SELECT file_group_file_id
	  INTO v_file_group_file_id
	  FROM file_group_file
	 WHERE app_sid = security_pkg.GetApp
	   AND file_group_id = in_group_id
	   AND file_upload_sid = in_file_upload_sid;
	
	UPDATE file_group
	   SET default_file_group_file_id = v_file_group_file_id
	 WHERE app_sid = security_pkg.GetApp
	   AND file_group_id = in_group_id;
END;

PROCEDURE SetGroupPermission (
	in_group_id					IN  file_group.file_group_id%TYPE,
	in_permission				IN  chain_pkg.T_DOWNLOAD_PERMISSION
)
AS
	v_company_sid 				security_pkg.T_SID_ID DEFAULT GetGroupCompanySid(in_group_id);
BEGIN
	IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to file uploads for company with sid '||v_company_sid);
	END IF;

	UPDATE file_group
	   SET download_permission_id = in_permission
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND file_group_id = in_group_id;

	UPDATE file_upload
	   SET download_permission_id = in_permission
	 WHERE (app_sid, file_upload_sid) IN (
	 			SELECT app_sid, file_upload_sid 
	 			  FROM file_group_file 
	 			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	 			   AND file_group_id = in_group_id
	 		);
END;

PROCEDURE SetFilePermission (
	in_file_sid					IN  security_pkg.T_SID_ID,
	in_permission				IN  chain_pkg.T_DOWNLOAD_PERMISSION
)
AS
	v_company_sid 				security_pkg.T_SID_ID DEFAULT GetCompanySid(in_file_sid);
	v_is_group_file				NUMBER(10);
BEGIN
	IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to file uploads for company with sid '||v_company_sid);
	END IF;
	
	SELECT COUNT(*)
	  INTO v_is_group_file
	  FROM file_group_file
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND file_upload_sid = in_file_sid;
	
	IF v_is_group_file > 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'You cannot change the invidual permissions of group files');
	END IF;
	
	UPDATE file_upload
	   SET download_permission_id = in_permission
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND file_upload_sid = in_file_sid;
END;

PROCEDURE SetFileLang (
	in_file_sid					IN  security_pkg.T_SID_ID,
	in_lang						IN  file_upload.lang%TYPE
)
AS
	v_company_sid 				security_pkg.T_SID_ID DEFAULT GetCompanySid(in_file_sid);
BEGIN
	IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to file uploads for company with sid '||v_company_sid);
	END IF;
	
	UPDATE file_upload
	   SET lang = in_lang
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND file_upload_sid = in_file_sid;
END;

PROCEDURE GetGroups (
	out_groups_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_group_files_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_files_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_file_sids					security.T_SID_TABLE;
	v_can_edit_global_groups	NUMBER := 0;
BEGIN
	--if they want to read groups, they need to be able to write
	IF NOT capability_pkg.CheckCapability(chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to file uploads for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	-- Can logged on user see groups that are global - e.g. aren't tightly bound to a company (this would be documents just linked in pages)
	-- Adding this here rather than using document library as the "knowledge of chain" and the ability to get documents based on language settings is potentially v useful 
	-- and it means a single point of management where groups linked to companies are needed too
	-- NOTE: these "global" groups can only be setup as read permission "EVERYONE" - this is constrained at the DB table level
	IF (csr.csr_data_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'ACT'), chain_pkg.EDIT_GLOBAL_FILE_GROUPS)) THEN 
		v_can_edit_global_groups := 1;
	END IF;
	
	OPEN out_groups_cur FOR
		SELECT file_group_id, title, description, download_permission_id, guid, default_file_group_file_id
		  FROM file_group
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND (((v_can_edit_global_groups = 1) AND (company_sid IS NULL)) OR (company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')))
		 ORDER BY LOWER(title);

	OPEN out_group_files_cur FOR
		SELECT fgf.file_group_id, fgf.file_upload_sid, fgf.file_group_file_id
		  FROM file_group_file fgf, file_group fg
		 WHERE fg.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND fg.app_sid = fgf.app_sid
		   AND (((v_can_edit_global_groups = 1) AND (fg.company_sid IS NULL)) OR (fg.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')))
		   AND fg.file_group_id = fgf.file_group_id;

	SELECT fgf.file_upload_sid
	  BULK COLLECT INTO v_file_sids
	  FROM file_group_file fgf, file_group fg
	 WHERE fg.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND fg.app_sid = fgf.app_sid
	   AND (((v_can_edit_global_groups = 1) AND (fg.company_sid IS NULL)) OR (fg.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')))
	   AND fg.file_group_id = fgf.file_group_id;
	
	GetFiles(v_file_sids, out_files_cur);
END;

PROCEDURE GetGroupsForLang (
	out_groups_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_group_files_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_files_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_file_sids					security.T_SID_TABLE;
	v_file_group_file_ids		security.T_SID_TABLE;
BEGIN
	--if they want to read groups, they need to be able to write
	IF NOT capability_pkg.CheckCapability(chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to file uploads for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	OPEN out_groups_cur FOR
		SELECT file_group_id, title, description, download_permission_id, guid, default_file_group_file_id
		  FROM file_group
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		 ORDER BY LOWER(title);

	GetFileGroupFileIDsForLang(NULL, SYS_CONTEXT('SECURITY', 'LANGUAGE'), v_file_group_file_ids);
	
	OPEN out_group_files_cur FOR
		SELECT fgf.file_group_id, fgf.file_upload_sid, fgf.file_group_file_id
		  FROM file_group_file fgf
		  JOIN TABLE(v_file_group_file_ids) f ON fgf.file_group_file_id = f.column_value
		 WHERE fgf.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	SELECT fgf.file_upload_sid
	  BULK COLLECT INTO v_file_sids
	  FROM file_group_file fgf
	  JOIN TABLE(v_file_group_file_ids) f ON fgf.file_group_file_id = f.column_value
	 WHERE fgf.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	GetFiles(v_file_sids, out_files_cur);
END;

FUNCTION GetGroupId (
	in_guid						IN  file_group.guid%TYPE
) RETURN file_group.file_group_id%TYPE
AS
	v_group_id					file_group.file_group_id%TYPE;
BEGIN
	SELECT file_group_id
	  INTO v_group_id
	  FROM file_group
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND guid = LOWER(in_guid);
	
	RETURN v_group_id;
END;

PROCEDURE SetGroupDefaultFile (
	in_group_id					IN	file_group.file_group_id%TYPE,
	in_file_upload_sid			IN	security_pkg.T_SID_ID
)
AS
	v_file_group_file_id		file_group_file.file_group_file_id%TYPE;
	v_can_edit_global_groups	NUMBER := 0;
BEGIN

	IF NOT capability_pkg.CheckCapability(chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to file uploads for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	-- Can logged on user see groups that are global - e.g. aren't tightly bound to a company (this would be documents just linked in pages)
	-- Adding this here rather than using document library as the "knowledge of chain" and the ability to get documents based on language settings is potentially v useful 
	-- and it means a single point of management where groups linked to companies are needed too
	-- NOTE: these "global" groups can only be setup as read permission "EVERYONE" - this is constrained at the DB table level
	IF (csr.csr_data_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'ACT'), chain_pkg.EDIT_GLOBAL_FILE_GROUPS)) THEN 
		v_can_edit_global_groups := 1;
	END IF;
	
	IF in_file_upload_sid IS NULL THEN
		UPDATE file_group
		   SET default_file_group_file_id = NULL
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND (((v_can_edit_global_groups = 1) AND (company_sid IS NULL)) OR (company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')))
		   AND file_group_id = in_group_id;
	ELSE
		SELECT fgf.file_group_file_id
		  INTO v_file_group_file_id
		  FROM file_group_file fgf
		  JOIN file_group fg ON fgf.app_sid = fg.app_sid AND fgf.file_group_id = fg.file_group_id
		 WHERE fgf.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND (((v_can_edit_global_groups = 1) AND (fg.company_sid IS NULL)) OR (fg.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')))
		   AND fg.file_group_id = in_group_id
		   AND fgf.file_upload_sid = in_file_upload_sid;
		
		UPDATE file_group
		   SET default_file_group_file_id = v_file_group_file_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND (((v_can_edit_global_groups = 1) AND (company_sid IS NULL)) OR (company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')))
		   AND file_group_id = in_group_id;

	END IF;
END;

/******************* GenerateCompanyUploadsData_ ***************************/
/*
Recursively goes through company file data starting at the provided company and stopping based on the set flags.
NOTE: DUE TO RAINFOREST ALLIANCE CURRENTLY ALLOWING CIRCULAR SUPPLY CHAIN SITUATIONS THIS COULD RESULT IN AN INFINITE LOOP
*/
/*************************************************************************************/
PROCEDURE GenerateCompanyUploadsData_ (
	in_company_sid						IN security.security_pkg.T_SID_ID,
	in_get_supplier_uploads			IN NUMBER,
	in_cascade								IN NUMBER,
	in_get_inactive_deleted			IN NUMBER,
	in_root_folder							IN VARCHAR2 DEFAULT NULL,
	in_max_levels							IN NUMBER DEFAULT 10 --how many "supplier levels" should this go down (usefull for avoiding perma loops on, for example, RA ;) 
)
AS
	v_get_supplier_uploads			NUMBER;
	v_success								BOOLEAN;
	v_root										VARCHAR2(255) := NULL;
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_READ) THEN
		RETURN; --skip if we are not allowed to read (only get documents from companies we have access to)
	END IF;	
	
	IF in_root_folder IS NOT NULL THEN
		v_root := in_root_folder || '/';
	END IF;
	v_root := v_root || to_char(in_company_sid);
	
	--add uploads to TT_FILE_UPLOADS temp table for this company
	--if there is a custom link implementation, use that instead
	chain_link_pkg.GenerateCompanyUploadsData(in_company_sid, v_root , v_success); 
	IF NOT v_success THEN
		--default implementation
		INSERT INTO TT_FILE_UPLOAD(file_upload_sid, company_sid, filename, folder, last_modified_dtm, file_size)
		SELECT  file_upload_sid, company_sid, filename,v_root, last_modified_dtm, (dbms_lob.getlength(data) / (1024))  
		   FROM file_upload
		WHERE company_sid = in_company_sid
			  AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF; 

	--check if we need to get supplier uploads too
	IF in_get_supplier_uploads = 1 AND in_max_levels > 0 THEN
	
		IF in_cascade = 1 THEN
			v_get_supplier_uploads := in_get_supplier_uploads;
		ELSE
			v_get_supplier_uploads := 0;
		END IF;
	
		--recursive call for all suppliers
			FOR r IN (
				SELECT *
				FROM supplier_relationship
				WHERE purchaser_company_sid = in_company_sid
				AND (in_get_inactive_deleted = 1 OR (active = chain_pkg.ACTIVE AND deleted = chain_pkg.NOT_DELETED))
				AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
			) LOOP
				GenerateCompanyUploadsData_(r.supplier_company_sid, v_get_supplier_uploads , in_cascade, in_get_inactive_deleted, v_root || '/Suppliers', in_max_levels - 1);
			END LOOP;
		
		END IF;

END;

PROCEDURE GenerateCompanyUploadsData (
	in_company_sid						IN security.security_pkg.T_SID_ID,
	in_get_supplier_uploads			IN NUMBER DEFAULT 0,	--set to 1 to get file uploads for this company and its suppliers
	in_cascade								IN NUMBER DEFAULT 0,  --set to 1 to file uploads for this company and all of the suppliers in its supply chain
	in_get_inactive_deleted			IN NUMBER DEFAULT 0, -- set to 1 to get file uploads from inactive or deleted suppliers also
	out_file_metadata					OUT security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading file uploads for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
		
	GenerateCompanyUploadsData_(in_company_sid, in_get_supplier_uploads, in_cascade, in_get_inactive_deleted);
	
	OPEN out_file_metadata FOR
	SELECT file_upload_sid, company_sid, filename, folder, last_modified_dtm, file_size
		FROM TT_FILE_UPLOAD
		ORDER BY company_sid;
		
END;

END upload_pkg;
/
