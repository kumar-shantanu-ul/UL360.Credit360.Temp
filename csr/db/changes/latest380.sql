-- Please update version.sql too -- this keeps clean builds in sync
define version=380
@update_header

CREATE SEQUENCE ISSUE_NON_COMPLIANCE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE OR REPLACE VIEW v$issue AS
	SELECT i.app_sid, i.issue_id, i.label, note, i.source_label,
		   raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
		   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
		   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
		   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
		   sysdate now_dtm, due_dtm, ist.issue_type_Id, ist.label issue_type_label,
		   issue_pending_val_id, issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id,
		   CASE 
			WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND SYSDATE > due_dtm THEN 1
			ELSE 0 
		   END is_overdue
	  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user cuass
	 WHERE i.app_sid = curai.app_sid AND i.raised_by_user_sid = curai.csr_user_sid
	   AND i.app_sid = ist.app_sid AND i.issue_type_Id = ist.issue_type_id
	   AND i.app_sid = cures.app_sid(+) AND i.resolved_by_user_sid = cures.csr_user_sid(+) 
	   AND i.app_sid = cuclo.app_sid(+) AND i.closed_by_user_sid = cuclo.csr_user_sid(+)
	   AND i.app_sid = cuass.app_sid(+) AND i.assigned_to_user_sid = cuass.csr_user_sid(+);

@..\audit_pkg
@..\issue_pkg
@..\audit_body
@..\issue_body

@update_tail
