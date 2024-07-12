PROMPT please enter: host

-- test data
DECLARE
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
	-- menu
	v_menu_sheet_export			security.security_pkg.T_SID_ID;
BEGIN
	-- log on
	security.user_pkg.logonadmin('&&1');
	v_app_sid := sys_context('security','app');
	v_act_id := sys_context('security','act');

	/*** ADD MENU ITEM ***/
	security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/analysis'),
		'csr_delegation_browse2_sheetExport', 'Sheet export', '/csr/site/delegation/browse2/sheetExport.acds', 5, null, v_menu_sheet_export);
	csr.csr_data_pkg.EnableCapability('Run sheet export report');
	
	COMMIT;
END;
/
