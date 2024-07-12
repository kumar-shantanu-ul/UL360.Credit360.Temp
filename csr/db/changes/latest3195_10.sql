-- Please update version.sql too -- this keeps clean builds in sync
define version=3195
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.automated_import_class_step
MODIFY (days_to_retain_payload DEFAULT 90);

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
