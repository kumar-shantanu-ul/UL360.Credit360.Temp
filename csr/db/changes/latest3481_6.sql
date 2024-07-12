-- Please update version.sql too -- this keeps clean builds in sync
define version=3481
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.CUSTOMER_FEATURE_FLAGS(
    APP_SID                 NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    FEATURE_FLAG_SCRAG_A    NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    FEATURE_FLAG_SCRAG_B    NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    FEATURE_FLAG_SCRAG_C    NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CONSTRAINT PK_CUSTOMER_FEATURE_FLAGS PRIMARY KEY (APP_SID),
    CONSTRAINT CHK_CUSTOMER_FEATURE_FLAGS_SCRAG_A CHECK (FEATURE_FLAG_SCRAG_A IN (0, 1)),
    CONSTRAINT CHK_CUSTOMER_FEATURE_FLAGS_SCRAG_B CHECK (FEATURE_FLAG_SCRAG_B IN (0, 1)),
    CONSTRAINT CHK_CUSTOMER_FEATURE_FLAGS_SCRAG_C CHECK (FEATURE_FLAG_SCRAG_C IN (0, 1))
)
;

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.capability (name, allow_by_default, description) 
VALUES ('Enable Temporal Aggregation on Measure Conversion Flycalcs', 0, 'Enable Temporal Aggregation on Measure Conversion Flycalcs');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../scenario_run_pkg
@../scenario_run_body
@../stored_calc_datasource_body

@update_tail
