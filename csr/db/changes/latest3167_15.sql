-- Please update version.sql too -- this keeps clean builds in sync
define version=3167
define minor_version=15
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE CSR.CORE_WORKING_HOURS_ID_SEQ;

CREATE TABLE CSR.CORE_WORKING_HOURS (
	APP_SID						NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CORE_WORKING_HOURS_ID		NUMBER(10)		NOT NULL,
	START_TIME					VARCHAR2(16)	NOT NULL,
	END_TIME					VARCHAR2(16)	NOT NULL,
	CONSTRAINT PK_CORE_WORKING_HOURS PRIMARY KEY (APP_SID, CORE_WORKING_HOURS_ID),
	CONSTRAINT FK_CUSTOMER_COREWKHRS FOREIGN KEY 
		(APP_SID) REFERENCES CSR.CUSTOMER(APP_SID)
);

CREATE TABLE CSR.CORE_WORKING_HOURS_DAY (
	APP_SID						NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CORE_WORKING_HOURS_ID		NUMBER(10)		NOT NULL,
	DAY							NUMBER(1)		NOT NULL,
	CONSTRAINT PK_CORE_WORKING_HOURS_DAY PRIMARY KEY (APP_SID, CORE_WORKING_HOURS_ID, DAY),
	CONSTRAINT FK_COREWKHRS_COREWKHRSDAY FOREIGN KEY 
		(APP_SID, CORE_WORKING_HOURS_ID) REFERENCES CSR.CORE_WORKING_HOURS(APP_SID, CORE_WORKING_HOURS_ID),
	CONSTRAINT CK_CORE_WORKING_HOURS_DAY CHECK (DAY IN (1,2,3,4,5,6,7))
);

CREATE TABLE CSR.CORE_WORKING_HOURS_REGION (
	APP_SID						NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	REGION_SID					NUMBER(10)		NOT NULL,
	CORE_WORKING_HOURS_ID		NUMBER(10)		NOT NULL,
	CONSTRAINT PK_CORE_WORKING_HOURS_REGION PRIMARY KEY (APP_SID, REGION_SID, CORE_WORKING_HOURS_ID),
	CONSTRAINT FK_REGION_COREWKHRS FOREIGN KEY 
		(APP_SID, REGION_SID) REFERENCES CSR.REGION(APP_SID, REGION_SID)
);

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_CORE_WORKING_HOURS (
	INHERITED_FROM_REGION_SID	NUMBER(10)		NOT NULL,
	CORE_WORKING_HOURS_ID		NUMBER(10)		NOT NULL,
	DAY							NUMBER(1)		NOT NULL,
	START_TIME					VARCHAR2(16)	NOT NULL,
	END_TIME					VARCHAR2(16)	NOT NULL,
	CONSTRAINT CK_TMP_CORE_WORKING_HOURS_DAY CHECK (DAY IN (1,2,3,4,5,6,7))
) ON COMMIT DELETE ROWS;

-- CSRIMP
CREATE TABLE CSRIMP.CORE_WORKING_HOURS (
	CSRIMP_SESSION_ID			NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CORE_WORKING_HOURS_ID		NUMBER(10)		NOT NULL,
	START_TIME					VARCHAR2(16)	NOT NULL,
	END_TIME					VARCHAR2(16)	NOT NULL,
	CONSTRAINT PK_CORE_WORKING_HOURS PRIMARY KEY (CSRIMP_SESSION_ID, CORE_WORKING_HOURS_ID),
	CONSTRAINT FK_CUSTOMER_COREWKHRS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CORE_WORKING_HOURS_DAY (
	CSRIMP_SESSION_ID			NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CORE_WORKING_HOURS_ID		NUMBER(10)		NOT NULL,
	DAY							NUMBER(1)		NOT NULL,
	CONSTRAINT PK_CORE_WORKING_HOURS_DAY PRIMARY KEY (CSRIMP_SESSION_ID, CORE_WORKING_HOURS_ID, DAY),
	CONSTRAINT FK_COREWKHRS_COREWKHRSDAY FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE,
	CONSTRAINT CK_CORE_WORKING_HOURS_DAY CHECK (DAY IN (1,2,3,4,5,6,7))
);

CREATE TABLE CSRIMP.CORE_WORKING_HOURS_REGION (
	CSRIMP_SESSION_ID			NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	REGION_SID					NUMBER(10)		NOT NULL,
	CORE_WORKING_HOURS_ID		NUMBER(10)		NOT NULL,
	CONSTRAINT PK_CORE_WORKING_HOURS_REGION PRIMARY KEY (CSRIMP_SESSION_ID, REGION_SID, CORE_WORKING_HOURS_ID),
	CONSTRAINT FK_REGION_COREWKHRS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CORE_WORKING_HOURS  (
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_core_working_hours_id	NUMBER(10) NOT NULL,
	new_core_working_hours_id	NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CORE_WORKING_HOURS primary key (csrimp_session_id, old_core_working_hours_id) USING INDEX,
	CONSTRAINT UK_MAP_CORE_WORKING_HOURS UNIQUE (csrimp_session_id, new_core_working_hours_id) USING INDEX,
	CONSTRAINT FK_MAP_CORE_WORKING_HOURS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE CSR.METER_BUCKET ADD (
	CORE_WORKING_HOURS			NUMBER(1)		DEFAULT 0 NOT NULL,
	CONSTRAINT CK_CORE_WORKING_HOURS CHECK (CORE_WORKING_HOURS IN (0,1))
);

ALTER TABLE CSR.METER_ALARM_STATISTIC ADD (
	CORE_WORKING_HOURS			NUMBER(1)		DEFAULT 0 NOT NULL,
	POS							NUMBER(10)		DEFAULT 0 NOT NULL,
	CONSTRAINT CK_CORE_WORKING_HOURS_MAS CHECK (CORE_WORKING_HOURS IN (0,1))
);

ALTER TABLE CSR.METER_ALARM MODIFY (
	COMPARE_STATISTIC_ID		NUMBER(10)		NULL
);

ALTER TABLE CSR.METER_ALARM RENAME COLUMN COMPARISON_PCT TO COMPARISON_VAL;

-- CSRIMP
ALTER TABLE CSRIMP.METER_BUCKET ADD (
	CORE_WORKING_HOURS			NUMBER(1)		NOT NULL,
	CONSTRAINT CK_CORE_WORKING_HOURS CHECK (CORE_WORKING_HOURS IN (0,1))
);

ALTER TABLE CSRIMP.METER_ALARM_STATISTIC ADD (
	CORE_WORKING_HOURS			NUMBER(1)		NOT NULL,
	POS							NUMBER(10)		NOT NULL,
	CONSTRAINT CK_CORE_WORKING_HOURS_MAS CHECK (CORE_WORKING_HOURS IN (0,1))
);

ALTER TABLE CSRIMP.METER_ALARM MODIFY (
	COMPARE_STATISTIC_ID		NUMBER(10)		NULL
);

ALTER TABLE CSRIMP.METER_ALARM RENAME COLUMN COMPARISON_PCT TO COMPARISON_VAL;

-- *** Grants ***
grant select on csr.core_working_hours_id_seq to csrimp;
grant select, insert, update on csr.core_working_hours to csrimp;
grant select, insert, update on csr.core_working_hours_day to csrimp;
grant select, insert, update on csr.core_working_hours_region to csrimp;

grant select, insert, update on csrimp.core_working_hours to tool_user;
grant select, insert, update on csrimp.core_working_hours_day to tool_user;
grant select, insert, update on csrimp.core_working_hours_region to tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_region_root					NUMBER(10);
	v_daily_bucket_id				NUMBER(10);
	v_hourly_bucket_id				NUMBER(10);
	v_meter_input_id				NUMBER(10);
	v_cwh_id						NUMBER(10);
BEGIN

	-- For each app with meter alarm stats
	FOR a IN (
		SELECT DISTINCT app_sid
		  FROM csr.meter_alarm_statistic
	) LOOP
	
		SELECT region_tree_root_sid
		  INTO v_region_root
		  FROM csr.region_tree
		 WHERE app_sid = a.app_sid
		   AND is_primary = 1;

		-- Set a default core working hours set that matches the old hard-coded 
		-- values if the client has any core working hours stats in use.
		FOR r IN (
			SELECT rt.region_tree_root_sid
			  FROM csr.region_tree rt
			  JOIN (
			  	SELECT s.app_sid
				  FROM csr.meter_alarm_statistic s
				 WHERE s.app_sid = a.app_sid
				   AND LOWER(s.name) LIKE '%core%'
				   AND s.all_meters = 1
				UNION
				SELECT s.app_sid
				  FROM csr.meter_alarm_statistic s
				  JOIN csr.meter_alarm ma on ma.app_sid = a.app_sid AND ma.look_at_statistic_id = s.statistic_id
				 WHERE s.app_sid = a.app_sid
				   AND LOWER(s.name) LIKE '%core%'
				UNION
				SELECT s.app_sid
				  FROM csr.meter_alarm_statistic s
				  JOIN csr.meter_alarm ma on ma.app_sid = a.app_sid AND ma.compare_statistic_id = s.statistic_id
				 WHERE s.app_sid = a.app_sid
				   AND LOWER(s.name) LIKE '%core%'
			  ) x ON x.app_sid = rt.app_sid
			 WHERE rt.app_sid = a.app_sid
			   AND rt.is_primary = 1
		) LOOP

			INSERT INTO csr.core_working_hours (app_sid, core_working_hours_id, start_time, end_time)
			VALUES (a.app_sid, csr.core_working_hours_id_seq.NEXTVAL, '0 07:00:00', '0 17:00:00')
			RETURNING core_working_hours_id INTO v_cwh_id;

			INSERT INTO csr.core_working_hours_region (app_sid, core_working_hours_id, region_sid)
			VALUES (a.app_sid, v_cwh_id, r.region_tree_root_sid);

			INSERT INTO csr.core_working_hours_day (app_sid, core_working_hours_id, day)
			VALUES(a.app_sid, v_cwh_id, 1);
			INSERT INTO csr.core_working_hours_day (app_sid, core_working_hours_id, day)
			VALUES(a.app_sid, v_cwh_id, 2);
			INSERT INTO csr.core_working_hours_day (app_sid, core_working_hours_id, day)
			VALUES(a.app_sid, v_cwh_id, 3);
			INSERT INTO csr.core_working_hours_day (app_sid, core_working_hours_id, day)
			VALUES(a.app_sid, v_cwh_id, 4);
			INSERT INTO csr.core_working_hours_day (app_sid, core_working_hours_id, day)
			VALUES(a.app_sid, v_cwh_id, 5);

			EXIT;
		END LOOP;

		-- Ensure any existing stats with the word "core" 
		-- in the name have the core_working_hours flag set.
		UPDATE csr.meter_alarm_statistic
		   SET core_working_hours = 1
		 WHERE app_sid = a.app_sid
		   AND LOWER(name) LIKE '%core%';

		-- Set the day specific stat positions
		FOR r IN (
			SELECT statistic_id, ROWNUM rn
			  FROM csr.meter_alarm_statistic
			 WHERE app_sid = a.app_sid
			   AND name IN (
				'Monday''s usage',
				'Tuesday''s usage',
				'Wednesday''s usage',
				'Thursday''s usage',
				'Friday''s usage',
				'Saturday''s usage',
				'Sunday''s usage'
			  )
			 ORDER BY statistic_id
		) LOOP
			UPDATE csr.meter_alarm_statistic
			   SET pos = 50 + r.rn -1
			 WHERE app_sid = a.app_sid
			   AND statistic_id = r.statistic_id;
		END LOOP;

		FOR r IN (
			SELECT statistic_id, ROWNUM rn
			  FROM csr.meter_alarm_statistic
			 WHERE app_sid = a.app_sid
			   AND name IN (
				'Average Monday usage',
				'Average Tuesday usage',
				'Average Wednesday usage',
				'Average Thursday usage',
				'Average Friday usage',
				'Average Saturday usage',
				'Average Sunday usage'
			   )
			 ORDER BY statistic_id
		) LOOP
			UPDATE csr.meter_alarm_statistic
			   SET pos = 57 + r.rn - 1
			 WHERE app_sid = a.app_sid
			   AND statistic_id = r.statistic_id;
		END LOOP;

		BEGIN
			-- Find consumption input
			SELECT meter_input_id
			  INTO v_meter_input_id
			  FROM csr.meter_input
			 WHERE app_sid = a.app_sid
			   AND lookup_key = 'CONSUMPTION';

			-- Add/replace the core/non-core working hours stats
			BEGIN
				-- Find the hourly bucket
				SELECT meter_bucket_id
				  INTO v_hourly_bucket_id
				  FROM csr.meter_bucket
				 WHERE app_sid = a.app_sid
				   AND is_hours = 1
				   AND duration = 24;

				UPDATE csr.meter_alarm_statistic
				   SET name = 'Core working hours - daily usage',
					   comp_proc = 'meter_alarm_core_stat_pkg.ComputeCoreDayUse',
					   pos = 100,
					   core_working_hours = 1
				 WHERE app_sid = a.app_sid
				   AND comp_proc IN (
				   	'meter_alarm_stat_pkg.ComputeWkgDayCore', 
				   	'meter_alarm_core_stat_pkg.ComputeCoreDayUse');

				IF SQL%NOTFOUND THEN
					INSERT INTO csr.meter_alarm_statistic (app_sid, statistic_id, meter_bucket_id, name, is_average, is_sum, comp_proc, meter_input_id, aggregator, pos, core_working_hours)
					VALUES (a.app_sid, csr.meter_statistic_id_seq.NEXTVAL, v_hourly_bucket_id, 'Core working hours - daily usage',  0/*<--IS AVG*/, 0, 
						'meter_alarm_core_stat_pkg.ComputeCoreDayUse', v_meter_input_id, 'SUM', 100, 1);
				END IF;

				UPDATE csr.meter_alarm_statistic
				   SET name = 'Core working hours - daily average',
					   comp_proc = 'meter_alarm_core_stat_pkg.ComputeCoreDayAvg',
					   pos = 101,
					   core_working_hours = 1
				 WHERE app_sid = a.app_sid
				   AND comp_proc IN (
				   	'meter_alarm_stat_pkg.ComputeWkgDayCoreAvg', 
				   	'meter_alarm_core_stat_pkg.ComputeCoreDayAvg');

				IF SQL%NOTFOUND THEN
					INSERT INTO csr.meter_alarm_statistic (app_sid, statistic_id, meter_bucket_id, name, is_average, is_sum, comp_proc, meter_input_id, aggregator, pos, core_working_hours)
					VALUES (a.app_sid, csr.meter_statistic_id_seq.NEXTVAL, v_hourly_bucket_id, 'Core working hours - daily average',  1/*<--IS AVG*/, 0, 
						'meter_alarm_core_stat_pkg.ComputeCoreDayAvg', v_meter_input_id, 'SUM', 101, 1);
				END IF;

				UPDATE csr.meter_alarm_statistic
				   SET name = 'Non-core working hours - daily usage',
					   comp_proc = 'meter_alarm_core_stat_pkg.ComputeNonCoreDayUse',
					   pos = 103,
					   core_working_hours = 1
				 WHERE app_sid = a.app_sid
				   AND comp_proc IN (
				   	'meter_alarm_stat_pkg.ComputeWkgDayNonCore', 
				   	'meter_alarm_core_stat_pkg.ComputeNonCoreDayUse');

				IF SQL%NOTFOUND THEN
					INSERT INTO csr.meter_alarm_statistic (app_sid, statistic_id, meter_bucket_id, name, is_average, is_sum, comp_proc, meter_input_id, aggregator, pos, core_working_hours)
					VALUES (a.app_sid, csr.meter_statistic_id_seq.NEXTVAL, v_hourly_bucket_id, 'Non-core working hours - daily usage',  0/*<--IS AVG*/, 0, 
						'meter_alarm_core_stat_pkg.ComputeNonCoreDayUse', v_meter_input_id, 'SUM', 103, 1);
				END IF;

				UPDATE csr.meter_alarm_statistic
				   SET name = 'Non-core working hours - daily average',
					   comp_proc = 'meter_alarm_core_stat_pkg.ComputeNonCoreDayAvg',
					   pos = 104,
					   core_working_hours = 1
				 WHERE app_sid = a.app_sid
				   AND comp_proc IN (
				   	'meter_alarm_stat_pkg.ComputeWkgDayNonCoreAvg', 
				   	'meter_alarm_core_stat_pkg.ComputeNonCoreDayAvg');

				IF SQL%NOTFOUND THEN
					INSERT INTO csr.meter_alarm_statistic (app_sid, statistic_id, meter_bucket_id, name, is_average, is_sum, comp_proc, meter_input_id, aggregator, pos, core_working_hours)
					VALUES (a.app_sid, csr.meter_statistic_id_seq.NEXTVAL, v_hourly_bucket_id, 'Non-core working hours - daily average',  1/*<--IS AVG*/, 0, 
						'meter_alarm_core_stat_pkg.ComputeNonCoreDayAvg', v_meter_input_id, 'SUM', 104, 1);
				END IF;

			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					NULL; -- Ignore missing hourly bucket
			END;

		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL; -- Ignore clients with no consumption input
		END;

		-- Use the hourly bucket for core working hours by default
		UPDATE csr.meter_bucket
		   SET core_working_hours = CASE WHEN is_hours = 1 AND duration = 1 THEN 1 ELSE 0 END
		 WHERE app_sid = a.app_sid;

	END LOOP; -- For each app

END;
/

-- New util scripts
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (45, 'Metering stats - same day average', 'Enable/disable the same day average meter alarm statistic feature.', 'EnableMeteringSameDayAvg', NULL);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (45, 'Enable/disable', 'Enable = 1, Disable = 0', 1, NULL);

	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (46, 'Metering core working hours - same day average', 'Enable/disable the same day average meter alarm statistic feature for core working hours.', 'EnableMeteringCoreSameDayAvg', NULL);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (46, 'Enable/disable', 'Enable = 1, Disable = 0', 1, NULL);

	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (47, 'Metering core working hours - day normalised values', 'Enable/disable the day normalised meter alarm statistics for core working hours.', 'EnableMeteringCoreDayNorm', NULL);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (47, 'Enable/disable', 'Enable = 1, Disable = 0', 1, NULL);

	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (48, 'Metering core working hours - extended values', 'Enable/disable the extended alarm statistics set for core working hours.', 'EnableMeteringCoreExtended', NULL);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (48, 'Enable/disable', 'Enable = 1, Disable = 0', 1, NULL);

	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (49, 'Metering core working hours - single day statistics', 'Enable/disable the single day alarm statistics set.', 'EnableMeteringDayStats', NULL);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (49, 'Enable/disable', 'Enable = 1, Disable = 0', 1, NULL);
END;
/

BEGIN
	UPDATE csr.meter_alarm_comparison
	   SET op_code = 'GT_PCT'
	 WHERE op_code = 'GT';

	UPDATE csr.meter_alarm_comparison
	   SET op_code = 'LT_PCT'
	 WHERE op_code = 'LT';

	FOR a IN (
		SELECT DISTINCT app_sid
		  FROM csr.meter_alarm_comparison
	) LOOP

		INSERT INTO csr.meter_alarm_comparison (app_sid, comparison_id, name, op_code)
		VALUES (a.app_sid, csr.meter_comparison_id_seq.NEXTVAL, 'Usage is more than', 'GT_ABS');

		INSERT INTO csr.meter_alarm_comparison (app_sid, comparison_id, name, op_code)
		VALUES (a.app_sid, csr.meter_comparison_id_seq.NEXTVAL, 'Usage is more than', 'GT_ADD');

		INSERT INTO csr.meter_alarm_comparison (app_sid, comparison_id, name, op_code)
		VALUES (a.app_sid, csr.meter_comparison_id_seq.NEXTVAL, 'Usage is more than', 'GT_SUB');

		INSERT INTO csr.meter_alarm_comparison (app_sid, comparison_id, name, op_code)
		VALUES (a.app_sid, csr.meter_comparison_id_seq.NEXTVAL, 'Usage is less than', 'LT_ABS');

		INSERT INTO csr.meter_alarm_comparison (app_sid, comparison_id, name, op_code)
		VALUES (a.app_sid, csr.meter_comparison_id_seq.NEXTVAL, 'Usage is less than', 'LT_ADD');

		INSERT INTO csr.meter_alarm_comparison (app_sid, comparison_id, name, op_code)
		VALUES (a.app_sid, csr.meter_comparison_id_seq.NEXTVAL, 'Usage is less than', 'LT_SUB');

	END LOOP;

END;
/

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.meter_alarm_core_stat_pkg
IS
END;
/
GRANT EXECUTE ON csr.meter_alarm_core_stat_pkg TO web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@../meter_alarm_pkg
@../meter_alarm_stat_pkg
@../meter_alarm_core_stat_pkg
@../util_script_pkg
@../schema_pkg

@../meter_alarm_body
@../meter_alarm_core_stat_body
@../meter_alarm_stat_body
@../enable_body
@../util_script_body
@../schema_body
@../csrimp/imp_body

@update_tail
