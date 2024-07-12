-- Please update version.sql too -- this keeps clean builds in sync
define version=3035
define minor_version=28
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
	INSERT INTO csr.batch_job_type(batch_job_type_id, description, sp)
	VALUES (59, 'Product Type export', 'chain.product_type_pkg.ExportProductTypes');

	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (59, 'Product Type Exporter', 'Credit360.ExportImport.Export.Batched.Exporters.ProductTypeExporter');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
