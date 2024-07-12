define version=39
@update_header

begin
	for r in (select app_sid, company_sid, questionnaire_type_id, min(rowid) rid
				from questionnaire
			   group by app_sid, company_sid, questionnaire_type_id
			  having count(*) > 1) loop
		update action
		   set related_questionnaire_id = null
		 where related_questionnaire_id = (select questionnaire_id from questionnaire where rowid = r.rid);
		update event
		   set related_questionnaire_id = null
		 where related_questionnaire_id = (select questionnaire_id from questionnaire where rowid = r.rid);
		delete from qnr_share_log_entry
		 where questionnaire_share_id in (
				select questionnaire_share_id
				  from questionnaire_share
				  where questionnaire_id = (select questionnaire_id from questionnaire where rowid = r.rid));
		delete from questionnaire_share
		  where questionnaire_id = (select questionnaire_id from questionnaire where rowid = r.rid);
		delete from qnr_status_log_entry
		 where questionnaire_id = (select questionnaire_id from questionnaire where rowid = r.rid);
		delete from questionnaire where rowid = r.rid;
	end loop;
end;
/

alter table questionnaire add CONSTRAINT UNIQUE_COMPANY_QNR_TYPE  UNIQUE (APP_SID, COMPANY_SID, QUESTIONNAIRE_TYPE_ID);

@update_tail

