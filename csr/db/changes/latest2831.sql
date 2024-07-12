define version=2831
define minor_version=0
define is_combined=1
@update_header

CREATE TABLE chain.capability_flow_capability (
	app_sid					NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	flow_capability_id		NUMBER(10, 0) NOT NULL,
	capability_id			NUMBER(10, 0) NOT NULL,
	CONSTRAINT pk_cap_flow_cap PRIMARY KEY (app_sid, flow_capability_id, capability_id),
	CONSTRAINT uk_cap_flow_cap_capability UNIQUE (app_sid, capability_id),
	CONSTRAINT fk_cap_flow_cap_capability FOREIGN KEY (capability_id) REFERENCES chain.capability (capability_id)
);
CREATE TABLE CSRIMP.CHAIN_CAPABILITY_FLOW_CAP (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	FLOW_CAPABILITY_ID NUMBER(10,0) NOT NULL,
	CAPABILITY_ID NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_CHAIN_CAPABI_FLOW_CAPABI PRIMARY KEY (CSRIMP_SESSION_ID, FLOW_CAPABILITY_ID, CAPABILITY_ID),
	CONSTRAINT FK_CHAIN_CAPABI_FLOW_CAPABI_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
ALTER TABLE csr.auto_exp_filecreate_dsv
ADD secondary_delimiter_id NUMBER(10);
ALTER TABLE csr.auto_exp_filecreate_dsv
ADD CONSTRAINT fk_auto_exp_second_delimiter FOREIGN KEY (secondary_delimiter_id) REFERENCES csr.auto_exp_imp_dsv_delimiters(delimiter_id);
ALTER TABLE csr.automated_export_class
MODIFY period_span_pattern_id NUMBER(10) NULL;

ALTER TABLE csrimp.chain_company ADD (
	DEACTIVATED_DTM	DATE
);
DECLARE
	v_count			NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tables
	 WHERE UPPER(owner) = 'CSRIMP'
	   AND UPPER(table_name) = 'MAP_PLUGIN_TYPE';
	
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE
			'CREATE TABLE csrimp.map_plugin_type ('||
			'    CSRIMP_SESSION_ID		NUMBER(10) DEFAULT SYS_CONTEXT(''SECURITY'', ''CSRIMP_SESSION_ID'') NOT NULL,'||
			'    old_plugin_type_id		NUMBER(10) NOT NULL,'||
			'    new_plugin_type_id		NUMBER(10) NOT NULL,'||
			'    CONSTRAINT pk_map_plugin_type_id PRIMARY KEY (csrimp_session_id, old_plugin_type_id) USING INDEX,'||
			'    CONSTRAINT uk_map_plugin_type_id UNIQUE (csrimp_session_id, new_plugin_type_id) USING INDEX,'||
			'    CONSTRAINT fk_map_plugin_type_is FOREIGN KEY'||
			'        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)'||
			'        ON DELETE CASCADE'||
			')';
	ELSE
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.MAP_PLUGIN_TYPE DROP constraint PK_MAP_PLUGIN_TYPE_ID DROP INDEX';
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.MAP_PLUGIN_TYPE ADD constraint PK_MAP_PLUGIN_TYPE_ID PRIMARY KEY (CSRIMP_SESSION_ID,OLD_PLUGIN_TYPE_ID)';
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.MAP_PLUGIN_TYPE DROP constraint UK_MAP_PLUGIN_TYPE_ID DROP INDEX';
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.MAP_PLUGIN_TYPE ADD constraint UK_MAP_PLUGIN_TYPE_ID UNIQUE (CSRIMP_SESSION_ID,NEW_PLUGIN_TYPE_ID)';
	END IF;
END;
/
BEGIN
	EXECUTE IMMEDIATE 'DROP SEQUENCE csr.STD_MEASURE_CONVERSION_ID_SEQ';
EXCEPTION WHEN OTHERS THEN
	IF (SQLCODE = -2289) THEN
		NULL; -- sequence already deleted
	ELSE
		RAISE;
	END IF;
END;
/
GRANT select, references ON csr.customer_flow_capability TO chain;
grant select, insert, update, delete on csrimp.chain_capability_flow_cap to web_user;
grant select, insert, update on chain.capability_flow_capability to csr;
grant select, insert, update on chain.capability_flow_capability to csrimp;
GRANT EXECUTE ON csr.automated_import_pkg TO security;
GRANT EXECUTE ON csr.automated_export_pkg TO security;

ALTER TABLE chain.capability_flow_capability ADD (
	CONSTRAINT fk_cap_flow_cap_flow_cap FOREIGN KEY (app_sid, flow_capability_id) REFERENCES csr.customer_flow_capability (app_sid, flow_capability_id) ON DELETE CASCADE
);
UPDATE chain.capability SET capability_type_id = 2 WHERE capability_name = 'Deactivate company';
GRANT EXECUTE ON csr.appSidCheck TO chain;
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);
BEGIN
	FOR r IN (
		SELECT object_owner, object_name, policy_name 
		  FROM all_policies 
		 WHERE function IN ('APPSIDCHECK', 'NULLABLEAPPSIDCHECK')
		   AND object_owner = 'CHAIN'
	) LOOP
		dbms_rls.drop_policy(
			object_schema   => 'CHAIN',
			object_name     => r.object_name,
			policy_name     => r.policy_name
		);
        declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin					
					if v_i = 1 then
						v_name := SUBSTR(r.object_name, 1, 23)||'_POLICY';
					else
						v_name := SUBSTR(r.object_name, 1, 21)||'_POLICY_'||v_i;
					end if;
					dbms_output.put_line('doing '||v_name);
				    dbms_rls.add_policy(
				        object_schema   => r.object_owner,
				        object_name     => r.object_name,
				        policy_name     => v_name,
				        function_schema => 'CSR',
				        policy_function => 'appSidCheck',
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.context_sensitive);
				    -- dbms_output.put_line('done  '||v_name);
				  	exit;
				exception
					when policy_already_exists then
						v_i := v_i + 1;
					WHEN FEATURE_NOT_ENABLED THEN
						DBMS_OUTPUT.PUT_LINE('RLS policy '||v_name||' not applied as feature not enabled');
						exit;
				end;
			end loop;
		end;
	END LOOP;
EXCEPTION
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');	
END;
/
DROP FUNCTION chain.nullableAppSidCheck;
DROP FUNCTION chain.appSidCheck;
BEGIN
	-- Log out of any app
	security.user_pkg.LogonAdmin;
END;
/
INSERT INTO csr.region_role_member (app_sid, region_sid, inherited_from_sid, role_sid, user_sid)
WITH rrm AS (
SELECT sr.app_sid, ss.region_sid, ps.region_sid inherited_from_sid, rrm.role_sid, rrm.user_sid
  FROM chain.supplier_relationship sr
  JOIN csr.supplier ps ON sr.app_sid = ps.app_sid AND sr.purchaser_company_sid = ps.company_sid
  JOIN csr.supplier ss ON sr.app_sid = ss.app_sid AND sr.supplier_company_sid = ss.company_sid
  JOIN csr.region_role_member rrm ON ps.app_sid = rrm.app_sid AND ps.region_sid = rrm.region_sid
  JOIN chain.company_type_role ctr ON rrm.app_sid = ctr.app_sid AND rrm.role_sid = ctr.role_sid
 WHERE ps.region_sid IS NOT NULL
   AND ss.region_sid IS NOT NULL
   AND rrm.region_sid = rrm.inherited_from_sid
   AND ctr.cascade_to_supplier = 1
   AND sr.deleted = 0
   AND sr.active = 1
)
SELECT r.app_sid, r.region_sid, rrm.inherited_from_sid, rrm.role_sid, rrm.user_sid
  FROM (
	SELECT app_sid, connect_by_root region_sid root_region_sid, region_sid, active
	  FROM csr.region
	 START WITH region_sid IN (SELECT region_sid FROM rrm)
   CONNECT BY PRIOR app_sid = app_sid AND prior region_sid = parent_sid
	) r
	JOIN rrm ON r.app_sid = rrm.app_sid AND r.root_region_sid = rrm.region_sid
 WHERE r.active = 1
   AND NOT EXISTS (
    SELECT *
      FROM csr.region_role_member
     WHERE app_sid = rrm.app_sid
       AND region_sid = r.region_sid
       AND role_sid = rrm.role_sid
       AND user_sid = rrm.user_sid
   )
;
BEGIN
    FOR r IN (
       	SELECT distinct c.host
		FROM security.menu m
		JOIN security.securable_object so on so.sid_id = m.SID_ID
		JOIN csr.customer c on so.APPLICATION_SID_ID = c.APP_SID
		where action = '/csr/site/audit/browse.acds'
    )
    LOOP
        security.user_pkg.logonadmin(r.host);
        BEGIN
            CSR.ENABLE_PKG.ENABLEAUDITFILTERING();
            dbms_output.put_line( r.host || ' updated to new audits.');
        EXCEPTION
            WHEN security.security_pkg.object_not_found THEN
                 dbms_output.put_line('Error ' || r.host || ' already has new audits enabled.');
        END;
    END LOOP;
	
	security.user_pkg.logonadmin;
 END;
 /
 
INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description, license_warning)
	VALUES (55, 'Campaigns', 'EnableCampaigns', 'Enables campaigns', 1);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
VALUES (5, 'User exporter (dsv)',		'Credit360.AutomatedExportImport.Export.Exporters.Users.UserExporter', 'Credit360.AutomatedExportImport.Export.Exporters.Users.UserDsvOutputter');
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
VALUES (6, 'Groups and roles exporter (dsv)',		'Credit360.AutomatedExportImport.Export.Exporters.GroupsAndRoles.GroupsAndRolesExporter', 'Credit360.AutomatedExportImport.Export.Exporters.GroupsAndRoles.GroupsAndRolesDsvOutputter');
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
VALUES (7, 'User exporter (dsv, Deutsche Bank)',		'Credit360.AutomatedExportImport.Export.Exporters.Users.UserExporter', 'Credit360.AutomatedExportImport.Export.Exporters.Gatekeeper.DeutscheBankUsersDsvOutputter');
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
VALUES (8, 'Groups and roles exporter (dsv, Deutsche Bank)', 'Credit360.AutomatedExportImport.Export.Exporters.GroupsAndRoles.GroupsAndRolesExporter', 'Credit360.AutomatedExportImport.Export.Exporters.Gatekeeper.DeutscheBankEntitlementsDsvOutputter');

UPDATE csr.capability
   SET name = 'Manually import automated import instances'
 WHERE name = 'Manually import CMS data import instances';

BEGIN
	INSERT INTO postcode.country (country, name, latitude, longitude, area_in_sqkm, continent, currency, iso3, is_standard)
	VALUES ('cw', 'Curacao', 12.7, -68.6, 444, 'SA', 'ANG', 'cuw', 1);
EXCEPTION 
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/
BEGIN
	INSERT INTO postcode.country (country, name, latitude, longitude, area_in_sqkm, continent, currency, iso3, is_standard)
	VALUES ('bq', 'Bonaire, Sint Eustatius and Saba', 12.11, -68.14, 328, 'SA', 'USD', 'bes', 1);
EXCEPTION 
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/
BEGIN
	INSERT INTO postcode.country (country, name, latitude, longitude, area_in_sqkm, continent, currency, iso3, is_standard)
	VALUES ('sx', 'Sint Maarten', 18.02, -63.03, 34, 'SA', 'ANG', 'sxm', 1);
EXCEPTION 
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/
DELETE FROM csr.branding_availability
 WHERE lower(client_folder_name) = 'picknpay';
DELETE FROM csr.branding
 WHERE lower(client_folder_name) = 'picknpay';
DELETE FROM csr.branding_availability
 WHERE lower(client_folder_name) in ('dbdms', 't-mobile');
DELETE FROM csr.branding
 WHERE lower(client_folder_name) in ('dbdms', 't-mobile');
BEGIN
  FOR x IN (SELECT t.tab_sid,r.description FROM cms.tab t JOIN cms.fk f ON f.fk_tab_sid =t.tab_sid AND f.r_owner = t.oracle_schema  
            JOIN cms.tab r ON r.tab_sid = f.r_tab_sid WHERE t.oracle_table LIKE 'I$%' AND t.description IS NULL)
  LOOP
    UPDATE cms.tab SET description = x.description || ' Action' WHERE tab_sid = x.tab_sid;
  END LOOP;
END;
/
DELETE FROM csr.branding_availability
 WHERE lower(client_folder_name) IN ('acona', 'allianceboots', 'bclc', 'brooks', 'chipotle', 'coinstar', 'elektro', 'fiep', 'greenlife', 'huawei', 'ma-industries', 'mcnicholas', 'mettlertoledo', 'mtn', 'payroll_giving', 'pearson', 'prologis', 'rim', 'rmenergy', 'taqa', 'td', 'towngas', 'tullowoil', 'ubs', 'uniq', 'vtplc', 'xyz');
DELETE FROM csr.branding
 WHERE lower(client_folder_name) IN ('acona', 'allianceboots', 'bclc', 'brooks', 'chipotle', 'coinstar', 'elektro', 'fiep', 'greenlife', 'huawei', 'ma-industries', 'mcnicholas', 'mettlertoledo', 'mtn', 'payroll_giving', 'pearson', 'prologis', 'rim', 'rmenergy', 'taqa', 'td', 'towngas', 'tullowoil', 'ubs', 'uniq', 'vtplc', 'xyz');
DELETE FROM csr.branding_availability
 WHERE lower(client_folder_name) IN ('2012', 'essent', 'itv', 'mace', 'sustainability', 'telekom');
DELETE FROM csr.branding
 WHERE lower(client_folder_name) IN ('2012', 'essent', 'itv', 'mace', 'sustainability', 'telekom');
DELETE FROM csr.branding_availability
 WHERE lower(client_folder_name) IN ('amwater', 'frontenac', 'gpf', 'idb', 'mectest', 'vancity');
DELETE FROM csr.branding
 WHERE lower(client_folder_name) IN ('amwater', 'frontenac', 'gpf', 'idb', 'mectest', 'vancity');
 
@..\schema_pkg
@..\flow_pkg
@..\chain\type_capability_pkg
@..\chain\filter_pkg
@..\chain\company_filter_pkg
@..\chain\company_pkg
@..\..\..\aspen2\cms\db\filter_pkg
@..\property_report_pkg
@..\non_compliance_report_pkg
@..\initiative_report_pkg
@..\issue_report_pkg
@..\audit_report_pkg
@..\chain\company_type_pkg
@..\quick_survey_pkg
@..\scenario_run_pkg
@..\csr_user_pkg
@..\enable_pkg
@..\automated_export_pkg
@..\chain\helper_pkg
@..\measure_pkg
@..\audit_pkg

@..\schema_body
@..\flow_body
@..\chain\type_capability_body
@..\chain\filter_body
@..\chain\company_filter_body
@..\chain\company_body
@..\chain\business_relationship_body
@..\chain\flow_form_body
@..\chain\report_body
@..\..\..\aspen2\cms\db\filter_body
@..\property_report_body
@..\non_compliance_report_body
@..\initiative_report_body
@..\issue_report_body
@..\audit_report_body
@..\chain\company_type_body
@..\quick_survey_body
@..\chain\company_user_body
@..\region_body
@..\property_body
@..\scenario_run_body
@..\imp_body
@..\delegation_body
@..\csr_user_body
@..\..\..\aspen2\cms\db\tab_body
@..\enable_body
@..\role_body
@..\automated_export_body
@..\csrimp\imp_body
@..\chain\helper_body
@..\chain\setup_body
@..\alert_body
@..\..\..\aspen2\cms\db\cms_tab_body
@..\certificate_body
@..\doc_body
@..\factor_body
@..\indicator_body
@..\issue_body
@..\region_tree_body
@..\measure_body
@..\audit_body
@..\meter_body

@update_tail
