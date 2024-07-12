define version=3332
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;

CREATE OR REPLACE TYPE CSR.T_FLOW_ITEM_PERM_ROW AS
	OBJECT (
		FLOW_ITEM_ID				NUMBER(10),
		PERMISSION_SET				NUMBER(10)
	);
/
CREATE OR REPLACE TYPE CSR.T_FLOW_ITEM_PERM_TABLE IS TABLE OF CSR.T_FLOW_ITEM_PERM_ROW;
/


ALTER TABLE csr.module ADD (
	enable_class		VARCHAR2(1024)
);
ALTER TABLE csr.internal_audit ADD (
	EXTERNAL_URL		VARCHAR2(255) NULL
);
ALTER TABLE csrimp.internal_audit ADD (
	EXTERNAL_URL		VARCHAR2(255) NULL
);
ALTER TABLE csr.customer_saml_sso
ADD use_first_last_name_attrs NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE csr.customer_saml_sso
ADD first_name_attribute VARCHAR2(255);
ALTER TABLE csr.customer_saml_sso
ADD last_name_attribute VARCHAR2(255);
ALTER TABLE csr.customer_saml_sso
ADD CONSTRAINT CHK_USE_FIRST_LAST_NAME_ATTRS CHECK ((use_basic_user_management IS NULL OR use_basic_user_management = 0) OR (use_first_last_name_attrs IS NULL OR use_first_last_name_attrs = 0) OR (use_basic_user_management = 1 AND use_first_last_name_attrs = 1 AND first_name_attribute IS NOT NULL AND last_name_attribute IS NOT NULL));
ALTER TABLE csr.customer_saml_sso
DROP CONSTRAINT CHK_BASIC_USR_MGMT_ATTRS;
ALTER TABLE csr.customer_saml_sso
ADD CONSTRAINT CHK_BASIC_USR_MGMT_ATTRS CHECK ((use_basic_user_management IS NULL OR use_basic_user_management = 0) OR (use_basic_user_management = 1 AND full_name_attribute IS NOT NULL AND email_attribute IS NOT NULL) OR (use_basic_user_management = 1 AND use_first_last_name_attrs = 1));
DECLARE
	v_is_nullable 	VARCHAR2(1);
BEGIN
	SELECT nullable
	  INTO v_is_nullable
	  FROM all_tab_cols
	 WHERE table_name = 'CUSTOMER_SAML_SSO'
	   AND owner = 'CSR'
	   AND column_name = 'USE_BASIC_USER_MANAGEMENT';
	IF v_is_nullable = 'Y' THEN
		UPDATE csr.customer_saml_sso
		   SET use_basic_user_management = 0
		 WHERE use_basic_user_management IS NULL;
	
		EXECUTE IMMEDIATE 'ALTER TABLE csr.customer_saml_sso MODIFY use_basic_user_management NOT NULL';
	END IF;
END;
/






CREATE OR REPLACE VIEW csr.v$audit AS
	SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label,
		   NVL2(ia.internal_audit_ref, atg.internal_audit_ref_prefix || ia.internal_audit_ref, null) custom_audit_id,
		   atg.internal_audit_ref_prefix, ia.internal_audit_ref, ia.ovw_validity_dtm,
		   ia.auditor_user_sid, NVL(cu.full_name, au.full_name) auditor_full_name, sr.submitted_dtm survey_completed,
		   NVL(nc.cnt, 0) open_non_compliances, ia.survey_sid, ia.auditor_name, ia.auditor_organisation,
		   r.region_type, r.geo_longitude longitude, r.geo_latitude latitude, rt.class_name region_type_class_name,
		   ia.auditee_user_sid, u.full_name auditee_full_name, u.email auditee_email,
		   SUBSTR(ia.notes, 1, 50) short_notes, ia.notes full_notes,
		   iat.internal_audit_type_id audit_type_id, iat.label audit_type_label, iat.internal_audit_type_source_id audit_type_source_id,
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
		   ncst.format_mask nc_score_format_mask, ia.permit_id, ia.external_audit_ref, ia.external_parent_ref, ia.external_url,
		   CASE (atct.re_audit_due_after_type)
				WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
				WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
				WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
				WHEN 'y' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after*12))
				ELSE ia.ovw_validity_dtm END next_audit_due_dtm,
		   iat.use_legacy_closed_definition
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
	  LEFT JOIN csr.v$quick_survey_response ssr ON ia.summary_response_id = ssr.survey_response_id AND ia.app_sid = ssr.app_sid
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




UPDATE csr.module SET enable_class = 'Credit360.Enable.EnableBranding' WHERE enable_sp = 'EnableBranding';
UPDATE csr.module SET enable_class = 'Credit360.Enable.EnableFileSharing' WHERE enable_sp = 'EnableQuestionLibrary';
UPDATE csr.module SET enable_class = 'Credit360.Enable.EnableFileSharing' WHERE enable_sp = 'EnableFileSharingApi';
UPDATE csr.module SET enable_class = 'Credit360.Enable.EnableAmforiIntegration' WHERE enable_sp = 'EnableAmforiIntegration';
UPDATE CSR.CUSTOMER_PORTLET
   SET portlet_id = 1070
 WHERE portlet_id = 923;
DELETE FROM CSR.PORTLET
 WHERE portlet_id = 923;
UPDATE CSR.PORTLET
   SET type = 'Credit360.Portlets.IndicatorMap', script_path = '/csr/site/portal/portlets/IndicatorMap.js'
 WHERE portlet_id = 1070;
DELETE FROM CSR.UTIL_SCRIPT_RUN_LOG
 WHERE util_script_id IN (65,66);
DELETE FROM CSR.UTIL_SCRIPT
 WHERE util_script_id IN (65,66);
EXEC security.user_pkg.LogonAdmin;
INSERT INTO csr.plugin 
		(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, app_sid, details) 
SELECT csr.plugin_id_seq.nextval, 10, 'Surveys 2 Campaign Responses', 
'/csr/site/chain/managecompany/controls/SurveyResponses.js', 'Chain.ManageCompany.SurveyResponses', 
'Credit360.Chain.Plugins.SurveyResponses', c.app_sid, 
'Displays a list of Surveys 2 Campaign Responses for the page company that the user has read access to. Includes a link to the survey for each response.'
  FROM csr.customer c
 WHERE c.question_library_enabled = 1;






@..\audit_pkg
@..\enable_pkg
@..\quick_survey_pkg
@..\util_script_pkg
@..\saml_pkg
@..\flow_pkg
@..\campaigns\campaign_pkg


@..\chain\company_body
@..\audit_body
@..\enable_body
@..\quick_survey_body
@..\schema_body
@..\csrimp\imp_body
@..\util_script_body
@..\saml_body
@..\flow_body
@..\campaigns\campaign_body



@update_tail
