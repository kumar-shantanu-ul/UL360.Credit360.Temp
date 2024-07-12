-- Please update version.sql too -- this keeps clean builds in sync
define version=52
@update_header

ALTER TABLE SUPPLIER.QUESTIONNAIRE_GROUP_MEMBERSHIP
 ADD (POS  NUMBER(10)                               DEFAULT 0                     NOT NULL);

update QUESTIONNAIRE_GROUP_MEMBERSHIP set pos = questionnaire_id;

-- switch order of formulation and pack
update QUESTIONNAIRE_GROUP_MEMBERSHIP set pos = 10 WHERE questionnaire_id = 9;
update QUESTIONNAIRE_GROUP_MEMBERSHIP set pos = 9 WHERE questionnaire_id = 10;

@update_tail
