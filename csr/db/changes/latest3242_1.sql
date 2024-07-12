-- Please update version.sql too -- this keeps clean builds in sync
define version=3242
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
@../supplier_pkg
@../supplier_body
@../chain/test_chain_utils_pkg
@../chain/test_chain_utils_body

@update_tail
