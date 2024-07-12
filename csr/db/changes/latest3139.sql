define version=3139
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
CREATE SEQUENCE surveys.audit_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;
CREATE SEQUENCE surveys.audit_log_detail_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;
CREATE TABLE SURVEYS.AUDIT_LOG_TYPE(
	AUDIT_LOG_TYPE_ID	NUMBER(10, 0) NOT NULL,
	NAME				VARCHAR2(20),
	CONSTRAINT PK_AUDIT_LOG_TYPE PRIMARY KEY (AUDIT_LOG_TYPE_ID)
);
DELETE FROM SURVEYS.AUDIT_LOG_DETAIL;
DELETE FROM SURVEYS.AUDIT_LOG;
ALTER TABLE SURVEYS.AUDIT_LOG ADD
(
	AUDIT_LOG_TYPE_ID	NUMBER(10) NOT NULL
);
CREATE TABLE SURVEYS.ANSWER_FILE(
	APP_SID				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	ANSWER_FILE_ID		NUMBER(10, 0)	NOT NULL,
	RESPONSE_ID			NUMBER(10, 0)	NOT NULL,
	QUESTION_ID			NUMBER(10, 0)	NOT NULL,
	QUESTION_VERSION	NUMBER(10, 0)	NOT NULL,
	FILENAME			VARCHAR2(255)	NOT NULL,
	MIME_TYPE			VARCHAR2(256)	NOT NULL,
	SHA1				RAW(20)			NOT NULL,
	CAPTION				VARCHAR2(1023),
	SURVEY_SID			NUMBER(10, 0)	NOT NULL,
	SURVEY_VERSION		NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_SURVEY_ANSWER_FILE PRIMARY KEY (APP_SID, ANSWER_FILE_ID),
	CONSTRAINT UK_SURVEY_ANSWER_FILE UNIQUE (APP_SID, ANSWER_FILE_ID, RESPONSE_ID),
	CONSTRAINT UK_SURVEYS_ANSWER_FILE_A UNIQUE (APP_SID, RESPONSE_ID, QUESTION_ID, SHA1, FILENAME, MIME_TYPE)
)
;
CREATE SEQUENCE SURVEYS.SURVEY_ANSWER_FILE_ID_SEQ;
CREATE INDEX SURVEYS.IX_ANS_FILE_RESP_ID ON SURVEYS.ANSWER_FILE(APP_SID, RESPONSE_ID)
;
CREATE TABLE SURVEYS.RESPONSE_FILE(
	APP_SID			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	RESPONSE_ID		NUMBER(10, 0)	NOT NULL,
	FILENAME		VARCHAR2(255)	NOT NULL,
	MIME_TYPE		VARCHAR2(256)	NOT NULL,
	DATA			BLOB			NOT NULL,
	SHA1			RAW(20)			NOT NULL,
	UPLOADED_DTM	DATE			DEFAULT SYSDATE NOT NULL,
	CONSTRAINT PK_RESPONSE_FILE PRIMARY KEY (APP_SID, RESPONSE_ID, SHA1, FILENAME, MIME_TYPE)
)
;
CREATE INDEX SURVEYS.IX_RESP_FILE_BY_SHA1 ON SURVEYS.RESPONSE_FILE(APP_SID, SHA1, FILENAME, MIME_TYPE)
;
CREATE TABLE CSR.AUTO_EXP_EXPORTER_PLUGIN_TYPE(
	PLUGIN_TYPE_ID	NUMBER NOT NULL,
	LABEL			VARCHAR2(255),
	CONSTRAINT PK_AEEPT_PLUGIN_TYPE_ID PRIMARY KEY (PLUGIN_TYPE_ID),
	CONSTRAINT UK_AEEPT_PLUGIN_LABEL UNIQUE (LABEL)
);
INSERT INTO csr.auto_exp_exporter_plugin_type(plugin_type_id, label) VALUES (1, 'DataView Exporter');
INSERT INTO csr.auto_exp_exporter_plugin_type(plugin_type_id, label) VALUES (2, 'DataView Exporter (Xml Mappable)');
INSERT INTO csr.auto_exp_exporter_plugin_type(plugin_type_id, label) VALUES (3, 'Batched Exporter');
INSERT INTO csr.auto_exp_exporter_plugin_type(plugin_type_id, label) VALUES (4, 'Stored Procedure Exporter');
CREATE TABLE CSR.AUTO_EXP_FILE_WRTR_PLUGIN_TYPE(
	PLUGIN_TYPE_ID	NUMBER NOT NULL,
	LABEL			VARCHAR2(255),
	CONSTRAINT PK_AEFWPT_PLUGIN_TYPE_ID PRIMARY KEY (PLUGIN_TYPE_ID),
	CONSTRAINT UK_AEFWPT_PLUGIN_LABEL UNIQUE (LABEL)
);
INSERT INTO csr.auto_exp_file_wrtr_plugin_type(plugin_type_id, label) VALUES (1, 'FTP');
INSERT INTO csr.auto_exp_file_wrtr_plugin_type(plugin_type_id, label) VALUES (2, 'DB');
INSERT INTO csr.auto_exp_file_wrtr_plugin_type(plugin_type_id, label) VALUES (3, 'Manual Download');


ALTER TABLE csr.std_factor_set ADD visible_in_classic_tool NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.FACTOR ADD IS_VIRTUAL NUMBER (1,0) DEFAULT 0;
ALTER TABLE CSR.FACTOR ADD CONSTRAINT CK_FACTOR_IS_VIRTUAL CHECK (IS_VIRTUAL IN (1, 0));
ALTER TABLE CSRIMP.FACTOR ADD IS_VIRTUAL NUMBER (1,0);
ALTER TABLE CSRIMP.FACTOR ADD CONSTRAINT CK_FACTOR_IS_VIRTUAL CHECK (IS_VIRTUAL IN (1, 0));
ALTER TABLE surveys.question_option_data_sources DROP CONSTRAINT chk_data_source_selected_0_1;
ALTER TABLE surveys.question_option_data_sources DROP COLUMN selected;
ALTER TABLE surveys.question_version ADD (
	option_data_source_id				NUMBER(10, 0),
	CONSTRAINT fk_question_ver_data_source FOREIGN KEY (app_sid, option_data_source_id) REFERENCES surveys.question_option_data_sources(app_sid, data_source_id)
);
ALTER TABLE SURVEYS.ANSWER_FILE ADD CONSTRAINT FK_ANS_FILE_QSTN_ID
	FOREIGN KEY (APP_SID, QUESTION_ID, SURVEY_SID, SURVEY_VERSION)
	REFERENCES SURVEYS.SURVEY_SECTION_QUESTION(APP_SID, QUESTION_ID, SURVEY_SID, SURVEY_VERSION)
;
ALTER TABLE SURVEYS.ANSWER_FILE ADD CONSTRAINT FK_ANS_FILE_RESP_ID
	FOREIGN KEY (APP_SID, RESPONSE_ID)
	REFERENCES SURVEYS.RESPONSE(APP_SID, RESPONSE_ID)
;
ALTER TABLE SURVEYS.ANSWER_FILE ADD CONSTRAINT FK_ANSWER_FILE_FILE
	FOREIGN KEY (APP_SID, RESPONSE_ID, SHA1, FILENAME, MIME_TYPE)
	REFERENCES SURVEYS.RESPONSE_FILE(APP_SID, RESPONSE_ID, SHA1, FILENAME, MIME_TYPE)
;
ALTER TABLE SURVEYS.RESPONSE_FILE ADD CONSTRAINT FK_RESPONSE_FILE_RESPONSE
	FOREIGN KEY (APP_SID, RESPONSE_ID)
	REFERENCES SURVEYS.RESPONSE(APP_SID, RESPONSE_ID)
;
DECLARE
	v_count NUMBER(1);
BEGIN
	SELECT COUNT(constraint_name)
	  INTO v_count
	  FROM all_constraints
	 WHERE owner='SURVEYS' and (constraint_name = 'RefCUSTOMER_ANSWER_FILE')
	   AND table_name ='ANSWER_FILE';
	IF v_count = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE surveys.answer_file DROP CONSTRAINT RefCUSTOMER_ANSWER_FILE';
	END IF;
END;
/
ALTER TABLE SURVEYS.RESPONSE ADD CAMPAIGN_SENT NUMBER(1);
DECLARE
index_not_exists EXCEPTION;
PRAGMA EXCEPTION_INIT(index_not_exists, -1418);
BEGIN
	EXECUTE IMMEDIATE 'DROP INDEX CSR.UK_FACTOR_2';
EXCEPTION
	WHEN index_not_exists THEN NULL;
END;
/
CREATE UNIQUE INDEX CSR.UK_FACTOR_2 ON CSR.FACTOR (APP_SID, NVL(STD_FACTOR_ID, -FACTOR_ID), REGION_SID);
ALTER TABLE CSR.AUTO_EXP_EXPORTER_PLUGIN ADD
	DSV_OUTPUTTER			NUMBER(1)		DEFAULT 0 NOT NULL;
ALTER TABLE CSR.AUTO_EXP_EXPORTER_PLUGIN ADD
	PLUGIN_TYPE_ID	NUMBER;
ALTER TABLE CSR.AUTO_EXP_EXPORTER_PLUGIN ADD
	CONSTRAINT CK_AUTO_EXP_EXPORTER_DSV_OUTP CHECK (DSV_OUTPUTTER IN (0, 1));
	
ALTER TABLE CSR.AUTO_EXP_EXPORTER_PLUGIN ADD
	CONSTRAINT FK_AEE_PLUGIN_TYPE_ID
		FOREIGN KEY (PLUGIN_TYPE_ID)
		REFERENCES CSR.AUTO_EXP_EXPORTER_PLUGIN_TYPE (PLUGIN_TYPE_ID);
ALTER TABLE CSR.AUTO_EXP_FILE_WRITER_PLUGIN ADD
	PLUGIN_TYPE_ID	NUMBER		DEFAULT 1	NOT NULL;
ALTER TABLE CSR.AUTO_EXP_FILE_WRITER_PLUGIN ADD
	CONSTRAINT FK_AEFWP_PLUGIN_TYPE_ID
		FOREIGN KEY (PLUGIN_TYPE_ID)
		REFERENCES CSR.AUTO_EXP_FILE_WRTR_PLUGIN_TYPE (PLUGIN_TYPE_ID);
ALTER TABLE CSR.AUTO_EXP_FILE_WRITER_PLUGIN MODIFY PLUGIN_TYPE_ID DEFAULT NULL;
create index csr.ix_auto_exp_expo_plugin_type_i on csr.auto_exp_exporter_plugin (plugin_type_id);
create index csr.ix_auto_exp_file_plugin_type_i on csr.auto_exp_file_writer_plugin (plugin_type_id);
create index surveys.ix_audit_detail_audit on surveys.audit_log_detail (app_sid, audit_log_id);
ALTER TABLE SURVEYS.AUDIT_LOG_DETAIL DROP CONSTRAINT FK_AUDIT_DETAIL_AUDIT;
ALTER TABLE SURVEYS.AUDIT_LOG_DETAIL ADD CONSTRAINT FK_AUDIT_DETAIL_AUDIT
	FOREIGN KEY (APP_SID, AUDIT_LOG_ID)
	REFERENCES SURVEYS.AUDIT_LOG(APP_SID, AUDIT_LOG_ID);


grant execute on cms.pivot_pkg to security, web_user;
GRANT SELECT, REFERENCES ON aspen2.translation_set TO surveys;


ALTER TABLE SURVEYS.ANSWER_FILE ADD CONSTRAINT FK_ANSWER_FILE_CUSTOMER
	FOREIGN KEY (APP_SID)
	REFERENCES CSR.CUSTOMER(APP_SID)
;


CREATE OR REPLACE VIEW surveys.v$question AS
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, q.question_type,
			qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
			qv.max_selections, qv.display_type, qv.value_validation_type, qv.remember_answer, qv.count_towards_progress,
			qv.allow_file_uploads, qv.allow_user_comments, qv.action, q.matrix_parent_id, q.matrix_row_id, qv.matrix_child_pos, q.measure_sid,
			q.deleted_dtm question_deleted_dtm, q.default_lang, qv.option_data_source_id
	  FROM question_version qv
	  JOIN question q ON q.question_id = qv.question_id AND q.app_sid = qv.app_sid;
CREATE OR REPLACE VIEW surveys.v$survey_question AS
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, qv.question_type,
		qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
		qv.max_selections, qv.display_type, qv.value_validation_type, qv.remember_answer, qv.count_towards_progress,
		qv.allow_file_uploads, qv.allow_user_comments, qv.matrix_parent_id, qv.matrix_row_id, qv.matrix_child_pos,
		qv.action, sq.survey_sid, sq.survey_version, sq.section_id, sq.pos, NVL2(qv.question_deleted_dtm, 1, sq.deleted) deleted, qv.measure_sid,
		qv.default_lang, qv.option_data_source_id AS data_source_id
	  FROM survey_section_question sq
	  JOIN v$question qv ON sq.question_id = qv.question_id AND sq.question_version = qv.question_version
	 UNION
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, qv.question_type,
		qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
		qv.max_selections, qv.display_type, qv.value_validation_type, qv.remember_answer, qv.count_towards_progress,
		qv.allow_file_uploads, qv.allow_user_comments, qv.matrix_parent_id, qv.matrix_row_id, qv.matrix_child_pos,
		qv.action, sq.survey_sid, sq.survey_version, sq.section_id, sq.pos, NVL2(qv.question_deleted_dtm, 1, sq.deleted) deleted, qv.measure_sid,
		qv.default_lang, qv.option_data_source_id AS data_source_id
	  FROM survey_section_question sq
	  JOIN v$question qv ON sq.question_id = qv.matrix_parent_id
	   AND sq.question_version = qv.question_version
  ORDER BY matrix_parent_id, matrix_row_id, matrix_child_pos;
CREATE OR REPLACE VIEW surveys.v$survey_question AS
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, qv.question_type,
		qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
		qv.max_selections, qv.display_type, qv.value_validation_type, qv.remember_answer, qv.count_towards_progress,
		qv.allow_file_uploads, qv.allow_user_comments, qv.matrix_parent_id, qv.matrix_row_id, qv.matrix_child_pos,
		qv.action, sq.survey_sid, sq.survey_version, sq.section_id, sq.pos, NVL2(qv.question_deleted_dtm, 1, sq.deleted) deleted, qv.measure_sid,
		qv.default_lang, qv.option_data_source_id AS data_source_id
	  FROM survey_section_question sq
	  JOIN v$question qv ON sq.question_id = qv.question_id AND sq.question_version = qv.question_version AND sq.question_draft = qv.question_draft
	 UNION
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, qv.question_type,
		qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
		qv.max_selections, qv.display_type, qv.value_validation_type, qv.remember_answer, qv.count_towards_progress,
		qv.allow_file_uploads, qv.allow_user_comments, qv.matrix_parent_id, qv.matrix_row_id, qv.matrix_child_pos,
		qv.action, sq.survey_sid, sq.survey_version, sq.section_id, sq.pos, NVL2(qv.question_deleted_dtm, 1, sq.deleted) deleted, qv.measure_sid,
		qv.default_lang, qv.option_data_source_id AS data_source_id
	  FROM survey_section_question sq
	  JOIN v$question qv ON sq.question_id = qv.matrix_parent_id AND sq.question_version = qv.question_version AND sq.question_draft = qv.question_draft
  ORDER BY matrix_parent_id, matrix_row_id, matrix_child_pos;




DECLARE
	v_root_product_type_id			NUMBER(10, 0);
BEGIN
	FOR r IN (
		SELECT c.host, c.app_sid
		  FROM csr.customer c
		  JOIN chain.product_metric pm ON pm.app_sid = c.app_sid
		 GROUP BY c.host, c.app_sid
	) LOOP
		security.user_pkg.logonadmin(r.host);
		BEGIN
			SELECT product_type_id
			  INTO v_root_product_type_id
			  FROM chain.product_type
			 WHERE parent_product_type_id IS NULL
			   AND app_sid = r.app_sid;
		EXCEPTION
			WHEN no_data_found THEN
				CONTINUE;
			WHEN too_many_rows THEN
				CONTINUE;
		END;
		INSERT INTO chain.product_metric_product_type (app_sid, ind_sid, product_type_id)
		SELECT r.app_sid, pm.ind_sid, v_root_product_type_id
		  FROM chain.product_metric pm
		  LEFT JOIN chain.product_metric_product_type pmpt ON pmpt.app_sid = pm.app_sid AND pmpt.ind_sid = pm.ind_sid
		 WHERE pmpt.product_type_id IS NULL;
	END LOOP;
END;
/
UPDATE csr.auto_exp_exporter_plugin
   SET outputter_assembly = 'Credit360.ExportImport.Automated.Export.Exporters.ELC.IncidentZipXmlOutputter'
 WHERE plugin_id = 20;
BEGIN
	BEGIN
		insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
		values (csr.plugin_id_seq.NEXTVAL, 19, 'Chain Product Certifications Tab', '/csr/site/chain/manageProduct/controls/ProductCertificationsTab.js', 'Chain.ManageProduct.ProductCertificationsTab', 'Credit360.Chain.Plugins.ProductCertificationsDto', 'This tab shows the certifications attached to a product.');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	BEGIN
		insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
		values (csr.plugin_id_seq.NEXTVAL, 20, 'Chain Product Supplier Certifications Tab', '/csr/site/chain/manageProduct/controls/ProductSupplierCertificationsTab.js', 'Chain.ManageProduct.ProductSupplierCertificationsTab', 'Credit360.Chain.Plugins.ProductSupplierCertificationsDto', 'This tab shows the certifications attached to a product supplier.');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/
UPDATE csr.std_factor_set
   SET visible_in_classic_tool = 1
 WHERE published_dtm IS NULL OR
  published_dtm < DATE '2017-10-31';
 
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Region Emission Factor Cascading', 0, 'Emission Factors: Cascade region level factors to child regions.');
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (100, 'Region Emission Factor cascading', 'EnableRegionEmFactorCascading', 'Enables Region Emission Factor cascading.');
INSERT INTO SURVEYS.AUDIT_LOG_TYPE (AUDIT_LOG_TYPE_ID, NAME) VALUES (1, 'Created');
INSERT INTO SURVEYS.AUDIT_LOG_TYPE (AUDIT_LOG_TYPE_ID, NAME) VALUES (2, 'Updated');
INSERT INTO SURVEYS.AUDIT_LOG_TYPE (AUDIT_LOG_TYPE_ID, NAME) VALUES (3, 'Deleted');
INSERT INTO SURVEYS.AUDIT_LOG_TYPE (AUDIT_LOG_TYPE_ID, NAME) VALUES (4, 'Approved');
INSERT INTO SURVEYS.AUDIT_LOG_TYPE (AUDIT_LOG_TYPE_ID, NAME) VALUES (5, 'Published');
BEGIN
	FOR r IN (
		SELECT s.survey_sid, s.latest_published_version
		  FROM surveys.survey s
		  JOIN surveys.survey_version sv ON s.survey_sid = sv.survey_sid AND s.latest_published_version = sv.survey_version
	) LOOP
		UPDATE surveys.survey_section_question
		   SET question_draft = 0
		 WHERE survey_version = r.latest_published_version
		   AND deleted = 0
		   AND survey_sid = r.survey_sid;
		UPDATE surveys.survey_section_question
		   SET question_draft = 1
		 WHERE survey_version <> r.latest_published_version
		   AND deleted = 0
		   AND survey_sid = r.survey_sid;
	END LOOP;
END;
/
UPDATE CSR.AUTO_EXP_EXPORTER_PLUGIN
   SET DSV_OUTPUTTER = 1
 WHERE PLUGIN_ID IN (1, 2, 3, 4, 5, 6, 7, 13, 14, 15, 17, 19, 21, 22);
UPDATE CSR.AUTO_EXP_EXPORTER_PLUGIN
   SET PLUGIN_TYPE_ID = 1
 WHERE PLUGIN_ID IN (1, 2, 3);
UPDATE CSR.AUTO_EXP_EXPORTER_PLUGIN
   SET PLUGIN_TYPE_ID = 2
 WHERE PLUGIN_ID IN (21, 22);
UPDATE CSR.AUTO_EXP_EXPORTER_PLUGIN
   SET PLUGIN_TYPE_ID = 3
 WHERE PLUGIN_ID IN (19);
UPDATE CSR.AUTO_EXP_EXPORTER_PLUGIN
   SET PLUGIN_TYPE_ID = 4
 WHERE PLUGIN_ID IN (13);
UPDATE CSR.AUTO_EXP_FILE_WRITER_PLUGIN
   SET PLUGIN_TYPE_ID = 1
 WHERE PLUGIN_ID IN (1, 7);
UPDATE CSR.AUTO_EXP_FILE_WRITER_PLUGIN
   SET PLUGIN_TYPE_ID = 2
 WHERE PLUGIN_ID = 6;
UPDATE CSR.AUTO_EXP_FILE_WRITER_PLUGIN
   SET PLUGIN_TYPE_ID = 3
 WHERE PLUGIN_ID = 5;
	insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	values (csr.plugin_id_seq.nextval, 10, 'BSCI supplier details', '/csr/site/chain/manageCompany/controls/BsciSupplierDetailsTab.js', 'Chain.ManageCompany.BsciSupplierDetailsTab', 'Credit360.Chain.Plugins.BsciSupplierDetailsDto', 'This tab shows the BSCI details for a supplier.');
	
	insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	values (csr.plugin_id_seq.nextval, 13, 'BSCI supplier details', '/csr/site/audit/controls/BsciSupplierDetailsTab.js', 'Audit.Controls.BsciSupplierDetailsTab', 'Credit360.Audit.Plugins.BsciSupplierDetailsDto', 'This tab shows the current BSCI details for the company being audited.');




grant execute on csr.like_for_like_pkg to web_user;
create or replace package surveys.audit_pkg as end;
/
create or replace package surveys.integration_pkg as end;
/
create or replace package csr.region_api_pkg as end;
/
grant execute on surveys.audit_pkg to web_user;
grant execute on surveys.integration_pkg to web_user;
grant execute on csr.region_api_pkg to web_user;


@..\chain\product_metric_pkg
@..\dataview_pkg
@..\templated_report_pkg
@..\enable_pkg
@..\factor_pkg
--@..\surveys\audit_pkg
--@..\surveys\survey_pkg
--@..\surveys\question_library_pkg
@..\region_api_pkg
--@..\surveys\integration_pkg
@..\automated_export_pkg
@..\chain\bsci_pkg
@..\chain\company_filter_pkg
@..\initiative_report_pkg
@..\automated_import_pkg


@..\chain\product_metric_body
@..\meter_body
@..\dataview_body
@..\templated_report_body
@..\factor_body
@..\enable_body
@..\schema_body
@..\stored_calc_datasource_body
--@..\surveys\audit_body
--@..\surveys\survey_body
--@..\surveys\question_library_body
@..\region_api_body
--@..\surveys\integration_body
--@..\surveys\campaign_body
@..\..\..\aspen2\cms\db\filter_body
@..\compliance_register_report_body
@..\automated_export_body
@..\chain\bsci_body
@..\chain\company_filter_body
@..\initiative_report_body
@..\automated_import_body
@..\property_body



@update_tail
