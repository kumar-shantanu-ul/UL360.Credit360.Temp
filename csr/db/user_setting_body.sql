CREATE OR REPLACE PACKAGE BODY CSR.user_setting_pkg AS

FUNCTION CanSetSetting
RETURN BOOLEAN
AS
	v_user_sid			security_pkg.T_SID_ID;
BEGIN
	-- make sure that our user exists, and that it's not the guest
	BEGIN
		SELECT csr_user_sid
		  INTO v_user_sid
		  FROM csr_user
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
		   AND csr_user_sid NOT IN (security_pkg.SID_BUILTIN_GUEST);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN FALSE;
	END;

	RETURN TRUE;
END;

PROCEDURE GetCategory_(
	in_category			IN  user_setting.category%TYPE,
	in_tab_portlet_id	IN  user_setting_entry.tab_portlet_id%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT us.category, us.setting, us.data_type, use.value, use.tab_portlet_id
		  FROM user_setting us, (
					SELECT * 
					  FROM user_setting_entry
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
					   AND NVL(tab_portlet_id, -1) = NVL(in_tab_portlet_id, -1)
				) use
		 WHERE us.category = use.category(+)
		   AND us.setting = use.setting(+)
		   AND us.category = UPPER(TRIM(in_category));
END;

/***********************************************************************
	STANDARD PROCEDURES
***********************************************************************/
PROCEDURE GetRegisteredSettings (
	in_category			IN  user_setting.category%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT setting, data_type, null value
		  FROM user_setting
		 WHERE category = UPPER(TRIM(in_category));
END;

PROCEDURE GetCategory(
	in_category			IN  user_setting.category%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetCategory_(in_category, NULL, out_cur);
END;

PROCEDURE ClearCategory (
	in_category			IN  user_setting.category%TYPE
)
AS
BEGIN
	DELETE FROM user_setting_entry
	 WHERE category = UPPER(TRIM(in_category))
	   AND csr_user_sid = SYS_CONTEXT('SECURITY', 'SID');
END;


PROCEDURE ClearSetting (
	in_category			IN  user_setting.category%TYPE,
	in_setting			IN  user_setting.setting%TYPE
)
AS
BEGIN
	DELETE FROM user_setting_entry
	 WHERE category = UPPER(TRIM(in_category))
	   AND setting = TRIM(in_setting)
	   AND csr_user_sid = SYS_CONTEXT('SECURITY', 'SID');
END;


PROCEDURE SetSetting (
	in_category			IN  user_setting.category%TYPE,
	in_setting			IN  user_setting.setting%TYPE,
	in_value			IN  user_setting_entry.value%TYPE
)
AS
BEGIN
	IF NOT CanSetSetting() THEN
		RETURN;
	END IF;
	
	-- if the values are null, clear the setting
	IF in_value IS NULL THEN
		ClearSetting(in_category, in_setting);
		RETURN;
	END IF;
	
	-- save the setting
	BEGIN
		INSERT INTO user_setting_entry
		(category, setting, value)
		VALUES
		(UPPER(TRIM(in_category)), TRIM(in_setting), in_value);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE user_setting_entry
			   SET value = in_value
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND category = UPPER(TRIM(in_category))
			   AND setting = TRIM(in_setting);
	END;
END;

PROCEDURE SetSettings (
	in_category			IN  user_setting.category%TYPE,
	in_settings			IN  security_pkg.T_VARCHAR2_ARRAY,
	in_values			IN  security_pkg.T_VARCHAR2_ARRAY
)
AS
BEGIN
	IF in_settings IS NULL OR in_values IS NULL THEN 
		RAISE_APPLICATION_ERROR(-20001, 'Expected non-null settings and/or values arrays');
	END IF;
	
	IF in_settings.COUNT <> in_values.COUNT THEN
		RAISE_APPLICATION_ERROR(-20001, 'Mismatch lengths between the settings and values arrays ('||in_settings.count||'/'||in_values.COUNT||')');
	END IF;
	
	IF NOT CanSetSetting() THEN
		RETURN;
	END IF;
	
	ClearCategory(in_category);
	
	FOR i IN in_settings.FIRST .. in_settings.LAST
	LOOP
		SetSetting(in_category, in_settings(i), in_values(i));
	END LOOP;
	
END;

/***********************************************************************
	PORTLET PROCEDURES
***********************************************************************/
PROCEDURE ClearPortletSettings (
	in_portlet_name		IN  user_setting.category%TYPE,
	in_tab_portlet_id	IN  user_setting_entry.tab_portlet_id%TYPE
)
AS
BEGIN
	DELETE FROM user_setting_entry
	 WHERE category = UPPER(TRIM(in_portlet_name))
	   AND tab_portlet_id = in_tab_portlet_id
	   AND csr_user_sid = SYS_CONTEXT('SECURITY', 'SID');
END;


PROCEDURE ClearPortletSetting (
	in_portlet_name		IN  user_setting.category%TYPE,
	in_tab_portlet_id	IN  user_setting_entry.tab_portlet_id%TYPE,
	in_setting			IN  user_setting.setting%TYPE
)
AS
BEGIN
	DELETE FROM user_setting_entry
	 WHERE category = UPPER(TRIM(in_portlet_name))
	   AND tab_portlet_id = in_tab_portlet_id
	   AND setting = TRIM(in_setting)
	   AND csr_user_sid = SYS_CONTEXT('SECURITY', 'SID');
END;


PROCEDURE GetPortletSettings (
	in_portlet_name		IN  user_setting.category%TYPE,
	in_tab_portlet_id	IN  user_setting_entry.tab_portlet_id%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetCategory_(in_portlet_name, in_tab_portlet_id, out_cur);
END;

PROCEDURE SetPortletSetting (
	in_portlet_name		IN  user_setting.category%TYPE,
	in_tab_portlet_id	IN  user_setting_entry.tab_portlet_id%TYPE,
	in_setting			IN  user_setting.setting%TYPE,
	in_value			IN  user_setting_entry.value%TYPE
)
AS
BEGIN
	IF NOT CanSetSetting() THEN
		RETURN;
	END IF;
	
	-- if the values are null, clear the setting
	IF in_value IS NULL THEN
		ClearPortletSetting(in_portlet_name, in_tab_portlet_id, in_setting);
		RETURN;
	END IF;
	
	-- save the setting
	BEGIN
		INSERT INTO user_setting_entry
		(category, setting, tab_portlet_id, value)
		VALUES
		(UPPER(TRIM(in_portlet_name)), TRIM(in_setting), in_tab_portlet_id, in_value);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE user_setting_entry
			   SET value = in_value
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND category = UPPER(TRIM(in_portlet_name))
			   AND setting = TRIM(in_setting)
			   AND tab_portlet_id = in_tab_portlet_id;
	END;
END;

PROCEDURE SetPortletSettings (
	in_portlet_name		IN  user_setting.category%TYPE,
	in_tab_portlet_id	IN  user_setting_entry.tab_portlet_id%TYPE,
	in_settings			IN  security_pkg.T_VARCHAR2_ARRAY,
	in_values			IN  security_pkg.T_VARCHAR2_ARRAY
)
AS
BEGIN
	IF in_settings IS NULL OR in_values IS NULL THEN 
		RAISE_APPLICATION_ERROR(-20001, 'Expected non-null settings and/or values arrays');
	END IF;
	
	IF in_settings.COUNT <> in_values.COUNT THEN
		RAISE_APPLICATION_ERROR(-20001, 'Mismatch lengths between the settings and values arrays ('||in_settings.count||'/'||in_values.COUNT||')');
	END IF;
	
	IF NOT CanSetSetting() THEN
		RETURN;
	END IF;
	
	ClearPortletSettings(in_portlet_name, in_tab_portlet_id);
	
	FOR i IN in_settings.FIRST .. in_settings.LAST
	LOOP
		SetPortletSetting(in_portlet_name, in_tab_portlet_id, in_settings(i), in_values(i));
	END LOOP;
	
END;

END user_setting_pkg;
/
