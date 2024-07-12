define version=3189
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
CREATE OR REPLACE TYPE CSR.T_QS_INC_FIELD_ROW AS 
  OBJECT ( 
	ORACLE_COLUMN	VARCHAR2(30),
	BIND_TYPE		VARCHAR2(4),
	TEXT_VALUE		CLOB,
	NUM_VALUE		NUMBER(24,10),
	DATE_VALUE		DATE
  );
/
CREATE OR REPLACE TYPE CSR.T_QS_INC_FIELD_TABLE AS 
  TABLE OF CSR.T_QS_INC_FIELD_ROW;
/
CREATE TABLE CSR.FLOW_TRANSITION_ALERT_CC_ROLE(
    APP_SID                     NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    FLOW_TRANSITION_ALERT_ID    NUMBER(10, 0)    NOT NULL,
    ROLE_SID                    NUMBER(10, 0),
    GROUP_SID                   NUMBER(10, 0),
    CONSTRAINT CHK_FTACCR_ROLE_SID_GROUP_SID CHECK ((ROLE_SID IS NULL AND GROUP_SID IS NOT NULL) OR (ROLE_SID IS NOT NULL AND GROUP_SID IS NULL)),
    CONSTRAINT UK_FLOW_TRANS_ALERT_CC_ROLE UNIQUE (APP_SID, FLOW_TRANSITION_ALERT_ID, ROLE_SID, GROUP_SID)
)
;
CREATE TABLE CSR.FLOW_TRANSITION_ALERT_CC_USER(
    APP_SID                     NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    FLOW_TRANSITION_ALERT_ID    NUMBER(10, 0)    NOT NULL,
    USER_SID                    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_FLOW_TRANS_ALERT_CC_USER PRIMARY KEY (APP_SID, FLOW_TRANSITION_ALERT_ID, USER_SID)
)
;
CREATE TABLE CSRIMP.FLOW_TRANSITION_ALERT_CC_ROLE (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    FLOW_TRANSITION_ALERT_ID    NUMBER(10, 0)    NOT NULL,
    ROLE_SID                    NUMBER(10, 0)    NULL,
    GROUP_SID                   NUMBER(10, 0)    NULL,
    CONSTRAINT UC_FLOW_TRANS_ALERT_CC_ROLE UNIQUE (CSRIMP_SESSION_ID, FLOW_TRANSITION_ALERT_ID, ROLE_SID, GROUP_SID),
    CONSTRAINT FK_FL_TRANS_ALERT_CC_ROLE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
CREATE TABLE CSRIMP.FLOW_TRANSITION_ALERT_CC_USER(
	CSRIMP_SESSION_ID			NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	FLOW_TRANSITION_ALERT_ID	NUMBER(10, 0)	NOT NULL,
	USER_SID					NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_FLOW_TRANS_ALERT_CC_USER PRIMARY KEY (CSRIMP_SESSION_ID, FLOW_TRANSITION_ALERT_ID, USER_SID),
	CONSTRAINT FK_FLOW_Cc_CSR_USER FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);


ALTER TABLE csr.quick_survey ADD lookup_key VARCHAR2(256);
ALTER TABLE csrimp.quick_survey ADD lookup_key VARCHAR2(256);
CREATE UNIQUE INDEX csr.ix_quick_survey_lk ON csr.quick_survey(app_sid, NVL(UPPER(lookup_key), 'QS:' || survey_sid));
ALTER TABLE csr.customer ADD (
	allow_cc_on_alerts NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT ck_allow_cc_on_alerts CHECK (allow_cc_on_alerts IN (0,1))
);
ALTER TABLE csrimp.customer ADD (
	allow_cc_on_alerts NUMBER(1) NOT NULL,
	CONSTRAINT ck_allow_cc_on_alerts CHECK (allow_cc_on_alerts IN (0,1))
);
ALTER TABLE CSR.FLOW_TRANSITION_ALERT_CC_ROLE ADD CONSTRAINT FK_FLOW_TR_AL_CC_RL_FLOW_TR_AL
    FOREIGN KEY (APP_SID, FLOW_TRANSITION_ALERT_ID)
    REFERENCES CSR.FLOW_TRANSITION_ALERT(APP_SID, FLOW_TRANSITION_ALERT_ID)
;
ALTER TABLE CSR.FLOW_TRANSITION_ALERT_CC_ROLE ADD CONSTRAINT FK_CC_ROLE_FL_TR_AL_ROLE
    FOREIGN KEY (APP_SID, ROLE_SID)
    REFERENCES CSR.ROLE(APP_SID, ROLE_SID)
;
ALTER TABLE CSR.FLOW_TRANSITION_ALERT_CC_USER ADD CONSTRAINT FK_FLOW_CC_CSR_USER
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;
CREATE INDEX CSR.IX_FLOW_TR_AL_CC_RL_FLOW_TR_AL ON CSR.FLOW_TRANSITION_ALERT_CC_ROLE(APP_SID, FLOW_TRANSITION_ALERT_ID);
CREATE INDEX CSR.IX_CC_ROLE_FL_TR_AL_ROLE ON CSR.FLOW_TRANSITION_ALERT_CC_ROLE(APP_SID, ROLE_SID);
CREATE INDEX CSR.IX_FLOW_CC_CSR_USER ON CSR.FLOW_TRANSITION_ALERT_CC_USER(APP_SID, USER_SID);
ALTER TABLE CSR.T_FLOW_TRANS_ALERT ADD (
	CC_USER_SIDS					VARCHAR2(2000),
	CC_ROLE_SIDS					VARCHAR2(2000),
	CC_GROUP_SIDS					VARCHAR2(2000)
);
ALTER TABLE chain.company ADD signature VARCHAR2(1024);
ALTER TABLE csr.region MODIFY lookup_key VARCHAR2(1024);
@@latestUS15250_packages
BEGIN
	security.user_pkg.LogonAdmin;
	-- fix some bad data...
	UPDATE chain.company_type
	   SET default_region_layout = NULL
	 WHERE UPPER(default_region_layout) = 'NULL';
	-- Process differs from what the actual package will be doing, 
	-- still the eventual result will be the same
	-- 35 secs on .sup 
	-- signature will temporarily hold the normalised name
	UPDATE chain.company c
	   SET signature = chain.latestUS15250_package.NormaliseCompanyName(c.name);
	-- 2 mins on .sup
	UPDATE security.securable_object so
	   SET so.name = (
	   	SELECT c.signature || ' (' || c.company_sid || ')'  --signature holds the normalised name
		  FROM chain.company c
		 WHERE c.app_sid = so.application_sid_id
		   AND c.company_sid = so.sid_id
	)
 	 WHERE (so.application_sid_id, so.sid_id) IN (
	 	SELECT c.app_sid, c.company_sid
	   	  FROM chain.company c
	  	 WHERE c.deleted = 0
	);
	-- 1 min on .sup
	UPDATE chain.company c
	   SET c.signature = (
		SELECT chain.latestUS15250_package.GenerateCompanySignature(
			in_normalised_name		=> c.signature,
			in_country				=> c.country_code,
			in_company_type_id		=> c.company_type_id,
			in_city					=> city,	
			in_state				=> c.state,
			in_sector_id			=> c.sector_id,
			in_layout				=> NVL(ct.default_region_layout, '{COUNTRY}/{SECTOR}'),
			in_parent_sid			=> c.parent_sid
			)
		  FROM chain.company_type ct
		 WHERE ct.app_sid = c.app_sid
		   AND ct.company_type_id = c.company_type_id
	   );
	-- Handle dupicate signatures
	FOR r IN (
		SELECT app_sid, signature
		  FROM chain.company
		 WHERE deleted = 0
		   AND pending = 0
		 GROUP BY app_sid, signature
		 HAVING COUNT(*) > 1
	)
	LOOP
		UPDATE chain.company
		   SET signature = signature || '|sid:' || company_sid||'|DUPE-VAL'
		 WHERE app_sid = r.app_sid
		   AND signature = r.signature;
	END LOOP;
END;
/
DROP PACKAGE chain.latestUS15250_package;
ALTER TABLE chain.company MODIFY signature NOT NULL;
CREATE UNIQUE INDEX CHAIN.UK_COMPANY_SIGNATURE ON CHAIN.COMPANY (APP_SID, DECODE(PENDING + DELETED, 0, LOWER(SIGNATURE), COMPANY_SID));
ALTER TABLE csrimp.chain_company ADD signature VARCHAR2(1024) NOT NULL;
ALTER TABLE csrimp.region MODIFY lookup_key VARCHAR2(1024);
ALTER TABLE csr.scenario
  ADD DONT_RUN_AGGREGATE_INDICATORS NUMBER(1) DEFAULT 0 NOT NULL;
  
ALTER TABLE csr.scenario
  ADD CONSTRAINT ck_dont_run_agg_inds CHECK (DONT_RUN_AGGREGATE_INDICATORS IN (0, 1));
ALTER TABLE csrimp.scenario ADD DONT_RUN_AGGREGATE_INDICATORS NUMBER(1) NOT NULL;
DROP TABLE CSR.EXT_METER_DATA;
CREATE TABLE CSR.EXT_METER_DATA (
	CONTAINER_ID	VARCHAR2(1024),
	JOB_ID			VARCHAR2(1024),
	BUCKET_NAME		VARCHAR2(256),
	START_DTM		DATE,
	SERIAL_ID		VARCHAR2(1024),
	INPUT_KEY		VARCHAR2(256),
	UOM				VARCHAR2(256),
	VAL				NUMBER(24, 10)
)
ORGANIZATION EXTERNAL 
(
	TYPE ORACLE_LOADER 
	DEFAULT DIRECTORY DIR_EXT_METER_DATA 
	ACCESS PARAMETERS 
	( 
		RECORDS DELIMITED BY NEWLINE
		PREPROCESSOR DIR_SCRIPTS:'concatAllFiles.sh'
		FIELDS TERMINATED BY ','
		OPTIONALLY ENCLOSED BY '"'
		MISSING FIELD VALUES ARE NULL 
		(
			CONTAINER_ID,
			JOB_ID,
			BUCKET_NAME,
			START_DTM DATE 'YYYY-MM-DD HH24:MI:SS',
			SERIAL_ID,
			INPUT_KEY,
			UOM,
			VAL
		) 
	)
	LOCATION('path.txt') 
)
REJECT LIMIT UNLIMITED;
ALTER TABLE chain.import_source
  ADD override_company_active NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE csrimp.chain_import_source
  ADD override_company_active NUMBER(1, 0) NOT NULL;


GRANT SELECT, REFERENCES ON cms.fk_cons TO csr;
GRANT SELECT, REFERENCES ON cms.fk_cons_col TO csr;
GRANT SELECT, REFERENCES ON cms.uk_cons TO csr;
GRANT SELECT, REFERENCES ON cms.uk_cons_col TO csr;
grant select,insert,update,delete on csrimp.flow_transition_alert_cc_role to tool_user;
grant select,insert,update,delete on csrimp.flow_transition_alert_cc_user to tool_user;
grant insert on csr.flow_transition_alert_cc_role to csrimp;
grant insert on csr.flow_transition_alert_cc_user to csrimp;
GRANT UPDATE ON security.securable_object TO chain;
GRANT EXECUTE ON chain.helper_pkg TO csrimp;




CREATE OR REPLACE VIEW csr.v$quick_survey AS
	SELECT qs.app_sid, qs.survey_sid, d.label draft_survey_label, l.label live_survey_label,
		   NVL(l.label, d.label) label, qs.audience, qs.group_key, qs.created_dtm, qs.auditing_audit_type_id,
		   CASE WHEN l.survey_sid IS NOT NULL THEN 1 ELSE 0 END survey_is_published,
		   CASE WHEN qs.last_modified_dtm > l.published_dtm THEN 1 ELSE 0 END survey_has_unpublished_changes,
		   qs.score_type_id, st.label score_type_label, st.format_mask score_format_mask,
		   qs.quick_survey_type_id, qst.description quick_survey_type_desc, qs.current_version,
		   qs.from_question_library, qs.lookup_key
	  FROM csr.quick_survey qs
	  JOIN csr.quick_survey_version d ON qs.app_sid = d.app_sid AND qs.survey_sid = d.survey_sid
	  LEFT JOIN csr.quick_survey_version l ON qs.app_sid = l.app_sid AND qs.survey_sid = l.survey_sid AND qs.current_version = l.survey_version
	  LEFT JOIN csr.score_type st ON st.score_type_id = qs.score_type_id AND st.app_sid = qs.app_sid
	  LEFT JOIN csr.quick_survey_type qst ON qst.quick_survey_type_id = qs.quick_survey_type_id AND qst.app_sid = qs.app_sid
	 WHERE d.survey_version = 0;




 
BEGIN
	security.user_pkg.LogonAdmin;
	UPDATE chain.chain_user
	   SET registration_status_id = 1 /* chain_pkg.REGISTERED */
	 WHERE (app_sid, user_sid) IN (
		-- look for users that were created by dedupe
		 SELECT ch.app_sid, ch.user_sid
		   FROM chain.dedupe_merge_log ml
		   JOIN chain.dedupe_processed_record dpr
		     ON dpr.app_sid = ml.app_sid
		    AND dpr.dedupe_processed_record_id = ml.dedupe_processed_record_id
		   JOIN chain.chain_user ch
		     ON ch.user_sid = dpr.imported_user_sid
		    AND ch.app_sid = dpr.app_sid
		  WHERE ml.old_val IS NULL
			AND ml.dedupe_field_id = 105 /*  USERNAME */
			AND ch.registration_status_id = 0 /* chain_pkg.PENDING */
	 );
END;
/
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) 
VALUES (60, 'Enable CC on workflow alerts', 'Allows adding CC users/roles to workflow alerts. Use with caution!', 'EnableCCOnAlerts', NULL);
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) 
VALUES (61, 'Disable CC on workflow alerts', 'Turns off ability to add CC users/roles to workflow alerts.', 'DisableCCOnAlerts', NULL);
DECLARE
	PROCEDURE IgnoreDupe(
		in_insert_statement	VARCHAR2
	)
	AS
	BEGIN
		BEGIN
			EXECUTE IMMEDIATE in_insert_statement;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
			WHEN OTHERS THEN
				RAISE;
		END;
	END;
BEGIN
	IgnoreDupe('INSERT INTO csr.flow_alert_class (flow_alert_class, label, helper_pkg) VALUES (''regulation'', ''Regulation'', ''CSR.COMPLIANCE_PKG'')');
	IgnoreDupe('INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (5, ''regulation'', ''New'')');
	IgnoreDupe('INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (6, ''regulation'', ''Updated'')');
	IgnoreDupe('INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (7, ''regulation'', ''Action Required'')');
	IgnoreDupe('INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (8, ''regulation'', ''Compliant'')');
	IgnoreDupe('INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (9, ''regulation'', ''Not applicable'')');
	IgnoreDupe('INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (10, ''regulation'', ''Retired'')');
	IgnoreDupe('INSERT INTO csr.flow_alert_class (flow_alert_class, label, helper_pkg) VALUES (''requirement'', ''Requirement'', ''CSR.COMPLIANCE_PKG'')');
	IgnoreDupe('INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (11, ''requirement'', ''New'')');
	IgnoreDupe('INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (12, ''requirement'', ''Updated'')');
	IgnoreDupe('INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (13, ''requirement'', ''Action Required'')');
	IgnoreDupe('INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (14, ''requirement'', ''Compliant'')');
	IgnoreDupe('INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (15, ''requirement'', ''Not applicable'')');
	IgnoreDupe('INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (16, ''requirement'', ''Retired'')');
	IgnoreDupe('INSERT INTO csr.module_param (module_id, param_name, pos, param_hint) VALUES (79, ''Create regulation workflow?'', 0, ''(Y/N)'')');
	IgnoreDupe('INSERT INTO csr.module_param (module_id, param_name, pos, param_hint) VALUES (79, ''Create requirement workflow?'', 1, ''(Y/N)'')');
END;
/
BEGIN
	UPDATE csr.scenario
	   SET dont_run_aggregate_indicators = 1
	 WHERE scenario_sid in (
		SELECT scenario_sid 
		  FROM csr.scenario_run sr
		  JOIN csr.approval_dashboard ad ON (
			sr.scenario_run_sid = ad.active_period_scenario_run_sid OR 
			sr.scenario_run_sid = ad.signed_off_scenario_run_sid
		)
	);
END;
/
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (62, 'Remove calc xml from trashed indicator', 
  'Removes calc xml from a trashed indicator where the indicator references one or more deleted indicators', 'ClearTrashedIndCalcXml', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (62, 'Indicator sid', 'Sid of trashed indicator from which to delete calc xml', 1, NULL);
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (29, 'Migrate Emission Factor tool', '** It needs to be tested against test environments before applying Live**. It migrates old emission factor settings to the new Emission Factor Profile tool.','MigrateEmissionFactorTool','W2990');
EXCEPTION 
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (29, 'Profile Name', 'Profile Name', 0, 'Migrated profile');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/






@..\quick_survey_report_pkg
@..\audit_report_pkg
@..\chain\activity_report_pkg
@..\chain\bsci_2009_audit_report_pkg
@..\chain\bsci_2014_audit_report_pkg
@..\chain\bsci_ext_audit_report_pkg
@..\chain\bsci_supplier_report_pkg
@..\chain\business_rel_report_pkg
@..\chain\certification_report_pkg
@..\chain\company_filter_pkg
@..\chain\company_request_report_pkg
@..\chain\dedupe_proc_record_report_pkg
@..\chain\prdct_supp_mtrc_report_pkg
@..\chain\product_metric_report_pkg
@..\chain\product_report_pkg
@..\chain\product_supplier_report_pkg
@..\compliance_library_report_pkg
@..\compliance_register_report_pkg
@..\initiative_report_pkg
@..\issue_report_pkg
@..\meter_list_pkg
@..\meter_report_pkg
@..\non_compliance_report_pkg
@..\permit_report_pkg
@..\property_report_pkg
@..\region_report_pkg
@..\user_report_pkg
@..\quick_survey_pkg
@..\qs_incident_helper_pkg
@..\customer_pkg
@..\util_script_pkg
@..\schema_pkg
@..\flow_pkg
@..\chain\helper_pkg
@..\chain\company_type_pkg
@..\chain\company_pkg
@..\chain\test_chain_utils_pkg
@..\audit_pkg
@..\permit_pkg
@..\factor_pkg
@..\factor_set_group_pkg
@..\tag_pkg
@..\meter_pkg
@..\chain\chain_pkg
@..\chain\dedupe_admin_pkg


@..\enable_body
@..\quick_survey_report_body
@..\audit_report_body
@..\chain\activity_report_body
@..\chain\bsci_2009_audit_report_body
@..\chain\bsci_2014_audit_report_body
@..\chain\bsci_ext_audit_report_body
@..\chain\bsci_supplier_report_body
@..\chain\business_rel_report_body
@..\chain\certification_report_body
@..\chain\company_filter_body
@..\chain\company_request_report_body
@..\chain\dedupe_proc_record_report_body
@..\chain\prdct_supp_mtrc_report_body
@..\chain\product_metric_report_body
@..\chain\product_report_body
@..\chain\product_supplier_report_body
@..\compliance_library_report_body
@..\compliance_register_report_body
@..\initiative_report_body
@..\issue_report_body
@..\meter_list_body
@..\meter_report_body
@..\non_compliance_report_body
@..\permit_report_body
@..\property_report_body
@..\region_report_body
@..\user_report_body
@..\chain\company_dedupe_body
@..\doc_folder_body
@..\quick_survey_body
@..\qs_incident_helper_body
@..\schema_body
@..\csrimp\imp_body
@..\csr_data_body
@..\customer_body
@..\util_script_body
@..\flow_body
@..\csr_app_body
@..\..\..\Yam\db\webmail_body
@..\supplier_body
@..\chain\helper_body
@..\chain\dev_body
@..\chain\company_type_body
@..\chain\company_body
@..\chain\invitation_body
@..\chain\uninvited_body
@..\chain\test_chain_utils_body
@..\ct\supplier_body
@..\campaign_body
@..\audit_body
@..\scenario_body
@..\approval_dashboard_body
@..\permit_body
@..\region_body
@..\chain\filter_body
@..\factor_body
@..\factor_set_group_body
@..\issue_body
@..\csr_user_body
@..\tag_body
@..\meter_body
@..\meter_processing_job_body
@..\chain\dedupe_admin_body



@update_tail
