-- Please update version.sql too -- this keeps clean builds in sync
define version=1081
@update_header

CREATE OR REPLACE VIEW CHAIN.v$message AS
	SELECT m.app_sid, m.message_id, m.message_definition_id, 
			m.re_company_sid, m.re_user_sid, m.re_questionnaire_type_id, m.re_component_id,
			m.due_dtm, m.completed_dtm, m.completed_by_user_sid,
			mrl0.refresh_dtm created_dtm, mrl.refresh_dtm last_refreshed_dtm, mrl.refresh_user_sid last_refreshed_by_user_sid
	  FROM message m, message_refresh_log mrl0, message_refresh_log mrl,
		(
			SELECT message_id, MAX(refresh_index) max_refresh_index
			  FROM message_refresh_log 
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 GROUP BY message_id
		) mlr
	 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND m.app_sid = mrl0.app_sid
	   AND m.app_sid = mrl.app_sid
	   AND m.message_id = mrl0.message_id
	   AND m.message_id = mrl.message_id
	   AND mrl0.refresh_index = 0
	   AND mlr.message_id = mrl.message_id
	   AND mlr.max_refresh_index = mrl.refresh_index
;


CREATE OR REPLACE VIEW CHAIN.v$message_recipient AS
	SELECT m.app_sid, m.message_id, m.message_definition_id, 
			m.re_company_sid, m.re_user_sid, m.re_questionnaire_type_id, m.re_component_id, m.completed_dtm,
			m.completed_by_user_sid, r.recipient_id, r.to_company_sid, r.to_user_sid, mrl.refresh_dtm last_refreshed_dtm, mrl.refresh_user_sid last_refreshed_by_user_sid
	  FROM message_recipient mr, message m, recipient r, message_refresh_log mrl,
		(
			SELECT message_id, MAX(refresh_index) max_refresh_index
			  FROM message_refresh_log 
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 GROUP BY message_id
		) mlr
	 WHERE mr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND mr.app_sid = m.app_sid
	   AND mr.app_sid = r.app_sid
	   AND mr.app_sid = mrl.app_sid
	   AND mr.message_id = m.message_id
	   AND mr.message_id = mrl.message_id
	   AND mr.recipient_id = r.recipient_id
	   AND mlr.message_id = mrl.message_id
	   AND mlr.max_refresh_index = mrl.refresh_index
;

@update_tail
