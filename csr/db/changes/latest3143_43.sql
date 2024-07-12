-- Please update version.sql too -- this keeps clean builds in sync
define version=3143
define minor_version=43
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
@../chain/card_pkg
@../chain/plugin_pkg

@../chain/card_body
@../chain/plugin_body
@../chain/business_relationship_body
@../chain/company_body
@../chain/company_filter_body
@../chain/dashboard_body
@../chain/type_capability_body


@update_tail
