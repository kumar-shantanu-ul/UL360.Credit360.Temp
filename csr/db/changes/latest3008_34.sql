-- Please update version.sql too -- this keeps clean builds in sync
define version=3008
define minor_version=34
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
	INSERT INTO csr.batched_import_type (batch_import_type_id,label,assembly) VALUES (5,'Factor set import','Credit360.ExportImport.Import.Batched.Importers.FactorSetImporter');
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
