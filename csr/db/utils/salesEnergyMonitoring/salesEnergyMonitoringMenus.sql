DECLARE
	v_energy_menu_sid		security_pkg.T_SID_ID;
BEGIN
	
	security.user_pkg.logonadmin('&&1');
	
	-- Rename the real-time metering menu
	FOR m IN (
		SELECT sid_id, action, pos, context
		  FROM security.menu
		 WHERE sid_id = security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP,'menu/meter_monitor')
	) LOOP
		security.menu_pkg.SetMenu(security_pkg.GetACT, m.sid_id, 'Energy Monitoring', m.action, m.pos, m.context);
	END LOOP;
	
	-- Remove metering item from data entry menu
	BEGIN
		security.securableobject_pkg.DeleteSO(security.security_pkg.GetACT, 
			security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP,'menu/data/csr_meter')
		);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	-- Move utility/contract menu items into energy monitoring menu
	BEGIN
		
		v_energy_menu_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP,'menu/meter_monitor');
	
		BEGIN
			security.securableobject_pkg.MoveSO(security_pkg.GetACT, 
				security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP,'menu/meter_utility/contract_search'), v_energy_menu_sid);
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
		
		BEGIN
		security.securableobject_pkg.MoveSO(security_pkg.GetACT, 
			security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP,'menu/meter_utility/utility_supplier'), v_energy_menu_sid);
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
		
		BEGIN
		security.securableobject_pkg.MoveSO(security_pkg.GetACT, 
			security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP,'menu/meter_utility/utility_invoice'), v_energy_menu_sid);
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
		
		BEGIN
		security.securableobject_pkg.MoveSO(security_pkg.GetACT, 
			security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP,'menu/meter_utility/utility_invoice_verification'), v_energy_menu_sid);
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
		
		BEGIN
		security.securableobject_pkg.MoveSO(security_pkg.GetACT, 
			security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP,'menu/meter_utility/utility_reports_extract'), v_energy_menu_sid);
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
		
		BEGIN
		security.securableobject_pkg.MoveSO(security_pkg.GetACT, 
			security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP,'menu/meter_utility/utility_reports_exception'), v_energy_menu_sid);
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
		
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	-- Dlete the parent utility menu
	BEGIN
		security.securableobject_pkg.DeleteSO(security.security_pkg.GetACT, 
			security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP,'menu/meter_utility'));
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	-- Re-order menu items
	security.menu_pkg.SetPos(security.security_pkg.GetACT, 
		security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security_pkg.getAPP, 'menu/meter_monitor/csr_meter'), 1);
		
	security.menu_pkg.SetPos(security.security_pkg.GetACT, 
		security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security_pkg.getAPP, 'menu/meter_monitor/meter_monitor_alarms_setup'), 2);
	
	security.menu_pkg.SetPos(security.security_pkg.GetACT, 
		security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'menu/meter_monitor/contract_search'), 3);
	
	security.menu_pkg.SetPos(security.security_pkg.GetACT, 
		security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'menu/meter_monitor/utility_supplier'), 4);
	
	security.menu_pkg.SetPos(security.security_pkg.GetACT, 
		security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security_pkg.getAPP, 'menu/meter_monitor/data_source_list'), 5);
	
	security.menu_pkg.SetPos(security.security_pkg.GetACT, 
		security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security_pkg.getAPP, 'menu/meter_monitor/orphan_data_list'), 6);
	
	security.menu_pkg.SetPos(security.security_pkg.GetACT, 
		security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP,'menu/meter_monitor/utility_invoice_verification'), 7);
	
	security.menu_pkg.SetPos(security.security_pkg.GetACT, 
		security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP,'menu/meter_monitor/utility_reports_exception'), 8);
	
	security.menu_pkg.SetPos(security.security_pkg.GetACT, 
		security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP,'menu/meter_monitor/utility_invoice'), 9);
	
	security.menu_pkg.SetPos(security.security_pkg.GetACT, 
		security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP,'menu/meter_monitor/utility_reports_extract'), 10);
	
	security.menu_pkg.SetPos(security.security_pkg.GetACT, 
		security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security_pkg.getAPP, 'menu/meter_monitor/csr_issue'), 11);
	
	security.menu_pkg.SetPos(security.security_pkg.GetACT, 
		security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security_pkg.getAPP, 'menu/meter_monitor/csr_region_events_and_docs'), 12);
	
	security.menu_pkg.SetPos(security.security_pkg.GetACT, 
		security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security_pkg.getAPP, 'menu/meter_monitor/raw_data_list'), 13);

	COMMIT;	
END;
/
