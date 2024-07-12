-- Please update version.sql too -- this keeps clean builds in sync
define version=1661
@update_header

alter table csr.scenario add scrag_test_scenario number(1) default 0 not null;
alter table csr.scenario add constraint ck_scenario_scrag_test check (scrag_test_scenario in (0,1));

alter table csr.calc_job drop constraint CK_CALC_JOB_DATA_SOURCE;
alter table csr.calc_job add constraint CK_CALC_JOB_DATA_SOURCE CHECK (DATA_SOURCE IN (0,1,2,3));

grant execute on csr.t_scrag_queue_entry to web_user;

-- create a queue for scrag++ testing
BEGIN
	DBMS_AQADM.CREATE_QUEUE_TABLE (
		queue_table        => 'csr.scrag_test_queue',
		queue_payload_type => 'csr.t_scrag_queue_entry',
		sort_list		   => 'priority,enq_time'
	);
	DBMS_AQADM.CREATE_QUEUE (
		queue_name  => 'csr.scrag_test_queue',
		queue_table => 'csr.scrag_test_queue'
	);
	DBMS_AQADM.START_QUEUE (
		queue_name => 'csr.scrag_test_queue'
	);
END;
/

@../stored_calc_datasource_pkg
@../stored_calc_datasource_body
@../region_pkg
@../region_body

@update_tail
