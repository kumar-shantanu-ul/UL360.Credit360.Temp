-- Please update version.sql too -- this keeps clean builds in sync
define version=1401
@update_header

ALTER TABLE CSR.QUICK_SURVEY_QUESTION DROP CONSTRAINT FK_ST_QS_QUESTION;
ALTER TABLE CSR.QUICK_SURVEY_QUESTION DROP COLUMN IND_FOR_SCORE_THRESHOLD_ID;

@..\quick_survey_body

@update_tail
