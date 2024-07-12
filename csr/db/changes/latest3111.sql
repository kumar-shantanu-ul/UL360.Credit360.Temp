define version=3111
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
CREATE TABLE CSR.USER_PROFILE_DEFAULT_ROLE (
	APP_SID								NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	ROLE_SID							NUMBER(10)	NOT NULL,
	AUTOMATED_IMPORT_CLASS_SID			NUMBER(10),
	STEP_NUMBER							NUMBER(10),
	CONSTRAINT PK_USER_PROFILE_DEFAULT_ROLE PRIMARY KEY (APP_SID, ROLE_SID, AUTOMATED_IMPORT_CLASS_SID, STEP_NUMBER),
	CONSTRAINT FK_USER_PROFILE_DEFAULT_ROLE FOREIGN KEY (APP_SID, ROLE_SID) REFERENCES CSR.ROLE (APP_SID, ROLE_SID),
	CONSTRAINT CK_USER_PROFILE_DEFAULT_ROLE CHECK (AUTOMATED_IMPORT_CLASS_SID IS NULL OR STEP_NUMBER IS NOT NULL)
)
;
create index csr.ix_user_profile_role_auto_imp on csr.user_profile_default_role (app_sid, automated_import_class_sid, step_number)
;
CREATE TABLE CHAIN.IMPORT_SOURCE_LOCK(
	APP_SID				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	IMPORT_SOURCE_ID	NUMBER(10, 0)	NOT NULL,
	IS_LOCKED			NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_IS_LOCK_IS_LOCKED CHECK (IS_LOCKED IN (0, 1)),
	CONSTRAINT PK_IMPORT_SOURCE_LOCK PRIMARY KEY (APP_SID, IMPORT_SOURCE_ID)
)
;
ALTER TABLE CHAIN.IMPORT_SOURCE_LOCK ADD CONSTRAINT FK_IS_LOCK_IMPORT_SOURCE
	FOREIGN KEY (APP_SID, IMPORT_SOURCE_ID)
	REFERENCES CHAIN.IMPORT_SOURCE (APP_SID, IMPORT_SOURCE_ID);
DROP TABLE CSR.T_FLOW_STATE_TRANS;
CREATE GLOBAL TEMPORARY TABLE CSR.T_FLOW_STATE_TRANS
(
	FLOW_SID					NUMBER(10) NOT NULL,
	POS							NUMBER(10) NOT NULL,
	FLOW_STATE_TRANSITION_ID	NUMBER(10) NOT NULL,
	FROM_STATE_ID				NUMBER(10) NOT NULL,
	TO_STATE_ID					NUMBER(10) NOT NULL,
	ASK_FOR_COMMENT				VARCHAR2(16) NOT NULL,
	MANDATORY_FIELDS_MESSAGE	VARCHAR2(255),
	AUTO_TRANS_TYPE				NUMBER(10) NOT NULL,
	HOURS_BEFORE_AUTO_TRAN		NUMBER(10),
	AUTO_SCHEDULE_XML			XMLTYPE,
	BUTTON_ICON_PATH			VARCHAR2(255),
	VERB						VARCHAR2(255) NOT NULL,
	LOOKUP_KEY					VARCHAR2(255),
	HELPER_SP					VARCHAR2(255),
	ROLE_SIDS					VARCHAR2(2000),
	COLUMN_SIDS					VARCHAR2(2000),
	INVOLVED_TYPE_IDS			VARCHAR2(2000),
	GROUP_SIDS					VARCHAR2(2000),
	ATTRIBUTES_XML				XMLTYPE
)
ON COMMIT DELETE ROWS;
CREATE TABLE surveys.audit_log (
	app_sid				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	audit_log_id		NUMBER(10) NOT NULL,
	audit_dtm			DATE DEFAULT SYSDATE NOT NULL,
	user_sid			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL,
	object_id			NUMBER(10) NOT NULL,
	object_type_id		NUMBER(10) NOT NULL,		-- constant survey(s)_pkg?
	CONSTRAINT PK_AUDIT_LOG PRIMARY KEY (app_sid, audit_log_id)
);
CREATE TABLE surveys.audit_log_detail (
	app_sid				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	audit_log_detail_id	NUMBER(10) NOT NULL,
	audit_log_id		NUMBER(10) NOT NULL,
	entity_path			VARCHAR2(4000),			-- survey/{sid}/versions/{version}/sections/{sectionId}/simpleHelp/{lang}
	new_value			VARCHAR2(255),			-- Updated help text
	old_value			VARCHAR2(255),			-- Old help text
	user_display_path	CLOB,					-- /section a / section a.1 / What is your name?
	user_disp_new_value	VARCHAR2(255),			-- Updated help text
	user_disp_old_value	VARCHAR2(255),			-- Old help text
	field_type			VARCHAR2(255),			-- survey/versions/sections/simpleHelp/
	operation			VARCHAR2(255),			-- CHANGE, ADD, DELETE etc.
	CONSTRAINT FK_AUDIT_DETAIL_AUDIT FOREIGN KEY (app_sid, audit_log_id) REFERENCES surveys.audit_log(app_sid, audit_log_id)
);
CREATE TABLE SURVEYS.CONDITION (
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CONDITION_ID			NUMBER(10, 0) 	NOT NULL,
	SURVEY_SID				NUMBER(10, 0)	NOT NULL,
	LABEL					NVARCHAR2(255)	NOT NULL,
	ROOT_GROUP_ID			NUMBER(10, 0),
	CONSTRAINT PK_CONDITION PRIMARY KEY(APP_SID, CONDITION_ID)
);
ALTER TABLE SURVEYS.CONDITION DROP COLUMN LABEL;
ALTER TABLE SURVEYS.CONDITION ADD LABEL VARCHAR2(255);
CREATE TABLE SURVEYS.CLAUSE_GROUP (
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CLAUSE_GROUP_ID			NUMBER(10, 0) 	NOT NULL,
	CONDITION_ID			NUMBER(10, 0)	NOT NULL,
	GROUP_TYPE				VARCHAR2(3) 	NOT NULL,
	CONSTRAINT PK_CLAUSE_GROUP PRIMARY KEY(APP_SID, CLAUSE_GROUP_ID)
);
CREATE TABLE SURVEYS.CLAUSE_GROUP_ITEM (
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CLAUSE_GROUP_ITEM_ID	NUMBER(10, 0) 	NOT NULL,
	CLAUSE_GROUP_ID			NUMBER(10, 0)	NOT NULL,
	CLAUSE_ID				NUMBER(10, 0),
	NESTED_GROUP_ID			NUMBER(10, 0),
	POSITION				NUMBER(10, 0)  NOT NULL,
	CONSTRAINT PK_CLAUSE_GROUP_ITEM PRIMARY KEY(APP_SID, CLAUSE_GROUP_ID, CLAUSE_GROUP_ITEM_ID)
);
CREATE TABLE SURVEYS.CLAUSE (
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CLAUSE_ID				NUMBER(10, 0)	NOT NULL,
	CLAUSE_TYPE				NUMBER(10, 0)	NOT NULL,
	CLAUSE_OPERATOR			NUMBER(10, 0)	NOT NULL,
	QUESTION_ID				NUMBER(10, 0),
	COUNTRY					VARCHAR2(25),
	TAG_ID					NUMBER(10, 0),
	QUESTION_OPTION_ID		NUMBER(10, 0),
	NUMERIC_VALUE			NUMBER(10,10),
	DATE_VALUE				DATE,
	CONSTRAINT PK_CLAUSE PRIMARY KEY(APP_SID, CLAUSE_ID)
);
CREATE TABLE SURVEYS.CONDITION_LINK (
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CONDITION_LINK_ID		NUMBER(10, 0) 	NOT NULL,
	CONDITION_ID			NUMBER(10, 0) 	NOT NULL,
	QUESTION_ID				NUMBER(10, 0),
	CONSTRAINT PK_CONDITION_LINK PRIMARY KEY(APP_SID, CONDITION_LINK_ID)
);
CREATE GLOBAL TEMPORARY TABLE surveys.temp_survey_versions
(
	SURVEY_SID     NUMBER(10) NOT NULL,
	SURVEY_VERSION NUMBER(10) NOT NULL
) ON COMMIT DELETE ROWS;


DECLARE
	v_count NUMBER;
BEGIN
	SELECT COUNT(*) INTO v_count
	  FROM all_constraints
	 WHERE constraint_name = 'CHK_COMPANY_REQUEST_ACTION' AND owner = 'CHAIN' AND table_name = 'COMPANY_REQUEST_ACTION';
	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE chain.company_request_action DROP CONSTRAINT chk_company_request_action';
	END IF;
END;
/
ALTER TABLE chain.company_request_action ADD CONSTRAINT chk_company_request_action
CHECK (action IN (1, 2, 3));
	 
	 
DECLARE
	v_count NUMBER;
BEGIN
	SELECT COUNT(*) INTO v_count
	  FROM all_constraints
	 WHERE constraint_name = 'CHK_ACTION_MATCHED' AND owner = 'CHAIN' AND table_name = 'COMPANY_REQUEST_ACTION';
	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE chain.company_request_action DROP CONSTRAINT chk_action_matched';
	END IF;
END;
/
	 
ALTER TABLE chain.company_request_action ADD CONSTRAINT chk_action_matched
CHECK ((action = 3 AND matched_company_sid IS NOT NULL) OR matched_company_sid IS NULL);
ALTER TABLE CSR.AUTO_IMP_USER_IMP_SETTINGS ADD REGION_MAPPING_TYPE_ID NUMBER(2) DEFAULT 1 NOT NULL;
ALTER TABLE CSR.AUTO_IMP_USER_IMP_SETTINGS ADD CONSTRAINT FK_AUTO_IMP_USER_SET_REGMAP
    FOREIGN KEY (REGION_MAPPING_TYPE_ID)
    REFERENCES CSR.AUTO_IMP_MAPPING_TYPE(MAPPING_TYPE_ID);
create index csr.ix_auto_imp_user_region_mappin on csr.auto_imp_user_imp_settings (region_mapping_type_id);	
ALTER TABLE CSR.AUTO_EXP_BATCHED_EXP_SETTINGS ADD (
	INCLUDE_FIRST_ROW NUMBER(1) DEFAULT 0 NOT NULL
);
UPDATE CSR.AUTO_EXP_BATCHED_EXP_SETTINGS SET INCLUDE_FIRST_ROW = 1 WHERE CONVERT_TO_DSV = 1;
ALTER TABLE CSR.AUTO_EXP_BATCHED_EXP_SETTINGS
ADD CONSTRAINT CK_AUTO_EXP_BATCH_EXP_INC_F_R CHECK (INCLUDE_FIRST_ROW IN (0, 1));
ALTER TABLE csr.flow_state_transition ADD (
	AUTO_SCHEDULE_XML	SYS.XMLType,
	AUTO_TRANS_TYPE		NUMBER(10) DEFAULT 0 NOT NULL,
	LAST_RUN_DTM		DATE
);
ALTER TABLE csrimp.flow_state_transition ADD (
	AUTO_SCHEDULE_XML	SYS.XMLType,
	AUTO_TRANS_TYPE		NUMBER(10) NOT NULL,
	LAST_RUN_DTM		DATE
);
DROP INDEX CHAIN.IX_COMPANY_PRODUCT_SKU;
ALTER TABLE chain.company_product RENAME COLUMN sku TO product_ref;
ALTER TABLE chain.company_product MODIFY (product_ref NULL);
CREATE UNIQUE INDEX CHAIN.IX_COMPANY_PRODUCT_REF ON CHAIN.COMPANY_PRODUCT(APP_SID, COMPANY_SID, LOWER(NVL(PRODUCT_REF, 'NOPRODUCTREF_' || PRODUCT_ID)));
ALTER TABLE chain.product_supplier ADD (
	PRODUCT_SUPPLIER_REF				VARCHAR2(1024)
);
CREATE UNIQUE INDEX CHAIN.IX_PRODUCT_SUPPLIER_REF ON CHAIN.PRODUCT_SUPPLIER(APP_SID, PRODUCT_ID, LOWER(NVL(PRODUCT_SUPPLIER_REF, 'NOSUPPLIERREF_' || PRODUCT_SUPPLIER_ID)));
ALTER TABLE csr.doc_folder_name_translation ADD (
	parent_sid		NUMBER(10)
);
ALTER TABLE csrimp.doc_folder_name_translation ADD (
	parent_sid		NUMBER(10)
);
BEGIN
	security.user_pkg.LogonAdmin();
	
	UPDATE csr.doc_folder_name_translation t 
	   SET parent_sid = (
		SELECT parent_sid_id 
		  FROM security.securable_object
		 WHERE sid_id = t.doc_folder_sid);
		 
	UPDATE csrimp.doc_folder_name_translation t 
	   SET parent_sid = (
		SELECT parent_sid_id 
		  FROM security.securable_object
		 WHERE sid_id = t.doc_folder_sid);
END;
/
	
ALTER TABLE csr.doc_folder_name_translation MODIFY (
	parent_sid		NUMBER(10) NOT NULL
);	
ALTER TABLE csrimp.doc_folder_name_translation MODIFY (
	parent_sid		NUMBER(10) NOT NULL
);
DECLARE
	v_cnt			NUMBER;
	v_curr_lang		VARCHAR2(1024) := 'NOTALANG';
BEGIN
	security.user_pkg.LogonAdmin();
	
	
	FOR R IN (
		SELECT doc_folder_sid, t.translated, t.lang, cnt from (
			SELECT parent_sid, translated, lang, COUNT(*) cnt FROM CSR.DOC_FOLDER_NAME_TRANSLATION ft
			GROUP BY parent_sid, translated, lang
		) t
		JOIN csr.DOC_FOLDER_NAME_TRANSLATION dt
		ON dt.parent_sid = t.parent_sid AND dt.translated = t.translated AND dt.lang = t.lang
		WHERE t.cnt > 1
		ORDER BY t.parent_sid, t.translated, t.lang, doc_folder_sid ASC
	) LOOP
		IF v_curr_lang != r.lang THEN
			v_cnt := r.cnt;
			v_curr_lang := r.lang;
		END IF;
		
		IF r.translated = 'supporting_docs' THEN
			IF v_cnt != 1 THEN
				UPDATE csr.DOC_FOLDER_NAME_TRANSLATION 
				   SET translated = translated || ' (' || (v_cnt - 1) || ')'
				 WHERE doc_folder_sid = r.doc_folder_sid
				   AND lang = r.lang;
			END IF;
			
			v_cnt := v_cnt - 1;
		ELSE
			IF v_cnt != r.cnt THEN
				UPDATE csr.DOC_FOLDER_NAME_TRANSLATION 
				   SET translated = translated || ' (' || v_cnt || ')'
				 WHERE doc_folder_sid = r.doc_folder_sid
				   AND lang = r.lang;
			END IF;
			
			v_cnt := v_cnt - 1;
		END IF;
	END LOOP;
END;
/
	
ALTER TABLE csr.doc_folder_name_translation ADD CONSTRAINT UK_DOC_FOLDER_NAME UNIQUE (parent_sid, lang, translated);
ALTER TABLE csrimp.doc_folder_name_translation ADD CONSTRAINT UK_DOC_FOLDER_NAME UNIQUE (parent_sid, lang, translated);
ALTER TABLE SURVEYS.SURVEY_VERSION ADD AUDIENCE VARCHAR2(32) NULL;
ALTER TABLE SURVEYS.SURVEY_VERSION_TR ADD SUBMIT_MESSAGE VARCHAR2(4000) NULL;
ALTER TABLE SURVEYS.ANSWER DROP CONSTRAINT CHK_SURVEY_ANSWER_VALUE;
ALTER TABLE SURVEYS.ANSWER ADD CONSTRAINT CHK_SURVEY_ANSWER_VALUE CHECK ((TEXT_VALUE_SHORT IS NOT NULL AND TEXT_VALUE_LONG IS NULL AND BOOLEAN_VALUE IS NULL AND NUMERIC_VALUE IS NULL AND DATE_VALUE IS NULL)
									OR (TEXT_VALUE_SHORT IS NULL AND TEXT_VALUE_LONG IS NOT NULL AND BOOLEAN_VALUE IS NULL AND NUMERIC_VALUE IS NULL AND DATE_VALUE IS NULL)
									OR (TEXT_VALUE_SHORT IS NULL AND TEXT_VALUE_LONG IS NULL AND BOOLEAN_VALUE IS NOT NULL AND NUMERIC_VALUE IS NULL AND DATE_VALUE IS NULL)
									OR (TEXT_VALUE_SHORT IS NULL AND TEXT_VALUE_LONG IS NULL AND BOOLEAN_VALUE IS NULL AND NUMERIC_VALUE IS NOT NULL AND DATE_VALUE IS NULL)
									OR (TEXT_VALUE_SHORT IS NULL AND TEXT_VALUE_LONG IS NULL AND BOOLEAN_VALUE IS NULL AND NUMERIC_VALUE IS NULL AND DATE_VALUE IS NOT NULL)
									OR (TEXT_VALUE_SHORT IS NULL AND TEXT_VALUE_LONG IS NULL AND BOOLEAN_VALUE IS NULL AND NUMERIC_VALUE IS NULL AND DATE_VALUE IS NULL))
;
ALTER TABLE SURVEYS.CONDITION
	ADD SURVEY_VERSION NUMBER(10, 0);
ALTER TABLE SURVEYS.QUESTION ADD (
	MATRIX_ROW_ID			NUMBER(10, 0)
);
ALTER TABLE SURVEYS.CONDITION ADD CONSTRAINT FK_CONDITION_SURVEY_VERSION
	FOREIGN KEY (APP_SID, SURVEY_SID, SURVEY_VERSION)
	REFERENCES SURVEYS.SURVEY_VERSION (APP_SID, SURVEY_SID, SURVEY_VERSION);
ALTER TABLE surveys.clause_group ADD CONSTRAINT fk_clause_group_condition
     FOREIGN KEY (app_sid, condition_id)
     REFERENCES surveys.condition (app_sid, condition_id)
     ON DELETE CASCADE;
ALTER TABLE SURVEYS.CLAUSE_GROUP_ITEM ADD CONSTRAINT fk_clause_grp_item_clause_grp
     FOREIGN KEY (app_sid, clause_group_id)
     REFERENCES surveys.clause_group (app_sid, clause_group_id)
     ON DELETE CASCADE;
ALTER TABLE SURVEYS.CLAUSE_GROUP_ITEM ADD CONSTRAINT fk_clause_group_item_clause
     FOREIGN KEY (app_sid, clause_id)
     REFERENCES surveys.clause (app_sid, clause_id)
     ON DELETE CASCADE;
     -- FOREIGN KEY (app_sid, clause_id)
     -- REFERENCES surveys.clause (app_sid, clause_id)
     -- ON DELETE CASCADE;
ALTER TABLE SURVEYS.CONDITION_LINK ADD CONSTRAINT fk_condition_link_condition
	FOREIGN KEY (app_sid, condition_id)
	REFERENCES surveys.condition (app_sid, condition_id);
ALTER TABLE SURVEYS.CONDITION_LINK ADD CONSTRAINT fk_condition_link_question
	FOREIGN KEY (app_sid, question_id)
	REFERENCES surveys.question (app_sid, question_id);
ALTER TABLE csr.customer_saml_sso ADD show_sso_option_login NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE csr.customer_saml_sso ADD CONSTRAINT chk_show_sso_option_log CHECK (show_sso_option_login IN (0,1));
UPDATE csr.meter_source_type SET description = 'Urjanet meter' WHERE name ='period-null-start-dtm';
DELETE FROM csr.module where module_id = 96;
ALTER TABLE CSR.CUSTOMER_SAML_SSO ADD USE_DEFAULT_USER_ACC NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.CUSTOMER_SAML_SSO ADD DEFAULT_LOGON_USER_SID NUMBER(10, 0);
ALTER TABLE CSR.CUSTOMER_SAML_SSO ADD CONSTRAINT FK_DEFAULT_LOGON_USER_SID FOREIGN KEY (APP_SID, DEFAULT_LOGON_USER_SID) REFERENCES CSR.CSR_USER (APP_SID, CSR_USER_SID);
ALTER TABLE CSR.CUSTOMER_SAML_SSO ADD CONSTRAINT CHK_USE_DEFAULT_USER_ACC CHECK (USE_DEFAULT_USER_ACC IN (0,1));
ALTER TABLE CSR.CUSTOMER_SAML_SSO ADD CONSTRAINT CHK_USE_DEF_USER_ACC_SET CHECK (USE_DEFAULT_USER_ACC <> 1 OR (USE_DEFAULT_USER_ACC = 1 AND DEFAULT_LOGON_USER_SID IS NOT NULL));
CREATE INDEX CSR.IX_CUST_SAML_SSO_DEF_USER_SID ON CSR.CUSTOMER_SAML_SSO (APP_SID, DEFAULT_LOGON_USER_SID);


GRANT INSERT ON CHAIN.IMPORT_SOURCE_LOCK TO CSRIMP;
grant select on chain.v$company_admin to csr;
GRANT SELECT, REFERENCES ON csr.v$customer_lang TO surveys;
GRANT SELECT ON chain.v$company_reference TO csr;
GRANT SELECT ON chain.reference TO csr;
GRANT SELECT, DELETE ON chain.company_reference TO csr;
GRANT EXECUTE ON chain.helper_pkg TO csr;




CREATE OR REPLACE VIEW chain.v$company_product AS
	SELECT cp.app_sid, cp.product_id, tr.description product_name, cp.company_sid, cp.product_type_id,
		   cp.product_ref, cp.lookup_key, cp.is_active
	  FROM chain.company_product cp
	  JOIN chain.company_product_tr tr ON tr.product_id = cp.product_id AND tr.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');




UPDATE chain.filter_type
   SET helper_pkg = 'csr.permit_report_pkg'
 WHERE helper_pkg = 'csr.permit_pkg';
BEGIN
	security.user_pkg.logonadmin;
	INSERT INTO chain.import_source_lock (app_sid, import_source_id)
	SELECT app_sid, import_source_id
	  FROM chain.import_source
	 WHERE is_owned_by_system = 0;
END;
/
BEGIN
	security.user_pkg.logonadmin;
	UPDATE chain.saved_filter_alert_param
	   SET field_name = 'PRODUCT_REF', description = 'Product Reference'
	 WHERE field_name = 'SKU';
END;
/
DECLARE
	v_plugin_id			NUMBER(10, 0);
BEGIN
	security.user_pkg.logonadmin;
	BEGIN
		SELECT plugin_id
		  INTO v_plugin_id
		  FROM csr.plugin WHERE js_class = 'Chain.ManageProduct.ProductDetailsTab';
		DELETE FROM chain.product_tab_product_type
		 WHERE product_tab_id IN (
			SELECT product_tab_id
			  FROM chain.product_tab
			 WHERE plugin_id = v_plugin_id
		 );
		
		DELETE FROM chain.product_tab
		 WHERE plugin_id = v_plugin_id;
		DELETE FROM csr.plugin
		 WHERE plugin_id = v_plugin_id;
	EXCEPTION
		WHEN no_data_found THEN
			NULL;
	END;
END;
/
UPDATE surveys.survey_version
   SET audience  = 'everyone'
 WHERE audience IS NULL;
UPDATE surveys.survey_version_tr
   SET submit_message = '<p>Thank you for your submission</p>'
 WHERE submit_message IS NULL;
ALTER TABLE SURVEYS.SURVEY_VERSION MODIFY AUDIENCE NOT NULL;
ALTER TABLE SURVEYS.SURVEY_VERSION_TR MODIFY SUBMIT_MESSAGE NOT NULL;
INSERT INTO surveys.question_type (question_type, label)
VALUES ('matrixset', 'Matrix question set');
CREATE SEQUENCE surveys.condition_id_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;
CREATE SEQUENCE surveys.clause_group_id_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;
CREATE SEQUENCE surveys.clause_group_item_id_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;
 CREATE SEQUENCE surveys.clause_id_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;
 CREATE SEQUENCE surveys.condition_link_id_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;


begin
	for r in (select * from all_objects where owner='CHAIN' and object_name='TEST_PRODUCT_DATA_PKG' and object_type='PACKAGE') loop
		execute immediate 'drop package chain.test_product_data_pkg';
	end loop;
end;
/

CREATE OR REPLACE PACKAGE surveys.condition_pkg AS END;
/
GRANT EXECUTE ON surveys.condition_pkg TO web_user;


@..\chain\company_user_pkg
@..\integration_api_pkg
--@..\surveys\survey_pkg
@..\automated_import_pkg
@..\chain\chain_pkg
@..\chain\company_dedupe_pkg
@..\supplier_pkg
@..\user_profile_pkg
@..\batch_exporter_pkg
@..\automated_export_pkg
@..\recurrence_pattern_pkg
@..\flow_pkg
@..\chain\company_product_pkg
@..\csr_data_pkg
@..\audit_pkg
--@..\surveys\question_library_pkg
--@..\surveys\condition_pkg
@..\saml_pkg
@..\chain\company_pkg
@..\enable_pkg


@..\quick_survey_body
@..\chain\company_user_body
@..\integration_api_body
--@..\surveys\survey_body
@..\compliance_library_report_body
@..\chain\company_product_body
@..\chain\product_report_body
@..\chain\product_supplier_report_body
@..\automated_import_body
@..\user_profile_body
@..\chain\chain_body
@..\chain\company_dedupe_body
@..\chain\dedupe_admin_body
@..\chain\test_chain_utils_body
@..\csrimp\imp_body
@..\supplier_body
@..\batch_exporter_body
@..\automated_export_body
@..\recurrence_pattern_body
@..\flow_body
@..\schema_body
@..\csr_data_body
@..\audit_body
@..\chain\supplier_audit_body
@..\compliance_setup_body
@..\compliance_register_report_body
@..\doc_folder_body
@..\initiative_doc_body
--@..\surveys\question_library_body
--@..\surveys\condition_body
@..\saml_body
@..\chain\company_body
@..\enable_body
@..\stored_calc_datasource_body
@..\scenario_run_snapshot_body



@update_tail
