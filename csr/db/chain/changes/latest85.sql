define version=85
@update_header

-- Fix up any data that might prevent a questionnaire submission
INSERT INTO chain.qnr_share_log_entry(app_sid, questionnaire_share_id, share_log_entry_index, share_status_id, user_notes, company_sid, user_sid)
SELECT qs.app_sid, qs.questionnaire_share_id, 1, 11, NULL, qs.qnr_owner_company_sid, MIN(i.to_user_sid)
  FROM chain.questionnaire_share qs
  JOIN chain.invitation i ON i.to_company_sid = qs.qnr_owner_company_sid
 WHERE qs.questionnaire_share_id NOT IN (SELECT questionnaire_share_id FROM chain.qnr_share_log_entry)
   AND i.invitation_status_id=5 -- accepted
 GROUP BY qs.app_sid, qs.questionnaire_share_id, qs.qnr_owner_company_sid;

@..\questionnaire_body

@update_tail