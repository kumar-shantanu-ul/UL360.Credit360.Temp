-- Please update version.sql too -- this keeps clean builds in sync
define version=2989
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.region_description
  ADD last_changed_dtm DATE;

ALTER TABLE csrimp.region_description
  ADD last_changed_dtm DATE;

ALTER TABLE csrimp.ind_description
  ADD last_changed_dtm DATE;
  
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.batched_export_type (
		batch_export_type_id, label, assembly
	) VALUES (
		12, 'Region translations', 'Credit360.ExportImport.Export.Batched.Exporters.RegionTranslationExporter'
	);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\indicator_pkg
@..\indicator_body
@..\region_pkg
@..\region_body

@..\schema_body
@..\csrimp\imp_body

@update_tail
