-- Please update version.sql too -- this keeps clean builds in sync
define version=1419
@update_header

ALTER TABLE CSRIMP.QUICK_SURVEY ADD(
	SUBMISSION_VALIDITY_MONTHS NUMBER(10, 0) NOT NULL
)
;

ALTER TABLE CSRIMP.SCORE_THRESHOLD ADD(
    MEASURE_LIST_INDEX        NUMBER(10, 0)
)
;

ALTER TABLE CSRIMP.MAIL_MESSAGE MODIFY SUBJECT VARCHAR2(4000);

@..\schema_body
@..\csrimp\imp_body

@update_tail
