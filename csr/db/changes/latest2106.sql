-- Please update version.sql too -- this keeps clean builds in sync
define version=2106
@update_header

CREATE OR REPLACE VIEW CHAIN.v$questionnaire AS
	SELECT q.app_sid, q.questionnaire_id, q.company_sid, q.component_id, c.description component_description, q.questionnaire_type_id, q.created_dtm,
		   qt.view_url, qt.edit_url, qt.owner_can_review, qt.class, qt.name, NVL(q.description, qt.name) description, qt.db_class, qt.group_name, qt.position, qt.security_scheme_id, 
		   qsle.status_log_entry_index, qsle.questionnaire_status_id, qs.description questionnaire_status_name, qsle.entry_dtm status_update_dtm
	  FROM questionnaire q, questionnaire_type qt, qnr_status_log_entry qsle, questionnaire_status qs, component c
	 WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND q.app_sid = qt.app_sid
	   AND q.app_sid = qsle.app_sid
       AND q.questionnaire_type_id = qt.questionnaire_type_id
       AND qsle.questionnaire_status_id = qs.questionnaire_status_id
       AND q.questionnaire_id = qsle.questionnaire_id
       AND q.component_id = c.component_id(+)
       AND (qsle.questionnaire_id, qsle.status_log_entry_index) IN (   
			SELECT questionnaire_id, MAX(status_log_entry_index)
			  FROM qnr_status_log_entry
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 GROUP BY questionnaire_id
			)
;

@update_tail
