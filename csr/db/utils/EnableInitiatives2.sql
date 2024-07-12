ACCEPT host CHAR     PROMPT 'Host (e.g. clientname.credit360.com)  :  '
BEGIN
	-- log on
	security.user_pkg.logonadmin('&&host');
	-- This is now implemented in the enable_pkg and Enable Modules page.
	csr.enable_pkg.EnableInitiatives;
	COMMIT;
END;
/
