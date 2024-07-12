-- Please update version.sql too -- this keeps clean builds in sync
define version=205
@update_header

alter table old_survey rename to quick_survey;
alter table old_survey_response rename to quick_survey_response;
alter table old_survey_response_answer rename to quick_survey_response_answer;

update security.securable_object_class set class_name='CSRQuickSurvey', helper_pkg ='csr.quick_survey_pkg' where lower(class_name)='csroldsurvey';

DROP PACKAGE old_survey_pkg;

@..\quick_survey_pkg
@..\quick_survey_body

GRANT EXECUTE ON csr.quick_survey_pkg TO SECURITY;

@update_tail
