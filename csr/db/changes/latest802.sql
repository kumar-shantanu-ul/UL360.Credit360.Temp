-- Please update version.sql too -- this keeps clean builds in sync
define version=802
@update_header

-- ALERT BASEDATE
BEGIN
	INSERT INTO CSR.ALERT_TYPE (ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (36, 'Correspondent notified when the issue priority is first set',
		'A system user manually sets the priority of an issue for the first time, and we notify the correspondent.',
		'A issue type configured address, or the configured system e-mail address when not found (this defaults to support@credit360.com, but can be changed from the site setup page).'
	);

	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (33, 0, 'PRIORITY_DESCRIPTION', 'Priority', 'The description of the issue priority', 8);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (33, 0, 'PRIORITY_DUE_DATE_OFFSET', 'Priority offset in days', 'The number of days that the priority is offset from the date the issue was submitted', 9);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (33, 0, 'LONG_DUE_DTM', 'Long due date', 'The due date of the issue, written in long date format', 10);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (33, 0, 'SHORT_DUE_DTM', 'Short due date', 'The due date of the issue, written in short date format', 11);

	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (34, 0, 'PRIORITY_DESCRIPTION', 'Priority', 'The description of the issue priority', 8);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (34, 0, 'PRIORITY_DUE_DATE_OFFSET', 'Priority offset in days', 'The number of days that the priority is offset from the date the issue was submitted', 9);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (34, 0, 'LONG_DUE_DTM', 'Long due date', 'The due date of the issue, written in long date format', 10);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (34, 0, 'SHORT_DUE_DTM', 'Short due date', 'The due date of the issue, written in short date format', 11);

	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (35, 0, 'PRIORITY_DESCRIPTION', 'Priority', 'The description of the issue priority', 8);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (35, 0, 'PRIORITY_DUE_DATE_OFFSET', 'Priority offset in days', 'The number of days that the priority is offset from the date the issue was submitted', 9);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (35, 0, 'LONG_DUE_DTM', 'Long due date', 'The due date of the issue, written in long date format', 10);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (35, 0, 'SHORT_DUE_DTM', 'Short due date', 'The due date of the issue, written in short date format', 11);

	-- a correspondent issue has had the priority set for the first time
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (36, 0, 'TO_NAME', 'To full name', 'The full name of the person (correspondent) that the alert is being sent to', 1);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (36, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the person (correspondent) that the alert is being sent to', 2);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (36, 0, 'FROM_FULL_NAME', 'From full name', 'The full name of the user that is triggering the alert send', 3);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (36, 0, 'LINK', 'Public access link', 'The public link that allows the correspondent to view the issue and add further comments', 4);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (36, 0, 'ISSUE_ID', 'The issue id string', 'The issue identification for the mail reader', 5);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (36, 0, 'PRIORITY_DESCRIPTION', 'Priority', 'The description of the issue priority', 6);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (36, 0, 'PRIORITY_DUE_DATE_OFFSET', 'Priority offset in days', 'The number of days that the priority is offset from the date the issue was submitted', 7);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (36, 0, 'LONG_DUE_DTM', 'Long due date', 'The due date of the issue, written in long date format', 8);
	INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (36, 0, 'SHORT_DUE_DTM', 'Short due date', 'The due date of the issue, written in short date format', 9);
	
	UPDATE csr.alert_type_param 
	   SET field_name = 'FROM_FULL_NAME'
	 WHERE alert_type_id IN (33, 34, 35, 36)
	   AND field_name = 'FROM_NAME';
END;
/

-- OTHER STUFF

ALTER TABLE CSR.ISSUE_TYPE ADD (
    REQUIRE_PRIORITY             NUMBER(1, 0)     DEFAULT 0 NOT NULL
);

ALTER TABLE CSR.ISSUE ADD (
    FIRST_PRIORITY_SET_DTM       DATE
);


-- reset defaults (priorities are only used by Atkins at present so this is csr safe)
UPDATE csr.issue_type 
   SET require_priority = 1,
       default_issue_priority_id = NULL
 WHERE default_issue_priority_id IS NOT NULL; 

-- reset defaults (priorities are only used by Atkins at present so this is csr safe)
UPDATE csr.issue 
   SET first_priority_set_dtm = SYSDATE 
 WHERE issue_priority_id IS NOT NULL;


CREATE OR REPLACE VIEW csr.v$issue AS
	SELECT i.app_sid, i.issue_id, i.label, i.source_label,
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
	   AND i.app_sid = rrm.app_sid(+) AND i.region_sid = rrm.region_sid(+) AND i.owner_role_sid = rrm.role_sid(+);

@..\issue_pkg
@..\issue_body

@update_tail
