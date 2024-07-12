-- Please update version.sql too -- this keeps clean builds in sync
define version=3020
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
insert into csr.dataview_scenario_run (app_sid, dataview_sid, scenario_run_type, scenario_run_sid)
	select app_sid, dataview_sid, case when use_unmerged=1 then 1 else 0 end, null 
	  from csr.dataview
	 where dataview_sid not in (select dataview_sid from csr.dataview_scenario_run);

alter table csr.dataview drop column use_unmerged;
alter table csr.dataview_history drop column use_unmerged;
alter table csrimp.dataview drop column use_unmerged;
alter table csrimp.dataview_history drop column use_unmerged;

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

@../dataview_pkg
@../dataview_body
@../schema_body
@../csrimp/imp_body

@update_tail
