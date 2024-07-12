-- Please update version.sql too -- this keeps clean builds in sync
define version=2773
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- already has data_explorer_show_markers
ALTER TABLE csr.customer ADD data_explorer_show_ranking    NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE csr.customer ADD data_explorer_show_trends     NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE csr.customer ADD data_explorer_show_scatter    NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE csr.customer ADD data_explorer_show_radar      NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE csr.customer ADD data_explorer_show_gauge      NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE csr.customer ADD data_explorer_show_waterfall  NUMBER(1, 0) DEFAULT 0 NOT NULL;

-- constraints
ALTER TABLE csr.customer DROP CONSTRAINT CK_CUST_SHOW_DE_MARKERS; -- drop and recreate for better naming

ALTER TABLE csr.customer ADD CONSTRAINT ck_cust_de_show_markers CHECK (data_explorer_show_markers IN (0, 1));
ALTER TABLE csr.customer ADD CONSTRAINT ck_cust_de_show_ranking CHECK (data_explorer_show_ranking IN (0, 1));
ALTER TABLE csr.customer ADD CONSTRAINT ck_cust_de_show_trends CHECK (data_explorer_show_trends IN (0, 1));
ALTER TABLE csr.customer ADD CONSTRAINT ck_cust_de_show_scatter CHECK (data_explorer_show_scatter IN (0, 1));
ALTER TABLE csr.customer ADD CONSTRAINT ck_cust_de_show_radar CHECK (data_explorer_show_radar IN (0, 1));
ALTER TABLE csr.customer ADD CONSTRAINT ck_cust_de_show_gauge CHECK (data_explorer_show_gauge IN (0, 1));
ALTER TABLE csr.customer ADD CONSTRAINT ck_cust_de_show_waterfall CHECK (data_explorer_show_waterfall IN (0, 1));

-- same again for csrimp

ALTER TABLE csrimp.customer ADD data_explorer_show_ranking    NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE csrimp.customer ADD data_explorer_show_trends     NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE csrimp.customer ADD data_explorer_show_scatter    NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE csrimp.customer ADD data_explorer_show_radar      NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE csrimp.customer ADD data_explorer_show_gauge      NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE csrimp.customer ADD data_explorer_show_waterfall  NUMBER(1, 0) DEFAULT 0 NOT NULL;

ALTER TABLE csrimp.customer DROP CONSTRAINT CK_CUST_SHOW_DE_MARKERS; -- drop and recreate for better naming

ALTER TABLE csrimp.customer ADD CONSTRAINT ck_cust_de_show_markers CHECK (data_explorer_show_markers IN (0, 1));
ALTER TABLE csrimp.customer ADD CONSTRAINT ck_cust_de_show_ranking CHECK (data_explorer_show_ranking IN (0, 1));
ALTER TABLE csrimp.customer ADD CONSTRAINT ck_cust_de_show_trends CHECK (data_explorer_show_trends IN (0, 1));
ALTER TABLE csrimp.customer ADD CONSTRAINT ck_cust_de_show_scatter CHECK (data_explorer_show_scatter IN (0, 1));
ALTER TABLE csrimp.customer ADD CONSTRAINT ck_cust_de_show_radar CHECK (data_explorer_show_radar IN (0, 1));
ALTER TABLE csrimp.customer ADD CONSTRAINT ck_cust_de_show_gauge CHECK (data_explorer_show_gauge IN (0, 1));
ALTER TABLE csrimp.customer ADD CONSTRAINT ck_cust_de_show_waterfall CHECK (data_explorer_show_waterfall IN (0, 1));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.source_type_error_code
   SET detail_url = '/csr/site/dataExplorer5/dataNavigator/dataNavigator.acds?valId=%VALID%'
 WHERE detail_url = '/csr/site/dataExplorer4/dataNavigator/dataNavigator.acds?valId=%VALID%';

DELETE FROM csr.module
 WHERE module_id = 31
   AND module_name = 'Data explorer 5'
   AND enable_sp = 'EnableDE5';

UPDATE mtdata.metadata
   SET clob_value = REPLACE(clob_value, 'dataExplorer4', 'dataExplorer5')
 WHERE dbms_lob.instr(clob_value, 'dataExplorer4') > 0;

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
			v_admin_menu				security.security_pkg.T_SID_ID;
			v_chartfeatures_menu		security.security_pkg.T_SID_ID;
			--
			v_wwwroot_sid				security.security_pkg.T_SID_ID;
			v_www_csr_site				security.security_pkg.T_SID_ID;
			v_old_www_sid				security.security_pkg.T_SID_ID;
			v_new_www_sid				security.security_pkg.T_SID_ID;
			--
			v_was_de4					BOOLEAN;
		BEGIN
			v_act_id := security.security_pkg.GetAct;
			v_app_sid := security.security_pkg.GetApp;

			-- ... create the new "Admin | Optional chart features" menu ...
			v_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu');

			BEGIN
				v_admin_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'Admin');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(v_act_id, v_menu, 'admin',  'Admin',  '/csr/site/userSettings.acds',  0, null, v_admin_menu);
			END;

			BEGIN
				v_chartfeatures_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'csr_admin_optional_chart_features');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'csr_admin_optional_chart_features',  'Optional chart features',  '/csr/site/admin/dataExplorer/chartFeatures.acds',  12, null, v_chartfeatures_menu);
			END;

			-- ... upgrade site from DE4 to DE5 ...
			BEGIN
				v_wwwroot_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
				v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_wwwroot_sid, 'csr/site');
				v_old_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'dataExplorer4');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					GOTO CONTINUE; -- nothing to upgrade so this loop's work is done
			END;

			v_was_de4 := FALSE;
			BEGIN
				security.web_pkg.CreateResource(v_act_id, v_wwwroot_sid, v_www_csr_site, 'dataExplorer5', v_new_www_sid);

				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_new_www_sid));
				FOR r IN (
					SELECT a.acl_id, a.acl_index, a.ace_type, a.ace_flags, a.permission_set, a.sid_id
					  FROM security.securable_object so
					  JOIN security.acl a ON so.dacl_id = a.acl_id
					 WHERE so.sid_id = v_old_www_sid
					 ORDER BY acl_index
				)
				LOOP
					security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_new_www_sid), r.acl_index,
						r.ace_type, r.ace_flags, r.sid_id, r.permission_Set);
				END LOOP;
			EXCEPTION
				WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
					NULL;
			END;

			FOR r IN (
				SELECT m.sid_id, REPLACE(lower(m.action), 'dataexplorer4/explorer.acds', 'dataexplorer5/explorer.acds') new_action
				  FROM security.menu m
				  JOIN SECURITY.SECURABLE_OBJECT so ON so.SID_ID = m.SID_ID
				 WHERE LOWER(m.ACTION) LIKE '%dataexplorer4/explorer.acds'
				   AND so.APPLICATION_SID_ID = v_app_sid
			)
			LOOP
				security.menu_pkg.SetMenuAction(v_act_id, r.sid_id, r.new_action);
				v_was_de4 := TRUE;
			END LOOP;

			-- ... enable all the optional settings for existing DE5 users
			IF NOT v_was_de4 THEN
				UPDATE csr.customer
				   SET data_explorer_show_ranking = 1,
				       data_explorer_show_markers = 1,
					   data_explorer_show_trends = 1,
					   data_explorer_show_scatter = 1,
					   data_explorer_show_radar = 1,
					   data_explorer_show_gauge = 1,
					   data_explorer_show_waterfall = 1
				 WHERE app_sid = v_app_sid;
			END IF;
		END;

		<<CONTINUE>> NULL; 
	END LOOP;

	-- clear the app_sid
	security.user_pkg.logonadmin;
END;
/

-- ** New package grants **

-- *** Packages ***

@../delegation_pkg
@../enable_pkg
@../delegation_body
@../deleg_plan_body
@../enable_body
@../schema_body
@../csr_app_body
@../csrimp/imp_body
@../chain/setup_body

@update_tail
