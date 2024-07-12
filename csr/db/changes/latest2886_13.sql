-- Please update version.sql too -- this keeps clean builds in sync
define version=2886
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
-- RLS

-- Data

INSERT INTO CSR.AUTO_EXP_FILE_WRITER_PLUGIN (plugin_id, label, assembly)
VALUES (7, 'FTP (zip extraction)', 'Credit360.AutomatedExportImport.Export.FileWrite.FtpZipExtractionWriter');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
