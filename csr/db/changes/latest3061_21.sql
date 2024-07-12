-- Please update version.sql too -- this keeps clean builds in sync
define version=3061
define minor_version=21
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
INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
VALUES (62, 'Product type translations export', null, 'batch-exporter', 0, null, 120);

INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
VALUES (63, 'Product type translations import', null, 'batch-importer', 0, null, 120);

INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (62, 'Product type translation export', 'Credit360.ExportImport.Export.Batched.Exporters.ProductTypeTranslationExporter');

INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (63, 'Product type translation import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.ProductTypeTranslationImporter');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
CREATE OR REPLACE TYPE CHAIN.T_SID_AND_DESCRIPTION_ROW AS 
  OBJECT ( 
	pos				NUMBER(10,0),
	sid_id 			NUMBER(10,0),
	description		VARCHAR2(2047)
  );
/
CREATE OR REPLACE TYPE CHAIN.T_SID_AND_DESCRIPTION_TABLE AS 
  TABLE OF CHAIN.T_SID_AND_DESCRIPTION_ROW;
/

@../chain/product_type_pkg

@../chain/product_type_body

@update_tail
