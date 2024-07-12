-- Please update version.sql too -- this keeps clean builds in sync
define version=80
@update_header

/*
PROMPT > Enter service name (e.g. ASPEN):
connect csr/csr@&&1;
grant select, references on quick_survey to supplier;
grant select on quick_survey_response to supplier;
grant select on quick_survey_response_answer to supplier;
connect supplier/supplier@&&1;
grant select, references on all_company to csr;

-- alter existing tables
alter table chain_questionnaire add (
	result_url 				varchar2(255), 
	all_results_url 		varchar2(255),
	quick_survey_sid 		number(10)
);

alter table questionnaire_request add (
	RELEASED_DTM              DATE,
    RELEASED_BY_USER_SID      NUMBER(10, 0)
);

alter table chain_questionnaire add constraint CHAIN_QUEST_QUICK_SURVEY
	foreign key (app_sid, quick_survey_sid)
	references csr.quick_survey(app_sid, survey_sid)
;

alter table csr.quick_survey_response add constraint CHAIN_SUPPLIER_COMPANY 
    foreign key (company_sid)
    references all_company(company_sid)
;     

ALTER TABLE QUESTIONNAIRE_REQUEST ADD CONSTRAINT RefCOMPANY_USER779 
    FOREIGN KEY (SUPPLIER_COMPANY_SID, RELEASED_BY_USER_SID, APP_SID)
    REFERENCES SUPPLIER.COMPANY_USER(COMPANY_SID, CSR_USER_SID, APP_SID)
;

-- recreate view and chain packages
--@..\create_views
--@..\chain\recreate_packages
*/
-- insert some message data
begin
	insert into supplier.message_template_format (message_template_format_id, tpl_format) values (6, 'SupplierSid (Company name), QuestionnaireId (Friendly name)');
	
	insert into supplier.message_template (message_template_id, message_template_format_id, label, tpl) values (
		10,
		6, 
		'Message that a supplier has released a questionnaire to a procurer', 
		'{0} has submitted the {1} questionnaire');

	insert into supplier.message_template (message_template_id, message_template_format_id, label, tpl) values (
		11,
		5,
		'Message from procurer user to supplier company to complete a questionnaire', 
		'{0} has released {2} questionnaire to {1}');
	
	insert into supplier.message_template (message_template_id, message_template_format_id, label, tpl) values (
		12,
		4,
		'Reminder from procurer to supplier user to complete a questionnaire', 
		'{0} has reminded {1} to complete the {2} questionnaire');
end;
/

-- update the description
update request_status set description = 'Submitted by supplier' where request_status_id = 2;

@update_tail