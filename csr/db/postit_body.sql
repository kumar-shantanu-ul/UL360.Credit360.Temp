CREATE OR REPLACE PACKAGE BODY CSR.postit_Pkg
IS

/**
 * Checks to see if a user can access a postit issue 
 *
 * @param	in_postit_id 	The postit ID
 */
FUNCTION IsReadAccessAllowed(
	in_postit_id			IN	postit.postit_id%TYPE
) RETURN BOOLEAN
AS
	v_sid				security_pkg.T_SID_ID;
	v_audit_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT p.secured_via_sid, ia.internal_audit_sid
	  INTO v_sid, v_audit_sid
	  FROM postit p
	  LEFT JOIN internal_audit ia ON p.secured_via_sid = ia.internal_audit_sid
	 WHERE p.postit_id = in_postit_id;
	
	IF v_audit_sid IS NOT NULL THEN
		RETURN audit_pkg.GetPermissionOnAudit(v_sid) >= security_pkg.PERMISSION_READ;
	END IF;
	
	IF delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, v_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
        RETURN TRUE;
    END IF;
	
	RETURN security_pkg.IsAccessAllowedSID(security_pkg.getACT, v_sid, security_pkg.PERMISSION_READ);
END;


FUNCTION IsWriteAccessAllowed(
	in_postit_id			IN	postit.postit_id%TYPE
) RETURN BOOLEAN
AS
	v_created_by_sid	security_pkg.T_SID_ID;
	v_secured_via_sid	security_pkg.T_SID_ID;
	v_delegation_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT p.created_by_sid, p.secured_via_sid, d.delegation_sid
	  INTO v_created_by_sid, v_secured_via_sid, v_delegation_sid
	  FROM postit p
	  LEFT JOIN delegation d ON p.secured_via_sid = d.delegation_sid
	 WHERE postit_id = in_postit_id;
	
	IF v_delegation_sid IS NOT NULL AND delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, v_delegation_sid, delegation_pkg.DELEG_PERMISSION_WRITE) THEN
        RETURN TRUE;
    END IF;
	
	-- for most postits you can only fiddle if you're the owner (or maybe add some capability based thing?)
	IF v_created_by_sid = security_pkg.getSid THEN
		RETURN TRUE;
	-- If they were created by the builtin admin (e.g. imported lease postits) then we check the secured object.
	ELSIF v_created_by_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR THEN
		RETURN security_pkg.IsAccessAllowedSID(security_pkg.getACT, v_secured_via_sid, security_pkg.PERMISSION_WRITE);
	ELSE
		RETURN FALSE;
	END IF;
END;


PROCEDURE GetFile(
	in_postit_file_id	IN	postit_file.postit_file_id%TYPE,
	in_sha1				IN	VARCHAR2,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_postit_id	postit.postit_id%TYPE;
BEGIN
	SELECT postit_id 
	  INTO v_postit_id
	  FROM postit_file
	 WHERE postit_file_Id = in_postit_file_Id
	   AND sha1 = in_sha1;
	
	IF NOT IsReadAccessAllowed(v_postit_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied download the postit file '||in_postit_file_id);
	END IF;
	
	OPEN out_cur FOR
		SELECT filename, mime_type, data, cast(sha1 as varchar2(40)) sha1, uploaded_dtm
		  FROM postit_file
		 WHERE postit_file_id = in_postit_file_id;
END;

PROCEDURE GetDetails(
	in_postit_id		IN	postit.postit_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_files		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT postit_pkg.IsReadAccessAllowed(in_postit_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied reading the postit with id '||in_postit_id);
	END IF;
	
    OPEN out_cur FOR
		SELECT p.postit_id, p.message, p.label, p.created_dtm, p.created_by_sid, p.secured_via_sid,
			p.created_by_user_name, p.created_by_full_name, p.created_by_email, p.can_edit
		  FROM v$postit p
		 WHERE p.postit_id = in_postit_id
		 ORDER BY created_dtm;

	OPEN out_cur_files FOR
		SELECT pf.postit_file_Id, pf.postit_id, pf.filename, pf.mime_type, cast(pf.sha1 as varchar2(40)) sha1, pf.uploaded_dtm
		  FROM postit p
		  JOIN postit_file pf ON p.postit_id = pf.postit_id AND p.app_sid = pf.app_sid
		 WHERE p.postit_id = in_postit_id;

END;

PROCEDURE FixUpFiles(
	in_postit_id		IN	postit.postit_id%TYPE,
	in_keeper_ids		IN	security_pkg.T_SID_IDS,
	in_cache_keys		IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_keeper_id_tbl		security.T_SID_TABLE;
	v_cache_key_tbl		security.T_VARCHAR2_TABLE;
BEGIN
	IF NOT postit_pkg.IsWriteAccessAllowed(in_postit_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied altering the postit '||in_postit_id);
	END IF;
	
	-- crap hack for ODP.NET
    IF in_keeper_ids IS NULL OR (in_keeper_ids.COUNT = 1 AND in_keeper_ids(1) IS NULL) THEN
		DELETE FROM postit_file
		  WHERE postit_id = in_postit_id;
    ELSE
		v_keeper_id_tbl := security_pkg.SidArrayToTable(in_keeper_ids);
		DELETE FROM postit_file
		  WHERE postit_id = in_postit_id
			AND postit_file_Id NOT IN (
				SELECT column_value FROM TABLE(v_keeper_id_tbl)
			);
    END IF;	 

	-- crap hack for ODP.NET
    IF in_cache_keys IS NULL OR (in_cache_keys.COUNT = 1 AND in_cache_keys(1) IS NULL) THEN
		-- do nothing
        NULL;
    ELSE
		v_cache_key_tbl := security_pkg.Varchar2ArrayToTable(in_cache_keys);
		INSERT INTO postit_file 
			(postit_file_id, postit_id, filename, mime_type, data, sha1) 
			SELECT postit_file_Id_seq.nextval, in_postit_id, filename, mime_type, object, 
				   dbms_crypto.hash(object, dbms_crypto.hash_sh1)
			  FROM aspen2.filecache 
			 WHERE cache_key IN (
				SELECT value FROM TABLE(v_cache_key_tbl)     
			 );
	END IF;
	
	-- return a nice clean list
	OPEN out_cur FOR
		SELECT pf.postit_file_Id, pf.postit_id, pf.filename, pf.mime_type, cast(pf.sha1 as varchar2(40)) sha1, pf.uploaded_dtm
		  FROM postit_file pf
		 WHERE postit_id = in_postit_id;
END;

PROCEDURE DeletePostitOrRemoveFromAudit(
	in_postit_id			IN	postit.postit_id%TYPE,
	in_internal_audit_sid	IN	security_pkg.T_SID_ID
)
AS
v_numberOfRelatedInternalAudit	NUMBER;
BEGIN
	IF NOT postit_pkg.IsWriteAccessAllowed(in_postit_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied altering the postit '||in_postit_id);
	END IF;
	
	SELECT COUNT(iap.postit_id)
	  INTO v_numberOfRelatedInternalAudit
	  FROM internal_audit_postit iap
	 WHERE iap.postit_id = in_postit_id;
	   

	IF v_numberOfRelatedInternalAudit > 1	THEN
		-- Only delete the record from the connection table
		DELETE FROM internal_audit_postit iap
		 WHERE iap.postit_id = in_postit_id
	       AND iap.internal_audit_sid = in_internal_audit_sid;
		
	ELSE
		-- No other audit uses this postit -> delete postit fully
		postit_pkg.Delete(in_postit_id);
		
	END IF;
END;

PROCEDURE Delete(
	in_postit_id		IN	postit.postit_id%TYPE
)
AS
BEGIN
	IF NOT postit_pkg.IsWriteAccessAllowed(in_postit_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied altering the postit '||in_postit_id);
	END IF;
	
	-- cascade delete cleans up files, and also linked tables (e.g. delegation_comment)
	DELETE FROM POSTIT 
	 WHERE postit_id = in_postit_id;
END;

PROCEDURE UNSEC_Save(
	in_postit_id		IN	postit.postit_id%TYPE,
	in_label			IN	postit.label%TYPE,
	in_message			IN	postit.message%TYPE,
	in_secured_via_sid	IN	security_pkg.T_SID_ID,
	out_postit_id		OUT	postit.postit_id%TYPE
)
AS
BEGIN
	-- XXX: uses crappy short-cut clob setting. Notes > 32k will be dull to read anyway
	
	IF in_postit_id IS NULL THEN		
		INSERT INTO postit
			(postit_id, label, message, secured_via_sid, created_by_sid)
		VALUES
			(postit_id_seq.nextval, in_label, in_message, in_secured_via_sid, security_pkg.getSid)
		RETURNING postit_id INTO out_postit_id;
	ELSE
		UPDATE postit
		   SET label = in_label,
			message = in_message,
			secured_via_sid = NVL(in_secured_via_sid, secured_via_sid) -- don't change if null
		 WHERE postit_id = in_postit_id;
		-- return the same as what we got sent
		out_postit_id := in_postit_id;
	END IF;
END;

-- XXX: note on "secured_via_sid". We could have done each postit as a secobj but worried 
-- about it polluting sec obj trees (e.g. if we stuck it in doc lib then the whole doclib
-- tree code will need altering etc). It can always be fixed up later if this turns out 
-- to be a really bad idea. (i.e create sec objs under secured_via_sid, and alter the SP
-- code).
-- It's a really bad idea to have random sids that don't relate to real tables -- you
-- should know by now that if you don't have an RI constraint on a column then you end
-- up with duff data in there.  You want at minimum an RI constraint to SO (probably a bad
-- idea), one column per type of object and a constraint (cf issues) or a join table.
PROCEDURE Save(
	in_postit_id		IN	postit.postit_id%TYPE,
	in_label			IN	postit.label%TYPE,
	in_message			IN	postit.message%TYPE,
	in_secured_via_sid	IN	security_pkg.T_SID_ID,
	out_postit_id		OUT	postit.postit_id%TYPE
)
AS
BEGIN
	-- XXX: uses crappy short-cut clob setting. Notes > 32k will be dull to read anyway
	
	IF in_postit_id IS NULL THEN		
		-- check permissions on secured_via_sid
		-- AUDIT role security stuff
		IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_secured_via_sid, security_pkg.PERMISSION_READ) THEN 
			IF audit_pkg.GetPermissionOnAudit(in_secured_via_sid) <= security_pkg.PERMISSION_READ THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
				'Permission denied reading the object '||in_secured_via_sid||' securing a postit');
			END IF;
		END IF;
	ELSE
		IF NOT postit_pkg.IsWriteAccessAllowed(in_postit_id) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
				'Permission denied altering the postit '||in_postit_id);
		END IF;
	END IF;
	
	UNSEC_Save(in_postit_id, in_label, in_message, in_secured_via_sid, out_postit_id);
END;
	
END postit_Pkg;
/
