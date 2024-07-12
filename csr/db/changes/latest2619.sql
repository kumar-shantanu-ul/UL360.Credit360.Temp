-- Please update version.sql too -- this keeps clean builds in sync
define version=2619
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE chain.aggregate_type (
	card_group_id			NUMBER(10) NOT NULL,
	aggregate_type_id		NUMBER(10) NOT NULL,
	description				VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_aggregate_type PRIMARY KEY (card_group_id, aggregate_type_id)
);

CREATE TABLE chain.card_group_column_type (
	card_group_id			NUMBER(10) NOT NULL,
	column_id				NUMBER(10) NOT NULL,
	column_type				NUMBER(10) NOT NULL,
	description				VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_card_group_column_type PRIMARY KEY (card_group_id, column_id)
);

CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_FILTER_VALUE_MAP (
	OLD_FILTER_VALUE_ID NUMBER(10),
	NEW_FILTER_VALUE_ID NUMBER(10)
) ON COMMIT DELETE ROWS;

-- Alter tables
ALTER TABLE chain.filter_value ADD (
	saved_filter_sid_value			NUMBER(10),
	CONSTRAINT fk_filter_value_saved_filter FOREIGN KEY (app_sid, saved_filter_sid_value)
		REFERENCES chain.saved_filter (app_sid, saved_filter_sid)
);

ALTER TABLE csrimp.chain_filter_value ADD (
	saved_filter_sid_value			NUMBER(10)
);

ALTER TABLE chain.card_group ADD (
	helper_pkg						VARCHAR2(255)
);

ALTER TABLE chain.card_group ADD (
	list_page_url					VARCHAR2(255)
);

ALTER TABLE chain.aggregate_type ADD CONSTRAINT fk_aggregate_type_card_group
	FOREIGN KEY (card_group_id) REFERENCES chain.card_group (card_group_id);

ALTER TABLE chain.card_group_column_type ADD CONSTRAINT fk_card_group_column_type_cg
	FOREIGN KEY (card_group_id) REFERENCES chain.card_group (card_group_id);
	
ALTER TABLE chain.saved_filter ADD (
	group_key						VARCHAR2(255)
);	

ALTER TABLE csrimp.chain_saved_filter ADD (
	group_key						VARCHAR2(255)
);

ALTER TABLE chain.saved_filter ADD (
	region_column_id				NUMBER(10),
	date_column_id					NUMBER(10),
	CONSTRAINT fk_saved_fltr_region_column_id FOREIGN KEY (card_group_id, region_column_id) 
		REFERENCES chain.card_group_column_type (card_group_id, column_id),
	CONSTRAINT fk_saved_fltr_date_column_id FOREIGN KEY (card_group_id, date_column_id) 
		REFERENCES chain.card_group_column_type (card_group_id, column_id)
);	

ALTER TABLE csrimp.chain_saved_filter ADD (
	region_column_id				NUMBER(10),
	date_column_id					NUMBER(10)
);

ALTER TABLE csr.tpl_report_tag_dataview ADD (
	saved_filter_sid				NUMBER(10),
	filter_result_mode				NUMBER(10),
	aggregate_type_id				NUMBER(10),
	CONSTRAINT chk_report_fields_set CHECK ((dataview_sid IS NOT NULL AND saved_filter_sid IS NULL) OR (dataview_sid IS NULL AND saved_filter_sid IS NOT NULL)),
	CONSTRAINT chk_filter_report_fields_set CHECK (saved_filter_sid IS NULL OR filter_result_mode IS NOT NULL),
	CONSTRAINT chk_filter_result_mode CHECK (filter_result_mode IN (2, 3, 4)),
	CONSTRAINT fk_tpl_rprt_tag_dv_saved_fltr FOREIGN KEY (app_sid, saved_filter_sid)
		REFERENCES chain.saved_filter (app_sid, saved_filter_sid)
);

ALTER TABLE csr.tpl_report_tag_dataview MODIFY dataview_sid NULL;

ALTER TABLE csrimp.tpl_report_tag_dataview ADD (
	saved_filter_sid				NUMBER(10),
	filter_result_mode				NUMBER(10),
	aggregate_type_id				NUMBER(10),
	CONSTRAINT chk_report_fields_set CHECK ((dataview_sid IS NOT NULL AND saved_filter_sid IS NULL) OR (dataview_sid IS NULL AND saved_filter_sid IS NOT NULL)),
	CONSTRAINT chk_filter_report_fields_set CHECK (saved_filter_sid IS NULL OR filter_result_mode IS NOT NULL),
	CONSTRAINT chk_filter_result_mode CHECK (filter_result_mode IN (2, 3, 4))
);

ALTER TABLE csrimp.tpl_report_tag_dataview MODIFY dataview_sid NULL;
	

-- *** Grants ***
GRANT SELECT, INSERT, UPDATE, DELETE ON csr.temp_region_sid TO chain;

-- ** Cross schema constraints ***

-- *** Views ***
CREATE OR REPLACE VIEW chain.v$filter_value AS
       SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, fv.filter_value_id, fv.str_value,
		   fv.num_value, fv.min_num_val, fv.max_num_val, fv.start_dtm_value, fv.end_dtm_value, fv.region_sid, fv.user_sid,
		   fv.compound_filter_id_value, fv.saved_filter_sid_value,
		   NVL(NVL(fv.description, CASE fv.user_sid WHEN -1 THEN 'Me' WHEN -2 THEN 'My roles' WHEN -3 THEN 'My staff' ELSE
		   NVL(NVL(r.description, cu.full_name), cr.name) END), fv.str_value) description, ff.group_by_index,
		   f.compound_filter_id
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id
	  JOIN filter_value fv ON ff.app_sid = fv.app_sid AND ff.filter_field_id = fv.filter_field_id
	  LEFT JOIN csr.v$region r ON fv.region_sid = r.region_sid AND fv.app_sid = r.app_sid
	  LEFT JOIN csr.csr_user cu ON fv.user_sid = cu.csr_user_sid AND fv.app_sid = cu.app_sid
	  LEFT JOIN csr.role cr ON fv.user_sid = cr.role_sid AND fv.app_sid = cr.app_sid;

CREATE OR REPLACE VIEW csr.v$audit AS
	SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label,
		   NVL2(ia.internal_audit_ref, atg.internal_audit_ref_prefix || ia.internal_audit_ref, null) custom_audit_id,
		   atg.internal_audit_ref_prefix, ia.internal_audit_ref, ia.ovw_validity_dtm,
		   ia.auditor_user_sid, ca.full_name auditor_full_name, sr.submitted_dtm survey_completed,
		   NVL(nc.cnt, 0) open_non_compliances, ia.survey_sid, ia.auditor_name, ia.auditor_organisation,
		   r.region_type, rt.class_name region_type_class_name,
		   SUBSTR(ia.notes, 1, 50) short_notes, ia.notes full_notes,
		   iat.internal_audit_type_id audit_type_id, iat.label audit_type_label, iat.interactive audit_type_interactive,
		   qs.label survey_label, ia.app_sid, ia.internal_audit_type_id, iat.auditor_role_sid,
		   iat.audit_contact_role_sid, ia.audit_closure_type_id, act.label closure_label, act.icon_image_filename,
		   ia.created_by_user_sid, ia.survey_response_id, ia.created_dtm, ca.email auditor_email,
		   iat.filename template_filename, iat.assign_issues_to_role, iat.add_nc_per_question, cvru.user_giving_cover_sid cover_auditor_sid,
		   fi.flow_sid, f.label flow_label, ia.flow_item_id, fi.current_state_id, fs.label flow_state_label, fs.is_final flow_state_is_final,
		   iat.summary_survey_sid, sqs.label summary_survey_label, ia.summary_response_id, act.is_failure,
		   ia.auditor_company_sid, ac.name auditor_company_name, iat.tab_sid, iat.form_path, ia.comparison_response_id, iat.nc_audit_child_region,
		   atg.label int_audit_type_group_label, atg.internal_audit_type_group_id, atg.group_coordinator_noun,
		   sr.overall_score survey_overall_score, sr.overall_max_score survey_overall_max_score,
		   sst.score_type_id survey_score_type_id, sst.label survey_score_label, sst.format_mask survey_score_format_mask,
		   ia.nc_score, iat.nc_score_type_id, NVL(ia.ovw_nc_score_thrsh_id, ia.nc_score_thrsh_id) nc_score_thrsh_id, ncst.max_score nc_max_score, ncst.label nc_score_label, ncst.format_mask nc_score_format_mask
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
	  JOIN csr.csr_user ca ON NVL(cvru.user_giving_cover_sid , ia.auditor_user_sid) = ca.csr_user_sid AND ia.app_sid = ca.app_sid
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
	  JOIN csr.v$region r ON ia.app_sid = r.app_sid AND ia.region_sid = r.region_sid
	  JOIN csr.region_type rt ON r.region_type = rt.region_type
	  LEFT JOIN csr.audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id AND ia.app_sid = act.app_sid
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

BEGIN
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (23/*chain.filter_pkg.FILTER_TYPE_COMPANIES*/, 1/*chain.company_filter_pkg.SUPPLIER_COUNT*/, 'Number of suppliers');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (25/*chain.filter_pkg.FILTER_TYPE_ISSUES*/, 1/*csr.issue_report_pkg.AGG_TYPE_COUNT*/, 'Number of actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (25/*chain.filter_pkg.FILTER_TYPE_ISSUES*/, 2/*csr.issue_report_pkg.AGG_TYPE_DAYS_OPEN*/, 'Total days open');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (25/*chain.filter_pkg.FILTER_TYPE_ISSUES*/, 3/*csr.issue_report_pkg.AGG_TYPE_DAYS_OVERDUE*/, 'Total days overdue');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (25/*chain.filter_pkg.FILTER_TYPE_ISSUES*/, 4/*csr.issue_report_pkg.AGG_TYPE_AVG_DAYS_OPEN*/, 'Average days open');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (25/*chain.filter_pkg.FILTER_TYPE_ISSUES*/, 5/*csr.issue_report_pkg.AGG_TYPE_AVG_DAYS_OVRDUE*/, 'Average days overdue');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (41/*chain.filter_pkg.FILTER_TYPE_AUDITS*/, 1/*csr.audit_report_pkg.AGG_TYPE_COUNT*/, 'Number of audits');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (42/*chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES*/, 1/*csr.non_compliance_report_pkg.AGG_TYPE_COUNT*/, 'Number of findings');
END;
/

BEGIN
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (23/*chain.filter_pkg.FILTER_TYPE_COMPANIES*/, 1/*chain.company_filter_pkg.COL_TYPE_SUPPLIER_REGION*/, 1/*chain.filter_pkg.COLUMN_TYPE_REGION*/, 'Supplier region');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (25/*chain.filter_pkg.FILTER_TYPE_ISSUES*/, 1/*csr.issue_report_pkg.COL_TYPE_REGION_SID*/, 1/*chain.filter_pkg.COLUMN_TYPE_REGION*/, 'Action region');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (25/*chain.filter_pkg.FILTER_TYPE_ISSUES*/, 2/*csr.issue_report_pkg.COL_TYPE_RAISED_DTM*/, 2/*chain.filter_pkg.COLUMN_TYPE_DATE*/, 'Raised date');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (25/*chain.filter_pkg.FILTER_TYPE_ISSUES*/, 3/*csr.issue_report_pkg.COL_TYPE_RESOLVED_DTM*/, 2/*chain.filter_pkg.COLUMN_TYPE_DATE*/, 'Resolved date');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (25/*chain.filter_pkg.FILTER_TYPE_ISSUES*/, 4/*csr.issue_report_pkg.COL_TYPE_DUE_DTM*/, 2/*chain.filter_pkg.COLUMN_TYPE_DATE*/, 'Due date');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (25/*chain.filter_pkg.FILTER_TYPE_ISSUES*/, 5/*csr.issue_report_pkg.COL_TYPE_FORECAST_DTM*/, 2/*chain.filter_pkg.COLUMN_TYPE_DATE*/, 'Forecast date');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (41/*chain.filter_pkg.FILTER_TYPE_AUDITS*/, 1/*csr.audit_report_pkg.COL_TYPE_REGION_SID*/, 1/*chain.filter_pkg.COLUMN_TYPE_REGION*/, 'Audit region');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (41/*chain.filter_pkg.FILTER_TYPE_AUDITS*/, 2/*csr.audit_report_pkg.COL_TYPE_AUDIT_DTM*/, 2/*chain.filter_pkg.COLUMN_TYPE_DATE*/, 'Audit date');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (42/*chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES*/, 1/*csr.non_compliance_report_pkg.COL_TYPE_REGION_SID*/, 1/*chain.filter_pkg.COLUMN_TYPE_REGION*/, 'Finding region');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (42/*chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES*/, 2/*csr.non_compliance_report_pkg.COL_TYPE_AUDIT_DTM*/, 2/*chain.filter_pkg.COLUMN_TYPE_DATE*/, 'Audit date');
END;
/

-- new aggregate types
BEGIN
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (41/*chain.filter_pkg.FILTER_TYPE_AUDITS*/, 2/*csr.audit_report_pkg.AGG_TYPE_COUNT_NON_COMP*/, 'Number of findings');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (41/*chain.filter_pkg.FILTER_TYPE_AUDITS*/, 3/*csr.audit_report_pkg.AGG_TYPE_COUNT_OPEN_NON_COMP*/, 'Number of open findings');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (41/*chain.filter_pkg.FILTER_TYPE_AUDITS*/, 4/*csr.audit_report_pkg.AGG_TYPE_COUNT_ISSUES*/, 'Number of actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (41/*chain.filter_pkg.FILTER_TYPE_AUDITS*/, 5/*csr.audit_report_pkg.AGG_TYPE_COUNT_OPEN_ISSUES*/, 'Number of open actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (41/*chain.filter_pkg.FILTER_TYPE_AUDITS*/, 6/*csr.audit_report_pkg.AGG_TYPE_COUNT_OVRD_ISSUES*/, 'Number of overdue actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (42/*chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES*/, 4/*csr.non_compliance_report_pkg.AGG_TYPE_COUNT_ISSUES*/, 'Number of actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (42/*chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES*/, 5/*csr.non_compliance_report_pkg.AGG_TYPE_COUNT_OPEN_ISSUES*/, 'Number of open actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (42/*chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES*/, 6/*csr.non_compliance_report_pkg.AGG_TYPE_COUNT_OVRD_ISSUES*/, 'Number of overdue actions');
END;
/

BEGIN
	UPDATE chain.card_group
	   SET helper_pkg='chain.company_filter_pkg'
	 WHERE card_group_id = 23;
	
	UPDATE chain.card_group
	   SET helper_pkg='csr.issue_report_pkg'
	 WHERE card_group_id = 25;
	
	UPDATE chain.card_group
	   SET helper_pkg='csr.audit_report_pkg'
	 WHERE card_group_id = 41;
	
	UPDATE chain.card_group
	   SET helper_pkg='csr.non_compliance_report_pkg'
	 WHERE card_group_id = 42;
END;
/

BEGIN
	UPDATE chain.card_group
	   SET list_page_url='/csr/site/chain/filterSuppliers.acds?reportMode=1&'||'sid='
	 WHERE card_group_id = 23;
	
	UPDATE chain.card_group
	   SET list_page_url='/csr/site/issues/issueList.acds?reportMode=1&'||'savedFilterSid='
	 WHERE card_group_id = 25;
	
	UPDATE chain.card_group
	   SET list_page_url='/csr/site/audit/auditList.acds?savedFilterSid='
	 WHERE card_group_id = 41;
	
	UPDATE chain.card_group
	   SET list_page_url='/csr/site/audit/nonComplianceList.acds?savedFilterSid='
	 WHERE card_group_id = 42;
END;
/

BEGIN
	UPDATE chain.saved_filter
	   SET region_column_id = 1
	 WHERE card_group_id = 23;

	UPDATE chain.saved_filter
	   SET region_column_id = 1,
		   date_column_id = 2
	 WHERE card_group_id = 25;

	UPDATE chain.saved_filter
	   SET region_column_id = 1,
		   date_column_id = 2
	 WHERE card_group_id = 41;

	UPDATE chain.saved_filter
	   SET region_column_id = 1,
		   date_column_id = 2
	 WHERE card_group_id = 42;
END;
/

-- ** New package grants **

-- *** Packages ***
@..\chain\filter_pkg
@..\chain\card_pkg
@..\chain\company_filter_pkg
@..\audit_pkg
@..\issue_report_pkg
@..\audit_report_pkg
@..\non_compliance_report_pkg
@..\templated_report_pkg

@..\chain\card_body
@..\chain\filter_body
@..\chain\company_filter_body
@..\audit_body
@..\issue_report_body
@..\audit_report_body
@..\non_compliance_report_body
@..\schema_body
@..\templated_report_body
@..\csrimp\imp_body
@..\ct\setup_body

@update_tail
