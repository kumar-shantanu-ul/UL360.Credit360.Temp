-- Please update version.sql too -- this keeps clean builds in sync
define version=3052
define minor_version=0
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
DECLARE 
	v_plugin_id 	NUMBER;
BEGIN
	SELECT plugin_id
	  INTO v_plugin_id
	  FROM csr.auto_exp_exporter_plugin
	 WHERE plugin_id = 18;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
		VALUES (18, 'Heineken SPM - dataview export (excel)', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.HeinekenExcelOutputter');
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
