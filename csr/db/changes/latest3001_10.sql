-- Please update version.sql too -- this keeps clean builds in sync
define version=3001
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- Note that this drops and creates tables, so is in fact DDL rather than DML
DECLARE
	v_enqueue_options				dbms_aq.enqueue_options_t;
	v_message_properties			dbms_aq.message_properties_t;
	v_message_handle				RAW(16);
BEGIN
	DBMS_AQADM.STOP_QUEUE (
		queue_name => 'csr.batch_job_queue'
	);
	DBMS_AQADM.DROP_QUEUE (
		queue_name  => 'csr.batch_job_queue'
	);
	DBMS_AQADM.DROP_QUEUE_TABLE (
		queue_table        => 'csr.batch_job_queue'
	);
	DBMS_AQADM.CREATE_QUEUE_TABLE (
		queue_table        => 'csr.batch_job_queue',
		queue_payload_type => 'csr.t_batch_job_queue_entry',
		sort_list		   => 'priority,enq_time'
	);
	DBMS_AQADM.CREATE_QUEUE (
		queue_name  => 'csr.batch_job_queue',
		queue_table => 'csr.batch_job_queue',
		max_retries => 2147483647
	);
	DBMS_AQADM.START_QUEUE (
		queue_name => 'csr.batch_job_queue'
	);
	FOR r IN (SELECT batch_job_id
				FROM csr.batch_job
			   WHERE completed_dtm IS NULL) LOOP

		UPDATE csr.batch_job
		   SET completed_dtm = NULL,
			   processing = 0
		 WHERE batch_job_id = r.batch_job_id;

		-- queue for processing (becomes available at commit time)
		dbms_aq.enqueue(
			queue_name			=> 'csr.batch_job_queue',
			enqueue_options		=> v_enqueue_options,
			message_properties	=> v_message_properties,
 			payload				=> csr.t_batch_job_queue_entry (r.batch_job_id),
 			msgid				=> v_message_handle
 		);
	END LOOP;
	COMMIT;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***

-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
