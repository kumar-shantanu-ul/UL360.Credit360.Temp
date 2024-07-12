-- Please update version.sql too -- this keeps clean builds in sync
define version=3489
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

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

@../enable_body
@../automated_export_body
@../automated_import_body
@../meter_monitor_body
@../util_script_body

@update_tail
