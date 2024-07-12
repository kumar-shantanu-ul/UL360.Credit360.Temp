-- Please update version.sql too -- this keeps clean builds in sync
define version=2915
define minor_version=14
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
-- Add admin menu item to metering sites
DECLARE
	v_act_id						VARCHAR2(36);
	v_admins_sid					NUMBER(10);
	v_menu_sid						NUMBER(10);
	v_www_csr_site					NUMBER(10);
	v_www_sid						NUMBER(10);
	v_wwwroot_sid					NUMBER(10);
BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT c.app_sid, c.host
		  FROM security.menu m 
		  JOIN security.securable_object so ON m.sid_id = so.sid_id 
		  JOIN csr.customer c ON so.application_sid_id = c.app_sid
		 WHERE LOWER(m.action) = '/csr/site/meter/meterlist.acds'
	) LOOP
		security.user_pkg.LogonAdmin(r.host);
		v_act_id := security.security_pkg.GetAct;
		
		BEGIN
			v_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'Groups/Administrators');

			BEGIN
				security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'menu/admin'),
					'csr_meter_admin', 'Metering admin', '/csr/site/meter/admin/menu.acds', 20, null, v_menu_sid);
			EXCEPTION
				WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
					v_menu_sid := security.securableobject_pkg.GetSidFromPath(
						v_act_id, 
						security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'menu/admin'), 
						'csr_meter_admin'
					);
			END;

			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_sid), -1,
					security.security_pkg.ACE_TYPE_ALLOW,
					security.security_pkg.ACE_FLAG_DEFAULT,
					v_admins_sid,
					security.security_pkg.PERMISSION_STANDARD_ALL);

			security.acl_pkg.PropogateACEs(v_act_id, v_menu_sid);

			/*** ADD WEB RESOURCE ***/
			v_wwwroot_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'wwwroot');
			v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_wwwroot_sid, 'csr/site/meter');

			BEGIN
				security.web_pkg.CreateResource(v_act_id, v_wwwroot_sid, v_www_csr_site, 'admin', v_www_sid);
			EXCEPTION
				WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
					v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'admin');
			END;
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_sid), -1,
					security.security_pkg.ACE_TYPE_ALLOW,
					security.security_pkg.ACE_FLAG_DEFAULT,
					v_admins_sid,
					security.security_pkg.PERMISSION_STANDARD_ALL);
		EXCEPTION
			WHEN others THEN
				NULL; -- don't mind if they don't have the normal menu structures/group etc.
		END;
	END LOOP;
	
	security.user_pkg.LogonAdmin;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
