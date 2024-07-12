-- Please update version.sql too -- this keeps clean builds in sync
define version=2861
define minor_version=2
@update_header

-- *** DDL ***

CREATE SEQUENCE csr.auto_importer_settings_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20;
	
-- Create tables
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

-- Alter tables
ALTER TABLE csr.all_meter ADD urjanet_meter_id VARCHAR2(256);
ALTER TABLE csrimp.all_meter ADD urjanet_meter_id VARCHAR2(256);

CREATE UNIQUE INDEX csr.uk_all_meter_urjanet_id ON csr.all_meter (app_sid, NVL(LOWER(urjanet_meter_id), region_sid));

-- fk indexes
create index csr.ix_auto_imp_impo_automated_imp on csr.auto_imp_importer_settings (automated_import_file_type_id);
create index csr.ix_urjanet_servi_meter_ind_id on csr.urjanet_service_type (app_sid, meter_ind_id);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

CREATE OR REPLACE VIEW csr.METER AS
  SELECT APP_SID,REGION_SID, NOTE, PRIMARY_IND_SID, PRIMARY_MEASURE_CONVERSION_ID, METER_SOURCE_TYPE_ID, REFERENCE, CRC_METER,
	COST_IND_SID, COST_MEASURE_CONVERSION_ID, DAYS_IND_SID, DAYS_MEASURE_CONVERSION_ID, COSTDAYS_IND_SID, COSTDAYS_MEASURE_CONVERSION_ID,
	APPROVED_BY_SID, APPROVED_DTM, IS_CORE, URJANET_METER_ID
    FROM ALL_METER
   WHERE ACTIVE = 1;
   
-- *** Data changes ***
-- RLS

-- Data
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
	 
-- ** New package grants **

-- *** Packages ***
@../enable_pkg
@../automated_import_pkg
@../meter_pkg
@../meter_monitor_pkg
@../space_pkg
@../schema_pkg
@../region_body
@../csr_app_body
@../enable_body
@../automated_import_body
@../meter_monitor_body
@../schema_body
@../csrimp/imp_body
@../meter_body
@../space_body

@update_tail
