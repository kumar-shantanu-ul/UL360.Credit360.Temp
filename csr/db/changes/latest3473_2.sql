-- Please update version.sql too -- this keeps clean builds in sync
define version=3473
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
UPDATE csr.util_script
   SET util_script_sp = 'TerminatedClientData'
 WHERE util_script_id = 77;

-- RLS

-- Data

-- ** New package grants **


-- *** Conditional Packages ***

-- *** Packages ***
@..\automated_export_pkg
@..\automated_export_body

@update_tail
