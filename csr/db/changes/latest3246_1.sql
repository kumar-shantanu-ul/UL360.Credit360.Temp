-- Please update version.sql too -- this keeps clean builds in sync
define version=3246
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csrimp.issue_type MODIFY region_is_mandatory DEFAULT NULL;

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
@../region_body
@../region_tree_body
@../tag_body

@../chain/company_body
@../chain/company_dedupe_body

@update_tail
