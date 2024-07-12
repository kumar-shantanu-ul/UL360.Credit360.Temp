-- Please update version.sql too -- this keeps clean builds in sync
define version=3470
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
UPDATE csr.auto_exp_exporter_plugin 
   SET label = 'Client Termination Dsv',
	   exporter_assembly = 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.TerminatedClientExporter',
   	   outputter_assembly = 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.TerminatedClientXmlMappableDsvOutputter'
 WHERE plugin_id = 26;

DELETE
  FROM csr.util_script_param  
 WHERE util_script_id = 77 
   AND Param_name = 'Dataview sid';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../util_script_pkg
@../automated_export_pkg
@../util_script_body
@../automated_export_body
@../region_body
@../indicator_body

@update_tail
