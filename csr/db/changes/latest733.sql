-- Please update version.sql too -- this keeps clean builds in sync
define version=733
@update_header

INSERT INTO csr.QS_QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('regionpicker', 'Region picker', null);

@../quick_survey_pkg
@../quick_survey_body

@update_tail
