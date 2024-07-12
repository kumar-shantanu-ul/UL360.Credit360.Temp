-- Please update version.sql too -- this keeps clean builds in sync
define version=1862
@update_header

-- create a queue for scrag++ file based scenario testing
BEGIN
	DBMS_AQADM.CREATE_QUEUE_TABLE (
		queue_table        => 'csr.scrag_file_test_queue',
		queue_payload_type => 'csr.t_scrag_queue_entry',
		sort_list		   => 'priority,enq_time'
	);
	DBMS_AQADM.CREATE_QUEUE (
		queue_name  => 'csr.scrag_file_test_queue',
		queue_table => 'csr.scrag_file_test_queue'
	);
	DBMS_AQADM.START_QUEUE (
		queue_name => 'csr.scrag_file_test_queue'
	);
END;
/

@../stored_calc_datasource_pkg
@../stored_calc_datasource_body
@../scenario_run_pkg
@../scenario_run_body

@update_tail
