CREATE OR REPLACE PACKAGE BODY ACTIONS.dependency_pkg
IS

PROCEDURE ClearDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ClearIndDependencies(in_act_id, in_task_sid);
	ClearTaskDependencies(in_act_id, in_task_sid);
END;

PROCEDURE ClearIndDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE FROM task_ind_dependency
	 WHERE task_sid = in_task_sid;
END;

PROCEDURE ClearTaskDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE FROM task_task_dependency
	 WHERE task_sid = in_task_sid;
END;

-- internal
PROCEDURE AddIndDependencies(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_ind_sids			IN	security_pkg.T_SID_IDS
)
AS
	v_sid_table			security.T_SID_TABLE;
BEGIN
	v_sid_table := security_pkg.SidArrayToTable(in_ind_sids);
	
	INSERT INTO task_ind_dependency (task_sid, ind_sid)
		SELECT in_task_sid, s.column_value
		  FROM TABLE(v_sid_table) s
		 MINUS
		SELECT task_sid, ind_sid
		  FROM task_ind_dependency
		 WHERE task_sid = in_task_sid;
END;

-- internal
PROCEDURE AddTaskDependencies(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_task_sids		IN	security_pkg.T_SID_IDS
)
AS
	v_sid_table			security.T_SID_TABLE;
BEGIN
	v_sid_table := security_pkg.SidArrayToTable(in_task_sids);

	INSERT INTO task_task_dependency (task_sid, depends_on_task_sid)
		SELECT in_task_sid, s.column_value
		  FROM TABLE(v_sid_table) s
		 MINUS
		SELECT task_sid, depends_on_task_sid
		  FROM aggr_task_task_dependency
		 WHERE task_sid = in_task_sid;
END;

PROCEDURE SetDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_ind_sids			IN	security_pkg.T_SID_IDS,
	in_task_sids		IN	security_pkg.T_SID_IDS
)
AS
	v_sid_table			security.T_SID_TABLE;
BEGIN
	-- Clear down old dependencies
	ClearDependencies(in_act_id, in_task_sid);
	
	-- Add ind dependencies
	AddIndDependencies(in_task_sid, in_ind_sids);
	
	-- Add task dependencies
	AddTaskDependencies(in_task_sid, in_task_sids);
END;

PROCEDURE SetIndDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_ind_sids			IN	security_pkg.T_SID_IDS
)
AS
	v_sid_table			security.T_SID_TABLE;
BEGIN
	-- Clear down old dependencies
	ClearIndDependencies(in_act_id, in_task_sid);
	
	-- Add ind dependencies
	AddIndDependencies(in_task_sid, in_ind_sids);
END;

PROCEDURE SetTaskDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_task_sids		IN	security_pkg.T_SID_IDS
)
AS
	v_sid_table			security.T_SID_TABLE;
BEGIN
	-- Clear down old dependencies
	ClearTaskDependencies(in_act_id, in_task_sid);
	
	-- Add task dependencies
	AddTaskDependencies(in_task_sid, in_task_sids);
END;

PROCEDURE AddIndDependency (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	BEGIN
		INSERT INTO task_ind_dependency (task_sid, ind_sid)
		VALUES (in_task_sid, in_ind_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE RemoveIndDependency (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE FROM task_ind_dependency
	 WHERE task_sid = in_task_sid
	   AND ind_sid = in_ind_sid;
END;

PROCEDURE AddTaskDependency (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_dep_task_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	BEGIN
		INSERT INTO task_task_dependency (task_sid, depends_on_task_sid)
		VALUES (in_task_sid, in_dep_task_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE RemoveTaskDependency (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_dep_task_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE FROM task_task_dependency
	 WHERE task_sid = in_task_sid
	   AND depends_on_task_sid = in_dep_task_sid;
END;

PROCEDURE GetIndDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ind_sid
		  FROM task_ind_dependency
		 WHERE task_sid = in_task_sid;
END;

PROCEDURE GetTaskDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT depends_on_task_sid
		  FROM task_task_dependency
		 WHERE task_sid = in_task_sid;
END;

PROCEDURE CreateJobsFromInd (
	--in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_start_dtm		IN	task_recalc_period.start_dtm%TYPE DEFAULT NULL
)
AS
BEGIN
	UPDATE task_recalc_job
	   SET processing = 0
	 WHERE rowid IN (SELECT trj.rowid
					   FROM task_recalc_job trj, task_ind_dependency tid
					  WHERE trj.app_sid = in_app_sid
					    AND tid.app_sid = in_app_sid
					    AND trj.app_sid = tid.app_sid
					    AND trj.task_sid = tid.task_sid
					    AND tid.ind_sid = in_ind_sid);
					    
	INSERT INTO task_recalc_job (app_sid, task_sid, processing)
		SELECT DISTINCT app_sid, task_sid, 0
		  FROM (
			SELECT app_sid, task_sid
			  FROM task_ind_dependency
			 WHERE app_sid = in_app_sid 
			   AND (ind_sid = in_ind_sid
			     	OR ind_sid IN (
				    	SELECT calc_ind_sid
				      	  FROM csr.calc_dependency 
				     	 WHERE ind_sid = in_ind_sid)
				    )
			 MINUS
			SELECT app_sid, task_sid
			  FROM task_recalc_job
			 WHERE app_sid = in_app_sid
		);
		
	FOR r IN (
		SELECT task_sid
		  FROM task_ind_dependency
		 WHERE app_sid = in_app_sid 
		   AND (ind_sid = in_ind_sid
		     	OR ind_sid IN (
			    	SELECT calc_ind_sid
			      	  FROM csr.calc_dependency 
			     	 WHERE ind_sid = in_ind_sid)
			    )
	) LOOP
		Internal_AddTaskRecalcRegion(r.task_sid, in_region_sid);
		Internal_AddTaskRecalcPeriod(r.task_sid, in_start_dtm);
	END LOOP; 
	 
END;

PROCEDURE CreateJobsFromTask (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_start_dtm		IN	task_recalc_period.start_dtm%TYPE DEFAULT NULL
)
AS
BEGIN
	UPDATE task_recalc_job
	   SET processing = 0
	 WHERE rowid IN (SELECT trj.rowid
					   FROM task_recalc_job trj, task_task_dependency ttd
					  WHERE trj.app_sid = in_app_sid
					    AND ttd.app_sid = in_app_sid
					    AND trj.app_sid = ttd.app_sid
					    AND trj.task_sid = ttd.task_sid
					    AND ttd.depends_on_task_sid = in_task_sid);

	-- Insert the job
	INSERT INTO task_recalc_job (app_sid, task_sid, processing)
		SELECT app_sid, task_sid, 0
		  FROM (
			SELECT app_sid, task_sid
			  FROM task_task_dependency
			 WHERE app_sid = in_app_sid 
			   AND depends_on_task_sid = in_task_sid
			 MINUS
			SELECT app_sid, task_sid
			  FROM task_recalc_job
			 WHERE app_sid = in_app_sid
		);
	
	-- Add region and period data to the job
	FOR r IN (
		SELECT task_sid
		  FROM task_task_dependency
		 WHERE app_sid = in_app_sid 
		   AND depends_on_task_sid = in_task_sid
	) LOOP
		Internal_AddTaskRecalcRegion(r.task_sid, in_region_sid);
		Internal_AddTaskRecalcPeriod(r.task_sid, in_start_dtm);
	END LOOP;
	
END;

PROCEDURE CreateJobForTask (
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_start_dtm		IN	task_recalc_period.start_dtm%TYPE DEFAULT NULL
)
AS
	v_app_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_task_sid, security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied creating job for task with sid: ' || in_task_sid);
	END IF;
	
	SELECT t.app_sid
	  INTO v_app_sid
	  FROM task t
	 WHERE t.task_sid = in_task_sid;
	
	-- Add the job
	BEGIN
		INSERT INTO task_recalc_job
		  (app_sid, task_sid, processing)
			VALUES (v_app_sid, in_task_sid, 0);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE task_recalc_job
			   SET processing = 0
			 WHERE app_sid = v_app_sid 
			   AND task_sid = in_task_sid;
	END;
	
	-- Add region and period data to the job
	Internal_AddTaskRecalcRegion(in_task_sid, in_region_sid);
	Internal_AddTaskRecalcPeriod(in_task_sid, in_start_dtm);
	
END;

PROCEDURE GetJobs (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Get jobs to process
	OPEN out_cur FOR
		SELECT task_sid
		  FROM task_recalc_job
		 WHERE app_sid = in_app_sid
		   AND processing = 0;
		 -- FOR UPDATE;
		 
	-- Set jobs to processing
	UPDATE task_recalc_job
	   SET processing = 1
	 WHERE app_sid = in_app_sid
	   AND processing = 0;
END;

PROCEDURE DeleteJobs(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sids		IN	security_pkg.T_SID_IDS
)
AS
	v_sid_table			security.T_SID_TABLE;
BEGIN
	v_sid_table := security_pkg.SidArrayToTable(in_task_sids);
	
	DELETE FROM task_recalc_region
	 WHERE task_sid IN (
		SELECT task_sid 
		  FROM task_recalc_job
		 WHERE processing = 1
		   AND task_sid IN (
			SELECT column_value
			  FROM TABLE(v_sid_table)
		)
	);
	
	DELETE FROM task_recalc_period
	 WHERE task_sid IN (
		SELECT task_sid 
		  FROM task_recalc_job
		 WHERE processing = 1
		   AND task_sid IN (
			SELECT column_value
			  FROM TABLE(v_sid_table)
		)
	);
		
	DELETE FROM task_recalc_job
	 WHERE processing = 1
	   AND task_sid IN (
		SELECT column_value
		  FROM TABLE(v_sid_table)
	);
END;

PROCEDURE DeleteJobs(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID
)
AS
	v_sid_table			security.T_SID_TABLE;
BEGIN
	
	DELETE FROM task_recalc_region
	 WHERE task_sid IN (
		SELECT task_sid 
		  FROM task_recalc_job
		 WHERE processing = 1
	   	   AND task_sid = in_task_sid
	);
	
	DELETE FROM task_recalc_period
	 WHERE task_sid IN (
		SELECT task_sid 
		  FROM task_recalc_job
		 WHERE processing = 1
	   	   AND task_sid = in_task_sid
	);
	
	DELETE FROM task_recalc_job
	 WHERE processing = 1
	   AND task_sid = in_task_sid;
END;


PROCEDURE GetDependentTaskPeriodStatuses(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ttd.depends_on_task_sid, tp.task_period_status_id, tps.label status_label, tps.colour status_colour, start_dtm, end_dtm, region_sid
	    FROM task_period tp, task_period_status tps, task_task_dependency ttd
	   WHERE tp.task_period_status_id = tps.task_period_status_id
	     AND tp.task_sid = ttd.depends_on_task_sid
	     AND ttd.task_sid = in_task_sid;
END;

PROCEDURE GetTaskJobRegions(
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT region_sid
		  FROM task_recalc_region
		 WHERE task_sid = in_task_sid;
END;

PROCEDURE GetTaskJobPeriods(
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT p.start_dtm, p.end_dtm
		  FROM task_recalc_period p, task t
		 WHERE t.task_sid = in_task_sid
		   AND p.task_sid = t.task_sid
		   AND p.start_dtm >= t.start_dtm
		   AND p.end_dtm <= t.end_dtm
		 	ORDER BY start_dtm ASC;
END;
	
PROCEDURE Internal_AddTaskRecalcRegion (
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	-- Add region information if we have it, if not then 
	-- we have to assume all regions need processing
	IF in_region_sid IS NULL THEN
		FOR r IN (
			SELECT region_sid
			  FROM task_region
			 WHERE task_sid = in_task_sid
		) LOOP
			BEGIN
				INSERT INTO task_recalc_region
				  (task_sid, region_sid)
					VALUES (in_task_sid, r.region_sid);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					-- Ignore f already exists
					NULL;
			END;		
		END LOOP;
	ELSE
		BEGIN
			INSERT INTO task_recalc_region
			  (task_sid, region_sid) (
			  	SELECT task_sid, region_sid
			  	  FROM task_region
			  	 WHERE task_sid = in_task_sid
			  	   AND region_sid = in_region_sid
			);
		EXCEPTION 
			WHEN DUP_VAL_ON_INDEX THEN
				-- Ignore if it already exists
				NULL;
		END;
	END IF;
END;

PROCEDURE Internal_AddTaskRecalcPeriod (
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	task_recalc_period.start_dtm%TYPE DEFAULT NULL
)
AS
	v_start_dtm			task.start_dtm%TYPE;
	v_end_dtm			task.end_dtm%TYPE;
	v_duration			task.period_duration%TYPE;
BEGIN
	-- Add period information if we have it, if not then 
	-- we have to assume all periods need processing
	IF in_start_dtm IS NULL THEN	
		
		-- Fetch the task's start, end and duration
		SELECT start_dtm, end_dtm, period_duration
		  INTO v_start_dtm, v_end_dtm, v_duration
		  FROM task
		 WHERE task_sid = in_task_sid;

		-- Loop over simulated periods
		FOR r IN (
			SELECT start_dtm, ADD_MONTHS(start_dtm, v_duration) end_dtm, v_duration period_duration
			  FROM (
				SELECT ADD_MONTHS(v_start_dtm, (rownum - 1) * v_duration) start_dtm
				  FROM DUAL
				  	CONNECT BY ADD_MONTHS(v_start_dtm, (rownum - 1) * v_duration) < v_end_dtm
			)
		) LOOP
			BEGIN
				INSERT INTO task_recalc_period
				  (task_sid, start_dtm, end_dtm)
				  	VALUES (in_task_sid, r.start_dtm, r.end_dtm);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					-- Ignroe if already exists
					NULL;
			END;
		END LOOP;
		
	ELSE
		-- We have the period, just add it
		BEGIN
			INSERT INTO task_recalc_period
			  (task_sid, start_dtm, end_dtm) (
			  	SELECT task_sid, in_start_dtm, ADD_MONTHS(in_start_dtm, period_duration)
			  	  FROM task
			  	 WHERE task_sid = in_task_sid
			  );
		EXCEPTION 
			WHEN DUP_VAL_ON_INDEX THEN
				-- Ignore if it already exists
				NULL;
		END;
	END IF;
END;

END dependency_pkg;
/
