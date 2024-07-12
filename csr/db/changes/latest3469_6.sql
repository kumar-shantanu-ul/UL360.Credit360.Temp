-- Please update version.sql too -- this keeps clean builds in sync
define version=3469
define minor_version=6
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
INSERT INTO csr.util_script (util_script_id,util_script_name,description,util_script_sp,wiki_article) 
VALUES (77, 'Client Termination Export', 'Export terminated client data', 'TerminatedClientData', NULL);

INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint, pos, param_value)
VALUES (77, 'Setup/TearDown', '(1 Setup, 0 TearDown)', 0, '1');

INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint, pos)
VALUES (77, 'Dataview sid', 'The sid of the dataview', 1);

INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter, plugin_type_id)
VALUES (26, 'Dataview - Client Termination Dsv', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.TerminatedClientExporter', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.DsvOutputter', 1, 1);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
