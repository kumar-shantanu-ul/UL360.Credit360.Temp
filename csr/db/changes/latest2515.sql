-- Please update version.sql too -- this keeps clean builds in sync
define version=2515
@update_header

--Make nullable as we null the owner when user is deleted, rather than delete it. Support added for 'ownerless' schedules
ALTER TABLE CSR.TPL_REPORT_SCHEDULE modify (owner_user_sid NULL);

update csr.region_selection_type set label = 'properties'           where region_selection_type_id = 0;
update csr.region_selection_type set label = 'meters'               where region_selection_type_id = 1;
update csr.region_selection_type set label = 'leaf nodes'           where region_selection_type_id = 2;
update csr.region_selection_type set label = 'children'             where region_selection_type_id = 3;
update csr.region_selection_type set label = 'countries'            where region_selection_type_id = 4;
update csr.region_selection_type set label = 'sites tagged'         where region_selection_type_id = 5;
update csr.region_selection_type set label = 'selected items only'  where region_selection_type_id = 6;

-- New capability for managing all settings (changing ownership, etc)
INSERT INTO csr.capability (name, allow_by_default) VALUES ('Manage all templated report settings', 0);

-- Add new "My report" page to the admin menu for all clients who have Word2 templated reports enabled
BEGIN
	security.user_pkg.logonadmin;
	
	FOR r IN (
		SELECT c.host 
		  FROM security.menu m, security.securable_object so, csr.customer c, security.website w
		 WHERE LOWER(m.action) LIKE '%word2/reports.acds'
		   AND m.SID_ID = so.SID_ID
		   AND so.APPLICATION_SID_ID = c.APP_SID
       AND LOWER(c.host) = LOWER(w.website_name)
	) LOOP
	
		security.user_pkg.logonadmin(r.host);
	
		DECLARE
			v_act_id 					security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
			v_app_sid 					security.security_pkg.T_SID_ID DEFAULT security.security_pkg.GetApp;
			v_menu						security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu');
			v_reg_users_sid  			security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.getsidfrompath(v_act_id, v_app_sid, 'Groups/RegisteredUsers');
			v_admin_menu				security.security_pkg.T_SID_ID;
			v_myreports_menu			security.security_pkg.T_SID_ID;
			
		BEGIN
			v_admin_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'Admin');
			
			BEGIN
				v_myreports_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'csr_site_reports_word_myreports');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'csr_site_reports_word_myreports',  'My reports',  '/csr/site/reports/word2/myreports.acds',  0, null, v_myreports_menu);
			END;
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_myreports_menu), -1, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			
		END;
	END LOOP;
	
	COMMIT;
END;
/

@../csr_user_body
@../doc_pkg
@../doc_body
@../region_picker_pkg
@../region_picker_body
@../templated_report_pkg
@../templated_report_body
@../templated_report_schedule_pkg
@../templated_report_schedule_body

@update_tail