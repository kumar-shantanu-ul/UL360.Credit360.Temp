-- Please update version.sql too -- this keeps clean builds in sync
define version=2144
@update_header

-- a debug view of all supplier questionnaires as it was before tuning for FB43470 - to see if that has impacted 43915

CREATE VIEW CHAIN.v$questionnaire_share_debug AS
	SELECT q.app_sid, q.questionnaire_id, q.component_id, q.questionnaire_type_id, q.created_dtm, qs.due_by_dtm, qs.overdue_events_sent,
		   qs.qnr_owner_company_sid, qs.share_with_company_sid, qsle.share_log_entry_index, qsle.entry_dtm, 
		   qs.questionnaire_share_id, qs.reminder_sent_dtm, qs.overdue_sent_dtm, qsle.share_status_id, ss.description share_status_name,
           qsle.company_sid entry_by_company_sid, qsle.user_sid entry_by_user_sid, qsle.user_notes
	  FROM questionnaire q, questionnaire_share qs, qnr_share_log_entry qsle, share_status ss, v$company s
	 WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND q.app_sid = qs.app_sid
	   AND q.app_sid = qsle.app_sid
	   AND q.company_sid = s.company_sid
	   AND q.company_sid = qs.qnr_owner_company_sid
	   AND (								-- allows builtin admin to see relationships as well for debugging purposes
	   			qs.share_with_company_sid = NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), qs.share_with_company_sid)
	   		 OR qs.qnr_owner_company_sid = NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), qs.qnr_owner_company_sid)
	   	   )
	   AND q.questionnaire_id = qs.questionnaire_id
	   AND qs.questionnaire_share_id = qsle.questionnaire_share_id
	   AND qsle.share_status_id = ss.share_status_id
	   AND (qsle.questionnaire_share_id, qsle.share_log_entry_index) IN (   
	   			SELECT questionnaire_share_id, MAX(share_log_entry_index)
	   			  FROM qnr_share_log_entry
	   			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   			 GROUP BY questionnaire_share_id
			)
;

@..\chain\questionnaire_pkg;
@..\chain\questionnaire_body;
		
@update_tail
