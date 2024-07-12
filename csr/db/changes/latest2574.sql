-- Please update version.sql too -- this keeps clean builds in sync
define version=2574
@update_header



-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE chain.filter_field ADD (
	top_n			NUMBER(10),
	bottom_n		NUMBER(10)
);

ALTER TABLE csrimp.chain_filter_field ADD (
	top_n			NUMBER(10),
	bottom_n		NUMBER(10)
);

-- DROP TABLE CHAIN.TT_FILTER_OBJECT_DATA;
CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_FILTER_OBJECT_DATA
( 
	DATA_TYPE_ID				NUMBER(10)  NOT NULL,
	AGG_TYPE_ID					NUMBER(10)  NOT NULL,
	OBJECT_ID					NUMBER(10)  NOT NULL,
	VAL_NUMBER					NUMBER(10),
	CONSTRAINT PK_FILTER_OBJ_DATA PRIMARY KEY (DATA_TYPE_ID, AGG_TYPE_ID, OBJECT_ID)
) 
ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_GROUP_BY_FIELD_VALUE (
	OBJECT_ID NUMBER(10),
	GROUP_BY_INDEX NUMBER(10),
	FILTER_VALUE_ID NUMBER(10),
	CONSTRAINT PK_GROUP_BY_FIELD_VALUE PRIMARY KEY (GROUP_BY_INDEX, OBJECT_ID, FILTER_VALUE_ID)
)ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_GROUP_BY_PIVOT (
	OBJECT_ID NUMBER(10),
	FILTER_VALUE_ID1 NUMBER(10),
	FILTER_VALUE_ID2 NUMBER(10),
	FILTER_VALUE_ID3 NUMBER(10),
	FILTER_VALUE_ID4 NUMBER(10)
) ON COMMIT DELETE ROWS;

CREATE INDEX CHAIN.IX_GROUP_BY_PIVOT ON CHAIN.TT_GROUP_BY_PIVOT (OBJECT_ID, FILTER_VALUE_ID1, FILTER_VALUE_ID2, FILTER_VALUE_ID3, FILTER_VALUE_ID4);

grant create table to csr;
/* SURVEY ANSWER ANSWER INDEX */
create index csr.ix_qs_ans_ans_search on csr.quick_survey_answer(answer) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* AUDIT LABEL TEXT INDEX */
create index csr.ix_audit_label_search on csr.internal_audit(label) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* AUDIT NOTES TEXT INDEX */
create index csr.ix_audit_notes_search on csr.internal_audit(notes) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* NON COMPLIANCE LABEL TEXT INDEX */
create index csr.ix_non_comp_label_search on csr.non_compliance(label) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* NON COMPLIANCE DETAIL TEXT INDEX */
create index csr.ix_non_comp_detail_search on csr.non_compliance(detail) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');
revoke create table from csr;


-- *** Types ***
-- probably better to force the row definition than drop the table definition
-- as client schemas might have grants that will be lost
DROP TYPE CHAIN.T_FILTERED_OBJECT_TABLE;

CREATE OR REPLACE TYPE CHAIN.T_FILTERED_OBJECT_ROW AS 
	 OBJECT ( 
		OBJECT_ID					NUMBER(10),
		GROUP_BY_INDEX				NUMBER(10),
		GROUP_BY_VALUE				NUMBER(10),
		CONSTRUCTOR FUNCTION T_FILTERED_OBJECT_ROW (
			in_object_id	NUMBER
		)
		RETURN SELF AS RESULT,
		MAP MEMBER FUNCTION MAP
			RETURN VARCHAR2
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
	MAP MEMBER FUNCTION MAP
		RETURN VARCHAR2
	IS
	BEGIN
		RETURN OBJECT_ID||'@'||GROUP_BY_INDEX||':'||GROUP_BY_VALUE;
	END;
END;
/

CREATE OR REPLACE TYPE CHAIN.T_FILTERED_OBJECT_TABLE AS 
	TABLE OF CHAIN.T_FILTERED_OBJECT_ROW;
/

-- *** Grants ***

GRANT EXECUTE ON CHAIN.T_FILTERED_OBJECT_TABLE TO CSR;
GRANT EXECUTE ON CHAIN.T_FILTERED_OBJECT_ROW TO CSR;
GRANT EXECUTE ON CHAIN.T_FILTERED_OBJECT_ROW TO CMS;
GRANT EXECUTE ON CHAIN.T_FILTERED_OBJECT_TABLE TO CMS;
GRANT SELECT ON chain.filter_value TO cms;
GRANT SELECT ON chain.v$filter_value TO cms;
GRANT SELECT ON chain.filter_value_id_seq TO cms;

-- ** Cross schema constraints ***

-- *** Views ***
CREATE OR REPLACE VIEW csr.v$audit AS
	SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label,
		   NVL2(ia.internal_audit_ref, atg.internal_audit_ref_prefix || ia.internal_audit_ref, null) custom_audit_id,
		   atg.internal_audit_ref_prefix, ia.internal_audit_ref,
		   ia.auditor_user_sid, ca.full_name auditor_full_name, sr.submitted_dtm survey_completed,
		   NVL(nc.cnt, 0) open_non_compliances, ia.survey_sid, ia.auditor_name, ia.auditor_organisation,
		   r.region_type, rt.class_name region_type_class_name, SUBSTR(ia.notes, 1, 50) short_notes,
		   ia.notes full_notes, iat.internal_audit_type_id audit_type_id, iat.label audit_type_label,
		   qs.label survey_label, ia.app_sid, ia.internal_audit_type_id, iat.auditor_role_sid,
		   iat.audit_contact_role_sid, ia.audit_closure_type_id, act.label closure_label, act.icon_image_filename,
		   ia.created_by_user_sid, ia.survey_response_id, ia.created_dtm, ca.email auditor_email,
		   iat.filename template_filename, iat.assign_issues_to_role, iat.add_nc_per_question, cvru.user_giving_cover_sid cover_auditor_sid,
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

CREATE OR REPLACE FORCE VIEW csr.v$issue AS
SELECT i.app_sid, NVL2(i.issue_ref, ist.internal_issue_ref_prefix || i.issue_ref, null) custom_issue_id, i.issue_id, i.label, i.description, i.source_label, i.is_visible, i.source_url, i.region_sid, re.description region_name, i.parent_id,
	   i.issue_escalated, i.owner_role_sid, i.owner_user_sid, cuown.user_name owner_user_name, cuown.full_name owner_full_name, cuown.email owner_email, i.first_issue_log_id, i.last_issue_log_id, NVL(lil.logged_dtm, i.raised_dtm) last_modified_dtm,
	   i.is_public, i.is_pending_assignment, i.rag_status_id, itrs.label rag_status_label, itrs.colour rag_status_colour, raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
	   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
	   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
	   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
	   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
	   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, c.more_info_1 correspondent_more_info_1,
	   sysdate now_dtm, due_dtm, forecast_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, ist.allow_children, ist.can_be_public, ist.show_forecast_dtm, ist.require_var_expl, ist.enable_reject_action,
	   i.issue_priority_id, ip.due_date_offset, ip.description priority_description,
	   CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden, i.first_priority_set_dtm,
	   issue_pending_val_id, i.issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id, issue_meter_missing_data_id, issue_supplier_id,
	   CASE WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND rejected_by_user_sid IS NULL AND SYSDATE > NVL(forecast_dtm, due_dtm) THEN 1 ELSE 0
	   END is_overdue,
	   CASE WHEN rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID') OR i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0
	   END is_owner,
	   CASE WHEN assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0 --OR #### HOW + WHERE CAN I GET THE ROLES THE USER IS PART OF??
	   END is_assigned_to_you,
	   CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1
	   END is_resolved,
	   CASE WHEN i.closed_dtm IS NULL THEN 0 ELSE 1
	   END is_closed,
	   CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1
	   END is_rejected,
	   CASE
		WHEN i.closed_dtm IS NOT NULL THEN 'Closed'
		WHEN i.resolved_dtm IS NOT NULL THEN 'Resolved'
		WHEN i.rejected_dtm IS NOT NULL THEN 'Rejected'
		ELSE 'Ongoing'
	   END status, CASE WHEN ist.auto_close_after_resolve_days IS NULL THEN NULL ELSE i.allow_auto_close END allow_auto_close,
	   ist.restrict_users_to_region, ist.deletable_by_administrator, ist.deletable_by_owner, ist.deletable_by_raiser, ist.send_alert_on_issue_raised,
	   ind.ind_sid, ind.description ind_name, isv.start_dtm, isv.end_dtm, ist.owner_can_be_changed
  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user curej, csr_user cuass, csr_user cuown,  role r, correspondent c, issue_priority ip,
	   (SELECT * FROM region_role_member WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')) rrm, v$region re, issue_log lil, v$issue_type_rag_status itrs,
	   v$ind ind, issue_sheet_value isv
 WHERE i.app_sid = curai.app_sid AND i.raised_by_user_sid = curai.csr_user_sid
   AND i.app_sid = ist.app_sid AND i.issue_type_Id = ist.issue_type_id
   AND i.app_sid = cures.app_sid(+) AND i.resolved_by_user_sid = cures.csr_user_sid(+)
   AND i.app_sid = cuclo.app_sid(+) AND i.closed_by_user_sid = cuclo.csr_user_sid(+)
   AND i.app_sid = curej.app_sid(+) AND i.rejected_by_user_sid = curej.csr_user_sid(+)
   AND i.app_sid = cuass.app_sid(+) AND i.assigned_to_user_sid = cuass.csr_user_sid(+)
   AND i.app_sid = cuown.app_sid(+) AND i.owner_user_sid = cuown.csr_user_sid(+)
   AND i.app_sid = r.app_sid(+) AND i.assigned_to_role_sid = r.role_sid(+)
   AND i.app_sid = re.app_sid(+) AND i.region_sid = re.region_sid(+)
   AND i.app_sid = c.app_sid(+) AND i.correspondent_id = c.correspondent_id(+)
   AND i.app_sid = ip.app_sid(+) AND i.issue_priority_id = ip.issue_priority_id(+)
   AND i.app_sid = rrm.app_sid(+) AND i.region_sid = rrm.region_sid(+) AND i.owner_role_sid = rrm.role_sid(+)
   AND i.app_sid = lil.app_sid(+) AND i.last_issue_log_id = lil.issue_log_id(+)
   AND i.app_sid = itrs.app_sid(+) AND i.rag_status_id = itrs.rag_status_id(+) AND i.issue_type_id = itrs.issue_type_id(+)
   AND i.app_sid = isv.app_sid(+) AND i.issue_sheet_value_id = isv.issue_sheet_value_id(+)
   AND isv.app_sid = ind.app_sid(+) AND isv.ind_sid = ind.ind_sid(+)
   AND i.deleted = 0;

-- *** Data changes ***
-- RLS

-- Data
-- output from chain.card_pkg.dumpcard
DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	-- Credit360.Audit.Filters.InternalAuditFilter
	v_desc := 'Internal Audit Filter';
	v_class := 'Credit360.Audit.Cards.InternalAuditFilter';
	v_js_path := '/csr/site/audit/internalAuditFilter.js';
	v_js_class := 'Credit360.Audit.Filters.InternalAuditFilter';
	v_css_path := '';
	
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card
			SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
			WHERE js_class_type = v_js_class
			RETURNING card_id INTO v_card_id;
	END;
	
	DELETE FROM chain.card_progression_action
	WHERE card_id = v_card_id
	AND action NOT IN ('default');
	
	v_actions := chain.T_STRING_LIST('default');
	
	FOR i IN v_actions.FIRST .. v_actions.LAST
	LOOP
		BEGIN
			INSERT INTO chain.card_progression_action (card_id, action)
			VALUES (v_card_id, v_actions(i));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
	
	-- Credit360.Audit.Filters.AuditNonComplianceFilterAdapter
	v_desc := 'Internal Audit Non-compliance Filter Adapter';
	v_class := 'Credit360.Audit.Cards.AuditNonComplianceFilterAdapter';
	v_js_path := '/csr/site/audit/auditNonComplianceFilterAdapter.js';
	v_js_class := 'Credit360.Audit.Filters.AuditNonComplianceFilterAdapter';
	v_css_path := '';
	
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card
			SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
			WHERE js_class_type = v_js_class
			RETURNING card_id INTO v_card_id;
	END;
	
	DELETE FROM chain.card_progression_action
	WHERE card_id = v_card_id
	AND action NOT IN ('default');
	
	v_actions := chain.T_STRING_LIST('default');
	
	FOR i IN v_actions.FIRST .. v_actions.LAST
	LOOP
		BEGIN
			INSERT INTO chain.card_progression_action (card_id, action)
			VALUES (v_card_id, v_actions(i));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
	
	-- Credit360.Audit.Filters.AuditCMSFilter
	v_desc := 'Internal Audit CMS Filter';
	v_class := 'Credit360.Audit.Cards.AuditCMSFilter';
	v_js_path := '/csr/site/audit/auditCMSFilter.js';
	v_js_class := 'Credit360.Audit.Filters.AuditCMSFilter';
	v_css_path := '';
	
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card
			SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
			WHERE js_class_type = v_js_class
			RETURNING card_id INTO v_card_id;
	END;
	
	DELETE FROM chain.card_progression_action
	WHERE card_id = v_card_id
	AND action NOT IN ('default');
	
	v_actions := chain.T_STRING_LIST('default');
	
	FOR i IN v_actions.FIRST .. v_actions.LAST
	LOOP
		BEGIN
			INSERT INTO chain.card_progression_action (card_id, action)
			VALUES (v_card_id, v_actions(i));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
	
	-- Credit360.Audit.Filters.NonComplianceFilter
	v_desc := 'Non-compliance Filter';
	v_class := 'Credit360.Audit.Cards.NonComplianceFilter';
	v_js_path := '/csr/site/audit/nonComplianceFilter.js';
	v_js_class := 'Credit360.Audit.Filters.NonComplianceFilter';
	v_css_path := '';
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card
			SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
			WHERE js_class_type = v_js_class
			RETURNING card_id INTO v_card_id;
	END;
	
	DELETE FROM chain.card_progression_action
	WHERE card_id = v_card_id
	AND action NOT IN ('default');
	
	v_actions := chain.T_STRING_LIST('default');
	
	FOR i IN v_actions.FIRST .. v_actions.LAST
	LOOP
		BEGIN
			INSERT INTO chain.card_progression_action (card_id, action)
			VALUES (v_card_id, v_actions(i));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
	
	-- Credit360.Audit.Filters.NonComplianceAuditFilterAdapter
	v_desc := 'Non-compliance Filter';
	v_class := 'Credit360.Audit.Cards.NonComplianceAuditFilterAdapter';
	v_js_path := '/csr/site/audit/nonComplianceAuditFilterAdapter.js';
	v_js_class := 'Credit360.Audit.Filters.NonComplianceAuditFilterAdapter';
	v_css_path := '';
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card
			SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
			WHERE js_class_type = v_js_class
			RETURNING card_id INTO v_card_id;
	END;
	
	DELETE FROM chain.card_progression_action
	WHERE card_id = v_card_id
	AND action NOT IN ('default');
	
	v_actions := chain.T_STRING_LIST('default');
	
	FOR i IN v_actions.FIRST .. v_actions.LAST
	LOOP
		BEGIN
			INSERT INTO chain.card_progression_action (card_id, action)
			VALUES (v_card_id, v_actions(i));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;
/

-- make sure all issues relating to deleted audits are marked as deleted
UPDATE csr.internal_audit
   SET deleted = 1
 WHERE deleted = 0
   AND internal_audit_sid IN (
	SELECT ia.internal_audit_sid
	  FROM csr.internal_audit ia
	  JOIN csr.customer c ON ia.app_sid = c.app_sid
	  JOIN security.securable_object so ON ia.internal_audit_sid = so.sid_id
	 WHERE so.parent_sid_id = c.trash_sid
);

UPDATE csr.issue
   SET deleted = 1
 WHERE deleted = 0
   AND issue_non_compliance_id IN (
	SELECT inc.issue_non_compliance_id
	  FROM csr.issue_non_compliance inc
	  JOIN csr.audit_non_compliance anc ON inc.non_compliance_id = anc.non_compliance_id AND inc.app_sid = anc.app_sid
	  JOIN csr.internal_audit ia ON anc.internal_audit_sid = ia.internal_audit_sid AND anc.app_sid = inc.app_sid
	 WHERE ia.deleted = 1
	)
  AND issue_non_compliance_id NOT IN (
	SELECT inc.issue_non_compliance_id
	  FROM csr.issue_non_compliance inc
	  JOIN csr.audit_non_compliance anc ON inc.non_compliance_id = anc.non_compliance_id AND inc.app_sid = anc.app_sid
	  JOIN csr.internal_audit ia ON anc.internal_audit_sid = ia.internal_audit_sid AND anc.app_sid = inc.app_sid
	 WHERE ia.deleted = 0
	);

DECLARE
	v_card_id	NUMBER(10);
BEGIN
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description)
		VALUES(41, 'Internal Audit Filter', 'Allows filtering of internal audits');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description)
		VALUES(42, 'Non-compliance Filter', 'Allows filtering of non-compliances');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		SELECT card_id
		  INTO v_card_id
		  FROM chain.card
		 WHERE js_class_type = 'Credit360.Audit.Filters.InternalAuditFilter';
	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Internal Audit Filter', 'csr.audit_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;

	BEGIN
		SELECT card_id
		  INTO v_card_id
		  FROM chain.card
		 WHERE js_class_type = 'Credit360.Audit.Filters.AuditNonComplianceFilterAdapter';
	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Internal Audit Non-compliance Filter Adapter', 'csr.audit_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;

	BEGIN
		SELECT card_id
		  INTO v_card_id
		  FROM chain.card
		 WHERE js_class_type = 'Credit360.Audit.Filters.AuditCMSFilter';
	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Internal Audit CMS Filter', 'csr.audit_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		SELECT card_id
		  INTO v_card_id
		  FROM chain.card
		 WHERE js_class_type = 'Credit360.Audit.Filters.NonComplianceFilter';
	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Non-compliance Filter', 'csr.non_compliance_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		SELECT card_id
		  INTO v_card_id
		  FROM chain.card
		 WHERE js_class_type = 'Credit360.Audit.Filters.NonComplianceAuditFilterAdapter';
	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Non-compliance Audit Filter Adapter', 'csr.non_compliance_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	UPDATE chain.filter_type
	   SET helper_pkg = 'csr.issue_report_pkg'
	 WHERE helper_pkg = 'csr.issue_pkg';
END;
/

DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every minute afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.qs_answer_text',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.sync_index(''ix_qs_ans_ans_search'');',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise survey answer text indexes');
       COMMIT;
END;
/

DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every minute afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.audit_text',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.sync_index(''ix_audit_label_search'');ctx_ddl.sync_index(''ix_audit_notes_search'');ctx_ddl.sync_index(''ix_non_comp_label_search'');ctx_ddl.sync_index(''ix_non_comp_detail_search'');',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise audit and non-compliance text indexes');
       COMMIT;
END;
/

DECLARE
	v_audit_card_group_id  		NUMBER;
	v_non_comp_card_group_id 	NUMBER;
	v_audit_card_id				NUMBER;
	v_audit_nc_card_id			NUMBER;
	v_audit_cms_card_id			NUMBER;
	v_nc_card_id				NUMBER;
	v_nc_audit_card_id   		NUMBER;
BEGIN
	SELECT card_group_id
	  INTO v_audit_card_group_id
	  FROM chain.card_group
	 WHERE name = 'Internal Audit Filter';
	 
	SELECT card_group_id
	  INTO v_non_comp_card_group_id
	  FROM chain.card_group
	 WHERE name = 'Non-compliance Filter';
	 
	SELECT card_id
	  INTO v_audit_card_id
	  FROM chain.card
	 WHERE js_class_type ='Credit360.Audit.Filters.InternalAuditFilter';
	 
	SELECT card_id
	  INTO v_audit_nc_card_id
	  FROM chain.card
	 WHERE js_class_type ='Credit360.Audit.Filters.AuditNonComplianceFilterAdapter';
	 
	SELECT card_id
	  INTO v_audit_cms_card_id
	  FROM chain.card
	 WHERE js_class_type ='Credit360.Audit.Filters.AuditCMSFilter';
	 
	SELECT card_id
	  INTO v_nc_card_id
	  FROM chain.card
	 WHERE js_class_type ='Credit360.Audit.Filters.NonComplianceFilter';
	  
	SELECT card_id
	  INTO v_nc_audit_card_id
	  FROM chain.card
	 WHERE js_class_type ='Credit360.Audit.Filters.NonComplianceAuditFilterAdapter';

	FOR r IN (
	  SELECT c.host 
		FROM csr.customer c 
		JOIN security.securable_object so on so.parent_sid_id = c.app_sid 
	   WHERE LOWER(so.name) = 'audits'
	   GROUP BY c.host
	 ) LOOP
		security.user_pkg.logonadmin(r.host);
	  
		BEGIN
			-- cards are in chain at the moment so need a row in this table - ugly
			INSERT INTO chain.customer_options(app_sid, use_company_type_css_class)
			VALUES (security.security_pkg.getapp, 0);
		EXCEPTION WHEN dup_val_on_index THEN
			NULL;
		END;

		INSERT INTO chain.card_group_card (card_group_id, card_id, position)
			VALUES (v_audit_card_group_id, v_audit_card_id, 0);
		INSERT INTO chain.card_group_card (card_group_id, card_id, position)
			VALUES (v_audit_card_group_id, v_audit_nc_card_id, 1);
		INSERT INTO chain.card_group_card (card_group_id, card_id, position)
			VALUES (v_audit_card_group_id, v_audit_cms_card_id, 2);
		INSERT INTO chain.card_group_card (card_group_id, card_id, position)
			VALUES (v_non_comp_card_group_id, v_nc_card_id, 0);
		INSERT INTO chain.card_group_card (card_group_id, card_id, position)
			VALUES (v_non_comp_card_group_id, v_nc_audit_card_id, 1);
	 END LOOP;
	 
	security.user_pkg.LogonAdmin;
	 
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	 VALUES (42, 'Audit filtering', 'EnableAuditFiltering', 'Enable audit/non-compliance filtering pages');
END;
/

-- ** New package grants **
create or replace package csr.audit_report_pkg as
procedure dummy;
end;
/
create or replace package body csr.audit_report_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

create or replace package csr.non_compliance_report_pkg as
procedure dummy;
end;
/
create or replace package body csr.non_compliance_report_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

create or replace package cms.filter_pkg as
procedure dummy;
end;
/
create or replace package body cms.filter_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

GRANT EXECUTE ON csr.audit_report_pkg TO web_user;
GRANT EXECUTE ON csr.audit_report_pkg TO chain;
GRANT EXECUTE ON csr.non_compliance_report_pkg TO web_user;
GRANT EXECUTE ON csr.non_compliance_report_pkg TO chain;
GRANT EXECUTE ON cms.filter_pkg TO csr;

GRANT ALL ON CHAIN.TT_FILTER_OBJECT_DATA TO csr;
-- *** Packages ***

@..\issue_report_pkg
@..\quick_survey_pkg
@..\tag_pkg
@..\supplier_pkg
@..\chain\company_filter_pkg
@..\chain\filter_pkg
@..\chain\business_relationship_pkg
@..\chain\product_pkg
@..\audit_pkg
@..\audit_report_pkg
@..\non_compliance_report_pkg
@..\flow_pkg
@..\..\..\aspen2\cms\db\filter_pkg

@..\issue_report_body
@..\quick_survey_body
@..\tag_body
@..\supplier_body
@..\chain\company_body
@..\chain\company_filter_body
@..\chain\product_body
@..\chain\filter_body
@..\chain\business_relationship_body
@..\chain\product_body
@..\chain\report_body
@..\audit_body
@..\audit_report_body
@..\non_compliance_report_body
@..\flow_body
@..\schema_body
@..\csrimp\imp_body
@..\..\..\aspen2\cms\db\filter_body

@update_tail
