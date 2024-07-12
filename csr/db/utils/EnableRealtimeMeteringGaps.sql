define host = &&host
define root_meter_monitor_menu_path = &&root_meter_monitor_menu_path
define gaps_from_acquisition = &&gaps_from_acquisition

DECLARE
	v_menu_meter_mon_sid			security.security_pkg.T_SID_ID;
	v_menu_missing_data_sid			security.security_pkg.T_SID_ID;
	v_cnt							NUMBER(10);
BEGIN
	-- log on
	security.user_pkg.logonadmin('&&host');
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM csr.meter_source_type
	  WHERE name = 'live';
	  
	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(-20001,'Please Enable realtime metering first');
	END IF;

	v_menu_meter_mon_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP,'&&root_meter_monitor_menu_path');

	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.getACT, v_menu_meter_mon_sid, 'meter_missing_data_report', 'Missing data report', '/csr/site/meter/monitor/MetersWithMissingData.acds', 8, null, v_menu_missing_data_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_missing_data_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, '&&root_meter_monitor_menu_path/meter_missing_data_report');
	END;
	
	update csr.customer set LIVE_METERING_SHOW_GAPS = 1, METERING_GAPS_FROM_ACQUISITION = &&gaps_from_acquisition WHERE app_sid = security.security_pkg.getAPP;
	
	COMMIT;
END;
/
