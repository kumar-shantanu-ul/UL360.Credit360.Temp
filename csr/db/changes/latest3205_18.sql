-- Please update version.sql too -- this keeps clean builds in sync
define version=3205
define minor_version=18
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
@../chain/type_capability_pkg

@../chain/type_capability_body
@../chain/company_filter_body

@update_tail
