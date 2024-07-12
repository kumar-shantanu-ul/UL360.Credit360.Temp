define version=3369
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;

CREATE TABLE CSR.INTEGRATION_QUESTION_ANSWER(
	APP_SID				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	PARENT_REF			VARCHAR2(255)	NOT NULL,
	QUESTION_REF		VARCHAR2(255)	NOT NULL,
	INTERNAL_AUDIT_SID	NUMBER(10, 0),
	SECTION_NAME		VARCHAR2(1024),
	SECTION_CODE		VARCHAR2(1024),
	SECTION_SCORE		NUMBER(10, 5),
	SUBSECTION_NAME		VARCHAR2(1024),
	SUBSECTION_CODE		VARCHAR2(1024),
	QUESTION_TEXT		VARCHAR2(4000),
	RATING				VARCHAR2(1024),
	CONCLUSION			CLOB,
	ANSWER				VARCHAR2(4000),
	DATA_POINTS			CLOB,
	LAST_UPDATED		DATE,
	CONSTRAINT PK_INTEGRATION_QUESTION_ANSWER PRIMARY KEY (APP_SID, PARENT_REF, QUESTION_REF),
	CONSTRAINT FK_INTEGRATION_QTN_ANS_IA_SID FOREIGN KEY (APP_SID, INTERNAL_AUDIT_SID) REFERENCES CSR.INTERNAL_AUDIT (APP_SID, INTERNAL_AUDIT_SID)
)
;
CREATE INDEX CSR.IX_INT_QTN_ANS_IA ON CSR.INTEGRATION_QUESTION_ANSWER(APP_SID, INTERNAL_AUDIT_SID);
CREATE TABLE CSRIMP.INTEGRATION_QUESTION_ANSWER(
	CSRIMP_SESSION_ID	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	PARENT_REF			VARCHAR2(255)	NOT NULL,
	QUESTION_REF		VARCHAR2(255)	NOT NULL,
	INTERNAL_AUDIT_SID	NUMBER(10, 0),
	SECTION_NAME		VARCHAR2(1024),
	SECTION_CODE		VARCHAR2(1024),
	SECTION_SCORE		NUMBER(10, 5),
	SUBSECTION_NAME		VARCHAR2(1024),
	SUBSECTION_CODE		VARCHAR2(1024),
	QUESTION_TEXT		VARCHAR2(4000),
	RATING				VARCHAR2(1024),
	CONCLUSION			CLOB,
	ANSWER				VARCHAR2(4000),
	DATA_POINTS			CLOB,
	LAST_UPDATED		DATE
);
CREATE SEQUENCE CSR.INTEGRATION_QUESTION_ANSWER_ID_SEQ;


ALTER TABLE CSR.INTEGRATION_QUESTION_ANSWER ADD (ID	NUMBER(10, 0));
UPDATE CSR.INTEGRATION_QUESTION_ANSWER
   SET ID = CSR.INTEGRATION_QUESTION_ANSWER_ID_SEQ.NEXTVAL;
ALTER TABLE CSR.INTEGRATION_QUESTION_ANSWER MODIFY (ID NOT NULL);
ALTER TABLE CSR.INTEGRATION_QUESTION_ANSWER ADD CONSTRAINT UK_INTEGRATION_QUESTION_ANSWER_ID UNIQUE (APP_SID, ID);
ALTER TABLE CSRIMP.INTEGRATION_QUESTION_ANSWER ADD (ID	NUMBER(10, 0));


grant select,insert,update,delete on csrimp.integration_question_answer to tool_user;
grant select,insert, update on csr.integration_question_answer to csrimp;
CREATE OR REPLACE PACKAGE csr.integration_question_answer_pkg AS
    PROCEDURE DUMMY;
END;
/
CREATE OR REPLACE PACKAGE BODY csr.integration_question_answer_pkg AS
    PROCEDURE DUMMY
AS
    BEGIN
        NULL;
    END;
END;
/
CREATE OR REPLACE PACKAGE csr.integration_question_answer_report_pkg AS
    PROCEDURE DUMMY;
END;
/
CREATE OR REPLACE PACKAGE BODY csr.integration_question_answer_report_pkg AS
    PROCEDURE DUMMY
AS
    BEGIN
        NULL;
    END;
END;
/
grant execute on csr.integration_question_answer_pkg to web_user;
GRANT EXECUTE ON csr.integration_question_answer_report_pkg TO chain;
grant execute on csr.integration_question_answer_report_pkg to web_user;








BEGIN
	FOR r IN (SELECT tag_group_id FROM csr.tag_group WHERE lookup_key = 'RBA_F_FINDING_STATUS')
	LOOP
		DELETE FROM csr.non_compliance_tag
		 WHERE tag_id IN (SELECT tag_id FROM csr.tag_group_member WHERE tag_group_id = r.tag_group_id);
		 
		DELETE FROM csr.tag_group_member
		 WHERE tag_group_id = r.tag_group_id;
		
		DELETE FROM csr.tag_description
		 WHERE tag_id IN (SELECT tag_id FROM csr.tag_group_member WHERE tag_group_id = r.tag_group_id);
		 
		DELETE FROM csr.tag
		 WHERE tag_id IN (SELECT tag_id FROM csr.tag_group_member WHERE tag_group_id = r.tag_group_id);
		   
		DELETE FROM csr.non_compliance_type_tag_group
		 WHERE tag_group_id = r.tag_group_id;
		 
		DELETE FROM csr.tag_group_description
		 WHERE tag_group_id = r.tag_group_id;
		DELETE FROM csr.tag_group
		 WHERE tag_group_id = r.tag_group_id;
	END LOOP;
END;
/
INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (305,'IQA',6);
@@latestUD-9655_packages
DECLARE
	v_card_id NUMBER;
BEGIN
	security.user_pkg.logonadmin;
	chain.temp_card_pkg.RegisterCardGroup(68, 'Integration Question/Answers', 'Allows filtering of Integration Question/Answers.', 'csr.integration_question_answer_report_pkg', NULL);
	chain.temp_card_pkg.RegisterCard(
		'Integration Question Answer Filter', 
		'Credit360.Audit.Cards.IntegrationQuestionAnswerFilter',
		'/csr/site/audit/IntegrationQuestionAnswerFilter.js', 
		'Credit360.Audit.Filters.IntegrationQuestionAnswerFilter'
	);
	
	SELECT card_id INTO v_card_id FROM chain.card WHERE js_class_type = 'Credit360.Audit.Filters.IntegrationQuestionAnswerFilter'; 
	
	BEGIN
		INSERT INTO chain.filter_type
		(filter_type_id, description, helper_pkg, card_id)
		VALUES
		(chain.filter_type_id_seq.NEXTVAL, 'Integration Question Answer Filter', 'csr.integration_question_answer_report_pkg', v_card_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;
	chain.temp_card_pkg.RegisterCard(
		'Integration Question Answer Filter Adapter', 
		'Credit360.Audit.Cards.IntegrationQuestionAnswerFilterAdapter',
		'/csr/site/audit/IntegrationQuestionAnswerFilterAdapter.js', 
		'Credit360.Audit.Filters.IntegrationQuestionAnswerFilterAdapter'
	);
	
	SELECT card_id INTO v_card_id FROM chain.card WHERE js_class_type = 'Credit360.Audit.Filters.IntegrationQuestionAnswerFilterAdapter'; 
	
	BEGIN
		INSERT INTO chain.filter_type
		(filter_type_id, description, helper_pkg, card_id)
		VALUES
		(chain.filter_type_id_seq.NEXTVAL, 'Integration Question Answer Filter Adapter', 'csr.integration_question_answer_report_pkg', v_card_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;
END;
/
DROP PACKAGE chain.temp_card_pkg;
BEGIN
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (68 /*chain.filter_pkg.FILTER_TYPE_INTEGRATION_QUESTION_ANSWER*/, 2 /*csr.integration_question_answer_report_pkg.AGG_TYPE_COUNT*/, 'Number of records');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;
	BEGIN
		INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
		VALUES (68 /*chain.filter_pkg.FILTER_TYPE_INTEGRATION_QUESTION_ANSWER*/, 2 /*csr.integration_question_answer_report_pkg.COL_TYPE_LAST_UPDATED*/, 2 /*chain.filter_pkg.COLUMN_TYPE_DATE*/, 'Last updated');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;
END;
/


BEGIN




	EXECUTE IMMEDIATE 'DROP PACKAGE csr.latest_xxx_pkg';
EXCEPTION
	WHEN OTHERS THEN
		NULL;
END;
/
@..\csr_user_pkg
@..\csr_data_pkg
@..\csrimp\imp_pkg
@..\integration_question_answer_pkg
@..\integration_question_answer_report_pkg
@..\schema_pkg
@..\unit_test_pkg
@..\audit_pkg
@..\enable_pkg
@..\chain\filter_pkg


@..\csr_user_body
@..\enable_body
@..\csr_app_body
@..\csrimp\imp_body
@..\integration_question_answer_body
@..\integration_question_answer_report_body
@..\schema_body
@..\unit_test_body
@..\audit_body



@update_tail
