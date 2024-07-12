-- Please update version.sql too -- this keeps clean builds in sync
define version=1482
@update_header

CREATE TABLE CSR.AUDIT_NON_COMPLIANCE(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    INTERNAL_AUDIT_SID    NUMBER(10, 0)    NOT NULL,
    NON_COMPLIANCE_ID     NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_AUDIT_NON_COMPLIANCE PRIMARY KEY (APP_SID, INTERNAL_AUDIT_SID, NON_COMPLIANCE_ID)
)
;

BEGIN
	DBMS_OUTPUT.ENABLE(NULL);
	FOR c IN (
		SELECT DISTINCT constraint_name
		  FROM all_cons_columns
		 WHERE owner='CSR'
		   AND table_name='NON_COMPLIANCE'
		   AND column_name='INTERNAL_AUDIT_SID'
		   AND constraint_name IN (
			SELECT constraint_name
			  FROM all_constraints
			 WHERE owner='CSR'
			   AND table_name='NON_COMPLIANCE'
			   AND r_constraint_name IN (
				SELECT constraint_name
				  FROM all_constraints
				 WHERE owner='CSR'
				   AND table_name='INTERNAL_AUDIT'
				   AND constraint_type='P'
			   )
		   )
	) LOOP
		DBMS_OUTPUT.PUT_LINE('ALTER TABLE CSR.NON_COMPLIANCE DROP CONSTRAINT '||c.constraint_name);
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.NON_COMPLIANCE DROP CONSTRAINT '||c.constraint_name;
	END LOOP;
END;
/

ALTER TABLE CSR.NON_COMPLIANCE RENAME COLUMN INTERNAL_AUDIT_SID TO CREATED_IN_AUDIT_SID;

ALTER TABLE CSR.AUDIT_NON_COMPLIANCE ADD CONSTRAINT FK_AUD_NC_AUD 
    FOREIGN KEY (APP_SID, INTERNAL_AUDIT_SID)
    REFERENCES CSR.INTERNAL_AUDIT(APP_SID, INTERNAL_AUDIT_SID)
;

ALTER TABLE CSR.AUDIT_NON_COMPLIANCE ADD CONSTRAINT FK_AUD_NC_NC 
    FOREIGN KEY (APP_SID, NON_COMPLIANCE_ID)
    REFERENCES CSR.NON_COMPLIANCE(APP_SID, NON_COMPLIANCE_ID)
;

ALTER TABLE CSR.NON_COMPLIANCE ADD CONSTRAINT FK_NC_ORIG_AUD 
    FOREIGN KEY (APP_SID, CREATED_IN_AUDIT_SID)
    REFERENCES CSR.INTERNAL_AUDIT(APP_SID, INTERNAL_AUDIT_SID)
;

CREATE INDEX CSR.IX_AUD_NC_AUD ON CSR.AUDIT_NON_COMPLIANCE(APP_SID, INTERNAL_AUDIT_SID)
;

CREATE INDEX CSR.IX_AUD_NC_NC ON CSR.AUDIT_NON_COMPLIANCE(APP_SID, NON_COMPLIANCE_ID)
;

INSERT INTO csr.audit_non_compliance (app_sid, internal_audit_sid, non_compliance_id)
SELECT app_sid, created_in_audit_sid, non_compliance_id
  FROM csr.non_compliance;

CREATE OR REPLACE VIEW csr.v$issue AS
	SELECT i.app_sid, i.issue_id, i.label, i.source_label, i.is_visible, i.source_url, i.region_sid, re.description region_name, i.parent_id, i.owner_role_sid, i.owner_user_sid,
		   raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
		   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
		   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
		   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
		   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
		   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, c.more_info_1 correspondent_more_info_1,
		   sysdate now_dtm, due_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, ist.allow_children, i.issue_priority_id, ip.due_date_offset, CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden, i.first_priority_set_dtm,
		   issue_pending_val_id, issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id, issue_supplier_id,
		   CASE WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND rejected_by_user_sid IS NULL AND SYSDATE > due_dtm THEN 1 ELSE 0 
		   END is_overdue,
		   CASE WHEN rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID') OR i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0 
		   END is_owner,
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
		   END status
	  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user curej, csr_user cuass, role r, correspondent c, issue_priority ip,
	       (SELECT * FROM region_role_member WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')) rrm, v$region re
	 WHERE i.app_sid = curai.app_sid AND i.raised_by_user_sid = curai.csr_user_sid
	   AND i.app_sid = ist.app_sid AND i.issue_type_Id = ist.issue_type_id
	   AND i.app_sid = cures.app_sid(+) AND i.resolved_by_user_sid = cures.csr_user_sid(+) 
	   AND i.app_sid = cuclo.app_sid(+) AND i.closed_by_user_sid = cuclo.csr_user_sid(+)
	   AND i.app_sid = curej.app_sid(+) AND i.rejected_by_user_sid = curej.csr_user_sid(+)
	   AND i.app_sid = cuass.app_sid(+) AND i.assigned_to_user_sid = cuass.csr_user_sid(+)
	   AND i.app_sid = r.app_sid(+) AND i.assigned_to_role_sid = r.role_sid(+)
	   AND i.app_sid = re.app_sid(+) AND i.region_sid = re.region_sid(+)
	   AND i.app_sid = c.app_sid(+) AND i.correspondent_id = c.correspondent_id(+)
	   AND i.app_sid = ip.app_sid(+) AND i.issue_priority_id = ip.issue_priority_id(+)
	   AND i.app_sid = rrm.app_sid(+) AND i.region_sid = rrm.region_sid(+) AND i.owner_role_sid = rrm.role_sid(+)
	   AND i.deleted = 0
	   AND (i.issue_non_compliance_id IS NULL OR i.issue_non_compliance_id IN (
		-- filter out issues from deleted audits
		SELECT inc.issue_non_compliance_id
		  FROM issue_non_compliance inc
		  JOIN audit_non_compliance anc ON inc.non_compliance_id = anc.non_compliance_id AND inc.app_sid = anc.app_sid
		 WHERE NOT EXISTS (SELECT NULL FROM trash t WHERE t.trash_sid = anc.internal_audit_sid)
	   ));

CREATE OR REPLACE VIEW csr.v$audit AS
	SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label, 
		   ia.auditor_user_sid, ca.full_name auditor_full_name, sr.submitted_dtm survey_completed, 
		   NVL(nc.cnt, 0) open_non_compliances, ia.survey_sid, ia.auditor_name, ia.auditor_organisation,
		   r.region_type, rt.class_name region_type_class_name, SUBSTR(ia.notes, 1, 50) short_notes,
		   iat.internal_audit_type_id audit_type_id, iat.label audit_type_label, qs.label survey_label,
		   ia.app_sid, ia.internal_audit_type_id
	  FROM internal_audit ia
	  JOIN csr_user ca ON ia.auditor_user_sid = ca.csr_user_sid AND ia.app_sid = ca.app_sid
	  LEFT JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id
	  JOIN quick_survey qs ON ia.survey_sid = qs.survey_sid AND ia.app_sid = qs.app_sid
	  LEFT JOIN (
			SELECT anc.app_sid, anc.internal_audit_sid, COUNT(DISTINCT anc.non_compliance_id) cnt
			  FROM audit_non_compliance anc
			  JOIN issue_non_compliance inc ON anc.non_compliance_id = inc.non_compliance_id AND anc.app_sid = inc.app_sid
			  JOIN issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id AND inc.app_sid = i.app_sid
			 WHERE i.resolved_dtm IS NULL
			 GROUP BY anc.app_sid, anc.internal_audit_sid
			) nc ON ia.internal_audit_sid = nc.internal_audit_sid AND ia.app_sid = nc.app_sid
	  LEFT JOIN v$quick_survey_response sr ON ia.survey_response_id = sr.survey_response_id AND ia.app_sid = sr.app_sid
	  JOIN v$region r ON ia.region_sid = r.region_sid
	  JOIN region_type rt ON r.region_type = rt.region_type;


-- CSRIMP/EXP changes
ALTER TABLE CSRIMP.NON_COMPLIANCE RENAME COLUMN INTERNAL_AUDIT_SID TO CREATED_IN_AUDIT_SID;

CREATE TABLE CSRIMP.AUDIT_NON_COMPLIANCE(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    INTERNAL_AUDIT_SID     NUMBER(10, 0)    NOT NULL,
    NON_COMPLIANCE_ID      NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_AUDIT_NON_COMPLIANCE PRIMARY KEY (CSRIMP_SESSION_ID, NON_COMPLIANCE_ID, INTERNAL_AUDIT_SID),
    CONSTRAINT FK_AUD_NON_COMPL_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

ALTER TABLE CSRIMP.DELEG_PLAN_COL MODIFY DELEG_PLAN_SID NULL;

grant insert on csr.audit_non_compliance to csrimp;

grant select,insert,update,delete on csrimp.audit_non_compliance to web_user;

BEGIN
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		  JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner IN ('CSRIMP')
		   AND (t.dropped = 'NO' OR t.dropped IS NULL)
		   AND c.column_name = 'CSRIMP_SESSION_ID'
		   AND t.table_name IN ('AUDIT_NON_COMPLIANCE')
 	)
 	LOOP
		dbms_output.put_line('Writing policy '||r.policy_name);
		dbms_rls.add_policy(
			object_schema   => r.owner,
			object_name     => r.table_name,
			policy_name     => r.policy_name, 
			function_schema => 'CSRIMP',
			policy_function => 'SessionIDCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.static);
	END LOOP;
END;
/


@..\audit_pkg
@..\schema_pkg

@..\tag_body
@..\issue_body
@..\quick_survey_body
@..\audit_body
@..\schema_body
@..\supplier_body
@..\csrimp\imp_body

@update_tail
