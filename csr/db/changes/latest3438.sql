define version=3438
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;

--Failed to locate all sections of latest3433_1.sql
--Failed to locate all sections of latest3433_2.sql
CREATE TABLE CSR.BASELINE_CONFIG (
	APP_SID						NUMBER(10, 0)  DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	BASELINE_CONFIG_ID			NUMBER(10, 0)  NOT NULL,
	BASELINE_NAME				VARCHAR2(200)  NOT NULL,
	BASELINE_LOOKUP_KEY			VARCHAR2(200)  NOT NULL,
	CONSTRAINT pk_baseline_config PRIMARY KEY (APP_SID, BASELINE_CONFIG_ID),
	CONSTRAINT uk_baseline_lookup_key UNIQUE (APP_SID, BASELINE_CONFIG_ID, BASELINE_LOOKUP_KEY)
);
CREATE SEQUENCE CSR.BASELINE_CONFIG_ID_SEQ CACHE 5;
CREATE TABLE CSR.BASELINE_CONFIG_PERIOD (
	APP_SID								NUMBER(10, 0)   DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	BASELINE_CONFIG_PERIOD_ID			NUMBER(10, 0)   NOT NULL,
	BASELINE_CONFIG_ID					NUMBER(10, 0)   NOT NULL,
	BASELINE_PERIOD_DTM					DATE NOT NULL,
	BASELINE_COVER_PERIOD_START_DTM		DATE,
	BASELINE_COVER_PERIOD_END_DTM		DATE,
	CONSTRAINT pk_baseline_config_period PRIMARY KEY (APP_SID, BASELINE_CONFIG_PERIOD_ID),
	CONSTRAINT fk_bsl_config_period_bsl_config FOREIGN KEY 
			(APP_SID, BASELINE_CONFIG_ID) REFERENCES CSR.BASELINE_CONFIG (APP_SID, BASELINE_CONFIG_ID)
);
CREATE SEQUENCE CSR.BASELINE_CONFIG_PERIOD_ID_SEQ CACHE 5;
create index csr.ix_baseline_conf_baseline_conf on csr.baseline_config_period (app_sid, baseline_config_id);
CREATE TABLE CSRIMP.BASELINE_CONFIG (
	CSRIMP_SESSION_ID			NUMBER(10)  DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	BASELINE_CONFIG_ID			NUMBER(10, 0)  NOT NULL,
	BASELINE_NAME				VARCHAR2(200)  NOT NULL,
	BASELINE_LOOKUP_KEY			VARCHAR2(200)  NOT NULL,
	CONSTRAINT pk_baseline_config PRIMARY KEY (CSRIMP_SESSION_ID, BASELINE_CONFIG_ID),
	CONSTRAINT FK_BASELINE_CONFIG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.BASELINE_CONFIG_PERIOD (
	CSRIMP_SESSION_ID					NUMBER(10)   DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	BASELINE_CONFIG_PERIOD_ID			NUMBER(10, 0)   NOT NULL,
	BASELINE_CONFIG_ID					NUMBER(10, 0)   NOT NULL,
	BASELINE_PERIOD_DTM					DATE NOT NULL,
	BASELINE_COVER_PERIOD_START_DTM		DATE,
	BASELINE_COVER_PERIOD_END_DTM		DATE,
	CONSTRAINT pk_baseline_config_period PRIMARY KEY (CSRIMP_SESSION_ID, BASELINE_CONFIG_PERIOD_ID),
	CONSTRAINT FK_BASELINE_CONFIG_PERIOD_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);


DROP TABLE csr.temp_deleg_plan_overlap;
CREATE GLOBAL TEMPORARY TABLE csr.temp_deleg_plan_overlap
(	
	APP_SID						NUMBER(10)  DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	OVERLAPPING_DELEG_SID		NUMBER(10)  NOT NULL,
	APPLIED_TO_REGION_SID		NUMBER(10)  NOT NULL,
	TPL_DELEG_SID				NUMBER(10)  NOT NULL,
	IS_SYNC_DELEG				NUMBER (1)  NOT NULL,
	REGION_SID					NUMBER(10)	NULL,
	DELEG_PLAN_SID				NUMBER(10)  NULL,
	DELEG_PLAN_COL_DELEG_ID		NUMBER(10)  NULL
)
ON COMMIT PRESERVE ROWS;
CREATE TABLE csr.delegation_batch_job_export 
(
	app_sid 					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL, 
	batch_job_id 				NUMBER(10) NOT NULL, 
	file_blob 					BLOB, 
	file_name 					VARCHAR2(1024), 
	CONSTRAINT pk_bj_deleg PRIMARY KEY (app_sid, batch_job_id)
);
ALTER TABLE csr.region_certificate ADD (
	NOTE							VARCHAR2(2048) NULL,
	SUBMIT_TO_GRESB					NUMBER(1) DEFAULT 0 NOT NULL
);
ALTER TABLE csr.region_certificate DROP CONSTRAINT uk_reg_cert_ext_id;
ALTER TABLE csrimp.region_certificate ADD (
	NOTE							VARCHAR2(2048) NULL,
	SUBMIT_TO_GRESB					NUMBER(1) DEFAULT 0 NOT NULL
);
ALTER TABLE csrimp.region_certificate DROP CONSTRAINT uk_reg_cert_ext_id;
CREATE INDEX csr.ix_region_certif_region_sid ON csr.region_certificate (app_sid, region_sid);
ALTER TABLE csr.est_account_global DROP COLUMN user_name;
ALTER TABLE csr.est_account_global DROP COLUMN password_old;
ALTER TABLE csr.est_account_global DROP COLUMN base_url;


grant select,insert,update,delete on csrimp.baseline_config to tool_user;
grant select,insert,update,delete on csrimp.baseline_config_period to tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON CSR.BASELINE_CONFIG TO CSRIMP;
GRANT SELECT, INSERT, UPDATE, DELETE ON CSR.BASELINE_CONFIG_PERIOD TO CSRIMP;




UPDATE csr.batch_job_type
   SET sp = null,
       plugin_name = 'delegation-plan'
 WHERE batch_job_type_id = 1
 ;
CREATE OR REPLACE VIEW csr.v$est_account AS
	SELECT a.app_sid, a.est_account_sid, a.est_account_id, a.account_customer_id,
		g.connect_job_interval, g.last_connect_job_dtm,
		a.share_job_interval, a.last_share_job_dtm,
		a.building_job_interval, a.meter_job_interval,
		a.auto_map_customer, a.allow_delete
	 FROM csr.est_account a
	 JOIN csr.est_account_global g ON a.est_account_id = g.est_account_id
;




INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter, plugin_type_id)
VALUES (25, 'Quick Chart Export - JSON','Credit360.ExportImport.Automated.Export.Exporters.QuickChart.QuickChartExporter','Credit360.ExportImport.Automated.Export.Exporters.QuickChart.QuickChartJsonOutputter', 0, 5);
	--  Add Web Resource
DECLARE
	v_act_id 					security.security_pkg.T_ACT_ID;
	--
	v_www_root					security.security_pkg.T_SID_ID;
	v_www_resource				security.security_pkg.T_SID_ID;
	v_www_csr_site				security.security_pkg.T_SID_ID;
	v_reg_users_sid				security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, v_act_id);
	FOR r IN (
		SELECT DISTINCT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id IN (
			SELECT app_sid FROM csr.customer
		 )
	)	 
	LOOP
		BEGIN
			v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'wwwroot/csr/site');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				CONTINUE;
		END;
		BEGIN
			v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'wwwroot');
			v_www_resource := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'batchFileDownload');
			CONTINUE;
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
		security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_csr_site, 'batchFileDownload', v_www_resource);
		v_reg_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'Groups/RegisteredUsers');
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_resource), security.security_pkg.ACL_INDEX_LAST,
								security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
								v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END lOOP;
END;
/
BEGIN
	INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) 
		 VALUES ('Enable Delegation Overlap Warning', 0, 
				 'Delegations: Shows an error message when delegation is overlapped while applying Delegation Plan
				  and while synchronising Child delegations');
END;
/
INSERT INTO csr.capability (name, allow_by_default, description)
VALUES ('Baseline calculations', 0, 'Enables configuration of baseline calcuations for scrag++.');
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (125, 'Baseline calculations', 'EnableBaselineCalculations', 'Enable the Baseline calculations settings pages');
INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
VALUES (125, 'State', '0 (disable) or 1 (enable)', 0);
INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
VALUES (125, 'Menu Postion', '-1 (end) or 1 based position', 1);
INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (307,'Period Set',6);
UPDATE csr.module SET warning_msg = 'Please check the customer does not have any custom scenarios as this could break (old) scrag.' WHERE module_id = 125;




CREATE OR REPLACE PACKAGE csr.baseline_pkg AS
    PROCEDURE DUMMY;
END;
/
CREATE OR REPLACE PACKAGE BODY csr.baseline_pkg AS
PROCEDURE DUMMY
AS
    BEGIN
        NULL;
    END;
END;
/
GRANT EXECUTE ON csr.baseline_pkg TO web_user;


@..\delegation_pkg
@..\deleg_plan_pkg
@..\enable_pkg
@..\csr_data_pkg
@..\region_certificate_pkg
@..\baseline_pkg
@..\csrimp\imp_pkg
@..\schema_pkg
@..\energy_star_pkg
@..\indicator_pkg
@..\region_api_pkg


@..\delegation_body
@..\deleg_plan_body
@..\region_api_body
@..\enable_body
@..\period_body
@..\region_certificate_body
@..\schema_body
@..\csrimp\imp_body
@..\baseline_body
@..\csr_data_body
@..\csr_app_body
@..\energy_star_body
@..\indicator_body
@..\recurrence_pattern_body



@update_tail
