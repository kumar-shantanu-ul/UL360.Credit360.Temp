CREATE OR REPLACE PACKAGE csr.zap_pkg AS

PROCEDURE GetSitesToZap_Regex(
	in_expr						IN	VARCHAR2,
	in_ignore_activity_window	IN	NUMBER DEFAULT 1440, --24hours
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetSiteInfo(
	in_host_name			IN	VARCHAR2,
	out_info_cur			OUT	SYS_REFCURSOR,
	out_cms_schema_cur		OUT	SYS_REFCURSOR,
	out_website_cur			OUT	SYS_REFCURSOR
);

PROCEDURE DoZap;

END;
/
