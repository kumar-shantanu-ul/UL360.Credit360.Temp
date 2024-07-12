-- Please update version.sql too -- this keeps clean builds in sync
define version=3088
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.AUTO_EXP_RETRIEVAL_DATAVIEW ADD (MAPPING_XML SYS.XMLType);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
VALUES (21, 'Dataview - Xml Mapped Dsv',	'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.XmlMappableDsvOutputter');
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
VALUES (22, 'Dataview - Xml Mapped Excel',	'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.XmlMappableExcelOutputter');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../automated_export_pkg

@../automated_export_body
@../dataview_body

@update_tail
