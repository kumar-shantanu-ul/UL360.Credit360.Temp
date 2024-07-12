-- Please update version.sql too -- this keeps clean builds in sync
define version=1791
@update_header

Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1036,'Incident','Credit360.Portlets.Incident', EMPTY_CLOB(),'/csr/site/portal/portlets/incident.js');

CREATE TABLE CSR.AUDIT_USER_COVER(
    APP_SID                   NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    USER_COVER_ID             NUMBER(10, 0)    NOT NULL,
    USER_GIVING_COVER_SID     NUMBER(10, 0)    NOT NULL,
    USER_BEING_COVERED_SID    NUMBER(10, 0)    NOT NULL,
    INTERNAL_AUDIT_SID        NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_AUDIT_USER_COVER PRIMARY KEY (APP_SID, INTERNAL_AUDIT_SID, USER_COVER_ID),
    CONSTRAINT FK_AUDIT_USR_CVR_AUDIT FOREIGN KEY (APP_SID, INTERNAL_AUDIT_SID) REFERENCES CSR.INTERNAL_AUDIT(APP_SID, INTERNAL_AUDIT_SID),
    CONSTRAINT FK_AUDIT_USR_CVR_USRG FOREIGN KEY (APP_SID, USER_GIVING_COVER_SID) REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID),
    CONSTRAINT FK_AUDIT_USR_CVR_USRR FOREIGN KEY (APP_SID, USER_BEING_COVERED_SID) REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
)
;

CREATE INDEX CSR.IX_AUD_USR_CVR_USRG ON CSR.AUDIT_USER_COVER(APP_SID, USER_GIVING_COVER_SID);
CREATE INDEX CSR.IX_AUD_USR_CVR_USRR ON CSR.AUDIT_USER_COVER(APP_SID, USER_BEING_COVERED_SID);

CREATE OR REPLACE VIEW csr.v$audit AS
	SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label, 
		   ia.auditor_user_sid, ca.full_name auditor_full_name, sr.submitted_dtm survey_completed, 
		   NVL(nc.cnt, 0) open_non_compliances, ia.survey_sid, ia.auditor_name, ia.auditor_organisation,
		   r.region_type, rt.class_name region_type_class_name, SUBSTR(ia.notes, 1, 50) short_notes,
		   ia.notes full_notes, iat.internal_audit_type_id audit_type_id, iat.label audit_type_label,
		   qs.label survey_label, ia.app_sid, ia.internal_audit_type_id, iat.auditor_role_sid,
		   iat.audit_contact_role_sid, ia.audit_closure_type_id, act.label closure_label, act.icon_image_filename,
		   ia.created_by_user_sid, ia.survey_response_id, ia.created_dtm, ca.email auditor_email,
		   iat.filename as template_filename, iat.assign_issues_to_role, cvru.user_giving_cover_sid cover_auditor_sid
	  FROM internal_audit ia
	  LEFT JOIN (
			SELECT auc.app_sid, auc.internal_audit_sid, auc.user_giving_cover_sid,
				   ROW_NUMBER() OVER (PARTITION BY auc.internal_audit_sid ORDER BY LEVEL DESC, uc.start_dtm DESC,  uc.user_cover_id DESC) rn,
				   CONNECT_BY_ROOT auc.user_being_covered_sid user_being_covered_sid
			  FROM audit_user_cover auc
			  JOIN user_cover uc ON auc.user_cover_id = uc.user_cover_id
			 CONNECT BY PRIOR auc.user_being_covered_sid = auc.user_giving_cover_sid
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
	  ;
	  

CREATE TABLE CSRIMP.AUDIT_USER_COVER(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    USER_COVER_ID             NUMBER(10, 0)    NOT NULL,
    USER_GIVING_COVER_SID     NUMBER(10, 0)    NOT NULL,
    USER_BEING_COVERED_SID    NUMBER(10, 0)    NOT NULL,
    INTERNAL_AUDIT_SID        NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_AUD_USR_COVER PRIMARY KEY (CSRIMP_SESSION_ID, INTERNAL_AUDIT_SID, USER_COVER_ID),
    CONSTRAINT FK_AUDIT_USER_COVER_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

grant select,insert,update,delete on csrimp.audit_user_cover to web_user;
grant insert on csr.audit_user_cover to csrimp;

ALTER TABLE CSR.INCIDENT_TYPE ADD (PLURAL VARCHAR2(255));
UPDATE CSR.INCIDENT_TYPE SET PLURAL = LABEL;
ALTER TABLE CSR.INCIDENT_TYPE MODIFY PLURAL NOT NULL;

ALTER TABLE CMS.TAB_COLUMN ADD (INCL_IN_ACTIVE_USER_FILTER NUMBER(1) DEFAULT 0 CONSTRAINT NN_TAB_COLUMN_INCL_USR_FLTR NOT NULL);
INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.INCIDENT', 'show', 'STRING', 'Incidents portlet');

ALTER TABLE CSRIMP.CMS_TAB_COLUMN ADD (INCL_IN_ACTIVE_USER_FILTER NUMBER(1) CONSTRAINT NN_TAB_COLUMN_INCL_USR_FLTR NOT NULL);
UPDATE CSRIMP.CMS_TAB_COLUMN SET INCL_IN_ACTIVE_USER_FILTER = 0;
ALTER TABLE CSRIMP.CMS_TAB_COLUMN ADD CONSTRAINT CK_TAB_COL_USR_FILTER 
    CHECK (INCL_IN_ACTIVE_USER_FILTER IN (1, 0));


-- FLOW ALERT CHANGES
GRANT SELECT, REFERENCES ON cms.tab_column TO csr;

CREATE TABLE CSR.FLOW_TRANSITION_ALERT_USER(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	FLOW_TRANSITION_ALERT_ID	NUMBER(10, 0)	NOT NULL,
	USER_SID					NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_FLOW_TRANS_ALERT_USER PRIMARY KEY (APP_SID, FLOW_TRANSITION_ALERT_ID, USER_SID),
	CONSTRAINT FK_FLOW_CSR_USER FOREIGN KEY (APP_SID, USER_SID) REFERENCES CSR.CSR_USER (APP_SID, CSR_USER_SID)
);

CREATE TABLE CSR.FLOW_TRANSITION_ALERT_CMS_COL(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	FLOW_TRANSITION_ALERT_ID	NUMBER(10, 0)	NOT NULL,
	COLUMN_SID					NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_FLOW_TRANS_ALERT_CMS_COL PRIMARY KEY (APP_SID, FLOW_TRANSITION_ALERT_ID, COLUMN_SID),
	CONSTRAINT FK_FLOW_CMS_COL FOREIGN KEY (APP_SID, COLUMN_SID) REFERENCES CMS.TAB_COLUMN (APP_SID, COLUMN_SID)
);

CREATE SEQUENCE csr.flow_item_gen_alert_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER;

ALTER TABLE csr.flow_item_generated_alert
ADD(TO_COLUMN_SID NUMBER(10, 0) NULL);

ALTER TABLE csr.flow_item_generated_alert
ADD(flow_item_generated_alert_id NUMBER(10, 0));

UPDATE csr.flow_item_generated_alert
   SET flow_item_generated_alert_id = csr.flow_item_gen_alert_id_seq.NEXTVAL
 WHERE flow_item_generated_alert_id = NULL;
 
--BEGIN
--	FOR r IN (
--		SELECT app_sid, flow_item_alert_id, flow_transition_alert_id, from_user_sid, to_user_sid
--		  FROM csr.flow_item_generated_alert
--	) LOOP
--		UPDATE csr.flow_item_generated_alert
--		   SET flow_item_generated_alert_id = csr.flow_item_gen_alert_id_seq.NEXTVAL
--		 WHERE app_sid = r.app_sid
--		   AND flow_item_alert_id = r.flow_item_alert_id
--		   AND flow_transition_alert_id = r.flow_transition_alert_id
--		   AND from_user_sid = r.from_user_sid
--		   AND to_user_sid = r.to_user_sid;
--	END LOOP;
--END;
--/

ALTER TABLE csr.flow_item_generated_alert 
MODIFY (flow_item_generated_alert_id NOT NULL);

ALTER TABLE csr.flow_item_generated_alert
ADD CONSTRAINT FK_FL_ITM_GN_ALRT_TO_COL_SID FOREIGN KEY (app_sid, to_column_sid) REFERENCES cms.tab_column(app_sid, column_sid);

ALTER TABLE csr.flow_item_generated_Alert
DROP CONSTRAINT FK_FL_ITM_GN_ALRT_TO_USER;

ALTER TABLE csr.flow_item_generated_alert
DROP CONSTRAINT PK_FLOW_ITEM_GENERATED_ALERT;

ALTER TABLE csr.flow_item_generated_alert
ADD CONSTRAINT PK_FLOW_ITEM_GENERATED_ALERT PRIMARY KEY (app_sid, flow_item_generated_alert_id);

ALTER TABLE csr.flow_item_generated_alert
ADD CONSTRAINT UK_FLOW_ITEM_GENERATED_ALERT UNIQUE (app_sid, flow_item_alert_id, flow_transition_alert_id, from_user_sid, to_user_sid, to_column_sid);

ALTER TABLE csr.flow_item_generated_alert
MODIFY (to_user_sid NULL);

ALTER TABLE csr.flow_item_generated_alert
ADD CONSTRAINT FK_FL_ITM_GN_ALRT_TO_USER FOREIGN KEY (app_sid, to_user_sid) REFERENCES csr.csr_user(app_sid, csr_user_sid);

ALTER TABLE csr.flow_item_generated_alert
ADD CONSTRAINT CHK_TO_USER_TO_COL_SIDS CHECK((TO_COLUMN_SID IS NOT NULL OR TO_USER_SID IS NOT NULL) AND (TO_COLUMN_SID IS NULL OR TO_USER_SID IS NULL)) ENABLE;

CREATE INDEX CSR.IX_FLOW_ITEM_GEN_TO_COL_SID ON csr.flow_item_generated_alert (app_sid, to_column_sid);

CREATE TABLE CSRIMP.FLOW_TRANSITION_ALERT_CMS_COL(
	CSRIMP_SESSION_ID			NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	FLOW_TRANSITION_ALERT_ID	NUMBER(10, 0)	NOT NULL,
	COLUMN_SID					NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_FLOW_TRANS_ALERT_CMS_COL PRIMARY KEY (CSRIMP_SESSION_ID, FLOW_TRANSITION_ALERT_ID, COLUMN_SID),
	CONSTRAINT FK_FLOW_CMS_COL FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.FLOW_TRANSITION_ALERT_USER(
	CSRIMP_SESSION_ID			NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	FLOW_TRANSITION_ALERT_ID	NUMBER(10, 0)	NOT NULL,
	USER_SID					NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_FLOW_TRANS_ALERT_USER PRIMARY KEY (CSRIMP_SESSION_ID, FLOW_TRANSITION_ALERT_ID, USER_SID),
	CONSTRAINT FK_FLOW_CSR_USER FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

grant insert on CSR.FLOW_TRANSITION_ALERT_CMS_COL to csrimp;
grant insert on CSR.FLOW_TRANSITION_ALERT_USER to csrimp;

-- END FLOW ALERT CHANGES

DECLARE
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA exception_init(POLICY_ALREADY_EXISTS, -28101);

	TYPE T_TABS IS TABLE OF VARCHAR2(30);
	v_list T_TABS;
	v_null_list T_TABS;
	v_found NUMBER;
BEGIN   
	v_list := T_TABS(
		'AUDIT_USER_COVER',
		'FLOW_TRANSITION_ALERT_CMS_COL',
		'FLOW_TRANSITION_ALERT_USER'
	);
	FOR i IN 1 .. v_list.COUNT LOOP
		DECLARE
			v_name VARCHAR2(30);
		BEGIN
			v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
			
			dbms_output.put_line('doing '||v_name);
			dbms_rls.add_policy(
				object_schema   => 'CSR',
				object_name     => v_list(i),
				policy_name     => v_name,
				function_schema => 'CSR',
				policy_function => 'appSidCheck',
				statement_types => 'select, insert, update, delete',
				update_check    => TRUE,
				policy_type     => dbms_rls.context_sensitive );
		EXCEPTION
			WHEN POLICY_ALREADY_EXISTS THEN
				NULL;
		END;
		
		BEGIN
			dbms_rls.add_policy(
				object_schema   => 'CSRIMP',
				object_name     => v_list(i),
				policy_name     => (SUBSTR(v_list(i), 1, 26) || '_POL') , 
				function_schema => 'CSRIMP',
				policy_function => 'SessionIDCheck',
				statement_types => 'select, insert, update, delete',
				update_check	=> TRUE,
				policy_type     => dbms_rls.context_sensitive);
		EXCEPTION
			WHEN POLICY_ALREADY_EXISTS THEN
				NULL;
		END;
	END LOOP;
END;
/

@..\schema_pkg
@..\..\..\aspen2\cms\db\tab_pkg
@..\incident_pkg
@..\flow_pkg
@..\supplier_pkg
@..\flow_body

@..\schema_body
@..\incident_body
@..\csrimp\imp_body
@..\..\..\aspen2\cms\db\tab_body
@..\user_cover_body
@..\audit_body
@..\csr_user_body
@..\section_body
@..\supplier_body

@update_tail