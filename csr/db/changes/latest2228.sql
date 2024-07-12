-- Please update version.sql too -- this keeps clean builds in sync
define version=2228
@update_header

-- XXX: needs to be run as sys.
declare
	insufficient_privileges exception;
	pragma exception_init(insufficient_privileges, -1031);
begin
	begin
		execute immediate 'grant select on sys.dbms_lock_allocated to csr';
	exception
		when insufficient_privileges then
			raise_application_error(-20001, 'insufficient privileges on sys.dbms_lock_allocated -- please re-run c360dba.sql');
	end;
	begin
		execute immediate 'grant select on sys.v_$lock to csr';
	exception
		when insufficient_privileges then
			raise_application_error(-20001, 'insufficient privileges on sys.v_$lock -- please re-run c360dba.sql');
	end;
end;
/

alter table csr.calc_job add priority number(10) default 1 not null;
alter table csr.calc_job add full_recompute number(1) default 0 not null;
alter table csr.calc_job add constraint ck_calc_job_full_recompute check (full_recompute in (0,1));
alter table csr.scenario_run_version_file drop column discard;
alter table csr.calc_job add process_after_dtm date default sysdate not null;
alter table csr.calc_job add calc_queue_id number(10) default 0 not null;

create table csr.calc_queue (
	calc_queue_id	number(1) not null,
	name			varchar2(100),
	constraint pk_calc_queue primary key (calc_queue_id),
	constraint uk_calc_queue unique (name),
	constraint ck_calc_queue_name check (name = upper(name))
);

insert into csr.calc_queue values (0, 'CSR.SCRAG_QUEUE');
insert into csr.calc_queue values (1, 'CSR.SCRAGPP_QUEUE');
insert into csr.calc_queue values (2, 'CSR.SCRAG_DEBUG_QUEUE');

alter table csr.calc_job add constraint fk_calc_job_calc_queue
foreign key (calc_queue_id) references csr.calc_queue (calc_queue_id);

alter table csr.scenario_auto_run_request add full_recompute number(1) default 0 not null;
alter table csr.scenario_auto_run_request add constraint ck_scn_auto_run_req_frecomput check (full_recompute in (0, 1));

BEGIN
	DBMS_AQADM.STOP_QUEUE (
		queue_name => 'csr.scrag_queue'
	);
	DBMS_AQADM.DROP_QUEUE (
		queue_name  => 'csr.scrag_queue'
	);
	DBMS_AQADM.DROP_QUEUE_TABLE (
		queue_table        => 'csr.scrag_queue'
	);
	DBMS_AQADM.STOP_QUEUE (
		queue_name => 'csr.scrag_test_queue'
	);
	DBMS_AQADM.DROP_QUEUE (
		queue_name  => 'csr.scrag_test_queue'
	);
	DBMS_AQADM.DROP_QUEUE_TABLE (
		queue_table        => 'csr.scrag_test_queue'
	);
	DBMS_AQADM.STOP_QUEUE (
		queue_name => 'csr.scrag_file_test_queue'
	);
	DBMS_AQADM.DROP_QUEUE (
		queue_name  => 'csr.scrag_file_test_queue'
	);
	DBMS_AQADM.DROP_QUEUE_TABLE (
		queue_table        => 'csr.scrag_file_test_queue'
	);
END;
/

BEGIN
	DBMS_AQADM.CREATE_QUEUE_TABLE (
		queue_table        => 'csr.scrag_queue',
		queue_payload_type => 'csr.t_scrag_queue_entry'
	);
	DBMS_AQADM.CREATE_QUEUE (
		queue_name  => 'csr.scrag_queue',
		queue_table => 'csr.scrag_queue',
		max_retries => 2147483647
	);
	DBMS_AQADM.START_QUEUE (
		queue_name => 'csr.scrag_queue'
	);
	DBMS_AQADM.CREATE_QUEUE_TABLE (
		queue_table        => 'csr.scragpp_queue',
		queue_payload_type => 'csr.t_scrag_queue_entry'
	);
	DBMS_AQADM.CREATE_QUEUE (
		queue_name  => 'csr.scragpp_queue',
		queue_table => 'csr.scragpp_queue',
		max_retries => 2147483647
	);
	DBMS_AQADM.START_QUEUE (
		queue_name => 'csr.scragpp_queue'
	);
END;
/

@../stored_calc_datasource_pkg
@../stored_calc_datasource_body
@../csr_app_pkg
@../csr_app_body
@../region_body

@update_tail
