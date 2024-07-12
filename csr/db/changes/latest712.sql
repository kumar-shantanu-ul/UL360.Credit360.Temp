-- Please update version.sql too -- this keeps clean builds in sync
define version=712
@update_header

DROP INDEX csr.UK_QUESTION_AND_OPTION;
ALTER TABLE csr.QS_QUESTION_OPTION DROP PRIMARY KEY DROP INDEX;
ALTER TABLE csr.QS_QUESTION_OPTION ADD PRIMARY KEY (APP_SID, QUESTION_OPTION_ID);

BEGIN
INSERT INTO csr.QS_QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('matrix', 'Matrix');
INSERT INTO csr.QS_QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('radiorow', 'Matrix radio button row');
INSERT INTO csr.QS_QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('number', 'Number');
INSERT INTO csr.QS_QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('date', 'Date');
END;
/

@..\quick_survey_pkg
@..\quick_survey_body

@update_tail
