CREATE OR REPLACE PACKAGE CSR.temp_sqlreport_pkg
IS

PROCEDURE EnableReport(
	in_report_procedure	IN	security_pkg.T_SO_NAME
);
END;
/

CREATE OR REPLACE PACKAGE BODY CSR.temp_sqlreport_pkg
IS

PROCEDURE EnableReport(
	in_report_procedure	IN	security_pkg.T_SO_NAME
)
AS
	v_container_sid	security_pkg.T_SID_ID;
	v_sqlreport_sid	security_pkg.T_SID_ID;
	v_admins 		security_pkg.T_SID_ID;
BEGIN
	-- just create a sec obj of the right type in the right place
	BEGIN
		v_container_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/SqlReports');		
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'),
				SYS_CONTEXT('SECURITY','APP'),
				security_pkg.SO_CONTAINER,
				'SqlReports',
				v_container_sid
			);
			-- allow administrators access
			BEGIN
				v_admins := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Groups/Administrators');
				acl_pkg.AddACE(SYS_CONTEXT('SECURITY','ACT'), acl_pkg.GetDACLIDForSID(v_container_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
					security_pkg.ACE_FLAG_DEFAULT, v_admins, security_pkg.PERMISSION_STANDARD_READ);
			EXCEPTION
				WHEN security_pkg.OBJECT_NOT_FOUND THEN
					-- skip if no administrators group
					NULL;
			END;
	END;
	
	-- Again, catch the exception in case they are trying to enable a report that already exists
	BEGIN
		securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'),
			v_container_sid,
			class_pkg.GetClassId('CSRSqlReport'),
			in_report_procedure,
			v_sqlreport_sid
		);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
END;

END;
/
