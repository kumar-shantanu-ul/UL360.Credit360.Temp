-- Please update version.sql too -- this keeps clean builds in sync
define version=3319
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

INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (93, 'Reporting point export', 'Credit360.ExportImport.Export.Batched.Exporters.ReportingPointExporter');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\region_pkg
@..\region_body

@update_tail
