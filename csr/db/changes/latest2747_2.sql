-- Please update version.sql too -- this keeps clean builds in sync
define version=2747
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***

-- Data

-- ** New package grants **

-- *** Packages ***
@..\automated_export_import_body
@..\automated_export_import_pkg

@update_tail
