-- Please update version.sql too -- this keeps clean builds in sync
define version=779
@update_header

-- 
-- SEQUENCE: CSR.ISSUE_PRIORITY_ID_SEQ 
--

CREATE SEQUENCE CSR.ISSUE_PRIORITY_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

-- 
-- TABLE: CSR.ISSUE_PRIORITY 
--

CREATE TABLE CSR.ISSUE_PRIORITY(
    APP_SID              NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ISSUE_PRIORITY_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION          VARCHAR2(1000)   NOT NULL,
    DUE_DATE_OFFSET      NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_ISSUE_PRIORITY PRIMARY KEY (APP_SID, ISSUE_PRIORITY_ID)
)
;

ALTER TABLE CSR.ISSUE_ACTION_LOG ADD (
	RE_USER_SID                   NUMBER(10, 0),
	OLD_LABEL                     VARCHAR2(2048),
	NEW_LABEL                     VARCHAR2(2048),
	OLD_DUE_DTM                   DATE,
	NEW_DUE_DTM                   DATE,
	OLD_PRIORITY_ID               NUMBER(10, 0),
    NEW_PRIORITY_ID               NUMBER(10, 0)
);

ALTER TABLE CSR.CORRESPONDENT ADD (MORE_INFO_1 VARCHAR2(1000));

ALTER TABLE CSR.ISSUE ADD (
	LAST_LABEL               VARCHAR2(2048),
	ISSUE_PRIORITY_ID        NUMBER(10, 0),
	LAST_ISSUE_PRIORITY_ID   NUMBER(10, 0),
    LAST_DUE_DTM             DATE,
	REJECTED_DTM             DATE,
    REJECTED_BY_USER_SID     NUMBER(10, 0)
);

ALTER TABLE CSR.ISSUE MODIFY LABEL NULL;

ALTER TABLE CSR.ISSUE_TYPE ADD (DEFAULT_ISSUE_PRIORITY_ID  NUMBER(10, 0));

ALTER TABLE CSR.ISSUE ADD CONSTRAINT FK_IPRIO_ISSUE  
    FOREIGN KEY (APP_SID, ISSUE_PRIORITY_ID)
    REFERENCES CSR.ISSUE_PRIORITY(APP_SID, ISSUE_PRIORITY_ID)
;

ALTER TABLE CSR.ISSUE ADD CONSTRAINT FK_IPRIO_ISSUE_LAST 
    FOREIGN KEY (APP_SID, LAST_ISSUE_PRIORITY_ID)
    REFERENCES CSR.ISSUE_PRIORITY(APP_SID, ISSUE_PRIORITY_ID)
;

ALTER TABLE CSR.ISSUE_PRIORITY ADD CONSTRAINT FK_CUSTOMER_ISSUE_PRIORITY  
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;

ALTER TABLE CSR.ISSUE_TYPE ADD CONSTRAINT FK_IPRIO_ITYPE_DEFAULT 
    FOREIGN KEY (APP_SID, DEFAULT_ISSUE_PRIORITY_ID)
    REFERENCES CSR.ISSUE_PRIORITY(APP_SID, ISSUE_PRIORITY_ID)
;

ALTER TABLE CSR.ISSUE ADD CONSTRAINT FK_REJECTED_CSRU_ISSUE 
    FOREIGN KEY (APP_SID, REJECTED_BY_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE CSR.ISSUE_ACTION_LOG ADD CONSTRAINT FK_RE_CSRU_AIL 
    FOREIGN KEY (APP_SID, RE_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE CSR.ISSUE_ACTION_LOG ADD CONSTRAINT FK_IPRIO_IAL_NEW 
    FOREIGN KEY (APP_SID, NEW_PRIORITY_ID)
    REFERENCES CSR.ISSUE_PRIORITY(APP_SID, ISSUE_PRIORITY_ID)
;

ALTER TABLE CSR.ISSUE_ACTION_LOG ADD CONSTRAINT FK_IPRIO_IAL_OLD 
    FOREIGN KEY (APP_SID, OLD_PRIORITY_ID)
    REFERENCES CSR.ISSUE_PRIORITY(APP_SID, ISSUE_PRIORITY_ID)
;


ALTER TABLE CSR.ISSUE DROP COLUMN NOTE;

BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'ISSUE_PRIORITY',
		policy_name     => 'ISSUE_PRIORITY_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/

CREATE OR REPLACE VIEW csr.v$issue AS
	SELECT i.app_sid, i.issue_id, i.label, i.source_label,
		   raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
		   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
		   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
		   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
		   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
		   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, c.more_info_1 correspondent_more_info_1,
		   sysdate now_dtm, due_dtm, ist.issue_type_Id, ist.label issue_type_label, i.issue_priority_id, ip.due_date_offset, CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden,
		   issue_pending_val_id, issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id,
		   CASE 
			WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND SYSDATE > due_dtm THEN 1
			ELSE 0 
		   END is_overdue,
		   CASE 
			WHEN rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID') OR i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1
			ELSE 0 
		   END is_owner
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
	   AND i.app_sid = rrm.app_sid(+) AND i.region_sid = rrm.region_sid(+) AND i.owner_role_sid = rrm.role_sid(+);
	   

@..\csr_data_pkg	   
@..\issue_pkg
@..\issue_body
	   
	   
UPDATE CSR.ISSUE_TYPE SET label = 'Enquiry' WHERE issue_type_id = 9;	   
	   
BEGIN
	UPDATE csr.alert_type SET description = 'Issue resolved response to correspondent' WHERE alert_type_id = 33;
	
	INSERT INTO CSR.ALERT_TYPE (ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (34, 'Message to issue correspondent or user',
		'A system user manually triggers an email to an issue correspondent or user.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
	);  
	INSERT INTO CSR.ALERT_TYPE (ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (35, 'Issue rejected response to correspondent',
		'A system user manually triggers a rejection of an issue which has a correspondent.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
	); 
	
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (34, 0, 'TO_NAME', 'To full name', 'The full name of the person that the alert is being sent to', 1);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (34, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the person that the alert is being sent to', 2);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (34, 0, 'FROM_NAME', 'From full name', 'The full name of the user that is triggering the alert send', 3);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (34, 0, 'NOTE', 'Log entry note', 'The note to the user or correspondent that is also written into the issue log', 4);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (34, 0, 'LINK', 'Access link', 'The link that allows the user or correspondent to view the issue and add further comments', 5);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (34, 0, 'ATTACHMENT_COUNT', 'Attachment count', 'The number of attachments which are attached to the last log entry that can be downloaded following the link.', 6);

	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (35, 0, 'TO_NAME', 'To full name', 'The full name of the person (correspondent) that the alert is being sent to', 1);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (35, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the person (correspondent) that the alert is being sent to', 2);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (35, 0, 'FROM_NAME', 'From full name', 'The full name of the user that is triggering the alert send', 3);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (35, 0, 'NOTE', 'Log entry note', 'The note to the correspondent that is also written into the issue log', 4);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (35, 0, 'LINK', 'Public access link', 'The public link that allows the correspondent to view the issue and add further comments', 5);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (35, 0, 'ATTACHMENT_COUNT', 'Attachment count', 'The number of attachments which are attached to the last log entry that can be downloaded by the correspondent.', 6);

	UPDATE CSR.ISSUE_ACTION_TYPE SET DESCRIPTION = 'Emailed correspondent' WHERE ISSUE_ACTION_TYPE_ID = 2;
	
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (7, 'Emailed user');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (8, 'Priority changed');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (9, 'Rejected');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (10, 'Label changed');
END;
/



@update_tail