-- Please update version.sql too -- this keeps clean builds in sync
define version=2967
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

UPDATE csr.automated_import_class
   SET import_plugin = REPLACE(import_plugin, '.AutomatedExportImport.', '.ExportImport.Automated.')
 WHERE import_plugin IS NOT NULL;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
