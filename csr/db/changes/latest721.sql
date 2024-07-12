-- Please update version.sql too -- this keeps clean builds in sync
define version=721
@update_header

-- we're going to rename this so drop for now
begin
	for r in (
		select object_name, policy_name 
		  from all_policies 
		 where object_owner='CSR' and object_name='QUICK_SURVEY_STATUS'
	) 
	loop
		dbms_rls.drop_policy(
			object_schema   => 'CSR',
			object_name     => r.object_name,
			policy_name     => r.policy_name
		);
	end loop;
end;
/

ALTER TABLE csr.QS_QUESTION_TYPE ADD (
	ANSWER_TYPE VARCHAR2(10),
	CONSTRAINT CK_QS_QUES_TYPE_ANS_TYPE CHECK (ANSWER_TYPE IN ('val', 'option'))
);

 
ALTER TABLE csr.QS_QUESTION_OPTION ADD (
    LOOKUP_KEY            VARCHAR2(255)
);

CREATE UNIQUE INDEX csr.IX_QS_QUESTION_OPTION ON csr.QS_QUESTION_OPTION(QUESTION_ID, NVL(UPPER(LOOKUP_KEY),'QOID_'||TO_CHAR(QUESTION_OPTION_ID)));

CREATE UNIQUE INDEX csr.IX_QS_QUESTION ON csr.QUICK_SURVEY_QUESTION(SURVEY_SID, NVL(UPPER(LOOKUP_KEY),'QID_'||TO_CHAR(QUESTION_ID)));

DROP TYPE csr.T_QS_QUESTION_OPTION_TABLE;

CREATE OR REPLACE TYPE csr.T_QS_QUESTION_OPTION_ROW AS
	OBJECT (
		QUESTION_ID			NUMBER(10), 
		QUESTION_OPTION_ID	NUMBER(10), 
		POS					NUMBER(10), 		
		LABEL				VARCHAR2(4000), 
		SCORE				NUMBER(10), 
		COLOR				NUMBER(10),
		LOOKUP_KEY			VARCHAR2(255)
	);
/

CREATE OR REPLACE TYPE csr.T_QS_QUESTION_OPTION_TABLE AS
  TABLE OF csr.T_QS_QUESTION_OPTION_ROW;
/


DROP TYPE csr.T_QS_QUESTION_TABLE;

CREATE OR REPLACE TYPE csr.T_QS_QUESTION_ROW AS
	OBJECT (
		QUESTION_ID		NUMBER(10),
		PARENT_ID		NUMBER(10),
		POS				NUMBER(10), 
		LABEL			VARCHAR2(4000), 
		QUESTION_TYPE	VARCHAR2(40), 
		SCORE			NUMBER(10),
		LOOKUP_KEY		VARCHAR2(255)
	);
/
CREATE OR REPLACE TYPE csr.T_QS_QUESTION_TABLE AS
  TABLE OF csr.T_QS_QUESTION_ROW;
/

BEGIN
UPDATE csr.qs_question_type SET answer_type =  'option' WHERE question_type = 'radio';
UPDATE csr.qs_question_type SET answer_type =  'val' WHERE question_type = 'checkbox';
UPDATE csr.qs_question_type SET answer_type =  'option' WHERE question_type = 'radiorow';
UPDATE csr.qs_question_type SET answer_type =  'val' WHERE question_type = 'number';
UPDATE csr.qs_question_type SET answer_type =  'val' WHERE question_type = 'date';
END;
/

ALTER TABLE csr.NON_COMPLIANCE DROP CONSTRAINT FK_QS_EXPR_NC_ACT_NC;

ALTER TABLE csr.NON_COMPLIANCE DROP COLUMN QS_EXPR_NON_COMPL_ACTION_ID;

CREATE TABLE csr.NON_COMPLIANCE_EXPR_ACTION(
    APP_SID                        NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    NON_COMPLIANCE_ID              NUMBER(10, 0)    NOT NULL,
    QS_EXPR_NON_COMPL_ACTION_ID    NUMBER(10, 0)    NOT NULL,
    SURVEY_RESPONSE_ID             NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_NON_COMPL_EXPR_ACTION PRIMARY KEY (APP_SID, QS_EXPR_NON_COMPL_ACTION_ID, SURVEY_RESPONSE_ID)
);
 
ALTER TABLE csr.QS_EXPR_STATUS_ACTION RENAME COLUMN QUICK_SURVEY_STATUS_ID TO QS_RESPONSE_STATUS_ID;

ALTER TABLE csr.QUICK_SURVEY_STATUS RENAME TO QS_RESPONSE_STATUS;

ALTER TABLE csr.QS_EXPR_STATUS_ACTION DROP CONSTRAINT FK_QS_STATUS_EXPR_ST_ACT;

ALTER TABLE csr.QUICK_SURVEY_RESPONSE DROP CONSTRAINT FK_QS_STATUS_RESPONSE;

ALTER TABLE csr.QS_RESPONSE_STATUS DROP PRIMARY KEY DROP INDEX;

ALTER TABLE csr.QUICK_SURVEY_RESPONSE RENAME COLUMN QUICK_SURVEY_STATUS_ID TO QS_RESPONSE_STATUS_ID;

ALTER TABLE csr.QS_RESPONSE_STATUS RENAME COLUMN QUICK_SURVEY_STATUS_ID TO QS_RESPONSE_STATUS_ID;

ALTER TABLE csr.QS_RESPONSE_STATUS ADD CONSTRAINT PK_QUICK_SURVEY_STATUS PRIMARY KEY (APP_SID, QS_RESPONSE_STATUS_ID);

 
ALTER TABLE csr.QS_EXPR_STATUS_ACTION ADD CONSTRAINT FK_QS_STATUS_EXPR_ST_ACT 
    FOREIGN KEY (APP_SID, QS_RESPONSE_STATUS_ID)
    REFERENCES csr.QS_RESPONSE_STATUS(APP_SID, QS_RESPONSE_STATUS_ID);

ALTER TABLE csr.QUICK_SURVEY_RESPONSE ADD CONSTRAINT FK_QS_STATUS_RESPONSE 
    FOREIGN KEY (APP_SID, QS_RESPONSE_STATUS_ID)
    REFERENCES csr.QS_RESPONSE_STATUS(APP_SID, QS_RESPONSE_STATUS_ID);
 
ALTER TABLE csr.NON_COMPLIANCE_EXPR_ACTION ADD CONSTRAINT FK_EXPR_NC_ACT_NC 
    FOREIGN KEY (APP_SID, QS_EXPR_NON_COMPL_ACTION_ID)
    REFERENCES csr.QS_EXPR_NON_COMPL_ACTION(APP_SID, QS_EXPR_NON_COMPL_ACTION_ID)
;

ALTER TABLE csr.NON_COMPLIANCE_EXPR_ACTION ADD CONSTRAINT FK_NC_NC_EXPR_ACT 
    FOREIGN KEY (APP_SID, NON_COMPLIANCE_ID)
    REFERENCES csr.NON_COMPLIANCE(APP_SID, NON_COMPLIANCE_ID);

ALTER TABLE csr.NON_COMPLIANCE_EXPR_ACTION ADD CONSTRAINT FK_QSR_NC_EXPR_ACTION 
    FOREIGN KEY (APP_SID, SURVEY_RESPONSE_ID)
    REFERENCES csr.QUICK_SURVEY_RESPONSE(APP_SID, SURVEY_RESPONSE_ID);


DROP SEQUENCE csr.QUICK_SURVEY_STATUS_ID_SEQ;

CREATE SEQUENCE csr.QS_RESPONSE_STATUS_ID_SEQ
    START WITH 1000
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

ALTER TABLE csr.QUICK_SURVEY_RESPONSE ADD
    CONSTRAINT CONS_QS_RESPONSE  UNIQUE (APP_SID, SURVEY_SID, SURVEY_RESPONSE_ID);
    
ALTER TABLE csr.INTERNAL_AUDIT ADD (
    SURVEY_RESPONSE_ID        NUMBER(10, 0));
    
ALTER TABLE csr.INTERNAL_AUDIT ADD CONSTRAINT FK_QSR_INTERNAL_AUDIT 
    FOREIGN KEY (APP_SID, SURVEY_SID, SURVEY_RESPONSE_ID)
    REFERENCES csr.QUICK_SURVEY_RESPONSE(APP_SID, SURVEY_SID, SURVEY_RESPONSE_ID);


@..\quick_survey_pkg
@..\quick_survey_body

@update_tail
