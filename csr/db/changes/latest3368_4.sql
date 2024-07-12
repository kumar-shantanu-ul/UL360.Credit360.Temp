-- Please update version.sql too -- this keeps clean builds in sync
define version=3368
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables
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


-- Alter tables

-- *** Grants ***
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

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (305,'IQA',6);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../csrimp/imp_pkg
@../integration_question_answer_pkg
@../integration_question_answer_report_pkg
@../schema_pkg
@../unit_test_pkg

@../csr_app_body
@../csrimp/imp_body
@../integration_question_answer_body
@../integration_question_answer_report_body
@../schema_body
@../unit_test_body

@update_tail
