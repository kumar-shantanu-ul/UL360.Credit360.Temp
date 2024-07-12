-- Please update version.sql too -- this keeps clean builds in sync
define version=1
@update_header


alter table chain_questionnaire add (
  view_url varchar2(2000)
);

update chain_questionnaire 
   set view_url = '/csr/site/quickSurvey/results.acds?sid={quickSurveySid}'||chr(38)||'flags=procurer_sid_{procurerSid}' 
 where result_url = '/csr/site/quickSurvey/results.acds?sid={quickSurveySid}'||chr(38)||'flags=supplier_sid_{supplierSid}'

@..\chain_questionnaire_pkg
@..\company_user_pkg

@..\..\create_views

@..\chain_questionnaire_body
@..\company_user_body

@update_tail