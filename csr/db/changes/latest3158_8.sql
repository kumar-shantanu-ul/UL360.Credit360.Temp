-- Please update version.sql too -- this keeps clean builds in sync
define version=3158
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- Change from latest2801 was left out of schema.sql - apply change to any new databases with wrong PK
BEGIN
	-- Remove existing PK
	FOR r IN (
		SELECT constraint_name
		  FROM all_constraints
		 WHERE owner = 'CSRIMP'
		   AND table_name = 'METER_LIVE_DATA'
		   AND constraint_type = 'P'
	) LOOP
		EXECUTE IMMEDIATE('ALTER TABLE CSRIMP.METER_LIVE_DATA DROP CONSTRAINT  '||r.constraint_name||' DROP INDEX');
	END LOOP;
END;
/

ALTER TABLE CSRIMP.METER_LIVE_DATA ADD(
	CONSTRAINT PK_METER_LIVE_DATA PRIMARY KEY (CSRIMP_SESSION_ID, REGION_SID, METER_BUCKET_ID, METER_INPUT_ID, AGGREGATOR, PRIORITY, START_DTM)
);

-- *** Grants ***

-- These were missing on demodb
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_item_history TO tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_region_tag TO tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_root_regions TO tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
