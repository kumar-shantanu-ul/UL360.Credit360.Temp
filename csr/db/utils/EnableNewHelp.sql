PROMPT please enter: host

DECLARE
	v_menu_help		security_pkg.T_SID_ID;
	v_act			security_pkg.T_ACT_ID;
	v_app_sid		security_pkg.T_SID_ID;
	v_count			NUMBER;
	v_default_lang	help_lang.help_lang_id%TYPE;
	v_name			customer.name%TYPE;
BEGIN
	-- log on
	user_pkg.LogonAdmin('&&1');	
	v_act := sys_context('security','act');
	v_app_sid := sys_context('security','app');
	security.menu_pkg.CreateMenu(v_act, securableobject_pkg.GetSIDFromPath(v_act, security_pkg.GetApp, 'menu'),
		'csr_new_help', --'csr_help_viewhelp', 
		'Help', '/csr/site/newHelp/editor.acds', 12, null, v_menu_help);
	acl_pkg.AddACE(v_act, acl_pkg.GetDACLIDForSID(v_menu_help), -1, security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_DEFAULT, 
		securableobject_pkg.GetSidFromPath(v_act, security_pkg.GetApp, 'Groups/RegisteredUsers'), 
		security_pkg.PERMISSION_STANDARD_READ);
	COMMIT;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM customer_help_lang
	 WHERE app_sid = v_app_sid;
	
	IF v_count = 0 THEN
		INSERT INTO customer_help_lang (help_lang_id, is_default, app_sid)
			VALUES (1, 1, v_app_sid);
		v_count := 1;
	END IF;
	
	SELECT help_lang_id
	  INTO v_default_lang
	  FROM customer_help_lang
	 WHERE app_sid = v_app_sid
	   AND is_default = 1;
	
	IF v_count = 1 AND v_default_lang = 1 THEN
		SELECT name
		  INTO v_name
		  FROM customer
		 WHERE app_sid = v_app_sid;
		
		INSERT INTO help_lang (help_lang_id, base_lang_id, label, short_name)
			VALUES (help_lang_id_seq.nextval, 1, 'English (' || v_name || ')', v_name)
			RETURNING help_lang_id INTO v_default_lang;
		
		UPDATE customer_help_lang
		   SET is_default = 0
		 WHERE app_sid = v_app_sid;
		
		UPDATE customer_help_lang
		   SET is_default = 1
		 WHERE app_sid = v_app_sid
		   AND help_lang_id = v_default_lang;
	END IF;
END;
/
exit
