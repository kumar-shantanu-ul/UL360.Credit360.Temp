-- Please update version.sql too -- this keeps clean builds in sync
define version=2955
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE cms.form ADD (lookup_key VARCHAR2(255));
ALTER TABLE csrimp.cms_form ADD (lookup_key VARCHAR2(255));

CREATE UNIQUE INDEX cms.ix_form_lkup_key ON cms.form (app_sid, NVL(UPPER(lookup_key), TO_CHAR(form_sid)));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	--Create the menu item for all sites
	security.user_pkg.logonadmin;
	
	FOR r IN (
		SELECT app_sid, host
		  FROM csr.customer c, security.website w
		 WHERE c.host = w.website_name
	) LOOP
	
		security.user_pkg.logonadmin(r.host);
	
		DECLARE
			v_act_id 					security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
			v_app_sid 					security.security_pkg.T_SID_ID DEFAULT security.security_pkg.GetApp;
			v_menu						security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu');
			v_sa_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');
			v_setup_menu				security.security_pkg.T_SID_ID;
			v_forms_admin_menu			security.security_pkg.T_SID_ID;
			
		BEGIN
			BEGIN
				v_setup_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'Setup');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(v_act_id, v_menu, 'setup',  'Setup',  '/csr/site/admin/config/global.acds',  0, null, v_setup_menu);
			END;
		
			BEGIN
				v_forms_admin_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_setup_menu, 'cms_admin_forms');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(v_act_id, v_setup_menu, 'cms_admin_forms',  'CMS form XML manager',  '/fp/cms/admin/forms/list.acds',  0, null, v_forms_admin_menu);
			END;
			
			-- don't inherit dacls
			security.securableobject_pkg.SetFlags(v_act_id, v_forms_admin_menu, 0);
			--Remove inherited ones
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_forms_admin_menu));
			-- Add SA permission
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_forms_admin_menu), -1, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			
		END;
	END LOOP;
	
	security.user_pkg.logonadmin;
	
	UPDATE cms.form 
	   SET form_xml = XMLTYPE(REPLACE(REPLACE(XMLTYPE.getclobval(form_xml), '<select xmlns="http://www.credit360.com/XMLSchemas/cms">', '<select>'),'<form>','<form xmlns="http://www.credit360.com/XMLSchemas/cms">'));
	commit;
	
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../../../aspen2/cms/db/form_pkg
@../../../aspen2/cms/db/form_body
@../../../aspen2/cms/db/tab_body
@../csrimp/imp_body

@update_tail
