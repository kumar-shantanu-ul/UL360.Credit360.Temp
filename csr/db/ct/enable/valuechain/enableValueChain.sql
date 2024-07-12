whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

PROMPT >> &&host
PROMPT >> Would you like to update the default url (Y/N)?
PROMPT >> &&update_url
PROMPT >> &&side_by_side

DECLARE
	v_host					VARCHAR2(200) DEFAULT '&&host';
	v_update_url			VARCHAR2(100) DEFAULT TRIM(UPPER(NVL('&&update_url', 'Y')));
	v_side_by_side			VARCHAR2(100) DEFAULT TRIM(UPPER(NVL('&&side_by_side', 'Y')));
BEGIN
	security.user_pkg.logonadmin(v_host);
	
	ct.setup_pkg.SetupValueChain(
		in_overwrite_default_url => v_update_url = 'Y', 
		in_side_by_side => v_side_by_side = 'Y'
	);
END;
/

commit;

exit



