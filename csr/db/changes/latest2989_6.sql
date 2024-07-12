-- Please update version.sql too -- this keeps clean builds in sync
define version=2989
define minor_version=6
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
INSERT INTO csr.batched_import_type (BATCH_IMPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (3, 'Meter readings import', 'Credit360.ExportImport.Batched.Import.Importers.MeterReadingsImporter');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
