-- Please update version.sql too -- this keeps clean builds in sync
define version=3128
define minor_version=0
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
DECLARE
	v_new_menu_sid security.security_pkg.t_sid_id;
	v_groups_sid security.security_pkg.t_sid_id;
	v_admins_group_sid security.security_pkg.t_sid_id;
	v_admin_menu_sid security.security_pkg.t_sid_id;
	v_act_id security.security_pkg.t_act_id;
BEGIN
	security.user_pkg.logonadmin;
	FOR r IN (
		SELECT host, app_sid
		  FROM csr.customer
		 WHERE LOWER(host) IN (
			SELECT LOWER(website_name)
			  FROM security.website
			)
	) LOOP
		security.user_pkg.logonadmin(r.host);
		v_act_id := security.security_pkg.getAct;
		BEGIN
			v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'Groups');
			v_admins_group_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
			v_admin_menu_sid := security.securableobject_pkg.getsidfrompath(null, r.app_sid, 'menu/admin');
			v_new_menu_sid := NULL;
			BEGIN
				v_new_menu_sid := security.securableobject_pkg.getsidfrompath(NULL, r.app_sid, 'menu/admin/csr_admin_jobs');
			EXCEPTION
				WHEN security.security_pkg.object_not_found THEN
					NULL;
			END;
			IF v_new_menu_sid IS NULL THEN
				security.menu_pkg.createMenu(v_act_id,
				v_admin_menu_sid, 'csr_admin_jobs', 'Batch jobs', '/csr/site/admin/jobs/jobs.acds', -1, null, v_new_menu_sid);
				--security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_new_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
				--security.security_pkg.ACE_FLAG_DEFAULT, v_admins_group_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			END IF;
		EXCEPTION
			WHEN security.security_pkg.object_not_found THEN
				NULL;
		END;
		security.user_pkg.logonadmin;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
