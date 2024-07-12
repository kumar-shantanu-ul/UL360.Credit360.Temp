-- Please update version.sql too -- this keeps clean builds in sync
define version=1063
@update_header

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
		queue_table => 'csr.scrag_queue'
	);
	DBMS_AQADM.START_QUEUE (
		queue_name => 'csr.scrag_queue'
	);
END;
/

declare
	v_enqueue_options				dbms_aq.enqueue_options_t;
	v_message_properties			dbms_aq.message_properties_t;
	v_message_handle				RAW(16);
begin
	for r in (select cj.calc_job_id, cj.unmerged, cj.scenario_run_sid, c.calc_job_priority
				from csr.calc_job cj, csr.customer c
			   where cj.app_sid = c.app_sid) loop
		v_message_properties.priority := r.calc_job_priority * (1 +
			(case when r.scenario_run_sid is not null then 2 else 0 end) + 
			(case when r.unmerged = 1 then 1 else 0 end)
		);
		dbms_aq.enqueue(
			queue_name			=> 'csr.scrag_queue',
			enqueue_options		=> v_enqueue_options,
			message_properties	=> v_message_properties,
	 		payload				=> csr.t_scrag_queue_entry (r.calc_job_id),
	 		msgid				=> v_message_handle
	 	);
	end loop;
end;
/

@update_tail
