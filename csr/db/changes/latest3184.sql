-- Please update version.sql too -- this keeps clean builds in sync
define version=3184
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

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

@..\region_api_body
@..\..\..\aspen2\cms\db\tab_body

@update_tail
