-- Please update version.sql too -- this keeps clean builds in sync
define version=3096
define minor_version=32
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE CSR.COMPLIANCE_PERMIT_SCORE_ID_SEQ;

CREATE TABLE CSR.COMPLIANCE_PERMIT_SCORE (
	APP_SID							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	COMPLIANCE_PERMIT_SCORE_ID		NUMBER(10, 0)	NOT NULL,
	COMPLIANCE_PERMIT_ID			NUMBER(10, 0)	NOT NULL,
	SCORE_THRESHOLD_ID				NUMBER(10, 0),
	SCORE_TYPE_ID					NUMBER(10, 0)	NOT NULL,
	SCORE							NUMBER(15, 5),
	COMMENT_TEXT					CLOB,
	SET_DTM							DATE			DEFAULT TRUNC(SYSDATE) NOT NULL,
	CHANGED_BY_USER_SID				NUMBER(10, 0),
	VALID_UNTIL_DTM					DATE,
	SCORE_SOURCE_TYPE				NUMBER(10, 0),
	SCORE_SOURCE_ID					NUMBER(10, 0),
	IS_OVERRIDE						NUMBER(1)		DEFAULT 0 NOT NULL,
	CONSTRAINT PK_COMPIANCE_PERMIT_SCORE PRIMARY KEY (APP_SID, COMPLIANCE_PERMIT_SCORE_ID),
	CONSTRAINT UK_SUPPLIER_RELATIONSHIP_SCORE UNIQUE (APP_SID, COMPLIANCE_PERMIT_ID, SET_DTM, IS_OVERRIDE),
	CONSTRAINT CHK_COMP_PERM_SCORE_SET_DTM CHECK (SET_DTM = TRUNC(SET_DTM)),
	CONSTRAINT CHK_COMP_PERM_SCORE_VLD_DTM CHECK (VALID_UNTIL_DTM = TRUNC(VALID_UNTIL_DTM)),
	CONSTRAINT CHK_IS_OVERRIDE CHECK (IS_OVERRIDE IN (0,1))
);

CREATE INDEX csr.ix_perm_score_perm ON csr.compliance_permit_score (app_sid, compliance_permit_id);
CREATE INDEX csr.ix_perm_score_type ON csr.compliance_permit_score (app_sid, score_type_id);
CREATE INDEX csr.ix_perm_score_csr_user ON csr.compliance_permit_score (app_sid, changed_by_user_sid);
CREATE INDEX csr.ix_perm_score_threshold ON csr.compliance_permit_score (app_sid, score_threshold_id);
CREATE UNIQUE INDEX csr.ix_perm_score_view ON csr.compliance_permit_score (app_sid, compliance_permit_id, score_type_id, set_dtm, is_override);

CREATE TABLE CSRIMP.COMPLIANCE_PERMIT_SCORE (
	CSRIMP_SESSION_ID 				NUMBER(10) 		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	COMPLIANCE_PERMIT_SCORE_ID		NUMBER(10, 0)	NOT NULL,
	COMPLIANCE_PERMIT_ID			NUMBER(10, 0)	NOT NULL,
	SCORE_THRESHOLD_ID				NUMBER(10, 0),
	SCORE_TYPE_ID					NUMBER(10, 0)	NOT NULL,
	SCORE							NUMBER(15, 5),
	COMMENT_TEXT					CLOB,
	SET_DTM							DATE			NOT NULL,
	CHANGED_BY_USER_SID				NUMBER(10, 0),
	VALID_UNTIL_DTM					DATE,
	SCORE_SOURCE_TYPE				NUMBER(10, 0),
	SCORE_SOURCE_ID					NUMBER(10, 0),
	IS_OVERRIDE						NUMBER(1)		NOT NULL,
	LAST_PERMIT_SCORE_LOG_ID 		NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_COMPL_PERMIT_SCORE PRIMARY KEY (CSRIMP_SESSION_ID, COMPLIANCE_PERMIT_SCORE_ID),
	CONSTRAINT FK_COMPL_PERMIT_SCORE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_COMPLIANCE_PERMIT_SCORE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPLIANCE_PERMIT_SCORE_ID NUMBER(10) NOT NULL,
	NEW_COMPLIANCE_PERMIT_SCORE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COMPLIANCE_PERMIT_SCORE PRIMARY KEY (OLD_COMPLIANCE_PERMIT_SCORE_ID) USING INDEX,
	CONSTRAINT UK_MAP_COMPLIANCE_PERMIT_SCORE UNIQUE (NEW_COMPLIANCE_PERMIT_SCORE_ID) USING INDEX,
	CONSTRAINT FK_MAP_COMPLI_PERMIT_SCORE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);


CREATE TABLE csr.compliance_permit_header (
    app_sid							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    plugin_id         				NUMBER(10, 0)	NOT NULL,
    plugin_type_id    				NUMBER(10, 0)	NOT NULL,
    pos               				NUMBER(10, 0)	NOT NULL,
    CONSTRAINT pk_permit_header  PRIMARY KEY (app_sid, plugin_id),
    CONSTRAINT ck_permit_header_plugin_type CHECK (plugin_type_id = 22)
);

CREATE INDEX ix_compli_permit_hdr_plugin ON csr.compliance_permit_header (plugin_id, plugin_type_id);

ALTER TABLE csr.compliance_permit_header ADD CONSTRAINT fk_compli_permit_hdr_plugin
    FOREIGN KEY (plugin_id, plugin_type_id)
    REFERENCES csr.plugin(plugin_id, plugin_type_id);

CREATE TABLE csr.compliance_permit_header_group (
    app_sid							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    plugin_id         				NUMBER(10, 0)	NOT NULL,
    group_sid						NUMBER(10, 0),
    role_sid						NUMBER(10, 0),
    CONSTRAINT pk_permit_header_group PRIMARY KEY (app_sid, plugin_id, group_sid),
    CONSTRAINT ck_permit_hdr_group_grp_role CHECK (
		(group_sid IS NULL AND role_sid IS NOT NULL) OR 
		(group_sid IS NOT NULL AND role_sid IS NULL)
	)
);

CREATE INDEX csr.ix_compliance_permit_hdr_role ON csr.compliance_permit_header_group (app_sid, role_sid);

ALTER TABLE csr.compliance_permit_header_group ADD CONSTRAINT fk_compliance_permit_hdr_group
    FOREIGN KEY (app_sid, plugin_id)
    REFERENCES csr.compliance_permit_header (app_sid, plugin_id);

ALTER TABLE csr.compliance_permit_header_group ADD CONSTRAINT fk_compliance_permit_hdr_role
    FOREIGN KEY (app_sid, role_sid)
    REFERENCES csr.role (app_sid, role_sid);

CREATE TABLE csrimp.compliance_permit_header(
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    plugin_id         				NUMBER(10, 0)	NOT NULL,
    plugin_type_id    				NUMBER(10, 0)	NOT NULL,
    pos               				NUMBER(10, 0)	NOT NULL,
    CONSTRAINT pk_permit_header PRIMARY KEY (csrimp_session_id, plugin_id),
    CONSTRAINT fk_permit_header_is 
		FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.compliance_permit_header_group (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    plugin_id         				NUMBER(10, 0)	NOT NULL,
    group_sid						NUMBER(10, 0),
    role_sid						NUMBER(10, 0),
    CONSTRAINT pk_permit_header_group PRIMARY KEY (csrimp_session_id, plugin_id, group_sid),
    CONSTRAINT fk_permit_header_group_is 
		FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE CSR.COMPLIANCE_PERMIT_SCORE ADD CONSTRAINT FK_COMPL_PERM_SCRE_COMPL_PERM
	FOREIGN KEY (APP_SID, COMPLIANCE_PERMIT_ID)
	REFERENCES CSR.COMPLIANCE_PERMIT (APP_SID, COMPLIANCE_PERMIT_ID);

ALTER TABLE CSR.COMPLIANCE_PERMIT_SCORE ADD CONSTRAINT FK_COMPL_PERM_SCRE_SCORE_TYPE 
	FOREIGN KEY (APP_SID, SCORE_TYPE_ID)
	REFERENCES CSR.SCORE_TYPE(APP_SID, SCORE_TYPE_ID);

ALTER TABLE CSR.COMPLIANCE_PERMIT_SCORE ADD CONSTRAINT FK_COMPL_PERM_SCRE_SCORE_THRSH 
	FOREIGN KEY (APP_SID, SCORE_THRESHOLD_ID)
	REFERENCES CSR.SCORE_THRESHOLD(APP_SID, SCORE_THRESHOLD_ID);
	
ALTER TABLE CSR.COMPLIANCE_PERMIT_SCORE ADD CONSTRAINT FK_COMPL_PERM_SCRE_CSR_USER 
	FOREIGN KEY (APP_SID, CHANGED_BY_USER_SID)
	REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID);
	
ALTER TABLE csr.score_type ADD (
	applies_to_permits				NUMBER(1, 0) DEFAULT 0 NOT NULL,
    CONSTRAINT ck_score_type_app_to_perm CHECK (applies_to_permits IN (0, 1))
);

ALTER TABLE csrimp.score_type ADD (
	applies_to_permits				NUMBER(1, 0) NOT NULL
);

ALTER TABLE csr.internal_audit ADD (
	permit_id		NUMBER(10, 0),
	CONSTRAINT FK_IA_COMPL_PERMIT FOREIGN KEY (APP_SID, PERMIT_ID) REFERENCES CSR.COMPLIANCE_PERMIT (APP_SID, COMPLIANCE_PERMIT_ID)
);

create index csr.ix_internal_audi_permit_id on csr.internal_audit (app_sid, permit_id);

ALTER TABLE csrimp.internal_audit ADD (
	permit_id		NUMBER(10, 0)
);

ALTER TABLE csr.internal_audit_type_group ADD (
	applies_to_permits		NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT ck_iatg_appl_to_permits CHECK (applies_to_permits IN (0,1))
);

ALTER TABLE csr.internal_audit_type_group DROP CONSTRAINT CK_IATG_MUST_APPL_TO_STHNG;

ALTER TABLE csr.internal_audit_type_group ADD (
	CONSTRAINT CK_IATG_MUST_APPL_TO_STHNG CHECK (applies_to_regions = 1 OR applies_to_users = 1 OR applies_to_permits = 1)
);

ALTER TABLE csrimp.internal_audit_type_group ADD (
	applies_to_permits		NUMBER(1) NOT NULL
);
	
-- *** Grants ***
GRANT SELECT ON CSR.COMPLIANCE_PERMIT_SCORE_ID_SEQ TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.compliance_permit_score TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_permit_score TO tool_user;

grant select, insert, update, delete on csrimp.compliance_permit_header to tool_user;
grant select, insert, update, delete on csrimp.compliance_permit_header_group to tool_user;
grant select, insert, update on csr.compliance_permit_header to csrimp;
grant select, insert, update on csr.compliance_permit_header_group to csrimp;

grant select, insert, update on chain.filter_page_column to csr;

-- ** Cross schema constraints ***
	
-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
-- csr/db/create_views.sql
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

-- csr/db/create_views.sql
/***********************************************************************
	v$current_raw_compl_perm_score - the current non-overridden (raw) compliance permit score
***********************************************************************/
CREATE OR REPLACE VIEW csr.v$current_raw_compl_perm_score AS
	SELECT 
		   compliance_permit_id, score_type_id, compliance_permit_score_id,
		   score_threshold_id, score, is_override, set_dtm, valid_until_dtm, 
		   comment_text, changed_by_user_sid, score_source_type, score_source_id
	  FROM compliance_permit_score cps
	 WHERE cps.set_dtm <= SYSDATE
	   AND (cps.valid_until_dtm IS NULL OR cps.valid_until_dtm > SYSDATE)
	   AND cps.is_override = 0
	   AND NOT EXISTS (
			SELECT NULL
			  FROM compliance_permit_score cps2
			 WHERE cps2.app_sid = cps.app_sid
			   AND cps2.compliance_permit_id = cps.compliance_permit_id
			   AND cps2.score_type_id = cps.score_type_id
			   AND cps2.is_override = 0
			   AND cps2.set_dtm > cps.set_dtm
			   AND cps2.set_dtm <= SYSDATE
		);

-- csr/db/create_views.sql
/***********************************************************************
	v$current_ovr_compl_perm_score - the current overridden compliance permit score
***********************************************************************/
CREATE OR REPLACE VIEW csr.v$current_ovr_compl_perm_score AS
	SELECT 
		   compliance_permit_id, score_type_id, compliance_permit_score_id,
		   score_threshold_id, score, is_override, set_dtm, valid_until_dtm, 
		   comment_text, changed_by_user_sid, score_source_type, score_source_id
	  FROM compliance_permit_score cps
	 WHERE cps.set_dtm <= SYSDATE
	   AND (cps.valid_until_dtm IS NULL OR cps.valid_until_dtm > SYSDATE)
	   AND cps.is_override = 1
	   AND NOT EXISTS (
			SELECT NULL
			  FROM compliance_permit_score cps2
			 WHERE cps2.app_sid = cps.app_sid
			   AND cps2.compliance_permit_id = cps.compliance_permit_id
			   AND cps2.score_type_id = cps.score_type_id
			   AND cps2.is_override = 1
			   AND cps2.set_dtm > cps.set_dtm
			   AND cps2.set_dtm <= SYSDATE
		);
		
-- csr/db/create_views.sql
/***********************************************************************
	v$current_compl_perm_score_all - the current raw compliance permit score and corresponding overrides
***********************************************************************/
CREATE OR REPLACE VIEW csr.v$current_compl_perm_score_all AS
	SELECT 
		   compliance_permit_id, score_type_id, 
		   --
		   MAX(compliance_permit_score_id) raw_compliance_permit_score_id, 
		   MAX(score_threshold_id) raw_score_threshold_id, 
		   MAX(score) raw_score, 
		   MAX(set_dtm) raw_set_dtm, 
		   MAX(valid_until_dtm) raw_valid_until_dtm, 
		   MAX(changed_by_user_sid) raw_changed_by_user_sid, 
		   MAX(score_source_type) raw_score_source_type, 
		   MAX(score_source_id) raw_score_source_id, 
		   --
		   MAX(ovr_compliance_permit_score_id) ovr_compliance_permit_score_id, 
		   MAX(ovr_score_threshold_id) ovr_score_threshold_id, 
		   MAX(ovr_score) ovr_score, 
		   MAX(ovr_set_dtm) ovr_set_dtm, 
		   MAX(ovr_valid_until_dtm) ovr_valid_until_dtm,  
		   MAX(ovr_changed_by_user_sid) ovr_changed_by_user_sid, 
		   MAX(ovr_score_source_type) ovr_score_source_type, 
		   MAX(ovr_score_source_id) ovr_score_source_id
	  FROM (
			SELECT 
				   compliance_permit_id, score_type_id, 
				   --
				   compliance_permit_score_id, score_threshold_id, score, is_override, set_dtm, valid_until_dtm, 
				   changed_by_user_sid, score_source_type, score_source_id, 
				   --
				   NULL ovr_compliance_permit_score_id, NULL ovr_score_threshold_id, NULL ovr_score, NULL ovr_is_override, NULL ovr_set_dtm, NULL ovr_valid_until_dtm, 
				   NULL ovr_changed_by_user_sid, NULL ovr_score_source_type, NULL ovr_score_source_id
			  FROM v$current_raw_compl_perm_score
			 UNION ALL
			SELECT 
				   compliance_permit_id, score_type_id, 
				   --
				   NULL compliance_permit_score_id, NULL score_threshold_id, score, NULL is_override, NULL set_dtm, NULL valid_until_dtm, 
				   NULL changed_by_user_sid, NULL score_source_type, NULL score_source_id, 
				   --
				   compliance_permit_score_id ovr_compliance_permit_score_id, score_threshold_id ovr_score_threshold_id, score ovr_score, is_override ovr_is_override,
				   set_dtm ovr_set_dtm, valid_until_dtm ovr_valid_until_dtm, changed_by_user_sid ovr_changed_by_user_sid, score_source_type ovr_score_source_type, 
				   score_source_id ovr_score_source_id
			  FROM v$current_ovr_compl_perm_score
	)
	GROUP BY compliance_permit_id, score_type_id; 

-- csr/db/create_views.sql
/***********************************************************************
	v$current_compl_perm_score - the current returns overridden if set / raw if not
***********************************************************************/
CREATE OR REPLACE VIEW csr.v$current_compl_perm_score AS
	SELECT 
		   compliance_permit_id, score_type_id, 
		   --
		   NVL(ovr_score_threshold_id, raw_score_threshold_id) score_threshold_id, 
		   NVL(ovr_score, raw_score) score, 
		   NVL2(ovr_score, ovr_set_dtm, raw_set_dtm) set_dtm, 
		   NVL2(ovr_score, ovr_valid_until_dtm, raw_valid_until_dtm) valid_until_dtm, 
		   NVL2(ovr_score, ovr_changed_by_user_sid, raw_changed_by_user_sid) changed_by_user_sid, 
		   NVL2(ovr_score, ovr_score_source_type, raw_score_source_type) score_source_type, 
		   NVL2(ovr_score, ovr_score_source_id, raw_score_source_id) score_source_id
	  FROM v$current_compl_perm_score_all;
	  
-- *** Data changes ***
-- RLS

-- Data
	
INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES (csr.plugin_id_seq.nextval, 21, 'Permit audit tab', '/csr/site/compliance/controls/AuditList.js', 'Credit360.Compliance.Controls.AuditList', 'Credit360.Compliance.Plugins.AuditListPlugin', 'Shows permit audits.');

INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (22, 'Permit tab header');

insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
values (csr.plugin_id_seq.nextval, 22, 'Permit score', '/csr/site/compliance/permits/ScoreHeader.js', 'Credit360.Compliance.Permits.ScoreHeader', 'Credit360.Compliance.Plugins.ScoreHeaderDto', 'This header shows some stuff.');

DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
	v_group_id		  chain.card_group.card_group_id%TYPE;
BEGIN
	v_desc := 'Permit Audit Filter Adapter';
	v_class := 'Credit360.Compliance.Cards.PermitAuditFilterAdapter';
	v_js_path := '/csr/site/compliance/filters/permitAuditFilterAdapter.js';
	v_js_class := 'Credit360.Compliance.Filters.PermitAuditFilterAdapter';
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

	BEGIN
		INSERT INTO chain.filter_type (
			filter_type_id,
			description,
			helper_pkg,
			card_id
		) VALUES (
			chain.filter_type_id_seq.NEXTVAL,
			'Permit Audit Filter Adapter',
			'csr.permit_pkg',
			v_card_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		SELECT card_group_id
		  INTO v_group_id
		  FROM chain.card_group
		 WHERE LOWER(name) = LOWER('Compliance Permit Filter');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a card group with name = Basic Company Filter');
	END;
	
	FOR r IN (
		SELECT app_sid, NVL(MAX(position) + 1, 1) pos
		  FROM chain.card_group_card
		 WHERE card_group_id = v_group_id
		 GROUP BY app_sid
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card(app_sid, card_group_id, card_id, position)
			     VALUES (r.app_sid, v_group_id, v_card_id, r.pos);
		EXCEPTION
			WHEN dup_val_on_index THEN
				NULL;
		END;
	END LOOP;
END;
/

BEGIN
	FOR r IN (SELECT app_sid FROM csr.compliance_options WHERE permit_flow_sid IS NOT NULL)
	LOOP
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'auditDtm','Date',1,75,0,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'label','Label',2,130,0,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'internalAuditTypeLabel','Audit type',3,100,0,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'surveyScore','Survey score',4,90,0,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'flowStateLabel','Status',5,80,0,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'auditClosureTypeLabel','Result',6,80,0,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'openNonCompliances','Open findings',7,60,0,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'surveyCompleted','Survey submitted',8,110,0,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'auditorFullName','Audit coordinator',9,100,0,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'regionDescription','Region',10,100,1,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'internalAuditSid','ID',11,75,1,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'regionPath','Region path',12,100,1,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'ncScore','Finding score',13,60,1,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'surveyLabel','Survey',14,100,1,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'auditorName','Auditor',15,100,1,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'auditorOrganisation','Auditor Organisation',16,120,1,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'auditorCompany','Auditor Company',17,120,1,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'notes','Notes',18,130,1,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'createdDtm','Created date',19,75,1,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'nextAuditDueDtm','Expiry date',20,75,1,'csr_site_compliance_auditlist_');
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../quick_survey_pkg
@../permit_pkg
@../audit_helper_pkg
@../audit_pkg
@../permit_report_pkg

@../quick_survey_body
@../permit_body
@../audit_helper_body
@../flow_body
@../audit_body
@../enable_body
@../permit_report_body
@../audit_report_body
@../csr_app_body

@../csrimp/imp_body

@../schema_pkg
@../schema_body

@update_tail
