-- Please update version.sql too -- this keeps clean builds in sync
define version=1303
@update_header

ALTER TABLE CSR.QUICK_SURVEY_RESPONSE ADD(
    SCORE_THRESHOLD_ID       NUMBER(10, 0)
);

ALTER TABLE CSR.QUICK_SURVEY_RESPONSE ADD CONSTRAINT FK_QS_RESP_THRESHOLD 
    FOREIGN KEY (APP_SID, SCORE_THRESHOLD_ID)
    REFERENCES CSR.SCORE_THRESHOLD(APP_SID, SCORE_THRESHOLD_ID)
;

ALTER TABLE CSR.QUICK_SURVEY_ANSWER ADD(
    VERSION_STAMP            NUMBER(10, 0)
)
;

CREATE SEQUENCE CSR.VERSION_STAMP_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

UPDATE csr.quick_survey_answer
   SET version_stamp = csr.version_stamp_seq.NEXTVAL
;
   

ALTER TABLE CSR.QUICK_SURVEY_ANSWER MODIFY VERSION_STAMP NOT NULL;

@..\csr_data_pkg
@..\quick_survey_pkg
@..\supplier_pkg

@..\chain\invitation_body
@..\quick_survey_body
@..\supplier_body


@update_tail
