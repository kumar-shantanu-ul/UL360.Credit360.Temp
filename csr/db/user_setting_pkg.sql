CREATE OR REPLACE PACKAGE CSR.user_setting_pkg AS

/***********************************************************************
	STANDARD PROCEDURES
***********************************************************************/
PROCEDURE GetRegisteredSettings (
	in_category			IN  user_setting.category%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCategory (
	in_category			IN  user_setting.category%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ClearCategory (
	in_category			IN  user_setting.category%TYPE
);

PROCEDURE ClearSetting (
	in_category			IN  user_setting.category%TYPE,
	in_setting			IN  user_setting.setting%TYPE
);

PROCEDURE SetSetting (
	in_category			IN  user_setting.category%TYPE,
	in_setting			IN  user_setting.setting%TYPE,
	in_value			IN  user_setting_entry.value%TYPE
);

PROCEDURE SetSettings (
	in_category			IN  user_setting.category%TYPE,
	in_settings			IN  security_pkg.T_VARCHAR2_ARRAY,
	in_values			IN  security_pkg.T_VARCHAR2_ARRAY
);

/***********************************************************************
	PORTLET PROCEDURES
***********************************************************************/
PROCEDURE ClearPortletSettings (
	in_portlet_name		IN  user_setting.category%TYPE,
	in_tab_portlet_id	IN  user_setting_entry.tab_portlet_id%TYPE
);

PROCEDURE ClearPortletSetting (
	in_portlet_name		IN  user_setting.category%TYPE,
	in_tab_portlet_id	IN  user_setting_entry.tab_portlet_id%TYPE,
	in_setting			IN  user_setting.setting%TYPE
);

PROCEDURE GetPortletSettings (
	in_portlet_name		IN  user_setting.category%TYPE,
	in_tab_portlet_id	IN  user_setting_entry.tab_portlet_id%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetPortletSetting (
	in_portlet_name		IN  user_setting.category%TYPE,
	in_tab_portlet_id	IN  user_setting_entry.tab_portlet_id%TYPE,
	in_setting			IN  user_setting.setting%TYPE,
	in_value			IN  user_setting_entry.value%TYPE
);

PROCEDURE SetPortletSettings (
	in_portlet_name		IN  user_setting.category%TYPE,
	in_tab_portlet_id	IN  user_setting_entry.tab_portlet_id%TYPE,
	in_settings			IN  security_pkg.T_VARCHAR2_ARRAY,
	in_values			IN  security_pkg.T_VARCHAR2_ARRAY
);


END user_setting_pkg;
/
