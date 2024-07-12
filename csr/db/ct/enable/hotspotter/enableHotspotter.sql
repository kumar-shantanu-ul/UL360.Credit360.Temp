whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

PROMPT >> &&host
PROMPT >> Would you like to update the default url (Y/N)?
PROMPT >> &&default_Y

DECLARE
	v_host					VARCHAR2(200) DEFAULT '&&host';
	v_update_url			VARCHAR2(100) DEFAULT TRIM(UPPER(NVL('&&default_Y', 'Y')));
BEGIN
	security.user_pkg.logonadmin(v_host);
	
	ct.setup_pkg.SetupHotspotter(
		in_overwrite_default_url => v_update_url = 'Y'
	);
END;
/

commit;

exit



