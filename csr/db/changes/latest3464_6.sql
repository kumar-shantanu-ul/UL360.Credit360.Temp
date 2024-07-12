-- Please update version.sql too -- this keeps clean builds in sync
define version=3464
define minor_version=6
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

INSERT INTO csr.capability (name, allow_by_default, description)
VALUES ('Can manage custom notification templates', 0, 'Allows creation and modification of notification types');

DECLARE
	v_act							security.security_pkg.T_ACT_ID;
	v_resource						security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, NULL, v_act);
	FOR r IN (
		SELECT DISTINCT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id IN (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		BEGIN
			security.web_pkg.CreateResource(v_act, r.web_root_sid_id, r.web_root_sid_id, 'api.notifications', v_resource);
			security.acl_pkg.AddACE(
				v_act,
				security.acl_pkg.GetDACLIDForSID(v_resource),
				security.security_pkg.ACL_INDEX_LAST,
				security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT,
				security.securableobject_pkg.getsidfrompath(v_act, r.application_sid_id, 'Groups/RegisteredUsers'),
				security.security_pkg.PERMISSION_STANDARD_READ);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
	END LOOP;
	security.user_pkg.LogOff(v_act);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../notification_body

@update_tail
