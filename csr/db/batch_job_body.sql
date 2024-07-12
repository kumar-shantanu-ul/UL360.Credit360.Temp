CREATE OR REPLACE PACKAGE BODY CSR.batch_job_pkg AS

-- No security, only called by the batch
PROCEDURE StartDispatcher
AS
	v_lock_handle 					VARCHAR2(128);
	v_lock_result 					INTEGER;
BEGIN
	dbms_lock.allocate_unique(
		lockname 			=> 'BATCH_JOB_'||SYS_CONTEXT('USERENV', 'HOST'),
		lockhandle			=> v_lock_handle
	);
	v_lock_result := dbms_lock.request(
		lockhandle 			=> v_lock_handle, 
		lockmode 			=> dbms_lock.x_mode, 
		timeout 			=> 5, 
		release_on_commit	=> FALSE
	);
	-- Already held may result due to Oracle connection pooling -- if the dispatcher
	-- fails and restarts internally it may not have released the lock.  This doesn't
	-- matter.
	IF v_lock_result NOT IN (0, 4) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Failed to take the dispatcher lock BATCH_JOB_'
			||SYS_CONTEXT('USERENV', 'HOST')||' with '||v_lock_result);
	END IF;
	
	-- mark any jobs we dequeued but didn't dispatch as failed
	UPDATE batch_job
	   SET running_on = NULL,
	   	   work_done = 0,
	   	   total_work = 0,
	   	   updated_dtm = SYSDATE
	 WHERE running_on = SYS_CONTEXT('USERENV', 'HOST');	
END;

PROCEDURE Enqueue(
	in_batch_job_type_id			IN	batch_job.batch_job_type_id%TYPE,
	in_description					IN	batch_job.description%TYPE DEFAULT NULL,
	in_email_on_completion			IN	batch_job.email_on_completion%TYPE DEFAULT 0,
	in_total_work					IN	batch_job.total_work%TYPE DEFAULT 0,
	in_requesting_user				IN  batch_job.requested_by_user_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY','SID'),
	in_requesting_company			IN  batch_job.requested_by_company_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),
	in_in_order_group				IN	batch_job.in_order_group%TYPE DEFAULT NULL,
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
)
AS
	v_priority						batch_job.priority%TYPE;
BEGIN
	SELECT NVL(bjtac.priority, bjt.priority) priority
	  INTO v_priority
	  FROM batch_job_type bjt
	  LEFT JOIN batch_job_type_app_cfg bjtac ON bjt.batch_job_type_id = bjtac.batch_job_type_id
	 WHERE bjt.batch_job_type_id = in_batch_job_type_id;

	-- no security: this is a utility function that other code should call, and that
	-- code should be doing the security checks
	INSERT INTO batch_job
		(batch_job_id, description, batch_job_type_id, email_on_completion, total_work,
		 requested_by_user_sid, requested_by_company_sid, priority, in_order_group)
	VALUES
		(batch_job_id_seq.nextval, in_description, in_batch_job_type_id, in_email_on_completion,
		 in_total_work, in_requesting_user, in_requesting_company, v_priority, in_in_order_group)
	RETURNING
		batch_job_id INTO out_batch_job_id;
END;

PROCEDURE Requeue(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE
)
AS
BEGIN
	-- no security: this is a utility function for developer use
	UPDATE batch_job
	   SET completed_dtm = NULL
	 WHERE batch_job_id = in_batch_job_id;
	IF SQL%ROWCOUNT = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND,
			'The batch job with id '||in_batch_job_id||' could not be found');
	END IF;
END;

PROCEDURE SetProgress(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	in_work_done					IN	batch_job.work_done%TYPE,
	in_total_work					IN	batch_job.total_work%TYPE DEFAULT NULL
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	-- no security, called from the batch
	UPDATE batch_job
	   SET work_done = in_work_done,
	   	   total_work = NVL(in_total_work, total_work),
	   	   updated_dtm = SYSDATE
	 WHERE batch_job_id = in_batch_job_id;

	IF SQL%ROWCOUNT = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'The batch job with id '||in_batch_job_id||' does not exist');
	END IF;

	COMMIT;
END;

PROCEDURE GetProgress(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security check: only shows jobs submitted by the current user
	OPEN out_cur FOR
		SELECT requested_dtm, email_on_completion, started_dtm, completed_dtm,
		       updated_dtm, retry_dtm, work_done, total_work, result, result_url, failed
		  FROM batch_job
		 WHERE batch_job_id = in_batch_job_id
		   AND requested_by_user_sid = SYS_CONTEXT('SECURITY', 'SID');
END;

PROCEDURE GetProgresses(
	in_batch_job_ids				IN	security_pkg.T_SID_IDS,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_job_ids				security.T_SID_TABLE;
BEGIN
	v_job_ids := security_pkg.SidArrayToTable(in_batch_job_ids);

	OPEN out_cur FOR
		SELECT requested_dtm, email_on_completion, started_dtm, completed_dtm,
		       updated_dtm, retry_dtm, work_done, total_work, result, result_url, failed
		  FROM batch_job
		 WHERE batch_job_id in (select column_value from TABLE(v_job_ids))
		   AND requested_by_user_sid = SYS_CONTEXT('SECURITY', 'SID');
END;

PROCEDURE MarkRunning(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	in_running_by_worker_id			IN	batch_job.running_by_worker_id%TYPE,
	in_running_by_pid				IN	batch_job.running_by_pid%TYPE
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	UPDATE batch_job
	   SET running_by_pid = in_running_by_pid,
		   running_by_worker_id = in_running_by_worker_id,
		   running_by_sid = SYS_CONTEXT('USERENV', 'SID'),
		   running_on = SYS_CONTEXT('USERENV', 'HOST')
	 WHERE batch_job_id = in_batch_job_id;
	COMMIT;
END;

PROCEDURE GetDetails(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security check: only called from the batch application
	OPEN out_cur FOR
		SELECT bj.app_sid, bj.batch_job_id, bjt.batch_job_type_id,
			   bjt.description batch_job_type_description, bj.requested_by_user_sid, bj.requested_by_company_sid,
			   bj.email_on_completion, bjt.sp, bjt.plugin_name, bj.description,
			   bj.attempts, bj.notified, bjt.notify_address, bjt.max_retries,
			   c.host
		  FROM batch_job bj, batch_job_type bjt, customer c
		 WHERE bj.batch_job_type_id = bjt.batch_job_type_id
		   AND bj.batch_job_id = in_batch_job_id
		   AND bj.app_sid = c.app_sid;
END;

PROCEDURE StartProcessing(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	in_running_by_worker_id			IN	batch_job.running_by_worker_id%TYPE,
	in_running_by_pid				IN	batch_job.running_by_pid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_lock_handle 					VARCHAR2(128);
	v_lock_result 					INTEGER;
BEGIN
	dbms_lock.allocate_unique(
		lockname 			=> 'BATCH_JOB_'||SYS_CONTEXT('USERENV', 'HOST')||'_'||in_running_by_worker_id,
		lockhandle			=> v_lock_handle
	);
	v_lock_result := dbms_lock.request(
		lockhandle 			=> v_lock_handle, 
		lockmode 			=> dbms_lock.x_mode, 
		timeout 			=> 5,
		release_on_commit	=> FALSE
	);
	
	-- the lock may already be held: that's ok, it's from connection pooling
	-- we never bother to unlock it explicitly as it's only used to check if
	-- a job has been lost -- if the process is still alive then the job isn't lost.
	IF v_lock_result NOT IN (0, 4) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Failed to take the worker lock BATCH_JOB_'||
			SYS_CONTEXT('USERENV', 'HOST')||'_'||in_running_by_worker_id||
			' with '||v_lock_result);
	END IF;

	MarkRunning(in_batch_job_id, in_running_by_worker_id, in_running_by_pid);
	GetDetails(in_batch_job_id, out_cur);
END;

PROCEDURE GetJobs(
	in_all_jobs						IN	NUMBER,
	in_filter_user_sid				IN	NUMBER,
	in_batch_job_type_id			IN	NUMBER DEFAULT -1,
	in_filter_date_start			IN	DATE,
	in_filter_date_end				IN	DATE,
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	out_total_rows					OUT	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_filter_user_sid				NUMBER := SYS_CONTEXT('SECURITY', 'SID');
BEGIN

	IF csr_user_pkg.IsSuperAdmin = 1 OR csr_data_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'ACT'), 'Manage jobs') THEN
		IF in_all_jobs = 0 THEN
			v_filter_user_sid := NVL(in_filter_user_sid, v_filter_user_sid);
		ELSE
			v_filter_user_sid := NULL;
		END IF;
	END IF;

	SELECT COUNT(*)
	  INTO out_total_rows
	  FROM batch_job
	 WHERE (NVL(in_batch_job_type_id, -1) = -1 OR batch_job_type_id = in_batch_job_type_id)
	   AND (in_filter_date_start IS NULL OR requested_dtm > in_filter_date_start)
	   AND (in_filter_date_end IS NULL OR requested_dtm < in_filter_date_end)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND (v_filter_user_sid IS NULL OR requested_by_user_sid = v_filter_user_sid);

	OPEN out_cur FOR
		SELECT *
		  FROM (SELECT bj.*, rownum rn
			      FROM (SELECT bj.batch_job_id, bj.batch_job_type_id, bj.batch_job_type_description,
			      			   bj.requested_by_user_sid, bj.requested_by_full_name, bj.requested_by_company_sid,
							   bj.requested_by_email, bj.requested_dtm, bj.email_on_completion, bj.started_dtm,
							   bj.completed_dtm, bj.updated_dtm, bj.retry_dtm, bj.work_done, bj.total_work,
							   bj.description, bj.result, bj.result_url, bj.aborted_dtm, bj.failed
						  FROM v$batch_job bj
						 WHERE (NVL(in_batch_job_type_id, -1) = -1 OR batch_job_type_id = in_batch_job_type_id)
						   AND (in_filter_date_start IS NULL OR requested_dtm > in_filter_date_start)
						   AND (in_filter_date_end IS NULL OR requested_dtm < in_filter_date_end)
						   AND bj.app_sid = SYS_CONTEXT('SECURITY', 'APP')
						   AND (v_filter_user_sid IS NULL OR bj.requested_by_user_sid = v_filter_user_sid)
						 ORDER BY bj.requested_dtm DESC, bj.batch_job_id DESC) bj
				 WHERE rownum < in_start_row + in_page_size)
		 WHERE rn >= in_start_row;
END;

PROCEDURE MarkCompleted(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	in_running_by_worker_id			IN	batch_job.running_by_worker_id%TYPE,
	in_result						IN	batch_job.result%TYPE,
	in_result_url					IN	batch_job.result_url%TYPE,
	in_failed						IN	batch_job.failed%TYPE,
	in_ram_usage					IN	batch_job.ram_usage%TYPE,
	in_cpu_ms						IN	batch_job.cpu_ms%TYPE,
	out_email_on_completion			OUT	batch_job.email_on_completion%TYPE
)
AS
	
	v_completed_dtm					batch_job.completed_dtm%TYPE;
	v_result_max					NUMBER;
	v_ellipsis						VARCHAR2(3):= '...';
	v_lock_handle 					VARCHAR2(128);
	v_lock_result 					INTEGER;
BEGIN
	-- seriously?
	SELECT data_length
	  INTO v_result_max
	  FROM all_tab_cols
	 WHERE owner = 'CSR' AND
	 	   table_name = 'BATCH_JOB' AND
	 	   column_name = 'RESULT';

	-- no security, only called from the batch
	UPDATE batch_job
	   SET completed_dtm = SYSDATE,
	       running_on = NULL,
		   running_by_pid = NULL,
		   running_by_sid = NULL,
		   running_by_worker_id = NULL,
	       result =
			CASE
	            WHEN LENGTH(in_result) > v_result_max
    	        THEN SUBSTR(in_result, 1, v_result_max - LENGTH(v_ellipsis)) || v_ellipsis
        	    ELSE in_result
			END,
	       result_url = in_result_url,
	       processing = 0,
		   failed = in_failed,
		   ram_usage = in_ram_usage,
		   cpu_ms = in_cpu_ms,
		   timed_out = 0
	 WHERE batch_job_id = in_batch_job_id
	 	   RETURNING email_on_completion INTO out_email_on_completion;

	-- release the job lock
	dbms_lock.allocate_unique(
		lockname 			=> 'BATCH_JOB_'||SYS_CONTEXT('USERENV', 'HOST')||'_'||in_running_by_worker_id,
		lockhandle			=> v_lock_handle
	);
	v_lock_result := dbms_lock.release(
		lockhandle			=> v_lock_handle
	);

	-- if the lock release failed, we'll report it, but we still want the job marked as complete
	COMMIT;

	IF v_lock_result != 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unlocking the lock named ' ||
			'BATCH_JOB_'||SYS_CONTEXT('USERENV', 'HOST')||'_'||in_running_by_worker_id ||
			' for the job with id '||in_batch_job_id||' failed with '||v_lock_result);
	END IF;
END;

PROCEDURE MarkKilled(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	in_ram_usage					IN	batch_job.ram_usage%TYPE,
	in_allow_retry					IN	NUMBER
)
AS
BEGIN
	-- no security, only called from the batch
	UPDATE batch_job
	   SET ram_usage = in_ram_usage,
	       failed = CASE WHEN in_allow_retry = 1 THEN 0 ELSE 1 END,
	   	   result = NVL(result, 'Killed due to excessive memory consumption'),
	   	   completed_dtm = NVL(completed_dtm, CASE WHEN in_allow_retry = 1 THEN NULL ELSE SYSDATE END),
	   	   running_on = NULL,
		   running_by_pid = NULL,
		   running_by_sid = NULL,
		   running_by_worker_id = NULL,
	   	   work_done = 0,
	   	   total_work = 0,
	   	   retry_dtm = SYSDATE,
	   	   updated_dtm = SYSDATE,
		   timed_out = 0
	 WHERE batch_job_id = in_batch_job_id;
	COMMIT;
END;

PROCEDURE MarkTimedOut(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE
)
AS
BEGIN
	-- no security, only called from the batch
	UPDATE batch_job
	   SET failed = 1,
	   	   result = 'Job timed out',
	   	   completed_dtm = SYSDATE,
	   	   running_on = NULL,
		   running_by_pid = NULL,
		   running_by_sid = NULL,
		   running_by_worker_id = NULL,
	   	   work_done = 0,
	   	   total_work = 0,
	   	   retry_dtm = NULL,
	   	   updated_dtm = SYSDATE,
		   timed_out = 1
	 WHERE batch_job_id = in_batch_job_id;
	COMMIT;
END;

PROCEDURE MarkFailing(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE
)
AS
	v_failed_job_retry_delay		customer.failed_calc_job_retry_delay%TYPE;
	v_attempts						batch_job.attempts%TYPE;
	v_max_retries					batch_job_type.max_retries%TYPE;
	v_retry_dtm						DATE;
BEGIN
	-- no security, only called from the batch
	SELECT failed_calc_job_retry_delay, bj.attempts, bjt.max_retries
	  INTO v_failed_job_retry_delay, v_attempts, v_max_retries
	  FROM customer c, batch_job bj, batch_job_type bjt
	 WHERE bj.batch_job_id = in_batch_job_id
	   AND bj.batch_job_type_id = bjt.batch_job_type_id
	   AND c.app_sid = bj.app_sid;

	IF v_attempts < v_max_retries THEN
		v_retry_dtm := SYSDATE + 
			CASE
				-- now acts as a boolean flag useful for testing
				WHEN v_failed_job_retry_delay = 0 THEN 0 
				-- exponential backoff
				-- note that LEAST on the exponent is needed to prevent 
				-- overflow with a large number of attempts
				ELSE LEAST(1440, POWER(2, LEAST(11, v_attempts)) * 10) / 1440
			END;
	END IF;

	UPDATE batch_job
	   SET result = CASE WHEN v_retry_dtm IS NULL THEN 'Failing due to an error, and retry limit reached' ELSE NVL(result, 'Failing due to error') END,
	   	   running_on = NULL,
		   running_by_pid = NULL,
		   running_by_sid = NULL,
		   running_by_worker_id = NULL,
	   	   work_done = 0,
	   	   total_work = 0,
		   retry_dtm = v_retry_dtm,
	   	   updated_dtm = SYSDATE,
		   completed_dtm = CASE WHEN v_retry_dtm IS NULL THEN SYSDATE ELSE NULL END,
		   failed = CASE WHEN v_retry_dtm IS NULL THEN 1 ELSE 0 END,
		   timed_out = 0
	 WHERE batch_job_id = in_batch_job_id;
	COMMIT;
END;

PROCEDURE MarkNotified(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE
)
AS
BEGIN
	-- no security, only called from the batch
	UPDATE batch_job
	   SET notified = 1
	 WHERE batch_job_id = in_batch_job_id;
	COMMIT;
END;

PROCEDURE TakeGlobalLock
AS
	v_lock_handle					VARCHAR2(128);
	v_lock_result 					INTEGER;
BEGIN
	dbms_lock.allocate_unique(
		lockname 			=> 'BATCH_JOB_QUEUE',
		lockhandle			=> v_lock_handle
	);
	v_lock_result := dbms_lock.request(
		lockhandle 			=> v_lock_handle, 
		lockmode 			=> dbms_lock.x_mode, 
		timeout 			=> 30, --dbms_lock.maxwait,
		release_on_commit	=> TRUE
	);
	IF v_lock_result != 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Locking the BATCH_JOB_QUEUE lock failed with '||v_lock_result);
	END IF;
END;

-- Scan jobs that are marked as running, but where the transaction has rolled back
-- and mark them as not running / to be retried after the retry delay has elapsed
PROCEDURE MarkFailedJobs
AS
	-- ORA-30926: unable to get a stable set of rows in the source tables
	-- This is documented to happen under 'heavy DML' (which just appears to mean
	-- some DML).  The recommended action is just to retry the SQL, so we'll
	-- just ignore it as this gets run periodically anyway.
	MERGE_ROWS_UNSTABLE EXCEPTION;
	PRAGMA EXCEPTION_INIT(MERGE_ROWS_UNSTABLE, -30926);
BEGIN
	TakeGlobalLock;

	BEGIN
		MERGE INTO batch_job bj
		USING (
			SELECT bj.batch_job_id, bj.attempts, c.failed_calc_job_retry_delay
			  FROM batch_job bj
			  JOIN customer c ON c.app_sid = bj.app_sid
			  LEFT JOIN (
					SELECT bj.app_sid, bj.batch_job_id
					  FROM batch_job bj
					  JOIN sys.dbms_lock_allocated dla ON 
							'BATCH_JOB_'||bj.running_on||DECODE(bj.running_by_worker_id, NULL, 
								NULL, '_'||bj.running_by_worker_id) = dla.name
					  JOIN v$lock l ON dla.lockid = l.id1
 					 WHERE bj.completed = 0
					   AND NVL(l.lmode, 0) != 0) l
 				ON bj.app_sid = l.app_sid AND bj.batch_job_id = l.batch_job_id
 			 WHERE bj.completed = 0
			   AND bj.running_on IS NOT NULL
 			   AND l.batch_job_id IS NULL
		) bjf
 		   ON (bjf.batch_job_id = bj.batch_job_id)
 		 WHEN matched THEN
 			UPDATE
 			   SET bj.work_done = 0,
				   bj.total_work = 0,
				   bj.updated_dtm = SYSDATE,
				   bj.running_on = NULL,
				   bj.running_by_worker_id = NULL,
				   bj.running_by_pid = NULL,
				   bj.running_by_sid = NULL,
				   bj.retry_dtm = SYSDATE + 
			   		CASE
			   			-- now acts as a boolean flag useful for testing
			   			WHEN bjf.failed_calc_job_retry_delay = 0 THEN 0 
			   			-- exponential backoff
			   			-- note that LEAST on the exponent is needed to prevent 
			   			-- overflow with a large number of attempts
			   			ELSE LEAST(1440, POWER(2, LEAST(11, bjf.attempts)) * 10) / 1440
			   		END;
	EXCEPTION
		WHEN MERGE_ROWS_UNSTABLE THEN
			NULL;
	END;

	COMMIT;
END;

PROCEDURE Dequeue(
	in_min_priority					IN	batch_job.priority%TYPE DEFAULT NULL,
	in_max_priority					IN	batch_job.priority%TYPE DEFAULT NULL,
	in_max_ram						IN	batch_job.ram_usage%TYPE DEFAULT NULL,
	in_host							IN	customer.host%TYPE,
	out_host						OUT	customer.host%TYPE,
	out_batch_job_id				OUT batch_job.batch_job_id%TYPE,
	out_ram_usage					OUT	batch_job.ram_usage%TYPE,
	out_ram_estimate				OUT	batch_job_type.ram_estimate%TYPE,
	out_timeout_mins				OUT batch_job_type.timeout_mins%TYPE
)
AS
	v_app_sid						csr.customer.app_sid%TYPE;
BEGIN
	IF in_host IS NOT NULL THEN
		csr.customer_pkg.GetAppSid(in_host, v_app_sid);
	END IF;

	TakeGlobalLock;
	
	out_batch_job_id := NULL;

	-- The dynamic priority for batch jobs is determined as follows:
	--	By priority, then within priority:
	--		Applications with the least number of currently running jobs,
	--		then within applications with the same number of running jobs:
	--			oldest jobs first
	-- In summary:
	--	priority always wins
	--	After that we try and be fair across applications
	--	After that we try for older jobs first
	-- Starvation of newer jobs by failing jobs being rerun is handled by the backoff
	-- (the quadratically increasing time between job attempts, limited to 1 day)

	BEGIN
		WITH jobs AS (
			SELECT app_sid, batch_job_id, batch_job_type_id, priority, retry_dtm, ram_usage, ignore_timeout, aborted_dtm, in_order_group
			  FROM batch_job
			 WHERE completed = 0
		), proc AS (
			SELECT app_sid, batch_job_type_id, batch_job_id
			  FROM batch_job
			 WHERE completed = 0
			   AND running_on IS NOT NULL
		)
		SELECT host, batch_job_id, ram_usage, ram_estimate, timeout_mins
		  INTO out_host, out_batch_job_id, out_ram_usage, out_ram_estimate, out_timeout_mins
		  FROM (
			SELECT bj.app_sid, c.host, bj.batch_job_id, bj.ram_usage,
				   COALESCE(bjtac.ram_estimate, bjtas.ram_avg, bjt.ram_estimate) ram_estimate, 
				   CASE bj.ignore_timeout WHEN 1 THEN NULL ELSE NVL(bjtac.timeout_mins, bjt.timeout_mins) END timeout_mins
			  FROM jobs bj
			  JOIN customer c on bj.app_sid = c.app_sid
			  JOIN batch_job_type bjt ON bj.batch_job_type_id = bjt.batch_job_type_id
			  LEFT JOIN batch_job_type_app_stat bjtas ON bjtas.app_sid = c.app_sid
			   AND bjtas.batch_job_type_id = bj.batch_job_type_id
			  LEFT JOIN batch_job_type_app_cfg bjtac ON bjtac.app_sid = c.app_sid
			   AND bjtac.batch_job_type_id = bj.batch_job_type_id
			  LEFT JOIN (SELECT app_sid, batch_job_type_id, COUNT(*) running_jobs
				  		   FROM proc
				  		  GROUP BY app_sid, batch_job_type_id) r
				ON bj.app_sid = r.app_sid AND bj.batch_job_type_id = r.batch_job_type_id
			  JOIN (SELECT app_sid, MIN(batch_job_id) min_batch_job_id
					  FROM jobs
					  GROUP BY app_sid) mj
				ON bj.app_sid = mj.app_sid
			  LEFT JOIN (SELECT bj.app_sid, bjt.batch_job_type_id, bj.in_order_group, MIN(bj.batch_job_id) batch_job_id
						   FROM jobs bj
						   JOIN batch_job_type bjt ON bj.batch_job_type_id = bjt.batch_job_type_id
						  WHERE bjt.in_order = 1
						  GROUP BY bj.app_sid, bjt.batch_job_type_id, bj.in_order_group) pio
				ON bj.app_sid = pio.app_sid AND bj.batch_job_type_id = pio.batch_job_type_id AND DECODE(bj.in_order_group, pio.in_order_group, 1, 0) = 1
			 WHERE (bj.app_sid, bj.batch_job_id) NOT IN (
				 	SELECT app_sid, batch_job_id
				 	  FROM proc)
			   AND (bj.retry_dtm IS NULL OR bj.retry_dtm <= SYSDATE)
			   AND bj.aborted_dtm IS NULL
			   AND (in_min_priority IS NULL OR bj.priority >= in_min_priority)
			   AND (in_max_priority IS NULL OR bj.priority <= in_max_priority)
			   AND (NVL(bjtac.max_concurrent_jobs, bjt.max_concurrent_jobs) IS NULL OR
				   	NVL(r.running_jobs, 0) < NVL(bjtac.max_concurrent_jobs, bjt.max_concurrent_jobs))
			   AND (v_app_sid IS NULL OR bj.app_sid = v_app_sid)
			   AND (pio.batch_job_id IS NULL OR pio.batch_job_id = bj.batch_job_id)
			   AND (in_max_ram IS NULL OR
				   	COALESCE(bj.ram_usage, bjtac.ram_estimate, bjt.ram_estimate, 0) <= in_max_ram)
			   AND c.batch_jobs_disabled = 0
	          ORDER BY bj.priority DESC, r.running_jobs DESC, mj.min_batch_job_id, bj.batch_job_id)
			WHERE rownum = 1;

			UPDATE batch_job
			   SET started_dtm = SYSDATE,
				   updated_dtm = SYSDATE,
				   retry_dtm = NULL,
				   running_on = SYS_CONTEXT('USERENV', 'HOST'),
				   attempts = attempts + 1
			 WHERE batch_job_id = out_batch_job_id;
		
			IF SQL%ROWCOUNT = 0 THEN
				RAISE_APPLICATION_ERROR(-20001, 'Attempted to start a batch job with id '||
					out_batch_job_id||', but the job was missing');
			END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;

	COMMIT;
END;

PROCEDURE SetEmailOnCompletion(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	in_email_on_completion			IN	batch_job.email_on_completion%TYPE,
	out_already_completed			OUT	NUMBER
)
AS
	v_can_manage_jobs				NUMBER := 0;
	v_completed_dtm					batch_job.completed_dtm%TYPE;
BEGIN
	IF csr_data_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'ACT'), 'Manage jobs') THEN
		v_can_manage_jobs := 1;
	END IF;

	UPDATE batch_job
	   SET email_on_completion = in_email_on_completion
	 WHERE batch_job_id = in_batch_job_id
	   AND (requested_by_user_sid = SYS_CONTEXT('SECURITY', 'SID') OR v_can_manage_jobs = 1)
	   	   RETURNING completed_dtm INTO v_completed_dtm;

	IF SQL%ROWCOUNT != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'The batch job with id '||in_batch_job_id||' does not exist, or was not created '||
			'by the user with sid '||SYS_CONTEXT('SECURITY', 'SID'));
	END IF;

	out_already_completed := CASE WHEN v_completed_dtm IS NOT NULL THEN 1 ELSE 0 END;
END;

FUNCTION GetFileDataSp(
	in_batch_job_id					IN batch_job.batch_job_id%TYPE
)
RETURN VARCHAR2
AS
	v_return VARCHAR2(255);
BEGIN
	SELECT MIN(file_data_sp)
	  INTO v_return
	  FROM batch_job bj
	  JOIN batch_job_type bjt ON bj.batch_job_type_id = bjt.batch_job_type_id
	 WHERE bj.batch_job_id = in_batch_job_id;

	RETURN v_return;
END;

PROCEDURE GetBatchJobTypesInUse(
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT batch_job_type_id, description 
		  FROM batch_job_type
		 WHERE batch_job_type_id IN (
			SELECT DISTINCT batch_job_type_id
			  FROM batch_job
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		)
		 ORDER BY description;

END;

-- No security, only called from a dbms_scheduler task to update per app per job stats
PROCEDURE ComputeJobStats
AS
BEGIN
	MERGE INTO batch_job_type_app_stat bjtas
	USING (SELECT app_sid, batch_job_type_id,
				  MAX(ram_usage) ram_max, AVG(ram_usage) ram_avg,
				  MAX(cpu_ms) cpu_max_ms, AVG(cpu_ms) cpu_avg_ms,
				  MAX(completed_dtm - started_dtm) * 86400 run_time_max,
				  AVG(completed_dtm - started_dtm) * 86400 run_time_avg,
				  MAX(started_dtm - requested_dtm) * 86400 start_delay_max,
				  AVG(started_dtm - requested_dtm) * 86400 start_delay_avg
			 FROM batch_job
			WHERE completed_dtm IS NOT NULL
			  AND failed = 0
			GROUP BY app_sid, batch_job_type_id) s
	   ON (s.app_sid = bjtas.app_sid AND s.batch_job_type_id = bjtas.batch_job_type_id)
	 WHEN MATCHED THEN
	 	UPDATE SET bjtas.ram_max = s.ram_max,
	 			   bjtas.ram_avg = s.ram_avg,
	 			   bjtas.cpu_max_ms = s.cpu_max_ms,
	 			   bjtas.cpu_avg_ms = s.cpu_avg_ms,
	 			   bjtas.run_time_max = s.run_time_max,
	 			   bjtas.run_time_avg = s.run_time_avg,
	 			   bjtas.start_delay_max = s.start_delay_max,
	 			   bjtas.start_delay_avg = s.start_delay_avg
	 WHEN NOT MATCHED THEN
	 	INSERT (app_sid, batch_job_type_id, ram_max, ram_avg, cpu_max_ms, cpu_avg_ms,
	 			run_time_max, run_time_avg, start_delay_max, start_delay_avg)
	 	VALUES (s.app_sid, s.batch_job_type_id, s.ram_max, s.ram_avg, s.cpu_max_ms, s.cpu_avg_ms,
	 			s.run_time_max, s.run_time_avg, s.start_delay_max, s.start_delay_avg);
	COMMIT;
END;

PROCEDURE SetCustomerTimeoutForType (
	in_batch_job_type_id		NUMBER,
	in_timeout_mins				NUMBER
)
AS
BEGIN

	BEGIN
		INSERT INTO batch_job_type_app_cfg
			(batch_job_type_id, timeout_mins)
		VALUES
			(in_batch_job_type_id, in_timeout_mins);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE batch_job_type_app_cfg
			   SET timeout_mins = in_timeout_mins
			 WHERE batch_job_type_id = in_batch_job_type_id
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END;

END;

FUNCTION CanRetryJob (
	in_batch_job_id			IN	NUMBER
) 
RETURN NUMBER
AS
	v_super_admin			NUMBER;
	v_is_running			NUMBER;
	v_failed				NUMBER;
	v_retry_dtm				DATE;
BEGIN
	-- Can retry a job where;
		-- The current user is a super admin
		-- The job is not running
		-- The job failed OR already has a retry dtm
	
	v_super_admin := security.user_pkg.IsSuperAdmin;
	
	SELECT processing, failed, retry_dtm
	  INTO v_is_running, v_failed, v_retry_dtm
	  FROM batch_job
	 WHERE batch_job_id = in_batch_job_id;
	
	IF v_super_admin = 1 AND v_is_running = 0 AND (v_failed = 1 OR v_retry_dtm IS NOT NULL) THEN
		RETURN 1;
	END IF;
	
	RETURN 0;
END;

PROCEDURE RetryJob(
	in_batch_job_id			IN	NUMBER
)
AS
	v_can_retry	NUMBER;
BEGIN

	v_can_retry := CanRetryJob(in_batch_job_id);
	
	IF v_can_retry = 1 THEN
		UPDATE batch_job
		   SET retry_dtm = SYSDATE,
			   timed_out = 0,
			   failed = 0,
			   ignore_timeout = 1
		 WHERE batch_job_id = in_batch_job_id;

		 Requeue(in_batch_job_id => in_batch_job_id);	
	ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Job ' || in_batch_job_id || ' not in retryable state.');
	END IF;

END;

FUNCTION CanAbortJob (
	in_batch_job_id			IN	NUMBER
) 
RETURN NUMBER
AS
	v_super_admin			NUMBER;
	v_is_running			NUMBER;
	v_completed_dtm			DATE;
	v_retry_dtm				DATE;
BEGIN
	-- Can abort a job where;
		-- The current user is a super admin
		-- The job is not running
		-- The job has not completed
		-- The job has a retry dtm
	
	v_super_admin := security.user_pkg.IsSuperAdmin;
	
	SELECT processing, completed_dtm, retry_dtm
	  INTO v_is_running, v_completed_dtm, v_retry_dtm
	  FROM batch_job
	 WHERE batch_job_id = in_batch_job_id;
	
	IF v_super_admin = 1 AND v_is_running = 0 AND v_completed_dtm IS NULL AND v_retry_dtm IS NOT NULL THEN
		RETURN 1;
	END IF;
	
	RETURN 0;
END;

PROCEDURE AbortJob(
	in_batch_job_id			IN	NUMBER
)
AS
	v_can_abort	NUMBER;
BEGIN

	v_can_abort := CanAbortJob(in_batch_job_id);
	
	IF v_can_abort = 1 THEN
		UPDATE batch_job
		   SET retry_dtm = NULL,
			   timed_out = 0,
			   failed = 0,
			   aborted_dtm = SYSDATE,
			   completed_dtm = SYSDATE,
			   result = 'Aborted'
		 WHERE batch_job_id = in_batch_job_id;
	ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Job ' || in_batch_job_id || ' not in abortable state.');
	END IF;

END;

PROCEDURE GetExtraJobDetails (
	in_batch_job_id			IN	NUMBER,
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT CanRetryJob(in_batch_job_id) can_retry, CanAbortJob(in_batch_job_id) can_abort
		  FROM DUAL;

END;

END;
/
