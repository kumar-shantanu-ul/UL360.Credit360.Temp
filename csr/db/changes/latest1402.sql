-- Please update version.sql too -- this keeps clean builds in sync
define version=1402
@update_header

ALTER TABLE CSR.SCORE_THRESHOLD ADD(
    SUPPLIER_SCORE_IND_SID    NUMBER(10, 0)
)
;

ALTER TABLE CSR.SCORE_THRESHOLD ADD CONSTRAINT FK_SUP_SCORE_IND_SID 
    FOREIGN KEY (APP_SID, SUPPLIER_SCORE_IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;

@..\supplier_pkg
@..\quick_survey_body
@..\supplier_body
@..\indicator_body

@update_tail
