-- Please update version.sql too -- this keeps clean builds in sync
define version=2752
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DROP INDEX CSR.UK_EST_JOB;

CREATE UNIQUE INDEX CSR.UK_EST_JOB ON CSR.EST_JOB(APP_SID, EST_JOB_TYPE_ID, EST_ACCOUNT_SID, PM_CUSTOMER_ID, PM_BUILDING_ID, PM_SPACE_ID, PM_METER_ID, REGION_SID, PROCESSING);


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***

@update_tail
