-- Please update version.sql too -- this keeps clean builds in sync
define version=3111
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (75, 'Region mappings import', null, 'batch-importer', 0, null, 120);
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (75, 'Region mapping import', 'Credit360.ExportImport.Import.Batched.Importers.Mappings.RegionMappingImporter');
	
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (76, 'Indicator mappings import', null, 'batch-importer', 0, null, 120);
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (76, 'Indicator mapping import', 'Credit360.ExportImport.Import.Batched.Importers.Mappings.IndicatorMappingImporter');
	
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (77, 'Measure mappings import', null, 'batch-importer', 0, null, 120);
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (77, 'Measure mapping import', 'Credit360.ExportImport.Import.Batched.Importers.Mappings.MeasureMappingImporter');
	
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (78, 'Region mappings export', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (78, 'Region mapping export', 'Credit360.ExportImport.Export.Batched.Exporters.Mappings.RegionMappingExporter');
	
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (79, 'Indicator mappings export', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (79, 'Indicator mapping export', 'Credit360.ExportImport.Export.Batched.Exporters.Mappings.IndicatorMappingExporter');

	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (80, 'Measure mappings export', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (80, 'Measure mapping export', 'Credit360.ExportImport.Export.Batched.Exporters.Mappings.MeasureMappingExporter');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../automated_import_pkg

@../automated_import_body

@update_tail
