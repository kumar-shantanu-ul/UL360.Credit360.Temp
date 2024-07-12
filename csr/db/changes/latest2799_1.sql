-- Please update version.sql too -- this keeps clean builds in sync
define version=2799
define minor_version=1
define is_combined=0
@update_header


-- *** DDL ***
-- Create tables
DROP TABLE CSR.TEMP_METER_CONSUMPTION;
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_METER_CONSUMPTION(
	REGION_SID			NUMBER(10)			NOT NULL,
	PRIORITY			NUMBER(10)			NOT NULL,
	START_DTM			DATE				NOT NULL,
	END_DTM				DATE				NOT NULL,
	VAL_NUMBER			NUMBER(24, 10),
	PER_DIEM			NUMBER(24, 10),
	RAW_DATA_ID			NUMBER(10)
) ON COMMIT DELETE ROWS;

DROP TABLE CSR.METER_INSERT_DATA;
CREATE GLOBAL TEMPORARY TABLE CSR.METER_INSERT_DATA 
(
	METER_INPUT_ID		NUMBER(10)					NOT NULL,
	START_DTM   		TIMESTAMP WITH TIME ZONE	NOT NULL,
	END_DTM     		TIMESTAMP WITH TIME ZONE,
	CONSUMPTION 		NUMBER(24,10)
)
ON COMMIT DELETE ROWS;

DROP TABLE CSR.TEMP_METER_CONSUMPTION;
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_METER_CONSUMPTION(
	REGION_SID			NUMBER(10)			NOT NULL,
	METER_INPUT_ID		NUMBER(10)			NOT NULL,
	PRIORITY			NUMBER(10)			NOT NULL,
	START_DTM			DATE				NOT NULL,
	END_DTM				DATE				NOT NULL,
	VAL_NUMBER			NUMBER(24, 10),
	PER_DIEM			NUMBER(24, 10),
	RAW_DATA_ID			NUMBER(10)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_METER_GAPS(
	REGION_SID				NUMBER(10)		NOT NULL,
	METER_INPUT_ID			NUMBER(10)		NOT NULL,
	START_DTM				DATE			NOT NULL,
	END_DTM					DATE			NOT NULL
) ON COMMIT DELETE ROWS;


CREATE TABLE CSR.METER_DATA_PRIORITY(
	APP_SID				NUMBER(10, 0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	PRIORITY			NUMBER(10, 0)		NOT NULL,
	LABEL				VARCHAR2(1024)		NOT NULL,
	LOOKUP_KEY			VARCHAR2(256),
	IS_INPUT			NUMBER(1, 0)		DEFAULT 0 NOT NULL,
	IS_OUTPUT			NUMBER(1, 0)		DEFAULT 0 NOT NULL,
	IS_PATCH			NUMBER(1, 0)		DEFAULT 0 NOT NULL,
	IS_AUTO_PATCH		NUMBER(1, 0)		DEFAULT 0 NOT NULL,
	CHECK (IS_INPUT IN(0,1)),
	CHECK (IS_OUTPUT IN(0,1)),
	CHECK (IS_PATCH IN(0,1)),
	CHECK (IS_AUTO_PATCH IN(0,1)),
	CONSTRAINT PK_METER_DATA_PRIORITY PRIMARY KEY (APP_SID, PRIORITY)
);

CREATE TABLE CSR.METER_PATCH_DATA(
	APP_SID				NUMBER(10, 0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	REGION_SID			NUMBER(10, 0)		NOT NULL,
	METER_INPUT_ID		NUMBER(10, 0)		NOT NULL,
	PRIORITY			NUMBER(10, 0)		NOT NULL,
	START_DTM			DATE				NOT NULL,
	END_DTM				DATE				NOT NULL,
	CONSUMPTION			NUMBER(24, 10),
	UPDATED_DTM			DATE				DEFAULT SYSDATE NOT NULL,
	CONSTRAINT PK_METER_PATCH_DATA PRIMARY KEY (APP_SID, REGION_SID, METER_INPUT_ID, PRIORITY, START_DTM)
);

CREATE TABLE CSR.METER_AGGREGATOR(
	AGGREGATOR			VARCHAR2(32)		NOT NULL,
	LABEL				VARCHAR2(256)		NOT NULL,
	AGGR_PROC			VARCHAR2(256)		NOT NULL,
	CONSTRAINT PK_METER_AGGREGATOR PRIMARY KEY (AGGREGATOR)
);

CREATE TABLE CSR.METER_INPUT(
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	METER_INPUT_ID			NUMBER(10, 0)	NOT NULL,
	LABEL					VARCHAR2(1024)	NOT NULL,
	LOOKUP_KEY				VARCHAR2(256)	NOT NULL,
	IS_CONSUMPTION_BASED	NUMBER(1, 0)	DEFAULT 1 NOT NULL,
	PATCH_HELPER			VARCHAR2(256),
	GAP_FINDER				VARCHAR2(256),
	CHECK (IS_CONSUMPTION_BASED IN(0,1)),
	CONSTRAINT PK_METER_INPUT PRIMARY KEY (APP_SID, METER_INPUT_ID)
);
CREATE UNIQUE INDEX CSR.UK_INPUT_LOOKUP_KEY ON CSR.METER_INPUT(APP_SID, LOOKUP_KEY);

CREATE TABLE CSR.METER_INPUT_AGGR_IND(
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	REGION_SID				NUMBER(10, 0)	NOT NULL,
	METER_INPUT_ID			NUMBER(10, 0)	NOT NULL,
	AGGREGATOR				VARCHAR2(32)	NOT NULL,
	IND_SID					NUMBER(10, 0),
	MEASURE_SID				NUMBER(10, 0),
	MEASURE_CONVERSION_ID	NUMBER(10, 0),
	CONSTRAINT PK_METER_INPUT_AGGR_IND PRIMARY KEY (APP_SID, REGION_SID, METER_INPUT_ID, AGGREGATOR)
);

CREATE TABLE CSR.METER_INPUT_AGGREGATOR(
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	METER_INPUT_ID			NUMBER(10, 0)	NOT NULL,
	AGGREGATOR				VARCHAR2(32)	NOT NULL,
	AGGR_PROC				VARCHAR2(256),
	CONSTRAINT PK_METER_INPUT_AGGREGATOR PRIMARY KEY (APP_SID, METER_INPUT_ID, AGGREGATOR)
);


CREATE TABLE CSR.METER_PATCH_JOB(
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	REGION_SID				NUMBER(10, 0)	NOT NULL,
	METER_INPUT_ID			NUMBER(10, 0)	NOT NULL,
	START_DTM				DATE			NOT NULL,
	END_DTM					DATE			NOT NULL,
	CREATED_DTM				DATE			DEFAULT SYSDATE NOT NULL,
	CONSTRAINT PK_METER_PATCH_JOB PRIMARY KEY (APP_SID, REGION_SID, METER_INPUT_ID)
);

CREATE TABLE CSR.METER_PATCH_BATCH_JOB(
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	BATCH_JOB_ID			NUMBER(10, 0)	NOT NULL,
	REGION_SID				NUMBER(10, 0)	NOT NULL,
	IS_REMOVE				NUMBER(1, 0)	DEFAULT 0,
	CREATED_DTM				DATE			DEFAULT SYSDATE NOT NULL,
	CHECK(IS_REMOVE IN (0,1)),
	CONSTRAINT PK_METER_PATCH_BATCH_JOB PRIMARY KEY (APP_SID, BATCH_JOB_ID)
);

CREATE TABLE CSR.METER_PATCH_BATCH_DATA(
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	BATCH_JOB_ID			NUMBER(10, 0)	NOT NULL,
	METER_INPUT_ID			NUMBER(10, 0)	NOT NULL,
	PRIORITY				NUMBER(10, 0)	NOT NULL,
	START_DTM				DATE			NOT NULL,
	END_DTM					DATE			NOT NULL,
	PERIOD_TYPE				VARCHAR2(32),
	CONSUMPTION				NUMBER(24, 10),
	CONSTRAINT PK_METER_PATCH_BATCH_DATA PRIMARY KEY (APP_SID, BATCH_JOB_ID, METER_INPUT_ID, PRIORITY, START_DTM)
);

CREATE TABLE CSR.METER_DATA_COVERAGE_IND(
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	METER_INPUT_ID			NUMBER(10, 0)	NOT NULL,
	PRIORITY				NUMBER(10, 0)	NOT NULL,
	IND_SID					NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_METER_DATA_COVERAGE_IND PRIMARY KEY (APP_SID, METER_INPUT_ID, PRIORITY)
);

-- Alter sequence
-- Can't simply rename a sequence
DECLARE
	v_next_seq		NUMBER;
BEGIN
	SELECT csr.live_data_duration_id_seq.NEXTVAL
	  INTO v_next_seq
	  FROM DUAL;
	EXECUTE IMMEDIATE('CREATE SEQUENCE CSR.METER_BUCKET_ID_SEQ START WITH '||v_next_seq||' INCREMENT BY 1 NOMINVALUE NOMAXVALUE CACHE 20 NOORDER');
END;
/
DROP SEQUENCE CSR.LIVE_DATA_DURATION_ID_SEQ;

-- Alter tables
ALTER TABLE CSR.LIVE_DATA_DURATION RENAME TO METER_BUCKET;

DECLARE
	v_cons_name		VARCHAR2(30);
BEGIN
	-- Find the name of the primary key
	SELECT constraint_name
	  INTO v_cons_name
	  FROM all_constraints
	 WHERE owner = 'CSR'
	   AND table_name = 'METER_BUCKET'
	   AND constraint_type = 'P';
	
	-- Drop the primary key
	EXECUTE IMMEDIATE('ALTER TABLE CSR.METER_BUCKET RENAME CONSTRAINT  '||v_cons_name|| ' TO PK_METER_BUCKET');
END;
/

ALTER TABLE CSR.METER_BUCKET RENAME COLUMN IS_SYSTEM_PERIOD TO IS_EXPORT_PERIOD;
ALTER TABLE CSR.METER_BUCKET RENAME COLUMN LIVE_DATA_DURATION_ID TO METER_BUCKET_ID;
ALTER TABLE CSR.METER_LIVE_DATA RENAME COLUMN LIVE_DATA_DURATION_ID TO METER_BUCKET_ID;

BEGIN
	-- Remove existing check constraints
	FOR r IN (
		SELECT constraint_name
		  FROM all_constraints
		 WHERE owner = 'CSR'
		   AND table_name = 'METER_BUCKET'
		   AND constraint_type = 'C'
	) LOOP
		EXECUTE IMMEDIATE('ALTER TABLE CSR.METER_BUCKET DROP CONSTRAINT  '||r.constraint_name);
	END LOOP;
END;
/

ALTER TABLE CSR.METER_BUCKET ADD(
	PERIOD_SET_ID			NUMBER(10),
	PERIOD_INTERVAL_ID		NUMBER(10),
	HIGH_RESOLUTION_ONLY	NUMBER(1) DEFAULT 0 NOT NULL,
	CHECK (IS_HOURS = 0 OR (IS_HOURS  = 1 AND IS_MINUTES = 0 AND IS_WEEKS = 0 AND IS_MONTHS = 0 AND PERIOD_SET_ID IS NULL AND PERIOD_INTERVAL_ID IS NULL)),
	CHECK (IS_WEEKS = 0 OR (IS_WEEKS = 1 AND IS_MINUTES = 0 AND IS_HOURS = 0 AND IS_MONTHS = 0 AND PERIOD_SET_ID IS NULL AND PERIOD_INTERVAL_ID IS NULL)),
	CHECK (IS_MINUTES = 0 OR (IS_MINUTES  = 1 AND IS_HOURS = 0 AND IS_WEEKS = 0 AND IS_MONTHS = 0 AND PERIOD_SET_ID IS NULL AND PERIOD_INTERVAL_ID IS NULL)),
	CHECK (WEEK_START_DAY IS NULL OR IS_WEEKS = 1),
	CHECK (START_MONTH IS NULL OR IS_MONTHS = 1),
	CHECK ((PERIOD_SET_ID IS NULL AND PERIOD_INTERVAL_ID IS NULL) OR (PERIOD_SET_ID IS NOT NULL AND PERIOD_INTERVAL_ID IS NOT NULL AND IS_MINUTES = 0 AND IS_HOURS = 0 AND IS_WEEKS = 0)),
	CHECK (HIGH_RESOLUTION_ONLY IN (0,1))
);

BEGIN
	-- All export buckets must have period set and interval
	UPDATE csr.meter_bucket
	   SET period_set_id = 1,
	       period_interval_id = 1
	 WHERE is_export_period = 1
	   AND period_set_id IS NULL;
END;
/

ALTER TABLE CSR.METER_BUCKET ADD(
	CHECK (IS_MONTHS = 0 OR (IS_MONTHS = 1 AND IS_MINUTES = 0 AND IS_HOURS = 0 AND IS_WEEKS = 0 AND (IS_EXPORT_PERIOD = 0 OR (PERIOD_SET_ID = 1 AND PERIOD_INTERVAL_ID = 1)))),
	CHECK (IS_EXPORT_PERIOD IN (0,1) AND (IS_EXPORT_PERIOD = 0 OR (PERIOD_SET_ID IS NOT NULL AND PERIOD_INTERVAL_ID IS NOT NULL)))
);


ALTER TABLE CSR.METER_ORPHAN_DATA ADD(
	METER_INPUT_ID			NUMBER(10, 0),
	PRIORITY				NUMBER(10)
);

ALTER TABLE CSR.METER_READING_DATA ADD(
	METER_INPUT_ID			NUMBER(10, 0),
	PRIORITY				NUMBER(10)
);

ALTER TABLE CSR.METER_SOURCE_DATA ADD(
	METER_INPUT_ID			NUMBER(10, 0),
	PRIORITY				NUMBER(10)
);

ALTER TABLE CSR.METER_LIVE_DATA ADD(
	METER_INPUT_ID			NUMBER(10, 0),
	AGGREGATOR				VARCHAR2(32),
	PRIORITY				NUMBER(10, 0)
);

ALTER TABLE CSR.METER_ALARM_STATISTIC ADD (
	METER_INPUT_ID			NUMBER(10, 0),
	AGGREGATOR				VARCHAR2(32),
	METER_BUCKET_ID			NUMBER(10),
	ALL_METERS				NUMBER(1)		DEFAULT 0 NOT NULL,
	NOT_BEFORE_DTM			DATE,
	LOOKUP_KEY				VARCHAR2(256),
	CHECK(ALL_METERS IN(0,1))
);

CREATE UNIQUE INDEX CSR.UK_LOOKUP_KEY ON CSR.METER_ALARM_STATISTIC(APP_SID, NVL(LOOKUP_KEY, STATISTIC_ID));

DECLARE
	v_bucket_id				csr.meter_bucket.meter_bucket_id%TYPE;
BEGIN
	-- Aggregator types
	INSERT INTO csr.meter_aggregator(aggregator, label, aggr_proc) VALUES ('SUM', 'Sum', 'csr.meter_aggr_pkg.Sum');
	INSERT INTO csr.meter_aggregator(aggregator, label, aggr_proc) VALUES ('AVERAGE', 'Average', 'csr.meter_aggr_pkg.Average');
	
	FOR a IN (
		SELECT app_sid
		  FROM csr.meter_source_type
		UNION
		SELECT app_sid
		  FROM csr.meter_live_data
		UNION
		SELECT app_sid
		  FROM csr.meter_orphan_data
		UNION
		SELECT app_sid
		  FROM csr.meter_patch_data
		UNION
		SELECT app_sid
		  FROM csr.meter_reading_data
		UNION
		SELECT app_sid
		  FROM csr.meter_source_data
	) LOOP
		-- Input types
		INSERT INTO csr.meter_input (app_sid, meter_input_id, label, lookup_key, is_consumption_based) VALUES (a.app_sid, 1, 'Consumption', 'CONSUMPTION', 1);
		INSERT INTO csr.meter_input (app_sid, meter_input_id, label, lookup_key, is_consumption_based) VALUES (a.app_sid, 2, 'Cost','COST', 1);
		
		-- Input -> aggregator type mappings
		INSERT INTO csr.meter_input_aggregator(app_sid, meter_input_id, aggregator) VALUES(a.app_sid, 1, 'SUM');
		INSERT INTO csr.meter_input_aggregator(app_sid, meter_input_id, aggregator) VALUES(a.app_sid, 2, 'SUM');
		
		-- Meter consumption indicators
		INSERT INTO csr.meter_input_aggr_ind (app_sid, region_sid, meter_input_id, aggregator, ind_sid, measure_sid, measure_conversion_id)
			SELECT m.app_sid, m.region_sid, 1, 'SUM', m.primary_ind_sid, i.measure_sid, m.primary_measure_conversion_id
			  FROM csr.all_meter m
			  JOIN csr.ind i ON i.app_sid = m.app_sid AND i.ind_sid = m.primary_ind_sid
			 WHERE m.app_sid = a.app_sid;
			 
		-- Meter cost indicators
		INSERT INTO csr.meter_input_aggr_ind (app_sid, region_sid, meter_input_id, aggregator, ind_sid, measure_sid, measure_conversion_id)
			SELECT m.app_sid, m.region_sid, 2, 'SUM', m.cost_ind_sid, i.measure_sid, m.cost_measure_conversion_id
			  FROM csr.all_meter m
			  JOIN csr.ind i ON i.app_sid = m.app_sid AND i.ind_sid = m.cost_ind_sid
			 WHERE m.app_sid = a.app_sid;

		-- Patch prority
		INSERT INTO csr.meter_data_priority (app_sid, priority, label, lookup_key, is_input, is_output, is_patch, is_auto_patch) VALUES (a.app_sid, 1, 'Auto pathcer', 'AUTO', 1, 0, 0, 1);
		INSERT INTO csr.meter_data_priority (app_sid, priority, label, lookup_key, is_input, is_output, is_patch, is_auto_patch) VALUES (a.app_sid, 2, 'Low resolution', 'LO_RES', 1, 0, 0, 0);
		INSERT INTO csr.meter_data_priority (app_sid, priority, label, lookup_key, is_input, is_output, is_patch, is_auto_patch) VALUES (a.app_sid, 3, 'High resolution', 'HI_RES', 1, 0, 0, 0);
		INSERT INTO csr.meter_data_priority (app_sid, priority, label, lookup_key, is_input, is_output, is_patch, is_auto_patch) VALUES (a.app_sid, 4, 'User patch', 'PATCH_01', 0, 0, 1, 0);
		INSERT INTO csr.meter_data_priority (app_sid, priority, label, lookup_key, is_input, is_output, is_patch, is_auto_patch) VALUES (a.app_sid, 100, 'Patched output', 'OUTPUT', 0, 1, 0, 0);
 
	END LOOP;

	UPDATE csr.meter_orphan_data
	   SET meter_input_id = 1,
		   priority = 3; -- Before the update all data in this table is real-time
			   
	UPDATE csr.meter_reading_data
	   SET meter_input_id = 1,
		   priority = 3; -- Before the update all data in this table is real-time
	   
	UPDATE csr.meter_source_data
	   SET meter_input_id = 1,
		   priority = 3; -- Before the update all data in this table is real-time
	
	UPDATE csr.meter_live_data
	   SET meter_input_id = 1,
		   aggregator = 'SUM',
		   priority = 3; -- Before the update all data in this table is real-time

	UPDATE csr.meter_alarm_statistic
	   SET meter_input_id = 1,
	   aggregator = 'SUM';

	-- Stats that use daily buckets
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM csr.meter_alarm_Statistic
	) LOOP
		BEGIN
			SELECT meter_bucket_id
			  INTO v_bucket_id
			  FROM csr.meter_bucket
			 WHERE app_sid = r.app_sid
			   AND is_hours = 1
			   AND duration = 24;
			   
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				INSERT INTO csr.meter_bucket (app_sid, meter_bucket_id, description, duration, is_hours)
				  VALUES (r.app_sid, csr.meter_bucket_id_seq.NEXTVAL, 'Daily', 24, 1)
				  RETURNING meter_bucket_id INTO v_bucket_id;
		END;
		
		-- Set the bucket id
		UPDATE csr.meter_alarm_statistic
		   SET meter_bucket_id = v_bucket_id
		 WHERE app_sid = r.app_sid
		   AND LOWER(comp_proc) NOT IN (
			'meter_alarm_stat_pkg.computewkgdaycoreavg',
			'meter_alarm_stat_pkg.computewkgdaycore',
			'meter_alarm_stat_pkg.computewkgdaynoncoreavg',
			'meter_alarm_stat_pkg.computewkgdaynoncore',
			'csr.meter_alarm_stat_pkg.computewkgdaycoreavg',
			'csr.meter_alarm_stat_pkg.computewkgdaycore',
			'csr.meter_alarm_stat_pkg.computewkgdaynoncoreavg',
			'csr.meter_alarm_stat_pkg.computewkgdaynoncore'
		);
	END LOOP;
	
	-- Stats that use hourly buckets
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM csr.meter_alarm_statistic
	) LOOP
		BEGIN
			-- Most existing stats use a daily bucket
			SELECT meter_bucket_id
			  INTO v_bucket_id
			  FROM csr.meter_bucket
			 WHERE app_sid = r.app_sid
			   AND is_hours = 1
			   AND duration = 1;
			   
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				INSERT INTO csr.meter_bucket (app_sid, meter_bucket_id, description, duration, is_hours)
				  VALUES (r.app_sid, csr.meter_bucket_id_seq.NEXTVAL, 'Hourly', 1, 1)
				  RETURNING meter_bucket_id INTO v_bucket_id;
		END;
		
		-- Set the bucket id
		UPDATE csr.meter_alarm_statistic
		   SET meter_bucket_id = v_bucket_id
		 WHERE app_sid = r.app_sid
		   AND LOWER(comp_proc) IN (
			'meter_alarm_stat_pkg.computewkgdaycoreavg',
			'meter_alarm_stat_pkg.computewkgdaycore',
			'meter_alarm_stat_pkg.computewkgdaynoncoreavg',
			'meter_alarm_stat_pkg.computewkgdaynoncore',
			'csr.meter_alarm_stat_pkg.computewkgdaycoreavg',
			'csr.meter_alarm_stat_pkg.computewkgdaycore',
			'csr.meter_alarm_stat_pkg.computewkgdaynoncoreavg',
			'csr.meter_alarm_stat_pkg.computewkgdaynoncore'
		);
		   
		-- Set lookup keys for day averages
		UPDATE csr.meter_alarm_statistic
		   SET lookup_key = 'MONDAY_AVG'
		 WHERE app_sid = r.app_sid
		   AND LOWER(comp_proc) IN (
			'meter_alarm_stat_pkg.computeavgmondayusage',
			'csr.meter_alarm_stat_pkg.computeavgmondayusage'
		 );
		   
		UPDATE csr.meter_alarm_statistic
		   SET lookup_key = 'TUESDAY_AVG'
		 WHERE app_sid = r.app_sid
		   AND LOWER(comp_proc) IN (
			'meter_alarm_stat_pkg.computeavgtuesdayusage',
			'csr.meter_alarm_stat_pkg.computeavgtuesdayusage'
		 );
		
		UPDATE csr.meter_alarm_statistic
		   SET lookup_key = 'WEDNESDAY_AVG'
		 WHERE app_sid = r.app_sid
		   AND LOWER(comp_proc) IN (
			'meter_alarm_stat_pkg.computeavgwednesdayusage',
			'csr.meter_alarm_stat_pkg.computeavgwednesdayusage'
		 );
		   
		UPDATE csr.meter_alarm_statistic
		   SET lookup_key = 'THURSDAY_AVG'
		 WHERE app_sid = r.app_sid
		   AND LOWER(comp_proc) IN (
			'meter_alarm_stat_pkg.computeavgthursdayusage',
			'csr.meter_alarm_stat_pkg.computeavgthursdayusage'
		 );
		   
		UPDATE csr.meter_alarm_statistic
		   SET lookup_key = 'FRIDAY_AVG'
		 WHERE app_sid = r.app_sid
		   AND LOWER(comp_proc) IN (
			'meter_alarm_stat_pkg.computeavgfridayusage',
			'csr.meter_alarm_stat_pkg.computeavgfridayusage'
		 );
		   
		UPDATE csr.meter_alarm_statistic
		   SET lookup_key = 'SATURDAY_AVG'
		 WHERE app_sid = r.app_sid
		   AND LOWER(comp_proc) IN (
			'meter_alarm_stat_pkg.computeavgsaturdayusage',
			'csr.meter_alarm_stat_pkg.computeavgsaturdayusage'
		 );
		   
		UPDATE csr.meter_alarm_statistic
		   SET lookup_key = 'SUNDAY_AVG'
		 WHERE app_sid = r.app_sid
		   AND LOWER(comp_proc) IN (
			'meter_alarm_stat_pkg.computeavgsundayusage',
			'csr.meter_alarm_stat_pkg.computeavgsundayusage'
		 );
	END LOOP;
END;
/

ALTER TABLE CSR.METER_ORPHAN_DATA MODIFY(
	METER_INPUT_ID			NUMBER(10, 0)	NOT NULL,
	PRIORITY				NUMBER(10, 0)	NOT NULL
);
DROP INDEX CSR.UK_METER_ORPHAN_DATA;
CREATE UNIQUE INDEX CSR.UK_METER_ORPHAN_DATA ON CSR.METER_ORPHAN_DATA(APP_SID, SERIAL_ID, METER_INPUT_ID, PRIORITY, START_DTM);

ALTER TABLE CSR.METER_READING_DATA MODIFY(
	METER_INPUT_ID			NUMBER(10, 0)	NOT NULL,
	PRIORITY				NUMBER(10, 0)	NOT NULL
);
DROP INDEX CSR.UK_METER_READING_DATA;
CREATE UNIQUE INDEX CSR.UK_METER_READING_DATA ON CSR.METER_READING_DATA(APP_SID, REGION_SID, METER_INPUT_ID, PRIORITY, READING_DTM);


ALTER TABLE CSR.METER_SOURCE_DATA MODIFY(
	METER_INPUT_ID			NUMBER(10, 0)	NOT NULL,
	PRIORITY				NUMBER(10, 0)	NOT NULL
);
DROP INDEX CSR.UK_METER_SOURCE_DATA;
CREATE UNIQUE INDEX CSR.UK_METER_SOURCE_DATA ON CSR.METER_SOURCE_DATA(APP_SID, REGION_SID, METER_INPUT_ID, PRIORITY, START_DTM);



BEGIN
	-- Remove existing PK
	FOR r IN (
		SELECT constraint_name
		  FROM all_constraints
		 WHERE owner = 'CSR'
		   AND table_name = 'METER_LIVE_DATA'
		   AND constraint_type = 'P'
	) LOOP
		EXECUTE IMMEDIATE('ALTER TABLE CSR.METER_LIVE_DATA DROP CONSTRAINT  '||r.constraint_name);
	END LOOP;
END;
/
ALTER TABLE CSR.METER_LIVE_DATA MODIFY(
	METER_INPUT_ID			NUMBER(10, 0)	NOT NULL,
	AGGREGATOR				VARCHAR2(32)	NOT NULL,
	PRIORITY				NUMBER(10)		NOT NULL
);
ALTER TABLE CSR.METER_LIVE_DATA ADD(
	CONSTRAINT PK_METER_LIVE_DATA PRIMARY KEY (APP_SID, REGION_SID, METER_BUCKET_ID, METER_INPUT_ID, AGGREGATOR, PRIORITY, START_DTM)
);

ALTER TABLE CSR.METER_ALARM_STATISTIC MODIFY (
	METER_INPUT_ID			NUMBER(10, 0)	NOT NULL,
	AGGREGATOR				VARCHAR2(32)	NOT NULL,
	METER_BUCKET_ID			NUMBER(10, 0)	NOT NULL
);

ALTER TABLE CSR.METER_READING_DATA ADD (
	VAL						NUMBER(24, 10)
);

ALTER TABLE CSR.METER_ALARM_STATISTIC_JOB ADD (
	START_DTM				DATE	NULL,
	END_DTM					DATE	NULL
);

DECLARE
	v_start_dtm				DATE;
	v_end_dtm				DATE;
BEGIN
	FOR r IN (
		SELECT j.app_sid, j.region_sid, j.statistic_id, s.meter_bucket_id
		  FROM csr.meter_alarm_statistic_job j
		  JOIN csr.meter_alarm_statistic s ON s.app_sid = j.app_sid AND s.statistic_id = j.statistic_id
			ORDER BY app_sid
	) LOOP
		
		-- Start date (last statistic data point)
		BEGIN
			SELECT MAX(statistic_dtm)
			  INTO v_start_dtm
			  FROM csr.meter_alarm_statistic_period
			 WHERE app_sid = r.app_sid
			   AND region_sid = r.region_sid
			   AND statistic_id = r.statistic_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_start_dtm := NULL;
		END;
		
		-- End date (last bucketed data point > last statistic data point)
		BEGIN
			SELECT NVL(v_start_dtm, MIN(start_dtm)), MAX(start_dtm)
			  INTO v_start_dtm, v_end_dtm
			  FROM csr.meter_live_data
			 WHERE app_sid = r.app_sid
			   AND region_sid = r.region_sid
			   AND meter_bucket_id = r.meter_bucket_id
			   AND start_dtm >= NVL(v_start_dtm, start_dtm);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_start_dtm := NULL;
				v_end_dtm := NULL;
		END;		
		
		-- If we have valid dates then update the job
		IF v_start_dtm IS NOT NULL AND v_end_dtm IS NOT NULL THEN
			UPDATE csr.meter_alarm_statistic_job
			   SET start_dtm = v_start_dtm,
				   end_dtm = v_end_dtm
			 WHERE app_sid = r.app_sid
			   AND region_sid = r.region_sid
			   AND statistic_id = r.statistic_id;
		ELSE
			-- No valid dates, so no data, just remove the job
			DELETE FROM csr.meter_alarm_statistic_job
			 WHERE app_sid = r.app_sid
			   AND region_sid = r.region_sid
			   AND statistic_id = r.statistic_id;
		END IF;	
	END LOOP;
END;
/

ALTER TABLE CSR.METER_ALARM_STATISTIC_JOB MODIFY (
	START_DTM				DATE	NOT NULL,
	END_DTM					DATE	NOT NULL
);

ALTER TABLE CSR.METER_SOURCE_TYPE ADD (
	AUTO_PATCH				NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	CHECK (AUTO_PATCH IN(0,1))
);

-- FKs

ALTER TABLE CSR.METER_DATA_PRIORITY ADD CONSTRAINT FK_CUSTOMER_MDPRIORITY 
	FOREIGN KEY (APP_SID)
	REFERENCES CSR.CUSTOMER(APP_SID)
;

ALTER TABLE CSR.METER_ORPHAN_DATA ADD CONSTRAINT FK_MDPRIORITY_MORPHAN 
	FOREIGN KEY (APP_SID, PRIORITY)
	REFERENCES CSR.METER_DATA_PRIORITY(APP_SID, PRIORITY)
;

ALTER TABLE CSR.METER_READING_DATA ADD CONSTRAINT FK_MDPRIORITY_MREADING 
	FOREIGN KEY (APP_SID, PRIORITY)
	REFERENCES CSR.METER_DATA_PRIORITY(APP_SID, PRIORITY)
;

ALTER TABLE CSR.METER_SOURCE_DATA ADD CONSTRAINT FK_MDPRIORITY_MSOURCE 
	FOREIGN KEY (APP_SID, PRIORITY)
	REFERENCES CSR.METER_DATA_PRIORITY(APP_SID, PRIORITY)
;

ALTER TABLE CSR.METER_INPUT ADD CONSTRAINT FK_CUSTOMER_METIMP
	FOREIGN KEY (APP_SID)
	REFERENCES CSR.CUSTOMER(APP_SID)
;

ALTER TABLE CSR.METER_INPUT_AGGR_IND ADD CONSTRAINT FK_AMETER_METINPAGGIND
	FOREIGN KEY (APP_SID, REGION_SID)
	REFERENCES CSR.ALL_METER(APP_SID, REGION_SID)
;

ALTER TABLE CSR.METER_INPUT_AGGR_IND ADD CONSTRAINT FK_IND_METERINPAGGRIND 
	FOREIGN KEY (APP_SID, IND_SID, MEASURE_SID)
	REFERENCES CSR.IND(APP_SID, IND_SID, MEASURE_SID)
;

ALTER TABLE CSR.METER_INPUT_AGGR_IND ADD CONSTRAINT FK_MESCONV_METINPAGGRIND 
	FOREIGN KEY (APP_SID, MEASURE_CONVERSION_ID, MEASURE_SID)
	REFERENCES CSR.MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID, MEASURE_SID)
;

ALTER TABLE CSR.METER_INPUT_AGGR_IND ADD CONSTRAINT FK_METINPAGGR_METINPAGRIND
	FOREIGN KEY (APP_SID, METER_INPUT_ID, AGGREGATOR)
	REFERENCES CSR.METER_INPUT_AGGREGATOR(APP_SID, METER_INPUT_ID, AGGREGATOR)
;

ALTER TABLE CSR.METER_INPUT_AGGREGATOR ADD CONSTRAINT FK_METAGG_METINPAGG
	FOREIGN KEY (AGGREGATOR)
	REFERENCES CSR.METER_AGGREGATOR(AGGREGATOR)
;

ALTER TABLE CSR.METER_INPUT_AGGREGATOR ADD CONSTRAINT FK_METIMP_METIMPAGG
	FOREIGN KEY (APP_SID, METER_INPUT_ID)
	REFERENCES CSR.METER_INPUT(APP_SID, METER_INPUT_ID)
;

ALTER TABLE CSR.METER_LIVE_DATA ADD CONSTRAINT FK_METIMPAGG_METLIVDAT
	FOREIGN KEY (APP_SID, METER_INPUT_ID, AGGREGATOR)
	REFERENCES CSR.METER_INPUT_AGGREGATOR(APP_SID, METER_INPUT_ID, AGGREGATOR)
;

ALTER TABLE CSR.METER_ORPHAN_DATA ADD CONSTRAINT FK_METIMP_METORPDAT
	FOREIGN KEY (APP_SID, METER_INPUT_ID)
	REFERENCES CSR.METER_INPUT(APP_SID, METER_INPUT_ID)
;

ALTER TABLE CSR.METER_PATCH_DATA ADD CONSTRAINT FK_METIMP_METPATDAT
	FOREIGN KEY (APP_SID, METER_INPUT_ID)
	REFERENCES CSR.METER_INPUT(APP_SID, METER_INPUT_ID)
;

ALTER TABLE CSR.METER_READING_DATA ADD CONSTRAINT FK_METIMP_METREDDAT
	FOREIGN KEY (APP_SID, METER_INPUT_ID)
	REFERENCES CSR.METER_INPUT(APP_SID, METER_INPUT_ID)
;

ALTER TABLE CSR.METER_SOURCE_DATA ADD CONSTRAINT FK_METIMP_METSRCDAT
	FOREIGN KEY (APP_SID, METER_INPUT_ID)
	REFERENCES CSR.METER_INPUT(APP_SID, METER_INPUT_ID)
;

ALTER TABLE CSR.METER_ALARM_STATISTIC ADD CONSTRAINT FK_METIMPAGG_METALMSTAT 
	FOREIGN KEY (APP_SID, METER_INPUT_ID, AGGREGATOR)
	REFERENCES CSR.METER_INPUT_AGGREGATOR(APP_SID, METER_INPUT_ID, AGGREGATOR)
;

ALTER TABLE CSR.METER_ALARM_STATISTIC ADD CONSTRAINT FK_METERBUCKET_STATISTIC 
	FOREIGN KEY (APP_SID, METER_BUCKET_ID)
	REFERENCES CSR.METER_BUCKET(APP_SID, METER_BUCKET_ID)
;

ALTER TABLE CSR.METER_LIVE_DATA ADD CONSTRAINT FK_MDPRIORITY_MLIVE 
	FOREIGN KEY (APP_SID, PRIORITY)
	REFERENCES CSR.METER_DATA_PRIORITY(APP_SID, PRIORITY)
;

ALTER TABLE CSR.METER_PATCH_DATA ADD CONSTRAINT FK_ALLMETER_MPATCH
	FOREIGN KEY (APP_SID, REGION_SID)
	REFERENCES CSR.ALL_METER(APP_SID, REGION_SID)
;

ALTER TABLE CSR.METER_PATCH_DATA ADD CONSTRAINT FK_MDPRIORITY_MPATCH 
	FOREIGN KEY (APP_SID, PRIORITY)
	REFERENCES CSR.METER_DATA_PRIORITY(APP_SID, PRIORITY)
;

-- Hmm
BEGIN
	FOR r IN (
		SELECT table_name, constraint_name
		  FROM all_constraints
		 WHERE owner = 'CSR'
		   AND table_name IN (
			'METER_ALARM_STATISTIC_JOB',
			'METER_ALARM_STATISTIC_PERIOD'
		   )
		   AND constraint_name IN (
			'REFMETER_METER_ALARM_STATI2143',
			'REFMETER_METER_ALARM_STATI2174'
		  )
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.'||r.table_name||' DROP CONSTRAINT '||r.constraint_name;
	END LOOP;
END;
/

BEGIN
	FOR r IN (
		SELECT p.table_name, p.constraint_name
		  FROM all_constraints p
		  JOIN all_constraints c
			ON c.constraint_name = p.r_constraint_name
		   AND c.constraint_type = 'P' 
		   AND c.table_name = 'METER_METER_ALARM_STATISTIC'
		 WHERE p.owner = 'CSR'
		   AND p.table_name = 'METER_ALARM_STATISTIC_PERIOD'
		   AND p.constraint_type = 'R'
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.'||r.table_name||' DROP CONSTRAINT '||r.constraint_name;
	END LOOP;
END;
/


ALTER TABLE CSR.METER_ALARM_STATISTIC_PERIOD ADD CONSTRAINT FK_METALMSTAT_METALMSTATPRD 
	FOREIGN KEY (APP_SID, STATISTIC_ID)
	REFERENCES CSR.METER_ALARM_STATISTIC(APP_SID, STATISTIC_ID)
;

ALTER TABLE CSR.METER_ALARM_STATISTIC_PERIOD ADD CONSTRAINT FK_METER_METALMSTATPERIOD 
	FOREIGN KEY (APP_SID, REGION_SID)
	REFERENCES CSR.ALL_METER(APP_SID, REGION_SID)
;

ALTER TABLE CSR.METER_PATCH_JOB ADD CONSTRAINT FK_AMETER_METERPATCHJOB 
	FOREIGN KEY (APP_SID, REGION_SID)
	REFERENCES CSR.ALL_METER(APP_SID, REGION_SID)
;

ALTER TABLE CSR.METER_PATCH_JOB ADD CONSTRAINT FK_METIMP_METPATJOB 
	FOREIGN KEY (APP_SID, METER_INPUT_ID)
	REFERENCES CSR.METER_INPUT(APP_SID, METER_INPUT_ID)
;

ALTER TABLE CSR.METER_PATCH_BATCH_JOB ADD CONSTRAINT FK_ALLMET_METPATBATJOB 
	FOREIGN KEY (APP_SID, REGION_SID)
	REFERENCES CSR.ALL_METER(APP_SID, REGION_SID)
;

ALTER TABLE CSR.METER_PATCH_BATCH_JOB ADD CONSTRAINT FK_CUSTOMER_METPATBATJOB 
	FOREIGN KEY (APP_SID)
	REFERENCES CSR.CUSTOMER(APP_SID)
;

ALTER TABLE CSR.METER_PATCH_BATCH_DATA ADD CONSTRAINT FK_METINP_METPATBATDAT 
	FOREIGN KEY (APP_SID, METER_INPUT_ID)
	REFERENCES CSR.METER_INPUT(APP_SID, METER_INPUT_ID)
;

ALTER TABLE CSR.METER_PATCH_BATCH_DATA ADD CONSTRAINT FK_METDATPRI_METPATBATDAT 
	FOREIGN KEY (APP_SID, PRIORITY)
	REFERENCES CSR.METER_DATA_PRIORITY(APP_SID, PRIORITY)
;

ALTER TABLE CSR.METER_PATCH_BATCH_DATA ADD CONSTRAINT FK_METPATBATJOB_METPATBADAT
	FOREIGN KEY (APP_SID, BATCH_JOB_ID)
	REFERENCES CSR.METER_PATCH_BATCH_JOB(APP_SID, BATCH_JOB_ID)
;

ALTER TABLE CSR.METER_DATA_COVERAGE_IND ADD CONSTRAINT FK_IND_METDATCOVIND 
	FOREIGN KEY (APP_SID, IND_SID)
	REFERENCES CSR.IND(APP_SID, IND_SID)
;

ALTER TABLE CSR.METER_DATA_COVERAGE_IND ADD CONSTRAINT FK_METDATPRI_METDATCOVIND 
	FOREIGN KEY (APP_SID, PRIORITY)
	REFERENCES CSR.METER_DATA_PRIORITY(APP_SID, PRIORITY)
;

ALTER TABLE CSR.METER_DATA_COVERAGE_IND ADD CONSTRAINT FK_METINP_METDATCOVIND 
	FOREIGN KEY (APP_SID, METER_INPUT_ID)
	REFERENCES CSR.METER_INPUT(APP_SID, METER_INPUT_ID)
;

-- FK indexes
CREATE INDEX CSR.IX_CUSTOMER_MDPRIORITY ON CSR.METER_DATA_PRIORITY(APP_SID);
CREATE INDEX CSR.IX_MDPRIORITY_MORPHAN ON CSR.METER_ORPHAN_DATA(APP_SID, PRIORITY);
CREATE INDEX CSR.IX_MDPRIORITY_MREADING ON CSR.METER_READING_DATA(APP_SID, PRIORITY);
CREATE INDEX CSR.IX_MDPRIORITY_MSOURCE ON CSR.METER_SOURCE_DATA(APP_SID, PRIORITY);
CREATE INDEX CSR.IX_MDPRIORITY_MLIVE ON CSR.METER_LIVE_DATA(APP_SID, PRIORITY);
CREATE INDEX CSR.FK_ALLMETER_MPATCH ON CSR.METER_PATCH_DATA(APP_SID, REGION_SID);
CREATE INDEX CSR.FK_MDPRIORITY_MPATCH ON CSR.METER_PATCH_DATA(APP_SID, PRIORITY);

CREATE INDEX CSR.IX_CUSTOMER_METIMP ON CSR.METER_INPUT(APP_SID);
CREATE INDEX CSR.IX_AMETER_METINPAGGIND ON CSR.METER_INPUT_AGGR_IND(APP_SID);
CREATE INDEX CSR.IX_IND_METERINPAGGRIND ON CSR.METER_INPUT_AGGR_IND(APP_SID, IND_SID);
CREATE INDEX CSR.IX_METINPAGGR_METINPAGRIND ON CSR.METER_INPUT_AGGR_IND(APP_SID, METER_INPUT_ID, AGGREGATOR);
CREATE INDEX CSR.IX_METAGG_METINPAGG ON CSR.METER_INPUT_AGGREGATOR(AGGREGATOR);
CREATE INDEX CSR.IX_METIMP_METIMPAGG ON CSR.METER_INPUT_AGGREGATOR(APP_SID, METER_INPUT_ID);
CREATE INDEX CSR.IX_METIMPAGG_METLIVDAT ON CSR.METER_LIVE_DATA(APP_SID, METER_INPUT_ID, AGGREGATOR);
CREATE INDEX CSR.IX_METIMP_METORPDAT ON CSR.METER_ORPHAN_DATA(APP_SID, METER_INPUT_ID);
CREATE INDEX CSR.IX_METIMP_METPATDAT ON CSR.METER_PATCH_DATA(APP_SID, METER_INPUT_ID);
CREATE INDEX CSR.IX_METIMP_METREDDAT ON CSR.METER_READING_DATA(APP_SID, METER_INPUT_ID);
CREATE INDEX CSR.IX_METIMP_METSRCDAT ON CSR.METER_SOURCE_DATA(APP_SID, METER_INPUT_ID);
CREATE INDEX CSR.IX_METIMPAGG_METALMSTAT ON CSR.METER_ALARM_STATISTIC (APP_SID, METER_INPUT_ID, AGGREGATOR);

CREATE INDEX CSR.IX_METERBUCKET_STATISTIC ON CSR.METER_ALARM_STATISTIC (APP_SID, METER_BUCKET_ID);
CREATE INDEX IX_METALMSTAT_METALMSTATPRD ON CSR.METER_ALARM_STATISTIC_PERIOD (APP_SID, STATISTIC_ID);
CREATE INDEX IX_METER_METALMSTATPERIOD ON CSR.METER_ALARM_STATISTIC_PERIOD (APP_SID, REGION_SID);
CREATE INDEX CSR.IX_AMETER_METERPATCHJOB ON CSR.METER_PATCH_JOB(APP_SID, REGION_SID);
CREATE INDEX CSR.IX_METIMP_METPATJOB ON CSR.METER_PATCH_JOB(APP_SID, METER_INPUT_ID);

CREATE INDEX CSR.IX_ALLMET_METPATBATJOB ON CSR.METER_PATCH_BATCH_JOB (APP_SID, REGION_SID);
CREATE INDEX CSR.IX_CUSTOMER_METPATBATJOB ON CSR.METER_PATCH_BATCH_JOB (APP_SID);
CREATE INDEX CSR.IX_METINP_METPATBATDAT ON CSR.METER_PATCH_BATCH_DATA (APP_SID, METER_INPUT_ID);
CREATE INDEX CSR.IX_METDATPRI_METPATBATDAT ON CSR.METER_PATCH_BATCH_DATA (APP_SID, PRIORITY);
CREATE INDEX CSR.IX_METPATBATJOB_METPATBADAT ON CSR.METER_PATCH_BATCH_DATA (APP_SID, BATCH_JOB_ID);

CREATE INDEX CSR.IX_IND_METDATCOVIND ON CSR.METER_DATA_COVERAGE_IND(APP_SID, IND_SID);
CREATE INDEX CSR.IX_METDATPRI_METDATCOVIND ON CSR.METER_DATA_COVERAGE_IND(APP_SID, PRIORITY);
CREATE INDEX CSR.IX_METINP_METDATCOVIND ON CSR.METER_DATA_COVERAGE_IND(APP_SID, METER_INPUT_ID);

-- Non-FK indexes
CREATE INDEX CSR.IX_METLD_BUINPR ON CSR.METER_LIVE_DATA(APP_SID, METER_BUCKET_ID, METER_INPUT_ID, PRIORITY);
CREATE INDEX CSR.IX_METLD_BUINPRAG ON CSR.METER_LIVE_DATA(APP_SID, METER_BUCKET_ID, METER_INPUT_ID, PRIORITY, AGGREGATOR);
CREATE INDEX CSR.IX_METLD_RGBUINPR ON CSR.METER_LIVE_DATA(APP_SID, REGION_SID, METER_BUCKET_ID, METER_INPUT_ID, PRIORITY);
CREATE INDEX CSR.IX_METLD_RGBUINAGPR ON CSR.METER_LIVE_DATA(APP_SID, REGION_SID, METER_BUCKET_ID, METER_INPUT_ID, AGGREGATOR, PRIORITY);
CREATE INDEX CSR.IX_METRDNG_RGIN ON CSR.METER_READING_DATA(APP_SID, REGION_SID, METER_INPUT_ID);
CREATE INDEX CSR.IX_METSRC_RGIN ON CSR.METER_SOURCE_DATA(APP_SID, REGION_SID, METER_INPUT_ID);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- /csr/db/create_views.sql
CREATE OR REPLACE VIEW CSR.V$PATCHED_METER_LIVE_DATA AS
	SELECT app_sid, region_sid, meter_input_id, aggregator, meter_bucket_id, priority, start_dtm, end_dtm, meter_raw_data_id, modified_dtm, consumption
	  FROM (
		SELECT app_sid, region_sid, meter_input_id, aggregator, meter_bucket_id, priority, start_dtm, end_dtm, meter_raw_data_id, modified_dtm, consumption,
			ROW_NUMBER() OVER (PARTITION BY app_sid, region_sid, meter_input_id, aggregator, meter_bucket_id, start_dtm ORDER BY priority DESC) rn
		  FROM csr.meter_live_data d
	 )
	 WHERE rn = 1;


-- ** Triggers ** --

-- /csr/db/create_triggers.sql
CREATE OR REPLACE TRIGGER CSR.METER_IND_TRIGGER
AFTER INSERT OR UPDATE
	ON CSR.ALL_METER
	FOR EACH ROW
DECLARE
	v_consumption_input_id	csr.meter_input.meter_input_id%TYPE;
	v_cost_input_id			csr.meter_input.meter_input_id%TYPE;
BEGIN
	SELECT meter_input_id
	  INTO v_consumption_input_id
	  FROM csr.meter_input
	 WHERE app_sid = :NEW.app_sid
	   AND lookup_key = 'CONSUMPTION';
	
	SELECT meter_input_id
	  INTO v_cost_input_id
	  FROM csr.meter_input
	 WHERE app_sid = :NEW.app_sid
	   AND lookup_key = 'COST';
	
	FOR r IN (
		SELECT :NEW.app_sid app_sid, :NEW.region_sid region_sid, 
			pia.aggregator primary_aggregator, :NEW.primary_ind_sid primary_ind_sid, pi.measure_sid primary_measure_sid, :NEW.primary_measure_conversion_id primary_measure_conversion_id,
			cia.aggregator cost_aggregator, :NEW.cost_ind_sid cost_ind_sid, ci.measure_sid cost_measure_sid, :NEW.cost_measure_conversion_id cost_measure_conversion_id
		  FROM csr.ind pi
		  JOIN csr.meter_input_aggregator pia ON pia.app_sid = pi.app_sid AND pia.meter_input_id = v_consumption_input_id
		  LEFT JOIN csr.ind ci ON ci.app_sid = pi.app_sid AND ci.ind_sid = :NEW.cost_ind_sid
		  LEFT JOIN csr.meter_input_aggregator cia ON cia.app_sid = ci.app_sid AND cia.meter_input_id = v_cost_input_id
		 WHERE pi.app_sid = :NEW.app_sid
		   AND pi.ind_sid = :NEW.primary_ind_sid
	) LOOP
		-- Set the consumption indicator/measure/conversion
		BEGIN
			INSERT INTO csr.meter_input_aggr_ind (app_sid, region_sid, meter_input_id, aggregator, ind_sid, measure_sid, measure_conversion_id)
			VALUES (r.app_sid, r.region_sid, v_consumption_input_id, r.primary_aggregator, r.primary_ind_sid, r.primary_measure_sid, r.primary_measure_conversion_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE csr.meter_input_aggr_ind
				   SET ind_sid = r.primary_ind_sid,
					   measure_sid = r.primary_measure_sid, 
					   measure_conversion_id = r.primary_measure_conversion_id
				 WHERE app_sid = r.app_sid
				   AND region_sid = r.region_sid
				   AND meter_input_id = v_consumption_input_id
				   AND aggregator = r.primary_aggregator;
		END;
		
		-- Set the cost indicator/measure/conversion
		IF r.cost_ind_sid IS NOT NULL THEN
			BEGIN
				INSERT INTO csr.meter_input_aggr_ind (app_sid, region_sid, meter_input_id, aggregator, ind_sid, measure_sid, measure_conversion_id)
				VALUES (r.app_sid, r.region_sid, v_cost_input_id, r.cost_aggregator, r.cost_ind_sid, r.cost_measure_sid, r.cost_measure_conversion_id);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE csr.meter_input_aggr_ind
					   SET ind_sid = r.cost_ind_sid,
						   measure_sid = r.cost_measure_sid, 
						   measure_conversion_id = r.cost_measure_conversion_id
					 WHERE app_sid = r.app_sid
					   AND region_sid = r.region_sid
					   AND meter_input_id = v_cost_input_id
					   AND aggregator = r.cost_aggregator;
			END;
		ELSE
			DELETE FROM csr.meter_input_aggr_ind
			  WHERE app_sid = r.app_sid
			    AND region_sid = r.region_sid
			    AND meter_input_id = v_cost_input_id;
		END IF;
	END LOOP;
END;
/

-- *** Data changes ***
-- RLS

-- Types
CREATE OR REPLACE TYPE CSR.T_METER_PATCH_DATA_ROW AS
	OBJECT (
		POS					NUMBER(10, 0),
		START_DTM			DATE,
		END_DTM				DATE,
		PERIOD_TYPE			VARCHAR2(32),
		CONSUMPTION			NUMBER(24, 10)
	);
/

CREATE OR REPLACE TYPE CSR.T_METER_PATCH_DATA_TABLE AS
	TABLE OF CSR.T_METER_PATCH_DATA_ROW;
/

-- Data
BEGIN
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
	VALUES (19, 'Meter patch', 'csr.meter_patch_pkg.ProcessBatchJob', NULL, 0, NULL);
END;
/

BEGIN
	-- Restrict some existing buckets to high resolution data only
	UPDATE csr.meter_bucket
	   SET high_resolution_only = 1
	 WHERE is_minutes = 1
	    OR (is_hours = 1 AND duration < 24);

	-- All metering now needs a system bucket (even non-real-time)
	-- A daily bucket is sometimes used to compute some values with better granularity (so add that too)
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM csr.meter_source_type st
		 WHERE NOT EXISTS (
		 	SELECT 1
		 	  FROM csr.meter_bucket mb
		 	 WHERE app_sid = st.app_sid
		 )
	) LOOP
		-- System period bucket
		INSERT INTO csr.meter_bucket (app_sid, meter_bucket_id, description, is_export_period, period_set_id, period_interval_id)
		VALUES(r.app_sid, csr.meter_bucket_id_seq.NEXTVAL, 'System', 1, 1, 1);
		-- Daily bucket
		INSERT INTO csr.meter_bucket (app_sid, meter_bucket_id, description, duration, is_hours)
		VALUES(r.app_sid, csr.meter_bucket_id_seq.NEXTVAL, 'Daily', 24, 1);
	END LOOP;
END;
/

-- ** New package grants **
create or replace package csr.meter_patch_pkg as end;
/
grant execute on csr.meter_patch_pkg to web_user;


-- *** Packages ***
@../batch_job_pkg
@../meter_pkg
@../meter_monitor_pkg
@../meter_patch_pkg
@../meter_alarm_stat_pkg
@../meter_aggr_pkg
@../period_pkg

@../csr_app_body
@../meter_body
@../meter_monitor_body
@../meter_alarm_stat_body
@../meter_patch_body
@../meter_aggr_body
@../period_body

@update_tail
