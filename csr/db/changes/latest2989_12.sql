-- Please update version.sql too -- this keeps clean builds in sync
define version=2989
define minor_version=12
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
INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (13, 'CMS quick chart exporter', 'Credit360.ExportImport.Export.Batched.Exporters.CmsQuickChartExporter');
INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (14, 'CMS exporter', 'Credit360.ExportImport.Export.Batched.Exporters.CmsExporter');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
