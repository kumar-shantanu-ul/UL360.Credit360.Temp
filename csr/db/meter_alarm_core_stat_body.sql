CREATE OR REPLACE PACKAGE BODY CSR.meter_alarm_core_stat_pkg IS

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

PROCEDURE INTERNAL_ComputeCoreDayUse (
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
	v_start_dtm			DATE := TRUNC(in_start_dtm, 'DD');
BEGIN
	-- For each day (stats are one slot per day) between the start and end date
	WHILE v_start_dtm <= in_end_dtm 
	LOOP
		-- Sum the consumption values falling during core hours for the day
		SELECT SUM(d.consumption)
		  INTO v_consumption
		  FROM v$patched_meter_live_data d
		  JOIN temp_core_working_hours h
				ON TO_CHAR(d.start_dtm, 'D') = h.day
			   AND d.start_dtm >= v_start_dtm + TO_DSINTERVAL(h.start_time)
			   AND d.start_dtm < v_start_dtm + TO_DSINTERVAL(h.end_time)
		 WHERE d.meter_input_id = in_meter_input_id
		   AND d.aggregator = in_aggregator
		   AND d.meter_bucket_id = in_meter_bucket_id
		   AND d.region_sid = in_region_sid
		   AND TRUNC(d.start_dtm, 'DD') = v_start_dtm
		;

		-- Fill in the statistic data for the day, but only if the value is present
		IF v_consumption IS NOT NULL THEN
			INTERNAL_UpsertStatValue(in_region_sid, in_statistic_id, v_start_dtm, NULL, v_consumption);
		END IF;
		
		-- Move to next day
		v_start_dtm := v_start_dtm + 1;

	END LOOP;
END;

PROCEDURE INTERNAL_ComputeCoreDayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
	v_avg				meter_alarm_statistic_period.val%TYPE;
	v_day_count			meter_alarm_statistic_period.average_count%TYPE;
	v_consumption		meter_alarm_statistic_period.val%TYPE;
	v_start_dtm			DATE := TRUNC(in_start_dtm, 'DD');
BEGIN
	
	-- Get daily average for all historic data falling under core working hours
	-- there might be missing days so we need to sum up the count of distinct days 
	-- to get the correct average (as per below, missing days don't contribute to average)
	SELECT days_with_data_count, val_sum / days_with_data_count daily_avg
	  INTO v_day_count, v_avg
	  FROM (
		SELECT SUM(consumption) val_sum, COUNT(DISTINCT TRUNC(start_dtm, 'DD')) days_with_data_count
		  FROM (
			SELECT d.consumption, d.start_dtm
			  FROM v$patched_meter_live_data d
			  JOIN temp_core_working_hours h
					ON TO_CHAR(d.start_dtm, 'D') = h.day
				   AND d.start_dtm >= TRUNC(d.start_dtm, 'DD') + TO_DSINTERVAL(h.start_time)
				   AND d.start_dtm < TRUNC(d.start_dtm, 'DD') + TO_DSINTERVAL(h.end_time)
			 WHERE d.meter_input_id = in_meter_input_id
			   AND d.aggregator = in_aggregator
			   AND d.meter_bucket_id = in_meter_bucket_id
			   AND d.region_sid = in_region_sid
			   AND d.start_dtm < v_start_dtm
		  )
	  );
	
	-- For each day between the start and end date
	WHILE v_start_dtm <= in_end_dtm 
	LOOP
		-- Sum the consumption for the new day
		SELECT SUM(consumption)
		  INTO v_consumption
		  FROM v$patched_meter_live_data d
		  JOIN temp_core_working_hours h
				ON TO_CHAR(d.start_dtm, 'D') = h.day
			   AND d.start_dtm >= v_start_dtm + TO_DSINTERVAL(h.start_time)
			   AND d.start_dtm < v_start_dtm + TO_DSINTERVAL(h.end_time)
		 WHERE d.meter_input_id = in_meter_input_id
		   AND d.aggregator = in_aggregator
		   AND d.meter_bucket_id = in_meter_bucket_id
		   AND d.region_sid = in_region_sid
		   AND TRUNC(d.start_dtm, 'DD') = v_start_dtm
		;
		
		-- Compute the new daily average
		-- Value stays the same if there is no data
		IF v_consumption IS NOT NULL THEN
			v_avg := (NVL(v_avg, 0) * v_day_count + v_consumption) / (v_day_count + 1);
			v_day_count := v_day_count + 1; -- increment by one day
		END IF;
		
		-- Fill in the new average core working consumption per day data for the day
		INTERNAL_UpsertStatValue(in_region_sid, in_statistic_id, v_start_dtm, v_day_count, v_avg);
		
		-- Move to next day
		v_start_dtm := v_start_dtm + 1;

	END LOOP;
END;

PROCEDURE INTERNAL_ComputeCoreSameDayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
	v_avg				meter_alarm_statistic_period.val%TYPE;
	v_day_count			meter_alarm_statistic_period.average_count%TYPE;
	v_consumption		meter_alarm_statistic_period.val%TYPE;
	v_day_of_week		NUMBER;
	v_start_dtm			DATE;
BEGIN
	-- For each day of the week
	FOR v_day_of_week IN 1 .. 7
	LOOP
		-- Reset the start dtm for each day we process
		v_start_dtm	:=  TRUNC(in_start_dtm, 'DD');
		
		SELECT days_with_data_count, val_sum / days_with_data_count daily_avg
		  INTO v_day_count, v_avg
		  FROM (
			SELECT SUM(consumption) val_sum, COUNT(DISTINCT TRUNC(start_dtm, 'DD')) days_with_data_count
			  FROM (
				SELECT d.consumption, d.start_dtm
				  FROM v$patched_meter_live_data d
				  JOIN temp_core_working_hours h
						ON TO_CHAR(d.start_dtm, 'D') = h.day
					   AND d.start_dtm >= TRUNC(d.start_dtm, 'DD') + TO_DSINTERVAL(h.start_time)
					   AND d.start_dtm < TRUNC(d.start_dtm, 'DD') + TO_DSINTERVAL(h.end_time)
				 WHERE d.meter_input_id = in_meter_input_id
				   AND d.aggregator = in_aggregator
				   AND d.meter_bucket_id = in_meter_bucket_id
				   AND d.region_sid = in_region_sid
				   AND d.start_dtm < v_start_dtm
				   AND TO_CHAR(d.start_dtm, 'D') = v_day_of_week
			  )
		  );
	
		-- For each day between the start and end date
		WHILE v_start_dtm <= in_end_dtm
		LOOP
			-- Sum the consumption for the new day matching on
			-- the day of the week we're computing the average for
			SELECT SUM(consumption)
			  INTO v_consumption
			  FROM v$patched_meter_live_data d
			  JOIN temp_core_working_hours h
					ON TO_CHAR(d.start_dtm, 'D') = h.day
				   AND d.start_dtm >= v_start_dtm + TO_DSINTERVAL(h.start_time)
				   AND d.start_dtm < v_start_dtm + TO_DSINTERVAL(h.end_time)
			 WHERE d.meter_input_id = in_meter_input_id
			   AND d.aggregator = in_aggregator
			   AND d.meter_bucket_id = in_meter_bucket_id
			   AND d.region_sid = in_region_sid
			   AND TRUNC(d.start_dtm, 'DD') = v_start_dtm
			   AND TO_CHAR(start_dtm, 'D') = v_day_of_week
			;
			
			-- Compute the new daily average if we have data for the day we're processing
			IF v_consumption IS NOT NULL THEN
				v_avg := (NVL(v_avg, 0) * v_day_count + v_consumption) / (v_day_count + 1);
				v_day_count := v_day_count + 1; -- increment by one day

				-- Fill in the new average core working consumption per day data for the day
				-- Unlike other average functions we only write the data if we have a value
				-- as this stat implicitly encompasses all days.
				INTERNAL_UpsertStatValue(in_region_sid, in_statistic_id, v_start_dtm, v_day_count, v_avg);
			END IF;
			
			-- Move to next day
			v_start_dtm := v_start_dtm + 1;
		
		END LOOP; -- for each day between start and end

	END LOOP; -- for each day of the week
END;

-------------------------------------------------------------------------------

PROCEDURE INTERNAL_ComputeNonCoreDayUse (
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
	v_start_dtm			DATE := TRUNC(in_start_dtm, 'DD');
BEGIN
	-- For each day (stats are one slot per day) between the start and end date
	WHILE v_start_dtm <= in_end_dtm
	LOOP
		-- Sum the consumption values falling outside core hours 
		-- but still on the days specified in the core hours config
		SELECT SUM(d.consumption)
		  INTO v_consumption
		  FROM v$patched_meter_live_data d
		  JOIN temp_core_working_hours h
				ON TO_CHAR(d.start_dtm, 'D') = h.day
			   AND (
					d.start_dtm < TRUNC(d.start_dtm, 'DD') + TO_DSINTERVAL(h.start_time)
				 OR d.start_dtm >= TRUNC(d.start_dtm, 'DD') + TO_DSINTERVAL(h.end_time)
			   )
		 WHERE d.meter_input_id = in_meter_input_id
		   AND d.aggregator = in_aggregator
		   AND d.meter_bucket_id = in_meter_bucket_id
		   AND d.region_sid = in_region_sid
		   AND TRUNC(d.start_dtm, 'DD') = v_start_dtm
		;

		-- Fill in the statistic data for the day, but only if the value is present
		IF v_consumption IS NOT NULL THEN
			INTERNAL_UpsertStatValue(in_region_sid, in_statistic_id, v_start_dtm, NULL, v_consumption);
		END IF;
		
		-- Move to next day
		v_start_dtm := v_start_dtm + 1;
		
	END LOOP;
END;

PROCEDURE INTERNAL_ComputeNonCoreDayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
	v_avg				meter_alarm_statistic_period.val%TYPE;
	v_day_count			meter_alarm_statistic_period.average_count%TYPE;
	v_consumption		meter_alarm_statistic_period.val%TYPE;
	v_start_dtm			DATE := TRUNC(in_start_dtm, 'DD');
BEGIN
	-- Get daily average for all historic data falling under non-core working hours
	-- there might be missing days so we need to sum up the count of distinct days 
	-- to get the correct average (as per below, missing days don't contribute to average)
	SELECT days_with_data_count, val_sum / days_with_data_count daily_avg
	  INTO v_day_count, v_avg
	  FROM (
		SELECT SUM(consumption) val_sum, COUNT(DISTINCT TRUNC(start_dtm, 'DD')) days_with_data_count
		  FROM (
			SELECT d.consumption, d.start_dtm
			  FROM v$patched_meter_live_data d
			  JOIN temp_core_working_hours h
					ON TO_CHAR(d.start_dtm, 'D') = h.day
				   AND (
						d.start_dtm < TRUNC(d.start_dtm, 'DD') + TO_DSINTERVAL(h.start_time)
					 OR d.start_dtm >= TRUNC(d.start_dtm, 'DD') + TO_DSINTERVAL(h.end_time)
				   )
			 WHERE d.meter_input_id = in_meter_input_id
			   AND d.aggregator = in_aggregator
			   AND d.meter_bucket_id = in_meter_bucket_id
			   AND d.region_sid = in_region_sid
			   AND d.start_dtm < v_start_dtm
		  )
	  );

	-- For each day between the start and end date
	WHILE v_start_dtm <= in_end_dtm
	LOOP
		-- Sum the consumption for the new day
		SELECT SUM(consumption)
		  INTO v_consumption
		  FROM v$patched_meter_live_data d
		  JOIN temp_core_working_hours h
				ON TO_CHAR(d.start_dtm, 'D') = h.day
			   AND (
					d.start_dtm < TRUNC(d.start_dtm, 'DD') + TO_DSINTERVAL(h.start_time)
				 OR d.start_dtm >= TRUNC(d.start_dtm, 'DD') + TO_DSINTERVAL(h.end_time)
			   )
		 WHERE d.meter_input_id = in_meter_input_id
		   AND d.aggregator = in_aggregator
		   AND d.meter_bucket_id = in_meter_bucket_id
		   AND d.region_sid = in_region_sid
		   AND TRUNC(d.start_dtm, 'DD') = v_start_dtm
		;
		
		-- Compute the new daily average
		-- Value stays the same if there is no data
		IF v_consumption IS NOT NULL THEN
			v_avg := (NVL(v_avg, 0) * v_day_count + v_consumption) / (v_day_count + 1);
			v_day_count := v_day_count + 1; -- increment by one day
		END IF;

		-- Fill in the new average core working consumption per day data for the day
		INTERNAL_UpsertStatValue(in_region_sid, in_statistic_id, v_start_dtm, v_day_count, v_avg);
		
		-- Move to next day
		v_start_dtm := v_start_dtm + 1;

	END LOOP;
END;

PROCEDURE INTERNAL_CmpNonCoreSameDayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
	v_avg				meter_alarm_statistic_period.val%TYPE;
	v_day_count			meter_alarm_statistic_period.average_count%TYPE;
	v_consumption		meter_alarm_statistic_period.val%TYPE;
	v_day_of_week		NUMBER;
	v_start_dtm			DATE;
BEGIN
	-- For each day of the week
	FOR v_day_of_week IN 1 .. 7
	LOOP
		-- Reset the start dtm for each day we process
		v_start_dtm	:=  TRUNC(in_start_dtm, 'DD');
		
		SELECT days_with_data_count, val_sum / days_with_data_count daily_avg
		  INTO v_day_count, v_avg
		  FROM (
			SELECT SUM(consumption) val_sum, COUNT(DISTINCT TRUNC(start_dtm, 'DD')) days_with_data_count
			  FROM (
				SELECT d.consumption, d.start_dtm
				  FROM v$patched_meter_live_data d
				  JOIN temp_core_working_hours h
						ON TO_CHAR(d.start_dtm, 'D') = h.day
					   AND (
					   		d.start_dtm < TRUNC(d.start_dtm, 'DD') + TO_DSINTERVAL(h.start_time)
					     OR d.start_dtm >= TRUNC(d.start_dtm, 'DD') + TO_DSINTERVAL(h.end_time)
					   )
				 WHERE d.meter_input_id = in_meter_input_id
				   AND d.aggregator = in_aggregator
				   AND d.meter_bucket_id = in_meter_bucket_id
				   AND d.region_sid = in_region_sid
				   AND d.start_dtm < v_start_dtm
				   AND TO_CHAR(d.start_dtm, 'D') = v_day_of_week
			  )
		  );
	
		-- For each day between the start and end date
		WHILE v_start_dtm <= in_end_dtm
		LOOP
			-- Sum the consumption for the new day matching on
			-- the day of the week we're computing the average for
			SELECT SUM(consumption)
			  INTO v_consumption
			  FROM v$patched_meter_live_data d
			  JOIN temp_core_working_hours h
					ON TO_CHAR(d.start_dtm, 'D') = h.day
				   AND (
						d.start_dtm < TRUNC(d.start_dtm, 'DD') + TO_DSINTERVAL(h.start_time)
					 OR d.start_dtm >= TRUNC(d.start_dtm, 'DD') + TO_DSINTERVAL(h.end_time)
				   )
			 WHERE d.meter_input_id = in_meter_input_id
			   AND d.aggregator = in_aggregator
			   AND d.meter_bucket_id = in_meter_bucket_id
			   AND d.region_sid = in_region_sid
			   AND TRUNC(d.start_dtm, 'DD') = v_start_dtm
			   AND TO_CHAR(start_dtm, 'D') = v_day_of_week
			;
			
			-- Compute the new average
			IF v_consumption IS NOT NULL THEN
				v_avg := (NVL(v_avg, 0) * v_day_count + v_consumption) / (v_day_count + 1);
				v_day_count := v_day_count + 1; -- increment by one day
				
				-- Fill in the new average core working consumption per day data for the day
				-- Unlike other average functions we only write the data if we have a value
				-- as this stat implicitly encompasses all days.
				INTERNAL_UpsertStatValue(in_region_sid, in_statistic_id, v_start_dtm, v_day_count, v_avg);
			END IF;
			
			-- Move to next day
			v_start_dtm := v_start_dtm + 1;

		END LOOP; -- for each day of data we're processing

	END LOOP; -- for each day of the week
END;

-------------------------------------------------------------------------------

PROCEDURE ComputeCoreDayUse (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Simple case, compute usage during core hours for each core day so
	-- no need to filter the temp table populated by PrepCoreWorkingHours.
	INTERNAL_ComputeCoreDayUse(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;


PROCEDURE ComputeCoreDayAvg (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Simple case, compute average daily usage during core hours for each core 
	-- day, no need to filter the temp table populated by PrepCoreWorkingHours.
	INTERNAL_ComputeCoreDayAvg(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeCoreSameDayAvg (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Simple case, compute average daily usage during core hours for each core 
	-- day, no need to filter the temp table populated by PrepCoreWorkingHours.
	INTERNAL_ComputeCoreSameDayAvg(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

-------------------------------------------------------------------------------

PROCEDURE ComputeNonCoreDayUse (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Simple case, compute usage during non-core hours for each core day so
	-- no need to filter the temp table populated by PrepCoreWorkingHours.
	INTERNAL_ComputeNonCoreDayUse(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeNonCoreDayAvg (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Simple case, compute average daily usage during non-core hours for each core 
	-- day, no need to filter the temp table populated by PrepCoreWorkingHours.
	INTERNAL_ComputeNonCoreDayAvg(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeNonCoreSameDayAvg (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Simple case, compute average daily usage during non-core hours for each core 
	-- day, no need to filter the temp table populated by PrepCoreWorkingHours.
	INTERNAL_CmpNonCoreSameDayAvg(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

-------------------------------------------------------------------------------

PROCEDURE ComputeCoreWeekDayUse (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day NOT IN (1, 2, 3, 4, 5); -- Week day

	INTERNAL_ComputeCoreDayUse(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeCoreWeekendUse (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day NOT IN (6, 7); -- Weekend day

	INTERNAL_ComputeCoreDayUse(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeCoreWeekDayAvg (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day NOT IN (1, 2, 3, 4, 5); -- Week day

	INTERNAL_ComputeCoreDayAvg(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeCoreWeekendAvg (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day NOT IN (6, 7); -- Weekend day

	INTERNAL_ComputeCoreDayAvg(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

-------------------------------------------------------------------------------

PROCEDURE ComputeNonCoreWeekDayUse (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day NOT IN (1, 2, 3, 4, 5); -- Week day

	INTERNAL_ComputeNonCoreDayUse(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeNonCoreWeekendUse (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day NOT IN (6, 7); -- Weekend day

	INTERNAL_ComputeNonCoreDayUse(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeNonCoreWeekDayAvg (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day NOT IN (1, 2, 3, 4, 5); -- Week day

	INTERNAL_ComputeNonCoreDayAvg(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeNonCoreWeekendAvg (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day NOT IN (6, 7); -- Weekend day

	INTERNAL_ComputeNonCoreDayAvg(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

-------------------------------------------------------------------------------

PROCEDURE ComputeCoreMondayUse (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 1; -- Monday

	INTERNAL_ComputeCoreDayUse(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeCoreTuesdayUse (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 2; -- Tuesday

	INTERNAL_ComputeCoreDayUse(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeCoreWednesdayUse (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 3; -- Wednesday

	INTERNAL_ComputeCoreDayUse(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeCoreThursdayUse (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 4; -- Thursday

	INTERNAL_ComputeCoreDayUse(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeCoreFridayUse (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 5; -- Friday

	INTERNAL_ComputeCoreDayUse(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeCoreSaturdayUse (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 6; -- Saturday

	INTERNAL_ComputeCoreDayUse(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeCoreSundayUse (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 7; -- Sunday

	INTERNAL_ComputeCoreDayUse(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

-------------------------------------------------------------------------------

PROCEDURE ComputeCoreMondayAvg (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 1; -- Monday

	INTERNAL_ComputeCoreDayAvg(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeCoreTuesdayAvg (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 2; -- Tuesday

	INTERNAL_ComputeCoreDayAvg(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeCoreWednesdayAvg (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 3; -- Wednesday

	INTERNAL_ComputeCoreDayAvg(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeCoreThursdayAvg (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 4; -- Thursday

	INTERNAL_ComputeCoreDayAvg(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeCoreFridayAvg (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 5; -- Friday

	INTERNAL_ComputeCoreDayAvg(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeCoreSaturdayAvg (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 6; -- Saturday

	INTERNAL_ComputeCoreDayAvg(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeCoreSundayAvg (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 7; -- Sunday

	INTERNAL_ComputeCoreDayAvg(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

-------------------------------------------------------------------------------

PROCEDURE ComputeNonCoreMondayUse (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 1; -- Monday

	INTERNAL_ComputeNonCoreDayUse(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeNonCoreTuesdayUse (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 2; -- Tuesday

	INTERNAL_ComputeNonCoreDayUse(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeNonCoreWednesdayUse (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 3; -- Wednesday

	INTERNAL_ComputeNonCoreDayUse(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeNonCoreThursdayUse (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 4; -- Thursday

	INTERNAL_ComputeNonCoreDayUse(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeNonCoreFridayUse (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 5; -- Friday

	INTERNAL_ComputeNonCoreDayUse(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeNonCoreSaturdayUse (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 6; -- Saturday

	INTERNAL_ComputeNonCoreDayUse(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeNonCoreSundayUse (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 7; -- Sunday

	INTERNAL_ComputeNonCoreDayUse(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

-------------------------------------------------------------------------------

PROCEDURE ComputeNonCoreMondayAvg (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 1; -- Monday

	INTERNAL_ComputeNonCoreDayAvg(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeNonCoreTuesdayAvg (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 2; -- Tuesday

	INTERNAL_ComputeNonCoreDayAvg(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeNonCoreWednesdayAvg (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 3; -- Wednesday

	INTERNAL_ComputeNonCoreDayAvg(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeNonCoreThursdayAvg (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 4; -- Thursday

	INTERNAL_ComputeNonCoreDayAvg(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeNonCoreFridayAvg (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 5; -- Friday

	INTERNAL_ComputeNonCoreDayAvg(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeNonCoreSaturdayAvg (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 6; -- Saturday

	INTERNAL_ComputeNonCoreDayAvg(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

PROCEDURE ComputeNonCoreSundayAvg (
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
	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- Filter out any core hours not falling on the correct day
	DELETE FROM temp_core_working_hours
	 WHERE day != 7; -- Sunday

	INTERNAL_ComputeNonCoreDayAvg(
		in_region_sid		=> in_region_sid,
		in_statistic_id		=> in_statistic_id,
		in_meter_input_id	=> in_meter_input_id,
		in_aggregator		=> in_aggregator,
		in_meter_bucket_id	=> in_meter_bucket_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm
	);
END;

-------------------------------------------------------------------------------

FUNCTION INTERNAL_GetBucketHours (
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE
)
RETURN NUMBER
AS
	v_bucket_length_hours	NUMBER;
BEGIN
	SELECT CASE
		WHEN is_minutes = 1 THEN duration / 60
		WHEN is_hours = 1 THEN duration
		ELSE NULL -- others not supported
	END bucket_length_hours
	  INTO v_bucket_length_hours
	  FROM meter_bucket
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND meter_bucket_id = in_meter_bucket_id;

	RETURN v_bucket_length_hours;
END;

-------------------------------------------------------------------------------

PROCEDURE ComputeCoreDayNormUse (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
	v_consumption			meter_alarm_statistic_period.val%TYPE;
	v_start_dtm				DATE := TRUNC(in_start_dtm, 'DD');
	v_bucket_length_hours	NUMBER;
BEGIN
	-- What's the bucket length in hours
	v_bucket_length_hours := INTERNAL_GetBucketHours(in_meter_bucket_id);

	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- For each day (stats are one slot per day) between the start and end date
	WHILE v_start_dtm <= in_end_dtm
	LOOP
		-- Get the normalised daily consumption for this day
		SELECT (SUM(d.consumption) * 24) / (COUNT(*) * v_bucket_length_hours)
		  INTO v_consumption
		  FROM v$patched_meter_live_data d
		  JOIN temp_core_working_hours h
				ON TO_CHAR(d.start_dtm, 'D') = h.day
			   AND d.start_dtm >= v_start_dtm + TO_DSINTERVAL(h.start_time)
			   AND d.start_dtm < v_start_dtm + TO_DSINTERVAL(h.end_time)
		 WHERE d.meter_input_id = in_meter_input_id
		   AND d.aggregator = in_aggregator
		   AND d.meter_bucket_id = in_meter_bucket_id
		   AND d.region_sid = in_region_sid
		   AND TRUNC(d.start_dtm, 'DD') = v_start_dtm
		;

		-- Fill in the statistic data for the day, but only if the value is present
		IF v_consumption IS NOT NULL THEN
			INTERNAL_UpsertStatValue(in_region_sid, in_statistic_id, v_start_dtm, NULL, v_consumption);
		END IF;
		
		-- Move to next day
		v_start_dtm := v_start_dtm + 1;

	END LOOP;
END;

PROCEDURE ComputeCoreDayNormAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
	v_avg					meter_alarm_statistic_period.val%TYPE;
	v_day_count					meter_alarm_statistic_period.average_count%TYPE;
	v_consumption			meter_alarm_statistic_period.val%TYPE;
	v_start_dtm				DATE := TRUNC(in_start_dtm, 'DD');
	v_bucket_length_hours	NUMBER;
BEGIN
	-- What's the bucket length in hours
	v_bucket_length_hours := INTERNAL_GetBucketHours(in_meter_bucket_id);

	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	
	SELECT day_count, total_day_normalised / day_count day_normalised_average
	  INTO v_day_count, v_avg
	  FROM (
	  	-- sum the day normalised consumptions
		SELECT SUM(day_normalised) total_day_normalised, COUNT(*) day_count
		  FROM (
		  	-- select the day normalised concumption for each day
			SELECT (SUM(d.consumption) * 24) / (COUNT(*) * v_bucket_length_hours) day_normalised
			  FROM v$patched_meter_live_data d
			  JOIN temp_core_working_hours h
					ON TO_CHAR(d.start_dtm, 'D') = h.day
				   AND d.start_dtm >= TRUNC(d.start_dtm, 'DD') + TO_DSINTERVAL(h.start_time)
				   AND d.start_dtm < TRUNC(d.start_dtm, 'DD') + TO_DSINTERVAL(h.end_time)
			 WHERE d.meter_input_id = in_meter_input_id
			   AND d.aggregator = in_aggregator
			   AND d.meter_bucket_id = in_meter_bucket_id
			   AND d.region_sid = in_region_sid
			   AND d.start_dtm < v_start_dtm
			 GROUP BY TRUNC(start_dtm, 'DD')
		  )
	  );
	
	-- For each day between the start and end date
	WHILE v_start_dtm <= in_end_dtm
	LOOP
		-- Get the normalised daily consumption for this day
		SELECT (SUM(d.consumption) * 24) / (COUNT(*) * v_bucket_length_hours)
		  INTO v_consumption
		  FROM v$patched_meter_live_data d
		  JOIN temp_core_working_hours h
				ON TO_CHAR(d.start_dtm, 'D') = h.day
			   AND d.start_dtm >= v_start_dtm + TO_DSINTERVAL(h.start_time)
			   AND d.start_dtm < v_start_dtm + TO_DSINTERVAL(h.end_time)
		 WHERE d.meter_input_id = in_meter_input_id
		   AND d.aggregator = in_aggregator
		   AND d.meter_bucket_id = in_meter_bucket_id
		   AND d.region_sid = in_region_sid
		   AND TRUNC(d.start_dtm, 'DD') = v_start_dtm
		;
		
		-- Compute the new daily normalised average
		-- Value stays the same if there is no data
		IF v_consumption IS NOT NULL THEN
			v_avg := (NVL(v_avg, 0) * v_day_count + v_consumption) / (v_day_count + 1);
			v_day_count := v_day_count + 1; -- increment by one day
		END IF;
		
		-- Fill in the new average core working consumption per day data for the day
		INTERNAL_UpsertStatValue(in_region_sid, in_statistic_id, v_start_dtm, v_day_count, v_avg);
		
		-- Move to next day
		v_start_dtm := v_start_dtm + 1;

	END LOOP;
END;

-------------------------------------------------------------------------------

PROCEDURE ComputeNonCoreDayNormUse (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
	v_consumption			meter_alarm_statistic_period.val%TYPE;
	v_start_dtm				DATE := TRUNC(in_start_dtm, 'DD');
	v_bucket_length_hours	NUMBER;
BEGIN
	-- What's the bucket length in hours
	v_bucket_length_hours := INTERNAL_GetBucketHours(in_meter_bucket_id);

	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- For each day (stats are one slot per day) between the start and end date
	WHILE v_start_dtm <= in_end_dtm
	LOOP
		-- Get the normalised daily consumption for this day
		SELECT (SUM(d.consumption) * 24) / (COUNT(*) * v_bucket_length_hours)
		  INTO v_consumption
		  FROM v$patched_meter_live_data d
		  JOIN temp_core_working_hours h
				ON TO_CHAR(d.start_dtm, 'D') = h.day
			   AND (
					d.start_dtm < TRUNC(d.start_dtm, 'DD') + TO_DSINTERVAL(h.start_time)
				 OR d.start_dtm >= TRUNC(d.start_dtm, 'DD') + TO_DSINTERVAL(h.end_time)
			   )
		 WHERE d.meter_input_id = in_meter_input_id
		   AND d.aggregator = in_aggregator
		   AND d.meter_bucket_id = in_meter_bucket_id
		   AND d.region_sid = in_region_sid
		   AND TRUNC(d.start_dtm, 'DD') = v_start_dtm
		;

		-- Fill in the statistic data for the day, but only if the value is present
		IF v_consumption IS NOT NULL THEN
			INTERNAL_UpsertStatValue(in_region_sid, in_statistic_id, v_start_dtm, NULL, v_consumption);
		END IF;
		
		-- Move to next day
		v_start_dtm := v_start_dtm + 1;
		
	END LOOP;
END;

PROCEDURE ComputeNonCoreDayNormAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
)
AS
	v_avg					meter_alarm_statistic_period.val%TYPE;
	v_day_count				meter_alarm_statistic_period.average_count%TYPE;
	v_consumption			meter_alarm_statistic_period.val%TYPE;
	v_start_dtm				DATE := TRUNC(in_start_dtm, 'DD');
	v_bucket_length_hours	NUMBER;
BEGIN
	-- What's the bucket length in hours
	v_bucket_length_hours := INTERNAL_GetBucketHours(in_meter_bucket_id);

	-- Populate core hour hours for this region
	meter_alarm_pkg.PrepCoreWorkingHours(in_region_sid);

	-- select the day normalised average
	SELECT day_count, total_day_normalised / day_count day_normalised_average
	  INTO v_day_count, v_avg
	  FROM (
	  	-- sum the day normalised consumptions
		SELECT SUM(day_normalised) total_day_normalised, COUNT(*) day_count
		  FROM (
		  	-- select the day normalised consumption for each day
			SELECT (SUM(d.consumption) * 24) / (COUNT(*) * v_bucket_length_hours) day_normalised
			  FROM v$patched_meter_live_data d
			  JOIN temp_core_working_hours h
					ON TO_CHAR(d.start_dtm, 'D') = h.day
				   AND (
						d.start_dtm < TRUNC(d.start_dtm, 'DD') + TO_DSINTERVAL(h.start_time)
					 OR d.start_dtm >= TRUNC(d.start_dtm, 'DD') + TO_DSINTERVAL(h.end_time)
				   )
			 WHERE d.meter_input_id = in_meter_input_id
			   AND d.aggregator = in_aggregator
			   AND d.meter_bucket_id = in_meter_bucket_id
			   AND d.region_sid = in_region_sid
			   AND d.start_dtm < v_start_dtm
			 GROUP BY TRUNC(start_dtm, 'DD')
		  )
	  );
		
	-- For each day between the start and end date
	WHILE v_start_dtm <= in_end_dtm
	LOOP
		-- Get the normalised daily consumption for this day
		SELECT (SUM(d.consumption) * 24) / (COUNT(*) * v_bucket_length_hours)
		  INTO v_consumption
		  FROM v$patched_meter_live_data d
		  JOIN temp_core_working_hours h
				ON TO_CHAR(d.start_dtm, 'D') = h.day
			   AND (
					d.start_dtm < TRUNC(d.start_dtm, 'DD') + TO_DSINTERVAL(h.start_time)
				 OR d.start_dtm >= TRUNC(d.start_dtm, 'DD') + TO_DSINTERVAL(h.end_time)
			   )
		 WHERE d.meter_input_id = in_meter_input_id
		   AND d.aggregator = in_aggregator
		   AND d.meter_bucket_id = in_meter_bucket_id
		   AND d.region_sid = in_region_sid
		   AND TRUNC(d.start_dtm, 'DD') = v_start_dtm
		;
		
		-- Compute the new daily normalised average
		-- Value stays the same if there is no data
		IF v_consumption IS NOT NULL THEN
			v_avg := (NVL(v_avg, 0) * v_day_count + v_consumption) / (v_day_count + 1);
			v_day_count := v_day_count + 1; -- increment by one day
		END IF;
		
		-- Fill in the new average core working consumption per day data for the day
		INTERNAL_UpsertStatValue(in_region_sid, in_statistic_id, v_start_dtm, v_day_count, v_avg);
		
		-- Move to next day
		v_start_dtm := v_start_dtm + 1;

	END LOOP;
END;

END meter_alarm_core_stat_pkg;
/
