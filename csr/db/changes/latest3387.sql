-- Please update version.sql too -- this keeps clean builds in sync
define version=3387
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
GRANT EXECUTE ON csr.factor_set_group_pkg TO TOOL_USER;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../alert_body

@update_tail
