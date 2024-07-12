-- Please update version.sql too -- this keeps clean builds in sync
define version=300
@update_header

alter table quick_survey add (result_provider varchar2(255));

alter table quick_survey_response add (company_sid number(10) default SYS_CONTEXT('SECURITY', 'SUPPLY_CHAIN_COMPANY'));

@..\quick_survey_pkg
@..\quick_survey_body

@update_tail
