-- Please update version.sql too -- this keeps clean builds in sync
define version=2528
@update_header

ALTER TABLE csr.quick_survey_question ADD REMEMBER_ANSWER NUMBER(1); 
UPDATE csr.quick_survey_question SET REMEMBER_ANSWER = 0;
ALTER TABLE csr.quick_survey_question MODIFY REMEMBER_ANSWER DEFAULT 0 NOT NULL;

ALTER TABLE csr.temp_question ADD REMEMBER_ANSWER NUMBER(1); 
UPDATE csr.temp_question SET REMEMBER_ANSWER = 0;
ALTER TABLE csr.temp_question MODIFY REMEMBER_ANSWER DEFAULT 0 NOT NULL;

@update_tail
