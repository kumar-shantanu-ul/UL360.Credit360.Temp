-- Please update version.sql too -- this keeps clean builds in sync
define version=3129
define minor_version=1
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
   SET outputter_assembly = 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.FixedExcelOutputter'
 WHERE outputter_assembly = 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.ExcelOutputter';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
