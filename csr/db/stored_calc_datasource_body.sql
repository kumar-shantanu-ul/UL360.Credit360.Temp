CREATE OR REPLACE PACKAGE BODY CSR.stored_calc_datasource_pkg AS

PROCEDURE BatchTrigger(
	in_host							IN	VARCHAR2,
	in_default_port					IN	NUMBER,
	in_batch_job_id					IN	NUMBER
)
AS LANGUAGE JAVA NAME 'BatchTrigger.send(java.lang.String, int, long)';

PROCEDURE TriggerPoll
AS
BEGIN
	BatchTrigger('*', 998, 0);
END;

PROCEDURE DisableJobCreation(
	in_app_sid						IN	calc_job.app_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY', 'APP')
)
AS
	v_lock_handle 					VARCHAR2(128);
	v_lock_result 					INTEGER;
BEGIN
	dbms_lock.allocate_unique(
		lockname 			=> 'CALC_JOB_CREATION_'||in_app_sid, 
		lockhandle			=> v_lock_handle
	);
	v_lock_result := dbms_lock.request(
		lockhandle 			=> v_lock_handle, 
		lockmode 			=> dbms_lock.s_mode, 
		timeout 			=> dbms_lock.maxwait, 
		release_on_commit	=> FALSE
	);
	IF v_lock_result NOT IN (0, 4) THEN -- 0 = success; 4 = already held
		RAISE_APPLICATION_ERROR(-20001, 'Disabling calc job creation for the app with sid '||in_app_sid||' failed with '||v_lock_result);
	END IF;
END;

PROCEDURE EnableJobCreation(
	in_app_sid						IN	calc_job.app_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY', 'APP')
)
AS
	v_lock_handle 					VARCHAR2(128);
	v_lock_result 					INTEGER;
BEGIN
	dbms_lock.allocate_unique(
		lockname 			=> 'CALC_JOB_CREATION_'||in_app_sid, 
		lockhandle			=> v_lock_handle
	);
	v_lock_result := dbms_lock.release(
		lockhandle			=> v_lock_handle
	);
	IF v_lock_result != 0 AND v_lock_result != 4 THEN -- 0 = success, 4 = lock not held
		RAISE_APPLICATION_ERROR(-20001, 'Enabling calc job creation for the app with sid '||in_app_sid||' failed with '||v_lock_result);
	END IF;
END;

PROCEDURE GetOrCreateCalcJob(
	in_app_sid						IN	calc_job.app_sid%TYPE,
	in_calc_job_type				IN	calc_job.calc_job_type%TYPE,
	in_scenario_run_sid				IN	calc_job.scenario_run_sid%TYPE,
	in_start_dtm					IN	calc_job.start_dtm%TYPE,
	in_end_dtm						IN	calc_job.end_dtm%TYPE,
	in_full_recompute				IN	calc_job.full_recompute%TYPE,
	in_delay_publish_scenario		IN	calc_job.delay_publish_scenario%TYPE,
	out_calc_job_id					OUT	calc_job.calc_job_id%TYPE
)
AS
	v_customer_priority				customer.calc_job_priority%TYPE;
	v_file_based					scenario.file_based%TYPE := 0;
	v_scrag_queue					customer.scrag_queue%TYPE;
	v_calc_queue_id					calc_job.calc_queue_id%TYPE;
BEGIN
	-- it's ok to do this rather than inserting first as we've got a row lock
	UPDATE calc_job
	   SET start_dtm = LEAST(start_dtm, in_start_dtm),
	   	   end_dtm = GREATEST(end_dtm, in_end_dtm),
	   	   full_recompute = GREATEST(full_recompute, in_full_recompute),
	   	   delay_publish_scenario = GREATEST(delay_publish_scenario, in_delay_publish_scenario)
	 WHERE app_sid = in_app_sid
	   AND calc_job_type = in_calc_job_type
	   AND NVL(in_scenario_run_sid, -1) = NVL(scenario_run_sid, -1)
	   AND processing = 0
	   	   RETURNING calc_job_id INTO out_calc_job_id;

	IF SQL%ROWCOUNT = 0 THEN				 
		-- get the calc job queue + calc job priority for the customer
		SELECT calc_job_priority, scrag_queue
		  INTO v_customer_priority, v_scrag_queue
		  FROM customer
		 WHERE app_sid = in_app_sid;

		-- see if this is a test job for scrag++
		IF in_scenario_run_sid IS NOT NULL THEN
			SELECT file_based
			  INTO v_file_based
			  FROM scenario s, scenario_run sr
			 WHERE s.app_sid = sr.app_sid AND s.scenario_sid = sr.scenario_sid
			   AND sr.scenario_run_sid = in_scenario_run_sid;			
		END IF;
		
		IF v_file_based = 1 THEN
			v_scrag_queue := 'csr.scragpp_queue';
		ELSE
			v_scrag_queue := NVL(v_scrag_queue, 'csr.scrag_queue');
		END IF;
		
		SELECT calc_queue_id
		  INTO v_calc_queue_id
		  FROM calc_queue
		 WHERE name = UPPER(v_scrag_queue);

		INSERT INTO calc_job (app_sid, calc_queue_id, calc_job_id, calc_job_type,
			scenario_run_sid, start_dtm, end_dtm, full_recompute, delay_publish_scenario, priority)
		VALUES (in_app_sid, v_calc_queue_id, calc_job_id_seq.NEXTVAL, in_calc_job_type,
			in_scenario_run_sid, in_start_dtm, in_end_dtm, in_full_recompute, in_delay_publish_scenario, 
			v_customer_priority)
		RETURNING calc_job_id INTO out_calc_job_id;
	END IF;
END;

PROCEDURE AddFullScenarioJob(
	in_app_sid						IN	calc_job.app_sid%TYPE,
	in_scenario_run_sid				IN	calc_job.scenario_run_sid%TYPE,
	in_full_recompute				IN	calc_job.full_recompute%TYPE,
	in_delay_publish_scenario		IN	calc_job.delay_publish_scenario%TYPE
)
AS
	v_calc_job_id					calc_job.calc_job_id%TYPE;
	v_calc_start_dtm				customer.calc_start_dtm%TYPE;
	v_calc_end_dtm					customer.calc_end_dtm%TYPE;
BEGIN
	SELECT calc_start_dtm, calc_end_dtm
	  INTO v_calc_start_dtm, v_calc_end_dtm
	  FROM customer;

	GetOrCreateCalcJob(in_app_sid, CALC_JOB_TYPE_SCENARIO, in_scenario_run_sid,
		v_calc_start_dtm, v_calc_end_dtm, in_full_recompute, 
		in_delay_publish_scenario, v_calc_job_id);

	INSERT INTO calc_job_ind (app_sid, calc_job_id, ind_sid)
		SELECT in_app_sid, v_calc_job_id, ind_sid
		  FROM (SELECT ind_sid
				  FROM ind
				 WHERE app_sid = in_app_sid
				 MINUS
				SELECT ind_sid
				  FROM calc_job_ind
				 WHERE app_sid = in_app_sid AND calc_job_id = v_calc_job_id);

	INSERT INTO calc_job_aggregate_ind_group (app_sid, calc_job_id, aggregate_ind_group_id)
		SELECT app_sid, v_calc_job_id, aggregate_ind_group_id
		  FROM aggregate_ind_group
		 WHERE app_sid = in_app_sid
		 MINUS 
		SELECT app_sid, v_calc_job_id, aggregate_ind_group_id
		  FROM calc_job_aggregate_ind_group
		 WHERE app_sid = in_app_sid
		   AND calc_job_id = v_calc_job_id;
END;

-- private
PROCEDURE UpdateAggIndGroupsForIndJobs(
	in_app_sid						IN	calc_job.app_sid%TYPE,
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE
)
AS
BEGIN
	INSERT INTO calc_job_aggregate_ind_group (app_sid, calc_job_id, aggregate_ind_group_id)
		SELECT app_sid, in_calc_job_id, aggregate_ind_group_id
		  FROM aggregate_ind_calc_job 
		 WHERE app_sid = in_app_sid
		 UNION
		SELECT app_sid, in_calc_job_id, aggregate_ind_group_id
		  FROM aggregate_ind_group_member
		 WHERE (app_sid, ind_sid) IN (
				SELECT app_sid, ind_sid
				  FROM calc_job_ind
				 WHERE app_sid = in_app_sid AND calc_job_id = in_calc_job_id)
		 MINUS 
		SELECT app_sid, calc_job_id, aggregate_ind_group_id
		  FROM calc_job_aggregate_ind_group
		 WHERE app_sid = in_app_sid AND calc_job_id = in_calc_job_id;
END;

PROCEDURE AddMergedIndJobs(
	in_app_sid						IN	calc_job.app_sid%TYPE,
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE
)
AS
BEGIN
	INSERT INTO calc_job_ind (app_sid, calc_job_id, ind_sid)
		SELECT in_app_sid, in_calc_job_id, ind_sid
		  FROM (SELECT ind_sid
		  		  FROM val_change_log
		  		 WHERE app_sid = in_app_sid
		  		 MINUS
		  		SELECT ind_sid
		  		  FROM calc_job_ind
		  		 WHERE app_sid = in_app_sid AND calc_job_id = in_calc_job_id);

	UpdateAggIndGroupsForIndJobs(in_app_sid, in_calc_job_id);
END;

PROCEDURE AddUnmergedIndJobs(
	in_app_sid						IN	calc_job.app_sid%TYPE,
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE
)
AS
BEGIN
	INSERT INTO calc_job_ind (app_sid, calc_job_id, ind_sid)
		SELECT in_app_sid, in_calc_job_id, ind_sid
		  FROM (SELECT ind_sid
		  		  FROM val_change_log
		  		 WHERE app_sid = in_app_sid
		  		 UNION
		  		SELECT ind_sid
		  		  FROM sheet_val_change_log
		  		 WHERE app_sid = in_app_sid
		  		 MINUS
		  		SELECT ind_sid
		  		  FROM calc_job_ind
		  		 WHERE app_sid = in_app_sid AND calc_job_id = in_calc_job_id);

	UpdateAggIndGroupsForIndJobs(in_app_sid, in_calc_job_id);
END;

FUNCTION TryLockApp(
	in_app_sid						IN	app_lock.app_sid%TYPE
)
RETURN BOOLEAN
AS
BEGIN
	IF NOT csr_data_pkg.TryLockApp(in_app_sid, csr_data_pkg.LOCK_TYPE_CALC) THEN
		RETURN FALSE;
	END IF;
	IF NOT csr_data_pkg.TryLockApp(in_app_sid, csr_data_pkg.LOCK_TYPE_SHEET_CALC) THEN
		COMMIT; -- release earlier lock
		RETURN FALSE;
	END IF;
	RETURN TRUE;
END;

PROCEDURE QueueCalcJob(
	in_app_sid						IN	calc_job.app_sid%TYPE
)
AS
	v_start_dtm						calc_job.start_dtm%TYPE;
	v_end_dtm						calc_job.end_dtm%TYPE;
	v_calc_job_id					calc_job.calc_job_id%TYPE;
	v_auto_unmerged_scenarios 		NUMBER;
	v_scenario_run_sid				scenario_run.scenario_run_sid%TYPE;
	v_merged_scenario_run_sid		customer.merged_scenario_run_sid%TYPE;
	v_lock_handle 					VARCHAR2(128);
	v_lock_result 					INTEGER;
	v_calc_start_dtm				customer.calc_start_dtm%TYPE;
	v_calc_end_dtm					customer.calc_end_dtm%TYPE;
BEGIN		
	dbms_lock.allocate_unique(
		lockname 			=> 'CALC_JOB_CREATION_'||in_app_sid, 
		lockhandle			=> v_lock_handle
	);
	v_lock_result := dbms_lock.request(
		lockhandle 			=> v_lock_handle, 
		lockmode 			=> dbms_lock.x_mode, 
		timeout 			=> 0, 
		release_on_commit	=> TRUE
	);
	IF v_lock_result NOT IN (0, 1, 4) THEN -- 0 = success, 1 = timeout, 4 = already own lock
		RAISE_APPLICATION_ERROR(-20001, 'Locking calc job creation for the app with sid '||in_app_sid||' failed with '||v_lock_result);
	END IF;
	IF v_lock_result = 1 THEN
		RETURN; -- skip for now
	END IF;
	-- else success or already owned lock
	
	-- prevent jobs from changing while we are looking at them
	IF NOT TryLockApp(in_app_sid) THEN
		RETURN; -- app locked, skip this time
	END IF;

	SELECT calc_start_dtm, calc_end_dtm
	  INTO v_calc_start_dtm, v_calc_end_dtm
	  FROM customer;

	-- jobs for merged data
	SELECT LEAST(v_calc_end_dtm, GREATEST(v_calc_start_dtm, MIN(start_dtm))),
		   LEAST(v_calc_end_dtm, GREATEST(v_calc_start_dtm, MAX(end_dtm)))
	  INTO v_start_dtm, v_end_dtm
	  FROM (SELECT start_dtm, end_dtm
			  FROM val_change_log
			 WHERE app_sid = in_app_sid
			 UNION
			SELECT start_dtm, end_dtm
			  FROM aggregate_ind_calc_job
			 WHERE app_sid = in_app_sid);	

	IF v_end_dtm > v_start_dtm THEN -- null implies no rows
		-- create jobs for old style merged data with calc results dumped into val
		-- if necessary
		SELECT merged_scenario_run_sid
		  INTO v_merged_scenario_run_sid
		  FROM customer
		 WHERE app_sid = in_app_sid;
		IF v_merged_scenario_run_sid IS NULL THEN
			GetOrCreateCalcJob(in_app_sid, CALC_JOB_TYPE_STANDARD, NULL,
				v_start_dtm, v_end_dtm, 0, 0, v_calc_job_id);
			AddMergedIndJobs(in_app_sid, v_calc_job_id);
		END IF;

		-- we have changes to merged data, so also write jobs for auto update scenarios based on merged data
		FOR s IN (SELECT auto_update_run_sid
					FROM scenario
				   WHERE app_sid = in_app_sid
					 AND auto_update_run_sid IS NOT NULL
					 AND recalc_trigger_type = RECALC_TRIGGER_MERGED) LOOP
			GetOrCreateCalcJob(in_app_sid, CALC_JOB_TYPE_SCENARIO, s.auto_update_run_sid,
				v_calc_start_dtm, v_calc_end_dtm, 0, 0, v_calc_job_id);
			AddMergedIndJobs(in_app_sid, v_calc_job_id);
		END LOOP;
	END IF;

	-- see if there are any auto-updated unmerged scenarios
	SELECT COUNT(*)
	  INTO v_auto_unmerged_scenarios
	  FROM DUAL
	 WHERE EXISTS (SELECT 1
					 FROM scenario
					WHERE recalc_trigger_type = RECALC_TRIGGER_UNMERGED
					  AND auto_update_run_sid IS NOT NULL
					  AND app_sid = in_app_sid);

	-- jobs for unmerged data
	IF v_auto_unmerged_scenarios != 0 THEN
		-- Messy, but what it says is "the least not null value"
		SELECT LEAST(v_calc_end_dtm, GREATEST(v_calc_start_dtm,
				COALESCE(LEAST(MIN(start_dtm), v_start_dtm), MIN(start_dtm), v_start_dtm))),
			   LEAST(v_calc_end_dtm, GREATEST(v_calc_start_dtm,
				COALESCE(LEAST(MIN(end_dtm), v_end_dtm), MIN(end_dtm), v_end_dtm)))
		  INTO v_start_dtm, v_end_dtm
		  FROM sheet_val_change_log
		 WHERE app_sid = in_app_sid;
		 
		IF v_end_dtm > v_start_dtm THEN -- null implies no rows
			-- we have changes to unmerged data, so write jobs for auto update scenarios based on unmerged data
			FOR s IN (SELECT auto_update_run_sid
						FROM scenario
					   WHERE app_sid = in_app_sid
						 AND auto_update_run_sid IS NOT NULL
						 AND recalc_trigger_type = RECALC_TRIGGER_UNMERGED) LOOP
				GetOrCreateCalcJob(in_app_sid, CALC_JOB_TYPE_SCENARIO, s.auto_update_run_sid,
					v_calc_start_dtm, v_calc_end_dtm, 0, 0, v_calc_job_id);
				AddUnmergedIndJobs(in_app_sid, v_calc_job_id);			
			END LOOP;
		END IF;
	END IF;
	
	-- once split, the change logs can be cleared down
	DELETE FROM val_change_log
	 WHERE app_sid = in_app_sid;
	DELETE FROM sheet_val_change_log
	 WHERE app_sid = in_app_sid;
	DELETE FROM aggregate_ind_calc_job
	 WHERE app_sid = in_app_sid;

	-- handle auto update scenario run requests
	FOR s IN (SELECT sc.auto_update_run_sid, sarr.full_recompute, sarr.delay_publish_scenario
				FROM scenario_auto_run_request sarr
				JOIN scenario sc ON sarr.app_sid = sc.app_sid AND sarr.scenario_sid = sc.scenario_sid
			   WHERE sarr.app_sid = in_app_sid
				 AND sc.auto_update_run_sid IS NOT NULL) LOOP
		AddFullScenarioJob(in_app_sid, s.auto_update_run_sid, s.full_recompute, s.delay_publish_scenario);
	END LOOP;

	DELETE FROM scenario_auto_run_request
	 WHERE app_sid = in_app_sid;
	 
	-- handle manual scenario run requests
	FOR s IN (SELECT sc.scenario_sid, smrr.description
				FROM scenario_man_run_request smrr, scenario sc
			   WHERE smrr.app_sid = in_app_sid
				 AND smrr.app_sid = sc.app_sid AND smrr.scenario_sid = sc.scenario_sid) LOOP
		scenario_run_pkg.CreateScenarioRun(s.scenario_sid, s.description, v_scenario_run_sid);
		AddFullScenarioJob(in_app_sid, v_scenario_run_sid, 1, 0); -- either is fine for full recompute as the run is new
	END LOOP;		
	DELETE FROM scenario_man_run_request
	 WHERE app_sid = in_app_sid;

	-- these jobs are now consistent so commit to release locks
	COMMIT;
	
	-- trigger any idle calc job runners to poll
	--TriggerPoll;
END;

PROCEDURE QueueCalcJobs
AS
BEGIN
	-- log in for 10 minutes only as should complete quickly, and runs every 15 seconds
	security.user_pkg.LogonAdmin(timeout => 600);

	FOR r IN (SELECT DISTINCT app_sid app_sid
				FROM val_change_log
			   UNION
			  SELECT DISTINCT app_sid
			    FROM sheet_val_change_log
			   UNION
			  SELECT DISTINCT app_sid
			    FROM aggregate_ind_calc_job
			   UNION
			  SELECT DISTINCT app_sid
			    FROM scenario_auto_run_request
			   UNION
			  SELECT DISTINCT app_sid
			    FROM scenario_man_run_request) LOOP
		
		security_pkg.setApp(r.app_sid);
		QueueCalcJob(r.app_sid);
	END LOOP;
	
	-- log off when done
	security.user_pkg.LogOff(security.security_pkg.GetAct);
END;

/**
 * Internal -- locks a calc job so that it cannot be changed
 * uses a separate transaction so that DequeueCalcJob doesn't remove 
 * the message before it has completed processing it.
 *
 * @param in_app_sid				The app to lock for
 * @param in_calc_job_id			id of the calc job to lock
 * @return boolean indicating if the job was locked successfully
 */
FUNCTION LockCalcJob(
	in_app_sid						IN	calc_job.app_sid%TYPE,
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	in_ignore_phase					IN	BOOLEAN DEFAULT FALSE
)
RETURN BOOLEAN
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
	v_ignore_phase					NUMBER := 0;
BEGIN
	IF in_ignore_phase THEN
		v_ignore_phase := 1;
	END IF;

	-- this means new jobs can't be added while we eat the job
	csr_data_pkg.LockApp(in_app_sid => in_app_sid, in_lock_type => csr_data_pkg.LOCK_TYPE_CALC);
	
	-- lock the job -- if it fails because we are already processing a job of 
	-- the same type or because it was just processed, failed and isn't due a retry
	-- yet then return failure.
	BEGIN
		UPDATE calc_job
		   SET processing = 1,
		   	   last_attempt_dtm = SYSDATE,
		   	   running_on = SYS_CONTEXT('USERENV', 'HOST'),
		   	   phase = PHASE_GET_DATA,
		   	   updated_dtm = SYSDATE,
		   	   attempts = attempts + 1
		 WHERE app_sid = in_app_sid
		   AND calc_job_id = in_calc_job_id
		   AND (v_ignore_phase = 1 OR 
		   		(phase IN (PHASE_IDLE, PHASE_FAILED) AND 
		   		 process_after_dtm < SYSDATE));
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			COMMIT; -- release locks
			RETURN FALSE;
	END;
	IF SQL%ROWCOUNT = 0 THEN
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
PROCEDURE MarkFailedJobs(
	in_calc_queue_id				IN	NUMBER
)
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
		MERGE INTO calc_job cj
		USING (
			SELECT /*+CARDINALITY(cj, 100)*/ cj.calc_job_id, c.failed_calc_job_retry_delay, cj.attempts
			  FROM calc_job cj
			  JOIN customer c ON c.app_sid = cj.app_sid
			  LEFT JOIN (
					SELECT /*+CARDINALITY(cj, 100)*/ cj.app_sid, cj.calc_job_id, cj.scenario_run_sid
  					  FROM calc_job cj
  					  JOIN sys.dbms_lock_allocated dla ON 'CALC_JOB_'||cj.app_sid||'_'||NVL(cj.scenario_run_sid, 0)||'_'||in_calc_queue_id = dla.name
  					  JOIN v$lock l ON dla.lockid = l.id1
 					 WHERE NVL(l.lmode, 0) != 0) l
 				ON cj.app_sid = l.app_sid AND cj.calc_job_id = l.calc_job_id
 			 WHERE cj.phase NOT IN (PHASE_IDLE, PHASE_FAILED)
 			   AND l.calc_job_id IS NULL
 			   AND cj.calc_queue_id = in_calc_queue_id
		) cjf
 		   ON (cjf.calc_job_id = cj.calc_job_id)
 		 WHEN matched THEN
 			UPDATE
 			   SET cj.phase = PHASE_FAILED, 
				   cj.work_done = 0,
				   cj.total_work = 0,
				   cj.updated_dtm = SYSDATE,
				   cj.running_on = NULL,
				   cj.process_after_dtm = SYSDATE + 
			   		CASE
			   			-- now acts as a boolean flag useful for testing
			   			WHEN cjf.failed_calc_job_retry_delay = 0 THEN 0 
			   			-- exponential backoff
			   			-- note that LEAST on the exponent is needed to prevent 
			   			-- overflow with a large number of attempts
			   			ELSE LEAST(1440, POWER(2, LEAST(11, cjf.attempts)) * 10) / 1440
			   		END;
	EXCEPTION
		WHEN MERGE_ROWS_UNSTABLE THEN
			NULL;
	END;

	COMMIT;
END;

-- Mark jobs that have failed in the UI -- this can take a little while if all
-- instances of scrag are busy so we also poke it periodically from an oracle
-- dbms_scheduler job
PROCEDURE MarkFailedJobs
AS
BEGIN
	FOR r IN (SELECT calc_queue_id
	 			FROM calc_queue) LOOP
		MarkFailedJobs(r.calc_queue_id);
	END LOOP;
END;

PROCEDURE DequeueCalcJob(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE
)
AS
	v_app_sid						calc_job.app_sid%TYPE;
	v_scenario_run_sid				calc_job.scenario_run_sid%TYPE;
	v_calc_queue_id					calc_job.calc_queue_id%TYPE;
	v_lock_handle 					VARCHAR2(128);
	v_lock_result 					INTEGER;
BEGIN
	BEGIN
		SELECT app_sid, scenario_run_sid, calc_queue_id
		  INTO v_app_sid, v_scenario_run_sid, v_calc_queue_id
		  FROM calc_job
		 WHERE calc_job_id = in_calc_job_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_OBJECT_NOT_FOUND, 'The calc job with id '||in_calc_job_id||' does not exist');
	END;
	
	-- First, take the job lock which indicates processing is in progress
	--security_pkg.debugmsg('scrag '||USERENV('SID')||': take job lock for '||'CALC_JOB_'||v_app_sid||'_'||NVL(v_scenario_run_sid, 0));
	dbms_lock.allocate_unique(
		lockname 			=> 'CALC_JOB_'||v_app_sid||'_'||NVL(v_scenario_run_sid, 0)||'_'||v_calc_queue_id,
		lockhandle			=> v_lock_handle
	);
	v_lock_result := dbms_lock.request(
		lockhandle 			=> v_lock_handle, 
		lockmode 			=> dbms_lock.x_mode, 
		timeout 			=> 0, --dbms_lock.maxwait, 
		release_on_commit	=> TRUE
	);
	
	IF v_lock_result = 1 THEN
		-- if the lock timed out then someone else is processing this
		RAISE_APPLICATION_ERROR(-20001, 'Locking the calc job with id '||in_calc_job_id||' timed out');
	END IF;
	
	IF v_lock_result NOT IN (0, 4) THEN -- 0 = success; 4 = already held
		RAISE_APPLICATION_ERROR(-20001, 'Locking the calc job with id '||in_calc_job_id||' for the app with sid '||v_app_sid||
			' and scenario run with sid '||v_scenario_run_sid||' failed with '||v_lock_result);
	END IF;

	-- Next try to lock the job row (ignoring the current job state as this is
	-- a manual retry so it doesn't matter if it's only just failed)
	IF NOT LockCalcJob(v_app_sid, in_calc_job_id, TRUE) THEN
		-- This shouldn't happen often -- if the job was picked up, tried and failed
		-- then LockCalcJob will detect this and return FALSE, so tidy up and re-run
		-- the find jobs query
		v_lock_result := dbms_lock.release(
			lockhandle			=> v_lock_handle
		);
		IF v_lock_result NOT IN (0, 4) THEN -- 0 = success, 4 = lock not held
			--security_pkg.debugmsg('scrag '||USERENV('SID')||': Releasing the calc job lock for the app with sid '||r.app_sid||
			--	' failed with '||v_lock_result);
			RAISE_APPLICATION_ERROR(-20001, 'Releasing the calc job lock for the app with sid '||v_app_sid||
				' failed with '||v_lock_result);
		END IF;
		
		-- Locking the calc job failed, why?				
		--security_pkg.debugmsg('scrag '||USERENV('SID')||': LockCalcJob failed for the job with id '||r.calc_job_id);
		RAISE_APPLICATION_ERROR(-20001, 'Locking the calc job with id '||in_calc_job_id||' for the app with sid '||v_app_sid||
			' and scenario run with sid '||v_scenario_run_sid||' failed');
	END IF;
	
	-- Ok, so we've got a locked job ready for processing
END;

PROCEDURE DequeueCalcJob(
	in_min_priority					IN	NUMBER,
	in_max_priority					IN	NUMBER,
	in_queue_name					IN	VARCHAR2,
	in_host							IN	customer.host%TYPE,
	out_calc_job_id					OUT	calc_job.calc_job_id%TYPE
)
AS
	v_lock_handle 					VARCHAR2(128);
	v_lock_result 					INTEGER;
	v_calc_queue_id					NUMBER;
	v_again							BOOLEAN;
	v_app_sid						NUMBER;
BEGIN
	-- clear any act for pooled sessions
	dbms_session.clear_identifier;

	out_calc_job_id := NULL;

	BEGIN
		SELECT calc_queue_id
		  INTO v_calc_queue_id
		  FROM calc_queue
		 WHERE name = UPPER(in_queue_name);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'The calc queue with name '||in_queue_name||' could not be found');
	END;
	
	IF in_host IS NOT NULL THEN
		csr.customer_pkg.GetAppSid(in_host, v_app_sid);
	END IF;
		
	LOOP
		MarkFailedJobs(v_calc_queue_id);
		
		-- The dynamic priority for calc jobs is determined as follows:
		--	By priority, then within priority:
		--		Applications with the least number of currently running jobs,
		--		then within applications with the same number of running jobs:
		--			Minimum calc job id for the application (i.e. application with the oldest job),
		--			then:
		--				using an age function which is:
		--              	age = the creation date of the job - the creation date of the earliest job for the app
		--				then computing bins for this using 15 minute intervals:
		--					age_bin = floor(age / 15 minutes)
		--				Ordered by age_bin
		--				then within age_bin:
		--					merged jobs
		--					unmerged jobs
		--					oldest jobs first
		-- In summary:
		--	Calc job priority always wins
		--	After that we try and be fair across applications
		--	After that we try for older jobs first
		--  Then within what we've selected to run for an app we group jobs in 15 minute
		--  windows and consider them to be the same age
		--  Then within the age group we pick merged jobs, unmerged jobs then by
		--  job age (calc job order)
		-- Starvation of newer jobs by failing jobs being rerun is handled by the backoff
		-- (the quadratically increasing time between job attempts, limited to 1 day)
		-- This is a bit flawed in that if 23 scenarios need recomputing we might well start running as many as we can --
		-- then when new jobs come along we have no free slots for a new app.  Seems better to use the slots rather
		-- than leave them empty, and at least the new jobs will slot in higher up (most of the time)
		
		/*dbms_output.put_line('queue id is '||v_calc_queue_id);
		FOR r IN (SELECT cj.app_sid, cj.scenario_run_sid
				    FROM calc_job cj
				    JOIN sys.dbms_lock_allocated dla ON 'CALC_JOB_'||cj.app_sid||'_'||NVL(cj.scenario_run_sid, 0)||'_'||v_calc_queue_id = dla.name
				    JOIN v$lock l ON dla.lockid = l.id1
				   WHERE NVL(l.lmode, 0) != 0
				     AND cj.calc_queue_id = v_calc_queue_id
		) LOOP
			dbms_output.put_line('lock found for app '||r.app_sid||', scenario run '||r.scenario_run_sid);
		END LOOP;
		
		FOR r IN (SELECT app_sid, MIN(calc_job_id) min_calc_job_id
			  		FROM calc_job
			  	   WHERE calc_queue_id = v_calc_queue_id
			  	   GROUP BY app_sid)
		LOOP
			dbms_output.put_line('min calc job for app '||r.app_sid|| ' is '||r.min_calc_job_id);
		END LOOP;
		
		FOR r in (SELECT app_sid, scenario_run_sid, MIN(calc_job_id) min_calc_job_id
			  		FROM calc_job
			  	   WHERE calc_queue_id = v_calc_queue_id
			  	   GROUP BY app_sid, scenario_run_sid) loop
			dbms_output.put_line('min calc job for app '||r.app_sid||', scenario run '||r.scenario_run_sid||' is '||r.min_calc_job_id);
		END LOOP;*/

		v_again := FALSE;
		FOR r IN (
			WITH proc AS (
				SELECT /*+CARDINALITY(cj, 100)*/ cj.app_sid, cj.scenario_run_sid
				  FROM calc_job cj
				  JOIN sys.dbms_lock_allocated dla ON 'CALC_JOB_'||cj.app_sid||'_'||NVL(cj.scenario_run_sid, 0)||'_'||v_calc_queue_id = dla.name
				  JOIN v$lock l ON dla.lockid = l.id1
				 WHERE NVL(l.lmode, 0) != 0
				   AND cj.calc_queue_id = v_calc_queue_id
				   AND cj.processing = 1
			)
			SELECT /*+CARDINALITY(cj, 100)*/
				   cj.app_sid, cj.scenario_run_sid, cj.priority, cj.calc_job_id,
				   FLOOR((created_dtm - FIRST_VALUE(created_dtm) OVER (PARTITION BY cj.app_sid ORDER BY created_dtm)) * (1440 / 15)) age_bin,
				   CASE WHEN cj.scenario_run_sid = c.merged_scenario_run_sid OR cj.scenario_run_sid IS NULL AND c.merged_scenario_run_sid IS NULL THEN 1 ELSE 0 END is_merged,
				   CASE WHEN cj.scenario_run_sid = c.unmerged_scenario_run_sid THEN 1 ELSE 0 END is_unmerged,
				   r.running_jobs
			  FROM calc_job cj
			  JOIN customer c on cj.app_sid = c.app_sid
			  LEFT JOIN (SELECT app_sid, COUNT(*) running_jobs
			  			   FROM proc
			  			  GROUP BY app_sid) r
				ON cj.app_sid = r.app_sid
			  JOIN (SELECT app_sid, MIN(calc_job_id) min_calc_job_id
			  		  FROM calc_job
			  		 WHERE calc_queue_id = v_calc_queue_id
			  		 GROUP BY app_sid) mj
			    ON cj.app_sid = mj.app_sid
			  JOIN (SELECT app_sid, scenario_run_sid, MIN(calc_job_id) min_calc_job_id
			  		  FROM calc_job
			  		 WHERE calc_queue_id = v_calc_queue_id
			  		 GROUP BY app_sid, scenario_run_sid) aj
				ON cj.app_sid = aj.app_sid and cj.calc_job_id = aj.min_calc_job_id
			 WHERE (cj.app_sid, cj.scenario_run_sid) NOT IN (
			 		SELECT app_sid, scenario_run_sid
			 		  FROM proc)
			   AND cj.process_after_dtm <= SYSDATE
			   AND cj.calc_queue_id = v_calc_queue_id
			   AND (in_min_priority IS NULL OR priority >= in_min_priority)
			   AND (in_max_priority IS NULL OR priority <= in_max_priority)
			   AND (c.max_concurrent_calc_jobs IS NULL OR NVL(r.running_jobs, 0) < c.max_concurrent_calc_jobs)
			   AND (v_app_sid IS NULL OR cj.app_sid = v_app_sid)
			   AND c.calc_jobs_disabled = 0
             ORDER BY cj.priority DESC, r.running_jobs DESC, mj.min_calc_job_id,
             	      age_bin ASC, is_merged DESC, is_unmerged DESC, calc_job_id
		) LOOP
			
			-- First, take the job lock which indicates processing is in progress
			--security_pkg.debugmsg('scrag '||USERENV('SID')||': take job lock for '||'CALC_JOB_'||r.app_sid||'_'||NVL(r.scenario_run_sid, 0)||'_'||v_calc_queue_id);
			dbms_lock.allocate_unique(
				lockname 			=> 'CALC_JOB_'||r.app_sid||'_'||NVL(r.scenario_run_sid, 0)||'_'||v_calc_queue_id,
				lockhandle			=> v_lock_handle
			);
			v_lock_result := dbms_lock.request(
				lockhandle 			=> v_lock_handle, 
				lockmode 			=> dbms_lock.x_mode, 
				timeout 			=> 0, --dbms_lock.maxwait, 
				release_on_commit	=> TRUE
			);
			
			IF v_lock_result = 1 THEN
				-- if the lock timed out then this indicates the next job query returned
				-- stale results -- try it again
				--security_pkg.debugmsg('scrag '||USERENV('SID')||': lock timed out -- OK');
				v_again := TRUE;
				EXIT;
			ELSE
				IF v_lock_result NOT IN (0, 4) THEN -- 0 = success; 4 = already held
					RAISE_APPLICATION_ERROR(-20001, 'Locking the calc job for the app with sid '||r.app_sid||
						' and scenario run with sid '||r.scenario_run_sid||' failed with '||v_lock_result);
				END IF;
				--security_pkg.debugmsg('scrag '||USERENV('SID')||': lock result: '||v_lock_result||' lock handle '||v_lock_handle);
			END IF;
	
			-- Next try lock the job row
			IF NOT LockCalcJob(r.app_sid, r.calc_job_id) THEN
				-- This shouldn't happen often -- if the job was picked up, tried and failed
				-- then LockCalcJob will detect this and return FALSE, so tidy up and re-run
				-- the find jobs query
				v_lock_result := dbms_lock.release(
					lockhandle			=> v_lock_handle
				);
				IF v_lock_result NOT IN (0, 4) THEN -- 0 = success, 4 = lock not held
					--security_pkg.debugmsg('scrag '||USERENV('SID')||': Releasing the calc job lock for the app with sid '||r.app_sid||
					--	' failed with '||v_lock_result);
					RAISE_APPLICATION_ERROR(-20001, 'Releasing the calc job lock for the app with sid '||r.app_sid||
						' failed with '||v_lock_result);
				END IF;
				
				-- Locking the calc job failed, why?				
				--security_pkg.debugmsg('scrag '||USERENV('SID')||': LockCalcJob failed for the job with id '||r.calc_job_id);
				v_again := TRUE;
				EXIT;
			END IF;
			
			-- Ok, so we've got a locked job ready for processing
			out_calc_job_id := r.calc_job_id;
			RETURN;
		END LOOP;

		/*IF v_again THEN
			security_pkg.debugmsg('scrag '||USERENV('SID')||': go again');
		ELSE
			security_pkg.debugmsg('scrag '||USERENV('SID')||': waiting');
		END IF;*/

		-- if the loop doesn't need retrying, then return
		IF NOT v_again THEN	
			RETURN;
		END IF;
		
	END LOOP;
END;

PROCEDURE DeleteProcessedCalcJob(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE
)
AS
BEGIN
	-- no lock is required because we have marked the job as in-flight
	DELETE FROM calc_job_ind
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND calc_job_id = in_calc_job_id;

	DELETE FROM calc_job_aggregate_ind_group
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND calc_job_id = in_calc_job_id;

	DELETE FROM calc_job
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND calc_job_id = in_calc_job_id;

	-- sanity check
	IF SQL%ROWCOUNT = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Attempt to delete a non-existent calc job with id '||in_calc_job_id);
	END IF;
END;

PROCEDURE GetCalcJob(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT cj.app_sid, cj.calc_job_id, cj.calc_job_type, sr.scenario_sid, NVL(s.file_based, 0) file_based,
			   cj.scenario_run_sid, cj.start_dtm, cj.end_dtm, cj.last_attempt_dtm, cj.full_recompute,
			   cj.delay_publish_scenario, c.host, cj.attempts, c.calc_job_notify_after_attempts notify_after_attempts,
			   c.calc_job_notify_address notify_address, cj.notified
		  FROM calc_job cj
		  JOIN customer c ON cj.app_sid = c.app_sid
		  LEFT JOIN scenario_run sr ON cj.app_sid = sr.app_sid AND cj.scenario_run_sid = sr.scenario_run_sid
		  LEFT JOIN scenario s ON sr.app_sid = s.app_sid AND sr.scenario_sid = s.scenario_sid
		 WHERE cj.calc_job_id = in_calc_job_id;
END;

PROCEDURE MarkNotified(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE
)
AS
BEGIN
	-- no security, only called from scrag
	UPDATE calc_job
	   SET notified = 1
	 WHERE calc_job_id = in_calc_job_id;
	COMMIT;
END;

PROCEDURE GetDateAdj(
	out_min_adj						OUT	NUMBER,
	out_max_adj						OUT NUMBER
)
AS
	v_min_graph						dag_pkg.Graph;
	v_max_graph						dag_pkg.Graph;
BEGIN
	FOR r in (SELECT calc_ind_sid, ind_sid, calc_start_dtm_adjustment, calc_end_dtm_adjustment
			    FROM v$calc_dependency cd
			   WHERE calc_ind_sid IN (SELECT ind_sid FROM ind_list)) LOOP
		dag_pkg.addEdge(v_min_graph, 0, r.ind_sid, 0);
		dag_pkg.addEdge(v_min_graph, r.calc_ind_sid, r.ind_sid, -r.calc_start_dtm_adjustment);
		dag_pkg.addEdge(v_max_graph, 0, r.ind_sid, 0);
		dag_pkg.addEdge(v_max_graph, r.calc_ind_sid, r.ind_sid, r.calc_end_dtm_adjustment);
	END LOOP;
	out_min_adj := -dag_pkg.longestPath(v_min_graph, 0);
	out_max_adj := dag_pkg.longestPath(v_max_graph, 0);
END;

PROCEDURE AddAggregateInds(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE
)
AS
BEGIN
	-- Include all inds involved in aggregation groups queued for recalculation
	INSERT INTO ind_list (ind_sid)
		SELECT aigm.ind_sid
  		  FROM calc_job_aggregate_ind_group cjaig, aggregate_ind_group_member aigm
  		 WHERE cjaig.calc_job_id = in_calc_job_id
  		   AND cjaig.app_sid = aigm.app_sid AND cjaig.aggregate_ind_group_id = aigm.aggregate_ind_group_id
		 MINUS
		SELECT ind_sid
		  FROM ind_list;
END;

PROCEDURE AddDependantInds
AS
	v_lvl							BINARY_INTEGER := 2;
BEGIN
	-- now we have figured out which stored calcs and calcs to recompute then get all the dependencies of those too
	-- we do this one tree level at a time to avoid explosions in the dependency tree due to adding the same
	-- subtree more than once -- Oracle appears to be incapable of pruning subtrees during connect by
	DELETE FROM temp_calc_tree;
	INSERT INTO temp_calc_tree (lvl, parent_sid, ind_sid)
		SELECT 1, null, ind_sid
		  FROM ind_list;
	LOOP
		INSERT INTO temp_calc_tree (lvl, parent_sid, ind_sid)
			SELECT v_lvl, cd.calc_ind_sid, cd.ind_sid
			  FROM v$calc_dependency cd
			 WHERE cd.calc_ind_sid IN (SELECT ind_sid FROM temp_calc_tree WHERE lvl = v_lvl - 1)
			   AND cd.ind_sid NOT IN (SELECT ind_sid FROM temp_calc_tree);
		EXIT WHEN SQL%ROWCOUNT = 0;
		v_lvl := v_lvl + 1;
	END LOOP;
	
	INSERT INTO ind_list (ind_sid)
		SELECT /*+ALL_ROWS*/ DISTINCT ind_sid
		  FROM temp_calc_tree
		 MINUS
		SELECT ind_sid
		  FROM ind_list;		  
END;

PROCEDURE SelectCalcs(
	in_stored_only					IN	NUMBER
)
AS
	v_lvl							BINARY_INTEGER := 2;
BEGIN
	-- Swap ind_list into ind_list_2
	DELETE FROM ind_list_2;
	INSERT INTO ind_list_2 (ind_sid)
		SELECT ind_sid
		  FROM ind_list;

	-- Find all the stored calculations that depend on anything in ind_list
	-- ind_list is what was in stored calc job, so it contains:
	--   normal indicators that have changed
	--   calcs which have changed
	--   stored calcs which have changed	
	DELETE FROM temp_calc_tree;
	INSERT INTO temp_calc_tree (lvl, parent_sid, ind_sid)
		SELECT 1, null, calc_ind_sid
		  FROM v$calc_dependency
		 WHERE ind_sid IN (SELECT ind_sid FROM ind_list);
	LOOP
		INSERT INTO temp_calc_tree (lvl, parent_sid, ind_sid)
			SELECT v_lvl, cd.ind_sid, cd.calc_ind_sid
			  FROM v$calc_dependency cd
			 WHERE cd.ind_sid IN (SELECT ind_sid FROM temp_calc_tree WHERE lvl = v_lvl - 1)
			   AND cd.calc_ind_sid NOT IN (SELECT ind_sid FROM temp_calc_tree);
		EXIT WHEN SQL%ROWCOUNT = 0;
		v_lvl := v_lvl + 1;
	END LOOP;
	
	DELETE FROM ind_list;
	INSERT INTO ind_list (ind_sid)
		SELECT /*+ALL_ROWS*/ DISTINCT t.ind_sid
		  FROM temp_calc_tree t, ind i
		 WHERE i.ind_sid = t.ind_sid
		   AND ( (in_stored_only = 1 AND i.ind_type = csr_data_pkg.IND_TYPE_STORED_CALC) OR
		   		 (in_stored_only = 0 AND i.ind_type IN (csr_data_pkg.IND_TYPE_CALC, csr_data_pkg.IND_TYPE_STORED_CALC)) );

	-- Add in everything that's not a normal calc from the original set of jobs
	INSERT INTO ind_list (ind_sid)
		SELECT il.ind_sid
		  FROM ind_list_2 il, ind i
		 WHERE i.ind_sid = il.ind_sid
		   AND ( (in_stored_only = 1 AND i.ind_type != csr_data_pkg.IND_TYPE_CALC) OR
		   		 in_stored_only = 0 )
		 MINUS
		SELECT ind_sid
		  FROM ind_list;
END;

PROCEDURE AddScenarioInds(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE
)
AS
	v_scenario_sid					scenario.scenario_sid%TYPE;
BEGIN
	SELECT MIN(scenario_sid)
	  INTO v_scenario_sid
	  FROM scenario_run sr, calc_job cj
	 WHERE cj.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND cj.calc_job_id = in_calc_job_id
	   AND sr.app_sid = cj.app_sid AND sr.scenario_run_sid = cj.scenario_run_sid;

	IF v_scenario_sid IS NULL THEN
		RETURN;
	END IF;
	
	INSERT INTO ind_list (ind_sid)
		SELECT DISTINCT ind_sid
		  FROM scenario_rule_ind
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = v_scenario_sid
		 UNION
		SELECT DISTINCT ind_sid
		  FROM scenario_rule_like_contig_ind
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = v_scenario_sid
		 MINUS 
		SELECT ind_sid
		  FROM ind_list;
END;

PROCEDURE BeginCalcJob(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	in_stored_only					IN	NUMBER DEFAULT 0
)
AS
BEGIN
	-- Clean up any random entries in the temporary indicator list
	DELETE FROM ind_list;
	
	-- Catch any stored calcs that we queued for recalculation (in a lazy fashion)
	INSERT INTO ind_list (ind_sid)
		SELECT ind_sid 
		  FROM calc_job_ind
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND calc_job_id = in_calc_job_id;
		
	-- Add any indicators required for scenario rules
	AddScenarioInds(in_calc_job_id);

	-- Include all inds involved in aggregation groups queued for recalculation
	AddAggregateInds(in_calc_job_id);

	-- Restrict recomputation to just the things we need for stored calcs
	-- (unless we are saving the result of normal calcs as well)
	SelectCalcs(in_stored_only);

	-- Add calcs / stored calcs that depend on the indicators in the list
	AddDependantInds;
		  
	-- Use only regions not in the trash
	DELETE FROM region_list;
	INSERT INTO region_list (region_sid)
		SELECT region_sid
		  FROM region r
		  	   START WITH region_sid IN (SELECT region_tree_root_sid 
		  	   							   FROM region_tree)
		  	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR region_sid = parent_sid;
	
	-- Stick in DelegPlansRegion to results (it lives outside region tree)
	INSERT INTO region_list (region_sid)
		SELECT securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), '/DelegationPlans/DelegPlansRegion') 
		  FROM dual;
END;

PROCEDURE BeginFileJob(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	out_files_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	BeginCalcJob(in_calc_job_id, 0);
	
	OPEN out_files_cur FOR
		SELECT srvf.version, srvf.file_path, srvf.sha1
		  FROM calc_job cj, scenario_run sr, scenario_run_version srv, scenario_run_version_file srvf
		 WHERE cj.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cj.calc_job_id = in_calc_job_id
		   AND cj.app_sid = sr.app_sid AND cj.scenario_run_sid = sr.scenario_run_sid
		   AND sr.app_sid = srv.app_sid AND sr.scenario_run_sid = srv.scenario_run_sid
		   AND sr.version = srv.version
		   AND srv.app_sid = srvf.app_sid AND srv.scenario_run_sid = srvf.scenario_run_sid
		   AND srv.version = srvf.version;
END;

PROCEDURE AddScenarioRunVersion(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	out_scenario_run_sid			OUT	scenario_run.scenario_run_sid%TYPE,
	out_version						OUT	scenario_run.version%TYPE
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	SELECT scenario_run_sid
	  INTO out_scenario_run_sid
	  FROM calc_job
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND calc_job_id = in_calc_job_id;
	IF SQL%ROWCOUNT = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Missing calc job with id '||in_calc_job_id);
	END IF;
	
	-- lock the scenario run (to prevent generation of conflicting version numbers)
	SELECT scenario_run_sid
	  INTO out_scenario_run_sid
	  FROM scenario_run
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND scenario_run_sid = out_scenario_run_sid
	  	   FOR UPDATE;
	IF SQL%ROWCOUNT = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Missing scenario run with sid '||out_scenario_run_sid);
	END IF;
	  	   
	-- get a version number
	SELECT NVL(MAX(version), 0) + 1
	  INTO out_version
	  FROM scenario_run_version
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND scenario_run_sid = out_scenario_run_sid;
	   
	-- register the version
	INSERT INTO scenario_run_version (scenario_run_sid, version)
	VALUES (out_scenario_run_sid, out_version);
	
	-- commit to release locks (note the autonomous transaction prevents
	-- long term blocking)
	COMMIT;
END;

PROCEDURE AddScenarioRunFile(
	in_scenario_run_sid				IN	scenario_run_version_file.scenario_run_sid%TYPE,
	in_version						IN	scenario_run_version_file.version%TYPE,
	in_file_path					IN	scenario_run_version_file.file_path%TYPE
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
	v_sha1							scenario_run_version_file.sha1%TYPE := '0000000000000000000000000000000000000000';
BEGIN
	-- Add the file.  Since there's no transaction for the file creation, commit in an autonomous
	-- transction to record it -- if there's a failure then the file will get cleaned up next
	-- time the scenario is run
	INSERT INTO scenario_run_version_file (scenario_run_sid, version, file_path, sha1)
	VALUES (in_scenario_run_sid, in_version, in_file_path, v_sha1);
	COMMIT;
END;

PROCEDURE SetScenarioRunFileSHA1(
	in_scenario_run_sid				IN	scenario_run_version_file.scenario_run_sid%TYPE,
	in_version						IN	scenario_run_version_file.version%TYPE,
	in_sha1							IN	scenario_run_version_file.sha1%TYPE
)
AS
BEGIN
	UPDATE scenario_run_version_file
	   SET sha1 = in_sha1
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND scenario_run_sid = in_scenario_run_sid
	   AND version = in_version;
END;

PROCEDURE SetScenarioRunVersion(
	in_scenario_run_sid				IN	scenario_run_version_file.scenario_run_sid%TYPE,
	in_version						IN	scenario_run_version_file.version%TYPE
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	-- Bump the active scenario run version
	UPDATE scenario_run
	   SET version = GREATEST(NVL(version, 0), in_version)
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND scenario_run_sid = in_scenario_run_sid;
	IF SQL%ROWCOUNT != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Missing scenario_run row for the scenario with sid '||in_scenario_run_sid);
	END IF;
	
	-- Delete old scenario run version details.
	-- (these used to be kept for cleanup, but now the calcJobRunner process 
	--  has a clean up thread that spins around looking for files in the 
	--  'repository' directory that are old and cleans them up periodically)
	DELETE FROM scenario_run_version_file
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND scenario_run_sid = in_scenario_run_sid AND version < in_version;

	DELETE FROM scenario_run_version
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND scenario_run_sid = in_scenario_run_sid AND version < in_version;	 
	COMMIT;
END;

PROCEDURE GetCurrentScenarios(
	out_scn_cur						OUT	SYS_REFCURSOR,
	out_snap_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_scn_cur FOR
		SELECT c.app_sid, LOWER(c.host) host, sr.scenario_run_sid, sr.version
		  FROM scenario_run sr, csr.customer c
		 WHERE c.app_sid = sr.app_sid;

	OPEN out_snap_cur FOR
		SELECT c.app_sid, LOWER(c.host) host, srs.scenario_run_snapshot_sid, srs.version
		  FROM scenario_run_snapshot srs, csr.customer c
		 WHERE c.app_sid = srs.app_sid;
END;


PROCEDURE RerunFileJob(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE
)
AS
BEGIN
	-- something has gone wrong with the scenario file: instead of updating, we
	-- need to run all the calcs / aggregations again
	INSERT INTO calc_job_aggregate_ind_group (calc_job_id, aggregate_ind_group_id)
		SELECT in_calc_job_id, aggregate_ind_group_id
		  FROM aggregate_ind_group
		 MINUS
		SELECT in_calc_job_id, aggregate_ind_group_id
		  FROM calc_job_aggregate_ind_group;
	
	INSERT INTO ind_list (ind_sid)
		SELECT ind_sid
		  FROM ind
		 MINUS
		SELECT ind_sid
		  FROM ind_list;
END;

PROCEDURE GetRecalcDates(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	out_min_date					OUT	DATE,
	out_max_date					OUT	DATE,
	out_min_adj						OUT	NUMBER,
	out_max_adj						OUT NUMBER
)
AS
	v_calc_start_dtm				customer.calc_start_dtm%TYPE;
	v_calc_end_dtm					customer.calc_end_dtm%TYPE;
BEGIN
	BeginCalcJob(in_calc_job_id, 1);
				
	SELECT calc_start_dtm, calc_end_dtm
	  INTO v_calc_start_dtm, v_calc_end_dtm
	  FROM customer;

	-- now we have all of the indicators, including calcs then we can figure out the dates we actually need to
	-- recalculate for.  val_change_log records the changed values, so we need to expand the calculation area
	-- to take account of any calcs that look backwards (i.e. we are adding to the maximum date here).
	SELECT GREATEST(v_calc_start_dtm, NVL(MIN(start_dtm), v_calc_start_dtm)), 
		   LEAST(v_calc_end_dtm, NVL(MAX(end_dtm), v_calc_end_dtm))
	  INTO out_min_date, out_max_date
	  FROM calc_job
     WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
       AND calc_job_id = in_calc_job_id
	   AND processing = 1;
	  
	-- Take account of any fixed date calcs
	SELECT LEAST(out_min_date, NVL(MIN(calc_fixed_start_dtm), v_calc_end_dtm)),
		   GREATEST(out_max_date, NVL(MAX(calc_fixed_end_dtm), v_calc_start_dtm))
	  INTO out_min_date, out_max_date
	  FROM ind i, ind_list il
	 WHERE i.ind_sid = il.ind_sid;

	-- Find the maximum that calcs look backwards/forwards taking account of calcs of calcs
	-- this is used to adjust the start date/end dates used when reading data
	GetDateAdj(out_min_adj, out_max_adj);
	out_max_date := LEAST(v_calc_end_dtm, ADD_MONTHS(out_max_date, -NVL(out_min_adj, 0)));
	out_min_date := GREATEST(v_calc_start_dtm, ADD_MONTHS(out_min_date, -NVL(out_max_adj, 0)));
END;

PROCEDURE GetTags(
	out_tag_cur						OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_tag_cur FOR
		SELECT tag_id, tag
		  FROM v$tag
		 WHERE tag_id IN (
		 		SELECT tag_id
		 		  FROM region_tag);
END;

PROCEDURE GetLookupTables(
	out_lookup_table_cur			OUT SYS_REFCURSOR,
	out_lookup_table_entry_cur		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_lookup_table_cur FOR
		SELECT lookup_id, lookup_name
		  FROM lookup_table
		 ORDER BY lookup_id;
		 
	OPEN out_lookup_table_entry_cur FOR
		SELECT lookup_id, start_dtm, val
		  FROM lookup_table_entry
		 ORDER BY lookup_id, start_dtm;
END;

PROCEDURE GetStoredCalcRegionTrees(
	out_tree_cur					OUT	SYS_REFCURSOR,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_region_tag_cur				OUT	SYS_REFCURSOR,
	out_region_fund_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- All tree roots
	OPEN out_tree_cur FOR
		SELECT /*+ALL_ROWS*/ region_tree_root_sid, is_primary
		  FROM region_tree;

	-- The regions, unordered (including unresolved links)
	OPEN out_region_cur FOR
		SELECT r.*, rd.description, p.property_type_id, p.property_sub_type_id, s.space_type_id, am.meter_type_id meter_ind_id, p.mgmt_company_id
		  FROM (SELECT /*+ALL_ROWS*/ r.app_sid, r.parent_sid, r.active, r.region_sid, r.link_to_region_sid, r.pos, r.geo_latitude, 
					   r.geo_longitude, r.geo_country, r.geo_region, r.geo_city_id, r.map_entity, r.egrid_ref, r.geo_type, 
					   r.disposal_dtm, r.acquisition_dtm, r.lookup_key, r.region_type, r.region_ref
				  FROM region r
				  	   START WITH region_sid IN (SELECT region_tree_root_sid -- this also filters out "Enquiry Issues" region
												   FROM region_tree 
												  UNION 
												 SELECT securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), '/DelegationPlans/DelegPlansRegion') 
												   FROM dual)
				  	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR region_sid = parent_sid) r
		  JOIN region_description rd
		    ON r.app_sid = rd.app_sid 
		   AND r.region_sid = rd.region_sid 
		   AND rd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
		  LEFT JOIN property p
		    ON r.app_sid = p.app_sid AND r.region_sid = p.region_sid
		  LEFT JOIN space s
		    ON r.app_sid = s.app_sid AND r.region_sid = s.region_sid
		  LEFT JOIN all_meter am
		    ON r.app_sid = am.app_sid AND r.region_sid = am.region_sid;

	-- The region tags
	OPEN out_region_tag_cur FOR
		SELECT region_sid, tag_id
		  FROM region_tag;
		  
	-- The region funds
	OPEN out_region_fund_cur FOR
		SELECT region_sid, fund_id
		  FROM property_fund;
END;

PROCEDURE GetPropertyMetadata(
	out_property_type_cur			OUT	SYS_REFCURSOR,
	out_property_sub_type_cur		OUT	SYS_REFCURSOR,
	out_space_cur					OUT	SYS_REFCURSOR,
	out_meter_ind_cur				OUT	SYS_REFCURSOR,
	out_mgmt_company_cur			OUT	SYS_REFCURSOR,
	out_fund_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_property_type_cur FOR
		SELECT property_type_id, label
		  FROM property_type;
		  
	OPEN out_property_sub_type_cur FOR
		SELECT property_type_id, property_sub_type_id, label
		  FROM property_sub_type;

	OPEN out_space_cur FOR
		SELECT space_type_id, label
		  FROM space_type;
		  
	OPEN out_meter_ind_cur FOR
		SELECT meter_type_id meter_ind_id, label
		  FROM meter_type;
		  
	OPEN out_mgmt_company_cur FOR
		SELECT mgmt_company_id, name
		  FROM mgmt_company;
		  
	OPEN out_fund_cur FOR
		SELECT fund_id, name
		  FROM fund;
END;

PROCEDURE GetStoredCalcValues(
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
    out_val_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
/*
	declare
		v_x number;
	begin 
		select count(*) into v_x from ind_list;
		if v_x = 0 then 
			raise_application_error(-20001,'empty fetch');
		end if;
	end;
*/

	-- stuff from val we need incl for calculations
	OPEN out_val_cur FOR
		SELECT /*+ALL_ROWS CARDINALITY(il, 10000) CARDINALITY(r, 10000)*/
			   v.period_start_dtm, v.period_end_dtm, v.source_type_id, v.ind_sid, v.region_sid, v.val_number, v.error_code
		  FROM ind_list il, val v, region_list r
		 WHERE v.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r.region_sid = v.region_sid 
		   AND il.ind_sid = v.ind_sid
		   AND v.period_end_dtm > in_start_dtm
		   AND v.period_start_dtm < in_end_dtm
      ORDER BY v.ind_sid, v.region_sid, v.period_start_dtm, CASE WHEN v.val_number IS NULL THEN 1 ELSE 0 END, v.period_end_dtm DESC, v.changed_dtm DESC;
END;

PROCEDURE GetNormalValues(
	in_start_dtm                    IN  DATE,
    in_end_dtm                      IN  DATE,
	in_scenario_run_sid				IN	SCENARIO_RUN.scenario_run_sid%type,
    out_val_cur                     OUT SYS_REFCURSOR,
    out_note_cur					OUT SYS_REFCURSOR,
    out_file_cur					OUT	SYS_REFCURSOR,
    out_var_expl_id_cur				OUT	SYS_REFCURSOR,
    out_var_expl_cur				OUT	SYS_REFCURSOR    
)
AS
BEGIN
	-- for file based scenarios, we only want user entered data
	DELETE FROM ind_list_2;
	INSERT INTO ind_list_2 (ind_sid)
		SELECT i.ind_sid
		  FROM ind i, ind_list il
		 WHERE i.ind_sid = il.ind_sid
		   AND i.ind_type NOT IN (csr_data_pkg.IND_TYPE_CALC, csr_data_pkg.IND_TYPE_STORED_CALC, csr_data_pkg.IND_TYPE_AGGREGATE);
		   
	OPEN out_val_cur FOR
		SELECT /*+ALL_ROWS CARDINALITY(il, 10000) CARDINALITY(r, 10000)*/
			   v.val_id, v.period_start_dtm, v.period_end_dtm, v.ind_sid, v.region_sid,
			   v.source_type_id, v.source_id, v.val_number, v.error_code, 
			   1 is_merged, v.changed_by_sid, v.changed_dtm, v.val_id val_key,
			   utils_pkg.TruncateClob(note) note
		  FROM ind_list_2 il, val v, region_list r
		 WHERE v.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r.region_sid = v.region_sid 
		   AND il.ind_sid = v.ind_sid
		   AND v.period_end_dtm > in_start_dtm
		   AND v.period_start_dtm < in_end_dtm
		   AND v.source_type_id NOT IN (csr_data_pkg.SOURCE_TYPE_AGGREGATOR, csr_data_pkg.SOURCE_TYPE_STORED_CALC, csr.csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP)
      ORDER BY v.ind_sid, v.region_sid, v.period_start_dtm, CASE WHEN v.val_number IS NULL THEN 1 ELSE 0 END, v.period_end_dtm DESC, v.changed_dtm DESC;

	OPEN out_note_cur FOR
		SELECT /*+ALL_ROWS CARDINALITY(il, 10000) CARDINALITY(r, 10000)*/
			   v.val_id val_key, v.note
		  FROM ind_list_2 il, val v, region_list r
		 WHERE v.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r.region_sid = v.region_sid 
		   AND il.ind_sid = v.ind_sid
		   AND v.period_end_dtm > in_start_dtm
		   AND v.period_start_dtm < in_end_dtm
		   AND v.source_type_id NOT IN (csr_data_pkg.SOURCE_TYPE_AGGREGATOR, csr_data_pkg.SOURCE_TYPE_STORED_CALC, csr.csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP)
		   AND v.note IS NOT NULL
		   AND utils_pkg.ClobNeedsTruncation(note) = 1
		 ORDER BY val_key;

	OPEN out_file_cur FOR
		SELECT /*+ALL_ROWS*/ v.val_id val_key, fu.file_upload_sid, fu.filename, fu.mime_type
		  FROM ind_list_2 il, val v, region_list r, val_file vf, file_upload fu
		 WHERE v.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r.region_sid = v.region_sid 
		   AND il.ind_sid = v.ind_sid
		   AND v.period_end_dtm > in_start_dtm
		   AND v.period_start_dtm < in_end_dtm
		   AND v.source_type_id NOT IN (csr_data_pkg.SOURCE_TYPE_AGGREGATOR, csr_data_pkg.SOURCE_TYPE_STORED_CALC, csr.csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP)
		   AND v.app_sid = vf.app_sid AND v.val_id = vf.val_id
		   AND vf.app_sid = fu.app_sid AND vf.file_upload_sid = fu.file_upload_sid
		 ORDER BY val_key;

	OPEN out_var_expl_id_cur FOR
		SELECT /*+ALL_ROWS CARDINALITY(r, 10000) CARDINALITY(il, 1)*/ 
			   v.val_id val_key, svve.var_expl_id
		  FROM val v, sheet_value_var_expl svve, ind_list_2 il, region_list rl
     	 WHERE v.app_sid = SYS_CONTEXT('SECURITY','APP')
	       AND v.ind_sid = il.ind_sid
		   AND v.region_sid = rl.region_sid
	       AND v.period_end_dtm > in_start_dtm
	       AND v.period_start_dtm < in_end_dtm
	       AND v.source_type_id = csr_data_pkg.SOURCE_TYPE_DELEGATION
	       AND svve.app_sid = v.app_sid
	       AND svve.sheet_value_id = v.source_id
      	 ORDER BY val_key, var_expl_id;

	OPEN out_var_expl_cur FOR
		SELECT /*+ALL_ROWS CARDINALITY(r, 10000) CARDINALITY(il, 1)*/ 
			   v.val_id val_key, sv.var_expl_note
		  FROM val v, ind_list_2 il, region_list rl, sheet_value sv
     	 WHERE v.app_sid = SYS_CONTEXT('SECURITY','APP')
	       AND v.ind_sid = il.ind_sid
		   AND v.region_sid = rl.region_sid
	       AND v.period_end_dtm > in_start_dtm
	       AND v.period_start_dtm < in_end_dtm
	       AND v.source_type_id = csr_data_pkg.SOURCE_TYPE_DELEGATION
	       AND sv.app_sid = v.app_sid
	       AND sv.sheet_value_id = v.source_id
	       AND sv.var_expl_note IS NOT NULL
		 ORDER BY val_key;	       	
END;	

PROCEDURE GetUnmergedNormalValues(
	in_start_dtm                    IN  DATE,
    in_end_dtm                      IN  DATE,
	in_scenario_run_sid				IN	SCENARIO_RUN.scenario_run_sid%type,
    out_val_cur                     OUT SYS_REFCURSOR,
    out_note_cur					OUT SYS_REFCURSOR,    
    out_file_cur					OUT	SYS_REFCURSOR,
    out_var_expl_id_cur				OUT	SYS_REFCURSOR,
    out_var_expl_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- for file based scenarios, we only want user entered data
	DELETE FROM ind_list_2;
	INSERT INTO ind_list_2 (ind_sid)
		SELECT i.ind_sid
		  FROM ind i, ind_list il
		 WHERE i.ind_sid = il.ind_sid
		   AND i.ind_type NOT IN (csr_data_pkg.IND_TYPE_CALC, csr_data_pkg.IND_TYPE_STORED_CALC, csr_data_pkg.IND_TYPE_AGGREGATE);

	-- more breaking out
	DELETE FROM temp_sheets_to_use;
	DELETE FROM temp_sheets_ind_region_to_use;
	INSERT INTO temp_sheets_to_use (app_sid, delegation_sid, lvl, sheet_id, start_dtm, end_dtm, last_action_colour)
		SELECT d.app_sid, d.delegation_sid, d.lvl, sla.sheet_id, sla.start_dtm, sla.end_dtm, sla.last_action_colour
		  FROM (SELECT app_sid, delegation_sid, level lvl
				  FROM delegation 
					   START WITH app_sid = SYS_CONTEXT('SECURITY','APP') AND parent_sid = SYS_CONTEXT('SECURITY','APP') AND delegation_sid NOT IN (SELECT delegation_sid FROM master_deleg)
					   CONNECT BY app_sid = SYS_CONTEXT('SECURITY','APP') AND PRIOR delegation_sid = parent_sid) d,
			   sheet_with_last_action sla
		 WHERE sla.app_sid = d.app_sid AND sla.delegation_sid = d.delegation_sid
		   AND sla.is_visible = 1
		   AND sla.end_dtm > in_start_dtm
		   AND sla.start_dtm < in_end_dtm;
	
	INSERT INTO temp_sheets_ind_region_to_use (app_sid, delegation_sid, lvl, sheet_id, ind_sid, region_sid, start_dtm, end_dtm, last_action_colour)
		SELECT /*+ALL_ROWS CARDINALITY(ts, 10000) CARDINALITY(il, 10000) CARDINALITY(rl, 10000)*/
			   ts.app_sid, ts.delegation_sid, ts.lvl, ts.sheet_id, di.ind_sid, dr.region_sid, ts.start_dtm, ts.end_dtm, ts.last_action_colour
		  FROM temp_sheets_to_use ts
		  JOIN delegation_ind di ON ts.app_sid = di.app_sid AND ts.delegation_sid = di.delegation_sid
		  JOIN ind_list_2 il ON di.ind_sid = il.ind_sid
		  JOIN delegation_region dr ON ts.app_sid = dr.app_sid AND ts.delegation_sid = dr.delegation_sid
		  JOIN region_list rl ON dr.region_sid = rl.region_sid;

	OPEN out_val_cur FOR
		SELECT /*+ALL_ROWS*/ *
		  FROM (SELECT /*+ALL_ROWS CARDINALITY(rp, 10000) CARDINALITY(il, 1)*/
		  			   null val_id, start_dtm period_start_dtm, end_dtm period_end_dtm, 0 source_type_id, null source_id,
		  			   ind_sid, region_sid, val_number, null error_code, note,
		  			   0 is_merged, set_by_user_sid changed_by_sid, set_dtm changed_dtm, -sheet_value_id val_key
				  FROM (SELECT sv.sheet_value_id, ts.start_dtm, ts.end_dtm, ts.ind_sid, ts.region_sid, sv.val_number,
				  			   sv.set_by_user_sid, sv.set_dtm,
				  			   utils_pkg.TruncateClob(sv.note) note,
				          	   ROW_NUMBER() OVER (
								PARTITION BY ts.ind_sid, ts.region_sid, ts.start_dtm, ts.end_dtm
								ORDER BY DECODE(ts.last_action_colour,'G',1,'O',2,'R',3), ts.lvl DESC, ts.sheet_id DESC, sv.sheet_value_id) SEQ
						  FROM temp_sheets_ind_region_to_use ts
						  LEFT JOIN sheet_value sv ON ts.app_sid = sv.app_sid AND ts.sheet_id = sv.sheet_id 
						   AND ts.app_sid = sv.app_sid AND ts.ind_sid = sv.ind_sid 
						   AND ts.app_sid = sv.app_sid AND ts.region_sid = sv.region_sid)
				 WHERE SEQ = 1
				 UNION ALL
				SELECT /*+ALL_ROWS CARDINALITY(r, 10000) CARDINALITY(il, 1)*/ 
					   v.val_id, v.period_start_dtm, v.period_end_dtm, v.source_type_id, v.source_id,
					   v.ind_sid, v.region_sid, v.val_number, v.error_code,
					   utils_pkg.TruncateClob(v.note) note,
					   1 is_merged, v.changed_by_sid, v.changed_dtm, v.val_id val_key
				  FROM val v, ind_list_2 il, region_list rl
		     	 WHERE v.app_sid = SYS_CONTEXT('SECURITY','APP')
			       AND v.ind_sid = il.ind_sid
				   AND v.region_sid = rl.region_sid
			       AND v.period_end_dtm > in_start_dtm
			       AND v.period_start_dtm < in_end_dtm
			       AND v.source_type_id NOT IN (csr_data_pkg.SOURCE_TYPE_AGGREGATOR, csr_data_pkg.SOURCE_TYPE_STORED_CALC, csr.csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP)
			       -- check value isn't on one of the sheets we've selected
			       AND NOT EXISTS (SELECT 1
			       					 FROM temp_sheets_ind_region_to_use ts
			       					WHERE v.app_sid = ts.app_sid
						  			  AND v.period_end_dtm > ts.start_dtm
						  			  AND v.period_start_dtm < ts.end_dtm
						  			  AND v.app_sid = ts.app_sid AND v.ind_sid = ts.ind_sid
						  			  AND v.app_sid = ts.app_sid AND v.region_sid = ts.region_sid))
      	 ORDER BY ind_sid, region_sid, period_start_dtm, CASE WHEN val_number IS NULL THEN 1 ELSE 0 END, period_end_dtm DESC, changed_dtm DESC;

	OPEN out_note_cur FOR
		SELECT /*+ALL_ROWS*/ *
		  FROM (SELECT -sheet_value_id val_key, note
				  FROM (SELECT /*+CARDINALITY(ts, 100000)*/ sv.sheet_value_id, sv.note,
				          	   ROW_NUMBER() OVER (
								PARTITION BY ts.ind_sid, ts.region_sid, ts.start_dtm, ts.end_dtm
								ORDER BY DECODE(ts.last_action_colour,'G',1,'O',2,'R',3), ts.lvl DESC, ts.sheet_id DESC, sv.sheet_value_id) SEQ
						  FROM temp_sheets_ind_region_to_use ts
						  LEFT JOIN sheet_value sv ON ts.app_sid = sv.app_sid AND ts.sheet_id = sv.sheet_id 
						   AND ts.app_sid = sv.app_sid AND ts.ind_sid = sv.ind_sid 
						   AND ts.app_sid = sv.app_sid AND ts.region_sid = sv.region_sid)
				 WHERE SEQ = 1
				   AND note IS NOT NULL
				   AND utils_pkg.ClobNeedsTruncation(note) = 1
				 UNION ALL
				SELECT /*+ALL_ROWS CARDINALITY(r, 10000) CARDINALITY(il, 1)*/ 
					   v.val_id val_key, v.note
				  FROM val v, ind_list_2 il, region_list rl
		     	 WHERE v.app_sid = SYS_CONTEXT('SECURITY','APP')
			       AND v.ind_sid = il.ind_sid
				   AND v.region_sid = rl.region_sid
			       AND v.period_end_dtm > in_start_dtm
			       AND v.period_start_dtm < in_end_dtm
			       AND v.source_type_id NOT IN (csr_data_pkg.SOURCE_TYPE_AGGREGATOR, csr_data_pkg.SOURCE_TYPE_STORED_CALC, csr.csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP)
			       AND v.note IS NOT NULL
			       AND utils_pkg.ClobNeedsTruncation(v.note) = 1
			       -- check value isn't on one of the sheets we've selected
			       AND NOT EXISTS (SELECT /*+CARDINALITY(ts, 100000)*/ 1
			       					 FROM temp_sheets_ind_region_to_use ts
			       					WHERE v.app_sid = ts.app_sid
						  			  AND v.period_end_dtm > ts.start_dtm
						  			  AND v.period_start_dtm < ts.end_dtm
						  			  AND v.app_sid = ts.app_sid AND v.ind_sid = ts.ind_sid
						  			  AND v.app_sid = ts.app_sid AND v.region_sid = ts.region_sid))
		 ORDER BY val_key;						  			  

	OPEN out_file_cur FOR
		SELECT /*+ALL_ROWS*/ *
		  FROM (SELECT /*+CARDINALITY(ts, 100000)*/
		  			   -sv.sheet_value_id val_key, fu.file_upload_sid, fu.filename, fu.mime_type
				  FROM (SELECT sv.sheet_value_id,
				          	   ROW_NUMBER() OVER (
								PARTITION BY ts.ind_sid, ts.region_sid, ts.start_dtm, ts.end_dtm
								ORDER BY DECODE(ts.last_action_colour,'G',1,'O',2,'R',3), ts.lvl DESC, ts.sheet_id DESC, sv.sheet_value_id) SEQ
						  FROM temp_sheets_ind_region_to_use ts
						  LEFT JOIN sheet_value sv ON ts.app_sid = sv.app_sid AND ts.sheet_id = sv.sheet_id 
						   AND ts.app_sid = sv.app_sid AND ts.ind_sid = sv.ind_sid 
						   AND ts.app_sid = sv.app_sid AND ts.region_sid = sv.region_sid) sv,
					   sheet_value_file svf, file_upload fu
				 WHERE sv.seq = 1
				   AND sv.sheet_value_id = svf.sheet_value_id
				   AND svf.app_sid = fu.app_sid AND svf.file_upload_sid = fu.file_upload_sid
				 UNION ALL
				SELECT /*+ALL_ROWS CARDINALITY(r, 10000) CARDINALITY(il, 1)*/
					   v.val_id val_key, fu.file_upload_sid, fu.filename, fu.mime_type
				  FROM val v, ind_list_2 il, region_list rl, val_file vf, file_upload fu
		     	 WHERE v.app_sid = SYS_CONTEXT('SECURITY','APP')
			       AND v.ind_sid = il.ind_sid
				   AND v.region_sid = rl.region_sid
			       AND v.period_end_dtm > in_start_dtm
			       AND v.period_start_dtm < in_end_dtm
			       AND v.source_type_id NOT IN (csr_data_pkg.SOURCE_TYPE_AGGREGATOR, csr_data_pkg.SOURCE_TYPE_STORED_CALC, csr.csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP)
				   AND v.app_sid = vf.app_sid AND v.val_id = vf.val_id
				   AND vf.app_sid = fu.app_sid AND vf.file_upload_sid = fu.file_upload_sid
			       -- check value isn't on one of the sheets we've selected
			       AND NOT EXISTS (SELECT /*+CARDINALITY(ts, 100000)*/ 1
			       					 FROM temp_sheets_ind_region_to_use ts
			       					WHERE v.app_sid = ts.app_sid
						  			  AND v.period_end_dtm > ts.start_dtm
						  			  AND v.period_start_dtm < ts.end_dtm
						  			  AND v.app_sid = ts.app_sid AND v.ind_sid = ts.ind_sid
						  			  AND v.app_sid = ts.app_sid AND v.region_sid = ts.region_sid))
		 ORDER BY val_key;

	OPEN out_var_expl_id_cur FOR
		SELECT /*+ALL_ROWS*/ *
		  FROM (SELECT -sv.sheet_value_id val_key, svve.var_expl_id
				  FROM (SELECT /*+CARDINALITY(ts, 100000)*/ sv.sheet_value_id,
				          	   ROW_NUMBER() OVER (
								PARTITION BY ts.ind_sid, ts.region_sid, ts.start_dtm, ts.end_dtm
								ORDER BY DECODE(ts.last_action_colour,'G',1,'O',2,'R',3), ts.lvl DESC, ts.sheet_id DESC, sv.sheet_value_id) SEQ
						  FROM temp_sheets_ind_region_to_use ts
						  LEFT JOIN sheet_value sv ON ts.app_sid = sv.app_sid AND ts.sheet_id = sv.sheet_id 
						   AND ts.app_sid = sv.app_sid AND ts.ind_sid = sv.ind_sid 
						   AND ts.app_sid = sv.app_sid AND ts.region_sid = sv.region_sid) sv,
					   sheet_value_var_expl svve
				 WHERE sv.seq = 1
				   AND sv.sheet_value_id = svve.sheet_value_id
				 UNION ALL
				SELECT /*+ALL_ROWS CARDINALITY(r, 10000) CARDINALITY(il, 1)*/ 
					   v.val_id val_key, svve.var_expl_id
				  FROM val v, sheet_value_var_expl svve, ind_list_2 il, region_list rl
		     	 WHERE v.app_sid = SYS_CONTEXT('SECURITY','APP')
			       AND v.ind_sid = il.ind_sid
				   AND v.region_sid = rl.region_sid
			       AND v.period_end_dtm > in_start_dtm
			       AND v.period_start_dtm < in_end_dtm
			       AND v.source_type_id = csr_data_pkg.SOURCE_TYPE_DELEGATION
			       AND svve.app_sid = v.app_sid
			       AND svve.sheet_value_id = v.source_id
			       -- check value isn't on one of the sheets we've selected
			       AND NOT EXISTS (SELECT /*+CARDINALITY(ts, 100000)*/ 1
			       					 FROM temp_sheets_ind_region_to_use ts
			       					WHERE v.app_sid = ts.app_sid
						  			  AND v.period_end_dtm > ts.start_dtm
						  			  AND v.period_start_dtm < ts.end_dtm
						  			  AND v.app_sid = ts.app_sid AND v.ind_sid = ts.ind_sid
						  			  AND v.app_sid = ts.app_sid AND v.region_sid = ts.region_sid))
      	 ORDER BY val_key, var_expl_id;

	OPEN out_var_expl_cur FOR
		SELECT /*+ALL_ROWS*/ *
		  FROM (SELECT -sheet_value_id val_key, var_expl_note
				  FROM (SELECT /*+CARDINALITY(ts, 100000)*/ sv.sheet_value_id, sv.var_expl_note,
				          	   ROW_NUMBER() OVER (
								PARTITION BY ts.ind_sid, ts.region_sid, ts.start_dtm, ts.end_dtm
								ORDER BY DECODE(ts.last_action_colour,'G',1,'O',2,'R',3), ts.lvl DESC, ts.sheet_id DESC, sv.sheet_value_id) SEQ
						  FROM temp_sheets_ind_region_to_use ts
						  LEFT JOIN sheet_value sv ON ts.app_sid = sv.app_sid AND ts.sheet_id = sv.sheet_id 
						   AND ts.app_sid = sv.app_sid AND ts.ind_sid = sv.ind_sid 
						   AND ts.app_sid = sv.app_sid AND ts.region_sid = sv.region_sid)
				 WHERE SEQ = 1
				   AND var_expl_note IS NOT NULL
				 UNION ALL
				SELECT /*+ALL_ROWS CARDINALITY(r, 10000) CARDINALITY(il, 1)*/ 
					   v.val_id val_key, sv.var_expl_note
				  FROM val v, ind_list_2 il, region_list rl, sheet_value sv
		     	 WHERE v.app_sid = SYS_CONTEXT('SECURITY','APP')
			       AND v.ind_sid = il.ind_sid
				   AND v.region_sid = rl.region_sid
			       AND v.period_end_dtm > in_start_dtm
			       AND v.period_start_dtm < in_end_dtm
			       AND v.source_type_id = csr_data_pkg.SOURCE_TYPE_DELEGATION
			       AND sv.app_sid = v.app_sid
			       AND sv.sheet_value_id = v.source_id
			       AND sv.var_expl_note IS NOT NULL
			       -- check value isn't on one of the sheets we've selected
			       AND NOT EXISTS (SELECT /*+CARDINALITY(ts, 100000)*/ 1
			       					 FROM temp_sheets_ind_region_to_use ts
			       					WHERE v.app_sid = ts.app_sid
						  			  AND v.period_end_dtm > ts.start_dtm
						  			  AND v.period_start_dtm < ts.end_dtm
						  			  AND v.app_sid = ts.app_sid AND v.ind_sid = ts.ind_sid
						  			  AND v.app_sid = ts.app_sid AND v.region_sid = ts.region_sid))
		 ORDER BY val_key;
END;

PROCEDURE INTERNAL_GetUnmergedValues(
	in_unmerged_start_dtm			IN	DATE,
	in_unmerged_end_dtm				IN	DATE,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	out_val_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- more breaking out
	DELETE FROM temp_sheets_to_use;
	DELETE FROM temp_sheets_ind_region_to_use;

	INSERT INTO temp_sheets_to_use (app_sid, delegation_sid, lvl, sheet_id, start_dtm, end_dtm, last_action_colour)
		SELECT d.app_sid, d.delegation_sid, d.lvl, sla.sheet_id, sla.start_dtm, sla.end_dtm, sla.last_action_colour
		  FROM (SELECT app_sid, delegation_sid, level lvl
				  FROM delegation 
					   START WITH app_sid = SYS_CONTEXT('SECURITY','APP') AND parent_sid = SYS_CONTEXT('SECURITY','APP')
					   CONNECT BY app_sid = SYS_CONTEXT('SECURITY','APP') AND PRIOR delegation_sid = parent_sid) d,
			   sheet_with_last_action sla
		 WHERE sla.app_sid = d.app_sid AND sla.delegation_sid = d.delegation_sid
		   AND sla.is_visible = 1
		   AND sla.end_dtm > in_unmerged_start_dtm AND sla.end_dtm > in_start_dtm
		   AND sla.start_dtm < in_unmerged_end_dtm AND sla.start_dtm < in_end_dtm;
	
	INSERT INTO temp_sheets_ind_region_to_use (app_sid, delegation_sid, lvl, sheet_id, ind_sid, region_sid, start_dtm, end_dtm, last_action_colour)
		SELECT /*+ALL_ROWS CARDINALITY(ts, 10000) CARDINALITY(il, 10000) CARDINALITY(rl, 10000)*/
			   ts.app_sid, ts.delegation_sid, ts.lvl, ts.sheet_id, di.ind_sid, dr.region_sid, ts.start_dtm, ts.end_dtm, ts.last_action_colour
		  FROM temp_sheets_to_use ts
		  JOIN delegation_ind di ON ts.app_sid = di.app_sid AND ts.delegation_sid = di.delegation_sid
		  JOIN ind_list il ON di.ind_sid = il.ind_sid
		  JOIN delegation_region dr ON ts.app_sid = dr.app_sid AND ts.delegation_sid = dr.delegation_sid
		  JOIN region_list rl ON dr.region_sid = rl.region_sid;

	/* Values from selected unmerged sheets UNION ALL (merged values that don't overlap the selected unmerged sheets) */
	OPEN out_val_cur FOR
		SELECT /*+ALL_ROWS*/ *
		  FROM (SELECT /*+ALL_ROWS CARDINALITY(rp, 10000) CARDINALITY(il, 1)*/ start_dtm period_start_dtm, end_dtm period_end_dtm, 0 source_type_id, ind_sid, region_sid,
					   val_number, null error_code, set_dtm changed_dtm
				  FROM (SELECT ts.start_dtm, ts.end_dtm, ts.ind_sid, ts.region_sid, sv.val_number, sv.set_dtm,
				          	   ROW_NUMBER() OVER (
								PARTITION BY ts.ind_sid, ts.region_sid, ts.start_dtm, ts.end_dtm
								ORDER BY DECODE(ts.last_action_colour,'G',1,'O',2,'R',3), ts.lvl DESC, ts.sheet_id DESC, sv.sheet_value_id) SEQ
						  FROM temp_sheets_ind_region_to_use ts
						  LEFT JOIN sheet_value sv ON ts.app_sid = sv.app_sid AND ts.sheet_id = sv.sheet_id 
						   AND ts.app_sid = sv.app_sid AND ts.ind_sid = sv.ind_sid 
						   AND ts.app_sid = sv.app_sid AND ts.region_sid = sv.region_sid)
				 WHERE SEQ = 1
				 UNION ALL
				SELECT /*+ALL_ROWS CARDINALITY(r, 10000) CARDINALITY(il, 1)*/ 
					   v.period_start_dtm, v.period_end_dtm, v.source_type_id, v.ind_sid, v.region_sid, 
					   v.val_number, v.error_code, v.changed_dtm
				  FROM val v, region_list r, ind_list il, ind i
		     	 WHERE v.app_sid = SYS_CONTEXT('SECURITY','APP')
			       AND i.app_sid = SYS_CONTEXT('SECURITY','APP')
			       AND v.app_sid = i.app_sid
			       AND v.ind_sid = il.ind_sid
			       AND v.period_end_dtm > in_start_dtm
			       AND v.period_start_dtm < in_end_dtm
			       -- hack: include propagate down values
			       AND v.ind_sid = i.ind_sid
			       AND (v.source_type_id != csr_data_pkg.SOURCE_TYPE_AGGREGATOR OR i.aggregate in ('DOWN', 'FORCE DOWN'))
			       -- hack ends
			       AND v.region_sid = r.region_sid
			       -- check value isn't on one of the sheets we've selected
			       AND NOT EXISTS (SELECT 1
			       					 FROM temp_sheets_ind_region_to_use ts
			       					WHERE v.app_sid = ts.app_sid
						  			  AND v.period_end_dtm > ts.start_dtm
						  			  AND v.period_start_dtm < ts.end_dtm
						  			  AND v.app_sid = ts.app_sid AND v.ind_sid = ts.ind_sid
						  			  AND v.app_sid = ts.app_sid AND v.region_sid = ts.region_sid))
      	 ORDER BY ind_sid, region_sid, period_start_dtm, CASE WHEN val_number IS NULL THEN 1 ELSE 0 END, period_end_dtm DESC, changed_dtm DESC;
END;

PROCEDURE GetUnmergedValues(
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	out_val_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	INTERNAL_GetUnmergedValues(in_start_dtm, in_end_dtm, in_start_dtm, in_end_dtm, out_val_cur);
END;

PROCEDURE GetUnmergedLastPeriodValues(
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	out_val_cur						OUT	SYS_REFCURSOR
)
AS
	v_unmerged_start_dtm			DATE;
	v_sysdate						DATE := getSysDate;
BEGIN
	-- start of the previous month (e.g. on 3-Feb-2013, get 1-Jan-2013)
	SELECT TRUNC((TRUNC(v_sysdate, 'mm') - 1), 'mm')
	  INTO v_unmerged_start_dtm
	  FROM DUAL;

	INTERNAL_GetUnmergedValues(v_unmerged_start_dtm, in_end_dtm, in_start_dtm, in_end_dtm, out_val_cur);
END;

PROCEDURE GetUnmergedLPNormalValues(
	in_start_dtm					IN  DATE,
    in_end_dtm						IN  DATE,
	in_scenario_run_sid				IN	scenario_run.scenario_run_sid%type,
    out_val_cur						OUT SYS_REFCURSOR,
    out_note_cur					OUT SYS_REFCURSOR,
    out_file_cur					OUT	SYS_REFCURSOR
)
AS
	v_unmerged_start_dtm			DATE;
	v_sysdate						DATE := getSysDate;
BEGIN
	-- start of the previous month (e.g. on 3-Feb-2013, get 1-Jan-2013)
	SELECT TRUNC((TRUNC(v_sysdate, 'mm') - 1), 'mm')
	  INTO v_unmerged_start_dtm
	  FROM DUAL;

	-- for file based scenarios, we only want user entered data
	DELETE FROM ind_list_2;
	INSERT INTO ind_list_2 (ind_sid)
		SELECT i.ind_sid
		  FROM ind i, ind_list il
		 WHERE i.ind_sid = il.ind_sid
		   AND i.ind_type NOT IN (csr_data_pkg.IND_TYPE_CALC, csr_data_pkg.IND_TYPE_STORED_CALC, csr_data_pkg.IND_TYPE_AGGREGATE);

	-- more breaking out
	DELETE FROM temp_sheets_to_use;
	DELETE FROM temp_sheets_ind_region_to_use;

	INSERT INTO temp_sheets_to_use (app_sid, delegation_sid, lvl, sheet_id, start_dtm, end_dtm, last_action_colour)
		SELECT d.app_sid, d.delegation_sid, d.lvl, sla.sheet_id, sla.start_dtm, sla.end_dtm, sla.last_action_colour
		  FROM (SELECT app_sid, delegation_sid, level lvl
				  FROM delegation 
					   START WITH app_sid = SYS_CONTEXT('SECURITY','APP') AND parent_sid = SYS_CONTEXT('SECURITY','APP')
					   CONNECT BY app_sid = SYS_CONTEXT('SECURITY','APP') AND PRIOR delegation_sid = parent_sid) d,
			   sheet_with_last_action sla
		 WHERE sla.app_sid = d.app_sid AND sla.delegation_sid = d.delegation_sid
		   AND sla.is_visible = 1
		   AND sla.end_dtm > v_unmerged_start_dtm AND sla.end_dtm > in_start_dtm
		   AND sla.start_dtm < in_end_dtm AND sla.start_dtm < in_end_dtm;
	
	INSERT INTO temp_sheets_ind_region_to_use (app_sid, delegation_sid, lvl, sheet_id, ind_sid, region_sid, start_dtm, end_dtm, last_action_colour)
		SELECT /*+ALL_ROWS CARDINALITY(ts, 10000) CARDINALITY(il, 10000) CARDINALITY(rl, 10000)*/
			   ts.app_sid, ts.delegation_sid, ts.lvl, ts.sheet_id, di.ind_sid, dr.region_sid, ts.start_dtm, ts.end_dtm, ts.last_action_colour
		  FROM temp_sheets_to_use ts
		  JOIN delegation_ind di ON ts.app_sid = di.app_sid AND ts.delegation_sid = di.delegation_sid
		  JOIN ind_list il ON di.ind_sid = il.ind_sid
		  JOIN delegation_region dr ON ts.app_sid = dr.app_sid AND ts.delegation_sid = dr.delegation_sid
		  JOIN region_list rl ON dr.region_sid = rl.region_sid;

	/* Values from selected unmerged sheets UNION ALL (merged values that don't overlap the selected unmerged sheets) */
	OPEN out_val_cur FOR
		SELECT /*+ALL_ROWS*/ *
		  FROM (SELECT /*+ALL_ROWS CARDINALITY(rp, 10000) CARDINALITY(il, 1)*/
		  			   null val_id, start_dtm period_start_dtm, end_dtm period_end_dtm, 0 source_type_id, null source_id,
		  			   ind_sid, region_sid, val_number, null error_code,
		  			   note, 0 is_merged, set_by_user_sid changed_by_sid, set_dtm changed_dtm,
		  			   -sheet_value_id val_key
				  FROM (SELECT sv.sheet_value_id, ts.start_dtm, ts.end_dtm, ts.ind_sid, ts.region_sid, sv.val_number,
				  			   sv.set_by_user_sid, sv.set_dtm,
				  			   utils_pkg.TruncateClob(sv.note) note,
				          	   ROW_NUMBER() OVER (
								PARTITION BY ts.ind_sid, ts.region_sid, ts.start_dtm, ts.end_dtm 
								ORDER BY DECODE(ts.last_action_colour,'G',1,'O',2,'R',3), ts.lvl DESC, ts.sheet_id DESC, sv.sheet_value_id) SEQ
						  FROM temp_sheets_ind_region_to_use ts
						  LEFT JOIN sheet_value sv ON ts.app_sid = sv.app_sid AND ts.sheet_id = sv.sheet_id 
						   AND ts.app_sid = sv.app_sid AND ts.ind_sid = sv.ind_sid 
						   AND ts.app_sid = sv.app_sid AND ts.region_sid = sv.region_sid)
				 WHERE SEQ = 1
				 UNION ALL
				SELECT /*+ALL_ROWS CARDINALITY(r, 10000) CARDINALITY(il, 1)*/ 
					   v.val_id, v.period_start_dtm, v.period_end_dtm, v.source_type_id, v.source_id,
					   v.ind_sid, v.region_sid, v.val_number, v.error_code,
					   utils_pkg.TruncateClob(v.note) note,
					   1 is_merged, v.changed_by_sid, v.changed_dtm, v.val_id val_key
				  FROM val v, ind_list_2 il, region_list rl
		     	 WHERE v.app_sid = SYS_CONTEXT('SECURITY','APP')
			       AND v.ind_sid = il.ind_sid
				   AND v.region_sid = rl.region_sid
			       AND v.period_end_dtm > in_start_dtm
			       AND v.period_start_dtm < in_end_dtm
			       -- check value isn't on one of the sheets we've selected
			       AND NOT EXISTS (SELECT 1
			       					 FROM temp_sheets_ind_region_to_use ts
			       					WHERE v.app_sid = ts.app_sid
						  			  AND v.period_end_dtm > ts.start_dtm
						  			  AND v.period_start_dtm < ts.end_dtm
						  			  AND v.app_sid = ts.app_sid AND v.ind_sid = ts.ind_sid
						  			  AND v.app_sid = ts.app_sid AND v.region_sid = ts.region_sid))
      	 ORDER BY ind_sid, region_sid, period_start_dtm, CASE WHEN val_number IS NULL THEN 1 ELSE 0 END, period_end_dtm DESC, changed_dtm DESC;

	OPEN out_note_cur FOR
		SELECT /*+ALL_ROWS*/ *
		  FROM (SELECT -sheet_value_id val_key, note
				  FROM (SELECT /*+CARDINALITY(ts, 100000)*/ sv.sheet_value_id, sv.note,
				          	   ROW_NUMBER() OVER (
								PARTITION BY ts.ind_sid, ts.region_sid, ts.start_dtm, ts.end_dtm 
								ORDER BY DECODE(ts.last_action_colour,'G',1,'O',2,'R',3), ts.lvl DESC, ts.sheet_id DESC, sv.sheet_value_id) SEQ
						  FROM temp_sheets_ind_region_to_use ts
						  LEFT JOIN sheet_value sv ON ts.app_sid = sv.app_sid AND ts.sheet_id = sv.sheet_id 
						   AND ts.app_sid = sv.app_sid AND ts.ind_sid = sv.ind_sid 
						   AND ts.app_sid = sv.app_sid AND ts.region_sid = sv.region_sid)
				 WHERE SEQ = 1
				   AND note IS NOT NULL
				   AND utils_pkg.ClobNeedsTruncation(note) = 1
				 UNION ALL
				SELECT /*+ALL_ROWS CARDINALITY(r, 10000) CARDINALITY(il, 1)*/ 
					   v.val_id val_key, v.note
				  FROM val v, ind_list_2 il, region_list rl
		     	 WHERE v.app_sid = SYS_CONTEXT('SECURITY','APP')
			       AND v.ind_sid = il.ind_sid
				   AND v.region_sid = rl.region_sid
			       AND v.period_end_dtm > in_start_dtm
			       AND v.period_start_dtm < in_end_dtm
				   AND v.note IS NOT NULL
				   AND utils_pkg.ClobNeedsTruncation(v.note) = 1
			       -- check value isn't on one of the sheets we've selected
			       AND NOT EXISTS (SELECT /*+CARDINALITY(ts, 100000)*/ 1
			       					 FROM temp_sheets_ind_region_to_use ts
			       					WHERE v.app_sid = ts.app_sid
						  			  AND v.period_end_dtm > ts.start_dtm
						  			  AND v.period_start_dtm < ts.end_dtm
						  			  AND v.app_sid = ts.app_sid AND v.ind_sid = ts.ind_sid
						  			  AND v.app_sid = ts.app_sid AND v.region_sid = ts.region_sid))
		 ORDER BY val_key;

	OPEN out_file_cur FOR
		SELECT /*+ALL_ROWS*/ *
		  FROM (SELECT /*+CARDINALITY(ts, 100000)*/
		  			   -sv.sheet_value_id val_key, fu.file_upload_sid, fu.filename, fu.mime_type
				  FROM (SELECT sv.sheet_value_id, ts.start_dtm, ts.end_dtm, ts.ind_sid, ts.region_sid, sv.val_number, sv.set_dtm,
				          	   ROW_NUMBER() OVER (
								PARTITION BY ts.ind_sid, ts.region_sid, ts.start_dtm, ts.end_dtm
								ORDER BY DECODE(ts.last_action_colour,'G',1,'O',2,'R',3), ts.lvl DESC, ts.sheet_id DESC, sv.sheet_value_id) SEQ
						  FROM temp_sheets_ind_region_to_use ts
						  LEFT JOIN sheet_value sv ON ts.app_sid = sv.app_sid AND ts.sheet_id = sv.sheet_id 
						   AND ts.app_sid = sv.app_sid AND ts.ind_sid = sv.ind_sid 
						   AND ts.app_sid = sv.app_sid AND ts.region_sid = sv.region_sid) sv,
					   sheet_value_file svf, file_upload fu
				 WHERE sv.seq = 1
				   AND sv.sheet_value_id = svf.sheet_value_id
				   AND svf.app_sid = fu.app_sid AND svf.file_upload_sid = fu.file_upload_sid
				 UNION ALL
				SELECT /*+ALL_ROWS CARDINALITY(r, 10000) CARDINALITY(il, 1)*/ 
					   v.val_id val_key, fu.file_upload_sid, fu.filename, fu.mime_type
				  FROM val v, ind_list_2 il, region_list rl, val_file vf, file_upload fu
		     	 WHERE v.app_sid = SYS_CONTEXT('SECURITY','APP')
			       AND v.ind_sid = il.ind_sid
				   AND v.region_sid = rl.region_sid
			       AND v.period_end_dtm > in_start_dtm
			       AND v.period_start_dtm < in_end_dtm
				   AND v.app_sid = vf.app_sid AND v.val_id = vf.val_id
				   AND vf.app_sid = fu.app_sid AND vf.file_upload_sid = fu.file_upload_sid
			       -- check value isn't on one of the sheets we've selected
			       AND NOT EXISTS (SELECT /*+CARDINALITY(ts, 100000)*/ 1
			       					 FROM temp_sheets_ind_region_to_use ts
			       					WHERE v.app_sid = ts.app_sid
						  			  AND v.period_end_dtm > ts.start_dtm
						  			  AND v.period_start_dtm < ts.end_dtm
						  			  AND v.app_sid = ts.app_sid AND v.ind_sid = ts.ind_sid
						  			  AND v.app_sid = ts.app_sid AND v.region_sid = ts.region_sid))
		 ORDER BY val_key;
END;

PROCEDURE GetAllIndDetails(
	in_all_inds						IN	NUMBER,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_ind_tag_cur					OUT	SYS_REFCURSOR,
	out_recompute_ind_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF in_all_inds = 0 THEN
		OPEN out_ind_cur FOR
			SELECT i.ind_sid, i.description,
		   		   NVL(i.scale, m.scale) scale,
		   		   NVL(i.format_mask, m.format_mask) format_mask, 
		   		   NVL(i.divisibility, m.divisibility) divisibility, 
	   		   	   i.aggregate, i.period_set_id, i.period_interval_id, i.do_temporal_aggregation,
		   		   i.calc_description, i.calc_xml, i.ind_type, i.calc_start_dtm_adjustment,
				   i.calc_end_dtm_adjustment, m.description measure_description, i.measure_sid,
				   -- old scrag expects info_xml (but doesn't care about it)
				   NULL info_xml, i.start_month, i.gri, 
				   i.parent_sid, i.pos, i.target_direction, i.active,
				   i.tolerance_type, i.pct_lower_tolerance, i.pct_upper_tolerance,
				   i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
				   i.factor_type_id, i.gas_measure_sid, i.gas_type_id, i.map_to_ind_sid, i.normalize,
				   i.ind_activity_type_id, i.core, i.roll_forward, i.prop_down_region_tree_sid, i.is_system_managed, 
				   i.calc_fixed_start_dtm, i.calc_fixed_end_dtm, i.lookup_key, i.calc_output_round_dp,
				   NVL(m.factor, smc.a) factor, NVL(m.m, sm.m) m, NVL(m.kg, sm.kg) kg, NVL(m.s, sm.s) s,
				   NVL(m.a, sm.a) a, NVL(m.k, sm.k) k, NVL(m.mol, sm.mol)  mol, NVL(m.cd, sm.cd) cd,
				   NVL(m.pct_ownership_applies, 0) pct_ownership_applies, m.custom_field,
				   smc.std_measure_conversion_id
			  FROM v$ind i, ind_list il, measure m, std_measure_conversion smc, std_measure sm
			 WHERE i.ind_sid = il.ind_sid
			   AND i.app_sid = m.app_sid(+) AND i.measure_sid = m.measure_sid(+)
			   AND m.std_measure_conversion_id = smc.std_measure_conversion_id(+)
			   AND smc.std_measure_id = sm.std_measure_id(+);
			   
		OPEN out_ind_tag_cur FOR
			SELECT itg.ind_sid, itg.tag_id
			  FROM ind_list il, ind_tag itg
			 WHERE itg.ind_sid = il.ind_sid;
	ELSE
		OPEN out_ind_cur FOR
			SELECT i.ind_sid, i.description,
		   		   NVL(i.scale, m.scale) scale,
		   		   NVL(i.format_mask, m.format_mask) format_mask, 
		   		   NVL(i.divisibility, m.divisibility) divisibility, 
		   		   i.aggregate, i.period_set_id, i.period_interval_id, i.do_temporal_aggregation,
		   		   i.calc_description, i.calc_xml, i.ind_type, i.calc_start_dtm_adjustment,
				   i.calc_end_dtm_adjustment, m.description measure_description, i.measure_sid,
				   -- old scrag expects info_xml (but doesn't care about it)
				   NULL info_xml, i.start_month, i.gri, 
				   i.parent_sid, i.pos, i.target_direction, i.active,
				   i.tolerance_type, i.pct_lower_tolerance, i.pct_upper_tolerance,
				   i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
				   i.factor_type_id, i.gas_measure_sid, i.gas_type_id, i.map_to_ind_sid, i.normalize,
				   i.ind_activity_type_id, i.core, i.roll_forward, i.prop_down_region_tree_sid, i.is_system_managed, 
				   i.calc_fixed_start_dtm, i.calc_fixed_end_dtm, i.lookup_key, i.calc_output_round_dp,
				   NVL(m.factor, smc.a) factor, NVL(m.m, sm.m) m, NVL(m.kg, sm.kg) kg, NVL(m.s, sm.s) s,
				   NVL(m.a, sm.a) a, NVL(m.k, sm.k) k, NVL(m.mol, sm.mol)  mol, NVL(m.cd, sm.cd) cd,
				   NVL(m.pct_ownership_applies, 0) pct_ownership_applies, m.custom_field,
				   smc.std_measure_conversion_id
			  FROM v$ind i, measure m, std_measure_conversion smc, std_measure sm
			 WHERE i.app_sid = m.app_sid(+) AND i.measure_sid = m.measure_sid(+)
			   AND m.std_measure_conversion_id = smc.std_measure_conversion_id(+)
			   AND smc.std_measure_id = sm.std_measure_id(+);

		OPEN out_ind_tag_cur FOR
			SELECT ind_sid, tag_id
			  FROM ind_tag;
	END IF;
	
	OPEN out_recompute_ind_cur FOR
		SELECT ind_sid
		  FROM ind_list;
END;

PROCEDURE GetIndDependencies(
	in_all_inds						IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF in_all_inds = 0 THEN
		OPEN out_cur FOR
			SELECT cd.calc_ind_sid, cd.ind_sid
			  FROM v$calc_dependency cd, ind_list il
			 WHERE cd.calc_ind_sid = il.ind_sid;
	ELSE
		OPEN out_cur FOR
			SELECT cd.calc_ind_sid, cd.ind_sid
			  FROM v$calc_dependency cd;
	END IF;
END;

PROCEDURE GetAggregateChildren(
	in_all_inds						IN	NUMBER,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	IF in_all_inds = 0 THEN
		OPEN out_cur FOR
			-- now make a list of parent and child nodes that we'll need for aggregate functions
			SELECT DISTINCT i.parent_sid, i.ind_sid 
	          FROM calc_dependency cd, ind i, ind_list il
	         WHERE cd.dep_type = csr_data_pkg.DEP_ON_CHILDREN
	       	   AND cd.ind_sid = i.parent_sid
	           AND cd.calc_ind_sid = il.ind_sid
	           AND i.map_to_ind_sid IS NULL
	           AND i.measure_sid IS NOT NULL
	         ORDER BY parent_sid;
	ELSE
		OPEN out_cur FOR
			-- now make a list of parent and child nodes that we'll need for aggregate functions
			SELECT DISTINCT i.parent_sid, i.ind_sid 
	          FROM calc_dependency cd, ind i
	         WHERE cd.dep_type = csr_data_pkg.DEP_ON_CHILDREN
	       	   AND cd.ind_sid = i.parent_sid
	           AND i.map_to_ind_sid IS NULL
	           AND i.measure_sid IS NOT NULL
	         ORDER BY parent_sid;
	END IF;
END;	

PROCEDURE GetAllGasFactors(
	in_all_inds						IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	factor_pkg.UpdateSubRegionFactors;
	
	IF in_all_inds = 0 THEN
		OPEN out_cur FOR		
			SELECT f.factor_type_id, f.gas_type_id,
				   f.region_sid, f.geo_country, f.geo_region, f.egrid_ref,
				   f.start_dtm, f.end_dtm, f.std_measure_conversion_id, 
				   POWER((f.value - smc.c) / smc.a, 1 / smc.b) value,
				   0 is_virtual
			  FROM factor_type ft, factor f, std_measure_conversion smc
			 WHERE ft.factor_type_id IN (SELECT i.factor_type_id
										   FROM ind i, ind_list il
										  WHERE i.ind_sid = il.ind_sid)
			   AND ft.factor_type_id = f.factor_type_id
			   AND f.is_selected = 1
			   AND f.std_measure_conversion_id = smc.std_measure_conversion_id
			 ORDER BY f.start_dtm, f.gas_type_id;
	ELSE
		OPEN out_cur FOR		
			SELECT f.factor_type_id, f.gas_type_id,
				   f.region_sid, f.geo_country, f.geo_region, f.egrid_ref,
				   f.start_dtm, f.end_dtm, f.std_measure_conversion_id, 
				   POWER((f.value - smc.c) / smc.a, 1 / smc.b) value,
				   0 is_virtual
			  FROM factor_type ft, factor f, std_measure_conversion smc
			 WHERE ft.factor_type_id IN (SELECT i.factor_type_id
										   FROM ind i)
			   AND ft.factor_type_id = f.factor_type_id
			   AND f.is_selected = 1
			   AND f.std_measure_conversion_id = smc.std_measure_conversion_id
			 ORDER BY f.start_dtm, f.gas_type_id;
	END IF;
END;

PROCEDURE GetRegionPctOwnership(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT pct.region_sid, pct.start_dtm, pct.end_dtm, pct.pct
		  FROM pct_ownership pct
		 ORDER BY pct.region_sid, pct.start_dtm;
END;

PROCEDURE GetAggregateIndHelperProcs(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT aig.aggregate_ind_group_id, aig.helper_proc, aig.helper_proc_args
		  FROM aggregate_ind_group aig, calc_job_aggregate_ind_group cjaig
		 WHERE cjaig.calc_job_id = in_calc_job_id
		   AND aig.app_sid = cjaig.app_sid AND aig.aggregate_ind_group_id = cjaig.aggregate_ind_group_id;
END;

PROCEDURE GetAggregateInds(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT aigm.aggregate_ind_group_id, aigm.ind_sid
		  FROM calc_job_aggregate_ind_group cjaig, aggregate_ind_group_member aigm
		 WHERE cjaig.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND cjaig.calc_job_id = in_calc_job_id
		   AND cjaig.aggregate_ind_group_id = aigm.aggregate_ind_group_id;
END;

-- UNUSED?
-- PROCEDURE GetScenarioValues(
	-- in_start_dtm					IN	DATE,
	-- in_end_dtm						IN	DATE,
    -- out_val_cur						OUT	SYS_REFCURSOR
-- )
-- AS
	-- v_ind_list						csr_data_pkg.T_NUMBER_ARRAY;
	-- v_reg_list						csr_data_pkg.T_NUMBER_ARRAY;
-- BEGIN
	-- SELECT il.ind_sid
	  -- BULK COLLECT INTO v_ind_list
	  -- FROM ind_list il;
	   
	-- SELECT rl.region_sid
	  -- BULK COLLECT INTO v_reg_list
	  -- FROM region_list rl;
	  
	-- -- stuff from val we need incl for calculations
	-- OPEN out_val_cur FOR
		-- SELECT /*+ALL_ROWS*/ v.period_start_dtm, v.period_end_dtm, v.source_type_id, v.ind_sid, v.region_sid, v.val_number, v.error_code
		  -- FROM val v
		  -- JOIN TABLE(v_ind_list) il ON v.ind_sid = il.column_value
		  -- JOIN TABLE(v_reg_list) r ON v.region_sid = r.column_value
		 -- WHERE v.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   -- AND v.period_end_dtm > in_start_dtm
		   -- AND v.period_start_dtm < in_end_dtm
      -- ORDER BY v.ind_sid, v.region_sid, v.period_start_dtm, CASE WHEN v.val_number IS NULL THEN 1 ELSE 0 END, v.period_end_dtm DESC, v.changed_dtm DESC;		   
-- END;

PROCEDURE GetOldScenarioValues(
	in_scenario_run_sid				IN	scenario_run.scenario_run_sid%TYPE,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
    out_val_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- stuff from val we need incl for calculations
	OPEN out_val_cur FOR
		SELECT /*+ALL_ROWS*/ v.period_start_dtm, v.period_end_dtm, v.source_type_id, v.ind_sid, v.region_sid, v.val_number, v.error_code
		  FROM ind_list il, scenario_run_val v, region_list r
		 WHERE v.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND v.scenario_run_sid = in_scenario_run_sid
		   AND il.ind_sid = v.ind_sid
		   AND r.region_Sid = v.region_Sid
		   AND v.period_end_dtm > in_start_dtm
		   AND v.period_start_dtm < in_end_dtm
      ORDER BY v.ind_sid, v.region_sid, v.period_start_dtm, CASE WHEN v.val_number IS NULL THEN 1 ELSE 0 END, v.period_end_dtm DESC;
END;

PROCEDURE MergeScenarioValues(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	in_scenario_run_sid				IN	scenario_run.scenario_run_sid%TYPE
)
AS
	v_total_work	NUMBER;
	v_work_done		NUMBER;
	v_last_update	DATE;
BEGIN
	/*for r in (select * from temp_new_val) loop
		security_pkg.debugmsg('ind='||r.ind_sid||', region='||r.region_sid||', period_start_dtm='||r.period_start_dtm||', period_end_dtm='||r.period_end_dtm||
			', source_type_id='||r.source_type_id||', val_number='||r.val_number||', error_code='||r.error_code);
	end loop;*/
		
	-- Clean up any old aggregate/stored calc values that we are setting to null -- since we've done
	-- aggregation we can now remove these
	DELETE FROM scenario_run_val
	 WHERE rowid IN (
        SELECT /*+CARDINALITY(tv, 1000000)*/ v.rowid
          FROM temp_new_val tv, scenario_run_val v
         WHERE v.scenario_run_sid = in_scenario_run_sid
           AND v.ind_sid = tv.ind_sid 
           AND v.region_sid = tv.region_sid 
           AND tv.period_start_dtm < v.period_end_dtm
           AND tv.period_end_dtm > v.period_start_dtm
           AND tv.val_number IS NULL 
           AND tv.error_code IS NULL);

	-- progress
	SELECT /*+CARDINALITY(tv, 1000000)*/ NVL(COUNT(*), 0)
	  INTO v_total_work
	  FROM temp_new_val;	  
	recordProgress(in_calc_job_id, PHASE_MERGE_DATA, 0, v_total_work);
	v_last_update := SYSDATE;

	-- Actually set the other values.  Since we are authoritative for the cube (i.e. the user can't have changed the state
	-- of any of the data that it contains) then we can just write the values without checking
	v_work_done := 0;
	FOR r IN (SELECT /*+CARDINALITY(tv, 1000000)*/ tv.ind_sid, tv.region_sid, tv.period_start_dtm,
					 tv.period_end_dtm, tv.source_type_id, tv.val_number, tv.error_code
				FROM temp_new_val tv
			   WHERE (tv.val_number IS NOT NULL OR tv.error_code IS NOT NULL)) LOOP			   	
		scenario_run_pkg.SetValue(
			in_scenario_run_sid	=> in_scenario_run_sid,
			in_ind_sid 			=> r.ind_sid,
			in_region_sid 		=> r.region_sid,
			in_period_start		=> r.period_start_dtm,
			in_period_end 		=> r.period_end_dtm,
			in_val_number 		=> r.val_number,
			in_error_code	 	=> r.error_code,
			in_source_type_id 	=> r.source_type_id
		);		

		v_work_done := v_work_done + 1;
		IF SYSDATE - v_last_update > 10/86400 THEN
			recordProgress(in_calc_job_id, v_work_done);
			v_last_update := SYSDATE;
		END IF;
	END LOOP;
END;

-- clean up values in temp_val_id
PROCEDURE CleanValues
AS
BEGIN
	UPDATE imp_val
	   SET set_val_id = NULL 
	 WHERE (app_sid, set_val_id) IN (SELECT app_sid, val_id
	 								   FROM temp_val_id);

	DELETE FROM val_file
	 WHERE (app_sid, val_id) IN (SELECT app_sid, val_id
	 							   FROM temp_val_id);
	
	DELETE FROM val 
	 WHERE (app_sid, val_id) IN (SELECT app_sid, val_id
	 							   FROM temp_val_id);
END;

PROCEDURE MergeValues(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	in_max_val_changed_dtm			IN	val.changed_dtm%TYPE
)
AS
	v_set_val_id	NUMBER;
	v_total_work	NUMBER;
	v_work_done		NUMBER;
	v_last_update	DATE;
	v_empty_uploads security_pkg.T_SID_IDS;
BEGIN
	/*IF SYS_CONTEXT('SECURITY', 'APP') = 10931422 THEN
		INSERT INTO rbs_new_val
			SELECT tv.*,0,in_calc_job_id FROM temp_new_val tv;
		RETURN;
	END IF;*/

	-- Clean up any old aggregate/stored calc values that we are setting to null -- since we've done
	-- aggregation we can now remove these
	INSERT INTO temp_val_id (app_sid, val_id)
        SELECT /*+CARDINALITY(tv, 1000000)*/ v.app_sid, v.val_id
          FROM temp_new_val tv, val v
         WHERE v.ind_sid = tv.ind_sid 
           AND v.region_sid = tv.region_sid 
           AND tv.period_start_dtm < v.period_end_dtm
           AND tv.period_end_dtm > v.period_start_dtm
           AND tv.val_number IS NULL 
           AND tv.error_code IS NULL
           AND v.source_type_id IN (csr_data_pkg.SOURCE_TYPE_AGGREGATOR, csr_data_pkg.SOURCE_TYPE_STORED_CALC, csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP);
	
	-- Also kill any existing null values (which would have been inserted to force aggregation)
	-- We only kill up to the snapped maximum val_id as we have only calculated up to that point
	INSERT INTO temp_val_id (app_sid, val_id)
		SELECT v.app_sid, v.val_id
		  FROM val v
		 WHERE v.val_number IS NULL
		   AND (v.note IS NULL OR LENGTH(v.note) = 0) -- only delete if there's no file or note attached
		   AND v.error_code IS NULL
		   AND v.changed_dtm <= in_max_val_changed_dtm
	MINUS
		SELECT app_sid, val_id 
		  FROM val_file;
	CleanValues;

	-- compute total work
	SELECT /*+CARDINALITY(tv, 1000000)*/ NVL(COUNT(*), 0)
	  INTO v_total_work
	  FROM temp_new_val tv, ind i
     WHERE (tv.val_number IS NOT NULL OR tv.error_code IS NOT NULL)
   	   AND tv.ind_sid = i.ind_sid
   	   AND (i.aggregate IN ('FORCE SUM', 'FORCE DOWN') OR
   	 	    NOT EXISTS (SELECT 1
   	 	  				  FROM val v
   	 	  			     WHERE v.ind_sid = tv.ind_sid
   	 	  			       AND v.region_sid = tv.region_sid
   	 	  			       AND v.period_end_dtm > tv.period_start_dtm
   	 	  			       AND v.period_start_dtm < tv.period_end_dtm
   	 	  			       AND (v.val_number IS NOT NULL OR v.error_code IS NOT NULL)
   	 	  			       AND v.source_type_id NOT IN (csr_data_pkg.SOURCE_TYPE_AGGREGATOR, csr_data_pkg.SOURCE_TYPE_STORED_CALC, csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP)));
	recordProgress(in_calc_job_id, PHASE_MERGE_DATA, 0, v_total_work);
	v_last_update := SYSDATE;
	
	-- Actually set the other values - stored calcs always / force aggregates always; aggregates only go
	-- over the top of other aggregates: this is to avoid overwriting any user data that was merged
	-- before the stored calc engine was run
	v_work_done := 0;
	FOR r IN (SELECT /*+CARDINALITY(tv, 1000000)*/ tv.ind_sid, tv.region_sid, tv.period_start_dtm,
					 tv.period_end_dtm, tv.source_type_id, tv.val_number, tv.error_code
				FROM temp_new_val tv, ind i
			   WHERE (tv.val_number IS NOT NULL OR tv.error_code IS NOT NULL)
			   	 AND tv.ind_sid = i.ind_sid
				 AND i.measure_sid IS NOT NULL -- temp patch for FB37537 -- skip folders so we don't get an error
			   	 AND (i.aggregate IN ('FORCE SUM', 'FORCE DOWN') OR
			   	 	  NOT EXISTS (SELECT 1
			   	 	  				FROM val v
			   	 	  			   WHERE v.ind_sid = tv.ind_sid
			   	 	  			     AND v.region_sid = tv.region_sid
			   	 	  			     AND v.period_end_dtm > tv.period_start_dtm
			   	 	  			     AND v.period_start_dtm < tv.period_end_dtm
			   	 	  			     AND (v.val_number IS NOT NULL OR v.error_code IS NOT NULL)
			   	 	  			     AND v.source_type_id NOT IN (csr_data_pkg.SOURCE_TYPE_AGGREGATOR, csr_data_pkg.SOURCE_TYPE_STORED_CALC, csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP)))
		      ) LOOP
		Indicator_Pkg.SetValueWithReasonWithSid(
			in_user_sid			=> SYS_CONTEXT('SECURITY', 'SID'),
			in_ind_sid 			=> r.ind_sid,
			in_region_sid 		=> r.region_sid,
			in_period_start		=> r.period_start_dtm,
			in_period_end 		=> r.period_end_dtm,
			in_val_number 		=> r.val_number,
			in_error_code	 	=> r.error_code,
			in_source_type_id 	=> r.source_type_id,
			in_update_flags		=> indicator_pkg.IND_SKIP_UPDATE_ALERTS + 
								   indicator_pkg.IND_DISALLOW_RECALC + indicator_pkg.IND_DISALLOW_AGGREGATION,		
			in_reason 			=> 'Stored calculation',
			in_have_file_uploads => 1,
			in_file_uploads		=> v_empty_uploads, 
			out_val_id 			=> v_set_val_id
		);
		v_work_done := v_work_done + 1;
		IF SYSDATE - v_last_update > 10/86400 THEN
			recordProgress(in_calc_job_id, v_work_done);
			v_last_update := SYSDATE;
		END IF;
	END LOOP;
	
	-- Create actions jobs
	-- XXX: this is very suspect (actions ought to be calculated by scrag)
	DELETE FROM ind_list_2;
	INSERT INTO ind_list_2 (ind_sid)
		SELECT /*+CARDINALITY(tv, 1000000)*/ DISTINCT ind_sid
		  FROM temp_new_val;
		  
	UPDATE /*+ALL_ROWS*/ actions.task_recalc_job
	   SET processing = 0
	 WHERE (app_sid, task_sid) IN (SELECT app_sid, task_sid
	 								 FROM actions.task_ind_dependency tid, ind_list_2 il
	 								WHERE tid.ind_sid = il.ind_sid);

	INSERT /*+ALL_ROWS*/ INTO actions.task_recalc_job (app_sid, task_sid, processing)
		SELECT DISTINCT app_sid, task_sid, 0
		  FROM (SELECT tid.app_sid, tid.task_sid
				  FROM actions.task_ind_dependency tid, ind_list_2 il
				 WHERE tid.ind_sid = il.ind_sid
				 UNION 
				SELECT tid.app_sid, tid.task_sid
				  FROM actions.task_ind_dependency tid, ind_list_2 il, calc_dependency cd
				 WHERE tid.app_sid = cd.app_sid AND tid.ind_sid = cd.calc_ind_sid
				   AND cd.ind_sid = il.ind_sid)
		 MINUS
		SELECT app_sid, task_sid, 0
		  FROM actions.task_recalc_job
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
		
	INSERT /*+ALL_ROWS*/ INTO actions.task_recalc_region (task_sid, region_sid)
		SELECT DISTINCT task_sid, region_sid
		  FROM (SELECT /*+CARDINALITY(tv, 1000000)*/ tid.task_sid, tv.region_sid
				  FROM actions.task_ind_dependency tid, actions.task_region tr, temp_new_val tv
				 WHERE tid.ind_sid = tv.ind_sid
				   AND tr.app_sid = tid.app_sid AND tid.task_sid = tr.task_sid
				   AND tr.region_sid = tv.region_sid
				 UNION 
				SELECT /*+CARDINALITY(tv, 1000000)*/ tid.task_sid, tv.region_sid
				  FROM actions.task_ind_dependency tid, temp_new_val tv, actions.task_region tr, calc_dependency cd
				 WHERE tid.app_sid = cd.app_sid AND tid.ind_sid = cd.calc_ind_sid
				   AND tr.app_sid = tid.app_sid AND tid.task_sid = tr.task_sid
				   AND tr.region_sid = tv.region_sid
				   AND cd.ind_sid = tv.ind_sid)
		 MINUS
		SELECT task_sid, region_sid
		  FROM actions.task_recalc_region;

	INSERT /*+ALL_ROWS*/ INTO actions.task_recalc_period (task_sid, start_dtm, end_dtm)
		SELECT DISTINCT task_sid, start_dtm, end_dtm
		  FROM (SELECT /*+CARDINALITY(tv, 1000000)*/ tid.task_sid,
		  			   tv.period_start_dtm start_dtm, ADD_MONTHS(tv.period_start_dtm, period_duration) end_dtm
				  FROM actions.task t, actions.task_ind_dependency tid, temp_new_val tv
				 WHERE tid.app_sid = t.app_sid AND tid.task_sid = t.task_sid
				   AND tid.ind_sid = tv.ind_sid
				 UNION 
				SELECT /*+CARDINALITY(tv, 1000000)*/ tid.task_sid,
					   tv.period_start_dtm start_dtm, ADD_MONTHS(tv.period_start_dtm, period_duration) end_dtm
				  FROM actions.task t, actions.task_ind_dependency tid, temp_new_val tv, calc_dependency cd
				 WHERE tid.app_sid = t.app_sid AND tid.task_sid = t.task_sid
				   AND tid.app_sid = cd.app_sid AND tid.ind_sid = cd.calc_ind_sid
				   AND cd.ind_sid = tv.ind_sid)
		 MINUS
		SELECT task_sid, start_dtm, end_dtm
		  FROM actions.task_recalc_period;
END;

PROCEDURE RecordProgress(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	in_phase						IN	calc_job.phase%TYPE,
	in_work_done					IN	calc_job.work_done%TYPE,
	in_total_work					IN	calc_job.total_work%TYPE
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	UPDATE calc_job
	   SET phase = in_phase,
	   	   work_done = in_work_done,
	   	   total_work = in_total_work,
	   	   updated_dtm = SYSDATE
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND calc_job_id = in_calc_job_id;
	COMMIT;
END;

PROCEDURE RecordProgress(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	in_work_done					IN	calc_job.work_done%TYPE
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	UPDATE calc_job
	   SET work_done = in_work_done,
	   	   updated_dtm = SYSDATE
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND calc_job_id = in_calc_job_id;
	COMMIT;
END;

PROCEDURE OnJobCompletion(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	in_scenario_run_sid				IN	scenario_run.scenario_run_sid%TYPE
)
AS
	v_on_complete_sp				scenario_run.on_completion_sp%TYPE;
	v_run_by_user_sid				calc_job.run_by_user_sid%TYPE;
	v_run_dtm						DATE;
BEGIN
	-- Record last run by user, last refresh date against the scenario run
	SELECT run_by_user_sid, SYSDATE
	  INTO v_run_by_user_sid, v_run_dtm
	  FROM calc_job
	 WHERE calc_job_id = in_calc_job_id;

	UPDATE scenario_run
	   SET last_run_by_user_sid = v_run_by_user_sid,
	   	   last_success_dtm = v_run_dtm
	 WHERE scenario_run_sid = in_scenario_run_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	-- Trigger email notifications of scenario run completion
	INSERT INTO scenario_alert (app_sid, scenario_sid, csr_user_sid, calc_job_id, calc_job_completion_dtm)
		SELECT sub.app_sid, sub.scenario_sid, sub.csr_user_sid, in_calc_job_id, v_run_dtm
		  FROM scenario_email_sub sub
		  JOIN scenario_run sr ON sub.app_sid = sr.app_sid AND sub.scenario_sid = sr.scenario_sid
		 WHERE scenario_run_sid = in_scenario_run_sid;

	-- Run any on completion hook
	BEGIN
		SELECT on_completion_sp
		  INTO v_on_complete_sp
		  FROM scenario_run
		 WHERE scenario_run_sid = in_scenario_run_sid;		 
	EXCEPTION
		WHEN NO_DATA_FOUND THEN NULL;
	END;
	
	IF v_on_complete_sp IS NOT NULL THEN
		EXECUTE IMMEDIATE 'begin ' || v_on_complete_sp || '(:1, :2, :3); end;'
		USING in_calc_job_id, in_scenario_sid, in_scenario_run_sid;
	END IF;

END;

PROCEDURE SetCalcJobStats(
	in_calc_job_id					IN	calc_job_stat.calc_job_id%TYPE,
	in_version						IN	calc_job_stat.version%TYPE,
	in_scenario_file_size			IN	calc_job_stat.scenario_file_size%TYPE,
	in_heap_allocated				IN	calc_job_stat.heap_allocated%TYPE,
	in_total_time					IN	calc_job_stat.total_time%TYPE,
	in_fetch_time					IN	calc_job_stat.fetch_time%TYPE,
	in_calc_time					IN	calc_job_stat.calc_time%TYPE,
	in_load_file_time				IN	calc_job_stat.load_file_time%TYPE,
	in_load_metadata_time			IN	calc_job_stat.load_metadata_time%TYPE,
	in_load_values_time				IN	calc_job_stat.load_values_time%TYPE,
	in_load_aggregates_time			IN	calc_job_stat.load_aggregates_time%TYPE,
	in_scenario_rules_time			IN	calc_job_stat.scenario_rules_time%TYPE,
	in_save_file_time				IN	calc_job_stat.save_file_time%TYPE,
	in_total_values					IN	calc_job_stat.total_values%TYPE,
	in_aggregate_values				IN	calc_job_stat.aggregate_values%TYPE,
	in_calc_values					IN	calc_job_stat.calc_values%TYPE,
	in_normal_values				IN	calc_job_stat.normal_values%TYPE,
	in_external_aggregate_values	IN	calc_job_stat.external_aggregate_values%TYPE,
	in_calcs_run					IN	calc_job_stat.calcs_run%TYPE,
	in_inds							IN	calc_job_stat.inds%TYPE,
	in_regions						IN	calc_job_stat.regions%TYPE
)
AS
	v_calc_job_inds					calc_job_stat.calc_job_inds%TYPE;
BEGIN
	SELECT COUNT(*)
	  INTO v_calc_job_inds
	  FROM csr.calc_job_ind
	 WHERE calc_job_id = in_calc_job_id;
	 
	INSERT INTO calc_job_stat (
		calc_job_id, scenario_run_sid, version, start_dtm, end_dtm, calc_job_inds,
		attempts, calc_job_type, priority, full_recompute, created_dtm, ran_dtm,
		ran_on, scenario_file_size, heap_allocated, total_time, fetch_time,
		calc_time, load_file_time, load_metadata_time, load_values_time,
		load_aggregates_time, scenario_rules_time, save_file_time, total_values,
		aggregate_values, calc_values, normal_values, external_aggregate_values,
		calcs_run, inds, regions)
		SELECT cj.calc_job_id, cj.scenario_run_sid, sr.version, cj.start_dtm, cj.end_dtm,
			   v_calc_job_inds, cj.attempts, cj.calc_job_type, cj.priority,
			   cj.full_recompute, cj.created_dtm, cj.last_attempt_dtm,
			   SYS_CONTEXT('USERENV', 'HOST'), in_scenario_file_size, in_heap_allocated,
			   in_total_time, in_fetch_time, in_calc_time, in_load_file_time,
			   in_load_metadata_time, in_load_values_time, in_load_aggregates_time,
			   in_scenario_rules_time, in_save_file_time, in_total_values,
			   in_aggregate_values, in_calc_values, in_normal_values,
			   in_external_aggregate_values, in_calcs_run, in_inds, in_regions
		  FROM calc_job cj, csr.scenario_run sr
		 WHERE cj.calc_job_id = in_calc_job_id
		   AND cj.scenario_run_sid = sr.scenario_run_sid(+);
END;

PROCEDURE SetCalcJobFetchStat(
	in_calc_job_id					IN	calc_job_fetch_stat.calc_job_id%TYPE,
	in_fetch_sp						IN	calc_job_fetch_stat.fetch_sp%TYPE,
	in_fetch_time					IN	calc_job_fetch_stat.fetch_time%TYPE
)
AS
BEGIN
	--security_pkg.debugmsg('cjid ' ||in_calc_job_id||', fetch sp '||in_fetch_sp||', fetch time '||in_fetch_time);
	INSERT INTO calc_job_fetch_stat (calc_job_id, fetch_sp, fetch_time)
	VALUES (in_calc_job_id, in_fetch_sp, in_fetch_time);
END;

PROCEDURE GetAppSettings(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'),
		SYS_CONTEXT('SECURITY', 'APP'), security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
		SELECT equality_epsilon, check_divisibility, divisibility_bug,
			   calc_sum_to_dt_cust_yr_start, calc_start_dtm, calc_end_dtm
		  FROM customer;
END;

END stored_calc_datasource_pkg;
/
