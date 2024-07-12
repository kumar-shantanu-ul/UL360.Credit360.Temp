-- Please update version.sql too -- this keeps clean builds in sync
define version=986
@update_header


ALTER TABLE CSR.METER_LIST_CACHE ADD (
	ENTERED_DTM             DATE,
	AVG_CONSUMPTION         NUMBER(24, 10)	
);


SET SERVEROUTPUT ON
DECLARE
	v_duration_id		csr.live_data_duration.live_data_duration_id%TYPE;
BEGIN
	FOR h IN (
		-- Find any hosts that have meters
		SELECT DISTINCT host
		  FROM csr.customer cu, csr.all_meter m
		 WHERE cu.app_sid = m.app_sid
	) LOOP
		dbms_output.put_line('Processing '||h.host);
		security.user_pkg.logonadmin(h.host);
		
		-- Get the "system period" duration to 
		-- query the live meter data table against
		BEGIN
			SELECT live_data_duration_id
			  INTO v_duration_id
			  FROM csr.live_data_duration
			 WHERE is_system_period = 1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_duration_id := NULL;
		END;
		
		-- Update the cache
		FOR r IN (
			-- Last meter reading values for point in time meters
			SELECT
				region_sid,
				FIRST_VALUE(reading_dtm) OVER (PARTITION BY region_sid ORDER BY reading_dtm DESC) last_reading_dtm,
				FIRST_VALUE(entered_dtm) OVER (PARTITION BY region_sid ORDER BY reading_dtm DESC) last_entered_dtm,
				FIRST_VALUE(val_number) OVER (PARTITION BY region_sid ORDER BY reading_dtm DESC) val_number,
				FIRST_VALUE(cost) OVER (PARTITION BY region_sid ORDER BY reading_dtm DESC) cost_number,
				FIRST_VALUE(entered_by_user_sid) OVER (PARTITION BY region_sid ORDER BY reading_dtm DESC) read_by_sid,
				FIRST_VALUE(CASE WHEN day_interval > 0 THEN ROUND(consumption / day_interval, 2) ELSE 0 END) 
					   OVER (PARTITION BY region_sid ORDER BY reading_dtm DESC) avg_consumption,
				NULL realtime_last_period,
				NULL realtime_consumption
			  FROM (	
				SELECT
					mr.region_sid,
					reading_dtm,
					entered_dtm,
					val_number,
					cost,
					mr.entered_by_user_sid,
					val_number - LAG(val_number, 1, 0) OVER (PARTITION BY mr.region_sid ORDER BY reading_dtm) AS consumption,
					TRUNC(reading_dtm,'dd') - TRUNC(LAG(reading_dtm, 1, reading_dtm) OVER (PARTITION BY m.region_sid ORDER BY reading_dtm), 'dd') AS day_interval
				  FROM csr.region r, csr.all_meter m, csr.meter_reading mr, csr.meter_source_type st
				 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND (r.region_type = 1 --csr_data_pkg.REGION_TYPE_METER
				     OR r.region_type = 5 --csr_data_pkg.REGION_TYPE_RATE
				   )
				   AND r.region_sid = m.region_sid
				   AND mr.region_sid = m.region_sid
				   AND m.meter_source_type_id = st.meter_source_type_id
				   AND st.arbitrary_period = 0
			  )
			UNION
			-- Last consumption values for arbitrary period meters
			SELECT region_sid,
				MAX(last_reading_dtm) last_reading_dtm,
				MAX(last_entered_dtm) last_entered_dtm,
				MAX(DECODE (is_end, 1, val_number, NULL)) - MAX(DECODE (is_end, 0, val_number, NULL)) val_number,
				MAX(cost_number) cost_number,
				MAX(read_by_sid) read_by_sid,
				CASE WHEN MAX(DECODE (is_end, 1, last_reading_dtm, NULL)) - MAX(DECODE (is_end, 0, last_reading_dtm, NULL)) > 0 
				THEN
					ROUND((MAX(DECODE (is_end, 1, val_number, NULL)) - MAX(DECODE (is_end, 0, val_number, NULL))) / 
						(MAX(DECODE (is_end, 1, last_reading_dtm, NULL)) - MAX(DECODE (is_end, 0, last_reading_dtm, NULL))), 2) 
				ELSE 0 END avg_consumption,
				NULL realtime_last_period,
				NULL realtime_consumption
			  FROM (
				SELECT 1 is_end, m.region_sid,
					FIRST_VALUE(val_number) OVER (PARTITION BY mr.region_sid ORDER BY reading_dtm DESC) val_number,
					FIRST_VALUE(reading_dtm) OVER (PARTITION BY mr.region_sid ORDER BY reading_dtm DESC) last_reading_dtm,
					FIRST_VALUE(entered_dtm) OVER (PARTITION BY mr.region_sid ORDER BY reading_dtm DESC) last_entered_dtm,
					FIRST_VALUE(cost) OVER (PARTITION BY mr.region_sid ORDER BY reading_dtm DESC) cost_number,
					FIRST_VALUE(mr.entered_by_user_sid) OVER (PARTITION BY mr.region_sid ORDER BY reading_dtm DESC) read_by_sid
				  FROM csr.region r, csr.all_meter m, csr.meter_reading mr, csr.meter_source_type st, csr.meter_reading_period mrp		
				 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND (r.region_type = 1 --csr_data_pkg.REGION_TYPE_METER
				     OR r.region_type = 5 --csr_data_pkg.REGION_TYPE_RATE
				   )
				   AND r.region_sid = m.region_sid
				   AND mr.region_sid = m.region_sid
				   AND m.meter_source_type_id = st.meter_source_type_id
				   AND st.arbitrary_period = 1
				   AND mrp.end_id = mr.meter_reading_id
				UNION
				SELECT 0 is_end, m.region_sid,
					FIRST_VALUE(val_number) OVER (PARTITION BY mr.region_sid ORDER BY reading_dtm DESC) val_number,
					FIRST_VALUE(reading_dtm) OVER (PARTITION BY mr.region_sid ORDER BY reading_dtm DESC) last_reading_dtm,
					NULL last_entered_dtm,
					NULL cost_number,
					NULL read_by_sid
				  FROM csr.region r, csr.all_meter m, csr.meter_reading mr, csr.meter_source_type st, csr.meter_reading_period mrp		
				 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND (r.region_type = 1 --csr_data_pkg.REGION_TYPE_METER
				     OR r.region_type = 5 --csr_data_pkg.REGION_TYPE_RATE
				   )
				   AND r.region_sid = m.region_sid
				   AND mr.region_sid = m.region_sid
				   AND m.meter_source_type_id = st.meter_source_type_id
				   AND st.arbitrary_period = 1
				   AND mrp.start_id = mr.meter_reading_id
			) GROUP BY region_sid
			UNION
			-- Last system period value for real-time meters
			SELECT
				m.region_sid, 
				NULL last_reading_dtm,
				NULL last_entered_dtm,
				NULL val_number,
				NULL cost_number,
				NULL read_by_sid,
				NULL avg_consumption,
				FIRST_VALUE(start_dtm) OVER (PARTITION BY rmr.region_sid ORDER BY start_dtm DESC) realtime_last_period,
				FIRST_VALUE(consumption) OVER (PARTITION BY rmr.region_sid ORDER BY start_dtm DESC) realtime_consumption
			  FROM csr.region r, csr.all_meter m, csr.meter_live_data rmr	
			 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND r.region_type = 8 --csr_data_pkg.REGION_TYPE_REALTIME_METER
			   AND r.region_sid = m.region_sid
			   AND rmr.region_sid = m.region_sid
			   AND rmr.live_data_duration_id(+) = v_duration_id
		) LOOP
			BEGIN
				INSERT INTO csr.meter_list_cache
					(region_sid, last_reading_dtm, entered_dtm, val_number, avg_consumption, cost_number, read_by_sid, realtime_last_period, realtime_consumption)
				  VALUES (r.region_sid, r.last_reading_dtm, r.last_entered_dtm, r.val_number, r.avg_consumption, r.cost_number, r.read_by_sid, r.realtime_last_period, r.realtime_consumption);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE csr.meter_list_cache
					   SET last_reading_dtm = r.last_reading_dtm,
					       entered_dtm = r.last_entered_dtm,
					       val_number = r.val_number,
					       avg_consumption = r.avg_consumption,
					       cost_number = r.cost_number, 
					       read_by_sid = r.read_by_sid, 
					       realtime_last_period = r.realtime_last_period, 
					       realtime_consumption = r.realtime_consumption
					 WHERE region_sid = r.region_sid;
			END;				
		END LOOP;
		
		v_duration_id := NULL;
		security.user_pkg.logonadmin(NULL);
		
	END LOOP;
END;
/


@../meter_body

@update_tail
