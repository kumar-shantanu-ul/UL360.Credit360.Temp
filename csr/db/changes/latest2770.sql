-- Please update version.sql too -- this keeps clean builds in sync
define version=2770
@update_header


CREATE OR REPLACE VIEW CHAIN.v$questionnaire_share AS
	SELECT q.app_sid, q.questionnaire_id, q.component_id, q.questionnaire_type_id, q.created_dtm,
		   qs.due_by_dtm, qs.overdue_events_sent, qs.qnr_owner_company_sid, qs.share_with_company_sid,
		   qsle.share_log_entry_index, qsle.entry_dtm, qs.questionnaire_share_id, qs.reminder_sent_dtm,
		   qs.overdue_sent_dtm, qsle.share_status_id, ss.description share_status_name,
		   qsle.company_sid entry_by_company_sid, qsle.user_sid entry_by_user_sid, qsle.user_notes,
		   qt.class qt_class, 
		   qt.name questionnaire_name, qs.expiry_dtm, CASE WHEN qs.expiry_dtm < SYSDATE THEN 1 ELSE 0 END has_expired,
		   q.rejected questionnaire_rejected
	  FROM questionnaire q
	  JOIN questionnaire_share qs ON q.app_sid = qs.app_sid AND q.questionnaire_id = qs.questionnaire_id
	  JOIN qnr_share_log_entry qsle ON qs.app_sid = qsle.app_sid AND qs.questionnaire_share_id = qsle.questionnaire_share_id
	  JOIN share_status ss ON qsle.share_status_id = ss.share_status_id
	  JOIN company s ON q.app_sid = s.app_sid AND q.company_sid = s.company_sid
	  JOIN questionnaire_type qt ON q.app_sid = qt.app_sid AND q.questionnaire_type_id = qt.questionnaire_type_id	 
	 WHERE s.deleted = 0
	   AND (								-- allows builtin admin to see relationships as well for debugging purposes
	   			qs.share_with_company_sid = NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), qs.share_with_company_sid)
	   		 OR qs.qnr_owner_company_sid = NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), qs.qnr_owner_company_sid)
	   	   )
	   AND (qsle.app_sid, qsle.questionnaire_share_id, qsle.share_log_entry_index) IN (   
	   			SELECT app_sid, questionnaire_share_id, MAX(share_log_entry_index)
	   			  FROM qnr_share_log_entry
	   			 GROUP BY app_sid, questionnaire_share_id
			)
;


-- *** Packages ***
@../quick_survey_body
@../chain/questionnaire_body

@update_tail
