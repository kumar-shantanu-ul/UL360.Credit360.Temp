-- Please update version.sql too -- this keeps clean builds in sync
define version=3150
define minor_version=12
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
GRANT SELECT ON cms.uk_cons_col TO chain;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../../../aspen2/cms/db/tab_pkg
@../../../aspen2/cms/db/tab_pkg

@../chain/company_dedupe_pkg
@../chain/company_dedupe_body

@update_tail
