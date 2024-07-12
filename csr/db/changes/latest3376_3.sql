-- Please update version.sql too -- this keeps clean builds in sync
define version=3376
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE campaigns.campaign_region_response ADD registered_in_acg_dtm DATE;

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

@../campaigns/campaign_pkg
@../campaigns/campaign_body

@update_tail
