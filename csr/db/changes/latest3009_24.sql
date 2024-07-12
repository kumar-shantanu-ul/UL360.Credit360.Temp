-- Please update version.sql too -- this keeps clean builds in sync
define version=3009
define minor_version=24
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
-- Move Initiative admin menu item from Admin to Setup if exists.
DECLARE
	v_act_id			security.security_pkg.T_ACT_ID;
	v_app_sid			security.security_pkg.T_SID_ID;
	v_setup_menu_sid	security.security_pkg.T_SID_ID;
	v_init_admin		security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAdmin(NULL);
	
	FOR r IN (
		SELECT c.app_sid, c.host, so.sid_id
		  FROM security.menu m 
		  JOIN security.securable_object so ON m.sid_id = so.sid_id 
		  JOIN csr.customer c ON so.application_sid_id = c.app_sid
		 WHERE LOWER(m.action) = '/csr/site/initiatives/admin/menu.acds'
	)
	LOOP
		security.user_pkg.LogonAdmin(r.host);
		v_act_id := security.security_pkg.GetAct;
		v_app_sid := security.security_pkg.GetApp;
		
		v_setup_menu_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu/setup');
		
		UPDATE security.securable_object
		   SET parent_sid_id = v_setup_menu_sid
		 WHERE sid_id = r.sid_id;
	END LOOP;
	
	security.user_pkg.LogonAdmin(NULL);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@@..\enable_body

@update_tail
