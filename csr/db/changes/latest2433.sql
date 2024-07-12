-- Please update version.sql too -- this keeps clean builds in sync
define version=2433
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.filter_field ADD (
	GROUP_BY_INDEX     NUMBER(1),
	SHOW_ALL           NUMBER(1),
	CONSTRAINT CHK_FLTR_FLD_SHO_ALL_0_1 CHECK (SHOW_ALL IN (0,1))
);

DELETE FROM chain.filter
 WHERE filter_id IN (
	SELECT f.filter_id
	  FROM chain.filter f
	  JOIN (
		SELECT compound_filter_id, filter_type_id, MAX(filter_id) max_filter_id
		  FROM chain.filter
		 GROUP BY compound_filter_id, filter_type_id
		) k
		ON f.compound_filter_id = k.compound_filter_id
	   AND f.filter_type_id = k.filter_type_id
	   AND f.filter_id < k.max_filter_id
	);

ALTER TABLE chain.filter ADD (
	CONSTRAINT UK_FILTER_CMP_FIL_TYP UNIQUE (COMPOUND_FILTER_ID, FILTER_TYPE_ID)
);

ALTER TABLE CSR.QUICK_SURVEY ADD (
	AUDITING_AUDIT_TYPE_ID			NUMBER(10),
	CONSTRAINT FK_QS_AUD_AUD_TYPE FOREIGN KEY (APP_SID, AUDITING_AUDIT_TYPE_ID) REFERENCES CSR.INTERNAL_AUDIT_TYPE (APP_SID, INTERNAL_AUDIT_TYPE_ID)
);

CREATE INDEX CSR.IX_QS_AUD_AUD_TYPE ON CSR.QUICK_SURVEY (APP_SID, AUDITING_AUDIT_TYPE_ID);

ALTER TABLE csr.score_type ADD (
	FORMAT_MASK			VARCHAR(20) DEFAULT ('#,##0.0%') NOT NULL
);

ALTER TABLE csr.qs_campaign ADD (
	filter_xml					CLOB,
	response_column_sid			NUMBER(10),
	tag_lookup_key_column_sid	NUMBER(10),
	is_system_generated			NUMBER(10) DEFAULT 0 NOT NULL,
	customer_alert_type_id		NUMBER(10),
	CONSTRAINT fk_qs_campaign_alert_type_id FOREIGN KEY (app_sid, customer_alert_type_id) REFERENCES csr.customer_alert_type (app_sid, customer_alert_type_id)
);

CREATE INDEX csr.ix_qs_campaign_alert_type_id ON csr.qs_campaign(app_sid, customer_alert_type_id);


-- *** Types ***
CREATE OR REPLACE TYPE CHAIN.T_FILTERED_OBJECT_ROW AS 
	 OBJECT ( 
		OBJECT_ID					NUMBER(10),
		GROUP_BY_1					NUMBER(10),
		GROUP_BY_2					NUMBER(10),
		GROUP_BY_3					NUMBER(10),
		GROUP_BY_4					NUMBER(10),
		CONSTRUCTOR FUNCTION T_FILTERED_OBJECT_ROW (
			in_object_id	NUMBER
		)
		RETURN SELF AS RESULT
	 ); 
/

CREATE OR REPLACE TYPE BODY chain.T_FILTERED_OBJECT_ROW IS
	CONSTRUCTOR FUNCTION T_FILTERED_OBJECT_ROW (
		in_object_id	NUMBER
	)
	RETURN SELF AS RESULT
	IS
	BEGIN
		object_id := in_object_id;
		RETURN;
	END;
END;
/

CREATE OR REPLACE TYPE CHAIN.T_FILTERED_OBJECT_TABLE AS 
	TABLE OF CHAIN.T_FILTERED_OBJECT_ROW;
/

-- *** Grants ***
GRANT EXECUTE ON CHAIN.T_FILTERED_OBJECT_TABLE TO CSR;
GRANT EXECUTE ON CHAIN.T_FILTERED_OBJECT_ROW TO CSR;
grant select on CHAIN.filter_value_id_seq to CSR;

-- ** Cross schema constraints ***

-- *** Views ***

CREATE OR REPLACE VIEW CHAIN.v$filter_field AS
	SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, ff.show_all, ff.group_by_index,
		   f.compound_filter_id
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id;

CREATE OR REPLACE VIEW chain.v$filter_value AS
       SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, fv.filter_value_id, fv.str_value,
		   fv.num_value, Fv.Min_Num_Val, Fv.Max_Num_Val, fv.start_dtm_value, fv.end_dtm_value, fv.region_sid, fv.user_sid,
		   NVL(NVL(fv.description, CASE fv.user_sid WHEN -1 THEN 'Me' WHEN -2 THEN 'My roles' WHEN -3 THEN 'My staff' ELSE
		   NVL(NVL(r.description, cu.full_name), cr.name) END), fv.str_value) description, ff.group_by_index,
		   f.compound_filter_id
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id
	  JOIN filter_value fv ON ff.app_sid = fv.app_sid AND ff.filter_field_id = fv.filter_field_id
	  LEFT JOIN csr.v$region r ON fv.region_sid = r.region_sid AND fv.app_sid = r.app_sid
	  LEFT JOIN csr.csr_user cu ON fv.user_sid = cu.csr_user_sid AND fv.app_sid = cu.app_sid
	  LEFT JOIN csr.role cr ON fv.user_sid = cr.role_sid AND fv.app_sid = cr.app_sid;

CREATE OR REPLACE VIEW csr.v$quick_survey AS
	SELECT qs.app_sid, qs.survey_sid, d.label draft_survey_label, l.label live_survey_label,
		   NVL(l.label, d.label) label, qs.audience, qs.created_dtm, qs.auditing_audit_type_id,
		   CASE WHEN l.survey_sid IS NOT NULL THEN 1 ELSE 0 END survey_is_published,
		   CASE WHEN qs.last_modified_dtm > l.published_dtm THEN 1 ELSE 0 END survey_has_unpublished_changes
	  FROM csr.quick_survey qs
	  JOIN csr.quick_survey_version d ON qs.survey_sid = d.survey_sid
	  LEFT JOIN csr.quick_survey_version l ON qs.survey_sid = l.survey_sid AND qs.current_version = l.survey_version
	 WHERE d.survey_version = 0;

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
		   ia.auditor_company_sid, ac.name auditor_company_name, iat.tab_sid, iat.form_path, ia.comparison_response_id
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

CREATE OR REPLACE VIEW csr.v$supplier_score AS
	SELECT css.app_sid, css.company_sid, css.score_type_id, css.last_supplier_score_id,
		   ss.score, ss.set_dtm score_last_changed, ss.score_threshold_id,
		   st.description score_threshold_description, t.label score_type_label, t.pos,
		   t.format_mask
	  FROM csr.current_supplier_score css
	  JOIN csr.supplier_score_log ss ON css.company_sid = css.company_sid AND css.last_supplier_score_id = ss.supplier_score_id
	  LEFT JOIN csr.score_threshold st ON ss.score_threshold_id = st.score_threshold_id
	  JOIN csr.score_type t ON css.score_type_id = t.score_type_id;

-- *** Data changes ***


-- RLS

-- Data

UPDATE chain.filter_type
   SET helper_pkg = 'csr.issue_report_pkg'
 WHERE LOWER(helper_pkg) = 'csr.issue_pkg';



CREATE OR REPLACE PROCEDURE chain.temp_RegisterCapability (
	in_capability_type			IN  NUMBER,
	in_capability				IN  VARCHAR2,
	in_perm_type				IN  NUMBER,
	in_is_supplier				IN  NUMBER
)
AS
	v_count						NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;

	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND (
				(capability_type_id = 0 /*chain_pkg.CT_COMMON*/ AND (in_capability_type = 1 /*chain_pkg.CT_COMPANY*/ OR in_capability_type = 2 /*chain_pkg.CT_SUPPLIERS*/))
			 OR (in_capability_type = 0 /*chain_pkg.CT_COMMON*/ AND (capability_type_id = 1 /*chain_pkg.CT_COMPANY*/ OR capability_type_id = 2 /*chain_pkg.CT_SUPPLIERS*/))
		   );

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;

	INSERT INTO capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type, in_is_supplier);

END;
/

-- New chain capabilities
BEGIN
	security.user_pkg.logonadmin;
	
	BEGIN
		-- chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.AUDIT_QUESTIONNAIRE_RESPONSES, chain.chain_pkg.BOOLEAN_PERMISSION);	
		chain.temp_RegisterCapability(2 /*chain_pkg.CT_SUPPLIERS*/, 'Audit questionnaire responses', 1, 1);
	END;
END;
/

DROP PROCEDURE chain.temp_RegisterCapability;

-- ** New package grants **

create or replace package csr.issue_report_pkg as end;
/
grant execute on csr.issue_report_pkg to chain;
grant execute on csr.issue_report_pkg to web_user;


-- *** Packages ***

@..\issue_pkg
@..\issue_report_pkg
@..\chain\filter_pkg
@..\chain\chain_pkg
@..\chain\company_filter_pkg
@..\chain\product_pkg
@..\chain\company_pkg
@..\chain\company_type_pkg
@..\chain\report_pkg
@..\chain\chain_link_pkg
@..\chain\helper_pkg
@..\supplier_pkg
@..\audit_pkg
@..\quick_survey_pkg
@..\campaign_pkg

@..\issue_body
@..\audit_body
@..\chain\filter_body
@..\chain\company_filter_body
@..\chain\questionnaire_body
@..\chain\product_body
@..\chain\company_body
@..\chain\company_type_body
@..\chain\report_body
@..\chain\chain_link_body
@..\chain\helper_body
@..\chain\setup_body
@..\issue_report_body
@..\enable_body
@..\supplier_body
@..\audit_body
@..\alert_body
@..\quick_survey_body
@..\campaign_body

@latest2433_plugins

@update_tail
