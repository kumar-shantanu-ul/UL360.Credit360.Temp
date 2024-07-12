define version=3035
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

-- Following block copied from ^/csr/db/utils/populateMeterDataIds.sql
--
-- This was run as an ad-hoc script on live, but will need to be run here
-- if applying to an on-premises database.
BEGIN
	-- 
	FOR r IN (
		SELECT DISTINCT app_sid, region_sid
		  FROM csr.meter_live_data
		 WHERE meter_data_id IS NULL
	) LOOP
		-- Cases where an id exists in meter_data_id
		FOR d IN (
			SELECT id.app_sid, id.region_sid, id.meter_bucket_id, id.meter_input_id, 
				id.aggregator, id.priority, id.start_dtm, id.meter_data_id
			  FROM csr.meter_live_data l
			  JOIN csr.meter_data_id id
			    ON id.app_sid = l.app_sid
			   AND id.region_sid = l.region_sid
			   AND id.meter_bucket_id = l.meter_bucket_id
			   AND id.meter_input_id = l.meter_input_id
			   AND id.aggregator = l.aggregator
			   AND id.priority = l.priority
			   AND id.start_dtm = l.start_dtm
			 WHERE l.app_sid = r.app_sid
			   AND l.region_Sid = r.region_sid
			   AND l.meter_data_id IS NULL
		) LOOP
			UPDATE csr.meter_live_data
			   SET meter_data_id = d.meter_data_id
			 WHERE app_sid = d.app_sid
			   AND region_sid = d.region_sid
			   AND meter_bucket_id = d.meter_bucket_id
			   AND meter_input_id = d.meter_input_id
			   AND aggregator = d.aggregator
			   AND priority = d.priority
			   AND start_dtm = d.start_dtm
			   AND meter_data_id IS NULL;
		END LOOP;

		-- Cases where there's no id in meter_data_id
		FOR d IN (
			SELECT l.app_sid, l.region_sid, l.meter_bucket_id, l.meter_input_id, 
				l.aggregator, l.priority, l.start_dtm
			  FROM csr.meter_live_data l
			 WHERE l.app_sid = r.app_sid
			   AND l.region_Sid = r.region_sid
			   AND l.meter_data_id IS NULL
			   AND NOT EXISTS (
				SELECT 1
				  FROM csr.meter_data_id id
				 WHERE id.app_sid = l.app_sid
				   AND id.region_sid = l.region_sid
				   AND id.meter_bucket_id = l.meter_bucket_id
				   AND id.meter_input_id = l.meter_input_id
				   AND id.aggregator = l.aggregator
				   AND id.priority = l.priority
				   AND id.start_dtm = l.start_dtm
			)
		) LOOP
			UPDATE csr.meter_live_data
			   SET meter_data_id = csr.meter_data_id_seq.NEXTVAL
			 WHERE app_sid = d.app_sid
			   AND region_sid = d.region_sid
			   AND meter_bucket_id = d.meter_bucket_id
			   AND meter_input_id = d.meter_input_id
			   AND aggregator = d.aggregator
			   AND priority = d.priority
			   AND start_dtm = d.start_dtm
			   AND meter_data_id IS NULL;
		END LOOP;

		-- Commit per region
		COMMIT;
	END LOOP;
END;
/

ALTER TABLE CSR.METER_LIVE_DATA MODIFY (
	METER_DATA_ID		NUMBER(10)	NOT NULL
);
ALTER INDEX CSR.UK_METER_DATA_ID RENAME TO UK_METER_DATA_ID_OLD;
ALTER TABLE CSR.METER_LIVE_DATA ADD (
	CONSTRAINT UK_METER_DATA_ID UNIQUE (APP_SID, METER_DATA_ID)
);
CREATE SEQUENCE CHAIN.DEDUPE_PREPROC_RULE_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;
CREATE TABLE CHAIN.DEDUPE_PREPROC_COMP (
	APP_SID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	COMPANY_SID 			NUMBER(10) NOT NULL,
	NAME 					VARCHAR2(255) NOT NULL,
	ADDRESS 				VARCHAR2(1024),
	CITY	 				VARCHAR2(255),
	STATE 					VARCHAR2(255),
	POSTCODE 				VARCHAR2(255),
	WEBSITE 				VARCHAR2(1000),
	PHONE					VARCHAR2(255),
	EMAIL_DOMAIN 			VARCHAR2(255),
	UPDATED_DTM 			DATE,
	CONSTRAINT PK_DEDUPE_PREPROC_COMP PRIMARY KEY (APP_SID, COMPANY_SID)
);
ALTER TABLE CHAIN.DEDUPE_PREPROC_COMP ADD CONSTRAINT COMPANY_DEDUPE_PREPROC_COMP 
	FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CHAIN.COMPANY (APP_SID,COMPANY_SID);
	
CREATE TABLE CHAIN.DEDUPE_PREPROC_RULE (
	APP_SID						NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	DEDUPE_PREPROC_RULE_ID 		NUMBER(10) NOT NULL,
	PATTERN 					VARCHAR2(1000) NOT NULL,
	REPLACEMENT 				VARCHAR2(1000),
	RUN_ORDER 					NUMBER(10) NOT NULL,
	CONSTRAINT UC_DEDUPE_PREPROC_RULE UNIQUE (APP_SID, RUN_ORDER) DEFERRABLE INITIALLY DEFERRED,
	CONSTRAINT CHK_DP_PP_RULE_PATT_REP CHECK (PATTERN <> REPLACEMENT),
	CONSTRAINT PK_DEDUPE_PREPROC_RULE PRIMARY KEY (APP_SID, DEDUPE_PREPROC_RULE_ID)
);
ALTER TABLE CHAIN.DEDUPE_PREPROC_RULE ADD CONSTRAINT REF_DEDUPE_PREPROCESS_RULE_APP
	FOREIGN KEY (APP_SID)
	REFERENCES CHAIN.CUSTOMER_OPTIONS(APP_SID)
;
CREATE TABLE CHAIN.DEDUPE_PP_FIELD_CNTRY (
	APP_SID 					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	DEDUPE_PREPROC_RULE_ID 		NUMBER(10) NOT NULL,
	DEDUPE_FIELD_ID 			NUMBER(10),
	COUNTRY_CODE				VARCHAR2(2),
	CONSTRAINT UC_DEDUPE_PP_FIELD_CNTRY UNIQUE (APP_SID, DEDUPE_PREPROC_RULE_ID, DEDUPE_FIELD_ID, COUNTRY_CODE)
);
ALTER TABLE CHAIN.DEDUPE_PP_FIELD_CNTRY ADD CONSTRAINT DD_PP_RULE_DD_PP_FIELD_CNTRY 
	FOREIGN KEY (APP_SID, DEDUPE_PREPROC_RULE_ID) REFERENCES CHAIN.DEDUPE_PREPROC_RULE (APP_SID,DEDUPE_PREPROC_RULE_ID);
ALTER TABLE CHAIN.DEDUPE_PP_FIELD_CNTRY ADD CONSTRAINT DD_FIELD_DD_PP_FIELD_CNTRY 
	FOREIGN KEY (DEDUPE_FIELD_ID) REFERENCES CHAIN.DEDUPE_FIELD (DEDUPE_FIELD_ID);
ALTER TABLE CHAIN.DEDUPE_PP_FIELD_CNTRY ADD CONSTRAINT COUNTRY_DD_PP_FIELD_CNTRY 
	FOREIGN KEY (COUNTRY_CODE) REFERENCES POSTCODE.COUNTRY (COUNTRY);
CREATE TABLE CSRIMP.CHAIN_DEDUPE_PREPRO_COMP (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	COMPANY_SID NUMBER(10,0) NOT NULL,
	ADDRESS VARCHAR2(1024),
	CITY VARCHAR2(255),
	NAME VARCHAR2(255) NOT NULL,
	POSTCODE VARCHAR2(255),
	STATE VARCHAR2(255),
	WEBSITE VARCHAR2(1000),
	PHONE VARCHAR2(255),
	EMAIL_DOMAIN VARCHAR2(255),
	UPDATED_DTM DATE,
	CONSTRAINT PK_CHAIN_DEDUPE_PREPRO_COMP PRIMARY KEY (CSRIMP_SESSION_ID, COMPANY_SID),
	CONSTRAINT FK_CHAIN_DEDUPE_PREPRO_COMP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.CHAIN_DEDUPE_PREPRO_RULE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DEDUPE_PREPROC_RULE_ID NUMBER(10,0) NOT NULL,
	PATTERN VARCHAR2(1000) NOT NULL,
	REPLACEMENT VARCHAR2(1000),
	RUN_ORDER NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_CHAIN_DEDUPE_PREPRO_RULE PRIMARY KEY (CSRIMP_SESSION_ID, DEDUPE_PREPROC_RULE_ID),
	CONSTRAINT FK_CHAIN_DEDUPE_PREPRO_RULE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.CHAIN_DEDU_PP_FIEL_CNTRY (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	COUNTRY_CODE VARCHAR2(2),
	DEDUPE_FIELD_ID NUMBER(10,0),
	DEDUPE_PREPROC_RULE_ID NUMBER(10,0) NOT NULL,
	CONSTRAINT FK_CHAIN_DEDU_PP_FIEL_CNTRY_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.MAP_CHAIN_DEDU_PREP_RULE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CHAIN_DEDUP_PREPRO_RULE_ID NUMBER(10) NOT NULL,
	NEW_CHAIN_DEDUP_PREPRO_RULE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_DEDU_PREP_RULE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CHAIN_DEDUP_PREPRO_RULE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_DEDU_PREP_RULE UNIQUE (CSRIMP_SESSION_ID, NEW_CHAIN_DEDUP_PREPRO_RULE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_DEDU_PREP_RULE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
--Failed to locate all sections of latest3022_4.sql
--Failed to process contents of latest3022_6.sql
--Failed to locate all sections of latest3022_6.sql
CREATE TABLE csr.compliance_item_status (
	compliance_item_status_id			NUMBER(10) NOT NULL,
	description							VARCHAR2(255) NOT NULL,
	pos									NUMBER(10) NOT NULL,
	CONSTRAINT pk_compliance_item_status PRIMARY KEY (compliance_item_status_id)
);
INSERT INTO csr.compliance_item_status (compliance_item_status_id, description, pos) VALUES (1, 'Draft', 1);
INSERT INTO csr.compliance_item_status (compliance_item_status_id, description, pos) VALUES (2, 'Published', 2);
INSERT INTO csr.compliance_item_status (compliance_item_status_id, description, pos) VALUES (3, 'Retired', 3);
CREATE TABLE csr.compliance_item_source (
	compliance_item_source_id			NUMBER(10) NOT NULL,
	description							VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_compliance_item_source PRIMARY KEY (compliance_item_source_id)
);
INSERT INTO csr.compliance_item_source (compliance_item_source_id, description) VALUES (0, 'User entered');
INSERT INTO csr.compliance_item_source (compliance_item_source_id, description) VALUES (1, 'Enhesa');
CREATE TABLE csr.compliance_item_change_type (
	compliance_item_change_type_id	NUMBER(10,0)	NOT NULL,
	description						VARCHAR2(100)	NOT NULL,
	source							NUMBER(10,0)	NOT NULL,
	change_type_index				NUMBER(10,0)	NOT NULL,
	CONSTRAINT pk_compliance_item_change_type PRIMARY KEY (compliance_item_change_type_id)
);
CREATE SEQUENCE CSR.COMPLIANCE_ITEM_HISTORY_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;
CREATE TABLE CSR.COMPLIANCE_ITEM_HISTORY (
    app_sid                         NUMBER(10, 0)  	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    compliance_item_history_id      NUMBER(10, 0)   NOT NULL,
    compliance_item_id              NUMBER(10, 0)   NOT NULL,
    change_type                     NUMBER(10, 0),
    major_version	                NUMBER(10, 0)	NOT NULL,
	minor_version					NUMBER(10, 0)	NOT NULL,
	is_major_change					NUMBER(1, 0),
    description                     CLOB,
    change_dtm                      DATE			 DEFAULT SYSDATE NOT NULL,
	CONSTRAINT PK_COMPLIANCE_ITEM_HISTORY PRIMARY KEY (APP_SID, COMPLIANCE_ITEM_HISTORY_ID),
	CONSTRAINT fk_compliance_item_his_ci_ct 
		FOREIGN KEY (change_type)
		REFERENCES csr.compliance_item_change_type (compliance_item_change_type_id)
);
CREATE TABLE csrimp.compliance_item_history (
    csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    compliance_item_history_id      NUMBER(10, 0)   NOT NULL,
    compliance_item_id              NUMBER(10, 0)   NOT NULL,
    change_type                     NUMBER(10, 0),
    major_version	                NUMBER(10, 0)	NOT NULL,
	minor_version					NUMBER(10, 0)	NOT NULL,
	is_major_change					NUMBER(1, 0),
    description                     CLOB,
    change_dtm                      DATE            NOT NULL,
	CONSTRAINT pk_compliance_item_history PRIMARY KEY (csrimp_session_id, compliance_item_history_id),
    CONSTRAINT fk_compliance_item_history_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);
CREATE TABLE csrimp.map_compliance_item_history (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_compliance_item_history_id	NUMBER(10) NOT NULL,
	new_compliance_item_history_id	NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_compliance_item_history PRIMARY KEY (csrimp_session_id, old_compliance_item_history_id),
	CONSTRAINT uk_map_compliance_item_history UNIQUE (csrimp_session_id, new_compliance_item_history_id),
    CONSTRAINT fk_map_compliance_item_history FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);
CREATE SEQUENCE chain.dedupe_rule_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;
CREATE TABLE chain.dedupe_rule_type (
	dedupe_rule_type_id 						NUMBER(10) NOT NULL,
	description 								VARCHAR2(100) NOT NULL,
	threshold_default 							NUMBER(3) NOT NULL,
	CONSTRAINT pk_dedupe_rule_type PRIMARY KEY (dedupe_rule_type_id), 
	CONSTRAINT chk_dd_rule_type_threshold CHECK (threshold_default <=100 AND threshold_default > 0)
);
CREATE TABLE chain.dedupe_no_match_action (
	dedupe_no_match_action_id			NUMBER(10) NOT NULL,
	description 						VARCHAR2(100) NOT NULL,
	CONSTRAINT pk_dedupe_no_match_action PRIMARY KEY (dedupe_no_match_action_id)
);
CREATE TABLE CSRIMP.MAP_CHAIN_DEDUPE_RULE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_DEDUPE_RULE_ID NUMBER(10) NOT NULL,
	NEW_DEDUPE_RULE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_DEDUPE_RULE_X PRIMARY KEY (CSRIMP_SESSION_ID, OLD_DEDUPE_RULE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_DEDUPE_RULE_X UNIQUE (CSRIMP_SESSION_ID, NEW_DEDUPE_RULE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_DEDUPE_RULE_IS_X FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE csr.property_fund_ownership (
    app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	region_sid						NUMBER(10, 0) NOT NULL,
	fund_id							NUMBER(10, 0) NOT NULL,
	start_dtm						DATE NOT NULL,
	ownership						NUMBER(29, 28) NOT NULL,
	CONSTRAINT pk_property_fund_ownership PRIMARY KEY (app_sid, region_sid, fund_id, start_dtm),
    CONSTRAINT ck_ownerships CHECK (ownership >= 0 AND ownership <= 1)
);
CREATE TABLE csrimp.property_fund_ownership (
	csrimp_session_id				NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	region_sid						NUMBER(10, 0) NOT NULL,
	fund_id							NUMBER(10, 0) NOT NULL,
	start_dtm						DATE NOT NULL,
	ownership						NUMBER(29, 28) NOT NULL,
	CONSTRAINT pk_property_fund_ownership PRIMARY KEY (csrimp_session_id, region_sid, fund_id, start_dtm),
	CONSTRAINT fk_property_fund_ownership FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);
INSERT INTO csr.property_fund_ownership (app_sid, region_sid, fund_id, start_dtm, ownership)
	SELECT app_sid, region_sid, fund_id, DATE'1900-01-01', ownership
	  FROM csr.property_fund;


DROP INDEX CSR.IX_METER_LIVE_DATA_ID;
DROP INDEX CSR.UK_METER_DATA_ID_OLD;
DROP INDEX CSR.IX_METER_DATA_ID_REGION;
DROP INDEX CSR.IX_METER_DATA_ID_APP;
DROP TABLE CSR.METER_DATA_ID CASCADE CONSTRAINTS;
DROP TABLE CSRIMP.METER_DATA_ID CASCADE CONSTRAINTS;
CREATE INDEX CSR.IX_TEMP_METER_CONSUMPTION ON CSR.TEMP_METER_CONSUMPTION (
	REGION_SID, METER_INPUT_ID, PRIORITY, START_DTM
);
ALTER TABLE csr.img_chart ADD (
	scenario_run_sid		NUMBER(10, 0),
	use_unmerged			NUMBER(1, 0)      DEFAULT 0 NOT NULL
);
ALTER TABLE csr.img_chart ADD CONSTRAINT FK_IMG_CHART_SCENARIO_RUN
	FOREIGN KEY (APP_SID, SCENARIO_RUN_SID)
	REFERENCES CSR.SCENARIO_RUN (APP_SID, SCENARIO_RUN_SID)
;
ALTER TABLE csr.img_chart ADD CONSTRAINT CK_IMG_CHART_USE_UNMERGED CHECK (USE_UNMERGED IN (0,1));
create index csr.ix_img_chart_scenario_run_ on csr.img_chart (app_sid, scenario_run_sid);
ALTER TABLE chain.customer_options ADD enable_dedupe_preprocess NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE chain.customer_options ADD CONSTRAINT chk_co_enable_preprocess CHECK (enable_dedupe_preprocess IN (0,1));
ALTER TABLE csrimp.chain_customer_options ADD enable_dedupe_preprocess NUMBER(1);
ALTER TABLE csrimp.chain_customer_options ADD CONSTRAINT chk_co_enable_preprocess CHECK (enable_dedupe_preprocess IN (0,1));
create index chain.ix_dedupe_pp_fld_country_field on chain.dedupe_pp_field_cntry (dedupe_field_id);
create index chain.ix_dedupe_pp_fld_country_count on chain.dedupe_pp_field_cntry (country_code);
BEGIN
	DBMS_SCHEDULER.CREATE_JOB (
		job_name        => 'chain.DedupePreprocessing',
		job_type        => 'PLSQL_BLOCK',
		job_action      => 'chain.dedupe_preprocess_pkg.RunPreprocessJob;',
		job_class       => 'low_priority_job',
		start_date      => to_timestamp_tz('2008/01/01 05:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		repeat_interval => 'FREQ=HOURLY;',
		enabled         => TRUE,
		auto_drop       => FALSE,
		comments        => 'Create Dedupe preprocessing batch job');
END;
/
	
ALTER TABLE csr.section_val ADD (
    period_set_id           NUMBER(10, 0),
    period_interval_id      NUMBER(10, 0)
);
ALTER TABLE chain.business_relationship_tier ADD (
	create_sup_rels_w_lower_tiers			NUMBER(1, 0) DEFAULT 0 NOT NULL,
	CONSTRAINT ck_bus_rel_tier_ctsrwlt CHECK (create_sup_rels_w_lower_tiers IN (0, 1))
);
ALTER TABLE csrimp.chain_busine_relati_tier ADD (
	create_sup_rels_w_lower_tiers			NUMBER(1, 0) NOT NULL
);
ALTER TABLE CSR.IMG_CHART ADD (
	SCENARIO_RUN_TYPE		NUMBER(1, 0)      DEFAULT 0 NOT NULL
);
ALTER TABLE CSRIMP.IMG_CHART ADD (
	SCENARIO_RUN_SID		NUMBER(10, 0),
	SCENARIO_RUN_TYPE		NUMBER(1, 0)      DEFAULT 0 NOT NULL
);
ALTER TABLE csr.deleg_plan ADD last_applied_dynamic NUMBER(1);
ALTER TABLE csrimp.deleg_plan ADD last_applied_dynamic NUMBER(1);
DECLARE
	v_newest_st	NUMBER(10);
BEGIN
	FOR r IN (SELECT app_sid FROM csr.compliance_options)
	LOOP
		SELECT MAX(quick_survey_type_id)
		  INTO v_newest_st
		  FROM csr.compliance_options
		 WHERE app_sid = r.app_sid;
		IF (v_newest_st IS NOT NULL) THEN 
			DELETE FROM csr.compliance_options
			 WHERE quick_survey_type_id != v_newest_st
			   AND app_sid = r.app_sid;
			   
			DELETE FROM csr.quick_survey_type
			 WHERE quick_survey_type_id != v_newest_st
			   AND app_sid = r.app_sid
			   AND cs_class = 'Credit360.QuickSurvey.ComplianceSurveyType';
		 END IF;
	END LOOP;
END;
/
ALTER TABLE csr.compliance_options 
  ADD CONSTRAINT pk_compliance_options PRIMARY KEY (app_sid);
CREATE TABLE csr.compliance_region_tag( 
    APP_SID             NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    TAG_ID			    NUMBER(10, 0)    NOT NULL,
    REGION_SID			NUMBER(10, 0)	 NOT NULL,
	CONSTRAINT PK_COMP_REGION_TAG PRIMARY KEY (APP_SID, TAG_ID, REGION_SID)
);
ALTER TABLE csr.compliance_region_tag ADD CONSTRAINT FK_COMP_REGION_TAG_TAG
    FOREIGN KEY (APP_SID, TAG_ID)
    REFERENCES CSR.TAG(APP_SID, TAG_ID)
;
ALTER TABLE csr.compliance_region_tag ADD CONSTRAINT FK_COMP_REGION_TAG_REGION
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES CSR.REGION(APP_SID, REGION_SID)
;
CREATE TABLE csrimp.compliance_region_tag( 
	CSRIMP_SESSION_ID	NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	TAG_ID				NUMBER(10, 0)	NOT NULL,
	REGION_SID			NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_comp_region_tag PRIMARY KEY (csrimp_session_id, TAG_ID, REGION_SID),
	CONSTRAINT fk_comp_region_tag_is
		FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id) 
		ON DELETE CASCADE
);
CREATE INDEX csr.ix_comp_reg_tag_region_sid ON csr.compliance_region_tag (app_sid, region_sid);
CREATE INDEX csr.ix_comp_reg_tag_tag_id ON csr.compliance_region_tag (app_sid, tag_id);
  
ALTER TABLE CSR.compliance_item_history ADD CONSTRAINT fk_cih_ci
    FOREIGN KEY (app_sid, compliance_item_id)
    REFERENCES csr.compliance_item(app_sid, compliance_item_id)
;
ALTER TABLE csr.compliance_item DROP CONSTRAINT ck_compliance_item_source;
ALTER TABLE csr.compliance_item ADD (
	compliance_item_status_id			NUMBER(10) DEFAULT 1 NOT NULL,
	major_version             			NUMBER(10) DEFAULT 1 NOT NULL,
    minor_version             			NUMBER(10) DEFAULT 0 NOT NULL,
	CONSTRAINT fk_compliance_item_ci_status
			FOREIGN KEY (compliance_item_status_id)
			REFERENCES csr.compliance_item_status (compliance_item_status_id),
	CONSTRAINT fk_compliance_item_ci_source 
		FOREIGN KEY (source)
		REFERENCES csr.compliance_item_source (compliance_item_source_id)
);
create index csr.ix_compliance_it_status on csr.compliance_item (compliance_item_status_id);
create index csr.ix_compliance_it_source on csr.compliance_item (source);
ALTER TABLE csrimp.compliance_item ADD (
	compliance_item_status_id			NUMBER(10) NOT NULL,
	major_version						NUMBER(10) NOT NULL,
	minor_version						NUMBER(10) NOT NULL
);
create index csr.ix_compliance_it_his_ct on csr.compliance_item_history (change_type);
create index csr.ix_compliance_it_compliance_it on csr.compliance_item_history (app_sid, compliance_item_id);
ALTER TABLE chain.dedupe_rule ADD dedupe_rule_type_id NUMBER(10) DEFAULT 1 NOT NULL;
ALTER TABLE chain.dedupe_rule ADD match_threshold NUMBER(3) DEFAULT 100 NOT NULL;
BEGIN
	INSERT INTO chain.dedupe_rule_type (dedupe_rule_type_id, description, threshold_default) 
		VALUES (1, 'Exact match (case insensitive)', 100);
END;
/
ALTER TABLE chain.dedupe_rule ADD CONSTRAINT fk_dedupe_rule_rule_type
	FOREIGN KEY (dedupe_rule_type_id) REFERENCES chain.dedupe_rule_type (dedupe_rule_type_id);
ALTER TABLE chain.dedupe_rule MODIFY dedupe_rule_type_id DEFAULT NULL;
ALTER TABLE chain.dedupe_rule MODIFY match_threshold DEFAULT NULL;
ALTER TABLE chain.dedupe_rule ADD CONSTRAINT chk_dd_rule_threshold CHECK (match_threshold <=100 AND match_threshold > 0);
ALTER TABLE chain.dedupe_rule_set ADD dedupe_match_type_id NUMBER(10) DEFAULT 2 NOT NULL;
ALTER TABLE CHAIN.DEDUPE_RULE ADD DEDUPE_RULE_ID NUMBER(10);
BEGIN	
	security.user_pkg.logonadmin;
	UPDATE chain.dedupe_rule SET dedupe_rule_id = chain.dedupe_rule_id_seq.nextval;
END;
/
ALTER TABLE CHAIN.DEDUPE_RULE MODIFY DEDUPE_RULE_ID NOT NULL;
ALTER TABLE CHAIN.DEDUPE_RULE DROP CONSTRAINT PK_DEDUPE_RULE;
ALTER TABLE CHAIN.DEDUPE_RULE ADD CONSTRAINT PK_DEDUPE_RULE PRIMARY KEY (APP_SID, DEDUPE_RULE_ID); 
ALTER TABLE CHAIN.DEDUPE_RULE_SET ADD DESCRIPTION VARCHAR2(255);
BEGIN
	security.user_pkg.logonadmin;
	UPDATE chain.dedupe_rule_set SET description = 'Rule-'||DEDUPE_RULE_SET_ID;
END;
/
ALTER TABLE CHAIN.DEDUPE_RULE_SET MODIFY DESCRIPTION NOT NULL;
ALTER TABLE csrimp.chain_dedupe_rule_set ADD DESCRIPTION VARCHAR2(255) NOT NULL;
ALTER TABLE csrimp.chain_dedupe_rule_set ADD DEDUPE_MATCH_TYPE_ID NUMBER(10) NOT NULL;
ALTER TABLE csrimp.chain_dedupe_rule_set RENAME CONSTRAINT PK_CHAIN_DEDUPE_RULE TO PK_CHAIN_DEDUPE_RULE_SET;
ALTER TABLE csrimp.chain_dedupe_rule_set RENAME CONSTRAINT FK_CHAIN_DEDUPE_RULE_IS TO FK_CHAIN_DEDUPE_RULE_SET_IS;
ALTER TABLE CSRIMP.CHAIN_DEDUPE_RULE ADD DEDUPE_RULE_ID NUMBER(10) NOT NULL;
ALTER TABLE CSRIMP.CHAIN_DEDUPE_RULE ADD DEDUPE_RULE_TYPE_ID NUMBER(10) NOT NULL;
ALTER TABLE CSRIMP.CHAIN_DEDUPE_RULE ADD MATCH_THRESHOLD NUMBER(3) NOT NULL;
ALTER TABLE CSRIMP.CHAIN_DEDUPE_RULE RENAME CONSTRAINT PK_CHAIN_DEDUPE_RULE_MAPPIN TO PK_CHAIN_DEDUPE_RULE;
ALTER TABLE CSRIMP.CHAIN_DEDUPE_RULE RENAME CONSTRAINT FK_CHAIN_DEDUPE_RULE_MAPPIN_IS TO FK_CHAIN_DEDUPE_RULE_IS;
ALTER TABLE CSRIMP.MAP_CHAIN_DEDUPE_RULE_SET RENAME CONSTRAINT PK_MAP_CHAIN_DEDUPE_RULE TO PK_MAP_CHAIN_DD_RULE_SET;
ALTER TABLE CSRIMP.MAP_CHAIN_DEDUPE_RULE_SET RENAME CONSTRAINT UK_MAP_CHAIN_DEDUPE_RULE TO UK_MAP_CHAIN_DD_RULE_SET;
ALTER TABLE CSRIMP.MAP_CHAIN_DEDUPE_RULE_SET RENAME CONSTRAINT FK_MAP_CHAIN_DEDUPE_RULE_IS TO FK_MAP_CHAIN_DD_RULE_SET_IS;
ALTER TABLE CSRIMP.MAP_CHAIN_DEDUPE_RULE RENAME CONSTRAINT PK_MAP_CHAIN_DEDUPE_RULE_X TO PK_MAP_CHAIN_DEDUPE_RULE;
ALTER TABLE CSRIMP.MAP_CHAIN_DEDUPE_RULE RENAME CONSTRAINT UK_MAP_CHAIN_DEDUPE_RULE_X TO UK_MAP_CHAIN_DEDUPE_RULE;
ALTER TABLE CSRIMP.MAP_CHAIN_DEDUPE_RULE RENAME CONSTRAINT FK_MAP_CHAIN_DEDUPE_RULE_IS_X TO FK_MAP_CHAIN_DEDUPE_RULE_IS;
grant select on chain.dedupe_match_type to CSR;
ALTER TABLE chain.dedupe_rule_set ADD CONSTRAINT fk_dedupe_rule_set_match_type 
	FOREIGN KEY (dedupe_match_type_id) REFERENCES chain.dedupe_match_type (dedupe_match_type_id);
	
ALTER TABLE chain.dedupe_rule_set MODIFY dedupe_match_type_id DEFAULT NULL;
ALTER TABLE chain.import_source RENAME COLUMN can_create TO dedupe_no_match_action_id;
ALTER TABLE chain.import_source DROP CONSTRAINT chk_can_create;
ALTER TABLE chain.import_source MODIFY dedupe_no_match_action_id DEFAULT 1;
ALTER TABLE csrimp.chain_import_source RENAME COLUMN can_create TO dedupe_no_match_action_id;
BEGIN
	security.user_pkg.logonadmin;
	UPDATE chain.import_source SET dedupe_no_match_action_id = 1;
END;
/
BEGIN	
	INSERT INTO chain.dedupe_no_match_action (dedupe_no_match_action_id, description) 
		VALUES (1, 'Auto create company');
END;
/
ALTER TABLE chain.import_source ADD CONSTRAINT fk_imp_source_no_match_action
	FOREIGN KEY (dedupe_no_match_action_id) REFERENCES chain.dedupe_no_match_action (dedupe_no_match_action_id);
DROP TABLE CHAIN.TT_DEDUPE_PROCESSED_ROW;
CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_DEDUPE_PROCESSED_ROW(
	DEDUPE_PROCESSED_RECORD_ID	NUMBER(10, 0) NOT NULL,
	DEDUPE_STAGING_LINK_ID		NUMBER(10, 0) NOT NULL,
	REFERENCE					VARCHAR(512) NOT NULL,
	ITERATION_NUM				NUMBER(10, 0) NOT NULL,
	BATCH_NUM					NUMBER(10, 0) NULL,
	PROCESSED_DTM				DATE NOT NULL,
	MATCHED_TO_COMPANY_SID		NUMBER(10, 0),
	DEDUPE_ACTION_TYPE_ID		NUMBER(10, 0),
	MATCHED_DTM					DATE,
	MATCHED_BY_USER_SID			NUMBER(10, 0),
	MATCHED_TO_COMPANY_NAME		VARCHAR(512),
	IMPORT_SOURCE_NAME			VARCHAR(512) NOT NULL,
	CREATED_COMPANY_SID 		NUMBER(10, 0),
	CREATED_COMPANY_NAME		VARCHAR(512),
	DATA_MERGED					NUMBER(1,0),
	CMS_RECORD_ID 				NUMBER(10, 0),
	STAGING_LINK_DESCRIPTION 	VARCHAR(512),
	IMPORTED_USER_SID 			NUMBER(10),
	IMPORTED_USER_NAME 			VARCHAR2(256),
	MERGE_STATUS				NUMBER(10),
	ERROR_MESSAGE				VARCHAR2(4000),
	FORM_LOOKUP_KEY				VARCHAR2(255),
	DEDUPE_ACTION	 			NUMBER(1)
)
ON COMMIT DELETE ROWS;
ALTER TABLE chain.dedupe_processed_record ADD (
	batch_job_id						NUMBER(10) NULL,
	merge_status_id						NUMBER(10) NULL,
	error_message						VARCHAR2(4000) NULL,
	error_detail						VARCHAR2(4000) NULL,
	CONSTRAINT chk_ddp_prc_rec_bat_job CHECK ((batch_job_id IS NULL AND merge_status_id IS NULL) OR (batch_job_id IS NOT NULL AND merge_status_id IS NOT NULL))
);
ALTER TABLE csrimp.CHAIN_DEDUP_PROCE_RECORD ADD (
	merge_status_id						NUMBER(10) NULL
);
ALTER TABLE chain.dedupe_processed_record
  ADD dedupe_action NUMBER(1);
ALTER TABLE chain.dedupe_processed_record
  ADD CONSTRAINT chk_dedupe_action CHECK (dedupe_action IN (1,2,3));
ALTER TABLE chain.dedupe_processed_record DROP CONSTRAINT fk_dedupe_process_rec_match;
ALTER TABLE chain.dedupe_processed_record RENAME COLUMN dedupe_match_type_id TO dedupe_action_type_id;
ALTER TABLE chain.dedupe_processed_record 
	ADD CONSTRAINT chk_action_type_id CHECK (dedupe_action_type_id IN (1,2)); 
ALTER TABLE csrimp.chain_dedup_proce_record ADD dedupe_action NUMBER(1);
ALTER TABLE csrimp.chain_dedup_proce_record RENAME COLUMN dedupe_match_type_id TO dedupe_action_type_id;
create index chain.ix_dedupe_rule_dedupe_rule_t on chain.dedupe_rule (dedupe_rule_type_id);
create index chain.ix_dedupe_rule_s_dedupe_match_ on chain.dedupe_rule_set (dedupe_match_type_id);
create index chain.ix_import_source_dedupe_no_mat on chain.import_source (dedupe_no_match_action_id);
ALTER TABLE csr.property_fund DROP COLUMN ownership;
ALTER TABLE csr.property_fund_ownership ADD CONSTRAINT fk_pfo_pf
    FOREIGN KEY (app_sid, region_sid, fund_id)
    REFERENCES csr.property_fund(app_sid, region_sid, fund_id);
ALTER TABLE csrimp.property_fund DROP COLUMN ownership;


grant select, insert, update, delete on csrimp.chain_dedupe_prepro_comp to tool_user;
grant select, insert, update, delete on csrimp.chain_dedupe_prepro_rule to tool_user;
grant select, insert, update, delete on csrimp.chain_dedu_pp_fiel_cntry to tool_user;
grant select, insert, update on chain.dedupe_preproc_comp to csrimp;
grant select, insert, update on chain.dedupe_preproc_rule to csrimp;
grant select, insert, update on chain.dedupe_pp_field_cntry to csrimp;
grant select on chain.dedupe_preproc_rule_id_seq to csrimp;
grant select on chain.dedupe_preproc_rule_id_seq to CSR;
grant select, insert, update on chain.dedupe_preproc_comp to CSR;
grant select, insert, update on chain.dedupe_preproc_rule to CSR;
grant select, insert, update on chain.dedupe_pp_field_cntry to CSR;
GRANT SELECT, INSERT, UPDATE ON csr.compliance_region_tag TO csrimp;
GRANT SELECT ON chain.dedupe_rule_type TO csr;
GRANT SELECT ON chain.dedupe_rule_id_seq TO csrimp;
GRANT SELECT ON cms.v$form TO chain;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.property_fund_ownership TO tool_user;
GRANT SELECT, INSERT, UPDATE ON csr.property_fund_ownership TO csrimp;


ALTER TABLE CSR.IMG_CHART ADD CONSTRAINT CK_IMG_CHART_SCN_RUN_TYPE CHECK (SCENARIO_RUN_TYPE IN (0,1,2));
ALTER TABLE chain.dedupe_processed_record
ADD CONSTRAINT fk_ddp_prc_rec_batch_job FOREIGN KEY (app_sid, batch_job_id)
	REFERENCES csr.batch_job (app_sid, batch_job_id);
create index chain.ix_dedupe_processed_rec_batch on chain.dedupe_processed_record (app_sid, batch_job_id);
ALTER INDEX chain.ix_dedupe_proces_dedupe_match_ RENAME TO ix_dedupe_proces_dedupe_actn;


CREATE OR REPLACE VIEW csr.v$corp_rep_capability AS
	SELECT sec.app_sid, sec.section_sid, fsrc.flow_capability_id,
	   MAX(BITAND(fsrc.permission_set, 1)) + -- security_pkg.PERMISSION_READ
	   MAX(BITAND(fsrc.permission_set, 2)) permission_set -- security_pkg.PERMISSION_WRITE
	  FROM csr.section sec
	  JOIN csr.section_module secmod ON sec.app_sid = secmod.app_sid
	   AND sec.module_root_sid = secmod.module_root_sid
	  JOIN csr.flow_item fi ON sec.app_sid = fi.app_sid
	   AND sec.flow_item_id = fi.flow_item_id
	  JOIN csr.flow_state_role_capability fsrc ON fi.app_sid = fsrc.app_sid
	   AND fi.current_state_id = fsrc.flow_state_id
	  LEFT JOIN csr.region_role_member rrm ON sec.app_sid = rrm.app_sid
	   AND secmod.region_sid = rrm.region_sid
	   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND rrm.role_sid = fsrc.role_sid
	 WHERE sec.active = 1
	   AND rrm.role_sid IS NOT NULL
	 GROUP BY sec.app_sid, sec.section_sid, fsrc.flow_capability_id;
	 
CREATE OR REPLACE VIEW csr.v$factor_type AS
SELECT f.factor_type_id, f.parent_id, f.name, f.std_measure_id, f.egrid, af.active, uf.in_use, mf.mapped
  FROM csr.factor_type f
  LEFT JOIN (
    SELECT factor_type_id, 1 mapped FROM (
          SELECT DISTINCT f.factor_type_id
            FROM csr.factor_type f
                 START WITH f.factor_type_id
                  IN (
              SELECT DISTINCT f.factor_type_id
                FROM csr.factor_type f
                JOIN csr.ind i ON i.factor_type_id = f.factor_type_id
                 AND i.app_sid = security.security_pkg.getApp
               WHERE std_measure_id IS NOT NULL
            )
          CONNECT BY PRIOR parent_id = f.factor_type_id
        )) mf ON f.factor_type_id = mf.factor_type_id
  LEFT JOIN (
    SELECT factor_type_id, 1 active FROM (
          SELECT DISTINCT af.factor_type_id
            FROM csr.factor_type af
           START WITH af.factor_type_id
            IN (
              SELECT DISTINCT aaf.factor_type_id
                FROM csr.factor_type aaf
                JOIN csr.std_factor sf ON sf.factor_type_id = aaf.factor_type_id
                JOIN csr.std_factor_set_active sfa ON sfa.std_factor_set_id = sf.std_factor_set_id
            )
           CONNECT BY PRIOR parent_id = af.factor_type_id
          UNION
          SELECT DISTINCT f.factor_type_id
            FROM csr.factor_type f
                 START WITH f.factor_type_id
                  IN (
              SELECT DISTINCT f.factor_type_id
                FROM csr.factor_type f
                JOIN csr.custom_factor sf ON sf.factor_type_id = f.factor_type_id
                 AND sf.app_sid = security.security_pkg.getApp
               WHERE std_measure_id IS NOT NULL
            )
          CONNECT BY PRIOR parent_id = f.factor_type_id
          UNION
          SELECT 3 factor_type_id -- factor_pkg.UNSPECIFIED_FACTOR_TYPE
            FROM dual
        )) af ON f.factor_type_id = af.factor_type_id
   LEFT JOIN (
    SELECT factor_type_id, 1 in_use FROM (
      SELECT factor_type_id
        FROM csr.factor_type
       START WITH factor_type_id
          IN (
          SELECT DISTINCT factor_type_id
            FROM csr.factor
           WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
      )
      CONNECT BY PRIOR parent_id = factor_type_id
      UNION
      SELECT DISTINCT f.factor_type_id
        FROM csr.factor_type f
             START WITH f.factor_type_id
              IN (
          SELECT DISTINCT f.factor_type_id
            FROM csr.factor_type f
            JOIN csr.custom_factor sf ON sf.factor_type_id = f.factor_type_id
             AND sf.app_sid = security.security_pkg.getApp
           WHERE std_measure_id IS NOT NULL
        )
      CONNECT BY PRIOR parent_id = f.factor_type_id
      UNION
      SELECT factor_type_id
        FROM csr.factor_type
       START WITH factor_type_id
          IN (
          SELECT DISTINCT factor_type_id
            FROM csr.factor
           WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
      )
      CONNECT BY PRIOR factor_type_id = parent_id
      UNION
      SELECT 3 factor_type_id -- factor_pkg.UNSPECIFIED_FACTOR_TYPE
        FROM dual
        )) uf ON f.factor_type_id = uf.factor_type_id;
		
CREATE OR REPLACE VIEW csr.v$property_fund_ownership AS 
	SELECT fo.app_sid, 
		   fo.region_sid, 
		   fo.fund_id, 
		   f.name,
		   pf.container_sid,
		   fo.start_dtm, 
		   LEAD(fo.start_dtm) OVER (PARTITION BY fo.app_sid, fo.region_sid, fo.fund_id 
										ORDER BY fo.start_dtm) end_dtm, 
		   fo.ownership
	  FROM property_fund_ownership fo
	  JOIN property_fund pf ON fo.app_sid = pf.app_sid AND pf.region_sid = fo.region_sid AND fo.fund_id = pf.fund_id
	  JOIN fund f ON fo.app_sid = f.app_sid AND fo.fund_id = f.fund_id
	 ORDER BY fo.region_sid, fo.fund_id, fo.start_dtm;
	 
CREATE OR REPLACE VIEW csr.v$property AS
    SELECT r.app_sid, r.region_sid, r.description, r.parent_sid, r.lookup_key, r.region_ref, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode, c.country country_code,
        c.name country_name, c.currency country_currency, r.geo_type,
        pt.property_type_id, pt.label property_type_label,
        pst.property_sub_type_id, pst.label property_sub_type_label,
        p.flow_item_id, fi.current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key, fs.state_colour current_state_colour,
        r.active, r.acquisition_dtm, r.disposal_dtm, geo_longitude lng, geo_latitude lat, pf.fund_id,
        mgmt_company_id, mgmt_company_other, mgmt_company_contact_id, p.company_sid, p.pm_building_id,
        pt.lookup_key property_type_lookup_key,
        p.energy_star_sync, p.energy_star_push
      FROM property p
        JOIN v$region r ON p.region_sid = r.region_sid AND p.app_sid = r.app_sid
        LEFT JOIN postcode.country c ON r.geo_country = c.country
        LEFT JOIN property_type pt ON p.property_type_id = pt.property_type_id AND p.app_sid = pt.app_sid
        LEFT JOIN property_sub_type pst ON p.property_sub_type_id = pst.property_sub_type_id AND p.app_sid = pst.app_sid
        LEFT JOIN flow_item fi ON p.flow_item_id = fi.flow_item_id AND p.app_sid = fi.app_sid
        LEFT JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid
		LEFT JOIN (
			-- In the case of multiple fund ownership, the "default" fund is the fund with the highest
			-- current ownership. Where multiple funds have the same ownership, the default is the 
			-- fund that was created first. Fund ID is retained for compatibility with pre-multi 
			-- ownership code.
			SELECT
				app_sid, region_sid, fund_id, ownership,
				ROW_NUMBER() OVER (PARTITION BY app_sid, region_sid
								   ORDER BY start_dtm DESC, ownership DESC, fund_id ASC) priority
			FROM csr.property_fund_ownership
		) pf ON pf.app_sid = r.app_sid AND pf.region_sid = r.region_sid AND pf.priority = 1;




BEGIN
	FOR r IN (
		SELECT DISTINCT app_sid, merged_scenario_run_sid
		  FROM csr.customer
	) LOOP
		UPDATE csr.img_chart
		   SET scenario_run_sid = r.merged_scenario_run_sid
		 WHERE app_sid = r.app_sid;
	END LOOP;
END;
/
BEGIN
	UPDATE csr.img_chart
	   SET scenario_run_type = use_unmerged
	 WHERE scenario_run_sid IS NULL;
	
	UPDATE csr.img_chart
	   SET scenario_run_type = 2
	 WHERE scenario_run_sid IS NOT NULL;
END;
/
ALTER TABLE CSR.IMG_CHART ADD CONSTRAINT CK_IMG_CHART_SCN_RUN_SID 
CHECK ((SCENARIO_RUN_TYPE = 2 AND SCENARIO_RUN_SID IS NOT NULL) OR
	   (SCENARIO_RUN_TYPE IN (0,1) AND SCENARIO_RUN_SID IS NULL));
ALTER TABLE csr.img_chart DROP COLUMN use_unmerged;
insert into csr.source_type (source_type_id, description)
values (16, 'Fixed calc result');
CREATE PROCEDURE CSR.LatestSaveRule(
	in_scenario_sid					IN	scenario_rule.scenario_sid%TYPE,
	in_rule_id						IN	scenario_rule.rule_id%TYPE,
	in_description					IN	scenario_rule.description%TYPE,
	in_rule_type					IN	scenario_rule.rule_type%TYPE,
	in_amount						IN	scenario_rule.amount%TYPE,
	in_measure_conversion_id		IN	scenario_rule.measure_conversion_id%TYPE,
	in_start_dtm					IN	scenario_rule.start_dtm%TYPE,
	in_end_dtm						IN	scenario_rule.end_dtm%TYPE,
	in_indicators					IN	security_pkg.T_SID_IDS,
	in_regions						IN	security_pkg.T_SID_IDS,
	out_rule_id						OUT	scenario_rule.rule_id%TYPE
)
AS
	v_dummy					scenario.scenario_sid%TYPE;
	v_regions				security.T_SID_TABLE;
	v_indicators			security.T_SID_TABLE;
BEGIN
	-- Lock the scenario row so we get a consistent rule id
	SELECT scenario_sid
	  INTO v_dummy
	  FROM scenario
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid
	  	   FOR UPDATE;
	IF in_rule_id IS NULL THEN
		SELECT NVL(MAX(rule_id), 0) + 1
		  INTO out_rule_id
		  FROM scenario_rule
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid;
		INSERT INTO scenario_rule
			(scenario_sid, rule_id, description, rule_type, amount, measure_conversion_id, start_dtm, end_dtm)
		VALUES
			(in_scenario_sid, out_rule_id, in_description, in_rule_type, in_amount, in_measure_conversion_id, in_start_dtm, in_end_dtm);
	ELSE
		UPDATE scenario_rule
		   SET description = in_description,
		   	   rule_type = in_rule_type,
		   	   amount = in_amount,
		   	   measure_conversion_id = in_measure_conversion_id,
		   	   start_dtm = in_start_dtm,
		   	   end_dtm = in_end_dtm
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid AND rule_id = in_rule_id;
		 
		DELETE FROM scenario_rule_region
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid AND rule_id = in_rule_id;
		DELETE FROM scenario_like_for_like_rule
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid AND rule_id = in_rule_id;
		 
		DELETE FROM scenario_rule_ind
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid AND rule_id = in_rule_id;
		out_rule_id := in_rule_id;		
	END IF;
	
	v_regions := security_pkg.SidArrayToTable(in_regions);
	INSERT INTO scenario_rule_region (app_sid, scenario_sid, rule_id, region_sid)
		SELECT SYS_CONTEXT('SECURITY', 'APP'), in_scenario_sid, out_rule_id, column_value
		   FROM TABLE(v_regions);
	
	v_indicators := security_pkg.SidArrayToTable(in_indicators);
	INSERT INTO scenario_rule_ind (app_sid, scenario_sid, rule_id, ind_sid)
		SELECT SYS_CONTEXT('SECURITY', 'APP'), in_scenario_sid, out_rule_id, column_value
		   FROM TABLE(v_indicators);
END;
/
CREATE PROCEDURE CSR.LatestSaveScenarioRule(
	in_scenario_run_sid				IN	scenario_run.scenario_run_sid%TYPE
)
AS
	v_scenario_sid					scenario.scenario_sid%TYPE;
	v_empty_sids					security_pkg.T_SID_IDS;
	v_rule_id						scenario_rule.rule_id%TYPE;
	v_app_sid						security_pkg.T_SID_ID;
BEGIN
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	
	SELECT scenario_sid
	  INTO v_scenario_sid
	  FROM scenario_run
	 WHERE scenario_run_sid = in_scenario_run_sid
	   AND app_sid = v_app_sid;
	 
	SELECT max(rule_id)
	  INTO v_rule_id
	  FROM scenario_rule
	 WHERE scenario_sid = v_scenario_sid
	   AND rule_type = 7 --scenario_pkg.RT_FIXCALCRESULTS
	   AND app_sid = v_app_sid;
	-- Save the rule with no inds and regions; the scenario can be shared across multiple dashboards
	-- so we need to add these later in a query.
	CSR.LatestSaveRule(
		in_scenario_sid				=> v_scenario_sid,
		in_rule_id					=> v_rule_id,
		in_description				=> 'Approval dashboard calcs',
		in_rule_type				=> 7, --scenario_pkg.RT_FIXCALCRESULTS,
		in_amount					=> 0,
		in_measure_conversion_id	=> NULL,
		in_start_dtm				=> DATE '1990-01-01',
		in_end_dtm					=> DATE '2021-01-01',
		in_indicators				=> v_empty_sids,
		in_regions					=> v_empty_sids,
		out_rule_id					=> v_rule_id
	);
	
	INSERT INTO scenario_rule_region (app_sid, scenario_sid, rule_id, region_sid)
		SELECT DISTINCT v_app_sid, v_scenario_sid, v_rule_id, region_sid
		  FROM approval_dashboard_region adr
		  JOIN approval_dashboard ad ON ad.approval_dashboard_sid = adr.approval_dashboard_sid
		 WHERE (active_period_scenario_run_sid = in_scenario_run_sid OR signed_off_scenario_run_sid = in_scenario_run_sid)
		   AND adr.app_sid = v_app_sid;
	
	INSERT INTO scenario_rule_ind (app_sid, scenario_sid, rule_id, ind_sid)
		SELECT DISTINCT v_app_sid, v_scenario_sid, v_rule_id, ind_sid
		  FROM approval_dashboard_ind adi
		  JOIN approval_dashboard ad ON ad.approval_dashboard_sid = adi.approval_dashboard_sid
		 WHERE (active_period_scenario_run_sid = in_scenario_run_sid OR signed_off_scenario_run_sid = in_scenario_run_sid)
		   AND adi.app_sid = v_app_sid;
END;
/
BEGIN
	security.user_pkg.logonadmin;
	FOR h IN (
		SELECT host
		  FROM csr.customer
		 WHERE app_sid IN (
			SELECT DISTINCT app_sid 
			  FROM csr.approval_dashboard
		)
	) 
	LOOP
		security.user_pkg.logonadmin(h.host);
		FOR r IN (
			SELECT active_period_scenario_run_sid scenario_run_sid
			  FROM csr.approval_dashboard
			 WHERE active_period_scenario_run_sid IS NOT NULL
			 UNION
			SELECT signed_off_scenario_run_sid scenario_run_sid
			  FROM csr.approval_dashboard
			 WHERE signed_off_scenario_run_sid IS NOT NULL
		) LOOP
			CSR.LatestSaveScenarioRule(r.scenario_run_sid);
		END LOOP;
	END LOOP;
	security.user_pkg.logonadmin;
END;
/
DROP PROCEDURE CSR.LatestSaveRule;
DROP PROCEDURE CSR.LatestSaveScenarioRule;
DECLARE
	v_company_score_cap_id	NUMBER;
	v_supplier_score_cap_id	NUMBER;
	v_company_cap_id		NUMBER;
	v_supplier_cap_id		NUMBER;
BEGIN
	-- Log out of any apps from other scripts
	security.user_pkg.LogonAdmin;
	-- Change to specific capability and rename
	UPDATE chain.capability
	   SET capability_name = 'Company scores',
		   perm_type = 0
	 WHERE capability_name = 'Set company scores';
	
	SELECT capability_id INTO v_company_score_cap_id  FROM chain.capability WHERE is_supplier = 0 AND capability_name = 'Company scores';
	SELECT capability_id INTO v_supplier_score_cap_id FROM chain.capability WHERE is_supplier = 1 AND capability_name = 'Company scores';
	SELECT capability_id INTO v_company_cap_id		  FROM chain.capability WHERE is_supplier = 0 AND capability_name = 'Company';
	SELECT capability_id INTO v_supplier_cap_id		  FROM chain.capability WHERE is_supplier = 1 AND capability_name = 'Suppliers';
	-- We already have write capability from previous type, add read capbability from company
	-- There are some instances where user has write on score but not read on company
	UPDATE chain.company_type_capability cs
	   SET cs.permission_set = cs.permission_set + NVL((
		SELECT BITAND(permission_set, 1)
		  FROM chain.company_type_capability c
		 WHERE c.app_sid = cs.app_sid
		   AND c.primary_company_type_id = cs.primary_company_type_id
		   AND NVL(c.secondary_company_type_id, -1) = NVL(cs.secondary_company_type_id, -1)
		   AND NVL(c.primary_company_group_type_id, -1) = NVL(cs.primary_company_group_type_id, -1)
		   AND NVL(c.primary_company_type_role_sid, -1) = NVL(cs.primary_company_type_role_sid, -1)
		   AND c.capability_id IN (v_company_cap_id, v_supplier_cap_id)
		), 0)
	 WHERE cs.capability_id IN (v_company_score_cap_id, v_supplier_score_cap_id)
	   AND cs.permission_set IN (0, 2); -- check we haven't applied read permission before so script is rerunnable
	
	-- Where we have no capability already (i.e. no row in company_type_capability), we still want read access
	INSERT INTO chain.company_type_capability (app_sid, primary_company_type_id, secondary_company_type_id,
		   primary_company_group_type_id, primary_company_type_role_sid, capability_id, permission_set)
	SELECT app_sid, primary_company_type_id, secondary_company_type_id,
		   primary_company_group_type_id, primary_company_type_role_sid, 
		   DECODE(capability_id, v_company_cap_id, v_company_score_cap_id, v_supplier_cap_id, v_supplier_score_cap_id), 1
	  FROM chain.company_type_capability cs
	 WHERE BITAND(permission_set, 1) = 1
	   AND capability_id IN (v_company_cap_id, v_supplier_cap_id)
	   AND NOT EXISTS (
		SELECT *
		  FROM chain.company_type_capability c
		 WHERE c.app_sid = cs.app_sid
		   AND c.primary_company_type_id = cs.primary_company_type_id
		   AND NVL(c.secondary_company_type_id, -1) = NVL(cs.secondary_company_type_id, -1)
		   AND NVL(c.primary_company_group_type_id, -1) = NVL(cs.primary_company_group_type_id, -1)
		   AND NVL(c.primary_company_type_role_sid, -1) = NVL(cs.primary_company_type_role_sid, -1)
		   AND c.capability_id IN (v_company_score_cap_id, v_supplier_score_cap_id)
		);
END;
/
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (29, 'Migrate Emission Factor tool', '** It needs to be tested against test environments before applying Live**. It migrates old emission factor settings to the new Emission Factor Profile tool.','MigrateEmissionFactorTool','W2990');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (29, 'Profile Name', 'Profile Name', 0, 'Migrated profile');
BEGIN
	security.user_pkg.LogOnAdmin;
	FOR s IN (
		SELECT host, app_sid
		  FROM (
			SELECT DISTINCT w.website_name host, c.app_sid,
				   ROW_NUMBER() OVER (PARTITION BY c.app_sid ORDER BY c.app_sid) rn
			  FROM csr.customer c
			  JOIN security.website w ON c.app_sid = w.application_sid_id
		)
		 WHERE rn = 1
	)
	LOOP
		security.user_pkg.LogOnAdmin(s.host);
		
		UPDATE security.user_table
		   SET account_expiry_enabled = 0
		 WHERE account_expiry_enabled = 1
		   AND sid_id IN (
			SELECT csr_user_sid
			  FROM csr.csr_user
			 WHERE LOWER(user_name) in (
				'webquerydaemon','usercreatordaemon','systemuserdaemon',
				'invitation respondent','cardprocessordaemon','feed user',
				'sso','as2','enquirycreatordaemon'
			)
		);
		security.user_pkg.LogOff(SYS_CONTEXT('SECURITY', 'ACT'));
	END LOOP;
END;
/
UPDATE mail.version
   SET db_version = 34;
BEGIN
	security.user_pkg.logonadmin;
	FOR a IN (
		-- Quickly find likely apps (matching the log message globally is slow because it's a CLOB)
		SELECT DISTINCT app_sid 
		  FROM csr.issue 
		 WHERE issue_meter_raw_data_id IS NOT NULL
	) LOOP
		-- Update the issue labels (strip out the date times)
		FOR i IN (
			SELECT issue_id, 
				TRIM(REGEXP_REPLACE(label, 
					'^(.*RAW DATA PROCESSOR.*)\(' ||
					'[0-3][0-9]-[A-Z][A-Z][A-Z]-[0-1][0-9] [0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]\.[0-9]+ [+|-][0-2][0-9]:[0-5][0-9]' ||
					' - ' ||
					'[0-3][0-9]-[A-Z][A-Z][A-Z]-[0-1][0-9] [0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]\.[0-9]+ [+|-][0-2][0-9]:[0-5][0-9]' ||
					'\).*$', '\1')) clean_label
			 FROM csr.issue
			WHERE app_sid = a.app_sid
			   AND issue_meter_raw_data_id IS NOT NULL
			   AND REGEXP_LIKE (label,
				'^.*RAW DATA PROCESSOR.*\(' ||
				'[0-3][0-9]-[A-Z][A-Z][A-Z]-[0-1][0-9] [0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]\.[0-9]+ [+|-][0-2][0-9]:[0-5][0-9]' ||
				' - ' ||
				'[0-3][0-9]-[A-Z][A-Z][A-Z]-[0-1][0-9] [0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]\.[0-9]+ [+|-][0-2][0-9]:[0-5][0-9]' ||
				'\).*$')
		) LOOP
			 UPDATE csr.issue
			    SET label = i.clean_label
			  WHERE app_sid = a.app_sid
			    AND issue_id = i.issue_id;
		END LOOP;
		-- Parameterise the issue log entries
		FOR i IN (
			SELECT x.issue_id, x.issue_log_id, x.param_message,
				TO_CHAR(TO_TIMESTAMP_TZ(CAST (x.start_dtm AS VARCHAR2(64)), 'DD-MON-YY HH24.MI.SS.FF5 TZH:TZM'), 'YYYY-MM-DD"T"HH24:MI:SS.FF3TZH:TZM') iso_start_dtm,
				TO_CHAR(TO_TIMESTAMP_TZ(CAST (x.end_dtm AS VARCHAR2(64)), 'DD-MON-YY HH24.MI.SS.FF5 TZH:TZM'), 'YYYY-MM-DD"T"HH24:MI:SS.FF3TZH:TZM') iso_end_dtm
			  FROM (
				SELECT l.issue_id, l.issue_log_id, l.message,
					REGEXP_REPLACE(l.message, 
						'^(.*RAW DATA PROCESSOR.*)\(' ||
						'[0-3][0-9]-[A-Z][A-Z][A-Z]-[0-1][0-9] [0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]\.[0-9]+ [+|-][0-2][0-9]:[0-5][0-9]' ||
						' - ' ||
						'[0-3][0-9]-[A-Z][A-Z][A-Z]-[0-1][0-9] [0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]\.[0-9]+ [+|-][0-2][0-9]:[0-5][0-9]' ||
						'\)(.*)$', '\1({0:ISO} - {1:ISO})\2') param_message,
					REGEXP_REPLACE(l.message, 
						'^.*RAW DATA PROCESSOR.*\(' ||
						'([0-3][0-9]-[A-Z][A-Z][A-Z]-[0-1][0-9] [0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]\.[0-9]+ [+|-][0-2][0-9]:[0-5][0-9])' ||
						' - .+\).*$', '\1') start_dtm,
					REGEXP_REPLACE(l.message, 
						'^.*RAW DATA PROCESSOR.*\(.+ - ' ||
						'([0-3][0-9]-[A-Z][A-Z][A-Z]-[0-1][0-9] [0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]\.[0-9]+ [+|-][0-2][0-9]:[0-5][0-9])' ||
						'\).*$', '\1') end_dtm
				  FROM csr.issue_log l
				  JOIN csr.issue i ON i.issue_id = l.issue_id AND i.issue_meter_raw_data_id IS NOT NULL
				 WHERE l.app_sid = a.app_sid
				   AND l.message LIKE '%RAW DATA PROCESSOR%' -- This really speeds up the query, presumably something to do with the fact the message is in a CLOB
				   AND REGEXP_LIKE (l.message,
					'^.*RAW DATA PROCESSOR.*\(' ||
					'[0-3][0-9]-[A-Z][A-Z][A-Z]-[0-1][0-9] [0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]\.[0-9]+ [+|-][0-2][0-9]:[0-5][0-9]' ||
					' - ' ||
					'[0-3][0-9]-[A-Z][A-Z][A-Z]-[0-1][0-9] [0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]\.[0-9]+ [+|-][0-2][0-9]:[0-5][0-9]' ||
					'\).*$'
				)
			) x
		) LOOP
			-- Switch out the message and fill in the params
			UPDATE csr.issue_log
			   SET message = i.param_message,
			       param_1 = i.iso_start_dtm,
			       param_2 = i.iso_end_dtm
			 WHERE app_sid = a.app_sid
			   AND issue_id = i.issue_id
			   AND issue_log_id = i.issue_log_id;
		END LOOP;
	END LOOP;
END;
/
INSERT INTO csr.flow_alert_class (flow_alert_class, label, helper_pkg) VALUES ('regulation', 'Regulation', 'CSR.COMPLIANCE_PKG');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (5, 'regulation', 'New');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (6, 'regulation', 'Updated');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (7, 'regulation', 'Action Required');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (8, 'regulation', 'Compliant');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (9, 'regulation', 'Not applicable');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (10, 'regulation', 'Retired');
INSERT INTO csr.flow_alert_class (flow_alert_class, label, helper_pkg) VALUES ('requirement', 'Requirement', 'CSR.COMPLIANCE_PKG');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (11, 'requirement', 'New');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (12, 'requirement', 'Updated');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (13, 'requirement', 'Action Required');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (14, 'requirement', 'Compliant');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (15, 'requirement', 'Not applicable');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (16, 'requirement', 'Retired');
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (79, 'in_enable_regulation_flow', 0, 'Should the regulation workflow be created? (Y/N)');
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (79, 'in_enable_requirement_flow', 1, 'Should the requirement workflow be created? (Y/N)');
BEGIN
	-- Remove old enums
	DELETE FROM csr.est_attr_enum
	 WHERE type_name = 'poolSizeType'
	   AND enum NOT IN (
		'Recreational (20 yards x 15 yards)',
		'Short Course (25 yards x 20 yards)',
		'Olympic (50 meters x 25 meters)'
	);
	-- Add new enums if required
	BEGIN
		INSERT INTO csr.est_attr_enum (type_name, enum, pos)
		VALUES ('poolSizeType', 'Recreational (20 yards x 15 yards)', 0);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Ignore
	END;
	BEGIN
		INSERT INTO csr.est_attr_enum (type_name, enum, pos)
		VALUES ('poolSizeType', 'Short Course (25 yards x 20 yards)', 1);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Ignore
	END;
	BEGIN
		INSERT INTO csr.est_attr_enum (type_name, enum, pos)
		VALUES ('poolSizeType', 'Olympic (50 meters x 25 meters)', 2);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Ignore
	END;
END;
/
BEGIN
	BEGIN
		INSERT INTO csr.capability (name, allow_by_default) VALUES ('Manage compliance items', 0);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;
/
ALTER TABLE chain.saved_filter DROP CONSTRAINT FK_SAVED_FILTER_CMP_ID;
ALTER TABLE chain.saved_filter ADD CONSTRAINT FK_SAVED_FILTER_CMP_ID 
    FOREIGN KEY (APP_SID, COMPOUND_FILTER_ID, CARD_GROUP_ID)
    REFERENCES CHAIN.COMPOUND_FILTER(APP_SID, COMPOUND_FILTER_ID, CARD_GROUP_ID)
	DEFERRABLE INITIALLY DEFERRED
;
ALTER TABLE chain.saved_filter DROP CONSTRAINT FK_SAVED_FILTER_GRP_BY_CMP_ID;
ALTER TABLE chain.saved_filter ADD CONSTRAINT FK_SAVED_FILTER_GRP_BY_CMP_ID 
    FOREIGN KEY (APP_SID, GROUP_BY_COMPOUND_FILTER_ID, CARD_GROUP_ID)
    REFERENCES CHAIN.COMPOUND_FILTER(APP_SID, COMPOUND_FILTER_ID, CARD_GROUP_ID)
	DEFERRABLE INITIALLY DEFERRED
;
DECLARE
	v_old_filter_type_id		NUMBER;
BEGIN
	security.user_pkg.LogonAdmin;
	UPDATE chain.card_group
	   SET name = 'Compliance Library Filter',
	       description = 'Allows filtering of global compliance items',
	       helper_pkg = 'csr.compliance_library_report_pkg',
	       list_page_url = '/csr/site/compliance/Library.acds?savedFilterSid='
	 WHERE card_group_id = 48;
	 
	DELETE FROM chain.aggregate_type
	      WHERE card_group_id = 49;
	
	UPDATE chain.aggregate_type
	   SET description = 'Number of items'
	 WHERE card_group_id = 48
	   AND aggregate_type_id = 1;
	
	DELETE FROM chain.card_group_column_type
	      WHERE card_group_id = 49;
	UPDATE chain.card_group_column_type
	   SET description = 'Compliance item region'
	 WHERE card_group_id = 48
	   AND column_id = 1;
	 
	-- Tidy up child tables first
	DELETE FROM chain.filter_item_config
	      WHERE card_group_id = 49;
	
	DELETE FROM chain.filter_page_column
	      WHERE card_group_id = 49;
	
	DELETE FROM chain.filter_cache
	      WHERE card_group_id = 49;
	
	-- I've temporarily made the FK constraints deferred, so this should work
	UPDATE chain.saved_filter
	   SET card_group_id = 48
	 WHERE card_group_id = 49;
	
	UPDATE chain.compound_filter
	   SET card_group_id = 48
	 WHERE card_group_id = 49;
	
	DELETE FROM chain.card_group_card
	      WHERE card_group_id = 49;
	
	DELETE FROM chain.card_group
	      WHERE card_group_id = 49;
	UPDATE chain.card
	   SET description = 'Compliance Library Filter',
	       class_type = 'Credit360.Compliance.Cards.ComplianceLibraryFilter',
	       js_include = '/csr/site/compliance/filters/ComplianceLibraryFilter.js',
	       js_class_type = 'Credit360.Compliance.Filters.ComplianceLibraryFilter'
	 WHERE js_class_type = 'Credit360.Compliance.Requirement.Filters.ComplianceRequirementFilter';
	DELETE FROM chain.card_progression_action WHERE card_id = (
		SELECT card_id 
		  FROM chain.card
	     WHERE js_class_type = 'Credit360.Compliance.Regulation.Filters.ComplianceRegulatonFilter'
	);
	 
	DELETE FROM chain.card
	      WHERE js_class_type = 'Credit360.Compliance.Regulation.Filters.ComplianceRegulatonFilter';
		  
	UPDATE chain.filter_type
	   SET description = 'Compliance Library Filter',
	       helper_pkg = 'csr.compliance_library_report_pkg'
	 WHERE helper_pkg = 'csr.comp_requirement_report_pkg';
	SELECT filter_type_id
	  INTO v_old_filter_type_id
	  FROM chain.filter_type
	 WHERE helper_pkg = 'csr.comp_regulation_report_pkg';
	 
	UPDATE chain.filter
	   SET filter_type_id = (
		SELECT filter_type_id
		  FROM chain.filter_type
		 WHERE helper_pkg = 'csr.compliance_library_report_pkg'
		)
	 WHERE filter_type_id = v_old_filter_type_id;
	 
	DELETE FROM chain.filter_type
	      WHERE filter_type_id = v_old_filter_type_id;
END;
/
ALTER TABLE chain.saved_filter DROP CONSTRAINT FK_SAVED_FILTER_CMP_ID;
ALTER TABLE chain.saved_filter ADD CONSTRAINT FK_SAVED_FILTER_CMP_ID 
    FOREIGN KEY (APP_SID, COMPOUND_FILTER_ID, CARD_GROUP_ID)
    REFERENCES CHAIN.COMPOUND_FILTER(APP_SID, COMPOUND_FILTER_ID, CARD_GROUP_ID)
;
ALTER TABLE chain.saved_filter DROP CONSTRAINT FK_SAVED_FILTER_GRP_BY_CMP_ID;
ALTER TABLE chain.saved_filter ADD CONSTRAINT FK_SAVED_FILTER_GRP_BY_CMP_ID 
    FOREIGN KEY (APP_SID, GROUP_BY_COMPOUND_FILTER_ID, CARD_GROUP_ID)
    REFERENCES CHAIN.COMPOUND_FILTER(APP_SID, COMPOUND_FILTER_ID, CARD_GROUP_ID)
;
DECLARE
	v_act_id						security.security_pkg.T_ACT_ID;
	v_menu_sid						security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT c.app_sid, c.host, m.sid_id compliance_menu_sid
		  FROM security.menu m
		  JOIN security.securable_object so ON m.sid_id = so.sid_id
		  JOIN csr.customer c ON so.application_sid_id = c.app_sid
		 WHERE m.action = '/csr/site/compliance/myCompliance.acds'
		   AND so.name = 'csr_compliance'
	) LOOP
		security.user_pkg.LogonAdmin(r.host);
		
		v_act_id := security.security_pkg.GetAct;
		
		UPDATE security.menu
		   SET action = '/csr/site/compliance/LegalRegister.acds'
		 WHERE sid_id = r.compliance_menu_sid;
		
		FOR m IN (
			SELECT m.sid_id
			  FROM security.menu m
			  JOIN security.securable_object so ON m.sid_id = so.sid_id
			 WHERE so.parent_sid_id = r.compliance_menu_sid
			   AND so.application_sid_id = r.app_sid
			   AND so.name IN ('csr_compliance_mycompliance', 'csr_compliance_regulations', 'csr_compliance_requirements')
		) LOOP
			security.securableobject_pkg.DeleteSO(v_act_id, m.sid_id);
		END LOOP;
		 
		BEGIN
			security.menu_pkg.CreateMenu(v_act_id, r.compliance_menu_sid, 'csr_compliance_legal_register', 'Legal register', '/csr/site/compliance/LegalRegister.acds', 1, null, v_menu_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
		BEGIN
			security.menu_pkg.CreateMenu(v_act_id, r.compliance_menu_sid, 'csr_compliance_calendar', 'Compliance calendar', '/csr/site/compliance/ComplianceCalendar.acds', 2, null, v_menu_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
		BEGIN
			security.menu_pkg.CreateMenu(v_act_id, r.compliance_menu_sid, 'csr_compliance_library', 'Compliance library', '/csr/site/compliance/Library.acds', 3, null, v_menu_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
		BEGIN
			security.menu_pkg.CreateMenu(v_act_id, r.compliance_menu_sid, 'csr_compliance_create_regulation', 'New regulation', '/csr/site/compliance/CreateItem.acds?type=regulation', 4, null, v_menu_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
		BEGIN
			security.menu_pkg.CreateMenu(v_act_id, r.compliance_menu_sid, 'csr_compliance_create_requirement', 'New requirement', '/csr/site/compliance/CreateItem.acds?type=requirement', 5, null, v_menu_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
	END LOOP;
	
	security.user_pkg.LogonAdmin;
END;
/
INSERT ALL
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (1, 'No change',0, 1 )
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (2, 'New development', 0, 2)
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (3, 'Explicit regulatory change', 0,3)
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (4, 'Repealing change', 0, 4)
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (5, 'Implicit regulatory change', 0, 5)
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (6, 'Editorial change that does not impact meaning', 0, 6)	
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (7, 'Improved guidance / analysis', 0, 7)
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (8, 'No change',1, 1 )
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (9, 'New development', 1, 2)
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (10, 'Explicit regulatory change', 1, 3)
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (11, 'Repealing change', 1, 4)
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (12, 'Implicit regulatory change', 1, 5)
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (13, 'Editorial change that does not impact meaning', 1, 6)	
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (14, 'Improved guidance / analysis', 1, 7)
SELECT 1 FROM DUAL;
BEGIN
	 
	INSERT INTO chain.dedupe_rule_type (dedupe_rule_type_id, description, threshold_default) 
		VALUES (2, 'Levenshtein (distance match)', 50);
	INSERT INTO CHAIN.DEDUPE_RULE_TYPE (DEDUPE_RULE_TYPE_ID, DESCRIPTION, THRESHOLD_DEFAULT) 
		VALUES (3, 'Jaro-Winkler (distance match)', 70);
	
	INSERT INTO chain.dedupe_rule_type (dedupe_rule_type_id, description, threshold_default) 
		VALUES (4, 'Contains match (case insensitive)', 100);
			
	INSERT INTO chain.dedupe_no_match_action (dedupe_no_match_action_id, description) 
		VALUES (2, 'Mark record for manual review');
		
	INSERT INTO chain.dedupe_no_match_action (dedupe_no_match_action_id, description) 
		VALUES (3, 'Park record');
		
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp)
	VALUES (58, 'Dedupe manual merge', 'chain.company_dedupe_pkg.ProcessUserActions');
END;
/
BEGIN
	UPDATE CHAIN.DEDUPE_MATCH_TYPE SET label = 'Automatic' WHERE DEDUPE_MATCH_TYPE_ID = 1;
END;
/


DROP PACKAGE chain.report_pkg;
CREATE OR REPLACE PACKAGE BODY MAIL.mail_pkg
AS
FUNCTION generateSalt 
RETURN NUMBER
AS
    v_salt CHAR(32);
    -- This is fixed, but we seem to get different ACTs each time anyway
    -- Presumably sufficient entropy is added that we don't need to fetch it ourselves?
    -- Since Oracle couldn't be fucked to document the function, I'm not really
    -- sure what the answer is.
    seedval RAW(80) := HEXTORAW('3D074594FB092A1A11228BE1A8FD488A'
							 || '83455D95C79318D15787A796A68F932D'
							 || 'A2821E85667A2F28DA5B8AC594A9147C'
							 || '85F8BCDC25EDD95DB7B48E29FFBB1B30'
							 || '49DDD6A4AABDCE5861BE68FD1C603160');
BEGIN
	v_salt := RAWTOHEX(DBMS_OBFUSCATION_TOOLKIT.DES3GETKEY(seed => seedval));
	RETURN TO_NUMBER(SUBSTR(v_salt,1,8),'XXXXXXXX'); 
END;
FUNCTION hashPassword(
   in_salt				IN NUMBER, 
   in_pass 				IN VARCHAR2
)
RETURN VARCHAR2
AS
	v_hex_digest 	VARCHAR2(32);
	v_digest 		VARCHAR2(16);
BEGIN
	v_digest := DBMS_OBFUSCATION_TOOLKIT.MD5(
		INPUT_STRING => NVL(TO_CHAR(in_salt),'X')||NVL(in_pass,'Y'));
	SELECT RAWTOHEX(v_digest) 
	  INTO v_hex_digest 
	  FROM dual;
	RETURN v_hex_digest;
END;
FUNCTION getAccountFromMailbox(
	in_mailbox_sid		IN	mailbox_message.mailbox_sid%TYPE
) RETURN account.account_sid%TYPE
AS
	v_root_mailbox_sid	mailbox.mailbox_sid%TYPE;
	v_account_sid		account.account_sid%TYPE;
BEGIN
	BEGIN
		-- Walk up tree to get the root mailbox
		SELECT mailbox_sid
		  INTO v_root_mailbox_sid
		  FROM (
			SELECT mailbox_sid, parent_sid
  			  FROM mailbox
		   CONNECT BY PRIOR parent_sid = mailbox_sid
		     START WITH mailbox_sid = in_mailbox_sid
			   )
		WHERE NVL(parent_sid,0) = 0;
		
		-- Use this to look up the account
		SELECT MIN(account_sid)
		  INTO v_account_sid
		  FROM account
		 WHERE root_mailbox_sid = v_root_mailbox_sid;
		 RETURN v_account_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE MAILBOX_NOT_FOUND;
	END;
END;
PROCEDURE deleteMessage(
	in_mailbox_sid					IN 	mailbox_message.mailbox_sid%TYPE,
	in_message_uid					IN 	mailbox_message.message_uid%TYPE
)
IS
	v_modseq						mailbox.modseq%TYPE;
BEGIN
	-- Add a delete job for the message, if required
	--fulltext_index_pkg.deleteMessage(in_mailbox_sid, in_message_uid);
	UPDATE mailbox
	   SET modseq = modseq + 1
	 WHERE mailbox_sid = in_mailbox_sid
	 	   RETURNING modseq INTO v_modseq;
	
	INSERT INTO expunged_message (mailbox_sid, modseq, min_uid, max_uid)
	VALUES (in_mailbox_sid, v_modseq, in_message_uid, in_message_uid);
	-- Clean all child objects
	DELETE FROM account_message
	 WHERE mailbox_sid = in_mailbox_sid AND message_uid = in_message_uid;
	-- Clean the message itself
	DELETE FROM mailbox_message
	 WHERE mailbox_sid = in_mailbox_sid AND message_uid = in_message_uid;
END;
PROCEDURE copyMessage(
	in_mailbox_sid					IN	mailbox_message.mailbox_sid%TYPE,
	in_message_uid					IN	mailbox_message.message_uid%TYPE,
	in_dest_mailbox_sid				IN	mailbox_message.mailbox_sid%TYPE,
	out_dest_message_uid			OUT	mailbox_message.message_uid%TYPE
)
IS
	v_new_uid						mailbox.last_message_uid%TYPE;
	v_modseq						mailbox.modseq%TYPE;
BEGIN
	-- lock the destination mailbox	
	UPDATE mailbox
	   SET last_message_uid = last_message_uid + 1, modseq = modseq + 1
	 WHERE mailbox_sid = in_dest_mailbox_sid
	 	   RETURNING last_message_uid, modseq INTO v_new_uid, v_modseq;
	out_dest_message_uid := v_new_uid;
	-- copy the various bits of the mail
	INSERT INTO mailbox_message (mailbox_sid, message_uid, message_id, flags,
		received_dtm, modseq)
		SELECT in_dest_mailbox_sid, v_new_uid, m.message_id, m.flags,
			   m.received_dtm, v_modseq
		  FROM mailbox_message m
		 WHERE mailbox_sid = in_mailbox_sid AND message_uid = in_message_uid;
	IF SQL%ROWCOUNT = 0 THEN
		RAISE MESSAGE_NOT_FOUND;
	END IF;
END;
PROCEDURE moveMessage(
	in_mailbox_sid					IN	mailbox_message.mailbox_sid%TYPE,
	in_message_uid					IN	mailbox_message.message_uid%TYPE,
	in_dest_mailbox_sid				IN	mailbox_message.mailbox_sid%TYPE,
	out_dest_message_uid			OUT	mailbox_message.message_uid%TYPE
)
IS
BEGIN
	-- XXX: we could use ON UPDATE CASCADE for the constraints to do this
	copyMessage(in_mailbox_sid, in_message_uid, in_dest_mailbox_sid, out_dest_message_uid);
	deleteMessage(in_mailbox_sid, in_message_uid);
END;
PROCEDURE resetPassword(
	in_account_sid					IN	mailbox.mailbox_sid%TYPE,
	in_password						IN	VARCHAR2
)
AS
	v_salt			account.password_salt%TYPE;
BEGIN
	v_salt := generateSalt();
	UPDATE account 
	   SET password = hashPassword(v_salt, in_password),
	       password_salt = v_salt,
	       apop_secret = in_password
	 WHERE account_sid = in_account_sid;
END;
PROCEDURE createAccount(
	in_email_address				IN	account.email_address%TYPE,
	in_password						IN	VARCHAR2,
	in_description					IN	account.description%TYPE,
	out_account_sid					OUT	account.account_sid%TYPE,
	out_root_mailbox_sid			OUT	mailbox.mailbox_sid%TYPE
)
AS
BEGIN
	createAccount(in_email_address, in_password, in_description, 0, out_account_sid, out_root_mailbox_sid);
END;
PROCEDURE createSpecialFolder(
	in_account_sid					IN	account.account_sid%TYPE,
	in_parent_sid					IN	mailbox.mailbox_sid%TYPE,
	in_mailbox_name					IN	mailbox.mailbox_name%TYPE,
	in_special_use					IN	mailbox.special_use%TYPE,
	out_mailbox_sid					OUT	mailbox.mailbox_sid%TYPE
)
AS
BEGIN
	mailbox_pkg.createMailbox(in_parent_sid, in_mailbox_name, in_account_sid, out_mailbox_sid);
	UPDATE mail.mailbox
	   SET special_use = in_special_use
	 WHERE mailbox_sid = out_mailbox_sid;
END;
PROCEDURE createAccount(
	in_email_address				IN	account.email_address%TYPE,
	in_password						IN	VARCHAR2,
	in_description					IN	account.description%TYPE,
	in_for_outlook					IN	NUMBER,
	out_account_sid					OUT	account.account_sid%TYPE,
	out_root_mailbox_sid			OUT	mailbox.mailbox_sid%TYPE
)
AS
BEGIN
	createAccount(
		in_email_address				=> in_email_address,
		in_password						=> in_password,
		in_description					=> in_description,
		in_for_outlook					=> in_for_outlook,
		in_class_id						=> NULL,
		out_account_sid					=> out_account_sid,
		out_root_mailbox_sid			=> out_root_mailbox_sid
	);
END;
PROCEDURE createAccount(
	in_email_address				IN	account.email_address%TYPE,
	in_password						IN	VARCHAR2,
	in_description					IN	account.description%TYPE,
	in_for_outlook					IN	NUMBER,
	in_class_id						IN	NUMBER DEFAULT NULL,
	out_account_sid					OUT	account.account_sid%TYPE,
	out_root_mailbox_sid			OUT	mailbox.mailbox_sid%TYPE
)
IS
	v_salt			account.password_salt%TYPE;
	v_inbox_sid		mailbox.mailbox_sid%TYPE;
	v_accounts_sid	security.security_pkg.T_SID_ID;
	v_folders_sid	security.security_pkg.T_SID_ID;
	v_folder_sid	security.security_pkg.T_SID_ID;
BEGIN
	-- Folders where the mail SOs live
	v_folders_sid := security.securableObject_pkg.getSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), security.security_pkg.SID_ROOT, '/Mail/Folders');
	v_accounts_sid := security.securableObject_pkg.getSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), security.security_pkg.SID_ROOT, '/Mail/Accounts');
	-- Create the account
	-- XXX: this probably ought to change to just log the user on with security.security.user_pkg,
	-- leaving it for now as too many other changes to make
	security.user_pkg.createuser(
		in_act_id				=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_parent_sid			=> v_accounts_sid,
		in_login_name			=> in_email_address,
		in_plaintext_password	=> in_password,
		in_class_id				=> security.security_pkg.SO_USER,
		out_user_sid			=> out_account_sid
	);
	
	-- Grant the creating user permissions on the account (except for builtin/administrator, which by default has permissions)
	IF SYS_CONTEXT('SECURITY', 'SID') != security.security_pkg.SID_BUILTIN_ADMINISTRATOR THEN
		security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), security.acl_pkg.GetDACLIDForSID(out_account_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, SYS_CONTEXT('SECURITY', 'SID'), security.security_pkg.PERMISSION_STANDARD_ALL);
	END IF;
	
	BEGIN
		INSERT INTO account_alias
			(account_sid, email_address)
		VALUES
			(out_account_sid, in_email_address);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'The email address '||in_email_address||' is already in use');
	END;
		
	v_salt := generateSalt();
	INSERT INTO account
		(account_sid, email_address, password, password_salt, apop_secret)
	VALUES
		(out_account_sid, in_email_address, hashPassword(v_salt, in_password), v_salt, in_password);
		
	-- Create the root mailbox/inbox for the account
	mailbox_pkg.createMailboxWithClass(v_folders_sid, in_email_address, out_account_sid, in_class_id, out_root_mailbox_sid);
	-- Grant the creating user permissions on the mailbox (except for builtin/administrator, which by default has permissions)
	IF SYS_CONTEXT('SECURITY', 'SID') != security.security_pkg.SID_BUILTIN_ADMINISTRATOR THEN
		security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), security.acl_pkg.GetDACLIDForSID(out_root_mailbox_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, SYS_CONTEXT('SECURITY', 'SID'), security.security_pkg.PERMISSION_STANDARD_ALL);
	END IF;
	-- Grant the account permissions on the mailbox
	security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), security.acl_pkg.GetDACLIDForSID(out_root_mailbox_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, out_account_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	-- Create an inbox for the account
	mailbox_pkg.createMailboxWithClass(out_root_mailbox_sid, 'Inbox', out_account_sid, in_class_id, v_inbox_sid);
	
	-- If the account is for outlook, then pre-create the special folders because it's too retarded to allow the
	-- user to set them manually, and too retarded to use them if you create them after adding the account
	IF in_for_outlook = 1 THEN
		createSpecialFolder(out_account_sid, out_root_mailbox_sid, 'Drafts', SU_Drafts, v_folder_sid);
		createSpecialFolder(out_account_sid, out_root_mailbox_sid, 'Junk E-mail', SU_Junk, v_folder_sid);
		createSpecialFolder(out_account_sid, out_root_mailbox_sid, 'Deleted Items', SU_Trash, v_folder_sid);
		createSpecialFolder(out_account_sid, out_root_mailbox_sid, 'Sent Items', SU_Sent, v_folder_sid);
	END IF;
	
	UPDATE account
	   SET root_mailbox_sid = out_root_mailbox_sid,
		   inbox_sid = v_inbox_sid
	 WHERE account_sid = out_account_sid;
END;
PROCEDURE renameAccount(
	in_account_sid					IN	account.account_sid%TYPE,
	in_new_email_address			IN	account.email_address%TYPE
)
IS
	v_folders_sid					security.security_pkg.T_SID_ID;
	v_root_mailbox_sid				account.root_mailbox_sid%TYPE;
	v_old_email_address				account.email_address%TYPE;
BEGIN
	-- renaming the securable objects will effectively take care of security checks	
	
	-- the bit under /Mail/Accounts
	security.securableObject_pkg.renameSO(SYS_CONTEXT('SECURITY', 'ACT'), in_account_sid, in_new_email_address);
	
	-- get the old mail address for cleaning up account alias
	SELECT email_address
	  INTO v_old_email_address
	  FROM account
	 WHERE account_sid = in_account_sid;
	 
	-- account.email_address references the alias table, so add the new address as an alias
	BEGIN
		INSERT INTO account_alias
			(account_sid, email_address)
		VALUES
			(in_account_sid, in_new_email_address);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'The email address '||in_new_email_address||' is already in use');
	END;
	-- set the new address
	UPDATE account
	   SET email_address = in_new_email_address
	 WHERE account_sid = in_account_sid;
	-- clean up the old one
	DELETE FROM account_alias
     WHERE account_sid = in_account_sid
       AND email_address = v_old_email_address;
	
	-- now fix up the stuff under /Mail/Folders 
	SELECT root_mailbox_sid
	  INTO v_root_mailbox_sid
	  FROM account
	 WHERE account_sid = in_account_sid;
	 
	security.securableObject_pkg.renameSO(SYS_CONTEXT('SECURITY', 'ACT'), v_root_mailbox_sid, in_new_email_address);
END;
PROCEDURE createAccount(
	in_email_address				IN	account.email_address%TYPE,
	in_password						IN	VARCHAR2,
	out_root_mailbox_sid			OUT	mailbox.mailbox_sid%TYPE
)
IS
	v_account_sid					account.account_sid%TYPE;
BEGIN
	createAccount(in_email_address, in_password, null, v_account_sid, out_root_mailbox_sid);
END;
PROCEDURE addAccountAlias(
	in_account_sid					IN	account_alias.account_sid%TYPE,
	in_email_address				IN	account_alias.email_address%TYPE
)
AS
	v_accounts_sid					security.security_pkg.T_SID_ID;
BEGIN
	-- Write permission is required on the account to modify it
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_account_sid, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Add contents permission denied on the account with sid '||in_account_sid);
	END IF;
	
	-- Add contents permission on the accounts folder is required to add an e-mail address
	v_accounts_sid := security.securableObject_pkg.getSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), security.security_pkg.SID_ROOT, '/Mail/Accounts');
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), v_accounts_sid, security.security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Add contents permission denied on /Mail/Accounts');
	END IF;
	-- account.email_address references the alias table, so add the new address as an alias
	BEGIN
		INSERT INTO account_alias
			(account_sid, email_address)
		VALUES
			(in_account_sid, in_email_address);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'The email address '||in_email_address||' is already in use');
	END;
END;
PROCEDURE deleteAccountAlias(
	in_account_sid					IN	account_alias.account_sid%TYPE,
	in_email_address				IN	account_alias.email_address%TYPE
)
AS
BEGIN
	-- Write permission is required on the account to modify it
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_account_sid, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Add contents permission denied on /Mail/Accounts');
	END IF;
	DELETE FROM account_alias
	 WHERE account_sid = in_account_sid 
	   AND LOWER(email_address) = LOWER(in_email_address);
END;
PROCEDURE getAccountAliases(
	in_account_sid					IN	account.account_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- Read permission is required on the account to list aliases
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_account_sid, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the account with sid '||in_account_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT email_address
		  FROM account_alias
		 WHERE account_sid = in_account_sid
		 MINUS
		SELECT email_address
		  FROM account
		 WHERE account_sid = in_account_sid;
END;
PROCEDURE createAccountForCurrentUser(
	in_email_address				IN	account.email_address%TYPE,
	in_password						IN	VARCHAR2,
	in_description					IN	account.description%TYPE,
	out_account_sid					OUT	account.account_sid%TYPE,
	out_root_mailbox_sid			OUT	mailbox.mailbox_sid%TYPE
)
IS
BEGIN
	createAccount(in_email_address, in_password, in_description, out_account_sid, out_root_mailbox_sid);
	INSERT INTO user_account 
		(user_sid, account_sid)
	VALUES
		(SYS_CONTEXT('SECURITY', 'SID'), out_account_sid);
END;
PROCEDURE deleteAccount(
	in_email_address	IN	account.email_address%TYPE
)
IS
	v_account_sid		account.account_sid%TYPE;
BEGIN
	SELECT account_sid
	  INTO v_account_sid
	  FROM account
	 WHERE LOWER(email_address) = LOWER(in_email_address);
	deleteAccount(v_account_sid);
END;
PROCEDURE deleteAccount(
	in_account_sid		IN	account.account_sid%TYPE
)
IS
	v_root_mailbox_sid	account.root_mailbox_sid%TYPE;
BEGIN
	SELECT root_mailbox_sid
	  INTO v_root_mailbox_sid
	  FROM account
	 WHERE account_sid = in_account_sid;
	DELETE FROM temp_mailbox;
	INSERT INTO temp_mailbox (mailbox_sid)
		SELECT mailbox_sid
	 	  FROM mailbox
	 		   START WITH mailbox_sid = v_root_mailbox_sid
	 		   CONNECT BY PRIOR mailbox_sid = parent_sid;
	 		   
	DELETE FROM account_message
	 WHERE mailbox_sid IN (SELECT mailbox_sid
	 						 FROM temp_mailbox);
	DELETE FROM mailbox_message
	 WHERE mailbox_sid IN (SELECT mailbox_sid
	 						 FROM temp_mailbox);
	FOR r IN (SELECT account_sid, mailbox_sid
				FROM fulltext_index
			   WHERE account_sid = in_account_sid) LOOP
		fulltext_index_pkg.deleteIndex(r.account_sid, r.mailbox_sid);
	END LOOP;
	DELETE FROM fulltext_index
	 WHERE account_sid = in_account_sid;
	DELETE FROM mbox_subscription
	 WHERE account_sid = in_account_sid;
	DELETE FROM message_filter_entry
	 WHERE message_filter_id IN (SELECT message_filter_id
	 							   FROM message_filter
	 							  WHERE account_sid = in_account_sid);
	DELETE FROM message_filter
	 WHERE account_sid = in_account_sid;
	DELETE FROM user_account
	 WHERE account_sid = in_account_sid;
	DELETE FROM vacation_notified
	 WHERE account_sid = in_account_sid;
	DELETE FROM vacation
	 WHERE account_sid = in_account_sid;
	 
	DELETE FROM account
	 WHERE account_sid = in_account_sid;
	DELETE FROM account_alias
	 WHERE account_sid = in_account_sid;
	 
	-- Mark mailboxes as containers to speed up deletion a bit, then clean up all the
	-- SOs using DeleteSO
	UPDATE security.securable_object
	   SET class_id = security.security_pkg.SO_CONTAINER
	 WHERE sid_id IN (SELECT mailbox_sid
 						FROM temp_mailbox);
	FOR r IN (SELECT mailbox_sid
				FROM temp_mailbox) LOOP
		security.securableObject_pkg.deleteSO(SYS_CONTEXT('SECURITY', 'ACT'), r.mailbox_sid);
	END LOOP;
	DELETE FROM mail.expunged_message
	 WHERE mailbox_sid IN (SELECT mailbox_sid
	 						 FROM temp_mailbox);
	DELETE FROM account_mailbox
	 WHERE mailbox_sid IN (SELECT mailbox_sid
	 						 FROM temp_mailbox);
	DELETE FROM mailbox
	 WHERE mailbox_sid IN (SELECT mailbox_sid
	 						 FROM temp_mailbox);
	 						 	  
	-- Clean up the account object
	security.securableObject_pkg.deleteSO(SYS_CONTEXT('SECURITY', 'ACT'), in_account_sid);
END;
PROCEDURE setAccountDetails(
	in_account_sid					IN	account.account_sid%TYPE,
	in_description					IN	account.description%TYPE,
	in_inbox_sid					IN	account.inbox_sid%TYPE
)
IS
BEGIN
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_account_sid, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Write access denied on the account with sid '||in_account_sid);
	END IF;
	UPDATE account
	   SET description = in_description, inbox_sid = in_inbox_sid
	 WHERE account_sid = in_account_sid;
END;
PROCEDURE createMailbox(
	in_parent_sid					IN	mailbox.mailbox_sid%TYPE,
	in_name							IN	mailbox.mailbox_name%TYPE,
	out_mailbox_sid					OUT	mailbox.mailbox_sid%TYPE
)
IS
BEGIN
	mailbox_pkg.createMailbox(in_parent_sid, in_name, NULL, out_mailbox_sid);
END;
PROCEDURE deleteMailbox(
	in_mailbox_sid					IN	mailbox.mailbox_sid%TYPE
)
IS
BEGIN
	security.securableObject_pkg.deleteSO(SYS_CONTEXT('SECURITY', 'ACT'), in_mailbox_sid);
END;
FUNCTION getMailboxSIDFromPath(
	in_parent_sid					IN	mailbox.mailbox_sid%TYPE,
	in_path							IN	VARCHAR2
) RETURN mailbox.mailbox_sid%TYPE
AS
	v_sid			mailbox.mailbox_sid%TYPE;
	v_parent_sid	mailbox.mailbox_sid%TYPE;
BEGIN
	getMailboxFromPath(in_parent_sid, in_path, v_sid, v_parent_sid);
	RETURN v_sid;
END;
PROCEDURE getMailboxFromPath(
	in_parent_sid					IN	mailbox.mailbox_sid%TYPE,
	in_path							IN	VARCHAR2,
	out_mailbox_sid					OUT	mailbox.mailbox_sid%TYPE,
	out_parent_sid					OUT mailbox.parent_sid%TYPE
)
AS
	v_pos			BINARY_INTEGER;
	v_last_pos		BINARY_INTEGER DEFAULT 1;
	v_length		BINARY_INTEGER DEFAULT LENGTH(in_path);
	v_mailbox_name	VARCHAR2(4000);
BEGIN
	-- Initial output
	out_mailbox_sid := in_parent_sid;
	out_parent_sid := in_parent_sid;
	
	-- Repeat for each component in the path
	WHILE v_last_pos <= v_length LOOP
		v_pos := INSTR(in_path, '/', v_last_pos);
		IF v_pos = 0 THEN
			v_pos := v_length + 1;
		END IF;
		--security.security_pkg.debugmsg('look for '||LOWER(SUBSTR(in_path, v_last_pos, v_pos - v_last_pos)) || ' with parent sid ' || out_mailbox_sid);
		IF v_pos - v_last_pos >= 1 THEN
			BEGIN
				out_parent_sid := out_mailbox_sid;
				v_mailbox_name := LOWER(SUBSTR(in_path, v_last_pos, v_pos - v_last_pos));
				IF out_mailbox_sid IS NULL THEN
					SELECT NVL(link_to_mailbox_sid, mailbox_sid)
					  INTO out_mailbox_sid
					  FROM mailbox
					 WHERE parent_sid IS NULL
					   AND LOWER(mailbox_name) = v_mailbox_name;
				ELSE
					SELECT NVL(link_to_mailbox_sid, mailbox_sid)
					  INTO out_mailbox_sid
					  FROM mailbox
					 WHERE parent_sid = out_mailbox_sid
					   AND LOWER(mailbox_name) = v_mailbox_name;
				END IF;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					--oh bugger i've used the wrong numbers
					--security.security_pkg.debugmsg('The mailbox with parent sid '||in_parent_sid||' and path '||in_path||' could not be found');
					RAISE mail_pkg.PATH_NOT_FOUND;					
					--RAISE_APPLICATION_ERROR(mail_pkg.ERR_PATH_NOT_FOUND, 'The mailbox with parent sid '||in_parent_sid||' and path '||in_path||' could not be found');
			END;
		END IF;
		v_last_pos := v_pos + 1;
	END LOOP;
END;
FUNCTION getPathFromMailbox(
	in_mailbox_sid					IN	mailbox.mailbox_sid%TYPE
) RETURN VARCHAR2
AS
	v_path 	VARCHAR2(4000);
	v_found BOOLEAN;
BEGIN
	v_found := FALSE;
	FOR r IN (
			SELECT mailbox_name, parent_sid
  			  FROM mailbox
		   CONNECT BY PRIOR parent_sid = mailbox_sid
		     START WITH mailbox_sid = in_mailbox_sid 
		     ) LOOP
		v_found := TRUE;
		v_path := '/' || r.mailbox_name || v_path;
	END LOOP;
	IF NOT v_found THEN
		RAISE MAILBOX_NOT_FOUND;
	END IF;
	IF v_path IS NULL THEN
		RETURN '/';
	END IF;
	RETURN v_path;
END;
FUNCTION parseLink(
	in_sid							IN	mailbox.mailbox_sid%TYPE
) RETURN mailbox.mailbox_sid%TYPE
AS 
	v_sid	mailbox.mailbox_sid%TYPE;
BEGIN
	BEGIN
		SELECT NVL(link_to_mailbox_sid, mailbox_sid)
		  INTO v_sid
		  FROM mailbox
		 WHERE mailbox_sid = in_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_sid := in_sid;
	END;
	RETURN v_sid;
END;
FUNCTION processStartPoints(
	in_parent_sids					IN	security.security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER
)
RETURN security.T_SID_TABLE
AS
	v_parsed_sids	security.security_pkg.T_SID_IDS;
BEGIN
	-- Process link and check permissions
	FOR i IN in_parent_sids.FIRST .. in_parent_sids.LAST
	LOOP
		IF in_include_root = 0 THEN			
			v_parsed_sids(i) := ParseLink(in_parent_sids(i));
		ELSE 
			v_parsed_sids(i) := in_parent_sids(i);
		END IF;
	END LOOP;
	RETURN security.security_pkg.SidArrayToTable(v_parsed_sids);
END;
PROCEDURE getUserAccounts(
	out_cur							OUT	SYS_REFCURSOR
)
IS
BEGIN
	OPEN out_cur FOR
		SELECT a.account_sid, a.email_address, a.root_mailbox_sid, a.inbox_sid, a.description
		  FROM user_account ua, account a
		 WHERE ua.user_sid = SYS_CONTEXT('SECURITY', 'SID') AND a.account_sid = ua.account_sid;
END;
FUNCTION isUserAccount(
	in_account_sid					IN	account.account_sid%TYPE
) RETURN NUMBER
IS
	v_cnt	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM user_account
	 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID') AND account_sid = in_account_sid;
	RETURN v_cnt;
END;
PROCEDURE getAccount(
	in_account_sid					IN	account.account_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR	
)
IS
BEGIN
	OPEN out_cur FOR
		SELECT a.account_sid, a.email_address, a.root_mailbox_sid, a.inbox_sid, m.mailbox_name inbox_name, a.description
		  FROM account a, mailbox m
		 WHERE a.account_sid = in_account_sid AND a.inbox_sid = m.mailbox_sid;
END;
PROCEDURE getTreeWithDepth(
	in_parent_sids					IN	security.security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_roots 						security.T_SID_TABLE;
BEGIN
	v_roots := ProcessStartPoints(in_parent_sids, in_include_root);
	
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ mailbox_sid, mailbox_name, LEVEL lvl, CONNECT_BY_ISLEAF is_leaf
		  FROM mailbox
		 WHERE level <= in_fetch_depth
		       START WITH (in_include_root = 0 AND parent_sid IN (SELECT column_value FROM TABLE(v_roots))) OR 
			 		      (in_include_root = 1 AND mailbox_sid IN (SELECT column_value FROM TABLE(v_roots)))
			   CONNECT BY PRIOR NVL(link_to_mailbox_sid, mailbox_sid) = parent_sid
		  	   ORDER SIBLINGS BY LOWER(mailbox_name);
END;
PROCEDURE getTreeWithSelect(
	in_parent_sids					IN	security.security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_select_sid					IN	security.security_pkg.T_SID_ID,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_roots 						security.T_SID_TABLE;
BEGIN
	v_roots := ProcessStartPoints(in_parent_sids, in_include_root);
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ mailbox_sid, mailbox_name, lvl, is_leaf
		  FROM (SELECT mailbox_sid, mailbox_name, LEVEL lvl, CONNECT_BY_ISLEAF is_leaf, rownum rn,
             	       sys_connect_by_path(to_char(mailbox_sid),'/')||'/' path,
             	       sys_connect_by_path(to_char(parent_sid),'/')||'/' ppath             	       
		 	      FROM mailbox m
			      START WITH (in_include_root = 0 AND parent_sid IN (SELECT column_value FROM TABLE(v_roots))) OR 
			 			     (in_include_root = 1 AND mailbox_sid IN (SELECT column_value FROM TABLE(v_roots)))
		 		CONNECT BY PRIOR NVL(link_to_mailbox_sid, mailbox_sid) = parent_sid
		 		  ORDER SIBLINGS BY LOWER(m.mailbox_name))
		  WHERE lvl <= in_fetch_depth OR path IN (
         			SELECT (SELECT '/'||reverse(sys_connect_by_path(reverse(to_char(mailbox_sid)),'/'))
                  	  	      FROM mailbox mp
                	         WHERE (in_include_root = 1 and mp.mailbox_sid IN (SELECT column_value FROM TABLE(v_roots))) OR 
                	 	           (in_include_root = 0 and mp.parent_sid IN (SELECT column_value FROM TABLE(v_roots)))
                                   START WITH mp.mailbox_sid = m.mailbox_sid
                                   CONNECT BY PRIOR mp.parent_sid = mp.mailbox_sid) path
		 		      FROM mailbox m
		 		           START WITH mailbox_sid = in_select_sid
		 	               CONNECT BY PRIOR parent_sid = mailbox_sid AND (
		 	                   (in_include_root = 1 AND PRIOR mailbox_sid NOT IN (SELECT column_value FROM TABLE(v_roots))) OR
           					   (in_include_root = 0 AND PRIOR parent_sid NOT IN (SELECT column_value FROM TABLE(v_roots))))
                  ) OR ppath IN (
         			SELECT (SELECT '/'||reverse(sys_connect_by_path(reverse(to_char(parent_sid)),'/'))
                  	  	      FROM mailbox mp
                	         WHERE (in_include_root = 1 and mp.mailbox_sid IN (SELECT column_value FROM TABLE(v_roots))) OR 
                	 	           (in_include_root = 0 and mp.parent_sid IN (SELECT column_value FROM TABLE(v_roots)))
                                   START WITH mp.mailbox_sid = m.mailbox_sid
                                   CONNECT BY PRIOR mp.parent_sid = mp.mailbox_sid) path
		 		      FROM mailbox m
		 		           START WITH mailbox_sid = in_select_sid
		 	               CONNECT BY PRIOR parent_sid = mailbox_sid AND (
		 	                   (in_include_root = 1 AND PRIOR mailbox_sid NOT IN (SELECT column_value FROM TABLE(v_roots))) OR
           					   (in_include_root = 0 AND PRIOR parent_sid NOT IN (SELECT column_value FROM TABLE(v_roots))))
           	      )
        ORDER BY rn;
END;
PROCEDURE getTreeTextFiltered(
	in_account_sid					IN  account.account_sid%TYPE,
	in_parent_sids					IN	security.security_pkg.T_SID_IDS,	
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_roots 						security.T_SID_TABLE;
	v_root_mailbox_sid				mailbox.mailbox_sid%TYPE;
BEGIN
	v_roots := ProcessStartPoints(in_parent_sids, in_include_root);
	
	SELECT root_mailbox_sid
	  INTO v_root_mailbox_sid
	  FROM account
	 WHERE account_sid = in_account_sid;
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ mailbox_sid, mailbox_name, lvl, is_leaf
		  FROM ( 
		  	SELECT mailbox_sid, mailbox_name, LEVEL lvl, CONNECT_BY_ISLEAF is_leaf, ROWNUM rn
		  	  FROM mailbox
		  	 	   START WITH (in_include_root = 0 AND parent_sid IN (SELECT column_value FROM TABLE(v_roots))) OR 
			 			      (in_include_root = 1 AND mailbox_sid IN (SELECT column_value FROM TABLE(v_roots)))
				   CONNECT BY PRIOR NVL(link_to_mailbox_sid, mailbox_sid) = parent_sid
		  	 ORDER SIBLINGS BY LOWER(mailbox_name))
		 WHERE mailbox_sid IN (
		  	SELECT m.mailbox_sid 
		  	  FROM mailbox m, (
					SELECT m2.mailbox_sid, m1.mailbox_sid parent_sid
					  FROM mailbox m1, mailbox m2
					 WHERE m1.link_to_mailbox_sid = m2.parent_sid
					 UNION ALL
					SELECT mailbox_sid, parent_sid
					  FROM mailbox
					  	   START WITH mailbox_sid = v_root_mailbox_sid
					  	   CONNECT BY PRIOR mailbox_sid = parent_sid) mp
			  WHERE m.mailbox_sid = mp.mailbox_sid
					START WITH m.mailbox_sid IN (SELECT mailbox_sid 
					       					       FROM mailbox 
					       				          WHERE LOWER(mailbox_name) LIKE '%'||LOWER(in_search_phrase)||'%')
			        CONNECT BY PRIOR mp.parent_sid = m.mailbox_sid)
		ORDER BY rn;
END;
PROCEDURE getListTextFiltered(
	in_parent_sids					IN	security.security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_fetch_limit					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_roots 						security.T_SID_TABLE;
BEGIN
	v_roots := ProcessStartPoints(in_parent_sids, in_include_root);
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ *
		  FROM (SELECT mailbox_sid, mailbox_name, link_to_mailbox_sid, LEVEL lvl, CONNECT_BY_ISLEAF is_leaf,
					   SYS_CONNECT_BY_PATH(mailbox_name, '/') path
				  FROM mailbox
				 WHERE LOWER(mailbox_name) LIKE '%'||LOWER(in_search_phrase)||'%'
			       	   START WITH (in_include_root = 0 AND parent_sid IN (SELECT column_value FROM TABLE(v_roots))) OR 
			 			          (in_include_root = 1 AND mailbox_sid IN (SELECT column_value FROM TABLE(v_roots)))
					   CONNECT BY PRIOR NVL(link_to_mailbox_sid, mailbox_sid) = parent_sid
				 ORDER SIBLINGS BY LOWER(mailbox_name))
		   WHERE rownum <= in_fetch_limit;
END;
FUNCTION getInboxSIDFromEmail(
	in_email_address				IN	VARCHAR2
) RETURN account.inbox_sid%TYPE
AS
	v_inbox_sid account.inbox_sid%TYPE;
BEGIN
	BEGIN
		SELECT a.inbox_sid
		  INTO v_inbox_sid
		  FROM account_alias aa, account a
		 WHERE LOWER(aa.email_address) = LOWER(in_email_address)
		   AND a.account_sid = aa.account_sid;
		 
		RETURN v_inbox_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE MAILBOX_NOT_FOUND;
	END;
END;
PROCEDURE getAllMailboxMessage(
	in_mailbox_sid					IN	mailbox.mailbox_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT mm.mailbox_sid, mm.message_uid, mm.flags, m.subject, m.message_dtm,
			   m.message_id_hdr, m.in_reply_to, m.priority, m.has_attachments,
			   mm.received_dtm, m.body
		  FROM mailbox_message mm, message m
		 WHERE mm.mailbox_sid = in_mailbox_sid
		   AND mm.message_id = m.message_id;
END;
PROCEDURE cleanOrphanedMessages
AS
	TYPE t_ids IS TABLE OF NUMBER;
	v_ids t_ids;
	v_id NUMBER;
BEGIN
	-- The bulk delete approach seems to be very slow, so do this one at a time using
	-- a pl/sql collection to avoid a long running cursor (which would be subject
	-- to undo aging out -- i.e. would get a 'snapshot too old' error)
	SELECT message_id
		   BULK COLLECT INTO v_ids
	  FROM mail.message
	 WHERE message_id NOT IN (SELECT message_id
								FROM mail.mailbox_message);
								
	FOR v_i IN 1 .. v_ids.COUNT LOOP
		v_id := v_ids(v_i);
		DELETE FROM mail.message_address_field
		 WHERE message_id = v_id;
		DELETE FROM mail.message_header
		 WHERE message_id = v_id;
		DELETE FROM mail.message
		 WHERE message_id = v_id;
		COMMIT;
		--security.security_pkg.debugmsg('cleaned '||v_id||' - ' ||v_i||' of '||v_ids.COUNT);
	END LOOP;
END;
END mail_pkg;
/


CREATE OR REPLACE PACKAGE chain.dedupe_admin_pkg as
	PROCEDURE dummy;
END;
/
CREATE OR REPLACE PACKAGE BODY chain.dedupe_admin_pkg as
	PROCEDURE dummy
	AS
	BEGIN
		null;
	END;
END;
/
CREATE OR REPLACE PACKAGE chain.dedupe_helper_pkg as
	PROCEDURE dummy;
END;
/
CREATE OR REPLACE PACKAGE BODY chain.dedupe_helper_pkg as
	PROCEDURE dummy
	AS
	BEGIN
		null;
	END;
END;
/
CREATE OR REPLACE PACKAGE chain.dedupe_preprocess_pkg as
	PROCEDURE dummy;
END;
/
CREATE OR REPLACE PACKAGE BODY chain.dedupe_preprocess_pkg as
	PROCEDURE dummy
	AS
	BEGIN
		null;
	END;
END;
/
GRANT EXECUTE ON chain.dedupe_admin_pkg TO web_user;
create or replace package csr.compliance_library_report_pkg as
	procedure dummy;
end;
/
create or replace package body csr.compliance_library_report_pkg as
	procedure dummy
	as
	begin
		null;
	end;
end;
/
GRANT EXECUTE ON csr.compliance_library_report_pkg TO web_user;
GRANT EXECUTE ON csr.compliance_library_report_pkg TO chain;
GRANT INSERT ON csr.compliance_item_history TO csrimp;


@..\schema_pkg
@..\img_chart_pkg
@..\chain\helper_pkg
@..\chain\company_type_pkg
@..\chain\dedupe_admin_pkg
@..\chain\dedupe_helper_pkg
@..\chain\dedupe_preprocess_pkg
@..\chain\company_dedupe_pkg
@..\section_pkg
@..\chain\business_relationship_pkg
@..\deleg_plan_pkg
@..\csr_data_pkg
@..\scenario_pkg
@..\compliance_pkg
@..\tag_pkg
@..\chain\chain_pkg
@..\factor_pkg
@..\approval_dashboard_pkg
@..\factor_set_group_pkg
@..\util_script_pkg
@..\csr_user_pkg
@..\meter_monitor_pkg
@@..\tag_pkg
@..\enable_pkg
DROP PACKAGE csr.comp_regulation_report_pkg;
DROP PACKAGE csr.comp_requirement_report_pkg;
@..\compliance_library_report_pkg
@..\chain\filter_pkg
@..\batch_job_pkg
@..\property_pkg


@..\csrimp\imp_body
@..\csr_app_body
@..\enable_body
@..\meter_body
@..\meter_monitor_body
@..\meter_report_body
@..\meter_patch_body
@..\meter_aggr_body
@..\schema_body
@..\img_chart_body
@..\chain\helper_body
@..\chain\chain_body
@..\chain\company_type_body
@..\chain\company_body
@..\chain\dedupe_admin_body
@..\chain\company_dedupe_body
@..\chain\dedupe_helper_body
@..\chain\dedupe_preprocess_body
@..\chain\test_chain_utils_body
@..\imp_body
@..\section_body
@..\section_root_body
@..\chain\business_relationship_body
@..\factor_body
@..\deleg_plan_body
@..\scenario_body
@..\approval_dashboard_body
@..\compliance_body
@..\region_body
@..\tag_body
@..\chain\company_filter_body
@..\chain\dashboard_body
@..\supplier_body
@..\factor_set_group_body
@..\util_script_body
@..\..\..\aspen2\db\aspen_user_body
@..\..\..\aspen2\db\aspenapp_body
@..\..\..\aspen2\db\fp_user_body
@..\csr_user_body
@..\teamroom_body
@..\chain\company_user_body
@..\chain\setup_body
@@..\tag_body
@..\compliance_library_report_body
@..\property_body



@update_tail
