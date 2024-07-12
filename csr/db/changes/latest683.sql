-- Please update version.sql too -- this keeps clean builds in sync
define version=683
@update_header

DECLARE
	v_act 			security_pkg.T_ACT_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_ACT);	
	Class_Pkg.AddPermission(v_act, class_pkg.GetClassId('CSRRole'), 65536, 'Logon as another user'); --csr.csr_data_pkg.PERMISSION_LOGON_AS_USER
END;
/

@update_tail


