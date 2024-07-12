-- Please update version.sql too -- this keeps clean builds in sync
define version=3193
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.automated_import_class
  ADD pending_files_limit NUMBER(3) DEFAULT 20 NOT NULL;
 
ALTER TABLE csr.automated_import_class
  ADD CONSTRAINT ck_auto_imp_cls_files_limit CHECK (pending_files_limit <= 100);
  
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

UPDATE csr.automated_import_class
   SET pending_files_limit = 0
 WHERE automated_import_class_sid IN (
	SELECT automated_import_class_sid 
	  FROM csr.automated_import_class_step 
	 WHERE importer_plugin_id = 2
	 );


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../automated_import_pkg

@../automated_import_body

@update_tail
