-- Please update version.sql too -- this keeps clean builds in sync
define version=10
@update_header


drop table survey;

-- 
-- SEQUENCE: SURVEY_RESPONSE_ID_SEQ 
--

CREATE SEQUENCE SURVEY_RESPONSE_ID_SEQ 
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;



-- 
-- TABLE: SURVEY 
--

CREATE TABLE SURVEY(
    SURVEY_SID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK116 PRIMARY KEY (SURVEY_SID)
)
;



-- 
-- TABLE: SURVEY_RESPONSE 
--

CREATE TABLE SURVEY_RESPONSE(
    SURVEY_RESPONSE_ID    NUMBER(10, 0)    NOT NULL,
    SURVEY_SID            NUMBER(10, 0)    NOT NULL,
    USER_SID              NUMBER(10, 0),
    USER_NAME             VARCHAR2(255),
    RESPONDED_DTM         DATE              DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK117 PRIMARY KEY (SURVEY_RESPONSE_ID)
)
;



-- 
-- TABLE: SURVEY_RESPONSE_ANSWER 
--

CREATE TABLE SURVEY_RESPONSE_ANSWER(
    SURVEY_RESPONSE_ID    NUMBER(10, 0)     NOT NULL,
    QUESTION_CODE         VARCHAR2(32)      NOT NULL,
    ANSWER                VARCHAR2(2047),
    CONSTRAINT PK118 PRIMARY KEY (SURVEY_RESPONSE_ID, QUESTION_CODE)
)
;



-- 
-- TABLE: SURVEY_RESPONSE 
--

ALTER TABLE SURVEY_RESPONSE ADD CONSTRAINT RefSURVEY192 
    FOREIGN KEY (SURVEY_SID)
    REFERENCES SURVEY(SURVEY_SID)
;


-- 
-- TABLE: SURVEY_RESPONSE_ANSWER 
--

ALTER TABLE SURVEY_RESPONSE_ANSWER ADD CONSTRAINT RefSURVEY_RESPONSE193 
    FOREIGN KEY (SURVEY_RESPONSE_ID)
    REFERENCES SURVEY_RESPONSE(SURVEY_RESPONSE_ID)
;





CREATE SEQUENCE ERROR_LOG_ID_SEQ 
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;




-- 
-- TABLE: ERROR_LOG 
--

CREATE TABLE ERROR_LOG(
    ERROR_LOG_ID      CHAR(10)          NOT NULL,
    DESCRIPTION       VARCHAR2(2048)    NOT NULL,
    SOURCE_TYPE_ID    NUMBER(10, 0)     NOT NULL,
    DTM               DATE               DEFAULT SYSDATE NOT NULL,
    CSR_ROOT_SID      NUMBER(10, 0)      NOT NULL,
    USER_SID	      NUMBER(10, 0)	NOT NULL,
    CONSTRAINT PK123 PRIMARY KEY (ERROR_LOG_ID)
)
;



-- 
-- TABLE: ERROR_LOG 
--

ALTER TABLE ERROR_LOG ADD CONSTRAINT RefSOURCE_TYPE196 
    FOREIGN KEY (SOURCE_TYPE_ID)
    REFERENCES SOURCE_TYPE(SOURCE_TYPE_ID)
;



@update_tail
