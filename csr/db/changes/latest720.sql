-- Please update version.sql too -- this keeps clean builds in sync
define version=720
@update_header

CREATE TABLE csr.QS_EXPR_DEPENDENCY(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SURVEY_SID            NUMBER(10, 0)    NOT NULL,
    EXPR_ID               NUMBER(10, 0)    NOT NULL,
    DEPENDS_ON_EXPR_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_QS_EXPR_DEPENDENCY PRIMARY KEY (APP_SID, SURVEY_SID, EXPR_ID)
);


ALTER TABLE csr.QS_QUESTION_OPTION ADD (
    PARENT_OPTION_ID      NUMBER(10, 0)
);

ALTER TABLE csr.QS_QUESTION_OPTION MODIFY SCORE NUMBER(13,3);
ALTER TABLE csr.QUICK_SURVEY_QUESTION MODIFY SCORE NUMBER(13,3);
ALTER TABLE csr.QUICK_SURVEY_ANSWER MODIFY SCORE NUMBER(13,3);

ALTER TABLE csr.QUICK_SURVEY DROP CONSTRAINT FK_QS_STATUS_QS;
 
ALTER TABLE csr.QUICK_SURVEY DROP COLUMN QUICK_SURVEY_STATUS_ID;


ALTER TABLE csr.QUICK_SURVEY_ANSWER ADD (
    QUESTION_OPTION_ID    NUMBER(10, 0),
    VAL_NUMBER            NUMBER(24, 10)
);

ALTER TABLE csr.QUICK_SURVEY_EXPR ADD (
    NAME           VARCHAR2(255)
);

ALTER TABLE csr.QUICK_SURVEY_RESPONSE RENAME COLUMN RESPONDED_DTM TO CREATED_DTM;

ALTER TABLE csr.QUICK_SURVEY_RESPONSE ADD (
    FIRST_RESPONSE_DTM        DATE,
    SUBMITTED_DTM             DATE,
    QUICK_SURVEY_STATUS_ID    NUMBER(10, 0)
);
 
ALTER TABLE csr.QS_EXPR_DEPENDENCY ADD CONSTRAINT FK_QS_EXPR_DEP_CHILD 
    FOREIGN KEY (APP_SID, SURVEY_SID, DEPENDS_ON_EXPR_ID)
    REFERENCES csr.QUICK_SURVEY_EXPR(APP_SID, SURVEY_SID, EXPR_ID);

ALTER TABLE csr.QS_EXPR_DEPENDENCY ADD CONSTRAINT FK_QS_EXPR_DEP_MASTER 
    FOREIGN KEY (APP_SID, SURVEY_SID, EXPR_ID)
    REFERENCES csr.QUICK_SURVEY_EXPR(APP_SID, SURVEY_SID, EXPR_ID);
 
 
ALTER TABLE csr.QS_QUESTION_OPTION ADD CONSTRAINT QS_Q_OPT_PARENT_OPT 
    FOREIGN KEY (APP_SID, PARENT_OPTION_ID)
    REFERENCES csr.QS_QUESTION_OPTION(APP_SID, QUESTION_OPTION_ID);
 
--ALTER TABLE csr.QS_QUESTION_OPTION DROP INDEX UK_QUESTION_AND_OPTION;
--DROP INDEX UK_QUESTION_AND_OPTION; 

CREATE UNIQUE INDEX csr.UK_QS_EXPR ON csr.QUICK_SURVEY_EXPR(SURVEY_SID, NVL(UPPER(NAME),'UK_QS_EXPR_'||TO_CHAR(EXPR_ID)));

ALTER TABLE csr.QS_QUESTION_OPTION ADD CONSTRAINT CONS_QUESTION_AND_OPTION  UNIQUE (QUESTION_ID, QUESTION_OPTION_ID);
 
ALTER TABLE csr.QUICK_SURVEY_ANSWER ADD CONSTRAINT FK_QS_Q_OPT_ANSWER 
    FOREIGN KEY (QUESTION_ID, QUESTION_OPTION_ID)
    REFERENCES csr.QS_QUESTION_OPTION(QUESTION_ID, QUESTION_OPTION_ID);
 
ALTER TABLE csr.QUICK_SURVEY_RESPONSE ADD CONSTRAINT FK_QS_STATUS_RESPONSE 
    FOREIGN KEY (APP_SID, QUICK_SURVEY_STATUS_ID)
    REFERENCES csr.QUICK_SURVEY_STATUS(APP_SID, QUICK_SURVEY_STATUS_ID);

@..\quick_survey_body

@update_tail
