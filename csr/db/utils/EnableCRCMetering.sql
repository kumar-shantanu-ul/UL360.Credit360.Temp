PROMPT please enter: host

DECLARE
	v_menu_utility		security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin('&&1');

	-- turn on CRC metering on app
	UPDATE csr.customer
	   SET crc_metering_enabled = 1,
		   crc_metering_auto_core = 1,
		   crc_metering_ind_core = 0;
	IF SQL%ROWCOUNT != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Expected exactly one row in CSR.CUSTOMER but got '||SQL%ROWCOUNT||' rows');
	END IF;
	
	-- this menu is only really relevant to CRC
	security.menu_pkg.CreateMenu(security.security_pkg.GetACT, 
		security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'menu/meter_utility'),
		'utility_reports_activity', 'Activity reports', '/csr/site/meter/reports/activity.acds', 8, null, v_menu_utility);
END;
/

exit
