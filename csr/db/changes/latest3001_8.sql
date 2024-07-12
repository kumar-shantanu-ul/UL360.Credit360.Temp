-- Please update version.sql too -- this keeps clean builds in sync
define version=3001
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
alter table csr.scenario add constraint fk_scenario_data_source_run foreign key (app_sid, data_source_run_sid)
references csr.scenario_run (app_sid, scenario_run_sid);
create index csr.ix_scenario_data_source_run on csr.scenario (app_sid, data_source_run_sid);

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

@update_tail
