CREATE OR REPLACE PACKAGE DONATIONS.browse_settings_pkg
IS
-- filter_type 
-- 0 - for browse.acds
-- 1 - for pivotTable.acds

FILTER_BROWSE					CONSTANT NUMBER(1) := 0;
FILTER_PIVOT					CONSTANT NUMBER(1) := 1;
FILTER_FUNDING_COMMITMENT		CONSTANT NUMBER(1) := 2;

FUNCTION CanModify(
	in_filter_id	IN	filter.filter_id%TYPE
) RETURN BOOLEAN;

PROCEDURE SaveSetting(
	in_act				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_name				IN	filter.name%TYPE,
	in_description      IN  filter.description%TYPE,
	in_isshared         IN  NUMBER,
	in_filter_xml       IN  sys.xmltype,
	in_column_xml       IN  sys.xmltype,
	in_filter_type      IN  filter.filter_type%TYPE,
	out_filter_id		OUT	filter.filter_id%TYPE
);

PROCEDURE GetSettings(
	in_act				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_filter_type      IN  filter.filter_type%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE LoadSetting(
    in_act				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
    in_filter_id        IN  security_pkg.T_SID_ID,
    out_cur             OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteSetting(
    in_act				IN  security_pkg.T_ACT_ID,
	in_app_sid			IN  security_pkg.T_SID_ID,
    in_filter_id        IN  security_pkg.T_SID_ID
);

END browse_settings_pkg;
/
