-- This only needs to be run if chem was enabled before reports existed.

DECLARE
	v_act_id				security.security_pkg.T_ACT_ID;
	v_app_sid				security.security_pkg.T_SID_ID;
	v_menu_admin			security.security_pkg.T_SID_ID;
	v_menu1					security.security_pkg.T_SID_ID;
	v_admins_sid			security.security_pkg.T_SID_ID;
	v_groups_sid			security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin('&&1');
	
	v_app_sid := sys_context('security','app');
	v_act_id := sys_context('security','act');
	
	v_menu_admin := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin');
  
	BEGIN
    v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
    v_admins_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
  
		security.menu_pkg.CreateMenu(v_act_id, v_menu_admin,
			'csr_chem_reports',
			'Chemical reports',
			'/csr/site/chem/reports/reports.acds',
			10, null, v_menu1);
		
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu1), -1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid,
			security.security_pkg.PERMISSION_STANDARD_READ);
		
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	-- this grants admins access automatically
	csr.sqlreport_pkg.EnableReport('chem.report_pkg.GetCasCodes');
	csr.sqlreport_pkg.EnableReport('chem.report_pkg.GetCasRestrictions');
	csr.sqlreport_pkg.EnableReport('chem.report_pkg.GetWaiverStatus');
	csr.sqlreport_pkg.EnableReport('chem.report_pkg.GetSubstances');
	csr.sqlreport_pkg.EnableReport('chem.report_pkg.GetSubstancesReport');
	csr.sqlreport_pkg.EnableReport('chem.report_pkg.GetFullReport');
	csr.sqlreport_pkg.EnableReport('chem.report_pkg.GetMSDSUploads');
	csr.sqlreport_pkg.EnableReport('chem.report_pkg.GetUngroupedCASCodes');
	csr.sqlreport_pkg.EnableReport('chem.report_pkg.CasGroupsReport');
	csr.sqlreport_pkg.EnableReport('chem.report_pkg.GetRawOutputs');
	csr.sqlreport_pkg.EnableReport('chem.report_pkg.SubstCompCheckReport');
	csr.sqlreport_pkg.EnableReport('chem.report_pkg.GetFullSheetReport');
	csr.sqlreport_pkg.EnableReport('chem.audit_pkg.GetSubLogEntries');
	csr.sqlreport_pkg.EnableReport('chem.audit_pkg.GetAllUsageLogEntries');
	csr.sqlreport_pkg.EnableReport('chem.report_pkg.GetAuditReport');
END;
/