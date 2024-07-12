CREATE OR REPLACE PACKAGE BODY CSR.meter_aggr_pkg IS

PROCEDURE Sum(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_priority			IN	meter_data_priority.priority%TYPE,
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE,
	out_val				OUT	meter_live_data.consumption%TYPE,
	out_raw_data_id		OUT	meter_raw_data.meter_raw_data_id%TYPE
)
AS
BEGIN
	-- Sum of all overlapping data points
	-- Overlapping parts scaled to proportion of iverlap with specified period
	
	out_val := NULL;
	out_raw_data_id := NULL;
	
	FOR r IN (
		SELECT /*+ INDEX(TEMP_METER_CONSUMPTION IX_TEMP_METER_CONSUMPTION) */
			start_dtm, end_dtm, val_number consumption, MAX(raw_data_id) OVER () raw_data_id
		  FROM temp_meter_consumption
		 WHERE region_sid = in_region_sid
		   AND meter_input_id = in_meter_input_id
		   AND priority = in_priority
		   AND end_dtm > in_start_dtm
		   AND start_dtm < in_end_dtm
		   AND val_number IS NOT NULL
	) LOOP
		out_raw_data_id := r.raw_data_id;

		IF r.start_dtm >= in_start_dtm AND r.end_dtm <= in_end_dtm THEN
			-- Data contained entirely within period (optimisaation)
			out_val := NVL(out_val, 0) + r.consumption;
		
		
		ELSIF r.start_dtm != r.end_dtm THEN --<< Prevent divide by zero
			-- Data overlaps period boundary, 
			-- use overlapping fracton of consumption data
			out_val := NVL(out_val, 0) + 
				(LEAST(in_end_dtm, r.end_dtm) - GREATEST(in_start_dtm, r.start_dtm)) * r.consumption / 
										 (r.end_dtm - r.start_dtm)
			;
		END IF;
	END LOOP;
END;

PROCEDURE Average(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_priority			IN	meter_data_priority.priority%TYPE,
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE,
	out_val				OUT	meter_live_data.consumption%TYPE,
	out_raw_data_id		OUT	meter_raw_data.meter_raw_data_id%TYPE
)
AS
	v_consumption_based	NUMBER;
	v_sum				meter_live_data.consumption%TYPE;
	v_per				NUMBER;
	v_dummy_raw_data_id	meter_raw_data.meter_raw_data_id%TYPE;
BEGIN
	SELECT is_consumption_based
	  INTO v_consumption_based
	  FROM meter_input
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND meter_input_id = in_meter_input_id;

	out_val := NULL;
	
	IF v_consumption_based = 0 THEN
		-- Simple average over number of data points (point-like data)
		-- Intended for point-like data
		SELECT SUM(val_number) / COUNT(*), MAX(raw_data_id)
		  INTO out_val, out_raw_data_id
		  FROM temp_meter_consumption
		 WHERE region_sid = in_region_sid
		   AND meter_input_id = in_meter_input_id
		   AND priority = in_priority
		   AND end_dtm > in_start_dtm
		   AND start_dtm < in_end_dtm;
	
	ELSIF in_start_dtm != in_end_dtm THEN
		
		-- XXX: Set to per day for now, need to define on bucket or something
		v_per := 1;
		
		-- Compute the sum
		Sum(in_region_sid, in_meter_input_id, in_priority, in_start_dtm, in_end_dtm, v_sum, v_dummy_raw_data_id);
		
		-- Compute value per duration (sum * duration / bucket size)
		out_val := v_sum * v_per / (in_end_dtm - in_start_dtm);
		
	END IF;
END;


PROCEDURE GetDataCoverageDaysAggr(
	in_aggregate_ind_group_id	IN	NUMBER,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_daily_bucket_id			meter_bucket.meter_bucket_id%TYPE;
	v_period_set_id				meter_bucket.period_set_id%TYPE;
	v_period_interval_id		meter_bucket.period_interval_id%TYPE;
	v_cur						SYS_REFCURSOR;
	v_tbl						T_NORMALISED_VAL_TABLE;
	v_min_dtm					DATE;
	v_max_dtm					DATE;
BEGIN

	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only administrators can run aggregates');
	END IF;

	DELETE FROM temp_new_val;

	BEGIN
		-- Fetch information about the daily bucket
		SELECT meter_bucket_id, NVL(period_set_id, 1), NVL(period_interval_id, 1)
		  INTO v_daily_bucket_id, v_period_set_id, v_period_interval_id
		  FROM meter_bucket
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND is_hours = 1
		   AND duration = 24;

		-- For each input/priority we're interested in coverage data fir
		FOR i IN (
			SELECT meter_input_id, priority, ind_sid
			  FROM meter_data_coverage_ind
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		) LOOP

			-- Loop over regions to save aggregateOverTime having to compute lots of nulls for different regions
			FOR r IN (
				SELECT DISTINCT region_sid
				  FROM meter_live_data
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND meter_bucket_id = v_daily_bucket_id
				   AND meter_input_id = i.meter_input_id
				   AND priority = i.priority
			) LOOP

				SELECT NVL(in_start_dtm, MIN(start_dtm)), NVL(in_end_dtm, MAX(end_dtm))
				  INTO v_min_dtm, v_max_dtm
				  FROM meter_live_data
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND meter_bucket_id = v_daily_bucket_id
				   AND meter_input_id = i.meter_input_id
				   AND priority = i.priority
				   AND region_sid = r.region_sid;

				OPEN v_cur FOR
					SELECT region_sid, start_dtm, end_dtm, 1 val_number
					  FROM (
						SELECT region_sid, start_dtm, end_dtm, MAX(aggregator)
						  FROM meter_live_data
						 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
						   AND meter_bucket_id = v_daily_bucket_id
						   AND meter_input_id = i.meter_input_id
						   AND priority = i.priority
						   AND region_sid = r.region_sid
						   AND start_dtm < v_max_dtm
						   AND end_dtm > v_min_dtm
						 GROUP BY region_sid, start_dtm, end_dtm
					)
					ORDER BY start_dtm;

				v_tbl := period_pkg.AggregateOverTime(
					in_cur					=> v_cur,
					in_start_dtm 			=> v_min_dtm,
					in_end_dtm				=> v_max_dtm,
				    in_period_set_id		=> v_period_set_id,
				    in_peiod_interval_id	=> v_period_interval_id
				);

				INSERT INTO temp_new_val (ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number)
					SELECT i.ind_sid, t.region_sid, t.start_dtm, t.end_dtm, t.val_number
					  FROM TABLE(v_tbl) t;

				CLOSE v_cur;

			END LOOP;
		END LOOP;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL; -- No daily bucket, ignore
	END;

	OPEN out_cur FOR
		SELECT ind_sid, region_sid, period_start_dtm, period_end_dtm, 
			csr.csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id, error_code, val_number
		  FROM temp_new_val
		 ORDER BY ind_sid, region_sid, period_start_dtm;
END;

END meter_aggr_pkg;
/
