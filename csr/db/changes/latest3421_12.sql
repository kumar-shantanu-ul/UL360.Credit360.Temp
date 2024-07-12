-- Please update version.sql too -- this keeps clean builds in sync
define version=3421
define minor_version=12
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
VALUES (94, 'Alert bounce export', 'batch-exporter', 0, 'support@credit360.com', 3, 120);

INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (94, 'Alert bounce export', 'Credit360.ExportImport.Export.Batched.Exporters.AlertBounceExporter');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../alert_pkg

@../alert_body

@update_tail
