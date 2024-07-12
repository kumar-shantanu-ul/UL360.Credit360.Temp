-- Please update version.sql too -- this keeps clean builds in sync
define version=2900
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.auto_imp_importer_cms
  ADD header_row NUMBER(10);
  
ALTER TABLE csr.auto_imp_importer_cms 
	MODIFY(header_row DEFAULT 0);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../automated_import_pkg
@../automated_import_body

@update_tail
