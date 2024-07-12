-- Please update version.sql too -- this keeps clean builds in sync
define version=2881
define minor_version=13
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
BEGIN
	INSERT INTO csr.auto_imp_fileread_plugin (plugin_id, label, fileread_assembly)
		 VALUES (3, 'Manual Instance Reader', 'Credit360.AutomatedExportImport.Import.FileReaders.ManualInstanceDbReader');
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/

-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_body

@../automated_import_pkg
@../automated_import_body

@update_tail
