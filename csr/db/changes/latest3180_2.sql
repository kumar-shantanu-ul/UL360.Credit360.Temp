-- Please update version.sql too -- this keeps clean builds in sync
define version=3180
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
-- Create Resources for current compliance customers
DECLARE
	v_act							security.security_pkg.T_ACT_ID;
	v_sid							security.security_pkg.T_SID_ID;
	v_regusers_sid					security.security_pkg.T_SID_ID;
    v_groups_sid					security.security_pkg.T_SID_ID;
    v_www_sid						security.security_pkg.T_SID_ID;
    v_www_api_compliance			security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT wr.sid_id, wr.web_root_sid_id, so.application_sid_id
		  FROM security.web_resource wr
          JOIN security.securable_object so on wr.sid_id = so.sid_id
		 WHERE path = '/csr/site/compliance'
	)
	LOOP
  
        v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act, r.application_sid_id, 'wwwroot');
        
        BEGIN
            v_www_api_compliance := security.securableobject_pkg.GetSidFromPath(v_act, v_www_sid, 'api.compliance');
        EXCEPTION
            WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
            BEGIN
                security.security_pkg.SetApp(r.application_sid_id);
                security.web_pkg.CreateResource(v_act, v_www_sid, v_www_sid, 'api.compliance', v_www_api_compliance);
                
                v_groups_sid := security.securableObject_pkg.GetSIDFromPath(v_act, r.application_sid_id, 'Groups');
                v_regusers_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_groups_sid, 'RegisteredUsers');
                security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_www_api_compliance), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security.security_pkg.PERMISSION_STANDARD_READ);
                security.security_pkg.SetApp(null);
            END;
        END;
		
	END LOOP;
    security.user_pkg.LogOff(v_act);
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../enable_body.sql

@update_tail
