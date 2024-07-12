-- Please update version.sql too -- this keeps clean builds in sync
define version=2334
@update_header

BEGIN
	INSERT INTO csr.capability (name, allow_by_default) VALUES ('Allow parent sheet submission before child sheet approval', 0);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

@latest2334_packages

-- Enable the capabilities
DECLARE
	v_acl_id			security.security_pkg.T_ACL_ID;
	v_act				security.security_pkg.T_ACT_ID;
	v_sid_id			security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAdmin;
	FOR r IN (
		SELECT distinct w.website_name host 
		  FROM csr.customer c
		  JOIN security.website w
		    ON c.app_sid = w.application_sid_id
	)
	LOOP
		security.user_pkg.logonadmin(r.host);
		DBMS_OUTPUT.PUT_LINE('Adding parent sheet submission capability to '||r.host||'...');
		BEGIN
			csr.Latest2334_Csr_Data_Pkg.EnableCapability('Allow parent sheet submission before child sheet approval');

			v_act := security.security_pkg.GetAct;
			v_acl_id := security.acl_pkg.GetDACLIDForSID(security.securableobject_pkg.GetSIDFromPath(v_act, security.security_pkg.GetApp, 'Capabilities/Allow parent sheet submission before child sheet approval'));
			v_sid_id := security.securableobject_pkg.GetSIDFromPath(v_act, security.security_pkg.GetApp, 'Groups/RegisteredUsers');

			security.acl_pkg.RemoveACEsForSid(
				v_act,
				v_acl_id,
				v_sid_id
			);
			-- Give access to RegisteredUsers by default (a site admin can turn it off later if they want)
			security.acl_pkg.AddACE(
				v_act,
				v_acl_id,
				security.security_pkg.ACL_INDEX_LAST,
				security.security_pkg.ACE_TYPE_ALLOW,
				0,
				v_sid_id,
				security.security_pkg.PERMISSION_READ+security.security_pkg.PERMISSION_WRITE+security.security_pkg.PERMISSION_READ_PERMISSIONS+security.security_pkg.PERMISSION_LIST_CONTENTS+security.security_pkg.PERMISSION_READ_ATTRIBUTES+security.security_pkg.PERMISSION_WRITE_ATTRIBUTES);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL; -- exists already
		END;
	END LOOP;
END;
/

-- Tidy up
DROP PACKAGE BODY CSR.Latest2334_Csr_Data_Pkg;
DROP PACKAGE CSR.Latest2334_Csr_Data_Pkg;

@update_tail
