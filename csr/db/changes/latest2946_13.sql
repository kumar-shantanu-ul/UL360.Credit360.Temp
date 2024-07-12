-- Please update version.sql too -- this keeps clean builds in sync
define version=2946
define minor_version=13
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.TPL_REPORT_SCHEDULE
ADD scenario_run_sid NUMBER(10);

ALTER TABLE CSR.TPL_REPORT_SCHEDULE ADD CONSTRAINT FK_TPL_REP_SCHED_SCEN_RUN 
    FOREIGN KEY (APP_SID, SCENARIO_RUN_SID)
    REFERENCES CSR.SCENARIO_RUN(APP_SID, SCENARIO_RUN_SID);


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
@../templated_report_pkg
@../templated_report_body
@../templated_report_schedule_pkg
@../templated_report_schedule_body

@update_tail
