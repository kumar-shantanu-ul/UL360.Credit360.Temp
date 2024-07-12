-- Please update version.sql too -- this keeps clean builds in sync
define version=3187
define minor_version=10
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
@../role_pkg
@../chain/chain_pkg
@../chain/company_type_pkg

@../role_body
@../chain/company_type_body

@update_tail
