-- Please update version.sql too -- this keeps clean builds in sync
define version=1202
@update_header

CREATE SEQUENCE CT.SUPPLIER_CONTACT_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    noorder;

CREATE TABLE CT.SUPPLIER_CONTACT (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    SUPPLIER_ID NUMBER(10) NOT NULL,
    SUPPLIER_CONTACT_ID NUMBER(10) NOT NULL,
    USER_SID NUMBER(10),
    FULL_NAME VARCHAR2(1000) NOT NULL,
    EMAIL VARCHAR2(1000) NOT NULL,
    CONSTRAINT PK_SUPPLIER_CONTACT PRIMARY KEY (APP_SID, SUPPLIER_ID, SUPPLIER_CONTACT_ID)
);

ALTER TABLE CT.SUPPLIER_CONTACT ADD CONSTRAINT SUPPLIER_SUPPLIER_CONTACT 
    FOREIGN KEY (APP_SID, SUPPLIER_ID) REFERENCES CT.SUPPLIER (APP_SID,SUPPLIER_ID);


ALTER TABLE CT.SUPPLIER DROP CONSTRAINT COMPANY_SUPPLIER_2;

ALTER TABLE CT.SUPPLIER ADD CONSTRAINT CHAIN_COMPANY_SUPPLIER 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CHAIN.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.SUPPLIER_CONTACT ADD CONSTRAINT CHAIN_USER_SUPPLIER_CONTACT 
    FOREIGN KEY (APP_SID, USER_SID) REFERENCES CHAIN.CHAIN_USER (APP_SID,USER_SID);

-- add excel resource
DECLARE
	v_act_id 					security.security_pkg.T_ACT_ID;
	v_reg_users_sid				security.security_pkg.T_SID_ID;
	v_www_root					security.security_pkg.T_SID_ID;
	v_www_csr_site				security.security_pkg.T_SID_ID;
	v_www_csr_site_excel		security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin();
	v_act_id := security.security_pkg.GetAct();
	
	FOR r IN (
		SELECT app_sid FROM csr.customer
	)
	LOOP
		v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'wwwroot');
		BEGIN
			v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_root, 'csr/site');
		
			BEGIN
				v_www_csr_site_excel := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_www_csr_site, 'excel');
			EXCEPTION 
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_csr_site, 'excel', v_www_csr_site_excel);	
					
					-- give the RegisteredUsers group READ permission on the resource
					security.acl_pkg.AddACE(
						v_act_id, 
						security.acl_pkg.GetDACLIDForSID(v_www_csr_site_excel), 
						security.security_pkg.ACL_INDEX_LAST, 
						security.security_pkg.ACE_TYPE_ALLOW,
						security.security_pkg.ACE_FLAG_DEFAULT, 
						security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'Groups/RegisteredUsers'), 
						security.security_pkg.PERMISSION_STANDARD_READ
					);	
			END;
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
	END LOOP;
END;
/

-- fixup/cleanup
BEGIN
	security.user_pkg.logonadmin();
	
	UPDATE chain.customer_options SET site_name = 'Value Chain Hotspotter', default_url = NULL WHERE app_sid IN (SELECT app_sid FROM ct.customer_options);
	
	FOR r IN (
		SELECT breakdown_type_id FROM ct.breakdown_type WHERE company_sid IS NULL
	)
	LOOP
		
		DELETE FROM ct.hotspot_result
		 WHERE breakdown_id IN (SELECT breakdown_id FROM ct.breakdown WHERE breakdown_type_id = r.breakdown_type_id);

		DELETE FROM ct.breakdown_region_eio
		 WHERE breakdown_id IN (SELECT breakdown_id FROM ct.breakdown WHERE breakdown_type_id = r.breakdown_type_id);

		DELETE FROM ct.bt_profile 
		 WHERE breakdown_group_id IN (	
			SELECT breakdown_group_id 
			  FROM ct.breakdown_group
			 WHERE app_sid = app_sid
			   AND breakdown_type_id = r.breakdown_type_id
		);

		DELETE FROM ct.bt_emissions
		 WHERE breakdown_id IN (SELECT breakdown_id FROM ct.breakdown WHERE breakdown_type_id = r.breakdown_type_id);

		DELETE FROM ct.ec_car_entry
		 WHERE breakdown_group_id IN (	
			SELECT breakdown_group_id 
			  FROM ct.breakdown_group
			 WHERE app_sid = app_sid
			   AND breakdown_type_id = r.breakdown_type_id
		);

		DELETE FROM ct.ec_bus_entry
		 WHERE breakdown_group_id IN (	
			SELECT breakdown_group_id 
			  FROM ct.breakdown_group
			 WHERE app_sid = app_sid
			   AND breakdown_type_id = r.breakdown_type_id
		);

		DELETE FROM ct.ec_train_entry
		 WHERE breakdown_group_id IN (	
			SELECT breakdown_group_id 
			  FROM ct.breakdown_group
			 WHERE app_sid = app_sid
			   AND breakdown_type_id = r.breakdown_type_id
		);

		DELETE FROM ct.ec_motorbike_entry
		 WHERE breakdown_group_id IN (	
			SELECT breakdown_group_id 
			  FROM ct.breakdown_group
			 WHERE app_sid = app_sid
			   AND breakdown_type_id = r.breakdown_type_id
		);

		DELETE FROM ct.ec_profile 
		 WHERE breakdown_group_id IN (	
			SELECT breakdown_group_id 
			  FROM ct.breakdown_group
			 WHERE app_sid = app_sid
			   AND breakdown_type_id = r.breakdown_type_id
		);

		DELETE FROM ct.ec_emissions
		 WHERE breakdown_id IN (SELECT breakdown_id FROM ct.breakdown WHERE breakdown_type_id = r.breakdown_type_id);

		DELETE FROM ct.breakdown_region_group 
		 WHERE breakdown_id IN (SELECT breakdown_id FROM ct.breakdown WHERE breakdown_type_id = r.breakdown_type_id);

		DELETE FROM ct.breakdown_group
		 WHERE breakdown_type_id = r.breakdown_type_id;

		/* TO DO - there are more things that will need to be cleared here before deleting breakdown_region (questionnaires etc) when implemented */
		DELETE FROM ct.ec_questionnaire
		 WHERE breakdown_id IN (SELECT breakdown_id FROM ct.breakdown WHERE breakdown_type_id = r.breakdown_type_id);	

		DELETE FROM ct.breakdown_region
		 WHERE breakdown_id IN (SELECT breakdown_id FROM ct.breakdown WHERE breakdown_type_id = r.breakdown_type_id);

		DELETE FROM ct.breakdown
		 WHERE breakdown_type_id = r.breakdown_type_id;

		DELETE FROM ct.bt_options
		 WHERE breakdown_type_id = r.breakdown_type_id;

		DELETE FROM ct.ec_options
		 WHERE breakdown_type_id = r.breakdown_type_id;

		DELETE FROM ct.ps_options
		 WHERE breakdown_type_id = r.breakdown_type_id;

		DELETE FROM ct.ps_item
		 WHERE breakdown_id IN (SELECT breakdown_id FROM ct.breakdown WHERE breakdown_type_id = r.breakdown_type_id);	

		DELETE FROM ct.breakdown_type
		 WHERE breakdown_type_id = r.breakdown_type_id;
	END LOOP;
	
	
END;
/

ALTER TABLE CT.BREAKDOWN_TYPE MODIFY COMPANY_SID NOT NULL;

-- security tweaks
BEGIN
	security.user_pkg.logonadmin;
	
	FOR r IN (
		SELECT c.host FROM csr.customer c, ct.customer_options co WHERE co.app_sid = c.app_sid
	) LOOP
	
		security.user_pkg.logonadmin(r.host);
	
		DECLARE
			v_act_id 					security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
			v_app_sid 					security.security_pkg.T_SID_ID DEFAULT security.security_pkg.GetApp;
			v_groups_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
			v_www_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
			v_menu						security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu');
			v_hu_group					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Hotspot Users');
			v_sa_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');
			v_rhu_group					security.security_pkg.T_SID_ID;
			v_ct_site_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site/ct');
			v_ct_hs_site_sid			security.security_pkg.T_SID_ID;
			v_ct_hs_m_site_sid			security.security_pkg.T_SID_ID;
			v_ct_mgmt_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_ct_site_sid, 'management');
			v_hotspot_menu				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'hotspot_dashboard');
			--v_admin_menu				security.security_pkg.T_SID_ID;
			--v_template_upload_menu		security.security_pkg.T_SID_ID;
			--v_demo_menu					security.security_pkg.T_SID_ID;
			--v_setup_menu				security.security_pkg.T_SID_ID;
			--v_hs_wiz_menu				security.security_pkg.T_SID_ID;
			v_hs_breakdown_menu			security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_hotspot_menu, 'breakdown');
			v_hs_report_menu			security.security_pkg.T_SID_ID;
			--v_about_menu				security.security_pkg.T_SID_ID;
			--v_data_menu					security.security_pkg.T_SID_ID;
			--v_analysis_menu				security.security_pkg.T_SID_ID;
			--v_chain_menu				security.security_pkg.T_SID_ID;
			--v_manage_templates			security.security_pkg.T_SID_ID;
		
		BEGIN
			security.group_pkg.CreateGroup(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Restricted Hotspot Users', v_rhu_group);
			-- Add hotspot users group to the restricted hotspot users group
			security.group_pkg.AddMember(v_act_id, v_hu_group, v_rhu_group);

			-- remove the hotspot user group permissions
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_site_sid), v_hu_group);
			security.acl_pkg.ResetDescendantACLs(v_act_id, v_ct_site_sid);
			-- add the restricted hotspot user group permissions
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_site_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_rhu_group, security.security_pkg.PERMISSION_STANDARD_READ);	

			-- don't inherit dacls
			security.securableobject_pkg.SetFlags(v_act_id, v_ct_mgmt_sid, 0);
			-- clean existing ACE's
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_mgmt_sid));

			-- give SuperAdmins group READ permission on the resource - everyone else is blocked
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_mgmt_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_INHERITABLE, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_READ);	
			
			-- add new web resources
			BEGIN
				v_ct_hs_site_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_ct_site_sid, 'hotspotter');
			EXCEPTION 
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.web_pkg.CreateResource(v_act_id, v_www_sid, v_ct_site_sid, 'hotspotter', v_ct_hs_site_sid);	
			END;

			BEGIN
				v_ct_hs_m_site_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_ct_hs_site_sid, 'manage');
			EXCEPTION 
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.web_pkg.CreateResource(v_act_id, v_www_sid, v_ct_hs_site_sid, 'manage', v_ct_hs_m_site_sid);	

					-- don't inherit dacls
					security.securableobject_pkg.SetFlags(v_act_id, v_ct_hs_m_site_sid, 0);
					-- clean existing rhu sid
					security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_hs_m_site_sid), v_rhu_group);
					
					-- give the rhu group READ permission on the resource
					security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_hs_m_site_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
						security.security_pkg.ACE_FLAG_DEFAULT, v_hu_group, security.security_pkg.PERMISSION_STANDARD_READ);	
			END;

			-- remove the hotspot user permissions
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_hotspot_menu), v_hu_group);
			security.acl_pkg.ResetDescendantACLs(v_act_id, v_hotspot_menu);
			-- add the restricted hotspot user group permissions
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_hotspot_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_rhu_group, security.security_pkg.PERMISSION_STANDARD_READ);	
							
			BEGIN
				v_hs_report_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_hotspot_menu, 'reports');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(v_act_id, v_hotspot_menu, 'reports',  'Hotspot reports',  '/csr/site/ct/hotspotter/manage/reportdownload.acds',  0, null, v_hs_report_menu);
			END;
			
			-- don't inherit dacls
			security.securableobject_pkg.SetFlags(v_act_id, v_hs_breakdown_menu, 0);
			-- clean existing rhu sid
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_hs_breakdown_menu), v_rhu_group);
			-- add hotspot user permissions
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_hs_breakdown_menu), -1, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_hu_group, security.security_pkg.PERMISSION_STANDARD_READ);

			-- don't inherit dacls
			security.securableobject_pkg.SetFlags(v_act_id, v_hs_report_menu, 0);
			-- clean existing rhu sid
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_hs_report_menu), v_rhu_group);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_hs_report_menu), -1, security.security_pkg.ACE_TYPE_ALLOW, 
					security.security_pkg.ACE_FLAG_DEFAULT, v_hu_group, security.security_pkg.PERMISSION_STANDARD_READ);
		
			UPDATE security.menu SET action = '/csr/site/ct/hotspotter/manage/breakdownmanager.acds' WHERE sid_id = v_hs_breakdown_menu;
			UPDATE security.menu SET action = '/csr/site/ct/hotspotter/manage/reportdownload.acds' WHERE sid_id = v_hs_report_menu;		
			
		END;
	END LOOP;
END;
/

CREATE TABLE CSR.TMP_SID_MAP (HU_SID NUMBER(10), RHU_SID NUMBER(10));

BEGIN
	INSERT INTO CSR.TMP_SID_MAP (hu_sid, rhu_sid)
	SELECT hu.sid_id, rhu.sid_id rhu_sid 
	  FROM security.securable_object hu, security.securable_object rhu 
	 WHERE hu.name = 'Hotspot Users'
	   AND rhu.name = 'Restricted Hotspot Users'
	   AND hu.parent_sid_id = rhu.parent_sid_id;

	UPDATE csr.tab_group tg
	   SET group_sid = (
	   		SELECT rhu_sid
	   		  FROM csr.tmp_sid_map m
	   		 WHERE m.hu_sid = tg.group_sid
	   )
	 WHERE group_sid IN (SELECT hu_sid FROM csr.tmp_sid_map);
END;
/

DROP TABLE CSR.TMP_SID_MAP;

GRANT EXECUTE ON CHAIN.COMPANY_USER_PKG TO CT;

@..\ct\breakdown_type_pkg
@..\ct\hotspot_pkg
@..\ct\util_pkg
@..\ct\supplier_pkg

@..\ct\breakdown_body
@..\ct\breakdown_type_body
@..\ct\hotspot_body
@..\ct\link_body
@..\ct\util_body
@..\ct\supplier_body

@update_tail
