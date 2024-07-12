-- Please update version.sql too -- this keeps clean builds in sync
define version=3405
define minor_version=2
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
UPDATE csr.util_script
   SET util_script_name = 'New password hashing scheme: disable'
 WHERE util_script_id = 69;

UPDATE csr.util_script
   SET util_script_name = 'New password hashing scheme: enable'
 WHERE util_script_id = 70;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
