-- Please update version.sql too -- this keeps clean builds in sync
define version=2522
@update_header

CREATE OR REPLACE VIEW csr.v$audit_validity AS --more basic version of v$audit_next_due that returns all audits carried out and their validity instead of just the most recent of each type
SELECT ia.internal_audit_sid, ia.internal_audit_type_id, ia.region_sid,
ia.audit_dtm previous_audit_dtm, act.audit_closure_type_id, ia.app_sid,
CASE (re_audit_due_after_type)
	WHEN 'd' THEN nvl(ovw_validity_dtm, ia.audit_dtm + re_audit_due_after)
	WHEN 'w' THEN nvl(ovw_validity_dtm, ia.audit_dtm + (re_audit_due_after*7))
	WHEN 'm' THEN nvl(ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, re_audit_due_after))
	WHEN 'y' THEN nvl(ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, re_audit_due_after*12))
END next_audit_due_dtm, act.reminder_offset_days, act.label closure_label,
act.is_failure, ia.label previous_audit_label, act.icon_image_filename,
ia.auditor_user_sid previous_auditor_user_sid, ia.flow_item_id
  FROM csr.internal_audit ia
  JOIN csr.audit_closure_type act 
	ON ia.audit_closure_type_id = act.audit_closure_type_id
   AND ia.app_sid = act.app_sid
   AND ia.audit_closure_type_id IS NOT NULL
   AND ia.deleted = 0; 
   
   
CREATE OR REPLACE VIEW csr.v$quick_survey_answer AS
	SELECT qsa.app_sid, qsa.survey_response_id, qsa.question_id, qsa.note, qsa.score, qsa.question_option_id,
		   qsa.val_number, qsa.measure_conversion_id, qsa.measure_sid, qsa.region_sid, qsa.answer,
		   qsa.html_display, qsa.max_score, qsa.version_stamp, qsa.submission_id, qsa.survey_version, qsq.lookup_key
	  FROM quick_survey_answer qsa
	  JOIN v$quick_survey_response qsr ON qsa.survey_response_id = qsr.survey_response_id AND qsa.submission_id = qsr.submission_id
	  JOIN quick_survey_question qsq ON qsa.question_id = qsq.question_id;   
	  
--- CORNING / ENHESA

@../quick_survey_pkg
@../quick_survey_body

@../audit_pkg
@../audit_body

@update_tail
