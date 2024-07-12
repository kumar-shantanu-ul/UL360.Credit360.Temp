-- Please update version.sql too -- this keeps clean builds in sync
define version=3414
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.auto_imp_importer_plugin
ADD allow_manual NUMBER(1) DEFAULT 1 NOT NULL;

ALTER TABLE csr.auto_imp_importer_plugin
ADD CONSTRAINT CK_AUTO_IMP_IMPRTR_PLGN_MAN CHECK (ALLOW_MANUAL IN (0,1));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

UPDATE csr.auto_imp_importer_plugin
   SET allow_manual = 0
 WHERE importer_assembly = 'Credit360.ExportImport.Automated.Import.Importers.XmlBulkImporter';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\automated_import_body

@update_tail
