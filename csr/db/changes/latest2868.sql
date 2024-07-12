-- Please update version.sql too -- this keeps clean builds in sync
define version=2868
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

DECLARE
	v_act_id					security.security_pkg.T_ACT_ID;
	v_regusers_sid				security.security_pkg.T_SID_ID;
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_surveys_sid				security.security_pkg.T_SID_ID;
	v_www_sid					security.security_pkg.T_SID_ID;
BEGIN
	FOR r IN (
		SELECT DISTINCT sso.application_sid_id
		  FROM security.securable_object sso
		  JOIN security.acl ON acl.acl_id = sso.dacl_id
		  JOIN security.securable_object wwwso 
		    ON wwwso.sid_id = sso.parent_sid_id
		 WHERE sso.name = 'surveys'
		   AND wwwso.name = 'wwwroot'
		   AND wwwso.parent_sid_id = sso.application_sid_id
		   AND sso.application_sid_id IS NOT NULL
		 MINUS
		SELECT sso.application_sid_id
		  FROM security.securable_object sso
		  JOIN security.acl ON acl.acl_id = sso.dacl_id
		  JOIN security.securable_object gso
			ON gso.sid_id = acl.sid_id
		  JOIN security.group_table g
			ON g.sid_id = gso.sid_id
		  JOIN security.securable_object wwwso 
		    ON wwwso.sid_id = sso.parent_sid_id
		 WHERE sso.name = 'surveys'
		   AND wwwso.name = 'wwwroot'
		   AND wwwso.parent_sid_id = sso.application_sid_id
		   AND gso.name = 'RegisteredUsers'
		   AND sso.application_sid_id IS NOT NULL
	)
	LOOP
		security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 100000, r.application_sid_id, v_act_id);
		v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'Groups');
		v_regusers_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
		v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'wwwroot');
		v_surveys_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'surveys');
		
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_surveys_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
			v_regusers_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		security.user_pkg.Logoff(v_act_id);
	END LOOP;
END;
/


-- ** New package grants **

-- *** Packages ***
@..\enable_pkg
@..\enable_body

@update_tail
