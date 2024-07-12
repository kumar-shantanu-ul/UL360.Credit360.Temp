define version=2049
@update_header

ALTER TABLE csr.internal_audit ADD (
	flow_item_id		NUMBER(10),
	CONSTRAINT fk_ia_flow_item FOREIGN KEY (app_sid, flow_item_id) REFERENCES csr.flow_item (app_sid, flow_item_id)
);

ALTER TABLE csr.internal_audit_type ADD (
	flow_sid			NUMBER(10),
	CONSTRAINT fk_iat_flow FOREIGN KEY (app_sid, flow_sid) REFERENCES csr.flow (app_sid, flow_sid)
);

ALTER TABLE csrimp.internal_audit ADD (
	flow_item_id		NUMBER(10)
);

ALTER TABLE csrimp.internal_audit_type ADD (
	flow_sid			NUMBER(10)
);

create index csr.ix_internal_audit_flow_item on csr.internal_audit (app_sid, flow_item_id);
create index csr.ix_flow_aggregate_ind on csr.flow (app_sid, aggregate_ind_group_id);
create index csr.ix_flow_state_ind_sid on csr.flow_state (app_sid, ind_sid);
create index csr.ix_flow_state_cm_column_sid on csr.flow_state_cms_col (app_sid, column_sid);
create index csr.ix_flow_state_tr_column_sid on csr.flow_state_transition_cms_col (app_sid, column_sid);
create index csr.ix_flow_transiti_column_sid on csr.flow_transition_alert_cms_col (app_sid, column_sid);
create index csr.ix_flow_transiti_user_sid on csr.flow_transition_alert_user (app_sid, user_sid);
create index csr.ix_internal_audi_flow_sid on csr.internal_audit_type (app_sid, flow_sid);


CREATE OR REPLACE VIEW csr.v$audit AS
	SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label, 
		   ia.auditor_user_sid, ca.full_name auditor_full_name, sr.submitted_dtm survey_completed, 
		   NVL(nc.cnt, 0) open_non_compliances, ia.survey_sid, ia.auditor_name, ia.auditor_organisation,
		   r.region_type, rt.class_name region_type_class_name, SUBSTR(ia.notes, 1, 50) short_notes,
		   ia.notes full_notes, iat.internal_audit_type_id audit_type_id, iat.label audit_type_label,
		   qs.label survey_label, ia.app_sid, ia.internal_audit_type_id, iat.auditor_role_sid,
		   iat.audit_contact_role_sid, ia.audit_closure_type_id, act.label closure_label, act.icon_image_filename,
		   ia.created_by_user_sid, ia.survey_response_id, ia.created_dtm, ca.email auditor_email,
		   iat.filename as template_filename, iat.assign_issues_to_role, cvru.user_giving_cover_sid cover_auditor_sid,
		   ia.flow_item_id, fi.current_state_id, fs.label flow_state_label
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
	  LEFT JOIN quick_survey qs ON ia.survey_sid = qs.survey_sid AND ia.app_sid = qs.app_sid
	  LEFT JOIN (
			SELECT anc.app_sid, anc.internal_audit_sid, COUNT(DISTINCT anc.non_compliance_id) cnt
			  FROM audit_non_compliance anc
			  JOIN issue_non_compliance inc ON anc.non_compliance_id = inc.non_compliance_id AND anc.app_sid = inc.app_sid
			  JOIN issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id AND inc.app_sid = i.app_sid
			 WHERE i.resolved_dtm IS NULL
			   AND i.rejected_dtm IS NULL
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
	  ;
	  
CREATE OR REPLACE VIEW csr.v$audit_next_due AS
	SELECT ia.internal_audit_sid, ia.internal_audit_type_id, ia.region_sid,
		   ia.audit_dtm previous_audit_dtm, act.audit_closure_type_id, ia.app_sid,
		   CASE (re_audit_due_after_type)
				WHEN 'd' THEN ia.audit_dtm + re_audit_due_after
				WHEN 'w' THEN ia.audit_dtm + (re_audit_due_after*7)
				WHEN 'm' THEN ADD_MONTHS(ia.audit_dtm, re_audit_due_after)
				WHEN 'y' THEN ADD_MONTHS(ia.audit_dtm, re_audit_due_after*12)
		   END next_audit_due_dtm, act.reminder_offset_days, act.label closure_label,
		   ia.label previous_audit_label, act.icon_image_filename,
		   ia.auditor_user_sid previous_auditor_user_sid, ia.flow_item_id
	  FROM (
		SELECT internal_audit_sid, internal_audit_type_id, region_sid, audit_dtm,
			   ROW_NUMBER() OVER (
					PARTITION BY internal_audit_type_id, region_sid
					ORDER BY audit_dtm DESC) rn, -- take most recent audit of each type/region
			   audit_closure_type_id, app_sid, label, auditor_user_sid, flow_item_id
		  FROM internal_audit
	       ) ia
	  JOIN audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id
	   AND ia.app_sid = act.app_sid
	  JOIN region r ON ia.region_sid = r.region_sid AND ia.app_sid = r.app_sid
	 WHERE rn = 1
	   AND act.re_audit_due_after IS NOT NULL
	   AND r.active=1
	   AND ia.audit_closure_type_id IS NOT NULL;
	  

CREATE TABLE CSR.FLOW_CAPABILITY (
	FLOW_CAPABILITY_ID			NUMBER(10) NOT NULL,
	FLOW_ALERT_CLASS			VARCHAR(256) NOT NULL,
	DESCRIPTION					VARCHAR(256) NOT NULL,
	PERM_TYPE					NUMBER(10) NOT NULL,
	DEFAULT_PERMISSION_SET		NUMBER(10) DEFAULT 0 NOT NULL,
	CONSTRAINT PK_FLOW_CAPABILITY PRIMARY KEY (FLOW_CAPABILITY_ID),
	CONSTRAINT CHK_FLOW_CAP_PERM_TYPE CHECK (PERM_TYPE IN (0, 1)), -- To match chain.capability
	CONSTRAINT FK_FLOW_CAP_ALERT_CLASS FOREIGN KEY (FLOW_ALERT_CLASS) REFERENCES csr.FLOW_ALERT_CLASS(FLOW_ALERT_CLASS)
);

CREATE INDEX csr.IX_FLOW_CAP_ALERT_CLASS ON CSR.FLOW_CAPABILITY(FLOW_ALERT_CLASS);

CREATE TABLE CSR.FLOW_INVOLVEMENT_TYPE (
	FLOW_INVOLVEMENT_TYPE_ID	NUMBER(10) NOT NULL,
	FLOW_ALERT_CLASS			VARCHAR(256) NOT NULL,
	LABEL						VARCHAR(256) NOT NULL,
	CSS_CLASS					VARCHAR(256),
	CONSTRAINT PK_FLOW_INVOLVEMENT_TYPE PRIMARY KEY (FLOW_INVOLVEMENT_TYPE_ID),
	CONSTRAINT FK_FLOW_INVOLV_TYP_ALT_CLS FOREIGN KEY (FLOW_ALERT_CLASS) REFERENCES csr.FLOW_ALERT_CLASS(FLOW_ALERT_CLASS)
);

CREATE INDEX csr.IX_FLOW_INVOLV_TYP_ALT_CLS ON CSR.FLOW_INVOLVEMENT_TYPE(FLOW_ALERT_CLASS);

CREATE TABLE csr.FLOW_STATE_INVOLVEMENT (
	APP_SID						NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	FLOW_STATE_ID				NUMBER(10) NOT NULL,
	FLOW_INVOLVEMENT_TYPE_ID	NUMBER(10) NOT NULL,
	CONSTRAINT PK_FLOW_STATE_INVOLVEMENT PRIMARY KEY (APP_SID, FLOW_STATE_ID, FLOW_INVOLVEMENT_TYPE_ID),
	CONSTRAINT FK_FLOW_STATE_INV_STATE_ID FOREIGN KEY (APP_SID, FLOW_STATE_ID) REFERENCES CSR.FLOW_STATE (APP_SID, FLOW_STATE_ID),
	CONSTRAINT FK_FLOW_STATE_INV_INV_ID FOREIGN KEY (FLOW_INVOLVEMENT_TYPE_ID) REFERENCES CSR.FLOW_INVOLVEMENT_TYPE(FLOW_INVOLVEMENT_TYPE_ID)
);

CREATE INDEX csr.IX_FLOW_STATE_INV_STATE_ID ON csr.FLOW_STATE_INVOLVEMENT (APP_SID, FLOW_STATE_ID);
CREATE INDEX csr.IX_FLOW_STATE_INV_INV_ID ON csr.FLOW_STATE_INVOLVEMENT (FLOW_INVOLVEMENT_TYPE_ID);

CREATE SEQUENCE CSR.FLOW_STATE_RL_CAP_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE csr.FLOW_STATE_ROLE_CAPABILITY (
	APP_SID						NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	FLOW_STATE_RL_CAP_ID		NUMBER(10) NOT NULL,
	FLOW_STATE_ID				NUMBER(10) NOT NULL,
	FLOW_CAPABILITY_ID			NUMBER(10) NOT NULL,
	ROLE_SID					NUMBER(10),
	FLOW_INVOLVEMENT_TYPE_ID	NUMBER(10),
	PERMISSION_SET				NUMBER(10) NOT NULL,
	CONSTRAINT PK_FLOW_STATE_ROLE_CAPABILITY PRIMARY KEY (APP_SID, FLOW_STATE_RL_CAP_ID),
	CONSTRAINT UK_FLOW_STATE_ROLE_CAPABILITY UNIQUE (APP_SID, FLOW_STATE_ID, FLOW_CAPABILITY_ID, ROLE_SID, FLOW_INVOLVEMENT_TYPE_ID),
	CONSTRAINT CHK_FLOW_STATE_ROLE_CAPABILITY CHECK ((ROLE_SID IS NULL AND FLOW_INVOLVEMENT_TYPE_ID IS NOT NULL) OR (ROLE_SID IS NOT NULL AND FLOW_INVOLVEMENT_TYPE_ID IS NULL)),
	CONSTRAINT FK_FLOW_STATE_RL_CAP_ROLE FOREIGN KEY (APP_SID, FLOW_STATE_ID, ROLE_SID) REFERENCES CSR.FLOW_STATE_ROLE (APP_SID, FLOW_STATE_ID, ROLE_SID),
	CONSTRAINT FK_FLOW_STATE_RL_CAP_INV FOREIGN KEY (APP_SID, FLOW_STATE_ID, FLOW_INVOLVEMENT_TYPE_ID) REFERENCES csr.FLOW_STATE_INVOLVEMENT(APP_SID, FLOW_STATE_ID, FLOW_INVOLVEMENT_TYPE_ID)
);

CREATE INDEX csr.IX_FLOW_STATE_RL_CAP_ROLE ON csr.FLOW_STATE_ROLE_CAPABILITY (APP_SID, FLOW_STATE_ID, ROLE_SID);
CREATE INDEX csr.IX_FLOW_STATE_RL_CAP_INV ON csr.FLOW_STATE_ROLE_CAPABILITY (APP_SID, FLOW_STATE_ID, FLOW_INVOLVEMENT_TYPE_ID);

DROP TYPE CSR.T_FLOW_STATE_TABLE;

CREATE OR REPLACE TYPE CSR.T_FLOW_STATE_ROW AS
	OBJECT (	
		POS						NUMBER(10), 
		ID						NUMBER(10), 
		LABEL					VARCHAR2(255), 
		LOOKUP_KEY				VARCHAR2(255),
		IS_FINAL				NUMBER(1),
		STATE_COLOUR			NUMBER(10),
		EDITABLE_ROLE_SIDS		VARCHAR2(2000),
		NON_EDITABLE_ROLE_SIDS	VARCHAR2(2000),
		EDITABLE_COL_SIDS		VARCHAR2(2000),
		NON_EDITABLE_COL_SIDS	VARCHAR2(2000),
		INVOLVED_TYPE_IDS		VARCHAR2(2000),
		ATTRIBUTES_XML			XMLType
	);
/

CREATE OR REPLACE TYPE CSR.T_FLOW_STATE_TABLE AS
  TABLE OF CSR.T_FLOW_STATE_ROW;
/

INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.AUDITS', 'flowStateId', 'NUMBER', 'Audits portlet');

INSERT INTO CSR.FLOW_ALERT_CLASS (FLOW_ALERT_CLASS, LABEL) VALUES ('property', 'Property');
INSERT INTO CSR.FLOW_ALERT_CLASS (FLOW_ALERT_CLASS, LABEL) VALUES ('audit', 'Audit');
INSERT INTO CSR.FLOW_ALERT_CLASS (FLOW_ALERT_CLASS, LABEL) VALUES ('campaign', 'Campaign');

-- Flow involvement types
BEGIN
	-- csr.csr_data_pkg.FLOW_INV_TYPE_AUDITOR
	INSERT INTO csr.flow_involvement_type (flow_involvement_type_id, flow_alert_class, label, css_class)
		VALUES (1, 'audit', 'Audit co-ordinator', 'CSRUser');
END;
/

-- Flow capability types
BEGIN
	-- csr.csr_data_pkg.FLOW_CAP_AUDIT
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (1, 'audit', 'Audit', 0, security.security_pkg.PERMISSION_READ);
	
	--csr.csr_data_pkg.FLOW_CAP_AUDIT_SURVEY
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (2, 'audit', 'Survey', 0, security.security_pkg.PERMISSION_READ);
	
	--csr.csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (3, 'audit', 'Non-compliances', 0, security.security_pkg.PERMISSION_READ);
	
	--csr.csr_data_pkg.FLOW_CAP_AUDIT_ADD_ACTION
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (4, 'audit', 'Add actions', 1, security.security_pkg.PERMISSION_WRITE);
	
	--csr.csr_data_pkg.FLOW_CAP_AUDIT_DL_REPORT
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (5, 'audit', 'Download report', 1, security.security_pkg.PERMISSION_WRITE);
	
	--csr.csr_data_pkg.FLOW_CAP_AUDIT_PINBOARD
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (6, 'audit', 'Pinboard', 0, security.security_pkg.PERMISSION_READ);
	
	--TODO
	-- documents?
	-- score (this might not be tied to survey access because of GMCR)
	-- audit closure
END;
/

-- Add alert classes to apps with matching modules
BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT c.app_sid
		  FROM csr.customer c
		  JOIN security.securable_object so ON c.app_sid = so.parent_sid_id AND c.app_sid = so.application_sid_id
		 WHERE so.name = 'Campaigns'
	) LOOP
		BEGIN
			INSERT INTO csr.customer_flow_alert_class (app_sid, flow_alert_class)
			VALUES (r.app_sid, 'campaign');
		EXCEPTION WHEN dup_val_on_index THEN
			NULL;
		END;
	END LOOP;
	
	/*FOR r IN (
		SELECT c.app_sid
		  FROM csr.customer c
		  JOIN security.securable_object so ON c.app_sid = so.parent_sid_id AND c.app_sid = so.application_sid_id
		 WHERE so.name = 'Audits'
	) LOOP
		BEGIN
			INSERT INTO csr.customer_flow_alert_class (app_sid, flow_alert_class)
			VALUES (r.app_sid, 'audit');
		EXCEPTION WHEN dup_val_on_index THEN
			NULL;
		END;
	END LOOP;*/
	
	-- Count any site with spaces as a property site
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM csr.space
	) LOOP
		BEGIN
			INSERT INTO csr.customer_flow_alert_class (app_sid, flow_alert_class)
			VALUES (r.app_sid, 'property');
		EXCEPTION WHEN dup_val_on_index THEN
			NULL;
		END;
	END LOOP;
END;
/

--Remove legacy/unused issue types
UPDATE csr.issue
   SET issue_type_id = 11
 WHERE issue_type_id = 3;

DELETE FROM csr.issue_type_aggregate_ind_grp
 WHERE issue_type_id IN (2,3);
 
DELETE FROM csr.issue_type_state_perm
 WHERE issue_type_id IN (2,3);
 
DELETE FROM csr.issue_type_rag_status
 WHERE issue_type_id IN (2,3);
 
DELETE FROM csr.issue_custom_field_date_val
 WHERE issue_custom_field_id IN (
	SELECT issue_custom_field_id
	  FROM csr.issue_custom_field
	 WHERE issue_type_id IN (2,3)
 );
 
DELETE FROM csr.issue_custom_field_opt_sel
 WHERE issue_custom_field_id IN (
	SELECT issue_custom_field_id
	  FROM csr.issue_custom_field
	 WHERE issue_type_id IN (2,3)
 );
 
DELETE FROM csr.issue_custom_field_option
 WHERE issue_custom_field_id IN (
	SELECT issue_custom_field_id
	  FROM csr.issue_custom_field
	 WHERE issue_type_id IN (2,3)
 );
 
DELETE FROM csr.issue_custom_field_state_perm
 WHERE issue_custom_field_id IN (
	SELECT issue_custom_field_id
	  FROM csr.issue_custom_field
	 WHERE issue_type_id IN (2,3)
 );
 
DELETE FROM csr.issue_custom_field
 WHERE issue_type_id IN (2,3);
 
DELETE FROM csr.issue_type
 WHERE issue_type_id IN (2,3);

@..\audit_pkg
@..\flow_pkg
@..\csr_user_pkg
@..\issue_pkg
@..\property_pkg
@..\pending_pkg
@..\section_pkg
@..\campaign_pkg
@..\schema_pkg

@..\audit_body
@..\flow_body
@..\csr_user_body
@..\issue_body
@..\property_body
@..\pending_body
@..\section_body
@..\campaign_body

@..\schema_body
@..\csrimp\imp_body

-- do this last as it's most controversial
@..\csr_data_pkg
@..\csr_data_body

@update_tail
