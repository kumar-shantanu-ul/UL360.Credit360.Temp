-- Please update version.sql too -- this keeps clean builds in sync
define version=3436
define minor_version=4
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
UPDATE csr.module SET warning_msg = 'Please check the customer does not have any custom scenarios as this could break (old) scrag.' WHERE module_id = 125;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body

@update_tail
