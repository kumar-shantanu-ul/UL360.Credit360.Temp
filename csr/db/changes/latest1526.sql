-- Please update version.sql too -- this keeps clean builds in sync
define version=1526
@update_header

CREATE OR REPLACE VIEW csr.v$audit_next_due AS
	SELECT ia.internal_audit_sid, ia.internal_audit_type_id, ia.region_sid,
		   ia.audit_dtm previous_audit_dtm, act.audit_closure_type_id, ia.app_sid,
		   CASE (re_audit_due_after_type)
				WHEN 'd' THEN ia.audit_dtm + re_audit_due_after
				WHEN 'w' THEN ia.audit_dtm + (re_audit_due_after*7)
				WHEN 'm' THEN ADD_MONTHS(ia.audit_dtm, re_audit_due_after)
				WHEN 'y' THEN ADD_MONTHS(ia.audit_dtm, re_audit_due_after*12)
		   END next_audit_due_dtm, act.reminder_offset_days, act.label closure_label,
		   ia.label previous_audit_label, act.icon_image_filename,
		   ia.auditor_user_sid previous_auditor_user_sid
	  FROM (
		SELECT internal_audit_sid, internal_audit_type_id, region_sid, audit_dtm,
			   ROW_NUMBER() OVER (
					PARTITION BY internal_audit_type_id, region_sid
					ORDER BY audit_dtm DESC) rn, -- take most recent audit of each type/region
			   audit_closure_type_id, app_sid, label, auditor_user_sid
		  FROM internal_audit
	       ) ia
	  JOIN audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id
	   AND ia.app_sid = act.app_sid
	  JOIN region r ON ia.region_sid = r.region_sid AND ia.app_sid = r.app_sid
	 WHERE rn = 1
	   AND act.re_audit_due_after IS NOT NULL
	   AND r.active=1
	   AND ia.audit_closure_type_id IS NOT NULL;

CREATE OR REPLACE VIEW csr.v$audit AS
	SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label, 
		   ia.auditor_user_sid, ca.full_name auditor_full_name, sr.submitted_dtm survey_completed, 
		   NVL(nc.cnt, 0) open_non_compliances, ia.survey_sid, ia.auditor_name, ia.auditor_organisation,
		   r.region_type, rt.class_name region_type_class_name, SUBSTR(ia.notes, 1, 50) short_notes,
		   iat.internal_audit_type_id audit_type_id, iat.label audit_type_label, qs.label survey_label,
		   ia.app_sid, ia.internal_audit_type_id, iat.auditor_role_sid, iat.audit_contact_role_sid,
		   ia.audit_closure_type_id, act.label closure_label, act.icon_image_filename
	  FROM internal_audit ia
	  JOIN csr_user ca ON ia.auditor_user_sid = ca.csr_user_sid AND ia.app_sid = ca.app_sid
	  LEFT JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id
	  LEFT JOIN quick_survey qs ON ia.survey_sid = qs.survey_sid AND ia.app_sid = qs.app_sid
	  LEFT JOIN (
			SELECT anc.app_sid, anc.internal_audit_sid, COUNT(DISTINCT anc.non_compliance_id) cnt
			  FROM audit_non_compliance anc
			  JOIN issue_non_compliance inc ON anc.non_compliance_id = inc.non_compliance_id AND anc.app_sid = inc.app_sid
			  JOIN issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id AND inc.app_sid = i.app_sid
			 WHERE i.resolved_dtm IS NULL
			 GROUP BY anc.app_sid, anc.internal_audit_sid
			) nc ON ia.internal_audit_sid = nc.internal_audit_sid AND ia.app_sid = nc.app_sid
	  LEFT JOIN v$quick_survey_response sr ON ia.survey_response_id = sr.survey_response_id AND ia.app_sid = sr.app_sid
	  JOIN v$region r ON ia.region_sid = r.region_sid
	  JOIN region_type rt ON r.region_type = rt.region_type
	  LEFT JOIN audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id AND ia.app_sid = act.app_sid;

BEGIN
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1032,'Audits','Credit360.Portlets.Audits', EMPTY_CLOB(),'/csr/site/portal/portlets/audits.js');
EXCEPTION WHEN dup_val_on_index THEN NULL;
END;
/

BEGIN
INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.AUDITS', 'show', 'STRING', 'Audits portlet');
INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.AUDITS', 'internalAuditTypeId', 'NUMBER', 'Audits portlet');
INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.AUDITS', 'myAuditsOnly', 'BOOLEAN', 'Audits portlet');
EXCEPTION WHEN dup_val_on_index THEN NULL;
END;
/

@..\audit_pkg

@..\audit_body
@..\user_setting_body

@update_tail
