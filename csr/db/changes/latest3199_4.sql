-- Please update version.sql too -- this keeps clean builds in sync
define version=3199
define minor_version=4
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
			v_menu						security.security_pkg.T_SID_ID;
			v_clientconnect_menu		security.security_pkg.T_SID_ID;
			v_support_menu				security.security_pkg.T_SID_ID;
			v_other_menu				security.security_pkg.T_SID_ID;
			v_admin_menu				security.security_pkg.T_SID_ID;
		BEGIN
			v_act_id := security.security_pkg.GetAct;
			v_app_sid := security.security_pkg.GetApp;

			v_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu');


			BEGIN
				v_clientconnect_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'client_connect');
				security.securableobject_pkg.DeleteSO(v_act_id, v_clientconnect_menu);
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
			END;

			BEGIN
				-- client_connect on these sites is not at the top level menu
				--crdemo.credit360.com (other)
				--cr360.credit360.com (other)
				--techsupport.credit360.com (other)
				--tsupport.credit360.com (other)
				v_other_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'other');
				v_clientconnect_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_other_menu, 'client_connect');
				security.securableobject_pkg.DeleteSO(v_act_id, v_clientconnect_menu);
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
			END;


			BEGIN
				v_support_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'support');
				security.securableobject_pkg.DeleteSO(v_act_id, v_support_menu);
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
			END;

			BEGIN
				-- support (/owl/support/overview.acds) on these sites is not at the top level menu
				--mcdonalds-nalc.credit360.com (admin)
				v_admin_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'admin');
				v_support_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'support');
				security.securableobject_pkg.DeleteSO(v_act_id, v_support_menu);
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
			END;

		END;
	END LOOP;

	-- clear the app_sid
	security.user_pkg.logonadmin;
END;
/





-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
