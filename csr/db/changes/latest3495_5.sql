-- Please update version.sql too -- this keeps clean builds in sync
define version=3495
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

grant select,delete on csr.user_profile to chain;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\csr_user_body
@..\unit_test_pkg
@..\unit_test_body

@update_tail
