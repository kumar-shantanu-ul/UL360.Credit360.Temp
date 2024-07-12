-- Please update version.sql too -- this keeps clean builds in sync
define version=3022
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- DUSTAN - PLEASE RUN THESE BEFORE THE REST OF THE RELEASE
-- DUSTAN - PLEASE RUN THESE BEFORE THE REST OF THE RELEASE
-- DUSTAN - PLEASE RUN THESE BEFORE THE REST OF THE RELEASE
-- DUSTAN - PLEASE RUN THESE BEFORE THE REST OF THE RELEASE
-- DUSTAN - PLEASE RUN THESE BEFORE THE REST OF THE RELEASE
-- AND REMOVE THIS CALL TO THIS EXTERNAL SCRIPT, IT WILL HAVE ALREADY RUN ON LIVE
@../utils/populateMeterDataIds
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Make ID column not null
-- (took 2 minutes to run on old wembly)
ALTER TABLE CSR.METER_LIVE_DATA MODIFY (
	METER_DATA_ID		NUMBER(10)	NOT NULL
);

ALTER INDEX CSR.UK_METER_DATA_ID RENAME TO UK_METER_DATA_ID_OLD;

-- Add a unique constraint for the meter_data_id
-- (took 6 minutes to run on old wembly)
ALTER TABLE CSR.METER_LIVE_DATA ADD (
	CONSTRAINT UK_METER_DATA_ID UNIQUE (APP_SID, METER_DATA_ID)
);

-------------------------------------------------------------------------------
-- END OF PRE RELEASE SCRIPT
-------------------------------------------------------------------------------


-- Alter tables

DROP INDEX CSR.IX_METER_LIVE_DATA_ID;
DROP INDEX CSR.UK_METER_DATA_ID_OLD;
DROP INDEX CSR.IX_METER_DATA_ID_REGION;
DROP INDEX CSR.IX_METER_DATA_ID_APP;

DROP TABLE CSR.METER_DATA_ID CASCADE CONSTRAINTS;
DROP TABLE CSRIMP.METER_DATA_ID CASCADE CONSTRAINTS;

CREATE INDEX CSR.IX_TEMP_METER_CONSUMPTION ON CSR.TEMP_METER_CONSUMPTION (
	REGION_SID, METER_INPUT_ID, PRIORITY, START_DTM
);

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
@../schema_pkg

@../csr_app_body
@../enable_body
@../meter_body
@../meter_monitor_body
@../meter_report_body
@../meter_patch_body
@../meter_aggr_body
@../schema_body
@../csrimp/imp_body

@update_tail
