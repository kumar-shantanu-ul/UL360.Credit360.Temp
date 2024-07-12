-- Please update version.sql too -- this keeps clean builds in sync
define version=3240
define minor_version=3
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
VALUES (90, 'Compliance item export', 'batch-exporter', 0, 'support@credit360.com', 3, 120);

INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (90, 'Compliance item export', 'Credit360.ExportImport.Export.Batched.Exporters.ComplianceItemExporter');

INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, in_order, notify_address, max_retries, timeout_mins)
VALUES (91, 'Compliance item variant export', 'batch-exporter', 0, 'support@credit360.com', 3, 120);

INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (91, 'Compliance item variant export', 'Credit360.ExportImport.Export.Batched.Exporters.ComplianceItemVariantExporter');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../compliance_pkg
@../compliance_body

@update_tail
