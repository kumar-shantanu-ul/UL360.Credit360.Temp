ACCEPT host CHAR PROMPT 'Host (e.g. clientname.credit360.com)  :  '
ACCEPT enable CHAR PROMPT 'Enable? (1/0)  :  '

BEGIN
	security.user_pkg.logonadmin('&&host');

	IF &&enable=1 THEN
		csr.enable_pkg.EnableFactorStartMonth;
	END IF;
	
	IF &&enable=0 THEN
		csr.enable_pkg.DisableFactorStartMonth;
	END IF;
	
	COMMIT;
END;
/
EXIT;
