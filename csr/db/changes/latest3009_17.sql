-- Please update version.sql too -- this keeps clean builds in sync
define version=3009
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- ID column nullable for now
ALTER TABLE CSR.METER_LIVE_DATA ADD (
	METER_DATA_ID		NUMBER(10)
);

-- Until the step where we copy all the existing IDs from the meter_data_id table over we need to 
-- allow nulls in the meter_data_id column but want to constrain the ID to be unique if it's not null. 
--After all the IDS have been copied over we can switch this functional index out for a unique constraint.
CREATE UNIQUE INDEX CSR.IX_METER_LIVE_DATA_ID ON CSR.METER_LIVE_DATA(DECODE(METER_DATA_ID, NULL, NULL, APP_SID), METER_DATA_ID);

ALTER TABLE CSRIMP.METER_LIVE_DATA ADD (
	METER_DATA_ID		NUMBER(10)
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
@../meter_monitor_body

@update_tail
