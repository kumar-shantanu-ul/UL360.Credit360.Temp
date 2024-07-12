-- Please update version.sql too -- this keeps clean builds in sync
define version=1953
@update_header

create table csr.calc_job_aggregate_ind_group
(
	app_sid number(10) default sys_context('security', 'app') not null,
	calc_job_id	number(10) not null,
	aggregate_ind_group_id number(10) not null,
	constraint pk_calc_job_agg_ind_group primary key (app_sid, calc_job_id, aggregate_ind_group_id),
	constraint fk_calc_job_aig_calc_job foreign key (app_sid, calc_job_id)
	references csr.calc_job (app_sid, calc_job_id),
	constraint fk_calc_job_aig_aig foreign key (app_sid, aggregate_ind_group_id)
	references csr.aggregate_ind_group (app_sid, aggregate_ind_group_id)
);

create index csr.ix_calc_job_aig_aig on csr.calc_job_aggregate_ind_group (app_sid, aggregate_ind_group_id);

insert into csr.calc_job_aggregate_ind_group (app_sid, calc_job_id, aggregate_ind_group_id)
	select distinct cjai.app_sid, cjai.calc_job_id, aigm.aggregate_ind_group_id
	  from csr.calc_job_aggregate_ind cjai, csr.aggregate_ind_group_member aigm
	 where aigm.app_sid = cjai.app_sid and aigm.ind_sid = cjai.ind_sid;
	 
drop table csr.calc_job_aggregate_ind;

-- RLS
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);
	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
	v_found number;
begin	
	v_list := t_tabs(
		'ACTIVITY_LIKE',
		'CALC_JOB_AGGREGATE_IND_GROUP',
		'SCENARIO_RUN_VERSION',
		'SCENARIO_RUN_VERSION_FILE',
		'SECTION_ATTACH_LOG',
		'ROUTE_LOG',
		'ROUTE_STEP_VOTE',
		'SHEET_AUTOMATIC_APPROVAL',
		'DELEGATION_AUTOMATIC_APPROVAL',
		'DELEGATION_POLICY',
		'FUND',
		'FUND_FORM_PLUGIN',
		'EST_MISMATCHED_ESP_ID',
		'BATCH_JOB_CMS_IMPORT',
		'BATCH_JOB_STRUCTURE_IMPORT',
		'AUDIT_ALERT'
	);
	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin
					
					-- verify that the table has an app_sid column (dev helper)
					select count(*) 
					  into v_found
					  from all_tab_columns 
					 where owner = 'CSR' 
					   and table_name = UPPER(v_list(i))
					   and column_name = 'APP_SID';
					
					if v_found = 0 then
						raise_application_error(-20001, 'CSR.'||v_list(i)||' does not have an app_sid column');
					end if;
					
					if v_i = 1 then
						v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
					else
						v_name := SUBSTR(v_list(i), 1, 21)||'_POLICY_'||v_i;
					end if;
					dbms_output.put_line('doing '||v_name);
				    dbms_rls.add_policy(
				        object_schema   => 'CSR',
				        object_name     => v_list(i),
				        policy_name     => v_name,
				        function_schema => 'CSR',
				        policy_function => 'appSidCheck',
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.context_sensitive );
				  	exit;
				exception
					when policy_already_exists then
						v_i := v_i + 1;
					WHEN FEATURE_NOT_ENABLED THEN
						DBMS_OUTPUT.PUT_LINE('RLS policy '||v_name||' not applied as feature not enabled');
						exit;
				end;
			end loop;
		end;
	end loop;
end;
/

@../stored_calc_datasource_body
@../indicator_body
@../csr_data_body
@../scenario_run_body

@update_tail
