-- Please update version.sql too -- this keeps clean builds in sync
define version=3194
define minor_version=5
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
	BEGIN
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
		VALUES (83, 'Indicator validation rules export', null, 'batch-exporter', 0, null, 120);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE csr.batch_job_type
			   SET description = 'Indicator validation rules export',
				   sp = NULL,
				   plugin_name = 'batch-exporter',
				   in_order = 0,
				   file_data_sp = NULL,
				   timeout_mins = 120
			 WHERE BATCH_JOB_TYPE_ID = 83;
	END;
	BEGIN 
		INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
		VALUES (83, 'Indicator validation rules export', 'Credit360.ExportImport.Export.Batched.Exporters.IndicatorValidationRulesExporter');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE csr.batched_export_type
			   SET LABEL = 'Indicator validation rules export',
				   ASSEMBLY = 'Credit360.ExportImport.Export.Batched.Exporters.IndicatorValidationRulesExporter'
			 WHERE BATCH_JOB_TYPE_ID = 83;
	END;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../indicator_pkg
@../indicator_body

@update_tail
