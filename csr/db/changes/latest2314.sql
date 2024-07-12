-- Please update version.sql too -- this keeps clean builds in sync
define version=2314
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.qs_campaign ADD (
	send_to_column_sid			NUMBER(10),
	region_column_sid			NUMBER(10)
);

ALTER TABLE csr.qs_campaign ADD (
	created_by_sid				NUMBER(10)
);

ALTER TABLE csrimp.qs_campaign ADD (
	send_to_column_sid			NUMBER(10),
	region_column_sid			NUMBER(10)
);

ALTER TABLE csrimp.qs_campaign ADD (
	created_by_sid				NUMBER(10)
);

ALTER TABLE csr.internal_audit_type ADD (
	tab_sid						NUMBER(10),
	form_path					VARCHAR2(255),
	CONSTRAINT fk_int_audit_type_cms_tab FOREIGN KEY (app_sid, tab_sid)
		REFERENCES cms.tab(app_sid, tab_sid),
	CONSTRAINT chk_ia_type_cms_tab_form CHECK ((tab_sid IS NULL AND form_path IS NULL) OR (tab_sid IS NOT NULL AND form_path IS NOT NULL))
);

ALTER TABLE csrimp.internal_audit_type ADD (
	tab_sid						NUMBER(10),
	form_path					VARCHAR2(255),
	CONSTRAINT chk_ia_type_cms_tab_form CHECK ((tab_sid IS NULL AND form_path IS NULL) OR (tab_sid IS NOT NULL AND form_path IS NOT NULL))
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
CREATE OR REPLACE VIEW csr.v$audit AS
	SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label, 
		   ia.auditor_user_sid, ca.full_name auditor_full_name, sr.submitted_dtm survey_completed, 
		   NVL(nc.cnt, 0) open_non_compliances, ia.survey_sid, ia.auditor_name, ia.auditor_organisation,
		   r.region_type, rt.class_name region_type_class_name, SUBSTR(ia.notes, 1, 50) short_notes,
		   ia.notes full_notes, iat.internal_audit_type_id audit_type_id, iat.label audit_type_label,
		   qs.label survey_label, ia.app_sid, ia.internal_audit_type_id, iat.auditor_role_sid,
		   iat.audit_contact_role_sid, ia.audit_closure_type_id, act.label closure_label, act.icon_image_filename,
		   ia.created_by_user_sid, ia.survey_response_id, ia.created_dtm, ca.email auditor_email,
		   iat.filename as template_filename, iat.assign_issues_to_role, iat.add_nc_per_question, cvru.user_giving_cover_sid cover_auditor_sid,
		   fi.flow_sid, f.label flow_label, ia.flow_item_id, fi.current_state_id, fs.label flow_state_label,
		   iat.summary_survey_sid, sqs.label summary_survey_label, ia.summary_response_id, act.is_failure,
		   ia.auditor_company_sid, ac.name auditor_company_name, iat.tab_sid, iat.form_path
	  FROM internal_audit ia
	  LEFT JOIN (
			SELECT auc.app_sid, auc.internal_audit_sid, auc.user_giving_cover_sid,
				   ROW_NUMBER() OVER (PARTITION BY auc.internal_audit_sid ORDER BY LEVEL DESC, uc.start_dtm DESC,  uc.user_cover_id DESC) rn,
				   CONNECT_BY_ROOT auc.user_being_covered_sid user_being_covered_sid
			  FROM audit_user_cover auc
			  JOIN user_cover uc ON auc.user_cover_id = uc.user_cover_id
			 CONNECT BY NOCYCLE PRIOR auc.user_being_covered_sid = auc.user_giving_cover_sid
		) cvru
	    ON ia.internal_audit_sid = cvru.internal_audit_sid
	   AND ia.app_sid = cvru.app_sid AND ia.auditor_user_sid = cvru.user_being_covered_sid
	   AND cvru.rn = 1
	  JOIN csr_user ca ON NVL(cvru.user_giving_cover_sid , ia.auditor_user_sid) = ca.csr_user_sid AND ia.app_sid = ca.app_sid
	  LEFT JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id
	  LEFT JOIN v$quick_survey qs ON ia.survey_sid = qs.survey_sid AND ia.app_sid = qs.app_sid
	  LEFT JOIN v$quick_survey sqs ON iat.summary_survey_sid = sqs.survey_sid AND iat.app_sid = sqs.app_sid
	  LEFT JOIN (
			SELECT anc.app_sid, anc.internal_audit_sid, COUNT(DISTINCT anc.non_compliance_id) cnt
			  FROM audit_non_compliance anc
			  JOIN issue_non_compliance inc ON anc.non_compliance_id = inc.non_compliance_id AND anc.app_sid = inc.app_sid
			  JOIN issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id AND inc.app_sid = i.app_sid
			 WHERE i.resolved_dtm IS NULL
			   AND i.rejected_dtm IS NULL
			   AND i.deleted = 0
			 GROUP BY anc.app_sid, anc.internal_audit_sid
			) nc ON ia.internal_audit_sid = nc.internal_audit_sid AND ia.app_sid = nc.app_sid
	  LEFT JOIN v$quick_survey_response sr ON ia.survey_response_id = sr.survey_response_id AND ia.app_sid = sr.app_sid
	  JOIN v$region r ON ia.region_sid = r.region_sid
	  JOIN region_type rt ON r.region_type = rt.region_type
	  LEFT JOIN audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id AND ia.app_sid = act.app_sid
	  LEFT JOIN flow_item fi
	    ON ia.flow_item_id = fi.flow_item_id
	  LEFT JOIN flow_state fs
	    ON fs.flow_state_id = fi.current_state_id
	  LEFT JOIN flow f
	    ON f.flow_sid = fi.flow_sid
	  LEFT JOIN chain.company ac
	    ON ia.auditor_company_sid = ac.company_sid AND ia.app_sid = ac.app_sid
	 WHERE ia.deleted = 0;
-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.qs_campaign x SET (send_to_column_sid, region_column_sid) = (
	SELECT tc.column_sid, rtc.column_sid
	  FROM csr.qs_campaign c
	  JOIN cms.tab t ON c.table_sid = t.tab_sid AND c.app_sid = t.app_sid
	  JOIN cms.tab_column tc ON t.tab_sid = tc.tab_sid AND t.app_sid = tc.app_sid
	  LEFT JOIN cms.tab_column rtc ON t.tab_sid = rtc.tab_sid AND t.app_sid = rtc.app_sid AND rtc.col_type = 9 -- col_type=region
	 WHERE tc.oracle_column='EMAIL'
	   AND c.qs_campaign_sid = x.qs_campaign_sid
	   AND c.app_sid = x.app_sid
	)
 WHERE x.audience_type='LF'
   AND x.send_to_column_sid IS NULL;

  
insert into cms.col_type values (35, 'Internal Audit');
   
-- ** New package grants **

-- *** Packages ***
@..\campaign_pkg
@..\audit_pkg
@..\..\..\aspen2\cms\db\tab_pkg

@..\campaign_body
@..\audit_body
@..\alert_body
@..\schema_body
@..\plugin_body
@..\csrimp\imp_body
@..\..\..\aspen2\cms\db\tab_body

@update_tail
