define version=2937
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

DECLARE
	v_count	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_sequences
	 WHERE sequence_owner = 'CSR'
	   AND sequence_name = 'INITIATIVE_METRIC_ID_SEQ';
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'CREATE SEQUENCE CSR.INITIATIVE_METRIC_ID_SEQ
								START WITH 1
								INCREMENT BY 1
								NOMINVALUE
								NOMAXVALUE
								CACHE 20
								NOORDER';
	END IF;
END;
/
DECLARE
	v_count	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_sequences
	 WHERE sequence_owner = 'CSR'
	   AND sequence_name = 'INITIATIVE_METRID_ID_SEQ';
	IF v_count = 1 THEN
		EXECUTE IMMEDIATE 'DROP SEQUENCE CSR.INITIATIVE_METRID_ID_SEQ';
	END IF;
END;
/
DECLARE
	v_count	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_sequences
	 WHERE sequence_owner = 'CSR'
	   AND sequence_name = 'AGGR_TAG_GROUP_ID_SEQ';
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'CREATE SEQUENCE CSR.AGGR_TAG_GROUP_ID_SEQ
								START WITH 1
								INCREMENT BY 1
								NOMINVALUE
								NOMAXVALUE
								CACHE 20
								NOORDER';
	END IF;
END;
/
	
--Failed to locate all sections of latest2935_24.sql
CREATE TABLE csr.est_error_description
(
	error_no						NUMBER(10,0),
	url_pattern						VARCHAR2(1024),
	msg_pattern						VARCHAR2(1024),
	help_text						VARCHAR2(4000),
	applies_to_space				NUMBER(1,0),
	applies_to_meter				NUMBER(1,0),
	applies_to_push					NUMBER(1,0),
	CONSTRAINT ck_eed_applies_to_space CHECK (applies_to_space IN (0,1)),
	CONSTRAINT ck_eed_applies_to_meter CHECK (applies_to_meter IN (0,1)),
	CONSTRAINT ck_eed_applies_to_push CHECK (applies_to_push IN (0,1))
);
CREATE TABLE CSR.EST_ERROR_2 AS
SELECT * 
  FROM csr.est_error
 WHERE active = 1
    OR ADD_MONTHS(error_dtm, 1) >= SYSDATE;
CREATE SEQUENCE CSR.METER_RAW_DATA_LOG_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;
CREATE TABLE CSR.METER_RAW_DATA_LOG(
    APP_SID              NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    METER_RAW_DATA_ID    NUMBER(10, 0)     NOT NULL,
    LOG_ID               NUMBER(10, 0)     NOT NULL,
    USER_SID             NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL,
    LOG_TEXT             VARCHAR2(4000)    NOT NULL,
    LOG_DTM              DATE              DEFAULT SYSDATE NOT NULL,
    MIME_TYPE            VARCHAR2(256),
    FILE_NAME            VARCHAR2(1024),
    DATA                 BLOB,
    CONSTRAINT PK_METER_RAW_DATA_LOG PRIMARY KEY (APP_SID, METER_RAW_DATA_ID, LOG_ID)
);
CREATE TABLE CSRIMP.METER_RAW_DATA_LOG(
    CSRIMP_SESSION_ID    NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    METER_RAW_DATA_ID    NUMBER(10, 0)     NOT NULL,
    LOG_ID               NUMBER(10, 0)     NOT NULL,
    USER_SID             NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL,
    LOG_TEXT             VARCHAR2(4000)    NOT NULL,
    LOG_DTM              DATE              DEFAULT SYSDATE NOT NULL,
    MIME_TYPE            VARCHAR2(256),
    FILE_NAME            VARCHAR2(1024),
    DATA                 BLOB,
    CONSTRAINT PK_METER_RAW_DATA_LOG PRIMARY KEY (CSRIMP_SESSION_ID, METER_RAW_DATA_ID, LOG_ID),
    CONSTRAINT FK_METER_RAW_DATA_LOG FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
CREATE TABLE csr.dataview_arbitrary_period (
	APP_SID				NUMBER(10)			DEFAULT sys_context('security','app') NOT NULL,
	DATAVIEW_SID		NUMBER(10)			NOT NULL,
	START_DTM			DATE				NOT NULL,
	END_DTM				DATE,
	CONSTRAINT PK_DATAVIEW_ARB_PERIOD PRIMARY KEY (APP_SID, DATAVIEW_SID, START_DTM),
	CONSTRAINT FK_DATAVIEW_FROM_DATAVIEW_AP	FOREIGN KEY (APP_SID, DATAVIEW_SID) REFERENCES csr.dataview (APP_SID, DATAVIEW_SID)
);
CREATE TABLE csr.dataview_arbitrary_period_hist (
	APP_SID				NUMBER(10)			DEFAULT sys_context('security','app') NOT NULL,
	DATAVIEW_SID		NUMBER(10)			NOT NULL,
	VERSION_NUM         NUMBER(10)			NOT NULL,
	START_DTM			DATE				NOT NULL,
	END_DTM				DATE,
	CONSTRAINT PK_DATAVIEW_HIST_ARB_PERIOD PRIMARY KEY (APP_SID, DATAVIEW_SID, VERSION_NUM, START_DTM),
	CONSTRAINT FK_DATAVIEW_FROM_DATAVIEW_APH	FOREIGN KEY (APP_SID, DATAVIEW_SID) REFERENCES csr.dataview (APP_SID, DATAVIEW_SID)
);
CREATE TABLE CSRIMP.DATAVIEW_ARBITRARY_PERIOD (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DATAVIEW_SID		NUMBER(10),
	START_DTM			DATE,
	END_DTM				DATE,
	CONSTRAINT PK_DATAVIEW_ARB_PERIOD PRIMARY KEY (CSRIMP_SESSION_ID, DATAVIEW_SID, START_DTM),
    CONSTRAINT FK_DATAVIEW_ARB_PERIOD_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
CREATE TABLE CSRIMP.DATAVIEW_ARBITRARY_PERIOD_HIST (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DATAVIEW_SID		NUMBER(10),
	VERSION_NUM         NUMBER(10),
	START_DTM			DATE,
	END_DTM				DATE,
	CONSTRAINT PK_DATAVIEW_ARB_PERIOD_HIST PRIMARY KEY (CSRIMP_SESSION_ID, DATAVIEW_SID, VERSION_NUM, START_DTM),
    CONSTRAINT FK_DATAVIEW_ARB_PERIOD_HIST_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
CREATE TABLE csr.like_for_like_slot (
	app_sid						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	like_for_like_sid			NUMBER(10, 0) NOT NULL,
	name						VARCHAR2(255) NOT NULL,
	ind_sid						NUMBER(10, 0) NOT NULL,
	region_sid  				NUMBER(10, 0) NOT NULL,
	include_inactive_regions	NUMBER(1, 0) NOT NULL,
	period_start_dtm			DATE NOT NULL,
	period_end_dtm				DATE NOT NULL,
	period_set_id				NUMBER(10, 0) NOT NULL,
	period_interval_id			NUMBER(10, 0) NOT NULL,
	rule_type					NUMBER(1, 0) NOT NULL,
	scenario_run_sid			NUMBER(10, 0) NOT NULL,
	created_by_user_sid			NUMBER(10, 0),
	created_dtm 				DATE,
	last_refresh_user_sid 		NUMBER(10, 0),
	last_refresh_dtm 			DATE,
	is_locked					NUMBER(1, 0) NOT NULL,
	CONSTRAINT PK_LIKE_FOR_LIKE 		PRIMARY KEY	(APP_SID, LIKE_FOR_LIKE_SID),
	CONSTRAINT FK_L4L_SLOT_IND_SID 		FOREIGN KEY	(APP_SID, IND_SID) REFERENCES CSR.IND(APP_SID, IND_SID),
	CONSTRAINT FK_L4L_SLOT_REGION_SID 	FOREIGN KEY	(APP_SID, REGION_SID) REFERENCES CSR.REGION(APP_SID, REGION_SID),
	CONSTRAINT FK_L4L_SLOT_SCENARIO_RUN	FOREIGN KEY	(APP_SID, SCENARIO_RUN_SID) REFERENCES CSR.SCENARIO_RUN(APP_SID, SCENARIO_RUN_SID),
	CONSTRAINT FK_L4L_SLOT_CREATED_BY 	FOREIGN KEY	(APP_SID, CREATED_BY_USER_SID) REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID),
	CONSTRAINT FK_L4L_SLOT_REFRESHED_BY FOREIGN KEY	(APP_SID, LAST_REFRESH_USER_SID) REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID),
	CONSTRAINT FK_L4L_SLOT_PERIOD_INT 	FOREIGN KEY	(APP_SID, PERIOD_SET_ID, PERIOD_INTERVAL_ID) REFERENCES CSR.PERIOD_INTERVAL(APP_SID, PERIOD_SET_ID, PERIOD_INTERVAL_ID),
	CONSTRAINT CK_L4L_RULE_TYPE			CHECK 		(RULE_TYPE IN (0, 1)),
	CONSTRAINT CK_L4L_INCL_INACT_REG	CHECK 		(INCLUDE_INACTIVE_REGIONS IN (0, 1)),
	CONSTRAINT CK_L4L_INCL_LOCKED		CHECK 		(IS_LOCKED IN (0, 1))
);
CREATE TABLE csr.like_for_like_email_sub (
	app_sid				NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	like_for_like_sid	NUMBER(10, 0) NOT NULL,
	csr_user_sid		NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_L4L_EMAIL		 		PRIMARY KEY	(APP_SID, LIKE_FOR_LIKE_SID, CSR_USER_SID),
	CONSTRAINT FK_L4L_EMAIL_L4L_SID 	FOREIGN KEY	(APP_SID, LIKE_FOR_LIKE_SID) REFERENCES CSR.LIKE_FOR_LIKE_SLOT(APP_SID, LIKE_FOR_LIKE_SID),
	CONSTRAINT FK_L4L_EMAIL_USER_SID	FOREIGN KEY	(APP_SID, CSR_USER_SID) REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
);
CREATE TABLE csr.batch_job_like_for_like (
	app_sid				NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	batch_job_id		NUMBER(10, 0) NOT NULL,
	like_for_like_sid	NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_BATCH_JOB_L4L PRIMARY KEY (APP_SID, LIKE_FOR_LIKE_SID, BATCH_JOB_ID),
	CONSTRAINT FK_BATCH_JOB_L4L_LIKE_SID FOREIGN KEY (APP_SID, LIKE_FOR_LIKE_SID) REFERENCES CSR.LIKE_FOR_LIKE_SLOT(APP_SID, LIKE_FOR_LIKE_SID),
	CONSTRAINT FK_BATCH_JOB_L4L_JOB_ID FOREIGN KEY (APP_SID, BATCH_JOB_ID) REFERENCES CSR.BATCH_JOB(APP_SID, BATCH_JOB_ID)
);
CREATE TABLE csr.like_for_like_excluded_regions (
	app_sid				NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	like_for_like_sid	NUMBER(10, 0) NOT NULL,
	region_sid			NUMBER(10, 0) NOT NULL,
	period_start_dtm	DATE,
	period_end_dtm		DATE,
	CONSTRAINT PK_L4L_EXCLUDED_REGIONS PRIMARY KEY (APP_SID, LIKE_FOR_LIKE_SID, REGION_SID, PERIOD_START_DTM, PERIOD_END_DTM),
	CONSTRAINT FK_L4L_EXCLUDED_REG_LIKE_SID FOREIGN KEY (APP_SID, LIKE_FOR_LIKE_SID) REFERENCES CSR.LIKE_FOR_LIKE_SLOT(APP_SID, LIKE_FOR_LIKE_SID),
	CONSTRAINT FK_L4L_EXCLUDED_REG_REGION_SID FOREIGN KEY (APP_SID, REGION_SID) REFERENCES CSR.REGION(APP_SID, REGION_SID),
	CONSTRAINT CK_L4L_EXCLUDED_REG_DATES CHECK (PERIOD_END_DTM > PERIOD_START_DTM)
);
CREATE TABLE csrimp.like_for_like_slot (
	csrimp_session_id			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	like_for_like_sid			NUMBER(10, 0) NOT NULL,
	name						VARCHAR2(255) NOT NULL,
	ind_sid						NUMBER(10, 0) NOT NULL,
	region_sid  				NUMBER(10, 0) NOT NULL,
	include_inactive_regions	NUMBER(1, 0) NOT NULL,
	period_start_dtm			DATE NOT NULL,
	period_end_dtm				DATE NOT NULL,
	period_set_id				NUMBER(10, 0) NOT NULL,
	period_interval_id			NUMBER(10, 0) NOT NULL,
	rule_type					NUMBER(1, 0) NOT NULL,
	scenario_run_sid			NUMBER(10, 0) NOT NULL,
	created_by_user_sid			NUMBER(10, 0),
	created_dtm 				DATE,
	last_refresh_user_sid 		NUMBER(10, 0),
	last_refresh_dtm 			DATE,
	is_locked					NUMBER(1, 0) NOT NULL,
	CONSTRAINT PK_LIKE_FOR_LIKE 		PRIMARY KEY	(CSRIMP_SESSION_ID, LIKE_FOR_LIKE_SID),
	CONSTRAINT FK_LIKE_FOR_LIKE_SESSION FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE,
	CONSTRAINT CK_L4L_RULE_TYPE			CHECK 		(RULE_TYPE IN (0, 1)),
	CONSTRAINT CK_L4L_INCL_INACT_REG	CHECK 		(INCLUDE_INACTIVE_REGIONS IN (0, 1)),
	CONSTRAINT CK_L4L_INCL_LOCKED		CHECK 		(IS_LOCKED IN (0, 1))
);
CREATE TABLE csrimp.like_for_like_email_sub (
	csrimp_session_id		NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	like_for_like_sid		NUMBER(10, 0) NOT NULL,
	csr_user_sid			NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_L4L_EMAIL		 		PRIMARY KEY	(CSRIMP_SESSION_ID, LIKE_FOR_LIKE_SID, CSR_USER_SID),
	CONSTRAINT FK_L4L_EMAIL_SESSION 	FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
--Failed to locate all sections of latest2935_3.sql


ALTER TABLE CSR.EST_ERROR RENAME TO EST_ERROR_XXX;
ALTER TABLE CSR.EST_ERROR_2 RENAME TO EST_ERROR;
CREATE INDEX CSR.IX_EST_ERROR ON CSR.EST_ERROR (APP_SID, REGION_SID, EST_ACCOUNT_SID, PM_CUSTOMER_ID, PM_BUILDING_ID, PM_SPACE_ID, PM_METER_ID, ERROR_CODE, ERROR_MESSAGE, REQUEST_URL);
CREATE INDEX CSR.IX_EST_ERROR_ACTIVE_DTM ON CSR.EST_ERROR (ERROR_DTM, ACTIVE);
DROP INDEX CSR.IX_EST_ERROR_REGION;
DROP INDEX CSR.IX_EST_ERROR_ACCOUNT;
DROP INDEX CSR.IX_EST_ERROR_CUSTOMER;
DROP INDEX CSR.IX_EST_ERROR_BUILDING;
DROP INDEX CSR.IX_EST_ERROR_SPACE;
DROP INDEX CSR.IX_EST_ERROR_METER;
DROP INDEX CSR.IX_EST_ERROR_SPACE_METER;
ALTER TABLE CSR.EST_ERROR_XXX DROP CONSTRAINT PK_EST_ERROR;
ALTER TABLE CSR.EST_ERROR_XXX DROP CONSTRAINT FK_CUSTOMER_EST_ERROR;
CREATE INDEX CSR.IX_EST_ERROR_REGION ON CSR.EST_ERROR (APP_SID, REGION_SID);
CREATE INDEX CSR.IX_EST_ERROR_ACCOUNT ON CSR.EST_ERROR (APP_SID, EST_ACCOUNT_SID);
CREATE INDEX CSR.IX_EST_ERROR_CUSTOMER ON CSR.EST_ERROR (APP_SID, EST_ACCOUNT_SID, PM_CUSTOMER_ID);
CREATE INDEX CSR.IX_EST_ERROR_BUILDING ON CSR.EST_ERROR (APP_SID, EST_ACCOUNT_SID, PM_CUSTOMER_ID, PM_BUILDING_ID);
CREATE INDEX CSR.IX_EST_ERROR_SPACE ON CSR.EST_ERROR (APP_SID, EST_ACCOUNT_SID, PM_CUSTOMER_ID, PM_BUILDING_ID, PM_SPACE_ID);
CREATE INDEX CSR.IX_EST_ERROR_METER ON CSR.EST_ERROR (APP_SID, EST_ACCOUNT_SID, PM_CUSTOMER_ID, PM_BUILDING_ID, PM_METER_ID);
CREATE INDEX CSR.IX_EST_ERROR_SPACE_METER ON CSR.EST_ERROR (APP_SID, EST_ACCOUNT_SID, PM_CUSTOMER_ID, PM_BUILDING_ID, PM_SPACE_ID, PM_METER_ID);
ALTER TABLE CSR.EST_ERROR ADD (
	CONSTRAINT CHK_EST_ERROR_ACTIVE_1_0 CHECK (ACTIVE IN(0,1)),
    CONSTRAINT PK_EST_ERROR PRIMARY KEY (APP_SID, EST_ERROR_ID),
	CONSTRAINT FK_CUSTOMER_EST_ERROR FOREIGN KEY (APP_SID)
		REFERENCES CSR.CUSTOMER(APP_SID)
);
ALTER TABLE CSR.METER_RAW_DATA_LOG ADD CONSTRAINT FK_CSRUSR_METRAWDATLOG 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;
ALTER TABLE CSR.METER_RAW_DATA_LOG ADD CONSTRAINT FK_METRAWDAT_METRAWDATLOG 
    FOREIGN KEY (APP_SID, METER_RAW_DATA_ID)
    REFERENCES CSR.METER_RAW_DATA(APP_SID, METER_RAW_DATA_ID)
;
ALTER TABLE CSR.METER_RAW_DATA ADD (
	ORIGINAL_MIME_TYPE              VARCHAR2(256),
    ORIGINAL_FILE_NAME              VARCHAR2(1024),
    ORIGINAL_DATA                   BLOB,
    AUTOMATED_IMPORT_INSTANCE_ID    NUMBER(10, 0)
);
ALTER TABLE CSR.METER_RAW_DATA ADD CONSTRAINT FK_AUTIMPINST_METRAWDATLOG 
    FOREIGN KEY (APP_SID, AUTOMATED_IMPORT_INSTANCE_ID)
    REFERENCES CSR.AUTOMATED_IMPORT_INSTANCE(APP_SID, AUTOMATED_IMPORT_INSTANCE_ID)
;
CREATE INDEX CSR.IX_CSRUSR_METRAWDATLOG ON CSR.METER_RAW_DATA_LOG (APP_SID, USER_SID);
CREATE INDEX CSR.IX_METRAWDAT_METRAWDATLOG ON CSR.METER_RAW_DATA_LOG (APP_SID, METER_RAW_DATA_ID);
CREATE INDEX CSR.IX_AUTIMPINST_METRAWDATLOG ON CSR.METER_RAW_DATA (APP_SID, AUTOMATED_IMPORT_INSTANCE_ID);
ALTER TABLE CSRIMP.METER_RAW_DATA ADD (
	ORIGINAL_MIME_TYPE              VARCHAR2(256),
    ORIGINAL_FILE_NAME              VARCHAR2(1024),
    ORIGINAL_DATA                   BLOB,
    AUTOMATED_IMPORT_INSTANCE_ID    NUMBER(10, 0)
);
ALTER TABLE csr.flow_transition_alert ADD can_be_edited_before_sending NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE csr.flow_transition_alert ADD CONSTRAINT chk_fta_can_be_edited CHECK (can_be_edited_before_sending IN (0,1));
ALTER TABLE csr.t_flow_trans_alert ADD can_be_edited_before_sending NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE csr.flow_item_generated_alert ADD subject_override CLOB NULL;
ALTER TABLE csr.flow_item_generated_alert ADD body_override CLOB NULL;
ALTER TABLE csrimp.flow_transition_alert ADD can_be_edited_before_sending NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE csrimp.flow_item_generated_alert ADD subject_override CLOB NULL;
ALTER TABLE csrimp.flow_item_generated_alert ADD body_override CLOB NULL;
ALTER TABLE csr.property_options ADD (auto_assign_manager NUMBER(1, 0) DEFAULT 0 NOT NULL);
ALTER TABLE csrimp.property_options ADD (auto_assign_manager NUMBER(1, 0));
UPDATE csrimp.property_options SET auto_assign_manager = 0;
ALTER TABLE csrimp.property_options MODIFY auto_assign_manager NUMBER(1, 0) NOT NULL;
/*
ALTER TABLE chain.saved_filter DROP CONSTRAINT chk_ranking_mode;
ALTER TABLE chain.saved_filter DROP COLUMN ranking_mode;
ALTER TABLE csrimp.chain_saved_filter DROP COLUMN ranking_mode;
*/
ALTER TABLE chain.saved_filter ADD (
	ranking_mode NUMBER(1,0) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_ranking_mode CHECK (ranking_mode IN (0, 1, 2))
);
ALTER TABLE csrimp.chain_saved_filter ADD (
	ranking_mode NUMBER(1,0) NULL
);
UPDATE csrimp.chain_saved_filter SET ranking_mode = 0;
ALTER TABLE csrimp.chain_saved_filter MODIFY (ranking_mode NUMBER(1,0) NOT NULL);
ALTER TABLE csr.customer
ADD like_for_like_slots NUMBER(10) DEFAULT 0 NOT NULL;
ALTER TABLE csr.scenario_run
ADD last_success_dtm DATE;
ALTER TABLE csr.scenario_run
ADD on_completion_sp VARCHAR2(255);
ALTER TABLE csrimp.customer
ADD like_for_like_slots NUMBER(10) DEFAULT 0 NOT NULL;
ALTER TABLE csrimp.scenario_run
ADD last_success_dtm DATE;
ALTER TABLE csrimp.scenario_run
ADD on_completion_sp VARCHAR2(255);
CREATE SEQUENCE CHAIN.REFERENCE_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;
CREATE SEQUENCE CHAIN.COMPANY_REFERENCE_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;
ALTER TABLE CHAIN.REFERENCE ADD REFERENCE_ID NUMBER(10, 0);
ALTER TABLE CHAIN.COMPANY_REFERENCE ADD REFERENCE_ID NUMBER(10, 0);
ALTER TABLE CHAIN.COMPANY_REFERENCE ADD COMPANY_REFERENCE_ID NUMBER(10, 0);
BEGIN
	security.user_pkg.logonadmin; --all sites
	
	UPDATE chain.reference
	   SET reference_id = chain.reference_id_seq.nextval;
	   
	UPDATE chain.company_reference
	   SET company_reference_id = chain.company_reference_id_seq.nextval;
		 
	UPDATE chain.company_reference cr
	   SET cr.reference_id = (
			SELECT reference_id
			  FROM chain.reference r
			 WHERE r.app_sid = cr.app_sid
			   AND r.lookup_key = cr.lookup_key
	   );
	
END;
/
ALTER TABLE CHAIN.REFERENCE MODIFY REFERENCE_ID NUMBER(10, 0) NOT NULL;
ALTER TABLE CHAIN.COMPANY_REFERENCE DROP PRIMARY KEY DROP INDEX;
ALTER TABLE CHAIN.COMPANY_REFERENCE DROP CONSTRAINT FK_REF_COMPANY_REF;
ALTER TABLE CHAIN.COMPANY_REFERENCE RENAME COLUMN LOOKUP_KEY TO XXX_LOOKUP_KEY;
ALTER TABLE CHAIN.REFERENCE DROP PRIMARY KEY DROP INDEX;
ALTER TABLE CHAIN.REFERENCE ADD CONSTRAINT UC_REFERENCE UNIQUE (APP_SID, LOOKUP_KEY);
ALTER TABLE CHAIN.REFERENCE ADD CONSTRAINT PK_REFERENCE PRIMARY KEY (APP_SID, REFERENCE_ID);
ALTER TABLE CHAIN.COMPANY_REFERENCE ADD CONSTRAINT FK_REF_COMPANY_REF 
	FOREIGN KEY (APP_SID, REFERENCE_ID) REFERENCES CHAIN.REFERENCE(APP_SID, REFERENCE_ID);
ALTER TABLE CHAIN.COMPANY_REFERENCE MODIFY REFERENCE_ID NUMBER(10, 0) NOT NULL;
ALTER TABLE CHAIN.COMPANY_REFERENCE ADD CONSTRAINT PK_COMPANY_REFERENCE PRIMARY KEY (APP_SID, COMPANY_REFERENCE_ID);
ALTER TABLE CHAIN.COMPANY_REFERENCE ADD CONSTRAINT UC_COMPANY_REFERENCE UNIQUE (APP_SID, REFERENCE_ID, COMPANY_SID);
ALTER TABLE CSRIMP.CHAIN_REFERENCE ADD REFERENCE_ID NUMBER(10, 0) NOT NULL;
ALTER TABLE CSRIMP.CHAIN_COMPANY_REFERENCE ADD COMPANY_REFERENCE_ID NUMBER(10, 0) NOT NULL; 
ALTER TABLE CSRIMP.CHAIN_COMPANY_REFERENCE ADD REFERENCE_ID NUMBER(10, 0) NOT NULL;
ALTER TABLE CSRIMP.CHAIN_REFERENCE DROP CONSTRAINT PK_CHAIN_REFERENCE;
ALTER TABLE CSRIMP.CHAIN_COMPANY_REFERENCE DROP CONSTRAINT PK_CHAIN_COMPANY_REFERENCE;
ALTER TABLE CSRIMP.CHAIN_COMPANY_REFERENCE DROP COLUMN LOOKUP_KEY;
ALTER TABLE CSRIMP.CHAIN_REFERENCE ADD CONSTRAINT PK_CHAIN_REFERENCE PRIMARY KEY (CSRIMP_SESSION_ID, REFERENCE_ID);
ALTER TABLE CSRIMP.CHAIN_COMPANY_REFERENCE ADD CONSTRAINT PK_CHAIN_COMPANY_REFERENCE PRIMARY KEY (CSRIMP_SESSION_ID, COMPANY_REFERENCE_ID);
CREATE TABLE CSRIMP.MAP_CHAIN_REFERENCE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_REFERENCE_ID NUMBER(10) NOT NULL,
	NEW_REFERENCE_ID  NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_REFERENCE primary key (csrimp_session_id, OLD_REFERENCE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_REFERENCE unique (csrimp_session_id, NEW_REFERENCE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_REFERENCE FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
 ALTER TABLE csr.approval_dashboard_ind
RENAME COLUMN hidden_dtm TO deactivated_dtm;
 ALTER TABLE csrimp.approval_dashboard_ind
RENAME COLUMN hidden_dtm TO deactivated_dtm;
ALTER TABLE csr.approval_dashboard_ind
ADD is_hidden NUMBER(1) DEFAULT 0 NOT NULL; 
ALTER TABLE csrimp.approval_dashboard_ind
ADD is_hidden NUMBER(1) DEFAULT 0 NOT NULL;
DECLARE
	v_col_check NUMBER(1);
BEGIN	
	SELECT COUNT(*) INTO v_col_check
	  FROM dba_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'CUSTOMER'
	   AND column_name = 'REMOVE_ROLES_ON_ACCOUNT_EXPIR';
	
	IF v_col_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.CUSTOMER ADD REMOVE_ROLES_ON_ACCOUNT_EXPIR NUMBER(1,0) DEFAULT 0 NOT NULL';
	ELSE
		DBMS_OUTPUT.PUT_LINE('Skip, column already created.');
	END IF;
END;
/
DECLARE
	v_col_check NUMBER(1);
BEGIN	
	SELECT COUNT(*) INTO v_col_check
	  FROM dba_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'CSR_USER'
	   AND column_name = 'REMOVE_ROLES_ON_DEACTIVATION';
	
	IF v_col_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.CSR_USER ADD REMOVE_ROLES_ON_DEACTIVATION NUMBER(1,0) DEFAULT 0 NOT NULL';
	ELSE
		DBMS_OUTPUT.PUT_LINE('Skip, column already created.');
	END IF;
END;
/
DECLARE
	v_col_check NUMBER(1);
BEGIN	
	SELECT COUNT(*) INTO v_col_check
	  FROM dba_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'BATCH_JOB_STRUCTURE_IMPORT'
	   AND column_name = 'REMOVE_FROM_ROLES_INACTIVATED';
	
	IF v_col_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.BATCH_JOB_STRUCTURE_IMPORT ADD REMOVE_FROM_ROLES_INACTIVATED NUMBER(1,0) DEFAULT 0';
	ELSE
		DBMS_OUTPUT.PUT_LINE('Skip, column already created.');
	END IF;
END;
/
DECLARE
	v_col_check NUMBER(1);
BEGIN	
	SELECT COUNT(*) INTO v_col_check
	  FROM dba_tab_columns
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'CUSTOMER'
	   AND column_name = 'REMOVE_ROLES_ON_ACCOUNT_EXPIR';
	
	IF v_col_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.CUSTOMER ADD REMOVE_ROLES_ON_ACCOUNT_EXPIR NUMBER(1,0)';
	ELSE
		DBMS_OUTPUT.PUT_LINE('Skip, column already created.');
	END IF;
END;
/
DECLARE
	v_col_check NUMBER(1);
BEGIN	
	SELECT COUNT(*) INTO v_col_check
	  FROM dba_tab_columns
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'USER_TABLE'
	   AND column_name = 'REMOVE_ROLES_ON_DEACTIVATION';
	
	IF v_col_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.USER_TABLE ADD REMOVE_ROLES_ON_DEACTIVATION NUMBER(1,0)';
	ELSE
		DBMS_OUTPUT.PUT_LINE('Skip, column already created.');
	END IF;
END;
/


grant insert on csr.meter_raw_data_log to csrimp;
GRANT INSERT,SELECT,UPDATE ON csr.dataview_arbitrary_period TO csrimp;
GRANT INSERT,SELECT,UPDATE ON csr.dataview_arbitrary_period_hist TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.dataview_arbitrary_period TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.dataview_arbitrary_period_hist TO csrimp;
GRANT INSERT,SELECT,UPDATE,DELETE ON csrimp.dataview_arbitrary_period to web_user;
GRANT INSERT,SELECT,UPDATE,DELETE ON csrimp.dataview_arbitrary_period_hist to web_user;
grant select, insert, update on csr.like_for_like_slot to csrimp;
grant select, insert, update on csr.like_for_like_email_sub to csrimp;
grant select on chain.reference_id_seq to csrimp;
grant select on chain.company_reference_id_seq to csrimp;
grant select, insert, update, delete on csrimp.issue_custom_field_date_val to web_user;
grant select, insert, update, delete on csrimp.quick_survey_css to web_user;




CREATE OR REPLACE VIEW csr.v$est_error_description
AS
	SELECT est_error_id, help_text
	  FROM (
		SELECT est_error_id, 
			   help_text,
			   ROW_NUMBER() OVER(PARTITION BY e.est_error_id ORDER BY e.error_code) ix 
		  FROM csr.est_error e
		  LEFT JOIN csr.property p ON p.region_sid = e.region_sid
		  LEFT JOIN csr.est_space s ON s.pm_space_id = e.pm_space_id
		  LEFT JOIN csr.est_meter m ON m.pm_meter_id = e.pm_meter_id
		  LEFT JOIN csr.est_building b ON b.pm_building_id = e.pm_building_id
		  LEFT JOIN csr.property sp ON sp.region_sid = s.region_sid
		  LEFT JOIN csr.property mp ON mp.region_sid = m.region_sid
		  LEFT JOIN csr.property bp ON bp.region_sid = b.region_sid
		  LEFT JOIN csr.est_error_description ed 
			ON e.error_code = ed.error_no
		   AND (e.request_url IS NULL OR 
				ed.msg_pattern IS NULL OR 
				REGEXP_LIKE(e.request_url, ed.url_pattern, 'i'))
		   AND (ed.msg_pattern IS NULL OR 
				REGEXP_LIKE(e.error_message, ed.msg_pattern, 'i'))
		   AND ((ed.applies_to_space = 1 AND e.pm_space_id IS NOT NULL) OR 
				(ed.applies_to_meter = 1 AND e.pm_meter_id IS NOT NULL) OR 
				(ed.applies_to_push = 1 AND (
					p.energy_star_push = 1 OR 
					sp.energy_star_push = 1 OR
					mp.energy_star_push = 1 OR 
					bp.energy_star_push = 1)
				)
			)
	 )
	 WHERE ix = 1;
CREATE OR REPLACE VIEW csr.v$flow_item_gen_alert AS
SELECT fta.flow_transition_alert_id, fta.customer_alert_type_id, fta.helper_sp,
	flsf.flow_state_id from_state_id, flsf.label from_state_label,
	flst.flow_state_id to_state_id, flst.label to_state_label, 
	fsl.flow_state_log_Id, fsl.set_dtm, fsl.set_by_user_sid, fsl.comment_text,
	cusb.full_name set_by_full_name, cusb.email set_by_email, cusb.user_name set_by_user_name, 
	cut.csr_user_sid to_user_sid, cut.full_name to_full_name,
	cut.email to_email, cut.user_name to_user_name, cut.friendly_name to_friendly_name,
	fi.app_sid, fi.flow_item_id, fi.flow_sid, fi.current_state_id,
	fi.survey_response_id, fi.dashboard_instance_id, fta.to_initiator, fta.flow_alert_helper,
	figa.to_column_sid, figa.flow_item_generated_alert_id, figa.processed_dtm, figa.created_dtm, 
	cat.is_batched, ftacc.alert_manager_flag, fta.flow_state_transition_id,
	figa.subject_override, figa.body_override, fta.can_be_edited_before_sending
  FROM flow_item_generated_alert figa 
  JOIN flow_state_log fsl ON figa.flow_state_log_id = fsl.flow_state_log_id AND figa.flow_item_id = fsl.flow_item_id AND figa.app_sid = fsl.app_sid
  JOIN csr_user cusb ON fsl.set_by_user_sid = cusb.csr_user_sid AND fsl.app_sid = cusb.app_sid 
  JOIN flow_item fi ON figa.flow_item_id = fi.flow_item_id AND figa.app_sid = fi.app_sid
  JOIN flow_transition_alert fta ON figa.flow_transition_alert_id = fta.flow_transition_alert_id AND figa.app_sid = fta.app_sid            
  JOIN flow_state_transition fst ON fta.flow_state_transition_id = fst.flow_state_transition_id AND fta.app_sid = fst.app_sid
  JOIN flow_state flsf ON fst.from_state_id = flsf.flow_state_id AND fst.app_sid = flsf.app_sid
  JOIN flow_state flst ON fst.to_state_id = flst.flow_state_id AND fst.app_sid = flst.app_sid
  LEFT JOIN cms_alert_type cat ON  fta.customer_alert_type_id = cat.customer_alert_type_id
  LEFT JOIN flow_transition_alert_cms_col ftacc ON figa.flow_transition_alert_id = ftacc.flow_transition_alert_id AND figa.to_column_sid = ftacc.column_sid
  LEFT JOIN csr_user cut ON figa.to_user_sid = cut.csr_user_sid AND figa.app_sid = cut.app_sid
 WHERE fta.deleted = 0;
CREATE OR REPLACE VIEW csr.v$open_flow_item_gen_alert AS
SELECT flow_transition_alert_id, customer_alert_type_id, helper_sp,
	from_state_id, from_state_label,
	to_state_id, to_state_label, 
	flow_state_log_Id, set_dtm, set_by_user_sid, comment_text,
	set_by_full_name, set_by_email, set_by_user_name, 
	to_user_sid, to_full_name,
	to_email, to_user_name, to_friendly_name,
	app_sid, flow_item_id, flow_sid, current_state_id,
	survey_response_id, dashboard_instance_id, to_initiator, flow_alert_helper,
	to_column_sid, flow_item_generated_alert_id,
	is_batched, alert_manager_flag, created_dtm, flow_state_transition_id,
	subject_override, body_override, can_be_edited_before_sending
  FROM csr.v$flow_item_gen_alert 
 WHERE processed_dtm IS NULL;
INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
	VALUES (25, 'Like for like region recalc', NULL, 'like-for-like', 1, NULL);
CREATE OR REPLACE VIEW chain.v$company_reference AS
	SELECT cr.app_sid, cr.company_reference_id, cr.company_sid, cr.value, cr.reference_id, r.lookup_key
	  FROM chain.company_reference cr
	  JOIN chain.reference r ON r.app_sid = cr.app_sid AND r.reference_id = cr.reference_id;




BEGIN
	INSERT INTO csr.est_error_description(error_no, url_pattern, msg_pattern, help_text, applies_to_space, applies_to_meter, applies_to_push)
		 VALUES (404, NULL, '^404 - meter does not exist', 'The meter has been edited in cr360, but the meter has been deleted in Energy Star. Please restore the meter in Energy Star or delete it in cr360.', 0, 1, 1);
	INSERT INTO csr.est_error_description(error_no, url_pattern, msg_pattern, help_text, applies_to_space, applies_to_meter, applies_to_push)
		 VALUES (404, NULL, '^404 - meter consumption data does not exist', 'The reading has been edited in cr360, but the reading has been deleted in Energy Star. Please restore the reading in Energy Star or delete it in cr360.', 0, 1, 1);
	INSERT INTO csr.est_error_description(error_no, url_pattern, msg_pattern, help_text, applies_to_space, applies_to_meter, applies_to_push)
		 VALUES (404, 'consumptiondata'	, '^404 - $', 'The meter or its readings have been edited in cr360, but the meter or its readings have been deleted in Energy Star. Please restore the meter or readings in Energy Star or delete them in cr360.', 0, 1, 1);
	INSERT INTO csr.est_error_description(error_no, url_pattern, msg_pattern, help_text, applies_to_space, applies_to_meter, applies_to_push)
		 VALUES (404, 'meter', '^404 - $', 'The meter has been edited in cr360, but the meter has been deleted in Energy Star. Please restore the meter in Energy Star or delete it in cr360.', 0, 1, 1);
	INSERT INTO csr.est_error_description(error_no, url_pattern, msg_pattern, help_text, applies_to_space, applies_to_meter, applies_to_push)
		 VALUES (404, NULL, '^error retrieving rest response', 'Energy Star is currently unavailable.', 0, 1, 1);
END;
/
BEGIN
	DELETE FROM csr.est_error err
	 WHERE err.est_error_id NOT IN (
	  SELECT MAX(est_error_id)
	    FROM csr.est_error
	   GROUP BY region_sid, est_account_sid, pm_customer_id, pm_building_id, pm_space_id, pm_meter_id, error_code, error_message, request_url
	 );
END;
/
DECLARE
    job BINARY_INTEGER;
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.PurgeInactiveEnergyStarErrors',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'csr.energy_star_pkg.PurgeInactiveErrors;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 05:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=DAILY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Deletes inactive energy star errors that are older than a month');
END;
/
COMMIT;
BEGIN
	-- Hook-up automated import ids and raw data rows using the latest file name
	-- Error files
	FOR r IN (
		SELECT app_sid, automated_import_instance_id, meter_raw_data_id
		  FROM csr.urjanet_import_instance
	) LOOP
		UPDATE csr.meter_raw_data
		   SET automated_import_instance_id = r.automated_import_instance_id
		 WHERE app_sid = r.app_sid 
		   AND meter_raw_data_id = r.meter_raw_data_id
		   AND automated_import_instance_id IS NULL; 
	END LOOP;
	-- Normal files
	FOR r IN (
		SELECT DISTINCT d.app_sid, d.meter_raw_data_id, d.file_name,
			FIRST_VALUE(s.automated_import_instance_id) OVER (
				PARTITION BY s.payload_filename 
				ORDER BY s.completed_dtm DESC NULLS LAST, s.started_dtm DESC, s.automated_import_instance_id DESC
			) automated_import_instance_id
		  FROM csr.meter_raw_data d
		  JOIN csr.automated_import_instance_step s ON s.app_sid = d.app_sid AND s.payload_filename = d.file_name
	) LOOP
		UPDATE csr.meter_raw_data
		   SET automated_import_instance_id = r.automated_import_instance_id
		 WHERE app_sid = r.app_sid 
		   AND meter_raw_data_id = r.meter_raw_data_id
		   AND automated_import_instance_id IS NULL;
	END LOOP;
END;
/
BEGIN
	-- Keep urjanet files for 365 days
	FOR r IN (
		SELECT app_sid, automated_import_class_sid
		  FROM csr.automated_import_class
		 WHERE lookup_key = 'URJANET_IMPORTER'
	) LOOP
		UPDATE csr.automated_import_class_step
		   SET days_to_retain_payload = 365
		 WHERE app_sid = r.app_sid
		   AND automated_import_class_sid = r.automated_import_class_sid;
	END LOOP;
END;
/
EXEC security.user_pkg.logonadmin;
  
UPDATE csr.automated_import_class_step 
   SET plugin = 'Credit360.AutomatedExportImport.Import.Plugins.UrjanetImporterStepPlugin'
 WHERE importer_plugin_id = 2;
 
BEGIN  
  FOR x IN (
	SELECT map.app_sid app_sid, map.message_id message_id, message, severity, msg_dtm message_dtm
	  FROM csr.auto_import_message_map map
	  JOIN csr.auto_impexp_instance_msg msg ON msg.message_id = map.message_id AND msg.app_sid = map.app_sid
	 WHERE UPPER(message)='CRITICAL ERROR IN STEP'
	   AND (map.app_sid, import_instance_id) IN (
		SELECT app_sid, automated_import_instance_id 
		  FROM csr.automated_import_instance_step  
		 WHERE result=3 
		   AND payload_filename IS NULL 
		   AND (app_sid, automated_import_class_sid, step_number) IN (
			SELECT app_sid, automated_import_class_sid, step_number 
			  FROM csr.automated_import_class_step 
			 WHERE importer_plugin_id=2)))
LOOP
	DELETE FROM csr.auto_import_message_map WHERE message_id=x.message_id AND app_sid = x.app_sid;
	DELETE FROM csr.auto_impexp_instance_msg WHERE message_id=x.message_id AND app_sid = x.app_sid;
END LOOP;
END;
/ 
UPDATE csr.batch_job
   SET result='The import completed successfully'
 WHERE UPPER(result)='THE IMPORT FAILED' 
   AND (app_sid, batch_job_id) IN (
	SELECT ii.app_sid, batch_job_id 
      FROM csr.automated_import_instance ii
      JOIN csr.automated_import_instance_step  iis ON iis.automated_import_instance_id = ii.automated_import_instance_id AND ii.app_sid = iis.app_sid
     WHERE iis.result=3 
       AND iis.payload_filename IS NULL 
       AND (iis.app_sid, iis.automated_import_class_sid, step_number) IN (
		SELECT app_sid, automated_import_class_sid, step_number 
		  FROM csr.automated_import_class_step 
		 WHERE importer_plugin_id=2));
		 
UPDATE csr.automated_import_instance_step
   SET result=5
 WHERE result=3 
   AND payload_filename IS NULL 
   AND (app_sid, automated_import_class_sid,step_number) IN (
	SELECT app_sid, automated_import_class_sid,step_number 
	  FROM csr.automated_import_class_step 
	 WHERE importer_plugin_id=2);
INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class)
SELECT 
	csr.plugin_id_seq.NEXTVAL, 
	16,
	'Low-res chart', 
	'/csr/site/meter/controls/meterLowResChartTab.js', 
	'Credit360.Metering.MeterLowResChartTab', 
	'Credit360.Metering.Plugins.MeterLowResChart'
FROM dual
WHERE NOT EXISTS(
	SELECT * 
	  FROM csr.plugin 
	 WHERE js_class = 'Credit360.Metering.MeterLowResChartTab' 
	   AND plugin_type_id = 16
);
INSERT INTO csr.user_setting (category, setting, description, data_type)
VALUES ('CREDIT360.METER', 'activeTab', 'Stores the last active plugin tab', 'STRING');
EXEC security.user_pkg.LogonAdmin;
UPDATE chain.saved_filter 
   SET ranking_mode = 1 /* Ascending */
 WHERE (app_sid, saved_filter_sid) IN (
	SELECT app_sid, saved_filter_sid
	FROM (
	  SELECT 
		  app_sid,
		  saved_filter_sid, 
		  COUNT(CASE WHEN chart_type = 3 THEN 1 END) bar_charts,
		  COUNT(CASE WHEN chart_type <> 3 THEN 1 END) other_charts
	  FROM (
		  SELECT app_sid, saved_filter_sid, filter_result_mode chart_type 
		    FROM csr.tpl_report_tag_dataview 
		   WHERE saved_filter_sid IS NOT NULL
		     AND filter_result_mode IS NOT NULL
		UNION ALL
		  SELECT tp.app_sid,
				 TO_NUMBER(REGEXP_REPLACE(tp.state, '.*"dataviewSid":([0-9]+).*', '\1')) saved_filter_sid,
				 TO_NUMBER(REGEXP_REPLACE(tp.state, '.*"chartType":([0-9]+).*', '\1')) chart_type
		    FROM csr.tab_portlet tp
		    JOIN csr.customer_portlet cp 
		      ON cp.customer_portlet_sid = tp.customer_portlet_sid
		    JOIN csr.portlet p
		      ON cp.portlet_id = p.portlet_id
		   WHERE p.type = 'Credit360.Portlets.Chart'
		     AND REGEXP_LIKE(tp.state, '"dataviewSid":([0-9]+)')
		     AND REGEXP_LIKE(tp.state, '"chartType":([0-9]+)')
		     AND REGEXP_LIKE(tp.state, '"isFilter":true')
		UNION ALL
		  SELECT tp.app_sid,
				 TO_NUMBER(REGEXP_REPLACE(tp.state, '.*"dataviewSid":([0-9]+).*', '\1')) saved_filter_sid,
				 99 chart_type /* table... */
		    FROM csr.tab_portlet tp
		    JOIN csr.customer_portlet cp 
		      ON cp.customer_portlet_sid = tp.customer_portlet_sid
		    JOIN csr.portlet p
		      ON cp.portlet_id = p.portlet_id
		   WHERE p.type = 'Credit360.Portlets.Table'
		     AND REGEXP_LIKE(tp.state, '"dataviewSid":([0-9]+)')
		     AND REGEXP_LIKE(tp.state, '"isFilter":true')
	  )
	  GROUP BY app_sid, saved_filter_sid
	)
	WHERE bar_charts > 0 AND other_charts = 0
);
DECLARE
    v_id    NUMBER(10);
BEGIN   
    security.user_pkg.logonadmin;
    security.class_pkg.CreateClass(SYS_CONTEXT('SECURITY','ACT'), null, 'CSRLikeForLike', 'csr.like_for_like_pkg', null, v_id);
EXCEPTION
    WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
        NULL;
END;
/
/* Eurgh, this isn't nice, but needs to be done. I messed up the date format on the inputs for this so the month and day are the wrong way around. This is
   causing issues in .net because the format is wrong, ie 2015-29-01 is the 29th january, but it wants YYYY-MM-DD and ther isn't a 29th month...
   So I've got to try and convert them. Same release fixes the format going in, so we only need to do this once
*/
DECLARE
	v_dtm		DATE;
	v_is_date	NUMBER;
BEGIN
 
	FOR r IN (
		SELECT source_detail, approval_dashboard_val_id, id
		  FROM csr.approval_dashboard_val_src
	)
	LOOP
	
		BEGIN
			-- Try the broken date format first so that we catch any which don't fail but are still wrong 
			v_dtm := TO_DATE(r.source_detail, 'yyyy-dd-mm hh24:mi:ss');
			v_is_date := 1;
		EXCEPTION WHEN others THEN
			-- Try the default
			BEGIN
			-- Try the broken date format first so that we catch any which don't fail but are still wrong 
				v_dtm := TO_DATE(r.source_detail, 'yyyy-dd-mm hh24:mi:ss');
				v_is_date := 1;
			EXCEPTION WHEN others THEN
				-- It's not a date, so we'll leave it alone
				v_is_date := 0;
			END;
		END;
		IF v_is_date = 1 THEN
			-- Write it back
			UPDATE csr.approval_dashboard_val_src
			   SET source_detail = to_char(v_dtm, 'yyyy-mm-dd hh24:mi:ss')
			 WHERE approval_dashboard_val_id = r.approval_dashboard_val_id
			   AND id = r.id
			   AND source_detail = r.source_detail;
		END IF;
  
	END LOOP;
END;
/
DELETE FROM csr.branding_availability
 WHERE LOWER(client_folder_name) IN ('carnstone', 'greatforest');
DELETE FROM csr.branding
 WHERE LOWER(client_folder_name) IN ('carnstone', 'greatforest');




create or replace package csr.like_for_like_pkg as
	procedure dummy;
end;
/
create or replace package body csr.like_for_like_pkg as
	procedure dummy
	as
	begin
		null;
	end;
end;
/
grant execute on csr.like_for_like_pkg to security;
grant execute on csr.like_for_like_pkg to web_user;


@..\..\..\aspen2\db\utils_pkg
@..\energy_star_pkg
@..\meter_monitor_pkg
@..\schema_pkg
@..\flow_pkg
@..\audit_pkg
@..\chain\supplier_flow_pkg
@..\user_report_pkg
@..\property_pkg
@..\chain\filter_pkg
@..\dataview_pkg
@..\batch_job_pkg
@..\like_for_like_pkg
@..\chain\company_pkg
@..\approval_dashboard_pkg
@..\initiative_report_pkg
@..\..\..\security\db\oracle\user_pkg
@..\role_pkg
@..\csr_user_pkg
@..\customer_pkg
@..\structure_import_pkg
@..\stored_calc_datasource_pkg

@..\..\..\aspen2\db\utils_body
@..\portlet_body
@..\meter_monitor_body
@..\energy_star_body
@..\energy_star_job_data_body
@..\schema_body
@..\csrimp\imp_body
@..\enable_body
@..\flow_body
@..\audit_body
@..\chain\supplier_flow_body
@..\user_report_body
@..\property_body
@..\schema_body.sql
@..\csrimp\imp_body.sql
@..\chain\filter_body
@..\sheet_body
@..\section_root_body
@..\deleg_plan_body
@..\dataview_body
@..\non_compliance_report_body
@..\like_for_like_body
@..\chain\company_body
@..\chain\company_filter_body
@..\chain\helper_body
@..\chain\report_body
@..\approval_dashboard_body
@..\issue_body
@..\delegation_body
@..\initiative_report_body
@..\..\..\security\db\oracle\user_body
@..\role_body
@..\csr_user_body
@..\customer_body
@..\structure_import_body
@..\..\..\security\db\oracle\accountpolicyhelper_body
@..\meter_body
@..\period_body
@..\stored_calc_datasource_body


@update_tail
