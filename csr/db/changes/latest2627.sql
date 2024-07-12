define version=2627
@update_header

DECLARE
	PROCEDURE update_factor_val (
		in_std_factor_id	NUMBER,
		in_old_value		NUMBER,
		in_new_value		NUMBER,
		in_egrid_ref		NVARCHAR2
	)
	
	AS
		v_std_measure_conversion_id   NUMBER(10);
	
	BEGIN	
		UPDATE csr.std_factor
		   SET value = in_new_value
		 WHERE std_factor_id = in_std_factor_id
		   AND value = in_old_value
		   AND egrid_ref = in_egrid_ref;
	END;

	PROCEDURE AddJobsForIndWithoutActions(
		in_ind_sid		IN	security.security_pkg.T_SID_ID,
		in_ind_type		IN	csr.ind.ind_type%TYPE
	)
	AS
	BEGIN
		update csr.app_lock set dummy=1 where app_sid=sys_context('security','app') and lock_type=1;
		 
		-- if this is a normal ind then we can just write the region/period for the values
		-- for this indicator and the dependents will be worked out later (which is cheaper)
		IF in_ind_type = 0 THEN
			MERGE /*+ALL_ROWS*/ INTO csr.val_change_log vcl
			USING (SELECT NVL(MIN(period_start_dtm), date '1990-01-01') period_start_dtm, 
						  NVL(MAX(period_end_dtm), date '2021-01-01') period_end_dtm
			  		 FROM csr.val
			  		WHERE ind_sid = in_ind_sid) v
			   ON (vcl.ind_sid = in_ind_sid)
			 WHEN MATCHED THEN
				UPDATE 
				   SET vcl.start_dtm = LEAST(vcl.start_dtm, v.period_start_dtm),
					   vcl.end_dtm = GREATEST(vcl.end_dtm, v.period_end_dtm)
			 WHEN NOT MATCHED THEN
				INSERT (vcl.ind_sid, vcl.start_dtm, vcl.end_dtm)
				VALUES (in_ind_sid, v.period_start_dtm, v.period_end_dtm);
	
		-- otherwise if it's a calc then we need to write jobs for all periods
		-- this is to cover weird cases like 1+indicator (n=z) which has a value
		-- even if we have no stored data for indicator and also the calcs which have
		-- a constant value
		ELSE
			MERGE /*+ALL_ROWS*/ INTO csr.val_change_log vcl
			USING (SELECT date '1990-01-01' period_start_dtm, date '2021-01-01' period_end_dtm
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
		in_ind_sid		IN	security.security_pkg.T_SID_ID
	)
	AS
		v_ind_type						csr.ind.ind_type%TYPE;
	BEGIN
		SELECT ind_type
		  INTO v_ind_type
		  FROM csr.ind
		 WHERE ind_sid = in_ind_sid;
		
		AddJobsForIndWithoutActions(in_ind_sid, v_ind_type);
	END;

	PROCEDURE Internal_AddTaskRecalcRegion (
		in_task_sid			IN	security.security_pkg.T_SID_ID,
		in_region_sid		IN	security.security_pkg.T_SID_ID
	)
	AS
	BEGIN
		-- Add region information if we have it, if not then 
		-- we have to assume all regions need processing
		IF in_region_sid IS NULL THEN
			FOR r IN (
				SELECT region_sid
				  FROM actions.task_region
				 WHERE task_sid = in_task_sid
			) LOOP
				BEGIN
					INSERT INTO actions.task_recalc_region
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
				INSERT INTO actions.task_recalc_region
				  (task_sid, region_sid) (
				  	SELECT task_sid, region_sid
				  	  FROM actions.task_region
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
		in_task_sid			IN	security.security_pkg.T_SID_ID,
		in_start_dtm		IN	actions.task_recalc_period.start_dtm%TYPE DEFAULT NULL
	)
	AS
		v_start_dtm			actions.task.start_dtm%TYPE;
		v_end_dtm			actions.task.end_dtm%TYPE;
		v_duration			actions.task.period_duration%TYPE;
	BEGIN
		-- Add period information if we have it, if not then 
		-- we have to assume all periods need processing
		IF in_start_dtm IS NULL THEN	
			
			-- Fetch the task's start, end and duration
			SELECT start_dtm, end_dtm, period_duration
			  INTO v_start_dtm, v_end_dtm, v_duration
			  FROM actions.task
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
					INSERT INTO actions.task_recalc_period
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
				INSERT INTO actions.task_recalc_period
				  (task_sid, start_dtm, end_dtm) (
				  	SELECT task_sid, in_start_dtm, ADD_MONTHS(in_start_dtm, period_duration)
				  	  FROM actions.task
				  	 WHERE task_sid = in_task_sid
				  );
			EXCEPTION 
				WHEN DUP_VAL_ON_INDEX THEN
					-- Ignore if it already exists
					NULL;
			END;
		END IF;
	END;

	PROCEDURE actionsCreateJobsFromInd (
		--in_act_id			IN	security_pkg.T_ACT_ID,
		in_app_sid			IN	security.security_pkg.T_SID_ID,
		in_ind_sid			IN	security.security_pkg.T_SID_ID,
		in_region_sid		IN	security.security_pkg.T_SID_ID DEFAULT NULL,
		in_start_dtm		IN	actions.task_recalc_period.start_dtm%TYPE DEFAULT NULL
	)
	AS
	BEGIN
		UPDATE actions.task_recalc_job
		   SET processing = 0
		 WHERE rowid IN (SELECT trj.rowid
						   FROM actions.task_recalc_job trj, actions.task_ind_dependency tid
						  WHERE trj.app_sid = in_app_sid
						    AND tid.app_sid = in_app_sid
						    AND trj.app_sid = tid.app_sid
						    AND trj.task_sid = tid.task_sid
						    AND tid.ind_sid = in_ind_sid);
						    
		INSERT INTO actions.task_recalc_job (app_sid, task_sid, processing)
			SELECT DISTINCT app_sid, task_sid, 0
			  FROM (
				SELECT app_sid, task_sid
				  FROM actions.task_ind_dependency
				 WHERE app_sid = in_app_sid 
				   AND (ind_sid = in_ind_sid
				     	OR ind_sid IN (
					    	SELECT calc_ind_sid
					      	  FROM csr.calc_dependency 
					     	 WHERE ind_sid = in_ind_sid)
					    )
				 MINUS
				SELECT app_sid, task_sid
				  FROM actions.task_recalc_job
				 WHERE app_sid = in_app_sid
			);
			
		FOR r IN (
			SELECT task_sid
			  FROM actions.task_ind_dependency
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

	/* something about this indicator as a whole has changed so 
	   add in a ton of jobs for all the calculations that use its 
	   values (e.g. divisible field maybe changed?) */
	PROCEDURE AddJobsForInd(
		in_ind_sid		IN	security.security_pkg.T_SID_ID
	)
	AS
	BEGIN
		AddJobsForIndWithoutActions(in_ind_sid);
		
		-- add calculations for gas indicators that doesn't depend on the current indicator
		FOR r IN (
			SELECT ii.ind_sid
			  FROM csr.ind i
			  JOIN csr.ind ii ON i.ind_sid = ii.map_to_ind_sid
			 WHERE i.ind_sid = in_ind_sid
			   AND i.factor_type_id = 3 -- Unspecified
			   AND i.map_to_ind_sid IS NULL
		)
		LOOP
			AddJobsForIndWithoutActions(r.ind_sid);
		END LOOP;
		
		-- Add jobs for actions that depend on the indicator
		actionsCreateJobsFromInd(security.security_pkg.GetApp, in_ind_sid);
	END;

BEGIN
	update_factor_val(34647, 727.2585, 724.1201, 'CAMX');
	update_factor_val(184352777, 727.2585, 724.1201, 'CAMX');
	update_factor_val(184298051, 727.2585, 724.1201, 'CAMX');
	update_factor_val(184352841, 1059.427, 683.5329, 'CAMX');
	update_factor_val(184298055, 1059.427, 683.5329, 'CAMX');
	
	update_factor_val(34675, 934.7701, 927.6814, 'NEWE');
	update_factor_val(184353255, 934.7701, 927.6814, 'NEWE');
	update_factor_val(184298163, 934.7701, 927.6814, 'NEWE');
	update_factor_val(184353259, 1235.934, 834.2812, 'NEWE');
	update_factor_val(184298167, 1253.934, 834.2812, 'NEWE');
	
	update_factor_val(34679, 907.261, 902.2403, 'NWPP');
	update_factor_val(184353271, 907.261, 902.2403, 'NWPP');
	update_factor_val(184298179, 907.261, 902.2403, 'NWPP');
	update_factor_val(184353275, 1860.637, 863.3625, 'NWPP');
	update_factor_val(184298183, 1860.637, 863.3625, 'NWPP');
	
	update_factor_val(34695, 1145.512, 1139.075, 'RFCE');
	update_factor_val(184352627, 1145.512, 1139.075, 'RFCE');
	update_factor_val(184298243, 1145.512, 1139.075, 'RFCE');
	update_factor_val(184352631, 1817.16, 1065.174, 'RFCE');
	update_factor_val(184298247, 1817.16, 1065.174, 'RFCE');
	
	update_factor_val(34703, 1546.178, 1537.825, 'RFCW');
	update_factor_val(184352780, 1546.178, 1537.825, 'RFCW');
	update_factor_val(184298275, 1546.178, 1537.825, 'RFCW');
	update_factor_val(184352784, 2025.649, 1559.939, 'RFCW');
	update_factor_val(184298279, 2025.649, 1559.939, 'RFCW');
	
	update_factor_val(34711, 1971.39, 1960.943, 'SPNO');
	update_factor_val(184352872, 1971.39, 1960.943, 'SPNO');
	update_factor_val(184298307, 1971.39, 1960.943, 'SPNO');
	update_factor_val(184352876, 2167.833, 1808.203, 'SPNO');
	update_factor_val(184298311, 2167.833, 1808.203, 'SPNO');
	
	update_factor_val(34723, 1840.41, 1830.51, 'SRMW');
	update_factor_val(184353043, 1840.41, 1830.51, 'SRMW');
	update_factor_val(184298355, 1840.41, 1830.51, 'SRMW');
	update_factor_val(184353047, 2096.158, 1788.879, 'SRMW');
	update_factor_val(184298359, 2096.148, 1788.879, 'SRMW');
	update_factor_val(184353111, 1759.149, 1006.12, 'SRMW');
	update_factor_val(184298363, 1759.149, 1006.12, 'SRMW');
	
	update_factor_val(34727, 1497.987, 1489.539, 'SRSO');
	update_factor_val(184353119, 1497.987, 1489.539, 'SRSO');
	update_factor_val(184298371, 1497.987, 1489.539, 'SRSO');
	update_factor_val(184353123, 1833.71, 1503.586, 'SRSO');
	update_factor_val(184298375, 1833.71, 1503.586, 'SRSO');
	
	update_factor_val(34735, 1141.512, 1134.879,'SRVC');
	update_factor_val(184353213, 1141.512, 1134.879,'SRVC');
	update_factor_val(184298403, 1141.512, 1134.879,'SRVC');
	update_factor_val(184353289, 1846.505, 1124.786,'SRVC');
	update_factor_val(184298407, 1846.505, 1124.786,'SRVC');

	FOR r IN (
		 SELECT c.host
		   FROM csr.customer c, security.website ws
		  WHERE c.use_carbon_emission = 1 and lower(ws.website_name) = lower(c.host)
	)
	LOOP
		security.user_pkg.logonadmin(r.host);
		FOR s IN (
			SELECT i.ind_sid
			  FROM csr.ind i
			  JOIN csr.factor_type ft ON i.factor_type_id = ft.factor_type_id
			 WHERE i.map_to_ind_sid IS NULL
			   AND i.active = 1 -- XXX: this really ought to say !deleted
		)
		LOOP
			AddJobsForInd(s.ind_sid);
		END LOOP;
	END LOOP;
END;
/

@update_tail
