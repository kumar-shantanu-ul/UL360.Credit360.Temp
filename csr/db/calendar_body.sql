CREATE OR REPLACE PACKAGE BODY csr.calendar_pkg AS

PROCEDURE CreateObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_class_id					IN security_pkg.T_CLASS_ID,
	in_name						IN security_pkg.T_SO_NAME,
	in_parent_sid_id			IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_name					IN security_pkg.T_SO_NAME
) AS	
BEGIN
	NULL;
END;

PROCEDURE DeleteObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID
) AS 
BEGIN
	DELETE FROM calendar
	 WHERE calendar_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_parent_sid_id		IN security_pkg.T_SID_ID,
	in_old_parent_sid_id		IN security_pkg.T_SID_ID
) AS
BEGIN
	NULL;
END;

PROCEDURE GetAllCalendars(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetAllCalendars(null, out_cur);
END;

PROCEDURE GetAllCalendars (
	in_description					plugin.description%TYPE DEFAULT NULL,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_act						security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app						security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
BEGIN
	OPEN out_cur FOR
		SELECT p.cs_class, p.js_include, p.js_class, p.js_class js_class_type /* TEMP */, p.description, cal.applies_to_initiatives, cal.applies_to_teamrooms
		  FROM csr.plugin p
		  JOIN calendar cal ON p.plugin_id = cal.plugin_id AND p.plugin_type_id = 12
		  JOIN TABLE(securableObject_pkg.GetChildrenWithPermAsTable(v_act, securableobject_pkg.GetSIDFromPath(v_act, v_app, 'Calendars'), security_pkg.PERMISSION_READ)) so
		    ON cal.calendar_sid = so.sid_id
		 WHERE cal.is_global = 1
		   AND (in_description IS NULL OR UPPER(p.description) = UPPER(in_description));
END;

PROCEDURE RegisterCalendar (
	in_name						IN	security_Pkg.T_SO_NAME,
	in_js_include				IN	plugin.js_include%TYPE,
	in_js_class_type			IN	plugin.js_class%TYPE,
	in_description				IN	plugin.description%TYPE,
	in_is_global				IN	calendar.is_global%TYPE DEFAULT 1,
	in_applies_to_teamrooms		IN	calendar.applies_to_teamrooms%TYPE DEFAULT 0,
	in_applies_to_initiatives 	IN	calendar.applies_to_initiatives%TYPE DEFAULT 0,
	in_cs_class					IN	plugin.cs_class%TYPE DEFAULT 'Credit360.Plugins.PluginDto',
	out_calendar_sid			OUT	security_pkg.T_SID_ID
)
AS
	v_act						security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app						security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	v_calendars_sid				security_pkg.T_SID_ID;
	v_plugin_id					csr.plugin.plugin_id%TYPE;	
BEGIN
	BEGIN
		v_calendars_sid := securableobject_pkg.GetSIDFromPath(v_act, v_app, 'Calendars');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			SecurableObject_pkg.CreateSO(v_act, v_app, security_pkg.SO_CONTAINER, 'Calendars', v_calendars_sid);
	END;
	
	-- security checks are in here
	SecurableObject_pkg.CreateSO(v_act, v_calendars_sid, class_pkg.GetClassID('CSRCalendar'), in_name, out_calendar_sid);
		
	v_plugin_id := csr.plugin_pkg.GetPluginId(
		in_js_class				=> in_js_class_type
	);
	
	INSERT INTO calendar (calendar_sid, js_include, js_class_type, description, is_global, applies_to_teamrooms, applies_to_initiatives, plugin_id)
	VALUES (out_calendar_sid, in_js_include, in_js_class_type, in_description, in_is_global, in_applies_to_teamrooms, in_applies_to_initiatives, v_plugin_id);
END;

END calendar_pkg;
/
