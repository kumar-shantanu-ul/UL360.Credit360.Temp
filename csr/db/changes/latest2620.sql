-- Please update version.sql too -- this keeps clean builds in sync
define version=2620
@update_header

-- *** DDL ***
-- Create sequences
DECLARE
	v_cnt	NUMBER(10);
BEGIN
	SELECT count(*) 
	  INTO v_cnt
	  FROM ALL_SEQUENCES
	 WHERE SEQUENCE_NAME = 'COURSE_SCHEDULE_ID_SEQ'
	   AND SEQUENCE_OWNER = 'CSR';
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'CREATE SEQUENCE CSR.COURSE_SCHEDULE_ID_SEQ
			START WITH 1
			INCREMENT BY 1
			NOMINVALUE
			NOMAXVALUE
			CACHE 20
			NOORDER';
	END IF;
END;
/

-- Create tables
DECLARE
	v_cnt	NUMBER(10);
BEGIN
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'TEMP_COURSE'
	   AND owner = 'CSR';
	
	IF v_cnt = 0 THEN
		BEGIN
			EXECUTE IMMEDIATE 'CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_COURSE (
				APP_SID 					NUMBER(10) 		DEFAULT SYS_CONTEXT(''SECURITY'',''APP'') NOT NULL,
				COURSE_ID 					NUMBER(10) 		NOT NULL,
				TITLE 						VARCHAR2(50) 	NOT NULL,
				REFERENCE 					VARCHAR2(40),
				DESCRIPTION 				VARCHAR2(4000),
				VERSION 					VARCHAR2(50),
				COURSE_TYPE_ID 				NUMBER(10) 		NOT NULL,
				COURSE_GROUP 				NUMBER(10) 		NOT NULL,
				DELIVERY_METHOD_ID 			NUMBER(10) 		NOT NULL,
				PROVISION_ID 				NUMBER(10)		NOT NULL,
				STATUS_ID 					NUMBER(10) 		NOT NULL,
				DEFAULT_TRAINER_ID 			NUMBER(10),
				DEFAULT_PLACE_ID 			NUMBER(10),
				DURATION 					NUMBER(5) 		NOT NULL,
				EXPIRY_PERIOD 				NUMBER(5),
				EXPIRY_NOTICE_PERIOD 		NUMBER(5),
				ESCALATION_NOTICE_PERIOD 	NUMBER(5),
				REMINDER_NOTICE_PERIOD 		NUMBER(5),
				PASS_SCORE 					NUMBER(5),
				SURVEY_SID 					NUMBER(10),
				QUIZ_SID 					NUMBER(10),
				PASS_FAIL 					NUMBER(1) 		DEFAULT 0 NOT NULL,
				ABSOLUTE_DEADLINE 			DATE,
				COURSE_GROUP_DESCRIPTION	VARCHAR2(4000),
				COURSE_TYPE_LABEL			VARCHAR2(50),
				DELIVERY_METHOD_LABEL		VARCHAR2(50),
				PROVISION_LABEL				VARCHAR2(50),
				STATUS_LABEL				VARCHAR2(50),
				DEFAULT_TRAINER_LABEL		VARCHAR2(100),
				DEFAULT_PLACE_LABEL			VARCHAR2(4000),
				CAN_EDIT 					NUMBER(1) 		DEFAULT 0 NOT NULL
			) ON COMMIT DELETE ROWS';
		END;
	END IF;
END;
/

DECLARE
	v_cnt	NUMBER(10);
BEGIN
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'TEMP_COURSE_SCHEDULE'
	   AND owner = 'CSR';
	
	IF v_cnt = 0 THEN
		BEGIN
			EXECUTE IMMEDIATE 'CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_COURSE_SCHEDULE (
				APP_SID 					NUMBER(10) 		DEFAULT SYS_CONTEXT(''SECURITY'',''APP'') NOT NULL,
				COURSE_SCHEDULE_ID 			NUMBER(10) 		NOT NULL,
				COURSE_ID 					NUMBER(10) 		NOT NULL,
				MAX_CAPACITY 				NUMBER(5) 		NOT NULL,
				BOOKED						NUMBER(5) 		DEFAULT 0 NOT NULL,
				AVAILABLE 					NUMBER(5) 		NOT NULL,
				CANCELED					NUMBER(1) 		DEFAULT 0 NOT NULL,
				TRAINER_ID					NUMBER(10),
				PLACE_ID					NUMBER(10),
				CALENDAR_EVENT_ID 			NUMBER(10) 		NOT NULL,
				START_DTM         			DATE			NOT NULL,   
				END_DTM                    	DATE,
				CREATED_BY_SID    			NUMBER(10)    	NOT NULL,
				CREATED_DTM       			DATE			NOT NULL,          
				LOCATION                   	VARCHAR2(1000),
				REGION_SID                 	NUMBER(10), 
				TITLE 						VARCHAR2(50) 	NOT NULL,
				REFERENCE 					VARCHAR2(40),
				DESCRIPTION 				VARCHAR2(4000),
				VERSION 					VARCHAR2(50),
				COURSE_TYPE_ID 				NUMBER(10) 		NOT NULL,
				COURSE_GROUP 				NUMBER(10) 		NOT NULL,
				DELIVERY_METHOD_ID 			NUMBER(10) 		NOT NULL,
				PROVISION_ID 				NUMBER(10)		NOT NULL,
				STATUS_ID 					NUMBER(10) 		NOT NULL,
				DEFAULT_TRAINER_ID 			NUMBER(10),
				DEFAULT_PLACE_ID 			NUMBER(10),
				DURATION 					NUMBER(5) 		NOT NULL,
				EXPIRY_PERIOD 				NUMBER(5),
				EXPIRY_NOTICE_PERIOD 		NUMBER(5),
				ESCALATION_NOTICE_PERIOD 	NUMBER(5),
				REMINDER_NOTICE_PERIOD 		NUMBER(5),
				PASS_SCORE 					NUMBER(5),
				SURVEY_SID 					NUMBER(10),
				QUIZ_SID 					NUMBER(10),
				PASS_FAIL 					NUMBER(1) 		DEFAULT 0 NOT NULL,
				ABSOLUTE_DEADLINE 			DATE,
				COURSE_GROUP_DESCRIPTION	VARCHAR2(4000),
				COURSE_TYPE_LABEL			VARCHAR2(50),
				DELIVERY_METHOD_LABEL		VARCHAR2(50),
				PROVISION_LABEL				VARCHAR2(50),
				STATUS_LABEL				VARCHAR2(50),
				TRAINER_LABEL				VARCHAR2(100),
				PLACE_LABEL					VARCHAR2(4000),
				CAN_EDIT 					NUMBER(1) 		DEFAULT 0 NOT NULL
			) ON COMMIT DELETE ROWS';
		END;
	END IF;
END;
/

DECLARE
	v_cnt	NUMBER(10);
BEGIN
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'COURSE_SCHEDULE'
	   AND owner = 'CSR';
	
	IF v_cnt = 0 THEN
		BEGIN
			EXECUTE IMMEDIATE 'CREATE TABLE CSR.COURSE_SCHEDULE (
				APP_SID NUMBER(10) DEFAULT SYS_CONTEXT(''SECURITY'',''APP'') NOT NULL,
				COURSE_SCHEDULE_ID NUMBER(10) NOT NULL,
				COURSE_ID NUMBER(10) NOT NULL,
				CALENDAR_EVENT_ID NUMBER(10) NOT NULL,
				MAX_CAPACITY NUMBER(5) NOT NULL,
				TRAINER_ID NUMBER(10),
				PLACE_ID NUMBER(10),
				BOOKED NUMBER(5) DEFAULT 0 NOT NULL,
				AVAILABLE NUMBER(5) NOT NULL,
				CANCELED NUMBER(1) DEFAULT 0 NOT NULL,
				CONSTRAINT PK_COURSE_SCHEDULE PRIMARY KEY (APP_SID, COURSE_SCHEDULE_ID)
			)';
		END;
	END IF;
END;
/

DECLARE
	v_cnt	NUMBER(10);
BEGIN
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'USER_TRAINING'
	   AND owner = 'CSR';
	
	IF v_cnt = 0 THEN
		BEGIN
			EXECUTE IMMEDIATE 'CREATE TABLE CSR.USER_TRAINING (
				APP_SID NUMBER(10) DEFAULT SYS_CONTEXT(''SECURITY'',''APP'') NOT NULL,
				USER_SID NUMBER(10) NOT NULL,
				COURSE_SCHEDULE_ID NUMBER(10) NOT NULL,
				FLOW_ITEM_ID NUMBER(10) NOT NULL,
				SCORE NUMBER(5,2),
				CONSTRAINT PK_USER_TRAINING PRIMARY KEY (APP_SID, USER_SID, COURSE_SCHEDULE_ID)
			)';
		END;
	END IF;
END;
/

-- Alter tables

DECLARE
	v_cnt	NUMBER(10);
BEGIN
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'TRAINING_OPTIONS'
	   AND owner = 'CSR';
	
	IF v_cnt = 1 THEN
		BEGIN
			SELECT count(*) 
			  INTO v_cnt
			  FROM all_tab_columns
			 WHERE table_name = 'TRAINING_OPTIONS'
			   AND owner = 'CSR'
			   AND column_name = 'CALENDAR_SID';
			
			IF v_cnt = 0 THEN
				EXECUTE IMMEDIATE 'ALTER TABLE CSR.TRAINING_OPTIONS ADD CALENDAR_SID NUMBER(10)';
				EXECUTE IMMEDIATE 'ALTER TABLE CSR.TRAINING_OPTIONS ADD CONSTRAINT FK_TRAINING_OPTIONS_CALENDAR 
					FOREIGN KEY (APP_SID, CALENDAR_SID) REFERENCES CSR.CALENDAR (APP_SID, CALENDAR_SID)';
			END IF;
			
			SELECT count(*) 
			  INTO v_cnt
			  FROM all_tab_columns
			 WHERE table_name = 'TRAINING_OPTIONS'
			   AND owner = 'CSR'
			   AND column_name = 'FLOW_SID';
			
			IF v_cnt = 0 THEN
				EXECUTE IMMEDIATE 'ALTER TABLE CSR.TRAINING_OPTIONS ADD FLOW_SID NUMBER(10)';
				EXECUTE IMMEDIATE 'ALTER TABLE CSR.TRAINING_OPTIONS ADD CONSTRAINT FK_TRAINING_OPTIONS_FLOW 
					FOREIGN KEY (APP_SID, FLOW_SID) REFERENCES CSR.FLOW (APP_SID, FLOW_SID)';
			END IF;
		END;
	END IF;
END;
/

DECLARE
	v_cnt	NUMBER(10);
BEGIN
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'COURSE_SCHEDULE'
	   AND owner = 'CSR';
	
	IF v_cnt = 1 THEN
		BEGIN
			SELECT count(*) 
			  INTO v_cnt
			  FROM all_constraints
			 WHERE constraint_name = 'FK_COURSE_SCHEDULE_COURSE'
			   AND owner = 'CSR';
			   
			IF v_cnt = 1 THEN
				EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE_SCHEDULE DROP CONSTRAINT FK_COURSE_SCHEDULE_COURSE';
			END IF;
			
			SELECT count(*) 
			  INTO v_cnt
			  FROM all_constraints
			 WHERE constraint_name = 'FK_COURSE_SCHEDULE_EVENT'
			   AND owner = 'CSR';
			   
			IF v_cnt = 1 THEN
				EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE_SCHEDULE DROP CONSTRAINT FK_COURSE_SCHEDULE_EVENT';
			END IF;
			
			SELECT count(*) 
			  INTO v_cnt
			  FROM all_constraints
			 WHERE constraint_name = 'FK_COURSE_SCHEDULE_TRAINER'
			   AND owner = 'CSR';
			   
			IF v_cnt = 1 THEN
				EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE_SCHEDULE DROP CONSTRAINT FK_COURSE_SCHEDULE_TRAINER';
			END IF;
			
			SELECT count(*) 
			  INTO v_cnt
			  FROM all_constraints
			 WHERE constraint_name = 'FK_COURSE_SCHEDULE_PLACE'
			   AND owner = 'CSR';
			   
			IF v_cnt = 1 THEN
				EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE_SCHEDULE DROP CONSTRAINT FK_COURSE_SCHEDULE_PLACE';
			END IF;
			
			EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE_SCHEDULE ADD CONSTRAINT FK_COURSE_SCHEDULE_COURSE 
				FOREIGN KEY (APP_SID, COURSE_ID) REFERENCES CSR.COURSE (APP_SID, COURSE_ID)';

			EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE_SCHEDULE ADD CONSTRAINT FK_COURSE_SCHEDULE_EVENT 
				FOREIGN KEY (APP_SID, CALENDAR_EVENT_ID) REFERENCES CSR.CALENDAR_EVENT (APP_SID, CALENDAR_EVENT_ID)';

			EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE_SCHEDULE ADD CONSTRAINT FK_COURSE_SCHEDULE_TRAINER
				FOREIGN KEY (APP_SID, TRAINER_ID) REFERENCES CSR.TRAINER (APP_SID, TRAINER_ID)';

			EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE_SCHEDULE ADD CONSTRAINT FK_COURSE_SCHEDULE_PLACE
				FOREIGN KEY (APP_SID, PLACE_ID) REFERENCES CSR.PLACE (APP_SID, PLACE_ID)';
		END;
	END IF;
END;
/

DECLARE
	v_cnt	NUMBER(10);
BEGIN
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'USER_TRAINING'
	   AND owner = 'CSR';
	
	IF v_cnt = 1 THEN
		BEGIN
			SELECT count(*) 
			  INTO v_cnt
			  FROM all_constraints
			 WHERE constraint_name = 'FK_USER_TRAINING_CSR_USER'
			   AND owner = 'CSR';
			   
			IF v_cnt = 1 THEN
				EXECUTE IMMEDIATE 'ALTER TABLE CSR.USER_TRAINING DROP CONSTRAINT FK_USER_TRAINING_CSR_USER';
			END IF;
			
			SELECT count(*) 
			  INTO v_cnt
			  FROM all_constraints
			 WHERE constraint_name = 'FK_USER_TRAINING_SCHEDULE'
			   AND owner = 'CSR';
			   
			IF v_cnt = 1 THEN
				EXECUTE IMMEDIATE 'ALTER TABLE CSR.USER_TRAINING DROP CONSTRAINT FK_USER_TRAINING_SCHEDULE';
			END IF;
			
			SELECT count(*) 
			  INTO v_cnt
			  FROM all_constraints
			 WHERE constraint_name = 'FK_USER_TRAINING_FLOW_ITEM'
			   AND owner = 'CSR';
			   
			IF v_cnt = 1 THEN
				EXECUTE IMMEDIATE 'ALTER TABLE CSR.USER_TRAINING DROP CONSTRAINT FK_USER_TRAINING_FLOW_ITEM';
			END IF;
			   
			EXECUTE IMMEDIATE 'ALTER TABLE CSR.USER_TRAINING ADD CONSTRAINT FK_USER_TRAINING_CSR_USER 
				FOREIGN KEY (APP_SID, USER_SID) REFERENCES CSR.CSR_USER (APP_SID, CSR_USER_SID)';

			EXECUTE IMMEDIATE 'ALTER TABLE CSR.USER_TRAINING ADD CONSTRAINT FK_USER_TRAINING_SCHEDULE 
				FOREIGN KEY (APP_SID, COURSE_SCHEDULE_ID) REFERENCES CSR.COURSE_SCHEDULE (APP_SID, COURSE_SCHEDULE_ID)';
			
			EXECUTE IMMEDIATE 'ALTER TABLE CSR.USER_TRAINING ADD CONSTRAINT FK_USER_TRAINING_FLOW_ITEM 
				FOREIGN KEY (APP_SID, FLOW_ITEM_ID) REFERENCES CSR.FLOW_ITEM (APP_SID, FLOW_ITEM_ID)';
		END;
	END IF;
END;
/

-- FB57257
DECLARE
	v_cnt	NUMBER(10);
BEGIN
	SELECT count(*)
	  INTO v_cnt
	  FROM all_tab_cols
	 WHERE table_name = 'ISSUE_CUSTOM_FIELD'
	   AND column_name = 'FIELD_REFERENCE_NAME';
	   
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.ISSUE_CUSTOM_FIELD ADD (FIELD_REFERENCE_NAME VARCHAR2(255))';
	END IF;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Jobs ***

-- FB64371 Change job to run hourly
DECLARE
  v_check NUMBER(1);
BEGIN
  SELECT COUNT(*) INTO v_check
    FROM sys.dba_scheduler_jobs
   WHERE OWNER = 'CSR'
     AND JOB_NAME = 'CMSDATAIMPORT';

  IF v_check = 1 THEN
    DBMS_SCHEDULER.DROP_JOB(
      job_name =>   'CSR.CMSDATAIMPORT',
      force => TRUE
    );
    COMMIT;
  END IF;

  DBMS_SCHEDULER.CREATE_JOB (
    job_name        	=> 'CSR.CMSDATAIMPORT',
    job_type        	=> 'PLSQL_BLOCK',
    job_action      	=> '   
          BEGIN
          csr.user_pkg.logonadmin();
          csr.cms_data_imp_pkg.ScheduleRun();
          commit;
          END;
    ',
	job_class       	=> 'low_priority_job',
	start_date      	=> SYSTIMESTAMP,
	repeat_interval 	=> 'FREQ=HOURLY',
	enabled         	=> TRUE,
	auto_drop       	=> FALSE,
	comments        	=> 'Cms data import schedule. Check for new imports to queue in batch jobs.');
END;
/

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.capability (name, allow_by_default)
	VALUES ('Can edit course schedule', 0);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		-- it's in DB already
		NULL;
END;
/

BEGIN
	INSERT INTO csr.capability (name, allow_by_default)
	VALUES ('Can manage course requests', 0);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		-- it's in DB already
		NULL;
END;
/

BEGIN
	INSERT INTO CSR.FLOW_ALERT_CLASS (FLOW_ALERT_CLASS, LABEL)
	VALUES ('training', 'Training');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		-- it's in DB already
		NULL;
END;
/

--FB61924
BEGIN
	INSERT INTO csr.capability (name, allow_by_default)
	VALUES ('Can edit logging form restricted or locked dates', 0);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		-- it's in DB already
		NULL;
END;
/

-- *** Views ***
CREATE OR REPLACE VIEW csr.v$customer_lang AS
	SELECT ts.lang
	  FROM aspen2.translation_set ts
	 WHERE ts.application_sid = SYS_CONTEXT('SECURITY', 'APP')
	 UNION
	SELECT 'en' -- ensure english is present
	  FROM DUAL;

create or replace force view csr.v$ind as
	select i.app_sid, i.ind_sid, i.parent_sid, i.name, id.description, i.ind_type, i.tolerance_type, 
		   i.pct_upper_tolerance, i.pct_lower_tolerance, i.measure_sid, i.multiplier, i.scale,
		   i.format_mask, i.last_modified_dtm, i.active, i.target_direction, i.pos, i.info_xml,
		   i.start_month, i.divisibility, i.null_means_null, i.aggregate, i.default_interval, 
		   i.calc_start_dtm_adjustment, i.calc_end_dtm_adjustment, i.calc_fixed_start_dtm, 
		   i.calc_fixed_end_dtm, i.calc_xml, i.gri, i.lookup_key, i.owner_sid, 
		   i.ind_activity_type_id, i.core, i.roll_forward, i.factor_type_id, i.map_to_ind_sid, 
		   i.gas_measure_sid, i.gas_type_id, i.calc_description, i.normalize, 
		   i.do_temporal_aggregation, i.prop_down_region_tree_sid, i.is_system_managed,
		   i.calc_output_round_dp
	  from ind i, ind_description id
	 where id.app_sid = i.app_sid and i.ind_sid = id.ind_sid 
	   and id.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

create or replace view csr.v$delegation_ind as
	select di.app_sid, di.delegation_sid, di.ind_sid, di.mandatory, NVL(did.description, id.description) description,
		   di.pos, di.section_key, di.var_expl_group_id, di.visibility, di.css_class, di.allowed_na
	  from delegation_ind di
	  join ind_description id 
	    on di.app_sid = id.app_sid and di.ind_sid = id.ind_sid 
	   and id.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	  left join delegation_ind_description did
	    on di.app_sid = did.app_sid AND di.delegation_sid = did.delegation_sid
	   and di.ind_sid = did.ind_sid AND did.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

create or replace view csr.v$region as
	select r.app_sid, r.region_sid, r.link_to_region_sid, r.parent_sid, r.name, rd.description, r.active, 
		   r.pos, r.info_xml, r.flag, r.acquisition_dtm, r.disposal_dtm, r.region_type, 
		   r.lookup_key, r.geo_country, r.geo_region, r.geo_city_id, r.geo_longitude, r.geo_latitude, 
		   r.geo_type, r.map_entity, r.egrid_ref, r.egrid_ref_overridden, r.last_modified_dtm, r.region_ref
	  from region r, region_description rd
	 where r.app_sid = rd.app_sid and r.region_sid = rd.region_sid 
	   and rd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

create or replace view csr.v$delegation_region as
	select dr.app_sid, dr.delegation_sid, dr.region_sid, dr.mandatory, NVL(drd.description, rd.description) description,
		   dr.pos, dr.aggregate_to_region_sid, dr.visibility, dr.allowed_na, dr.hide_after_dtm, dr.hide_inclusive
	  from delegation_region dr
	  join region_description rd
	    on dr.app_sid = rd.app_sid and dr.region_sid = rd.region_sid 
	   and rd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	  left join delegation_region_description drd
	    on dr.app_sid = drd.app_sid AND dr.delegation_sid = drd.delegation_sid
	   and dr.region_sid = drd.region_sid AND drd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');
	  
-- View intended to provide delegation and the correct description for the current language.
CREATE OR REPLACE VIEW csr.v$delegation AS
	SELECT d.*, NVL(dd.description, d.name) as description, dp.SUBMIT_CONFIRMATION_TEXT as delegation_policy
	  FROM csr.delegation d
    LEFT JOIN csr.delegation_description dd ON dd.app_sid = d.app_sid 
     AND dd.delegation_sid = d.delegation_sid  
	 AND dd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
    LEFT JOIN CSR.DELEGATION_POLICY dp ON dp.app_sid = d.app_sid 
     AND dp.delegation_sid = d.delegation_sid;

CREATE OR REPLACE VIEW csr.TAG_GROUP_IR_MEMBER AS
SELECT tgm.tag_group_id, tgm.pos, t.tag_id, t.tag, region_tag.region_sid, ind_tag.ind_sid, non_compliance_tag.non_compliance_id
FROM tag_group_member tgm, 
  	tag t LEFT OUTER JOIN ind_tag ON ind_tag.tag_id = t.tag_id 
    	LEFT OUTER JOIN region_tag ON region_tag.tag_id = t.tag_id
    	LEFT OUTER JOIN non_compliance_tag ON non_compliance_tag.tag_id = t.tag_id
WHERE tgm.tag_id = t.tag_id
 AND tgm.TAG_ID = t.TAG_ID
;

create or replace force view csr.imp_val_mapped 
	(ind_description, region_description, ind_sid, region_sid, imp_ind_description, imp_region_description, 
	 imp_val_id, imp_ind_id, imp_region_id, unknown, start_dtm, end_dtm, val, file_sid, imp_session_sid, 
	 set_val_id, imp_measure_id, tolerance_type, pct_upper_tolerance, pct_lower_tolerance, note, lookup_key, region_ref,
	 map_entity, roll_forward, acquisition_dtm, a, b, c, calc_description, normalize, do_temporal_aggregation) as	 
	select i.description, r.description, i.ind_sid, r.region_sid, ii.description, ir.description, iv.imp_val_id, 
	       iv.imp_ind_id, iv.imp_region_id, iv.unknown, iv.start_dtm, iv.end_dtm, iv.val, iv.file_sid, iv.imp_session_sid, 
	       iv.set_val_id, iv.imp_measure_id, i.tolerance_type, i.pct_upper_tolerance, i.pct_lower_tolerance, iv.note, 
	       r.lookup_key, r.region_ref, r.map_entity, i.roll_forward, r.acquisition_dtm, iv.a, iv.b, iv.c, i.calc_description, 
	       i.normalize, i.do_temporal_aggregation
	  from imp_val iv, imp_ind ii, imp_region ir, v$ind i, v$region r
	 where iv.app_sid = ii.app_sid and iv.imp_ind_id = ii.imp_ind_id 
	   and iv.app_sid = ir.app_sid and iv.imp_region_id = ir.imp_region_id
	   and ii.app_sid = i.app_sid and ii.maps_to_ind_sid = i.ind_sid 
	   and ir.app_sid = r.app_sid and ir.maps_to_region_sid = r.region_sid;


-- using this view ignores any percentage ownership that was applied when the
-- value was originally saved

CREATE OR REPLACE VIEW csr.val_converted (
	app_sid, val_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number, 
	error_code, alert, flags, source_id, entry_measure_conversion_id, entry_val_number, 
	note, source_type_id, factor_a, factor_b, factor_c, changed_by_sid, changed_dtm
) AS
	SELECT v.app_sid, v.val_id, v.ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm,
	       -- we derive val_number from entry_val_number in case of pct_ownership
	       -- we round the value to avoid Arithmetic Overflows from converting Oracle Decimals to .NET Decimals
		   ROUND(NVL(NVL(mc.a, mcp.a), 1) * POWER(v.entry_val_number, NVL(NVL(mc.b, mcp.b), 1)) + NVL(NVL(mc.c, mcp.c), 0),10) val_number,
		   v.error_code,
		   v.alert, v.flags, v.source_id,
		   v.entry_measure_conversion_id, v.entry_val_number,
		   v.note, v.source_type_id,
		   NVL(mc.a, mcp.a) factor_a,
		   NVL(mc.b, mcp.b) factor_b,
		   NVL(mc.c, mcp.c) factor_c,
		   v.changed_by_sid, v.changed_dtm
	  FROM val v, measure_conversion mc, measure_conversion_period mcp
	 WHERE mc.measure_conversion_id = mcp.measure_conversion_id(+)
	   AND v.entry_measure_conversion_id = mc.measure_conversion_id(+)
	   AND (v.period_start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
	   AND (v.period_start_dtm < mcp.end_dtm or mcp.end_dtm is null);      

-- using this view ignores any percentage ownership that was applied when the
-- value was originally saved
CREATE OR REPLACE FORCE VIEW csr.sheet_value_converted 
	(app_sid, sheet_value_id, sheet_id, ind_sid, region_sid, val_number, set_by_user_sid, 
	 set_dtm, note, entry_measure_conversion_id, entry_val_number, is_inherited, 
	 status, last_sheet_value_change_id, alert, flag, factor_a, factor_b, factor_c, 
	 start_dtm, end_dtm, actual_val_number, var_expl_note, is_na) AS
  SELECT sv.app_sid, sv.sheet_value_id, sv.sheet_id, sv.ind_sid, sv.region_sid,
	       -- we derive val_number from entry_val_number in case of pct_ownership
	       -- we round the value to avoid Arithmetic Overflows from converting Oracle Decimals to .NET Decimals
		 ROUND(NVL(NVL(mc.a, mcp.a), 1) * POWER(sv.entry_val_number, NVL(NVL(mc.b, mcp.b), 1)) + NVL(NVL(mc.c, mcp.c), 0),10) val_number,		 
         sv.set_by_user_sid, sv.set_dtm, sv.note,
         sv.entry_measure_conversion_id, sv.entry_val_number,
         sv.is_inherited, sv.status, sv.last_sheet_value_change_id,
         sv.alert, sv.flag,
         NVL(mc.a, mcp.a) factor_a,
         NVL(mc.b, mcp.b) factor_b,
         NVL(mc.c, mcp.c) factor_c,
         s.start_dtm, s.end_dtm, sv.val_number actual_val_number, var_expl_note,
		 sv.is_na
    FROM sheet_value sv, sheet s, measure_conversion mc, measure_conversion_period mcp
   WHERE sv.app_sid = s.app_sid 
     AND sv.sheet_id = s.sheet_id
     AND sv.app_sid = mc.app_sid(+)
     AND sv.entry_measure_conversion_id = mc.measure_conversion_id(+)
     AND mc.app_sid = mcp.app_sid(+)
     AND mc.measure_conversion_id = mcp.measure_conversion_id(+)
     AND (s.start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
     AND (s.start_dtm < mcp.end_dtm or mcp.end_dtm is null)
;

CREATE OR REPLACE FORCE VIEW csr.PENDING_VAL_CONVERTED (
	pending_val_id, pending_ind_id, pending_region_id, pending_period_id, approval_step_id, 	
	 val_number, val_string, from_val_number, from_measure_conversion_id, action, 
	 factor_a, factor_b, factor_c, start_dtm, end_dtm, actual_val_number
) AS
  SELECT pending_val_id, pending_ind_id, pending_region_id, pv.pending_period_id, approval_step_id, 
	     NVL(NVL(mc.a, mcp.a), 1) * POWER(pv.from_val_number, NVL(NVL(mc.b, mcp.b), 1)) + NVL(NVL(mc.c, mcp.c), 0) val_number,
		val_string, 
		from_val_number, 
		from_measure_conversion_id, 
		action, 
	    NVL(mc.a, mcp.a) factor_a,
	    NVL(mc.b, mcp.b) factor_b,
	    NVL(mc.c, mcp.c) factor_c,
	    pp.start_dtm, 
	    pp.end_dtm, 
	    pv.val_number actual_val_number
    FROM pending_val pv, pending_period pp, measure_conversion mc, measure_conversion_period mcp
   WHERE pp.pending_period_id = pv.pending_period_id
     AND pv.from_measure_conversion_id = mc.measure_conversion_id(+)
     AND mc.measure_conversion_id = mcp.measure_conversion_id(+)
     AND (pp.start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
     AND (pp.start_dtm < mcp.end_dtm or mcp.end_dtm is null);

CREATE OR REPLACE VIEW csr.V$ACTIVE_USER AS
	SELECT cu.csr_user_sid, cu.email, cu.region_mount_point_sid, cu.app_sid, cu.full_name,
	  	   cu.user_name, cu.info_xml, cu.send_alerts, cu.guid, cu.friendly_name, 
	  	   ut.language, ut.culture, ut.timezone
	  FROM csr_user cu, security.user_table ut
	 WHERE cu.csr_user_sid = ut.sid_id
	   AND ut.account_enabled = 1;

CREATE OR REPLACE VIEW csr.V$MY_USER AS
  SELECT ut.account_enabled, CASE WHEN cu.line_manager_sid = SYS_CONTEXT('SECURITY','SID') THEN 1 ELSE 0 END is_direct_report, cu.*
    FROM csr.csr_user cu
    JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
   START WITH cu.line_manager_sid = SYS_CONTEXT('SECURITY','SID')
  CONNECT BY PRIOR cu.csr_user_sid = cu.line_manager_sid;

	   
CREATE OR REPLACE FORCE VIEW csr.audit_val_log AS
	SELECT changed_dtm audit_date, r.app_sid, 6 audit_type_id, vc.ind_sid object_sid, changed_by_sid user_sid,
	 	   'Set "{0}" ("{1}") to {2}: '||reason description, i.description param_1, r.description param_2, val_number param_3
	  FROM val_change vc, v$region r, v$ind i
	 WHERE vc.app_sid = r.app_sid AND vc.region_sid = r.region_sid
	   AND vc.app_sid = i.app_sid AND vc.ind_sid = i.ind_sid AND i.app_sid = r.app_sid;


/* ISSUES */
CREATE OR REPLACE VIEW csr.v$issue_pending AS
	SELECT i.app_sid, v.pending_region_id, v.pending_ind_id,  
		   p.approval_step_id, i.issue_id, i.resolved_dtm 
	  FROM issue_pending_val v, 
			(SELECT aps.app_sid, aps.approval_step_id, p.pending_period_id
			   FROM approval_step aps, pending_period p
			  WHERE aps.app_sid = p.app_sid AND aps.pending_dataset_id = p.pending_dataset_id) p,
			issue i
	 WHERE p.app_sid = v.app_sid 
	   AND p.pending_period_id = v.pending_period_id
	   AND i.issue_pending_val_id = v.issue_pending_val_id
	   AND i.deleted = 0;
	 
CREATE OR REPLACE VIEW csr.v$issue_involved_user AS
	SELECT ii.app_sid, ii.issue_id, MAX(ii.is_an_owner) is_an_owner, cu.csr_user_sid user_sid, cu.user_name, 
		   cu.full_name, cu.email, MIN(ii.from_role) from_role
	  FROM (
		SELECT ii.app_sid, ii.issue_id, is_an_owner, NVL(ii.user_sid, rrm.user_sid) user_sid,
			   CASE WHEN ii.role_sid IS NOT NULL THEN 1 ELSE 0 END from_role
		  FROM issue_involvement ii
		  JOIN issue i
			ON i.app_sid = ii.app_sid
		   AND i.issue_id = ii.issue_id
		  LEFT JOIN region_role_member rrm
			ON rrm.app_sid = i.app_sid
		   AND rrm.region_sid = i.region_sid
		   AND rrm.role_sid = ii.role_sid
		 UNION
		SELECT ii.app_sid, ii.issue_id, ii.is_an_owner, rrm.user_sid, 1 from_role
		  FROM issue_involvement ii
		  JOIN issue i
			ON i.app_sid = ii.app_sid
		   AND i.issue_id = ii.issue_id
		  JOIN region_role_member rrm
			ON rrm.app_sid = i.app_sid
		   AND rrm.region_sid = i.region_2_sid
		   AND rrm.role_sid = ii.role_sid
		) ii
	  JOIN csr_user cu
		ON ii.app_sid = cu.app_sid AND ii.user_sid = cu.csr_user_sid
	 GROUP BY ii.app_sid, ii.issue_id, cu.csr_user_sid, cu.user_name, cu.full_name, cu.email;

CREATE OR REPLACE VIEW csr.v$simple_issue AS
	SELECT i.app_sid, i.issue_id, i.label, i.source_label, i.is_visible, i.source_url, i.region_sid, i.parent_id,
	   CASE WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND rejected_by_user_sid IS NULL AND SYSDATE > due_dtm THEN 1 ELSE 0 
	   END is_overdue,
	   CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1
	   END is_resolved,
	   CASE WHEN i.closed_dtm IS NULL THEN 0 ELSE 1
	   END is_closed,
	   CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1
	   END is_rejected
  FROM issue i;
  

CREATE OR REPLACE VIEW csr.V$issue_type_rag_status AS  
    SELECT itrs.app_sid, itrs.issue_type_id, itrs.rag_status_id, itrs.pos, irs.colour, irs.label, irs.lookup_key
      FROM issue_type_rag_status itrs 
      JOIN rag_status irs ON itrs.rag_status_id = irs.rag_status_id AND itrs.app_sid = irs.app_sid;

CREATE OR REPLACE FORCE VIEW csr.v$issue AS
SELECT i.app_sid, NVL2(i.issue_ref, ist.internal_issue_ref_prefix || i.issue_ref, null) custom_issue_id, i.issue_id, i.label, i.description, i.source_label, i.is_visible, i.source_url, i.region_sid, re.description region_name, i.parent_id,
	   i.issue_escalated, i.owner_role_sid, i.owner_user_sid, cuown.user_name owner_user_name, cuown.full_name owner_full_name, cuown.email owner_email, i.first_issue_log_id, i.last_issue_log_id, NVL(lil.logged_dtm, i.raised_dtm) last_modified_dtm,
	   i.is_public, i.is_pending_assignment, i.rag_status_id, itrs.label rag_status_label, itrs.colour rag_status_colour, raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
	   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
	   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
	   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
	   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
	   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, c.more_info_1 correspondent_more_info_1,
	   sysdate now_dtm, due_dtm, forecast_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, ist.allow_children, ist.can_be_public, ist.show_forecast_dtm, ist.require_var_expl, ist.enable_reject_action,
	   i.issue_priority_id, ip.due_date_offset, ip.description priority_description,
	   CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden, i.first_priority_set_dtm,
	   issue_pending_val_id, i.issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id, issue_meter_missing_data_id, issue_supplier_id,
	   CASE WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND rejected_by_user_sid IS NULL AND SYSDATE > NVL(forecast_dtm, due_dtm) THEN 1 ELSE 0
	   END is_overdue,
	   CASE WHEN rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID') OR i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0
	   END is_owner,
	   CASE WHEN assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0 --OR #### HOW + WHERE CAN I GET THE ROLES THE USER IS PART OF??
	   END is_assigned_to_you,
	   CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1
	   END is_resolved,
	   CASE WHEN i.closed_dtm IS NULL THEN 0 ELSE 1
	   END is_closed,
	   CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1
	   END is_rejected,
	   CASE
		WHEN i.closed_dtm IS NOT NULL THEN 'Closed'
		WHEN i.resolved_dtm IS NOT NULL THEN 'Resolved'
		WHEN i.rejected_dtm IS NOT NULL THEN 'Rejected'
		ELSE 'Ongoing'
	   END status, CASE WHEN ist.auto_close_after_resolve_days IS NULL THEN NULL ELSE i.allow_auto_close END allow_auto_close,
	   ist.restrict_users_to_region, ist.deletable_by_administrator, ist.deletable_by_owner, ist.deletable_by_raiser, ist.send_alert_on_issue_raised,
	   ind.ind_sid, ind.description ind_name, isv.start_dtm, isv.end_dtm, ist.owner_can_be_changed
  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user curej, csr_user cuass, csr_user cuown,  role r, correspondent c, issue_priority ip,
	   (SELECT * FROM region_role_member WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')) rrm, v$region re, issue_log lil, v$issue_type_rag_status itrs,
	   v$ind ind, issue_sheet_value isv
 WHERE i.app_sid = curai.app_sid AND i.raised_by_user_sid = curai.csr_user_sid
   AND i.app_sid = ist.app_sid AND i.issue_type_Id = ist.issue_type_id
   AND i.app_sid = cures.app_sid(+) AND i.resolved_by_user_sid = cures.csr_user_sid(+)
   AND i.app_sid = cuclo.app_sid(+) AND i.closed_by_user_sid = cuclo.csr_user_sid(+)
   AND i.app_sid = curej.app_sid(+) AND i.rejected_by_user_sid = curej.csr_user_sid(+)
   AND i.app_sid = cuass.app_sid(+) AND i.assigned_to_user_sid = cuass.csr_user_sid(+)
   AND i.app_sid = cuown.app_sid(+) AND i.owner_user_sid = cuown.csr_user_sid(+)
   AND i.app_sid = r.app_sid(+) AND i.assigned_to_role_sid = r.role_sid(+)
   AND i.app_sid = re.app_sid(+) AND i.region_sid = re.region_sid(+)
   AND i.app_sid = c.app_sid(+) AND i.correspondent_id = c.correspondent_id(+)
   AND i.app_sid = ip.app_sid(+) AND i.issue_priority_id = ip.issue_priority_id(+)
   AND i.app_sid = rrm.app_sid(+) AND i.region_sid = rrm.region_sid(+) AND i.owner_role_sid = rrm.role_sid(+)
   AND i.app_sid = lil.app_sid(+) AND i.last_issue_log_id = lil.issue_log_id(+)
   AND i.app_sid = itrs.app_sid(+) AND i.rag_status_id = itrs.rag_status_id(+) AND i.issue_type_id = itrs.issue_type_id(+)
   AND i.app_sid = isv.app_sid(+) AND i.issue_sheet_value_id = isv.issue_sheet_value_id(+)
   AND isv.app_sid = ind.app_sid(+) AND isv.ind_sid = ind.ind_sid(+)
   AND i.deleted = 0;

CREATE OR REPLACE VIEW csr.v$issue_log AS
	SELECT il.app_sid, il.issue_log_id, il.issue_Id, il.message, il.logged_by_user_sid, 
		   cu.user_name logged_by_user_name, cu.email logged_by_email, il.logged_dtm,
		   il.is_system_generated, param_1, param_2, param_3, sysdate now_dtm,
		   CASE WHEN il.logged_by_user_sid IS NULL THEN 0 ELSE 1 END is_user,
		   CASE WHEN il.logged_by_user_sid IS NULL THEN ilc.full_name ELSE cu.full_name END logged_by_full_name
	  FROM issue_log il
	  LEFT JOIN csr_user cu ON il.app_sid = cu.app_sid AND il.logged_by_user_sid = cu.csr_user_sid
	  LEFT JOIN correspondent ilc ON il.logged_by_correspondent_id = ilc.correspondent_id
;

CREATE OR REPLACE VIEW csr.v$issue_type_perm_default
AS
	SELECT t.app_sid, t.issue_type_id,
			NVL(p.require_due_date, 0) require_due_date, NVL(p.allow_due_date, 1) allow_due_date, 
			NVL(p.require_priority, 0) require_priority, NVL(p.allow_priority, 1) allow_priority, 
			NVL(p.require_assign_user, 0) require_assign_user, NVL(p.allow_assign_user, 1) allow_assign_user, 
			NVL(p.require_assign_role, 0) require_assign_role, NVL(p.allow_assign_role, 1) allow_assign_role, 
			NVL(p.require_region, 0) require_region, NVL(p.allow_region, 1) allow_region
	  FROM issue_type t, (SELECT * FROM issue_type_state_perm WHERE issue_state_id = 0) p
	 WHERE t.app_sid = p.app_sid(+)
	   AND t.issue_type_id = p.issue_type_id(+);

CREATE OR REPLACE VIEW csr.v$issue_type_perm 
AS
	SELECT ts.app_sid, ts.issue_type_id, ts.issue_state_id,
			NVL(p.require_due_date, d.require_due_date) require_due_date, NVL(p.allow_due_date, d.allow_due_date) allow_due_date,
			NVL(p.require_priority, d.require_priority) require_priority, NVL(p.allow_priority, d.allow_priority) allow_priority,
			NVL(p.require_assign_user, d.require_assign_user) require_assign_user, NVL(p.allow_assign_user, d.allow_assign_user) allow_assign_user,
			NVL(p.require_assign_role, d.require_assign_role) require_assign_role, NVL(p.allow_assign_role, d.allow_assign_role) allow_assign_role,
			NVL(p.require_region, d.require_region) require_region, NVL(p.allow_region, d.allow_region) allow_region
	  FROM (SELECT t.app_sid, t.issue_type_id, s.issue_state_id FROM issue_type t, issue_state s WHERE s.issue_state_id <> 0) ts, 
	       issue_type_state_perm p, 
		   v$issue_type_perm_default d
	 WHERE ts.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND ts.app_sid = p.app_sid(+)
	   AND ts.issue_state_id = p.issue_state_id(+)
	   AND ts.issue_type_id = p.issue_type_id(+)
	   AND ts.app_sid = d.app_sid
	   AND ts.issue_type_id = d.issue_type_id
;

      
CREATE OR REPLACE VIEW csr.v$postit AS
    SELECT p.app_sid, p.postit_id, p.message, p.label, p.secured_via_sid, p.created_dtm, p.created_by_sid,
        pu.user_name created_by_user_name, pu.full_name created_by_full_name, pu.email created_by_email,
		CASE WHEN p.created_by_sid = SYS_CONTEXT('SECURITY','SID') THEN 1
			 WHEN p.created_by_sid = 3 -- 3 == security.security_pkg.SID_BUILTIN_ADMINISTRATOR, but we can't use that here
			 THEN security.security_pkg.SQL_IsAccessAllowedSID(security_pkg.getACT, p.secured_via_sid, 2) -- 2 == security.security_pkg.PERMISSION_WRITE, ditto
			 ELSE 0 END can_edit
      FROM postit p 
        JOIN csr_user pu ON p.created_by_sid = pu.csr_user_sid AND p.app_sid = pu.app_sid;
	 
CREATE OR REPLACE VIEW csr.v$doc_current AS
	SELECT dc.parent_sid, dc.doc_id, dc.locked_by_sid, dc.pending_version,
		   df.lifespan, 
		   dv.version, dv.filename, dv.description, dv.change_description, dv.changed_by_sid, dv.changed_dtm, 
		   dd.doc_data_id, dd.data, dd.sha1, dd.mime_type
	  FROM doc_current dc
		JOIN doc_folder df ON dc.parent_sid = df.doc_folder_sid
		LEFT JOIN doc_version dv ON dc.doc_id = dv.doc_id AND dc.version = dv.version 
		LEFT JOIN doc_data dd ON dv.doc_data_id = dd.doc_data_id;


CREATE OR REPLACE VIEW csr.v$doc_approved AS
	SELECT dc.parent_sid, dc.doc_id, dc.locked_by_sid, dc.pending_version,
		   dc.version,
		   df.lifespan, 
		   dv.filename, dv.description, dv.change_description, dv.changed_by_sid, dv.changed_dtm, 
		   dd.sha1, dd.mime_type, dd.data, dd.doc_data_id,
		   CASE WHEN dc.locked_by_sid = SYS_CONTEXT('SECURITY','SID') THEN 1 ELSE 0 END locked_by_me,
		   CASE	
				WHEN df.lifespan IS NULL THEN 0
				WHEN SYSDATE > ADD_MONTHS(dv.changed_dtm, df.lifespan) THEN 2 -- csr_data_pkg.DOCLIB_EXPIRED
				WHEN SYSDATE > ADD_MONTHS(dv.changed_dtm, df.lifespan - 1) THEN 1 -- csr_data_pkg.DOCLIB_NEARLY_EXPIRED
				ELSE 0
		   END expiry_status,
		   dd.app_sid
	  FROM doc_current dc
		JOIN doc_folder df ON dc.parent_sid = df.doc_folder_sid
		LEFT JOIN doc_version dv ON dc.doc_id = dv.doc_id AND dc.version = dv.version 
		LEFT JOIN doc_data dd ON dv.doc_data_id = dd.doc_data_id
		-- don't return stuff that's added but never approved
	   WHERE dc.version IS NOT NULL; 

-- right -> show the user pending stuff IF:
--   * locked_by_sid => is this user
--   * show filename etc of pending file (but null version) if dc.version is null
CREATE OR REPLACE VIEW csr.v$doc_current_status AS
	SELECT parent_sid, doc_id, locked_by_sid, pending_version, 
		version, lifespan,
		filename, description, change_description, changed_by_sid, changed_dtm,
		sha1, mime_type, data, doc_data_id,
		locked_by_me, expiry_status
	  FROM v$doc_approved
	   WHERE NVL(locked_by_sid,-1) != SYS_CONTEXT('SECURITY','SID') OR pending_version IS NULL
	   UNION ALL
	SELECT dc.parent_sid, dc.doc_id, dc.locked_by_sid, dc.pending_version,
			-- if it's the approver then show them the right version, otherwise pass through null (i.e. dc.version) to other users so they can't fiddle
		   CASE WHEN NVL(dc.locked_by_sid,-1) = SYS_CONTEXT('SECURITY','SID') AND dc.pending_version IS NOT NULL THEN dc.pending_version ELSE dc.version END version,		   
		   df.lifespan, 
		   dvp.filename, dvp.description, dvp.change_description, dvp.changed_by_sid, dvp.changed_dtm, 
		   ddp.sha1, ddp.mime_type, ddp.data, ddp.doc_data_id,
		   CASE WHEN dc.locked_by_sid = SYS_CONTEXT('SECURITY','SID') THEN 1 ELSE 0 END locked_by_me,
		   CASE	
				WHEN df.lifespan IS NULL THEN 0
				WHEN SYSDATE > ADD_MONTHS(dvp.changed_dtm, df.lifespan) THEN 2 -- csr_data_pkg.DOCLIB_EXPIRED
				WHEN SYSDATE > ADD_MONTHS(dvp.changed_dtm, df.lifespan - 1) THEN 1 -- csr_data_pkg.DOCLIB_NEARLY_EXPIRED
				ELSE 0
		   END expiry_status		
	  FROM doc_current dc
		JOIN doc_folder df ON dc.parent_sid = df.doc_folder_sid
		LEFT JOIN doc_version dvp ON dc.doc_id = dvp.doc_id AND dc.pending_version = dvp.version 
		LEFT JOIN doc_data ddp ON dvp.doc_data_id = ddp.doc_data_id
	   WHERE (NVL(dc.locked_by_sid,-1) = SYS_CONTEXT('SECURITY','SID') AND dc.pending_version IS NOT NULL) OR dc.version IS null;

create or replace view csr.v$doc_folder_root as
	select dl.doc_library_sid, dl.documents_sid, dl.trash_folder_sid, t.sid_id doc_folder_sid from (
		select connect_by_root sid_id doc_library_sid, so.sid_id
	  	  from security.securable_object so
	           start with sid_id in (select doc_library_sid from doc_library dl)
	       	   connect by prior sid_id = parent_sid_id) t, doc_library dl
     where t.doc_library_sid = dl.doc_library_sid;


-- provides more human readable information about pvc_stored_calc_jobs
create or replace view csr.v$pvc_stored_calc_job as
	select c.host, pi.description ind_description, pr.description region_description, pp.start_dtm, pp.end_dtm, processing, pi.pending_ind_id, pr.pending_region_id, pp.pending_period_id
	  from pvc_stored_calc_job cirj, pending_dataset pd, customer c, pending_ind pi, pending_region pr, pending_period pp
	 where cirj.pending_dataset_Id = pd.pending_dataset_id
	   and pd.app_sid = c.app_sid
	   and cirj.calc_pending_ind_id = pi.pending_ind_id
	   and cirj.pending_region_id = pr.pending_region_id
	   and cirj.pending_period_id = pp.pending_period_id;
	   
-- provides more human readable information about pvc_region_recalc_jobs
create or replace view csr.v$pvc_region_recalc_job as
	select c.host, pi.description ind_description, processing, pi.pending_ind_id, pd.pending_dataset_id
	  from pvc_region_recalc_job rrj, pending_dataset pd, customer c, pending_ind pi
	 where rrj.pending_dataset_Id = pd.pending_dataset_id
	   and pd.app_sid = c.app_sid
	   and rrj.pending_ind_id = pi.pending_ind_id;

-- provides more human readable information about pending_val_cache
create or replace view csr.v$pending_val_cache as
	select host, pi.description ind_description, pr.description region_description, pp.start_dtm, pp.end_dtm, val_number,
		pi.pending_ind_id, pr.pending_region_id, pp.pending_period_id, pd.pending_dataset_id
	  from pending_val_cache pvc, pending_ind pi, pending_region pr, pending_period pp, pending_dataset pd, customer c
	 where pvc.pending_ind_Id = pi.pending_ind_id
	   and pvc.pending_region_id = pr.pending_region_id
	   and pvc.pending_period_id = pp.pending_period_id
	   and pi.pending_dataset_Id = pd.pending_dataset_id
	   and pd.app_sid = c.app_sid;
	   
-- provides more human readable information about pending_val
create or replace view csr.v$pending_val as
	select host, pv.pending_val_id, pi.description ind_description, pr.description region_description, pp.start_dtm, pp.end_dtm, val_number,
		val_string, from_val_number, from_measure_conversion_id, action, note, pv.approval_step_id,
		pi.pending_ind_id, pr.pending_region_id, pp.pending_period_id, pd.pending_dataset_id
	  from pending_val pv, pending_ind pi, pending_region pr, pending_period pp, pending_dataset pd, customer c
	 where pv.pending_ind_Id = pi.pending_ind_id
	   and pv.pending_region_id = pr.pending_region_id
	   and pv.pending_period_id = pp.pending_period_id
	   and pi.pending_dataset_Id = pd.pending_dataset_id
	   and pd.app_sid = c.app_sid;

-- provides more human readable information about pending_region (query using pending_dataset_id)
create or replace view csr.v$pending_region as
	select pending_dataset_id, lpad(' ', (level-1)*4)||description description, pending_region_id, maps_to_region_sid
	  from pending_region
	 start with parent_region_id is null
	connect by prior pending_region_id = parent_region_id;

CREATE OR REPLACE VIEW csr.METER AS
  SELECT APP_SID,REGION_SID, NOTE, PRIMARY_IND_SID, PRIMARY_MEASURE_CONVERSION_ID, METER_SOURCE_TYPE_ID, REFERENCE, CRC_METER,
	COST_IND_SID, COST_MEASURE_CONVERSION_ID, DAYS_IND_SID, DAYS_MEASURE_CONVERSION_ID, COSTDAYS_IND_SID, COSTDAYS_MEASURE_CONVERSION_ID,
	APPROVED_BY_SID, APPROVED_DTM, IS_CORE
    FROM ALL_METER
   WHERE ACTIVE = 1;
   
CREATE OR REPLACE VIEW csr.V$TAB_USER AS
	SELECT t.TAB_ID, t.APP_SID, t.LAYOUT, t.NAME, t.IS_SHARED, tu.USER_SID, tu.POS, tu.IS_OWNER, tu.IS_HIDDEN, t.PORTAL_GROUP
	  FROM TAB t, TAB_USER tu
	 WHERE t.TAB_ID = tu.TAB_ID;
	 
	
CREATE OR REPLACE VIEW csr.V$GET_VALUE_RESULT_FILES AS
		SELECT r.source_id, fu.file_upload_sid, fu.filename, fu.mime_type
		  FROM get_value_result r, val_file vf, file_upload fu
		 WHERE r.source = 0 AND vf.val_id = r.source_id AND fu.file_upload_sid = vf.file_upload_sid
	 UNION ALL
		SELECT r.source_id, fu.file_upload_sid, fu.filename, fu.mime_type
		  FROM get_value_result r, sheet_value_file svf, file_upload fu
		 WHERE r.source = 1 AND svf.sheet_value_id = r.source_id AND fu.file_upload_sid = svf.file_upload_sid;

CREATE OR REPLACE VIEW csr.V$AUTOCREATE_USER AS
	SELECT user_name, app_sid, guid, requested_dtm, approved_dtm, approved_by_user_sid, created_user_sid, activated_dtm
	  FROM autocreate_user
	 WHERE rejected_dtm IS NULL;

CREATE OR REPLACE FORCE VIEW csr.V$IMP_VAL_MAPPED AS
    SELECT iv.imp_val_id, iv.imp_session_Sid, iv.file_sid, ii.maps_to_ind_sid, iv.start_dtm, iv.end_dtm, 
           ii.description ind_description,
           i.description maps_to_ind_description,
           ir.description region_description,
           i.aggregate,
           iv.val,			               				
           NVL(NVL(mc.a, mcp.a),1) factor_a,
           NVL(NVL(mc.b, mcp.b),1) factor_b,
           NVL(NVL(mc.c, mcp.c),0) factor_c,
           m.description measure_description,
           im.maps_to_measure_conversion_id,
           mc.description from_measure_description,
           NVL(i.format_mask, m.format_mask) format_mask,
           ir.maps_to_region_sid, 
           iv.rowid rid,
           ii.app_Sid, iv.note,
           CASE WHEN m.custom_field LIKE '|%' THEN 1 ELSE 0 END is_text_ind,
           icv.imp_conflict_id,
           m.measure_sid,
           iv.imp_ind_id, iv.imp_region_id,
           CASE WHEN rm.ind_Sid IS NOT NULL THEN 1 ELSE 0 END is_region_metric,
           CASE WHEN rmr.region_Sid IS NOT NULL THEN 1 ELSE 0 END region_metric_region_exists,
           rmr.measure_conversion_id region_metric_conversion_id
      FROM imp_val iv
           JOIN imp_ind ii ON iv.imp_ind_id = ii.imp_ind_id AND iv.app_sid = ii.app_sid AND ii.maps_to_ind_sid IS NOT NULL
           JOIN imp_region ir ON iv.imp_region_id = ir.imp_region_id AND iv.app_sid = ir.app_sid AND ir.maps_to_region_sid IS NOT NULL
           LEFT JOIN imp_measure im 
                ON  iv.imp_ind_id = im.imp_ind_id 
                AND iv.imp_measure_id = im.imp_measure_id 
                AND iv.app_sid = im.app_sid
           LEFT JOIN measure_conversion mc
                ON im.maps_to_measure_conversion_id = mc.measure_conversion_id
                AND im.app_sid = mc.app_sid
           LEFT JOIN measure_conversion_period mcp                
                ON mc.measure_conversion_id = mcp.measure_conversion_id
                AND (iv.start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
                AND (iv.start_dtm < mcp.end_dtm or mcp.end_dtm is null)
           LEFT JOIN imp_conflict_val icv
                ON iv.imp_val_id = icv.imp_val_id
                AND iv.app_sid = icv.app_sid
           JOIN v$ind i 
                ON ii.maps_to_ind_sid = i.ind_sid
                AND ii.app_sid = i.app_sid
                AND i.ind_type = 0 
           LEFT JOIN region_metric rm
				ON i.ind_sid = rm.ind_sid AND i.app_sid = rm.app_sid
           LEFT JOIN region_metric_region rmr
				ON rm.ind_sid = rmr.ind_sid AND rm.app_sid = rmr.app_sid
				AND ir.maps_to_region_sid = rmr.region_sid AND ir.app_sid = rmr.app_sid
           JOIN measure m 
                ON i.measure_sid = m.measure_sid 
                AND i.app_sid = m.app_sid;

CREATE OR REPLACE FORCE VIEW csr.V$IMP_MERGE AS
	SELECT * FROM v$imp_val_mapped 
	  WHERE imp_conflict_id is null;

CREATE OR REPLACE VIEW csr.v$calc_dependency (app_sid, calc_ind_sid, calc_ind_type, dep_type, ind_sid, ind_type, calc_start_dtm_adjustment, calc_end_dtm_adjustment) AS
	SELECT cd.app_sid, cd.calc_ind_sid, ci.ind_type, cd.dep_type, NVL(gi.ind_sid, i.ind_sid), NVL(gi.ind_type, i.ind_type), ci.calc_start_dtm_adjustment, ci.calc_end_dtm_adjustment
	  FROM calc_dependency cd
	  JOIN ind i
			ON cd.app_sid = i.app_sid
		   AND cd.ind_sid = i.ind_sid
	  JOIN ind ci
			ON cd.app_sid = ci.app_sid
		   AND cd.calc_ind_sid = ci.ind_sid
	  LEFT JOIN ind gi
			ON i.app_sid = gi.app_sid
		   AND i.ind_sid = gi.map_to_ind_sid
		   AND ci.gas_type_id = gi.gas_type_id
		   AND ci.map_to_ind_sid != gi.map_to_ind_sid
	 WHERE (i.measure_sid IS NOT NULL -- don't fetch things that have no unit of measure
	        OR EXISTS(SELECT * FROM model_map WHERE app_sid = cd.app_sid and model_sid = cd.ind_sid))
	   AND cd.dep_type = 1 -- csr_data_pkg.DEP_ON_INDICATOR
	 UNION
	SELECT cd.app_sid, cd.calc_ind_sid, ci.ind_type, cd.dep_type, NVL(gi.ind_sid, i.ind_sid), NVL(gi.ind_type, i.ind_type), ci.calc_start_dtm_adjustment, ci.calc_end_dtm_adjustment
	  FROM calc_dependency cd
	  JOIN ind i
			ON cd.app_sid = i.app_sid
		   AND cd.ind_sid = i.parent_sid
	  JOIN ind ci
			ON cd.app_sid = ci.app_sid
		   AND cd.calc_ind_sid = ci.ind_sid
	  LEFT JOIN ind gi
			ON i.app_sid = gi.app_sid
		   AND i.ind_sid = gi.map_to_ind_sid
		   AND ci.gas_type_id = gi.gas_type_id
		   AND ci.map_to_ind_sid != gi.map_to_ind_sid
	 WHERE cd.dep_type = 2 -- csr_data_pkg.DEP_ON_CHILDREN
	   AND i.measure_sid IS NOT NULL -- don't fetch things that have no unit of measure
	   AND (
			(i.map_to_ind_sid IS NULL) -- normal indicators or gas indicators depending on something that's not emission tracked
			OR
			(ci.map_to_ind_sid IS NOT NULL AND ci.ind_sid != gi.ind_sid AND ci.gas_type_id = gi.gas_type_id) -- gas
	)
	 UNION
	SELECT cd.app_sid, cd.calc_ind_sid, 1, cd.dep_type, mm.map_to_indicator_sid, 0, mi.calc_start_dtm_adjustment, mi.calc_end_dtm_adjustment
	  FROM calc_dependency cd
	  JOIN model_map mm
		    ON cd.app_sid = mm.app_sid
		   AND cd.calc_ind_sid = mm.model_sid
	  JOIN ind mi
	        ON mm.app_sid = mi.app_sid
	       AND mm.model_sid = mi.ind_sid
	 WHERE cd.dep_type = 3 -- csr_data_pkg.DEP_ON_MODEL
	   AND mm.model_map_type_id = 2
	   AND mm.map_to_indicator_sid IS NOT NULL
;

CREATE OR REPLACE VIEW csr.v$calc_direct_dependency (app_sid, calc_ind_sid, calc_ind_type, dep_type, ind_sid, ind_type, calc_start_dtm_adjustment, calc_end_dtm_adjustment) AS
	SELECT cd.app_sid, cd.calc_ind_sid, ci.ind_type, cd.dep_type, NVL(gi.ind_sid, i.ind_sid), NVL(gi.ind_type, i.ind_type), ci.calc_start_dtm_adjustment, ci.calc_end_dtm_adjustment
	  FROM calc_dependency cd
	  JOIN ind i
			ON cd.app_sid = i.app_sid
		   AND cd.ind_sid = i.ind_sid
	  JOIN ind ci
			ON cd.app_sid = ci.app_sid
		   AND cd.calc_ind_sid = ci.ind_sid
	  LEFT JOIN ind gi
			ON i.app_sid = gi.app_sid
		   AND i.ind_sid = gi.map_to_ind_sid
		   AND ci.gas_type_id = gi.gas_type_id
		   AND ci.map_to_ind_sid != gi.map_to_ind_sid
	 WHERE (i.measure_sid IS NOT NULL -- don't fetch things that have no unit of measure
	        OR EXISTS(SELECT * FROM model_map WHERE app_sid = cd.app_sid and model_sid = cd.ind_sid))
	   AND cd.dep_type IN (1, 2) -- csr_data_pkg.DEP_ON_INDICATOR, csr_data_pkg.DEP_ON_CHILDREN
	 UNION
	SELECT cd.app_sid, cd.calc_ind_sid, 1, cd.dep_type, mm.map_to_indicator_sid, 0, mi.calc_start_dtm_adjustment, mi.calc_end_dtm_adjustment
	  FROM calc_dependency cd
	  JOIN model_map mm
		    ON cd.app_sid = mm.app_sid
		   AND cd.calc_ind_sid = mm.model_sid
	  JOIN ind mi
	        ON mm.app_sid = mi.app_sid
	       AND mm.model_sid = mi.ind_sid
	 WHERE cd.dep_type = 3 -- csr_data_pkg.DEP_ON_MODEL
	   AND mm.model_map_type_id = 2
	   AND mm.map_to_indicator_sid IS NOT NULL
;

-- Well, this gave me a headache.
-- What it does is to first figure out what time it is in the user's timezone.  Then we stick with their timezone and:
-- a. Figure out what time they want the batch to run at, i.e. knock the time part off and set it to the batch run time
-- b. Decide when the next time to fire the trigger is. If the trigger time was in the past we add one day (i.e. do it tomorrow).
-- c. Figure out when the previous time to fire the trigger was (i.e. b - 1 day).
-- Then everything gets converted back to GMT.  Most of the columns in the view aren't necessary, but are left there
-- for ease of figuring out what's going on.
--
-- To run a batch using this, the idea is:
-- a. fill alert_batch_run info out for missing users so we know the next trigger fire time for all users
-- b. join $your_query to alert_batch_run and just do those jobs where systimestamp >= prev_fire_time_gmt
-- c. after running a batch for a user update their next fire time from query a).  You have to save this and NOT
-- requery!  (The next fire time computed above accounts for DST changes, i.e. clocks going forward one day by 1 hour
-- means that the next fire time will be 23 hours after the previous fire time instead of 24)
-- 
-- This method accounts for missed ticks, e.g. if you set a batch to run at 23:59 we may end up running a bit late, at 00.01
-- the next day.
--
-- Now the annoying bit is if the user changes timezone, the next fire time will be wrong.  To fix that
-- the last fire time should be converted to the new timezone, then the next tick computed based on that (using the
-- if in the past, that time tomorrow; if in the future at that time method as below).  I haven't actually fixed
-- this as I guess alerts going out at the wrong time once isn't a big deal (and I have a headache).
create or replace view csr.v$alert_batch_run_time as
	select app_sid, csr_user_sid, alert_batch_run_time, user_tz,
		   user_run_at, user_run_at at time zone 'Etc/GMT' user_run_at_gmt,
		   user_current_time, user_current_time at time zone 'Etc/GMT' user_current_time_gmt,
		   next_fire_time, next_fire_time at time zone 'Etc/GMT' next_fire_time_gmt,	
		   next_fire_time - numtodsinterval(1,'DAY') prev_fire_time,
		   (next_fire_time - numtodsinterval(1,'DAY')) at time zone 'Etc/GMT' prev_fire_time_gmt
	  from (select app_sid, csr_user_sid, alert_batch_run_time, user_run_at, user_current_time,
		   		   case when user_run_at < user_current_time then user_run_at + numtodsinterval(1,'DAY') else user_run_at end next_fire_time,
		   		   user_tz
			  from (select app_sid, csr_user_sid, alert_batch_run_time,
						   from_tz_robust(cast(trunc(user_current_time) + alert_batch_run_time as timestamp), user_tz) user_run_at,
						   user_current_time, user_tz
			  		  from (select cu.app_sid, cu.csr_user_sid, alert_batch_run_time,
								   systimestamp at time zone COALESCE(ut.timezone, a.timezone, 'Etc/GMT') user_current_time,
								   COALESCE(ut.timezone, a.timezone, 'Etc/GMT') user_tz
							  from security.user_table ut, security.application a, csr_user cu, customer c
							 where cu.csr_user_sid = ut.sid_id
							   and c.app_sid = cu.app_sid
							   and a.application_sid_id = c.app_sid)));

CREATE OR REPLACE VIEW csr.sheet_with_last_action AS
	SELECT sh.app_sid, sh.sheet_id, sh.delegation_sid, sh.start_dtm, sh.end_dtm, sh.reminder_dtm, sh.submission_dtm, 
		   she.sheet_action_id last_action_id, she.from_user_sid last_action_from_user_sid, she.action_dtm last_action_dtm, 
		   she.note last_action_note, she.to_delegation_sid last_action_to_delegation_sid, 
		   CASE WHEN SYSTIMESTAMP AT TIME ZONE COALESCE(ut.timezone, a.timezone, 'Etc/GMT') >= from_tz_robust(cast(sh.submission_dtm as timestamp), COALESCE(ut.timezone, a.timezone, 'Etc/GMT'))
                 AND she.sheet_action_id IN (0,10,2) 
                    THEN 1 
				WHEN SYSTIMESTAMP AT TIME ZONE COALESCE(ut.timezone, a.timezone, 'Etc/GMT') >= from_tz_robust(cast(sh.reminder_dtm as timestamp), COALESCE(ut.timezone, a.timezone, 'Etc/GMT')) 
                 AND she.sheet_action_id IN (0,10,2)
                    THEN 2 
				ELSE 3
		   END status, sh.is_visible, sh.last_sheet_history_id, sha.colour last_action_colour, sh.is_read_only, sh.percent_complete,
		   sha.description last_action_desc, sha.downstream_description last_action_downstream_desc
	 FROM sheet sh
		JOIN sheet_history she ON sh.last_sheet_history_id = she.sheet_history_id AND she.sheet_id = sh.sheet_id AND sh.app_sid = she.app_sid
		JOIN sheet_action sha ON she.sheet_action_id = sha.sheet_action_id
        LEFT JOIN csr.csr_user u ON u.csr_user_sid = SYS_CONTEXT('SECURITY','SID') AND u.app_sid = sh.app_sid
        LEFT JOIN security.user_table ut ON ut.sid_id = u.csr_user_sid
        LEFT JOIN security.application a ON a.application_sid_id = u.app_sid;

CREATE OR REPLACE VIEW csr.v$delegation_user AS
    SELECT app_sid, delegation_sid, user_sid
      FROM delegation_user
     UNION -- removes duplicates introduced by join to delegation_region etc
    SELECT d.app_sid, d.delegation_sid, rrm.user_sid
      FROM delegation d
        JOIN delegation_role dlr ON d.delegation_sid = dlr.delegation_sid AND d.app_sid = dlr.app_sid
        JOIN delegation_region dr ON d.delegation_sid = dr.delegation_sid AND d.app_sid = dr.app_sid
        JOIN region_role_member rrm ON dr.region_sid = rrm.region_sid AND dlr.role_sid = rrm.role_sid AND dr.app_sid = rrm.app_sid AND dlr.app_sid = rrm.app_sid
        ;

CREATE OR REPLACE VIEW csr.delegation_delegator (app_sid, delegation_sid, delegator_sid) AS
	SELECT d.app_sid, d.delegation_sid, du.user_sid
	  FROM delegation d, v$delegation_user du
	 WHERE d.app_sid = du.app_sid AND d.parent_sid = du.delegation_sid;

CREATE OR REPLACE VIEW csr.v$deleg_region_role_user AS
    SELECT d.app_sid, d.delegation_sid, dr.region_sid, dlr.role_sid, rrm.user_sid, dlr.is_read_only
      FROM delegation d
        JOIN delegation_role dlr ON d.delegation_sid = dlr.delegation_sid AND d.app_sid = dlr.app_sid
        JOIN delegation_region dr ON d.delegation_sid = dr.delegation_sid AND d.app_sid = dr.app_sid
        JOIN region_role_member rrm ON dr.region_sid = rrm.region_sid AND dlr.role_sid = rrm.role_sid AND dr.app_sid = rrm.app_sid AND dlr.app_sid = rrm.app_sid
        ;
        
-- Normal site users, both active and inactive (and including the active flag plus other 
-- things from security.user_table), but excluding trashed and hidden users
CREATE OR REPLACE VIEW csr.v$csr_user AS
	SELECT cu.app_sid, cu.csr_user_sid, cu.email, cu.region_mount_point_sid, cu.full_name, cu.user_name, cu.send_alerts,
		   cu.guid, cu.friendly_name, cu.info_xml, cu.show_portal_help, cu.donations_browse_filter_id, cu.donations_reports_filter_id,
		   cu.hidden, cu.phone_number, cu.job_title, ut.account_enabled active, ut.last_logon, cu.created_dtm, ut.expiration_dtm, 
		   ut.language, ut.culture, ut.timezone, so.parent_sid_id, cu.last_modified_dtm, cu.last_logon_type_Id, cu.line_manager_sid
      FROM csr_user cu, security.securable_object so, security.user_table ut, customer c
     WHERE cu.app_sid = c.app_sid
       AND cu.csr_user_sid = so.sid_id
       AND so.parent_sid_id != c.trash_sid
       AND ut.sid_id = so.sid_id
       AND cu.hidden = 0;

/********************************************* WORKFLOW ***************************************************/
-- View showing current state of items in workflow
CREATE OR REPLACE VIEW csr.V$FLOW_ITEM AS
    SELECT fi.app_sid, fi.flow_sid, fi.flow_item_id, f.label flow_label,
		fs.flow_state_id current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key,
		fs.state_colour current_state_colour, 
		fi.last_flow_state_log_id, fi.last_flow_state_transition_id,
        fi.survey_response_id, fi.dashboard_instance_id  -- deprecated
      FROM flow_item fi
	    JOIN flow f ON fi.flow_sid = f.flow_sid
        JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid 
    ;   


-- View showing all items in workflow, all roles where the current user is a member, and all regions for those roles.
-- You never want to just select from this, i.e. you would want to join this view to a workflow item detail table
-- which would also have information about which region the workflow item was applicable to (which reduces the returned
-- rows significantly ;)). 
--
-- A typical usage would be:
--
--    SELECT firm.flow_sid, firm.flow_item_id, firm.current_state_id, 
--        firm.current_state_label, firm.role_sid, firm.role_name, fsr.is_editable,
--        r.region_sid, r.description region_description,
--        adi.dashboard_instance_id, adi.start_dtm, adi.end_dtm
--      FROM V$FLOW_ITEM_ROLE_MEMBER firm
--        JOIN approval_dashboard_instance adi ON firm.dashboard_instance_id = adi.dashboard_instance_id 
--        JOIN region r ON adi.region_sid = r.region_sid AND firm.region_sid = r.region_sid      
--     WHERE adi.approval_dashboard_sid = in_dashboard_sid
--	     AND start_dtm = in_start_dtm
--	     AND end_dtm = in_end_dtm
--	   ORDER BY transition_pos;
CREATE OR REPLACE VIEW csr.V$FLOW_ITEM_ROLE_MEMBER AS
    SELECT fi.*, r.role_sid, r.name role_name, rrm.region_sid, fsr.is_editable
      FROM V$FLOW_ITEM fi
        JOIN flow_state_role fsr ON fi.current_state_id = fsr.flow_state_id AND fi.app_sid = fsr.app_sid
        JOIN role r ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
        JOIN region_role_member rrm ON r.role_sid = rrm.role_sid AND r.app_sid = rrm.app_sid AND rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
    ;
 

-- View showing items in workflow and possible future transitions
CREATE OR REPLACE VIEW csr.V$FLOW_ITEM_TRANSITION AS
    SELECT fst.app_sid, fi.flow_sid, fi.flow_item_Id, fst.flow_state_transition_id, fst.verb, 
		fs.flow_state_id from_state_id, fs.label from_state_label, fs.state_colour from_state_colour,
        tfs.flow_state_id to_state_id, tfs.label to_state_label, tfs.state_colour to_state_colour,
        fst.ask_for_comment, fst.pos transition_pos, fst.button_icon_path,
        fi.survey_response_id, fi.dashboard_instance_id -- these are deprecated
      FROM flow_item fi           
        JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid
        JOIN flow_state_transition fst ON fs.flow_state_id = fst.from_state_id AND fs.app_sid = fst.app_sid
        JOIN flow_state tfs ON fst.to_state_id = tfs.flow_state_id AND fst.app_sid = tfs.app_sid AND tfs.is_deleted = 0;

-- View showing all items in workflow where there are transitions where the current user is a member, and all regions for those roles.
-- You never want to just select from this, i.e. you would want to join this view to a workflow item detail table
-- which would also have information about which region the workflow item was applicable to (which reduces the returned
-- rows significantly ;)). 
--
-- A typical usage would be:
--
--    SELECT trm.flow_item_id, trm.flow_state_transition_id, trm.verb, trm.to_state_id, 
--        trm.to_state_label, trm.ask_for_comment, trm.role_sid, trm.role_name,
--        r.region_sid, r.description region_description,
--        adi.dashboard_instance_id, adi.start_dtm, adi.end_dtm
--      FROM V$FLOW_ITEM_TRANS_ROLE_MEMBER trm
--        JOIN approval_dashboard_instance adi ON trm.dashboard_instance_id = adi.dashboard_instance_id 
--        JOIN region r ON adi.region_sid = r.region_sid AND trm.region_sid = r.region_sid      
--     WHERE adi.approval_dashboard_sid = in_dashboard_sid
--	     AND start_dtm = in_start_dtm
--	     AND end_dtm = in_end_dtm
--	   ORDER BY transition_pos;
CREATE OR REPLACE VIEW csr.V$FLOW_ITEM_TRANS_ROLE_MEMBER AS
    SELECT fit.*, r.role_sid, r.name role_name, rrm.region_sid
      FROM V$FLOW_ITEM_TRANSITION fit
        JOIN flow_state_transition_role fstr ON fit.flow_state_transition_id = fstr.flow_state_transition_id AND fit.app_sid = fstr.app_sid
        JOIN role r ON fstr.role_sid = r.role_sid AND fstr.app_sid = r.app_sid
        JOIN region_role_member rrm ON r.role_sid = rrm.role_sid AND r.app_sid = rrm.app_sid 
     WHERE rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
    ;

CREATE OR REPLACE VIEW csr.v$user_flow_item AS
    SELECT fi.app_sid, fi.flow_sid, fi.flow_item_id, fi.current_state_id, fi.current_state_label,
           fi.survey_response_id, fi.dashboard_instance_id
      FROM v$flow_item fi
     WHERE (fi.app_sid, fi.current_state_id) IN (
     		SELECT fsr.app_sid, fsr.flow_state_id
     		  FROM flow_state_role fsr 
      		  JOIN (SELECT group_sid_id
					  FROM security.group_members 
						   START WITH member_sid_id = SYS_CONTEXT('SECURITY','SID')
						   CONNECT BY NOCYCLE PRIOR group_sid_id = member_sid_id) g
				ON g.group_sid_id = fsr.role_sid);     		 

/* v$open_flow_item_alert is Used for generating alerts. You need to join this to something else, for example:

	SELECT DISTINCT x.app_sid, x.region_sid, x.user_sid, x.flow_state_transition_id, x.flow_item_alert_id,
		customer_alert_type_id, x.flow_state_log_id, x.from_state_label, x.to_state_label, 
		x.set_by_user_sid, x.set_by_email, x.set_by_full_name, x.set_by_user_name,
		x.to_user_sid, to_email, to_full_name, to_friendly_name, to_user_name,
		ad.label dashboard_label, adi.start_dtm, adi.end_dtm, adi.approval_dashboard_sid
	  FROM v$open_flow_item_alert x
		JOIN approval_dashboard_instance adi 
			ON adi.dashboard_instance_Id = x.dashboard_instance_id
			AND x.region_sid = adi.region_sid 
			AND x.app_sid = adi.app_sid
		JOIN approval_dashboard ad 
			ON adi.approval_dashboard_sid = ad.approval_dashboard_sid
			AND adi.app_sid = ad.app_sid
*/
CREATE OR REPLACE VIEW CSR.v$flow_item_alert AS
    SELECT DISTINCT fia.flow_item_alert_id, rrm.region_sid, rrm.user_sid, fta.flow_state_transition_id,
           fta.flow_transition_alert_id, fta.customer_alert_type_id, 
           flsf.flow_state_id from_state_id, flsf.label from_state_label,
           flst.flow_state_id to_state_id, flst.label to_state_label, 
           fsl.flow_state_log_Id, fsl.set_dtm, fsl.set_by_user_sid,
           cusb.full_name set_by_full_name, cusb.email set_by_email, cusb.user_name set_by_user_name, 
           NVL(cut.csr_user_sid, fsl.set_by_user_sid) to_user_sid, cut.full_name to_full_name,
           cut.email to_email, cut.user_name to_user_name, cut.friendly_name to_friendly_name,
           fia.processed_dtm, fi.app_sid, fi.flow_item_id, fi.flow_sid, fi.current_state_id,
           fi.survey_response_id, fi.dashboard_instance_id, fta.to_initiator, fta.flow_alert_helper
      FROM flow_item_alert fia 
      JOIN flow_state_log fsl ON fia.flow_state_log_id = fsl.flow_state_log_id AND fia.app_sid = fsl.app_sid
      JOIN csr_user cusb ON fsl.set_by_user_sid = cusb.csr_user_sid AND fsl.app_sid = cusb.app_sid
      JOIN flow_item fi ON fia.flow_item_id = fi.flow_item_id AND fia.app_sid = fi.app_sid
      JOIN flow_transition_alert fta 
        ON fia.flow_transition_alert_id = fta.flow_transition_alert_id 
       AND fia.app_sid = fta.app_sid            
       AND fta.deleted = 0
      JOIN flow_state_transition fst ON fta.flow_state_transition_id = fst.flow_state_transition_id AND fta.app_sid = fst.app_sid
      JOIN flow_state flsf ON fst.from_state_id = flsf.flow_state_id AND fst.app_sid = flsf.app_sid
      JOIN flow_state flst ON fst.to_state_id = flst.flow_state_id AND fst.app_sid = flst.app_sid
	  LEFT JOIN flow_transition_alert_role ftar
        ON fta.to_initiator = 0 -- optionally, alerts can be to the person who initiated the transition (only)
       AND fta.flow_transition_alert_id = ftar.flow_transition_alert_id 
       AND fta.app_sid = ftar.app_sid
	  LEFT JOIN region_role_member rrm ON ftar.role_sid = rrm.role_sid AND ftar.app_sid = rrm.app_sid
      LEFT JOIN csr_user cut ON rrm.user_sid = cut.csr_user_sid AND rrm.app_sid = cut.app_sid;

CREATE OR REPLACE VIEW csr.v$open_flow_item_alert AS        
    SELECT *
      FROM csr.v$flow_item_alert
     WHERE processed_dtm IS NULL;

-- doclib
CREATE OR REPLACE VIEW csr.v$checked_out_version AS
SELECT s.section_sid, s.parent_sid, sv.version_number, sv.title, sv.body, s.checked_out_to_sid, 
	   s.checked_out_dtm, s.app_sid, s.section_position, s.active, s.module_root_sid, s.title_only  
  FROM section s, section_version sv
 WHERE s.section_sid = sv.section_sid
   AND s.checked_out_version_number = sv.version_number;

-- sections
CREATE OR REPLACE VIEW csr.v$visible_version AS
	SELECT s.section_sid, s.parent_sid, sv.version_number, sv.title, sv.body, s.checked_out_to_sid, s.checked_out_dtm, s.flow_item_id, s.current_route_step_id, s.is_split,
		   s.app_sid, s.section_position, s.active, s.module_root_sid, s.title_only, s.help_text, REF, plugin, plugin_config, section_status_sid, further_info_url,
		   s.previous_section_sid
	  FROM section s, section_version sv
	 WHERE s.section_sid = sv.section_sid
	   AND s.visible_version_number = sv.version_number;

-- quick surveys
CREATE OR REPLACE VIEW csr.v$quick_survey AS
	SELECT qs.app_sid, qs.survey_sid, d.label draft_survey_label, l.label live_survey_label,
		   NVL(l.label, d.label) label, qs.audience, qs.created_dtm, qs.auditing_audit_type_id,
		   CASE WHEN l.survey_sid IS NOT NULL THEN 1 ELSE 0 END survey_is_published,
		   CASE WHEN qs.last_modified_dtm > l.published_dtm THEN 1 ELSE 0 END survey_has_unpublished_changes,
		   qs.score_type_id
	  FROM csr.quick_survey qs
	  JOIN csr.quick_survey_version d ON qs.survey_sid = d.survey_sid
	  LEFT JOIN csr.quick_survey_version l ON qs.survey_sid = l.survey_sid AND qs.current_version = l.survey_version
	 WHERE d.survey_version = 0;

CREATE OR REPLACE VIEW csr.v$quick_survey_response AS
	SELECT qsr.app_sid, qsr.survey_response_id, qsr.survey_sid, qsr.user_sid, qsr.user_name,
		   qsr.created_dtm, qsr.guid, qss.submitted_dtm, qsr.qs_campaign_sid, qss.overall_score,
		   qss.overall_max_score, qss.score_threshold_id, qss.submission_id, qss.survey_version
	  FROM quick_survey_response qsr 
	  JOIN quick_survey_submission qss ON qsr.survey_response_id = qss.survey_response_id
	   AND NVL(qsr.last_submission_id, 0) = qss.submission_id
	   AND qsr.survey_version > 0 -- filter out draft submissions
	   AND qsr.hidden = 0 -- filter out hidden responses
;

CREATE OR REPLACE VIEW csr.v$qs_answer_file AS
	SELECT af.app_sid, af.qs_answer_file_id, af.survey_response_id, af.question_id, af.filename,
		   af.mime_type, af.data, af.sha1, af.uploaded_dtm, sf.submission_id, af.caption
	  FROM qs_answer_file af
	  JOIN qs_submission_file sf ON af.qs_answer_file_id = sf.qs_answer_file_id;

CREATE OR REPLACE VIEW csr.v$quick_survey_answer AS
	SELECT qsa.app_sid, qsa.survey_response_id, qsa.question_id, qsa.note, qsa.score, qsa.question_option_id,
		   qsa.val_number, qsa.measure_conversion_id, qsa.measure_sid, qsa.region_sid, qsa.answer,
		   qsa.html_display, qsa.max_score, qsa.version_stamp, qsa.submission_id, qsa.survey_version, qsq.lookup_key
	  FROM quick_survey_answer qsa
	  JOIN v$quick_survey_response qsr ON qsa.survey_response_id = qsr.survey_response_id AND qsa.submission_id = qsr.submission_id
	  JOIN quick_survey_question qsq ON qsa.question_id = qsq.question_id AND qsa.survey_version = qsq.survey_version;

CREATE OR REPLACE VIEW csr.v$supplier_score AS
	SELECT css.app_sid, css.company_sid, css.score_type_id, css.last_supplier_score_id,
		   ss.score, ss.set_dtm score_last_changed, ss.score_threshold_id, 
		   ss.changed_by_user_sid, cu.full_name changed_by_user_full_name, ss.comment_text,
		   st.description score_threshold_description, t.label score_type_label, t.pos,
		   t.format_mask
	  FROM csr.current_supplier_score css
	  JOIN csr.supplier_score_log ss ON css.company_sid = css.company_sid AND css.last_supplier_score_id = ss.supplier_score_id
	  LEFT JOIN csr.score_threshold st ON ss.score_threshold_id = st.score_threshold_id
	  JOIN csr.score_type t ON css.score_type_id = t.score_type_id
	  LEFT JOIN csr.csr_user cu ON ss.changed_by_user_sid = cu.csr_user_sid;

-- Flatten the join tables to make it easier to find delegations from a delegation plan
CREATE OR REPLACE VIEW csr.v$deleg_plan_delegs AS
	SELECT dpc.app_sid, dpc.deleg_plan_sid, dpcd.delegation_sid template_deleg_sid,
		   dpdrd.maps_to_root_deleg_sid, d.delegation_sid applied_to_delegation_sid, d.lvl, d.is_leaf
	  FROM deleg_plan_col dpc
	  JOIN deleg_plan_col_deleg dpcd ON dpc.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id AND dpc.app_sid = dpcd.app_sid
	  JOIN deleg_plan_deleg_region_deleg dpdrd ON dpcd.deleg_plan_col_deleg_id = dpdrd.deleg_plan_col_deleg_id AND dpcd.app_sid = dpdrd.app_sid
	  JOIN (
		SELECT CONNECT_BY_ROOT delegation_sid root_delegation_sid, delegation_sid, level lvl, connect_by_isleaf is_leaf
		  FROM delegation
		 START WITH parent_sid = app_sid
		CONNECT BY PRIOR delegation_sid = parent_sid AND PRIOR app_sid = app_sid
	  ) d ON d.root_delegation_sid = dpdrd.maps_to_root_deleg_sid;

-- Previously known as v$delegation, refactored to avoid inappropriate use.
CREATE OR REPLACE VIEW csr.v$delegation_hierarchical AS
	SELECT d.*, NVL(dd.description, d.name) as description, dp.submit_confirmation_text
	  FROM (
		SELECT delegation.*, CONNECT_BY_ROOT(delegation_sid) root_delegation_sid
		  FROM delegation
		 START WITH parent_sid = app_sid
	   CONNECT BY parent_sid = prior delegation_sid) d
	  LEFT JOIN delegation_description dd ON dd.app_sid = d.app_sid 
	   AND dd.delegation_sid = d.delegation_sid 
	   AND dd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	  LEFT JOIN delegation_policy dp ON dp.delegation_sid = root_delegation_sid;

-- deleg plans
CREATE OR REPLACE VIEW csr.V$DELEG_PLAN_DELEG_REGION AS
	SELECT dpc.app_sid, dpc.deleg_plan_sid, dpdr.deleg_plan_col_deleg_id, dpc.deleg_plan_col_id, dpc.is_hidden, 
		   dpcd.delegation_sid, dpdr.region_sid, dpdr.pending_deletion, dpdr.region_selection,
		   dpdr.tag_id
	  FROM deleg_plan_deleg_region dpdr
	  JOIN deleg_plan_col_deleg dpcd ON dpdr.app_sid = dpcd.app_sid AND dpdr.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
	  JOIN deleg_plan_col dpc ON dpcd.app_sid = dpc.app_sid AND dpcd.deleg_plan_col_deleg_id = dpc.deleg_plan_col_deleg_id;

CREATE OR REPLACE VIEW csr.V$DELEG_PLAN_SURVEY_REGION AS
	SELECT dpc.deleg_plan_sid, dpsr.deleg_plan_col_survey_id, dpc.deleg_plan_col_id, dpc.is_hidden, 
		dpcs.survey_sid, dpsr.region_sid, dpsr.has_manual_amends, dpsr.pending_deletion,
		dpsr.region_selection, dpsr.tag_id, dpc.qs_campaign_sid
	  FROM deleg_plan_survey_region dpsr
		JOIN deleg_plan_col_survey dpcs ON dpsr.deleg_plan_col_survey_id = dpcs.deleg_plan_col_survey_id
		JOIN deleg_plan_col dpc ON dpcs.deleg_plan_col_survey_id = dpc.deleg_plan_col_survey_id;

CREATE OR REPLACE VIEW csr.V$DELEG_PLAN_COL AS
	SELECT deleg_plan_col_id, deleg_plan_sid, d.name label, dpc.is_hidden, 'Delegation' type, dpcd.delegation_sid object_sid
	  FROM deleg_plan_col dpc
		JOIN deleg_plan_col_deleg dpcd ON dpc.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
		JOIN v$delegation d ON dpcd.delegation_sid = d.delegation_sid
	 UNION
	SELECT deleg_plan_col_id, deleg_plan_sid, qs.label, dpc.is_hidden, 'Survey' type, dpcs.survey_sid object_sid
	  FROM deleg_plan_col dpc
		JOIN deleg_plan_col_survey dpcs ON dpc.deleg_plan_col_survey_id = dpcs.deleg_plan_col_survey_id
		JOIN v$quick_survey qs ON dpcs.survey_sid = qs.survey_sid
	;
	
create or replace view csr.v$ind_selection_group_dep as
	select isg.app_sid, isg.master_ind_sid, isg.master_ind_sid ind_sid
	  from csr.ind_selection_group isg, csr.ind i
	 where i.app_sid = isg.app_sid and i.ind_sid = isg.master_ind_sid
	 union all
	select isgm.app_sid, isgm.master_ind_sid, isgm.ind_sid
	  from csr.ind_selection_group_member isgm;

create or replace view csr.v$calc_job as
	select cj.calc_job_id, c.host, cj.app_sid, cq.name calc_queue_name, 
		   sr.description scenario_run_description, cjp.description phase_description, 
		   case when cj.total_work = 0 then 0 else round(cj.work_done / cj.total_work * 100,2) end progress,
		   cj.running_on, cj.updated_dtm, cj.processing, cj.work_done, cj.total_work, cj.phase,
		   cj.calc_job_type, cj.scenario_run_sid, cj.start_dtm, cj.end_dtm, cj.last_attempt_dtm,
		   cq.calc_queue_id, cj.priority, cj.full_recompute, cj.delay_publish_scenario,
		   cj.process_after_dtm		   
	  from csr.calc_job cj
	  join csr.calc_job_phase cjp on cj.phase = cjp.phase
	  join csr.customer c on cj.app_sid = c.app_sid
	  join csr.calc_queue cq on cj.calc_queue_id = cq.calc_queue_id
	  left join csr.scenario_run sr on cj.app_sid = sr.app_sid and cj.scenario_run_sid = sr.scenario_run_sid;

CREATE OR REPLACE VIEW csr.v$resolved_region AS
	SELECT /*+ALL_ROWS*/ r.app_sid, r.region_sid, r.link_to_region_sid, r.parent_sid,
	  	   -- this pattern is a bit messier than NVL, but it avoids taking properties off the link
	  	   -- in the case that the property is unset on the region -- that's only possible if it's
	  	   -- nullable, but quite a few of the properties are.  They should not be set on the link,
	  	   -- but we don't want to return duff data because we do end up with links with properties.
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.name ELSE r.name END name,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.active ELSE r.active END active,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.pos ELSE r.pos END pos,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.info_xml ELSE r.info_xml END info_xml,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.flag ELSE r.flag END flag,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.acquisition_dtm ELSE r.acquisition_dtm END acquisition_dtm,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.disposal_dtm ELSE r.disposal_dtm END disposal_dtm,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.region_type ELSE r.region_type END region_type,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.region_ref ELSE r.region_ref END region_ref,
		   r.lookup_key, 
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_country ELSE r.geo_country END geo_country,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_region ELSE r.geo_region END geo_region,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_city_id ELSE r.geo_city_id END geo_city_id,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_longitude ELSE r.geo_longitude END geo_longitude,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_latitude ELSE r.geo_latitude END geo_latitude,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_type ELSE r.geo_type END geo_type,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.map_entity ELSE r.map_entity END map_entity,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.egrid_ref ELSE r.egrid_ref END egrid_ref,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.egrid_ref_overridden ELSE r.egrid_ref_overridden END egrid_ref_overridden,
		   -- If either the region or the region link is modified, then the resolved region
		   -- should appear to be modified.  GREATEST returns null if any of its arguments are
		   -- null, so the below ensures that we get the greatest non-null modified date.
		   GREATEST(NVL(r.last_modified_dtm, rl.last_modified_dtm),
				    NVL(rl.last_modified_dtm, r.last_modified_dtm)) last_modified_dtm
	  FROM region r
	  LEFT JOIN region rl ON r.link_to_region_sid = rl.region_sid AND r.app_sid = rl.app_sid;

CREATE OR REPLACE VIEW csr.v$resolved_region_description AS
	SELECT /*+ALL_ROWS*/ r.app_sid, r.region_sid, rd.description, r.link_to_region_sid, r.parent_sid,
		   r.name, r.active, r.pos, r.info_xml, r.flag, r.acquisition_dtm, r.disposal_dtm, r.region_type,
		   r.lookup_key, r.region_ref, r.geo_country, r.geo_region, r.geo_city_id, r.geo_longitude, r.geo_latitude,
		   r.geo_type, r.map_entity, r.egrid_ref, r.egrid_ref_overridden,  r.last_modified_dtm
	  FROM v$resolved_region r
	  JOIN region_description rd ON NVL(r.link_to_region_sid, r.region_sid) = rd.region_sid
	   AND rd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');


-- The current state of all approved meter readings
CREATE OR REPLACE FORCE VIEW csr.v$meter_reading AS
	SELECT mr.app_sid, mr.meter_reading_id, mr.region_sid, mr.start_dtm, mr.end_dtm, mr.val_number, mr.baseline_val,
		mr.entered_by_user_sid, mr.entered_dtm, mr.note, mr.reference, mr.cost, mr.meter_document_id, mr.created_invoice_id,
		mr.approved_dtm, mr.approved_by_sid, mr.is_estimate,
		mr.flow_item_id, mr.pm_reading_id,
		NVL(pi.format_mask,pm.format_mask) as format_mask
	  FROM csr.all_meter am
		JOIN csr.meter_reading mr ON am.app_sid = mr.app_sid
				AND am.region_sid = mr.region_sid
				AND am.meter_source_type_id = mr.meter_source_type_id
		LEFT JOIN csr.v$ind pi ON am.primary_ind_sid = pi.ind_sid AND am.app_sid = pi.app_sid
		LEFT JOIN csr.measure pm ON pi.measure_sid = pm.measure_sid AND pi.app_sid = pm.app_sid
	 WHERE mr.active = 1 AND req_approval = 0
;

-- A view of all meter readings, approved or otherwise.
-- Because a pending reading can replace an existing reading this view may contain overlaps
CREATE OR REPLACE VIEW csr.v$meter_reading_all AS
	SELECT mr.app_sid, mr.meter_reading_id, mr.region_sid, mr.start_dtm, mr.end_dtm, mr.val_number, mr.baseline_val,
		mr.entered_by_user_sid, mr.entered_dtm, mr.note, mr.reference, mr.cost, mr.meter_document_id, mr.created_invoice_id,
		mr.approved_dtm, mr.approved_by_sid, mr.req_approval, mr.is_delete, mr.replaces_reading_id, mr.is_estimate,
		mr.flow_item_id
	  FROM csr.all_meter am, csr.meter_reading mr
	 WHERE am.app_sid = mr.app_sid
	   AND am.region_sid = mr.region_sid
	   AND am.meter_source_type_id = mr.meter_source_type_id
	   AND mr.active = 1
;

-- A view onto the latest version of meter readings (if all had been approved)
CREATE OR REPLACE VIEW csr.v$meter_reading_head AS
	SELECT mr.app_sid, mr.meter_reading_id, mr.region_sid, mr.start_dtm, mr.end_dtm, mr.val_number, mr.baseline_val,
		mr.entered_by_user_sid, mr.entered_dtm, mr.note, mr.reference, mr.cost, mr.meter_document_id, mr.created_invoice_id,
		mr.approved_dtm, mr.approved_by_sid, mr.req_approval, mr.is_delete, mr.replaces_reading_id, mr.is_estimate,
		mr.flow_item_id
	  FROM meter_reading mr, (
	 	SELECT meter_reading_id
	 	  FROM csr.v$meter_reading_all
	 	MINUS
	 	SELECT replaces_reading_id meter_reading_id
	 	  FROM csr.v$meter_reading_all
	 	 WHERE req_approval = 1
	 ) x
	 WHERE mr.meter_reading_id = x.meter_reading_id
	   AND mr.active = 1
;

CREATE OR REPLACE VIEW CSR.v$batch_job AS
	SELECT bj.app_sid, bj.batch_job_id, bj.batch_job_type_id, bj.description,
		   bjt.description batch_job_type_description, bj.requested_by_user_sid,
	 	   cu.full_name requested_by_full_name, cu.email requested_by_email, bj.requested_dtm,
	 	   bj.email_on_completion, bj.started_dtm, bj.completed_dtm, bj.updated_dtm, bj.retry_dtm,
	 	   bj.work_done, bj.total_work, bj.running_on, bj.result, bj.result_url
      FROM batch_job bj, batch_job_type bjt, csr_user cu
     WHERE bj.app_sid = cu.app_sid AND bj.requested_by_user_sid = cu.csr_user_sid
       AND bj.batch_job_type_id = bjt.batch_job_type_id;

/* property */
CREATE OR REPLACE VIEW CSR.PROPERTY
	(APP_SID, REGION_SID, FLOW_ITEM_ID,
	 STREET_ADDR_1, STREET_ADDR_2, CITY, STATE, POSTCODE,
	 COMPANY_SID, PROPERTY_TYPE_ID, PROPERTY_SUB_TYPE_ID,
	 FUND_ID, MGMT_COMPANY_ID, MGMT_COMPANY_OTHER,
	 PM_BUILDING_ID, CURRENT_LEASE_ID, MGMT_COMPANY_CONTACT_ID,
	 ENERGY_STAR_SYNC, ENERGY_STAR_PUSH) AS
  SELECT ALP.APP_SID, ALP.REGION_SID, ALP.FLOW_ITEM_ID,
	 ALP.STREET_ADDR_1, ALP.STREET_ADDR_2, ALP.CITY, ALP.STATE, ALP.POSTCODE,
	 ALP.COMPANY_SID, ALP.PROPERTY_TYPE_ID, ALP.PROPERTY_SUB_TYPE_ID,
	 ALP.FUND_ID, ALP.MGMT_COMPANY_ID, ALP.MGMT_COMPANY_OTHER,
	 ALP.PM_BUILDING_ID, ALP.CURRENT_LEASE_ID, ALP.MGMT_COMPANY_CONTACT_ID,
	 ENERGY_STAR_SYNC, ENERGY_STAR_PUSH
    FROM ALL_PROPERTY ALP JOIN region r ON r.region_sid = alp.region_sid
   WHERE r.region_type = 3;

CREATE OR REPLACE VIEW csr.v$property AS
    SELECT r.app_sid, r.region_sid, r.description, r.parent_sid, r.lookup_key, r.region_ref, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode, c.country country_code,
        c.name country_name, c.currency country_currency,
        pt.property_type_id, pt.label property_type_label,
        pst.property_sub_type_id, pst.label property_sub_type_label,
        p.flow_item_id, fi.current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key, fs.state_colour current_state_colour,
        r.active, r.acquisition_dtm, r.disposal_dtm, geo_longitude lng, geo_latitude lat, fund_id,
        mgmt_company_id, mgmt_company_other, mgmt_company_contact_id, p.company_sid, p.pm_building_id,
        pt.lookup_key property_type_lookup_key,
        p.energy_star_sync, p.energy_star_push
      FROM property p
        JOIN v$region r ON p.region_sid = r.region_sid AND p.app_sid = r.app_sid
        LEFT JOIN postcode.country c ON r.geo_country = c.country 
        LEFT JOIN property_type pt ON p.property_type_id = pt.property_type_id AND p.app_sid = pt.app_sid
        LEFT JOIN property_sub_type pst ON p.property_sub_type_id = pst.property_sub_type_id AND p.app_sid = pst.app_sid
        LEFT JOIN flow_item fi ON p.flow_item_id = fi.flow_item_id AND p.app_sid = fi.app_sid
        LEFT JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid;


CREATE OR REPLACE FORCE VIEW csr.v$property_meter AS
	SELECT a.app_sid, a.region_sid, a.reference, r.description, r.parent_sid, a.note,
		NVL(mi.label, pi.description) group_label, mi.group_key,
		a.primary_ind_sid, pi.description primary_description, NVL(pmc.description, pm.description) primary_measure, a.primary_measure_conversion_id,
		a.cost_ind_sid, ci.description cost_description, NVL(cmc.description, cm.description) cost_measure, a.cost_measure_conversion_id,		
		ms.meter_source_type_id, ms.name source_type_name, ms.description source_type_description,
		ms.manual_data_entry, ms.supplier_data_mandatory, ms.arbitrary_period, ms.reference_mandatory, ms.add_invoice_data,
		ms.realtime_metering, ms.show_in_meter_list, ms.descending, ms.allow_reset, a.meter_ind_id, r.active, r.region_type,
		extractvalue(pi.info_xml, '/fields/field[@name="definition"]/text()') as ind_detail
	  FROM all_meter a
		JOIN meter_source_type ms ON a.meter_source_type_id = ms.meter_source_type_id AND a.app_sid = ms.app_sid			
		JOIN v$region r ON a.region_sid = r.region_sid AND a.app_sid = r.app_sid
		LEFT JOIN meter_ind mi ON a.meter_ind_id = mi.meter_ind_id
		LEFT JOIN v$ind pi ON a.primary_ind_sid = pi.ind_sid AND a.app_sid = pi.app_sid
		LEFT JOIN measure pm ON pi.measure_sid = pm.measure_sid AND pi.app_sid = pm.app_sid
		LEFT JOIN measure_conversion pmc ON a.primary_measure_conversion_id = pmc.measure_conversion_id AND a.app_sid = pmc.app_sid
		LEFT JOIN v$ind ci ON a.cost_ind_sid = ci.ind_sid AND a.app_sid = ci.app_sid
		LEFT JOIN measure cm ON ci.measure_sid = cm.measure_sid AND ci.app_sid = cm.app_sid
		LEFT JOIN measure_conversion cmc ON a.cost_measure_conversion_id = cmc.measure_conversion_id AND a.app_sid = cmc.app_sid;
		

-- bare-bones view  (can include dupes if you're in multiple matching roles) 
-- TODO: check that the role is a property role?
CREATE OR REPLACE VIEW csr.v$my_property AS
    SELECT p.app_sid, p.region_sid, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode, 
            p.property_type_id, p.flow_item_id, 
            fi.current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key,  
            fs.state_colour current_state_colour,
            r.role_sid, r.name role_name, fsr.is_editable, rg.active, p.pm_building_id
      FROM region_role_member rrm
        JOIN role r ON rrm.role_sid = r.role_sid AND rrm.app_sid = r.app_sid
        JOIN flow_state_role fsr ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
        JOIN flow_state fs ON fsr.flow_state_id = fs.flow_state_id AND fsr.app_sid = fs.app_sid 
        JOIN flow_item fi ON fs.flow_state_id = fi.current_state_id AND fs.app_sid = fi.app_sid
        JOIN property p ON fi.flow_item_id = p.flow_Item_id AND rrm.region_sid = p.region_sid AND rrm.app_sid = p.app_sid
        JOIN region rg ON p.region_sid = rg.region_sid AND p.app_Sid = rg.app_sid
     WHERE rrm.user_sid = SYS_CONTEXT('SECURITY','SID');

-- fuller-fat view (can include dupes if you're in multiple matching roles) 
CREATE OR REPLACE VIEW csr.v$my_property_full AS
    SELECT r.app_sid, r.region_sid, r.description, r.parent_sid, r.lookup_key, r.region_ref, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode, c.country country_code,
        c.name country_name, pt.property_type_id, pt.label property_type_label,
        p.flow_item_id, p.current_state_id, p.current_state_label, p.current_state_lookup_key,
        p.current_state_colour, p.role_sid, p.role_name, p.is_editable,
        r.active, r.acquisition_dtm, r.disposal_dtm, geo_longitude lng, geo_latitude lat, p.pm_building_id
      FROM csr.v$my_property p
        JOIN v$region r ON p.region_sid = r.region_sid AND p.app_sid = r.app_sid
        LEFT JOIN postcode.country c ON r.geo_country = c.country 
        LEFT JOIN property_type pt ON p.property_type_id = pt.property_type_id AND p.app_sid = pt.app_sid;

CREATE OR REPLACE FORCE VIEW csr.v$region_metric_region AS
    SELECT rmr.source_type_id, rmr.ind_sid, rmr.region_sid, rmr.measure_sid, NVL(mc.description, m.description) measure_description,
        NVL(i.format_mask, m.format_mask) format_mask, rmr.measure_conversion_id, i.description ind_description
      FROM region_metric_region rmr
      JOIN region_metric rm ON rmr.ind_sid = rm.ind_sid AND rmr.app_sid = rm.app_sid
      JOIN v$ind i ON rm.ind_sid = i.ind_sid AND rm.app_sid = i.app_sid
      JOIN measure m ON rmr.measure_sid = m.measure_sid AND rmr.app_sid = m.app_sid
      LEFT JOIN measure_conversion mc ON rmr.measure_conversion_id = mc.measure_conversion_id 
        AND rmr.measure_sid = mc.measure_sid AND rmr.app_sid = mc.app_sid;   

CREATE OR REPLACE VIEW csr.v$lease AS
	SELECT l.lease_id, l.start_dtm, l.end_dtm, l.next_break_dtm, l.current_rent, 
		   l.normalised_rent, l.next_rent_review, l.tenant_id, l.currency_code,
		   t.name tenant_name
	  FROM lease l
		LEFT JOIN tenant t ON t.tenant_id = l.tenant_id;

CREATE OR REPLACE VIEW CSR.SPACE
	(APP_SID, REGION_SID, SPACE_TYPE_ID,
	 PROPERTY_REGION_SID, PROPERTY_TYPE_ID, CURRENT_LEASE_ID) AS
  SELECT ALS.APP_SID, ALS.REGION_SID, ALS.SPACE_TYPE_ID,
	 ALS.PROPERTY_REGION_SID, ALS.PROPERTY_TYPE_ID, ALS.CURRENT_LEASE_ID
    FROM ALL_SPACE ALS JOIN region r ON r.region_sid = ALS.region_sid
   WHERE r.region_type = 9;

CREATE OR REPLACE VIEW csr.v$space AS
    SELECT s.region_sid, r.description, r.active, r.parent_sid, s.space_type_id, st.label space_type_label, s.current_lease_id, s.property_region_Sid,
		   l.tenant_name current_tenant_name
      FROM space s
        JOIN v$region r on s.region_sid = r.region_sid
        JOIN space_type st ON s.space_type_Id = st.space_type_id
		LEFT JOIN v$lease l ON l.lease_id = s.current_lease_id;

/* activities */
CREATE OR REPLACE VIEW CSR.V$ACTIVITY AS 
    SELECT a.app_sid, a.activity_id, 
        a.region_sid, r.description region_description,
        a.label, a.short_label, a.description, 
        a.activity_type_Id, t.label activity_type_label,
        a.activity_sub_type_Id, st.label activity_sub_type_label,
        a.created_by_sid, cu.full_name created_by_name, a.created_dtm, 
        a.flow_item_id, fs.flow_state_Id, fs.label flow_state_label, fs.state_colour, 
        c.name country_name, c.currency country_currency,
        t.track_time, t.track_money, NVL(st.base_css_class, t.base_css_class) base_css_class,
        CASE WHEN (open_dtm IS NULL OR SYSDATE >= open_dtm) AND (close_dtm IS NULL OR SYSDATE < close_dtm) THEN 1 ELSE 0 END is_running,
        a.start_dtm, a.end_dtm, a.open_dtm, a.close_dtm, a.is_members_only, a.active, t.matched_giving_policy_id,
        a.img_last_modified_dtm, a.img_sha1, a.img_mime_type
      FROM activity a
      JOIN v$region r ON a.region_sid = r.region_sid AND a.app_sid = r.app_sid
      JOIN activity_type t ON a.activity_type_id = t.activity_type_id AND a.app_sid = t.app_sid
      JOIN flow_item fi ON a.flow_item_id = fi.flow_item_id AND a.app_sid = fi.app_sid
      JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
      JOIN csr_user cu ON a.created_by_sid = cu.csr_user_sid AND a.app_sid = cu.app_sid
      LEFT JOIN activity_sub_type st ON a.activity_sub_type_id = st.activity_sub_type_id AND a.activity_type_id = st.activity_type_id AND a.app_sid = t.app_sid
      LEFT JOIN postcode.country c ON r.geo_country = c.country;

CREATE OR REPLACE VIEW CSR.V$MY_ACTIVITY AS
	SELECT a.app_sid, a.activity_id, a.region_sid, a.region_description, a.label, a.short_label, a.description,
		a.activity_type_Id, a.activity_type_label, a.activity_sub_type_Id, a.activity_sub_type_label, a.created_by_sid,
		a.created_by_name, a.created_dtm, a.flow_item_id, a.flow_state_Id, a.flow_state_label, a.state_colour, a.country_name,
		a.country_currency, a.track_time, a.track_money, a.base_css_class, a.is_running, a.start_dtm, a.end_dtm, a.open_dtm,
		a.close_dtm, a.is_members_only, a.active
	  FROM v$activity a
	  JOIN activity_member am ON a.activity_id = am.activity_id AND a.app_sid = am.app_sid         
	 WHERE am.user_sid = SYS_CONTEXT('SECURITY','SID')
	   AND a.active = 1
	   AND a.is_running = 1;

CREATE OR REPLACE VIEW CSR.V$USER_FEED AS
    SELECT uf.user_feed_id, uf.action_dtm, 
    	uf.acting_user_sid, cua.full_name acting_user_full_name,
        uf.target_user_sid, cut.full_name target_user_full_name, 
        uf.target_activity_id, a.label target_activity,
        target_param_1, target_param_2, target_param_3,
        ufa.action_text, ufa.action_url, ufa.label action_label, ufa.action_img_url
      FROM user_feed uf
      JOIN user_feed_action ufa ON uf.user_feed_action_id = ufa.user_feed_action_id
      JOIN csr_user cua ON uf.acting_user_sid = cua.csr_user_sid AND uf.app_sid = cua.app_sid
      LEFT JOIN csr_user cut ON uf.target_user_sid = cut.csr_user_sid AND uf.app_sid = cut.app_sid
      LEFT JOIN activity a ON uf.target_activity_id = a.activity_id AND uf.app_sid = a.app_sid;

/* user messages */
CREATE OR REPLACE VIEW CSR.V$USER_MSG AS
	SELECT um.user_msg_id, um.user_sid, cu.full_name, cu.email, um.msg_dtm, um.msg_text, um.reply_to_msg_id
	  FROM user_msg um 
	  JOIN csr_user cu ON um.user_sid = cu.csr_user_sid AND um.app_sid = cu.app_sid;

CREATE OR REPLACE VIEW CSR.V$USER_MSG_FILE AS
	SELECT umf.user_msg_file_id, umf.user_msg_id, cast(umf.sha1 as varchar2(40)) sha1, umf.mime_type, 
		um.msg_dtm last_modified_dtm
	  FROM user_msg um 
	  JOIN user_msg_file umf ON um.user_msg_id = umf.user_msg_id;

CREATE OR REPLACE VIEW CSR.V$USER_MSG_LIKE AS
	SELECT uml.user_msg_id, uml.liked_by_user_sid, uml.liked_dtm, cu.full_name, cu.email
	  FROM user_msg_like uml 
	  JOIN csr_user cu ON uml.liked_by_user_sid = cu.csr_user_sid AND uml.app_sid = cu.app_sid;

/* text */
CREATE OR REPLACE VIEW csr.v$my_section AS
    SELECT s.section_sid, firm.current_state_id, MAX(firm.is_editable) is_editable, 'F' source
      FROM csr.v$flow_item_role_member firm
        JOIN csr.section s ON firm.flow_item_id = s.flow_item_id AND firm.app_sid = s.app_sid
        JOIN csr.section_module sm
            ON s.module_root_sid = sm.module_root_sid AND s.app_sid = sm.app_sid
            AND firm.region_sid = sm.region_sid AND firm.app_sid = sm.app_sid
     WHERE NOT EXISTS (
        -- exclude if sections are currently in a workflow state that is routed
        SELECT null FROM csr.section_routed_flow_state WHERE flow_state_id = firm.current_state_id
     )
     GROUP BY s.section_sid, firm.current_state_id
    UNION ALL
    -- everything where the section is currently in a workflow state that is routed, and the user is in the currently route_step
    SELECT s.section_sid, fi.current_state_id, 1 is_editable, 'R' source
      FROM csr.section s
        JOIN csr.flow_item fi ON s.flow_item_id = fi.flow_item_id AND s.app_sid = fi.app_sid
        JOIN csr.route r ON fi.current_state_id = r.flow_state_id AND fi.app_sid = r.app_sid
        JOIN csr.route_step rs
            ON r.route_id = rs.route_id AND r.app_sid = rs.app_sid
            AND s.current_route_step_id = rs.route_step_id AND s.app_sid = rs.app_sid
        JOIN csr.route_step_user rsu
            ON rs.route_step_id = rsu.route_step_id
            AND rs.app_sid = rsu.app_sid
            AND rsu.csr_user_sid = SYS_CONTEXT('SECURITY','SID')
      WHERE s.current_route_step_id NOT IN (
		SELECT route_step_id FROM route_step_vote WHERE user_sid = SYS_CONTEXT('SECURITY','SID')
      );

CREATE OR REPLACE VIEW csr.v$current_user_cover AS
	SELECT user_being_covered_sid
	  FROM csr.user_cover
	 WHERE user_giving_cover_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND start_dtm < SYSDATE
	   AND (end_dtm IS NULL OR end_dtm > SYSDATE)
	   AND cover_terminated = 0;


CREATE OR REPLACE VIEW csr.v$audit AS
	SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label,
		   NVL2(ia.internal_audit_ref, atg.internal_audit_ref_prefix || ia.internal_audit_ref, null) custom_audit_id,
		   atg.internal_audit_ref_prefix, ia.internal_audit_ref, ia.ovw_validity_dtm,
		   ia.auditor_user_sid, ca.full_name auditor_full_name, sr.submitted_dtm survey_completed,
		   NVL(nc.cnt, 0) open_non_compliances, ia.survey_sid, ia.auditor_name, ia.auditor_organisation,
		   r.region_type, rt.class_name region_type_class_name, SUBSTR(ia.notes, 1, 50) short_notes,
		   ia.notes full_notes, iat.internal_audit_type_id audit_type_id, iat.label audit_type_label,
		   qs.label survey_label, ia.app_sid, ia.internal_audit_type_id, iat.auditor_role_sid,
		   iat.audit_contact_role_sid, ia.audit_closure_type_id, act.label closure_label, act.icon_image_filename,
		   ia.created_by_user_sid, ia.survey_response_id, ia.created_dtm, ca.email auditor_email,
		   iat.filename template_filename, iat.assign_issues_to_role, iat.add_nc_per_question, cvru.user_giving_cover_sid cover_auditor_sid,
		   fi.flow_sid, f.label flow_label, ia.flow_item_id, fi.current_state_id, fs.label flow_state_label, fs.is_final flow_state_is_final,
		   iat.summary_survey_sid, sqs.label summary_survey_label, ia.summary_response_id, act.is_failure,
		   ia.auditor_company_sid, ac.name auditor_company_name, iat.tab_sid, iat.form_path, ia.comparison_response_id, iat.nc_audit_child_region,
		   atg.label int_audit_type_group_label, atg.internal_audit_type_group_id, atg.group_coordinator_noun,
		   sr.overall_score survey_overall_score, sr.overall_max_score survey_overall_max_score,
		   sst.score_type_id survey_score_type_id, sst.label survey_score_label, sst.format_mask survey_score_format_mask,
		   ia.nc_score, iat.nc_score_type_id, NVL(ia.ovw_nc_score_thrsh_id, ia.nc_score_thrsh_id) nc_score_thrsh_id, ncst.max_score nc_max_score, ncst.label nc_score_label, ncst.format_mask nc_score_format_mask
	  FROM csr.internal_audit ia
	  LEFT JOIN (
			SELECT auc.app_sid, auc.internal_audit_sid, auc.user_giving_cover_sid,
				   ROW_NUMBER() OVER (PARTITION BY auc.internal_audit_sid ORDER BY LEVEL DESC, uc.start_dtm DESC,  uc.user_cover_id DESC) rn,
				   CONNECT_BY_ROOT auc.user_being_covered_sid user_being_covered_sid
			  FROM csr.audit_user_cover auc
			  JOIN csr.user_cover uc ON auc.app_sid = uc.app_sid AND auc.user_cover_id = uc.user_cover_id
			 CONNECT BY NOCYCLE PRIOR auc.app_sid = auc.app_sid AND PRIOR auc.user_being_covered_sid = auc.user_giving_cover_sid
		) cvru
	    ON ia.internal_audit_sid = cvru.internal_audit_sid
	   AND ia.app_sid = cvru.app_sid AND ia.auditor_user_sid = cvru.user_being_covered_sid
	   AND cvru.rn = 1
	  JOIN csr.csr_user ca ON NVL(cvru.user_giving_cover_sid , ia.auditor_user_sid) = ca.csr_user_sid AND ia.app_sid = ca.app_sid
	  LEFT JOIN csr.internal_audit_type iat ON ia.app_sid = iat.app_sid AND ia.internal_audit_type_id = iat.internal_audit_type_id
	  LEFT JOIN csr.internal_audit_type_group atg ON atg.app_sid = iat.app_sid AND atg.internal_audit_type_group_id = iat.internal_audit_type_group_id
	  LEFT JOIN csr.v$quick_survey qs ON ia.survey_sid = qs.survey_sid AND ia.app_sid = qs.app_sid
	  LEFT JOIN csr.v$quick_survey sqs ON iat.summary_survey_sid = sqs.survey_sid AND iat.app_sid = sqs.app_sid
	  LEFT JOIN (
			SELECT anc.app_sid, anc.internal_audit_sid, COUNT(DISTINCT anc.non_compliance_id) cnt
			  FROM csr.audit_non_compliance anc
			  JOIN csr.non_compliance nnc ON anc.non_compliance_id = nnc.non_compliance_id AND anc.app_sid = nnc.app_sid
			  LEFT JOIN csr.issue_non_compliance inc ON nnc.non_compliance_id = inc.non_compliance_id AND nnc.app_sid = inc.app_sid
			  LEFT JOIN csr.issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id AND inc.app_sid = i.app_sid
			 WHERE ((nnc.is_closed IS NULL 
			   AND i.resolved_dtm IS NULL
			   AND i.rejected_dtm IS NULL
			   AND i.deleted = 0)
			    OR nnc.is_closed = 0)
			 GROUP BY anc.app_sid, anc.internal_audit_sid
			) nc ON ia.internal_audit_sid = nc.internal_audit_sid AND ia.app_sid = nc.app_sid
	  LEFT JOIN csr.v$quick_survey_response sr ON ia.survey_response_id = sr.survey_response_id AND ia.app_sid = sr.app_sid
	  JOIN csr.v$region r ON ia.app_sid = r.app_sid AND ia.region_sid = r.region_sid
	  JOIN csr.region_type rt ON r.region_type = rt.region_type
	  LEFT JOIN csr.audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id AND ia.app_sid = act.app_sid
	  LEFT JOIN csr.flow_item fi
	    ON ia.app_sid = fi.app_sid AND ia.flow_item_id = fi.flow_item_id
	  LEFT JOIN csr.flow_state fs
	    ON fs.app_sid = fi.app_sid AND fs.flow_state_id = fi.current_state_id
	  LEFT JOIN csr.flow f
	    ON f.app_sid = fi.app_sid AND f.flow_sid = fi.flow_sid
	  LEFT JOIN chain.company ac
	    ON ia.auditor_company_sid = ac.company_sid AND ia.app_sid = ac.app_sid
	  LEFT JOIN score_type ncst ON ncst.app_sid = iat.app_sid AND ncst.score_type_id = iat.nc_score_type_id
	  LEFT JOIN score_type sst ON sst.app_sid = qs.app_sid AND sst.score_type_id = qs.score_type_id
	 WHERE ia.deleted = 0;
	 
CREATE OR REPLACE VIEW csr.v$audit_validity AS --more basic version of v$audit_next_due that returns all audits carried out and their validity instead of just the most recent of each type
SELECT ia.internal_audit_sid, ia.internal_audit_type_id, ia.region_sid,
ia.audit_dtm previous_audit_dtm, act.audit_closure_type_id, ia.app_sid,
CASE (re_audit_due_after_type)
	WHEN 'd' THEN nvl(ovw_validity_dtm, ia.audit_dtm + re_audit_due_after)
	WHEN 'w' THEN nvl(ovw_validity_dtm, ia.audit_dtm + (re_audit_due_after*7))
	WHEN 'm' THEN nvl(ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, re_audit_due_after))
	WHEN 'y' THEN nvl(ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, re_audit_due_after*12))
END next_audit_due_dtm, act.reminder_offset_days, act.label closure_label,
act.is_failure, ia.label previous_audit_label, act.icon_image_filename,
ia.auditor_user_sid previous_auditor_user_sid, ia.flow_item_id
  FROM csr.internal_audit ia
  JOIN csr.audit_closure_type act 
	ON ia.audit_closure_type_id = act.audit_closure_type_id
   AND ia.app_sid = act.app_sid
   AND ia.audit_closure_type_id IS NOT NULL
   AND ia.deleted = 0;   


CREATE OR REPLACE VIEW csr.v$audit_next_due AS
SELECT ia.internal_audit_sid, ia.internal_audit_type_id, ia.region_sid,
	   ia.audit_dtm previous_audit_dtm, act.audit_closure_type_id, ia.app_sid,
	   CASE (re_audit_due_after_type)
			WHEN 'd' THEN nvl(ovw_validity_dtm, ia.audit_dtm + re_audit_due_after)
			WHEN 'w' THEN nvl(ovw_validity_dtm, ia.audit_dtm + (re_audit_due_after*7))
			WHEN 'm' THEN nvl(ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, re_audit_due_after))
			WHEN 'y' THEN nvl(ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, re_audit_due_after*12))
	   END next_audit_due_dtm, act.reminder_offset_days, act.label closure_label,
	   act.is_failure, ia.label previous_audit_label, act.icon_image_filename,
	   ia.auditor_user_sid previous_auditor_user_sid, ia.flow_item_id
  FROM (
	SELECT internal_audit_sid, internal_audit_type_id, region_sid, audit_dtm,
		   ROW_NUMBER() OVER (
				PARTITION BY internal_audit_type_id, region_sid
				ORDER BY audit_dtm DESC) rn, -- take most recent audit of each type/region
		   audit_closure_type_id, app_sid, label, auditor_user_sid, flow_item_id, deleted, OVW_VALIDITY_DTM
	  FROM csr.internal_audit
	 WHERE deleted = 0
	   ) ia
  JOIN csr.audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id
   AND ia.app_sid = act.app_sid
  JOIN csr.region r ON ia.region_sid = r.region_sid AND ia.app_sid = r.app_sid
 WHERE rn = 1
   AND act.re_audit_due_after IS NOT NULL
   AND r.active=1
   AND ia.audit_closure_type_id IS NOT NULL
   AND ia.deleted = 0;
   
CREATE OR REPLACE VIEW CSR.v$audit_tag AS
	SELECT ia.app_sid, ia.internal_audit_sid, ia.label audit_label, at.source, tg.name tag_group_name, t.tag, tg.tag_group_id, t.tag_id, t.lookup_key tag_lookup_key
	  FROM internal_audit ia
	  JOIN (
		SELECT iia.app_sid, iia.internal_audit_sid, rt.tag_id, 'Region tag' source
		  FROM internal_audit iia
		  JOIN region_tag rt ON iia.region_sid = rt.region_sid AND iia.app_sid = rt.app_sid
	  ) at ON ia.internal_audit_sid = at.internal_audit_sid AND ia.app_sid = at.app_sid
	  JOIN tag t ON at.tag_id = t.tag_id AND at.app_sid = t.app_sid
	  JOIN tag_group_member tgm ON t.tag_id = tgm.tag_id AND t.app_sid = tgm.app_sid
	  JOIN tag_group tg ON tgm.tag_group_id = tg.tag_group_id AND tgm.app_sid = tg.app_sid
	  AND ia.deleted = 0
;

CREATE OR REPLACE VIEW CSR.v$flow_state_alert_user AS
    SELECT a.flow_sid, a.flow_state_alert_id, au.user_sid
      FROM flow_state_alert a
      JOIN flow_state_alert_user au ON au.flow_sid = a.flow_sid AND au.flow_state_alert_id = a.flow_state_alert_id
    UNION
    SELECT a.flow_sid, a.flow_state_alert_id, rrm.user_sid
      FROM flow_state_alert a
      JOIN flow_state_alert_role ar ON ar.flow_sid = a.flow_sid AND ar.flow_state_alert_id = a.flow_state_alert_id
      JOIN region_role_member rrm ON rrm.role_sid = ar.role_sid AND rrm.region_sid = rrm.inherited_from_sid
;

-- Selects all initiative/user associations, either by role or initiatvie user gorup
CREATE OR REPLACE VIEW csr.v$initiative_user AS
    SELECT app_sid, user_sid, initiative_sid, region_sid, flow_state_id, 
        flow_state_label, flow_state_lookup_key, flow_state_colour, active,
        MAX(is_editable) is_editable, MAX(generate_alerts) generate_alerts
    FROM (
        SELECT rrm.user_sid, 
            i.app_sid, i.initiative_sid,
            ir.region_sid,
            fi.current_state_id flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key, fs.state_colour flow_state_colour,
            MAX(fsr.is_editable) is_editable,
            1 generate_alerts,
            rg.active
            FROM region_role_member rrm
            JOIN role r ON rrm.role_sid = r.role_sid AND rrm.app_sid = r.app_sid
            JOIN flow_state_role fsr ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
            JOIN flow_state fs ON fsr.flow_state_id = fs.flow_state_id AND fsr.app_sid = fs.app_sid
            JOIN flow_item fi ON fs.flow_state_id = fi.current_state_id AND fs.app_sid = fi.app_sid
            JOIN initiative i ON fi.flow_item_id = i.flow_Item_id AND fi.app_sid = i.app_sid
            JOIN initiative_region ir ON i.initiative_sid = ir.initiative_sid AND rrm.region_sid = ir.region_sid AND rrm.app_sid = ir.app_sid
            JOIN region rg ON ir.region_sid = rg.region_sid AND ir.app_Sid = rg.app_sid
         GROUP BY rrm.user_sid, 
            i.app_sid, i.initiative_sid,
            ir.region_sid,
            fi.current_state_id, fs.label, fs.lookup_key, fs.state_colour,
            r.role_sid, r.name,
            rg.active
        UNION
        SELECT iu.user_sid, 
            i.app_sid, i.initiative_sid,
            ir.region_sid, 
            fi.current_state_id flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key, fs.state_colour flow_state_colour,
            MAX(igfs.is_editable) is_editable,
            MAX(igfs.generate_alerts) generate_alerts,
            rg.active
            FROM initiative_user iu
            JOIN initiative i ON iu.initiative_sid = i.initiative_sid AND iu.app_sid = i.app_sid
            JOIN flow_item fi ON i.flow_item_id = fi.flow_item_id AND i.app_sid = fi.app_sid
            JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.flow_sid = fs.flow_sid AND fi.app_sid = fs.app_sid
            JOIN initiative_project_user_group ipug 
            ON iu.initiative_user_group_id = ipug.initiative_user_group_id
             AND iu.project_sid = ipug.project_sid
            JOIN initiative_group_flow_state igfs
            ON ipug.initiative_user_group_id = igfs.initiative_user_group_id
             AND ipug.project_sid = igfs.project_sid
             AND ipug.app_sid = igfs.app_sid
             AND fs.flow_state_id = igfs.flow_State_id AND fs.flow_sid = igfs.flow_sid AND fs.app_sid = igfs.app_sid
            JOIN initiative_region ir ON ir.initiative_sid = i.initiative_sid AND ir.app_sid = i.app_sid
            JOIN region rg ON ir.region_sid = rg.region_sid AND ir.app_Sid = rg.app_sid
            LEFT JOIN rag_status rs ON i.rag_status_id = rs.rag_status_id AND i.app_sid = rs.app_sid
         GROUP BY iu.user_sid,
            i.app_sid, i.initiative_sid, ir.region_sid, 
            fi.current_state_id, fs.label, fs.lookup_key, fs.state_colour,
            rg.active
    ) GROUP BY app_sid, user_sid, initiative_sid, region_sid, flow_state_id, 
        flow_state_label, flow_state_lookup_key, flow_state_colour, active;
	  
CREATE OR REPLACE VIEW csr.v$my_initiatives AS
	SELECT  i.app_sid, i.initiative_sid,
		ir.region_sid,
		fi.current_state_id flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key, fs.state_colour flow_state_colour, fs.pos flow_state_pos,
		r.role_sid, r.name role_name,
		MAX(fsr.is_editable) is_editable,
		rg.active,
		null owner_sid
		FROM  region_role_member rrm
		JOIN  role r ON rrm.role_sid = r.role_sid AND rrm.app_sid = r.app_sid
		JOIN flow_state_role fsr ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
		JOIN flow_state fs ON fsr.flow_state_id = fs.flow_state_id AND fsr.app_sid = fs.app_sid
		JOIN flow_item fi ON fs.flow_state_id = fi.current_state_id AND fs.app_sid = fi.app_sid
		JOIN initiative i ON fi.flow_item_id = i.flow_Item_id AND fi.app_sid = i.app_sid
		JOIN initiative_region ir ON i.initiative_sid = ir.initiative_sid AND rrm.region_sid = ir.region_sid AND rrm.app_sid = ir.app_sid
		JOIN region rg ON ir.region_sid = rg.region_sid AND ir.app_Sid = rg.app_sid
	 WHERE  rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
	 GROUP BY i.app_sid, i.initiative_sid,
		ir.region_sid,
		fi.current_state_id, fs.label, fs.lookup_key, fs.state_colour, fs.pos,
		r.role_sid, r.name,
		rg.active
	 UNION ALL
	SELECT  i.app_sid, i.initiative_sid, ir.region_sid, 
		fi.current_state_id flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key, fs.state_colour flow_state_colour, fs.pos flow_state_pos,
		null role_sid,  null role_name,
		MAX(igfs.is_editable) is_editable,
		rg.active,
		iu.user_sid owner_sid
		FROM initiative_user iu
		JOIN initiative i ON iu.initiative_sid = i.initiative_sid AND iu.app_sid = i.app_sid
		JOIN flow_item fi ON i.flow_item_id = fi.flow_item_id AND i.app_sid = fi.app_sid
		JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.flow_sid = fs.flow_sid AND fi.app_sid = fs.app_sid
		JOIN initiative_project_user_group ipug 
		ON iu.initiative_user_group_id = ipug.initiative_user_group_id
		 AND iu.project_sid = ipug.project_sid
		JOIN initiative_group_flow_state igfs
		ON ipug.initiative_user_group_id = igfs.initiative_user_group_id
		 AND ipug.project_sid = igfs.project_sid
		 AND ipug.app_sid = igfs.app_sid
		 AND fs.flow_state_id = igfs.flow_State_id AND fs.flow_sid = igfs.flow_sid AND fs.app_sid = igfs.app_sid
		JOIN initiative_region ir ON ir.initiative_sid = i.initiative_sid AND ir.app_sid = i.app_sid
		JOIN region rg ON ir.region_sid = rg.region_sid AND ir.app_Sid = rg.app_sid
		LEFT JOIN rag_status rs ON i.rag_status_id = rs.rag_status_id AND i.app_sid = rs.app_sid
	 WHERE iu.user_sid = SYS_CONTEXT('SECURITY','SID')
	 GROUP BY i.app_sid, i.initiative_sid, ir.region_sid, 
		fi.current_state_id, fs.label, fs.lookup_key, fs.state_colour, fs.pos,
		rg.active, iu.user_sid;

-- extracts unanswered questions from quick survey responses
CREATE OR REPLACE VIEW csr.v$quick_survey_unans_quest AS
    SELECT qsr.app_sid, qsr.survey_sid, qsr.survey_response_id, qsq.question_id, qsq.pos AS question_pos, qsq.question_type, qsq.label AS question_label
	  FROM csr.v$quick_survey_response qsr
	  JOIN csr.quick_survey_question qsq ON qsq.app_sid = qsr.app_sid AND qsq.survey_sid = qsr.survey_sid AND qsr.survey_version = qsq.survey_version
	 WHERE qsq.parent_id IS NULL
	   AND qsq.is_visible = 1
	   AND qsq.question_type NOT IN ('section', 'pagebreak', 'files', 'richtext')      
	   AND ( -- questions without nested answers
	    (qsq.question_type IN ('note', 'number', 'slider', 'date', 'regionpicker', 'radio', 'rtquestion')
		 AND (qsq.question_id IN (
		   SELECT question_id 
		     FROM csr.v$quick_survey_answer
		    WHERE app_sid = qsr.app_sid
		     AND survey_response_id = qsr.survey_response_id
			 AND (answer IS NULL AND question_option_id IS NULL AND val_number IS NULL AND region_sid IS NULL))))
		-- questions with nested answers
		OR (qsq.question_type = 'checkboxgroup'
		 AND NOT EXISTS ( -- consider as unanswered if none of the options are ticked
		   SELECT qsq1.question_id 
		     FROM csr.quick_survey_question qsq1, csr.v$quick_survey_answer qsa1           
		    WHERE qsa1.app_sid = qsr.app_sid
			  AND qsa1.survey_response_id = qsr.survey_response_id 
			  AND qsq1.parent_id = qsq.question_id
			  AND qsq1.question_id = qsa1.question_id
			  AND qsq1.survey_version = qsa1.survey_version
			  AND qsq1.is_visible = 1
			  AND qsa1.val_number = 1))
		OR (qsq.question_type = 'matrix'
		 AND EXISTS ( -- consider as unanswered if any of the options/matrix-rows are not filled
		   SELECT qsq1.question_id 
		     FROM csr.quick_survey_question qsq1, csr.quick_survey_answer qsa1           
			WHERE qsa1.app_sid = qsr.app_sid
			  AND qsa1.survey_response_id = qsr.survey_response_id
			  AND qsq1.parent_id = qsq.question_id
			  AND qsq1.question_id = qsa1.question_id
			  AND qsq1.survey_version = qsa1.survey_version
			  AND qsq1.is_visible = 1
			  AND qsa1.question_option_id IS NULL))
		);

-- terms and conditions documents		
CREATE OR REPLACE VIEW csr.v$term_cond_doc AS
	SELECT tcd.doc_id, dv.filename, tcd.version, tcd.company_type_id, dv.description
	  FROM (
	    SELECT DISTINCT tcd.doc_id, dc.version, tcd.company_type_id
	      FROM csr.term_cond_doc tcd
	      JOIN csr.doc_current dc ON dc.app_sid = tcd.app_sid AND dc.doc_id = tcd.doc_id
	     WHERE tcd.app_sid = security_pkg.GetApp
		   AND dc.locked_by_sid IS NULL -- only set if current doc version needs approval or it has been marked as deleted
		   ) tcd
	  JOIN csr.doc_version dv ON dv.app_sid = security_pkg.GetApp AND dv.doc_id = tcd.doc_id AND dv.version = tcd.version;

-- ugh -> this looks nasty -- analytic function or store the id?
-- hang on? Bizarre. It doesn't even _use_ sal2??!
CREATE OR REPLACE VIEW csr.v$section_attach_log_last AS
	SELECT sal.app_sid,
			sal.section_attach_log_id,
			sal.section_sid,
			sal.attachment_id, 
			sal.log_date changed_dtm, 
			sal.csr_user_sid changed_by_sid,
			cu.full_name changed_by_name,
			sal.summary,
			sal.description
	  FROM section_attach_log sal
	  JOIN csr_user cu ON sal.csr_user_sid = cu.csr_user_sid AND sal.app_sid = cu.app_sid
	  JOIN (
		SELECT app_sid, attachment_id, MAX(log_date) log_date
		  FROM section_attach_log
		 GROUP BY app_sid, attachment_id
	) sal2 ON sal.app_sid = sal2.app_sid AND sal.log_date = sal2.log_date AND sal.attachment_id = sal2.attachment_id;



CREATE OR REPLACE VIEW csr.v$est_account AS
	SELECT a.app_sid, a.est_account_sid, a.est_account_id, a.account_customer_id,
		g.user_name, g.password, g.base_url,
		g.connect_job_interval, g.last_connect_job_dtm,
		a.share_job_interval, a.last_share_job_dtm,
		a.building_job_interval, a.meter_job_interval,
		a.auto_map_customer, a.allow_delete, a.strict_building_poll
	 FROM csr.est_account a
	 JOIN csr.est_account_global g ON a.est_account_id = g.est_account_id
;

CREATE OR REPLACE VIEW csr.v$est_customer AS
	SELECT a.app_sid, a.est_account_sid, a.pm_customer_id, a.est_customer_sid,
  		g.org_name, g.email
  	  FROM csr.est_customer a
  	  JOIN csr.est_customer_global g ON a.pm_customer_id = g.pm_customer_id
;

CREATE OR REPLACE VIEW csr.V$ENHESA_TOPIC AS
    SELECT t.app_sid, t.topic_id, t.country_code, ecn.name country, stn.status_id, stn.name status, 
        t.report_dtm, t.adoption_dtm, t.importance, t.archived, t.version topic_version, t.url, t.region_sid,
        tt.version text_version, tt.version_pub_dtm text_version_pub_dtm, tt.title, tt.abstract, tt.analysis, tt.affected_ops,
        tt.reg_citation, tt.biz_impact, t.flow_item_id, fs.label flow_state_label, fs.state_colour, fs.lookup_key state_lookup_key, t.protocol
      FROM csr.enhesa_topic t
      JOIN csr.enhesa_topic_text tt ON t.topic_id = tt.topic_id AND tt.lang = 'en' AND t.protocol = tt.protocol
      JOIN csr.enhesa_status_name stn ON t.status_id = stn.status_id AND stn.lang = 'en'
      JOIN csr.enhesa_country_name ecn ON t.country_code = ecn.country_code AND ecn.lang = 'en'
      JOIN csr.flow_item fi ON t.flow_item_id = fi.flow_item_id AND t.app_sid = fi.app_sid
      JOIN csr.flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid
    ;

CREATE OR REPLACE VIEW csr.V$ENHESA_TOPIC_REGION AS  
    SELECT tr.topic_id, tr.country_code, cn.name country, tr.region_code, crn.name region, tr.protocol
      FROM csr.enhesa_topic_region tr 
      JOIN csr.enhesa_country_name cn ON tr.country_code = cn.country_code AND cn.lang = 'en'
      JOIN csr.enhesa_country_region_name crn ON tr.country_code = crn.country_code AND tr.region_code = crn.region_code AND crn.lang = 'en'
    ; 

CREATE OR REPLACE VIEW csr.V$ENHESA_TOPIC_KEYWORD AS
    SELECT tk.topic_id, tk.keyword_id, kt.main, kt.category, tk.protocol
      FROM csr.enhesa_topic_keyword tk 
      JOIN csr.enhesa_keyword_text kt ON tk.keyword_id = kt.keyword_id AND kt.lang = 'en' AND tk.protocol = kt.protocol
    ; 

CREATE OR REPLACE VIEW csr.V$ENHESA_TOPIC_REG AS
    SELECT tr.topic_id, tr.reg_id, r.parent_reg_id, r.reg_ref, rt.title, r.ref_dtm, r.link, r.archived, r.version reg_version,
        r.reg_level, rt.version reg_text_version, rt.version_pub_dtm reg_text_version_pub_dtm, tr.protocol
      FROM csr.enhesa_topic_reg tr
      JOIN csr.enhesa_reg r ON tr.reg_id = r.reg_id AND tr.protocol = r.protocol
      JOIN csr.enhesa_reg_text rt ON r.reg_id = rt.reg_id AND rt.lang = 'en' AND tr.protocol = rt.protocol
    ;

CREATE OR REPLACE VIEW CSR.V$EST_ERROR AS
	SELECT APP_SID, EST_ERROR_ID, REGION_SID, EST_ACCOUNT_SID, PM_CUSTOMER_ID, PM_BUILDING_ID, PM_SPACE_ID, PM_METER_ID,
		ERROR_LEVEL, ERROR_DTM, ERROR_CODE, ERROR_MESSAGE, REQUEST_URL, REQUEST_HEADER, REQUEST_BODY, RESPONSE
	  FROM CSR.EST_ERROR
	 WHERE ACTIVE = 1
	;



-- *** Packages ***
@../training_pkg
@../training_body
@../issue_body
@../property_body
--FB64329
@../enable_body

@update_tail