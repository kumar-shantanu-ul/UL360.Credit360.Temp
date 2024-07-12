-- Please update version.sql too -- this keeps clean builds in sync
define version=3260
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
DECLARE
	PROCEDURE DisableCapability (
		in_name                         VARCHAR2
	)
	AS
		v_act_id                        security.security_pkg.T_ACT_ID;
		v_app_sid                       security.security_pkg.T_SID_ID;
		v_capability_sid                security.security_pkg.T_SID_ID;
	BEGIN
		v_act_id := security.security_pkg.GetAct;
		v_app_sid := security.security_pkg.GetApp;
		v_capability_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, '/Capabilities/' || in_name);
		security.securableobject_pkg.DeleteSO(v_act_id, v_capability_sid);
	END;

BEGIN
	FOR r IN (SELECT host FROM csr.customer WHERE name = 'leighcarter-emissionfactors.credit360.com')
	LOOP
		security.user_pkg.logonadmin(r.host);
		DisableCapability('Can delete factor type');
		security.user_pkg.logonadmin();
	END LOOP;
END;
/

-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
