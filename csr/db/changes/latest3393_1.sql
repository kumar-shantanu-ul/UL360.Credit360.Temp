-- Please update version.sql too -- this keeps clean builds in sync
define version=3393
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
INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Enable Delegation Plan Folders', 0, 'Delegations: Enable foldering for delegation plans in Manage Delegation Plans.');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../deleg_plan_pkg
@../deleg_plan_body

@update_tail
