-- Please update version.sql too -- this keeps clean builds in sync
define version=3173
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
INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, in_order, notify_address, max_retries, timeout_mins)
VALUES (82, 'Compliance item import', 'batch-importer', 0, 'support@credit360.com', 3, 120);
	
INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (82, 'Compliance item import', 'Credit360.ExportImport.Batched.Import.Importers.ComplianceItemImporter');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
