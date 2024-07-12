CREATE OR REPLACE PACKAGE csr.temp_meter_pkg
IS

PROCEDURE UpdateMeterListCache(
	in_region_sid			IN	security_pkg.T_SID_ID
);

END temp_meter_pkg;
/

CREATE OR REPLACE PACKAGE BODY csr.temp_meter_pkg
IS

PROCEDURE UpdateMeterListCache(
	in_region_sid			IN	security_pkg.T_SID_ID
)
AS
	v_data_found					BOOLEAN := FALSE;
	v_duration_id					meter_bucket.meter_bucket_id%TYPE;
	v_consumption_input_id			meter_input.meter_input_id%TYPE;
	v_cost_input_id					meter_input.meter_input_id%TYPE;
BEGIN
	-- Get the consumption and cost input ids
	SELECT meter_input_id
	  INTO v_consumption_input_id
	  FROM meter_input
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'CONSUMPTION';

	BEGIN
		SELECT meter_input_id
		  INTO v_cost_input_id
		  FROM meter_input
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND lookup_key = 'COST';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_cost_input_id := NULL;
	END;


	-- Get the "system period" duration to 
	-- query the live meter data table against
	BEGIN
		SELECT meter_bucket_id
		  INTO v_duration_id
		  FROM meter_bucket
		 WHERE IS_EXPORT_PERIOD = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_duration_id := NULL;
	END;

	IF in_region_sid IS NULL THEN
		-- if we're doing all then the v_data_found thing to clear out meters with empty 
		-- readings won't work, so just clear everything out.
		DELETE FROM meter_list_cache WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
	END IF;
	
	-- Update the cache.
	-- The first_reading_dtm and reading_count are for use by the REST API.
	FOR r IN (
		-- First and last meter reading values for point in time meters
		-- First and last consumption values for arbitrary period meters
		SELECT
			region_sid,
			-- XXX: Should the last reading date be the last sgtart date for arbitrary periods?
			-- This will use the last end date because that's the behaviour from before the
			-- reading data storage was refactored.
			FIRST_VALUE(NVL(end_dtm, start_dtm)) OVER (PARTITION BY region_sid ORDER BY start_dtm DESC) last_reading_dtm,
			FIRST_VALUE(entered_dtm) OVER (PARTITION BY region_sid ORDER BY start_dtm DESC) last_entered_dtm,
			FIRST_VALUE(val_number) OVER (PARTITION BY region_sid ORDER BY start_dtm DESC) val_number,
			FIRST_VALUE(cost) OVER (PARTITION BY region_sid ORDER BY start_dtm DESC) cost_number,
			FIRST_VALUE(entered_by_user_sid) OVER (PARTITION BY region_sid ORDER BY start_dtm DESC) read_by_sid,
			FIRST_VALUE(CASE WHEN day_interval > 0 THEN ROUND(consumption / day_interval, 2) ELSE 0 END) 
				   OVER (PARTITION BY region_sid ORDER BY start_dtm DESC) avg_consumption,
			NULL realtime_last_period,
			NULL realtime_consumption,
			LAST_VALUE(start_dtm) OVER (PARTITION BY region_sid ORDER BY start_dtm DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) first_reading_dtm,
			COUNT(*) OVER (PARTITION BY region_sid) reading_count
		  FROM (	
			SELECT
				mr.region_sid,
				start_dtm,
				end_dtm,
				entered_dtm,
				val_number,
				cost,
				mr.entered_by_user_sid,
				CASE WHEN st.arbitrary_period = 0 THEN
					val_number - LAG(val_number, 1, 0) OVER (PARTITION BY mr.region_sid ORDER BY start_dtm)
				ELSE
					val_number
				END consumption,
				CASE WHEN st.arbitrary_period = 0 THEN
					TRUNC(start_dtm,'dd') - TRUNC(LAG(start_dtm, 1, start_dtm) OVER (PARTITION BY m.region_sid ORDER BY start_dtm), 'dd')
				ELSE
					TRUNC(start_dtm,'dd') - TRUNC(end_dtm, 'dd')
				END day_interval
			  FROM region r, all_meter m, v$meter_reading mr, meter_source_type st
			 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND (r.region_type = csr_data_pkg.REGION_TYPE_METER
			     OR r.region_type = csr_data_pkg.REGION_TYPE_RATE
			   )
			   AND r.region_sid = m.region_sid
			   AND mr.region_sid = m.region_sid
			   AND st.app_sid = m.app_sid
			   AND m.meter_source_type_id = st.meter_source_type_id
			   AND m.urjanet_meter_id IS NULL -- non-urjanet meters
			   AND m.region_sid = NVL(in_region_sid, m.region_sid) -- if null, do all
		  )
		UNION
		-- Last meter_source_data entry for urjanet meters (can't use this for all real-time meters as finding the last reading just doesn't perform)
		SELECT region_sid, 
			MAX(last_reading_dtm) last_reading_dtm, 
			NULL last_entered_dtm, 
			MAX(val_number) val_number, 
			MAX(cost_number) cost_number,
			NULL read_by_sid, 
			MAX(avg_consumption) avg_consumption,
			NULL realtime_last_period,
			NULL realtime_consumption,
			MIN(first_reading_dtm) first_reading_dtm,
			MAX(reading_count) reading_count
		  FROM (	
			SELECT m.region_sid,
				CAST(FIRST_VALUE(msd.start_dtm) OVER (PARTITION BY m.region_sid ORDER BY msd.start_dtm DESC) AS DATE) last_reading_dtm,
				FIRST_VALUE(msd.raw_consumption) OVER (PARTITION BY m.region_sid ORDER BY msd.start_dtm DESC) val_number,
				NULL cost_number,
				NULL read_by_sid,
				FIRST_VALUE(CASE WHEN CAST(msd.end_dtm AS DATE) - CAST(msd.start_dtm AS DATE)  > 0 THEN ROUND(consumption / (CAST(msd.end_dtm AS DATE) - CAST(msd.start_dtm AS DATE)), 2) ELSE 0 END) OVER (PARTITION BY m.region_sid ORDER BY msd.start_dtm DESC) avg_consumption,
				CAST(LAST_VALUE(msd.start_dtm) OVER (PARTITION BY m.region_sid ORDER BY msd.start_dtm DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS DATE)first_reading_dtm,
				COUNT(*) OVER (PARTITION BY m.region_sid) reading_count
			  FROM meter_source_data msd
			  JOIN all_meter m on m.region_sid = msd.region_sid
			 WHERE msd.meter_input_id = v_consumption_input_id
			   AND m.urjanet_meter_id IS NOT NULL
			   AND m.region_sid = NVL(in_region_sid, m.region_sid) -- if null, do all
			UNION
			SELECT m.region_sid,
				CAST(FIRST_VALUE(msd.start_dtm) OVER (PARTITION BY m.region_sid ORDER BY msd.start_dtm DESC) AS DATE)last_reading_dtm,
				NULL val_number,
				FIRST_VALUE(msd.raw_consumption) OVER (PARTITION BY m.region_sid ORDER BY msd.start_dtm DESC) cost_number,
				NULL read_by_sid,
				NULL avg_consumption,
				CAST(LAST_VALUE(msd.start_dtm) OVER (PARTITION BY m.region_sid ORDER BY msd.start_dtm DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS DATE) first_reading_dtm,
				COUNT(*) OVER (PARTITION BY m.region_sid) reading_count
			  FROM meter_source_data msd
			  JOIN all_meter m on m.region_sid = msd.region_sid
			 WHERE msd.meter_input_id = v_cost_input_id
			   AND m.urjanet_meter_id IS NOT NULL
			   AND m.region_sid = NVL(in_region_sid, m.region_sid) -- if null, do all
		) GROUP BY region_sid
		UNION
		-- Last system period value for real-time meters (non-urjanet)
		SELECT
			m.region_sid, 
			NULL last_reading_dtm,
			NULL last_entered_dtm,
			NULL val_number,
			NULL cost_number,
			NULL read_by_sid,
			NULL avg_consumption,
			FIRST_VALUE(start_dtm) OVER (PARTITION BY rmr.region_sid ORDER BY start_dtm DESC) realtime_last_period,
			FIRST_VALUE(consumption) OVER (PARTITION BY rmr.region_sid ORDER BY start_dtm DESC) realtime_consumption,
			NULL first_reading_dtm,
			NULL reading_count
		  FROM region r, all_meter m, meter_live_data rmr
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r.region_type = csr_data_pkg.REGION_TYPE_REALTIME_METER
		   AND r.region_sid = m.region_sid
		   AND rmr.region_sid = m.region_sid
		   AND rmr.meter_bucket_id(+) = v_duration_id
		   AND m.urjanet_meter_id IS NULL -- non-urjanet meters
		   AND m.region_sid = NVL(in_region_sid, m.region_sid) -- if null, do all
	) LOOP
		BEGIN
			INSERT INTO meter_list_cache
				(region_sid, last_reading_dtm, entered_dtm, val_number, avg_consumption, cost_number, read_by_sid, realtime_last_period, realtime_consumption, first_reading_dtm, reading_count)
			  VALUES (r.region_sid, r.last_reading_dtm, r.last_entered_dtm, r.val_number, r.avg_consumption, r.cost_number, r.read_by_sid, r.realtime_last_period, r.realtime_consumption, r.first_reading_dtm, r.reading_count);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE meter_list_cache
				   SET last_reading_dtm = r.last_reading_dtm,
				       entered_dtm = r.last_entered_dtm,
				       val_number = r.val_number,
				       avg_consumption = r.avg_consumption,
				       cost_number = r.cost_number, 
				       read_by_sid = r.read_by_sid, 
				       realtime_last_period = r.realtime_last_period, 
				       realtime_consumption = r.realtime_consumption,
					   first_reading_dtm = r.first_reading_dtm,
					   reading_count = r.reading_count
				 WHERE region_sid = r.region_sid;
		END;	
		v_data_found := TRUE;			
	END LOOP;

	IF NOT v_data_found THEN
		-- nothing doing - must have been last reading
		DELETE FROM meter_list_cache
		 WHERE region_sid = in_region_sid;
	END IF;
END;

END temp_meter_pkg;
/
