define version=3022
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/

ALTER TABLE CSR.METER_ORPHAN_DATA ADD (
	REGION_SID						NUMBER(10),
	HAS_OVERLAP						NUMBER(1)	DEFAULT 0 NOT NULL,
	ERROR_TYPE_ID					NUMBER(10),
	CHECK (HAS_OVERLAP IN (0,1))
);

--Failed to locate all sections of latest3013_6.sql
DROP TYPE CHAIN.T_BUS_REL_COMP_TABLE;
CREATE OR REPLACE TYPE CHAIN.T_BUS_REL_COMP_ROW AS
	OBJECT (
		BUSINESS_RELATIONSHIP_ID	NUMBER(10),
		BUSINESS_RELATIONSHIP_TIER_ID	NUMBER(10),
		POS							NUMBER(10),
		COMPANY_SID					NUMBER(10),
		MAP MEMBER FUNCTION MAP
			RETURN VARCHAR2
	);
/
CREATE OR REPLACE TYPE BODY CHAIN.T_BUS_REL_COMP_ROW AS
	MAP MEMBER FUNCTION MAP
		RETURN VARCHAR2
	IS
	BEGIN
		RETURN BUSINESS_RELATIONSHIP_ID||'/'||BUSINESS_RELATIONSHIP_TIER_ID||'/'||POS;
	END;
END;
/
CREATE OR REPLACE TYPE CHAIN.T_BUS_REL_COMP_TABLE AS
	TABLE OF CHAIN.T_BUS_REL_COMP_ROW;
/
CREATE TABLE csr.INTERNAL_AUDIT_TYPE_SOURCE (
	INTERNAL_AUDIT_TYPE_SOURCE_ID 	NUMBER(10) NOT NULL,
	INTERNAL_AUDIT_TYPE_SOURCE 		VARCHAR2(255),
	CONSTRAINT PK_INTERNAL_AUDIT_TYPE_SOURCE PRIMARY KEY (INTERNAL_AUDIT_TYPE_SOURCE_ID)
);
--Failed to locate all sections of latest3018_4.sql
CREATE TABLE CSR.AUTO_IMP_CORE_DATA_VAL_FAIL (
	APP_SID						NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	VAL_ID						NUMBER(10) NOT NULL,
	INSTANCE_ID					NUMBER(10) NOT NULL,
	INSTANCE_STEP_ID			NUMBER(10) NOT NULL,
	IND_SID						NUMBER(10),
	IND_TEXT					VARCHAR2(1024) NOT NULL,
	REGION_SID					NUMBER(10),
	REGION_TEXT					VARCHAR2(1024) NOT NULL,
	MEASURE_CONVERSION_ID		NUMBER(10),
	MEASURE_TEXT				VARCHAR2(1024),
	VAL_NUMBER					NUMBER(24, 10),
	NOTE						CLOB,
	SOURCE_FILE_REF				VARCHAR2(1024),
	START_DTM					DATE NOT NULL,
	END_DTM						DATE NOT NULL,
	CONSTRAINT PK_AUTO_IMP_CORE_DATA_VAL_FAIL PRIMARY KEY (APP_SID, VAL_ID)
);
CREATE SEQUENCE CSR.CUSTOM_FACTOR_HISTORY_SEQ;
CREATE TABLE CSR.CUSTOM_FACTOR_HISTORY (
	APP_SID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	CUSTOM_FACTOR_HISTORY_ID	NUMBER(10) NOT NULL,
	FACTOR_CAT_ID			NUMBER(10) NOT NULL,
	FACTOR_TYPE_ID			NUMBER(10) NOT NULL,
	FACTOR_SET_ID			NUMBER(10) NOT NULL,
	GEO_COUNTRY				VARCHAR2(2),
	GEO_REGION				VARCHAR2(2),
	EGRID_REF				VARCHAR2(4),
	REGION_SID				NUMBER(10),
	GAS_TYPE_ID				NUMBER(10),
	START_DTM				DATE NOT NULL,
	END_DTM					DATE,
	FIELD_NAME				VARCHAR2(1024),
	OLD_VAL					VARCHAR2(1024),
	NEW_VAL					VARCHAR2(1024),
	MESSAGE					VARCHAR2(1024),
	AUDIT_DATE				DATE DEFAULT SYSDATE NOT NULL,
	USER_SID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','SID') NOT NULL,
	CONSTRAINT PK_CUSTOM_FACTOR_HISTORY PRIMARY KEY (APP_SID, CUSTOM_FACTOR_HISTORY_ID)
);
CREATE TABLE CSRIMP.CUSTOM_FACTOR_HISTORY (
	CSRIMP_SESSION_ID	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CUSTOM_FACTOR_HISTORY_ID	NUMBER(10) NOT NULL,
	FACTOR_CAT_ID			NUMBER(10) NOT NULL,
	FACTOR_TYPE_ID			NUMBER(10) NOT NULL,
	FACTOR_SET_ID			NUMBER(10) NOT NULL,
	GEO_COUNTRY				VARCHAR2(2),
	GEO_REGION				VARCHAR2(2),
	EGRID_REF				VARCHAR2(4),
	REGION_SID				NUMBER(10),
	GAS_TYPE_ID				NUMBER(10),
	START_DTM				DATE NOT NULL,
	END_DTM					DATE,
	FIELD_NAME				VARCHAR2(1024),
	OLD_VAL					VARCHAR2(1024),
	NEW_VAL					VARCHAR2(1024),
	MESSAGE					VARCHAR2(1024),
	AUDIT_DATE				DATE NOT NULL,
	USER_SID				NUMBER(10) NOT NULL,
	CONSTRAINT PK_CUSTOM_FACTOR_HISTORY PRIMARY KEY (CSRIMP_SESSION_ID, CUSTOM_FACTOR_HISTORY_ID),
	CONSTRAINT FK_CUSTOM_FACTOR_HISTORY_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSR.METER_MATCH_BATCH_JOB (
	APP_SID							NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	BATCH_JOB_ID					NUMBER(10)		NOT NULL,
	METER_RAW_DATA_ID				NUMBER(10),
	CONSTRAINT PK_METER_MATCH_BATCH_JOB PRIMARY KEY (APP_SID, BATCH_JOB_ID)
);
CREATE TABLE CSR.METER_RAW_DATA_IMPORT_JOB (
	APP_SID							NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	BATCH_JOB_ID					NUMBER(10)		NOT NULL,
	METER_RAW_DATA_ID				NUMBER(10),
	CONSTRAINT PK_METER_RAW_DATA_IMPORT_JOB PRIMARY KEY (APP_SID, BATCH_JOB_ID)
);
CREATE TABLE CSR.DUFF_METER_ERROR_TYPE (
	ERROR_TYPE_ID					NUMBER(10)		NOT NULL,
	LABEL							VARCHAR2(256)	NOT NULL,
	CONSTRAINT PK_DUFF_METER_ERROR_TYPE PRIMARY KEY (ERROR_TYPE_ID)
);
CREATE TABLE CSR.DUFF_METER_REGION (
	APP_SID							NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	URJANET_METER_ID				VARCHAR2(256)	NOT NULL,
	METER_NAME						VARCHAR2(1024)	NOT NULL,
	METER_NUMBER					VARCHAR2(256),
	REGION_REF						VARCHAR2(256),
	SERVICE_TYPE					VARCHAR2(256)	NOT NULL,
	METER_RAW_DATA_ID				NUMBER(10)		NOT NULL,
	METER_RAW_DATA_ERROR_ID			NUMBER(10),
	REGION_SID						NUMBER(10),
	ISSUE_ID						NUMBER(10),
	MESSAGE							VARCHAR2(4000),
	ERROR_TYPE_ID					NUMBER(10) 		NOT NULL,
	CREATED_DTM						DATE			DEFAULT SYSDATE NOT NULL,
	UPDATED_DTM						DATE			DEFAULT SYSDATE NOT NULL, 
	CONSTRAINT PK_DUFF_METER_REGION PRIMARY KEY (APP_SID, URJANET_METER_ID)
);
CREATE TABLE CSRIMP.DUFF_METER_REGION (
	CSRIMP_SESSION_ID				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	URJANET_METER_ID				VARCHAR2(256)	NOT NULL,
	METER_NAME						VARCHAR2(1024)	NOT NULL,
	METER_NUMBER					VARCHAR2(256),
	REGION_REF						VARCHAR2(256),
	SERVICE_TYPE					VARCHAR2(256)	NOT NULL,
	METER_RAW_DATA_ID				NUMBER(10)		NOT NULL,
	METER_RAW_DATA_ERROR_ID			NUMBER(10),
	REGION_SID						NUMBER(10),
	ISSUE_ID						NUMBER(10),
	MESSAGE							VARCHAR2(4000),
	ERROR_TYPE_ID					NUMBER(10) 		NOT NULL,
	CREATED_DTM						DATE			NOT NULL,
	UPDATED_DTM						DATE			NOT NULL, 
	CONSTRAINT PK_DUFF_METER_REGION PRIMARY KEY (CSRIMP_SESSION_ID, URJANET_METER_ID),
	CONSTRAINT FK_DUFF_METER_REGION_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_DUFF_METER_REGION (
	URJANET_METER_ID				VARCHAR2(256)	NOT NULL,
	METER_NAME						VARCHAR2(1024)	NOT NULL,
	METER_NUMBER					VARCHAR2(256),
	REGION_REF						VARCHAR2(256),
	SERVICE_TYPE					VARCHAR2(256)	NOT NULL,
	METER_RAW_DATA_ID				NUMBER(10)		NOT NULL,
	METER_RAW_DATA_ERROR_ID			NUMBER(10),
	REGION_SID						NUMBER(10),
	ISSUE_ID						NUMBER(10),
	MESSAGE							VARCHAR2(4000),
	ERROR_TYPE_ID					NUMBER(10) 		NOT NULL,
	CONSTRAINT PK_TEMP_DUFF_METER_REGION PRIMARY KEY (URJANET_METER_ID)
) ON COMMIT DELETE ROWS;
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_FIXED_DUFF_METER_REGION (
	URJANET_METER_ID				VARCHAR2(256)	NOT NULL,
	CONSTRAINT PK_TEMP_FIXED_DUFF_MTR_REGN PRIMARY KEY (URJANET_METER_ID)
) ON COMMIT DELETE ROWS;
CREATE TABLE csr.meter_data_source_hi_res_input (
	app_sid						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	raw_data_source_id			NUMBER(10) NOT NULL,
	meter_input_id				NUMBER(10) NOT NULL,
	CONSTRAINT pk_meter_data_src_hi_res_input PRIMARY KEY (app_sid, raw_data_source_id, meter_input_id),
	CONSTRAINT fk_meter_src_hi_res_meter_src FOREIGN KEY (app_sid, raw_data_source_id)
		REFERENCES csr.meter_raw_data_source (app_sid, raw_data_source_id),
	CONSTRAINT fk_meter_src_hi_res_mtr_input FOREIGN KEY (app_sid, meter_input_id)
		REFERENCES csr.meter_input (app_sid, meter_input_id)
);
CREATE TABLE csrimp.meter_data_source_hi_res_input (
	csrimp_session_id			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	raw_data_source_id			NUMBER(10) NOT NULL,
	meter_input_id				NUMBER(10) NOT NULL,
	CONSTRAINT pk_meter_data_src_hi_res_input PRIMARY KEY (csrimp_session_id, raw_data_source_id, meter_input_id),
	CONSTRAINT fk_meter_data_src_hi_res_in_is FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);
DROP TYPE CHAIN.T_BUS_REL_PATH_TABLE;
DROP TYPE CHAIN.T_BUS_REL_PATH_ROW;
DROP TYPE CHAIN.T_BUS_REL_COMP_TABLE;
CREATE OR REPLACE TYPE CHAIN.T_BUS_REL_COMP_ROW AS
	OBJECT (
		STARTING_COMPANY_SID		NUMBER(10),
		BUSINESS_RELATIONSHIP_ID	NUMBER(10),
		BUSINESS_RELATIONSHIP_TIER_ID	NUMBER(10),
		POS							NUMBER(10),
		COMPANY_SID					NUMBER(10),
		MAP MEMBER FUNCTION MAP
			RETURN VARCHAR2
	);
/
CREATE OR REPLACE TYPE BODY CHAIN.T_BUS_REL_COMP_ROW AS
	MAP MEMBER FUNCTION MAP
		RETURN VARCHAR2
	IS
	BEGIN
		RETURN STARTING_COMPANY_SID||':'||BUSINESS_RELATIONSHIP_ID||'/'||BUSINESS_RELATIONSHIP_TIER_ID||'.'||POS;
	END;
END;
/
CREATE OR REPLACE TYPE CHAIN.T_BUS_REL_COMP_TABLE AS
	TABLE OF CHAIN.T_BUS_REL_COMP_ROW;
/


ALTER TABLE chain.business_relationship_tier ADD (
	allow_multiple_companies			NUMBER(1, 0) DEFAULT 0 NOT NULL
);
ALTER TABLE csrimp.chain_busine_relati_tier ADD (
	allow_multiple_companies			NUMBER(1, 0) NOT NULL
);
ALTER TABLE chain.business_relationship_company DROP PRIMARY KEY;
ALTER TABLE chain.business_relationship_company ADD (
	pos									NUMBER(10, 0) DEFAULT 0 NOT NULL
);
ALTER TABLE chain.business_relationship_company ADD CONSTRAINT pk_bus_rel_company PRIMARY KEY (app_sid, business_relationship_id, business_relationship_tier_id, pos);
ALTER TABLE csrimp.chain_busin_relat_compan DROP PRIMARY KEY;
ALTER TABLE csrimp.chain_busin_relat_compan ADD (
	pos									NUMBER(10, 0) NOT NULL
);
ALTER TABLE csrimp.chain_busin_relat_compan ADD CONSTRAINT pk_chain_busin_relat_compan PRIMARY KEY (csrimp_session_id, business_relationship_id, business_relationship_tier_id, pos);
ALTER TABLE csr.INTERNAL_AUDIT_TYPE ADD INTERNAL_AUDIT_TYPE_SOURCE_ID NUMBER(10) NULL;
ALTER TABLE csr.INTERNAL_AUDIT_TYPE ADD CONSTRAINT FK_INTERNAL_AUDIT_SOURCE
	FOREIGN KEY (INTERNAL_AUDIT_TYPE_SOURCE_ID)
 REFERENCES csr.INTERNAL_AUDIT_TYPE_SOURCE(INTERNAL_AUDIT_TYPE_SOURCE_ID);
ALTER TABLE csrimp.INTERNAL_AUDIT_TYPE ADD INTERNAL_AUDIT_TYPE_SOURCE_ID NUMBER(10) NOT NULL;
create index csr.ix_internal_audit_type_source ON csr.internal_audit_type (internal_audit_type_source_id);
alter table csr.batch_job_type add max_concurrent_jobs number(10);
alter table csr.batch_job add priority number(10) default 1 not null;
alter table csr.batch_job rename column one_at_a_time to in_order;
alter table csr.batch_job_type rename column one_at_a_time to in_order;
alter table csr.batch_job add ram_usage number(20) default null;
alter table csr.batch_job add cpu_ms number(20) default null;
alter table csr.batch_job_type add ram_estimate number(20) default null;
alter table csr.batch_job_Type add priority number(10) default 1 not null;
create index ix_batch_job_completed_dtm on csr.batch_job (completed_dtm);
alter table csr.batch_job drop constraint CK_BATCH_JOB_ONE_AT_A_TIME;
alter table csr.batch_job add CONSTRAINT CK_BATCH_JOB_IN_ORDER CHECK (IN_ORDER IN (0, 1));
alter table csr.batch_job_type drop constraint CK_BATCH_JOB_TYPE_ONE_AT_TIME;
alter table csr.batch_job_type add CONSTRAINT CK_BATCH_JOB_TYPE_IN_ORDER CHECK (IN_ORDER IN (0, 1));
CREATE TABLE CSR.BATCH_JOB_TYPE_APP_CFG
(
	APP_SID							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	BATCH_JOB_TYPE_ID				NUMBER(10) NOT NULL,
	RAM_ESTIMATE					NUMBER(20),
	PRIORITY						NUMBER(10),
	MAX_CONCURRENT_JOBS				NUMBER(10),
	CONSTRAINT PK_BATCH_JOB_TYPE_APP_CFG PRIMARY KEY (APP_SID, BATCH_JOB_TYPE_ID)
);
	
ALTER TABLE CSR.BATCH_JOB_TYPE_APP_CFG ADD
	CONSTRAINT FK_BJT_APP_CFG_CUSTOMER FOREIGN KEY (APP_SID)
	REFERENCES CSR.CUSTOMER (APP_SID);
	
ALTER TABLE CSR.BATCH_JOB_TYPE_APP_CFG ADD
	CONSTRAINT FK_BJT_APP_CFG_BJT FOREIGN KEY (BATCH_JOB_TYPE_ID)
	REFERENCES CSR.BATCH_JOB_TYPE (BATCH_JOB_TYPE_ID);
CREATE TABLE CSR.BATCH_JOB_TYPE_APP_STAT
(
	APP_SID							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	BATCH_JOB_TYPE_ID				NUMBER(10) NOT NULL,
	RAM_MAX							NUMBER(20),
	RAM_AVG							NUMBER(20),
	CPU_MAX_MS						NUMBER(20),
	CPU_AVG_MS						NUMBER(20),
	RUN_TIME_MAX					NUMBER(20),
	RUN_TIME_AVG					NUMBER(20),
	START_DELAY_MAX					NUMBER(20),
	START_DELAY_AVG					NUMBER(20),
	CONSTRAINT PK_BATCH_JOB_TYPE_APP_STAT PRIMARY KEY (APP_SID, BATCH_JOB_TYPE_ID)
);
ALTER TABLE CSR.BATCH_JOB_TYPE_APP_STAT ADD CONSTRAINT FK_BJT_APP_STAT_CUSTOMER
FOREIGN KEY (APP_SID) REFERENCES CSR.CUSTOMER (APP_SID);
ALTER TABLE CSR.BATCH_JOB_TYPE_APP_STAT ADD 	CONSTRAINT FK_BJT_APP_STAT_BJT
FOREIGN KEY (BATCH_JOB_TYPE_ID) REFERENCES CSR.BATCH_JOB_TYPE
(BATCH_JOB_TYPE_ID);
create index csr.ix_bjt_app_cfg_bjt on csr.batch_job_type_app_cfg (batch_job_type_id);
create index csr.ix_bjt_app_stat_bjt on csr.batch_job_type_app_stat (batch_job_type_id);
CREATE TABLE CSR.BATCH_JOB_NOTIFY (
	APP_SID							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL, 
	BATCH_JOB_ID 					NUMBER(10) NOT NULL,
	CONSTRAINT PK_BATCH_JOB_NOTIFY_TABLE PRIMARY KEY (APP_SID, BATCH_JOB_ID)
);
CREATE MATERIALIZED VIEW LOG ON CSR.BATCH_JOB_NOTIFY;
GRANT CREATE TABLE TO CSR;
CREATE MATERIALIZED VIEW CSR.V$BATCH_JOB_NOTIFY BUILD IMMEDIATE REFRESH FAST ON COMMIT AS
	SELECT APP_SID, BATCH_JOB_ID
	  FROM CSR.BATCH_JOB_NOTIFY;
REVOKE CREATE TABLE FROM CSR;
ALTER TABLE CSR.BATCH_JOB_NOTIFY ADD CONSTRAINT
	FK_BATCH_JOB_NOTIFY_CUSTOMER FOREIGN KEY (APP_SID)
	REFERENCES CSR.CUSTOMER (APP_SID);
begin
execute immediate
'CREATE OR REPLACE TRIGGER csr.batch_job_notify_trigger
	AFTER INSERT ON csr.v$batch_job_notify
BEGIN
	csr.batch_job_pk' ||'g.TriggerRun(0);
END;';
end;
/
begin
	dbms_java.grant_permission( 'CSR', 'SYS:java.net.SocketPermission', 'localhost:0', 'listen,resolve' );
	dbms_java.grant_permission( 'CSR', 'SYS:java.net.SocketPermission', '255.255.255.255:899', 'connect,resolve' );
end;
/
DECLARE
	v_enqueue_options				dbms_aq.enqueue_options_t;
	v_message_properties			dbms_aq.message_properties_t;
	v_message_handle				RAW(16);
BEGIN
	DBMS_AQADM.STOP_QUEUE (
		queue_name => 'csr.batch_job_queue'
	);
	DBMS_AQADM.DROP_QUEUE (
		queue_name  => 'csr.batch_job_queue'
	);
	DBMS_AQADM.DROP_QUEUE_TABLE (
		queue_table        => 'csr.batch_job_queue'
	);
	COMMIT;
END;
/
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.MarkFailedBatchJobs',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'csr.batch_job_pkg.MarkFailedJobs;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY;INTERVAL=3',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Mark batch jobs as failed (if they have failed)');
END;
/
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.BatchJobStats',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'csr.batch_job_pkg.ComputeJobStats;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 01:43 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=DAILY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Compute aggregate batch job stats');
       COMMIT;
END;
/
alter index CSR.UX_BATCH_JOB_ONE_AT_A_TIME rename to UX_BATCH_JOB_IN_ORDER;
DECLARE v_curr NUMBER;
BEGIN
	SELECT chain.dedupe_rule_id_seq.nextval
	  INTO v_curr
	  FROM dual;
	EXECUTE IMMEDIATE'
		CREATE SEQUENCE chain.dedupe_rule_set_id_seq
			START WITH '||v_curr||' 
			INCREMENT BY 1
			NOMINVALUE
			NOMAXVALUE
			CACHE 20
			NOORDER
	';
	EXECUTE IMMEDIATE 'DROP SEQUENCE chain.dedupe_rule_id_seq';
END;
/
grant select on chain.dedupe_rule_set_id_seq to csrimp;
ALTER TABLE chain.dedupe_rule RENAME TO dedupe_rule_set;
ALTER TABLE chain.dedupe_rule_set RENAME COLUMN dedupe_rule_id TO dedupe_rule_set_id;
ALTER TABLE chain.dedupe_rule_set RENAME CONSTRAINT pk_dedupe_rule TO pk_dedupe_rule_set;
ALTER INDEX chain.pk_dedupe_rule RENAME TO pk_dedupe_rule_set;
ALTER TABLE chain.dedupe_rule_set RENAME CONSTRAINT uc_dedupe_rule TO uc_dedupe_rule_set;
ALTER INDEX chain.uc_dedupe_rule RENAME TO uc_dedupe_rule_set;
	
ALTER TABLE chain.dedupe_rule_mapping RENAME TO dedupe_rule;
ALTER TABLE chain.dedupe_rule RENAME COLUMN dedupe_rule_id TO dedupe_rule_set_id;
ALTER TABLE chain.dedupe_rule RENAME CONSTRAINT pk_dedupe_rule_mapping TO pk_dedupe_rule;
ALTER INDEX chain.pk_dedupe_rule_mapping RENAME TO pk_dedupe_rule;
ALTER TABLE chain.dedupe_rule DROP COLUMN is_fuzzy;
ALTER TABLE chain.dedupe_rule RENAME CONSTRAINT uc_dedupe_rule_mapping TO uc_dedupe_rule;
ALTER INDEX chain.uc_dedupe_rule_mapping RENAME TO uc_dedupe_rule;
ALTER TABLE chain.dedupe_rule RENAME CONSTRAINT fk_dedupe_rule_mapping_rule TO fk_dedupe_rule_rule_set;
ALTER TABLE chain.dedupe_rule RENAME CONSTRAINT FK_DEDUPE_RULE_MAPPING_MAP to fk_dedupe_rule_mapping;
ALTER TABLE chain.dedupe_match RENAME COLUMN dedupe_rule_id TO dedupe_rule_set_id;
ALTER TABLE chain.dedupe_match RENAME CONSTRAINT fk_dedupe_match_rule TO fk_dedupe_match_rule_set;
ALTER TABLE csrimp.chain_dedupe_rule RENAME TO chain_dedupe_rule_set;
ALTER TABLE csrimp.chain_dedupe_rule_mappin RENAME TO chain_dedupe_rule;
ALTER TABLE csrimp.chain_dedupe_rule_set RENAME COLUMN dedupe_rule_id to dedupe_rule_set_id;
ALTER TABLE csrimp.chain_dedupe_rule RENAME COLUMN dedupe_rule_id to dedupe_rule_set_id;
ALTER TABLE csrimp.chain_dedupe_match RENAME COLUMN dedupe_rule_id to dedupe_rule_set_id;
ALTER TABLE csrimp.map_chain_dedupe_rule RENAME TO map_chain_dedupe_rule_set;
ALTER TABLE csrimp.map_chain_dedupe_rule_set RENAME COLUMN old_dedupe_rule_id to old_dedupe_rule_set_id;
ALTER TABLE csrimp.map_chain_dedupe_rule_set RENAME COLUMN new_dedupe_rule_id to new_dedupe_rule_set_id;
ALTER TABLE CSR.AUTO_IMP_CORE_DATA_VAL_FAIL ADD CONSTRAINT FK_AUTIMP_CR_DT_VL_FAIL_REG 
	FOREIGN KEY (APP_SID, REGION_SID)
	REFERENCES CSR.REGION (APP_SID, REGION_SID)
;
ALTER TABLE CSR.AUTO_IMP_CORE_DATA_VAL_FAIL ADD CONSTRAINT FK_AUTIMP_CR_DT_VL_FAIL_IND 
	FOREIGN KEY (APP_SID, IND_SID)
	REFERENCES CSR.IND (APP_SID, IND_SID)
;
ALTER TABLE CSR.AUTO_IMP_CORE_DATA_VAL_FAIL ADD CONSTRAINT FK_AUTIMP_CR_DT_VL_FAIL_MEAS 
	FOREIGN KEY (APP_SID, MEASURE_CONVERSION_ID)
	REFERENCES CSR.MEASURE_CONVERSION (APP_SID, MEASURE_CONVERSION_ID)
;
ALTER TABLE CSR.AUTO_IMP_CORE_DATA_VAL_FAIL ADD CONSTRAINT FK_AUTIMP_CR_DT_VL_FAIL_STEP 
	FOREIGN KEY (APP_SID, INSTANCE_STEP_ID)
	REFERENCES CSR.AUTOMATED_IMPORT_INSTANCE_STEP (APP_SID, AUTO_IMPORT_INSTANCE_STEP_ID)
;
ALTER TABLE CSR.AUTOMATED_IMPORT_INSTANCE_STEP
ADD CUSTOM_URL VARCHAR2(1024);
ALTER TABLE CSR.AUTOMATED_IMPORT_INSTANCE_STEP
ADD CUSTOM_URL_TITLE VARCHAR(255);
ALTER TABLE CSR.AUTOMATED_IMPORT_INSTANCE_STEP
ADD CONSTRAINT CK_AUTO_IMP_INST_STP_URL_TITLE CHECK ((CUSTOM_URL IS NOT NULL AND CUSTOM_URL_TITLE IS NOT NULL) OR (CUSTOM_URL IS NULL AND CUSTOM_URL_TITLE IS NULL));
create index csr.ix_auto_imp_core_instance_step on csr.auto_imp_core_data_val_fail (app_sid, instance_step_id);
create index csr.ix_auto_imp_core_ind_sid on csr.auto_imp_core_data_val_fail (app_sid, ind_sid);
create index csr.ix_auto_imp_core_region_sid on csr.auto_imp_core_data_val_fail (app_sid, region_sid);
create index csr.ix_auto_imp_core_measure_conve on csr.auto_imp_core_data_val_fail (app_sid, measure_conversion_id);

ALTER TABLE CSRIMP.METER_ORPHAN_DATA ADD (
	REGION_SID						NUMBER(10),
	HAS_OVERLAP						NUMBER(1)		NOT NULL,
	ERROR_TYPE_ID					NUMBER(10),
	CHECK (HAS_OVERLAP IN (0,1))
);
ALTER TABLE CSR.AUTO_IMP_IMPORTER_SETTINGS ADD (
	EXCEL_ROW_INDEX					NUMBER(10),
	DATA_TYPE						VARCHAR2(256)
);
ALTER TABLE CSR.METER_RAW_DATA_SOURCE ADD (
	PROCESS_BODY					NUMBER(1)
);
	
ALTER TABLE CSRIMP.METER_RAW_DATA_SOURCE ADD (
	PROCESS_BODY					NUMBER(1)
);
UPDATE CSR.METER_RAW_DATA_SOURCE
   SET PROCESS_BODY = 0
 WHERE PROCESS_BODY IS NULL;
   
ALTER TABLE CSR.METER_RAW_DATA_SOURCE MODIFY PROCESS_BODY NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.METER_MATCH_BATCH_JOB ADD CONSTRAINT FK_BATCHJOB_METMATBATJOB
    FOREIGN KEY (APP_SID, BATCH_JOB_ID)
    REFERENCES CSR.BATCH_JOB(APP_SID, BATCH_JOB_ID)
;
ALTER TABLE CSR.METER_RAW_DATA_IMPORT_JOB ADD CONSTRAINT FK_BATCHJOB_METRAWDATAJOB
    FOREIGN KEY (APP_SID, BATCH_JOB_ID)
    REFERENCES CSR.BATCH_JOB(APP_SID, BATCH_JOB_ID)
;
ALTER TABLE CSR.DUFF_METER_REGION ADD CONSTRAINT FK_DUFMETERG_REGION
	FOREIGN KEY (APP_SID, REGION_SID)
	REFERENCES CSR.REGION(APP_SID, REGION_SID)
;
ALTER TABLE CSR.DUFF_METER_REGION ADD CONSTRAINT FK_DUFMETERG_ISSUE
	FOREIGN KEY (APP_SID, ISSUE_ID)
	REFERENCES CSR.ISSUE(APP_SID, ISSUE_ID)
;
ALTER TABLE CSR.DUFF_METER_REGION ADD CONSTRAINT FK_DUFMETERG_ORPMETDAT
	FOREIGN KEY (ERROR_TYPE_ID)
	REFERENCES CSR.DUFF_METER_ERROR_TYPE(ERROR_TYPE_ID)
;
ALTER TABLE CSR.METER_ORPHAN_DATA ADD CONSTRAINT FK_METERORPHANDATADATA_REGION
	FOREIGN KEY (APP_SID, REGION_SID)
	REFERENCES CSR.REGION(APP_SID, REGION_SID)
;
ALTER TABLE CSR.METER_ORPHAN_DATA ADD CONSTRAINT FK_DUFMETERRTYP_ORPMETDAT
	FOREIGN KEY (ERROR_TYPE_ID)
	REFERENCES CSR.DUFF_METER_ERROR_TYPE(ERROR_TYPE_ID)
;
CREATE INDEX CSR.IX_DUFMETERG_REGION ON CSR.DUFF_METER_REGION (APP_SID, REGION_SID);
CREATE INDEX CSR.IX_DUFMETERG_ISSUE ON CSR.DUFF_METER_REGION (APP_SID, ISSUE_ID);
CREATE INDEX CSR.IX_DUFMETERG_ORPMETDAT ON CSR.DUFF_METER_REGION(ERROR_TYPE_ID);
CREATE INDEX CSR.IX_METERORPHANDATADATA_REGION ON CSR.METER_ORPHAN_DATA(APP_SID, REGION_SID);
CREATE INDEX CSR.IX_DUFMETERRTYP_ORPMETDAT ON CSR.METER_ORPHAN_DATA(ERROR_TYPE_ID);
DROP INDEX CSR.UK_METER_ORPHAN_DATA;
CREATE UNIQUE INDEX CSR.UK_METER_ORPHAN_DATA ON CSR.METER_ORPHAN_DATA(APP_SID, SERIAL_ID, METER_INPUT_ID, PRIORITY, START_DTM, END_DTM, UOM);
ALTER TABLE csr.auto_imp_mail_attach_filter ADD (
	attachment_validator_plugin		VARCHAR2(1024)
);
ALTER TABLE csr.temp_meter_reading_rows ADD (
	priority						NUMBER(10)
);
ALTER TABLE csr.meter_insert_data ADD (
	priority						NUMBER(10)
);
ALTER TABLE csr.metering_options ADD (
	period_set_id				NUMBER(10),
	period_interval_id			NUMBER(10),
	show_invoice_reminder		NUMBER(1) DEFAULT 0 NOT NULL,
	invoice_reminder			VARCHAR2(1024),
	supplier_data_mandatory		NUMBER(1) DEFAULT 0 NOT NULL,
	region_date_clipping		NUMBER(1) DEFAULT 0 NOT NULL,
	fwd_estimate_meters			NUMBER(1) DEFAULT 0 NOT NULL,
	reference_mandatory			NUMBER(1) DEFAULT 0 NOT NULL,
	realtime_metering_enabled	NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_show_invoice_reminder_1_0 CHECK (show_invoice_reminder IN (1,0)),
	CONSTRAINT chk_supplier_data_mand_1_0 CHECK (supplier_data_mandatory IN (1,0)),
	CONSTRAINT chk_region_date_clipping_1_0 CHECK (region_date_clipping IN (1,0)),
	CONSTRAINT chk_fwd_estimate_meters_1_0 CHECK (fwd_estimate_meters IN (1,0)),
	CONSTRAINT chk_reference_mandatory_1_0 CHECK (reference_mandatory IN (1,0)),
	CONSTRAINT chk_realtime_meter_enbld_1_0 CHECK (realtime_metering_enabled IN (1,0)),
	CONSTRAINT fk_metering_options_period_set FOREIGN KEY (app_sid, period_set_id, period_interval_id)
		REFERENCES csr.period_interval (app_sid, period_set_id, period_interval_id)
);
DELETE FROM csrimp.metering_options;
ALTER TABLE csrimp.metering_options ADD (
	CONSTRAINT FK_METERING_OPTIONS_IS FOREIGN KEY (CSRIMP_SESSION_ID) 
		REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);
ALTER TABLE csrimp.metering_options ADD (
	period_set_id				NUMBER(10) NOT NULL,
	period_interval_id			NUMBER(10) NOT NULL,
	show_invoice_reminder		NUMBER(1) NOT NULL,
	invoice_reminder			VARCHAR2(1024),
	supplier_data_mandatory		NUMBER(1) NOT NULL,
	region_date_clipping		NUMBER(1) NOT NULL,
	fwd_estimate_meters			NUMBER(1) NOT NULL,
	reference_mandatory			NUMBER(1) NOT NULL,
	realtime_metering_enabled	NUMBER(1) NOT NULL,
	CONSTRAINT chk_show_invoice_reminder_1_0 CHECK (show_invoice_reminder IN (1,0)),
	CONSTRAINT chk_supplier_data_mand_1_0 CHECK (supplier_data_mandatory IN (1,0)),
	CONSTRAINT chk_region_date_clipping_1_0 CHECK (region_date_clipping IN (1,0)),
	CONSTRAINT chk_fwd_estimate_meters_1_0 CHECK (fwd_estimate_meters IN (1,0)),
	CONSTRAINT chk_reference_mandatory_1_0 CHECK (reference_mandatory IN (1,0)),
	CONSTRAINT chk_realtime_meter_enbld_1_0 CHECK (realtime_metering_enabled IN (1,0))
);
ALTER TABLE csr.all_meter ADD (
	manual_data_entry			NUMBER(1) DEFAULT 1 NOT NULL,
	CONSTRAINT chk_manual_data_entry_1_0 CHECK (manual_data_entry IN (1,0))
);
ALTER TABLE csrimp.all_meter ADD (
	manual_data_entry			NUMBER(1) NOT NULL,
	CONSTRAINT chk_manual_data_entry_1_0 CHECK (manual_data_entry IN (1,0))
);
ALTER TABLE csr.meter_type ADD (
	req_approval				NUMBER(1) DEFAULT 0 NOT NULL,
	flow_sid					NUMBER(10),
	CONSTRAINT chk_req_approval_1_0 CHECK (req_approval IN (1,0)),
	CONSTRAINT fk_meter_type_flow FOREIGN KEY (app_sid, flow_sid)
		REFERENCES csr.flow (app_sid, flow_sid)
);
ALTER TABLE csrimp.meter_type ADD (
	req_approval				NUMBER(1) NOT NULL,
	flow_sid					NUMBER(10),
	CONSTRAINT chk_req_approval_1_0 CHECK (req_approval IN (1,0))
);
ALTER TABLE csrimp.meter_source_type DROP COLUMN period_set_id;
ALTER TABLE csrimp.meter_source_type DROP COLUMN period_interval_id;
ALTER TABLE csrimp.meter_source_type DROP COLUMN show_invoice_reminder;
ALTER TABLE csrimp.meter_source_type DROP COLUMN invoice_reminder;
ALTER TABLE csrimp.meter_source_type DROP COLUMN supplier_data_mandatory;
ALTER TABLE csrimp.meter_source_type DROP COLUMN region_date_clipping;
ALTER TABLE csrimp.meter_source_type DROP COLUMN reference_mandatory;
ALTER TABLE csrimp.meter_source_type DROP COLUMN realtime_metering;
ALTER TABLE csrimp.meter_source_type DROP COLUMN manual_data_entry;
ALTER TABLE csrimp.meter_source_type DROP COLUMN req_approval;
ALTER TABLE csrimp.meter_source_type DROP COLUMN flow_sid;
ALTER TABLE csrimp.meter_source_type DROP COLUMN auto_patch;
ALTER TABLE csrimp.customer DROP COLUMN fwd_estimate_meters;
BEGIN
	security.user_pkg.LogonAdmin;
	
	INSERT INTO csr.meter_data_source_hi_res_input (app_sid, raw_data_source_id, meter_input_id)
		SELECT mrds.app_sid, mrds.raw_data_source_id, mi.meter_input_id
		  FROM csr.meter_raw_data_source mrds
		  JOIN csr.meter_input mi on mrds.app_sid = mi.app_sid
		 WHERE EXISTS (
			SELECT *
			  FROM csr.meter_raw_data mrd
			 WHERE mrd.app_sid = mrds.app_sid
			   AND mrd.raw_data_source_id = mrds.raw_data_source_id
			   AND EXISTS (
				SELECT *
				  FROM csr.meter_live_data mld
				  JOIN csr.meter_bucket mb ON mld.app_sid = mb.app_sid AND mld.meter_bucket_id = mb.meter_bucket_id
				 WHERE mld.app_sid = mrd.app_sid
				   AND mld.meter_raw_data_id = mrd.meter_raw_data_id
				   AND mb.high_resolution_only = 1
			 )
		 );
END;
/
BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT mst.app_sid, MIN(period_set_id) period_set_id, MIN(period_interval_id) period_interval_id,
		       MAX(show_invoice_reminder) show_invoice_reminder, MAX(invoice_reminder) invoice_reminder,
			   MAX(supplier_data_mandatory) supplier_data_mandatory, MAX(region_date_clipping) region_date_clipping,
			   MAX(reference_mandatory) reference_mandatory, MAX(realtime_metering) realtime_metering_enabled,
			   MAX(fwd_estimate_meters) fwd_estimate_meters, MAX(flow_sid) flow_sid, MAX(req_approval) req_approval
		  FROM csr.meter_source_type mst
		  JOIN csr.customer c ON mst.app_sid = c.app_sid
		 GROUP BY mst.app_sid
	) LOOP
		BEGIN
			INSERT INTO csr.metering_options (app_sid, period_set_id, period_interval_id, show_invoice_reminder,
							invoice_reminder, supplier_data_mandatory, region_date_clipping, fwd_estimate_meters,
							reference_mandatory, realtime_metering_enabled)
			     VALUES (r.app_sid, r.period_set_id, r.period_interval_id, r.show_invoice_reminder, r.invoice_reminder,
				 		 r.supplier_data_mandatory, r.region_date_clipping, r.fwd_estimate_meters,
						 r.reference_mandatory, r.realtime_metering_enabled);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE csr.metering_options
				   SET period_set_id = r.period_set_id,
				       period_interval_id = r.period_interval_id,
					   show_invoice_reminder = r.show_invoice_reminder,
					   invoice_reminder = r.invoice_reminder,
					   supplier_data_mandatory = r.supplier_data_mandatory,
					   region_date_clipping = r.region_date_clipping,
					   fwd_estimate_meters = r.fwd_estimate_meters,
					   reference_mandatory = r.reference_mandatory,
					   realtime_metering_enabled = r.realtime_metering_enabled
				 WHERE app_sid = r.app_sid;
		END;
		
		-- flow sid is null for all live meter source types, so this is just here for dev envs
		-- (which is why its lazily doing max(flow_sid))
		UPDATE csr.meter_type
		   SET req_approval = r.req_approval,
		       flow_sid = r.flow_sid
		 WHERE app_sid = r.app_sid;
	END LOOP;
	
	UPDATE csr.metering_options
	   SET period_set_id = 1,
	       period_interval_id =1
	 WHERE period_set_id IS NULL
	    OR period_interval_id IS NULL;
		
	UPDATE csr.all_meter am
	   SET manual_data_entry = (
			SELECT manual_data_entry
			  FROM csr.meter_source_type mst
			 WHERE mst.app_sid = am.app_sid
			   AND mst.meter_source_type_id = am.meter_source_type_id
		);
		
	-- remove old amr meter source type where it is no longer used
	DELETE FROM csr.meter_source_type mst
	 WHERE name = 'amr'
	  AND NOT EXISTS (
		SELECT 1
		  FROM csr.all_meter am
		 WHERE am.app_sid = mst.app_sid
		   AND am.meter_source_type_id = mst.meter_source_type_id
	  );
	-- remove live/urjanet meter source types
	FOR r IN (
		SELECT mst.app_sid, mst.meter_source_type_id old_id, MIN(nmst.meter_source_type_id) new_id
		  FROM csr.meter_source_type mst
		  JOIN csr.meter_source_type nmst ON mst.app_sid = nmst.app_sid
		 WHERE mst.name IN ('live', 'urjanet')
		   AND nmst.name IN ('period', 'consumption')
		 GROUP BY mst.app_sid, mst.meter_source_type_id
	) LOOP
		UPDATE csr.all_meter
		   SET meter_source_type_id = r.new_id
		 WHERE app_sid = r.app_sid
		   AND meter_source_type_id = r.old_id;
		DELETE FROM csr.meter_source_type
		 WHERE app_sid = r.app_sid
		   AND meter_source_type_id = r.old_id;
	END LOOP;
END;
/
 
ALTER TABLE csr.metering_options MODIFY period_set_id NOT NULL;
ALTER TABLE csr.metering_options MODIFY period_interval_id NOT NULL;
ALTER TABLE csr.meter_source_type RENAME COLUMN period_set_id TO xxx_period_set_id;
ALTER TABLE csr.meter_source_type RENAME COLUMN period_interval_id TO xxx_period_interval_id;
ALTER TABLE csr.meter_source_type RENAME COLUMN show_invoice_reminder TO xxx_show_invoice_reminder;
ALTER TABLE csr.meter_source_type RENAME COLUMN invoice_reminder TO	xxx_invoice_reminder;
ALTER TABLE csr.meter_source_type RENAME COLUMN supplier_data_mandatory TO xxx_supplier_data_mandatory;
ALTER TABLE csr.meter_source_type RENAME COLUMN region_date_clipping TO xxx_region_date_clipping;
ALTER TABLE csr.meter_source_type RENAME COLUMN reference_mandatory TO xxx_reference_mandatory;
ALTER TABLE csr.meter_source_type RENAME COLUMN realtime_metering TO xxx_realtime_metering;
ALTER TABLE csr.meter_source_type RENAME COLUMN manual_data_entry TO xxx_manual_data_entry;
ALTER TABLE csr.meter_source_type RENAME COLUMN req_approval TO xxx_req_approval;
ALTER TABLE csr.meter_source_type RENAME COLUMN flow_sid TO xxx_flow_sid;
ALTER TABLE csr.meter_source_type RENAME COLUMN auto_patch TO xxx_auto_patch;
ALTER TABLE csr.meter_source_type MODIFY xxx_period_set_id NULL;
ALTER TABLE csr.meter_source_type MODIFY xxx_period_interval_id NULL;
ALTER TABLE csr.meter_source_type DROP CONSTRAINT FK_FLOW_MET_SRC_TYPE;
ALTER TABLE csr.meter_source_type DROP CONSTRAINT FK_PERIOD_SET_MTR_SRC_TYPE;
DROP INDEX csr.ix_flow_met_src_type;
DROP INDEX csr.ix_period_set_mtr_src_type;
create index csr.ix_metering_opti_period_set_id on csr.metering_options (app_sid, period_set_id, period_interval_id);
create index csr.ix_meter_data_so_meter_input_i on csr.meter_data_source_hi_res_input (app_sid, meter_input_id);
create index csr.ix_meter_type_flow_sid on csr.meter_type (app_sid, flow_sid);
ALTER TABLE csr.customer RENAME COLUMN fwd_estimate_meters TO xxx_fwd_estimate_meters;
BEGIN
	FOR r IN (
		SELECT column_name
		  FROM all_tab_columns
		 WHERE owner = 'CSR'
		   AND table_name = 'ALL_METER'
		   AND column_name LIKE 'XXX_%'
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE csr.all_meter DROP COLUMN '||r.column_name;
	END LOOP;
	FOR r IN (
		SELECT column_name
		  FROM all_tab_columns
		 WHERE owner = 'CSR'
		   AND table_name = 'METER_TYPE'
		   AND column_name LIKE 'XXX_%'
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE csr.meter_type DROP COLUMN '||r.column_name;
	END LOOP;
END;
/
ALTER TABLE chain.company_tab ADD (
	business_relationship_type_id		NUMBER(10, 0),
	CONSTRAINT fk_company_tab_bus_rel_type FOREIGN KEY (app_sid, business_relationship_type_id) REFERENCES chain.business_relationship_type (app_sid, business_relationship_type_id)
);
CREATE INDEX chain.ix_company_tab_bus_rel_type ON chain.company_tab (app_sid, business_relationship_type_id);
ALTER TABLE csrimp.chain_company_tab ADD (
	business_relationship_type_id		NUMBER(10, 0)
);
ALTER TABLE chain.business_relationship_type 
	ADD USE_SPECIFIC_DATES NUMBER(1,0) DEFAULT 1 NOT NULL
	ADD PERIOD_SET_ID NUMBER(10,0) DEFAULT NULL
	ADD PERIOD_INTERVAL_ID NUMBER(10,0) DEFAULT NULL;
ALTER TABLE chain.business_relationship_type
	ADD CONSTRAINT FK_BUS_REL_TYPE_PER_INTERVAL FOREIGN KEY (APP_SID, PERIOD_SET_ID, PERIOD_INTERVAL_ID)
	  REFERENCES CSR.PERIOD_INTERVAL (APP_SID, PERIOD_SET_ID, PERIOD_INTERVAL_ID);
ALTER TABLE chain.business_relationship_type
 ADD CONSTRAINT CHK_BRT_USE_SPECIFIC_DATES CHECK (USE_SPECIFIC_DATES IN (0,1)) ENABLE;
ALTER TABLE chain.business_relationship_type
 ADD CONSTRAINT CHK_BRT_PERIOD_IDS CHECK ((USE_SPECIFIC_DATES = 1 AND PERIOD_SET_ID IS NULL AND PERIOD_INTERVAL_ID IS NULL) OR (USE_SPECIFIC_DATES = 0 AND PERIOD_SET_ID IS NOT NULL AND PERIOD_INTERVAL_ID IS NOT NULL)) ENABLE;
                
CREATE INDEX CHAIN.IX_BUS_REL_TYPE_PER_INTERVAL ON CHAIN.BUSINESS_RELATIONSHIP_TYPE (APP_SID, PERIOD_SET_ID, PERIOD_INTERVAL_ID);
 
 


GRANT SELECT, INSERT, UPDATE ON csr.CUSTOM_FACTOR_HISTORY to CSRIMP;
GRANT SELECT, INSERT, UPDATE, DELETE ON CSRIMP.CUSTOM_FACTOR_HISTORY TO TOOL_USER;
GRANT SELECT ON csr.custom_factor_history_seq TO CSRIMP;
GRANT SELECT, INSERT, UPDATE ON csr.duff_meter_region TO csrimp;
grant select,insert,update on csr.meter_data_source_hi_res_input to csrimp;
grant select, insert, update, delete on csrimp.meter_data_source_hi_res_input to tool_user;
begin
	dbms_java.grant_permission( 'CSR', 'SYS:java.net.SocketPermission', 'localhost:1024-', 'listen,resolve');
end;
/




CREATE OR REPLACE VIEW csr.v$audit AS
	SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label,
		   NVL2(ia.internal_audit_ref, atg.internal_audit_ref_prefix || ia.internal_audit_ref, null) custom_audit_id,
		   atg.internal_audit_ref_prefix, ia.internal_audit_ref, ia.ovw_validity_dtm,
		   ia.auditor_user_sid, NVL(cu.full_name, au.full_name) auditor_full_name, sr.submitted_dtm survey_completed,
		   NVL(nc.cnt, 0) open_non_compliances, ia.survey_sid, ia.auditor_name, ia.auditor_organisation,
		   r.region_type, r.geo_longitude longitude, r.geo_latitude latitude, rt.class_name region_type_class_name,
		   ia.auditee_user_sid, u.full_name auditee_full_name, u.email auditee_email,
		   SUBSTR(ia.notes, 1, 50) short_notes, ia.notes full_notes,
		   iat.internal_audit_type_id audit_type_id, iat.label audit_type_label, iat.internal_audit_type_source_id audit_type_source_id,
		   qs.label survey_label, ia.app_sid, ia.internal_audit_type_id, iat.auditor_role_sid,
		   iat.audit_contact_role_sid, ia.audit_closure_type_id, act.label closure_label, act.icon_image_filename, cast(act.icon_image_sha1  as varchar2(40)) icon_image_sha1,
		   ia.created_by_user_sid, ia.survey_response_id, ia.created_dtm, NVL(cu.email, au.email) auditor_email,
		   iat.assign_issues_to_role, iat.add_nc_per_question, cvru.user_giving_cover_sid cover_auditor_sid,
		   fi.flow_sid, f.label flow_label, ia.flow_item_id, fi.current_state_id, fs.label flow_state_label, fs.is_final flow_state_is_final, 
		   fs.state_colour flow_state_colour, act.is_failure,
		   sqs.survey_sid summary_survey_sid, sqs.label summary_survey_label, ssr.survey_version summary_survey_version, ia.summary_response_id,
		   ia.auditor_company_sid, ac.name auditor_company_name, iat.tab_sid, iat.form_path, ia.comparison_response_id, iat.nc_audit_child_region,
		   atg.label ia_type_group_label, atg.lookup_key ia_type_group_lookup_key, atg.internal_audit_type_group_id, iat.form_sid,
		   atg.audit_singular_label, atg.audit_plural_label, atg.auditee_user_label, atg.auditor_user_label, atg.auditor_name_label,
		   sr.overall_score survey_overall_score, sr.overall_max_score survey_overall_max_score, sr.survey_version,
		   sst.score_type_id survey_score_type_id, sr.score_threshold_id survey_score_thrsh_id, sst.label survey_score_label, sst.format_mask survey_score_format_mask,
		   ia.nc_score, iat.nc_score_type_id, NVL(ia.ovw_nc_score_thrsh_id, ia.nc_score_thrsh_id) nc_score_thrsh_id, ncst.max_score nc_max_score, ncst.label nc_score_label,
		   ncst.format_mask nc_score_format_mask,
		   CASE (atct.re_audit_due_after_type)
				WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
				WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
				WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
				WHEN 'y' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after*12))
				ELSE ia.ovw_validity_dtm END next_audit_due_dtm
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
	  LEFT JOIN csr.csr_user u ON ia.auditee_user_sid = u.csr_user_sid AND ia.app_sid = u.app_sid
	  JOIN csr.csr_user au ON ia.auditor_user_sid = au.csr_user_sid AND ia.app_sid = au.app_sid
	  LEFT JOIN csr.csr_user cu ON cvru.user_giving_cover_sid = cu.csr_user_sid AND cvru.app_sid = cu.app_sid
	  LEFT JOIN csr.internal_audit_type iat ON ia.app_sid = iat.app_sid AND ia.internal_audit_type_id = iat.internal_audit_type_id
	  LEFT JOIN csr.internal_audit_type_group atg ON atg.app_sid = iat.app_sid AND atg.internal_audit_type_group_id = iat.internal_audit_type_group_id
	  LEFT JOIN csr.v$quick_survey_response sr ON ia.survey_response_id = sr.survey_response_id AND ia.app_sid = sr.app_sid
	  LEFT JOIN csr.v$quick_survey_response ssr ON ia.summary_response_id = ssr.survey_response_id AND ia.app_sid = ssr.app_sid
	  LEFT JOIN csr.v$quick_survey qs ON ia.survey_sid = qs.survey_sid AND ia.app_sid = qs.app_sid
	  LEFT JOIN csr.v$quick_survey sqs ON NVL(ssr.survey_sid, iat.summary_survey_sid) = sqs.survey_sid AND iat.app_sid = sqs.app_sid
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
	  LEFT JOIN csr.v$region r ON ia.app_sid = r.app_sid AND ia.region_sid = r.region_sid
	  LEFT JOIN csr.region_type rt ON r.region_type = rt.region_type
	  LEFT JOIN csr.audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id AND ia.app_sid = act.app_sid
	  LEFT JOIN csr.audit_type_closure_type atct ON ia.audit_closure_type_id = atct.audit_closure_type_id AND ia.internal_audit_type_id = atct.internal_audit_type_id AND ia.app_sid = atct.app_sid
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
INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name)
VALUES (54, 'Eat RAM', 'eat-ram');
CREATE OR REPLACE VIEW CSR.V$METER_ORPHAN_DATA_SUMMARY AS
	SELECT od.app_sid, od.serial_id, od.meter_input_id, od.priority, ds.source_email, ds.source_folder,
		MIN(rd.received_dtm) created_dtm, MAX(rd.received_dtm) updated_dtm, 
		MIN(od.start_dtm) start_dtm, NVL(MAX(od.end_dtm), MAX(od.start_dtm)) end_dtm, 
		SUM(od.consumption) consumption,
		MAX(od.has_overlap) has_overlap,
		MAX(od.region_sid) region_sid,
		MAX(od.error_type_id) KEEP (DENSE_RANK LAST ORDER BY rd.received_dtm) error_type_id
	  FROM meter_orphan_data od
	  JOIN meter_raw_data rd ON rd.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND rd.meter_raw_data_id = od.meter_raw_data_id
	  JOIN meter_raw_data_source ds ON ds.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND ds.raw_data_source_id = rd.raw_data_source_id
	 WHERE od.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	 GROUP BY od.app_sid, od.serial_id, od.meter_input_id, od.priority, ds.source_email, ds.source_folder
;
CREATE OR REPLACE VIEW CSR.V$LEGACY_METER AS
	SELECT
		am.app_sid,
		am.region_sid,
		am.note,
		iip.ind_sid primary_ind_sid,
		iai.measure_conversion_id primary_measure_conversion_id,
		am.active,
		am.meter_source_type_id,
		am.reference,
		am.crc_meter,
		ciip.ind_sid cost_ind_sid,
		ciai.measure_conversion_id cost_measure_conversion_id,
		am.export_live_data_after_dtm,
		mi.days_ind_sid,
		am.days_measure_conversion_id,
		mi.costdays_ind_sid,
		am.costdays_measure_conversion_id,
		am.approved_by_sid,
		am.approved_dtm,
		am.is_core,
		am.meter_type_id,
		am.lower_threshold_percentage,
		am.upper_threshold_percentage,
		am.metering_version,
		am.urjanet_meter_id,
		am.manual_data_entry
	 FROM all_meter am
	 JOIN meter_type mi ON mi.app_sid = am.app_sid AND mi.meter_type_id = am.meter_type_id
	 -- Consumption mandatory
	 JOIN csr.meter_input ip ON ip.app_sid = am.app_sid AND ip.lookup_key = 'CONSUMPTION'
	 JOIN csr.v$legacy_aggregator iag ON iag.app_sid = ip.app_sid AND iag.meter_input_id = ip.meter_input_id
	 JOIN csr.meter_type_input iip ON iip.app_sid = am.app_sid AND iip.meter_type_id = am.meter_type_id AND iip.meter_input_id = iag.meter_input_id
	 JOIN meter_input_aggr_ind iai ON iai.app_sid = am.app_sid AND iai.region_sid = am.region_sid AND iai.meter_input_id = ip.meter_input_id
	 -- Cost optional
	 LEFT JOIN csr.meter_input cip ON cip.app_sid = am.app_sid AND cip.lookup_key = 'COST'
	 LEFT JOIN csr.v$legacy_aggregator ciag ON ciag.app_sid = cip.app_sid AND ciag.meter_input_id = cip.meter_input_id
	 LEFT JOIN csr.meter_type_input ciip ON ciip.app_sid = am.app_sid AND ciip.meter_type_id = am.meter_type_id AND ciip.meter_input_id = cip.meter_input_id
	 LEFT JOIN meter_input_aggr_ind ciai ON ciai.app_sid = am.app_sid AND ciai.region_sid = am.region_sid AND ciai.meter_input_id = cip.meter_input_id
;
CREATE OR REPLACE VIEW csr.v$property_meter AS
	SELECT a.app_sid, a.region_sid, a.reference, r.description, r.parent_sid, a.note,
		NVL(mi.label, pi.description) group_label, mi.group_key,
		a.primary_ind_sid, pi.description primary_description,
		NVL(pmc.description, pm.description) primary_measure, pm.measure_sid primary_measure_sid, a.primary_measure_conversion_id,
		a.cost_ind_sid, ci.description cost_description, NVL(cmc.description, cm.description) cost_measure, a.cost_measure_conversion_id,
		ms.meter_source_type_id, ms.name source_type_name, ms.description source_type_description,
		a.manual_data_entry, ms.arbitrary_period, ms.add_invoice_data,
		ms.show_in_meter_list, ms.descending, ms.allow_reset, a.meter_type_id, r.active, r.region_type,
		r.acquisition_dtm, r.disposal_dtm
	  FROM csr.v$legacy_meter a
		JOIN meter_source_type ms ON a.meter_source_type_id = ms.meter_source_type_id AND a.app_sid = ms.app_sid
		JOIN v$region r ON a.region_sid = r.region_sid AND a.app_sid = r.app_sid
		LEFT JOIN meter_type mi ON a.meter_type_id = mi.meter_type_id
		LEFT JOIN v$ind pi ON a.primary_ind_sid = pi.ind_sid AND a.app_sid = pi.app_sid
		LEFT JOIN measure pm ON pi.measure_sid = pm.measure_sid AND pi.app_sid = pm.app_sid
		LEFT JOIN measure_conversion pmc ON a.primary_measure_conversion_id = pmc.measure_conversion_id AND a.app_sid = pmc.app_sid
		LEFT JOIN v$ind ci ON a.cost_ind_sid = ci.ind_sid AND a.app_sid = ci.app_sid
		LEFT JOIN measure cm ON ci.measure_sid = cm.measure_sid AND ci.app_sid = cm.app_sid
		LEFT JOIN measure_conversion cmc ON a.cost_measure_conversion_id = cmc.measure_conversion_id AND a.app_sid = cmc.app_sid;
CREATE OR REPLACE VIEW csr.v$property_meter AS
	SELECT a.app_sid, a.region_sid, a.reference, r.description, r.parent_sid, a.note,
		NVL(mi.label, pi.description) group_label, mi.group_key,
		a.primary_ind_sid, pi.description primary_description,
		NVL(pmc.description, pm.description) primary_measure, pm.measure_sid primary_measure_sid, a.primary_measure_conversion_id,
		a.cost_ind_sid, ci.description cost_description, NVL(cmc.description, cm.description) cost_measure, a.cost_measure_conversion_id,
		ms.meter_source_type_id, ms.name source_type_name, ms.description source_type_description,
		a.manual_data_entry, ms.arbitrary_period, ms.add_invoice_data,
		ms.show_in_meter_list, ms.descending, ms.allow_reset, a.meter_type_id, r.active, r.region_type,
		r.acquisition_dtm, r.disposal_dtm
	  FROM csr.v$legacy_meter a
		JOIN meter_source_type ms ON a.meter_source_type_id = ms.meter_source_type_id AND a.app_sid = ms.app_sid
		JOIN v$region r ON a.region_sid = r.region_sid AND a.app_sid = r.app_sid
		LEFT JOIN meter_type mi ON a.meter_type_id = mi.meter_type_id
		LEFT JOIN v$ind pi ON a.primary_ind_sid = pi.ind_sid AND a.app_sid = pi.app_sid
		LEFT JOIN measure pm ON pi.measure_sid = pm.measure_sid AND pi.app_sid = pm.app_sid
		LEFT JOIN measure_conversion pmc ON a.primary_measure_conversion_id = pmc.measure_conversion_id AND a.app_sid = pmc.app_sid
		LEFT JOIN v$ind ci ON a.cost_ind_sid = ci.ind_sid AND a.app_sid = ci.app_sid
		LEFT JOIN measure cm ON ci.measure_sid = cm.measure_sid AND ci.app_sid = cm.app_sid
		LEFT JOIN measure_conversion cmc ON a.cost_measure_conversion_id = cmc.measure_conversion_id AND a.app_sid = cmc.app_sid;
		
CREATE OR REPLACE VIEW csr.v$temp_meter_reading_rows AS
       SELECT t.source_row, t.region_sid, t.start_dtm, t.end_dtm, t.reference, t.note, t.reset_val, t.error_msg,
              t.priority, v.consumption consumption, c.consumption cost
	    FROM ( SELECT DISTINCT source_row,
			    region_sid,
			    start_dtm,
			    end_dtm,
			    REFERENCE,
			    priority,
			    note,
			    reset_val,
			    error_msg
    			FROM csr.temp_meter_reading_rows
			  ) t
	LEFT JOIN csr.temp_meter_reading_rows v
		   ON v.source_row       = t.source_row
		  AND t.region_sid      =v.region_sid
		  AND v.meter_input_id IN (SELECT meter_input_id
									FROM csr.meter_input
									WHERE app_sid  = SYS_CONTEXT('SECURITY', 'APP')
									AND lookup_key = 'CONSUMPTION'
								  )
	LEFT JOIN csr.temp_meter_reading_rows c
		   ON c.source_row       = t.source_row
		  AND t.region_sid      =c.region_sid
		  AND c.meter_input_id IN (SELECT meter_input_id
									FROM csr.meter_input
									WHERE app_sid  = SYS_CONTEXT('SECURITY', 'APP')
									AND lookup_key = 'COST'
								  );




INSERT INTO csr.INTERNAL_AUDIT_TYPE_SOURCE (INTERNAL_AUDIT_TYPE_SOURCE_ID, INTERNAL_AUDIT_TYPE_SOURCE)
	 VALUES (1, 'Internal');
INSERT INTO csr.INTERNAL_AUDIT_TYPE_SOURCE (INTERNAL_AUDIT_TYPE_SOURCE_ID, INTERNAL_AUDIT_TYPE_SOURCE)
	 VALUES (2, 'External');
INSERT INTO csr.INTERNAL_AUDIT_TYPE_SOURCE (INTERNAL_AUDIT_TYPE_SOURCE_ID, INTERNAL_AUDIT_TYPE_SOURCE)
	 VALUES (3, 'Integration');
BEGIN
	FOR r IN (
		SELECT internal_audit_type_id, interactive, hc.audit_type_id, bo09.audit_type_2009_id, bo14.audit_type_2014_id
		  FROM csr.internal_audit_type iat
	 LEFT JOIN chain.higg_config hc ON iat.internal_audit_type_id = hc.audit_type_id AND hc.app_sid = iat.app_sid
	 LEFT JOIN chain.bsci_options bo09 ON iat.internal_audit_type_id = bo09.audit_type_2009_id AND bo09.app_sid = iat.app_sid
	 LEFT JOIN chain.bsci_options bo14 ON iat.internal_audit_type_id = bo14.audit_type_2014_id AND bo14.app_sid = iat.app_sid
	) LOOP
		security.user_pkg.logonadmin('');
		IF r.interactive = 1 AND r.audit_type_id IS NULL AND r.audit_type_2009_id IS NULL AND r.audit_type_2014_id IS NULL THEN
			UPDATE csr.internal_audit_type
			   SET internal_audit_type_source_id = 1
			 WHERE internal_audit_type_id = r.internal_audit_type_id;
		ELSIF r.interactive = 0 AND r.audit_type_id IS NULL AND r.audit_type_2009_id IS NULL AND r.audit_type_2014_id IS NULL THEN
			UPDATE csr.internal_audit_type
			   SET internal_audit_type_source_id = 2
			 WHERE internal_audit_type_id = r.internal_audit_type_id;
		ELSIF r.audit_type_id IS NOT NULL OR r.audit_type_2009_id IS NOT NULL OR r.audit_type_2014_id IS NOT NULL THEN
			UPDATE csr.internal_audit_type
			   SET internal_audit_type_source_id = 3
			 WHERE internal_audit_type_id = r.internal_audit_type_id;
		END IF;
	END LOOP;
END;
/
ALTER TABLE csr.INTERNAL_AUDIT_TYPE MODIFY INTERNAL_AUDIT_TYPE_SOURCE_ID NOT NULL;
ALTER TABLE csr.INTERNAL_AUDIT_TYPE DROP CONSTRAINT CHK_IAT_INTERACTIVE_1_0;
ALTER TABLE csr.INTERNAL_AUDIT_TYPE DROP COLUMN interactive;
ALTER TABLE csrimp.INTERNAL_AUDIT_TYPE DROP CONSTRAINT CHK_IAT_INTERACTIVE_1_0;
ALTER TABLE csrimp.INTERNAL_AUDIT_TYPE DROP COLUMN interactive;
BEGIN
	security.user_pkg.LogonAdmin;
	FOR r IN (
		SELECT app_sid
		  FROM csr.customer
		 WHERE property_flow_sid IS NOT NULL
		   AND app_sid NOT IN (SELECT app_sid
		                         FROM csr.issue_type
		                        WHERE issue_type_id = 15)
	) LOOP
		INSERT INTO csr.issue_type(app_sid, issue_type_id, label)
			 VALUES (r.app_sid, 15, 'Property');
	END LOOP;
END;
/
BEGIN
	security.user_pkg.LogonAdmin;
	
	-- some dev sites seemed to have missed these
	BEGIN
		INSERT INTO csr.meter_raw_data_source_type (raw_data_source_type_id, feed_type, description) VALUES(1, 'email', 'Email');		
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO csr.meter_raw_data_source_type (raw_data_source_type_id, feed_type, description) VALUES(2, 'ftp', 'FTP');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	UPDATE csr.auto_imp_importer_plugin
	   SET label='Meter raw data importer', importer_assembly= 'Credit360.ExportImport.Automated.Import.Importers.MeterRawDataImporter.MeterRawDataImporter'
	 WHERE plugin_id = 2;
	UPDATE csr.meter_raw_data_source
	   SET raw_data_source_type_id = 2
	 WHERE raw_data_source_type_id = 3;
	DELETE FROM csr.meter_raw_data_source_type WHERE raw_data_source_type_id = 3;
END;
/
BEGIN
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp)
	VALUES (55, 'Meter and meter data matching', null, 'meter-match', 0, null);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp)
	VALUES (56, 'Meter raw data import', null, 'meter-raw-data-import', 0, null);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp)
	VALUES (57, 'Meter recompute buckets', 'csr.meter_monitor_pkg.ProcessRecomputeBucketsJob', null, 0, null);
END;
/
BEGIN
	INSERT INTO CSR.AUTOMATED_IMPORT_FILE_TYPE (AUTOMATED_IMPORT_FILE_TYPE_ID, LABEL)
		VALUES (3, 'ediel');
	INSERT INTO CSR.AUTOMATED_IMPORT_FILE_TYPE (AUTOMATED_IMPORT_FILE_TYPE_ID, LABEL)
		VALUES (4, 'wi5');
END;
/
BEGIN
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (1 /*DUFF_METER_GENERIC*/, 'Orphan meter data');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (2 /*DUFF_METER_MATCH_SERIAL*/, 'Failed to match meter number');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (3 /*DUFF_METER_MATCH_UOM*/, 'Failed to match UOM');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (4 /*DUFF_METER_OVERLAP*/, 'Data has overlaps');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (5 /*DUFF_METER_EXISTING_MISMATCH*/, 'Meter number mismatch');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (6 /*DUFF_METER_PARENT_NOT_FOUND*/, 'Parent region not found');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (7 /*DUFF_METER_HOLDING_NOT_FOUND*/, 'Holding region not found');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (8 /*DUFF_METER_SVC_TYPE_NOT_FOUND*/, 'Service type not found');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (9 /*DUFF_METER_SVC_TYPE_MISMATCH*/, 'Service type mismatch');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (10 /*DUFF_METER_NOT_SET_UP*/, 'System not configured');
	UPDATE csr.meter_orphan_data
	   SET error_type_id = 1 /*DUFF_METER_GENERIC*/
	;
END;
/
ALTER TABLE CSR.METER_ORPHAN_DATA MODIFY (
	ERROR_TYPE_ID					NUMBER(10) 		NOT NULL
);
BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
	job_name		=> 'csr.MeterRawDataJob',
	job_type		=> 'PLSQL_BLOCK',
	job_action		=> 'BEGIN security.user_pkg.logonadmin(); csr.meter_monitor_pkg.CreateRawDataJobsForApps; commit; END;',
	job_class		=> 'low_priority_job',
	start_date		=> to_timestamp_tz('2016/10/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
	repeat_interval	=> 'FREQ=DAILY',
	enabled			=> TRUE,
	auto_drop		=> FALSE,
	comments		=> 'Schedule creating meter raw data jobs');
END;
/
BEGIN
	DBMS_SCHEDULER.CREATE_JOB (
		job_name		=> 'csr.MeterMatchJob',
		job_type		=> 'PLSQL_BLOCK',
		job_action		=> 'BEGIN security.user_pkg.logonadmin(); csr.meter_monitor_pkg.CreateMatchJobsForApps; commit; END;',
		job_class		=> 'low_priority_job',
		start_date		=> to_timestamp_tz('2016/10/01 03:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		repeat_interval	=> 'FREQ=DAILY',
		enabled			=> TRUE,
		auto_drop		=> FALSE,
		comments		=> 'Schedule creating meter match jobs'
	);
END;
/
DECLARE
	v_mapping_xml		VARCHAR2(3000);
BEGIN
	FOR x IN (
		SELECT aics.app_sid, aics.automated_import_class_sid, aics.step_number, mrds.raw_data_source_id,
			   mrds.source_folder, mec.worksheet_index, mec.row_index
		  FROM csr.automated_import_class_step aics
		  JOIN csr.meter_raw_data_source mrds ON aics.automated_import_class_sid = mrds.automated_import_class_sid AND aics.app_sid = mrds.app_sid
		  JOIN csr.meter_excel_option mec ON mec.raw_data_source_id = mrds.raw_data_source_id AND mec.app_sid = mrds.app_sid
		 WHERE plugin='Credit360.ExportImport.Automated.Import.Plugins.UrjanetImporterStepPlugin')
	LOOP
		UPDATE csr.automated_import_class_step
		   SET plugin = 'Credit360.ExportImport.Automated.Import.Plugins.MeterRawDataImportStepPlugin',
			   on_completion_sp = 'csr.meter_monitor_pkg.QueueRawDataImportJob'
		 WHERE automated_import_class_sid = x.automated_import_class_sid
		   AND step_number = x.step_number
		   AND app_sid = x.app_sid;
		UPDATE csr.meter_raw_data_source
		   SET create_meters = 1
		 WHERE app_sid = x.app_sid
		   AND raw_data_source_id = x.raw_data_source_id;
		IF x.source_folder LIKE '%yum%' THEN
			v_mapping_xml := '<columnMappings>
				<column name="METERID" column-type="urjanet-meter-id" />
				<column name="STOREID" column-type="region-ref"/>
				<column name="FROM_DATE" format="yyyy-MM-dd" column-type="start-date"/>
				<column name="TO_DATE" format="yyyy-MM-dd" column-type="end-date"/>
				<column name="USAGE" column-type="meter-input" format="CONSUMPTION" />
				<column name="UNIT_OF_MEASURE" column-type="meter-input-unit" format="CONSUMPTION" />
				<column name="MERCHANDISE_AMT" column-type="meter-input" format="COST" />
				<column name="TYPE" column-type="service-type"/>
				<column name="Name" format="{type} - {meterid}" column-type="name"/>
				</columnMappings>	';
		ELSE
			v_mapping_xml := '<columnMappings>
				<column name="LogicalMeterId" column-type="urjanet-meter-id" mandatory="yes"/>
				<column name="StartDate" format="MM/dd/yyyy" column-type="start-date"/>
				<column name="EndDate" format="MM/dd/yyyy" column-type="end-date"/>
				<column name="ConsumptionUnit" column-type="meter-input-unit" format="CONSUMPTION" filter-type="exclude" filter="kW"/>
				<column name="Consumption" column-type="meter-input" format="CONSUMPTION" />
				<column name="Cost" column-type="meter-input" format="COST" />
				<column name="Currency" column-type="meter-input-unit" format="COST" />
				<column name="ConsumptionReadType" column-type="is-estimate" />
				<column name="ServiceAddress"/>
				<column name="SiteCode" column-type="region-ref" mandatory="yes"/>
				<column name="ServiceType" column-type="service-type" filter-type="exclude" filter="sanitation" mandatory="yes" />
				<column name="MeterNumber" column-type="meter-number" mandatory="yes"/>
				<column name="Name" format="{MeterNumber} {ServiceAddress} {ServiceType}" column-type="name" />
				<column name="Url"/>
			 </columnMappings>	';
		END IF;
		UPDATE csr.auto_imp_importer_settings
		   SET mapping_xml = XMLTYPE(v_mapping_xml),
			   excel_worksheet_index = x.worksheet_index,
			   excel_row_index = x.row_index
		 WHERE app_sid = x.app_sid
		   AND automated_import_class_sid = x.automated_import_class_sid;
		DELETE FROM csr.meter_excel_mapping WHERE raw_data_source_id = x.raw_data_source_id AND app_sid = x.app_sid;
		DELETE FROM csr.meter_excel_option WHERE raw_data_source_id = x.raw_data_source_id AND app_sid = x.app_sid;
	END LOOP;
END;
/
BEGIN
	security.user_pkg.LogonAdmin;
	
	-- move auto patch down a level and put new estimate level in between
	FOR r IN (
		SELECT app_sid
		  FROM csr.meter_data_priority
		 WHERE priority = 1
		   AND lookup_key = 'AUTO'
	) LOOP
		BEGIN
			INSERT INTO csr.meter_data_priority (app_sid, priority, label, lookup_key, is_input, is_output, is_patch, is_auto_patch)
			VALUES (r.app_sid, 0, 'Auto patch', 'AUTO', 0, 0, 1, 1);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
		
		-- commented out for live run as it takes 30 seconds and doesn't update any rows
		-- the only systems with auto patch setup with be Dickie's laptop
		-- DICKIE - RUN THIS!
		--UPDATE csr.meter_reading_data
		--   SET priority = 0
		-- WHERE app_sid = r.app_sid
		--   AND priority = 1;
		--UPDATE csr.meter_source_data
		--   SET priority = 0
		-- WHERE app_sid = r.app_sid
		--   AND priority = 1;
		   
		UPDATE csr.meter_data_priority
		   SET label = 'Estimate',
		       lookup_key = 'ESTIMATE',
			   is_input = 1,
			   is_output = 0,
			   is_patch = 0,
			   is_auto_patch = 0
		 WHERE app_sid = r.app_sid
		   AND priority = 1;		   
	END LOOP;
	 
	-- move urjanet low res readings into the estimate level
	FOR r IN (
		SELECT app_sid
		  FROM csr.automated_import_class
		 WHERE lookup_key = 'URJANET_IMPORTER'
	) LOOP
		UPDATE csr.meter_source_data
		   SET priority = 1
		 WHERE app_sid = r.app_sid
		   AND priority = 2;
	END LOOP;
END;
/
BEGIN
	security.user_pkg.LogonAdmin;
	UPDATE security.menu
	   SET action = '/csr/site/meter/monitor/OrphanMeterRegions.acds'
	 WHERE LOWER(action) = '/csr/site/meter/monitor/orphandatalist.acds';
END;
/
insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
values (csr.plugin_id_seq.nextval, 10, 'Business Relationship Graph', '/csr/site/chain/manageCompany/controls/BusinessRelationshipGraph.js', 'Chain.ManageCompany.BusinessRelationshipGraph', 'Credit360.Chain.Plugins.BusinessRelationshipGraphDto', 'This tab shows a graph of business relationships for a company.');


@../section_pkg
@../section_body
@..\batch_trigger


CREATE OR REPLACE PACKAGE csr.meter_duff_region_pkg
IS
END;
/
	
GRANT EXECUTE ON csr.meter_duff_region_pkg to web_user;


@..\..\..\aspen2\cms\db\filter_pkg
@..\chain\business_relationship_pkg
@..\chain\company_pkg
@..\audit_pkg
@..\batch_job_pkg
@..\forecasting_pkg
@..\chain\chain_pkg
@..\chain\company_dedupe_pkg
@..\automated_import_pkg
@..\csr_data_pkg
@..\factor_pkg
@..\schema_pkg
@..\..\..\aspen2\cms\db\filter_pkg.sql
@..\meter_pkg
@..\meter_monitor_pkg
@..\meter_duff_region_pkg
@..\meter_patch_pkg
@..\space_pkg
@..\chain\plugin_pkg


@..\..\..\aspen2\cms\db\filter_body
@..\audit_report_body
@..\non_compliance_report_body
@..\issue_report_body
@..\portlet_body
@..\factor_body
@..\section_body
@..\chain\company_body
@..\chain\business_relationship_body
@..\schema_body
@..\csrimp\imp_body
@..\quick_survey_body
@..\audit_body
@..\enable_body
@..\batch_job_body
@..\auto_approve_body
@..\csr_app_body
@..\forecasting_body
@..\scenario_body
@..\scenario_run_body
@..\actions\scenario_body
@..\chain\chain_body
@..\chain\company_dedupe_body
@..\chain\test_chain_utils_body
@..\meter_body
@..\approval_dashboard_body
@..\automated_import_body
@..\..\..\aspen2\cms\db\filter_body.sql
@..\energy_star_body
@..\meter_monitor_body
@..\meter_duff_region_body
@..\meter_patch_body
@..\property_body
@..\space_body
@..\util_script_body
@..\chain\company_filter_body
@..\chain\plugin_body



@update_tail
