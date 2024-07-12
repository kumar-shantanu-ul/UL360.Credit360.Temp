-- Please update version.sql too -- this keeps clean builds in sync
define version=2071
@update_header

GRANT select, references on CSR.PLUGIN TO CHAIN;
GRANT select, references on CSR.PLUGIN_TYPE TO CHAIN;

CREATE SEQUENCE CHAIN.COMPANY_TAB_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE CHAIN.COMPANY_TAB(
    APP_SID                NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_TAB_ID         NUMBER(10, 0)     NOT NULL,
    PLUGIN_ID              NUMBER(10, 0)     NOT NULL,
    PLUGIN_TYPE_ID         NUMBER(10, 0)     NOT NULL,
    POS                    NUMBER(10, 0)     NOT NULL,
    LABEL                  VARCHAR2(254)     NOT NULL,
    PAGE_COMPANY_TYPE_ID   NUMBER(10, 0)     NOT NULL,
    USER_COMPANY_TYPE_ID   NUMBER(10, 0)     NOT NULL,
    CONSTRAINT COMPANY_TAB_PK PRIMARY KEY (APP_SID, COMPANY_TAB_ID)
);

ALTER TABLE CHAIN.COMPANY_TAB ADD CONSTRAINT REF_PAGE_CT_COMPANY_TYPE 
    FOREIGN KEY (APP_SID, PAGE_COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID)
;

ALTER TABLE CHAIN.COMPANY_TAB ADD CONSTRAINT REF_USER_CT_COMPANY_TYPE 
    FOREIGN KEY (APP_SID, USER_COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID)
;

ALTER TABLE CHAIN.COMPANY_TAB ADD CONSTRAINT REF_PLUGIN_ID_PLUGIN
    FOREIGN KEY (PLUGIN_ID)
    REFERENCES CSR.PLUGIN(PLUGIN_ID)
;

ALTER TABLE CHAIN.COMPANY_TAB ADD CONSTRAINT REF_PLUGIN_TYPE_ID_PLUGIN_TYPE
    FOREIGN KEY (PLUGIN_TYPE_ID)
    REFERENCES CSR.PLUGIN_TYPE(PLUGIN_TYPE_ID)
;

CREATE TABLE csr.FLOW_TRANSITION_ALERT_INV (
	APP_SID						NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	FLOW_TRANSITION_ALERT_ID	NUMBER(10) NOT NULL,
	FLOW_INVOLVEMENT_TYPE_ID	NUMBER(10) NOT NULL,
	CONSTRAINT PK_FLOW_TRANSITION_ALERT_INV PRIMARY KEY (APP_SID, FLOW_TRANSITION_ALERT_ID, FLOW_INVOLVEMENT_TYPE_ID),
	CONSTRAINT FK_FLOW_TRANS_ALERT_INV_ALERT FOREIGN KEY (APP_SID, FLOW_TRANSITION_ALERT_ID) REFERENCES csr.FLOW_TRANSITION_ALERT(APP_SID, FLOW_TRANSITION_ALERT_ID),
	CONSTRAINT FK_FLOW_TRANS_ALERT_INV_INV FOREIGN KEY (FLOW_INVOLVEMENT_TYPE_ID) REFERENCES csr.FLOW_INVOLVEMENT_TYPE(FLOW_INVOLVEMENT_TYPE_ID)
);

CREATE INDEX csr.FK_FLOW_TRANS_ALERT_INV_INV ON csr.FLOW_TRANSITION_ALERT_INV (FLOW_INVOLVEMENT_TYPE_ID);

CREATE TABLE csr.FLOW_STATE_TRANSITION_INV (
	APP_SID						NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	FLOW_STATE_TRANSITION_ID	NUMBER(10) NOT NULL,
	FROM_STATE_ID				NUMBER(10) NOT NULL,
	FLOW_INVOLVEMENT_TYPE_ID	NUMBER(10) NOT NULL,
	CONSTRAINT PK_FLOW_STATE_TRANSITION_INV PRIMARY KEY (APP_SID, FLOW_STATE_TRANSITION_ID, FLOW_INVOLVEMENT_TYPE_ID),
	CONSTRAINT FK_FLOW_STATE_TRANS_INV_INV FOREIGN KEY (APP_SID, FROM_STATE_ID, FLOW_INVOLVEMENT_TYPE_ID) REFERENCES csr.FLOW_STATE_INVOLVEMENT (APP_SID, FLOW_STATE_ID, FLOW_INVOLVEMENT_TYPE_ID) ON DELETE CASCADE,
	CONSTRAINT FK_FLOW_STATE_TRANS_INV_TRAN FOREIGN KEY (APP_SID, FLOW_STATE_TRANSITION_ID) REFERENCES csr.FLOW_STATE_TRANSITION (APP_SID, FLOW_STATE_TRANSITION_ID)
);

CREATE INDEX csr.IX_FLOW_STATE_TRANS_INV_INV ON csr.FLOW_STATE_TRANSITION_INV(APP_SID, FROM_STATE_ID, FLOW_INVOLVEMENT_TYPE_ID);

DROP TYPE CSR.T_FLOW_STATE_TRANS_TABLE;

CREATE OR REPLACE TYPE CSR.T_FLOW_STATE_TRANS_ROW AS
	OBJECT (
		POS							NUMBER(10),
		ID							NUMBER(10),
		FROM_STATE_ID				NUMBER(10),
		TO_STATE_ID					NUMBER(10),
		ASK_FOR_COMMENT				VARCHAR2(16),
		MANDATORY_FIELDS_MESSAGE	VARCHAR2(255),
		HOURS_BEFORE_AUTO_TRAN		NUMBER(10),
		BUTTON_ICON_PATH			VARCHAR2(255),
		VERB						VARCHAR2(255),
		LOOKUP_KEY					VARCHAR2(255),
		HELPER_SP					VARCHAR2(255),
		ROLE_SIDS					VARCHAR2(2000),
		COLUMN_SIDS					VARCHAR2(2000),
		INVOLVED_TYPE_IDS			VARCHAR2(2000),
		ATTRIBUTES_XML				XMLType
	);
/

CREATE OR REPLACE TYPE CSR.T_FLOW_STATE_TRANS_TABLE AS
  TABLE OF CSR.T_FLOW_STATE_TRANS_ROW;
/

ALTER TABLE CSRIMP.FLOW_STATE_CMS_COL ADD
    CONSTRAINT FK_FLOW_STATE_CMS_COL_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
;

ALTER TABLE CSRIMP.FLOW_STATE_TRANSITION_CMS_COL ADD
    CONSTRAINT FK_FLOW_STATE_TRANS_COL_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
;

CREATE TABLE CSRIMP.FLOW_STATE_INVOLVEMENT (
	CSRIMP_SESSION_ID			NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	FLOW_STATE_ID				NUMBER(10) NOT NULL,
	FLOW_INVOLVEMENT_TYPE_ID	NUMBER(10) NOT NULL,
	CONSTRAINT PK_FLOW_STATE_INVOLVEMENT PRIMARY KEY (CSRIMP_SESSION_ID, FLOW_STATE_ID, FLOW_INVOLVEMENT_TYPE_ID),
    CONSTRAINT FK_FLOW_STATE_INVOLVEMENT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.FLOW_STATE_ROLE_CAPABILITY (
	CSRIMP_SESSION_ID			NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	FLOW_STATE_RL_CAP_ID		NUMBER(10) NOT NULL,
	FLOW_STATE_ID				NUMBER(10) NOT NULL,
	FLOW_CAPABILITY_ID			NUMBER(10) NOT NULL,
	ROLE_SID					NUMBER(10),
	FLOW_INVOLVEMENT_TYPE_ID	NUMBER(10),
	PERMISSION_SET				NUMBER(10) NOT NULL,
	CONSTRAINT PK_FLOW_STATE_ROLE_CAPABILITY PRIMARY KEY (CSRIMP_SESSION_ID, FLOW_STATE_RL_CAP_ID),
	CONSTRAINT UK_FLOW_STATE_ROLE_CAPABILITY UNIQUE (CSRIMP_SESSION_ID, FLOW_STATE_ID, FLOW_CAPABILITY_ID, ROLE_SID, FLOW_INVOLVEMENT_TYPE_ID),
	CONSTRAINT CHK_FLOW_STATE_ROLE_CAPABILITY CHECK ((ROLE_SID IS NULL AND FLOW_INVOLVEMENT_TYPE_ID IS NOT NULL) OR (ROLE_SID IS NOT NULL AND FLOW_INVOLVEMENT_TYPE_ID IS NULL)),
    CONSTRAINT FK_FLOW_STATE_ROLE_CAPBLTY_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.FLOW_TRANSITION_ALERT_INV (
	CSRIMP_SESSION_ID			NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	FLOW_TRANSITION_ALERT_ID	NUMBER(10) NOT NULL,
	FLOW_INVOLVEMENT_TYPE_ID	NUMBER(10) NOT NULL,
	CONSTRAINT PK_FLOW_TRANSITION_ALERT_INV PRIMARY KEY (CSRIMP_SESSION_ID, FLOW_TRANSITION_ALERT_ID, FLOW_INVOLVEMENT_TYPE_ID),
    CONSTRAINT FK_FLOW_TRANSITION_ALRT_INV_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.FLOW_STATE_TRANSITION_INV (
	CSRIMP_SESSION_ID			NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	FLOW_STATE_TRANSITION_ID	NUMBER(10) NOT NULL,
	FROM_STATE_ID				NUMBER(10) NOT NULL,
	FLOW_INVOLVEMENT_TYPE_ID	NUMBER(10) NOT NULL,
	CONSTRAINT PK_FLOW_STATE_TRANSITION_INV PRIMARY KEY (CSRIMP_SESSION_ID, FLOW_STATE_TRANSITION_ID, FLOW_INVOLVEMENT_TYPE_ID),
    CONSTRAINT FK_FS_TRANSITION_INV_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_flow_state_rl_cap (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_flow_state_rl_cap_id		NUMBER(10) NOT NULL,
	new_flow_state_rl_cap_id		NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_flow_state_rl_cap PRIMARY KEY (old_flow_state_rl_cap_id) USING INDEX,
	CONSTRAINT uk_map_flow_state_rl_cap UNIQUE (new_flow_state_rl_cap_id) USING INDEX,
    CONSTRAINT FK_FLOW_STATE_RL_CAP_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

ALTER TABLE csr.internal_audit_type ADD (
	interactive						NUMBER(1) DEFAULT 1 NOT NULL,
	CONSTRAINT chk_iat_interactive_1_0 CHECK (interactive IN (1, 0))
);

ALTER TABLE chain.reference MODIFY DEPRICATED_REFERENCE_NUMBER NUMBER(10, 0) NULL;

ALTER TABLE csrimp.internal_audit_type ADD (interactive NUMBER(1));
UPDATE csrimp.internal_audit_type SET interactive=1;
ALTER TABLE csrimp.internal_audit_type MODIFY interactive NOT NULL;
ALTER TABLE csrimp.internal_audit_type ADD CONSTRAINT chk_iat_interactive_1_0 CHECK (interactive IN (1, 0));

ALTER TABLE csr.internal_audit ADD (
	summary_response_id				NUMBER(10),
	CONSTRAINT fk_ia_summary_qsr FOREIGN KEY (app_sid, summary_response_id) REFERENCES csr.quick_survey_response (app_sid, survey_response_id)
);

ALTER TABLE csr.internal_audit_type ADD (
	summary_survey_sid				NUMBER(10),
	CONSTRAINT fk_iat_summary_survey FOREIGN KEY (app_sid, summary_survey_sid) REFERENCES csr.quick_survey(app_sid, survey_sid)
);

ALTER TABLE csrimp.internal_audit ADD (
	summary_response_id				NUMBER(10)
);

ALTER TABLE csrimp.internal_audit_type ADD (
	summary_survey_sid				NUMBER(10)
);

CREATE SEQUENCE csr.internal_audit_file_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE csr.internal_audit_file (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	internal_audit_file_id			NUMBER(10) NOT NULL,
	internal_audit_sid				NUMBER(10) NOT NULL,
	filename						VARCHAR2(255) NOT NULL,
	mime_type						VARCHAR2(255) NOT NULL,
	data							BLOB NOT NULL,
	sha1							RAW(20) NOT NULL,
	uploaded_dtm					DATE NOT NULL,
	CONSTRAINT pk_internal_audit_file PRIMARY KEY (app_sid, internal_audit_file_id),
	CONSTRAINT fk_ia_file_ia FOREIGN KEY (app_sid, internal_audit_sid) REFERENCES csr.internal_audit (app_sid, internal_audit_sid)
);

ALTER TABLE csr.internal_audit_file MODIFY (uploaded_dtm DEFAULT SYSDATE);

CREATE TABLE csrimp.internal_audit_file (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	internal_audit_file_id			NUMBER(10) NOT NULL,
	internal_audit_sid				NUMBER(10) NOT NULL,
	filename						VARCHAR2(255) NOT NULL,
	mime_type						VARCHAR2(255) NOT NULL,
	data							BLOB NOT NULL,
	sha1							RAW(20) NOT NULL,
	uploaded_dtm					DATE NOT NULL,
	CONSTRAINT pk_internal_audit_file PRIMARY KEY (csrimp_session_id, internal_audit_file_id),
	CONSTRAINT fk_internal_audit_file_is FOREIGN KEY
    	(csrimp_session_id) REFERENCES CSRIMP.CSRIMP_SESSION (csrimp_session_id)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_internal_audit_file (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_internal_audit_file_id		NUMBER(10) NOT NULL,
	new_internal_audit_file_id		NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_internal_audit_file PRIMARY KEY (old_internal_audit_file_id) USING INDEX,
	CONSTRAINT uk_map_internal_audit_file UNIQUE (new_internal_audit_file_id) USING INDEX,
    CONSTRAINT fk_map_internal_audit_file_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

ALTER TABLE csr.internal_audit DROP CONSTRAINT fk_int_aud_clsr_type;
ALTER TABLE csr.internal_audit ADD CONSTRAINT fk_int_aud_clsr_type 
    FOREIGN KEY (app_sid, internal_audit_type_id, audit_closure_type_id)
    REFERENCES csr.audit_closure_type(app_sid, internal_audit_type_id, audit_closure_type_id) DEFERRABLE INITIALLY DEFERRED;

grant insert on csr.internal_audit_file to csrimp;
grant select on csr.internal_audit_file_id_seq to csrimp;

ALTER TABLE csr.internal_audit ADD (
	DELETED							NUMBER(10) DEFAULT 0 NOT NULL
);

ALTER TABLE csrimp.internal_audit ADD (
	DELETED							NUMBER(10)
);

UPDATE csrimp.internal_audit SET deleted=0;

ALTER TABLE csrimp.internal_audit MODIFY deleted NOT NULL;

BEGIN
	FOR r IN (
		SELECT * FROM dual WHERE NOT EXISTS (
			SELECT * from all_constraints WHERE owner='CHAIN' and constraint_name='PK_IMPLEMENTATION'
		)
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE chain.implementation ADD CONSTRAINT PK_IMPLEMENTATION PRIMARY KEY (app_sid, name)';
	END LOOP;
END;
/

ALTER TABLE chain.company_type_relationship ADD flow_sid NUMBER(10, 0);
GRANT select, references ON csr.flow TO chain;
ALTER TABLE chain.company_type_relationship ADD CONSTRAINT FK_COMPANY_TYPE_REL_FLOW FOREIGN KEY (app_sid, flow_sid) REFERENCES csr.flow (app_sid, flow_sid);

ALTER TABLE chain.supplier_relationship ADD flow_item_id NUMBER(10, 0);
GRANT select, references ON csr.flow_item TO chain;
ALTER TABLE chain.supplier_relationship ADD CONSTRAINT FK_SUPPLIER_REL_FLOW_ITEM FOREIGN KEY (app_sid, flow_item_id) REFERENCES csr.flow_item (app_sid, flow_item_id);


grant execute on csr.flow_pkg to chain;

grant select on csr.flow_capability to chain;
grant select on csr.flow_item to chain;
grant select on csr.flow_state to chain;
grant select on csr.flow_state_log to chain;
grant select on csr.flow_state_role_capability to chain;

grant select on csr.v$flow_item to chain;
grant select on csr.v$flow_item_role_member to chain;
grant select on csr.v$flow_item_trans_role_member to chain;
grant select on csr.v$open_flow_item_alert to chain;
grant select on csr.v$region to chain;

grant select,insert,update,delete on csrimp.flow_state_involvement to web_user;
grant select,insert,update,delete on csrimp.flow_state_role_capability to web_user;
grant select,insert,update,delete on csrimp.flow_transition_alert_inv to web_user;
grant select,insert,update,delete on csrimp.flow_state_transition_inv to web_user;

grant insert on csr.flow_state_involvement to csrimp;
grant insert on csr.flow_state_role_capability to csrimp;
grant insert on csr.flow_transition_alert_inv to csrimp;
grant insert on csr.flow_state_transition_inv to csrimp;

grant select on csr.flow_state_rl_cap_id_seq to csrimp;

-- dummy procs for grant
create or replace package chain.supplier_flow_pkg as
procedure dummy;
end;
/
create or replace package body chain.supplier_flow_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

grant execute on chain.supplier_flow_pkg to web_user;

CREATE OR REPLACE VIEW csr.V$FLOW_ITEM AS
    SELECT fi.app_sid, fi.flow_sid, fi.flow_item_id, f.label flow_label,
		fs.flow_state_id current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key,
        fi.survey_response_id, fi.dashboard_instance_id  -- deprecated
      FROM flow_item fi
	    JOIN flow f ON fi.flow_sid = f.flow_sid
        JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid;

CREATE OR REPLACE VIEW csr.V$FLOW_ITEM_ROLE_MEMBER AS
    SELECT fi.*, r.role_sid, r.name role_name, rrm.region_sid, fsr.is_editable
      FROM V$FLOW_ITEM fi
        JOIN flow_state_role fsr ON fi.current_state_id = fsr.flow_state_id AND fi.app_sid = fsr.app_sid
        JOIN role r ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
        JOIN region_role_member rrm ON r.role_sid = rrm.role_sid AND r.app_sid = rrm.app_sid AND rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
    ;

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
	 WHERE ia.deleted = 0;

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
			   audit_closure_type_id, app_sid, label, auditor_user_sid, flow_item_id, deleted
		  FROM internal_audit
	       ) ia
	  JOIN audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id
	   AND ia.app_sid = act.app_sid
	  JOIN region r ON ia.region_sid = r.region_sid AND ia.app_sid = r.app_sid
	 WHERE rn = 1
	   AND act.re_audit_due_after IS NOT NULL
	   AND r.active=1
	   AND ia.audit_closure_type_id IS NOT NULL
	   AND ia.deleted = 0;
	   
CREATE OR REPLACE VIEW CHAIN.v$supplier_relationship AS
	SELECT app_sid, purchaser_company_sid, supplier_company_sid, active, deleted, virtually_active_until_dtm, virtually_active_key, supp_rel_code, flow_item_id
	  FROM supplier_relationship 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND deleted = 0
-- either the relationship is active, or it is virtually active for a very short period so that we can send invitations
	   AND (active = 1 OR SYSDATE < virtually_active_until_dtm);

BEGIN
dbms_rls.add_policy(
			object_schema   => 'chain',
			object_name     => 'COMPANY_TAB',
			policy_name     => 'COMPANY_TAB_POL', 
			function_schema => 'chain',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.static );
END;
/

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
	TYPE T_TABS IS TABLE OF VARCHAR2(30);
	v_list T_TABS;
BEGIN
	v_list := t_tabs(
		'FLOW_TRANSITION_ALERT_INV',
		'FLOW_STATE_TRANSITION_INV',
		'FLOW_STATE_ROLE_CAPABILITY',
		'FLOW_STATE_INVOLVEMENT',
		'INTERNAL_AUDIT_FILE'
	);
	FOR I IN 1 .. v_list.count
	LOOP
		-- CSR RLS
		BEGIN
			DBMS_RLS.ADD_POLICY(
				object_schema   => 'CSR',
				object_name     => v_list(i),
				policy_name     => SUBSTR(v_list(i), 1, 23)||'_POLICY',
				function_schema => 'CSR',
				policy_function => 'appSidCheck',
				statement_types => 'select, insert, update, delete',
				update_check    => true,
				policy_type     => dbms_rls.context_sensitive );
				DBMS_OUTPUT.PUT_LINE('Policy added to '||v_list(i));
		EXCEPTION
			WHEN POLICY_ALREADY_EXISTS THEN
				DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));
			WHEN FEATURE_NOT_ENABLED THEN
				DBMS_OUTPUT.PUT_LINE('RLS policies not applied for '||v_list(i)||' as feature not enabled');
		END;
	END LOOP;
END;
/

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
	TYPE T_TABS IS TABLE OF VARCHAR2(30);
	v_list T_TABS;
BEGIN
	v_list := t_tabs(
		'FLOW_TRANSITION_ALERT_INV',
		'FLOW_STATE_TRANSITION_INV',
		'FLOW_STATE_ROLE_CAPABILITY',
		'FLOW_STATE_INVOLVEMENT',
		'INTERNAL_AUDIT_FILE',
		'MAP_FLOW_STATE_RL_CAP',
		'MAP_INTERNAL_AUDIT_FILE'
	);
	FOR I IN 1 .. v_list.count
	LOOP		
		-- CSRIMP RLS
		BEGIN
			DBMS_RLS.ADD_POLICY(
				object_schema   => 'CSRIMP',
				object_name     => v_list(i),
				policy_name     => SUBSTR(v_list(i), 1, 26)||'_POL',
				function_schema => 'CSRIMP',
				policy_function => 'SessionIDCheck',
				statement_types => 'select, insert, update, delete',
				update_check    => true,
				policy_type     => dbms_rls.context_sensitive );
				DBMS_OUTPUT.PUT_LINE('Policy added to '||v_list(i));
		EXCEPTION
			WHEN POLICY_ALREADY_EXISTS THEN
				DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));
			WHEN FEATURE_NOT_ENABLED THEN
				DBMS_OUTPUT.PUT_LINE('RLS policies not applied for '||v_list(i)||' as feature not enabled');
		END;
	END LOOP;
END;
/

/* Add CHAIN_COMPANY_TAB plugin type */
BEGIN
	INSERT INTO csr.plugin_type(plugin_type_id, description)
	VALUES (10, 'Chain Company Tab');
		EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
	   
UPDATE csr.internal_audit
   SET deleted = 1
 WHERE internal_audit_sid IN (
	SELECT trash_sid
	  FROM csr.trash
);

-- enable cms alert class for all clients with a flow cms table 
BEGIN 
    FOR r IN (
		SELECT DISTINCT app_sid
		  FROM cms.tab
		 WHERE flow_sid IS NOT NULL
	) LOOP
		BEGIN
			INSERT INTO csr.customer_flow_alert_class (app_sid, flow_alert_class)
			VALUES (r.app_sid, 'cms');
		EXCEPTION WHEN dup_val_on_index THEN
			NULL;
		END;
	END LOOP;
END;
/

BEGIN
	INSERT INTO csr.flow_alert_class (flow_alert_class, label)
							  VALUES ('supplier', 'Chain supplier');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
END;
/


-- update existing cms flows to have correct class
UPDATE csr.flow
   SET flow_alert_class = 'cms'
 WHERE flow_sid IN (
	SELECT f.flow_sid
	  FROM csr.flow f
	  JOIN cms.tab t
		ON t.flow_sid = f.flow_sid
	 WHERE flow_alert_class IS NULL
 );
 
BEGIN
	--csr.csr_data_pkg.FLOW_CAP_AUDIT_AUDIT_LOG
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (7, 'audit', 'View audit log', 1, security.security_pkg.PERMISSION_WRITE);
		
	--csr.csr_data_pkg.FLOW_CAP_AUDIT_CLOSURE
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (8, 'audit', 'Closure result', 0, security.security_pkg.PERMISSION_READ);
		
	--csr.csr_data_pkg.FLOW_CAP_AUDIT_COPY
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (9, 'audit', 'Copy audit', 1, security.security_pkg.PERMISSION_WRITE);
		
	--csr.csr_data_pkg.FLOW_CAP_AUDIT_DELETE
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (10, 'audit', 'Delete audit', 1, 0);
		
	--csr.csr_data_pkg.FLOW_CAP_AUDIT_IMPORT_NC
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (11, 'audit', 'Import non-compliances', 1, 0);
END;
/

BEGIN
	--csr.csr_data_pkg.FLOW_CAP_AUDIT_AUDIT_LOG
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (12, 'audit', 'Documents', 0, security.security_pkg.PERMISSION_READ);
		
	--csr.csr_data_pkg.FLOW_CAP_AUDIT_EXEC_SUMMARY
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (14, 'audit', 'Executive summary', 0, security.security_pkg.PERMISSION_READ);
END;
/

BEGIN		
	-- csr.csr_data_pkg.FLOW_INV_TYPE_PURCHASER
	INSERT INTO csr.flow_involvement_type (flow_involvement_type_id, flow_alert_class, label, css_class)
		VALUES (1001, 'supplier', 'Purchaser', 'CSRUser');
		
	-- csr.csr_data_pkg.FLOW_INV_TYPE_SUPPLIER
	INSERT INTO csr.flow_involvement_type (flow_involvement_type_id, flow_alert_class, label, css_class)
		VALUES (1002, 'supplier', 'Supplier', 'CSRUser');

	--csr.csr_data_pkg.FLOW_CAP_SUPPLIER
	INSERT INTO csr.flow_capability(flow_capability_id,  flow_alert_class, description, perm_type, default_permission_set)
		VALUES (1001, 'supplier', 'Manage company', 0, security.security_pkg.PERMISSION_READ);

END;
/

-- resync flow state role capabilities to add the default permission sets for any new ones
-- copied from utils\fixMissingFlowCapabilites.sql
BEGIN
	-- roles
	FOR r IN (
		SELECT f.app_sid, fs.flow_state_id, fc.flow_capability_id, fsr.role_sid, fc.default_permission_set
		  FROM csr.flow f
		  JOIN csr.flow_state fs
			ON f.flow_sid = fs.flow_sid
		  JOIN csr.flow_capability fc
			ON f.flow_alert_class = fc.flow_alert_class
		  JOIN csr.flow_state_role fsr
			ON fs.flow_state_id = fsr.flow_state_id AND fs.app_sid = fsr.app_sid
		  LEFT JOIN csr.flow_state_role_capability fsrc -- exclude existing capabilities
		    ON fsrc.app_sid = f.app_sid AND fsrc.flow_state_id = fs.flow_state_id 
		   AND fsrc.flow_capability_id = fc.flow_capability_id 
		   AND fsrc.role_sid = fsr.role_sid 
		 WHERE fsrc.flow_state_rl_cap_id IS NULL
	) LOOP
		BEGIN
			INSERT INTO csr.flow_state_role_capability (app_sid, flow_state_rl_cap_id, flow_state_id, flow_capability_id, role_sid, flow_involvement_type_id, permission_set)
			   VALUES (r.app_sid, csr.flow_state_rl_cap_id_seq.NEXTVAL, r.flow_state_id, r.flow_capability_id, r.role_sid, null, r.default_permission_set);
		EXCEPTION
			WHEN dup_val_on_index THEN
				-- already an existing capability
				NULL;
		END;
	END LOOP;
	
	-- involvements
	FOR r IN (
		SELECT f.app_sid, fs.flow_state_id, fc.flow_capability_id, fsi.flow_involvement_type_id, fc.default_permission_set
		  FROM csr.flow f
		  JOIN csr.flow_state fs
			ON f.flow_sid = fs.flow_sid
		  JOIN csr.flow_capability fc
			ON f.flow_alert_class = fc.flow_alert_class
		  JOIN csr.flow_state_involvement fsi
			ON fs.flow_state_id = fsi.flow_state_id AND fs.app_sid = fsi.app_sid
		  LEFT JOIN csr.flow_state_role_capability fsrc -- exclude existing capabilities
		    ON fsrc.app_sid = f.app_sid AND fsrc.flow_state_id = fs.flow_state_id 
		   AND fsrc.flow_capability_id = fc.flow_capability_id 
		   AND fsrc.flow_involvement_type_id = fsi.flow_involvement_type_id 
		 WHERE fsrc.flow_state_rl_cap_id IS NULL
	) LOOP
		BEGIN
			INSERT INTO csr.flow_state_role_capability (app_sid, flow_state_rl_cap_id, flow_state_id, flow_capability_id, role_sid, flow_involvement_type_id, permission_set)
			   VALUES (r.app_sid, csr.flow_state_rl_cap_id_seq.NEXTVAL, r.flow_state_id, r.flow_capability_id, null, r.flow_involvement_type_id, r.default_permission_set);
		EXCEPTION
			WHEN dup_val_on_index THEN
				-- already an existing capability
				NULL;
		END;
	END LOOP;
END;
/
	   
ALTER TABLE csrimp.customer ADD (
	audit_helper_pkg				VARCHAR2(255)
);

-- Do at the end because it invalidates so many packages
ALTER TABLE csr.customer ADD (
	audit_helper_pkg				VARCHAR2(255)
);

@..\chain\company_pkg
@..\chain\company_type_pkg
@..\chain\chain_link_pkg
@..\chain\supplier_flow_pkg
@..\chain\type_capability_pkg
@..\flow_pkg
@..\audit_pkg
@..\schema_pkg
@..\postit_pkg
@..\unit_test_pkg
@..\flow_body
@..\schema_body
@..\csrimp\imp_body
@..\postit_body
@..\chain\chain_link_body
@..\chain\chain_body
@..\chain\company_type_body
@..\chain\supplier_flow_body
@..\chain\type_capability_body
@..\unit_test_body
@..\csr_data_body
@..\csr_data_pkg
@..\audit_body
@..\chain\company_body

@update_tail
