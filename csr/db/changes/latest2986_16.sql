-- Please update version.sql too -- this keeps clean builds in sync
define version=2986
define minor_version=16
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

UPDATE csr.auto_exp_exporter_plugin
   SET exporter_assembly = 'Credit360.ExportImport.Automated.Export.Exporters.AbInBev.MeanScoresDataExporter'
 WHERE plugin_id = 14;
 
 UPDATE csr.auto_exp_exporter_plugin
   SET exporter_assembly = 'Credit360.ExportImport.Automated.Export.Exporters.AbInBev.SuepMeanScoresDataExporter'
WHERE plugin_id = 15;
 	
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\scenario_run_snapshot_pkg;
@..\scenario_run_snapshot_body;

@update_tail
