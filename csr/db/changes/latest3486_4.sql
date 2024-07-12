-- Please update version.sql too -- this keeps clean builds in sync
define version=3486
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

INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter, plugin_type_id)
VALUES (26, 'Client Termination Dsv', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.TerminatedClientExporter', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.TerminatedClientXmlMappableDsvOutputter', 1, 1);

INSERT INTO csr.util_script (util_script_id,util_script_name,description,util_script_sp,wiki_article) 
VALUES (77, 'Client Termination Export', 'Export terminating client data', 'TerminatedClientData', NULL);

INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint, pos, param_value)
VALUES (77, 'Setup/TearDown', '(1 Setup, 0 TearDown)', 0, '1');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../util_script_pkg
@../util_script_body

@update_tail
