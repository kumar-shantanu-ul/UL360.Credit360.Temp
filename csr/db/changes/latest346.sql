-- Please update version.sql too -- this keeps clean builds in sync
define version=346
@update_header

create global temporary table rag_temp_tree (
	app_sid number(10),
	region_sid number(10),
	parent_sid number(10)
) on commit delete rows;

alter table customer rename column aggregate_active to aggregation_engine_version;
update customer set aggregation_engine_version = 1;
alter table customer add constraint ck_aggregation_engine_version check (aggregation_engine_version in (1,2));

declare
	job_running exception;
	pragma exception_init(job_running, -27478);
begin
	loop
		begin
			dbms_scheduler.drop_job('csr.AggregateAllTrees');
			exit;
		exception
			when job_running then
				dbms_lock.sleep(5);
		end;
	end loop;
end;
/

@..\csr_app_pkg
@..\indicator_pkg
@..\region_pkg
@..\system_status_pkg
@..\rag_pkg
@..\csr_app_body
@..\region_body
@..\indicator_body
@..\val_body
@..\rag_body
@..\system_status_body
@..\..\..\aspen2\tools\recompile_packages

grant execute on rag_pkg to web_user;

@update_tail
