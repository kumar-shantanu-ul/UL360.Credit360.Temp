------------ actions.temp_dependency_pkg --------------------------

CREATE OR REPLACE PACKAGE actions.temp_dependency_pkg IS

PROCEDURE CreateJobsFromInd (
	--in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_start_dtm		IN	task_recalc_period.start_dtm%TYPE DEFAULT NULL
);

PROCEDURE Internal_AddTaskRecalcRegion (
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE Internal_AddTaskRecalcPeriod (
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	task_recalc_period.start_dtm%TYPE DEFAULT NULL
);

END temp_dependency_pkg;
/

CREATE OR REPLACE PACKAGE BODY actions.temp_dependency_pkg IS

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

END temp_dependency_pkg;
/

GRANT EXECUTE ON actions.temp_dependency_pkg TO csr;

------------ csr.temp_csr_data_pkg --------------------------

CREATE OR REPLACE PACKAGE csr.temp_csr_data_pkg IS

IND_TYPE_NORMAL			CONSTANT NUMBER(1) := 0;
LOCK_TYPE_CALC			CONSTANT NUMBER(10) := 1;

PROCEDURE LockApp(
	in_lock_type					IN	app_lock.lock_type%TYPE,
	in_app_sid						IN	app_lock.app_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY', 'APP')
);

END temp_csr_data_pkg;
/

CREATE OR REPLACE PACKAGE BODY csr.temp_csr_data_pkg IS

PROCEDURE LockApp(
	in_lock_type					IN	app_lock.lock_type%TYPE,
	in_app_sid						IN	app_lock.app_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY', 'APP')
)
AS
BEGIN
	UPDATE csr.app_lock
	   SET dummy = 1
	 WHERE lock_type = in_lock_type
	   AND app_sid = in_app_sid;
	 
	IF SQL%ROWCOUNT != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unknown lock type: '||in_lock_type||' for app_sid:'||in_app_sid);
	END IF;
END;

END temp_csr_data_pkg;
/

------------ csr.temp_calc_pkg --------------------------

CREATE OR REPLACE PACKAGE csr.temp_calc_pkg IS

-- calculation region
CALC_START							CONSTANT DATE := DATE '1990-01-01';
CALC_END							CONSTANT DATE := DATE '2021-01-01';

PROCEDURE AddJobsForFactorType(
	in_factor_type_id		IN	factor_type.factor_type_id%TYPE
);

PROCEDURE AddJobsForInd(
	in_ind_sid		IN	security_pkg.T_SID_ID
);

END temp_calc_pkg;
/

CREATE OR REPLACE PACKAGE BODY csr.temp_calc_pkg IS

PROCEDURE AddJobsForFactorType(
	in_factor_type_id		IN	factor_type.factor_type_id%TYPE
)
AS
BEGIN
	
	FOR r IN (
		SELECT i.ind_sid
		  FROM ind i
		  JOIN factor_type ft ON i.factor_type_id = ft.factor_type_id
		 WHERE ft.factor_type_id = in_factor_type_id
		   AND i.map_to_ind_sid IS NULL
		   AND i.active = 1 -- XXX: this really ought to say !deleted
	)
	LOOP
		csr.temp_calc_pkg.AddJobsForInd(r.ind_sid);
	END LOOP;

END;

PROCEDURE AddJobsForIndWithoutActions(
	in_ind_sid		IN	security_pkg.T_SID_ID,
	in_ind_type		IN	ind.ind_type%TYPE
)
AS
BEGIN
	csr.temp_csr_data_pkg.LockApp(csr.temp_csr_data_pkg.LOCK_TYPE_CALC);
	 
	-- if this is a normal ind then we can just write the region/period for the values
	-- for this indicator and the dependents will be worked out later (which is cheaper)
	IF in_ind_type = csr.temp_csr_data_pkg.IND_TYPE_NORMAL THEN
		MERGE /*+ALL_ROWS*/ INTO val_change_log vcl
		USING (SELECT NVL(MIN(period_start_dtm), csr.temp_calc_pkg.CALC_START) period_start_dtm, 
					  NVL(MAX(period_end_dtm), csr.temp_calc_pkg.CALC_END) period_end_dtm
		  		 FROM val
		  		WHERE ind_sid = in_ind_sid) v
		   ON (vcl.ind_sid = in_ind_sid)
		 WHEN MATCHED THEN
			UPDATE 
			   SET vcl.start_dtm = LEAST(vcl.start_dtm, v.period_start_dtm),
				   vcl.end_dtm = GREATEST(vcl.end_dtm, v.period_end_dtm)
		 WHEN NOT MATCHED THEN
			INSERT (vcl.ind_sid, vcl.start_dtm, vcl.end_dtm)
			VALUES (in_ind_sid, v.period_start_dtm, v.period_end_dtm);

	-- otherwise if it's a calc then we need to write jobs for all regions
	-- this is to cover weird cases like 1+indicator (n=z) which has a value
	-- even if we have no stored data for indicator and also the calcs which have
	-- a constant value
	ELSE
		MERGE /*+ALL_ROWS*/ INTO val_change_log vcl
		USING (SELECT csr.temp_calc_pkg.CALC_START period_start_dtm, csr.temp_calc_pkg.CALC_END period_end_dtm
		  		 FROM dual) r
		   ON (vcl.ind_sid = in_ind_sid)
		 WHEN MATCHED THEN
			UPDATE 
			   SET vcl.start_dtm = LEAST(vcl.start_dtm, r.period_start_dtm),
				   vcl.end_dtm = GREATEST(vcl.end_dtm, r.period_end_dtm)
		 WHEN NOT MATCHED THEN
			INSERT (vcl.ind_sid, vcl.start_dtm, vcl.end_dtm)
			VALUES (in_ind_sid, r.period_start_dtm, r.period_end_dtm);
	END IF;
END;

PROCEDURE AddJobsForIndWithoutActions(
	in_ind_sid		IN	security_pkg.T_SID_ID
)
AS
	v_ind_type						ind.ind_type%TYPE;
BEGIN
	SELECT ind_type
	  INTO v_ind_type
	  FROM ind
	 WHERE ind_sid = in_ind_sid;
	
	AddJobsForIndWithoutActions(in_ind_sid, v_ind_type);
END;

PROCEDURE AddJobsForInd(
	in_ind_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	AddJobsForIndWithoutActions(in_ind_sid);
	
	-- add calculations for gas indicators that doesn't depend on the current indicator
	FOR r IN (
		SELECT ii.ind_sid
		  FROM ind i
		  JOIN ind ii ON i.ind_sid = ii.map_to_ind_sid
		 WHERE i.ind_sid = in_ind_sid
		  AND i.factor_type_id = 3 -- Unspecified
		  AND i.map_to_ind_sid IS NULL
	)
	LOOP
		AddJobsForIndWithoutActions(r.ind_sid);
	END LOOP;
	
	-- Add jobs for actions that depend on the indicator
	actions.temp_dependency_pkg.CreateJobsFromInd(security_pkg.GetApp, in_ind_sid);
END;

END temp_calc_pkg;
/