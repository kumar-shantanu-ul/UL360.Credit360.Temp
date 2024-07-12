-- enable_pkg.enableClientConnect doesn't work.
SET VERIFY OFF
whenever sqlerror exit failure rollback 
whenever oserror exit failure rollback	

BEGIN
	security.user_pkg.logonadmin('&&host');
	csr.enable_pkg.EnableClientConnect('&&admin_access', '&&handling_office', '&&customer_name', '&&parenthost');
	COMMIT;
END;
/	
EXIT


