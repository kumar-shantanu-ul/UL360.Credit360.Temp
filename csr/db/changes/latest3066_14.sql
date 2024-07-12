-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=14
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.company_product_tr
	ADD last_changed_dtm_description DATE;


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (64, 'Product description translation export', null, 'batch-exporter', 0, null, 120);
INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (65, 'Product description translation import', null, 'batch-importer', 0, null, 120);

INSERT INTO csr.batched_export_type (batch_job_type_id, label, assembly)
	VALUES (64, 'Product description translation export', 'Credit360.ExportImport.Export.Batched.Exporters.ProductDescriptionTranslationExporter');
INSERT INTO csr.batched_import_type (batch_job_type_id, label, assembly)
	VALUES (65, 'Product description translation import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.ProductDescriptionTranslationImporter');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/company_product_pkg
@../chain/company_product_body

@update_tail
