define version=3047
define minor_version=0
define is_combined=1
@update_header

-- XXX: Need to grant access to some mail tables to get 
-- this temp package to compile - not ideal really!
-- Tried moving the package into UPD, but still didn't work.
GRANT SELECT ON MAIL.ACCOUNT TO CSR;
GRANT SELECT ON MAIL.ACCOUNT_ALIAS TO CSR;
GRANT SELECT, UPDATE ON MAIL.MAILBOX TO CSR;
GRANT SELECT, UPDATE ON MAIL.MAILBOX_MESSAGE TO CSR;

@@latestUS6151_2_packages

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/
CREATE TABLE CHAIN.DEDUPE_BATCH_JOB (
	APP_SID							NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	BATCH_JOB_ID					NUMBER(10)		NOT NULL,
	IMPORT_SOURCE_ID				NUMBER(10)		NOT NULL,
	BATCH_NUMBER					NUMBER(10),
	FORCE_RE_EVAL					NUMBER(1)		DEFAULT 0 NOT NULL,
	CONSTRAINT PK_DEDUPE_BATCH_JOB PRIMARY KEY (APP_SID, BATCH_JOB_ID)
);
CREATE TABLE csr.comp_item_region_sched_issue (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	flow_item_id					NUMBER(10) NOT NULL,
	issue_scheduled_task_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_comp_item_reg_sched_issue PRIMARY KEY (app_sid, flow_item_id, issue_scheduled_task_id),
	CONSTRAINT fk_cmp_itm_sched_iss_cmp_itm FOREIGN KEY (app_sid, flow_item_id)
		REFERENCES csr.compliance_item_region (app_sid, flow_item_id),
	CONSTRAINT fk_cmp_itm_schd_iss_iss_sched FOREIGN KEY (app_sid, issue_scheduled_task_id)
		REFERENCES csr.issue_scheduled_task (app_sid, issue_scheduled_task_id)
);
CREATE TABLE csrimp.comp_item_region_sched_issue (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	flow_item_id					NUMBER(10) NOT NULL,
	issue_scheduled_task_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_comp_item_reg_sched_issue PRIMARY KEY (csrimp_session_id, flow_item_id, issue_scheduled_task_id),
	CONSTRAINT fk_cmp_itm_rg_sched_issue_is FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);
CREATE TABLE csrimp.map_issue_scheduled_task (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_issue_scheduled_task_id 	NUMBER(10) NOT NULL,
	new_issue_scheduled_task_id		NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_issue_scheduled_task PRIMARY KEY (csrimp_session_id, old_issue_scheduled_task_id) USING INDEX,
	CONSTRAINT uk_map_issue_scheduled_task UNIQUE (csrimp_session_id, new_issue_scheduled_task_id) USING INDEX,
	CONSTRAINT fk_map_issue_scheduled_task_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);
CREATE SEQUENCE csr.comp_item_region_log_id_seq;

lock table csr.csr_user in exclusive mode;
lock table csr.compliance_item_region in exclusive mode;

CREATE TABLE csr.compliance_item_region_log (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	compliance_item_region_log_id	NUMBER(10) NOT NULL,
	flow_item_id					NUMBER(10) NOT NULL,
	log_dtm							DATE DEFAULT SYSDATE NOT NULL,
	user_sid						NUMBER(10) DEFAULT NVL(SYS_CONTEXT('SECURITY','SID'),3) NOT NULL,
	description						VARCHAR2(4000) NOT NULL,
	comment_text					CLOB,
	CONSTRAINT pk_compliance_item_region_log PRIMARY KEY (app_sid, compliance_item_region_log_id),
	CONSTRAINT fk_cmp_itm_reg_log_cmp_itm_reg FOREIGN KEY (app_sid, flow_item_id)
		REFERENCES csr.compliance_item_region (app_sid, flow_item_id),
	CONSTRAINT fk_cmp_itm_reg_log_user FOREIGN KEY (app_sid, user_sid)
		REFERENCES csr.csr_user (app_sid, csr_user_sid)
);
create index csr.ix_compliance_it_flow_item_id on csr.compliance_item_region_log (app_sid, flow_item_id);
create index csr.ix_compliance_it_user_sid on csr.compliance_item_region_log (app_sid, user_sid);
CREATE TABLE csrimp.compliance_item_region_log (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	compliance_item_region_log_id	NUMBER(10) NOT NULL,
	flow_item_id					NUMBER(10) NOT NULL,
	log_dtm							DATE NOT NULL,
	user_sid						NUMBER(10) NOT NULL,
	description						VARCHAR2(4000) NOT NULL,
	comment_text					CLOB,
	CONSTRAINT pk_compliance_item_region_log PRIMARY KEY (csrimp_session_id, compliance_item_region_log_id),
	CONSTRAINT fk_cmp_itm_reg_log_user_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);
CREATE TABLE csrimp.map_compliance_item_region_log (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_comp_item_region_log_id 	NUMBER(10) NOT NULL,
	new_comp_item_region_log_id		NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_comp_item_region_log PRIMARY KEY (csrimp_session_id, old_comp_item_region_log_id) USING INDEX,
	CONSTRAINT uk_map_comp_item_region_log UNIQUE (csrimp_session_id, new_comp_item_region_log_id) USING INDEX,
	CONSTRAINT fk_map_comp_item_region_log_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);
	
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_COMP_REGION_LVL_IDS (
	REGION_SID			NUMBER(10)		NOT NULL,
	REGION_DESCRIPTION	VARCHAR(1023)	NOT NULL,
	MGR_FULL_NAME		VARCHAR(255)
) ON COMMIT DELETE ROWS;
CREATE SEQUENCE CHAIN.ALT_COMPANY_NAME_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;
CREATE TABLE CHAIN.ALT_COMPANY_NAME(
	APP_SID							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	ALT_COMPANY_NAME_ID				NUMBER(10) NOT NULL,
	COMPANY_SID						NUMBER(10) NOT NULL,
	NAME							VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_ALT_COMPANY_NAME PRIMARY KEY (APP_SID, ALT_COMPANY_NAME_ID),
	CONSTRAINT FK_ALT_COMP_NAME_COMPANY FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CHAIN.COMPANY (APP_SID, COMPANY_SID),
	CONSTRAINT UK_ALT_COMPANY_NAME UNIQUE (APP_SID, COMPANY_SID, NAME)
);
CREATE TABLE CSRIMP.MAP_CHAIN_ALT_COMPANY_NAME(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ALT_COMPANY_NAME_ID			NUMBER(10) NOT NULL,
	NEW_ALT_COMPANY_NAME_ID			NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_ALT_COMPANY_NAME PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ALT_COMPANY_NAME_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_ALT_COMPANY_NAME UNIQUE (CSRIMP_SESSION_ID, NEW_ALT_COMPANY_NAME_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_ALT_COMPANY_NAME FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.CHAIN_ALT_COMPANY_NAME(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ALT_COMPANY_NAME_ID				NUMBER(10) NOT NULL,
	COMPANY_SID						NUMBER(10) NOT NULL,
	NAME							VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_CHAIN_ALT_COMPANY_NAME PRIMARY KEY (ALT_COMPANY_NAME_ID),
	CONSTRAINT FK_CHAIN_ALT_COMPANY_NAME FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);


ALTER TABLE csr.compliance_item_region ADD out_of_scope NUMBER (1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE csrimp.compliance_item_region ADD out_of_scope NUMBER (1, 0) NOT NULL;
ALTER TABLE csr.compliance_item_region ADD CONSTRAINT CHK_COMPLIANCE_ITEM_REGION_1_0 CHECK (out_of_scope IN (0,1));
ALTER TABLE csrimp.compliance_item_region ADD CONSTRAINT CHK_COMPLIANCE_ITEM_REGION_1_0 CHECK (out_of_scope IN (0,1));
ALTER TABLE csr.customer ADD (
	QUESTION_LIBRARY_ENABLED NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT CK_QUESTION_LIBRARY_ENABLED CHECK (QUESTION_LIBRARY_ENABLED IN (0,1))
);
ALTER TABLE csrimp.customer ADD (
	QUESTION_LIBRARY_ENABLED NUMBER(1) NOT NULL,
	CONSTRAINT CK_QUESTION_LIBRARY_ENABLED CHECK (QUESTION_LIBRARY_ENABLED IN (0,1))
);
ALTER TABLE csr.compliance_regulation ADD (
	is_policy						NUMBER(1)	DEFAULT 0 NOT NULL,
	CONSTRAINT ck_is_policy			CHECK (is_policy IN (0,1))
);
ALTER TABLE csrimp.compliance_regulation ADD (
	is_policy						NUMBER(1)	NOT NULL,
	CONSTRAINT ck_is_policy			CHECK (is_policy IN (0,1))
);
ALTER TABLE csr.compliance_options ADD (
	score_type_id NUMBER(10),
	CONSTRAINT FK_COMP_OPTIONS_SCORE_TYPE FOREIGN KEY (app_sid, score_type_id) REFERENCES csr.score_type(app_sid, score_type_id)
);
CREATE INDEX csr.ix_compliance_op_score_type_id ON csr.compliance_options (app_sid, score_type_id);
ALTER TABLE csrimp.compliance_options ADD (
	score_type_id NUMBER(10)
);
ALTER TABLE chain.higg_config_module ADD score_type_id NUMBER(10);
ALTER TABLE csrimp.higg_config_module ADD score_type_id NUMBER(10);
ALTER TABLE chain.higg_module ADD score_type_lookup_key VARCHAR2(255);
ALTER TABLE chain.higg_module ADD score_type_format_mask VARCHAR2(20);
ALTER TABLE csr.issue_scheduled_task ADD (
	issue_type_id					NUMBER(10),
	CONSTRAINT fk_iss_sched_tsk_iss_type FOREIGN KEY (app_sid, issue_type_id) 
		REFERENCES csr.issue_type (app_sid, issue_type_id)
);
ALTER TABLE csrimp.issue_scheduled_task ADD (
	issue_type_id					NUMBER(10)
);
ALTER TABLE csr.issue_scheduled_task ADD (
	scheduled_on_due_date			NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_scheduled_on_due_date_1_0 CHECK (scheduled_on_due_date IN (1, 0))
);
ALTER TABLE csrimp.issue_scheduled_task ADD (
	scheduled_on_due_date			NUMBER(1) NOT NULL,
	CONSTRAINT chk_scheduled_on_due_date_1_0 CHECK (scheduled_on_due_date IN (1, 0))
);
ALTER TABLE csr.temp_compliance_log_ids RENAME COLUMN flow_state_log_id TO compliance_item_region_log_id;
create index csr.ix_comp_item_reg_issue_schedul on csr.comp_item_region_sched_issue (app_sid, issue_scheduled_task_id);
create index csr.ix_issue_schedul_issue_type_id on csr.issue_scheduled_task (app_sid, issue_type_id);
DROP TABLE csr.enhesa_topic_sched_task;
DROP TABLE csr.enhesa_topic_issue;
BEGIN
	security.user_pkg.LogonAdmin;
	FOR r IN (
		SELECT app_sid, issue_id
		  FROM csr.issue
		 WHERE issue_type_id = 19
	) LOOP
		UPDATE csr.issue_log
		   SET issue_id = NULL
		 WHERE issue_id = r.issue_id
		   AND app_sid = r.app_sid;
		UPDATE csr.issue_action_log
		   SET issue_id = NULL
		 WHERE issue_id = r.issue_id
		   AND app_sid = r.app_sid;
		 
		DELETE FROM csr.issue_involvement
		 WHERE issue_id = r.issue_id
		   AND app_sid = r.app_sid;
		 
		DELETE FROM csr.issue_custom_field_str_val
		 WHERE issue_id = r.issue_id
		   AND app_sid = r.app_sid;
		 
		DELETE FROM csr.issue_custom_field_opt_sel 
		 WHERE issue_id = r.issue_id
		   AND app_sid = r.app_sid;
		 
		DELETE FROM csr.issue_custom_field_date_val
		 WHERE issue_id = r.issue_id
		   AND app_sid = r.app_sid;
		
		DELETE FROM csr.issue_alert
		 WHERE issue_id = r.issue_id
		   AND app_sid = r.app_sid;
		
		DELETE FROM csr.issue
		 WHERE issue_id = r.issue_id
		   AND app_sid = r.app_sid;
	END LOOP;
	
	DELETE FROM csr.issue_type
	 WHERE issue_type_id = 19;
END;
/
BEGIN
	security.user_pkg.LogonAdmin;
	
	INSERT INTO csr.compliance_item_region_log (app_sid, compliance_item_region_log_id, 
					flow_item_id, log_dtm, user_sid, description, comment_text)
	 SELECT fsl.app_sid, csr.comp_item_region_log_id_seq.NEXTVAL,
	        fsl.flow_item_id, fsl.set_dtm, set_by_user_sid, 'Entered state: '||fs.label, fsl.comment_text
	   FROM csr.flow_state_log fsl
	   JOIN csr.compliance_item_region cir ON fsl.app_sid = cir.app_sid AND fsl.flow_item_id = cir.flow_item_id
	   JOIN csr.flow_state fs ON fsl.app_sid = fs.app_sid AND fsl.flow_state_id = fs.flow_state_id;
END;
/
ALTER TABLE CMS.TAB ADD SHOW_IN_PRODUCT_FILTER NUMBER(1) DEFAULT 0;
UPDATE CMS.TAB SET SHOW_IN_PRODUCT_FILTER = 0 WHERE SHOW_IN_PRODUCT_FILTER IS NULL;
ALTER TABLE CMS.TAB MODIFY SHOW_IN_PRODUCT_FILTER NOT NULL;
ALTER TABLE CMS.TAB ADD CONSTRAINT CHK_SHOW_IN_PRODUCT_FILTER CHECK (SHOW_IN_PRODUCT_FILTER IN (0,1));
ALTER TABLE CSRIMP.CMS_TAB ADD SHOW_IN_PRODUCT_FILTER NUMBER(1) NULL;
UPDATE CSRIMP.CMS_TAB SET SHOW_IN_PRODUCT_FILTER = 0 WHERE SHOW_IN_PRODUCT_FILTER IS NULL;
ALTER TABLE CSRIMP.CMS_TAB MODIFY SHOW_IN_PRODUCT_FILTER NOT NULL;
ALTER TABLE CSR.TEMP_METER_READING_ROWS ADD (
	UNIT_OF_MEASURE 			VARCHAR2(10),
	IMPORT_CONVERSION_ID 		NUMBER(10),
	METER_CONVERSION_ID 		NUMBER(10),
	MEASURE_SID					NUMBER(10)
);
ALTER TABLE csr.auto_imp_core_data_settings
ADD financial_year_start_month NUMBER(2);
UPDATE csr.auto_imp_core_data_settings
   SET financial_year_start_month = 3
 WHERE zero_indexed_month_indices = 1;
UPDATE csr.auto_imp_core_data_settings
   SET financial_year_start_month = 4
 WHERE financial_year_start_month IS NULL;
 
 ALTER TABLE csr.auto_imp_core_data_settings
MODIFY financial_year_start_month NUMBER(2) NOT NULL;
create index chain.ix_alt_company_name on chain.alt_company_name (app_sid, company_sid);
ALTER TABLE chain.filter_page_column ADD session_prefix VARCHAR2(255);
ALTER TABLE chain.filter_item_config ADD session_prefix VARCHAR2(255);
ALTER TABLE chain.aggregate_type_config ADD session_prefix VARCHAR2(255);
ALTER TABLE csrimp.chain_filter_page_column ADD session_prefix VARCHAR2(255);
ALTER TABLE csrimp.chain_filter_item_config ADD session_prefix VARCHAR2(255);
ALTER TABLE csrimp.chain_aggregate_type_config ADD session_prefix VARCHAR2(255);
UPDATE chain.filter_page_column 
   SET session_prefix = 'csr_site_chain_supplierfilter_' || company_tab_id 
 WHERE company_tab_id IS NOT NULL AND card_group_id = 23;
UPDATE chain.filter_item_config 
   SET session_prefix = 'csr_site_chain_supplierfilter_' || company_tab_id 
 WHERE company_tab_id IS NOT NULL AND card_group_id = 23;
UPDATE chain.aggregate_type_config 
   SET session_prefix = 'csr_site_chain_supplierfilter_' || company_tab_id 
 WHERE company_tab_id IS NOT NULL AND card_group_id = 23;
UPDATE chain.filter_page_column 
   SET session_prefix = 'csr_site_audit_auditlist_' || group_key 
 WHERE group_key IS NOT NULL AND card_group_id = 41;
DROP INDEX chain.uk_filter_table_column ;
CREATE UNIQUE INDEX chain.uk_filter_table_column 
    ON chain.filter_page_column(app_sid, card_group_id, column_name, session_prefix, LOWER(group_key));
DROP INDEX chain.ix_filter_page_c_company_tab_i ;
CREATE INDEX chain.ix_filter_page_c_company_tab_i 
    ON chain.filter_page_column (app_sid, session_prefix);
	
DROP INDEX chain.uk_filter_item_config ;
CREATE UNIQUE INDEX chain.uk_filter_item_config 
    ON chain.filter_item_config(app_sid, card_group_id, card_id, item_name, session_prefix, path);
DROP INDEX chain.uk_aggregate_type_config ;
CREATE UNIQUE INDEX chain.uk_aggregate_type_config 
    ON chain.aggregate_type_config(app_sid, card_group_id, aggregate_type_id, session_prefix, path);
ALTER TABLE chain.filter_page_column DROP CONSTRAINT fk_fltr_pg_col_plugin;
ALTER TABLE chain.filter_page_column DROP COLUMN company_tab_id;
ALTER TABLE chain.filter_item_config DROP COLUMN company_tab_id;
ALTER TABLE chain.aggregate_type_config DROP COLUMN company_tab_id;
ALTER TABLE csrimp.chain_filter_page_column DROP COLUMN company_tab_id;
ALTER TABLE csrimp.chain_filter_item_config DROP COLUMN company_tab_id;
ALTER TABLE csrimp.chain_aggregate_type_config DROP COLUMN company_tab_id;
BEGIN
	security.user_pkg.logonadmin;
END;
/
DECLARE
	v_card_id			chain.card.card_id%TYPE;
	v_desc				chain.card.description%TYPE;
	v_class				chain.card.class_type%TYPE;
	v_js_path			chain.card.js_include%TYPE;
	v_js_class			chain.card.js_class_type%TYPE;
	v_css_path			chain.card.css_include%TYPE;
	v_actions			chain.T_STRING_LIST;
BEGIN
	v_desc := 'Dedupe Processed Record Filter';
	v_class := 'Credit360.Chain.Cards.Filters.DedupeProcessedRecordFilter';
	v_js_path := '/csr/site/chain/dedupe/filters/processedRecordFilter.js';
	v_js_class := 'Chain.dedupe.filters.ProcessedRecordFilter';
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
	v_card_id						NUMBER(10);
	v_audit_filter_card_id			NUMBER(10);
	v_sid							NUMBER(10);
BEGIN
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES(57 /*chain.filter_pkg.FILTER_TYPE_DEDUPE_PROC_RECS*/, 'Dedupe Processed Record Filter', 'Allows filtering of processed dedupe records.', 'chain.dedupe_proc_record_report_pkg', '/csr/site/chain/dedupe/processedRecords.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.dedupe.filters.ProcessedRecordFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Dedupe Processed Record Filter', 'chain.dedupe_proc_record_report_pkg', v_card_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	FOR r IN (
		SELECT app_sid FROM chain.customer_options
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
					VALUES (r.app_sid, 57 /*chain.filter_pkg.FILTER_TYPE_DEDUPE_PROC_RECS*/, v_card_id, 0);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;
/
BEGIN
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (57 /*chain.filter_pkg.FILTER_TYPE_DEDUPE_PROC_RECS*/, 1 /*chain.dedupe_proc_record_report_pkg.AGG_TYPE_COUNT*/, 'Number of records');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;
/
BEGIN
	BEGIN
		INSERT INTO chain.saved_filter_alert_param (card_group_id, field_name, description, translatable, link_text)
		VALUES (57, 'COMPANY_REF', 'Company ID', 0, NULL);
		
		INSERT INTO chain.saved_filter_alert_param (card_group_id, field_name, description, translatable, link_text)
		VALUES (57, 'MATCHED_TO_COMPANY_NAME', 'Matched to company name', 0, NULL);
		
		INSERT INTO chain.saved_filter_alert_param (card_group_id, field_name, description, translatable, link_text)
		VALUES (57, 'IMPORT_SOURCE_NAME', 'Import source name', 0, NULL);
		
		INSERT INTO chain.saved_filter_alert_param (card_group_id, field_name, description, translatable, link_text)
		VALUES (57, 'CREATED_COMPANY_NAME', 'Created company name', 0, NULL);
		
		INSERT INTO chain.saved_filter_alert_param (card_group_id, field_name, description, translatable, link_text)
		VALUES (57, 'BATCH_NUM', 'Batch number', 0, NULL);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;
/
ALTER TABLE csrimp.cms_tab
ADD policy_view VARCHAR(1024);
ALTER TABLE CSR.METER_RAW_DATA_SOURCE ADD (
	LABEL						VARCHAR2(1024)
);
ALTER TABLE CSR.METER_RAW_DATA_SOURCE RENAME COLUMN SOURCE_EMAIL TO XX_SOURCE_EMAIL;
ALTER TABLE CSR.METER_RAW_DATA_SOURCE RENAME COLUMN SOURCE_FOLDER TO XX_SOURCE_FOLDER;
ALTER TABLE CSR.METER_RAW_DATA_SOURCE RENAME COLUMN FILE_MATCH_RX TO XX_FILE_MATCH_RX;
ALTER TABLE CSR.METER_RAW_DATA_SOURCE RENAME COLUMN RAW_DATA_SOURCE_TYPE_ID TO XX_RAW_DATA_SOURCE_TYPE_ID;
ALTER TABLE CSRIMP.METER_RAW_DATA_SOURCE ADD (
	LABEL						VARCHAR2(1024)	NOT NULL
);
ALTER TABLE CSRIMP.METER_RAW_DATA_SOURCE DROP COLUMN SOURCE_EMAIL;
ALTER TABLE CSRIMP.METER_RAW_DATA_SOURCE DROP COLUMN SOURCE_FOLDER;
ALTER TABLE CSRIMP.METER_RAW_DATA_SOURCE DROP COLUMN FILE_MATCH_RX;
ALTER TABLE CSRIMP.METER_RAW_DATA_SOURCE DROP COLUMN RAW_DATA_SOURCE_TYPE_ID;
ALTER TABLE CSR.METER_RAW_DATA_SOURCE MODIFY (
	XX_RAW_DATA_SOURCE_TYPE_ID			NUMBER(10)	NULL
);
ALTER TABLE CSR.METER_RAW_DATA_SOURCE DROP CONSTRAINT FK_METER_RAW_DATA_SOURCE_TYPE;
DROP TABLE CSR.METER_RAW_DATA_SOURCE_TYPE;
ALTER TABLE csr.customer ADD (
	CALC_SUM_TO_DT_CUST_YR_START NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT CK_CALC_SUM_TO_DT_CUST_YR CHECK (CALC_SUM_TO_DT_CUST_YR_START IN (0,1))
);
ALTER TABLE csrimp.customer ADD (
	CALC_SUM_TO_DT_CUST_YR_START NUMBER(1) NOT NULL,
	CONSTRAINT CK_CALC_SUM_TO_DT_CUST_YR CHECK (CALC_SUM_TO_DT_CUST_YR_START IN (0,1))
);
update csr.customer set CALC_SUM_TO_DT_CUST_YR_START = 1 where name = 'firstgroup.credit360.com';


grant execute on chain.higg_setup_pkg to csr;
GRANT SELECT, INSERT, UPDATE ON csr.comp_item_region_sched_issue TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.comp_item_region_sched_issue TO tool_user;
GRANT SELECT, INSERT, UPDATE ON csr.compliance_item_region_log TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_item_region_log TO tool_user;
GRANT SELECT ON csr.comp_item_region_log_id_seq TO csrimp;
GRANT SELECT ON csr.compliance_item_seq TO csrimp;
GRANT SELECT ON csr.compliance_item_history_seq TO csrimp;
grant select on chain.alt_company_name_id_seq to csrimp;
grant select on chain.alt_company_name to csr;
grant select, insert, update on chain.alt_company_name to csrimp;
grant select, insert, update, delete on csrimp.chain_alt_company_name to tool_user;


ALTER TABLE CHAIN.DEDUPE_BATCH_JOB ADD CONSTRAINT FK_BATCHJOB_DEDUPEBATJOB
    FOREIGN KEY (APP_SID, BATCH_JOB_ID)
    REFERENCES CSR.BATCH_JOB(APP_SID, BATCH_JOB_ID)
;
ALTER TABLE chain.higg_config_module ADD CONSTRAINT FK_HIGG_MODULE_SCORE_TYPE_ID
    FOREIGN KEY (app_sid, score_type_id)
 REFERENCES csr.score_type(app_sid, score_type_id);


CREATE OR REPLACE VIEW csr.v$compliance_item_rag AS 
	SELECT t.region_sid, t.total_items, t.compliant_items, t.pct_compliant, 
		TRIM(TO_CHAR ((
			SELECT DISTINCT FIRST_VALUE(text_colour)
			  OVER (ORDER BY st.max_value ASC) AS text_colour
			  FROM csr.compliance_options co
			  JOIN csr.score_threshold st ON co.score_type_id = st.score_type_id AND st.app_sid = co.app_sid
			 WHERE co.app_sid = security.security_pkg.GetApp
				 AND t.pct_compliant <= st.max_value
		), 'XXXXXX')) pct_compliant_colour
	FROM (
		SELECT app_sid, region_sid, total_items, compliant_items, DECODE(total_items, 0, 0, ROUND(100*compliant_items/total_items)) pct_compliant
		 FROM (
			SELECT cir.app_sid, cir.region_sid, COUNT(*) total_items, SUM(DECODE(fsn.label, 'Compliant', 1, 0)) compliant_items
				FROM csr.compliance_item_region cir
				JOIN csr.compliance_item ci ON cir.compliance_item_id = ci.compliance_item_id
				JOIN csr.flow_item fi ON fi.flow_item_id = cir.flow_item_id
				JOIN csr.flow_state fs ON fi.current_state_id = fs.flow_state_id
				LEFT JOIN csr.flow_state_nature fsn ON fsn.flow_state_nature_id = fs.flow_state_nature_id
			 WHERE fsn.flow_alert_class IN ('regulation', 'requirement')
				 AND lower(fsn.label) NOT IN ('retired', 'not applicable')
			 GROUP BY cir.app_sid, cir.region_sid
		)
		ORDER BY region_sid
	) t
;
CREATE OR REPLACE VIEW csr.v$my_compliance_items AS
	SELECT cir.compliance_item_id, cir.region_sid, cir.flow_item_id
	  FROM csr.compliance_item_region cir
	  JOIN csr.flow_item fi ON cir.app_sid = fi.app_sid AND cir.flow_item_id = fi.flow_item_id
	 WHERE  (EXISTS (
			SELECT 1
			  FROM csr.region_role_member rrm
			  JOIN csr.flow_state_role fsr ON rrm.app_sid = fsr.app_sid AND fsr.role_sid = rrm.role_sid
			 WHERE rrm.app_sid = cir.app_sid
			   AND rrm.region_sid = cir.region_sid
			   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND fsr.flow_state_id = fi.current_state_id
		)
		OR EXISTS (
			SELECT 1
			  FROM csr.flow_state_role fsr
			  JOIN security.act act ON act.sid_id = fsr.group_sid
			 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
			   AND fsr.flow_state_id = fi.current_state_id
		)
);
CREATE OR REPLACE VIEW csr.v$temp_meter_reading_rows AS
       SELECT t.source_row, t.region_sid, t.start_dtm, t.end_dtm, t.reference, t.note, t.reset_val,
              t.priority, v.consumption consumption, c.consumption cost,
			  v.import_conversion_id cons_import_conv_id, c.import_conversion_id cost_import_conv_id,
			  v.meter_conversion_id  cons_meter_conv_id , c.meter_conversion_id cost_meter_conv_id,
			  v.error_msg cons_error_msg, c.error_msg cost_error_msg
	    FROM ( SELECT DISTINCT source_row,
			    region_sid,
			    start_dtm,
			    end_dtm,
			    REFERENCE,
			    priority,
			    note,
			    reset_val
    			FROM csr.temp_meter_reading_rows
			  ) t
	LEFT JOIN csr.temp_meter_reading_rows v
		   ON v.source_row       = t.source_row
		  AND t.region_sid       = v.region_sid
		  AND v.meter_input_id IN (SELECT meter_input_id
									FROM csr.meter_input
									WHERE app_sid  = SYS_CONTEXT('SECURITY', 'APP')
									AND lookup_key = 'CONSUMPTION'
								  )
	LEFT JOIN csr.temp_meter_reading_rows c
		   ON c.source_row       = t.source_row
		  AND t.region_sid       = c.region_sid
		  AND c.meter_input_id IN (SELECT meter_input_id
									FROM csr.meter_input
									WHERE app_sid  = SYS_CONTEXT('SECURITY', 'APP')
									AND lookup_key = 'COST'
								  );
CREATE OR REPLACE VIEW CSR.V$METER_ORPHAN_DATA_SUMMARY AS
	SELECT od.app_sid, od.serial_id, od.meter_input_id, od.priority, ds.label,
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
	 GROUP BY od.app_sid, od.serial_id, od.meter_input_id, od.priority, ds.label
;


DECLARE
	PROCEDURE DeleteMenu(in_path	IN VARCHAR2) 
	AS
		v_menu_sid					security.security_pkg.T_SID_ID;
	BEGIN
		v_menu_sid := security.securableobject_pkg.GetSIDFromPath(
			in_act => security.security_pkg.GetAct,
			in_parent_sid_id => security.security_pkg.GetApp,
			in_path => in_path
		);
		security.securableobject_pkg.DeleteSO(
			in_act_id => security.security_pkg.GetAct,
			in_sid_id => v_menu_sid
		);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN RETURN;
	END;
BEGIN
	security.user_pkg.LogonAdmin(NULL);
	FOR r IN (SELECT host
				FROM csr.customer c
				JOIN csr.compliance_options co ON c.app_sid = co.app_sid)
	LOOP
		security.user_pkg.LogonAdmin(r.host);
		DeleteMenu('menu/csr_compliance/csr_compliance_create_regulation');
		DeleteMenu('menu/csr_compliance/csr_compliance_create_requirement');
	END LOOP;
	security.user_pkg.LogonAdmin(NULL);
END;
/


UPDATE csr.util_script
   SET util_script_sp = 'RecalcOne'
 WHERE util_script_id = 2
   AND util_script_name = 'Recalc one'
   AND util_script_sp = 'CreateDelegationSheetsFuture';
BEGIN
	security.user_pkg.LogonAdmin();
	UPDATE security.menu
		SET action = '/csr/site/meter/meterIssuesList.acds'
		WHERE lower(action) = lower('/csr/site/meter/meterActionsList.acds')
		   OR lower(action) = lower('/csr/site/issues/issueList.acds?issueTypes=6,7,8');
END;
/
INSERT INTO csr.compliance_item_change_type (compliance_item_change_type_id, description, source, change_type_index)
	VALUES (15, 'Retired', 0, 8);
UPDATE csr.module SET description = 'Enable surveys'
 WHERE enable_sp = 'EnableSurveys';
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (94, 'Question Library', 'EnableQuestionLibrary', 'Enables the Question Library module used in conjunction with Surveys, supporting a question bank for repeatable, reusable questions across multiple surveys and reporting periods.');
BEGIN
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'AQ'
	   AND source_region = 'US';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'AU'
	   AND source_region = 'LG';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'BE'
	   AND source_region = 'WAL';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'BA'
	   AND source_region = 'BRC';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'CN'
	   AND source_region = 'CHD';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'CN'
	   AND source_region = 'DAL';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'CN'
	   AND source_region = 'DON';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'CN'
	   AND source_region = 'GGU';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'CN'
	   AND source_region = 'HNG';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'CN'
	   AND source_region = 'PIN';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'CN'
	   AND source_region = 'SQI';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'CN'
	   AND source_region = 'GSH';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'CN'
	   AND source_region = 'SUZ';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'CN'
	   AND source_region = 'FXI';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'CN'
	   AND source_region = 'XIA';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'IN'
	   AND source_region = 'BA';
	
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'IN'
	   AND source_region = 'TG';
	
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'AE'
	   AND source_region = 'YZA';
	
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'AE'
	   AND source_region = 'RUW';
	
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'CN'
	   AND source_region = 'MAC';
	
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'FR'
	   AND source_region = 'NC';
	
	UPDATE CSR.COMPLIANCE_REGION_MAP
	   SET REGION = NULL
	 WHERE source_country = 'CO'
	   AND source_region = 'BOG';
END;
/
INSERT INTO csr.portlet (portlet_id,name,type,default_state,script_path) 
VALUES (
	1061,
	'Non-compliant items',
	'Credit360.Portlets.Compliance.NonCompliantItems', 
	EMPTY_CLOB(),
	'/csr/site/portal/portlets/compliance/NonCompliantItems.js'
);
DECLARE 
	v_expr VARCHAR2(1024) := '^/compliance/RegionCompliance.acds\?flowItemId=(\d+)';
BEGIN
	security.user_pkg.LogonAdmin(NULL);
	UPDATE csr.issue 
	   SET source_url = 
			'/csr/site/compliance/RegionCompliance.acds?flowItemId=' || 
			REGEXP_SUBSTR(source_url, v_expr, 1, 1, NULL, 1)
	 WHERE REGEXP_LIKE(source_url, v_expr);
END;
/
BEGIN
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp)
	VALUES (60, 'Dedupe batch job', null, 'process-dedupe-records', 0, null);
END;
/
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH)
VALUES (1062,'Compliance levels','Credit360.Portlets.ComplianceLevels', EMPTY_CLOB(),'/csr/site/portal/portlets/ComplianceLevels.js');
DECLARE
	v_social_score_type_lookup 		VARCHAR2(255) := 'HIGG_SOCIAL_SCORE';
	v_social_module_id 				NUMBER(10) := 5;
	v_social_format_mask			VARCHAR2(20) := '0';
	v_env_score_type_lookup 		VARCHAR2(255) := 'HIGG_ENV_SCORE';
	v_env_module_id 				NUMBER(10) := 6;
	v_env_format_mask				VARCHAR2(20) := '0';
BEGIN
	security.user_pkg.LogonAdmin;
	UPDATE chain.higg_module
	   SET score_type_lookup_key = v_social_score_type_lookup,
		   score_type_format_mask = v_social_format_mask
	 WHERE higg_module_id = v_social_module_id;
	UPDATE chain.higg_module
	   SET score_type_lookup_key = v_env_score_type_lookup,
		   score_type_format_mask = v_env_format_mask
	 WHERE higg_module_id = v_env_module_id;
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM chain.higg_config
	)
	LOOP
		BEGIN
			INSERT INTO csr.score_type (app_sid, score_type_id, label, pos, hidden, allow_manual_set, lookup_key,
					applies_to_supplier, reportable_months, format_mask, ask_for_comment,
					applies_to_surveys, applies_to_non_compliances, applies_to_regions, applies_to_audits,
					min_score, max_score, start_score, normalise_to_max_score)
			VALUES (r.app_sid, csr.score_type_id_seq.nextval, 'Higg Social score', 0, 0, 0, v_social_score_type_lookup,
					1, 12, v_social_format_mask, 'none', 0, 0, 0, 1, NULL, NULL, 0, 0);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
		BEGIN
			INSERT INTO csr.score_type (app_sid, score_type_id, label, pos, hidden, allow_manual_set, lookup_key,
					applies_to_supplier, reportable_months, format_mask, ask_for_comment,
					applies_to_surveys, applies_to_non_compliances, applies_to_regions, applies_to_audits,
					min_score, max_score, start_score, normalise_to_max_score)
			VALUES (r.app_sid, csr.score_type_id_seq.nextval, 'Higg Social score', 0, 0, 0, v_env_score_type_lookup,
					1, 12, v_env_format_mask, 'none', 0, 0, 0, 1, NULL, NULL, 0, 0);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
	FOR r IN (
		SELECT hcm.app_sid, hcm.higg_config_id, hcm.higg_module_id, st.score_type_id
		  FROM chain.higg_config_module hcm
		  JOIN chain.higg_module hm ON hcm.higg_module_id = hm.higg_module_id
		  JOIN csr.score_type st ON st.lookup_key = hm.score_type_lookup_key AND st.app_sid = hcm.app_sid
	) LOOP
		UPDATE chain.higg_config_module
		   SET score_type_id = r.score_type_id
		 WHERE higg_module_id = r.higg_module_id
		   AND higg_config_id = r.higg_config_id
		   AND app_sid = r.app_sid;
	END LOOP;
END;
/
ALTER TABLE chain.higg_module MODIFY score_type_lookup_key NOT NULL;
ALTER TABLE chain.higg_config_module MODIFY score_type_id NOT NULL;
ALTER TABLE csrimp.higg_config_module MODIFY score_type_id NOT NULL;
BEGIN
	security.user_pkg.LogonAdmin;
	
	UPDATE csr.issue_type
	   SET helper_pkg = 'csr.compliance_pkg'
	 WHERE issue_type_id = 21
	   AND label = 'Compliance';
END;
/
BEGIN
	UPDATE csr.module_param
	   SET param_hint = 'Create regulation workflow? (Y/N)'
	 WHERE module_id = 79
	   AND param_name = 'in_enable_regulation_flow';
	UPDATE csr.module_param
	   SET param_hint = 'Create requirement workflow? (Y/N)'
	 WHERE module_id = 79
	   AND param_name = 'in_enable_requirement_flow';
	   
	UPDATE csr.module
	   SET module_name = 'Compliance - base'
	 WHERE module_id = 79;
END;
/
BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT sid_id
		  FROM security.menu
		 WHERE LOWER(action) = '/csr/site/enhesa/topiclist.acds'
	) LOOP
		security.securableobject_pkg.DeleteSO(security.security_pkg.GetAct, r.sid_id);
	END LOOP;
	
	FOR r IN (
		SELECT plugin_id
		  FROM csr.plugin
		 WHERE js_class = 'Controls.EnhesaTopicsTab'
	) LOOP
		DELETE FROM csr.property_tab_group
		 WHERE plugin_id = r.plugin_id;
		
		DELETE FROM csr.prop_type_prop_tab
		 WHERE plugin_id = r.plugin_id;
		   
		DELETE FROM csr.property_tab
		 WHERE plugin_id = r.plugin_id;
		 
		DELETE FROM csr.plugin
		 WHERE plugin_id = r.plugin_id;
	END LOOP;
END;
/
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) VALUES (1064,'My survey campaigns','Credit360.Portlets.MySurveyCampaigns', EMPTY_CLOB(),'/csr/site/portal/portlets/MySurveyCampaigns.js');
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH)
VALUES (1063, 'Site compliance levels', 'Credit360.Portlets.SiteComplianceLevels', EMPTY_CLOB(),'/csr/site/portal/portlets/SiteComplianceLevels.js');
DECLARE
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_act_id						security.security_pkg.T_ACT_ID;
	v_issue_man_capability_sid		security.security_pkg.T_SID_ID;	
	v_ehs_managers_sid				security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin;
	v_act_id := security.security_pkg.GetAct;
	-- Enable for all app_sids that have compliance
	FOR app IN (
		SELECT app_sid
		  FROM csr.customer
	)
	LOOP
		v_app_sid := app.app_sid;
		v_groups_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups');
		
		BEGIN
			v_ehs_managers_sid := security.securableObject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'EHS Managers');
		EXCEPTION WHEN OTHERS THEN
		  CONTINUE;
		END;
		
		BEGIN
			v_issue_man_capability_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Capabilities/Issue management');
		EXCEPTION WHEN OTHERS THEN
			CONTINUE;
		END;
		security.acl_pkg.AddACE(
			v_act_id,
			security.acl_pkg.GetDACLIDForSID(v_issue_man_capability_sid),
			-1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_ehs_managers_sid,
			security.security_pkg.PERMISSION_STANDARD_ALL
		);
	END LOOP;
END;
/
DELETE FROM csr.branding_availability
 WHERE client_folder_name = 'bettercoal';
DELETE FROM csr.branding
 WHERE client_folder_name = 'bettercoal';
insert into cms.col_type (col_type, description) values (39, 'Product');
DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_product_filter_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
	v_product_filter_card_id         chain.card.card_id%TYPE;
BEGIN
	-- Chain.Cards.Filters.CompanyCmsFilterAdapter
	v_desc := 'Chain Product CMS Adapter';
	v_class := 'Credit360.Chain.Cards.Filters.ProductCmsFilterAdapter';
	v_js_path := '/csr/site/chain/cards/filters/productCmsFilterAdapter.js';
	v_js_class := 'Chain.Cards.Filters.ProductCmsFilterAdapter';
	v_css_path := '';
	v_product_filter_js_class := 'Credit360.Chain.Filters.ProductFilter';
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
	BEGIN
		INSERT INTO chain.filter_type (
				filter_type_id,
				description,
				helper_pkg,
				card_id
			) VALUES (
				chain.filter_type_id_seq.NEXTVAL,
				'Chain Product CMS Filter',
				'chain.product_report_pkg',
				v_card_id
			);
		EXCEPTION
			WHEN dup_val_on_index THEN
				UPDATE chain.filter_type
				   SET description = 'Chain Product CMS Filter',
					   helper_pkg = 'chain.product_report_pkg'
				 WHERE card_id = v_card_id;
	END;
	SELECT card_id
	  INTO v_product_filter_card_id
	  FROM chain.card
	 WHERE js_class_type = v_product_filter_js_class;
	security.user_pkg.logonadmin;
	FOR r IN (
		SELECT c.app_sid, host 
		  FROM csr.customer c
		  JOIN chain.customer_options co on co.app_sid = c.app_sid
		 WHERE co.enable_product_compliance = 1
	) LOOP
		security.user_pkg.logonadmin(r.host);
		DELETE FROM chain.card_group_card
		 WHERE card_group_id = 56;
		
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		VALUES (r.app_sid, 56, v_product_filter_card_id, 0);
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		VALUES (r.app_sid, 56, v_card_id, 1);
	END LOOP;
	security.user_pkg.logonadmin;
END;
/
CREATE OR REPLACE PROCEDURE chain.Temp_RegisterCapability (
	in_capability_type			IN  NUMBER,
	in_capability				IN  VARCHAR2, 
	in_perm_type				IN  NUMBER,
	in_is_supplier				IN  NUMBER DEFAULT 0
)
AS
	v_count						NUMBER(10);
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
BEGIN
	chain.Temp_RegisterCapability(
		in_capability_type	=> 3,/*chain_pkg.CT_COMPANIES*/
		in_capability		=> 'Alternative company names',/*chain.chain_pkg.ALT_COMPANY_NAMES*/
		in_perm_type		=> 0/* chain.chain_pkg.SPECIFIC_PERMISSION */
	);
END;
/
DROP PROCEDURE chain.Temp_RegisterCapability;
DECLARE
	v_auto_imports_container_sid	NUMBER(10);
	v_automated_import_class_sid	NUMBER(10);
	v_ftp_profile_id				NUMBER(10);
	v_ftp_settings_id				NUMBER(10);
	v_inbox_sid						NUMBER(10);
	v_root_mailbox_sid				NUMBER(10);
	v_file_type_id					NUMBER(10);
BEGIN
	FOR cust IN (
		SELECT DISTINCT c.app_sid, c.host
		  FROM csr.meter_raw_data_source rds
		  JOIN csr.customer c ON c.app_sid = rds.app_sid
		 WHERE rds.automated_import_class_sid IS NULL
	) LOOP
		
		security.user_pkg.logonadmin(cust.host);
		-- Automated imports must be enabled
		BEGIN
			v_auto_imports_container_sid := security.securableobject_pkg.GetSidFromPath(
				security.security_pkg.GetACT, security.security_pkg.GetAPP, 'AutomatedImports');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				csr.TEMP_US6151_PACKAGE.EnableAutomatedExportImport;
		END;
		FOR rds IN (
			SELECT rds.raw_data_source_id, rds.xx_source_email source_email, rds.xx_source_folder source_folder, rds.process_body, eo.csv_delimiter,
				DECODE(rds.xx_raw_data_source_type_id, 1, NULL, cust.host || '/' || rds.xx_source_folder) ftp_path, 
				REPLACE(REPLACE(REPLACE(
					REGEXP_REPLACE(rds.xx_file_match_rx, '^(.*)\[.+\](.*)$', '\1\2'),	-- Remove anything in square brackets
					'.+', '*'),															-- Replace .+ with *
					'.*', '*'),															-- Replace .* with *
					'\.', '.')															-- Replace \. with .
				ftp_file_mask,
				CASE LOWER(rds.parser_type)
					WHEN 'csv' THEN 'dsv'
					WHEN 'excel' THEN 'excel'
					WHEN 'excel2' THEN 'excel'
					WHEN 'csvtimebycolumn' THEN 'dsv'
					WHEN 'exceltimebycolumn' THEN 'excel'
					WHEN 'xml' THEN 'xml'
					WHEN 'ediel' THEN 'ediel'
					WHEN 'wi5' THEN 'wi5'
				END file_type
			FROM csr.meter_raw_data_source rds
			LEFT JOIN csr.meter_excel_option eo ON eo.app_sid = rds.app_sid AND eo.raw_data_source_id = rds.raw_data_source_id
			WHERE rds.automated_import_class_sid IS NULL
		) LOOP
			-- Create Automated import class etc.
			csr.TEMP_US6151_PACKAGE.CreateClass(
				in_label						=> 'Meter data source ' || rds.raw_data_source_id,
				in_lookup_key					=> 'METER_DATA_SOURCE_' || rds.raw_data_source_id,
				in_schedule_xml					=> XMLType('<recurrences><daily/></recurrences>'),
				in_abort_on_error				=> 0,
				in_email_on_error				=> 'support@credit360.com',
				in_email_on_partial				=> NULL,
				in_email_on_success				=> NULL,
				in_on_completion_sp				=> NULL,
				in_import_plugin				=> NULL,
				in_process_all_pending_files	=> 1,
				out_class_sid					=> v_automated_import_class_sid
			);
			-- Make the schedule run at midnight
			UPDATE csr.automated_import_class
			   SET last_scheduled_dtm = TRUNC(SYSDATE, 'DD')
			 WHERE app_sid = cust.app_sid
			   AND automated_import_class_sid = v_automated_import_class_sid;
			-- FTP file readers for FTP sources
			IF rds.ftp_path IS NOT NULL THEN
				
				-- create FTP profile
				v_ftp_profile_id := csr.TEMP_US6151_PACKAGE.CreateCr360FTPProfile;
				
				-- create FTP settings
				v_ftp_settings_id := csr.TEMP_US6151_PACKAGE.MakeFTPReaderSettings(
					in_ftp_profile_id				=> v_ftp_profile_id,
					in_payload_path					=> '/' || rds.ftp_path || '/',
					in_file_mask					=> rds.ftp_file_mask,
					in_sort_by						=> 'DATE',
					in_sort_by_direction			=> 'ASC',
					in_move_to_path_on_success		=> '/' || rds.ftp_path || '/processed/',
					in_move_to_path_on_error		=> '/' || rds.ftp_path || '/error/',
					in_delete_on_success			=> 0,
					in_delete_on_error				=> 0
				);
				
				-- create step
				csr.TEMP_US6151_PACKAGE.AddFtpClassStep(
					in_import_class_sid				=> v_automated_import_class_sid,
					in_step_number					=> 1,
					in_on_completion_sp				=> 'csr.meter_monitor_pkg.QueueRawDataImportJob',
					in_days_to_retain_payload		=> 30,
					in_plugin						=> 'Credit360.ExportImport.Automated.Import.Plugins.MeterRawDataImportStepPlugin',
					in_ftp_settings_id				=> v_ftp_settings_id,
					in_importer_plugin_id			=> csr.TEMP_US6151_PACKAGE.IMPORT_PLUGIN_TYPE_METER_RD
				);
			END IF;
			-- Specific settings for email sources
			IF rds.source_email IS NOT NULL THEN
				v_inbox_sid := NULL;
				csr.TEMP_US6151_PACKAGE.AddClassStep(
					in_import_class_sid				=> v_automated_import_class_sid,
					in_step_number					=> 1,
					in_on_completion_sp				=> 'csr.meter_monitor_pkg.QueueRawDataImportJob',
					in_days_to_retain_payload		=> 30,
					in_plugin						=> 'Credit360.ExportImport.Automated.Import.Plugins.MeterRawDataImportStepPlugin',
					in_importer_plugin_id			=> csr.TEMP_US6151_PACKAGE.IMPORT_PLUGIN_TYPE_METER_RD,
					in_fileread_plugin_id			=> 3 /* Manual Instance Reader */
				);
				-- Get/create the inbox sid from the email address
				BEGIN
					v_inbox_sid := csr.TEMP_US6151_PACKAGE.getInboxSIDFromEmail(rds.source_email);
					-- We want the root mailbox sid
					-- TODO: Check it is the root mailbox we need
					SELECT root_mailbox_sid
					  INTO v_root_mailbox_sid
					  FROM mail.account
					 WHERE inbox_sid = v_inbox_sid;
					-- Associate the email/mailbox with the auto imp class sid 
					-- (extracted from automated_import_pkg.CreateMailbox as we 
					-- don't want to create a new mailbox here becasue it already exists)
					INSERT INTO csr.auto_imp_mailbox (address, mailbox_sid, 
						body_validator_plugin, 
						use_full_mail_logging, matched_imp_class_sid_for_body)
					VALUES (rds.source_email, v_root_mailbox_sid, 
						CASE rds.process_body WHEN 0 THEN NULL ELSE 'Credit360.ExportImport.Automated.Import.Mail.MailValidation.MeterRawDataValidatorPlugin' END, 
						1, v_automated_import_class_sid);
				
				EXCEPTION
					WHEN csr.TEMP_US6151_PACKAGE.MAILBOX_NOT_FOUND THEN
						-- Mailbox not found, create a new one
						csr.TEMP_US6151_PACKAGE.CreateMailbox(
							in_email_address				=> rds.source_email,
							in_body_plugin					=> CASE rds.process_body WHEN 0 THEN NULL ELSE 'Credit360.ExportImport.Automated.Import.Mail.MailValidation.MeterRawDataValidatorPlugin' END,
							in_use_full_logging				=> 1,
							in_matched_class_sid_for_body	=> v_automated_import_class_sid,
							in_user_sid						=> security.security_pkg.GetSID,
							out_new_sid						=> v_root_mailbox_sid
						);
						-- Get the new inbox sid
						v_inbox_sid := csr.TEMP_US6151_PACKAGE.getInboxSIDFromEmail(rds.source_email);
				END;
				-- Add an attachment filter too
				csr.TEMP_US6151_PACKAGE.AddAttachmentFilter(
					in_mailbox_sid					=> v_root_mailbox_sid,
					in_pos							=> 0,
					in_filter_string				=> '*',
					in_is_wildcard					=> 1,
					in_matched_import_class_sid		=> v_automated_import_class_sid,
					in_required_mimetype			=> NULL,
					in_attachment_validator_plugin	=> 'Credit360.ExportImport.Automated.Import.Mail.MailValidation.MeterRawDataValidatorPlugin'
				);
				-- Mark all existing mail in the inbox as read
				IF v_inbox_sid IS NOT NULL THEN
					FOR m IN (
						SELECT message_uid 
						  FROM mail.mailbox_message 
						 WHERE mailbox_sid = v_inbox_sid
						   AND bitand(flags, 4 + 2 /*mail_pkg.Flag_Seen + mail_pkg.Flag_Deleted*/) = 0
					) LOOP
						csr.TEMP_US6151_PACKAGE.MarkMessageAsRead(v_inbox_sid, m.message_uid);
					END LOOP;
				END IF;
			END IF;
			-- Get file type id
			SELECT automated_import_file_type_id
			  INTO v_file_type_id
			  FROM csr.automated_import_file_type
			 WHERE LOWER(label) = LOWER(rds.file_type);
			-- We're not converting the settings in the update script we'll get the code to 
			-- fall-back to the old settings tables if the xml does not specify the settings. 
			-- The next time the settings are saved they will be converted to the new format.
			csr.TEMP_US6151_PACKAGE.SetGenericImporterSettings(
				in_import_class_sid			=> v_automated_import_class_sid,
				in_step_number				=> 1,
				in_mapping_xml				=> XMLTYPE('<xml/>'),
				in_imp_file_type_id			=> v_file_type_id,
				in_dsv_separator			=> rds.csv_delimiter,
				in_dsv_quotes_as_literals	=> 0,
				in_excel_worksheet_index	=> 0,
				in_excel_row_index			=> 0,
				in_all_or_nothing			=> 0
			);
			-- Update meter_raw_data_source table
			UPDATE csr.meter_raw_data_source
			   SET automated_import_class_sid = v_automated_import_class_sid
			 WHERE app_sid = cust.app_sid
			   AND raw_data_source_id = rds.raw_data_source_id;
		END LOOP;
		security.user_pkg.logonadmin;
	END LOOP;
END;
/
BEGIN
	FOR r IN (
		 SELECT rds.app_sid, rds.raw_data_source_id, NVL(aic.label, 'Meter data source ' || rds.raw_data_source_id) label
		   FROM csr.meter_raw_data_source rds
		   LEFT JOIN csr.automated_import_class aic ON aic.app_sid = rds.app_sid AND aic.automated_import_class_sid = rds.automated_import_class_sid
	) LOOP
		UPDATE csr.meter_raw_data_source
		   SET label = r.label
		 WHERE app_sid = r.app_sid
		   AND raw_data_source_id = r.raw_data_source_id;
	END LOOP;
END;
/
ALTER TABLE CSR.METER_RAW_DATA_SOURCE MODIFY (
	LABEL						VARCHAR2(1024)	NOT NULL
);
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
	v_desc := 'Survey Response Filter';
	v_class := 'Credit360.QuickSurvey.Cards.SurveyResponseFilter';
	v_js_path := '/csr/site/quicksurvey/filters/surveyResponseFilter.js';
	v_js_class := 'Credit360.QuickSurvey.Filters.SurveyResponseFilter';
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
	v_desc := 'Survey Response Audit Filter Adapter';
	v_class := 'Credit360.QuickSurvey.Cards.SurveyResponseAuditFilterAdapter';
	v_js_path := '/csr/site/quicksurvey/filters/surveyResponseAuditFilterAdapter.js';
	v_js_class := 'Credit360.QuickSurvey.Filters.SurveyResponseAuditFilterAdapter';
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
	v_card_id						NUMBER(10);
	v_audit_filter_card_id			NUMBER(10);
	v_sid							NUMBER(10);
BEGIN
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES(54 /*chain.filter_pkg.FILTER_TYPE_QS_RESPONSES*/, 'Survey Response Filter', 'Allows filtering of survey responses', 'csr.quick_survey_report_pkg', '/csr/site/quickSurvey/responseList.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.QuickSurvey.Filters.SurveyResponseFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Survey Response Filter', 'csr.quick_survey_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	SELECT card_id
	  INTO v_audit_filter_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.QuickSurvey.Filters.SurveyResponseAuditFilterAdapter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Survey Response Audit Filter Adapter', 'csr.quick_survey_report_pkg', v_audit_filter_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	FOR r IN (
		SELECT app_sid FROM csr.customer
	) LOOP
		BEGIN
			v_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, r.app_sid, 'wwwroot/surveys');
				
			BEGIN
				INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
						VALUES (r.app_sid, 54 /*chain.filter_pkg.FILTER_TYPE_QS_RESPONSES*/, v_card_id, 0);
				EXCEPTION
			WHEN dup_val_on_index THEN
				NULL;
			END;
			
			v_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, r.app_sid, 'Audits');
				
			BEGIN
				INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
						VALUES (r.app_sid, 54 /*chain.filter_pkg.FILTER_TYPE_QS_RESPONSES*/, v_audit_filter_card_id, 1);
				EXCEPTION
			WHEN dup_val_on_index THEN
				NULL;
			END;
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL; -- Not a survey-enabled site, or not an audit-enabled site
		END;
	END LOOP;
END;
/
BEGIN
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (54 /*chain.filter_pkg.FILTER_TYPE_QS_RESPONSES*/, 1 /*csr.quick_survey_report_pkg.AGG_TYPE_COUNT*/, 'Number of survey responses');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (54 /*chain.filter_pkg.FILTER_TYPE_QS_RESPONSES*/, 2 /*csr.quick_survey_report_pkg.AGG_TYPE_SUM_SCORES*/, 'Sum of survey response scores');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (54 /*chain.filter_pkg.FILTER_TYPE_QS_RESPONSES*/, 3 /*csr.quick_survey_report_pkg.AGG_TYPE_AVG_SCORE*/, 'Average survey response score');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (54 /*chain.filter_pkg.FILTER_TYPE_QS_RESPONSES*/, 4 /*csr.quick_survey_report_pkg.AGG_TYPE_MAX_SCORE*/, 'Maximum survey response score');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (54 /*chain.filter_pkg.FILTER_TYPE_QS_RESPONSES*/, 5 /*csr.quick_survey_report_pkg.AGG_TYPE_MIN_SCORE*/, 'Minimum of survey response score');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/
BEGIN
	BEGIN
		INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
		VALUES (54 /*chain.filter_pkg.FILTER_TYPE_QS_RESPONSES*/, 1 /*chain.quick_survey_report_pkg.COL_TYPE_REGION_SID*/, 1 /*chain.filter_pkg.COLUMN_TYPE_REGION*/, 'Survey response region');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/
DECLARE
	v_exists number;
	v_constraint_name varchar2(40);
BEGIN
	
	SELECT constraint_name
		INTO v_constraint_name
		FROM dba_constraints 
		WHERE owner = 'ASPEN2' AND table_name = 'LANG_DEFAULT_INCLUDE' AND CONSTRAINT_TYPE = 'R' AND R_CONSTRAINT_NAME='PK_LANG' AND ROWNUM = 1;
	IF v_constraint_name IS NOT NULL AND v_constraint_name != 'FK_LANG_LANG_DEF_INC' THEN
		EXECUTE IMMEDIATE 'ALTER TABLE ASPEN2.LANG_DEFAULT_INCLUDE RENAME CONSTRAINT ' || v_constraint_name || ' TO FK_LANG_LANG_DEF_INC';
	END IF;
	
	SELECT count(constraint_name) 
		into v_exists 
		FROM all_cons_columns 
		WHERE table_name = 'TRANSLATION_SET' AND owner = 'ASPEN2' AND constraint_name = 'REFLANG4';
	IF v_exists > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE ASPEN2.TRANSLATION_SET RENAME CONSTRAINT REFLANG4 TO FK_LANG_TS';
	END IF;
	SELECT count(constraint_name)
		INTO v_exists
		FROM all_cons_columns 
		WHERE table_name = 'TRANSLATED' AND owner = 'ASPEN2' AND constraint_name = 'REFTRANSLATION_SET3';
	IF v_exists > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE ASPEN2.TRANSLATED RENAME CONSTRAINT REFTRANSLATION_SET3 TO FK_TRANSLATED_TS';
	END IF;
	SELECT count(constraint_name)
		INTO v_exists
		FROM all_cons_columns 
		WHERE table_name = 'TRANSLATION_SET_INCLUDE' AND owner = 'ASPEN2' AND constraint_name = 'REFTRANSLATION_SET6';
	IF v_exists > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE ASPEN2.TRANSLATION_SET_INCLUDE RENAME CONSTRAINT REFTRANSLATION_SET6 TO FK_TS_TO_TSI';
	END IF;
	SELECT count(constraint_name)
		INTO v_exists
		FROM all_cons_columns 
		WHERE table_name = 'TRANSLATION_SET_INCLUDE' AND owner = 'ASPEN2' AND constraint_name = 'REFTRANSLATION_SET7';
	
		
	IF v_exists > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE ASPEN2.TRANSLATION_SET_INCLUDE RENAME CONSTRAINT REFTRANSLATION_SET7 TO FK_TS_TSI';
	END IF;
	
	SELECT COUNT(*) INTO v_exists FROM all_constraints WHERE owner = 'CSR' and constraint_name = 'FK_REGION_DESC_ASPEN2_TS';
	IF v_exists = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.REGION_DESCRIPTION ADD CONSTRAINT FK_REGION_DESC_ASPEN2_TS
			FOREIGN KEY (APP_SID, LANG)
			REFERENCES ASPEN2.TRANSLATION_SET (APPLICATION_SID, LANG)';
	END IF;
	SELECT COUNT(*) INTO v_exists FROM all_constraints WHERE owner = 'CSR' and constraint_name = 'FK_REGION_DESC_ASPEN2_TS';
	IF v_exists = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.REGION_DESCRIPTION ADD CONSTRAINT FK_REGION_DESC_ASPEN2_TS
			FOREIGN KEY (APP_SID, LANG)
			REFERENCES ASPEN2.TRANSLATION_SET (APPLICATION_SID, LANG)';
	END IF;
	SELECT COUNT(*) INTO v_exists FROM all_constraints WHERE owner = 'CSR' and constraint_name = 'FK_DELEG_REG_DESC_ASPEN2_TS';
	IF v_exists = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.DELEGATION_REGION_DESCRIPTION ADD CONSTRAINT FK_DELEG_REG_DESC_ASPEN2_TS
			FOREIGN KEY (APP_SID, LANG)
			REFERENCES ASPEN2.TRANSLATION_SET (APPLICATION_SID, LANG)';
	END IF;
END;
/
ALTER TABLE aspen2.translation_set         DISABLE CONSTRAINT fk_lang_ts;
ALTER TABLE aspen2.translated              DISABLE CONSTRAINT fk_translated_ts;
ALTER TABLE aspen2.translation_set_include DISABLE CONSTRAINT fk_ts_to_tsi;
ALTER TABLE aspen2.translation_set_include DISABLE CONSTRAINT fk_ts_tsi;
ALTER TABLE aspen2.lang_default_include	   DISABLE CONSTRAINT fk_lang_lang_def_inc;
ALTER TABLE csr.ind_description            DISABLE CONSTRAINT fk_ind_description_aspen2_ts;
ALTER TABLE csr.region_description         DISABLE CONSTRAINT fk_region_desc_aspen2_ts;
ALTER TABLE csr.delegation_ind_description DISABLE CONSTRAINT fk_deleg_ind_desc_aspen2_ts;
ALTER TABLE csr.delegation_region_description DISABLE CONSTRAINT fk_deleg_reg_desc_aspen2_ts;
ALTER TABLE csr.dataview_ind_description   DISABLE CONSTRAINT fk_dv_ind_desc_aspen2_ts;
ALTER TABLE csr.alert_frame_body           DISABLE CONSTRAINT fk_alert_frm_bdy_tran_set;
ALTER TABLE csr.alert_template_body        DISABLE CONSTRAINT fk_alt_tpl_bdy_bdy_tran_set;
DECLARE
	PROCEDURE MigrateLanguageCode (
		in_obsolete_lang	VARCHAR2,
		in_valid_lang		VARCHAR2
	)
	AS
		v_obsolete_lang		VARCHAR2(10) := lower(in_obsolete_lang);
		v_valid_lang		VARCHAR2(10) := lower(in_valid_lang);
	BEGIN
		UPDATE aspen2.lang                    SET     lang = v_valid_lang WHERE     lang = v_obsolete_lang;
		UPDATE aspen2.translation_set         SET     lang = v_valid_lang WHERE     lang = v_obsolete_lang;
		UPDATE aspen2.translated              SET     lang = v_valid_lang WHERE     lang = v_obsolete_lang;
		UPDATE aspen2.translation_set_include SET     lang = v_valid_lang WHERE     lang = v_obsolete_lang;
		UPDATE aspen2.translation_set_include SET  to_lang = v_valid_lang WHERE  to_lang = v_obsolete_lang;
		UPDATE aspen2.lang_default_include    SET     lang = v_valid_lang WHERE     lang = v_obsolete_lang;
		UPDATE csr.ind_description            SET     lang = v_valid_lang WHERE     lang = v_obsolete_lang;
		UPDATE csr.region_description         SET     lang = v_valid_lang WHERE     lang = v_obsolete_lang;
		UPDATE csr.delegation_description     SET     lang = v_valid_lang WHERE     lang = v_obsolete_lang;		
		UPDATE csr.delegation_ind_description SET     lang = v_valid_lang WHERE     lang = v_obsolete_lang;		
		UPDATE csr.delegation_region_description SET  lang = v_valid_lang WHERE     lang = v_obsolete_lang;		
		UPDATE csr.dataview_ind_description   SET     lang = v_valid_lang WHERE     lang = v_obsolete_lang;		
		UPDATE csr.alert_frame_body           SET     lang = v_valid_lang WHERE     lang = v_obsolete_lang;
		UPDATE csr.alert_template_body        SET     lang = v_valid_lang WHERE     lang = v_obsolete_lang;
		UPDATE security.user_table            SET language = v_valid_lang WHERE language = v_obsolete_lang;
	END;
	
BEGIN
	MigrateLanguageCode('az-AZ-Cyrl', 'az-Cyrl-AZ');
	MigrateLanguageCode('az-AZ-Latn', 'az-Latn-AZ');
	MigrateLanguageCode('div', 'dv');
	MigrateLanguageCode('div-MV', 'dv-MV');
	MigrateLanguageCode('en-CB', 'en-029');
	MigrateLanguageCode('kh', 'km');
	MigrateLanguageCode('ky-kz', 'ky-kg');
	MigrateLanguageCode('sr-SP-Cyrl', 'sr-Cyrl-RS');
	MigrateLanguageCode('sr-SP-Latn', 'sr-Latn-RS');
	MigrateLanguageCode('uz-UZ-Cyrl', 'uz-Cyrl-UZ');
	MigrateLanguageCode('uz-UZ-Latn', 'uz-Latn-UZ');
	-- We don't need to fix these as Microsoft aliased them. Also they appear in tr.xml.
	-- { "zh-CHT", "zh-Hant" },
	-- { "zh-CHS", "zh-Hans" }
END;
/
ALTER TABLE aspen2.translation_set         ENABLE CONSTRAINT fk_lang_ts;
ALTER TABLE aspen2.translated              ENABLE CONSTRAINT fk_translated_ts;
ALTER TABLE aspen2.translation_set_include ENABLE CONSTRAINT fk_ts_to_tsi;
ALTER TABLE aspen2.translation_set_include ENABLE CONSTRAINT fk_ts_tsi;
ALTER TABLE aspen2.lang_default_include	   ENABLE CONSTRAINT fk_lang_lang_def_inc;
ALTER TABLE csr.ind_description            ENABLE CONSTRAINT fk_ind_description_aspen2_ts;
ALTER TABLE csr.region_description         ENABLE CONSTRAINT fk_region_desc_aspen2_ts;
ALTER TABLE csr.delegation_ind_description ENABLE CONSTRAINT fk_deleg_ind_desc_aspen2_ts;
ALTER TABLE csr.delegation_region_description ENABLE CONSTRAINT fk_deleg_reg_desc_aspen2_ts;
ALTER TABLE csr.dataview_ind_description   ENABLE CONSTRAINT fk_dv_ind_desc_aspen2_ts;
ALTER TABLE csr.alert_frame_body           ENABLE CONSTRAINT fk_alert_frm_bdy_tran_set;
ALTER TABLE csr.alert_template_body        ENABLE CONSTRAINT fk_alt_tpl_bdy_bdy_tran_set;


 
DROP PACKAGE CSR.TEMP_US6151_PACKAGE;

revoke select on mail.account_alias from csr;
revoke update on mail.mailbox from csr;
revoke update on mail.mailbox_message from csr;

CREATE OR REPLACE PACKAGE chain.dedupe_proc_record_report_pkg AS END;
/
GRANT EXECUTE ON chain.dedupe_proc_record_report_pkg TO web_user;
CREATE OR REPLACE PACKAGE csr.quick_survey_report_pkg AS END;
/
GRANT EXECUTE ON csr.quick_survey_report_pkg TO chain;
GRANT EXECUTE ON csr.quick_survey_report_pkg TO web_user;
grant execute on chain.product_type_pkg to csr;

@..\csr_data_pkg
@..\delegation_pkg
@..\supplier\audit_pkg
@..\indicator_pkg
@..\compliance_pkg
@..\enable_pkg
@@..\compliance_library_report_pkg
@@..\compliance_pkg
@..\batch_job_pkg
@..\chain\company_dedupe_pkg
@..\templated_report_pkg
@..\region_picker_pkg
@@..\geo_map_pkg
@..\chain\chain_pkg
@..\chain\higg_pkg
@..\chain\higg_setup_pkg
DROP PACKAGE csr.enhesa_pkg;
@@..\issue_pkg
@@..\schema_pkg
@@..\csr_data_pkg
@@..\folderlib_pkg
@..\..\..\aspen2\cms\db\filter_pkg
@..\..\..\aspen2\cms\db\tab_pkg
@..\chain\company_product_pkg
@..\meter_pkg
@..\meter_monitor_pkg
@..\chain\dedupe_admin_pkg
@..\automated_import_pkg
@..\chain\company_pkg
@..\chain\filter_pkg
@..\chain\dedupe_proc_record_report_pkg
@@..\quick_survey_pkg
@..\quick_survey_report_pkg
@..\chain\product_type_pkg


@..\csr_data_body
@..\delegation_body
@..\supplier\audit_body
@..\testdata_body
@..\indicator_body
@..\scenario_body
@..\scenario_run_body
@..\chain\plugin_body
@..\schema_body
@..\csrimp\imp_body
@..\compliance_body
@@..\role_body
@..\enable_body
@..\customer_body
@@..\..\..\aspen2\cms\db\form_body
@@..\enable_body
@@..\compliance_library_report_body
@@..\compliance_register_report_body
@@..\compliance_body
@@..\schema_body
@@..\csrimp\imp_body
@..\user_report_body
@@..\..\..\aspen2\cms\db\tab_body
@..\chain\company_dedupe_body
@..\templated_report_body
@..\region_picker_body
@..\region_body
@@..\region_body
@@..\geo_map_body
@@..\property_report_body
@..\chain\higg_body
@..\chain\higg_setup_body
@@..\issue_body
@@..\issue_report_body
@@..\csr_app_body
@@..\folderlib_body
@@..\campaign_body
@..\branding_body
@..\chain\type_capability_body
@@..\user_report_body
@..\..\..\aspen2\cms\db\filter_body
@..\chain\company_product_body
@..\chain\product_report_body
@..\plugin_body
@..\meter_monitor_body
@..\meter_body
@..\quick_survey_body
@..\automated_import_body
@..\chain\company_body
@..\schema_body 
@..\chain\chain_body
@..\chain\company_filter_body
@..\chain\filter_body
@..\chain\dedupe_admin_body
@..\chain\dedupe_proc_record_report_body
@..\chain\setup_body
@@..\quick_survey_body
@..\meter_duff_region_body
@..\quick_survey_report_body
@..\chain\product_type_body
@..\chain\helper_body



@update_tail
