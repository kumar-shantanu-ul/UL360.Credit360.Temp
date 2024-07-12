PROMPT please enter: 1 Host | 2 Start Month (where Jan = 1) | 3 Start Year | 4 End Year

whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

BEGIN
	security.user_pkg.logonadmin('&&1');
	csr.util_script_pkg.SetStartMonth('&&2', '&&3', '&&4');
END;
/

exit
