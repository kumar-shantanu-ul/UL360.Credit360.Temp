-- Please update version.sql too -- this keeps clean builds in sync
define version=2957
define minor_version=9
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

UPDATE csr.AUTOMATED_IMPORT_CLASS_STEP
   SET plugin = REPLACE(plugin, '.AutomatedExportImport.', '.ExportImport.Automated.');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
