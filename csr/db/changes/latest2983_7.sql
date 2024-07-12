-- Please update version.sql too -- this keeps clean builds in sync
define version=2983
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.batched_import_type (
	batch_import_type_id	NUMBER(10) NOT NULL,
	label					VARCHAR2(255) NOT NULL,
	assembly				VARCHAR2(1024) NOT NULL,
	CONSTRAINT pk_batched_import_type PRIMARY KEY (batch_import_type_id)
);
 
CREATE TABLE csr.batch_job_batched_import (
	app_sid					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL ,
	batch_job_id			NUMBER(10) NOT NULL,
	batch_import_type_id	NUMBER(10) NOT NULL,
	settings_xml			XMLTYPE NOT NULL,
	file_blob				BLOB,
	file_name				VARCHAR2(1024),
	error_file_blob			BLOB,
	error_file_name			VARCHAR2(1024),
	CONSTRAINT pk_bj_batched_import PRIMARY KEY (app_sid, batch_job_id),
	CONSTRAINT fk_bj_batched_import_bj_id FOREIGN KEY (app_sid, batch_job_id) REFERENCES csr.batch_job(app_sid, batch_job_id),
	CONSTRAINT fk_bj_batched_import_type FOREIGN KEY (batch_import_type_id) REFERENCES csr.batched_import_type (batch_import_type_id)  
);
-- Alter tables
ALTER TABLE csr.ind_description
ADD last_changed_dtm DATE;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.capability (name, allow_by_default) VALUES ('Import core translations', 0);
	
	INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (11, 'Indicator translations', 'Credit360.ExportImport.Export.Batched.Exporters.IndicatorTranslationExporter');
	
	INSERT INTO csr.batched_import_type (BATCH_IMPORT_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (0, 'Indicator translations import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.IndicatorTranslationImporter');
	INSERT INTO csr.batched_import_type (BATCH_IMPORT_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (1, 'Region translations import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.RegionTranslationImporter');
	INSERT INTO csr.batched_import_type (BATCH_IMPORT_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (2, 'Delegation translations import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.DelegationTranslationImporter');
	
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
	VALUES (29, 'Batched importer', null, 'batch-importer', 0, null);
END;
/
 
BEGIN
	DBMS_SCHEDULER.CREATE_JOB (
		job_name        => 'csr.BATCHEDIMPORTSCLEARUP',
		job_type        => 'PLSQL_BLOCK',
		job_action      => 'BEGIN security.user_pkg.logonadmin(); csr.batch_importer_pkg.ScheduledFileClearUp; commit; END;',
		job_class		=> 'low_priority_job',
		start_date		=> to_timestamp_tz('2016/09/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		repeat_interval	=> 'FREQ=DAILY',
		enabled			=> TRUE,
		auto_drop		=> FALSE,
		comments		=> 'Schedule for removing batched imports file data from the database, so we do not use endless space'
	);
END;
/

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.batch_importer_pkg as end;
/
GRANT EXECUTE ON csr.batch_importer_pkg TO WEB_USER;

-- *** Conditional Packages ***

-- *** Packages ***
@../indicator_pkg
@../indicator_body
@../batch_job_pkg
@../batch_importer_pkg
@../batch_importer_body

@update_tail
