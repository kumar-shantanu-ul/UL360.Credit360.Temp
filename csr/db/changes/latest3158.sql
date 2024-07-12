define version=3158
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
CREATE TABLE SURVEYS.SHARED_RESPONSE (
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SHARE_KEY				VARCHAR2(255)	NOT NULL,
	RESPONSE_ID				NUMBER(10, 0)	NOT NULL,
	SHARED_BY_SID			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','SID') NOT NULL,
	SHARED_DTM				DATE			DEFAULT SYSDATE NOT NULL,
	EXPIRES_DTM				DATE			DEFAULT (SYSDATE + 7) NOT NULL,
	CONSTRAINT PK_SHARED_RESPONSE PRIMARY KEY (APP_SID, SHARE_KEY)
)
;
create index surveys.ix_shared_response_response on surveys.shared_response (app_sid, response_id);
CREATE TABLE SURVEYS.IMPORT_MAP(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SURVEY_SID					NUMBER(10, 0)	NOT NULL,
	IMPORT_MAP_ID				NUMBER(10, 0)	NOT NULL,
	IMPORT_MAP_NAME				VARCHAR2(255)	NOT NULL,
	HIDDEN						NUMBER(1)		NOT NULL,
	CONSTRAINT PK_SURVEY_IMPORT_MAP PRIMARY KEY (APP_SID, IMPORT_MAP_ID)
)
;
CREATE TABLE SURVEYS.IMPORT_MAP_ITEM(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	IMPORT_MAP_ID				NUMBER(10, 0)	NOT NULL,
	IMPORT_MAP_ITEM_ID			NUMBER(10, 0)	NOT NULL,
	CELL_PATH					VARCHAR2(255)	NOT NULL,
	DATA_POINT					VARCHAR2(255)	NOT NULL,
	IMPORT_TO					NUMBER(10) 		NOT NULL,
	OTHER_OPTION				VARCHAR2(255)	NULL,
	CONSTRAINT PK_SURVEY_IMPORT_MAP_ITEM PRIMARY KEY (APP_SID, IMPORT_MAP_ITEM_ID)
)
;
CREATE TABLE SURVEYS.IMPORT_MAP_ITEM_TARGET(
	IMPORT_MAP_ITEM_TARGET_ID	NUMBER(10, 0) NOT NULL,
	NAME						VARCHAR2(20),
	CONSTRAINT PK_IMP_MAP_ITEM_TARGET PRIMARY KEY (IMPORT_MAP_ITEM_TARGET_ID)
);
 
CREATE SEQUENCE SURVEYS.IMPORT_MAP_ID_SEQ
	START WITH     1
	INCREMENT BY   1
	NOCACHE
	NOCYCLE
;
CREATE SEQUENCE SURVEYS.IMPORT_MAP_ITEM_ID_SEQ
	START WITH     1
	INCREMENT BY   1
	NOCACHE
	NOCYCLE
;
 
 
CREATE TABLE CSR.AUTO_IMPEXP_PUBLIC_KEY(
	APP_SID				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	PUBLIC_KEY_ID		NUMBER(10, 0)	NOT NULL,
	LABEL				VARCHAR2(255)	NOT NULL,
	KEY_BLOB			BLOB			NOT NULL,
	CONSTRAINT PK_AUTO_IMP_PUBLIC_KEY_ID PRIMARY KEY (PUBLIC_KEY_ID),
	CONSTRAINT UK_AUTO_IMP_PUBLIC_KEY_LABEL UNIQUE (APP_SID, LABEL)
);
CREATE SEQUENCE CSR.AUTO_IMPEXP_PUBLIC_KEY_ID_SEQ;
CREATE TABLE CSR.PUBLIC_KEY_LOG (
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	PUBLIC_KEY_ID			NUMBER(10) 		NOT NULL,
	CHANGED_DTM				DATE 			NOT NULL,
	CHANGED_BY_USER_SID		NUMBER(10) 		NOT NULL,
	MESSAGE					VARCHAR2(1024)	NOT NULL,
	FROM_KEY_BLOB			BLOB,
	TO_KEY_BLOB				BLOB
)
;
CREATE INDEX CSR.IDX_PUBLIC_KEY_LOG ON CSR.PUBLIC_KEY_LOG(APP_SID)
;


ALTER TABLE SURVEYS.SHARED_RESPONSE ADD CONSTRAINT FK_SHARED_RESPONSE_RESPONSE
	FOREIGN KEY (APP_SID, RESPONSE_ID)
	REFERENCES SURVEYS.RESPONSE(APP_SID, RESPONSE_ID)
;
ALTER TABLE surveys.survey_section ADD insert_page_break NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE surveys.survey_section ADD CONSTRAINT CHK_INSERT_PAGE_BREAK_0_1 CHECK (insert_page_break IN (0,1));
ALTER TABLE surveys.survey_section ADD CONSTRAINT CHK_TITLE_PAGE_BREAK_0_1 CHECK (hide_title * insert_page_break = 0);
alter table surveys.question_version add (
    NUMBER_EMPTY_ROWS_EXCEL_EXPORT NUMBER 
);
alter table surveys.question_version add NUMBER_ROWS_EXCEL_EXPORT_TEMP NUMBER;
update surveys.question_version set NUMBER_ROWS_EXCEL_EXPORT_TEMP = NUMBER_EMPTY_ROWS_EXCEL_EXPORT;
update surveys.question_version set NUMBER_EMPTY_ROWS_EXCEL_EXPORT = null;
alter table surveys.question_version modify NUMBER_EMPTY_ROWS_EXCEL_EXPORT NUMBER(3,0);
update surveys.question_version set NUMBER_EMPTY_ROWS_EXCEL_EXPORT = NUMBER_ROWS_EXCEL_EXPORT_TEMP;
alter table surveys.question_version drop column NUMBER_ROWS_EXCEL_EXPORT_TEMP;
ALTER TABLE csr.qs_campaign
MODIFY survey_sid NULL;
ALTER TABLE csrimp.qs_campaign
MODIFY survey_sid NULL;
ALTER TABLE csr.qs_campaign
ADD CONSTRAINT CHK_SURVEY_SID_NOT_DRAFT CHECK ((LOWER(status) != 'draft' AND survey_sid IS NOT NULL) OR (LOWER(status) = 'draft' AND survey_sid IS NOT NULL) OR (LOWER(status) = 'draft' AND survey_sid IS NULL));
ALTER TABLE csrimp.qs_campaign
ADD CONSTRAINT CHK_SURVEY_SID_NOT_DRAFT CHECK ((LOWER(status) != 'draft' AND survey_sid IS NOT NULL) OR (LOWER(status) = 'draft' AND survey_sid IS NOT NULL) OR (LOWER(status) = 'draft' AND survey_sid IS NULL));
ALTER TABLE SURVEYS.IMPORT_MAP_ITEM ADD CONSTRAINT FK_IMPORT_MAP
	FOREIGN KEY (APP_SID, IMPORT_MAP_ID)
	REFERENCES SURVEYS.IMPORT_MAP(APP_SID, IMPORT_MAP_ID) DEFERRABLE INITIALLY DEFERRED
;
ALTER TABLE SURVEYS.IMPORT_MAP_ITEM ADD CONSTRAINT FK_IMP_MAP_ITEM_TARGET
	FOREIGN KEY (IMPORT_TO)
	REFERENCES SURVEYS.IMPORT_MAP_ITEM_TARGET(IMPORT_MAP_ITEM_TARGET_ID)
;
ALTER TABLE csr.ftp_profile ADD PRESERVE_TIMESTAMP	NUMBER(1)	DEFAULT 0 NOT NULL;
ALTER TABLE surveys.import_map_item
MODIFY other_option NUMBER(10);
ALTER TABLE CSR.AUTOMATED_EXPORT_CLASS ADD AUTO_IMPEXP_PUBLIC_KEY_ID NUMBER(10, 0) DEFAULT NULL;
ALTER TABLE CSR.AUTOMATED_EXPORT_CLASS ADD ENABLE_ENCRYPTION NUMBER(1,0) DEFAULT 0;
ALTER TABLE CSR.AUTOMATED_IMPORT_CLASS_STEP ADD ENABLE_DECRYPTION NUMBER(1,0) DEFAULT 0;
ALTER TABLE CSR.AUTOMATED_EXPORT_CLASS ADD CONSTRAINT FK_AUTO_IMPEXP_PUBLIC_KEY_ID
		FOREIGN KEY (AUTO_IMPEXP_PUBLIC_KEY_ID)
		REFERENCES CSR.AUTO_IMPEXP_PUBLIC_KEY (PUBLIC_KEY_ID);
CREATE INDEX csr.ix_automated_exp_auto_impexp_p ON csr.automated_export_class (auto_impexp_public_key_id);


CREATE OR REPLACE PACKAGE surveys.import_map_pkg AS
END;
/
CREATE OR REPLACE PACKAGE BODY surveys.import_map_pkg AS
END;
/
GRANT EXECUTE ON surveys.import_map_pkg to web_user;




CREATE OR REPLACE VIEW surveys.v$question AS
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, q.question_type,
			qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
			qv.max_selections, qv.display_type, qv.value_validation_type, qv.allow_copy_answer, qv.count_towards_progress,
			qv.allow_file_uploads, qv.allow_user_comments, qv.action, q.matrix_parent_id, q.matrix_row_id, qv.matrix_child_pos, q.measure_sid,
			q.deleted_dtm question_deleted_dtm, q.default_lang, qv.option_data_source_id, q.lookup_key, qv.calculation_expression
	  FROM question_version qv
	  JOIN question q ON q.question_id = qv.question_id AND q.app_sid = qv.app_sid;
CREATE OR REPLACE VIEW surveys.v$survey_question AS
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, qv.question_type,
		qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
		qv.max_selections, qv.display_type, qv.value_validation_type, qv.allow_copy_answer, qv.count_towards_progress,
		qv.allow_file_uploads, qv.allow_user_comments, qv.matrix_parent_id, qv.matrix_row_id, qv.matrix_child_pos,
		qv.action, sq.survey_sid, sq.survey_version, sq.section_id, sq.pos, NVL2(qv.question_deleted_dtm, 1, sq.deleted) deleted, qv.measure_sid,
		qv.default_lang, qv.option_data_source_id AS data_source_id, qv.lookup_key, qv.calculation_expression
	  FROM survey_section_question sq
	  JOIN v$question qv ON sq.question_id = qv.question_id AND sq.question_version = qv.question_version
	 UNION ALL
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, qv.question_type,
		qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
		qv.max_selections, qv.display_type, qv.value_validation_type, qv.allow_copy_answer, qv.count_towards_progress,
		qv.allow_file_uploads, qv.allow_user_comments, qv.matrix_parent_id, qv.matrix_row_id, qv.matrix_child_pos,
		qv.action, sq.survey_sid, sq.survey_version, sq.section_id, sq.pos, NVL2(qv.question_deleted_dtm, 1, sq.deleted) deleted, qv.measure_sid,
		qv.default_lang, qv.option_data_source_id AS data_source_id, qv.lookup_key, qv.calculation_expression
	  FROM survey_section_question sq
	  JOIN v$question qv ON sq.question_id = qv.matrix_parent_id AND sq.question_version = qv.question_version
  ORDER BY matrix_parent_id, matrix_row_id, matrix_child_pos;


BEGIN
	UPDATE csr.ftp_profile
	SET preserve_timestamp = 1;
END;
/


BEGIN
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES(1002 /* csr_data_pkg.FLOW_CAP_CAMPAIGN_SHARE */, 'campaign', 'Share response', 1, 0);
END;
/
BEGIN
	UPDATE csr.flow_capability
	   SET description = 'Survey share response'
	 WHERE flow_capability_id = 1002; /* csr_data_pkg.FLOW_CAP_CAMPAIGN_SHARE */
END;
/
BEGIN
	security.user_pkg.logonadmin();
	UPDATE surveys.question_version
	   SET allow_copy_answer = 0
	 WHERE question_id IN (SELECT question_id
							 FROM surveys.question
							WHERE question_type IN ('matrixset', 'matrixdynamic')
						);
	END;
/
INSERT INTO cms.col_type(col_type, description)
VALUES(42, 'Flow state lookup key');
INSERT INTO SURVEYS.IMPORT_MAP_ITEM_TARGET (IMPORT_MAP_ITEM_TARGET_ID, NAME) VALUES (1, 'Response');
INSERT INTO SURVEYS.IMPORT_MAP_ITEM_TARGET (IMPORT_MAP_ITEM_TARGET_ID, NAME) VALUES (2, 'Comment');
INSERT INTO SURVEYS.IMPORT_MAP_ITEM_TARGET (IMPORT_MAP_ITEM_TARGET_ID, NAME) VALUES (3, 'Other');
UPDATE csr.ind 
   SET target_direction = -1 
 WHERE gas_type_id is not null
   AND target_direction != -1;




CREATE OR REPLACE PACKAGE csr.scenario_api_pkg
AS
END;
/
GRANT EXECUTE ON csr.scenario_api_pkg TO web_user;

@..\csr_data_pkg
--@..\surveys\survey_pkg
--@..\surveys\question_library_pkg
@..\scenario_api_pkg
@..\..\..\aspen2\cms\db\tab_pkg
@..\region_pkg
@..\indicator_pkg
--@..\surveys\integration_pkg
@..\measure_pkg
--@..\surveys\import_map_pkg
@..\automated_export_import_pkg
@..\automated_import_pkg
@..\automated_export_pkg


--@..\surveys\survey_body
--@..\surveys\question_library_body
@..\chain\company_filter_body
@..\scenario_api_body
@..\enable_body
--@ ..\surveys\survey_body
@..\region_body
@..\indicator_body
@..\..\..\aspen2\cms\db\tab_body
--@..\surveys\integration_body
@..\measure_body
--@..\surveys\import_map_body
@..\automated_export_import_body
@..\automated_export_body
@..\automated_import_body
@..\csrimp\imp_body
@..\calc_body



@update_tail
