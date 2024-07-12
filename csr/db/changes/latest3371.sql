-- Please update version.sql too -- this keeps clean builds in sync
define version=3371
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.metering_options ADD (
	RAW_FEED_DATA_JOBS_ENABLED	NUMBER(1)		DEFAULT 1 NOT NULL,
	CONSTRAINT CK_RAW_FEED_DATA_JOBS_ENABLED CHECK (RAW_FEED_DATA_JOBS_ENABLED IN (0, 1))
);

ALTER TABLE csrimp.metering_options ADD (
	RAW_FEED_DATA_JOBS_ENABLED	NUMBER(1)		NOT NULL,
	CONSTRAINT CK_RAW_FEED_DATA_JOBS_ENABLED CHECK (RAW_FEED_DATA_JOBS_ENABLED IN (0, 1))
);

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
@../csr_data_pkg

@../meter_monitor_body
@../schema_body
@../csrimp/imp_body

@update_tail
