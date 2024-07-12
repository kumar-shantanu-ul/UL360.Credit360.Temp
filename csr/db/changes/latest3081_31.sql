-- Please update version.sql too -- this keeps clean builds in sync
define version=3081
define minor_version=31
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
INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) values (66, 'Permit module types import', 'batch-importer', 'support@credit360.com', 3, 1, 120);
INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (66, 'Permit module types import', 'Credit360.ExportImport.Batched.Import.Importers.PermitModuleTypesImporter');

INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
VALUES (67, 'Permits import', 'batch-importer', 'support@credit360.com', 3, 1, 120);
INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (67, 'Permits import', 'Credit360.ExportImport.Batched.Import.Importers.PermitsImporter');

INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
VALUES (68, 'Conditions import', 'batch-importer', 'support@credit360.com', 3, 1, 120);
INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (68, 'Conditions import', 'Credit360.ExportImport.Batched.Import.Importers.ConditionsImporter');

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.permit_data_import_pkg AS END;
/
GRANT EXECUTE ON csr.permit_data_import_pkg TO web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@../permit_data_import_pkg
@../permit_pkg
@../compliance_pkg

@../permit_data_import_body
@../permit_body
@../compliance_body


@update_tail
