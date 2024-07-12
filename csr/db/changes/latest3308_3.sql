-- Please update version.sql too -- this keeps clean builds in sync
define version=3308
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE campaigns.campaign_region_response ADD response_uuid VARCHAR2(64);

CREATE UNIQUE INDEX campaigns.ix_campaign_response_uuid ON campaigns.campaign_region_response (lower(response_uuid));
-- no csrimp since the new column is globally unique

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
