-- Please update version.sql too -- this keeps clean builds in sync
define version=2904
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.internal_audit_type_group ADD (
	applies_to_regions		NUMBER(1, 0),
	applies_to_users		NUMBER(1, 0),
	use_user_primary_region	NUMBER(1, 0)
);

UPDATE csr.internal_audit_type_group
   SET applies_to_regions = NVL(applies_to_regions, 1),
	   applies_to_users = NVL(applies_to_users, 0),
	   use_user_primary_region = NVL(use_user_primary_region, 0);

ALTER TABLE csr.internal_audit_type_group MODIFY (
	applies_to_regions		DEFAULT 1 NOT NULL,
	applies_to_users		DEFAULT 0 NOT NULL,
	use_user_primary_region DEFAULT 0 NOT NULL
);

ALTER TABLE csr.internal_audit_type_group ADD (
	CONSTRAINT ck_iatg_appl_to_regions CHECK (applies_to_regions IN (0,1)),
	CONSTRAINT ck_iatg_appl_to_users CHECK (applies_to_users IN (0,1)),
	CONSTRAINT ck_iatg_must_appl_to_sthng CHECK (applies_to_regions = 1 OR applies_to_users = 1),
	CONSTRAINT ck_iatg_use_usr_pri_reg CHECK (use_user_primary_region = 0 OR (use_user_primary_region = 1 AND applies_to_regions = 0 AND applies_to_users = 1))
);

ALTER TABLE csr.internal_audit_type_group ADD (
	audit_singular_label	VARCHAR2(100),
	audit_plural_label		VARCHAR2(100),
	auditee_user_label		VARCHAR2(100),
	auditor_user_label		VARCHAR2(100)
);
ALTER TABLE csr.internal_audit_type_group RENAME COLUMN group_coordinator_noun TO auditor_name_label;

UPDATE csr.internal_audit_type_group
   SET audit_singular_label = NVL(audit_singular_label, label),
	   audit_plural_label = NVL(audit_plural_label, label);

ALTER TABLE csr.internal_audit MODIFY (
	region_sid				NULL
);

ALTER TABLE csr.internal_audit ADD (
	auditee_user_sid		NUMBER(10, 0),
	CONSTRAINT ck_ia_must_appl_to_sthng CHECK (region_sid IS NOT NULL OR auditee_user_sid IS NOT NULL)
);

ALTER TABLE csr.csr_user ADD (
	primary_region_sid		NUMBER(10, 0),
	CONSTRAINT fk_primary_region_sid FOREIGN KEY (app_sid, primary_region_sid) REFERENCES csr.region(app_sid, region_sid)
);

ALTER TABLE csr.customer ADD (
	audits_on_users NUMBER(1)
);
UPDATE csr.customer SET audits_on_users = 0 WHERE audits_on_users IS NULL;
ALTER TABLE csr.customer MODIFY (
	audits_on_users DEFAULT 0 NOT NULL
);
ALTER TABLE csr.customer ADD (
	CONSTRAINT ck_audits_on_users CHECK (audits_on_users IN (0, 1))
);

ALTER TABLE chain.filter_page_column ADD (
	group_key			VARCHAR2(255)
);
DROP INDEX chain.uk_filter_table_column;
CREATE UNIQUE INDEX chain.uk_filter_table_column ON chain.filter_page_column(app_sid, card_group_id, column_name, company_tab_id, LOWER(group_key));

ALTER TABLE csrimp.internal_audit_type_group ADD (
	applies_to_regions		NUMBER(1, 0),
	applies_to_users		NUMBER(1, 0),
	use_user_primary_region	NUMBER(1, 0),
	audit_singular_label	VARCHAR2(100),
	audit_plural_label		VARCHAR2(100),
	auditee_user_label		VARCHAR2(100),
	auditor_user_label		VARCHAR2(100)
);
ALTER TABLE csrimp.internal_audit_type_group RENAME COLUMN group_coordinator_noun TO auditor_name_label;

ALTER TABLE csrimp.internal_audit MODIFY (
	region_sid				NULL
);
ALTER TABLE csrimp.internal_audit ADD (
	auditee_user_sid		NUMBER(10, 0)
);

ALTER TABLE csrimp.csr_user ADD (
	primary_region_sid		NUMBER(10, 0)
);

ALTER TABLE csrimp.customer ADD (
	audits_on_users			NUMBER(1)
);

ALTER TABLE csrimp.chain_filter_page_column ADD (
	group_key			VARCHAR2(255)
);
DROP INDEX csrimp.uk_filter_table_column;
CREATE UNIQUE INDEX csrimp.uk_filter_table_column ON csrimp.chain_filter_page_column(csrimp_session_id, card_group_id, column_name, company_tab_id, LOWER(group_key));


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- from csr/db/create_views.sql
CREATE OR REPLACE VIEW csr.v$csr_user AS
	SELECT cu.app_sid, cu.csr_user_sid, cu.email, cu.full_name, cu.user_name, cu.send_alerts,
		   cu.guid, cu.friendly_name, cu.info_xml, cu.show_portal_help, cu.donations_browse_filter_id, cu.donations_reports_filter_id,
		   cu.hidden, cu.phone_number, cu.job_title, ut.account_enabled active, ut.last_logon, cu.created_dtm, ut.expiration_dtm, 
		   ut.language, ut.culture, ut.timezone, so.parent_sid_id, cu.last_modified_dtm, cu.last_logon_type_Id, cu.line_manager_sid, cu.primary_region_sid
      FROM csr_user cu, security.securable_object so, security.user_table ut, customer c
     WHERE cu.app_sid = c.app_sid
       AND cu.csr_user_sid = so.sid_id
       AND so.parent_sid_id != c.trash_sid
       AND ut.sid_id = so.sid_id
       AND cu.hidden = 0;
	   
-- from csr/db/create_views.sql
CREATE OR REPLACE VIEW csr.v$audit AS
	SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label,
		   NVL2(ia.internal_audit_ref, atg.internal_audit_ref_prefix || ia.internal_audit_ref, null) custom_audit_id,
		   atg.internal_audit_ref_prefix, ia.internal_audit_ref, ia.ovw_validity_dtm,
		   ia.auditor_user_sid, NVL(cu.full_name, au.full_name) auditor_full_name, sr.submitted_dtm survey_completed,
		   NVL(nc.cnt, 0) open_non_compliances, ia.survey_sid, ia.auditor_name, ia.auditor_organisation,
		   r.region_type, rt.class_name region_type_class_name,
		   ia.auditee_user_sid, u.full_name auditee_full_name, u.email auditee_email,
		   SUBSTR(ia.notes, 1, 50) short_notes, ia.notes full_notes,
		   iat.internal_audit_type_id audit_type_id, iat.label audit_type_label, iat.interactive audit_type_interactive,
		   qs.label survey_label, ia.app_sid, ia.internal_audit_type_id, iat.auditor_role_sid,
		   iat.audit_contact_role_sid, ia.audit_closure_type_id, act.label closure_label, act.icon_image_filename,
		   ia.created_by_user_sid, ia.survey_response_id, ia.created_dtm, NVL(cu.email, au.email) auditor_email,
		   iat.filename template_filename, iat.assign_issues_to_role, iat.add_nc_per_question, cvru.user_giving_cover_sid cover_auditor_sid,
		   fi.flow_sid, f.label flow_label, ia.flow_item_id, fi.current_state_id, fs.label flow_state_label, fs.is_final flow_state_is_final,
		   iat.summary_survey_sid, sqs.label summary_survey_label, ia.summary_response_id, act.is_failure,
		   ia.auditor_company_sid, ac.name auditor_company_name, iat.tab_sid, iat.form_path, ia.comparison_response_id, iat.nc_audit_child_region,
		   atg.label ia_type_group_label, atg.lookup_key ia_type_group_lookup_key, atg.internal_audit_type_group_id, 
		   atg.audit_singular_label, atg.audit_plural_label, atg.auditee_user_label, atg.auditor_user_label, atg.auditor_name_label,
		   sr.overall_score survey_overall_score, sr.overall_max_score survey_overall_max_score,
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
	  LEFT JOIN csr.v$quick_survey qs ON ia.survey_sid = qs.survey_sid AND ia.app_sid = qs.app_sid
	  LEFT JOIN csr.v$quick_survey sqs ON iat.summary_survey_sid = sqs.survey_sid AND iat.app_sid = sqs.app_sid
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
	  LEFT JOIN csr.v$quick_survey_response sr ON ia.survey_response_id = sr.survey_response_id AND ia.app_sid = sr.app_sid
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
INSERT INTO CSR.CAPABILITY (NAME,ALLOW_BY_DEFAULT) VALUES ('Edit user primary region',0);

INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
	VALUES (20, 'audit', 'Auditee', 0, 1);
	
-- if you need to change the module ID here please also change it in basedata.sql
INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (63, 'Audits on users', 'EnableAuditsOnUsers', 'Enables audits on users.', 1);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../audit_pkg
@../audit_report_pkg
@../csr_data_pkg
@../csr_user_pkg
@../enable_pkg
@../non_compliance_report_pkg
@../chain/filter_pkg

@../audit_body
@../audit_report_body
@../csr_data_body
@../csr_user_body
@../customer_body
@../enable_body
@../flow_body
@../non_compliance_report_body
@../region_body
@../schema_body
@../csrimp/imp_body
@../chain/filter_body
@../chain/company_user_body

@update_tail
