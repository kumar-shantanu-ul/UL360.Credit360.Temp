-- Please update version.sql too -- this keeps clean builds in sync
define version=3117
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'UK', 'UNITED KINGDOM', null, null, 'gb', null);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../compliance_body

@update_tail
