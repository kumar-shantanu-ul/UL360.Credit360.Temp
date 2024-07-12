-- Please update version.sql too -- this keeps clean builds in sync
define version=1399
@update_header

INSERT INTO csr.capability (name, allow_by_default) VALUES ('Import surveys from Excel', 1);

@latest1399_packages

-- Enable the capabilities
BEGIN
	security.user_pkg.LogonAdmin;
	FOR r IN (
		SELECT DISTINCT host 
		  FROM csr.customer c
			JOIN csr.tab t ON c.app_sid = t.app_sid
	)
	LOOP
		security.user_pkg.logonadmin(r.host);
		DBMS_OUTPUT.PUT_LINE('Adding survey import capability to '||r.host||'...');
		BEGIN
			CSR.Latest1399_Csr_Data_Pkg.EnableCapability('Import surveys from Excel');

			-- Give access to Everyone by default (a site admin can turn it off later if they want)
			security.acl_pkg.AddACE(
				security.security_pkg.GetAct,
				security.acl_pkg.GetDACLIDForSID(security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Capabilities/Import surveys from Excel')),
				security.security_pkg.ACL_INDEX_LAST,
				security.security_pkg.ACE_TYPE_ALLOW,
				0,
				security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Groups/Everyone'),
				security.security_pkg.PERMISSION_READ+security.security_pkg.PERMISSION_WRITE+security.security_pkg.PERMISSION_READ_PERMISSIONS+security.security_pkg.PERMISSION_LIST_CONTENTS+security.security_pkg.PERMISSION_READ_ATTRIBUTES+security.security_pkg.PERMISSION_WRITE_ATTRIBUTES);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL; -- exists already
		END;
	END LOOP;
	security.user_pkg.LogonAdmin;
END;
/

-- Tidy up
DROP PACKAGE BODY CSR.Latest1399_Csr_Data_Pkg;
DROP PACKAGE CSR.Latest1399_Csr_Data_Pkg;

@..\csr_data_body

@update_tail
