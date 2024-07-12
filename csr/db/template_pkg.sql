CREATE OR REPLACE PACKAGE CSR.template_pkg AS
   
PROCEDURE SetTemplate(		  
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_template_type_id	IN	template.template_type_Id%TYPE,
	in_mime_type		IN	FILE_UPLOAD.MIME_TYPE%TYPE,
	in_data				IN	FILE_UPLOAD.data%TYPE
);

PROCEDURE SetTemplateFromCache(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_template_type_id	IN	template.template_type_Id%TYPE,	
    in_cache_key		IN	aspen2.filecache.cache_key%type
);

PROCEDURE GetTemplate(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_template_type_id	IN	template.template_type_Id%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTemplates (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid					IN	security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteTemplate (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_template_type_id			IN	template.template_type_Id%TYPE
);

END;
/
