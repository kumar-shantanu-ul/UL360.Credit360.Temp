-- Please update version.sql too -- this keeps clean builds in sync
define version=973
@update_header

CREATE TABLE CSR.METER_LIST_CACHE(
    APP_SID                 NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    REGION_SID              NUMBER(10, 0)     NOT NULL,
    LAST_READING_DTM        DATE,
    VAL_NUMBER              NUMBER(24, 10),
    COST_NUMBER             NUMBER(24, 10),
    READ_BY_SID             NUMBER(10, 0),
    REALTIME_LAST_PERIOD    DATE,
    REALTIME_CONSUMPTION    NUMBER(24, 10),
    CONSTRAINT PK1319 PRIMARY KEY (APP_SID, REGION_SID)
)
;

ALTER TABLE CSR.METER_LIST_CACHE ADD CONSTRAINT FK_ALLMETER_MLISTCACHE 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES CSR.ALL_METER(APP_SID, REGION_SID)
;

ALTER TABLE CSR.METER_LIST_CACHE ADD CONSTRAINT FK_CSRUSER_MLISTCACHE 
    FOREIGN KEY (APP_SID, READ_BY_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

CREATE INDEX CSR.IX_CSRUSER_MLISTCACHE ON CSR.METER_LIST_CACHE(APP_SID, READ_BY_SID);

BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'METER_LIST_CACHE',
		policy_name     => 'METER_LIST_CACHE_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/

@../meter_pkg
@../meter_body
@../meter_monitor_body

-- Fill in the meter list cache for the first time
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
			-- Last merter reading values for point in time meters
			SELECT
				m.region_sid,
				FIRST_VALUE(reading_dtm) OVER (PARTITION BY mr.region_sid ORDER BY reading_dtm DESC) last_reading_dtm,
				FIRST_VALUE(val_number) OVER (PARTITION BY mr.region_sid ORDER BY reading_dtm DESC) val_number,
				FIRST_VALUE(cost) OVER (PARTITION BY mr.region_sid ORDER BY reading_dtm DESC) cost_number,
				FIRST_VALUE(mr.entered_by_user_sid) OVER (PARTITION BY mr.region_sid ORDER BY reading_dtm DESC) read_by_sid,
				NULL realtime_last_period,
				NULL realtime_consumption
			  FROM csr.region r, csr.meter m, csr.meter_reading mr, csr.meter_source_type st
			 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND (r.region_type = 1 --csr_data_pkg.REGION_TYPE_METER
			     OR r.region_type = 5 --csr_data_pkg.REGION_TYPE_RATE
			   )
			   AND r.region_sid = m.region_sid
			   AND mr.region_sid = m.region_sid
			   AND m.meter_source_type_id = st.meter_source_type_id
			   AND st.arbitrary_period = 0
			UNION
			-- Last consumption values for arbitrary period meters
			SELECT region_sid,
				MAX(last_reading_dtm) last_reading_dtm,
				MAX(DECODE (is_end, 1, val_number, NULL)) - MAX(DECODE (is_end, 0, val_number, NULL)) val_number,
				MAX(cost_number) cost_number,
				MAX(read_by_sid) read_by_sid,
				NULL realtime_last_period,
				NULL realtime_consumption
			  FROM (
				SELECT 1 is_end, m.region_sid,
					FIRST_VALUE(val_number) OVER (PARTITION BY mr.region_sid ORDER BY reading_dtm DESC) val_number,
					FIRST_VALUE(reading_dtm) OVER (PARTITION BY mr.region_sid ORDER BY reading_dtm DESC) last_reading_dtm,
					FIRST_VALUE(cost) OVER (PARTITION BY mr.region_sid ORDER BY reading_dtm DESC) cost_number,
					FIRST_VALUE(mr.entered_by_user_sid) OVER (PARTITION BY mr.region_sid ORDER BY reading_dtm DESC) read_by_sid
				  FROM csr.region r, csr.meter m, csr.meter_reading mr, csr.meter_source_type st, csr.meter_reading_period mrp		
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
					NULL last_reading_dtm,
					NULL cost_number,
					NULL read_by_sid
				  FROM csr.region r, csr.meter m, csr.meter_reading mr, csr.meter_source_type st, csr.meter_reading_period mrp		
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
			-- Last system meriod value for real-time meters
			SELECT
				m.region_sid, 
				NULL last_reading_dtm,
				NULL val_number,
				NULL cost_number,
				NULL read_by_sid,
				FIRST_VALUE(start_dtm) OVER (PARTITION BY rmr.region_sid ORDER BY start_dtm DESC) realtime_last_period,
				FIRST_VALUE(consumption) OVER (PARTITION BY rmr.region_sid ORDER BY start_dtm DESC) realtime_consumption
			  FROM csr.region r, csr.meter m, csr.meter_live_data rmr	
			 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND r.region_type = 8 --csr_data_pkg.REGION_TYPE_REALTIME_METER
			   AND r.region_sid = m.region_sid
			   AND rmr.region_sid = m.region_sid
			   AND rmr.live_data_duration_id(+) = v_duration_id
		) LOOP
			BEGIN
				INSERT INTO csr.meter_list_cache
					(region_sid, last_reading_dtm, val_number, cost_number, read_by_sid, realtime_last_period, realtime_consumption)
				  VALUES (r.region_sid, r.last_reading_dtm, r.val_number, r.cost_number, r.read_by_sid, r.realtime_last_period, r.realtime_consumption);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE csr.meter_list_cache
					   SET last_reading_dtm = r.last_reading_dtm, 
					       val_number = r.val_number, 
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

@update_tail
