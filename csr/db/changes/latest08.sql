-- Please update version.sql too -- this keeps clean builds in sync
define version=08
@update_header


CREATE SEQUENCE ALERT_ID_SEQ 
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;

CREATE TABLE ALERT(
    NOTIFY_USER_SID       NUMBER(10, 0)    NOT NULL,
    ALERT_ID              NUMBER(10, 0)    NOT NULL,
    ALERT_TYPE_ID         NUMBER(10, 0)    NOT NULL,
    CSR_ROOT_SID          NUMBER(10, 0)    NOT NULL,
    RAISED_BY_USER_SID    NUMBER(10, 0)    NOT NULL,
    RAISED_DTM            DATE             NOT NULL,
    SEND_AFTER_DTM        DATE             NOT NULL,
    SENT_DTM              DATE,
    PARAMS		  VARCHAR2(2048),
    CONSTRAINT PK111 PRIMARY KEY (ALERT_ID)
)
;



-- 
-- TABLE: ALERT_TEMPLATE 
--

CREATE TABLE ALERT_TEMPLATE(
    ALERT_TYPE_ID     NUMBER(10, 0)     NOT NULL,
    CSR_ROOT_SID      NUMBER(10, 0)     NOT NULL,
    MAIL_BODY         CLOB               DEFAULT EMPTY_CLOB() NOT NULL,
    MAIL_SUBJECT      VARCHAR2(1024)    NOT NULL,
    MAIL_FROM_NAME    VARCHAR2(255)     NOT NULL,
	ONCE_ONLY 	NUMBER(10,0) default 0 not null,
    CONSTRAINT PK102 PRIMARY KEY (ALERT_TYPE_ID, CSR_ROOT_SID)
)
;



-- 
-- TABLE: ALERT_TYPE 
--

CREATE TABLE ALERT_TYPE(
    ALERT_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION      VARCHAR2(255)    NOT NULL,
    GET_DATA_SP      VARCHAR2(255),
    CONSTRAINT PK101 PRIMARY KEY (ALERT_TYPE_ID)
)
;


ALTER TABLE ALERT ADD CONSTRAINT RefALERT_TYPE186 
    FOREIGN KEY (ALERT_TYPE_ID)
    REFERENCES ALERT_TYPE(ALERT_TYPE_ID)
;

ALTER TABLE ALERT ADD CONSTRAINT RefCSR_USER187 
    FOREIGN KEY (NOTIFY_USER_SID)
    REFERENCES CSR_USER(CSR_USER_SID)
;


-- 
-- TABLE: ALERT_TEMPLATE 
--

ALTER TABLE ALERT_TEMPLATE ADD CONSTRAINT RefALERT_TYPE188 
    FOREIGN KEY (ALERT_TYPE_ID)
    REFERENCES ALERT_TYPE(ALERT_TYPE_ID)
;


BEGIN
INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP ) VALUES ( 1, 'New user', 'alert_pkg.GetAlerts_NewUser'); 
END;
/

@update_tail
