-- Please update version.sql too -- this keeps clean builds in sync
define version=2283
@update_header

ALTER TABLE csr.non_compliance 
ADD (question_id NUMBER(10,0) DEFAULT NULL, 
     survey_response_id NUMBER(10, 0) DEFAULT NULL);

@update_tail