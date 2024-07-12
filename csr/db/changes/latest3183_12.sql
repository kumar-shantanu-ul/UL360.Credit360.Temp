-- Please update version.sql too -- this keeps clean builds in sync
define version=3183
define minor_version=12
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.automated_export_class ADD CONTAINS_PII NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE csr.automated_import_class ADD CONTAINS_PII NUMBER(1,0) DEFAULT 0 NOT NULL;
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../automated_export_pkg
@../automated_import_pkg

@../automated_export_body
@../automated_import_body
@update_tail
