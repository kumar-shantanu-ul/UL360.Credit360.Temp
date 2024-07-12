-- Please update version.sql too -- this keeps clean builds in sync
define version=3158
define minor_version=5
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
@../chain/company_pkg

@../chain/company_body
@../chain/company_dedupe_body

@update_tail
