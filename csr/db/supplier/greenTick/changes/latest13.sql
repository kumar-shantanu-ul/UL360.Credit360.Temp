-- Please update version.sql too -- this keeps clean builds in sync
define version=13
@update_header

UPDATE questionnaire_group_membership SET pos = 9 WHERE questionnaire_id = 13;
UPDATE questionnaire_group_membership SET pos = 9 WHERE questionnaire_id = 10;
UPDATE questionnaire_group_membership SET pos = 10 WHERE questionnaire_id = 9;

@update_tail