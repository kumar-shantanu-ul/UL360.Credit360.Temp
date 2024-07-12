define version=3040
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
CREATE TABLE csr.user_measure_conversion AS
SELECT app_sid, csr_user_sid, measure_sid, measure_conversion_id
  FROM csr.last_used_measure_conversion
 WHERE measure_conversion_id IS NOT NULL;
CREATE OR REPLACE TYPE CSR.T_GENERIC_SO_ROW AS 
	OBJECT ( 
		sid_id 			NUMBER(10,0),
		description		VARCHAR2(255),
		position		NUMBER(10,0)
  );
/
CREATE OR REPLACE TYPE CSR.T_GENERIC_SO_TABLE AS 
  TABLE OF CSR.T_GENERIC_SO_ROW;
/
CREATE TABLE CHAIN.PRODUCT_TYPE_TR(
    APP_SID                         NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    PRODUCT_TYPE_ID                 NUMBER(10, 0)     NOT NULL,
    LANG                            VARCHAR2(10)      NOT NULL,
    DESCRIPTION                     VARCHAR2(1023),
    LAST_CHANGED_DTM_DESCRIPTION    DATE,
    CONSTRAINT PK_PRODUCT_TYPE_TR_DESCRIPTION PRIMARY KEY (APP_SID, PRODUCT_TYPE_ID, LANG),
	CONSTRAINT FK_PRODUCT_TYPE_IS FOREIGN KEY
    	(APP_SID, PRODUCT_TYPE_ID) REFERENCES CHAIN.PRODUCT_TYPE (APP_SID, PRODUCT_TYPE_ID)
    	ON DELETE CASCADE
)
;
CREATE TABLE CSRIMP.CHAIN_PRODUCT_TYPE_TR (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    PRODUCT_TYPE_ID                 NUMBER(10, 0)     NOT NULL,
    LANG                            VARCHAR2(10)      NOT NULL,
    DESCRIPTION                     VARCHAR2(1023),
    LAST_CHANGED_DTM_DESCRIPTION    DATE,
    CONSTRAINT PK_PRODUCT_TYPE_TR PRIMARY KEY (CSRIMP_SESSION_ID, PRODUCT_TYPE_ID, LANG),
	CONSTRAINT FK_PRODUCT_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
drop package aspen2.fp_user_pkg;
drop package aspen2.job_pkg;
drop package aspen2.poll_pkg;
drop package aspen2.scheduledtask_pkg;
drop package aspen2.mdcomment_pkg;
drop package aspen2.supportTicket_pkg;
drop package aspen2.print_pkg;
drop package aspen2.trash_pkg;
DROP SEQUENCE ASPEN2.JOB_RUN_ID_SEQ;
DROP SEQUENCE ASPEN2.MDCOMMENT_ID_SEQ;
DROP SEQUENCE ASPEN2.MDCOMMENT_OFFENCE_ID_SEQ;
DROP SEQUENCE ASPEN2.POLL_OPTION_ID_SEQ;
DROP SEQUENCE ASPEN2.PRINT_REQUEST_ID_SEQ;
DROP SEQUENCE ASPEN2.SUPPORT_TICKET_ID_SEQ;
DROP TABLE ASPEN2.MDCOMMENT_OFFENCE;
DROP TABLE ASPEN2.MDCOMMENT;
DROP TABLE ASPEN2.MDCOMMENT_STATUS;
DROP TABLE ASPEN2.FP_USER;
DROP TABLE ASPEN2.POLL_VOTE;
DROP TABLE ASPEN2.POLL_OPTION;
DROP TABLE ASPEN2.POLL;
DROP TABLE ASPEN2.JOB_RUN;
DROP TABLE ASPEN2.JOB;
DROP TABLE ASPEN2.PRINT_RESULT;
DROP TABLE ASPEN2.PRINT_REQUEST_COOKIE;
DROP TABLE ASPEN2.PRINT_REQUEST_HEADER;
DROP TABLE ASPEN2.PRINT_REQUEST;
DROP TABLE ASPEN2.SUPPORT_ADMIN;
DROP TABLE ASPEN2.SUPPORT_TICKET;
DROP TABLE ASPEN2.SUPPORT_TYPE;
DROP TABLE ASPEN2.SUPPORT_STATUS;
DROP TABLE ASPEN2.TASKSCHEDULE;
drop table aspen2.trash;
DROP USER COMMERCE2 CASCADE;
CREATE SEQUENCE CHAIN.CERTIFICATION_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;
CREATE TABLE CHAIN.CERTIFICATION (
	APP_SID						NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CERTIFICATION_ID			NUMBER(10) NOT NULL,
	LABEL						VARCHAR2(1024) NOT NULL,
	LOOKUP_KEY					VARCHAR2(30),
	CONSTRAINT PK_CERTIFICATION PRIMARY KEY (APP_SID, CERTIFICATION_ID)
);
CREATE TABLE CHAIN.CERTIFICATION_AUDIT_TYPE (
	APP_SID						NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CERTIFICATION_ID			NUMBER(10) NOT NULL,
	INTERNAL_AUDIT_TYPE_ID		NUMBER(10) NOT NULL,
	CONSTRAINT PK_CERTIFICATION_AUDIT_TYPE PRIMARY KEY (APP_SID, CERTIFICATION_ID, INTERNAL_AUDIT_TYPE_ID),
	CONSTRAINT FK_CERT_AUDIT_TYPE_CERT FOREIGN KEY (APP_SID, CERTIFICATION_ID) REFERENCES CHAIN.CERTIFICATION(APP_SID, CERTIFICATION_ID)
);
CREATE TABLE CSRIMP.MAP_CHAIN_CERTIFICATION (
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CERTIFICATION_ID		NUMBER(10) NOT NULL,
	NEW_CERTIFICATION_ID		NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_CERTIFICATION PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CERTIFICATION_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_CERTIFICATION UNIQUE (CSRIMP_SESSION_ID, NEW_CERTIFICATION_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_CERTIFICATION_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.CHAIN_CERTIFICATION (
	CSRIMP_SESSION_ID 			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CERTIFICATION_ID			NUMBER(10) NOT NULL,
	LABEL						VARCHAR2(1024) NOT NULL,
	LOOKUP_KEY					VARCHAR2(30),
	CONSTRAINT PK_CERTIFICATION PRIMARY KEY (CERTIFICATION_ID),
	CONSTRAINT FK_CERTIFICATION FOREIGN KEY
	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
	ON DELETE CASCADE
);
CREATE TABLE CSRIMP.CHAIN_CERT_AUD_TYPE (
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CERTIFICATION_ID			NUMBER(10) NOT NULL,
	INTERNAL_AUDIT_TYPE_ID		NUMBER(10) NOT NULL,
	CONSTRAINT PK_CERTIFICATION_AUDIT_TYPE PRIMARY KEY (CERTIFICATION_ID, INTERNAL_AUDIT_TYPE_ID),
	CONSTRAINT FK_CERTIFICATION_AUDIT_TYPE FOREIGN KEY
	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
	ON DELETE CASCADE
);
CREATE TABLE CSR.SHEET_COMPLETENESS_SHEET (
	APP_SID		NUMBER(10, 0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SHEET_ID	NUMBER(10, 0)		NOT NULL,
	CONSTRAINT PK_SHEET_COMPLETENESS_SHEET PRIMARY KEY (app_sid, sheet_id)
);
ALTER TABLE CSR.SHEET_COMPLETENESS_SHEET ADD CONSTRAINT FK_SHEET_COMPLETENESS_SHEET 
	FOREIGN KEY (APP_SID, SHEET_ID)
	REFERENCES CSR.SHEET(APP_SID, SHEET_ID)
;
BEGIN
	FOR r IN (
		SELECT DISTINCT app_sid, sheet_id
		  FROM csr.sheet_completeness_job
	)
	LOOP
		INSERT INTO csr.sheet_completeness_sheet
			(app_sid, sheet_id)
		VALUES
			(r.app_sid, r.sheet_id);
	END LOOP;
END;
/
DROP TABLE csr.sheet_completeness_job;
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_COMPLIANCE_LOG_IDS (
	FLOW_STATE_LOG_ID	NUMBER(10)		NOT NULL,
	AUDIT_DTM			DATE			NOT NULL
) ON COMMIT DELETE ROWS;
ALTER TABLE csr.compliance_item_region ADD (
	CONSTRAINT uk_comp_item_reg_flow_item_id UNIQUE (app_sid, flow_item_id)
);
CREATE SEQUENCE CSR.ISSUE_COMPLIANCE_REGION_ID_SEQ;
CREATE TABLE CSR.ISSUE_COMPLIANCE_REGION (
	APP_SID							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	ISSUE_COMPLIANCE_REGION_ID		NUMBER(10) NOT NULL,
	FLOW_ITEM_ID					NUMBER(10) NOT NULL,
	CONSTRAINT PK_ISSUE_COMPLIANCE_REGION PRIMARY KEY (APP_SID, ISSUE_COMPLIANCE_REGION_ID),
	CONSTRAINT FK_ISSUE_CMP_REG_CMP_ITM_REG FOREIGN KEY (APP_SID, FLOW_ITEM_ID)
		REFERENCES CSR.COMPLIANCE_ITEM_REGION (APP_SID, FLOW_ITEM_ID)
);
CREATE TABLE CSRIMP.ISSUE_COMPLIANCE_REGION (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ISSUE_COMPLIANCE_REGION_ID		NUMBER(10) NOT NULL,
	FLOW_ITEM_ID					NUMBER(10) NOT NULL,
	CONSTRAINT PK_ISSUE_COMPLIANCE_REGION PRIMARY KEY (CSRIMP_SESSION_ID, ISSUE_COMPLIANCE_REGION_ID),
	CONSTRAINT FK_ISSUE_COMPLIANCE_REGION_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
CREATE TABLE CSRIMP.MAP_ISSUE_COMPLIANCE_REGION (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ISSUE_COMPLIANCE_REGION_ID NUMBER(10) NOT NULL,
	NEW_ISSUE_COMPLIANCE_REGION_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_ISSUE_COMPLIANCE_REGION PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ISSUE_COMPLIANCE_REGION_ID) USING INDEX,
	CONSTRAINT UK_MAP_ISSUE_COMPLIANCE_REGION UNIQUE (CSRIMP_SESSION_ID, NEW_ISSUE_COMPLIANCE_REGION_ID) USING INDEX,
	CONSTRAINT FK_MAP_ISSUE_COMPLIANCE_REG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_EST_ERROR_INFO
(
	REGION_SID					NUMBER(10),
	PROP_REGION_SID				NUMBER(10),
	EST_ACCOUNT_SID				NUMBER(10),
	PM_CUSTOMER_ID				VARCHAR2(256),
	PM_BUILDING_ID				VARCHAR2(256),
	PM_SPACE_ID					VARCHAR2(256),
	PM_METER_ID					VARCHAR2(256),
	BUILDING_NAME				VARCHAR2(1024),
	SPACE_NAME					VARCHAR2(1024),
	METER_NAME					VARCHAR2(1024),
	ERROR_ID					NUMBER(10),
	ERROR_CODE					NUMBER(10),
	ERROR_COUNT					NUMBER(10),
	ERROR_MESSAGE				VARCHAR2(4000),
	ERROR_DTM					DATE
) ON COMMIT DELETE ROWS;
CREATE TABLE csr.compliance_root_regions (
	app_sid							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	region_sid						NUMBER(10,0) NOT NULL,
	region_type						NUMBER(2,0) NOT NULL,
	CONSTRAINT pk_compliance_root_regions PRIMARY KEY (app_sid, region_sid, region_type)
);
CREATE INDEX csr.ix_crr_rt ON csr.compliance_root_regions (app_sid, region_type);
CREATE TABLE csr.enhesa_options (
	app_sid							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	client_id						VARCHAR2(1024) NOT NULL,
	username						VARCHAR2(1024) NOT NULL,
	password						VARCHAR2(1024) NOT NULL,
	last_success					DATE,	
	last_run						DATE,
	last_message					VARCHAR2(1024),
	next_run						DATE,
	CONSTRAINT pk_enhesa_options PRIMARY KEY (app_sid)
);
CREATE TABLE csrimp.compliance_root_regions (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	region_sid						NUMBER(10,0) NOT NULL,
	region_type						NUMBER(2,0) NOT NULL,
	CONSTRAINT pk_compliance_root_regions PRIMARY KEY (csrimp_session_id, region_sid, region_type),
	CONSTRAINT fk_compliance_root_regions
		FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id) 
		ON DELETE CASCADE
);
CREATE TABLE csrimp.enhesa_options (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	client_id						VARCHAR2(1024) NOT NULL,
	username						VARCHAR2(1024) NOT NULL,
	password						VARCHAR2(1024) NOT NULL,
	last_success					DATE,	
	last_run						DATE,
	last_message					VARCHAR2(1024),
	next_run						DATE,
	CONSTRAINT pk_enhesa_options PRIMARY KEY (csrimp_session_id),
	CONSTRAINT fk_enhesa_options
		FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id) 
		ON DELETE CASCADE
);
CREATE TABLE chain.dedupe_sub (
    dedupe_sub_id		NUMBER(10) NOT NULL,
    app_sid				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	pattern            	VARCHAR2(1000) NOT NULL, 
	substitution        VARCHAR2(1000) NOT NULL, 
	proc_pattern        VARCHAR2(1000), 
	proc_substitution   VARCHAR2(1000), 
	updated_dtm         DATE,
    CONSTRAINT pk_dedupe_sub PRIMARY KEY (dedupe_sub_id)
);
COMMENT ON TABLE chain.dedupe_sub IS 'desc="Deduplication CMS table for holding alternative strings for matching"';
COMMENT ON COLUMN chain.dedupe_sub.app_sid IS 'app';
COMMENT ON COLUMN chain.dedupe_sub.dedupe_sub_id IS 'desc="Id",auto';
COMMENT ON COLUMN chain.dedupe_sub.pattern IS 'desc="Pattern"';
COMMENT ON COLUMN chain.dedupe_sub.substitution IS 'desc="Substitution"';
COMMENT ON COLUMN chain.dedupe_sub.proc_pattern IS 'desc="Pre-processed pattern"';
COMMENT ON COLUMN chain.dedupe_sub.proc_substitution IS 'desc="Pre-processed substitution"';
COMMENT ON COLUMN chain.dedupe_sub.updated_dtm iS 'desc="Updated date"';
CREATE TABLE CSRIMP.CHAIN_DEDUPE_SUB (
    CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    DEDUPE_SUB_ID NUMBER(10) NOT NULL,
    PATTERN VARCHAR2(1000) NOT NULL,
    SUBSTITUTION VARCHAR2(1000) NOT NULL,
    PROC_PATTERN VARCHAR2(1000),
    PROC_SUBSTITUTION VARCHAR2(1000),
    UPDATED_DTM DATE,
    CONSTRAINT PK_CHAIN_DEDUPE_SUB PRIMARY KEY (CSRIMP_SESSION_ID, DEDUPE_SUB_ID),
    CONSTRAINT FK_CHAIN_DEDUPE_SUB_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.MAP_CHAIN_DEDUPE_SUB (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CHAIN_DEDUPE_SUB_ID NUMBER(10) NOT NULL,
	NEW_CHAIN_DEDUPE_SUB_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_DEDUPE_SUB PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CHAIN_DEDUPE_SUB_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_DEDUPE_SUB UNIQUE (CSRIMP_SESSION_ID, NEW_CHAIN_DEDUPE_SUB_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_DEDUPE_SUB_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);


declare
	v_exists number;
	v_sql varchar2(4000);
begin
	select count(*) into v_exists from all_objects where owner='CSR' and object_name='SCRAGFETCHOPTIONS' and object_type='TYPE';
	if v_exists = 0 then
		v_sql := '
CREATE OR REPLACE TYPE csr.ScragFetchOptions AS OBJECT
(
	app_sid						NUMBER(10),
	scenario_run_sid 			NUMBER(10),
	ind_sids					security.T_SID_TABLE,
	region_sids					security.T_SID_TABLE,
	start_dtm					DATE,
	end_dtm						DATE,
	period_set_id				NUMBER(10),
	period_interval_id			NUMBER(10),
	fetch_source_values			NUMBER(1),
	fetch_file_uploads			NUMBER(1),
	fetch_source_details		NUMBER(1),
	fixed_analysis_server		VARCHAR2(255),
	finder_broadcast_addresses	VARCHAR2(4000),
	CONSTRUCTOR FUNCTION ScragFetchOptions(
		ind_sids					security.T_SID_TABLE,
		region_sids					security.T_SID_TABLE,
		app_sid 					NUMBER DEFAULT SYS_CONTEXT(''SECURITY'', ''APP''),
		scenario_run_sid 			NUMBER DEFAULT NULL,
		start_dtm					DATE DEFAULT NULL,
		end_dtm						DATE DEFAULT NULL,
		period_set_id				NUMBER DEFAULT NULL,
		period_interval_id			NUMBER DEFAULT NULL,
		fetch_source_values			NUMBER DEFAULT 1,
		fetch_file_uploads			NUMBER DEFAULT 0,
		fetch_source_details 		NUMBER DEFAULT 0,
		fixed_analysis_server		VARCHAR2 DEFAULT NULL,
		finder_broadcast_addresses	VARCHAR2 DEFAULT NULL
	) RETURN SELF AS RESULT 
)';
		execute immediate v_sql;
	end if;
	select count(*) into v_exists from all_objects where owner='CSR' and object_name='SCRAGFETCHOPTIONS' and object_type='TYPE BODY';
	if v_exists = 0 then
		v_sql := '
CREATE OR REPLACE TYPE BODY csr.ScragFetchOptions AS
	CONSTRUCTOR FUNCTION ScragFetchOptions(
		ind_sids					security.T_SID_TABLE,
		region_sids					security.T_SID_TABLE,
		app_sid 					NUMBER DEFAULT SYS_CONTEXT(''SECURITY'', ''APP''),
		scenario_run_sid 			NUMBER DEFAULT NULL,
		start_dtm					DATE DEFAULT NULL,
		end_dtm						DATE DEFAULT NULL,
		period_set_id				NUMBER DEFAULT NULL,
		period_interval_id			NUMBER DEFAULT NULL,
		fetch_source_values			NUMBER DEFAULT 1,
		fetch_file_uploads			NUMBER DEFAULT 0,
		fetch_source_details 		NUMBER DEFAULT 0,
		fixed_analysis_server		VARCHAR2 DEFAULT NULL,
		finder_broadcast_addresses	VARCHAR2 DEFAULT NULL
	) RETURN SELF AS RESULT AS
	BEGIN
		self.app_sid := app_sid;
		self.scenario_run_sid := scenario_run_sid;
		self.ind_sids := ind_sids;
		self.region_sids := region_sids;
		self.start_dtm := start_dtm;
		self.end_dtm := end_dtm;
		self.period_set_id := period_set_id;
		self.period_interval_id := period_interval_id;
		self.fetch_source_values := fetch_source_values;
		self.fetch_file_uploads	:= fetch_file_uploads;
		self.fetch_source_details := fetch_source_details;
		self.fixed_analysis_server := fixed_analysis_server;
		self.finder_broadcast_addresses := finder_broadcast_addresses;
		RETURN;
	END;
END;';
		execute immediate v_sql;
	end if;
	select count(*) into v_exists from all_objects where owner='CSR' and object_name='SOURCEVALROW' and object_type='TYPE';
	if v_exists = 0 then
		v_sql := '
CREATE OR REPLACE TYPE csr.SourceValRow AS OBJECT
(
	ind_sid							NUMBER(10),
	region_sid						NUMBER(10),
	period_start_dtm				DATE,
	period_end_dtm					DATE,
	val_number						NUMBER(24, 10),
	error_code						NUMBER(10),
	source_type_id					NUMBER(10),
	source_id						NUMBER(10),
	val_id							NUMBER(20),
	entry_measure_conversion_id		NUMBER(10),
	entry_val_number				NUMBER(24, 10),
	is_merged						NUMBER(1),
	note							CLOB,
	var_expl_note					CLOB,
	changed_dtm						DATE,
	changed_by_sid					NUMBER(10)
)';
		execute immediate v_sql;
	end if;
	select count(*) into v_exists from all_objects where owner='CSR' and object_name='SOURCEVALTABLE' and object_type='TYPE';
	if v_exists = 0 then
		v_sql := '
CREATE OR REPLACE TYPE csr.SourceValTable AS TABLE OF SourceValRow;
';
		execute immediate v_sql;
	end if;
	select count(*) into v_exists from all_objects where owner='CSR' and object_name='SCRAGQUERY' and object_type='TYPE';
	if v_exists = 0 then
		v_sql := '
CREATE OR REPLACE TYPE csr.ScragQuery AS OBJECT
(
	key INTEGER,
	STATIC FUNCTION ODCITableStart(
		sctx 					OUT ScragQuery,
		options					IN	ScragFetchOptions
	)
		RETURN NUMBER
		AS LANGUAGE JAVA
		NAME ''ScragQuery.ODCITableStart(java.sql.Struct[], java.sql.Struct) return java.math.BigDecimal'',
	MEMBER FUNCTION ODCITableFetch(self IN OUT ScragQuery, nrows IN NUMBER,
																 outSet OUT SourceValTable) RETURN NUMBER
		AS LANGUAGE JAVA
		NAME ''ScragQuery.ODCITableFetch(java.math.BigDecimal, java.sql.Array[]) return java.math.BigDecimal'',
	MEMBER FUNCTION ODCITableClose(self IN ScragQuery) RETURN NUMBER
		AS LANGUAGE JAVA
		NAME ''ScragQuery.ODCITableClose() return java.math.BigDecimal''
)';
		execute immediate v_sql;
	end if;
	select count(*) into v_exists from all_objects where owner='CSR' and object_name='SCRAG' and object_type='FUNCTION';
	if v_exists = 0 then
		v_sql := '
CREATE OR REPLACE FUNCTION csr.Scrag(
	options		ScragFetchOptions
)
RETURN csr.SourceValTable
PIPELINED USING csr.ScragQuery;
';
		execute immediate v_sql;
	end if;
	select count(*) into v_exists from all_objects where owner='CSR' and object_name='SCRAG2' and object_type='FUNCTION';
	if v_exists = 0 then
		v_sql := '
CREATE OR REPLACE FUNCTION csr.Scrag2(
	options		csr.ScragFetchOptions
)
RETURN csr.SourceValTable
AS LANGUAGE JAVA NAME ''ScragQuery.Query(java.sql.Struct) return java.sql.Array'';
';
		execute immediate v_sql;
	end if;
	select count(*) into v_exists from all_objects where owner='CSR' and object_name='SCRAG_CONFIG' and object_type='TABLE';
	if v_exists = 0 then
		v_sql := '
CREATE TABLE CSR.SCRAG_CONFIG
(
	FIXED_ANALYSIS_SERVER			VARCHAR2(255),
	FINDER_BROADCAST_ADDRESSES 		VARCHAR2(4000),
	ONLY_ONE_ROW NUMBER(1) CHECK (ONLY_ONE_ROW = 0),
	CONSTRAINT PK_SCRAG_CONFIG PRIMARY KEY (ONLY_ONE_ROW)
)';
		execute immediate v_sql;
	end if;
	dbms_java.grant_permission( 'CSR', 'SYS:java.net.SocketPermission', '*', 'accept,connect,listen,resolve' );
end;
/
ALTER TABLE chain.customer_options ADD (
	show_extra_details_in_graph				NUMBER(1) DEFAULT 0 NOT NULL
);
ALTER TABLE chain.customer_options ADD CONSTRAINT chk_show_ext_det_in_grph CHECK (show_extra_details_in_graph IN (0,1));
ALTER TABLE csrimp.chain_customer_options ADD (
	show_extra_details_in_graph				NUMBER(1) DEFAULT 0 NOT NULL
);
alter table csr.plugin add card_group_id number(10);
grant references on chain.card_group to csr;
alter table csr.plugin add constraint fk_plugin_chain_card_group foreign key (card_group_id) references chain.card_group (card_group_id);
create index csr.ix_plugin_card_group_id on csr.plugin (card_group_id);
ALTER TABLE csr.user_measure_conversion ADD CONSTRAINT pk_user_measure_conversion PRIMARY KEY (app_sid, csr_user_sid, measure_sid);
ALTER TABLE csr.user_measure_conversion MODIFY app_sid DEFAULT SYS_CONTEXT('SECURITY', 'APP');
ALTER TABLE csr.user_measure_conversion MODIFY measure_conversion_id NOT NULL;
ALTER TABLE CSR.USER_MEASURE_CONVERSION ADD CONSTRAINT FK_MSRE_CONV_USER_MSRE_CONV
    FOREIGN KEY (APP_SID, MEASURE_SID, MEASURE_CONVERSION_ID)
    REFERENCES CSR.MEASURE_CONVERSION(APP_SID, MEASURE_SID, MEASURE_CONVERSION_ID)
;
ALTER TABLE CSR.USER_MEASURE_CONVERSION ADD CONSTRAINT FK_USER_USED_MEASURE_CONV
    FOREIGN KEY (APP_SID, CSR_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;
create index csr.ix_user_mea_measure_conv on csr.user_measure_conversion (app_sid, measure_conversion_id, measure_sid);
create index csr.ix_user_measure_user on csr.user_measure_conversion (app_sid, csr_user_sid);
DELETE FROM csrimp.last_used_measure_conversion WHERE measure_conversion_id IS NULL;
ALTER TABLE csrimp.last_used_measure_conversion RENAME TO user_measure_conversion;
ALTER TABLE csrimp.user_measure_conversion MODIFY measure_conversion_id NOT NULL;
ALTER TABLE CSRIMP.USER_MEASURE_CONVERSION DROP CONSTRAINT PK_LAST_USED_MEASURE_CONV;
ALTER TABLE CSRIMP.USER_MEASURE_CONVERSION ADD CONSTRAINT PK_USER_MEASURE_CONVERSION
	PRIMARY KEY (CSRIMP_SESSION_ID, CSR_USER_SID, MEASURE_SID);
ALTER TABLE CSRIMP.USER_MEASURE_CONVERSION DROP CONSTRAINT FK_LAST_USED_MEAS_CONV_IS;
ALTER TABLE CSRIMP.USER_MEASURE_CONVERSION ADD CONSTRAINT FK_USER_MEASURE_CONV_IS FOREIGN KEY
	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
	ON DELETE CASCADE;
ALTER TABLE csr.last_used_measure_conversion DROP CONSTRAINT FK_MEASURE_LAST_USED_MEASURE;
ALTER TABLE csr.last_used_measure_conversion DROP CONSTRAINT FK_MSRE_CONV_LAST_USED_MSRE;
ALTER TABLE csr.last_used_measure_conversion DROP CONSTRAINT FK_USER_LAST_USED_MEASURE;
ALTER TABLE csr.last_used_measure_conversion RENAME TO xx_last_used_measure_conv;
ALTER TABLE CHAIN.PRODUCT_TYPE ADD (
	NODE_TYPE					NUMBER(10, 0) 	DEFAULT 0 NOT NULL,
	ACTIVE						NUMBER(1, 0) 	DEFAULT 1 NOT NULL,
	CONSTRAINT CHK_NODE_TYPE CHECK (NODE_TYPE >= 0 AND NODE_TYPE <= 1),
	CONSTRAINT CHK_ACTIVE CHECK (ACTIVE IN (0,1))
);
ALTER TABLE CSRIMP.CHAIN_PRODUCT_TYPE ADD (
	NODE_TYPE					NUMBER(10, 0) 	DEFAULT 0 NOT NULL,
	ACTIVE						NUMBER(1, 0) 	DEFAULT 1 NOT NULL
);
ALTER TABLE csr.supplier_score_log
  ADD score_source_type NUMBER(10);
ALTER TABLE csr.supplier_score_log
  ADD score_source_id NUMBER(10);
ALTER TABLE csrimp.supplier_score_log
  ADD score_source_type NUMBER(10);
ALTER TABLE csrimp.supplier_score_log
  ADD score_source_id NUMBER(10);
CREATE OR REPLACE TYPE CHAIN.T_DEDUPE_COMPANY_ROW AS
	OBJECT (
		NAME				VARCHAR2(255),
		PARENT_COMPANY_NAME	VARCHAR2(255),
		COMPANY_TYPE		VARCHAR2(255),
		CREATED_DTM			DATE,
		ACTIVATED_DTM		DATE,
		ACTIVE				NUMBER(1),
		ADDRESS				VARCHAR2(1024),
		ADDRESS_1			VARCHAR2(255),
		ADDRESS_2			VARCHAR2(255),
		ADDRESS_3			VARCHAR2(255),
		ADDRESS_4			VARCHAR2(255),
		STATE				VARCHAR2(255),
		POSTCODE			VARCHAR2(32),
		COUNTRY_CODE		VARCHAR2(255),
		PHONE				VARCHAR2(255),
		FAX					VARCHAR2(255),
		WEBSITE				VARCHAR2(255),
		EMAIL				VARCHAR2(255),
		DELETED				NUMBER(1),
		SECTOR				VARCHAR2(255),
		CITY				VARCHAR2(255),
		DEACTIVATED_DTM		DATE,
		CONSTRUCTOR FUNCTION T_DEDUPE_COMPANY_ROW
		RETURN self AS RESULT
	);
/
CREATE OR REPLACE TYPE BODY CHAIN.T_DEDUPE_COMPANY_ROW AS
  CONSTRUCTOR FUNCTION T_DEDUPE_COMPANY_ROW
	RETURN SELF AS RESULT
	AS
	BEGIN
		RETURN;
	END;
END;
/
ALTER TABLE CSR.ISSUE DROP CONSTRAINT CHK_ISSUE_FKS;
ALTER TABLE CSR.ISSUE ADD (
	ISSUE_COMPLIANCE_REGION_ID		NUMBER(10),
	CONSTRAINT FK_ISS_ISS_COMPL_REG FOREIGN KEY (APP_SID, ISSUE_COMPLIANCE_REGION_ID)
		REFERENCES CSR.ISSUE_COMPLIANCE_REGION (APP_SID, ISSUE_COMPLIANCE_REGION_ID),
	CONSTRAINT CHK_ISSUE_FKS CHECK (
		CASE WHEN ISSUE_PENDING_VAL_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_SHEET_VALUE_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_SURVEY_ANSWER_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_NON_COMPLIANCE_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_ACTION_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_METER_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_METER_ALARM_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_METER_RAW_DATA_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_METER_DATA_SOURCE_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_METER_MISSING_DATA_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_SUPPLIER_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_INITIATIVE_ID IS NOT NULL THEN 1 ELSE 0 END + 
		CASE WHEN ISSUE_COMPLIANCE_REGION_ID IS NOT NULL THEN 1 ELSE 0 END
		IN (0, 1)
	)
);
ALTER TABLE CSRIMP.ISSUE DROP CONSTRAINT CHK_ISSUE_FKS;
ALTER TABLE CSRIMP.ISSUE ADD (
	ISSUE_COMPLIANCE_REGION_ID		NUMBER(10),
	CONSTRAINT CHK_ISSUE_FKS CHECK (
		CASE WHEN ISSUE_PENDING_VAL_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_SHEET_VALUE_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_SURVEY_ANSWER_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_NON_COMPLIANCE_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_ACTION_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_METER_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_METER_ALARM_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_METER_RAW_DATA_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_METER_DATA_SOURCE_ID IS NOT NULL THEN 1 ELSE 0 END +		
		-- pending new columns
		-- CASE WHEN ISSUE_METER_MISSING_DATA_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_SUPPLIER_ID IS NOT NULL THEN 1 ELSE 0 END +
		-- CASE WHEN ISSUE_INITIATIVE_ID IS NOT NULL THEN 1 ELSE 0 END
		CASE WHEN ISSUE_COMPLIANCE_REGION_ID IS NOT NULL THEN 1 ELSE 0 END
		IN (0, 1)
	)
);
ALTER TABLE csr.temp_issue_search ADD (
	ISSUE_COMPLIANCE_REGION_ID	NUMBER(10)
);
CREATE INDEX csr.ix_issue_issue_complia ON csr.issue (app_sid, issue_compliance_region_id);
CREATE INDEX csr.ix_issue_complia_flow_item_id ON csr.issue_compliance_region (app_sid, flow_item_id);
ALTER TABLE CSRIMP.qs_expr_non_compl_action MODIFY ASSIGN_TO_ROLE_SID NULL;
ALTER TABLE CSRIMP.chain_dedupe_rule DROP COLUMN IS_FUZZY;
ALTER TABLE csr.compliance_root_regions ADD (
	CONSTRAINT fk_crr_r
		FOREIGN KEY (app_sid, region_sid)
		REFERENCES csr.region (app_sid, region_sid),
	CONSTRAINT fk_crr_crt
		FOREIGN KEY (app_sid, region_type)
		REFERENCES csr.customer_region_type (app_sid, region_type)
);
ALTER TABLE csr.compliance_item ADD (
	rollout_dtm						DATE,
	rollout_pending					NUMBER(1) DEFAULT 0 NOT NULL,
	lookup_key						VARCHAR2(1024),
	CONSTRAINT ck_rollout_pending CHECK (rollout_pending IN (0, 1))
);
CREATE UNIQUE INDEX csr.uk_ci_lookup_key ON csr.compliance_item (app_sid,NVL(lookup_key, compliance_item_id));
ALTER TABLE csr.compliance_options ADD (
	rollout_delay					NUMBER(5) DEFAULT 15 NOT NULL
);
ALTER TABLE csr.compliance_regulation ADD (
	external_id						NUMBER(10)
);
ALTER TABLE csrimp.compliance_item ADD (
	rollout_dtm						DATE,
	rollout_pending					NUMBER(1) NOT NULL,
	lookup_key						VARCHAR2(1024)
);
ALTER TABLE csrimp.compliance_options ADD (
	requirement_flow_sid			NUMBER(10) NOT NULL,
	regulation_flow_sid				NUMBER(10) NOT NULL,
	rollout_delay					NUMBER(5) NOT NULL
);
ALTER TABLE csrimp.compliance_regulation ADD (
	external_id						NUMBER(10)
);
CREATE OR REPLACE TYPE CSR.T_COMPLIANCE_ROLLOUT_ITEM AS
	OBJECT (
		COMPLIANCE_ITEM_ID			NUMBER(10),
		REGION_SID					NUMBER(10)
	);
/
CREATE OR REPLACE TYPE CSR.T_COMPLIANCE_ROLLOUT_TABLE AS
	TABLE OF CSR.T_COMPLIANCE_ROLLOUT_ITEM;
/
ALTER TABLE csr.compliance_item_change_type ADD (
	enhesa_id					NUMBER(10),
	CONSTRAINT CK_ENHESA_CT CHECK (enhesa_id IS NULL OR (enhesa_id IS NOT NULL AND SOURCE = 1))	
);
DROP INDEX csr.IX_CI_TITLE_SEARCH; 
DROP INDEX csr.IX_CI_CITATION_SEARCH;
DROP INDEX csr.IX_CI_SUMMARY_SEARCH;
ALTER TABLE csr.compliance_item MODIFY (
	title						VARCHAR2(1024),
	citation					VARCHAR2(4000),
	summary						VARCHAR2(4000)
);
grant create table to csr;
create index csr.IX_CI_TITLE_SEARCH on csr.compliance_item(title) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');
create index csr.IX_CI_CITATION_SEARCH on csr.compliance_item(citation) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');
create index csr.IX_CI_SUMMARY_SEARCH on csr.compliance_item(summary) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');
create index csr.IX_CI_LOOKUP_SEARCH on csr.compliance_item(lookup_key) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');
revoke create table from csr;

BEGIN
	EXECUTE IMMEDIATE 'DROP INDEX dustan.uk_compliance_item_ref';
EXCEPTION
	WHEN OTHERS THEN 
		NULL;
END;
/

BEGIN
	FOR r IN (
		SELECT 1
		  FROM all_constraints
		 WHERE constraint_name = 'UK_REFERENCE_CODE'
		   AND owner = 'CSR'
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE csr.compliance_item DROP CONSTRAINT UK_REFERENCE_CODE';
	END LOOP;
END;
/
CREATE UNIQUE INDEX csr.uk_compliance_item_ref ON csr.compliance_item (
	app_sid,
	decode(source, 0, NVL(reference_code, compliance_item_id), compliance_item_id)
);
ALTER TABLE chain.dedupe_sub ADD CONSTRAINT fk_cust_opt_dedupe_sub
    FOREIGN KEY (app_sid)
    REFERENCES chain.customer_options(app_sid);
CREATE UNIQUE INDEX uk_dedupe_sub_patt_sub ON chain.dedupe_sub (app_sid, LOWER(TRIM(pattern)), LOWER(TRIM(substitution)));


grant insert on csr.user_measure_conversion to csrimp;
grant select,insert,update,delete on csrimp.user_measure_conversion to tool_user;
GRANT SELECT ON csr.v$customer_lang TO chain;
grant select on chain.certification_id_seq to csrimp;
grant select on chain.certification to csr;
grant select on chain.certification_audit_type to csr;
grant select, insert, update on chain.certification to csrimp;
grant select, insert, update on chain.certification_audit_type to csrimp;
GRANT SELECT ON csr.tpl_report_tag_dataview TO chain;
GRANT SELECT ON csr.tpl_report_tag_logging_form TO chain;
grant select,insert,update,delete on csrimp.issue_compliance_region to tool_user;
grant select on csr.issue_compliance_region_id_seq to csrimp;
grant insert on csr.issue_compliance_region to csrimp;
GRANT SELECT ON chain.dedupe_sub TO csr;
GRANT SELECT, INSERT, UPDATE on chain.dedupe_sub TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.chain_dedupe_sub TO tool_user;


ALTER TABLE CHAIN.CERTIFICATION_AUDIT_TYPE ADD CONSTRAINT FK_CERT_AUDIT_TYPE_AUDIT_TYPE 
	FOREIGN KEY (APP_SID, INTERNAL_AUDIT_TYPE_ID)
	REFERENCES CSR.INTERNAL_AUDIT_TYPE(APP_SID, INTERNAL_AUDIT_TYPE_ID)
;
CREATE INDEX CHAIN.IX_CERT_AUDIT_TYPE ON CHAIN.CERTIFICATION_AUDIT_TYPE (APP_SID, INTERNAL_AUDIT_TYPE_ID);
 
GRANT SELECT, INSERT, UPDATE ON csr.compliance_root_regions TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.enhesa_options TO csrimp;


CREATE OR REPLACE VIEW chain.v$product_type AS
	SELECT pt.app_sid, pt.product_type_id, pt.parent_product_type_id, pttr.description, pt.lookup_key, pt.node_type, pt.active
	  FROM product_type pt, product_type_tr pttr
	 WHERE pt.app_sid = pttr.app_sid AND pt.product_type_id = pttr.product_type_id
	   AND pttr.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');
CREATE OR REPLACE VIEW csr.v$supplier_score AS
	SELECT css.app_sid, css.company_sid, css.score_type_id, css.last_supplier_score_id,
		   ss.score, ss.set_dtm score_last_changed, ss.score_threshold_id,
		   ss.changed_by_user_sid, cu.full_name changed_by_user_full_name, ss.comment_text,
		   st.description score_threshold_description, t.label score_type_label, t.pos,
		   t.format_mask, ss.valid_until_dtm, CASE WHEN ss.valid_until_dtm IS NULL OR ss.valid_until_dtm >= SYSDATE THEN 1 ELSE 0 END valid,
		   ss.score_source_type, ss.score_source_id
	  FROM csr.current_supplier_score css
	  JOIN csr.supplier_score_log ss ON css.company_sid = ss.supplier_sid AND css.last_supplier_score_id = ss.supplier_score_id
	  LEFT JOIN csr.score_threshold st ON ss.score_threshold_id = st.score_threshold_id
	  JOIN csr.score_type t ON css.score_type_id = t.score_type_id
	  LEFT JOIN csr.csr_user cu ON ss.changed_by_user_sid = cu.csr_user_sid;
	  
CREATE OR REPLACE VIEW chain.v$supplier_certification AS
	SELECT cat.app_sid, cat.certification_id, ia.internal_audit_sid, s.company_sid, ia.internal_audit_type_id, ia.audit_dtm valid_from_dtm,
		   CASE (atct.re_audit_due_after_type)
				WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
				WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
				WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
				WHEN 'y' THEN nvl(ia.ovw_validity_dtm, add_months(ia.audit_dtm, atct.re_audit_due_after*12))
				ELSE ia.ovw_validity_dtm 
			END expiry_dtm, atct.audit_closure_type_id 
	FROM chain.certification_audit_type cat 
	JOIN csr.internal_audit ia ON ia.internal_audit_type_id = cat.internal_audit_type_id
	 AND cat.app_sid = ia.app_sid
	 AND ia.deleted = 0
	JOIN csr.supplier s  ON ia.region_sid = s.region_sid AND s.app_sid = ia.app_sid
	JOIN csr.audit_type_closure_type atct ON ia.audit_closure_type_id = atct.audit_closure_type_id 
	 AND ia.internal_audit_type_id = atct.internal_audit_type_id
	 AND ia.app_sid = atct.app_sid
	JOIN csr.audit_closure_type act ON atct.audit_closure_type_id = act.audit_closure_type_id 
	 AND act.is_failure = 0
	 AND act.app_sid = atct.app_sid;
CREATE OR REPLACE VIEW csr.v$flow_item_transition AS 
  SELECT fst.app_sid, fi.flow_sid, fi.flow_item_Id, fst.flow_state_transition_id, fst.verb,
		 fs.flow_state_id from_state_id, fs.label from_state_label, fs.state_colour from_state_colour,
		 tfs.flow_state_id to_state_id, tfs.label to_state_label, tfs.state_colour to_state_colour,
		 fst.ask_for_comment, fst.pos transition_pos, fst.button_icon_path,
		 tfs.flow_state_nature_id,
		 fi.survey_response_id, fi.dashboard_instance_id -- these are deprecated
      FROM flow_item fi
		JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid
		JOIN flow_state_transition fst ON fs.flow_state_id = fst.from_state_id AND fs.app_sid = fst.app_sid
		JOIN flow_state tfs ON fst.to_state_id = tfs.flow_state_id AND fst.app_sid = tfs.app_sid AND tfs.is_deleted = 0;
  CREATE OR REPLACE VIEW csr.v$flow_item_trans_role_member AS 
  SELECT fit.app_sid,fit.flow_sid,fit.flow_item_id,fit.flow_state_transition_id,fit.verb,fit.from_state_id,fit.from_state_label,
  		 fit.from_state_colour,fit.to_state_id,fit.to_state_label,fit.to_state_colour,fit.ask_for_comment,fit.transition_pos,
		 fit.button_icon_path,fit.survey_response_id,fit.dashboard_instance_id, r.role_sid, r.name role_name, rrm.region_sid, fit.flow_state_nature_id
	FROM v$flow_item_transition fit
		 JOIN flow_state_transition_role fstr ON fit.flow_state_transition_id = fstr.flow_state_transition_id AND fit.app_sid = fstr.app_sid
		 JOIN role r ON fstr.role_sid = r.role_sid AND fstr.app_sid = r.app_sid
		 JOIN region_role_member rrm ON r.role_sid = rrm.role_sid AND r.app_sid = rrm.app_sid
   WHERE rrm.user_sid = SYS_CONTEXT('SECURITY','SID');
CREATE OR REPLACE VIEW csr.v$issue AS
SELECT i.app_sid, NVL2(i.issue_ref, ist.internal_issue_ref_prefix || i.issue_ref, null) custom_issue_id, i.issue_id, i.label, i.description, i.source_label, i.is_visible, i.source_url, i.region_sid, re.description region_name, i.parent_id,
	   i.issue_escalated, i.owner_role_sid, i.owner_user_sid, cuown.user_name owner_user_name, cuown.full_name owner_full_name, cuown.email owner_email,
	   r2.name owner_role_name, i.first_issue_log_id, i.last_issue_log_id, NVL(lil.logged_dtm, i.raised_dtm) last_modified_dtm,
	   i.is_public, i.is_pending_assignment, i.rag_status_id, i.manual_completion_dtm, manual_comp_dtm_set_dtm, itrs.label rag_status_label, itrs.colour rag_status_colour,
	   raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
	   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
	   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
	   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
	   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
	   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, 
	   c.more_info_1 correspondent_more_info_1, sysdate now_dtm, due_dtm, forecast_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, 
	   ist.allow_children, ist.can_set_public, ist.show_forecast_dtm, ist.require_var_expl, ist.enable_reject_action, ist.require_due_dtm_comment, 
	   ist.enable_manual_comp_date, ist.comment_is_optional, ist.due_date_is_mandatory, ist.is_region_editable is_issue_type_region_editable, i.issue_priority_id, 
	   ip.due_date_offset, ip.description priority_description,
	   CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden, 
	   i.first_priority_set_dtm, issue_pending_val_id, i.issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id,
	   issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id, issue_meter_missing_data_id, issue_supplier_id, issue_compliance_region_id,
	   CASE WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND rejected_by_user_sid IS NULL AND SYSDATE > NVL(forecast_dtm, due_dtm) THEN 1 ELSE 0
	   END is_overdue,
	   CASE WHEN rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID') OR i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0
	   END is_owner,
	   CASE WHEN assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0 --OR #### HOW + WHERE CAN I GET THE ROLES THE USER IS PART OF??
	   END is_assigned_to_you,
	   CASE WHEN i.resolved_dtm IS NULL AND i.manual_completion_dtm IS NULL THEN 0 ELSE 1
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
	   END status,
	   CASE WHEN ist.auto_close_after_resolve_days IS NULL THEN NULL ELSE i.allow_auto_close END allow_auto_close, ist.auto_close_after_resolve_days,
	   ist.restrict_users_to_region, ist.deletable_by_administrator, ist.deletable_by_owner, ist.deletable_by_raiser, ist.send_alert_on_issue_raised,
	   ind.ind_sid, ind.description ind_name, isv.start_dtm, isv.end_dtm, ist.owner_can_be_changed, ist.show_one_issue_popup, ist.lookup_key, ist.allow_owner_resolve_and_close,
	   CASE WHEN ist.get_assignables_sp IS NULL THEN 0 ELSE 1 END get_assignables_overridden, ist.create_raw
  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user curej, csr_user cuass, csr_user cuown,  role r, role r2, correspondent c, issue_priority ip,
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
   AND i.app_sid = r2.app_sid(+) AND i.owner_role_sid = r2.role_sid(+)
   AND i.app_sid = re.app_sid(+) AND i.region_sid = re.region_sid(+)
   AND i.app_sid = c.app_sid(+) AND i.correspondent_id = c.correspondent_id(+)
   AND i.app_sid = ip.app_sid(+) AND i.issue_priority_id = ip.issue_priority_id(+)
   AND i.app_sid = rrm.app_sid(+) AND i.region_sid = rrm.region_sid(+) AND i.owner_role_sid = rrm.role_sid(+)
   AND i.app_sid = lil.app_sid(+) AND i.last_issue_log_id = lil.issue_log_id(+)
   AND i.app_sid = itrs.app_sid(+) AND i.rag_status_id = itrs.rag_status_id(+) AND i.issue_type_id = itrs.issue_type_id(+)
   AND i.app_sid = isv.app_sid(+) AND i.issue_sheet_value_id = isv.issue_sheet_value_id(+)
   AND isv.app_sid = ind.app_sid(+) AND isv.ind_sid = ind.ind_sid(+)
   AND i.deleted = 0;




DECLARE
	v_invsumm_id 			chain.card.card_id%TYPE;
	v_invsummwcheck_id		chain.card.card_id%TYPE;
BEGIN
	security.user_pkg.LogonAdmin;
	SELECT card_id
	  INTO v_invsumm_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.InvitationSummary';
	SELECT card_id
	  INTO v_invsummwcheck_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.InvitationSummaryWithCheck';
	 
	FOR rec IN (SELECT * 
				  FROM chain.card_group_card
				 WHERE card_id = v_invsummwcheck_id)
	LOOP
		INSERT INTO chain.card_group_card
		(app_sid, card_group_id, card_id, position, required_permission_set, invert_capability_check, required_capability_id, force_terminate)
		VALUES
		(rec.app_sid, rec.card_group_id, v_invsumm_id, rec.position, rec.required_permission_set, rec.invert_capability_check, rec.required_capability_id, rec.force_terminate);
		UPDATE chain.card_group_progression
		   SET from_card_id = v_invsumm_id
		 WHERE app_sid = rec.app_sid
		   AND card_group_id = rec.card_group_id
		   AND from_card_id = v_invsummwcheck_id;
		UPDATE chain.card_group_progression
		   SET to_card_id = v_invsumm_id
		 WHERE app_sid = rec.app_sid
		   AND card_group_id = rec.card_group_id
		   AND to_card_id = v_invsummwcheck_id;
		DELETE FROM chain.card_group_card
		 WHERE app_sid = rec.app_sid
		   AND card_group_id = rec.card_group_id
		   AND card_id = v_invsummwcheck_id;
	END LOOP;
DELETE FROM chain.card_progression_action
 WHERE card_id = v_invsummwcheck_id;
DELETE FROM chain.card
 WHERE card_id = v_invsummwcheck_id;
END;
/
BEGIN
	security.user_pkg.logonadmin;
END;
/
DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	v_desc := 'Business Relationship Filter';
	v_class := 'Credit360.Chain.Cards.Filters.BusinessRelationshipFilter';
	v_js_path := '/csr/site/chain/cards/filters/businessRelationshipFilter.js';
	v_js_class := 'Chain.Cards.Filters.BusinessRelationshipFilter';
	v_css_path := '';
	
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card
			SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
			WHERE js_class_type = v_js_class
			RETURNING card_id INTO v_card_id;
	END;
	
	DELETE FROM chain.card_progression_action
	WHERE card_id = v_card_id
	AND action NOT IN ('default');
	
	v_actions := chain.T_STRING_LIST('default');
	
	FOR i IN v_actions.FIRST .. v_actions.LAST
	LOOP
		BEGIN
			INSERT INTO chain.card_progression_action (card_id, action)
			VALUES (v_card_id, v_actions(i));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
	v_desc := 'Business Relationship Filter Adapter';
	v_class := 'Credit360.Chain.Cards.Filters.BusinessRelationshipFilterAdapter';
	v_js_path := '/csr/site/chain/cards/filters/businessRelationshipFilterAdapter.js';
	v_js_class := 'Chain.Cards.Filters.BusinessRelationshipFilterAdapter';
	v_css_path := '';
	
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card
			SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
			WHERE js_class_type = v_js_class
			RETURNING card_id INTO v_card_id;
	END;
	
	DELETE FROM chain.card_progression_action
	WHERE card_id = v_card_id
	AND action NOT IN ('default');
	
	v_actions := chain.T_STRING_LIST('default');
	
	FOR i IN v_actions.FIRST .. v_actions.LAST
	LOOP
		BEGIN
			INSERT INTO chain.card_progression_action (card_id, action)
			VALUES (v_card_id, v_actions(i));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
	v_desc := 'Company Business Relationship Filter Adapter';
	v_class := 'Credit360.Chain.Cards.Filters.CompanyBusinessRelationshipFilterAdapter';
	v_js_path := '/csr/site/chain/cards/filters/companyBusinessRelationshipFilterAdapter.js';
	v_js_class := 'Chain.Cards.Filters.CompanyBusinessRelationshipFilterAdapter';
	v_css_path := '';
	
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card
			SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
			WHERE js_class_type = v_js_class
			RETURNING card_id INTO v_card_id;
	END;
	
	DELETE FROM chain.card_progression_action
	WHERE card_id = v_card_id
	AND action NOT IN ('default');
	
	v_actions := chain.T_STRING_LIST('default');
	
	FOR i IN v_actions.FIRST .. v_actions.LAST
	LOOP
		BEGIN
			INSERT INTO chain.card_progression_action (card_id, action)
			VALUES (v_card_id, v_actions(i));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;
/
DECLARE
	v_card_id				NUMBER(10);
BEGIN
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES(53 /*chain.filter_pkg.FILTER_TYPE_BUS_RELS*/, 'Business Relationship Filter', 'Allows filtering of business relationships', 'chain.business_rel_report_pkg', '/csr/site/chain/businessRelationshipList.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.BusinessRelationshipFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Business Relationship Filter', 'chain.business_rel_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM chain.customer_options
	) LOOP
		BEGIN	
			INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
				 VALUES (r.app_sid, 53 /*chain.filter_pkg.FILTER_TYPE_BUS_RELS*/, v_card_id, 0);
			EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
		END;
	END LOOP;
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.BusinessRelationshipFilterAdapter';
	
	BEGIN
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Business Relationship Filter Adapter', 'chain.business_rel_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;	
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM chain.customer_options
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
				 VALUES (r.app_sid, 53 /*chain.filter_pkg.FILTER_TYPE_BUS_RELS*/, v_card_id, 0);
			EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
		END;
	END LOOP;
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.CompanyBusinessRelationshipFilterAdapter';
	
	BEGIN
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Chain Company Business Relationship Filter Adapter', 'chain.company_filter_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;	
	FOR r IN (
		SELECT DISTINCT app_sid, NVL(MAX(position) + 1, 1) pos
		   FROM chain.card_group_card
		  WHERE card_group_id = 23 /*chain.filter_pkg.FILTER_TYPE_COMPANIES*/
		  GROUP BY app_sid
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position, required_permission_set, required_capability_id)
				 VALUES (r.app_sid, 23 /*chain.filter_pkg.FILTER_TYPE_COMPANIES*/, v_card_id, r.pos, NULL, NULL);
			EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
		END;
	END LOOP;
END;
/
BEGIN
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (53 /*chain.filter_pkg.FILTER_TYPE_BUS_RELS*/, 1 /*chain.business_rel_report_pkg.AGG_TYPE_COUNT*/, 'Number of business relationships');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	BEGIN
		INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
		VALUES (53 /*chain.filter_pkg.FILTER_TYPE_BUS_RELS*/, 1 /*chain.business_rel_report_pkg.COL_TYPE_COMPANY_REGION*/, 1 /*chain.filter_pkg.COLUMN_TYPE_REGION*/, 'Company region');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/
DECLARE
	v_plugin_id			NUMBER(10);
BEGIN
	BEGIN
		SELECT plugin_id
		  INTO v_plugin_id
		  FROM csr.plugin
		 WHERE js_class = 'Chain.ManageCompany.BusinessRelationships';
		UPDATE csr.plugin
		   SET description = 'Business Relationship List',
			   js_include = '/csr/site/chain/managecompany/controls/BusinessRelationshipListTab.js',
			   js_class = 'Chain.ManageCompany.BusinessRelationshipListTab',
			   cs_class = 'Credit360.Chain.CompanyManagement.BusinessRelationshipListTab',
			   details = 'This tab displays a filterable and searchable table of all business relationships of which the supplier being viewed is a member, that the logged in user has permission to see.'
		 WHERE plugin_id = v_plugin_id;
	EXCEPTION
		WHEN no_data_found THEN
			BEGIN
				INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
				VALUES (csr.plugin_id_seq.NEXTVAL, 10, 'Business Relationship List', '/csr/site/chain/managecompany/controls/BusinessRelationshipListTab.js', 'Chain.ManageCompany.BusinessRelationshipListTab', 'Credit360.Chain.CompanyManagement.BusinessRelationshipListTab', 'This tab displays a filterable and searchable table of all business relationships of which the supplier being viewed is a member, that the logged in user has permission to see.');
			EXCEPTION
				WHEN dup_val_on_index THEN
					NULL;
			END;
	END;
END;
/
DECLARE
	v_company_filter_type_id	NUMBER(10);
	v_bus_rel_filter_type_id	NUMBER(10);
	v_company_fil_adp_type_id	NUMBER(10);
	v_bus_rel_fil_adp_type_id	NUMBER(10);
	v_business_rel_type_id		NUMBER(10);
	v_business_rel_type_label	VARCHAR2(255);
	v_company_comp_filt_id		NUMBER(10);
	v_company_filter_id			NUMBER(10);
	v_company_filt_field_id		NUMBER(10);
	v_bus_rel_comp_filt_id		NUMBER(10);
	v_bus_rel_adp_filter_id		NUMBER(10);
	v_bus_rel_adp_filt_field_id	NUMBER(10);
	v_bus_rel_typ_filter_id		NUMBER(10);
	v_bus_rel_typ_filt_field_id	NUMBER(10);
	
	v_filter_field_count		NUMBER;
	v_filter_id					NUMBER(10);
	v_filter_field_id			NUMBER(10);
BEGIN
	BEGIN
		SELECT filter_type_id
		  INTO v_company_filter_type_id
		  FROM chain.filter_type
		 WHERE description = 'Chain Core Filter';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- This is happening on CI build because the filter type is not in any change
			-- script. This script has probably already been run, so skip it for now, but
			-- we'll need another change script to add the missing filter types and then do
			-- this bit
			RETURN;
	END;
	SELECT filter_type_id
	  INTO v_bus_rel_filter_type_id
	  FROM chain.filter_type
	 WHERE description = 'Business Relationship Filter';
	 
	SELECT filter_type_id
	  INTO v_company_fil_adp_type_id
	  FROM chain.filter_type
	 WHERE description = 'Chain Company Business Relationship Filter Adapter';
	 
	SELECT filter_type_id
	  INTO v_bus_rel_fil_adp_type_id
	  FROM chain.filter_type
	 WHERE description = 'Business Relationship Filter Adapter';
	FOR site IN (
		SELECT c.host, c.app_sid
		  FROM csr.customer c 
		 WHERE EXISTS (
				SELECT null
				  FROM chain.filter_field ff
				 WHERE ff.app_sid = c.app_sid
				   AND ff.name LIKE 'BusinessRelationship.%'
		)
	) LOOP
		security.user_pkg.logonadmin(site.host);
		FOR r IN (
			SELECT cf.compound_filter_id, cf.created_by_user_sid, cf.card_group_id, cf.act_id,
				   f.filter_id, ff.filter_field_id, ff.name
			  FROM chain.filter_field ff
			  JOIN chain.filter f ON f.filter_id = ff.filter_id
			  JOIN chain.compound_filter cf ON cf.compound_filter_id = f.compound_filter_id
			 WHERE ff.app_sid = site.app_sid
			   AND ff.name LIKE 'BusinessRelationship.%'
			   AND cf.card_group_id = 23 /*chain.filter_pkg.FILTER_TYPE_COMPANIES*/
		) LOOP
			v_business_rel_type_id := TO_NUMBER(SUBSTR(r.name, 22));
			SELECT label 
			  INTO v_business_rel_type_label
			  FROM chain.business_relationship_type
			 WHERE business_relationship_type_id = v_business_rel_type_id;
			-- Create a compound filter that filters companies to the ones in the existing CF.
			INSERT INTO chain.compound_filter (
				compound_filter_id,
				operator_type,
				created_dtm,
				created_by_user_sid,
				card_group_id,
				act_id,
				read_only_saved_filter_sid,
				is_read_only_group_by
			) VALUES (
				chain.compound_filter_id_seq.nextval,
				'and',
				SYSDATE,
				r.created_by_user_sid,
				23, /*chain.filter_pkg.FILTER_TYPE_COMPANIES*/
				r.act_id,
				NULL,
				0
			)
			RETURNING compound_filter_id INTO v_company_comp_filt_id;
			INSERT INTO chain.filter (
				filter_id,
				filter_type_id,
				compound_filter_id,
				operator_type
			) VALUES (
				chain.filter_id_seq.nextval,
				v_company_filter_type_id, /* Company core */
				v_company_comp_filt_id,
				'and'
			) RETURNING filter_id INTO v_company_filter_id;
			INSERT INTO chain.filter_field (
				filter_field_id,
				filter_id,
				name,
				comparator
			) VALUES (
				chain.filter_field_id_seq.nextval,
				v_company_filter_id,
				'CompanySid',
				'equals'
			) RETURNING filter_field_id INTO v_company_filt_field_id;
			
			INSERT INTO chain.filter_value (
				filter_value_id,
				filter_field_id,
				num_value,
				description,
				pos
			) SELECT
				chain.filter_value_id_seq.nextval,
				v_company_filt_field_id,
				num_value,
				description,
				pos
			FROM chain.filter_value WHERE filter_field_id = r.filter_field_id;
			-- Create a business relationship filter containing the above one, and also a type filter
			
			INSERT INTO chain.compound_filter (
				compound_filter_id,
				operator_type,
				created_dtm,
				created_by_user_sid,
				card_group_id,
				act_id,
				read_only_saved_filter_sid,
				is_read_only_group_by
			) VALUES (
				chain.compound_filter_id_seq.nextval,
				'and',
				SYSDATE,
				r.created_by_user_sid,
				53, /*chain.filter_pkg.FILTER_TYPE_BUS_RELS*/
				r.act_id,
				NULL,
				0
			)
			RETURNING compound_filter_id INTO v_bus_rel_comp_filt_id;
			INSERT INTO chain.filter (
				filter_id,
				filter_type_id,
				compound_filter_id,
				operator_type
			) VALUES (
				chain.filter_id_seq.nextval,
				v_bus_rel_fil_adp_type_id, /* Business relationship adapter */
				v_bus_rel_comp_filt_id,
				'and'
			) RETURNING filter_id INTO v_bus_rel_adp_filter_id;
			
			INSERT INTO chain.filter_field (
				filter_field_id,
				filter_id,
				name,
				comparator
			) VALUES (
				chain.filter_field_id_seq.nextval,
				v_bus_rel_adp_filter_id,
				'CompanyFilter',
				'equals'
			) RETURNING filter_field_id INTO v_bus_rel_adp_filt_field_id;
			INSERT INTO chain.filter_value (
				filter_value_id,
				filter_field_id,
				compound_filter_id_value
			) VALUES (
				chain.filter_value_id_seq.nextval,
				v_bus_rel_adp_filt_field_id,
				v_company_comp_filt_id
			);
			INSERT INTO chain.filter (
				filter_id,
				filter_type_id,
				compound_filter_id,
				operator_type
			) VALUES (
				chain.filter_id_seq.nextval,
				v_bus_rel_filter_type_id, /* Business relationship */
				v_bus_rel_comp_filt_id,
				'and'
			) RETURNING filter_id INTO v_bus_rel_typ_filter_id;
			
			INSERT INTO chain.filter_field (
				filter_field_id,
				filter_id,
				name,
				comparator
			) VALUES (
				chain.filter_field_id_seq.nextval,
				v_bus_rel_typ_filter_id,
				'BusinessRelationshipTypeId',
				'equals'
			) RETURNING filter_field_id INTO v_bus_rel_typ_filt_field_id;
			INSERT INTO chain.filter_value (
				filter_value_id,
				filter_field_id,
				num_value
			) VALUES ( 
				chain.filter_value_id_seq.nextval,
				v_bus_rel_typ_filt_field_id,
				v_business_rel_type_id
			);
			
			-- Finally replace the existing filter field with one that filters companies using the business relationship CF.
			
			DELETE FROM chain.filter_value
			 WHERE filter_field_id = r.filter_field_id;
			DELETE FROM chain.filter_field
			 WHERE filter_field_id = r.filter_field_id;
			SELECT COUNT(*) 
			  INTO v_filter_field_count
			  FROM chain.filter_field
			 WHERE filter_id = r.filter_id;
			IF v_filter_field_count = 0 THEN
				DELETE FROM chain.filter
				 WHERE filter_id = r.filter_id;
			END IF;
			INSERT INTO chain.filter (
				filter_id,
				filter_type_id,
				compound_filter_id,
				operator_type
			) VALUES (
				chain.filter_id_seq.nextval,
				v_company_fil_adp_type_id, /* Company Business Relationship Adapter */
				r.compound_filter_id,
				'and'
			) RETURNING filter_id INTO v_filter_id;
			INSERT INTO chain.filter_field (
				filter_field_id,
				filter_id,
				name,
				comparator
			) VALUES (
				chain.filter_field_id_seq.nextval,
				v_filter_id,
				'BusinessRelationshipFilter',
				'equals'
			) RETURNING filter_field_id INTO v_filter_field_id;
			INSERT INTO chain.filter_value (
				filter_value_id,
				filter_field_id,
				compound_filter_id_value
			) VALUES ( 
				chain.filter_value_id_seq.nextval,
				v_filter_field_id,
				v_bus_rel_comp_filt_id
			);
			
		END LOOP;
	END LOOP;
	security.user_pkg.logonadmin;
END;
/
DELETE FROM csr.branding_availability
 WHERE client_folder_name IN ('ipfin', 'orange-ch', 'virginmedia', 'virginunite');
DELETE FROM csr.branding
 WHERE client_folder_name IN ('ipfin', 'orange-ch', 'virginmedia', 'virginunite');
DECLARE
	PROCEDURE CreateFilterType (
		in_description			chain.filter_type.description%TYPE,
		in_helper_pkg			chain.filter_type.helper_pkg%TYPE,
		in_js_class_type		chain.card.js_class_type%TYPE,
		in_update				NUMBER DEFAULT 0
	)
	AS
		v_filter_type_id		chain.filter_type.filter_type_id%TYPE;
		v_card_id				chain.card.card_id%TYPE;
	BEGIN
		-- N.B. card data is present on CI build DB
		BEGIN
			SELECT card_id
			  INTO v_card_id
			  FROM chain.card
			 WHERE LOWER(js_class_type) = LOWER(in_js_class_type);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RETURN;
		END;
		
		BEGIN
			SELECT filter_type_id
			  INTO v_filter_type_id
			  FROM chain.filter_type
			 WHERE card_id = v_card_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;
		
		IF v_filter_type_id IS NULL THEN
			INSERT INTO chain.filter_type (
				filter_type_id,
				description,
				helper_pkg,
				card_id
			) VALUES (
				chain.filter_type_id_seq.NEXTVAL,
				in_description,
				in_helper_pkg,
				v_card_id
			);
		ELSIF in_update = 1 THEN
			UPDATE chain.filter_type
			   SET description = in_description
			 WHERE card_id = v_card_id;
		END IF;
	END;
BEGIN
	CreateFilterType (
		in_description => 'Chain Core Filter',
		in_helper_pkg => 'chain.company_filter_pkg',
		in_js_class_type => 'Chain.Cards.Filters.CompanyCore'
	);
	
	CreateFilterType (
		in_description => 'Chain Company Tags Filter',
		in_helper_pkg => 'chain.company_filter_pkg',
		in_js_class_type => 'Chain.Cards.Filters.CompanyTagsFilter'
	);
	
	CreateFilterType (
		in_description => 'Survey Questionnaire Filter',
		in_helper_pkg => 'csr.quick_survey_pkg',
		in_js_class_type => 'Chain.Cards.Filters.SurveyQuestionnaire'
	);
	
	CreateFilterType (
		in_description => 'Issue Filter',
		in_helper_pkg => 'csr.issue_report_pkg',
		in_js_class_type => 'Credit360.Filters.Issues.StandardIssuesFilter'
	);
	
	-- This is called Credit360.Filters.Issues.IssuesCustomFieldsFilter on live. Update description
	-- to match basedata and keep everything in sync
	CreateFilterType (
		in_description => 'Issue Custom Fields Filter',
		in_helper_pkg => 'csr.issue_report_pkg',
		in_js_class_type => 'Credit360.Filters.Issues.IssuesCustomFieldsFilter',
		in_update => 1
	);
	
	-- The following are on live but are in neither basedata nor change scripts. First three are client specific
	-- so don't care (because latest scripts shouldn't be referencing these). Last two look like core, but I can't
	-- find references elsewhere so will just have to leave it.
	
	--	ChainDemo Risk Filter
	--	Otto Company Filter Sandbox
	--	McD Workflow Filter
	--	Compliance Requirement Data Filter
	--	Compliance Regulaton Data Filter
END;
/
DECLARE
	v_company_filter_type_id	NUMBER(10);
	v_bus_rel_filter_type_id	NUMBER(10);
	v_company_fil_adp_type_id	NUMBER(10);
	v_bus_rel_fil_adp_type_id	NUMBER(10);
	v_business_rel_type_id		NUMBER(10);
	v_business_rel_type_label	VARCHAR2(255);
	v_company_comp_filt_id		NUMBER(10);
	v_company_filter_id			NUMBER(10);
	v_company_filt_field_id		NUMBER(10);
	v_bus_rel_comp_filt_id		NUMBER(10);
	v_bus_rel_adp_filter_id		NUMBER(10);
	v_bus_rel_adp_filt_field_id	NUMBER(10);
	v_bus_rel_typ_filter_id		NUMBER(10);
	v_bus_rel_typ_filt_field_id	NUMBER(10);
	
	v_filter_field_count		NUMBER;
	v_filter_id					NUMBER(10);
	v_filter_field_id			NUMBER(10);
BEGIN
	SELECT filter_type_id
	  INTO v_company_filter_type_id
	  FROM chain.filter_type
	 WHERE description = 'Chain Core Filter';
	SELECT filter_type_id
	  INTO v_bus_rel_filter_type_id
	  FROM chain.filter_type
	 WHERE description = 'Business Relationship Filter';
	 
	SELECT filter_type_id
	  INTO v_company_fil_adp_type_id
	  FROM chain.filter_type
	 WHERE description = 'Chain Company Business Relationship Filter Adapter';
	 
	SELECT filter_type_id
	  INTO v_bus_rel_fil_adp_type_id
	  FROM chain.filter_type
	 WHERE description = 'Business Relationship Filter Adapter';
	FOR site IN (
		SELECT c.host, c.app_sid
		  FROM csr.customer c 
		 WHERE EXISTS (
				SELECT null
				  FROM chain.filter_field ff
				 WHERE ff.app_sid = c.app_sid
				   AND ff.name LIKE 'BusinessRelationship.%'
		)
	) LOOP
		security.user_pkg.logonadmin(site.host);
		FOR r IN (
			SELECT cf.compound_filter_id, cf.created_by_user_sid, cf.card_group_id, cf.act_id,
				   f.filter_id, ff.filter_field_id, ff.name
			  FROM chain.filter_field ff
			  JOIN chain.filter f ON f.filter_id = ff.filter_id
			  JOIN chain.compound_filter cf ON cf.compound_filter_id = f.compound_filter_id
			 WHERE ff.app_sid = site.app_sid
			   AND ff.name LIKE 'BusinessRelationship.%'
			   AND cf.card_group_id = 23 /*chain.filter_pkg.FILTER_TYPE_COMPANIES*/
		) LOOP
			v_business_rel_type_id := TO_NUMBER(SUBSTR(r.name, 22));
			SELECT label 
			  INTO v_business_rel_type_label
			  FROM chain.business_relationship_type
			 WHERE business_relationship_type_id = v_business_rel_type_id;
			-- Create a compound filter that filters companies to the ones in the existing CF.
			INSERT INTO chain.compound_filter (
				compound_filter_id,
				operator_type,
				created_dtm,
				created_by_user_sid,
				card_group_id,
				act_id,
				read_only_saved_filter_sid,
				is_read_only_group_by
			) VALUES (
				chain.compound_filter_id_seq.nextval,
				'and',
				SYSDATE,
				r.created_by_user_sid,
				23, /*chain.filter_pkg.FILTER_TYPE_COMPANIES*/
				r.act_id,
				NULL,
				0
			)
			RETURNING compound_filter_id INTO v_company_comp_filt_id;
			INSERT INTO chain.filter (
				filter_id,
				filter_type_id,
				compound_filter_id,
				operator_type
			) VALUES (
				chain.filter_id_seq.nextval,
				v_company_filter_type_id, /* Company core */
				v_company_comp_filt_id,
				'and'
			) RETURNING filter_id INTO v_company_filter_id;
			INSERT INTO chain.filter_field (
				filter_field_id,
				filter_id,
				name,
				comparator
			) VALUES (
				chain.filter_field_id_seq.nextval,
				v_company_filter_id,
				'CompanySid',
				'equals'
			) RETURNING filter_field_id INTO v_company_filt_field_id;
			
			INSERT INTO chain.filter_value (
				filter_value_id,
				filter_field_id,
				num_value,
				description,
				pos
			) SELECT
				chain.filter_value_id_seq.nextval,
				v_company_filt_field_id,
				num_value,
				description,
				pos
			FROM chain.filter_value WHERE filter_field_id = r.filter_field_id;
			-- Create a business relationship filter containing the above one, and also a type filter
			
			INSERT INTO chain.compound_filter (
				compound_filter_id,
				operator_type,
				created_dtm,
				created_by_user_sid,
				card_group_id,
				act_id,
				read_only_saved_filter_sid,
				is_read_only_group_by
			) VALUES (
				chain.compound_filter_id_seq.nextval,
				'and',
				SYSDATE,
				r.created_by_user_sid,
				53, /*chain.filter_pkg.FILTER_TYPE_BUS_RELS*/
				r.act_id,
				NULL,
				0
			)
			RETURNING compound_filter_id INTO v_bus_rel_comp_filt_id;
			INSERT INTO chain.filter (
				filter_id,
				filter_type_id,
				compound_filter_id,
				operator_type
			) VALUES (
				chain.filter_id_seq.nextval,
				v_bus_rel_fil_adp_type_id, /* Business relationship adapter */
				v_bus_rel_comp_filt_id,
				'and'
			) RETURNING filter_id INTO v_bus_rel_adp_filter_id;
			
			INSERT INTO chain.filter_field (
				filter_field_id,
				filter_id,
				name,
				comparator
			) VALUES (
				chain.filter_field_id_seq.nextval,
				v_bus_rel_adp_filter_id,
				'CompanyFilter',
				'equals'
			) RETURNING filter_field_id INTO v_bus_rel_adp_filt_field_id;
			INSERT INTO chain.filter_value (
				filter_value_id,
				filter_field_id,
				compound_filter_id_value
			) VALUES (
				chain.filter_value_id_seq.nextval,
				v_bus_rel_adp_filt_field_id,
				v_company_comp_filt_id
			);
			INSERT INTO chain.filter (
				filter_id,
				filter_type_id,
				compound_filter_id,
				operator_type
			) VALUES (
				chain.filter_id_seq.nextval,
				v_bus_rel_filter_type_id, /* Business relationship */
				v_bus_rel_comp_filt_id,
				'and'
			) RETURNING filter_id INTO v_bus_rel_typ_filter_id;
			
			INSERT INTO chain.filter_field (
				filter_field_id,
				filter_id,
				name,
				comparator
			) VALUES (
				chain.filter_field_id_seq.nextval,
				v_bus_rel_typ_filter_id,
				'BusinessRelationshipTypeId',
				'equals'
			) RETURNING filter_field_id INTO v_bus_rel_typ_filt_field_id;
			INSERT INTO chain.filter_value (
				filter_value_id,
				filter_field_id,
				num_value
			) VALUES ( 
				chain.filter_value_id_seq.nextval,
				v_bus_rel_typ_filt_field_id,
				v_business_rel_type_id
			);
			
			-- Finally replace the existing filter field with one that filters companies using the business relationship CF.
			
			DELETE FROM chain.filter_value
			 WHERE filter_field_id = r.filter_field_id;
			DELETE FROM chain.filter_field
			 WHERE filter_field_id = r.filter_field_id;
			SELECT COUNT(*) 
			  INTO v_filter_field_count
			  FROM chain.filter_field
			 WHERE filter_id = r.filter_id;
			IF v_filter_field_count = 0 THEN
				DELETE FROM chain.filter
				 WHERE filter_id = r.filter_id;
			END IF;
			INSERT INTO chain.filter (
				filter_id,
				filter_type_id,
				compound_filter_id,
				operator_type
			) VALUES (
				chain.filter_id_seq.nextval,
				v_company_fil_adp_type_id, /* Company Business Relationship Adapter */
				r.compound_filter_id,
				'and'
			) RETURNING filter_id INTO v_filter_id;
			INSERT INTO chain.filter_field (
				filter_field_id,
				filter_id,
				name,
				comparator
			) VALUES (
				chain.filter_field_id_seq.nextval,
				v_filter_id,
				'BusinessRelationshipFilter',
				'equals'
			) RETURNING filter_field_id INTO v_filter_field_id;
			INSERT INTO chain.filter_value (
				filter_value_id,
				filter_field_id,
				compound_filter_id_value
			) VALUES ( 
				chain.filter_value_id_seq.nextval,
				v_filter_field_id,
				v_bus_rel_comp_filt_id
			);
			
		END LOOP;
	END LOOP;
	security.user_pkg.logonadmin;
END;
/
begin
	insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	values (csr.plugin_id_seq.nextval, 10, 'Audits tab', '/csr/site/chain/manageCompany/controls/AuditList.js',
		'Chain.ManageCompany.AuditList', 'Credit360.Chain.Plugins.AuditListPlugin', 'A list of audits associated with the supplier.');
	insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	values (csr.plugin_id_seq.nextval, 10, 'Audit request list tab', '/csr/site/chain/manageCompany/controls/AuditRequestList.js',
		'Chain.ManageCompany.AuditRequestList', 'Credit360.Chain.Plugins.AuditRequestListPlugin', 'A list of open audit requests for the supplier.');
	insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	values (csr.plugin_id_seq.nextval, 1, 'Audits tab', '/csr/site/property/properties/controls/AuditList.js',
		'Controls.AuditList', 'Credit360.Property.Plugins.AuditListPlugin', 'A list of audits associated with the property.');
	commit;
end;
/
begin
	-- this is overkill, but it doesn't hurt.
	update csr.plugin set card_group_id=23 where plugin_type_id in (10,11);
	update csr.plugin set card_group_id=42 where plugin_type_id in (13,14);
	update csr.plugin set card_group_id=46 where plugin_type_id = 16;
	commit;
end;
/
DECLARE
	v_act_id 				security.security_pkg.T_ACT_ID;
	v_wwwroot_sid			security.security_pkg.T_SID_ID;
	v_www_csr_site			security.security_pkg.T_SID_ID;
	v_www_user_settings		security.security_pkg.T_SID_ID;
	v_registered_users		security.security_pkg.T_SID_ID;
	v_manage_templates		security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAdmin;
	v_act_id := security.security_pkg.GetAct();
	
	FOR r IN (
		SELECT app_sid, host
		  FROM csr.customer
	  ORDER BY host
	) LOOP
		BEGIN
			v_wwwroot_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'wwwroot');
			v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_wwwroot_sid, 'csr/site');
			v_registered_users := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'groups/RegisteredUsers');
			-- Add web resource for new folder
			BEGIN
				security.web_pkg.CreateResource(v_act_id, v_wwwroot_sid, v_www_csr_site, 'userSettings', v_www_user_settings);
				
				security.securableobject_pkg.SetFlags(v_act_id, v_www_user_settings, 0); -- unset inherited
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_user_settings));
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_user_settings), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_registered_users, security.security_pkg.PERMISSION_STANDARD_READ);
			EXCEPTION
				WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
					null;
			END;
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					NULL;
		END;
	END LOOP;
	
	-- Change menu actions
	FOR x IN (
		SELECT m.sid_id, m.description, m.action, REGEXP_REPLACE(m.action, '/csr/site/usersettings.acds', '/csr/site/usersettings/edit.acds', 1, 1, 'i') new_action
		  FROM security.menu m
		  JOIN security.securable_object so
				 ON m.sid_id = so.sid_id
		 WHERE LOWER(m.action) LIKE '/csr/site/usersettings.acds%'
	)
	LOOP
		security.menu_pkg.SetMenuAction(SYS_CONTEXT('security', 'act'), x.sid_id, x.new_action);
	END LOOP;
	
END;
/
INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) VALUES (4, 201, 'Product Type');
INSERT INTO csr.plugin
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES
	(csr.plugin_id_seq.nextval, 10, 'Supplier list expandable', '/csr/site/chain/managecompany/controls/SupplierListExpandableTab.js',
		'Chain.ManageCompany.SupplierListExpandableTab', 'Credit360.Chain.Plugins.SupplierListExpandable',
		'Same as supplier list plus extra column with expandable row with companies related to a particular company.');
CREATE OR REPLACE PROCEDURE chain.Temp_RegisterCapability (
	in_capability_type			IN  NUMBER,
	in_capability				IN  VARCHAR2, 
	in_perm_type				IN  NUMBER,
	in_is_supplier				IN  NUMBER DEFAULT 0
)
AS
	v_count						NUMBER(10);
	v_ct						NUMBER(10);
BEGIN
	IF in_capability_type = 3 /*chain_pkg.CT_COMPANIES*/ THEN
		Temp_RegisterCapability(1 /*chain_pkg.CT_COMPANY*/, in_capability, in_perm_type);
		Temp_RegisterCapability(2 /*chain_pkg.CT_SUPPLIERS*/, in_capability, in_perm_type, 1);
		RETURN;	
	END IF;
	
	IF in_capability_type = 1 AND in_is_supplier <> 0 /* chain_pkg.IS_NOT_SUPPLIER_CAPABILITY */ THEN
		RAISE_APPLICATION_ERROR(-20001, 'Company capabilities cannot be supplier centric');
	ELSIF in_capability_type = 2 /* chain_pkg.CT_SUPPLIERS */ AND in_is_supplier <> 1 /* chain_pkg.IS_SUPPLIER_CAPABILITY */ THEN
		RAISE_APPLICATION_ERROR(-20001, 'Supplier capabilities must be supplier centric');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;
	
	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND (
			(capability_type_id = 0 /*chain_pkg.CT_COMMON*/ AND (in_capability_type = 0 /*chain_pkg.CT_COMPANY*/ OR in_capability_type = 2 /*chain_pkg.CT_SUPPLIERS*/))
			 OR (in_capability_type = 0 /*chain_pkg.CT_COMMON*/ AND (capability_type_id = 1 /*chain_pkg.CT_COMPANY*/ OR capability_type_id = 2 /*chain_pkg.CT_SUPPLIERS*/))
		   );
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;
	
	INSERT INTO chain.capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(chain.capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type, in_is_supplier);
	
END;
/
DECLARE 
	v_capability_id		NUMBER;
BEGIN
	chain.Temp_RegisterCapability(
		in_capability_type	=> 1,  								/* CT_COMMON*/
		in_capability		=> 'View certifications' 		 	/* chain.chain_pkg.EDIT_OWN_FOLLOWER_STATUS */, 
		in_perm_type		=> 1, 								/* BOOLEAN_PERMISSION */
		in_is_supplier 		=> 0								/* chain_pkg.IS_SUPPLIER_CAPABILITY */
	);
	chain.Temp_RegisterCapability(
		in_capability_type	=> 2,  								/* CT_COMMON*/
		in_capability		=> 'View certifications' 			/* chain.chain_pkg.EDIT_OWN_FOLLOWER_STATUS */, 
		in_perm_type		=> 1, 								/* BOOLEAN_PERMISSION */
		in_is_supplier 		=> 1								/* chain_pkg.IS_SUPPLIER_CAPABILITY */
	);
END;
/
DROP PROCEDURE chain.Temp_RegisterCapability;
EXEC security.user_pkg.LogonAdmin;
UPDATE csr.plugin
   SET cs_class = 'Credit360.Plugins.PropertyCmsPluginDto'
 WHERE plugin_type_id = 1
   AND js_class = 'Controls.CmsTab'
   AND cs_class = 'Credit360.Plugins.PluginDto';
UPDATE csr.plugin
   SET cs_class = 'Credit360.Plugins.AuditCmsPluginDto'
 WHERE plugin_type_id IN (13,14)
   AND js_class IN ('Audit.Controls.CmsTab', 'Audit.Controls.CmsHeader')
   AND cs_class = 'Credit360.Plugins.PluginDto';
UPDATE csr.plugin
   SET cs_class = 'Credit360.Plugins.ChainCmsPluginDto'
 WHERE plugin_type_id IN (10,11)
   AND js_class IN ('Chain.ManageCompany.CmsTab', 'Chain.ManageCompany.CmsHeader')
   AND cs_class = 'Credit360.Plugins.PluginDto';
UPDATE csr.plugin
   SET cs_class = 'Credit360.Plugins.InitiativeCmsPluginDto'
 WHERE plugin_type_id = 8
   AND js_class = 'Credit360.Initiatives.Plugins.GridPanel'
   AND cs_class = 'Credit360.Plugins.PluginDto';
BEGIN
	INSERT INTO csr.batch_job_type(batch_job_type_id, description, sp)
	VALUES (59, 'Product Type export', 'chain.product_type_pkg.ExportProductTypes');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (59, 'Product Type Exporter', 'Credit360.ExportImport.Export.Batched.Exporters.ProductTypeExporter');
END;
/
delete from csr.batch_job where batch_job_type_id = 18;
delete from CSR.BATCH_JOB_TYPE_APP_STAT where batch_job_type_id = 18;
delete from csr.batch_job_type where batch_job_type_id = 18;
DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	v_desc := 'Compliance Legal Register Filter';
	v_class := 'Credit360.Compliance.Cards.LegalRegisterFilter';
	v_js_path := '/csr/site/compliance/filters/LegalRegisterFilter.js';
	v_js_class := 'Credit360.Compliance.Filters.LegalRegisterFilter';
	v_css_path := '';
	
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card
			SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
			WHERE js_class_type = v_js_class
			RETURNING card_id INTO v_card_id;
	END;
	
	DELETE FROM chain.card_progression_action
	WHERE card_id = v_card_id
	AND action NOT IN ('default');
	
	v_actions := chain.T_STRING_LIST('default');
	
	FOR i IN v_actions.FIRST .. v_actions.LAST
	LOOP
		BEGIN
			INSERT INTO chain.card_progression_action (card_id, action)
			VALUES (v_card_id, v_actions(i));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;
/
DECLARE
	v_card_id	NUMBER(10);
BEGIN
	security.user_pkg.LogonAdmin;
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES(49, 'Compliance Register Filter', 'Allows filtering of local compliance items in the legal register', 'csr.compliance_register_report_pkg', '/csr/site/compliance/LegalRegister.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.Compliance.Filters.LegalRegisterFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Compliance Legal Register Filter', 'csr.compliance_register_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	-- setup filter card for all sites with initiatives
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM csr.compliance_options
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		     VALUES (r.app_sid, 49, v_card_id, 0);
	END LOOP;
END;
/
BEGIN
	INSERT INTO chain.aggregate_type (CARD_GROUP_ID, AGGREGATE_TYPE_ID, DESCRIPTION)
		 VALUES (49, 1, 'Number of items');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (49, 2, 'Number of regulations');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (49, 3, 'Number of open regulations');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (49, 4, 'Number of requirements');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (49, 5, 'Number of open requirements');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (49, 6, 'Number of actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (49, 7, 'Number of open actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (49, 8, 'Number of overdue actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (49, 9, 'Number of closed actions');
		 
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	     VALUES (49, 1, 1, 'Compliance item region');
END;
/
BEGIN
	UPDATE csr.compliance_item_source
	   SET description = 'User-entered'
	 WHERE description = 'User entered';
END;
/
BEGIN
	INSERT INTO chain.filter_type (filter_type_id, description, helper_pkg, card_id ) 
	SELECT chain.filter_type_id_seq.NEXTVAL, 'Chain Company Cms Filter', 'chain.company_filter_pkg', card_id
	  FROM chain.card
	 WHERE LOWER(js_class_type) = LOWER('Chain.Cards.Filters.CompanyCmsFilterAdapter');
EXCEPTION
	WHEN dup_val_on_index THEN
		UPDATE chain.filter_type
		   SET description = 'Chain Company Cms Filter',
			   helper_pkg = 'chain.company_filter_pkg'
		 WHERE card_id IN (
		 	SELECT card_id
			  FROM chain.card
			 WHERE LOWER(js_class_type) = LOWER('Chain.Cards.Filters.CompanyCmsFilterAdapter'));
END;
/
UPDATE csr.std_measure_conversion
   SET A = 1.094
 WHERE std_measure_conversion_id = 28220;
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (80, 'in_client_id', 0, 'ENHESA client id');
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (80, 'in_username', 1, 'ENHESA username');
UPDATE csr.compliance_item_change_type SET enhesa_id = 0 WHERE compliance_item_change_type_id = 8;
UPDATE csr.compliance_item_change_type SET enhesa_id = 1 WHERE compliance_item_change_type_id = 9;
UPDATE csr.compliance_item_change_type SET enhesa_id = 3 WHERE compliance_item_change_type_id = 10;
UPDATE csr.compliance_item_change_type SET enhesa_id = 4 WHERE compliance_item_change_type_id = 11;
UPDATE csr.compliance_item_change_type SET enhesa_id = 5 WHERE compliance_item_change_type_id = 12;
UPDATE csr.compliance_item_change_type SET enhesa_id = 6 WHERE compliance_item_change_type_id = 13;
UPDATE csr.compliance_item_change_type SET enhesa_id = 7 WHERE compliance_item_change_type_id = 14;
			
BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
		 VALUES (92, 'Chain Company Dedupe', 'EnableCompanyDedupePreProc', 'Enables the preprocessing job and the registers the city substituion CMS table for Chain company deduplication.');
END;
/


create or replace package chain.business_rel_report_pkg as end;
/
grant execute on chain.business_rel_report_pkg to csr;
grant execute on chain.business_rel_report_pkg to web_user;
CREATE OR REPLACE PACKAGE chain.certification_pkg
IS
END certification_pkg;
/
CREATE OR REPLACE PACKAGE BODY chain.certification_pkg
IS
END certification_pkg;
/
grant execute on aspen2.t_split_numeric_table to chain;
grant execute on chain.certification_pkg to web_user;
CREATE OR REPLACE PACKAGE csr.compliance_register_report_pkg AS END;
/
	
GRANT EXECUTE ON csr.compliance_register_report_pkg to web_user;
GRANT EXECUTE ON csr.compliance_register_report_pkg to chain;


@..\templated_report_schedule_pkg
@..\chain\chain_pkg
@..\chain\business_relationship_pkg
@..\chain\business_rel_report_pkg
@..\chain\company_filter_pkg
@..\chain\filter_pkg
@..\chain\type_capability_pkg
@..\audit_report_pkg
@..\plugin_pkg
@..\chain\test_chain_utils_pkg
@..\chain\dedupe_admin_pkg
@..\measure_pkg
@..\schema_pkg
@..\csr_data_pkg
@..\chain\product_type_pkg
@..\chain\product_pkg
GRANT EXECUTE ON chain.product_type_pkg TO web_user;
@..\supplier_pkg
@..\templated_report_pkg
@..\approval_dashboard_pkg
@..\portlet_pkg
@..\chain\certification_pkg
@..\batch_job_pkg
@..\sheet_pkg
@@..\csr_data_pkg
@@..\compliance_pkg
@@..\chain\filter_pkg
@@..\compliance_library_report_pkg
@@..\compliance_register_report_pkg
@@..\schema_pkg
@@..\csrimp\imp_pkg
@..\..\..\aspen2\cms\db\tab_pkg
@..\enable_pkg
@..\chain\dedupe_preprocess_pkg
@..\chain\company_dedupe_pkg


@..\automated_export_import_body
@..\templated_report_schedule_body
@..\chain\helper_body
@..\csrimp\imp_body
@..\schema_body
@..\chain\chain_body
@..\chain\business_relationship_body
@..\chain\business_rel_report_body
@..\chain\company_filter_body
@..\chain\filter_body
@..\chain\setup_body
@..\chain\type_capability_body
@..\quick_survey_body
@..\user_report_body
@..\audit_report_body
@..\plugin_body
@..\chain\dedupe_preprocess_body
@..\chain\company_dedupe_body
@..\chain\dedupe_admin_body
@..\chain\test_chain_utils_body
@..\csr_app_body
@..\csr_user_body
@..\delegation_body
@..\measure_body
@..\util_script_body
@..\chain\product_type_body
@..\chain\product_body
@..\csr_data_body
@..\audit_helper_body
@..\campaign_body
@..\supplier_body
@..\role_body
@..\section_body
@..\templated_report_body
@..\approval_dashboard_body
@..\portlet_body
@..\portal_dashboard_body
@..\region_body
@..\chain\certification_body
@..\schema_body 
@..\sheet_body
@..\issue_report_body
@@..\csr_app_body
@@..\compliance_body
@@..\compliance_library_report_body
@@..\compliance_register_report_body
@@..\enable_body
@@..\schema_body
@@..\csrimp\imp_body
@@..\issue_body
@@..\flow_body
@..\..\..\aspen2\cms\db\tab_body
@..\energy_star_body
@..\energy_star_job_body



@update_tail
