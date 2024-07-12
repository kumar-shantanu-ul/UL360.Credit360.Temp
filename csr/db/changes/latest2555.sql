-- Please update version.sql too -- this keeps clean builds in sync
define version=2555
@update_header

-- *** DDL ***
-- Create tables
-- Alter tables

ALTER TABLE csr.score_type ADD (
	applies_to_surveys			NUMBER(1, 0),
	applies_to_non_compliances	NUMBER(1, 0),
	CONSTRAINT ck_score_type_appl2surv CHECK (applies_to_surveys in (0, 1)),
	CONSTRAINT ck_score_type_appl2ncs CHECK (applies_to_non_compliances in (0, 1))
);
UPDATE csr.score_type SET applies_to_surveys = 1 WHERE applies_to_surveys IS NULL 
   AND score_type_id IN ( SELECT score_type_id FROM csr.quick_survey );
UPDATE csr.score_type SET applies_to_surveys = 0 WHERE applies_to_surveys IS NULL;
ALTER TABLE csr.score_type MODIFY (
	applies_to_surveys			DEFAULT 0 NOT NULL
);
UPDATE csr.score_type SET applies_to_non_compliances = 0 WHERE applies_to_non_compliances IS NULL;
ALTER TABLE csr.score_type MODIFY (
	applies_to_non_compliances	DEFAULT 0 NOT NULL
);
ALTER TABLE csr.score_type ADD (
	min_score				NUMBER(15, 5),
	max_score				NUMBER(15, 5),
	start_score				NUMBER(15, 5)
);
UPDATE csr.score_type SET start_score = 0 WHERE start_score IS NULL;
ALTER TABLE csr.score_type MODIFY (
	start_score				DEFAULT 0 NOT NULL
);
ALTER TABLE csr.score_type ADD (
	normalise_to_max_score	NUMBER(1, 0),
	CONSTRAINT ck_score_type_norm2ms CHECK (normalise_to_max_score in (0, 1))
);
-- Current survey behaviour is to normalise
UPDATE csr.score_type SET normalise_to_max_score = 1 WHERE applies_to_surveys = 1 AND normalise_to_max_score IS NULL;
UPDATE csr.score_type SET normalise_to_max_score = 0 WHERE normalise_to_max_score IS NULL;
ALTER TABLE csr.score_type MODIFY (
	normalise_to_max_score	DEFAULT 0 NOT NULL
);

ALTER TABLE csrimp.score_type ADD (
	applies_to_surveys			NUMBER(1, 0),
	applies_to_non_compliances	NUMBER(1, 0)
);
ALTER TABLE csrimp.score_type ADD (
	min_score				NUMBER(15, 5),
	max_score				NUMBER(15, 5),
	start_score				NUMBER(15, 5)
);
ALTER TABLE csrimp.score_type ADD (
	normalise_to_max_score	NUMBER(1, 0)
);

ALTER TABLE csr.internal_audit_type ADD (
	nc_score_type_id			NUMBER(10, 0),
	CONSTRAINT fk_ia_type_nc_score_type FOREIGN KEY(app_sid, nc_score_type_id) REFERENCES csr.score_type(app_sid, score_type_id)
);
ALTER TABLE csrimp.internal_audit_type ADD (
	nc_score_type_id			NUMBER(10, 0)
);

ALTER TABLE csr.non_compliance_type ADD (
	score					NUMBER(15, 5),
	repeat_score			NUMBER(15, 5)
);
ALTER TABLE csrimp.non_compliance_type ADD (
	score					NUMBER(15, 5),
	repeat_score			NUMBER(15, 5)
);

ALTER TABLE csr.non_compliance ADD (
	override_score			NUMBER(15, 5)
);
ALTER TABLE csrimp.non_compliance ADD (
	override_score			NUMBER(15, 5)
);

ALTER TABLE csr.internal_audit ADD (
	nc_score				NUMBER(15, 5)
);
ALTER TABLE csrimp.internal_audit ADD (
	nc_score				NUMBER(15, 5)
);

ALTER TABLE csr.non_comp_default ADD (
	non_compliance_type_id	NUMBER(10),
	CONSTRAINT fk_non_comp_def_non_comp_type FOREIGN KEY (app_sid, non_compliance_type_id) 
		REFERENCES csr.non_compliance_type (app_sid, non_compliance_type_id)
);

ALTER TABLE csr.qs_expr_non_compl_action ADD (
	non_compliance_type_id NUMBER(10),
	CONSTRAINT fk_qs_ex_nc_act_non_comp_type FOREIGN KEY (app_sid, non_compliance_type_id) 
		REFERENCES csr.non_compliance_type (app_sid, non_compliance_type_id)
);

ALTER TABLE csrimp.non_comp_default ADD (
	non_compliance_type_id	NUMBER(10)
);

ALTER TABLE csrimp.qs_expr_non_compl_action ADD (
	non_compliance_type_id	NUMBER(10)
);

ALTER TABLE csr.non_compliance ADD (
	question_option_id		NUMBER(10),
	CONSTRAINT chk_non_compl_option_has_q CHECK (question_option_id IS NULL OR question_id IS NOT NULL)
);
ALTER TABLE csrimp.non_compliance ADD (
	question_id				NUMBER(10),
	question_option_id		NUMBER(10)
);

CREATE UNIQUE INDEX csr.uk_non_compliance_option_id ON csr.non_compliance (
	CASE WHEN question_option_id IS NULL THEN NULL ELSE app_sid END,
	CASE WHEN question_option_id IS NULL THEN NULL ELSE created_in_audit_sid END,
	CASE WHEN question_option_id IS NULL THEN NULL ELSE question_id END,
	question_option_id
);

ALTER TABLE csr.qs_question_option ADD (
	non_compliance_popup		NUMBER(1),
	non_comp_default_id			NUMBER(10),
	non_compliance_type_id		NUMBER(10),
	non_compliance_label		VARCHAR2(255),
	non_compliance_detail		VARCHAR2(4000),
	CONSTRAINT chk_non_comp_popup_0_1 CHECK (non_compliance_popup IN (0,1)),
	CONSTRAINT fk_qsq_option_def_non_comp FOREIGN KEY (app_sid, non_comp_default_id)
		REFERENCES csr.non_comp_default (app_sid, non_comp_default_id),
	CONSTRAINT fk_qsq_option_non_comp_typ FOREIGN KEY (app_sid, non_compliance_type_id)
		REFERENCES csr.non_compliance_type (app_sid, non_compliance_type_id)
);

CREATE INDEX csr.ix_qsq_option_def_non_comp ON csr.qs_question_option (app_sid, non_comp_default_id);
CREATE INDEX csr.ix_qsq_option_non_comp_typ ON csr.qs_question_option (app_sid, non_compliance_type_id);

CREATE TABLE csr.qs_question_option_nc_tag (
	app_sid						NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	question_id					NUMBER(10) NOT NULL,
	question_option_id			NUMBER(10) NOT NULL,
	survey_version				NUMBER(10) NOT NULL,
	tag_id						NUMBER(10) NOT NULL,
	CONSTRAINT pk_qs_question_option_nc_tag
		PRIMARY KEY (app_sid, question_id, question_option_id, survey_version, tag_id),
	CONSTRAINT fk_qsq_opt_tag_option FOREIGN KEY (app_sid, question_id, question_option_id, survey_version)
		REFERENCES csr.qs_question_option (app_sid, question_id, question_option_id, survey_version),
	CONSTRAINT fk_qsq_opt_tag_tag FOREIGN KEY (app_sid, tag_id)
		REFERENCES csr.tag(app_sid, tag_id)
);

CREATE INDEX csr.ix_qsq_opt_tag_option ON csr.qs_question_option_nc_tag (app_sid, question_id, question_option_id, survey_version);
CREATE INDEX csr.ix_qsq_opt_tag_tag ON csr.qs_question_option_nc_tag (app_sid, tag_id);

ALTER TABLE csrimp.qs_question_option ADD (
	non_compliance_popup		NUMBER(1),
	non_comp_default_id			NUMBER(10),
	non_compliance_type_id		NUMBER(10),
	non_compliance_label		VARCHAR2(255),
	non_compliance_detail		VARCHAR2(4000),
	CONSTRAINT chk_non_comp_popup_0_1 CHECK (non_compliance_popup IN (0,1))
);

CREATE TABLE csrimp.qs_question_option_nc_tag (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	question_id					NUMBER(10) NOT NULL,
	question_option_id			NUMBER(10) NOT NULL,
	survey_version				NUMBER(10) NOT NULL,
	tag_id						NUMBER(10) NOT NULL,
	CONSTRAINT pk_qs_question_option_nc_tag
		PRIMARY KEY (CSRIMP_SESSION_ID, question_id, question_option_id, survey_version, tag_id),
	CONSTRAINT FK_qs_qstn_option_nc_tag_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

ALTER TABLE csr.temp_question_option ADD (
	non_compliance_popup		NUMBER(1),
	non_comp_default_id			NUMBER(10),
	non_compliance_type_id		NUMBER(10),
	non_compliance_label		VARCHAR2(255),
	non_compliance_detail		VARCHAR2(4000)
);

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_QUESTION_OPTION_NC_TAG (
	QUESTION_ID				NUMBER(10),
	QUESTION_OPTION_ID		NUMBER(10),
	TAG_ID					NUMBER(10)
) ON COMMIT DELETE ROWS;

-- *** Types ***
DROP TYPE CSR.T_QS_QUESTION_OPTION_TABLE;


-- *** Grants ***
grant select,insert,update,delete on csrimp.qs_question_option_nc_tag to web_user;
grant insert on csr.qs_question_option_nc_tag to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***

CREATE OR REPLACE VIEW csr.v$quick_survey AS
	SELECT qs.app_sid, qs.survey_sid, d.label draft_survey_label, l.label live_survey_label,
		   NVL(l.label, d.label) label, qs.audience, qs.created_dtm, qs.auditing_audit_type_id,
		   CASE WHEN l.survey_sid IS NOT NULL THEN 1 ELSE 0 END survey_is_published,
		   CASE WHEN qs.last_modified_dtm > l.published_dtm THEN 1 ELSE 0 END survey_has_unpublished_changes,
		   qs.score_type_id
	  FROM csr.quick_survey qs
	  JOIN csr.quick_survey_version d ON qs.survey_sid = d.survey_sid
	  LEFT JOIN csr.quick_survey_version l ON qs.survey_sid = l.survey_sid AND qs.current_version = l.survey_version
	 WHERE d.survey_version = 0;

CREATE OR REPLACE VIEW csr.v$audit AS
	SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label,
		   NVL2(ia.internal_audit_ref, atg.internal_audit_ref_prefix || ia.internal_audit_ref, null) custom_audit_id,
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
		   ia.auditor_company_sid, ac.name auditor_company_name, iat.tab_sid, iat.form_path, ia.comparison_response_id, iat.nc_audit_child_region,
		   atg.label int_audit_type_group_label, atg.internal_audit_type_group_id,
		   sr.overall_score survey_overall_score, sr.overall_max_score survey_overall_max_score,
		   sst.score_type_id survey_score_type_id, sst.label survey_score_label, sst.format_mask survey_score_format_mask,
		   ia.nc_score, iat.nc_score_type_id, ncst.max_score nc_max_score, ncst.label nc_score_label, ncst.format_mask nc_score_format_mask
	  FROM csr.internal_audit ia
	  LEFT JOIN (
			SELECT auc.app_sid, auc.internal_audit_sid, auc.user_giving_cover_sid,
				   ROW_NUMBER() OVER (PARTITION BY auc.internal_audit_sid ORDER BY LEVEL DESC, uc.start_dtm DESC,  uc.user_cover_id DESC) rn,
				   CONNECT_BY_ROOT auc.user_being_covered_sid user_being_covered_sid
			  FROM csr.audit_user_cover auc
			  JOIN csr.user_cover uc ON auc.user_cover_id = uc.user_cover_id
			 CONNECT BY NOCYCLE PRIOR auc.user_being_covered_sid = auc.user_giving_cover_sid
		) cvru
	    ON ia.internal_audit_sid = cvru.internal_audit_sid
	   AND ia.app_sid = cvru.app_sid AND ia.auditor_user_sid = cvru.user_being_covered_sid
	   AND cvru.rn = 1
	  JOIN csr.csr_user ca ON NVL(cvru.user_giving_cover_sid , ia.auditor_user_sid) = ca.csr_user_sid AND ia.app_sid = ca.app_sid
	  LEFT JOIN csr.internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id
	  LEFT JOIN csr.internal_audit_type_group atg ON atg.internal_audit_type_group_id = iat.internal_audit_type_group_id
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
	  JOIN csr.v$region r ON ia.region_sid = r.region_sid
	  JOIN csr.region_type rt ON r.region_type = rt.region_type
	  LEFT JOIN csr.audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id AND ia.app_sid = act.app_sid
	  LEFT JOIN csr.flow_item fi
	    ON ia.flow_item_id = fi.flow_item_id
	  LEFT JOIN csr.flow_state fs
	    ON fs.flow_state_id = fi.current_state_id
	  LEFT JOIN csr.flow f
	    ON f.flow_sid = fi.flow_sid
	  LEFT JOIN chain.company ac
	    ON ia.auditor_company_sid = ac.company_sid AND ia.app_sid = ac.app_sid
	  LEFT JOIN score_type ncst ON ncst.score_type_id = iat.nc_score_type_id
	  LEFT JOIN score_type sst ON sst.score_type_id = qs.score_type_id
	 WHERE ia.deleted = 0;

-- *** Data changes ***

CREATE OR REPLACE FUNCTION csr.Temp_SetCorePlugin(
	in_plugin_type_id				IN 	csr.plugin.plugin_type_id%TYPE,
	in_js_class						IN  csr.plugin.js_class%TYPE,
	in_description					IN  csr.plugin.description%TYPE,
	in_js_include					IN  csr.plugin.js_include%TYPE,
	in_cs_class						IN  csr.plugin.cs_class%TYPE DEFAULT 'Credit360.Plugins.PluginDto',
	in_details						IN  csr.plugin.details%TYPE DEFAULT NULL,
	in_preview_image_path			IN  csr.plugin.preview_image_path%TYPE DEFAULT NULL,
	in_tab_sid						IN  csr.plugin.tab_sid%TYPE DEFAULT NULL,
	in_form_path					IN  csr.plugin.form_path%TYPE DEFAULT NULL
) RETURN plugin.plugin_id%TYPE
AS
	v_plugin_id		csr.plugin.plugin_id%TYPE;
BEGIN
	BEGIN
		INSERT INTO plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
							details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, plugin_id_seq.nextval, in_plugin_type_id, in_description,  in_js_include, in_js_class, 
					 in_cs_class, in_details, in_preview_image_path, in_tab_sid, in_form_path)
		  RETURNING plugin_id INTO v_plugin_id;
	EXCEPTION WHEN dup_val_on_index THEN
		UPDATE plugin 
		   SET description = in_description,
			   js_include = in_js_include,
			   cs_class = in_cs_class,
			   details = in_details,
			   preview_image_path = in_preview_image_path,
			   form_path = in_form_path
		 WHERE plugin_type_id = in_plugin_type_id
		   AND js_class = in_js_class
		   AND app_sid IS NULL
		   AND ((tab_sid IS NULL AND in_tab_sid IS NULL) OR (tab_sid = in_tab_sid))
			   RETURNING plugin_id INTO v_plugin_id;
	END;

	RETURN v_plugin_id;
END;
/

DECLARE
	v_plugin_id     csr.plugin.plugin_id%TYPE;
begin
	v_plugin_id := csr.temp_SetCorePlugin (
		in_plugin_type_id		=> 13, --csr.csr_data_pkg.PLUGIN_TYPE_AUDIT_TAB,
		in_js_class				=> 'Audit.Controls.NcScoreSummaryTab',
		in_description			=> 'Finding score summary',
		in_js_include			=> '/csr/site/audit/controls/NcScoreSummaryTab.js',
		in_cs_class				=> 'Credit360.Audit.Plugins.NcScoreSummaryTab',
		in_details				=> 'Summarises the findings score for the audit, broken down by finding type'
	);
end;
/

DROP FUNCTION csr.Temp_SetCorePlugin;

INSERT INTO CSR.QS_QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('noncompliances', 'Ad-hoc audit findings', null);

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		  JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner IN ('CSRIMP') AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'CSRIMP_SESSION_ID'
		   AND t.table_name IN ('QS_QUESTION_OPTION_NC_TAG')
 	)
 	LOOP
		dbms_output.put_line('Writing policy '||r.policy_name);
		dbms_rls.add_policy(
			object_schema   => r.owner,
			object_name     => r.table_name,
			policy_name     => r.policy_name, 
			function_schema => 'CSRIMP',
			policy_function => 'SessionIDCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.context_sensitive);
	END LOOP;
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		DBMS_OUTPUT.PUT_LINE('Policy exists');
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');
END;
/


-- ** New package grants **
grant execute on csr.utils_pkg to csrimp;
grant execute on csr.stragg to csrimp;

-- *** Packages ***
@../audit_pkg
@../quick_survey_pkg
@../schema_pkg

@../audit_body
@../quick_survey_body
@../schema_body
@../csrimp/imp_body
@../region_event_body
@../csr_app_body
@../unit_test_body

@update_tail
