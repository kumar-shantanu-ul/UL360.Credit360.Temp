-- Please update version.sql too -- this keeps clean builds in sync
define version=2265
@update_header

create or replace procedure csr.createIndex(
	in_sql							in	varchar2
) authid current_user
as
	e_name_in_use					exception;
	pragma exception_init(e_name_in_use, -00955);
begin
	begin
		dbms_output.put_line(in_sql);
		execute immediate in_sql;
	exception
		when e_name_in_use then
			null;
	end;
end;
/

begin
	for r in (select * from all_indexes where owner='CHAIN' and index_name='IX_COMPANY_TYPE__PRIMARY_COMPA') loop
		execute immediate 'drop index '||r.owner||'.'||r.index_name;
	end loop;
	csr.createIndex('create index chain.ix_activity_activity_ty_ou on chain.activity (app_sid, activity_type_id, outcome_type_id)');
	csr.createIndex('create index chain.ix_alert_entry_alert_ent_tpl on chain.alert_entry (alert_entry_type_id, template_name)');
	csr.createIndex('create index chain.ix_audit_request_req_by_user on chain.audit_request (app_sid, requested_by_user_sid)');
	csr.createIndex('create index chain.ix_company_type_pcomp_scomp on chain.company_type_capability (app_sid, primary_company_type_id, secondary_company_type_id)');
	csr.createIndex('create index chain.ix_company_type_pcomp_grp on chain.company_type_capability (primary_company_group_type_id)');
	csr.createIndex('create index chain.ix_comp_typ_pcomp_scomp_tcomp on chain.company_type_capability (app_sid, primary_company_type_id, secondary_company_type_id, tertiary_company_type_id)');
	csr.createIndex('create index chain.ix_question_user_comp_sid on chain.questionnaire_user (app_sid, company_sid)');
	csr.createIndex('create index chain.ix_questionnaire_ua_question on chain.questionnaire_user_action (app_sid, questionnaire_id, user_sid, company_function_id, company_sid)');
	csr.createIndex('create index chain.ix_questionnaire_ua_comp on chain.questionnaire_user_action (company_function_id, questionnaire_action_id)');
	csr.createIndex('create index csr.ix_term_cond_doc_doc_id_log on csr.term_cond_doc_log (app_sid, doc_id)');
	csr.createIndex('create index csr.ix_calendar_even_user_sid on csr.calendar_event_owner (app_sid, user_sid)');
	csr.createIndex('create index csr.ix_int_aud_file_int_aud_sid on csr.internal_audit_file (app_sid, internal_audit_sid)');
	csr.createIndex('create index csr.ix_issue_issue_type_id_lrs on csr.issue (app_sid, issue_type_id, last_rag_status_id)');
	csr.createIndex('create index csr.ix_property_mgmt_comp_comp on csr.property (app_sid, mgmt_company_contact_id, mgmt_company_id)');
end;
/

drop procedure csr.createIndex;

@update_tail
