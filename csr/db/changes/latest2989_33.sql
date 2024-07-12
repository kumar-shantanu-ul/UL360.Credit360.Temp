-- Please update version.sql too -- this keeps clean builds in sync
define version=2989
define minor_version=33
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
VALUES (15, 'Forecasting Slot export', 'Credit360.ExportImport.Export.Batched.Exporters.ForecastingSlotExporter');

INSERT INTO csr.batched_import_type (BATCH_IMPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (4, 'Forecasting Slot import', 'Credit360.ExportImport.Import.Batched.Importers.ForecastingSlotImporter');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../forecasting_pkg
@../forecasting_body

@update_tail
