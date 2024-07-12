-- Please update version.sql too -- this keeps clean builds in sync
define version=2259
@update_header

exec DBMS_RLS.ENABLE_POLICY('csr', 'customer', 'CUSTOMER_POLICY', FALSE);

ALTER TABLE CSR.CUSTOMER ADD 
(
  LIVE_METERING_SHOW_GAPS NUMBER(1) DEFAULT 0 NOT NULL ,
  METERING_GAPS_FROM_ACQUISITION NUMBER(1) DEFAULT 0 NOT NULL
);

exec DBMS_RLS.ENABLE_POLICY('csr', 'customer', 'CUSTOMER_POLICY', TRUE);

-- 
-- SEQUENCE: ISSUE_METER_MISSING_DATA_SEQ 
--

CREATE SEQUENCE CSR.ISSUE_METER_MISSING_DATA_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;

-- 
-- TABLE: CSR.ISSUE_METER_MISSING_DATA 
--

CREATE TABLE CSR.ISSUE_METER_MISSING_DATA (
  APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
  REGION_SID NUMBER(10) NOT NULL,
  ISSUE_METER_MISSING_DATA_ID NUMBER(10) NOT NULL,
  START_DTM DATE NOT NULL,
  END_DTM DATE NOT NULL,
  CONSTRAINT PK_ISSUE_METER_MISSING_DATA PRIMARY KEY (APP_SID, ISSUE_METER_MISSING_DATA_ID),
  CONSTRAINT FK_REGION_METER_MISSING_DATA FOREIGN KEY (APP_SID, REGION_SID) REFERENCES CSR.REGION(APP_SID, REGION_SID)
);

ALTER TABLE CSR.ISSUE ADD ISSUE_METER_MISSING_DATA_ID NUMBER(10);

ALTER TABLE CSR.ISSUE DROP CONSTRAINT CHK_ISSUE_FKS;

ALTER TABLE CSR.ISSUE 
ADD CONSTRAINT CHK_ISSUE_FKS CHECK ((ISSUE_PENDING_VAL_ID IS NOT NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL AND ISSUE_METER_MISSING_DATA_ID IS NULL AND ISSUE_SUPPLIER_ID IS NULL AND ISSUE_INITIATIVE_ID IS NULL)
OR
(ISSUE_SHEET_VALUE_ID IS NOT NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL AND ISSUE_METER_MISSING_DATA_ID IS NULL AND ISSUE_SUPPLIER_ID IS NULL AND ISSUE_INITIATIVE_ID IS NULL)
OR
(ISSUE_SURVEY_ANSWER_ID IS NOT NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL AND ISSUE_METER_MISSING_DATA_ID IS NULL AND ISSUE_SUPPLIER_ID IS NULL AND ISSUE_INITIATIVE_ID IS NULL)
OR
(ISSUE_NON_COMPLIANCE_ID IS NOT NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL AND ISSUE_METER_MISSING_DATA_ID IS NULL AND ISSUE_SUPPLIER_ID IS NULL AND ISSUE_INITIATIVE_ID IS NULL)
OR
(ISSUE_ACTION_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL AND ISSUE_METER_MISSING_DATA_ID IS NULL AND ISSUE_SUPPLIER_ID IS NULL AND ISSUE_INITIATIVE_ID IS NULL)
OR
(ISSUE_METER_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL AND ISSUE_METER_MISSING_DATA_ID IS NULL AND ISSUE_SUPPLIER_ID IS NULL AND ISSUE_INITIATIVE_ID IS NULL)
OR
(ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL AND ISSUE_SUPPLIER_ID IS NULL AND ISSUE_INITIATIVE_ID IS NULL AND ISSUE_METER_MISSING_DATA_ID IS NULL)
OR
(ISSUE_METER_ALARM_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL AND ISSUE_METER_MISSING_DATA_ID IS NULL AND ISSUE_SUPPLIER_ID IS NULL AND ISSUE_INITIATIVE_ID IS NULL)
OR
(ISSUE_METER_RAW_DATA_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL AND ISSUE_METER_MISSING_DATA_ID IS NULL AND ISSUE_SUPPLIER_ID IS NULL AND ISSUE_INITIATIVE_ID IS NULL)
OR
(ISSUE_METER_DATA_SOURCE_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_MISSING_DATA_ID IS NULL AND ISSUE_SUPPLIER_ID IS NULL AND ISSUE_INITIATIVE_ID IS NULL)
OR
(ISSUE_METER_MISSING_DATA_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL AND ISSUE_SUPPLIER_ID IS NULL AND ISSUE_INITIATIVE_ID IS NULL)
OR
(ISSUE_SUPPLIER_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_MISSING_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL AND ISSUE_INITIATIVE_ID IS NULL)
OR
(ISSUE_INITIATIVE_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL AND ISSUE_METER_DATA_SOURCE_ID IS NULL AND ISSUE_METER_MISSING_DATA_ID IS NULL AND ISSUE_SUPPLIER_ID IS NULL AND ISSUE_ACTION_ID IS NULL)
);

ALTER TABLE CSR.ISSUE
ADD CONSTRAINT FK_ISSUE_METER_MISSING_DATA
  FOREIGN KEY (APP_SID, ISSUE_METER_MISSING_DATA_ID)
  REFERENCES CSR.ISSUE_METER_MISSING_DATA(APP_SID, ISSUE_METER_MISSING_DATA_ID);

CREATE OR REPLACE VIEW csr.v$issue AS
SELECT i.app_sid, i.issue_id, i.label, i.description, i.source_label, i.is_visible, i.source_url, i.region_sid, re.description region_name, i.parent_id,
	   i.issue_escalated, i.owner_role_sid, i.owner_user_sid, i.first_issue_log_id, i.last_issue_log_id, NVL(lil.logged_dtm, i.raised_dtm) last_modified_dtm,
	   i.is_public, i.is_pending_assignment, i.rag_status_id, itrs.label rag_status_label, itrs.colour rag_status_colour, raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
	   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
	   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
	   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
	   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
	   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, c.more_info_1 correspondent_more_info_1,
	   sysdate now_dtm, due_dtm, forecast_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, ist.allow_children, ist.can_be_public, ist.show_forecast_dtm, ist.require_var_expl, ist.enable_reject_action,
	   i.issue_priority_id, ip.due_date_offset, ip.description priority_description,
	   CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden, i.first_priority_set_dtm,
	   issue_pending_val_id, i.issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id, issue_meter_missing_data_id, issue_supplier_id,
	   CASE WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND rejected_by_user_sid IS NULL AND SYSDATE > NVL(forecast_dtm, due_dtm) THEN 1 ELSE 0
	   END is_overdue,
	   CASE WHEN rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID') OR i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0
	   END is_owner,
	   CASE WHEN assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0 --OR #### HOW + WHERE CAN I GET THE ROLES THE USER IS PART OF??
	   END is_assigned_to_you,
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
	   END status, CASE WHEN ist.auto_close_after_resolve_days IS NULL THEN NULL ELSE i.allow_auto_close END allow_auto_close,
	   ist.restrict_users_to_region, ist.deletable_by_administrator, ist.deletable_by_owner,
	   ind.ind_sid, ind.description ind_name, isv.start_dtm, isv.end_dtm
  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user curej, csr_user cuass, role r, correspondent c, issue_priority ip,
	   (SELECT * FROM region_role_member WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')) rrm, v$region re, issue_log lil, v$issue_type_rag_status itrs,
	   v$ind ind, issue_sheet_value isv
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
   AND i.app_sid = itrs.app_sid(+) AND i.rag_status_id = itrs.rag_status_id(+) AND i.issue_type_id = itrs.issue_type_id(+)
   AND i.app_sid = isv.app_sid(+) AND i.issue_sheet_value_id = isv.issue_sheet_value_id(+)
   AND isv.app_sid = ind.app_sid(+) AND isv.ind_sid = ind.ind_sid(+)
   AND i.deleted = 0
   AND (i.issue_non_compliance_id IS NULL OR i.issue_non_compliance_id IN (
	-- filter out issues from deleted audits
	SELECT inc.issue_non_compliance_id
	  FROM issue_non_compliance inc
	  JOIN audit_non_compliance anc ON inc.non_compliance_id = anc.non_compliance_id AND inc.app_sid = anc.app_sid
	 WHERE NOT EXISTS (SELECT NULL FROM trash t WHERE t.trash_sid = anc.internal_audit_sid)
   ));

DECLARE
	v_missing_errors_role_sid	security.security_pkg.T_SID_ID;
	v_menu_meter_mon_sid		security.security_pkg.T_SID_ID;
	so_path_not_found EXCEPTION;
	PRAGMA EXCEPTION_INIT(so_path_not_found, -20102);
	v_class_id			security.security_pkg.T_CLASS_ID;
	v_groups_sid		security.security_pkg.T_SID_ID;
BEGIN
	FOR item IN (
				select c.app_sid, c.host
					from csr.customer c
						join  csr.customer_region_type crt on crt.app_sid = c.app_sid and region_type = csr.csr_data_pkg.REGION_TYPE_REALTIME_METER
				)
	LOOP
		BEGIN		
			security.user_pkg.logonadmin(item.host);
			
			BEGIN
				INSERT INTO csr.issue_type (app_sid, issue_type_id, label) 
					VALUES (security.security_pkg.GetAPP, 18 /*csr.csr_data_pkg.ISSUE_METER_MISSING_DATA*/, 'Meter missing data');
				EXCEPTION
					WHEN DUP_VAL_ON_INDEX THEN
					NULL;
			END;
				
			BEGIN
				v_menu_meter_mon_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP,'menu/meter_monitor');
			
				-- Add role for missing data errors
				-- csr.role_pkg.SetRole(security.security_pkg.getACT, security.security_pkg.getApp, 'Meter missing data errors', v_missing_errors_role_sid);
				UPDATE csr.role
				   SET name = 'Meter missing data errors',
					   lookup_key = NULL
				 WHERE LOWER(name) = LOWER('Meter missing data errors')
				   AND app_sid = security.security_pkg.getApp
				 RETURNING role_sid INTO v_missing_errors_role_sid;
				 
				-- insert if it doesn't do anything
				IF SQL%ROWCOUNT = 0 THEN
					
					v_class_id := security.class_pkg.GetClassId('CSRRole');
					v_groups_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.getACT, security.security_pkg.getApp, 'Groups');
					security.group_pkg.CreateGroupWithClass(security.security_pkg.getACT, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY,
						REPLACE('Meter missing data errors','/','\'), v_class_id, v_missing_errors_role_sid); --'
					
					--csr_data_pkg.WriteAuditLogEntry(security.security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security.security_pkg.getApp, security.security_pkg.getApp, 'Created role "{0}"', 
					--'Meter missing data errors');
					
					INSERT INTO csr.role 
						(role_sid, app_sid, name, lookup_key) 
					VALUES 
						(v_missing_errors_role_sid, security.security_pkg.getApp, 'Meter missing data errors', null);
				END IF;
				
				security.acl_pkg.AddACE(
					security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_menu_meter_mon_sid), -1,
					security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
					v_missing_errors_role_sid, security.security_pkg.PERMISSION_STANDARD_READ);
				EXCEPTION
					WHEN so_path_not_found THEN
						dbms_output.put_line('"menu/meter_monitor" not found for '||item.host||' ('||item.app_sid||')');
			END;
		END;
	END LOOP;
	
END;
/

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'ISSUE_METER_MISSING_DATA',
		policy_name     => 'ISSUE_METER_MISSING_DAT_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive
	);
EXCEPTION
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');
END;
/

@../csr_data_pkg
@../meter_monitor_pkg
@../issue_pkg

@../issue_body
@../meter_monitor_body

@update_tail
