--Please update version.sql too -- this keeps clean builds in sync
define version=2652
@update_header

ALTER TABLE csrimp.quick_survey_question
DROP CONSTRAINT pk_quick_survey_question;

ALTER TABLE csrimp.quick_survey_question
ADD CONSTRAINT pk_quick_survey_question PRIMARY KEY (csrimp_session_id, question_id, survey_version);

@update_tail
