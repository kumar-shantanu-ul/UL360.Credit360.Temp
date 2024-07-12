CREATE OR REPLACE PACKAGE BODY CSR.template_pkg AS
    
PROCEDURE SetTemplate(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_template_type_id			IN	template.template_type_Id%TYPE,
	in_mime_type				IN	FILE_UPLOAD.MIME_TYPE%TYPE,
	in_data						IN	FILE_UPLOAD.data%TYPE
)
AS
	v_name		template_type.name%TYPE;
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	-- check permission to alter schema
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid,  csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	user_pkg.GetSid(in_act_id, v_user_sid);
	
	DELETE FROM TEMPLATE
	 WHERE app_sid = in_app_sid
	   AND template_Type_id = in_template_type_id;

	INSERT INTO TEMPLATE
		(app_sid, template_type_id, mime_type, data, uploaded_dtm, uploaded_by_sid)
	VALUES
		(in_app_sid, in_template_type_id, in_mime_type, in_data, SYSDATE, v_user_sid);

	SELECT name INTO v_name
	  FROM template_type
	 WHERE template_type_id = in_template_type_id;
	
	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, in_app_sid, in_app_sid,
		'Uploaded template '||v_name);
END;	


PROCEDURE SetTemplateFromCache(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_template_type_id			IN	template.template_type_Id%TYPE,	
	in_cache_key				IN	aspen2.filecache.cache_key%type
)
AS
	v_user_sid	security_pkg.T_SID_ID;
	v_name		template_type.name%TYPE;
BEGIN
	-- check permission to alter schema
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid,  csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	user_pkg.GetSid(in_act_id, v_user_sid);
	
	DELETE FROM TEMPLATE
	 WHERE app_sid = in_app_sid
	   AND template_Type_id = in_template_type_id;
	   
	INSERT INTO TEMPLATE
		(app_sid, template_type_id, mime_type, data, uploaded_dtm, uploaded_by_sid)
		SELECT in_app_sid, in_template_type_id, mime_type, object, SYSDATE, v_user_sid
		  FROM aspen2.filecache 
		 WHERE cache_key = in_cache_key;
	
	IF SQL%ROWCOUNT = 0 THEN
		-- pah! not found
		RAISE_APPLICATION_ERROR(-20001, 'Cache Key "'||in_cache_key||'" not found');
	END IF; 
	   
	
	SELECT name INTO v_name
	  FROM template_type
	 WHERE template_type_id = in_template_type_id;
	
	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, in_app_sid, in_app_sid,
		'Uploaded template '||v_name);

END;


PROCEDURE GetTemplate(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_template_type_id			IN	template.template_type_Id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check permission on file	   	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
		SELECT NVL(t.mime_type, tt.mime_type) mime_type, NVL(t.DATA, tt.default_data) DATA, 
			t.uploaded_dtm, t.uploaded_by_sid, tt.NAME, tt.description
		  FROM TEMPLATE t, TEMPLATE_TYPE tt
		 WHERE t.app_sid(+) = in_app_sid
		   AND tt.template_type_id = in_template_type_id
		   AND t.template_type_id(+) = tt.template_type_id;
END; 

PROCEDURE GetTemplates (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid					IN	security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
) AS
BEGIN
	-- check permission to alter schema
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid,  csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
		SELECT tt.template_type_id, NVL(t.mime_type, tt.mime_type) mime_type, t.uploaded_dtm, t.uploaded_by_sid, tt.NAME, tt.description
		  FROM template_type tt
		  LEFT JOIN template t ON t.template_type_id = tt.template_type_id AND t.app_sid = in_app_sid;
END;

PROCEDURE DeleteTemplate (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_template_type_id			IN	template.template_type_Id%TYPE
) AS
BEGIN
	-- check permission to alter schema
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid,  csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	DELETE FROM template
	 WHERE template_type_id = in_template_type_id
	   AND app_sid = in_app_sid;
END;

END;
/
