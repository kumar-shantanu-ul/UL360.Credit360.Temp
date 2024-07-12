CREATE OR REPLACE PACKAGE csr.calendar_pkg AS

PROCEDURE CreateObject(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_sid_id					IN  security_pkg.T_SID_ID,
	in_class_id					IN  security_pkg.T_CLASS_ID,
	in_name						IN  security_pkg.T_SO_NAME,
	in_parent_sid_id			IN  security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_sid_id					IN  security_pkg.T_SID_ID,
	in_new_name					IN  security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_sid_id					IN  security_pkg.T_SID_ID
); 

PROCEDURE MoveObject(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_sid_id					IN  security_pkg.T_SID_ID,
	in_new_parent_sid_id		IN  security_pkg.T_SID_ID,
	in_old_parent_sid_id		IN security_pkg.T_SID_ID
); 

PROCEDURE GetAllCalendars(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllCalendars (
	in_description					plugin.description%TYPE DEFAULT NULL,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RegisterCalendar (
	in_name						IN	security_Pkg.T_SO_NAME,
	in_js_include				IN	plugin.js_include%TYPE,
	in_js_class_type			IN	plugin.js_class%TYPE,
	in_description				IN	plugin.description%TYPE,
	in_is_global				IN	calendar.is_global%TYPE DEFAULT 1,
	in_applies_to_teamrooms		IN	calendar.applies_to_teamrooms%TYPE DEFAULT 0,
	in_applies_to_initiatives	IN	calendar.applies_to_initiatives%TYPE DEFAULT 0,
	in_cs_class					IN	plugin.cs_class%TYPE DEFAULT 'Credit360.Plugins.PluginDto',
	out_calendar_sid			OUT	security_pkg.T_SID_ID
);

END calendar_pkg;
/
