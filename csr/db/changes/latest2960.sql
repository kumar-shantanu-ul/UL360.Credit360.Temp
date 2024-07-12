define version=2960
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
CREATE TABLE cms.form_staging (
	app_sid					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    lookup_key     			VARCHAR2(255) NOT NULL,
    description				VARCHAR2(2000) NOT NULL,
    file_name				VARCHAR2(255) NOT NULL,
    form_xml       			XMLTYPE NOT NULL,
    CONSTRAINT PK_FORM_STAGING PRIMARY KEY (app_sid, lookup_key)
);
CREATE TABLE cms.form_version(
	app_sid					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	form_sid				NUMBER(10) NOT NULL,
	form_version			NUMBER(10) NOT NULL,
	file_name				VARCHAR2(255) NOT NULL,
	form_xml				XMLTYPE NOT NULL,
	published_dtm			DATE DEFAULT SYSDATE NOT NULL,
	published_by_sid		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL,
	version_comment			VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_FORM_VERSION PRIMARY KEY (app_sid, form_sid, form_version),
	CONSTRAINT FK_FORM_VERSION FOREIGN KEY (app_sid, form_sid) REFERENCES cms.form (app_sid, form_sid)
);
CREATE TABLE csr.batched_export_type (
	batch_export_type_id	NUMBER(10) NOT NULL,
	label					VARCHAR2(255) NOT NULL,
	assembly				VARCHAR2(1024) NOT NULL,
	CONSTRAINT pk_batched_export_type PRIMARY KEY (batch_export_type_id)
);
CREATE TABLE csr.batch_job_batched_export (
	app_sid                 NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL ,
	batch_job_id            NUMBER(10) NOT NULL,
	batch_export_type_id	NUMBER(10) NOT NULL,
	settings_xml			XMLTYPE NOT NULL,
	file_blob				BLOB,
	file_name				VARCHAR2(1024),
	CONSTRAINT pk_bj_batched_export PRIMARY KEY (app_sid, batch_job_id),
	CONSTRAINT fk_bj_batched_export_bj_id FOREIGN KEY (app_sid, batch_job_id) REFERENCES csr.batch_job(app_sid, batch_job_id),
	CONSTRAINT fk_bj_batched_export_type FOREIGN KEY (batch_export_type_id) REFERENCES csr.batched_export_type (batch_export_type_id)  
);


ALTER TABLE csr.factor ADD (
	custom_factor_id	NUMBER(10)
);
ALTER TABLE csr.factor ADD CONSTRAINT fk_factor_custom_factor 
    FOREIGN KEY (app_sid, custom_factor_id)
    REFERENCES csr.custom_factor(app_sid, custom_factor_id)
;
ALTER TABLE csrimp.factor ADD (
	custom_factor_id	NUMBER(10)
);
ALTER TABLE csr.custom_factor_set ADD (
	created_by_sid		NUMBER(10), 
	created_dtm			DATE
);
ALTER TABLE csr.custom_factor_set ADD CONSTRAINT fk_custom_factor_set_user
    FOREIGN KEY (app_sid, created_by_sid)
    REFERENCES csr.csr_user(app_sid, csr_user_sid);
	
ALTER TABLE csrimp.custom_factor_set ADD (
	created_by_sid		NUMBER(10), 
	created_dtm			DATE
);
ALTER SEQUENCE csr.factor_set_id_seq INCREMENT BY +998;
SELECT csr.factor_set_id_seq.NEXTVAL FROM dual;
ALTER SEQUENCE csr.factor_set_id_seq INCREMENT BY 1;
ALTER SEQUENCE csr.factor_set_grp_id_seq INCREMENT BY +998;
SELECT csr.factor_set_grp_id_seq.NEXTVAL FROM dual;
ALTER SEQUENCE csr.factor_set_grp_id_seq INCREMENT BY 1;
ALTER TABLE cms.form ADD(
	current_version			NUMBER(10),
	is_report_builder		NUMBER(1)  DEFAULT 0 NOT NULL,
	draft_form_xml			XMLTYPE,
	draft_file_name			VARCHAR2(255),
	short_path				VARCHAR2(255),
	use_quick_chart			NUMBER(1)	DEFAULT 0 NOT NULL,
	CONSTRAINT CK_FORM_USE_QUICK_CHART CHECK (use_quick_chart IN (0,1)),
	CONSTRAINT CK_FORM_IS_REPORT_BUILDER_1_0 CHECK (is_report_builder IN (0,1))
);
ALTER TABLE cms.form RENAME COLUMN form_xml TO xx_form_xml;
ALTER TABLE cms.form MODIFY xx_form_xml NULL;
INSERT INTO cms.form_version (app_sid, form_sid, form_version, file_name, form_xml, published_dtm, published_by_sid, version_comment)
SELECT app_sid, form_sid, 1, description, xx_form_xml, sysdate, 3, 'Initial version'
  FROM cms.form;
UPDATE cms.form SET current_version = 1, is_report_builder = 1;
ALTER TABLE cms.form ADD CONSTRAINT FK_FORM_FORM_VERSION 
	FOREIGN KEY (app_sid, form_sid, current_version) 
	REFERENCES cms.form_version(app_sid, form_sid, form_version) 
	DEFERRABLE INITIALLY DEFERRED;
CREATE UNIQUE INDEX CMS.IDX_FORM_SHORT_PATH ON cms.form (app_sid, NVL(LOWER(short_path), TO_CHAR(form_sid)));
ALTER TABLE csrimp.cms_form DROP COLUMN form_xml;
ALTER TABLE csrimp.cms_form ADD (	
	current_version			NUMBER(10),
	is_report_builder		NUMBER(1) NOT NULL,
	draft_form_xml			XMLTYPE,
	draft_file_name			VARCHAR2(255),
	short_path				VARCHAR2(255),
	use_quick_chart			NUMBER(1) NOT NULL,
	CONSTRAINT CK_CMS_FORM_USE_QUICK_CHART CHECK (USE_QUICK_CHART IN (0,1)),
	CONSTRAINT CK_FORM_IS_REPORT_BUILDER_1_0 CHECK (IS_REPORT_BUILDER IN (0,1))
);
CREATE TABLE CSRIMP.CMS_FORM_VERSION (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	FORM_SID						NUMBER(10) NOT NULL,
	FORM_VERSION					NUMBER(10) NOT NULL,
	FILE_NAME						VARCHAR2(255) NOT NULL,
	FORM_XML						XMLTYPE NOT NULL,
	PUBLISHED_DTM					DATE NOT NULL,
	PUBLISHED_BY_SID				NUMBER(10) NOT NULL,
	VERSION_COMMENT					VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_FORM_VERSION PRIMARY KEY (CSRIMP_SESSION_ID, FORM_SID, FORM_VERSION),
	CONSTRAINT FK_CMS_FORM_VERSION_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);
ALTER TABLE CSRIMP.INTERNAL_AUDIT_TYPE ADD (
	AUDIT_COORD_ROLE_OR_GROUP_SID				NUMBER(10)	NULL
);
ALTER TABLE CSRIMP.AUDIT_TYPE_FLOW_INV_TYPE ADD (
	USERS_ROLE_OR_GROUP_SID					NUMBER(10)	NULL
);
DROP TABLE chain.fb87238_saved_filter_sent_alrt;
ALTER TABLE CSR.SCORE_THRESHOLD ADD (
	ICON_IMAGE_SHA1           RAW(20),
	DASHBOARD_SHA1            RAW(20)
);
ALTER TABLE CSRIMP.SCORE_THRESHOLD ADD (
	ICON_IMAGE_SHA1           RAW(20),
	DASHBOARD_SHA1            RAW(20)
);
ALTER TABLE CSR.AUDIT_CLOSURE_TYPE ADD (
	ICON_IMAGE_SHA1           RAW(20)
);
ALTER TABLE CSRIMP.AUDIT_CLOSURE_TYPE ADD (
	ICON_IMAGE_SHA1           RAW(20)
);
BEGIN
	security.user_pkg.LogonAdmin;
	
	UPDATE csr.score_threshold
	   SET icon_image_sha1 = sys.dbms_crypto.hash(icon_image, sys.dbms_crypto.hash_sh1)
	 WHERE icon_image IS NOT NULL;
	
	UPDATE csr.score_threshold
	   SET dashboard_sha1 = sys.dbms_crypto.hash(dashboard_image, sys.dbms_crypto.hash_sh1)
	 WHERE dashboard_image IS NOT NULL;
	
	UPDATE csrimp.score_threshold
	   SET icon_image_sha1 = sys.dbms_crypto.hash(icon_image, sys.dbms_crypto.hash_sh1)
	 WHERE icon_image IS NOT NULL;
	
	UPDATE csrimp.score_threshold
	   SET dashboard_sha1 = sys.dbms_crypto.hash(dashboard_image, sys.dbms_crypto.hash_sh1)
	 WHERE dashboard_image IS NOT NULL;
	
	UPDATE csr.audit_closure_type
	   SET icon_image_sha1 = sys.dbms_crypto.hash(icon_image, sys.dbms_crypto.hash_sh1)
	 WHERE icon_image IS NOT NULL;
	
	UPDATE csrimp.audit_closure_type
	   SET icon_image_sha1 = sys.dbms_crypto.hash(icon_image, sys.dbms_crypto.hash_sh1)
	 WHERE icon_image IS NOT NULL;
	
END;
/


GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.flow_state_group TO tool_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.flow_state_group_member TO tool_user;
GRANT SELECT, INSERT, UPDATE ON csrimp.custom_factor_set TO tool_user;
GRANT SELECT, INSERT, UPDATE ON csrimp.custom_factor TO tool_user;
GRANT SELECT, INSERT, UPDATE ON csrimp.emission_factor_profile TO tool_user;
GRANT SELECT, INSERT, UPDATE ON csrimp.emission_factor_profile_factor TO tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.init_tab_element_layout TO tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.init_create_page_el_layout TO tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.initiative_header_element TO tool_user;
grant insert on cms.form_version to csrimp;
grant select,insert,update,delete on csrimp.cms_form_version to tool_user;
grant select on chain.bsci_audit to csr;
grant select on chain.bsci_associate to csr;
grant select on chain.bsci_finding to csr;
grant select on chain.bsci_supplier to csr;
grant insert on chain.bsci_audit to csrimp;
grant insert on chain.bsci_associate to csrimp;
grant insert on chain.bsci_finding to csrimp;
grant insert on chain.bsci_supplier to csrimp;


DELETE FROM csr.module_param
 WHERE ROWID NOT IN (
	SELECT MAX(rowid)
	  FROM csr.module_param
	 GROUP BY module_id, pos);
ALTER TABLE CSR.MODULE_PARAM ADD CONSTRAINT MODULE_PARAM_UNIQUE UNIQUE (MODULE_ID, POS);
DELETE FROM csr.util_script_param
 WHERE ROWID NOT IN (
	SELECT MAX(rowid)
	  FROM csr.util_script_param
	 GROUP BY util_script_id, pos);
ALTER TABLE CSR.UTIL_SCRIPT_PARAM ADD CONSTRAINT UTIL_SCRIPT_PARAM_UNIQUE UNIQUE (UTIL_SCRIPT_ID, POS);


  
CREATE OR REPLACE VIEW csr.v$factor_type AS
SELECT f.factor_type_id, f.parent_id, f.name, f.std_measure_id, f.egrid, af.active, uf.in_use
  FROM csr.factor_type f
  LEFT JOIN (
    SELECT factor_type_id, 1 active FROM (
          SELECT DISTINCT af.factor_type_id
            FROM csr.factor_type af
           START WITH af.factor_type_id
            IN (
              SELECT DISTINCT aaf.factor_type_id
                FROM csr.factor_type aaf
                JOIN csr.std_factor sf ON sf.factor_type_id = aaf.factor_type_id
                JOIN csr.std_factor_set_active sfa ON sfa.std_factor_set_id = sf.std_factor_set_id
            )
           CONNECT BY PRIOR parent_id = af.factor_type_id
          UNION
          SELECT DISTINCT f.factor_type_id
            FROM csr.factor_type f
                 START WITH f.factor_type_id
                  IN (
              SELECT DISTINCT f.factor_type_id
                FROM csr.factor_type f
                JOIN csr.custom_factor sf ON sf.factor_type_id = f.factor_type_id
                 AND sf.app_sid = security.security_pkg.getApp
               WHERE std_measure_id IS NOT NULL
            )
          CONNECT BY PRIOR parent_id = f.factor_type_id
          UNION
          SELECT 3 factor_type_id -- factor_pkg.UNSPECIFIED_FACTOR_TYPE
            FROM dual
        )) af ON f.factor_type_id = af.factor_type_id
   LEFT JOIN (
    SELECT factor_type_id, 1 in_use FROM (
      SELECT factor_type_id
        FROM csr.factor_type
       START WITH factor_type_id
          IN (
          SELECT DISTINCT factor_type_id
            FROM csr.factor
           WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
      )
      CONNECT BY PRIOR parent_id = factor_type_id
      UNION
      SELECT DISTINCT f.factor_type_id
        FROM csr.factor_type f
             START WITH f.factor_type_id
              IN (
          SELECT DISTINCT f.factor_type_id
            FROM csr.factor_type f
            JOIN csr.custom_factor sf ON sf.factor_type_id = f.factor_type_id
             AND sf.app_sid = security.security_pkg.getApp
           WHERE std_measure_id IS NOT NULL
        )
      CONNECT BY PRIOR parent_id = f.factor_type_id
      UNION
      SELECT factor_type_id
        FROM csr.factor_type
       START WITH factor_type_id
          IN (
          SELECT DISTINCT factor_type_id
            FROM csr.factor
           WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
      )
      CONNECT BY PRIOR factor_type_id = parent_id
      UNION
      SELECT 3 factor_type_id -- factor_pkg.UNSPECIFIED_FACTOR_TYPE
        FROM dual
        )) uf ON f.factor_type_id = uf.factor_type_id;
  
CREATE OR REPLACE VIEW csr.v$factor_type AS
SELECT f.factor_type_id, f.parent_id, f.name, f.std_measure_id, f.egrid, af.active, uf.in_use
  FROM csr.factor_type f
  LEFT JOIN (
    SELECT factor_type_id, 1 active FROM (
          SELECT DISTINCT af.factor_type_id
            FROM csr.factor_type af
           START WITH af.factor_type_id
            IN (
              SELECT DISTINCT aaf.factor_type_id
                FROM csr.factor_type aaf
                JOIN csr.std_factor sf ON sf.factor_type_id = aaf.factor_type_id
                JOIN csr.std_factor_set_active sfa ON sfa.std_factor_set_id = sf.std_factor_set_id
            )
           CONNECT BY PRIOR parent_id = af.factor_type_id
          UNION
          SELECT DISTINCT f.factor_type_id
            FROM csr.factor_type f
                 START WITH f.factor_type_id
                  IN (
              SELECT DISTINCT f.factor_type_id
                FROM csr.factor_type f
                JOIN csr.custom_factor sf ON sf.factor_type_id = f.factor_type_id
                 AND sf.app_sid = security.security_pkg.getApp
               WHERE std_measure_id IS NOT NULL
            )
          CONNECT BY PRIOR parent_id = f.factor_type_id
          UNION ALL
          SELECT 3 factor_type_id -- factor_pkg.UNSPECIFIED_FACTOR_TYPE
            FROM dual
        )) af ON f.factor_type_id = af.factor_type_id
   LEFT JOIN (
    SELECT factor_type_id, 1 in_use FROM (
      SELECT factor_type_id
        FROM csr.factor_type
       START WITH factor_type_id
          IN (
          SELECT DISTINCT factor_type_id
            FROM csr.factor
           WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
      )
      CONNECT BY PRIOR parent_id = factor_type_id
      UNION
      SELECT DISTINCT f.factor_type_id
        FROM csr.factor_type f
             START WITH f.factor_type_id
              IN (
          SELECT DISTINCT f.factor_type_id
            FROM csr.factor_type f
            JOIN csr.custom_factor sf ON sf.factor_type_id = f.factor_type_id
             AND sf.app_sid = security.security_pkg.getApp
           WHERE std_measure_id IS NOT NULL
        )
      CONNECT BY PRIOR parent_id = f.factor_type_id
      UNION ALL
      SELECT factor_type_id
        FROM csr.factor_type
       START WITH factor_type_id
          IN (
          SELECT DISTINCT factor_type_id
            FROM csr.factor
           WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
      )
      CONNECT BY PRIOR factor_type_id = parent_id
      UNION ALL
      SELECT 3 factor_type_id -- factor_pkg.UNSPECIFIED_FACTOR_TYPE
        FROM dual
        )) uf ON f.factor_type_id = uf.factor_type_id;
  
CREATE OR REPLACE VIEW cms.v$form AS
	SELECT f.app_sid, f.form_sid, f.description, f.lookup_key, f.parent_tab_sid, fv.form_version, f.current_version,
		   fv.file_name, fv.form_xml, fv.published_dtm, fv.published_by_sid, fv.version_comment, f.is_report_builder, f.short_path, f.use_quick_chart
	  FROM form f
	  JOIN form_version fv
		ON f.app_sid = fv.app_sid AND f.form_sid = fv.form_sid AND f.current_version = fv.form_version;
		
GRANT SELECT, REFERENCES ON cms.v$form TO csr;
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
		   iat.filename template_filename, iat.assign_issues_to_role, iat.add_nc_per_question, cvru.user_giving_cover_sid cover_auditor_sid,
		   fi.flow_sid, f.label flow_label, ia.flow_item_id, fi.current_state_id, fs.label flow_state_label, fs.is_final flow_state_is_final, 
		   fs.state_colour flow_state_colour, iat.summary_survey_sid, sqs.label summary_survey_label, ia.summary_response_id, act.is_failure,
		   ia.auditor_company_sid, ac.name auditor_company_name, iat.tab_sid, iat.form_path, ia.comparison_response_id, iat.nc_audit_child_region,
		   atg.label ia_type_group_label, atg.lookup_key ia_type_group_lookup_key, atg.internal_audit_type_group_id,
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
CREATE OR REPLACE VIEW csr.v$audit_next_due AS
	SELECT ia.internal_audit_sid, ia.internal_audit_type_id, ia.region_sid,
		   ia.audit_dtm previous_audit_dtm, act.audit_closure_type_id, ia.app_sid,
		   CASE (atct.re_audit_due_after_type)
				WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
				WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
				WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
				WHEN 'y' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after*12))
				ELSE ia.ovw_validity_dtm
		   END next_audit_due_dtm, atct.reminder_offset_days, act.label closure_label,
		   act.is_failure, ia.label previous_audit_label, act.icon_image_filename,
		   ia.auditor_user_sid previous_auditor_user_sid, ia.flow_item_id,
		   cast(act.icon_image_sha1 as VARCHAR2(40)) icon_image_sha1
	  FROM (
		SELECT internal_audit_sid, internal_audit_type_id, region_sid, audit_dtm,
			   ROW_NUMBER() OVER (
					PARTITION BY internal_audit_type_id, region_sid
					ORDER BY audit_dtm DESC) rn, -- take most recent audit of each type/region
			   audit_closure_type_id, app_sid, label, auditor_user_sid, flow_item_id, deleted, ovw_validity_dtm
		  FROM csr.internal_audit
		 WHERE deleted = 0
		   ) ia
	  JOIN csr.audit_type_closure_type atct
		ON ia.audit_closure_type_id = atct.audit_closure_type_id
	   AND ia.app_sid = atct.app_sid
	   AND ia.internal_audit_type_id = atct.internal_audit_type_id
	  JOIN csr.audit_closure_type act
		ON atct.audit_closure_type_id = act.audit_closure_type_id
	   AND atct.app_sid = act.app_sid
	  JOIN csr.region r ON ia.region_sid = r.region_sid AND ia.app_sid = r.app_sid
	 WHERE rn = 1
	   AND atct.re_audit_due_after IS NOT NULL
	   AND r.active=1
	   AND ia.audit_closure_type_id IS NOT NULL
	   AND ia.deleted = 0;




BEGIN
	security.user_pkg.logonadmin;
	FOR r IN (
		SELECT sid_id
		  FROM security.menu
		 WHERE action = '/csr/site/chain/import/import.acds'
	) LOOP
		security.securableobject_pkg.DeleteSO(security.security_pkg.GetACT, r.sid_id);
	END LOOP;
END;
/
UPDATE csr.region r
   SET acquisition_dtm = NULL
 WHERE EXISTS (
	SELECT NULL 
	  FROM csr.est_meter
	 WHERE first_bill_dtm < TO_DATE('01-01-1900', 'DD-MM-YYYY')
	   AND region_sid = r.region_sid);
	
UPDATE CSR.PLUGIN 
   SET js_class = 'Credit360.EmissionFactors.MapIndicatorsTab'
 WHERE js_class = 'Controls.MapIndicatorsTab';
SET DEFINE OFF
BEGIN
	
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (1, 'Brazilian Agricultural Yearbook');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (2, 'Australia National Greenhouse Accounts (NGA)');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (3, 'Canada National Inventory Report ');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (4, 'China National Bureau of Statistics');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (5, 'US Environmental Protection Agency (EPA) Climate Leaders');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (6, 'US Environmental Protection Agency (EPA) Egrid');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (7, 'Greenhouse Gas Protocol');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (8, 'Intergovernmental Panel on Climate Change (IPCC)');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (9, 'International Energy Agency (IEA)');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (10, 'Inventory of Carbon & Energy (ICE)');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (11, 'New Zealand Ministry for the Environment');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (12, 'The Climate Registry');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (13, 'Reliable Disclosure (RE-DISS) European Residual Mixes');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (14, 'Taiwan Bureau of Energy');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (15, 'UK CRC Energy Efficiency Scheme');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (16, 'UK Department for Environment, Food & Rural Affairs (Defra)');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (17, 'US Energy Information Administration');
	
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 16
	 WHERE std_factor_set_id = 1;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 2;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 7
	 WHERE std_factor_set_id = 3;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 2
	 WHERE std_factor_set_id = 4;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 3
	 WHERE std_factor_set_id = 5;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 12
	 WHERE std_factor_set_id = 6;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 7
	 WHERE std_factor_set_id = 7;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 16
	 WHERE std_factor_set_id = 8;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 9;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 10;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 11;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 12;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 9
	 WHERE std_factor_set_id = 13;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 16
	 WHERE std_factor_set_id = 14;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 16
	 WHERE std_factor_set_id = 15;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 16;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 17;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 9
	 WHERE std_factor_set_id = 18;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 1
	 WHERE std_factor_set_id = 19;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 8
	 WHERE std_factor_set_id = 20;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 7
	 WHERE std_factor_set_id = 21;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 22;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 12
	 WHERE std_factor_set_id = 23;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 2
	 WHERE std_factor_set_id = 24;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 4
	 WHERE std_factor_set_id = 25;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 14
	 WHERE std_factor_set_id = 26;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 3
	 WHERE std_factor_set_id = 27;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 3
	 WHERE std_factor_set_id = 28;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 11
	 WHERE std_factor_set_id = 29;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 5
	 WHERE std_factor_set_id = 30;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 17
	 WHERE std_factor_set_id = 31;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 16
	 WHERE std_factor_set_id = 32;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 16
	 WHERE std_factor_set_id = 33;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 16
	 WHERE std_factor_set_id = 34;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 16
	 WHERE std_factor_set_id = 35;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 8
	 WHERE std_factor_set_id = 36;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 8
	 WHERE std_factor_set_id = 37;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 8
	 WHERE std_factor_set_id = 38;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 39;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 15
	 WHERE std_factor_set_id = 40;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 12
	 WHERE std_factor_set_id = 41;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 8
	 WHERE std_factor_set_id = 42;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 11
	 WHERE std_factor_set_id = 43;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 11
	 WHERE std_factor_set_id = 44;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 10
	 WHERE std_factor_set_id = 45;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 9
	 WHERE std_factor_set_id = 46;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 47;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 7
	 WHERE std_factor_set_id = 48;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 16
	 WHERE std_factor_set_id = 49;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 12
	 WHERE std_factor_set_id = 50;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 5
	 WHERE std_factor_set_id = 51;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 9
	 WHERE std_factor_set_id = 52;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 3
	 WHERE std_factor_set_id = 53;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 2
	 WHERE std_factor_set_id = 54;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 16
	 WHERE std_factor_set_id = 55;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 13
	 WHERE std_factor_set_id = 56;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 16
	 WHERE std_factor_set_id = 57;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 9
	 WHERE std_factor_set_id = 58;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 3
	 WHERE std_factor_set_id = 59;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 2
	 WHERE std_factor_set_id = 60;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 5
	 WHERE std_factor_set_id = 61;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 62;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 63;
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 64;
END;
/
SET DEFINE &
INSERT INTO csr.capability (name, allow_by_default) VALUES ('Can import std factor set', 0);
INSERT INTO csr.capability (name, allow_by_default) VALUES ('Can publish std factor set', 0);
DECLARE
	v_act_id 					security.security_pkg.T_ACT_ID;
	v_app_sid 					security.security_pkg.T_SID_ID;
	v_menu						security.security_pkg.T_SID_ID;
	v_sa_sid					security.security_pkg.T_SID_ID;
	v_setup_menu				security.security_pkg.T_SID_ID;
	v_factorset_menu			security.security_pkg.T_SID_ID;
	PROCEDURE EnableCapability(
		in_capability  					IN	security.security_pkg.T_SO_NAME,
		in_swallow_dup_exception    	IN  NUMBER DEFAULT 1
	)
	AS
		v_allow_by_default      csr.capability.allow_by_default%TYPE;
		v_capability_sid		security.security_pkg.T_SID_ID;
		v_capabilities_sid		security.security_pkg.T_SID_ID;
	BEGIN
		-- this also serves to check that the capability is valid
		BEGIN
			SELECT allow_by_default
			  INTO v_allow_by_default
			  FROM csr.capability
			 WHERE LOWER(name) = LOWER(in_capability);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20001, 'Unknown capability "'||in_capability||'"');
		END;
		-- just create a sec obj of the right type in the right place
		BEGIN
			v_capabilities_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
					SYS_CONTEXT('SECURITY','APP'), 
					security.security_pkg.SO_CONTAINER,
					'Capabilities',
					v_capabilities_sid
				);
		END;
		
		BEGIN
			security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
				v_capabilities_sid, 
				security.class_pkg.GetClassId('CSRCapability'),
				in_capability,
				v_capability_sid
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				IF in_swallow_dup_exception = 0 THEN
					RAISE_APPLICATION_ERROR(security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, SQLERRM);
				END IF;
		END;
	END;
BEGIN
	FOR r IN (SELECT host FROM csr.customer WHERE host = 'emissionfactors.credit360.com')
	LOOP
		security.user_pkg.logonadmin(r.host);
		
		v_act_id 	:= security.security_pkg.GetAct;
		v_app_sid 	:= security.security_pkg.GetApp;
		v_menu		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu');
		v_sa_sid	:= security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');
		
		EnableCapability('Can import std factor set', 1);
		EnableCapability('Can publish std factor set', 1);
		
		BEGIN
			v_setup_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'Setup');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.menu_pkg.CreateMenu(v_act_id, v_menu, 'setup', 'Setup', '/csr/site/admin/config/global.acds', 0, null, v_setup_menu);
		END;
	
		BEGIN
			v_factorset_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_setup_menu, 'csr_admin_factor_sets');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.menu_pkg.CreateMenu(v_act_id, v_setup_menu, 'csr_admin_factor_sets', 'Factor sets',
					'/csr/site/admin/emissionFactors/new/factorsetgroups.acds', 0, null, v_factorset_menu);
		END;
		
		-- don't inherit dacls
		security.securableobject_pkg.SetFlags(v_act_id, v_factorset_menu, 0);
		--Remove inherited ones
		security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_factorset_menu));
		-- Add SA permission
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_factorset_menu), -1, security.security_pkg.ACE_TYPE_ALLOW, 
			security.security_pkg.ACE_FLAG_DEFAULT, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			
		
		security.user_pkg.logoff(sys_context('security','act'));
	END LOOP;
END;
/
DECLARE
	v_act_id				security.security_pkg.T_ACT_ID;
	v_superadmins_sid		security.security_pkg.T_SID_ID;
	v_web_root_sid			security.security_pkg.T_SID_ID;
	v_web_forms_sid			security.security_pkg.T_SID_ID;
	v_registered_users_sid	security.security_pkg.T_SID_ID;
BEGIN
  security.user_pkg.logonAdmin();
  v_act_id := SYS_CONTEXT('SECURITY','ACT');
  v_superadmins_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, 0, '//csr/SuperAdmins');
  FOR r IN (
    SELECT host, app_sid
      FROM csr.customer
    ) LOOP
    BEGIN
      v_web_root_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, r.app_sid,'wwwroot');
      BEGIN
        v_web_forms_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, v_web_root_sid,'forms');
      EXCEPTION
        WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_web_root_sid, v_web_root_sid, 'forms', v_web_forms_sid);
			v_registered_users_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, r.app_sid,'Groups/RegisteredUsers');
			security.ACL_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSid(v_web_forms_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_registered_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
      END;
    END;
	security.ACL_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSid(v_web_forms_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
  END LOOP;
END;
/
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (83, 'Incidents', 'EnableIncidents', 'Enables the incidents module');
BEGIN
	security.user_pkg.LogonAdmin;
	
	UPDATE chain.filter_value
	   SET null_filter = 1
	 WHERE null_filter = 0
	   AND description = 'Is n/a'
	   AND filter_type = 1;
END;
/

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
	v_plugin_id NUMBER;
BEGIN
	v_plugin_id := csr.temp_SetCorePlugin(
		in_plugin_type_id		=> 10, /* csr.csr_data_pkg.PLUGIN_TYPE_CHAIN_COMPANY_TAB */
		in_description			=> 'Supplier followers',
		in_js_class				=> 'Chain.ManageCompany.SupplierFollowersTab',
		in_js_include			=> '/csr/site/chain/manageCompany/controls/SupplierFollowersTab.js',
		in_cs_class				=> 'Credit360.Chain.Plugins.SupplierFollowersDto',
		in_details				=> 'This tab shows the followers of the selected company, and given the correct permissions, will allow adding/removing followers.'
	);
END;
/
DROP FUNCTION csr.Temp_SetCorePlugin;
CREATE OR REPLACE PROCEDURE chain.Temp_RegisterCapability (
	in_capability_type			IN  NUMBER,
	in_capability				IN  VARCHAR2, 
	in_perm_type				IN  NUMBER,
	in_is_supplier				IN  NUMBER DEFAULT 0
)
AS
	v_count						NUMBER(10);
	v_ct						NUMBER(10);
BEGIN
	IF in_capability_type = 3 /*chain_pkg.CT_COMPANIES*/ THEN
		Temp_RegisterCapability(1 /*chain_pkg.CT_COMPANY*/, in_capability, in_perm_type);
		Temp_RegisterCapability(2 /*chain_pkg.CT_SUPPLIERS*/, in_capability, in_perm_type, 1);
		RETURN;	
	END IF;
	
	IF in_capability_type = 1 AND in_is_supplier <> 0 /* chain_pkg.IS_NOT_SUPPLIER_CAPABILITY */ THEN
		RAISE_APPLICATION_ERROR(-20001, 'Company capabilities cannot be supplier centric');
	ELSIF in_capability_type = 2 /* chain_pkg.CT_SUPPLIERS */ AND in_is_supplier <> 1 /* chain_pkg.IS_SUPPLIER_CAPABILITY */ THEN
		RAISE_APPLICATION_ERROR(-20001, 'Supplier capabilities must be supplier centric');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;
	
	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND (
			(capability_type_id = 0 /*chain_pkg.CT_COMMON*/ AND (in_capability_type = 0 /*chain_pkg.CT_COMPANY*/ OR in_capability_type = 2 /*chain_pkg.CT_SUPPLIERS*/))
	   		 OR (in_capability_type = 0 /*chain_pkg.CT_COMMON*/ AND (capability_type_id = 1 /*chain_pkg.CT_COMPANY*/ OR capability_type_id = 2 /*chain_pkg.CT_SUPPLIERS*/))
	   	   );
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;
	
	INSERT INTO chain.capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(chain.capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type, in_is_supplier);
	
END;
/
DECLARE 
	v_capability_id		NUMBER;
BEGIN
	chain.Temp_RegisterCapability(
		in_capability_type	=> 0,  								/* CT_COMMON*/
		in_capability		=> 'Edit own follower status' 		/* chain.chain_pkg.EDIT_OWN_FOLLOWER_STATUS */, 
		in_perm_type		=> 1, 								/* BOOLEAN_PERMISSION */
		in_is_supplier 		=> 1								/* chain_pkg.IS_SUPPLIER_CAPABILITY */
	);
END;
/
DROP PROCEDURE chain.Temp_RegisterCapability;
CREATE OR REPLACE PROCEDURE chain.tmp_GrantCapability (
	in_capability_type		IN  NUMBER,
	in_capability			IN  VARCHAR2,
	in_group				IN  VARCHAR2,
	in_permission_set		IN  security.security_pkg.T_PERMISSION
)
AS
	v_capability_id			NUMBER;
	v_company_group_type_id	NUMBER;
BEGIN
	SELECT capability_id
	  INTO v_capability_id
	  FROM capability
	 WHERE capability_type_id = in_capability_type
	   AND capability_name = in_capability;
	
	SELECT company_group_type_id
	  INTO v_company_group_type_id
	  FROM company_group_type
	 WHERE name = in_group;
	
	INSERT INTO chain.group_capability(group_capability_id, company_group_type_id, capability_id, permission_set)
		VALUES(chain.group_capability_id_seq.NEXTVAL, v_company_group_type_id, v_capability_id, in_permission_set);
END;
/
BEGIN
	security.user_pkg.logonadmin;
	chain.tmp_GrantCapability(0 /* chain.chain_pkg.CT_COMMON */,   'Edit own follower status', 'Users', security.security_pkg.PERMISSION_WRITE);
END;
/
DROP PROCEDURE chain.tmp_GrantCapability;
BEGIN
	security.user_pkg.logonadmin;
	
	INSERT INTO chain.company_type_capability
	(app_sid, primary_company_type_id, secondary_company_type_id, primary_company_group_type_id, capability_id, permission_set)
		SELECT ct.app_sid, ct.company_type_id, ctr.secondary_company_type_id, gc.company_group_type_id, gc.capability_id, gc.permission_set
		  FROM chain.group_capability gc, chain.capability c, chain.company_type_relationship ctr, chain.company_type ct
		 WHERE ct.app_sid = ctr.app_sid
		   AND ct.company_type_id = ctr.primary_company_type_id
		   AND gc.capability_id = c.capability_id
		   AND c.capability_name = 'Edit own follower status'
		   AND (ctr.primary_company_type_id, ctr.secondary_company_type_id, gc.company_group_type_id, gc.capability_id) NOT IN (
				SELECT primary_company_type_id, secondary_company_type_id, primary_company_group_type_id, capability_id
				  FROM chain.company_type_capability
		   );
END;
/
UPDATE csr.AUTOMATED_IMPORT_CLASS_STEP
   SET plugin = REPLACE(plugin, '.AutomatedExportImport.', '.ExportImport.Automated.');
INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (0, 'Full user export', 'Credit360.ExportImport.Export.Batched.Exporters.FullUserListExporter');
INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (1, 'Filtered user export', 'Credit360.ExportImport.Export.Batched.Exporters.FilteredUserListExporter');
INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (2, 'Region list export', 'Credit360.ExportImport.Export.Batched.Exporters.RegionListExporter');
INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (3, 'Indicator list export', 'Credit360.ExportImport.Export.Batched.Exporters.IndicatorListExporter');
INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (4, 'Data export', 'Credit360.ExportImport.Export.Batched.Exporters.DataExportExporter');
INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (5, 'Region role membership export', 'Credit360.ExportImport.Export.Batched.Exporters.RegionRoleExporter');
INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (6, 'Region and meter export', 'Credit360.ExportImport.Export.Batched.Exporters.RegionAndMeterExporter');
INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (7, 'Measure list export', 'Credit360.ExportImport.Export.Batched.Exporters.MeasureListExporter');
UPDATE csr.auto_exp_exporter_plugin
   SET exporter_assembly = REPLACE(exporter_assembly, '.AutomatedExportImport.', '.ExportImport.Automated.'),
       outputter_assembly = REPLACE(outputter_assembly, '.AutomatedExportImport.', '.ExportImport.Automated.');
UPDATE csr.AUTO_EXP_FILE_WRITER_PLUGIN
   SET assembly = REPLACE(assembly, '.AutomatedExportImport.', '.ExportImport.Automated.');
UPDATE csr.AUTO_IMP_FILEREAD_PLUGIN
   SET fileread_assembly = REPLACE(fileread_assembly, '.AutomatedExportImport.', '.ExportImport.Automated.');
UPDATE csr.AUTO_IMP_IMPORTER_PLUGIN
   SET importer_assembly = REPLACE(importer_assembly, '.AutomatedExportImport.', '.ExportImport.Automated.');
INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
VALUES (27, 'Batched exporter', null, 'batch-exporter', 0, null);
DECLARE
	v_act_id 					security.security_pkg.T_ACT_ID;
	v_reg_users_sid				security.security_pkg.T_SID_ID;
	v_www_root					security.security_pkg.T_SID_ID;
	v_www_csr_site				security.security_pkg.T_SID_ID;
	v_www_csr_site_batchExports	security.security_pkg.T_SID_ID;
	v_sid						security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin();
	v_act_id := security.security_pkg.GetAct();
	
	FOR r IN (
		SELECT app_sid FROM csr.customer
	)
	LOOP
	
	-- Web resource
		v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'wwwroot');
		BEGIN
			v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_root, 'csr/site');
		
			BEGIN
				v_www_csr_site_batchExports := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_www_csr_site, 'batchExports');
			EXCEPTION 
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_csr_site, 'batchExports', v_www_csr_site_batchExports);	
					
					-- give the RegisteredUsers group READ permission on the resource
					security.acl_pkg.AddACE(
						v_act_id, 
						security.acl_pkg.GetDACLIDForSID(v_www_csr_site_batchExports), 
						security.security_pkg.ACL_INDEX_LAST, 
						security.security_pkg.ACE_TYPE_ALLOW,
						security.security_pkg.ACE_FLAG_DEFAULT, 
						security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'Groups/RegisteredUsers'), 
						security.security_pkg.PERMISSION_STANDARD_READ
					);	
			END;
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
		
		-- Container for batch export dataviews
		BEGIN
			security.Securableobject_Pkg.CreateSO(v_act_id, r.app_sid, security.security_pkg.SO_CONTAINER, 'BatchExportDataviews', v_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, r.app_sid, 'BatchExportDataviews');
		END;
		-- give the RegisteredUsers group READ/WRITE permission on the resource
		security.acl_pkg.AddACE(
			v_act_id, 
			security.acl_pkg.GetDACLIDForSID(v_sid), 
			security.security_pkg.ACL_INDEX_LAST, 
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, 
			security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'Groups/RegisteredUsers'), 
			security.security_pkg.PERMISSION_STANDARD_READ + security.security_pkg.PERMISSION_WRITE + security.security_pkg.PERMISSION_DELETE + security.security_pkg.PERMISSION_ADD_CONTENTS
		);
	END LOOP;
END;
/
BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'csr.BATCHEDEXPORTSCLEARUP',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN security.user_pkg.logonadmin(); csr.batch_exporter_pkg.ScheduledFileClearUp; commit; END;',
	job_class		=> 'low_priority_job',
	start_date		=> to_timestamp_tz('2016/09/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
	repeat_interval	=> 'FREQ=DAILY',
	enabled			=> TRUE,
	auto_drop		=> FALSE,
	comments		=> 'Schedule for removing batched exports file data from the database, so we do not use endless space');
END;
/




CREATE OR REPLACE PACKAGE csr.batch_exporter_pkg as end;
/
GRANT EXECUTE ON csr.batch_exporter_pkg TO WEB_USER;

BEGIN
	INSERT INTO csr.std_measure (
		std_measure_id, name, description, scale, format_mask, regional_aggregation, custom_field, pct_ownership_applies, m, kg, s, a, k, mol, cd
	) VALUES (
		41, 'm.s^2/kg', 'm.s^2/kg', 0, '#,##0', 'sum', NULL, 0, 1, -1, 2, 0, 0, 0, 0
	);

	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28195, 3, 'm^3/m^2', 1, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28196, 5, 'cGal (UK)', 2.1997360, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28197, 5, 'cGal (US)', 2.64200793, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28198, 5, 'kcf', 0.03531073, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28199, 5, 'Kcm', 0.001, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28200, 5, 'MCF', 0.0000353144754, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28201, 5, 'MGal (UK)', 0.0002199736, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28202, 5, 'MGal (US)', 0.0002642008, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28203, 27, 'g/m^2', 1000, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28204, 3, 'cm', 100, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28205, 41, 'l/MJ', 1000000000, 1, 0, 1);
END;
/

@..\structure_import_pkg
@..\factor_pkg
@..\factor_set_group_pkg
@@..\..\..\security\db\oracle\web_pkg
@@..\..\..\aspen2\cms\db\form_pkg
@@..\..\..\aspen2\cms\db\tab_pkg
@..\schema_pkg
@..\csrimp\imp_pkg
@..\delegation_pkg
@..\enable_pkg
@..\chain\chain_pkg
@..\chain\company_pkg
@..\chain\company_user_pkg
@..\meter_pkg
@..\audit_pkg
@..\audit_report_pkg
@..\non_compliance_report_pkg
@..\chain\filter_pkg
@..\chain\company_filter_pkg
@..\initiative_report_pkg
@..\csr_user_pkg
@..\batch_job_pkg
@..\batch_exporter_pkg


@..\structure_import_body
@..\energy_star_body
@..\factor_body
@..\indicator_body
@..\sheet_body
@..\factor_set_group_body
@..\schema_body
@..\csrimp\imp_body
@@..\campaign_body
@@..\templated_report_body
@@..\..\..\security\db\oracle\web_body
@@..\..\..\aspen2\cms\db\form_body
@@..\..\..\aspen2\cms\db\tab_body
@@..\csrimp\imp_body
@..\property_report_body
@..\delegation_body
@..\deleg_plan_body
@..\enable_body
@..\supplier_body
@..\chain\company_body
@..\chain\company_user_body
@..\chain\company_filter_body
@..\flow_body
@..\audit_body
@..\quick_survey_body
@..\audit_report_body
@..\training_body
@..\meter_body
@..\non_compliance_report_body
@..\chain\filter_body
@..\..\..\aspen2\cms\db\pivot_body
@..\initiative_report_body
@..\chain\bsci_body
@..\csr_user_body
@..\batch_exporter_body



@update_tail
