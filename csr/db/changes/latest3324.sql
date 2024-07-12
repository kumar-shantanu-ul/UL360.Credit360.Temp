define version=3324
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

CREATE TABLE csr.service_user_map(
	service_identifier		VARCHAR2(255)				NOT NULL,
	user_sid				NUMBER(10)					NOT NULL,
	full_name				VARCHAR2(256)				NOT NULL,
	can_impersonate			NUMBER(1)		DEFAULT 0	NOT NULL,
	CONSTRAINT pk_service_user_map PRIMARY KEY (service_identifier),
	CONSTRAINT ck_service_user_map_impersonate CHECK (can_impersonate IN (0,1))
)
;
CREATE TABLE chain.integration_request (
	app_sid					NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	data_type				VARCHAR2(64)	NOT NULL,
	tenant_id				VARCHAR2(64)	NOT NULL,
	request_url				VARCHAR2(2048)	NOT NULL,
	request_verb			VARCHAR2(100)	NOT NULL,
	last_updated_dtm		DATE			NOT NULL,
	last_updated_message	VARCHAR2(1024)	NOT NULL,
	request_json			CLOB,
	CONSTRAINT pk_integration_request	PRIMARY KEY (app_sid, data_type)
);


ALTER TABLE csr.internal_audit ADD (
	EXTERNAL_AUDIT_REF		VARCHAR2(255) NULL
);
ALTER TABLE csrimp.internal_audit ADD (
	EXTERNAL_AUDIT_REF		VARCHAR2(255) NULL
);
ALTER TABLE csr.auto_impexp_instance_msg
ADD message_clob CLOB NULL;
BEGIN
	security.user_pkg.LogonAdmin;
	UPDATE csr.auto_impexp_instance_msg
	   SET message_clob = message;
END;
/
ALTER TABLE csr.auto_impexp_instance_msg
DROP COLUMN message;
ALTER TABLE csr.auto_impexp_instance_msg
RENAME COLUMN message_clob TO message;
ALTER TABLE csr.auto_impexp_instance_msg
MODIFY message NOT NULL;


create or replace package chain.integration_pkg as end;
/
GRANT EXECUTE ON chain.integration_pkg TO csr;
GRANT EXECUTE ON chain.integration_pkg TO web_user;




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
		   ncst.format_mask nc_score_format_mask, ia.permit_id, ia.external_audit_ref,
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
	INSERT INTO csr.service_user_map
		(service_identifier, user_sid, full_name, can_impersonate)
	VALUES
		('scheduler', 3, 'Scheduler service user', 1);
END;
/
CREATE TABLE csr.temp_ud327 AS
(SELECT sv.app_sid, sv.section_sid, sv.version_number 
   FROM csr.section s
   JOIN csr.section_version sv ON sv.app_sid = s.app_sid AND s.section_sid = sv.section_sid AND s.visible_version_number = sv.version_number
  WHERE s.plugin IS NOT NULL AND REGEXP_LIKE(body, '\^ [^#]')
);
DECLARE
    v_cnt NUMBER;
BEGIN
    SELECT MAX(REGEXP_COUNT(body, '\^ [^#]'))
      INTO v_cnt
      FROM csr.temp_ud327 s
      JOIN csr.section_version sv ON sv.app_sid = s.app_sid AND s.section_sid = sv.section_sid AND s.version_number = sv.version_number; 
	IF v_cnt > 0 THEN
		FOR i IN 1..v_cnt LOOP
			UPDATE csr.section_version sv SET body = regexp_replace(body, '(\^ )([^#])', '\1#IMPORT_'||i||'#\2', i, 1)
			 WHERE EXISTS (SELECT NULL FROM csr.temp_ud327 WHERE app_sid = sv.app_sid AND section_sid = sv.section_sid AND version_number = sv.version_number);
		END LOOP;
	END IF;
END;
/
DROP TABLE csr.temp_ud327;
DELETE FROM csr.module WHERE module_id = 75;
INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
VALUES (112, 'Amfori Integration', 'EnableAmforiIntegration', 'Enable Amfori Integration', 1);	
insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
values (csr.plugin_id_seq.nextval, 10, 'Integration supplier details', '/csr/site/chain/manageCompany/controls/IntegrationSupplierDetailsTab.js', 'Chain.ManageCompany.IntegrationSupplierDetailsTab', 'Credit360.Chain.Plugins.IntegrationSupplierDetailsDto', 'This tab shows the Integration details for a supplier.');






@..\csr_user_pkg
@..\region_pkg
@..\enable_pkg
@..\csr_data_pkg
@..\chain\integration_pkg
@..\audit_pkg
@..\chain\company_pkg
@..\tag_pkg


@..\csr_user_body
@..\region_body
@..\audit_body
@..\enable_body
@..\chain\chain_body
@..\chain\integration_body
@..\chain\company_body
@..\csrimp\imp_body
@..\tag_body



@update_tail
