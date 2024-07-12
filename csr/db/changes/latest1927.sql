-- Please update version.sql too -- this keeps clean builds in sync
define version=1927
@update_header

alter table csr.scenario_run_version_file drop constraint pk_scenario_run_version_file drop index;
alter table csr.scenario_run_version_file drop column interval;
alter table csr.scenario_run_version_file add constraint pk_scenario_run_version_file 
primary key (app_sid, scenario_run_sid, version);

-- recreate queues with larger retry limits due to the Oracle documentation begin duff
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
		queue_payload_type => 'csr.t_scrag_queue_entry',
		sort_list		   => 'priority,enq_time'
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
		queue_table        => 'csr.scrag_test_queue',
		queue_payload_type => 'csr.t_scrag_queue_entry',
		sort_list		   => 'priority,enq_time'
	);
	DBMS_AQADM.CREATE_QUEUE (
		queue_name  => 'csr.scrag_test_queue',
		queue_table => 'csr.scrag_test_queue',
		max_retries => 2147483647
	);
	DBMS_AQADM.START_QUEUE (
		queue_name => 'csr.scrag_test_queue'
	);
	DBMS_AQADM.CREATE_QUEUE_TABLE (
		queue_table        => 'csr.scrag_file_test_queue',
		queue_payload_type => 'csr.t_scrag_queue_entry',
		sort_list		   => 'priority,enq_time'
	);
	DBMS_AQADM.CREATE_QUEUE (
		queue_name  => 'csr.scrag_file_test_queue',
		queue_table => 'csr.scrag_file_test_queue',
		max_retries => 2147483647
	);
	DBMS_AQADM.START_QUEUE (
		queue_name => 'csr.scrag_file_test_queue'
	);
END;
/

DECLARE
	v_enqueue_options				dbms_aq.enqueue_options_t;
	v_message_properties			dbms_aq.message_properties_t;
	v_message_handle				RAW(16);
	v_scrag_test_scenario			csr.scenario.scrag_test_scenario%TYPE := 0;
	v_file_based					csr.scenario.file_based%TYPE := 0;
	v_scrag_queue					csr.customer.scrag_queue%TYPE;
BEGIN	
	FOR r IN (
		SELECT c.app_sid, c.calc_job_priority, c.scrag_queue, cj.calc_job_id, cj.scenario_run_sid, cj.data_source
		  FROM csr.customer c, csr.calc_job cj
		 WHERE c.app_sid = cj.app_sid
	) LOOP
		-- 0 = merged
		-- 1 = unmerged
		-- 2 = merged scenario
		-- 3 = pct ownership
		-- * customer_priority  
		v_message_properties.priority := r.calc_job_priority + (1 +
			(case when r.scenario_run_sid is not null then 2 else 0 end) + 
			(case when r.data_source <> 0 then 1 else 0 end)
		);
		
		-- see if this is a test job for scrag++
		IF r.scenario_run_sid IS NOT NULL THEN
			SELECT scrag_test_scenario, file_based
			  INTO v_scrag_test_scenario, v_file_based
			  FROM csr.scenario s, csr.scenario_run sr
			 WHERE s.app_sid = r.app_sid
			   AND s.app_sid = sr.app_sid AND s.scenario_sid = sr.scenario_sid
			   AND sr.scenario_run_sid = r.scenario_run_sid;
		END IF;
		
		IF v_scrag_test_scenario = 1 THEN
			IF v_file_based = 1 THEN
				v_scrag_queue := 'csr.scrag_file_test_queue';
			ELSE
				v_scrag_queue := 'csr.scrag_test_queue';
			END IF;
		ELSE
			v_scrag_queue := NVL(v_scrag_queue, 'csr.scrag_queue');
		END IF;

		-- queue for processing (becomes available at commit time)
		dbms_aq.enqueue(
			queue_name			=> v_scrag_queue,
			enqueue_options		=> v_enqueue_options,
			message_properties	=> v_message_properties,
	 		payload				=> csr.t_scrag_queue_entry (r.calc_job_id),
	 		msgid				=> v_message_handle
	 	);
	END LOOP;
	COMMIT;
END;
/

@../stored_calc_datasource_pkg
@../scenario_run_pkg
@../stored_calc_datasource_body
@../scenario_run_body

@update_tail
