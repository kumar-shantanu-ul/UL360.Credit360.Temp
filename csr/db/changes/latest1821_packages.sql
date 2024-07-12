CREATE OR REPLACE PACKAGE actions.temp_dependency_pkg AS
PROCEDURE CreateJobsFromInd (
	--in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_start_dtm		IN	task_recalc_period.start_dtm%TYPE DEFAULT NULL
);
END;
/

CREATE OR REPLACE PACKAGE BODY actions.temp_dependency_pkg AS
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
END;
/

GRANT EXECUTE on actions.temp_dependency_pkg to CSR;

CREATE OR REPLACE PACKAGE CSR.temp_factor_pkg AS
PROCEDURE StdFactorDelValue(
	in_std_factor_id		IN std_factor.std_factor_id%TYPE
);
END;
/

CREATE OR REPLACE PACKAGE BODY CSR.temp_factor_pkg AS

-- This is here due to FB7942, which hasn't successfully been reproduced.
-- If it doesn't trigger after a few years, it can be removed.
PROCEDURE CheckForOverlappingFactorData
AS
	v_overlaps						NUMBER;
BEGIN
	SELECT COUNT(*) 
	  INTO v_overlaps
	  FROM factor f1, factor f2
	 WHERE f1.app_sid = f2.app_sid
	   AND f1.factor_type_id = f2.factor_type_id
	   AND f1.gas_type_id = f2.gas_type_id
	   AND NVL(f1.region_sid, -1) = NVL(f2.region_sid, -1)
	   AND NVL(f1.egrid_ref, 'XX') = NVL(f2.egrid_ref, 'XX')
	   AND NVL(f1.geo_country, 'XX') = NVL(f2.geo_country, 'XX')
	   AND NVL(f1.geo_region, 'XX') = NVL(f2.geo_region, 'XX')
	   AND f1.factor_id != f2.factor_id
	   AND f1.is_selected = 1
	   AND f2.is_selected = 1
	   AND (f1.start_dtm < f2.end_dtm OR f2.end_dtm IS NULL)
	   AND (f1.end_dtm IS NULL OR f1.end_dtm > f2.start_dtm);
	IF v_overlaps > 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Overlapping factor data was detected: see FB7942');
	END IF;
END;

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

PROCEDURE AddJobsForIndWithoutActions(
	in_ind_sid		IN	security_pkg.T_SID_ID,
	in_ind_type		IN	ind.ind_type%TYPE
)
AS
BEGIN
	LockApp(1);
	 
	-- if this is a normal ind then we can just write the region/period for the values
	-- for this indicator and the dependents will be worked out later (which is cheaper)
	IF in_ind_type = 0 THEN
		MERGE /*+ALL_ROWS*/ INTO val_change_log vcl
		USING (SELECT NVL(MIN(period_start_dtm), DATE '1990-01-01') period_start_dtm, 
					  NVL(MAX(period_end_dtm), DATE '2021-01-01') period_end_dtm
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
		USING (SELECT DATE '1990-01-01' period_start_dtm, DATE '2021-01-01' period_end_dtm
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

/* something about this indicator as a whole has changed so 
   add in a ton of jobs for all the calculations that use its 
   values (e.g. divisible field maybe changed?) */
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
		AddJobsForInd(r.ind_sid);
	END LOOP;
END;

PROCEDURE UpdateSelectedSetForApp(
	in_app_sid				IN security_pkg.T_SID_ID,
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_geo_country			IN factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_std_factor_set_id	IN std_factor.std_factor_set_id%TYPE
)
AS
BEGIN
	--copy standard factor values to factor table
	--this duplication of select query because WITH AS doesn't work on my oracle
	INSERT INTO factor(app_sid, factor_id, factor_type_id, gas_type_id, geo_country, 
			geo_region, egrid_ref, std_factor_id, start_dtm, end_dtm, value, 
			std_measure_conversion_id, note, region_sid, is_selected)
	SELECT in_app_sid, FACTOR_ID_SEQ.nextval factor_id, in_factor_type_id, gas_type_id,
				geo_country, geo_region, egrid_ref, std_factor_id, start_dtm, end_dtm, value, 
				std_measure_conversion_id, note, NULL, 1 is_selected
	  FROM (
			SELECT sf.factor_type_id, gas_type_id,
					geo_country, geo_region, egrid_ref, std_factor_id, start_dtm, end_dtm, value, 
					std_measure_conversion_id, note, priority
			 FROM (
					(
						SELECT factor_type_id, gas_type_id,
								geo_country, geo_region, egrid_ref, std_factor_id, start_dtm, end_dtm, value, 
								std_measure_conversion_id, note
						  FROM std_factor 
						 WHERE std_factor_set_id = in_std_factor_set_id
						   AND ((in_geo_country IS NULL AND geo_country IS NULL) OR geo_country = in_geo_country)
						   AND ((in_geo_region IS NULL AND geo_region IS NULL AND egrid_ref IS NULL) OR geo_region = in_geo_region OR egrid_ref = in_geo_region)
					) sf
					JOIN
					(
						SELECT factor_type_id, level priority
						  FROM factor_type
						 START WITH factor_type_id = in_factor_type_id
						CONNECT BY PRIOR parent_id = factor_type_id
					) ft
					ON sf.factor_type_id = ft.factor_type_id
			)
	)
	 WHERE priority = (
			SELECT min(priority)
			  FROM (
					SELECT priority
					 FROM (
							(
								SELECT factor_type_id
								  FROM std_factor 
								 WHERE std_factor_set_id = in_std_factor_set_id
								   AND ((in_geo_country IS NULL AND geo_country IS NULL) OR geo_country = in_geo_country)
								   AND ((in_geo_region IS NULL AND geo_region IS NULL AND egrid_ref IS NULL) OR geo_region = in_geo_region OR egrid_ref = in_geo_region)
							) sf
							JOIN
							(
								SELECT factor_type_id, level priority
								  FROM factor_type
								 START WITH factor_type_id = in_factor_type_id
								CONNECT BY PRIOR parent_id = factor_type_id
							) ft
							ON sf.factor_type_id = ft.factor_type_id
					)
			)
	);
	CheckForOverlappingFactorData;
	
	-- write calc jobs
	AddJobsForFactorType(in_factor_type_id);
END;

PROCEDURE StdFactorDelValue(
	in_std_factor_id		IN std_factor.std_factor_id%TYPE
)
AS
	v_std_factor_set_id		std_factor_set.std_factor_set_id%TYPE;
	v_factor_type_id		factor_type.factor_type_id%TYPE;
	v_count					NUMBER;
	v_app_sid				security_pkg.T_SID_ID;
BEGIN	
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
		
	security_pkg.SetApp(NULL);
	SELECT std_factor_set_id
	  INTO v_std_factor_set_id
	  FROM std_factor
	 WHERE std_factor_id = in_std_factor_id;
	
	SELECT factor_type_id
	  INTO v_factor_type_id
	  FROM std_factor
	 WHERE std_factor_id = in_std_factor_id;
	
	INSERT INTO factor_for_update (app_sid, geo_country, geo_region)
	SELECT UNIQUE app_sid, geo_country, NVL(geo_region, egrid_ref)
	  FROM factor
	 WHERE std_factor_id = in_std_factor_id
	   AND is_selected = 1;
	
	-- update copies factor table
	DELETE FROM factor WHERE std_factor_id = in_std_factor_id;
	-- update std factor table
	DELETE FROM std_factor WHERE std_factor_id = in_std_factor_id;

	FOR r IN (SELECT * FROM factor_for_update)
	LOOP
		SELECT COUNT(*)
		  INTO v_count
		  FROM factor f
		  JOIN std_factor sf ON f.std_factor_id = sf.std_factor_id
		 WHERE f.app_sid = r.app_sid
		   AND NVL(f.geo_country, ' ') = NVL(r.geo_country, ' ')
		   AND NVL(f.geo_region, NVL(f.egrid_ref, ' ')) = NVL(r.geo_region, ' ')
		   AND f.factor_type_id = v_factor_type_id
		   AND sf.std_factor_set_id = v_std_factor_set_id;
		
		IF v_count = 0 THEN
			UpdateSelectedSetForApp(
				r.app_sid, v_factor_type_id, r.geo_country, r.geo_region, v_std_factor_set_id);
		END IF;
	END LOOP;
	
	CheckForOverlappingFactorData;
	
	-- write calc jobs for all customer
	FOR r IN (
		SELECT app_sid
		  FROM customer
		 WHERE use_carbon_emission = 1
	)
	LOOP
		security_pkg.SetApp(r.app_sid);
		AddJobsForFactorType(v_factor_type_id);
	END LOOP;
	
	security_pkg.SetApp(v_app_sid);
END;

END temp_factor_pkg;
/
