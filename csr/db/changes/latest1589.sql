-- Please update version.sql too -- this keeps clean builds in sync
define version=1589
@update_header

ALTER TABLE csr.issue ADD first_issue_log_id NUMBER(10, 0);
ALTER TABLE csr.issue ADD last_issue_log_id NUMBER(10, 0);
ALTER TABLE csrimp.issue ADD first_issue_log_id NUMBER(10, 0);
ALTER TABLE csrimp.issue ADD last_issue_log_id NUMBER(10, 0);

ALTER TABLE csr.issue ADD CONSTRAINT FK_ISSUE_FIRST_ISSUE_LOG
    FOREIGN KEY (app_sid, first_issue_log_id)
    REFERENCES csr.issue_log(app_sid, issue_log_id)  DEFERRABLE INITIALLY DEFERRED;
	
ALTER TABLE csr.issue ADD CONSTRAINT FK_ISSUE_LAST_ISSUE_LOG
    FOREIGN KEY (app_sid, last_issue_log_id)
    REFERENCES csr.issue_log(app_sid, issue_log_id)  DEFERRABLE INITIALLY DEFERRED;
	
CREATE INDEX csr.ix_issue_first_issue_log ON csr.issue(app_sid, first_issue_log_id);
CREATE INDEX csr.ix_issue_last_issue_log ON csr.issue(app_sid, last_issue_log_id);

CREATE OR REPLACE VIEW csr.v$issue AS
	SELECT i.app_sid, i.issue_id, i.label, i.source_label, i.is_visible, i.source_url, i.region_sid, re.description region_name, i.parent_id,
	       i.issue_escalated, i.owner_role_sid, i.owner_user_sid, i.first_issue_log_id, i.last_issue_log_id, NVL(lil.logged_dtm, i.raised_dtm) last_modified_dtm,
		   i.is_public, i.allow_auto_close, raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
		   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
		   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
		   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
		   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
		   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, c.more_info_1 correspondent_more_info_1,
		   sysdate now_dtm, due_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, ist.allow_children, ist.can_be_public, i.issue_priority_id, ip.due_date_offset, ip.description priority_description,
		   CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden, i.first_priority_set_dtm,
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
	       (SELECT * FROM region_role_member WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')) rrm, v$region re, issue_log lil
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
	   AND i.app_sid = lil.app_sid(+) AND i.last_issue_log_id = lil.issue_log_id(+)
	   AND i.deleted = 0
	   AND (i.issue_non_compliance_id IS NULL OR i.issue_non_compliance_id IN (
		-- filter out issues from deleted audits
		SELECT inc.issue_non_compliance_id
		  FROM issue_non_compliance inc
		  JOIN audit_non_compliance anc ON inc.non_compliance_id = anc.non_compliance_id AND inc.app_sid = anc.app_sid
		 WHERE NOT EXISTS (SELECT NULL FROM trash t WHERE t.trash_sid = anc.internal_audit_sid)
	   ));
	   
DROP TABLE CSR.TEMP_ISSUE_SEARCH;
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_ISSUE_SEARCH (
	ISSUE_ID 					NUMBER(10),
	LABEL 						VARCHAR2(2048), 
	SOURCE_LABEL 				VARCHAR2(2000), 
	IS_VISIBLE 					NUMBER(1), 
	SOURCE_URL 					VARCHAR2(2000), 
	REGION_SID					NUMBER(10),
	PARENT_ID					NUMBER(10),
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
	ISSUE_SUPPLIER_ID 			NUMBER(10), 
	IS_OVERDUE 					NUMBER(1), 
	IS_OWNER 					NUMBER(1), 
	IS_RESOLVED 				NUMBER(1), 
	IS_CLOSED 					NUMBER(1), 
	IS_REJECTED 				NUMBER(1), 
	STATUS 						VARCHAR2(8),
	FIRST_ISSUE_LOG_ID			NUMBER(10),
	LAST_ISSUE_LOG_ID			NUMBER(10),
	-- everything above is just a desc of v$issue
	POSITION			NUMBER(10)
) ON COMMIT DELETE ROWS;


BEGIN
	FOR r IN (
		-- get the most recent log entry
		SELECT *
		  FROM (
			SELECT ROW_NUMBER() OVER (PARTITION BY app_sid, issue_id ORDER BY logged_dtm DESC) rn,
				issue_id, issue_log_id, app_sid
			  FROM csr.v$issue_log
			)
		 WHERE rn = 1
	) LOOP
		UPDATE csr.issue
		   SET last_issue_log_id = r.issue_log_id
		 WHERE issue_id = r.issue_id
		   AND app_sid = r.app_sid;
		   
		   COMMIT;
	END LOOP;
END;
/

BEGIN
	FOR r IN (
		-- get the oldest log entry
		SELECT *
		  FROM (
			SELECT ROW_NUMBER() OVER (PARTITION BY app_sid, issue_id ORDER BY logged_dtm ASC) rn,
				issue_id, issue_log_id, app_sid
			  FROM csr.v$issue_log
			)
		 WHERE rn = 1
	) LOOP
		UPDATE csr.issue
		   SET first_issue_log_id = r.issue_log_id
		 WHERE issue_id = r.issue_id
		   AND app_sid = r.app_sid;
		   
		   COMMIT;
	END LOOP;
END;
/

@../issue_pkg
@../issue_body
@../pending_body
@../supplier_body
@../schema_body
@../csrimp/imp_body

-- Repeat to get any issues that were created during the release
BEGIN
	FOR r IN (
		-- get the most recent log entry
		SELECT *
		  FROM (
			SELECT ROW_NUMBER() OVER (PARTITION BY app_sid, issue_id ORDER BY logged_dtm DESC) rn,
				issue_id, issue_log_id, app_sid
			  FROM csr.v$issue_log
			)
		 WHERE rn = 1
	) LOOP
		UPDATE csr.issue
		   SET last_issue_log_id = r.issue_log_id
		 WHERE issue_id = r.issue_id
		   AND app_sid = r.app_sid;
		   
		   COMMIT;
	END LOOP;
END;
/

BEGIN
	FOR r IN (
		-- get the oldest log entry
		SELECT *
		  FROM (
			SELECT ROW_NUMBER() OVER (PARTITION BY app_sid, issue_id ORDER BY logged_dtm ASC) rn,
				issue_id, issue_log_id, app_sid
			  FROM csr.v$issue_log
			)
		 WHERE rn = 1
	) LOOP
		UPDATE csr.issue
		   SET first_issue_log_id = r.issue_log_id
		 WHERE issue_id = r.issue_id
		   AND app_sid = r.app_sid;
		   
		COMMIT;
	END LOOP;
END;
/

@update_tail

