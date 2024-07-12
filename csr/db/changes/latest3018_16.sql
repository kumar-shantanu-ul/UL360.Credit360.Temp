-- Please update version.sql too -- this keeps clean builds in sync
define version=3018
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables

-- Down Migration
-- DROP INDEX chain.ix_bus_rel_type_per_interval;
-- ALTER TABLE chain.business_relationship_type DROP CONSTRAINT FK_BUS_REL_TYPE_PER_INTERVAL;
-- ALTER TABLE chain.business_relationship_type DROP CONSTRAINT CHK_BRT_USE_SPECIFIC_DATES;
-- ALTER TABLE chain.business_relationship_type DROP CONSTRAINT CHK_BRT_PERIOD_IDS;
-- ALTER TABLE chain.business_relationship_type DROP COLUMN USE_SPECIFIC_DATES;
-- ALTER TABLE chain.business_relationship_type DROP COLUMN PERIOD_SET_ID;
-- ALTER TABLE chain.business_relationship_type DROP COLUMN PERIOD_INTERVAL_ID;

-- Alter tables
ALTER TABLE chain.business_relationship_type 
	ADD USE_SPECIFIC_DATES NUMBER(1,0) DEFAULT 1 NOT NULL
	ADD PERIOD_SET_ID NUMBER(10,0) DEFAULT NULL
	ADD PERIOD_INTERVAL_ID NUMBER(10,0) DEFAULT NULL;

ALTER TABLE chain.business_relationship_type
	ADD CONSTRAINT FK_BUS_REL_TYPE_PER_INTERVAL FOREIGN KEY (APP_SID, PERIOD_SET_ID, PERIOD_INTERVAL_ID)
	  REFERENCES CSR.PERIOD_INTERVAL (APP_SID, PERIOD_SET_ID, PERIOD_INTERVAL_ID);

ALTER TABLE chain.business_relationship_type
 ADD CONSTRAINT CHK_BRT_USE_SPECIFIC_DATES CHECK (USE_SPECIFIC_DATES IN (0,1)) ENABLE;

ALTER TABLE chain.business_relationship_type
 ADD CONSTRAINT CHK_BRT_PERIOD_IDS CHECK ((USE_SPECIFIC_DATES = 1 AND PERIOD_SET_ID IS NULL AND PERIOD_INTERVAL_ID IS NULL) OR (USE_SPECIFIC_DATES = 0 AND PERIOD_SET_ID IS NOT NULL AND PERIOD_INTERVAL_ID IS NOT NULL)) ENABLE;
                
CREATE INDEX CHAIN.IX_BUS_REL_TYPE_PER_INTERVAL ON CHAIN.BUSINESS_RELATIONSHIP_TYPE (APP_SID, PERIOD_SET_ID, PERIOD_INTERVAL_ID);
 
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
@../chain/business_relationship_pkg
@../chain/business_relationship_body

@update_tail
