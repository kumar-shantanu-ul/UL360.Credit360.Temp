-- Please update version.sql too -- this keeps clean builds in sync
define version=3359
define minor_version=13
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
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_reg_users_sid					security.security_pkg.T_SID_ID;
	v_www_sid						security.security_pkg.T_SID_ID;
	v_www_csr_site					security.security_pkg.T_SID_ID;
	v_www_helpiq					security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act_id);
	FOR r IN (
		SELECT application_sid_id app_sid, web_root_sid_id, website_name
		  FROM security.website
		 WHERE application_sid_id in (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'Groups');
		v_reg_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
		v_www_sid := r.web_root_sid_id; --security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'wwwroot');
		BEGIN
			v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN 
				dbms_output.put_line(r.website_name||':  *no csr/site for '||r.app_sid);
				CONTINUE;
		END;
		BEGIN
			v_www_helpiq       := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'wwwroot/csr/site/helpiq.acds');
			--dbms_output.put_line(r.website_name||':  helpiq resource exists for '||r.app_sid);
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				dbms_output.put_line(r.website_name||':  creating helpiq for '||r.app_sid);
				security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site, 'helpiq.acds', v_www_helpiq);
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_helpiq), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
					security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		END;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
