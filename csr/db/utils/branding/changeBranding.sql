PROMPT Enter Host, fromClientSubdirectory, toClientSubdirectory
PROMPT e.g. example.credit360.com example test
BEGIN
	security.user_pkg.logonadmin('&&1');

	-- change paths to styles folders
	UPDATE aspen2.application
	   SET default_stylesheet = REPLACE(default_stylesheet, '/&&2/', '/&&3/'), 
	   	   default_css = REPLACE(default_css, '/&&2/', '/&&3/'),
	   	   edit_css = REPLACE(edit_css, '/&&2/', '/&&3/')
	 WHERE app_sid = security.security_pkg.getAPP;
	 
	UPDATE csr.customer
	   SET default_admin_css = REPLACE(default_admin_css, '/&&2/', '/&&3/'),
	   	   chart_xsl = REPLACE(chart_xsl, '/&&2/', '/&&3/')
	 WHERE app_sid = security.security_pkg.getAPP;

	-- rename web resource
	BEGIN
		security.securableobject_pkg.renameSO(security.security_pkg.getACT,
			security.securableobject_pkg.getSIDFromPath(security.security_pkg.getACT, security.security_pkg.getApp, 'wwwroot/&&2'),
			'&&3');
	EXCEPTION
		WHEN security.security_pkg.duplicate_object_name THEN
			NULL; -- ignore - it exists already.
	END;
	COMMIT;
END;
/

EXIT
