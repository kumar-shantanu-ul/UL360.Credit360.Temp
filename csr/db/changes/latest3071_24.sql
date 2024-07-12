-- Please update version.sql too -- this keeps clean builds in sync
define version=3071
define minor_version=24
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
BEGIN
	INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly) 
	VALUES (20, 'ELC - Incident export (xml)', 'Credit360.ExportImport.Automated.Export.Exporters.ELC.IncidentExporter', 'Credit360.ExportImport.Automated.Export.Exporters.ELC.IncidentXmlOutputter');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
