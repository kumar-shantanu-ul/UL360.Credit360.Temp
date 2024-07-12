-- Please update version.sql too -- this keeps clean builds in sync
define version=3457
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
	v_act							security.security_pkg.T_ACT_ID;
	v_www_root						security.security_pkg.T_SID_ID;
	v_csr_resource_sid				security.security_pkg.T_SID_ID;
	v_sasso_resource_sid			security.security_pkg.T_SID_ID;
	v_ssopage_resource_sid			security.security_pkg.T_SID_ID;
	v_everyone_sid					security.security_pkg.T_SID_ID;
	v_sso_site						NUMBER;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, v_act);

	-- Ensure that csr\sasso and csr\sasso\singlesignon.acds resources exist.
	-- An issue in another latest script broke the script that creates these resources.
	-- We also want to ensure for already created SSO sites that
	-- we do not create the singlesignon.acds resource as this is removed when the SSO site is created
	-- by the EnableSuperadminSsoSite stored procedure
	FOR r IN (
		SELECT DISTINCT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id IN (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		v_everyone_sid := security.securableobject_pkg.GetSidFromPath(v_act, r.application_sid_id, 'Groups/Everyone');

		SELECT COUNT(*) INTO v_sso_site
		  FROM aspen2.application
		 WHERE app_sid = r.application_sid_id
		   AND aspen2.application.logon_url = '/csr/sasso/login/superadminlogin.acds';

		BEGIN
			v_www_root := security.securableobject_pkg.GetSidFromPath(v_act, r.application_sid_id, 'wwwroot');
			v_csr_resource_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_www_root, 'csr');
			
			BEGIN
				v_sasso_resource_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_csr_resource_sid, 'sasso');

				IF v_sso_site = 0 THEN
					BEGIN
						v_ssopage_resource_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_sasso_resource_sid, 'singlesignon.acds');
					EXCEPTION
						WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
							
							security.web_pkg.CreateResource(v_act, v_www_root, v_sasso_resource_sid, 'singlesignon.acds', v_ssopage_resource_sid);
							
							security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_ssopage_resource_sid), -1, 
								security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);
					END;
				END IF;		
			
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.web_pkg.CreateResource(v_act, v_www_root, v_csr_resource_sid, 'sasso', v_sasso_resource_sid);
					IF v_sso_site = 0 THEN					
						security.web_pkg.CreateResource(v_act, v_www_root, v_sasso_resource_sid, 'singlesignon.acds', v_ssopage_resource_sid);

						security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_ssopage_resource_sid), -1, 
							security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);
					END IF;
			END;
			
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				CONTINUE;
		END;
	END lOOP;

	security.user_pkg.LogOff(v_act);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
