-- Please update version too -- this keeps clean builds in sync
define version=1702
@update_header

-- clean out junk in csrimp
begin
	for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
		execute immediate 'truncate table csrimp.'||r.table_name;
	end loop;
	delete from csrimp.csrimp_session;
	commit;
end;
/

alter table csrimp.scenario modify equality_epsilon null;
alter table csrimp.customer modify equality_epsilon default null;

grant select on actions.scenario_filter_status to csr;
grant select on actions.task_ind_template_instance to csr;

@../scenario_pkg
@../scenario_body
@../actions/scenario_body

@update_tail