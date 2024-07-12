-- Please update version.sql too -- this keeps clean builds in sync
define version=3028
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
declare
	v_exists number;
begin
	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name='DATAVIEW' and column_name='USE_UNMERGED';
	if v_exists !=0 then
		execute immediate 'begin
		insert into csr.dataview_scenario_run (app_sid, dataview_sid, scenario_run_type, scenario_run_sid)
			select app_sid, dataview_sid, case when use_unmerged=1 then 1 else 0 end, null 
			  from csr.dataview
			 where dataview_sid not in (select dataview_sid from csr.dataview_scenario_run);
		commit; end;';

		execute immediate 'alter table csr.dataview drop column use_unmerged';
		execute immediate 'alter table csr.dataview_history drop column use_unmerged';
		execute immediate 'alter table csrimp.dataview drop column use_unmerged';
		execute immediate 'alter table csrimp.dataview_history drop column use_unmerged';
	end if;
end;
/

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
