-- Please update version.sql too -- this keeps clean builds in sync
define version=3249
define minor_version=1
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

INSERT INTO csr.compliance_region_map (COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
VALUES (csr.compliance_region_map_id_seq.nextval, 1, 'US', 'UNITED STATES', 'DW', 'DELAWARE', 'us', 'DE');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
