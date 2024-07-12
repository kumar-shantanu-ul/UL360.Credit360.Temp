CREATE OR REPLACE PACKAGE BODY CSR.meter_alarm_stat_pkg IS

PROCEDURE AddStatJobsForMeter (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm			IN	DATE
)
AS
	v_start_dtm				DATE;
	v_end_dtm				DATE;
BEGIN
	-- Insert a job for each statistic associated with the meter
	-- or any statistic computed for all meters
	FOR r IN (
		SELECT s.statistic_id, ms.meter_bucket_id
		  FROM meter_meter_alarm_statistic s
		  JOIN meter_alarm_statistic ms ON ms.app_sid = s.app_sid AND ms.statistic_id = s.statistic_id AND ms.all_meters = 0
		  JOIN region r ON r.app_sid = s.app_sid AND r.region_sid = s.region_sid AND r.active != 0
		  JOIN all_meter m ON m.app_sid = s.app_sid AND m.region_sid = s.region_sid
		 WHERE s.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND s.region_sid = in_region_sid		   
		UNION
		SELECT s.statistic_id, s.meter_bucket_id
		  FROM meter_alarm_statistic s
		  JOIN region r ON r.app_sid = s.app_sid AND r.region_sid = in_region_sid AND r.active != 0
		  JOIN all_meter m ON m.app_sid = s.app_sid AND m.region_sid = r.region_sid
		 WHERE s.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND s.all_meters != 0
	) LOOP
		
		-- Start date (last statistic data point)
		BEGIN
			SELECT MAX(statistic_dtm)
			  INTO v_start_dtm
			  FROM meter_alarm_statistic_period
			 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
			   AND region_sid = in_region_sid
			   AND statistic_id = r.statistic_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_start_dtm := NULL;
		END;
		
		-- If the start dtm was input then forcibly set the start date
		IF in_start_dtm IS NOT NULL THEN
			v_start_dtm := LEAST(in_start_dtm, v_start_dtm);
		END IF;
		
		-- End date (last bucketed data point > last statistic data point)
		BEGIN
			SELECT NVL(v_start_dtm, MIN(start_dtm)), MAX(start_dtm)
			  INTO v_start_dtm, v_end_dtm
			  FROM v$patched_meter_live_data
			 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
			   AND region_sid = in_region_sid
			   AND meter_bucket_id = r.meter_bucket_id
			   AND start_dtm >= NVL(v_start_dtm, start_dtm);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_start_dtm := NULL;
				v_end_dtm := NULL;
		END;		
		
		-- Insert the job if we have found valid dates
		IF v_start_dtm IS NOT NULL AND 
			v_end_dtm IS NOT NULL AND
			v_start_dtm != v_end_dtm THEN
			
			BEGIN
				INSERT INTO meter_alarm_statistic_job
					(region_sid, statistic_id, start_dtm, end_dtm)
				  VALUES (in_region_sid, r.statistic_id, v_start_dtm, v_end_dtm);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE meter_alarm_statistic_job
					   SET start_dtm = LEAST(start_dtm, v_start_dtm),
					       end_dtm = GREATEST(end_dtm, v_end_dtm)
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND region_sid = in_region_sid
					   AND statistic_id = r.statistic_id;
			END;
		END IF;
					
	END LOOP;
END;

-- Apps to compute stats for (not run alarms)
PROCEDURE GetAppsToCompute (
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT app_sid
		  FROM meter_alarm_statistic_job;
END;

PROCEDURE ComputeStatistics
AS
BEGIN
	FOR r IN (
		SELECT DISTINCT j.region_sid, j.statistic_id, s.comp_proc, s.meter_input_id, s.aggregator, s.meter_bucket_id,
			GREATEST(j.start_dtm, COALESCE(DECODE(s.all_meters, 0, mm.not_before_dtm, NULL), s.not_before_dtm, j.start_dtm)) start_dtm, j.end_dtm
		  FROM meter_alarm_statistic_job j
		  JOIN meter_alarm_statistic s ON s.app_sid = j.app_sid AND s.statistic_id = j.statistic_id
		  LEFT JOIN meter_meter_alarm_statistic mm ON mm.app_sid = j.app_sid AND mm.region_sid = j.region_sid AND mm.statistic_id = j.statistic_id
		 WHERE j.app_sid = SYS_CONTEXT('SECURITY','APP')
		 	ORDER BY j.region_sid, j.statistic_id
	) LOOP
		IF r.comp_proc IS NOT NULL AND
			r.start_dtm < r.end_dtm THEN
			-- Execute the computation procedure
			EXECUTE IMMEDIATE 'BEGIN '||r.comp_proc||'(:1,:2,:3,:4,:5,:6,:7);END;'
				USING r.region_sid, r.statistic_id, r.meter_input_id, r.aggregator, r.meter_bucket_id, r.start_dtm, r.end_dtm;
		END IF;
	END LOOP;
	
	-- Remove processed jobs
	DELETE FROM meter_alarm_statistic_job
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE AssignStatistics (
	in_region_sid		security_pkg.T_SID_ID
)
AS
	v_count				NUMBER;
BEGIN
	-- Add any new requied ststistics (required minus existing)	
	v_count := 0;
	FOR r IN (
		-- Required
		SELECT r.region_sid, mas.statistic_id
		  FROM (
			SELECT NVL(r.link_to_region_sid, r.region_sid) region_sid
			  FROM region r
			 WHERE r.region_type = csr_data_pkg.REGION_TYPE_REALTIME_METER
				START WITH r.region_sid = in_region_sid
				CONNECT BY PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
		  ) r, region_meter_alarm ra, meter_alarm a, meter_alarm_statistic mas
		 WHERE r.region_sid = ra.region_sid
		   AND ra.meter_alarm_id = a.meter_alarm_id
		   AND ra.ignore = 0
		   AND (a.look_at_statistic_id = mas.statistic_id
		     OR a.compare_statistic_id = mas.statistic_id)
		MINUS
		-- Existing
		SELECT r.region_sid, mmas.statistic_id
		  FROM (
			SELECT NVL(r.link_to_region_sid, r.region_sid) region_sid
			  FROM region r
			 WHERE r.region_type = csr_data_pkg.REGION_TYPE_REALTIME_METER
				START WITH r.region_sid = in_region_sid
				CONNECT BY PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
		  ) r, meter_meter_alarm_statistic mmas
		 WHERE r.region_sid = mmas.region_sid
	) LOOP
		-- Present behaviour is not to compute anything prior to when 
		-- the statistics are first assigned to the meter (via an alarm)
		INSERT INTO meter_meter_alarm_statistic 
			(region_sid, statistic_id, not_before_dtm)
		  VALUES (r.region_sid, r.statistic_id, TRUNC(SYSDATE,'DD'));
		v_count := v_count + 1;
	END LOOP;
	
	-- Remove any statistics that are no longer required (existing minus required)
	FOR r IN (
		-- Existing
		SELECT r.region_sid, mmas.statistic_id
		  FROM (
			SELECT NVL(r.link_to_region_sid, r.region_sid) region_sid
			  FROM region r
			 WHERE r.region_type = csr_data_pkg.REGION_TYPE_REALTIME_METER
				START WITH r.region_sid = in_region_sid
				CONNECT BY PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
		  ) r, meter_meter_alarm_statistic mmas
		 WHERE r.region_sid = mmas.region_sid
		MINUS
		-- Required
		SELECT r.region_sid, mas.statistic_id
		  FROM (
			SELECT NVL(r.link_to_region_sid, r.region_sid) region_sid
			  FROM region r
			 WHERE r.region_type = csr_data_pkg.REGION_TYPE_REALTIME_METER
				START WITH r.region_sid = in_region_sid
				CONNECT BY PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
		  ) r, region_meter_alarm ra, meter_alarm a, meter_alarm_statistic mas
		 WHERE r.region_sid = ra.region_sid
		   AND ra.meter_alarm_id = a.meter_alarm_id
		   AND ra.ignore = 0
		   AND (a.look_at_statistic_id = mas.statistic_id
		     OR a.compare_statistic_id = mas.statistic_id)
	) LOOP
		-- Delete any outstanding jobs
		DELETE FROM meter_alarm_statistic_job
		 WHERE region_sid = r.region_sid
		   AND statistic_id = r.statistic_id;
		-- Delete any associated run info
		DELETE FROM meter_alarm_stat_run
		 WHERE region_sid = r.region_sid
		   AND statistic_id = r.statistic_id;
		-- Delete stat data
		DELETE FROM meter_alarm_statistic_period
		 WHERE region_sid = r.region_sid
		   AND statistic_id = r.statistic_id;
		-- Delete meter/stat relationship
		DELETE FROM meter_meter_alarm_statistic
		 WHERE region_sid = r.region_sid
		   AND statistic_id = r.statistic_id;
		   
	END LOOP;
	
	-- Create jobs if any new statistics were added
	IF v_count > 0 THEN
		AddStatJobsForMeter(in_region_sid, NULL);
	END IF;
END;

-- Apps to run alarm code for (not compute stats)
PROCEDURE GetAppsToRun (
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT app_sid
		  FROM region_meter_alarm;
END;

FUNCTION INTERNAL_CompareStats (
	in_comparison_id		IN	meter_alarm_comparison.comparison_id%TYPE,
	in_lhs					IN	NUMBER,
	in_rhs					IN	NUMBER,
	in_val					IN	NUMBER
) RETURN BOOLEAN
AS
	v_op_code				meter_alarm_comparison.op_code%TYPE;
	--v_rhs					NUMBER;
BEGIN
	SELECT op_code
	  INTO v_op_code
	  FROM meter_alarm_comparison
	 WHERE comparison_id = in_comparison_id;
	
	CASE v_op_code
		-- Greater than %
		WHEN 'GT_PCT' THEN
			RETURN (in_lhs > (in_rhs * in_val / 100));
		
		-- Greater than absolute value
		WHEN 'GT_ABS' THEN
			RETURN (in_lhs > in_val);

		-- Greater than rhs plus absolute value
		WHEN 'GT_ADD' THEN
			RETURN (in_lhs > (in_rhs + in_val));

		-- Greater than rhs minus absolute value
		WHEN 'GT_SUB' THEN
			RETURN (in_lhs > (in_rhs - in_val));

		-- Less than %
		WHEN 'LT_PCT' THEN
			RETURN (in_lhs < (in_rhs * in_val / 100));

		-- Less than absolute value
		WHEN 'LT_ABS' THEN
			RETURN (in_lhs < in_val);

		-- Less than rhs plus absolute value
		WHEN 'LT_ADD' THEN
			RETURN (in_lhs < (in_rhs + in_val));

		-- Less than rhs minus absolute value
		WHEN 'LT_SUB' THEN
			RETURN (in_lhs < (in_rhs - in_val));
			
		ELSE
			-- TODO exception
			NULL;
	END CASE;
	RETURN FALSE;
END;

FUNCTION INTERNAL_CompareAlarmStats(
	in_alarm_id				meter_alarm.meter_alarm_id%TYPE,
	in_lhs					IN	NUMBER,
	in_rhs					IN	NUMBER
) RETURN BOOLEAN
AS
	v_comp_id				meter_alarm.comparison_id%TYPE;
	v_comp_val				meter_alarm.comparison_val%TYPE;
BEGIN
	SELECT comparison_id, comparison_val
	  INTO v_comp_id, v_comp_val
	  FROM meter_alarm
	 WHERE meter_alarm_id = in_alarm_id;
	 
	 RETURN INTERNAL_CompareStats(v_comp_id, in_lhs, in_rhs, v_comp_val);
END;

PROCEDURE RunComparisons
AS
	v_last_stat_dtm		DATE;
	v_do_test			NUMBER;
BEGIN
	
	-- For each region/alarm to test...
	FOR r_test IN (
		SELECT rma.region_sid, rma.meter_alarm_id, ma.look_at_statistic_id, ma.compare_statistic_id, tt.test_function test_time_proc
		  FROM region_meter_alarm rma, region r, meter_alarm ma, meter_alarm_test_time tt
		 WHERE r.active <> 0
		   AND rma.ignore = 0
		   AND rma.region_sid = r.region_sid
		   AND r.region_type = csr_data_pkg.REGION_TYPE_REALTIME_METER
		   AND ma.enabled = 1
		   AND ma.meter_alarm_id = rma.meter_alarm_id
		   AND tt.test_time_id = ma.test_time_id
	) LOOP
		
		-- Get the last statistic dtm we ran against for this alarm/region
		SELECT MAX(statistic_dtm)
		  INTO v_last_stat_dtm
		  FROM meter_alarm_stat_run
		 WHERE region_sid = r_test.region_sid
		   AND meter_alarm_id = r_test.meter_alarm_id
		   AND statistic_id = r_test.look_at_statistic_id;
		   
		SELECT NVL(v_last_stat_dtm, MIN(statistic_dtm))
		  INTO v_last_stat_dtm
		  FROM meter_alarm_statistic_period
		 WHERE region_sid = r_test.region_sid
		   AND statistic_id = r_test.look_at_statistic_id;
		
		-- Compare each statistic period since the last statistic dtm we ran against
		FOR r_period IN (
			SELECT l.val look_at_val, c.val compare_val, l.statistic_dtm
			  FROM meter_alarm_statistic_period l
			  LEFT JOIN meter_alarm_statistic_period c
			    	 ON c.region_sid = r_test.region_sid
				    AND c.statistic_id = r_test.compare_statistic_id
				    AND c.statistic_dtm > v_last_stat_dtm
				    AND l.statistic_dtm = c.statistic_dtm
			 WHERE l.region_sid = r_test.region_sid
			   AND l.statistic_id = r_test.look_at_statistic_id
			   AND l.statistic_dtm > v_last_stat_dtm
		) LOOP
			-- Test for when to run the comparison in the time domain of the statistic period we're processing
			v_do_test := 1;
			IF r_test.test_time_proc IS NOT NULL THEN
				EXECUTE IMMEDIATE 'BEGIN '||r_test.test_time_proc||'(:1,:2,:3,:4,:5);END;'
					USING r_test.region_sid, r_test.meter_alarm_id, r_test.look_at_statistic_id, r_period.statistic_dtm, OUT v_do_test;
			END IF;
			IF v_do_test <> 0 THEN
				-- Compare statistics raising an alarm event/issue if required
				IF INTERNAL_CompareAlarmStats(r_test.meter_alarm_id, r_period.look_at_val, r_period.compare_val) THEN
					meter_alarm_pkg.AddAlarmEvent(r_test.region_sid, r_test.meter_alarm_id, r_period.statistic_dtm);
				END IF;
				-- Update to reflect the fact we ran
				BEGIN
					INSERT INTO meter_alarm_stat_run
						(meter_alarm_id, region_sid, statistic_id, statistic_dtm)
					  VALUES (r_test.meter_alarm_id, r_test.region_sid, r_test.look_at_statistic_id, r_period.statistic_dtm);
				EXCEPTION 
					WHEN DUP_VAL_ON_INDEX THEN
						UPDATE meter_alarm_stat_run
						   SET statistic_dtm = r_period.statistic_dtm
						 WHERE app_sid = security_pkg.GetAPP
						   AND meter_alarm_id = r_test.meter_alarm_id
						   AND region_sid = r_test.region_sid
						   AND statistic_id = r_test.look_at_statistic_id;
				END;
			END IF;
		END LOOP;
		
	END LOOP;
END;

-------------------------------------------------------------------------------

PROCEDURE INTERNAL_UpsertStatValue(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic_period.statistic_id%TYPE,
	in_statistic_dtm	IN	meter_alarm_statistic_period.statistic_dtm%TYPE,
	in_avg_count		IN	meter_alarm_statistic_period.average_count%TYPE,
	in_val				IN	meter_alarm_statistic_period.val%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO meter_alarm_statistic_period
		  (region_sid, statistic_id, statistic_dtm, average_count, val)
			VALUES (in_region_sid, in_statistic_id, in_statistic_dtm, in_avg_count, in_val);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE meter_alarm_statistic_period
			   SET average_count = in_avg_count, 
			       val = in_val
			 WHERE region_sid = in_region_sid
			   AND statistic_id = in_statistic_id
			   AND statistic_dtm = in_statistic_dtm;
	END;
END;


-------------------------------------------------------------------------------

PROCEDURE INTERNAL_ComputeUsage(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE,
	in_days				IN	security.T_SID_TABLE
)
AS
BEGIN
	FOR r IN (
		SELECT start_dtm, consumption
		  FROM v$patched_meter_live_data
		 WHERE meter_input_id = in_meter_input_id
		   AND aggregator = in_aggregator
		   AND meter_bucket_id = in_meter_bucket_id
		   AND region_sid = in_region_sid
		   AND start_dtm >= TRUNC(in_start_dtm, 'DD')
		   AND TO_CHAR(start_dtm, 'D') IN (
			SELECT column_value
			  FROM TABLE(in_days)
		   )
	) LOOP
		INTERNAL_UpsertStatValue(in_region_sid, in_statistic_id, r.start_dtm, NULL, r.consumption);
	END LOOP;
END;

PROCEDURE INTERNAL_ComputeAverage(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE,
	in_days				IN	security.T_SID_TABLE
)
AS
	v_consumption		meter_alarm_statistic_period.val%TYPE;
	v_avg				meter_alarm_statistic_period.val%TYPE;
	v_count				meter_alarm_statistic_period.average_count%TYPE;
	v_start_dtm			DATE := TRUNC(in_start_dtm, 'DD');
BEGIN
	-- Select the average daily consumption up to the day before the start date
	SELECT val_count, DECODE(val_count, 0, NULL, val_sum / val_count) val_avg
	  INTO v_count, v_avg
	  FROM (
		SELECT SUM(consumption) val_sum, COUNT(*) val_count
		  FROM v$patched_meter_live_data  
		 WHERE meter_input_id = in_meter_input_id
		   AND aggregator = in_aggregator
		   AND meter_bucket_id = in_meter_bucket_id
		   AND region_sid = in_region_sid
		   AND start_dtm < v_start_dtm
		   AND TO_CHAR(start_dtm, 'D') IN (
			SELECT column_value
			  FROM TABLE(in_days)
		   )
	  );

	-- For each period (day) between the start and end date
	WHILE v_start_dtm <= in_end_dtm
	LOOP
		-- Fetch the consumption for the new day
		BEGIN
			SELECT consumption
			  INTO v_consumption
			  FROM v$patched_meter_live_data
			 WHERE meter_input_id = in_meter_input_id
			   AND aggregator = in_aggregator
			   AND meter_bucket_id = in_meter_bucket_id
			   AND region_sid = in_region_sid
			   AND start_dtm = v_start_dtm
			   AND TO_CHAR(start_dtm, 'D') IN (
					SELECT column_value
					  FROM TABLE(in_days)
			   );

			-- Compute the new average
			IF v_consumption IS NOT NULL THEN
				v_avg := (NVL(v_avg, 0) * v_count + v_consumption) / (v_count + 1);
				v_count := v_count + 1;
			END IF;

		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				-- No entry in dataset, the average stays 
				-- the same but is still filled in 
				NULL; 
		END;
		
		-- Fill in the statistic data for the day
		INTERNAL_UpsertStatValue(in_region_sid, in_statistic_id, v_start_dtm, v_count, v_avg);
		
		-- Move to next day
		v_start_dtm := v_start_dtm + 1;

	END LOOP;
END;


-------------------------------------------------------------------------------


PROCEDURE ComputeDailyUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
BEGIN
	INTERNAL_ComputeUsage(
		in_region_sid,
		in_statistic_id,
		in_meter_input_id,
		in_aggregator,
		in_meter_bucket_id,
		in_start_dtm,
		in_end_dtm,
		security.T_SID_TABLE(1, 2, 3, 4, 5, 6, 7)
	);
END;

PROCEDURE ComputeAvgDailyUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
BEGIN
	INTERNAL_ComputeAverage(
		in_region_sid,
		in_statistic_id,
		in_meter_input_id,
		in_aggregator,
		in_meter_bucket_id,
		in_start_dtm,
		in_end_dtm,
		security.T_SID_TABLE(1, 2, 3, 4, 5, 6, 7)
	);
END;

PROCEDURE ComputeSameDayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
	v_consumption		meter_alarm_statistic_period.val%TYPE;
	v_avg				meter_alarm_statistic_period.val%TYPE;
	v_count				meter_alarm_statistic_period.average_count%TYPE;
	v_day_of_week		NUMBER;
	v_start_dtm 		DATE;
BEGIN	
	-- For each day of the week
	FOR v_day_of_week IN 1 .. 7
	LOOP
		-- Reset the start dtm for each day of thw week we process
		v_start_dtm := TRUNC(in_start_dtm, 'DD');

		SELECT val_count, DECODE(val_count, 0, NULL, val_sum / val_count) val_avg 
		  INTO v_count, v_avg
		  FROM (
			SELECT SUM(consumption) val_sum, COUNT(*) val_count
			  FROM v$patched_meter_live_data
			 WHERE meter_input_id = in_meter_input_id
			   AND aggregator = in_aggregator
			   AND meter_bucket_id = in_meter_bucket_id
			   AND region_sid = in_region_sid
			   AND start_dtm < v_start_dtm
 			   AND TO_CHAR(start_dtm, 'D') = v_day_of_week
		  );
	
		-- Each period (day) between the start and end date
		WHILE v_start_dtm <= in_end_dtm
		LOOP
			-- Fetch the consumption for the new day matching on
			-- the day of the week we're computing the average for
			BEGIN
				SELECT consumption
				  INTO v_consumption
				  FROM v$patched_meter_live_data
				 WHERE meter_input_id = in_meter_input_id
				   AND aggregator = in_aggregator
			   	   AND meter_bucket_id = in_meter_bucket_id
				   AND region_sid = in_region_sid
				   AND start_dtm = v_start_dtm
				   AND TO_CHAR(start_dtm, 'D') = v_day_of_week;
				
				IF v_consumption IS NOT NULL THEN
					v_avg := (NVL(v_avg, 0) * v_count + v_consumption) / (v_count + 1);
					v_count := v_count + 1;
				END IF;

				-- Fill in the statistic data for the day (only for matching day)
				INTERNAL_UpsertStatValue(in_region_sid, in_statistic_id, v_start_dtm, v_count, v_avg);
			
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					NULL; 
			END;
			
			-- Move to next day
			v_start_dtm := v_start_dtm + 1;

		END LOOP; -- for each day between start and end date
	END LOOP; -- for each day of the week
END;

-------------------------------------------------------------------------------

PROCEDURE ComputeWeekdayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
BEGIN
	INTERNAL_ComputeUsage(
		in_region_sid,
		in_statistic_id,
		in_meter_input_id,
		in_aggregator,
		in_meter_bucket_id,
		in_start_dtm,
		in_end_dtm,
		security.T_SID_TABLE(1, 2, 3, 4, 5)
	);
END;

PROCEDURE ComputeAvgWeekdayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
BEGIN
	INTERNAL_ComputeAverage(
		in_region_sid,
		in_statistic_id,
		in_meter_input_id,
		in_aggregator,
		in_meter_bucket_id,
		in_start_dtm,
		in_end_dtm,
		security.T_SID_TABLE(1, 2, 3, 4, 5)
	);
END;

-------------------------------------------------------------------------------

PROCEDURE ComputeWeekendUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
BEGIN
	INTERNAL_ComputeUsage(
		in_region_sid,
		in_statistic_id,
		in_meter_input_id,
		in_aggregator,
		in_meter_bucket_id,
		in_start_dtm,
		in_end_dtm,
		security.T_SID_TABLE(6, 7)
	);
END;

PROCEDURE ComputeAvgWeekendUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
BEGIN
	INTERNAL_ComputeAverage(
		in_region_sid,
		in_statistic_id,
		in_meter_input_id,
		in_aggregator,
		in_meter_bucket_id,
		in_start_dtm,
		in_end_dtm,
		security.T_SID_TABLE(6, 7)
	);
END;

-------------------------------------------------------------------------------

PROCEDURE ComputeThisMonthDailyAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
	v_consumption		meter_alarm_statistic_period.val%TYPE;
	v_avg				meter_alarm_statistic_period.val%TYPE;
	v_count				meter_alarm_statistic_period.average_count%TYPE;
	v_start_dtm			DATE;
	v_end_dtm			DATE;
BEGIN
	--Ensure start dtm falls on a day boundary
	v_start_dtm := TRUNC(in_start_dtm, 'DD');
	
	-- Each period (day) between the start and end date
	LOOP
		-- Fetch "this month's" average daily consumption as of the day we're processing
		SELECT val_count, DECODE(val_count, 0, NULL, val_sum / val_count) val_avg
		  INTO v_count, v_avg
		  FROM (
			SELECT SUM(consumption) val_sum, COUNT(*) val_count
			  FROM v$patched_meter_live_data  
			 WHERE meter_input_id = in_meter_input_id
			   AND aggregator = in_aggregator
			   AND meter_bucket_id = in_meter_bucket_id
			   AND region_sid = in_region_sid
			   AND start_dtm >= TRUNC(v_start_dtm,'MONTH')
			   AND end_dtm <= ADD_MONTHS(TRUNC(v_start_dtm,'MONTH'),1)
		);
		
		-- Fill in the statistic data for the day
		INTERNAL_UpsertStatValue(in_region_sid, in_statistic_id, v_start_dtm, v_count, v_avg);
		
		-- Move to next day, exit when we've processed the last day
		v_start_dtm := v_start_dtm + 1;
		EXIT WHEN v_start_dtm > in_end_dtm;
	END LOOP;
END;

-------------------------------------------------------------------------------

PROCEDURE ComputeLastMonthDailyAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
	v_consumption		meter_alarm_statistic_period.val%TYPE;
	v_avg				meter_alarm_statistic_period.val%TYPE;
	v_count				meter_alarm_statistic_period.average_count%TYPE;
	v_start_dtm			DATE;
	v_end_dtm			DATE;
BEGIN
	--Ensure start dtm falls on a day boundary
	v_start_dtm := TRUNC(in_start_dtm, 'DD');
	
	-- Each period (day) between the start and end date
	LOOP
		-- Fetch "last month's" average daily consumption as of the day we're processing
		SELECT val_count, DECODE(val_count, 0, NULL, val_sum / val_count) val_avg
		  INTO v_count, v_avg
		  FROM (
			SELECT SUM(consumption) val_sum, COUNT(*) val_count
			  FROM v$patched_meter_live_data  
			 WHERE meter_input_id = in_meter_input_id
			   AND aggregator = in_aggregator
			   AND meter_bucket_id = in_meter_bucket_id
			   AND region_sid = in_region_sid
			   AND start_dtm >= ADD_MONTHS(TRUNC(v_start_dtm,'MONTH'),-1)
			   AND end_dtm <= TRUNC(v_start_dtm,'MONTH')
		);
		
		-- Fill in the statistic data for the day
		INTERNAL_UpsertStatValue(in_region_sid, in_statistic_id, v_start_dtm, v_count, v_avg);
		
		-- Move to next day, exit when we've processed the last day
		v_start_dtm := v_start_dtm + 1;
		EXIT WHEN v_start_dtm > in_end_dtm;
	END LOOP;
END;

-------------------------------------------------------------------------------

-- Usage on a given single day "Usage on Monday" for example.
PROCEDURE INTERNAL_ComputeSglDayUsage (
	in_day				IN	NUMBER,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
BEGIN
	INTERNAL_ComputeUsage(
		in_region_sid,
		in_statistic_id,
		in_meter_input_id,
		in_aggregator,
		in_meter_bucket_id,
		in_start_dtm,
		in_end_dtm,
		security.T_SID_TABLE(in_day)
	);
END;

-- Compute the average for a given single day, "The average usage on a Monday" for example.
PROCEDURE INTERNAL_ComputeAvgSglDayUsage (
	in_day				IN	NUMBER,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
BEGIN
	INTERNAL_ComputeAverage(
		in_region_sid,
		in_statistic_id,
		in_meter_input_id,
		in_aggregator,
		in_meter_bucket_id,
		in_start_dtm,
		in_end_dtm,
		security.T_SID_TABLE(in_day)
	);
END;

-------------------------------------------------------------------------------

PROCEDURE ComputeMondayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
BEGIN
	INTERNAL_ComputeSglDayUsage(1, in_region_sid, in_statistic_id, in_meter_input_id, in_aggregator, in_meter_bucket_id, in_start_dtm, in_end_dtm);
END;
	
PROCEDURE ComputeTuesdayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
BEGIN
	INTERNAL_ComputeSglDayUsage(2, in_region_sid, in_statistic_id, in_meter_input_id, in_aggregator, in_meter_bucket_id, in_start_dtm, in_end_dtm);
END;

PROCEDURE ComputeWednesdayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
BEGIN
	INTERNAL_ComputeSglDayUsage(3, in_region_sid, in_statistic_id, in_meter_input_id, in_aggregator, in_meter_bucket_id, in_start_dtm, in_end_dtm);
END;

PROCEDURE ComputeThursdayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
BEGIN
	INTERNAL_ComputeSglDayUsage(4, in_region_sid, in_statistic_id, in_meter_input_id, in_aggregator, in_meter_bucket_id, in_start_dtm, in_end_dtm);
END;

PROCEDURE ComputeFridayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
BEGIN
	INTERNAL_ComputeSglDayUsage(5, in_region_sid, in_statistic_id, in_meter_input_id, in_aggregator, in_meter_bucket_id, in_start_dtm, in_end_dtm);
END;

PROCEDURE ComputeSaturdayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
BEGIN
	INTERNAL_ComputeSglDayUsage(6, in_region_sid, in_statistic_id, in_meter_input_id, in_aggregator, in_meter_bucket_id, in_start_dtm, in_end_dtm);
END;

PROCEDURE ComputeSundayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
BEGIN
	INTERNAL_ComputeSglDayUsage(7, in_region_sid, in_statistic_id, in_meter_input_id, in_aggregator, in_meter_bucket_id, in_start_dtm, in_end_dtm);
END;

-------------------------------------------------------------------------------

PROCEDURE ComputeAvgMondayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
BEGIN
	INTERNAL_ComputeAvgSglDayUsage(1, in_region_sid, in_statistic_id, in_meter_input_id, in_aggregator, in_meter_bucket_id, in_start_dtm, in_end_dtm);
END;

PROCEDURE ComputeAvgTuesdayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
BEGIN
	INTERNAL_ComputeAvgSglDayUsage(2, in_region_sid, in_statistic_id, in_meter_input_id, in_aggregator, in_meter_bucket_id, in_start_dtm, in_end_dtm);
END;

PROCEDURE ComputeAvgWednesdayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
BEGIN
	INTERNAL_ComputeAvgSglDayUsage(3, in_region_sid, in_statistic_id, in_meter_input_id, in_aggregator, in_meter_bucket_id, in_start_dtm, in_end_dtm);
END;

PROCEDURE ComputeAvgThursdayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
BEGIN
	INTERNAL_ComputeAvgSglDayUsage(4, in_region_sid, in_statistic_id, in_meter_input_id, in_aggregator, in_meter_bucket_id, in_start_dtm, in_end_dtm);
END;

PROCEDURE ComputeAvgFridayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
BEGIN
	INTERNAL_ComputeAvgSglDayUsage(5, in_region_sid, in_statistic_id, in_meter_input_id, in_aggregator, in_meter_bucket_id, in_start_dtm, in_end_dtm);
END;

PROCEDURE ComputeAvgSaturdayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
BEGIN
	INTERNAL_ComputeAvgSglDayUsage(6, in_region_sid, in_statistic_id, in_meter_input_id, in_aggregator, in_meter_bucket_id, in_start_dtm, in_end_dtm);
END;

PROCEDURE ComputeAvgSundayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
BEGIN
	INTERNAL_ComputeAvgSglDayUsage(7, in_region_sid, in_statistic_id, in_meter_input_id, in_aggregator, in_meter_bucket_id, in_start_dtm, in_end_dtm);
END;

-------------------------------------------------------------------------------

END meter_alarm_stat_pkg;
/
