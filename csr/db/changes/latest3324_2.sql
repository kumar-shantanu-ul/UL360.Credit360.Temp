-- Please update version.sql too -- this keeps clean builds in sync
define version=3324
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
GRANT SELECT ON csr.region_survey_response TO chain;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/company_filter_pkg

@../chain/company_filter_body
@../chain/filter_body

@update_tail
