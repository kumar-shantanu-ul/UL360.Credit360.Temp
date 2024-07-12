-- Please update version.sql too -- this keeps clean builds in sync
define version=2972
define minor_version=21
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.AUTO_EXP_FILECREATE_DSV
ADD encoding_name VARCHAR2(255);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	UPDATE csr.auto_exp_exporter_plugin
	   SET outputter_assembly = 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.DsvOutputter'
	 WHERE plugin_id = 1;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../automated_export_pkg
@../automated_export_body

@update_tail
