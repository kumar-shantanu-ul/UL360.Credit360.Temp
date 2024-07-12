-- Please update version.sql too -- this keeps clean builds in sync
define version=1481
@update_header

declare
v_c number;
begin
select count(*) into v_c
from all_constraints
where owner = 'CSR' and table_name = 'MODEL_INSTANCE_CHART' and constraint_name = 'FK_MIC_MI';
if v_c > 0 then
execute immediate 'alter table csr.model_instance_chart drop constraint fk_mic_mi';
end if;
select count(*) into v_c
from all_constraints
where owner = 'CSR' and table_name = 'MODEL_INSTANCE_REGION' and constraint_name = 'FK_MIR_MI';
if v_c > 0 then
execute immediate 'alter table csr.model_instance_region drop constraint fk_mir_mi';
end if;
select count(*) into v_c
from all_constraints
where owner = 'CSR' and table_name = 'MODEL_INSTANCE_SHEET' and constraint_name = 'FK_MIS_MI';
if v_c > 0 then
execute immediate 'alter table csr.model_instance_sheet drop constraint fk_mis_mi';
end if;
select count(*) into v_c
from all_constraints
where owner = 'CSR' and table_name = 'MODEL_INSTANCE_MAP' and constraint_name = 'FK_MIM_MI';
if v_c > 0 then
execute immediate 'alter table csr.model_instance_map drop constraint fk_mim_mi';
end if;
end;
/

alter table csr.model_instance drop primary key drop index;

alter table csr.model_instance add constraint pk_model_instance primary key (app_sid, model_instance_sid, base_model_sid);
alter table csr.model_instance_map add constraint fk_mim_mi 
    foreign key (app_sid, model_instance_sid, base_model_sid)
    references csr.model_instance(app_sid, model_instance_sid, base_model_sid)
;
alter table csr.model_instance_sheet add constraint fk_mis_mi 
    foreign key (app_sid, model_instance_sid, base_model_sid)
    references csr.model_instance(app_sid, model_instance_sid, base_model_sid)
;
alter table csr.model_instance_region add constraint fk_mir_mi 
    foreign key (app_sid, model_instance_sid, base_model_sid)
    references csr.model_instance(app_sid, model_instance_sid, base_model_sid)
;
alter table csr.model_instance_chart add constraint fk_mic_mi
	foreign key (app_sid, model_instance_sid, base_model_sid)
	references csr.model_instance (app_sid, model_instance_sid, base_model_sid);

insert into csr.batch_job_type (batch_job_type_id, description, plugin_name)
values (2, 'Excel model run', 'excel-model-run');

create table csr.batch_job_excel_model
(
	app_sid number(10, 0) default sys_context('SECURITY', 'APP') not null,
	batch_job_id number(10, 0) not null,
	model_instance_sid number(10, 0) not null,
	base_model_sid number(10, 0) not null,
	instance_run number(20, 0) not null,
	constraint pk_bjem primary key (app_sid, batch_job_id)
);

alter table csr.batch_job_excel_model add constraint fk_bj_bjem
foreign key (app_sid, batch_job_id)
references csr.batch_job(app_sid, batch_job_id) on delete cascade
;

alter table csr.batch_job_excel_model add constraint fk_bjem_mi
foreign key (app_sid, model_instance_sid, base_model_sid)
references csr.model_instance(app_sid, model_instance_sid, base_model_sid) on delete cascade
;

declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'BATCH_JOB_EXCEL_MODEL'
	);
	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin
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
				    -- dbms_output.put_line('done  '||v_name);
				  	exit;
				exception
					when policy_already_exists then
						v_i := v_i + 1;
				end;
			end loop;
		end;
	end loop;
end;
/

@..\batch_job_pkg
@..\model_pkg
@..\model_body

@update_tail
