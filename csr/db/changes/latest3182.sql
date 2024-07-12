define version=3182
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/
CREATE SEQUENCE CSR.COOKIE_POLICY_CONSENT_ID_SEQ;
CREATE TABLE CSR.COOKIE_POLICY_CONSENT(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	COOKIE_POLICY_CONSENT_ID	NUMBER(10, 0)	NOT NULL,
	CSR_USER_SID				NUMBER(10, 0)	NOT NULL,
	CREATED_DTM 				DATE			DEFAULT SYSDATE NOT NULL,
	ACCEPTED					NUMBER(1),
	CHECK 	(ACCEPTED IN (0, 1)),
	CONSTRAINT PK_COOKIE_POLICY_CONSENT PRIMARY KEY (APP_SID, COOKIE_POLICY_CONSENT_ID)
);
ALTER TABLE CSR.COOKIE_POLICY_CONSENT ADD CONSTRAINT FK_COOKIE_POLICY_CONSENT_USER
    FOREIGN KEY (APP_SID, CSR_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;
CREATE INDEX CSR.IX_COOKIE_POLICY_CONSENT_USR ON CSR.COOKIE_POLICY_CONSENT(APP_SID, CSR_USER_SID);
CREATE TABLE CSRIMP.COOKIE_POLICY_CONSENT (
	CSRIMP_SESSION_ID			NUMBER(10)      DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    COOKIE_POLICY_CONSENT_ID	NUMBER(10, 0)	NOT NULL,
    CSR_USER_SID				NUMBER(10, 0)	NOT NULL,
    CREATED_DTM 				DATE			NOT NULL,
    ACCEPTED					NUMBER(1),
    CHECK (ACCEPTED IN (0, 1)),
    CONSTRAINT PK_COOKIE_POLICY_CONSENT PRIMARY KEY (CSRIMP_SESSION_ID, COOKIE_POLICY_CONSENT_ID),
    CONSTRAINT FK_COOKIE_POLICY_CONSENT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
CREATE TABLE CSRIMP.MAP_COOKIE_POLICY_CONSEN (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COOKIE_POLICY_CONSENT_ID NUMBER(10) NOT NULL,
	NEW_COOKIE_POLICY_CONSENT_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COOKIE_POLICY_CONSEN PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COOKIE_POLICY_CONSENT_ID) USING INDEX,
	CONSTRAINT UK_MAP_COOKIE_POLICY_CONSEN UNIQUE (CSRIMP_SESSION_ID, NEW_COOKIE_POLICY_CONSENT_ID) USING INDEX,
	CONSTRAINT FK_MAP_COOKIE_POLICY_CONSEN_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);


ALTER TABLE csrimp.enhesa_site_type
DROP CONSTRAINT PK_ENHESA_SITE_TYPE DROP INDEX;
ALTER TABLE csrimp.enhesa_site_type
ADD CONSTRAINT PK_ENHESA_SITE_TYPE PRIMARY KEY (csrimp_session_id, site_type_id);
ALTER TABLE csrimp.enhesa_site_type_heading
DROP CONSTRAINT PK_ENHESA_SITE_TYPE_HEADING DROP INDEX;
ALTER TABLE csrimp.enhesa_site_type_heading
ADD CONSTRAINT PK_ENHESA_SITE_TYPE_HEADING PRIMARY KEY (csrimp_session_id, site_type_heading_id);
ALTER TABLE csrimp.enhesa_site_type_heading
ADD CONSTRAINT UK_SITE_TYPE_HEADING UNIQUE (csrimp_session_id, site_type_id, heading_code);
DROP TABLE csrimp.map_compliance_condition_type;
ALTER TABLE CSR.METER_RAW_DATA_SOURCE ADD (
	PROC_USE_REMOTE_SERVICE		NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT CK_PROC_USE_REMOTE_SERVICE CHECK (PROC_USE_REMOTE_SERVICE IN (0,1))
);
ALTER TABLE CSRIMP.METER_RAW_DATA_SOURCE ADD (
	PROC_USE_REMOTE_SERVICE		NUMBER(1) NOT NULL,
	CONSTRAINT CK_PROC_USE_REMOTE_SERVICE CHECK (PROC_USE_REMOTE_SERVICE IN (0,1))
);
ALTER TABLE CSR.METER_PROCESSING_JOB ADD (
	METER_RAW_DATA_ID			NUMBER(10)
);
ALTER TABLE CSR.METER_PROCESSING_JOB ADD CONSTRAINT FK_METERPROCJOB_METERRAWDATA
	FOREIGN KEY (APP_SID, METER_RAW_DATA_ID)
	REFERENCES CSR.METER_RAW_DATA(APP_SID, METER_RAW_DATA_ID)
;
CREATE INDEX CSR.IX_METERPROCJOB_METERRAWDATA ON CSR.METER_PROCESSING_JOB (APP_SID, METER_RAW_DATA_ID);
ALTER TABLE csrimp.delegation_ind
 DROP CONSTRAINT CK_META_ROLE DROP INDEX;
ALTER TABLE csrimp.delegation_ind
  ADD CONSTRAINT CK_META_ROLE
CHECK (META_ROLE IN('MERGED','MERGED_ON_TIME', 'DP_COMPLETE', 'COMP_TOTAL_DP', 'IND_SEL_COUNT', 'IND_SEL_TOTAL', 'DP_NOT_CHANGED_COUNT', 'ACC_TOTAL_DP')) ENABLE;
ALTER TABLE csr.delegation_ind
 DROP CONSTRAINT CK_META_ROLE DROP INDEX;
ALTER TABLE csr.delegation_ind
  ADD CONSTRAINT CK_META_ROLE
CHECK (META_ROLE IN('MERGED','MERGED_ON_TIME', 'DP_COMPLETE', 'COMP_TOTAL_DP', 'IND_SEL_COUNT', 'IND_SEL_TOTAL', 'DP_NOT_CHANGED_COUNT', 'ACC_TOTAL_DP')) ENABLE;
ALTER TABLE CSR.DATAVIEW_REGION_MEMBER ADD TAB_LEVEL NUMBER(10, 0);
ALTER TABLE CSRIMP.DATAVIEW_REGION_MEMBER ADD TAB_LEVEL NUMBER(10, 0);
ALTER TABLE csr.internal_audit_type
  ADD use_legacy_closed_definition NUMBER(1, 0) DEFAULT (0) NOT NULL;
ALTER TABLE csrimp.internal_audit_type
  ADD use_legacy_closed_definition NUMBER(1, 0) NOT NULL;
ALTER TABLE csr.internal_audit_type ADD CONSTRAINT chk_iat_use_legacy_clsd_def
	CHECK (use_legacy_closed_definition IN (0,1));
ALTER TABLE csrimp.internal_audit_type ADD CONSTRAINT chk_iat_use_legacy_clsd_def
	CHECK (use_legacy_closed_definition IN (0,1));
ALTER TABLE CSR.CUSTOMER ADD DISPLAY_COOKIE_POLICY NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.CUSTOMER ADD CONSTRAINT CK_CUSTOMER_DISP_COOKIE_POLICY CHECK (DISPLAY_COOKIE_POLICY IN (0,1));
ALTER TABLE CSRIMP.CUSTOMER ADD DISPLAY_COOKIE_POLICY NUMBER(1) NOT NULL;
ALTER TABLE CSRIMP.CUSTOMER ADD CONSTRAINT CK_CUSTOMER_DISP_COOKIE_POLICY CHECK (DISPLAY_COOKIE_POLICY IN (0,1));


GRANT UPDATE ON csr.tag to csrimp;
grant select, insert, update, delete on csrimp.cookie_policy_consent to tool_user;
grant select, insert, update on csr.cookie_policy_consent to csrimp;
grant select on csr.cookie_policy_consent_id_seq to csrimp;




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
		   ncst.format_mask nc_score_format_mask, ia.permit_id,
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




BEGIN
	INSERT INTO csr.meter_raw_data_status (status_id, description, needs_processing) VALUES(10, 'Queued', 0);
	INSERT INTO csr.meter_raw_data_status (status_id, description, needs_processing) VALUES(11, 'Merging', 0);
END;
/
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (54, 'Display cookie policy', 'Show/hide the cookie policy prompt in the website', 'EnableDisplayCookiePolicy', NULL);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (54, 'Show/hide', 'Show = 1, Hide = 0', 1, NULL);
END;
/
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (55, 'Metering - Urjanet Renewable Energy Columns', 'Enable or disable the Urjanet renewable energy column mappings and associated meter inputs', 'EnableUrjanetRenewEnergy', NULL);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (55, 'Enable/disable', 'Enable = 1, Disable = 0', 1, NULL);
END;
/






@..\region_api_pkg
@..\meter_monitor_pkg
@..\meter_processing_job_pkg
@..\csr_data_pkg
@..\indicator_api_pkg
@..\role_pkg
@..\compliance_pkg
@..\dataview_pkg
@..\audit_pkg
@..\csr_user_pkg
@..\util_script_pkg
@..\schema_pkg
@..\unit_test_pkg


@..\csrimp\imp_body
@..\region_api_body
@..\meter_monitor_body
@..\meter_processing_job_body
@..\schema_body
@..\indicator_api_body
@..\role_body
@..\compliance_body
@..\dataview_body
@..\audit_body
@..\csr_user_body
@..\customer_body
@..\util_script_body
@..\unit_test_body



@update_tail
