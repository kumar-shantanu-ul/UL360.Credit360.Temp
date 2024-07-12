-- Please update version.sql too -- this keeps clean builds in sync
define version=844
@update_header

CREATE SEQUENCE CSR.ISSUE_CUSTOM_FIELD_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE CSR.ISSUE_CUSTOM_FIELD(
    APP_SID                  NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ISSUE_CUSTOM_FIELD_ID    NUMBER(10, 0)    NOT NULL,
    ISSUE_TYPE_ID            NUMBER(10, 0)    NOT NULL,
    FIELD_TYPE               CHAR(1)         NOT NULL,
    LABEL                    VARCHAR2(64)     NOT NULL,
    CONSTRAINT CHK_ISS_CUST_FLD_TYP CHECK (FIELD_TYPE IN ('T', 'O','M')),
    CONSTRAINT PK_ISSUE_CUSTOM_FIELD PRIMARY KEY (APP_SID, ISSUE_CUSTOM_FIELD_ID)
)
;


CREATE TABLE CSR.ISSUE_CUSTOM_FIELD_OPT_SEL(
    APP_SID                      NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ISSUE_ID                     NUMBER(10, 0)    NOT NULL,
    ISSUE_CUSTOM_FIELD_ID        NUMBER(10, 0)    NOT NULL,
    ISSUE_CUSTOM_FIELD_OPT_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_ISSUE_CUSTOM_FIELD_OPT_SEL PRIMARY KEY (APP_SID, ISSUE_ID, ISSUE_CUSTOM_FIELD_ID, ISSUE_CUSTOM_FIELD_OPT_ID)
)
;


CREATE TABLE CSR.ISSUE_CUSTOM_FIELD_OPTION(
    APP_SID                      NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ISSUE_CUSTOM_FIELD_ID        NUMBER(10, 0)    NOT NULL,
    ISSUE_CUSTOM_FIELD_OPT_ID    NUMBER(10, 0)    NOT NULL,
    LABEL                        VARCHAR2(64)     NOT NULL,
    CONSTRAINT PK_ISSUE_CUSTOM_FIELD_OPTION PRIMARY KEY (APP_SID, ISSUE_CUSTOM_FIELD_ID, ISSUE_CUSTOM_FIELD_OPT_ID)
)
;


CREATE TABLE CSR.ISSUE_CUSTOM_FIELD_STR_VAL(
    APP_SID                  NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ISSUE_ID                 NUMBER(10, 0)    NOT NULL,
    ISSUE_CUSTOM_FIELD_ID    NUMBER(10, 0)    NOT NULL,
    STRING_VALUE             VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK_ISSUE_CUSTOM_FIELD_STR_VAL PRIMARY KEY (APP_SID, ISSUE_ID, ISSUE_CUSTOM_FIELD_ID)
)
;


CREATE INDEX CSR.IX_ISS_CUST_FLD_ISS_TYPE ON CSR.ISSUE_CUSTOM_FIELD(APP_SID, ISSUE_TYPE_ID)
;


CREATE INDEX CSR.IX_ISS_CUST_FLD_OPT_SEL_ISS_ID ON CSR.ISSUE_CUSTOM_FIELD_OPT_SEL(APP_SID, ISSUE_ID)
;


CREATE INDEX CSR.IX_ISS_CUST_FLD_OPT_SEL_SEL_ID ON CSR.ISSUE_CUSTOM_FIELD_OPT_SEL(APP_SID, ISSUE_CUSTOM_FIELD_ID, ISSUE_CUSTOM_FIELD_OPT_ID)
;


CREATE INDEX CSR.IX_ISS_CUST_FLD_OPT_FLD ON CSR.ISSUE_CUSTOM_FIELD_OPTION(APP_SID, ISSUE_CUSTOM_FIELD_ID)
;


CREATE INDEX CSR.IX_ISS_CUST_FLD_STR_VAL_ISS_ID ON CSR.ISSUE_CUSTOM_FIELD_STR_VAL(APP_SID, ISSUE_ID)
;


CREATE INDEX CSR.IX_ISS_CUST_FLD_STR_VAL_FLD ON CSR.ISSUE_CUSTOM_FIELD_STR_VAL(APP_SID, ISSUE_CUSTOM_FIELD_ID)
;

ALTER TABLE CSR.ISSUE_CUSTOM_FIELD ADD CONSTRAINT FK_ISS_CUST_FLD_ISS_TYP 
    FOREIGN KEY (APP_SID, ISSUE_TYPE_ID)
    REFERENCES CSR.ISSUE_TYPE(APP_SID, ISSUE_TYPE_ID)
;


ALTER TABLE CSR.ISSUE_CUSTOM_FIELD_OPT_SEL ADD CONSTRAINT FK_ISS_CUST_FLD_OPT_OPT 
    FOREIGN KEY (APP_SID, ISSUE_CUSTOM_FIELD_ID, ISSUE_CUSTOM_FIELD_OPT_ID)
    REFERENCES CSR.ISSUE_CUSTOM_FIELD_OPTION(APP_SID, ISSUE_CUSTOM_FIELD_ID, ISSUE_CUSTOM_FIELD_OPT_ID)
;

ALTER TABLE CSR.ISSUE_CUSTOM_FIELD_OPT_SEL ADD CONSTRAINT FK_ISSUE_CUST_FLD_OPT_SEL 
    FOREIGN KEY (APP_SID, ISSUE_ID)
    REFERENCES CSR.ISSUE(APP_SID, ISSUE_ID)
;

ALTER TABLE CSR.ISSUE_CUSTOM_FIELD_OPTION ADD CONSTRAINT FK_ISS_CUST_FLD_OPT_FLD 
    FOREIGN KEY (APP_SID, ISSUE_CUSTOM_FIELD_ID)
    REFERENCES CSR.ISSUE_CUSTOM_FIELD(APP_SID, ISSUE_CUSTOM_FIELD_ID)
;


ALTER TABLE CSR.ISSUE_CUSTOM_FIELD_STR_VAL ADD CONSTRAINT FK_ISS_CUST_FLD_STR_FLD 
    FOREIGN KEY (APP_SID, ISSUE_CUSTOM_FIELD_ID)
    REFERENCES CSR.ISSUE_CUSTOM_FIELD(APP_SID, ISSUE_CUSTOM_FIELD_ID)
;

ALTER TABLE CSR.ISSUE_CUSTOM_FIELD_STR_VAL ADD CONSTRAINT FK_ISSUE_CUST_FLD_STR_VAL 
    FOREIGN KEY (APP_SID, ISSUE_ID)
    REFERENCES CSR.ISSUE(APP_SID, ISSUE_ID)
;


BEGIN
	FOR r in (
		SELECT DISTINCT c.host
		  FROM csr.customer c
		  JOIN csr.internal_audit ia on c.app_sid = ia.app_sid
	) LOOP
		security.user_pkg.logonadmin(r.host);
		
		BEGIN
			INSERT INTO csr.issue_type (issue_type_id, label)
			VALUES (11, 'Audit action');
		EXCEPTION WHEN dup_val_on_index THEN
			NULL;
		END;
		
		UPDATE csr.issue
		   SET issue_type_id=11
		 WHERE issue_type_id=1
		   AND issue_non_compliance_id IS NOT NULL
		   AND app_sid = security.security_pkg.GetApp;
		
	END LOOP;
END;
/

	 
CREATE OR REPLACE VIEW csr.v$issue AS
	SELECT i.app_sid, i.issue_id, i.label, i.source_label, i.is_visible,
		   raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
		   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
		   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
		   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
		   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
		   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, c.more_info_1 correspondent_more_info_1,
		   sysdate now_dtm, due_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, i.issue_priority_id, ip.due_date_offset, CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden, i.first_priority_set_dtm,
		   issue_pending_val_id, issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id,
		   CASE WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND SYSDATE > due_dtm THEN 1 ELSE 0 
		   END is_overdue,
		   CASE WHEN rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID') OR i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0 
		   END is_owner,
		   CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1
		   END is_resolved,
		   CASE WHEN i.closed_dtm IS NULL THEN 0 ELSE 1
		   END is_closed,
		   CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1
		   END is_rejected
	  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user curej, csr_user cuass, role r, correspondent c, issue_priority ip,
	       (SELECT * FROM region_role_member WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')) rrm
	 WHERE i.app_sid = curai.app_sid AND i.raised_by_user_sid = curai.csr_user_sid
	   AND i.app_sid = ist.app_sid AND i.issue_type_Id = ist.issue_type_id
	   AND i.app_sid = cures.app_sid(+) AND i.resolved_by_user_sid = cures.csr_user_sid(+) 
	   AND i.app_sid = cuclo.app_sid(+) AND i.closed_by_user_sid = cuclo.csr_user_sid(+)
	   AND i.app_sid = curej.app_sid(+) AND i.rejected_by_user_sid = curej.csr_user_sid(+)
	   AND i.app_sid = cuass.app_sid(+) AND i.assigned_to_user_sid = cuass.csr_user_sid(+)
	   AND i.app_sid = r.app_sid(+) AND i.assigned_to_role_sid = r.role_sid(+)
	   AND i.app_sid = c.app_sid(+) AND i.correspondent_id = c.correspondent_id(+)
	   AND i.app_sid = ip.app_sid(+) AND i.issue_priority_id = ip.issue_priority_id(+)
	   AND i.app_sid = rrm.app_sid(+) AND i.region_sid = rrm.region_sid(+) AND i.owner_role_sid = rrm.role_sid(+)
	   AND (i.issue_non_compliance_id IS NULL OR i.issue_non_compliance_id NOT IN (
		-- filter out issues from deleted audits
		SELECT inc.issue_non_compliance_id
		  FROM issue_non_compliance inc
		  JOIN non_compliance nc ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
		  JOIN customer c ON inc.app_sid = c.app_sid
		  JOIN security.securable_object so ON nc.internal_audit_sid = so.sid_id
		 WHERE so.parent_sid_id = c.trash_sid
	   ));

INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) VALUES (1, 90, 'Internal audit change');
INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) VALUES (1, 91, 'Non-compliance change');


@..\audit_pkg
@..\csr_data_pkg
@..\issue_pkg
@..\csr_data_pkg

@..\csr_app_body
@..\audit_body
@..\issue_body

@update_tail
