-- Please update version.sql too -- this keeps clean builds in sync
define version=882
@update_header

CREATE SEQUENCE CSR.ISSUE_METER_DATA_SOURCE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE CSR.ISSUE_METER_DATA_SOURCE(
    APP_SID                       NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ISSUE_METER_DATA_SOURCE_ID    NUMBER(10, 0)    NOT NULL,
    RAW_DATA_SOURCE_ID            NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK1193 PRIMARY KEY (APP_SID, ISSUE_METER_DATA_SOURCE_ID)
);

ALTER TABLE CSR.ISSUE DROP CONSTRAINT CHK_ISSUE_FKS;

ALTER TABLE CSR.ISSUE ADD (
	ISSUE_METER_DATA_SOURCE_ID    NUMBER(10, 0),
	CONSTRAINT CHK_ISSUE_FKS CHECK (
	(ISSUE_PENDING_VAL_ID IS NOT NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL)
	OR
	(ISSUE_SHEET_VALUE_ID IS NOT NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL)
	OR
	(ISSUE_SURVEY_ANSWER_ID IS NOT NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL)
	OR
	(ISSUE_NON_COMPLIANCE_ID IS NOT NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL)
	OR
	(ISSUE_ACTION_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL)
	OR
	(ISSUE_METER_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL)
	OR
	(ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL)
	OR
	(ISSUE_METER_ALARM_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL)
	OR
	(ISSUE_METER_RAW_DATA_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL)
	OR
	(ISSUE_METER_DATA_SOURCE_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL ))
);


ALTER TABLE CSR.METER_RAW_DATA_SOURCE ADD (
	EXPORT_AFTER_DTM			DATE,
	DEFAULT_ISSUE_USER_SID		NUMBER(10, 0)
);

ALTER TABLE CSR.ISSUE ADD CONSTRAINT RefISSUE_METER_DATA_SOURCE2756 
    FOREIGN KEY (APP_SID, ISSUE_METER_DATA_SOURCE_ID)
    REFERENCES CSR.ISSUE_METER_DATA_SOURCE(APP_SID, ISSUE_METER_DATA_SOURCE_ID)
;

ALTER TABLE CSR.ISSUE_METER_DATA_SOURCE ADD CONSTRAINT RefMETER_RAW_DATA_SOURCE2757 
    FOREIGN KEY (APP_SID, RAW_DATA_SOURCE_ID)
    REFERENCES CSR.METER_RAW_DATA_SOURCE(APP_SID, RAW_DATA_SOURCE_ID)
;

ALTER TABLE CSR.ISSUE_METER_DATA_SOURCE ADD CONSTRAINT RefCUSTOMER2758 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;

ALTER TABLE CSR.METER_RAW_DATA_SOURCE ADD CONSTRAINT RefCSR_USER2764 
    FOREIGN KEY (APP_SID, DEFAULT_ISSUE_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

CREATE INDEX csr.ix_issue_issue_meter_ds ON csr.issue (app_sid, issue_meter_data_source_id);

CREATE INDEX csr.ix_meter_raw_ds_def_user ON csr.meter_raw_data_source (app_sid, default_issue_user_sid);


CREATE OR REPLACE VIEW csr.v$issue AS
	SELECT i.app_sid, i.issue_id, i.label, i.source_label, i.is_visible, i.source_url,
		   raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
		   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
		   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
		   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
		   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
		   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, c.more_info_1 correspondent_more_info_1,
		   sysdate now_dtm, due_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, i.issue_priority_id, ip.due_date_offset, CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden, i.first_priority_set_dtm,
		   issue_pending_val_id, issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id,
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

BEGIN
	INSERT INTO csr.issue_type
	  (app_sid, issue_type_id, label)
		SELECT app_sid, 12, 'Meter data source'
		  FROM csr.issue_type
		 WHERE issue_type_id = 8; -- Where the "Meter raw data" issue type already exists
END;
/

BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'ISSUE_METER_DATA_SOURCE',
		policy_name     => 'ISSUE_METER_DATA_SOURCE_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive
	);
END;
/


@../csr_data_pkg
@../meter_monitor_pkg

@../issue_body
@../meter_monitor_body
@../meter_alarm_body


@update_tail
