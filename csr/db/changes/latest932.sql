-- Please update version.sql too -- this keeps clean builds in sync
define version=932
@update_header

BEGIN
	UPDATE csr.user_setting set description = 'stores the "overdue" checkbox selection in the settings panel'
	 WHERE category = 'CREDIT360.PORTLETS.ISSUE2'
	   AND setting = 'overdue';
	
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.ISSUE2', 'unresolved', 'BOOLEAN', 'stores the "unresolved" checkbox selection in the settings panel');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.ISSUE2', 'resolved', 'BOOLEAN', 'stores the "resolved" checkbox selection in the settings panel');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.ISSUE2', 'closed', 'BOOLEAN', 'stores the "closed" checkbox selection in the settings panel');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.ISSUE2', 'rejected', 'BOOLEAN', 'stores the "rejected" checkbox selection in the settings panel');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.ISSUE2', 'pageSize', 'NUMBER', 'stores the "page size" field selection in the settings panel');	
END;
/

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_ISSUE_SEARCH (
	ISSUE_ID 					NUMBER(10),
	LABEL 						VARCHAR2(2048), 
	SOURCE_LABEL 				VARCHAR2(2000), 
	IS_VISIBLE 					NUMBER(1), 
	SOURCE_URL 					VARCHAR2(2000), 
	REGION_SID					NUMBER(10),
	OWNER_ROLE_SID				NUMBER(10),
	OWNER_USER_SID				NUMBER(10),
	RAISED_BY_USER_SID 			NUMBER(10), 
	RAISED_DTM 					DATE, 
	RAISED_USER_NAME 			VARCHAR2(256), 
	RAISED_FULL_NAME 			VARCHAR2(256), 
	RAISED_EMAIL 				VARCHAR2(256), 
	RESOLVED_BY_USER_SID 		NUMBER(10), 
	RESOLVED_DTM 				DATE, 
	RESOLVED_USER_NAME 			VARCHAR2(256), 
	RESOLVED_FULL_NAME 			VARCHAR2(256), 
	RESOLVED_EMAIL 				VARCHAR2(256), 
	CLOSED_BY_USER_SID 			NUMBER(10), 
	CLOSED_DTM 					DATE, 
	CLOSED_USER_NAME 			VARCHAR2(256), 
	CLOSED_FULL_NAME 			VARCHAR2(256), 
	CLOSED_EMAIL 				VARCHAR2(256), 
	REJECTED_BY_USER_SID 		NUMBER(10), 
	REJECTED_DTM 				DATE, 
	REJECTED_USER_NAME 			VARCHAR2(256), 
	REJECTED_FULL_NAME 			VARCHAR2(256), 
	REJECTED_EMAIL 				VARCHAR2(256), 
	ASSIGNED_TO_USER_SID 		NUMBER(10), 
	ASSIGNED_TO_USER_NAME 		VARCHAR2(256), 
	ASSIGNED_TO_FULL_NAME		VARCHAR2(256), 
	ASSIGNED_TO_EMAIL 			VARCHAR2(256), 
	ASSIGNED_TO_ROLE_SID 		NUMBER(10), 
	ASSIGNED_TO_ROLE_NAME 		VARCHAR2(255), 
	CORRESPONDENT_ID 			NUMBER(10), 
	CORRESPONDENT_FULL_NAME 	VARCHAR2(255), 
	CORRESPONDENT_EMAIL 		VARCHAR2(255), 
	CORRESPONDENT_PHONE 		VARCHAR2(255), 
	CORRESPONDENT_MORE_INFO_1 	VARCHAR2(1000), 
	NOW_DTM 					DATE, 
	DUE_DTM 					DATE, 
	ISSUE_TYPE_ID 				NUMBER(10), 
	ISSUE_TYPE_LABEL 			VARCHAR2(255), 
	REQUIRE_PRIORITY 			NUMBER(1), 
	ISSUE_PRIORITY_ID 			NUMBER(10), 
	DUE_DATE_OFFSET 			NUMBER(10), 
	PRIORITY_OVERRIDDEN 		NUMBER(1), 
	FIRST_PRIORITY_SET_DTM 		DATE, 
	ISSUE_PENDING_VAL_ID 		NUMBER(10), 
	ISSUE_SHEET_VALUE_ID 		NUMBER(10), 
	ISSUE_SURVEY_ANSWER_ID 		NUMBER(10), 
	ISSUE_NON_COMPLIANCE_ID 	NUMBER(10), 
	ISSUE_ACTION_ID 			NUMBER(10), 
	ISSUE_METER_ID 				NUMBER(10), 
	ISSUE_METER_ALARM_ID 		NUMBER(10), 
	ISSUE_METER_RAW_DATA_ID 	NUMBER(10), 
	ISSUE_METER_DATA_SOURCE_ID 	NUMBER(10), 
	IS_OVERDUE 					NUMBER(1), 
	IS_OWNER 					NUMBER(1), 
	IS_RESOLVED 				NUMBER(1), 
	IS_CLOSED 					NUMBER(1), 
	IS_REJECTED 				NUMBER(1), 
	STATUS 						VARCHAR2(8),
	-- everything above is just a desc of v$issue
	POSITION			NUMBER(10)
) ON COMMIT DELETE ROWS;


CREATE OR REPLACE VIEW csr.v$issue AS
	SELECT i.app_sid, i.issue_id, i.label, i.source_label, i.is_visible, i.source_url, i.region_sid, i.owner_role_sid, i.owner_user_sid,
		   raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
		   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
		   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
		   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
		   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
		   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, c.more_info_1 correspondent_more_info_1,
		   sysdate now_dtm, due_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, i.issue_priority_id, ip.due_date_offset, CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden, i.first_priority_set_dtm,
		   issue_pending_val_id, issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id,
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
			ELSE 'Ongoing'
		   END status
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

@..\issue_pkg
@..\issue_body

@update_tail
