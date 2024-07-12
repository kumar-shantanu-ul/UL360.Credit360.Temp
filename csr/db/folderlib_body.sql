CREATE OR REPLACE PACKAGE BODY CSR.FolderLib_Pkg AS

PROCEDURE GetFolderTreeWithDepth(
	in_act_id   	IN  security.security_pkg.T_ACT_ID,
	in_parent_sid	IN	security.security_pkg.T_SID_ID,
	in_fetch_depth	IN	NUMBER,
	in_hide_root	IN  NUMBER DEFAULT 1,
	out_cur			OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
	v_act_id			security.security_pkg.T_ACT_ID := security.security_pkg.GetACT();
BEGIN
	OPEN out_cur FOR
		SELECT sid_id, parent_sid_id, class_id, name, flags, owner, so_level, is_leaf, path, 
			   security.security_pkg.SQL_IsAccessAllowedSID(v_act_id, sid_id, security.security_pkg.PERMISSION_ADD_CONTENTS) can_add,
			   security.security_pkg.SQL_IsAccessAllowedSID(v_act_id, sid_id, security.security_pkg.PERMISSION_WRITE) can_write,
			   security.security_pkg.SQL_IsAccessAllowedSID(v_act_id, sid_id, security.security_pkg.PERMISSION_DELETE) can_delete
	FROM TABLE ( security.SecurableObject_pkg.GetTreeWithPermAsTable( in_act_id , in_parent_sid, 
		security.security_pkg.PERMISSION_READ, in_fetch_depth, null, in_hide_root) )
		WHERE class_id IN (security.security_pkg.SO_CONTAINER, security.security_pkg.SO_WEB_RESOURCE);
END;

PROCEDURE INTERNAL_PopSearchTempTable(
	in_parent_sid		IN	security.security_pkg.T_SID_ID,
	in_search_term		IN	VARCHAR2,
	in_additional_class IN  VARCHAR2
)
AS
	v_so_class_id		security.securable_object_class.class_id%TYPE;
	v_so_helper_pkg     security.securable_object_class.helper_pkg%TYPE;
	v_helper_statement	VARCHAR2(150);
BEGIN
	SELECT class_id, helper_pkg into v_so_class_id, v_so_helper_pkg
	  FROM security.securable_object_class soc
	 WHERE LOWER(soc.class_name) = LOWER(in_additional_class);
	 
	-- Call the helper package
	v_helper_statement := 'BEGIN ' || v_so_helper_pkg ||'.PopulateExtendedFolderSearch(:1,:2,:3);END;';
	EXECUTE IMMEDIATE v_helper_statement USING in_parent_sid, v_so_class_id, in_search_term;
END;

PROCEDURE GetFolderTreeTextFiltered(
	in_act_id   		IN  security.security_pkg.T_ACT_ID,
	in_parent_sid		IN	security.security_pkg.T_SID_ID,
	in_search_phrase	IN	VARCHAR2,
	in_additional_class IN  VARCHAR2 DEFAULT null,
	in_hide_root		IN  NUMBER DEFAULT 1,
	out_cur				OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
	v_act_id			security.security_pkg.T_ACT_ID := security.security_pkg.GetACT();
BEGIN

	IF in_additional_class IS NOT NULL THEN
		INTERNAL_PopSearchTempTable(in_parent_sid, in_search_phrase, in_additional_class);
	END IF;

	-- XXX: this reads the whole tree, should we add an explicit tree text filter too?
	OPEN out_cur FOR
		SELECT t.sid_id, t.parent_sid_id, t.name, t.so_level, t.is_leaf, NVL(mt.is_match,0) is_match, 
		       security.security_pkg.SQL_IsAccessAllowedSID(v_act_id, t.sid_id, security.security_pkg.PERMISSION_ADD_CONTENTS) can_add,
			   security.security_pkg.SQL_IsAccessAllowedSID(v_act_id, t.sid_id, security.security_pkg.PERMISSION_WRITE) can_write,
			   security.security_pkg.SQL_IsAccessAllowedSID(v_act_id, t.sid_id, security.security_pkg.PERMISSION_DELETE) can_delete
		  FROM 
		(
		  	SELECT rownum rn, x.sid_id, x.parent_sid_id, x.name, x.so_level, x.is_leaf, x.class_id
		  	  FROM TABLE ( security.SecurableObject_pkg.GetTreeWithPermAsTable(in_act_id, in_parent_sid, 
				  		   security.security_pkg.PERMISSION_READ, null, null, in_hide_root) ) x
		) t, (
			SELECT DISTINCT sid_id
			  FROM security.securable_object
			 START WITH sid_id IN (
				   SELECT sid_id
					 FROM security.securable_object so2
					WHERE EXISTS (
							SELECT fse.sid_id 
							  FROM csr.temp_folder_search_extension fse 
							 WHERE fse.parent_sid = so2.sid_id )
						  OR (LOWER(name) LIKE '%'||LOWER(in_search_phrase)||'%')
					START WITH sid_id = in_parent_sid
			  CONNECT BY PRIOR sid_id = parent_sid_id)
			CONNECT BY PRIOR parent_sid_id = sid_id
		) ti, (
			SELECT sid_id, 1 is_match
			  FROM security.securable_object so3
			 WHERE EXISTS (
						SELECT fse.sid_id 
						  FROM csr.temp_folder_search_extension fse 
						 WHERE fse.parent_sid = so3.sid_id )
					OR (LOWER(name) LIKE '%'||LOWER(in_search_phrase)||'%')
			 START WITH sid_id = in_parent_sid
		   CONNECT BY PRIOR sid_id = parent_sid_id
		) mt 
		WHERE t.sid_id = ti.sid_id 
		  AND t.sid_id = mt.sid_id(+) 
		  AND t.class_id IN (security.security_pkg.SO_CONTAINER, security.security_pkg.SO_WEB_RESOURCE)
		
		ORDER BY t.rn;
END;


PROCEDURE GetFolderTreeWithSelect(
	in_act_id   	IN  security.security_pkg.T_ACT_ID,
	in_parent_sid	IN	security.security_pkg.T_SID_ID,
	in_select_sid	IN	security.security_pkg.T_SID_ID,
	in_fetch_depth	IN	NUMBER,
	in_hide_root	IN  NUMBER DEFAULT 1,
	out_cur			OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
	v_act_id			security.security_pkg.T_ACT_ID := security.security_pkg.GetACT();
BEGIN
	
	OPEN out_cur FOR
		SELECT sid_id, parent_sid_id, name, so_level, is_leaf, 1 is_match, 
		       security.security_pkg.SQL_IsAccessAllowedSID(v_act_id, sid_id, security.security_pkg.PERMISSION_ADD_CONTENTS) can_add,
			   security.security_pkg.SQL_IsAccessAllowedSID(v_act_id, sid_id, security.security_pkg.PERMISSION_WRITE) can_write,
			   security.security_pkg.SQL_IsAccessAllowedSID(v_act_id, sid_id, security.security_pkg.PERMISSION_DELETE) can_delete
		  FROM TABLE ( security.SecurableObject_pkg.GetTreeWithPermAsTable(security.security_pkg.GetACT(), in_parent_sid, 
		  				security.security_pkg.PERMISSION_READ, null, null, in_hide_root )
		 )
		 WHERE class_id IN (security.security_pkg.SO_CONTAINER, security.security_pkg.SO_WEB_RESOURCE)
		   AND  
		   (
				so_level <= in_fetch_depth 
				OR sid_id IN (
					SELECT sid_id
					  FROM security.securable_object
						   START WITH sid_id = in_select_sid
						   CONNECT BY PRIOR parent_sid_id = sid_id
				)
				OR parent_sid_id IN (
					SELECT sid_id
					  FROM security.securable_object
						   START WITH sid_id = in_select_sid
						   CONNECT BY PRIOR parent_sid_id = sid_id
				)
			);
END;


PROCEDURE GetFolderList(
	in_act_id   		IN  security.security_pkg.T_ACT_ID,
	in_parent_sid		IN	security.security_pkg.T_SID_ID,
	in_limit			IN	NUMBER,
	out_cur				OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
	v_act_id			security.security_pkg.T_ACT_ID := security.security_pkg.GetACT();
BEGIN
	
	OPEN out_cur FOR
		SELECT sid_id, parent_sid_id, name, so_level, is_leaf, SUBSTR(path, 2) path, 1 is_match, 
		       security.security_pkg.SQL_IsAccessAllowedSID(v_act_id, sid_id, security.security_pkg.PERMISSION_ADD_CONTENTS) can_add,
			   security.security_pkg.SQL_IsAccessAllowedSID(v_act_id, sid_id, security.security_pkg.PERMISSION_WRITE) can_write,
			   security.security_pkg.SQL_IsAccessAllowedSID(v_act_id, sid_id, security.security_pkg.PERMISSION_DELETE) can_delete
		  FROM TABLE ( security.SecurableObject_pkg.GetTreeWithPermAsTable(in_act_id, in_parent_sid, 
						security.security_pkg.PERMISSION_READ, NULL, in_limit + 1, 1) )
		 WHERE class_id IN (security.security_pkg.SO_CONTAINER, security.security_pkg.SO_WEB_RESOURCE)
		   AND (sid_id <> in_parent_sid AND rownum <= in_limit);
END;

PROCEDURE GetFolderListTextFiltered(
	in_act_id   		IN  security.security_pkg.T_ACT_ID,
	in_parent_sid		IN	security.security_pkg.T_SID_ID,
	in_search_term		IN	VARCHAR2,
	in_limit			IN	NUMBER,
	in_additional_class IN  VARCHAR2 DEFAULT null,
	out_cur				OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
	v_act_id			security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetACT();
	v_include_root		NUMBER(1,0);

BEGIN

	IF in_additional_class IS NOT NULL THEN
		INTERNAL_PopSearchTempTable(in_parent_sid, in_search_term, in_additional_class);
	END IF;

	v_include_root := case when in_additional_class is null then 1 else  0 end;

	-- XXX: this reads the whole tree, should we add an explicit list filter?
	OPEN out_cur FOR
		SELECT sid_id, parent_sid_id, name, so_level, is_leaf, SUBSTR(path, 2) path, 1 is_match,
		       security.security_pkg.SQL_IsAccessAllowedSID(v_act_id, sid_id, security.security_pkg.PERMISSION_ADD_CONTENTS) can_add,
			   security.security_pkg.SQL_IsAccessAllowedSID(v_act_id, sid_id, security.security_pkg.PERMISSION_WRITE) can_write,
			   security.security_pkg.SQL_IsAccessAllowedSID(v_act_id, sid_id, security.security_pkg.PERMISSION_DELETE) can_delete
		  FROM TABLE ( security.SecurableObject_pkg.GetTreeWithPermAsTable(security.security_pkg.GetACT(), in_parent_sid, 
						security.security_pkg.PERMISSION_READ, null, null, v_include_root ) ) so	
	
		 WHERE class_id IN (security.security_pkg.SO_CONTAINER, security.security_pkg.SO_WEB_RESOURCE) 
		   AND	(EXISTS (
					SELECT fse.sid_id 
					  FROM csr.temp_folder_search_extension fse 
					 WHERE fse.parent_sid = so.sid_id )
				  OR ((LOWER(name) LIKE '%'||LOWER(in_search_term)||'%') AND (sid_id <> in_parent_sid)) 
				  )
		   AND ROWNUM < in_limit+1;

END;


PROCEDURE CreateFolder(
	in_parent_sid			IN	security.security_pkg.T_SID_ID,
	in_name					IN	security.security_pkg.T_SO_NAME,
	out_sid_id				OUT	security.security_pkg.T_SID_ID
)
AS
BEGIN
	security.Securableobject_Pkg.CreateSO(security.security_pkg.GetACT(), in_parent_sid, 
		security.security_pkg.SO_CONTAINER, in_name, out_sid_id);
END;

PROCEDURE TrashObject(
	in_act_id   		IN  security.security_pkg.T_ACT_ID,
	in_sid_id			IN	security.security_pkg.T_SID_ID
) 
AS
	v_name	security.securable_object.name%TYPE;
BEGIN

	-- get name
	SELECT NVL(name, '(un-named)')
	  INTO v_name
	  FROM security.securable_object 
	 WHERE sid_id = in_sid_id;

	csr_data_pkg.WriteAuditLogEntry(
		in_act_id, 
		csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, 
		security_pkg.GetApp(), 
		in_sid_id, 
		'Folder "{0}" trashed', 
		v_name);

	trash_pkg.TrashObject(in_act_id, in_sid_id, 
		securableobject_pkg.GetSIDFromPath(in_act_id, security_pkg.GetApp(), 'Trash'),
		v_name);
END;

END;
/
