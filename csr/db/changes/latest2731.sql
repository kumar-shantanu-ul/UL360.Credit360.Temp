-- Please update version.sql too -- this keeps clean builds in sync
define version=2731
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csrimp.chain_saved_filter_agg_type DROP CONSTRAINT UK_CHAIN_SAVED_FIL_AGG_TYP;

ALTER TABLE csrimp.chain_saved_filter_agg_type ADD CONSTRAINT UK_CHAIN_SAVED_FIL_AGG_TYP
	UNIQUE (CSRIMP_SESSION_ID, SAVED_FILTER_SID, AGGREGATION_TYPE, CMS_AGGREGATE_TYPE_ID)
;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***

@update_tail
