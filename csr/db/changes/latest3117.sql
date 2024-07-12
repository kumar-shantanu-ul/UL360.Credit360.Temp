define version=3117
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
CREATE TABLE CSR.TAG_DESCRIPTION(
	APP_SID				NUMBER(10, 0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	TAG_ID				NUMBER(10, 0)		NOT NULL,
	LANG				VARCHAR2(10)		NOT NULL,
	TAG					VARCHAR2(255)		NOT NULL,
	EXPLANATION			VARCHAR2(1024),
	LAST_CHANGED_DTM	DATE,
	CONSTRAINT PK_TAG_DESCRIPTION PRIMARY KEY (APP_SID, TAG_ID, LANG)
);
CREATE TABLE CSR.TAG_GROUP_DESCRIPTION(
	APP_SID				NUMBER(10, 0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	TAG_GROUP_ID		NUMBER(10, 0)		NOT NULL,
	LANG				VARCHAR2(10)		NOT NULL,
	NAME				VARCHAR2(255)		NOT NULL,
	LAST_CHANGED_DTM	DATE,
	CONSTRAINT PK_TAG_GROUP_DESCRIPTION PRIMARY KEY (APP_SID, TAG_GROUP_ID, LANG)
);
CREATE TABLE CSRIMP.TAG_DESCRIPTION(
	CSRIMP_SESSION_ID	NUMBER(10)			DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	TAG_ID				NUMBER(10, 0)		NOT NULL,
	LANG				VARCHAR2(10)		NOT NULL,
	TAG					VARCHAR2(255)		NOT NULL,
	EXPLANATION			VARCHAR2(1024),
	LAST_CHANGED_DTM	DATE,
	CONSTRAINT PK_TAG_DESCRIPTION PRIMARY KEY (CSRIMP_SESSION_ID, TAG_ID, LANG),
	CONSTRAINT FK_TAG_DESCRIPTION_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);
CREATE TABLE CSRIMP.TAG_GROUP_DESCRIPTION(
	CSRIMP_SESSION_ID	NUMBER(10)			DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	TAG_GROUP_ID		NUMBER(10, 0)		NOT NULL,
	LANG 				VARCHAR2(10)		NOT NULL,
	NAME				VARCHAR2(255)		NOT NULL,
	LAST_CHANGED_DTM	DATE,
	CONSTRAINT PK_TAG_GROUP_DESCRIPTION PRIMARY KEY (CSRIMP_SESSION_ID, TAG_GROUP_ID, LANG),
	CONSTRAINT FK_TAG_GROUP_DESCRIPTION_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);
DROP INDEX csr.UK_TAG_GROUP_NAME;
CREATE TABLE chain.company_product_tag (
	APP_SID								NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	PRODUCT_ID							NUMBER(10, 0)    NOT NULL,
    TAG_GROUP_ID						NUMBER(10, 0)    NOT NULL,
    TAG_ID								NUMBER(10, 0)    NOT NULL,
	CONSTRAINT PK_COMPANY_PRODUCT_TAG PRIMARY KEY (APP_SID, PRODUCT_ID, TAG_GROUP_ID, TAG_ID),
	CONSTRAINT FK_COMPANY_PRODUCT_TAG_PROD FOREIGN KEY (APP_SID, PRODUCT_ID) REFERENCES CHAIN.COMPANY_PRODUCT (APP_SID, PRODUCT_ID)
);
CREATE TABLE chain.product_supplier_tag (
	APP_SID								NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	PRODUCT_SUPPLIER_ID					NUMBER(10, 0)    NOT NULL,
    TAG_GROUP_ID						NUMBER(10, 0)    NOT NULL,
    TAG_ID								NUMBER(10, 0)    NOT NULL,
	CONSTRAINT PK_PRODUCT_SUPPLIER_TAG PRIMARY KEY (APP_SID, PRODUCT_SUPPLIER_ID, TAG_GROUP_ID, TAG_ID),
	CONSTRAINT FK_PRODUCT_SUPPLIER_TAG_PRSP FOREIGN KEY (APP_SID, PRODUCT_SUPPLIER_ID) REFERENCES CHAIN.PRODUCT_SUPPLIER (APP_SID, PRODUCT_SUPPLIER_ID)
);
DROP INDEX CSR.PK_ALT_TAG_GROUP;
CREATE TABLE CSR.INTAPI_COMPANY_USER_GROUP(
	APP_SID			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	GROUP_SID_ID	NUMBER(10, 0)	NOT NULL,
	CONSTRAINT FK_GROUP_SID_ID FOREIGN KEY (GROUP_SID_ID) REFERENCES SECURITY.GROUP_TABLE (SID_ID),
	CONSTRAINT PK_INTAPI_COMPANY_USER_GROUP PRIMARY KEY (APP_SID, GROUP_SID_ID)
)
;
CREATE TABLE CSRIMP.INTAPI_COMPANY_USER_GROUP(
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	GROUP_SID_ID				NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_INTAPI_COMPANY_USER_GROUP PRIMARY KEY(CSRIMP_SESSION_ID, GROUP_SID_ID)
);


ALTER TABLE csr.tag_group ADD (
	APPLIES_TO_CHAIN_PRODUCTS			NUMBER(1, 0)     DEFAULT 0 NOT NULL,
	APPLIES_TO_CHAIN_PRODUCT_SUPPS		NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CONSTRAINT CHK_APPLIES_TO_CHAIN_PRD_1_0 CHECK (APPLIES_TO_CHAIN_PRODUCTS IN (1, 0)),
    CONSTRAINT CHK_APPLIES_TO_CHAIN_PRD_S_1_0 CHECK (APPLIES_TO_CHAIN_PRODUCT_SUPPS IN (1, 0))
);
ALTER TABLE csrimp.tag_group ADD (
	APPLIES_TO_CHAIN_PRODUCTS			NUMBER(1, 0)     DEFAULT 0 NOT NULL,
	APPLIES_TO_CHAIN_PRODUCT_SUPPS		NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CONSTRAINT CHK_APPLIES_TO_CHAIN_PRD_1_0 CHECK (APPLIES_TO_CHAIN_PRODUCTS IN (1, 0)),
    CONSTRAINT CHK_APPLIES_TO_CHAIN_PRD_S_1_0 CHECK (APPLIES_TO_CHAIN_PRODUCT_SUPPS IN (1, 0))
);
CREATE INDEX chain.ix_company_produ_tag_group_id_ on chain.company_product_tag (app_sid, tag_group_id, tag_id);
CREATE INDEX chain.ix_product_suppl_tag_group_id_ on chain.product_supplier_tag (app_sid, tag_group_id, tag_id);
ALTER TABLE csr.plugin DROP CONSTRAINT ck_plugin_refs;
DROP INDEX csr.plugin_js_class;
ALTER TABLE csr.plugin ADD (
    PRE_FILTER_SID			NUMBER(10, 0),
	CONSTRAINT CK_PLUGIN_REFS CHECK(
        (TAB_SID IS NULL AND (FORM_PATH IS NULL AND FORM_SID IS NULL) AND
		 GROUP_KEY IS NULL AND
         (SAVED_FILTER_SID IS NULL AND PRE_FILTER_SID IS NULL) AND
         CONTROL_LOOKUP_KEYS IS NULL AND PORTAL_SID IS NULL)
        OR
        (APP_SID IS NOT NULL AND(
            (TAB_SID IS NOT NULL AND (FORM_PATH IS NOT NULL OR FORM_SID IS NOT NULL) AND
             GROUP_KEY IS NULL AND
             (SAVED_FILTER_SID IS NULL AND PRE_FILTER_SID IS NULL) AND
             PORTAL_SID IS NULL)
            OR
            (TAB_SID IS NULL AND (FORM_PATH IS NULL AND FORM_SID IS NULL) AND
			 GROUP_KEY IS NOT NULL AND
             (SAVED_FILTER_SID IS NULL AND PRE_FILTER_SID IS NULL) AND
             PORTAL_SID IS NULL)
            OR
            (TAB_SID IS NULL AND (FORM_PATH IS NULL AND FORM_SID IS NULL) AND
             GROUP_KEY IS NULL AND
             (SAVED_FILTER_SID IS NOT NULL OR PRE_FILTER_SID IS NOT NULL) AND
             PORTAL_SID IS NULL)
            OR
            (TAB_SID IS NULL AND (FORM_PATH IS NULL AND FORM_SID IS NULL) AND
             GROUP_KEY IS NULL AND
             (SAVED_FILTER_SID IS NULL AND PRE_FILTER_SID IS NULL) AND
             PORTAL_SID IS NOT NULL)
        ))
    )
);
CREATE UNIQUE INDEX csr.plugin_js_class ON CSR.PLUGIN(APP_SID, JS_CLASS, FORM_PATH, GROUP_KEY, SAVED_FILTER_SID, RESULT_MODE, PORTAL_SID, R_SCRIPT_PATH, FORM_SID, PRE_FILTER_SID);
CREATE INDEX csr.ix_plugin_pre_filter ON CSR.PLUGIN (APP_SID, PRE_FILTER_SID);
ALTER TABLE csrimp.plugin ADD (
    PRE_FILTER_SID			NUMBER(10, 0)
);
ALTER TABLE CSR.AUTO_IMP_USER_IMP_SETTINGS ADD DATE_STRING_EXACT_PARSE_FORMAT VARCHAR2(255);
ALTER TABLE SURVEYS.CLAUSE
	ADD	(VALUE_TYPE NUMBER(10, 0),
		 TEXT_VALUE NUMBER(10, 0)
	);
ALTER TABLE SURVEYS.CLAUSE
	MODIFY TEXT_VALUE VARCHAR2(4000);
ALTER TABLE SURVEYS.CLAUSE
	MODIFY NUMERIC_VALUE NUMBER;
ALTER TABLE SURVEYS.CONDITION_LINK
	ADD	(SURVEY_SID NUMBER(10,0),
	 	 SURVEY_VERSION NUMBER(10,0),
	 	 SECTION_ID NUMBER(10, 0)
		);
ALTER TABLE SURVEYS.CONDITION_LINK ADD CONSTRAINT fk_condition_link_survey_sec
	FOREIGN KEY (app_sid, survey_sid, survey_version, section_id)
	REFERENCES surveys.survey_section (app_sid, survey_sid, survey_version, section_id);
/* US9220 */
ALTER TABLE SURVEYS.ANSWER ADD COMMENT_TEXT VARCHAR2(1000);
/* US10200*/
ALTER TABLE SURVEYS.ANSWER DROP CONSTRAINT FK_ANSWER_Q_OPTION;
ALTER TABLE SURVEYS.ANSWER DROP COLUMN QUESTION_OPTION_ID;
ALTER TABLE SURVEYS.ANSWER DROP CONSTRAINT PK_SURVEY_ANSWER;
ALTER TABLE SURVEYS.ANSWER ADD CONSTRAINT PK_SURVEY_ANSWER PRIMARY KEY (APP_SID, ANSWER_ID);
ALTER TABLE SURVEYS.ANSWER DROP CONSTRAINT CHK_SURVEY_ANSWER_VALUE;
ALTER TABLE SURVEYS.ANSWER ADD CONSTRAINT CHK_SURVEY_ANSWER_VALUE CHECK ((
	CASE WHEN TEXT_VALUE_SHORT	IS NOT NULL THEN 1 ELSE 0 END +
	CASE WHEN TEXT_VALUE_LONG	IS NOT NULL THEN 1 ELSE 0 END +
	CASE WHEN BOOLEAN_VALUE		IS NOT NULL THEN 1 ELSE 0 END +
	CASE WHEN NUMERIC_VALUE		IS NOT NULL THEN 1 ELSE 0 END +
	CASE WHEN DATE_VALUE		IS NOT NULL THEN 1 ELSE 0 END
) <= 1);
CREATE TABLE SURVEYS.ANSWER_OPTION(
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	ANSWER_ID				NUMBER(10, 0)	NOT NULL,
	QUESTION_ID				NUMBER(10, 0)	NOT NULL,
	QUESTION_OPTION_ID		NUMBER(10, 0)	NOT NULL,
	QUESTION_VERSION		NUMBER(10, 0)	NOT NULL,
	QUESTION_DRAFT			NUMBER(1)		NOT NULL,
	CONSTRAINT PK_ANSWER_OPTION PRIMARY KEY (APP_SID, ANSWER_ID, QUESTION_OPTION_ID)
);
ALTER TABLE SURVEYS.ANSWER_OPTION ADD CONSTRAINT FK_ANSWER_OPTION_Q_OPT
	FOREIGN KEY (APP_SID, QUESTION_ID, QUESTION_OPTION_ID, QUESTION_VERSION, QUESTION_DRAFT)
	REFERENCES SURVEYS.QUESTION_OPTION (APP_SID, QUESTION_ID, QUESTION_OPTION_ID, QUESTION_VERSION, QUESTION_DRAFT);
ALTER TABLE SURVEYS.ANSWER_OPTION ADD CONSTRAINT FK_ANSWER_OPTION_ANSWER
	FOREIGN KEY (APP_SID, ANSWER_ID)
	REFERENCES SURVEYS.ANSWER (APP_SID, ANSWER_ID);
ALTER TABLE SURVEYS.QUESTION_OPTION ADD CONSTRAINT FK_QUESTION_OPTION_QUESTION
	FOREIGN KEY (APP_SID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT)
	REFERENCES SURVEYS.QUESTION_VERSION (APP_SID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT);
/* end of US10200 */
ALTER TABLE SURVEYS.QUESTION_VERSION_TR ADD DETAILED_HELP_LINK	VARCHAR2(4000);
 UPDATE SURVEYS.QUESTION_VERSION_TR tr
	SET (DETAILED_HELP_LINK) = (SELECT qv.DETAILED_HELP_LINK
								 FROM SURVEYS.QUESTION_VERSION qv
								WHERE qv.question_id = tr.QUESTION_ID
								  AND qv.QUESTION_VERSION = tr.QUESTION_VERSION
								  AND qv.QUESTION_DRAFT = tr.QUESTION_DRAFT)
  WHERE EXISTS (
	SELECT 1
	  FROM SURVEYS.QUESTION_VERSION qv
	 WHERE qv.question_id = tr.QUESTION_ID
	   AND qv.QUESTION_VERSION = tr.QUESTION_VERSION
	   AND qv.QUESTION_DRAFT = tr.QUESTION_DRAFT );
ALTER TABLE SURVEYS.QUESTION_VERSION DROP COLUMN DETAILED_HELP_LINK;
ALTER TABLE SURVEYS.QUESTION DROP (MATRIX_PARENT_VERSION, MATRIX_PARENT_DRAFT);
ALTER TABLE SURVEYS.CONDITION_LINK ADD QUESTION_OPTION_ID NUMBER(10, 0);


GRANT INSERT ON CSR.TAG_DESCRIPTION TO CSRIMP;
GRANT INSERT ON CSR.TAG_GROUP_DESCRIPTION TO CSRIMP;
GRANT INSERT, SELECT, UPDATE, DELETE ON CSRIMP.TAG_DESCRIPTION TO TOOL_USER;
GRANT INSERT, SELECT, UPDATE, DELETE ON CSRIMP.TAG_GROUP_DESCRIPTION TO TOOL_USER;
grant delete on chem.cas_restricted to csr;
grant delete on chem.cas_group_member to csr;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.intapi_company_user_group TO tool_user;
GRANT SELECT, INSERT, UPDATE ON csr.intapi_company_user_group TO csrimp;
grant execute on csr.trash_pkg to surveys;


ALTER TABLE chain.company_product_tag ADD (
	CONSTRAINT FK_COMPANY_PRODUCT_TAG_TAG FOREIGN KEY (APP_SID, TAG_GROUP_ID, TAG_ID) REFERENCES CSR.TAG_GROUP_MEMBER (APP_SID, TAG_GROUP_ID, TAG_ID)
);
ALTER TABLE chain.product_supplier_tag ADD (
	CONSTRAINT FK_PRODUCT_SUPPLIER_TAG_TAG FOREIGN KEY (APP_SID, TAG_GROUP_ID, TAG_ID) REFERENCES CSR.TAG_GROUP_MEMBER (APP_SID, TAG_GROUP_ID, TAG_ID)
);
ALTER TABLE csr.plugin 
ADD CONSTRAINT fk_plugin_pre_filter 
FOREIGN KEY (app_sid, pre_filter_sid) 
REFERENCES chain.saved_filter(app_sid, saved_filter_sid);


CREATE OR REPLACE VIEW CSR.V$TAG_GROUP AS
	SELECT tg.app_sid, tg.tag_group_id, NVL(tgd.name, tgden.name) name,
		tg.multi_select, tg.mandatory, tg.applies_to_inds,
		tg.applies_to_regions, tg.applies_to_non_compliances, tg.applies_to_suppliers,
		tg.applies_to_initiatives, tg.applies_to_chain, tg.applies_to_chain_activities,
		tg.applies_to_chain_product_types, tg.applies_to_quick_survey, tg.applies_to_audits,
		tg.applies_to_compliances, tg.lookup_key
	  FROM csr.tag_group tg
	LEFT JOIN csr.tag_group_description tgd ON tgd.app_sid = tg.app_sid AND tgd.tag_group_id = tg.tag_group_id AND tgd.lang = SYS_CONTEXT('SECURITY', 'LANGUAGE')
	LEFT JOIN csr.tag_group_description tgden ON tgden.app_sid = tg.app_sid AND tgden.tag_group_id = tg.tag_group_id AND tgden.lang = 'en';
CREATE OR REPLACE VIEW CSR.V$TAG AS
	SELECT t.app_sid, t.tag_id, NVL(td.tag, tden.tag) tag, NVL(td.explanation, tden.explanation) explanation,
		t.lookup_key, t.exclude_from_dataview_grouping
	  FROM csr.tag t
	LEFT JOIN csr.tag_description td ON td.app_sid = t.app_sid AND td.tag_id = t.tag_id AND td.lang = SYS_CONTEXT('SECURITY', 'LANGUAGE')
	LEFT JOIN csr.tag_description tden ON tden.app_sid = t.app_sid AND tden.tag_id = t.tag_id AND tden.lang = 'en';
CREATE OR REPLACE VIEW csr.tag_group_ir_member AS
  -- get region tags
  SELECT tgm.tag_group_id, tgm.pos, t.tag_id, t.tag, region_sid, null ind_sid, null non_compliance_id
    FROM tag_group_member tgm, v$tag t, region_tag rt
   WHERE tgm.tag_id = t.tag_id
     AND rt.tag_id = t.tag_id
  UNION ALL
  -- get indicator tags
  SELECT tgm.tag_group_id, tgm.pos, t.tag_id,t.tag, null region_sid, it.ind_sid ind_sid, null non_compliance_id
    FROM tag_group_member tgm, v$tag t, ind_tag it
   WHERE tgm.tag_id = t.tag_id
     AND it.tag_id = t.tag_id
  UNION ALL
 -- get non compliance tags
  SELECT tgm.tag_group_id, tgm.pos, t.tag_id, t.tag, null region_sid, null ind_sid, nct.non_compliance_id
    FROM tag_group_member tgm, v$tag t, non_compliance_tag nct
   WHERE tgm.tag_id = t.tag_id
     AND nct.tag_id = t.tag_id;
GRANT SELECT ON csr.v$tag TO chain WITH GRANT OPTION;
GRANT SELECT ON csr.v$tag_group TO chain WITH GRANT OPTION;
GRANT SELECT, REFERENCES ON csr.v$tag_group TO donations;
GRANT SELECT, REFERENCES ON csr.v$tag TO donations;
GRANT SELECT, REFERENCES ON csr.v$tag_group TO surveys;
GRANT SELECT, REFERENCES ON csr.v$tag TO surveys;
CREATE OR REPLACE VIEW CHAIN.v$company_tag AS
	SELECT c.app_sid, c.company_sid, c.name company_name, ct.source, tg.name tag_group_name, t.tag, tg.tag_group_id, t.tag_id, t.lookup_key tag_lookup_key, c.active
	  FROM company c
	  JOIN (
		SELECT s.app_sid, s.company_sid, rt.tag_id, 'Supplier region tag' source
		  FROM csr.supplier s
		  JOIN csr.region_tag rt ON s.region_sid = rt.region_sid AND s.app_sid = rt.app_sid
		 UNION
		SELECT cpt.app_sid, cpt.company_sid, ptt.tag_id, 'Product type tag' source
		  FROM company_product_type cpt
		  JOIN product_type_tag ptt ON cpt.product_type_id = ptt.product_type_id AND cpt.app_sid = ptt.app_sid
	  ) ct ON c.company_sid = ct.company_sid AND c.app_sid = ct.app_sid
	  JOIN csr.v$tag t ON ct.tag_id = t.tag_id AND ct.app_sid = t.app_sid
	  JOIN csr.tag_group_member tgm ON t.tag_id = tgm.tag_id AND t.app_sid = tgm.app_sid
	  JOIN csr.v$tag_group tg ON tgm.tag_group_id = tg.tag_group_id AND tgm.app_sid = tg.app_sid
;
GRANT SELECT, UPDATE, DELETE ON csr.tpl_report_tag TO chain;
GRANT SELECT, UPDATE, DELETE ON csr.tpl_report_tag_logging_form TO chain;
GRANT SELECT, UPDATE, DELETE ON csr.approval_dashboard_tpl_tag TO chain;
GRANT SELECT, UPDATE, DELETE ON csr.tpl_report_tag_dataview TO chain;

CREATE OR REPLACE VIEW CSR.V$TAG_GROUP AS
	SELECT tg.app_sid, tg.tag_group_id, NVL(tgd.name, tgden.name) name,
		tg.multi_select, tg.mandatory, tg.applies_to_inds,
		tg.applies_to_regions, tg.applies_to_non_compliances, tg.applies_to_suppliers,
		tg.applies_to_initiatives, tg.applies_to_chain, tg.applies_to_chain_activities,
		tg.applies_to_chain_product_types, tg.applies_to_chain_products, tg.applies_to_chain_product_supps,
		tg.applies_to_quick_survey, tg.applies_to_audits,
		tg.applies_to_compliances, tg.lookup_key
	  FROM csr.tag_group tg
	LEFT JOIN csr.tag_group_description tgd ON tgd.app_sid = tg.app_sid AND tgd.tag_group_id = tg.tag_group_id AND tgd.lang = SYS_CONTEXT('SECURITY', 'LANGUAGE')
	LEFT JOIN csr.tag_group_description tgden ON tgden.app_sid = tg.app_sid AND tgden.tag_group_id = tg.tag_group_id AND tgden.lang = 'en';
CREATE OR REPLACE VIEW surveys.v$question AS
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, q.question_type,
			qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
			qv.max_selections, qv.display_type, qv.value_validation_type, qv.remember_answer, qv.count_towards_progress,
			qv.allow_file_uploads, qv.allow_user_comments, qv.action, q.matrix_parent_id, q.matrix_row_id, qv.matrix_child_pos
	  FROM question_version qv
	  JOIN question q ON q.question_id = qv.question_id AND q.app_sid = qv.app_sid;
CREATE OR REPLACE VIEW surveys.v$survey_question AS
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, qv.question_type,
		qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
		qv.max_selections, qv.display_type, qv.value_validation_type, qv.remember_answer, qv.count_towards_progress,
		qv.allow_file_uploads, qv.allow_user_comments, qv.matrix_parent_id, qv.matrix_row_id, qv.matrix_child_pos,
		qv.action, sq.survey_sid, sq.survey_version, sq.section_id, sq.pos, sq.deleted
	  FROM survey_section_question sq
	  JOIN v$question qv ON sq.question_id = qv.question_id AND sq.question_version = qv.question_version AND sq.question_draft = qv.question_draft
	 UNION
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, qv.question_type,
		qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
		qv.max_selections, qv.display_type, qv.value_validation_type, qv.remember_answer, qv.count_towards_progress,
		qv.allow_file_uploads, qv.allow_user_comments, qv.matrix_parent_id, qv.matrix_row_id, qv.matrix_child_pos,
		qv.action, sq.survey_sid, sq.survey_version, sq.section_id, sq.pos, sq.deleted
	  FROM survey_section_question sq
	  JOIN v$question qv ON sq.question_id = qv.matrix_parent_id
	   AND sq.question_version = qv.question_version
	   AND sq.question_draft = qv.question_draft;




INSERT INTO csr.audit_type (audit_type_id, label, audit_type_group_id)
VALUES (112, 'Category description changed', 1);
INSERT INTO csr.tag_description (app_sid, tag_id, lang, tag, explanation)
	SELECT t.app_sid, t.tag_id, ts.lang, NVL(trt.translated, t.tag) tag, NVL(tre.translated, t.explanation) explanation
	  FROM csr.tag t
	  JOIN aspen2.translation_set ts ON ts.application_sid = t.app_sid
	  LEFT JOIN (
		SELECT t.application_sid, t.original, trt.lang, trt.translated
		  FROM aspen2.translated trt, aspen2.translation t
		WHERE t.application_sid = trt.application_sid AND t.original_hash = trt.original_hash
	  ) trt ON trt.application_sid = ts.application_sid AND trt.lang = ts.lang AND t.tag = trt.original
	  LEFT JOIN (
		SELECT t.application_sid, t.original, tre.lang, tre.translated
		  FROM aspen2.translated tre, aspen2.translation t
		WHERE t.application_sid = tre.application_sid AND t.original_hash = tre.original_hash
	  ) tre ON tre.application_sid = ts.application_sid AND tre.lang = ts.lang AND t.explanation = tre.original
	  ORDER BY app_sid, tag_id, lang;
INSERT INTO csr.tag_group_description (app_sid, tag_group_id, lang, name)
	SELECT tg.app_sid, tg.tag_group_id, ts.lang, NVL(tr.translated, tg.name) name
	  FROM csr.tag_group tg
	  JOIN aspen2.translation_set ts ON ts.application_sid = tg.app_sid
	  LEFT JOIN (
		SELECT t.application_sid, t.original, tr.lang, tr.translated
		  FROM aspen2.translated tr, aspen2.translation t
		WHERE t.application_sid = tr.application_sid AND t.original_hash = tr.original_hash
	  ) tr ON tr.application_sid = ts.application_sid AND tr.lang = ts.lang AND tg.name = tr.original
	  ORDER BY app_sid, tag_group_id, lang;
/*
Note: Renaming these columns for now, we'll drop them later once the dust settles.
*/
ALTER TABLE CSR.TAG RENAME COLUMN TAG TO TAG_OLD;
ALTER TABLE CSR.TAG RENAME COLUMN EXPLANATION TO EXPLANATION_OLD;
ALTER TABLE CSR.TAG_GROUP RENAME COLUMN NAME TO NAME_OLD;
ALTER TABLE CSR.TAG MODIFY (TAG_OLD NULL);
ALTER TABLE CSR.TAG_GROUP MODIFY (NAME_OLD NULL);
ALTER TABLE CSRIMP.TAG DROP COLUMN TAG;
ALTER TABLE CSRIMP.TAG DROP COLUMN EXPLANATION;
ALTER TABLE CSRIMP.TAG_GROUP DROP COLUMN NAME;
INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
VALUES (69, 'Category translation import', 'batch-importer', 'support@credit360.com', 3, 1, 120);
INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
VALUES (70, 'Tag translation import', 'batch-importer', 'support@credit360.com', 3, 1, 120);
INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
VALUES (71, 'Category translation export', 'batch-exporter', 'support@credit360.com', 3, 1, 120);
INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
VALUES (72, 'Tag translation export', 'batch-exporter', 'support@credit360.com', 3, 1, 120);
INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
VALUES (73, 'Tag explanation translation import', 'batch-importer', 'support@credit360.com', 3, 1, 120);
INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
VALUES (74, 'Tag explanation translation export', 'batch-exporter', 'support@credit360.com', 3, 1, 120);
INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (69, 'Category translation import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.CategoryTranslationImporter');
INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (70, 'Tag translation import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.TagTranslationImporter');
INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (73, 'Tag explanation translation import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.TagExplanationTranslationImporter');
INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (71, 'Category translation export', 'Credit360.ExportImport.Export.Batched.Exporters.CategoryTranslationExporter');
INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (72, 'Tag translation export', 'Credit360.ExportImport.Export.Batched.Exporters.TagTranslationExporter');
INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (74, 'Tag explanation translation export', 'Credit360.ExportImport.Export.Batched.Exporters.TagExplanationTranslationExporter');
BEGIN
	security.user_pkg.logonadmin;
	UPDATE csr.plugin
	   SET cs_class = 'Credit360.Chain.Plugins.ProductSupplierDetailsDto'
	 WHERE js_class = 'Chain.ManageProduct.ProductSupplierDetailsTab';
	COMMIT;
END;
/
BEGIN
	BEGIN
		INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
		VALUES (csr.plugin_id_seq.NEXTVAL, 10, 'Product list (Purchaser)', '/csr/site/chain/manageCompany/controls/ProductListPurchaserTab.js', 'Chain.ManageCompany.ProductListPurchaserTab', 'Credit360.Chain.Plugins.ProductListDto', 'This tab shows the product list for a purchaser.');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/
UPDATE csr.plugin 
   SET js_include = '/csr/site/chain/managecompany/controls/BusinessRelationshipListTab.js' 
 WHERE js_include = '/csr/site/chain/managecompany/controls/BusinessRelationshipList.js';
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (36,'Change Integration Api Company User Default Groups','Add or remove default groups for users created via the Integration Api Company Users','ChangeIntApiCompanyUserGroup',null);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (36, 'Group Sid Id', 'The Group Sid of the group to add/remove', 1, NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (36, 'Remove', 'Add = 0, Remove = 1', 2, 0);
BEGIN
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (75, 'Region mappings import', null, 'batch-importer', 0, null, 120);
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (75, 'Region mapping import', 'Credit360.ExportImport.Import.Batched.Importers.Mappings.RegionMappingImporter');
	
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (76, 'Indicator mappings import', null, 'batch-importer', 0, null, 120);
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (76, 'Indicator mapping import', 'Credit360.ExportImport.Import.Batched.Importers.Mappings.IndicatorMappingImporter');
	
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (77, 'Measure mappings import', null, 'batch-importer', 0, null, 120);
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (77, 'Measure mapping import', 'Credit360.ExportImport.Import.Batched.Importers.Mappings.MeasureMappingImporter');
	
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (78, 'Region mappings export', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (78, 'Region mapping export', 'Credit360.ExportImport.Export.Batched.Exporters.Mappings.RegionMappingExporter');
	
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (79, 'Indicator mappings export', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (79, 'Indicator mapping export', 'Credit360.ExportImport.Export.Batched.Exporters.Mappings.IndicatorMappingExporter');
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (80, 'Measure mappings export', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (80, 'Measure mapping export', 'Credit360.ExportImport.Export.Batched.Exporters.Mappings.MeasureMappingExporter');
END;
/
DECLARE
	v_act 				security.security_pkg.T_ACT_ID;
	v_class_id 			security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	BEGIN
		v_class_id := security.class_pkg.GetClassID('Surveys');
	EXCEPTION WHEN dup_val_on_index THEN
		NULL;
	END;
	BEGIN
		security.class_pkg.AddPermission(
			in_act_id				=> v_act,
			in_class_id				=> v_class_id,
			in_permission			=> 131072, -- question_library_pkg.PERMISSION_PUBLISH_SURVEY
			in_permission_name		=> 'Publish survey'
		);
	EXCEPTION WHEN dup_val_on_index THEN
		NULL;
	END;
	BEGIN
		v_class_id := security.class_pkg.GetClassID('Webresource');
	
		security.class_pkg.AddPermission(
			in_act_id				=> v_act,
			in_class_id				=> v_class_id,
			in_permission			=> 131072, -- question_library_pkg.PERMISSION_PUBLISH_SURVEY
			in_permission_name		=> 'Publish survey'
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	security.user_pkg.LogOff(v_act);
END;
/






@..\chain\chain_link_pkg
@..\csr_data_pkg
@..\schema_pkg
@..\tag_pkg
@..\role_pkg
@..\question_library_pkg
@..\chain\company_product_pkg
@..\chain\product_report_pkg
@..\chain\product_supplier_report_pkg
@..\plugin_pkg
@..\chain\filter_pkg
@..\audit_report_pkg
@..\compliance_library_report_pkg
@..\compliance_register_report_pkg
@..\initiative_report_pkg
@..\issue_report_pkg
@..\meter_list_pkg
@..\meter_report_pkg
@..\non_compliance_report_pkg
@..\permit_report_pkg
@..\property_report_pkg
@..\question_library_report_pkg
@..\quick_survey_report_pkg
@..\region_report_pkg
@..\user_report_pkg
@..\chain\activity_report_pkg
@..\chain\business_rel_report_pkg
@..\chain\certification_report_pkg
@..\chain\company_filter_pkg
@..\chain\company_request_report_pkg
@..\chain\dedupe_proc_record_report_pkg
@..\chain\product_metric_report_pkg
@..\chain\prdct_supp_mtrc_report_pkg
--@..\surveys\question_library_report_pkg
@..\..\..\aspen2\cms\db\filter_pkg.sql
@..\automated_import_pkg
@..\user_profile_pkg
@..\csrimp\imp_pkg
@..\util_script_pkg
--@..\surveys\condition_pkg
--@..\surveys\question_library_pkg
--@..\surveys\survey_pkg
@..\doc_folder_pkg
@..\integration_api_pkg


@..\chain\chain_link_body
@..\chain\company_body
@..\schema_body
@..\tag_body
@..\meter_body
@..\region_body
@..\compliance_library_report_body
@..\compliance_register_report_body
@..\region_report_body
@..\question_library_body
@..\question_library_report_body
@..\indicator_body
@..\region_tree_body
@..\role_body
@..\csr_user_body
@..\calc_body
@..\benchmarking_dashboard_body
@..\dataset_legacy_body
@..\issue_body
@..\snapshot_body
@..\model_body
@..\audit_body
@..\audit_report_body
@..\non_compliance_report_body
@..\supplier_body
@..\stored_calc_datasource_body
@..\meter_list_body
@..\property_body
@..\property_report_body
@..\initiative_metric_body
@..\initiative_body
@..\initiative_project_body
@..\initiative_export_body
@..\initiative_grid_body
@..\initiative_report_body
@..\enable_body
@..\templated_report_schedule_body
@..\chain\activity_body
@..\chain\activity_report_body
@..\chain\company_tag_body
@..\chain\company_filter_body
@..\chain\component_body
@..\chain\filter_body
@..\chain\product_body
@..\chain\bsci_body
@..\chain\dedupe_admin_body
@..\chain\company_dedupe_body
@..\chain\dedupe_proc_record_report_body
@..\chain\helper_body
@..\csrimp\imp_body
--@..\surveys\question_library_body
--@..\surveys\question_library_report_body
@..\donations\donation_body
@..\donations\tag_body
@..\integration_api_body
@..\chain\company_product_body
@..\chain\product_report_body
@..\chain\product_supplier_report_body
@..\automated_import_body
@..\automated_export_body
@..\plugin_body
@..\permit_body
@..\chain\plugin_body
@..\issue_report_body
@..\meter_report_body
@..\permit_report_body
@..\quick_survey_report_body
@..\user_report_body
@..\chain\business_rel_report_body
@..\chain\certification_report_body
@..\chain\company_request_report_body
@..\chain\product_metric_report_body
@..\chain\prdct_supp_mtrc_report_body
@..\..\..\aspen2\cms\db\filter_body.sql
@..\flow_body
@..\chain\product_metric_body
@..\csr_app_body
@..\user_profile_body
@..\util_script_body
--@..\surveys\condition_body
--@..\surveys\survey_body
@..\doc_folder_body



@update_tail
