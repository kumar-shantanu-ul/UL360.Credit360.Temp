-- Please update version.sql too -- this keeps clean builds in sync
define version=2989
define minor_version=34
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.INTERNAL_AUDIT_TYPE_REPORT (
	APP_SID 						NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	INTERNAL_AUDIT_TYPE_ID 			NUMBER(10) NOT NULL,
	INTERNAL_AUDIT_TYPE_REPORT_ID 	NUMBER(10) NOT NULL,
	WORD_DOC						BLOB NOT NULL,
	REPORT_FILENAME					VARCHAR(255) NOT NULL,
	LABEL 							VARCHAR(255) NOT NULL,
	CONSTRAINT PK_AUDIT_TYPE_REPORT PRIMARY KEY (APP_SID, INTERNAL_AUDIT_TYPE_REPORT_ID),
	CONSTRAINT UK_AUDIT_TYPE_REPORT_LABEL UNIQUE (APP_SID, INTERNAL_AUDIT_TYPE_ID, LABEL),
	CONSTRAINT FK_AUDIT_TYPE_ID FOREIGN KEY (APP_SID, INTERNAL_AUDIT_TYPE_ID) REFERENCES CSR.INTERNAL_AUDIT_TYPE (APP_SID, INTERNAL_AUDIT_TYPE_ID)
);

CREATE SEQUENCE CSR.INTERNAL_AUDIT_TYPE_REPORT_SEQ CACHE 5;

CREATE TABLE CSRIMP.INTERNAL_AUDIT_TYPE_REPORT (
    CSRIMP_SESSION_ID               NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    INTERNAL_AUDIT_TYPE_ID          NUMBER(10) NOT NULL,
    INTERNAL_AUDIT_TYPE_REPORT_ID   NUMBER(10) NOT NULL,
    WORD_DOC                        BLOB NOT NULL,
    REPORT_FILENAME                 VARCHAR(255) NOT NULL,
    LABEL 							VARCHAR(255) NOT NULL,
    CONSTRAINT PK_AUDIT_TYPE_REPORT PRIMARY KEY (CSRIMP_SESSION_ID, INTERNAL_AUDIT_TYPE_REPORT_ID),
    CONSTRAINT UK_AUDIT_TYPE_REPORT_LABEL UNIQUE (CSRIMP_SESSION_ID, INTERNAL_AUDIT_TYPE_ID, LABEL),
    CONSTRAINT FK_INTERNAL_AUDIT_TYPE_REP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_INTERNAL_AUDIT_TYPE_REPORT (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_INTERNAL_AUDIT_TYPE_REP_ID		NUMBER(10)	NOT NULL,
	NEW_INTERNAL_AUDIT_TYPE_REP_ID		NUMBER(10)	NOT NULL,
	CONSTRAINT PK_MAP_INTERNAL_AUDIT_TYPE_REP PRIMARY KEY (CSRIMP_SESSION_ID, OLD_INTERNAL_AUDIT_TYPE_REP_ID) USING INDEX,
	CONSTRAINT UK_MAP_INTERNAL_AUDIT_TYPE_REP UNIQUE (CSRIMP_SESSION_ID, NEW_INTERNAL_AUDIT_TYPE_REP_ID) USING INDEX,
	CONSTRAINT FK_MAP_INTENAL_AUDIT_TYPE_REP FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);

-- Alter tables
BEGIN
	security.user_pkg.logonadmin();

	INSERT INTO csr.internal_audit_type_report(app_sid, internal_audit_type_report_id, internal_audit_type_id, word_doc, report_filename, label)
		 SELECT app_sid, csr.internal_audit_type_report_seq.nextval, internal_audit_type_id, word_doc, filename, 'Report'
		   FROM csr.internal_audit_type
		  WHERE filename IS NOT NULL;
 END;
 /

ALTER TABLE CSR.INTERNAL_AUDIT_TYPE DROP COLUMN WORD_DOC;
ALTER TABLE CSR.INTERNAL_AUDIT_TYPE DROP COLUMN FILENAME;

ALTER TABLE CSRIMP.INTERNAL_AUDIT_TYPE DROP COLUMN WORD_DOC;
ALTER TABLE CSRIMP.INTERNAL_AUDIT_TYPE DROP COLUMN FILENAME;

-- *** Grants ***
GRANT INSERT ON csr.internal_audit_type_report TO CSRIMP;
GRANT SELECT ON csr.internal_audit_type_report_seq TO CSRIMP;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
-- csr\db\create_views.sql changed v$audit, removed filename
CREATE OR REPLACE VIEW csr.v$audit AS
	SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label,
		   NVL2(ia.internal_audit_ref, atg.internal_audit_ref_prefix || ia.internal_audit_ref, null) custom_audit_id,
		   atg.internal_audit_ref_prefix, ia.internal_audit_ref, ia.ovw_validity_dtm,
		   ia.auditor_user_sid, NVL(cu.full_name, au.full_name) auditor_full_name, sr.submitted_dtm survey_completed,
		   NVL(nc.cnt, 0) open_non_compliances, ia.survey_sid, ia.auditor_name, ia.auditor_organisation,
		   r.region_type, r.geo_longitude longitude, r.geo_latitude latitude, rt.class_name region_type_class_name,
		   ia.auditee_user_sid, u.full_name auditee_full_name, u.email auditee_email,
		   SUBSTR(ia.notes, 1, 50) short_notes, ia.notes full_notes,
		   iat.internal_audit_type_id audit_type_id, iat.label audit_type_label, iat.interactive audit_type_interactive,
		   qs.label survey_label, ia.app_sid, ia.internal_audit_type_id, iat.auditor_role_sid,
		   iat.audit_contact_role_sid, ia.audit_closure_type_id, act.label closure_label, act.icon_image_filename, cast(act.icon_image_sha1  as varchar2(40)) icon_image_sha1,
		   ia.created_by_user_sid, ia.survey_response_id, ia.created_dtm, NVL(cu.email, au.email) auditor_email,
		   iat.assign_issues_to_role, iat.add_nc_per_question, cvru.user_giving_cover_sid cover_auditor_sid,
		   fi.flow_sid, f.label flow_label, ia.flow_item_id, fi.current_state_id, fs.label flow_state_label, fs.is_final flow_state_is_final, 
		   fs.state_colour flow_state_colour, act.is_failure,
		   sqs.survey_sid summary_survey_sid, sqs.label summary_survey_label, ssr.survey_version summary_survey_version, ia.summary_response_id,
		   ia.auditor_company_sid, ac.name auditor_company_name, iat.tab_sid, iat.form_path, ia.comparison_response_id, iat.nc_audit_child_region,
		   atg.label ia_type_group_label, atg.lookup_key ia_type_group_lookup_key, atg.internal_audit_type_group_id, iat.form_sid,
		   atg.audit_singular_label, atg.audit_plural_label, atg.auditee_user_label, atg.auditor_user_label, atg.auditor_name_label,
		   sr.overall_score survey_overall_score, sr.overall_max_score survey_overall_max_score, sr.survey_version,
		   sst.score_type_id survey_score_type_id, sr.score_threshold_id survey_score_thrsh_id, sst.label survey_score_label, sst.format_mask survey_score_format_mask,
		   ia.nc_score, iat.nc_score_type_id, NVL(ia.ovw_nc_score_thrsh_id, ia.nc_score_thrsh_id) nc_score_thrsh_id, ncst.max_score nc_max_score, ncst.label nc_score_label,
		   ncst.format_mask nc_score_format_mask,
		   CASE (atct.re_audit_due_after_type)
				WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
				WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
				WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
				WHEN 'y' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after*12))
				ELSE ia.ovw_validity_dtm END next_audit_due_dtm
	  FROM csr.internal_audit ia
	  LEFT JOIN (
			SELECT auc.app_sid, auc.internal_audit_sid, auc.user_giving_cover_sid,
				   ROW_NUMBER() OVER (PARTITION BY auc.internal_audit_sid ORDER BY LEVEL DESC, uc.start_dtm DESC,  uc.user_cover_id DESC) rn,
				   CONNECT_BY_ROOT auc.user_being_covered_sid user_being_covered_sid
			  FROM csr.audit_user_cover auc
			  JOIN csr.user_cover uc ON auc.app_sid = uc.app_sid AND auc.user_cover_id = uc.user_cover_id
			 CONNECT BY NOCYCLE PRIOR auc.app_sid = auc.app_sid AND PRIOR auc.user_being_covered_sid = auc.user_giving_cover_sid
		) cvru
	    ON ia.internal_audit_sid = cvru.internal_audit_sid
	   AND ia.app_sid = cvru.app_sid AND ia.auditor_user_sid = cvru.user_being_covered_sid
	   AND cvru.rn = 1
	  LEFT JOIN csr.csr_user u ON ia.auditee_user_sid = u.csr_user_sid AND ia.app_sid = u.app_sid
	  JOIN csr.csr_user au ON ia.auditor_user_sid = au.csr_user_sid AND ia.app_sid = au.app_sid
	  LEFT JOIN csr.csr_user cu ON cvru.user_giving_cover_sid = cu.csr_user_sid AND cvru.app_sid = cu.app_sid
	  LEFT JOIN csr.internal_audit_type iat ON ia.app_sid = iat.app_sid AND ia.internal_audit_type_id = iat.internal_audit_type_id
	  LEFT JOIN csr.internal_audit_type_group atg ON atg.app_sid = iat.app_sid AND atg.internal_audit_type_group_id = iat.internal_audit_type_group_id
	  LEFT JOIN csr.v$quick_survey_response sr ON ia.survey_response_id = sr.survey_response_id AND ia.app_sid = sr.app_sid
	  LEFT JOIN csr.v$quick_survey_response ssr ON ia.summary_response_id = ssr.survey_response_id AND ia.app_sid = sr.app_sid
	  LEFT JOIN csr.v$quick_survey qs ON ia.survey_sid = qs.survey_sid AND ia.app_sid = qs.app_sid
	  LEFT JOIN csr.v$quick_survey sqs ON NVL(ssr.survey_sid, iat.summary_survey_sid) = sqs.survey_sid AND iat.app_sid = sqs.app_sid
	  LEFT JOIN (
			SELECT anc.app_sid, anc.internal_audit_sid, COUNT(DISTINCT anc.non_compliance_id) cnt
			  FROM csr.audit_non_compliance anc
			  JOIN csr.non_compliance nnc ON anc.non_compliance_id = nnc.non_compliance_id AND anc.app_sid = nnc.app_sid
			  LEFT JOIN csr.issue_non_compliance inc ON nnc.non_compliance_id = inc.non_compliance_id AND nnc.app_sid = inc.app_sid
			  LEFT JOIN csr.issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id AND inc.app_sid = i.app_sid
			 WHERE ((nnc.is_closed IS NULL
			   AND i.resolved_dtm IS NULL
			   AND i.rejected_dtm IS NULL
			   AND i.deleted = 0)
			    OR nnc.is_closed = 0)
			 GROUP BY anc.app_sid, anc.internal_audit_sid
			) nc ON ia.internal_audit_sid = nc.internal_audit_sid AND ia.app_sid = nc.app_sid
	  LEFT JOIN csr.v$region r ON ia.app_sid = r.app_sid AND ia.region_sid = r.region_sid
	  LEFT JOIN csr.region_type rt ON r.region_type = rt.region_type
	  LEFT JOIN csr.audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id AND ia.app_sid = act.app_sid
	  LEFT JOIN csr.audit_type_closure_type atct ON ia.audit_closure_type_id = atct.audit_closure_type_id AND ia.internal_audit_type_id = atct.internal_audit_type_id AND ia.app_sid = atct.app_sid
	  LEFT JOIN csr.flow_item fi
	    ON ia.app_sid = fi.app_sid AND ia.flow_item_id = fi.flow_item_id
	  LEFT JOIN csr.flow_state fs
	    ON fs.app_sid = fi.app_sid AND fs.flow_state_id = fi.current_state_id
	  LEFT JOIN csr.flow f
	    ON f.app_sid = fi.app_sid AND f.flow_sid = fi.flow_sid
	  LEFT JOIN chain.company ac
	    ON ia.auditor_company_sid = ac.company_sid AND ia.app_sid = ac.app_sid
	  LEFT JOIN score_type ncst ON ncst.app_sid = iat.app_sid AND ncst.score_type_id = iat.nc_score_type_id
	  LEFT JOIN score_type sst ON sst.app_sid = qs.app_sid AND sst.score_type_id = qs.score_type_id
	 WHERE ia.deleted = 0;


-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../audit_pkg
@../schema_pkg

@../audit_body
@../schema_body
@../csrimp/imp_body

@update_tail
