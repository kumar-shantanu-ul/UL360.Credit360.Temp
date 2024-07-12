-- Please update version.sql too -- this keeps clean builds in sync
define version=2779
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
BEGIN
	-- For all sites...
	security.user_pkg.logonadmin;

	FOR r IN (
		SELECT app_sid, host
		  FROM csr.customer c, security.website w
		 WHERE c.host = w.website_name
	) LOOP
		security.user_pkg.logonadmin(r.host);

		DECLARE
			v_act_id 					security.security_pkg.T_ACT_ID;
			v_app_sid 					security.security_pkg.T_SID_ID;
			v_chartfeatures_menu		security.security_pkg.T_SID_ID;
		BEGIN
			v_act_id := security.security_pkg.GetAct;
			v_app_sid := security.security_pkg.GetApp;

			BEGIN
				v_chartfeatures_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Menu/admin/csr_admin_optional_chart_features');

				-- don't inherit dacls
				security.securableobject_pkg.SetFlags(v_act_id, v_chartfeatures_menu, 0);
				-- remove inherited ones
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_chartfeatures_menu));
				-- add Administrators read permission
				security.acl_pkg.AddACE(
					v_act_id,
					security.acl_pkg.GetDACLIDForSID(v_chartfeatures_menu),
					security.security_pkg.ACL_INDEX_LAST,
					security.security_pkg.ACE_TYPE_ALLOW,
					security.security_pkg.ACE_FLAG_DEFAULT,
					security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'Groups/Administrators'),
					security.security_pkg.PERMISSION_STANDARD_READ
				);
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					NULL;
			END;
		END;
	END LOOP;

	security.user_pkg.logonadmin;
END;
/
 
-- ** New package grants **

-- *** Packages ***

@update_tail
