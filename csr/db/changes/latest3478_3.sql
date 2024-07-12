-- Please update version.sql too -- this keeps clean builds in sync
define version=3478
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
BEGIN
    INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter, plugin_type_id)
    VALUES (13, 'Stored Procedure - Dsv', 'Credit360.ExportImport.Automated.Export.Exporters.StoredProcedure.StoredProcedureExporter', 'Credit360.ExportImport.Automated.Export.Exporters.StoredProcedure.StoredProcedureDsvOutputter', 1, 4);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
