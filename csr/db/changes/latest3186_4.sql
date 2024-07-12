-- Please update version.sql too -- this keeps clean builds in sync
define version=3186
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

GRANT EXECUTE ON csr.csr_app_pkg TO chain;
GRANT EXECUTE ON csr.unit_test_pkg TO chain;
GRANT EXECUTE ON chain.test_chain_utils_pkg TO csr;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
