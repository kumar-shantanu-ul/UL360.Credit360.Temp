-- Please update version.sql too -- this keeps clean builds in sync
define version=3035
define minor_version=12
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/test_chain_utils_pkg
@../chain/dedupe_admin_pkg

@../chain/dedupe_preprocess_body
@../chain/company_dedupe_body
@../chain/dedupe_admin_body
@../chain/test_chain_utils_body

@update_tail
