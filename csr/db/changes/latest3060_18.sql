-- Please update version.sql too -- this keeps clean builds in sync
define version=3060
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DROP INDEX CHAIN.COMPANY_PRODUCT_LOOKUP;

CREATE UNIQUE INDEX CHAIN.COMPANY_PRODUCT_LOOKUP
ON CHAIN.COMPANY_PRODUCT (APP_SID, LOWER(NVL(LOOKUP_KEY, 'NOLOOKUPKEY_' || PRODUCT_ID)));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
