-- Please update version.sql too -- this keeps clean builds in sync
define version=1873
@update_header

grant select on csr.quick_survey_submission to chain;

@../chain/questionnaire_pkg
@../chain/questionnaire_body

@update_tail
