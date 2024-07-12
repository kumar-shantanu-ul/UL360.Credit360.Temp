-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=34
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
-- Add Issues Management capability to the EHS Manager group

DECLARE
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_act_id						security.security_pkg.T_ACT_ID;
	v_issue_man_capability_sid		security.security_pkg.T_SID_ID;	
	v_ehs_managers_sid				security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin;
	v_act_id := security.security_pkg.GetAct;

	-- Enable for all app_sids that have compliance
	FOR app IN (
		SELECT app_sid
		  FROM csr.customer
	)
	LOOP
		v_app_sid := app.app_sid;
		v_groups_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups');
		
		BEGIN
			v_ehs_managers_sid := security.securableObject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'EHS Managers');
		EXCEPTION WHEN OTHERS THEN
		  CONTINUE;
		END;
		
		BEGIN
			v_issue_man_capability_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Capabilities/Issue management');
		EXCEPTION WHEN OTHERS THEN
			CONTINUE;
		END;

		security.acl_pkg.AddACE(
			v_act_id,
			security.acl_pkg.GetDACLIDForSID(v_issue_man_capability_sid),
			-1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_ehs_managers_sid,
			security.security_pkg.PERMISSION_STANDARD_ALL
		);
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@@..\enable_body

@update_tail
