-- Please update version.sql too -- this keeps clean builds in sync
define version=3422
define minor_version=2
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

INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter, plugin_type_id)
VALUES (24, 'Dataview - JSON','Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.DataViewExporter','Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.JsonOutputter', 0, 1);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
