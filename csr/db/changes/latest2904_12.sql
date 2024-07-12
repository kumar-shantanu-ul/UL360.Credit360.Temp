-- Please update version.sql too -- this keeps clean builds in sync
define version=2904
define minor_version=12
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.approval_dashboard
ADD source_scenario_run_sid NUMBER(10);

ALTER TABLE csr.approval_dashboard ADD CONSTRAINT FK_app_dash_source_scen_run
    FOREIGN KEY (app_sid, source_scenario_run_sid)
    REFERENCES csr.scenario_run(app_sid, scenario_run_sid);

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
@..\approval_dashboard_pkg
@..\approval_dashboard_body

@update_tail
