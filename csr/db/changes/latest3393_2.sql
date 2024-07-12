-- Please update version.sql too -- this keeps clean builds in sync
define version=3393
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
GRANT EXECUTE ON csr.delegation_pkg TO TOOL_USER;
GRANT EXECUTE ON csr.deleg_plan_pkg TO TOOL_USER;
GRANT EXECUTE ON csr.deleg_admin_pkg TO TOOL_USER;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../deleg_plan_pkg
@../deleg_plan_body

@update_tail
