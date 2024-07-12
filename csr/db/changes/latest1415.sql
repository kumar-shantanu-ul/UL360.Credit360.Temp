-- Please update version.sql too -- this keeps clean builds in sync
define version=1415
@update_header

ALTER TABLE ct.ec_questionnaire_answers MODIFY vacation_days_per_yr NULL;
ALTER TABLE ct.ec_questionnaire_answers MODIFY other_leave_days_per_yr NULL;

@update_tail
