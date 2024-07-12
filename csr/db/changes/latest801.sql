-- Please update version.sql too -- this keeps clean builds in sync
define version=801
@update_header


ALTER TABLE CSR.INTERNAL_AUDIT_TYPE ADD (
    DEFAULT_SURVEY_SID        NUMBER(10, 0),
    WORD_DOC                  BLOB,
    FILENAME                  VARCHAR2(255)
);

ALTER TABLE CSR.INTERNAL_AUDIT_TYPE ADD CONSTRAINT FK_INT_AUD_DEF_SURVEY 
    FOREIGN KEY (APP_SID, DEFAULT_SURVEY_SID)
    REFERENCES CSR.QUICK_SURVEY(APP_SID, SURVEY_SID)
;

@..\audit_pkg
@..\audit_body

@update_tail
