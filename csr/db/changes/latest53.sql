-- Please update version.sql too -- this keeps clean builds in sync
define version=53
@update_header

/* COMPILE HELP STUFF FIRST */

DECLARE
	v_act				SECURITY_PKG.T_ACT_ID;
	v_csr_sid			SECURITY_PKG.T_SID_ID;
	v_help_sid			SECURITY_PKG.T_SID_ID;
	v_lang_id			help_lang.help_lang_id%TYPE;
	v_superadmins_sid	SECURITY_PKG.T_SID_ID;
BEGIN
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	v_csr_sid := securableobject_pkg.GetSidFromPath(v_act, 0, 'csr');
	v_superadmins_sid := securableobject_pkg.GetSidFromPath(v_act, 0, 'csr/superadmins');
	securableobject_pkg.createSO(v_act, v_csr_sid, security_pkg.SO_CONTAINER, 'Help',v_help_sid);
	help_pkg.AddLanguage(v_act, NULL, 'English (British)', v_lang_id);
	INSERT INTO customer_help_lang 
		SELECT csr_root_sid, lang_id, 1
		  FROM customer, (SELECT MIN(help_lang_id) lang_id FROM help_lang) hl;
END;
/
commit;

@update_tail
