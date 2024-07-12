-- Please update version.sql too -- this keeps clean builds in sync
define version=3215
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
	INSERT INTO csr.batch_job_type (batch_job_type_id, description,  plugin_name, in_order, notify_address, max_retries, priority, timeout_mins)
	VALUES (87, 'Indicator selections groups translation export', 'batch-exporter', 0, 'support@credit360.com', 3, 1, 120);
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (87, 'Indicator selections translation export', 'Credit360.ExportImport.Export.Batched.Exporters.IndicatorSelectionsTranslationExporter');
	
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (88, 'Indicator selection groups translations import', null, 'batch-importer', 0, null, 120);
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (88, 'Indicator selections translations import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.IndicatorSelectionsTranslationImporter');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../indicator_pkg
@../indicator_body

@update_tail
