-- Please update version.sql too -- this keeps clean builds in sync
define version=3341
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

DECLARE
	v_act		security.security_pkg.T_ACT_ID;
	v_sid		security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT DISTINCT cu.app_sid, cu.csr_user_sid, w.web_root_sid_id
		  FROM csr.csr_user cu
		  JOIN security.website w ON w.application_sid_id = cu.app_sid
		 WHERE cu.user_name = 'surveyauthorisedguest'
	)
	LOOP
		BEGIN
			v_sid := security.securableobject_pkg.GetSidFromPath(v_act, r.web_root_sid_id, 'api.regions');

			security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
					security.security_pkg.ACE_FLAG_DEFAULT, r.csr_user_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
