-- Please update version.sql too -- this keeps clean builds in sync
define version=3139
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.METERING_OPTIONS ADD
	PREVENT_MANUAL_FUTURE_READINGS	NUMBER(1)	DEFAULT 0 NOT NULL;
ALTER TABLE CSR.METERING_OPTIONS ADD
	CONSTRAINT CK_MET_OPT_PMFR_0_1 CHECK (PREVENT_MANUAL_FUTURE_READINGS IN(0,1));

ALTER TABLE CSRIMP.METERING_OPTIONS ADD
	PREVENT_MANUAL_FUTURE_READINGS	NUMBER(1)	DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.METERING_OPTIONS ADD
	CONSTRAINT CK_MET_OPT_PMFR_0_1 CHECK (PREVENT_MANUAL_FUTURE_READINGS IN(0,1));

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
@../meter_pkg

@../csrimp/imp_body
@../meter_body
@../schema_body

@update_tail
