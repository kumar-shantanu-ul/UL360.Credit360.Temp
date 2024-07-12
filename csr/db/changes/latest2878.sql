define version=2878
define minor_version=0
define is_combined=1
@update_header

CREATE SEQUENCE csr.auto_importer_settings_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20;
	
CREATE TABLE csr.auto_imp_importer_settings (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	auto_imp_importer_settings_id	NUMBER(10) NOT NULL,
	automated_import_class_sid		NUMBER(10) NOT NULL,
	step_number						NUMBER(10) NOT NULL,
	mapping_xml						SYS.XMLTYPE NOT NULL,
	automated_import_file_type_id	NUMBER(10) NOT NULL,
	dsv_separator					CHAR(1),
	dsv_quotes_as_literals			NUMBER(1),
	excel_worksheet_index			NUMBER(10),
	all_or_nothing					NUMBER(1),
	CONSTRAINT pk_auto_imp_importer_settings PRIMARY KEY (app_sid, auto_imp_importer_settings_id),
	CONSTRAINT ck_auto_imp_settings_quo CHECK (dsv_quotes_as_literals IN (0,1) OR dsv_quotes_as_literals IS NULL),
	CONSTRAINT ck_auto_imp_settings_allorno CHECK (all_or_nothing IN (0,1) OR all_or_nothing IS NULL),
	CONSTRAINT fk_auto_imp_settings_step FOREIGN KEY (app_sid, automated_import_class_sid, step_number) REFERENCES csr.automated_import_class_step(app_sid, automated_import_class_sid, step_number),
	CONSTRAINT uk_auto_imp_settings_step UNIQUE (app_sid, automated_import_class_sid, step_number),
	CONSTRAINT fk_auto_imp_settings_filetype FOREIGN KEY (automated_import_file_type_id) REFERENCES csr.automated_import_file_type(automated_import_file_type_id)
);
CREATE TABLE csr.urjanet_import_instance (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	automated_import_instance_id	NUMBER(10) NOT NULL,
	meter_raw_data_id				NUMBER(10) NOT NULL,
	CONSTRAINT pk_urjanet_import_instance PRIMARY KEY (app_sid, automated_import_instance_id),
	CONSTRAINT fk_uii_aii 
		FOREIGN KEY (app_sid, automated_import_instance_id) 
		REFERENCES csr.automated_import_instance (app_sid, automated_import_instance_id),
	CONSTRAINT fk_uii_mrd
		FOREIGN KEY (app_sid, meter_raw_data_id) 
		REFERENCES csr.meter_raw_data (app_sid, meter_raw_data_id)
);
CREATE TABLE csr.urjanet_service_type (
	app_sid							NUMBER(10)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	service_type					VARCHAR2(255) NOT NULL,
	meter_ind_id					NUMBER(10)    NOT NULL,
	CONSTRAINT pk_urjanet_service_type PRIMARY KEY (app_sid, service_type),
	CONSTRAINT fk_urj_service_type_meter_ind FOREIGN KEY (app_sid, meter_ind_id)
		REFERENCES csr.meter_ind (app_sid, meter_ind_id)
);

ALTER TABLE csr.approval_dashboard_val_src
DROP COLUMN link_url;
ALTER TABLE csr.aggregate_ind_group
ADD source_url VARCHAR2(1027);
/* source_detail is just a string. We are using it to store a date but this isn't set in stone so need to replace LAST_DATE with it
   so that we are covered. The date here isn't used in any calculations, etc so a string of it is fine. */
ALTER TABLE csr.approval_dashboard_val_src
ADD source_detail VARCHAR(1024);
UPDATE csr.approval_dashboard_val_src
   SET source_detail = last_date;
   
ALTER TABLE csr.approval_dashboard_val_src
DROP COLUMN last_date;
ALTER TABLE chain.company_tab ADD (
	company_col_sid		NUMBER(10) NULL,
	supplier_col_sid	NUMBER(10) NULL
);
ALTER TABLE csrimp.chain_company_tab ADD (
	company_col_sid		NUMBER(10) NULL,
	supplier_col_sid	NUMBER(10) NULL
);
	
ALTER TABLE csr.issue_scheduled_task ADD (
	due_dtm_relative			NUMBER(10),
	due_dtm_relative_unit		CHAR(1)
);
ALTER TABLE csrimp.issue_scheduled_task ADD (
	due_dtm_relative			NUMBER(10),
	due_dtm_relative_unit		CHAR(1)
);
ALTER TABLE csr.all_meter ADD urjanet_meter_id VARCHAR2(256);
ALTER TABLE csrimp.all_meter ADD urjanet_meter_id VARCHAR2(256);
CREATE UNIQUE INDEX csr.uk_all_meter_urjanet_id ON csr.all_meter (app_sid, NVL(LOWER(urjanet_meter_id), region_sid));
create index csr.ix_auto_imp_impo_automated_imp on csr.auto_imp_importer_settings (automated_import_file_type_id);
create index csr.ix_urjanet_servi_meter_ind_id on csr.urjanet_service_type (app_sid, meter_ind_id);




ALTER TABLE chain.company_tab ADD CONSTRAINT fk_company_tab_company_col FOREIGN KEY (app_sid, company_col_sid) REFERENCES cms.tab_column(app_sid, column_sid);	
ALTER TABLE chain.company_tab ADD CONSTRAINT fk_company_tab_supplier_col FOREIGN KEY (app_sid, supplier_col_sid) REFERENCES cms.tab_column(app_sid, column_sid);	


CREATE OR REPLACE VIEW csr.METER AS
  SELECT APP_SID,REGION_SID, NOTE, PRIMARY_IND_SID, PRIMARY_MEASURE_CONVERSION_ID, METER_SOURCE_TYPE_ID, REFERENCE, CRC_METER,
	COST_IND_SID, COST_MEASURE_CONVERSION_ID, DAYS_IND_SID, DAYS_MEASURE_CONVERSION_ID, COSTDAYS_IND_SID, COSTDAYS_MEASURE_CONVERSION_ID,
	APPROVED_BY_SID, APPROVED_DTM, IS_CORE, URJANET_METER_ID
    FROM ALL_METER
   WHERE ACTIVE = 1;
   




UPDATE chain.company_tab target 
   SET target.company_col_sid = (
	SELECT source.column_sid 
	  FROM (
		SELECT tc.column_sid, ct.company_tab_id
		  FROM csr.plugin p
		  JOIN chain.company_tab ct ON ct.plugin_id = p.plugin_id AND ct.app_sid = p.app_sid
		  JOIN cms.tab t ON t.tab_sid = p.tab_sid 
						AND t.app_sid = p.app_sid
		  JOIN cms.tab_column tc ON tc.tab_sid = t.tab_sid AND tc.app_sid = p.app_sid AND tc.oracle_column = 'COMPANY_SID'
		 WHERE p.plugin_type_id = 10 
		   AND p.js_class = 'Chain.ManageCompany.CmsTab' 
		   AND p.form_path IS NOT NULL
		) source
	WHERE source.company_tab_id = target.company_tab_id
)
WHERE EXISTS (
	SELECT source.column_sid 
	  FROM (
		SELECT tc.column_sid, ct.company_tab_id
	      FROM csr.plugin p
	      JOIN chain.company_tab ct ON ct.plugin_id = p.plugin_id AND ct.app_sid = p.app_sid
	      JOIN cms.tab t ON t.tab_sid = p.tab_sid 
						AND t.app_sid = p.app_sid
		  JOIN cms.tab_column tc ON tc.tab_sid = t.tab_sid AND tc.app_sid = p.app_sid AND tc.oracle_column = 'COMPANY_SID'
	     WHERE p.plugin_type_id = 10 
	       AND p.js_class = 'Chain.ManageCompany.CmsTab' 
	       AND p.form_path IS NOT NULL
		) source
	 WHERE source.company_tab_id = target.company_tab_id
);
UPDATE chain.company_tab target 
   SET target.supplier_col_sid = (
	SELECT source.column_sid 
	  FROM (
		SELECT tc.column_sid, ct.company_tab_id
		  FROM csr.plugin p
		  JOIN chain.company_tab ct ON ct.plugin_id = p.plugin_id AND ct.app_sid = p.app_sid
		  JOIN cms.tab t ON t.tab_sid = p.tab_sid AND t.app_sid = p.app_sid
		  JOIN cms.tab_column tc ON tc.tab_sid = t.tab_sid AND tc.app_sid = p.app_sid AND tc.oracle_column = 'SUPPLIER_SID'
		 WHERE p.plugin_type_id = 10 
		   AND p.js_class = 'Chain.ManageCompany.CmsTab' 
		   AND p.form_path IS NOT NULL
		) source
	WHERE source.company_tab_id = target.company_tab_id
)
WHERE EXISTS (
	SELECT source.column_sid 
	  FROM (
		SELECT tc.column_sid, ct.company_tab_id
	      FROM csr.plugin p
	      JOIN chain.company_tab ct ON ct.plugin_id = p.plugin_id AND ct.app_sid = p.app_sid
	      JOIN cms.tab t ON t.tab_sid = p.tab_sid AND t.app_sid = p.app_sid
		  JOIN cms.tab_column tc ON tc.tab_sid = t.tab_sid AND tc.app_sid = p.app_sid AND tc.oracle_column = 'SUPPLIER_SID'
	     WHERE p.plugin_type_id = 10 
	       AND p.js_class = 'Chain.ManageCompany.CmsTab' 
	       AND p.form_path IS NOT NULL
		) source
	 WHERE source.company_tab_id = target.company_tab_id
);
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
VALUES (11, 'Enable/Disable self-registration permissions', 'Updates permissions. See wiki for details.', 'SetSelfRegistrationPermissions', 'W2592');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint, pos)
VALUES (11, 'Setting value (0 off, 1 on)', 'The setting to use.', 0);
INSERT INTO csr.auto_imp_importer_plugin (plugin_id, label, importer_assembly)
	 VALUES (2, 'Urjanet importer',   'Credit360.AutomatedExportImport.Import.Importers.UrjanetImporter');
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	 VALUES (60, 'Urjanet importer', 'EnableUrjanet', 'Enables the urjanet importer. It needs to know the SFTP folder on our server, which should be setup before enabling this. After running this, be sure to configure the Urjanet service types (via the "Property Setup" menu)');
		
INSERT INTO csr.module_param (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	 SELECT 60, 'in_ftp_path', 0, 'The path to the clients Urjanet folder on our STFP server (cyanoxantha). e.g. "client_name/urjanet".'
	   FROM dual
	  WHERE (60, 'in_ftp_path') NOT IN (SELECT module_id, param_name FROM csr.module_param);
INSERT INTO csr.meter_raw_data_source_type (raw_data_source_type_id, feed_type, description) VALUES(3, 'urjanet', 'Urjanet');
INSERT INTO CSR.meter_raw_data_status (status_id, description, needs_processing) VALUES(6, 'Pre-processing errors', 0);
INSERT INTO CSR.meter_raw_data_status (status_id, description, needs_processing) VALUES(7, 'Retry', 0);
	 






@..\aggregate_ind_pkg
@..\approval_dashboard_pkg
@..\recurrence_pattern_pkg
@..\quick_survey_pkg
@..\audit_pkg
@..\chain\plugin_pkg
@..\issue_pkg
@..\csr_data_pkg
@..\util_script_pkg
@..\enable_pkg
@..\automated_import_pkg
@..\meter_pkg
@..\meter_monitor_pkg
@..\space_pkg
@..\schema_pkg
@..\alert_pkg
@..\branding_pkg
@..\chain\admin_helper_pkg
@..\enhesa_pkg

@..\schema_body
@..\aggregate_ind_body
@..\approval_dashboard_body
@..\stored_calc_datasource_body
@..\..\..\aspen2\cms\db\filter_body
@..\flow_body
@..\recurrence_pattern_body
@..\quick_survey_body
@..\audit_body
@..\campaign_body
@..\region_body
@..\trash_body
@..\chain\plugin_body
@..\csrimp\imp_body
@..\issue_body
@..\chain\company_filter_body
@..\chem\substance_body
@..\audit_report_body
@..\csr_data_body
@..\util_script_body
@..\csr_app_body
@..\enable_body
@..\automated_import_body
@..\meter_monitor_body
@..\meter_body
@..\space_body
@..\alert_body
@..\branding_body
@..\customer_body
@..\supplier_body
@..\training_body
@..\chain\admin_helper_body
@..\chain\chain_link_body
@..\enhesa_body
@..\csr_user_body


@update_tail
