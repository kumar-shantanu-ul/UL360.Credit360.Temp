CREATE OR REPLACE PACKAGE BODY CSR.energy_star_job_pkg IS

PROCEDURE BatchTrigger(
	in_host							IN	VARCHAR2,
	in_default_port					IN	NUMBER,
	in_batch_job_id					IN	NUMBER
)
AS LANGUAGE JAVA NAME 'BatchTrigger.send(java.lang.String, int, long)';

PROCEDURE TriggerPoll
AS
BEGIN
	BatchTrigger('*', 997, 0);
END;

PROCEDURE GetOrCreateJob(
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_job_type_id					IN	est_job.est_job_type_id%TYPE,
	in_est_account_sid				IN	security_pkg.T_SID_ID,
	in_pm_customer_id				IN	est_job.pm_customer_id%TYPE			DEFAULT NULL,
	in_pm_building_id				IN	est_job.pm_building_id%TYPE			DEFAULT NULL,
	in_pm_space_id					IN	est_job.pm_space_id%TYPE			DEFAULT NULL,
	in_pm_meter_id					IN	est_job.pm_meter_id%TYPE			DEFAULT NULL,
	in_region_sid					IN	security_pkg.T_SID_ID				DEFAULT NULL,
	in_update_pm_object				IN	est_job.update_pm_object%TYPE		DEFAULT 1,
	out_job_id						OUT	est_job.est_job_id%TYPE
)
AS
BEGIN
	-- It's ok to do this rather than inserting first as we've got a row lock
	UPDATE est_job
	   SET update_pm_object = DECODE(update_pm_object, 1, 1, in_update_pm_object)
	 WHERE app_sid = in_app_sid
	   AND est_job_type_id = in_job_type_id
	   AND est_account_sid = in_est_account_sid
	   AND NVL(pm_customer_id, -1) = NVL(in_pm_customer_id, -1)
	   AND NVL(pm_building_id, -1) = NVL(in_pm_building_id, -1)
	   AND NVL(pm_space_id, -1) = NVL(in_pm_space_id, -1)
	   AND NVL(pm_meter_id, -1) = NVL(in_pm_meter_id, -1)
	   AND NVL(region_sid, -1) = NVL(in_region_sid, -1)
	   AND processing = 0
	   	RETURNING est_job_id INTO out_job_id;
		
	IF SQL%ROWCOUNT = 0 THEN
		INSERT INTO est_job 
			(app_sid, est_job_id, est_job_type_id, est_account_sid, pm_customer_id, pm_building_id, pm_space_id, pm_meter_id, region_sid, update_pm_object)
		VALUES
			(in_app_sid, csr.est_job_id_seq.NEXTVAL, in_job_type_id, in_est_account_sid, in_pm_customer_id, in_pm_building_id, in_pm_space_id, in_pm_meter_id, in_region_sid, in_update_pm_object)
		RETURNING est_job_id INTO out_job_id;
	END IF;
END;

-- Add a procedure, called by an oracle job to create jobs for building and meter polls.
PROCEDURE QueueJobs
AS
BEGIN
	-- log in for 10 minutes only as should complete quickly, and runs every 15 seconds
	security.user_pkg.LogonAdmin(timeout => 600);
	
	FOR r IN (
		SELECT DISTINCT app_sid app_sid
		  FROM est_account
		UNION
		SELECT DISTINCT app_sid
		  FROM est_region_change_log
		UNION
		SELECT DISTINCT app_sid
		  FROM est_building_change_log
		UNION
		SELECT DISTINCT app_sid
		  FROM est_space_change_log
		UNION
		SELECT DISTINCT app_sid
		  FROM est_meter_change_log
	) LOOP
		security_pkg.setApp(r.app_sid);
		QueueJobs(r.app_sid);
	END LOOP;
	
	-- log off when done
	security.user_pkg.LogOff(security.security_pkg.GetAct);
END;

PROCEDURE QueueJobs(
	in_app_sid						IN	security_pkg.T_SID_ID
)
AS
	v_job_id						est_job.est_job_id%TYPE;
	v_trash_sid						security_pkg.T_SID_ID;
	
BEGIN
	-- We'll need the trash sid later
	v_trash_sid := securableobject_pkg.GetSIDFromPath(security_pkg.getACT, security_pkg.GetAPP, 'Trash');
	
	-- prevent jobs from changing while we are looking at them
	csr_data_pkg.LockApp(
		in_lock_type => csr_data_pkg.LOCK_TYPE_ENERGY_STAR, 
		in_app_sid => in_app_sid
	);
	
	-- NOTE: est_account.*_poll_interval is in minutes.
	-- Where we poll periodically we're just making sure that 
	-- a job is created at least every poll interval. If the
	-- last job is still outstanding then a new job will not 
	-- be created by GetOrCreateJob.
	
	-- Connection poll (est_account.connect_poll_interval)
	FOR r IN (
		SELECT est_account_id, est_account_sid, SYSDATE job_dtm
		  FROM v$est_account
		 WHERE app_sid = in_app_sid
		   AND connect_job_interval IS NOT NULL
		   AND (last_connect_job_dtm IS NULL
		   	OR  SYSDATE >= last_connect_job_dtm + connect_job_interval / 1440)
	) LOOP
		-- Set the last job dtm
		UPDATE est_account_global
		   SET last_connect_job_dtm = r.job_dtm
		 WHERE est_account_id = r.est_account_id; 
		
		-- Create the job if required
		GetOrCreateJob(
			in_app_sid				=> in_app_sid,
			in_job_type_id			=> JOB_TYPE_CONNECT,
			in_est_account_sid		=> r.est_account_sid,
			out_job_id				=> v_job_id
		);
	END LOOP;
		   
	
	-- Sharing poll (est_account.share_poll_interval)
	FOR r IN (
		SELECT est_account_sid, auto_map_customer, SYSDATE job_dtm
		  FROM v$est_account
		 WHERE app_sid = in_app_sid
		   AND share_job_interval IS NOT NULL
		   AND (last_share_job_dtm IS NULL
		   	OR  SYSDATE >= last_share_job_dtm + share_job_interval / 1440)
	) LOOP
		-- Set the last job dtm
		UPDATE est_account
		   SET last_share_job_dtm = r.job_dtm
		 WHERE app_sid = in_app_sid
		   AND est_account_sid = r.est_account_sid; 
		
		-- Create the job if required
		GetOrCreateJob(
			in_app_sid				=> in_app_sid,
			in_job_type_id			=> JOB_TYPE_SHARE,
			in_est_account_sid		=> r.est_account_sid,
			out_job_id				=> v_job_id
		);
	END LOOP;
	
	-- Building pull (est_account.building_job_interval)
	FOR r IN (
		SELECT b.est_account_sid, b.pm_customer_id, b.pm_building_id, SYSDATE job_dtm
		  FROM est_account a
		  JOIN est_building b ON b.app_sid = a.app_sid AND b.est_account_sid = a.est_account_sid
		  JOIN region r ON b.app_sid = r.app_sid AND b.region_sid = r.region_sid
		  JOIN property p ON p.app_sid = a.app_sid AND p.region_sid = b.region_sid
		 WHERE a.app_sid = in_app_sid
		   AND a.building_job_interval IS NOT NULL
		   AND r.active = 1					-- Exclude inactive building regions
		   --AND b.missing = 0 				-- Missing properties can "reappear"
		   AND r.parent_sid != v_trash_sid	-- Exclude buildings in the trash
		   AND p.energy_star_sync = 1 		-- Sync must be switched on for the property
		   AND p.energy_star_push = 0 		-- Don't pull if the property is set to push
		   AND (b.last_job_dtm IS NULL
		   	OR  SYSDATE >= b.last_job_dtm + a.building_job_interval / 1440)
	) LOOP
		-- Set the last job dtm
		UPDATE est_building
		   SET last_job_dtm = r.job_dtm
		 WHERE app_sid = in_app_sid
		   AND est_account_sid = r.est_account_sid
		   AND pm_customer_id = r.pm_customer_id
		   AND pm_building_id = r.pm_building_id;
		
		-- Create the job if required
		GetOrCreateJob(
			in_app_sid				=> in_app_sid,
			in_job_type_id			=> JOB_TYPE_PROPERTY,
			in_est_account_sid		=> r.est_account_sid,
			in_pm_customer_id		=> r.pm_customer_id,
			in_pm_building_id		=> r.pm_building_id,
			out_job_id				=> v_job_id
		);
	END LOOP;
	
	-- Meter pull (est_account.meter_job_interval)
	FOR r IN (
		SELECT m.est_account_sid, m.pm_customer_id, m.pm_building_id, m.pm_meter_id, SYSDATE job_dtm
		  FROM est_account a
		  JOIN est_meter m ON m.app_sid = a.app_sid AND m.est_account_sid = a.est_account_sid
		  JOIN region r ON m.app_sid = r.app_sid AND m.region_sid = r.region_sid
		  JOIN est_building b ON b.app_sid = m.app_sid AND b.est_account_sid = m.est_account_sid AND b.pm_customer_id = m.pm_customer_id AND b.pm_building_id = m.pm_building_id
		  JOIN property p ON p.app_sid = a.app_sid AND p.region_sid = b.region_sid
		  JOIN region pr ON p.app_sid = pr.app_sid AND p.region_sid = pr.region_sid
		 WHERE a.app_sid = in_app_sid
		   AND a.meter_job_interval IS NOT NULL
		   AND r.active = 1					-- Exclude inactive meter regions
		   AND pr.active = 1				-- Exclude meters belonging to inactive building regions
		   AND m.missing = 0				-- Exclude missing meters
		   AND r.parent_sid != v_trash_sid	-- Exclude meters in the trash
		   AND b.missing = 0				-- Exclude meters belonging to missing buildings
		   AND pr.parent_sid != v_trash_sid	-- Exclude meters belonging to buildings in the trash
		   AND p.energy_star_sync = 1 		-- Sync must be switched on for the property
		   AND p.energy_star_push = 0 		-- Don't pull if the meter's property is set to push
		   AND (m.last_job_dtm IS NULL
		   	OR  SYSDATE >= m.last_job_dtm + a.meter_job_interval / 1440)
	) LOOP
		-- Set the last job dtm
		UPDATE est_meter
		   SET last_job_dtm = r.job_dtm
		 WHERE app_sid = in_app_sid
		   AND est_account_sid = r.est_account_sid
		   AND pm_customer_id = r.pm_customer_id
		   AND pm_building_id = r.pm_building_id
		   AND pm_meter_id = r.pm_meter_id;
		
		-- Create the job if required
		GetOrCreateJob(
			in_app_sid				=> in_app_sid,
			in_job_type_id			=> JOB_TYPE_METER,
			in_est_account_sid		=> r.est_account_sid,
			in_pm_customer_id		=> r.pm_customer_id,
			in_pm_building_id		=> r.pm_building_id,
			in_pm_meter_id			=> r.pm_meter_id,
			out_job_id				=> v_job_id
		);
	END LOOP;

	-- Pull read-only metrics for buildings set to push (est_account.building_job_interval)
	FOR r IN (
		SELECT b.est_account_sid, b.pm_customer_id, b.pm_building_id, SYSDATE job_dtm
		  FROM est_account a
		  JOIN est_building b ON b.app_sid = a.app_sid AND b.est_account_sid = a.est_account_sid
		  JOIN region r ON b.app_sid = r.app_sid AND b.region_sid = r.region_sid
		  JOIN property p ON p.app_sid = a.app_sid AND p.region_sid = b.region_sid
		 WHERE a.app_sid = in_app_sid
		   AND a.building_job_interval IS NOT NULL
		   AND r.active = 1					-- Exclude inactive building regions
		   --AND b.missing = 0 				-- Missing properties can "reappear"
		   AND r.parent_sid != v_trash_sid	-- Exclude buildings in the trash
		   AND p.energy_star_sync = 1 		-- Sync must be switched on for the property
		   AND p.energy_star_push = 1 		-- Only create for properties set to push
		   AND (b.last_job_dtm IS NULL
		   	OR  SYSDATE >= b.last_job_dtm + a.building_job_interval / 1440)
	) LOOP
		-- Set the last job dtm
		UPDATE est_building
		   SET last_job_dtm = r.job_dtm
		 WHERE app_sid = in_app_sid
		   AND est_account_sid = r.est_account_sid
		   AND pm_customer_id = r.pm_customer_id
		   AND pm_building_id = r.pm_building_id;
		
		-- Create the job if required
		GetOrCreateJob(
			in_app_sid				=> in_app_sid,
			in_job_type_id			=> JOB_TYPE_READONLY_METRICS,
			in_est_account_sid		=> r.est_account_sid,
			in_pm_customer_id		=> r.pm_customer_id,
			in_pm_building_id		=> r.pm_building_id,
			out_job_id				=> v_job_id
		);
	END LOOP;
	
	-- Region change push (est_region_change_log)
	-- Added because building or meter regions which need creating will not be in 
	-- the est_building or est_*_meter tables and will not have a pm_*_id
	FOR r IN (
		SELECT est_account_sid, region_sid, pm_customer_id
		  FROM est_region_change_log
		 WHERE app_sid = in_app_sid
	) LOOP
		GetOrCreateJob(
			in_app_sid				=> in_app_sid,
			in_job_type_id			=> JOB_TYPE_REGION,
			in_est_account_sid		=> r.est_account_sid,
			in_region_sid			=> r.region_sid,
			in_pm_customer_id		=> r.pm_customer_id,
			out_job_id				=> v_job_id
		);
	END LOOP;
	
	-- Building change push (est_building_change_log)
	FOR r IN (
		SELECT l.est_account_sid, l.pm_customer_id, l.pm_building_id
		  FROM est_building_change_log l
		 WHERE l.app_sid = in_app_sid
	) LOOP
		GetOrCreateJob(
			in_app_sid				=> in_app_sid,
			in_job_type_id			=> JOB_TYPE_PROPERTY,
			in_est_account_sid		=> r.est_account_sid,
			in_pm_customer_id		=> r.pm_customer_id,
			in_pm_building_id		=> r.pm_building_id,
			out_job_id				=> v_job_id
		);
	END LOOP;
	
	-- Space change push (est_space_change_log)
	FOR r IN (
		SELECT l.est_account_sid, l.pm_customer_id, l.pm_building_id, l.pm_space_id
		  FROM est_space_change_log l
		 WHERE l.app_sid = in_app_sid
	) LOOP
		GetOrCreateJob(
			in_app_sid				=> in_app_sid,
			in_job_type_id			=> JOB_TYPE_SPACE,
			in_est_account_sid		=> r.est_account_sid,
			in_pm_customer_id		=> r.pm_customer_id,
			in_pm_building_id		=> r.pm_building_id,
			in_pm_space_id			=> r.pm_space_id,
			out_job_id				=> v_job_id
		);
	END LOOP;
	
	-- Space attribute change push (est_space_attr_change_log)
	-- The job is still just for the space, the attribute changes are merged into EST_JOB_ATTRS
	FOR r IN (
		SELECT est_account_sid, pm_customer_id, pm_building_id, pm_space_id, region_metric_val_id, pm_val_id
		  FROM est_space_attr_change_log
		 WHERE app_sid = in_app_sid
	) LOOP
		GetOrCreateJob(
			in_app_sid				=> in_app_sid,
			in_job_type_id			=> JOB_TYPE_SPACE,
			in_est_account_sid		=> r.est_account_sid,
			in_pm_customer_id		=> r.pm_customer_id,
			in_pm_building_id		=> r.pm_building_id,
			in_pm_space_id			=> r.pm_space_id,
			in_update_pm_object		=> 0,
			out_job_id				=> v_job_id
		);
		-- Merge changed attributes into EST_JOB_ATTRS
		BEGIN
			INSERT INTO est_job_attr (app_sid, est_job_id, region_metric_val_id, pm_val_id)
			VALUES (in_app_sid, v_job_id, r.region_metric_val_id, r.pm_val_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE est_job_attr
				   SET pm_val_id = NVL(pm_val_id, r.pm_val_id)
				 WHERE app_sid = in_app_sid
				   AND est_job_id = v_job_id
				   AND region_metric_val_id = r.region_metric_val_id;
		END;
	END LOOP;
	
	-- Meter change push (est_meter_change_log)
	FOR r IN (
		SELECT l.est_account_sid, l.pm_customer_id, l.pm_building_id, l.pm_meter_id
		  FROM est_meter_change_log l
		 WHERE l.app_sid = in_app_sid
	) LOOP
		GetOrCreateJob(
			in_app_sid				=> in_app_sid,
			in_job_type_id			=> JOB_TYPE_METER,
			in_est_account_sid		=> r.est_account_sid,
			in_pm_customer_id		=> r.pm_customer_id,
			in_pm_building_id		=> r.pm_building_id,
			in_pm_meter_id			=> r.pm_meter_id,
			out_job_id				=> v_job_id
		);
	END LOOP;
	
	-- Meter reading change push (est_meter_reading_change_log)
	-- The job is still just for the meter, the reading changes are merged into EST_JOB_READINGS
	FOR r IN (
		SELECT est_account_sid, pm_customer_id, pm_building_id, pm_meter_id, meter_reading_id, pm_reading_id
		  FROM est_meter_reading_change_log
		 WHERE app_sid = in_app_sid
	) LOOP
		GetOrCreateJob(
			in_app_sid				=> in_app_sid,
			in_job_type_id			=> JOB_TYPE_METER,
			in_est_account_sid		=> r.est_account_sid,
			in_pm_customer_id		=> r.pm_customer_id,
			in_pm_building_id		=> r.pm_building_id,
			in_pm_meter_id			=> r.pm_meter_id,
			in_update_pm_object		=> 0,
			out_job_id				=> v_job_id
		);
		-- Merge changed readings into EST_JOB_READINGS
		BEGIN
			INSERT INTO est_job_reading (app_sid, est_job_id, meter_reading_id, pm_reading_id)
			VALUES (in_app_sid, v_job_id, r.meter_reading_id, r.pm_reading_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE est_job_reading
				   SET pm_reading_id = NVL(pm_reading_id, r.pm_reading_id)
				 WHERE app_sid = in_app_sid
				   AND est_job_id = v_job_id
				   AND meter_reading_id = r.meter_reading_id;
		END;
	END LOOP;
	
	-- Clear down change logs
	DELETE FROM est_region_change_log
	 WHERE app_sid = in_app_sid;
	
	DELETE FROM est_building_change_log 
	 WHERE app_sid = in_app_sid;
	 
	DELETE FROM est_space_change_log 
	 WHERE app_sid = in_app_sid;
	 
	DELETE FROM est_space_attr_change_log 
	 WHERE app_sid = in_app_sid;
	 
	DELETE FROM est_meter_change_log 
	 WHERE app_sid = in_app_sid;
	 
	DELETE FROM est_meter_reading_change_log 
	 WHERE app_sid = in_app_sid;
	
	-- commit to release locks
	COMMIT;

	-- trigger any idle job runners to poll
	--TriggerPoll;
END;

PROCEDURE QueueSingleJob(
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_job_type_id					IN	est_job.est_job_type_id%TYPE,
	in_est_account_sid				IN	security_pkg.T_SID_ID,
	in_pm_customer_id				IN	est_job.pm_customer_id%TYPE			DEFAULT NULL,
	in_pm_building_id				IN	est_job.pm_building_id%TYPE			DEFAULT NULL,
	in_pm_space_id					IN	est_job.pm_space_id%TYPE			DEFAULT NULL,
	in_pm_meter_id					IN	est_job.pm_meter_id%TYPE			DEFAULT NULL,
	in_region_sid					IN	security_pkg.T_SID_ID				DEFAULT NULL,
	in_update_pm_object				IN	est_job.update_pm_object%TYPE		DEFAULT 1,
	out_job_id						OUT	est_job.est_job_id%TYPE
)
AS
BEGIN
	-- prevent jobs from changing while we are looking at them
	csr_data_pkg.LockApp(
		in_lock_type => csr_data_pkg.LOCK_TYPE_ENERGY_STAR, 
		in_app_sid => in_app_sid
	);
	
	GetOrCreateJob(
		in_app_sid,
		in_job_type_id,
		in_est_account_sid,
		in_pm_customer_id,
		in_pm_building_id,
		in_pm_space_id,
		in_pm_meter_id,
		in_region_sid,
		in_update_pm_object,
		out_job_id
	);
END;


/**
 * Internal -- locks a job so that it cannot be changed
 * uses a separate transaction so that DequeueJob doesn't remove 
 * the message before it has completed processing it.
 *
 * @param in_app_sid				The app to lock for
 * @param in_job_id					id of the job to lock
 * @return boolean indicating if the job was locked successfully
 */
FUNCTION LockJob(
	in_app_sid						IN	est_job.app_sid%TYPE,
	in_job_id						IN	est_job.est_job_id%TYPE
)
RETURN BOOLEAN
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
	v_back_off_delay 				NUMBER := 600;
BEGIN
	-- this means new jobs can't be added while we eat the job
	csr_data_pkg.LockApp(in_app_sid => in_app_sid, in_lock_type => csr_data_pkg.LOCK_TYPE_ENERGY_STAR);
	
	-- lock the job -- if it fails because we are already processing a job of 
	-- the same type or because it was just processed, failed and isn't due a retry
	-- yet then return failure.
	BEGIN
		UPDATE est_job
		   SET processing = 1,
		   	   est_job_state_id = JOB_STATE_RUN,
		   	   last_attempt_dtm = SYSDATE,
			   attempts = attempts + 1
		 WHERE app_sid = in_app_sid
		   AND est_job_id = in_job_id
		   AND est_job_state_id	IN (JOB_STATE_IDLE, JOB_STATE_FAILED)
		   AND NVL(process_after_dtm, SYSDATE) <= SYSDATE;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			--security_pkg.DebugMsg('DUP_VAL_ON_INDEX');
			-- Experimental - If a job fails to lock because there's a failed job in 
			-- the queue that has reached it's rerun time then it's entirely likely 
			-- that the next run round the job loop will pick up the same job again 
			-- and again spinning the thread. Back the job that fails to lock off by 
			-- a small period to prevent this spinning. If the previously failed job 
			-- fails again when it is retried then this job will likely  be retried 
			-- again before the failed job is retried minimising the chance of lock 
			-- failure next time this job is retried.
			UPDATE est_job
			   SET process_after_dtm = SYSDATE + v_back_off_delay / 86400
			 WHERE app_sid = in_app_sid
			   AND est_job_id = in_job_id;
			COMMIT; -- release locks
			RETURN FALSE;
	END;
	IF SQL%ROWCOUNT = 0 THEN
		--security_pkg.DebugMsg('SQL%ROWCOUNT = 0');
		COMMIT; -- release locks
		RETURN FALSE;
	END IF;
	
	-- release locks: we now own the calc jobs
	COMMIT;
	 
	-- ok
	RETURN TRUE;
END;


-- Scan jobs that are marked as running, but where the transaction has rolled back
-- and mark them as not running / to be retried after the retry delay has elapsed
PROCEDURE MarkFailedJobs
AS
	PRAGMA AUTONOMOUS_TRANSACTION;

	-- ORA-30926: unable to get a stable set of rows in the source tables
	-- This is documented to happen under 'heavy DML' (which just appears to mean
	-- some DML).  The recommended action is just to retry the SQL, so we'll
	-- just ignore it as this gets run periodically anyway.
	MERGE_ROWS_UNSTABLE EXCEPTION;
	PRAGMA EXCEPTION_INIT(MERGE_ROWS_UNSTABLE, -30926);
BEGIN
	BEGIN
		MERGE INTO csr.est_job ej
		USING (
			SELECT ej.est_job_id
			  FROM csr.est_job ej
			  LEFT JOIN (
					SELECT ej.app_sid, ej.est_job_id
  					  FROM csr.est_job ej
  					  JOIN sys.dbms_lock_allocated dla ON dla.name = 
  				  		'EST_JOB_'||ej.app_sid||'_'||ej.est_job_type_id||'_'||ej.est_account_sid||'_'||NVL(ej.pm_customer_id, 0)||'_'||NVL(ej.pm_building_id, 0)||'_'||NVL(ej.pm_space_id, 0)||'_'||NVL(ej.pm_meter_id, 0)
  					  JOIN v$lock l ON dla.lockid = l.id1
 					 WHERE NVL(l.lmode, 0) != 0) l
 				ON ej.app_sid = l.app_sid AND ej.est_job_id = l.est_job_id
 			 WHERE ej.est_job_state_id NOT IN (JOB_STATE_IDLE, JOB_STATE_FAILED)
 			   AND l.est_job_id IS NULL
		) jf
 		   ON (jf.est_job_id = ej.est_job_id)
 		 WHEN matched THEN
 			UPDATE
 			   SET ej.est_job_state_id = JOB_STATE_FAILED,
				   -- exponential backoff
 		   		   ej.process_after_dtm = SYSDATE + LEAST(1440, POWER(2, LEAST(11, ej.attempts)) * 10) / 1440;
	EXCEPTION
		WHEN MERGE_ROWS_UNSTABLE THEN
			NULL;
	END;

	COMMIT;
END;


PROCEDURE DequeueJob(
	in_host							IN	customer.host%TYPE,
	out_job_id						OUT	est_job.est_job_id%TYPE
)
AS
	v_lock_handle 					VARCHAR2(128);
	v_lock_result 					INTEGER;
	v_again							BOOLEAN;
	v_app_sid						NUMBER;
BEGIN
	out_job_id := NULL;

	IF in_host IS NOT NULL THEN
		csr.customer_pkg.GetAppSid(in_host, v_app_sid);
	END IF;
	--security_pkg.debugMsg('ES: energy_star_job_pkg.DequeueJob: '||sys_context('userenv','sessionid')||', '||sys_context('SECURITY', 'ACT'));

	LOOP
		
		-- Deal with failed jobs
		MarkFailedJobs;
		
		-- The dynamic priority for jobs is determined as follows:
		--		Manually created jobs,
		--			then applications with the least number of currently running jobs,
		--			then within applications with the same number of running jobs:
		-- 			  job type: connect, share, property, space, meter, region
		--				Minimum job id for the application (i.e. application with the oldest job)
		--					then oldest jobs first
		v_again := FALSE;
		FOR r IN (
			WITH proc AS (
				SELECT ej.app_sid, ej.est_job_type_id, ej.est_account_sid, ej.pm_customer_id, ej.pm_building_id, ej.pm_space_id, ej.pm_meter_id
				  FROM csr.est_job ej
				  JOIN sys.dbms_lock_allocated dla ON dla.name = 
				  		'EST_JOB_'||ej.app_sid||'_'||ej.est_job_type_id||'_'||ej.est_account_sid||'_'||NVL(ej.pm_customer_id, 0)||'_'||NVL(ej.pm_building_id, 0)||'_'||NVL(ej.pm_space_id, 0)||'_'||NVL(ej.pm_meter_id, 0)
				  JOIN v$lock l ON dla.lockid = l.id1
				 WHERE NVL(l.lmode, 0) != 0
				   AND ej.processing = 1
			)
			SELECT ej.app_sid, ej.est_job_id, ej.est_job_type_id, ej.est_account_sid, ej.pm_customer_id, ej.pm_building_id, ej.pm_space_id, ej.pm_meter_id,
				'EST_JOB_'||ej.app_sid||'_'||ej.est_job_type_id||'_'||ej.est_account_sid||'_'||NVL(ej.pm_customer_id, 0)||'_'||NVL(ej.pm_building_id, 0)||'_'||NVL(ej.pm_space_id, 0)||'_'||NVL(ej.pm_meter_id, 0) job_lock_name,
				r.running_jobs, DECODE(ej.created_by_user_sid, NULL, 0, 1) is_manually_created
			  FROM csr.est_job ej
			  LEFT JOIN (SELECT app_sid, COUNT(*) running_jobs
			  			   FROM proc
			  			  GROUP BY app_sid) r
				ON ej.app_sid = r.app_sid
			  JOIN (SELECT app_sid, MIN(est_job_id) min_job_id
			  		  FROM csr.est_job
			  		 GROUP BY app_sid) mj
			    ON ej.app_sid = mj.app_sid
			 WHERE (ej.app_sid, ej.est_job_type_id, ej.est_account_sid, NVL(ej.pm_customer_id, -1), NVL(ej.pm_building_id, -1), NVL(ej.pm_space_id, -1), NVL(ej.pm_meter_id, -1)) 
			   NOT IN (
			 		SELECT app_sid, est_job_type_id, est_account_sid, NVL(pm_customer_id, -1), NVL(pm_building_id, -1), NVL(pm_space_id, -1), NVL(pm_meter_id, -1)
			 		  FROM proc)
			   AND NVL(ej.process_after_dtm, SYSDATE) <= SYSDATE
			   AND (v_app_sid IS NULL OR ej.app_sid = v_app_sid)
			 ORDER BY is_manually_created DESC, r.running_jobs DESC, est_job_type_id, mj.min_job_id, ej.est_job_id
		) LOOP
			
			-- First, take the job lock which indicates processing is in progress
			dbms_lock.allocate_unique(
				lockname 			=> r.job_lock_name,
				lockhandle			=> v_lock_handle
			);
			v_lock_result := dbms_lock.request(
				lockhandle 			=> v_lock_handle, 
				lockmode 			=> dbms_lock.x_mode, 
				timeout 			=> 0, --dbms_lock.maxwait, 
				release_on_commit	=> TRUE
			);
			
			IF v_lock_result = 1 THEN
				-- if the lock timed out then this indicates the next 
				-- job query returned stale results -- try it again
				--security_pkg.DebugMsg('Lock timed out for '||r.job_lock_name);
				v_again := TRUE;
				EXIT;
			ELSE
				IF v_lock_result NOT IN (0, 4) THEN -- 0 = success; 4 = already held
					--security_pkg.DebugMsg('Locking the energy star job '||r.job_lock_name||' failed with '||v_lock_result);
					RAISE_APPLICATION_ERROR(-20001, 'Locking the energy star job '||r.job_lock_name||' failed with '||v_lock_result);
				END IF;
			END IF;
	
			-- Next try lock the job row
			IF NOT LockJob(r.app_sid, r.est_job_id) THEN
				-- This shouldn't happen often -- if the job was picked up, tried and failed
				-- then LockJob will detect this and return FALSE, so tidy up and re-run
				-- the find jobs query
				
				--security_pkg.DebugMsg('Lock job failed for '||r.job_lock_name||', '||r.app_sid||', '||r.est_job_id);
				
				v_lock_result := dbms_lock.release(
					lockhandle			=> v_lock_handle
				);
				IF v_lock_result NOT IN (0, 4) THEN -- 0 = success, 4 = lock not held
					--security_pkg.debugmsg('estjob '||USERENV('SID')||': Releasing the calc job lock for the app with sid '||r.app_sid||
					--	' failed with '||v_lock_result);
					RAISE_APPLICATION_ERROR(-20001, 'Releasing the energy star job lock for '||r.job_lock_name||' failed with '||v_lock_result);
				END IF;
				
				-- Locking the calc job failed
				v_again := TRUE;
				EXIT;
			END IF;
			
			-- Ok, so we've got a locked job ready for processing
			out_job_id := r.est_job_id;
			RETURN;
		END LOOP;

		/*IF v_again THEN
			security_pkg.debugmsg('energy star '||USERENV('SID')||': go again');
		ELSE
			security_pkg.debugmsg('energy star '||USERENV('SID')||': waiting');
		END IF;*/

		-- if the loop doesn't need retrying, then return
		IF NOT v_again THEN	
			RETURN;
		END IF;
		
	END LOOP;
END;


PROCEDURE GetJob(
	in_job_id						IN	est_job.est_job_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT j.app_sid, j.est_job_id, j.est_account_sid, j.pm_customer_id, j.pm_building_id, j.pm_space_id, j.pm_meter_id, j.region_sid,
			j.est_job_type_id, j.est_job_state_id, j.processing, j.process_after_dtm, j.last_attempt_dtm, j.update_pm_object,
			COALESCE(p1.energy_star_sync, p2.energy_star_sync, 0) energy_star_sync, -- no region, no sync anyway
			COALESCE(p1.energy_star_push, p2.energy_star_push, 0) energy_star_push,
			j.attempts, c.est_job_notify_after_attempts notify_after_attempts,
			c.est_job_notify_address notify_address, j.notified, c.host,
			j.created_by_user_sid, SYSDATE db_timestamp
		  FROM est_job j
		  JOIN customer c ON j.app_sid = c.app_sid
		  -- Join to property using ether the job's region sid or the building's region sid (if both match they *should* be the same)
		  LEFT JOIN est_building b ON j.app_sid = b.app_sid AND j.est_account_sid = b.est_account_sid AND j.pm_customer_id = b.pm_customer_id AND j.pm_building_id = b.pm_building_id
		  LEFT JOIN property p1 ON b.region_sid = p1.region_sid
		  LEFT JOIN property p2 ON j.region_sid = p2.region_sid
		  LEFT JOIN est_space es ON j.app_sid = es.app_sid AND j.est_account_sid = es.est_account_sid AND j.pm_customer_id = es.pm_customer_id AND j.pm_space_id = es.pm_space_id
		  LEFT JOIN est_meter em ON j.app_sid = em.app_sid AND j.est_account_sid = em.est_account_sid AND j.pm_customer_id = em.pm_customer_id AND j.pm_meter_id = em.pm_meter_id
		  LEFT JOIN trash trash_b  ON b.region_sid  = trash_b.trash_sid
		  LEFT JOIN trash trash_j  ON j.region_sid  = trash_j.trash_sid
		  LEFT JOIN trash trash_es ON es.region_sid = trash_es.trash_sid
		  LEFT JOIN trash trash_em ON em.region_sid = trash_em.trash_sid
		 WHERE est_job_id = in_job_id
		   AND (b.region_sid IS NULL OR trash_b.trash_sid IS NULL)
		   AND (j.region_sid IS NULL OR trash_j.trash_sid IS NULL)
		   AND (p1.energy_star_push = 0 OR (es.region_sid IS NULL OR trash_es.trash_sid IS NULL))
		   AND (p1.energy_star_push = 0 OR (em.region_sid IS NULL OR trash_em.trash_sid IS NULL))
		;
END;

PROCEDURE MarkNotified(
	in_est_job_id					IN	est_job.est_job_id%TYPE
)
AS
BEGIN
	-- no security, only called from Energy Star job processor
	UPDATE est_job
	   SET notified = 1
	 WHERE est_job_id = in_est_job_id;
	COMMIT;
END;

PROCEDURE DeleteProcessedJob(
	in_job_id						IN	est_job.est_job_id%TYPE
)
AS
BEGIN
	-- Try and set the last poll dtm for the entity we updated
	-- (only for buildings or meters)
	FOR j IN (
		SELECT region_sid, est_account_sid, pm_customer_id, pm_building_id, pm_meter_id
		  FROM est_job
		 WHERE est_job_id = in_job_id
	) LOOP
		IF j.pm_meter_id IS NOT NULL THEN
			UPDATE est_meter
			   SET last_poll_dtm = SYSDATE
			 WHERE est_account_sid = j.est_account_sid
			   AND pm_customer_id = j.pm_customer_id
			   AND pm_building_id = j.pm_building_id
			   AND pm_meter_id = j.pm_meter_id;
		ELSIF j.pm_building_id IS NOT NULL THEN
			UPDATE est_building
			   SET last_poll_dtm = SYSDATE
			 WHERE est_account_sid = j.est_account_sid
			   AND pm_customer_id = j.pm_customer_id
			   AND pm_building_id = j.pm_building_id;
		ELSIF j.region_sid IS NOT NULL THEN
			UPDATE est_building
			   SET last_poll_dtm = SYSDATE
			 WHERE est_account_sid = j.est_account_sid
			   AND region_sid = j.region_sid;
			UPDATE est_meter
			   SET last_poll_dtm = SYSDATE
			 WHERE est_account_sid = j.est_account_sid
			   AND region_sid = j.region_sid;
		END IF;
	END LOOP;	
	
	-- no lock is required because we have marked the job as in-flight
	DELETE FROM est_job_attr
	 WHERE est_job_id = in_job_id;
	   
	DELETE FROM est_job_reading
	 WHERE est_job_id = in_job_id;
	
	DELETE FROM est_job
	 WHERE est_job_id = in_job_id;

	-- sanity check
	IF SQL%ROWCOUNT = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Attempt to delete a non-existent job with id '||in_job_id);
	END IF;
END;


-- Try and find the property sid
FUNCTION INTERNAL_GetPropertySid(
    in_region_sid				IN	security_pkg.T_SID_ID
)
RETURN security_pkg.T_SID_ID
AS
    v_property_sid  security_pkg.T_SID_ID;
BEGIN
    WITH pro AS (               
         SELECT region_sid, region_type
           FROM region 
          WHERE CONNECT_BY_ISLEAF = 1
          START WITH region_sid = in_region_sid
        CONNECT BY PRIOR parent_sid = region_sid
            AND PRIOR region_type != csr_data_pkg.REGION_TYPE_PROPERTY
     )
    SELECT CASE 
            WHEN pro.region_type != csr_data_pkg.REGION_TYPE_ROOT THEN pro.region_sid 
            ELSE pr.region_sid -- just use parent
           END property_sid
      INTO v_property_sid
      FROM pro, region r
        JOIN region pr ON pr.region_sid = r.parent_sid
     WHERE r.region_sid = in_region_sid;
    
    RETURN v_property_sid;
END;

PROCEDURE OnRegionChange(
	in_region_sid				IN	security_pkg.T_SID_ID
)
AS
	v_existing					BOOLEAN := FALSE;
	v_prop_sid					security_pkg.T_SID_ID;
	v_pm_building_id			property.pm_building_id%TYPE;
	v_default_customer_id		est_options.default_customer_id%TYPE;
	v_default_account_sid		est_options.default_account_sid%TYPE;
BEGIN

	BEGIN
		SELECT default_customer_id, default_account_sid
		  INTO v_default_customer_id, v_default_account_sid
		  FROM est_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN OTHERS THEN NULL;
	END;

	-- Check the property is set-up for energy_star_push
	BEGIN
		v_prop_sid := INTERNAL_GetPropertySid(in_region_sid);
		SELECT region_sid
		  INTO v_prop_sid
		  FROM property
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = v_prop_sid
		   AND energy_star_sync = 1
		   AND energy_star_push != 0;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN; -- Region not part of an energy star property doing push
	END;
	
	-- Lock the app when we fiddle with a change log table
	csr_data_pkg.LockApp(
		in_lock_type => csr_data_pkg.LOCK_TYPE_ENERGY_STAR, 
		in_app_sid => security_pkg.GetAPP
	);
	
	FOR r IN (
		SELECT est_account_sid, pm_customer_id, pm_building_id, NULL pm_space_id, NULL pm_meter_id
		  FROM est_building
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid
	  	UNION
	  	SELECT est_account_sid, pm_customer_id, pm_building_id, pm_space_id, NULL pm_meter_id
		  FROM est_space
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid
		UNION
		SELECT est_account_sid, pm_customer_id, pm_building_id, pm_space_id, pm_meter_id
		  FROM est_meter
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid
	) LOOP
		-- Found something
		v_existing := TRUE;
		
		-- Create a change log entry
		BEGIN
			IF r.pm_meter_id IS NOT NULL THEN
				-- It's a meter
				INSERT INTO est_meter_change_log (est_account_sid, pm_customer_id, pm_building_id, pm_meter_id)
				VALUES(r.est_account_sid, r.pm_customer_id, r.pm_building_id, r.pm_meter_id);
			ELSIF r.pm_space_id IS NOT NULL THEN
				-- It's a space
				INSERT INTO est_space_change_log (est_account_sid, pm_customer_id, pm_building_id, pm_space_id)
				VALUES(r.est_account_sid, r.pm_customer_id, r.pm_building_id, r.pm_space_id);
			ELSE
				-- It's a building
				INSERT INTO est_building_change_log (est_account_sid, pm_customer_id, pm_building_id)
				VALUES(r.est_account_sid, r.pm_customer_id, r.pm_building_id);
			END IF;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- Ignore dupes
		END;
	END LOOP;
	
	-- This region might be a property, try and 
	-- fetch the property's pm_building_id mapping
	BEGIN
		SELECT pm_building_id
		  INTO v_pm_building_id
		  FROM property
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- Not a property region
			v_pm_building_id := NULL;
	END;
	
	-- If it didn't exist then create a change log for the region sid 
	-- (the job will then create an object of the correct type).
	-- We check that each type, property, space or meter, can be mapped
	-- to a corresponding Energy Star type, if not then no job is created.
	-- Only one of the queries below will produce a row to insert.
	
	-- If the property table specifies a pm_building_id then this is a property 
	-- which might be waiting to be shared. We should not create a job to create 
	-- a new property but wait until the property is mapped, by which time it 
	-- will match above and v_existing will be TRUE.
	
	IF NOT v_existing AND v_pm_building_id IS NULL THEN
		BEGIN
			-- Property that can be mapped
			-- XXX: Hmm, est_property_type_map allows more than one mapping.
			INSERT INTO est_region_change_log (region_sid, est_account_sid, pm_customer_id)
				SELECT in_region_sid, v_default_account_sid, NVL(v_default_customer_id, ac.account_customer_id)
				  FROM property p
			  	  JOIN est_property_type_map map ON p.app_sid = map.app_sid AND p.property_type_id = map.property_type_id
			  	  JOIN est_account ac ON p.app_sid = ac.app_sid AND v_default_account_sid = ac.est_account_sid
			  	 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND p.region_sid = in_region_sid
			;
			
			-- OR
			-- Space that can be mapped
			INSERT INTO est_region_change_log (est_account_sid, region_sid, pm_customer_id)
				SELECT NVL(b.est_account_sid, v_default_account_sid), in_region_sid, NVL(b.pm_customer_id, NVL(v_default_customer_id, ac.account_customer_id))
				  FROM property p
				  JOIN space s ON p.app_sid = s.app_sid AND p.region_sid = s.property_region_sid
				  LEFT JOIN est_building b ON p.app_sid = b.app_sid AND p.region_sid = b.region_sid
				  JOIN est_account ac ON p.app_sid = ac.app_sid AND NVL(b.est_account_sid, v_default_account_sid) = ac.est_account_sid
				  JOIN est_space_type_map map ON s.app_sid = map.app_sid AND s.space_type_id = map.space_type_id
				 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND p.region_sid = v_prop_sid
				   AND s.region_sid = in_region_sid
			;
			
			-- OR
			-- Meter that can be mapped
			INSERT INTO est_region_change_log (est_account_sid, region_sid, pm_customer_id)
				SELECT NVL(b.est_account_sid, v_default_account_sid), in_region_sid, NVL(b.pm_customer_id, NVL(v_default_customer_id, ac.account_customer_id))
				  FROM property p
				  JOIN v$legacy_meter m ON p.app_sid = m.app_sid
				  LEFT JOIN est_building b ON p.app_sid = b.app_sid AND p.region_sid = b.region_sid
				  JOIN est_account ac ON p.app_sid = ac.app_sid AND NVL(b.est_account_sid, v_default_account_sid) = ac.est_account_sid
				  JOIN est_meter_type_mapping mtm ON m.app_sid = mtm.app_sid AND m.meter_type_id = mtm.meter_type_id AND ac.est_account_sid = mtm.est_account_sid
				  JOIN est_conv_mapping mcm ON m.app_sid = mcm.app_sid AND mtm.est_account_sid = mcm.est_account_sid AND mtm.meter_type = mcm.meter_type AND ac.est_account_sid = mcm.est_account_sid
				 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND p.region_sid = v_prop_sid
				   AND m.region_sid = in_region_sid
				   AND mcm.measure_sid IS NOT NULL -- Measure sid is null if not mapped
				   AND NVL(m.primary_measure_conversion_id, -1) = NVL(mcm.measure_conversion_id, -1);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- Ignore dupes
			WHEN CANNOT_INSERT_NULL_EXCEPTION THEN
				IF v_default_customer_id IS NULL OR v_default_account_sid IS NULL THEN
					RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_INVALID_EST_OPTIONS, 'There is no default customer or account Id set in the energy star options.');
				ELSE
					RAISE;
				END IF;
		END;
	END IF;
END;

PROCEDURE OnRegionRemoved(
	in_region_sid				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	-- Create a job for the correct energy star object type
	OnRegionChange(in_region_sid);
	
	-- If the region wasn't mapped then it will have created a 
	-- est_region_change_log entry wehich we now need to delete
	DELETE FROM est_region_change_log
	 WHERE region_sid = in_region_sid;

	-- Remove mapping from Energy Star (a delete of the ES object is required)
	UPDATE est_building
	   SET region_sid = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = in_region_sid;
	   
	UPDATE est_space
	   SET region_sid = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = in_region_sid;
	   
	UPDATE est_meter
	   SET region_sid = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = in_region_sid;
END;

PROCEDURE OnRegionMove(
	in_region_sid				IN	security_pkg.T_SID_ID
)
AS
	v_parent_sid				security_pkg.T_SID_ID;
	v_space_id					est_space.pm_space_id%TYPE;
BEGIN

	-- Note this procedure only deals with setting the parent space id on meters at this time, 
	-- it does not adjust the parent building information for a mved space/meter for example. 
	-- Stricly speaking moving spaces and meters about for energy star linked properties 
	-- should be done via the property module which ought to restrict such changes anyway.

	-- Get the parent sid
	SELECT parent_sid
	  INTO v_parent_sid
	  FROM region
	 WHERE region_sid = in_region_sid;

	-- The region has moved, if it's an energy star meter then we 
	-- might need to update the parent space id in the est_meter table
	BEGIN
		SELECT pm_space_id
		  INTO v_space_id
		  FROM est_space
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = v_parent_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_space_id := NULL;
	END;

	UPDATE est_meter
	   SET pm_space_id = v_space_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = in_region_sid
	   AND NVL(pm_space_id, -1) != NVL(v_space_id, -1);

	-- Create a job if the meter was updated
	IF SQL%ROWCOUNT > 0 THEN
		OnRegionChange(in_region_sid);
	END IF;
END;


PROCEDURE OnMeterReadingChange(
	in_meter_sid				IN	security_pkg.T_SID_ID,
	in_meter_reading_id			IN	meter_reading.meter_reading_id%TYPE
)
AS
	v_prop_sid					security_pkg.T_SID_ID;
	v_est_account_sid			security_pkg.T_SID_ID;
	v_pm_customer_id			est_building.pm_customer_id%TYPE;
	v_pm_building_id			est_building.pm_building_id%TYPE;
	v_pm_space_id				est_space.pm_space_id%TYPE;
	v_pm_reading_id				meter_reading.pm_reading_id%TYPE;
	v_prev_meter_reading_id		meter_reading.meter_reading_id%TYPE;
	v_prev_pm_reading_id		meter_reading.pm_reading_id%TYPE;
	v_next_meter_reading_id		meter_reading.meter_reading_id%TYPE;
	v_next_pm_reading_id		meter_reading.pm_reading_id%TYPE;
	v_arbitrary_period			meter_source_type.arbitrary_period%TYPE;

	v_acquisition_dtm			DATE;
	v_first_bill_dtm			DATE;
	v_first_reading_dtm			DATE;
BEGIN
	
	-- Check the associated property is set-up for energy_star_push
	BEGIN
		v_prop_sid := INTERNAL_GetPropertySid(in_meter_sid);
		SELECT region_sid
		  INTO v_prop_sid
		  FROM property
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = v_prop_sid
		   AND energy_star_sync = 1
		   AND energy_star_push != 0;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN; -- Associated meter not part of an energy star property doing push
	END;
	
	SELECT st.arbitrary_period
	  INTO v_arbitrary_period
	  FROM all_meter m
	  JOIN meter_source_type st ON m.app_sid = st.app_sid AND m.meter_source_type_id = st.meter_source_type_id
	 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND m.region_sid = in_meter_sid;
	
	-- Lock the app when we fiddle with the change log table
	csr_data_pkg.LockApp(
		in_lock_type => csr_data_pkg.LOCK_TYPE_ENERGY_STAR, 
		in_app_sid => security_pkg.GetAPP
	);
	
	BEGIN
		SELECT pm_reading_id, 
			next_meter_reading_id, next_pm_reading_id, 
			prev_meter_reading_id, prev_pm_reading_id
		  INTO v_pm_reading_id, 
		  	v_next_meter_reading_id, v_next_pm_reading_id,
		  	v_prev_meter_reading_id, v_prev_pm_reading_id
		  FROM (
		  		SELECT meter_reading_id, pm_reading_id, 
					LEAD(meter_reading_id) OVER (ORDER BY start_dtm) next_meter_reading_id,
					LEAD(pm_reading_id) OVER (ORDER BY start_dtm) next_pm_reading_id,
					LAG(meter_reading_id) OVER (ORDER BY start_dtm) prev_meter_reading_id, 
					LAG(pm_reading_id) OVER (ORDER BY start_dtm) prev_pm_reading_id
				  FROM v$meter_reading
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND region_sid = in_meter_sid
		  )
		 WHERE meter_reading_id = in_meter_reading_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_pm_reading_id := NULL;
	END;
	
	FOR r IN (
	  	SELECT est_account_sid, pm_customer_id, pm_building_id, pm_space_id, pm_meter_id
		  FROM est_meter
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_meter_sid
	) LOOP
		BEGIN
			INSERT INTO est_meter_reading_change_log (est_account_sid, pm_customer_id, pm_building_id, pm_meter_id, meter_reading_id, pm_reading_id)
			VALUES(r.est_account_sid, r.pm_customer_id, r.pm_building_id, r.pm_meter_id, in_meter_reading_id, v_pm_reading_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- Ignore dupes
		END;
		
		-- For point in time meters changing the current reading will potentially affect the previous 
		-- and next consumption figure in ES too so add the previous/next reading ids to the job too
		IF v_arbitrary_period = 0 THEN
			IF v_prev_meter_reading_id IS NOT NULL THEN
				BEGIN
					INSERT INTO est_meter_reading_change_log (est_account_sid, pm_customer_id, pm_building_id, pm_meter_id, meter_reading_id, pm_reading_id)
					VALUES(r.est_account_sid, r.pm_customer_id, r.pm_building_id, r.pm_meter_id, v_prev_meter_reading_id, v_prev_pm_reading_id);
				EXCEPTION
					WHEN DUP_VAL_ON_INDEX THEN
						NULL; -- Ignore dupes
				END;
			END IF;
			IF v_next_meter_reading_id IS NOT NULL THEN
				BEGIN
					INSERT INTO est_meter_reading_change_log (est_account_sid, pm_customer_id, pm_building_id, pm_meter_id, meter_reading_id, pm_reading_id)
					VALUES(r.est_account_sid, r.pm_customer_id, r.pm_building_id, r.pm_meter_id, v_next_meter_reading_id, v_next_pm_reading_id);
				EXCEPTION
					WHEN DUP_VAL_ON_INDEX THEN
						NULL; -- Ignore dupes
				END;
			END IF;
		END IF;
	END LOOP;

	-- Check to see if the reading will change the first_bill_dtm
	SELECT acquisition_dtm
	  INTO v_acquisition_dtm
	  FROM region
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = in_meter_sid;

	-- If the acquisiton dtm is set then we don't need to do anything
	IF v_acquisition_dtm IS NULL THEN
		
		-- Fetch the first bill dtm and first reading dtm if available
		SELECT MIN(m.first_bill_dtm), MIN(mr.start_dtm)
	      INTO v_first_bill_dtm, v_first_reading_dtm
	      FROM est_meter m
	      LEFT JOIN meter_reading mr ON mr.app_sid = m.app_sid AND mr.region_sid = m.region_sid
	     WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	       AND m.region_sid = in_meter_sid;

	    -- If the first bill dtm doesn't match the first reading dtm or if the first bill dtm is null then update the meter
	    -- No need to update if the first reading dtm is null and the fisrt bill dtm is already set
		IF v_first_bill_dtm != v_first_reading_dtm OR
		   v_first_bill_dtm IS NULL THEN
			-- Add a job to update the ES meter
			OnRegionChange(in_meter_sid);
		END IF;
	END IF;
END;

PROCEDURE OnRegionMetricChange(
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_region_metric_val_id		IN	region_metric_val.region_metric_val_id%TYPE
)
AS
	v_count						NUMBER;
	v_prop_sid					security_pkg.T_SID_ID;
	v_est_account_sid			security_pkg.T_SID_ID;
	v_pm_customer_id			est_building.pm_customer_id%TYPE;
	v_pm_building_id			est_building.pm_building_id%TYPE;
	v_pm_space_id				est_space.pm_space_id%TYPE;
	v_pm_val_id					est_space_attr.pm_val_id%TYPE;
BEGIN
	
	-- Check the associated property is set-up for energy_star_push
	BEGIN
		v_prop_sid := INTERNAL_GetPropertySid(in_region_sid);
		SELECT region_sid
		  INTO v_prop_sid
		  FROM property
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = v_prop_sid
		   AND energy_star_sync = 1
		   AND energy_star_push != 0;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN; -- Associated region not part of an energy star property doing push
	END;

	-- If the region metric value that changed is tied to a read-only building metric then we don't want to create a push job
	-- (this happens when we pull read-only building metrics for properties set to push).
	SELECT COUNT(*)
	  INTO v_count
	  FROM region_metric_val v
	  JOIN est_building_metric_mapping map ON map.app_sid = v.app_sid AND map.ind_sid = v.ind_sid
	 WHERE v.region_metric_val_id = in_region_metric_val_id
	   AND map.simulated = 0
	   AND map.read_only = 1;

	IF v_count > 0 THEN
		RETURN;
	END IF;
	
	-- Lock the app when we fiddle with the change log table
	csr_data_pkg.LockApp(
		in_lock_type => csr_data_pkg.LOCK_TYPE_ENERGY_STAR, 
		in_app_sid => security_pkg.GetAPP
	);
	
	BEGIN
		SELECT sa.pm_val_id
		  INTO v_pm_val_id
		  FROM region_metric_val v
		  LEFT JOIN est_space_attr sa ON v.app_sid = sa.app_sid AND v.region_metric_val_id = sa.region_metric_val_id
		 WHERE v.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND v.region_metric_val_id = in_region_metric_val_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_pm_val_id := NULL;
	END;
	
	-- If it's a building then add to the building change log
	FOR r IN (
		SELECT est_account_sid, pm_customer_id, pm_building_id
		  FROM est_building
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid
	) LOOP
		BEGIN
			INSERT INTO est_building_change_log (est_account_sid, pm_customer_id, pm_building_id)
			VALUES(r.est_account_sid, r.pm_customer_id, r.pm_building_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- Ignore dupes
		END;
	END LOOP;
	
	-- If it's a space then add to attribute change log
	FOR r IN (
		SELECT est_account_sid, pm_customer_id, pm_building_id, pm_space_id
		  FROM est_space
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid
	) LOOP
		BEGIN
			INSERT INTO est_space_attr_change_log (est_account_sid, pm_customer_id, pm_building_id, pm_space_id, region_metric_val_id, pm_val_id)
			VALUES(r.est_account_sid, r.pm_customer_id, r.pm_building_id, r.pm_space_id, in_region_metric_val_id, v_pm_val_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- Ignore dupes
		END;
	END LOOP;
END;

-- Create jobs for children of a given region
PROCEDURE CreateJobsForChildren(
	in_region_sid				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	FOR r IN (
		SELECT region_sid
		  FROM region
		 WHERE region_type IN (csr_data_pkg.REGION_TYPE_SPACE, csr_data_pkg.REGION_TYPE_METER)
		 START WITH region_sid = in_region_sid
		 CONNECT BY PRIOR region_sid = parent_sid
	) LOOP
		OnRegionChange(r.region_sid);
	END LOOP;
END;

-- Create jobs for the children of a given energy star building region
PROCEDURE CreateJobsForChildren(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_pm_customer_id			IN	est_job.pm_customer_id%TYPE,
	in_pm_building_id			IN	est_job.pm_building_id%TYPE
)
AS
BEGIN
	FOR r IN (
		SELECT region_sid
		  FROM est_building
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id
		   AND region_sid IS NOT NULL
	) LOOP
		CreateJobsForChildren(r.region_sid);
	END LOOP;
END;

PROCEDURE INTERNAL_DeleteChangeLogs(
	in_region_sid			IN	security_pkg.T_SID_ID
)
AS 
BEGIN
	csr_data_pkg.LockApp(
		in_lock_type => csr_data_pkg.LOCK_TYPE_ENERGY_STAR, 
		in_app_sid => security_pkg.GetAPP
	);
	
	DELETE FROM est_region_change_log
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = in_region_sid;
	   
END;

PROCEDURE INTERNAL_DeleteChangeLogs(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_pm_customer_id			IN	est_job.pm_customer_id%TYPE,
	in_pm_building_id			IN	est_job.pm_building_id%TYPE,
	in_pm_space_id				IN	est_job.pm_space_id%TYPE		DEFAULT NULL,
	in_pm_meter_id				IN	est_job.pm_meter_id%TYPE		DEFAULT NULL
)
AS 
BEGIN
	csr_data_pkg.LockApp(
		in_lock_type => csr_data_pkg.LOCK_TYPE_ENERGY_STAR, 
		in_app_sid => security_pkg.GetAPP
	);
	
	IF in_pm_space_id IS NULL AND in_pm_meter_id IS NULL THEN
		DELETE FROM est_building_change_log
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id;
	
		DELETE FROM est_space_change_log
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id;
		   
		DELETE FROM est_space_attr_change_log
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id;
		
		DELETE FROM est_meter_change_log
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id;
		   
		DELETE FROM est_meter_reading_change_log
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id;

	ELSIF in_pm_space_id IS NOT NULL THEN
		DELETE FROM est_space_change_log
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id
		   AND pm_space_id = in_pm_space_id;
		   
		DELETE FROM est_space_attr_change_log
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id
		   AND pm_space_id = in_pm_space_id;
	
	ELSIF in_pm_meter_id IS NOT NULL THEN
		DELETE FROM est_meter_change_log
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id
		   AND pm_meter_id = in_pm_meter_id;
		   
		DELETE FROM est_meter_reading_change_log
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id
		   AND pm_meter_id = in_pm_meter_id;
		   
	END IF;
END;

PROCEDURE DeleteChangeLogs(
	in_region_sid			IN	security_pkg.T_SID_ID
)
AS 
BEGIN
	csr_data_pkg.LockApp(
		in_lock_type => csr_data_pkg.LOCK_TYPE_ENERGY_STAR, 
		in_app_sid => security_pkg.GetAPP
	);
	
	FOR r IN (
		SELECT est_account_sid, pm_customer_id, pm_building_id, NULL pm_space_id, NULL pm_meter_id
		  FROM est_building
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid
		UNION
		SELECT est_account_sid, pm_customer_id, pm_building_id, pm_space_id, NULL pm_meter_id
		  FROM est_space
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid
		UNION
		SELECT est_account_sid, pm_customer_id, pm_building_id, NULL pm_space_id, pm_meter_id
		  FROM est_meter
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid
	) LOOP
		INTERNAL_DeleteChangeLogs(
			r.est_account_sid,
			r.pm_customer_id,
			r.pm_building_id,
			r.pm_space_id,
			r.pm_meter_id
		);
	END LOOP;
	
	INTERNAL_DeleteChangeLogs(in_region_sid);
	   
END;

PROCEDURE DeleteChangeLogs(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_pm_customer_id			IN	est_job.pm_customer_id%TYPE,
	in_pm_building_id			IN	est_job.pm_building_id%TYPE,
	in_pm_space_id				IN	est_job.pm_space_id%TYPE		DEFAULT NULL,
	in_pm_meter_id				IN	est_job.pm_meter_id%TYPE		DEFAULT NULL
)
AS 
BEGIN
	csr_data_pkg.LockApp(
		in_lock_type => csr_data_pkg.LOCK_TYPE_ENERGY_STAR, 
		in_app_sid => security_pkg.GetAPP
	);
	
	FOR r IN (
		SELECT region_sid
		  FROM est_building
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  AND est_account_sid = in_est_account_sid
		  AND pm_customer_id = in_pm_customer_id
		  AND pm_building_id = in_pm_building_id
		UNION
		SELECT region_sid
		  FROM est_space
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  AND est_account_sid = in_est_account_sid
		  AND pm_customer_id = in_pm_customer_id
		  AND pm_building_id = in_pm_building_id
		  AND pm_space_id = in_pm_space_id
		UNION
		SELECT region_sid
		  FROM est_meter
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  AND est_account_sid = in_est_account_sid
		  AND pm_customer_id = in_pm_customer_id
		  AND pm_building_id = in_pm_building_id
		  AND pm_meter_id = in_pm_meter_id
	) LOOP
		INTERNAL_DeleteChangeLogs(r.region_sid);
	END LOOP;
	
	INTERNAL_DeleteChangeLogs(
		in_est_account_sid,
		in_pm_customer_id,
		in_pm_building_id,
		in_pm_space_id,
		in_pm_meter_id
	);
END;

PROCEDURE CreateManualJobs(
	in_prop_region_sid			IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_default_account_sid		security_pkg.T_SID_ID;
	v_default_customer_id		est_options.default_customer_id%TYPE;
	v_energy_star_sync			property.energy_star_sync%TYPE;
	v_energy_star_push			property.energy_star_push%TYPE;
	v_pm_building_id			est_building.pm_building_id%TYPE;
	v_job_ids_created			security_pkg.T_SID_IDS;
	t_job_ids_created			security.T_SID_TABLE;
	v_job_id					est_job.est_job_id%TYPE;
BEGIN

	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can create Energy Star jobs.');
	END IF;

	SELECT op.default_account_sid, NVL(op.default_customer_id, ac.account_customer_id)
	  INTO v_default_account_sid, v_default_customer_id
	  FROM est_options op
	  JOIN est_account ac ON op.app_sid = ac.app_sid AND op.default_account_sid = ac.est_account_sid
	 WHERE op.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	SELECT p.energy_star_sync, p.energy_star_push, NVL(b.pm_building_id, p.pm_building_id)
	  INTO v_energy_star_sync, v_energy_star_push, v_pm_building_id
	  FROM property p
	  LEFT JOIN est_building b ON  b.app_sid = p.app_sid AND b.region_sid = p.region_sid
	 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND p.region_sid = in_prop_region_sid;

	-- DON'T DO ANYTHING IF THE PROPERTY IS NOT SET TO SYNC
	IF v_energy_star_sync = 0 THEN
		-- Return dummy cursor (expected columns but no rows)
		OPEN out_cur FOR
			SELECT NULL est_job_id,  NULL est_account_sid, NULL pm_customer_id, NULL pm_building_id, NULL pm_space_id, 
				NULL pm_meter_id, NULL region_sid, NULL est_job_type_id, NULL job_type_desc
			  FROM DUAL
			 WHERE 1 = 0;
		RETURN;
	END IF;

	-- Lock the app
	csr_data_pkg.LockApp(
		in_lock_type => csr_data_pkg.LOCK_TYPE_ENERGY_STAR, 
		in_app_sid => security_pkg.GetAPP
	);

	IF v_energy_star_push = 0 THEN
		-- Only create pull jobs for properties which are "shared"
		-- (exists in est_building and has a region_sid)
		FOR b IN (
			SELECT est_account_sid, pm_customer_id, pm_building_id
			  FROM est_building
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND region_sid = in_prop_region_sid
		) LOOP
			-- 1. Job to pull building, space and meter info
			QueueSingleJob(
				in_app_sid				=> SYS_CONTEXT('SECURITY', 'APP'),
				in_job_type_id			=> energy_star_job_pkg.JOB_TYPE_PROPERTY,
				in_est_account_sid		=> b.est_account_sid,
				in_pm_customer_id		=> b.pm_customer_id,
				in_pm_building_id		=> b.pm_building_id,
				out_job_id				=> v_job_id
			);

			UPDATE est_job
			   SET created_by_user_sid = SYS_CONTEXT('SECURITY', 'SID')
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND est_job_id = v_job_id;

			v_job_ids_created(v_job_ids_created.COUNT) := v_job_id;

			UPDATE est_building
			   SET last_job_dtm = SYSDATE
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND est_account_sid = b.est_account_sid
			   AND pm_customer_id = b.pm_customer_id
			   AND pm_building_id = b.pm_building_id;

			-- 2. Job to pull meter readings for all child meters
			FOR m IN (
				SELECT pm_meter_id, region_sid
				  FROM est_meter
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND est_account_sid = b.est_account_sid
				   AND pm_customer_id = b.pm_customer_id
				   AND pm_building_id = b.pm_building_id
				   AND region_sid IS NOT NULL
				   AND missing = 0
			) LOOP
				QueueSingleJob(
					in_app_sid				=> SYS_CONTEXT('SECURITY', 'APP'),
					in_job_type_id			=> energy_star_job_pkg.JOB_TYPE_METER,
					in_est_account_sid		=> b.est_account_sid,
					in_pm_customer_id		=> b.pm_customer_id,
					in_pm_building_id		=> b.pm_building_id,
					in_pm_meter_id			=> m.pm_meter_id,
					out_job_id				=> v_job_id
				);

				UPDATE est_job
				   SET created_by_user_sid = SYS_CONTEXT('SECURITY', 'SID')
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND est_job_id = v_job_id;

				v_job_ids_created(v_job_ids_created.COUNT) := v_job_id;

				UPDATE est_meter
				   SET last_job_dtm = SYSDATE
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND est_account_sid = b.est_account_sid
				   AND pm_customer_id = b.pm_customer_id
				   AND pm_building_id = b.pm_building_id
				   AND pm_meter_id = m.pm_meter_id;

			END LOOP;

		END LOOP;
	ELSE
		IF v_pm_building_id IS NULL THEN
			-- Not "mapped" but set to push => NEW PROPERTY (push property only)
			QueueSingleJob(
				in_app_sid				=> SYS_CONTEXT('SECURITY', 'APP'),
				in_job_type_id			=> energy_star_job_pkg.JOB_TYPE_REGION,
				in_est_account_sid		=> v_default_account_sid,
				in_pm_customer_id		=> v_default_customer_id,
				in_region_sid			=> in_prop_region_sid,
				in_update_pm_object		=> 1,
				out_job_id				=> v_job_id
			);

			UPDATE est_job
			   SET created_by_user_sid = SYS_CONTEXT('SECURITY', 'SID')
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND est_job_id = v_job_id;

			v_job_ids_created(v_job_ids_created.COUNT) := v_job_id;

		ELSE
			-- Mapped and set to push, only create a  job if it's "shared" 
			-- (exists in the est_building table with a region sid)
			FOR b IN (
				SELECT est_account_sid, pm_customer_id, pm_building_id
				  FROM est_building
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND region_sid = in_prop_region_sid
			) LOOP

				-- 1. Job to push the property
				QueueSingleJob(
					in_app_sid				=> SYS_CONTEXT('SECURITY', 'APP'),
					in_job_type_id			=> energy_star_job_pkg.JOB_TYPE_PROPERTY,
					in_est_account_sid		=> b.est_account_sid,
					in_pm_customer_id		=> b.pm_customer_id,
					in_pm_building_id		=> b.pm_building_id,
					in_update_pm_object		=> 1,
					out_job_id				=> v_job_id
				);

				UPDATE est_job
				   SET created_by_user_sid = SYS_CONTEXT('SECURITY', 'SID')
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND est_job_id = v_job_id;

				v_job_ids_created(v_job_ids_created.COUNT) := v_job_id;

				-- 2. jobs to push child spaces and attributes
				FOR s IN (
					SELECT pm_space_id, region_sid
					  FROM est_space
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND est_account_sid = b.est_account_sid
					   AND pm_customer_id = b.pm_customer_id
					   AND pm_building_id = b.pm_building_id
					   AND region_sid IS NOT NULL
					   AND missing = 0
				) LOOP
					QueueSingleJob(
						in_app_sid				=> SYS_CONTEXT('SECURITY', 'APP'),
						in_job_type_id			=> energy_star_job_pkg.JOB_TYPE_SPACE,
						in_est_account_sid		=> b.est_account_sid,
						in_pm_customer_id		=> b.pm_customer_id,
						in_pm_building_id		=> b.pm_building_id,
						in_pm_space_id			=> s.pm_space_id,
						in_update_pm_object		=> 1,
						out_job_id				=> v_job_id
					);

					FOR r IN (
						SELECT v.region_metric_val_id, sa.pm_val_id
						  FROM region_metric_val v
						  LEFT JOIN est_space_attr sa 
						    ON sa.app_sid = v.app_sid
						   AND sa.region_metric_val_id = v.region_metric_val_id
						   AND sa.est_account_sid = b.est_account_sid
						   AND sa.pm_customer_id = b.pm_customer_id
						   AND sa.pm_building_id = b.pm_building_id
						   AND sa.pm_space_id = s.pm_space_id
						 WHERE v.app_sid = SYS_CONTEXT('SECURITY', 'APP')
						   AND v.region_sid = s.region_sid
					) LOOP
						BEGIN
							INSERT INTO est_job_attr (est_job_id, region_metric_val_id, pm_val_id)
							VALUES (v_job_id, r.region_metric_val_id, r.pm_val_id);
						EXCEPTION
							WHEN DUP_VAL_ON_INDEX THEN
								NULL;
						END;
					END LOOP;

					UPDATE est_job
					   SET created_by_user_sid = SYS_CONTEXT('SECURITY', 'SID')
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND est_job_id = v_job_id;

					v_job_ids_created(v_job_ids_created.COUNT) := v_job_id;

				END LOOP;

				-- 3. Jobs to push child meters and readings
				FOR m IN (
					SELECT pm_meter_id, region_sid
					  FROM est_meter
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND est_account_sid = b.est_account_sid
					   AND pm_customer_id = b.pm_customer_id
					   AND pm_building_id = b.pm_building_id
					   AND region_sid IS NOT NULL
					   AND missing = 0
				) LOOP
					QueueSingleJob(
						in_app_sid				=> SYS_CONTEXT('SECURITY', 'APP'),
						in_job_type_id			=> energy_star_job_pkg.JOB_TYPE_METER,
						in_est_account_sid		=> b.est_account_sid,
						in_pm_customer_id		=> b.pm_customer_id,
						in_pm_building_id		=> b.pm_building_id,
						in_pm_meter_id			=> m.pm_meter_id,
						in_update_pm_object		=> 1,
						out_job_id				=> v_job_id
					);

					FOR r IN (
						SELECT meter_reading_id, pm_reading_id
						  FROM v$meter_reading
						 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
						   AND region_sid = m.region_sid
					) LOOP
						BEGIN
							INSERT INTO est_job_reading (est_job_id, meter_reading_id, pm_reading_id)
							VALUES (v_job_id, r.meter_reading_id, r.pm_reading_id);
						EXCEPTION
							WHEN DUP_VAL_ON_INDEX THEN
								NULL;
						END;
					END LOOP;

					UPDATE est_job
					   SET created_by_user_sid = SYS_CONTEXT('SECURITY', 'SID')
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND est_job_id = v_job_id;

					v_job_ids_created(v_job_ids_created.COUNT) := v_job_id;

				END LOOP;

				-- 4. Jobs to push any new regions (if the regions are not mappable the job will just complete with no action)
				FOR r IN (
					SELECT r.region_sid
					  FROM region r
					 WHERE region_type IN (csr_data_pkg.REGION_TYPE_SPACE, csr_data_pkg.REGION_TYPE_METER)
					   AND NOT EXISTS (
							SELECT 1
							  FROM est_building b
							WHERE b.region_sid = r.region_sid
							UNION
							SELECT 1
							FROM est_space s
							WHERE s.region_sid = r.region_sid
							UNION
							SELECT 1
							FROM est_meter m
							WHERE m.region_sid = r.region_sid
							)
					 START WITH r.region_sid = in_prop_region_sid
					 CONNECT BY PRIOR r.region_sid = r.parent_sid
				) LOOP
					QueueSingleJob(
						in_app_sid				=> SYS_CONTEXT('SECURITY', 'APP'),
						in_job_type_id			=> energy_star_job_pkg.JOB_TYPE_REGION,
						in_est_account_sid		=> b.est_account_sid,
						in_pm_customer_id		=> b.pm_customer_id,
						in_region_sid			=> r.region_sid,
						in_update_pm_object		=> 1,
						out_job_id				=> v_job_id
					);

					UPDATE est_job
					   SET created_by_user_sid = SYS_CONTEXT('SECURITY', 'SID')
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND est_job_id = v_job_id;

					v_job_ids_created(v_job_ids_created.COUNT) := v_job_id;
					
				END LOOP;

				-- 5. Job to pull read-only property metrics
				QueueSingleJob(
					in_app_sid				=> SYS_CONTEXT('SECURITY', 'APP'),
					in_job_type_id			=> energy_star_job_pkg.JOB_TYPE_READONLY_METRICS,
					in_est_account_sid		=> b.est_account_sid,
					in_pm_customer_id		=> b.pm_customer_id,
					in_pm_building_id		=> b.pm_building_id,
					out_job_id				=> v_job_id
				);

				UPDATE est_job
				   SET created_by_user_sid = SYS_CONTEXT('SECURITY', 'SID')
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND est_job_id = v_job_id;

				v_job_ids_created(v_job_ids_created.COUNT) := v_job_id;

			END LOOP;
		END IF;
	END IF;

	-- Return created job information
	t_job_ids_created := security_pkg.SidArrayToTable(v_job_ids_created);
	OPEN out_cur FOR
		SELECT j.est_job_id, j.est_account_sid, j.pm_customer_id, j.pm_building_id, j.pm_space_id, 
			j.pm_meter_id, j.region_sid, j.est_job_type_id, jt.description job_type_desc
		  FROM est_job j
		  JOIN est_job_type jt ON jt.est_job_type_id = j.est_job_type_id
		  JOIN TABLE(t_job_ids_created) c ON c.column_value = j.est_job_id
		  	ORDER BY j.est_job_id;
END;

PROCEDURE GetJobs(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF security.user_pkg.IsSuperAdmin != 1 THEN
		RAISE_APPLICATION_ERROR(security.Security_pkg.ERR_ACCESS_DENIED, 'You do not have permissions to view energystar jobs');
	END IF;
	
	OPEN out_cur FOR
		SELECT j.app_sid, j.est_job_id, j.est_account_sid, j.pm_customer_id, j.pm_building_id, j.pm_space_id, j.pm_meter_id, j.region_sid,
			j.est_job_type_id, j.est_job_state_id, j.processing, j.process_after_dtm, j.last_attempt_dtm, j.update_pm_object,
			COALESCE(p1.energy_star_sync, p2.energy_star_sync, 0) energy_star_sync, -- no region, no sync anyway
			COALESCE(p1.energy_star_push, p2.energy_star_push, 0) energy_star_push,
			j.attempts, c.est_job_notify_after_attempts notify_after_attempts,
			c.est_job_notify_address notify_address, j.notified, c.host,
			j.created_by_user_sid, SYSDATE db_timestamp
		  FROM est_job j
		  JOIN customer c ON j.app_sid = c.app_sid
		  -- Join to property using ether the job's region sid or the building's region sid (if both match they *should* be the same)
		  LEFT JOIN est_building b ON j.app_sid = b.app_sid AND j.est_account_sid = b.est_account_sid AND j.pm_customer_id = b.pm_customer_id AND j.pm_building_id = b.pm_building_id
		  LEFT JOIN property p1 ON b.region_sid = p1.region_sid
		  LEFT JOIN property p2 ON j.region_sid = p2.region_sid
		  LEFT JOIN est_space es ON j.app_sid = es.app_sid AND j.est_account_sid = es.est_account_sid AND j.pm_customer_id = es.pm_customer_id AND j.pm_space_id = es.pm_space_id
		  LEFT JOIN est_meter em ON j.app_sid = em.app_sid AND j.est_account_sid = em.est_account_sid AND j.pm_customer_id = em.pm_customer_id AND j.pm_meter_id = em.pm_meter_id
		  LEFT JOIN trash trash_b  ON b.region_sid  = trash_b.trash_sid
		  LEFT JOIN trash trash_j  ON j.region_sid  = trash_j.trash_sid
		  LEFT JOIN trash trash_es ON es.region_sid = trash_es.trash_sid
		  LEFT JOIN trash trash_em ON em.region_sid = trash_em.trash_sid
		 WHERE (b.region_sid IS NULL OR trash_b.trash_sid IS NULL)
		   AND (j.region_sid IS NULL OR trash_j.trash_sid IS NULL)
		   AND (p1.energy_star_push = 0 OR (es.region_sid IS NULL OR trash_es.trash_sid IS NULL))
		   AND (p1.energy_star_push = 0 OR (em.region_sid IS NULL OR trash_em.trash_sid IS NULL))
		;
END;


PROCEDURE DeleteJob(
	in_est_job_id				est_job.est_job_id%TYPE
)
AS
BEGIN
	IF security.user_pkg.IsSuperAdmin != 1 THEN
		RAISE_APPLICATION_ERROR(security.Security_pkg.ERR_ACCESS_DENIED, 'You do not have permissions to delete energystar jobs');
	END IF;

	-- Set any errors matching the job's region signature to inactive
	UPDATE est_error
	   SET active = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND active = 1
	   AND region_sid IN (
	   	SELECT region_sid
		  FROM est_job
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND in_est_job_id = in_est_job_id
	   );

	-- Set any errors matching the job's pm id signature to inactive
	UPDATE est_error
	   SET active = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND active = 1
	   AND (
	 	est_account_sid, pm_customer_id, pm_building_id, 
	 	NVL(pm_space_id, '-1'), NVL(pm_meter_id, '-1')
	   ) IN (
	   	SELECT 
			est_account_sid, pm_customer_id, pm_building_id,
			NVL(pm_space_id, '-1'), NVL(pm_meter_id, '-1')
		  FROM est_job
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND in_est_job_id = in_est_job_id
	   );

	DELETE FROM est_job_attr
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_job_id = in_est_job_id;

	DELETE FROM est_job_reading
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_job_id = in_est_job_id;

	DELETE FROM est_job 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_job_id = in_est_job_id;
END;


END energy_star_job_pkg;
/

