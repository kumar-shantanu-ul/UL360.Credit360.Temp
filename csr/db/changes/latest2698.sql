--Please update version.sql too -- this keeps clean builds in sync
define version=2698
@update_header

ALTER TABLE csr.qs_campaign 
ADD campaign_end_dtm DATE NULL;

@..\quick_survey_pkg
@..\quick_survey_body
@..\campaign_pkg
@..\campaign_body

@update_tail