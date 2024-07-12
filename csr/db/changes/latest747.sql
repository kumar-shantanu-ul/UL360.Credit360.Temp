-- Please update version.sql too -- this keeps clean builds in sync
define version=747
@update_header

CREATE SEQUENCE csr.QS_CAMPAIGN_ID_SEQ 
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;


CREATE TABLE csr.QS_CAMPAIGN
(
	APP_SID						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	QS_CAMPAIGN_ID				NUMBER(10, 0) NOT NULL,
	NAME						VARCHAR2(255),
	TABLE_SID					NUMBER(10, 0),
	FILTER_SID					NUMBER(10, 0),
	SURVEY_SID					NUMBER(10, 0),
	FRAME_ID					NUMBER(10, 0),
	SUBJECT						CLOB,
	BODY						CLOB,
	SEND_AFTER_DTM				DATE,
	STATUS						VARCHAR2(20),
	SENT_DTM					DATE,
	CONSTRAINT CHK_QS_CAMPAIGN_STATUS CHECK (STATUS IN ('draft', 'pending', 'sent')),
	CONSTRAINT PK_QS_CAMPAIGN PRIMARY KEY (APP_SID, QS_CAMPAIGN_ID)
);

@..\quick_survey_pkg
@..\quick_survey_body

@update_tail
