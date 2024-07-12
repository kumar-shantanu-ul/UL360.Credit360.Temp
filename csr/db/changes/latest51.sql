-- Please update version.sql too -- this keeps clean builds in sync
define version=51
@update_header

-- bit of an overhaul. CSRApp object is like AspenApp but creates CSRUserGroup classes for registered users /administrators


connect aspen2/aspen2@aspen
-- rebuild aspen2/aspenapp_pkg and aspenapp_body first!!
@c:\cvs\aspen2\db\aspenapp_pkg.sql
@c:\cvs\aspen2\db\aspenapp_body.sql
GRANT EXECUTE ON aspenapp_pkg TO csr;

connect csr/csr@aspen
@c:\cvs\csr\db\csr_app_pkg.sql
@c:\cvs\csr\db\csr_app_body.sql
GRANT EXECUTE ON csr.csr_app_pkg TO SECURITY;


DECLARE
	new_class_id 	security_pkg.T_SID_ID;
	v_act 			security_pkg.T_ACT_ID;
	v_attribute_id	security_pkg.T_ATTRIBUTE_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_ACT);	
	-- create csr app classes (inherits from aspenapp)
	BEGIN	
		class_pkg.CreateClass(v_act, class_pkg.getclassid('aspenapp'), 'CSRApp', 'csr.csr_app_pkg', null, new_class_id);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=class_pkg.GetClassId('CSRApp');
	END;
END;
/
COMMIT;
/

@update_tail
