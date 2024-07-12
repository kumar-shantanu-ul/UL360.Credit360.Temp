define version=3168
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/
CREATE SEQUENCE CSR.ENHESA_SITE_TYPE_ID_SEQ
;
CREATE TABLE CSR.ENHESA_SITE_TYPE(
    APP_SID             		NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SITE_TYPE_ID				NUMBER(10, 0),
	LABEL						VARCHAR2(256),
	CONSTRAINT PK_ENHESA_SITE_TYPE PRIMARY KEY (APP_SID, SITE_TYPE_ID)
)
;
CREATE SEQUENCE CSR.ENHESA_SITE_TYP_HEADING_ID_SEQ
;
CREATE TABLE CSR.ENHESA_SITE_TYPE_HEADING(
    APP_SID             		NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SITE_TYPE_HEADING_ID		NUMBER(10, 0),
	SITE_TYPE_ID				NUMBER(10, 0),
	HEADING_CODE				VARCHAR2(256),
	CONSTRAINT PK_SITE_TYPE_HEADING PRIMARY KEY (APP_SID, SITE_TYPE_HEADING_ID),
	CONSTRAINT UK_SITE_TYPE_HEADING UNIQUE (APP_SID, SITE_TYPE_ID, HEADING_CODE),
	CONSTRAINT FK_SITE_TYP_HEADING_SITE_TYP FOREIGN KEY (APP_SID, SITE_TYPE_ID)
		REFERENCES CSR.ENHESA_SITE_TYPE (APP_SID, SITE_TYPE_ID)
)
;
CREATE INDEX CSR.IX_SITE_TYP_HEADING_SITE_TYP ON CSR.ENHESA_SITE_TYPE_HEADING(APP_SID, SITE_TYPE_ID)
;
CREATE TABLE CSRIMP.ENHESA_SITE_TYPE(
    CSRIMP_SESSION_ID           NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	SITE_TYPE_ID				NUMBER(10),
	LABEL						VARCHAR2(256),
	CONSTRAINT pk_enhesa_site_type PRIMARY KEY (csrimp_session_id),
    CONSTRAINT fk_enhesa_site_type
		FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
)
;
CREATE TABLE CSRIMP.ENHESA_SITE_TYPE_HEADING(
    CSRIMP_SESSION_ID           NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    SITE_TYPE_HEADING_ID		NUMBER(10),
	SITE_TYPE_ID				NUMBER(10),
	HEADING_CODE				VARCHAR2(256),
	CONSTRAINT pk_enhesa_site_type_heading PRIMARY KEY (csrimp_session_id),
    CONSTRAINT fk_enhesa_site_type_heading
		FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
)
;
CREATE TABLE CSR.SCRAGPP_STATUS(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	OLD_SCRAG					NUMBER(1)	DEFAULT 1 NOT NULL,
	TESTCUBE_ENABLED			NUMBER(1)	DEFAULT 0 NOT NULL,
	VALIDATION_APPROVED_REF		VARCHAR2(1023),
	SCRAGPP_ENABLED				NUMBER(1)	DEFAULT 0 NOT NULL,
	CONSTRAINT PK_SCRAGPP_STATUS PRIMARY KEY (APP_SID),
	CONSTRAINT CHK_SCRAGPP_STATUS_OLD_SCRAG CHECK (OLD_SCRAG IN (0,1)),
	CONSTRAINT CHK_SCRAGPP_STATUS_TESTCUBE CHECK (TESTCUBE_ENABLED IN (0,1)),
	CONSTRAINT CHK_SCRAGPP_STATUS_SCRAGPP CHECK (SCRAGPP_ENABLED IN (0,1))
)
;
CREATE TABLE CSRIMP.SCRAGPP_STATUS(
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_SCRAG					NUMBER(1)	DEFAULT 1 NOT NULL,
	TESTCUBE_ENABLED			NUMBER(1)	DEFAULT 0 NOT NULL,
	VALIDATION_APPROVED_REF		VARCHAR2(1023),
	SCRAGPP_ENABLED				NUMBER(1)	DEFAULT 0 NOT NULL,
	CONSTRAINT PK_SCRAGPP_STATUS PRIMARY KEY (CSRIMP_SESSION_ID),
	CONSTRAINT FK_SCRAGPP_STATUS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE,
	CONSTRAINT CHK_SCRAGPP_STATUS_OLD_SCRAG CHECK (OLD_SCRAG IN (0,1)),
	CONSTRAINT CHK_SCRAGPP_STATUS_TESTCUBE CHECK (TESTCUBE_ENABLED IN (0,1)),
	CONSTRAINT CHK_SCRAGPP_STATUS_SCRAGPP CHECK (SCRAGPP_ENABLED IN (0,1))
)
;
CREATE TABLE CSR.SCRAGPP_AUDIT_LOG(
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	ACTION					VARCHAR2(1023)	NOT NULL,
	ACTION_DTM				DATE,
	USER_SID				NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_SCRAGPP_AUDIT_LOG PRIMARY KEY (APP_SID, ACTION, ACTION_DTM)
)
;
CREATE TABLE CSRIMP.SCRAGPP_AUDIT_LOG(
	CSRIMP_SESSION_ID		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ACTION					VARCHAR2(1023)	NOT NULL,
	ACTION_DTM				DATE,
	USER_SID				NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_SCRAGPP_AUDIT_LOG PRIMARY KEY (CSRIMP_SESSION_ID, ACTION, ACTION_DTM),
	CONSTRAINT FK_SCRAGPP_AUDIT_LOG FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
)
;
CREATE SEQUENCE CSR.CORE_WORKING_HOURS_ID_SEQ;
CREATE TABLE CSR.CORE_WORKING_HOURS (
	APP_SID						NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CORE_WORKING_HOURS_ID		NUMBER(10)		NOT NULL,
	START_TIME					VARCHAR2(16)	NOT NULL,
	END_TIME					VARCHAR2(16)	NOT NULL,
	CONSTRAINT PK_CORE_WORKING_HOURS PRIMARY KEY (APP_SID, CORE_WORKING_HOURS_ID),
	CONSTRAINT FK_CUSTOMER_COREWKHRS FOREIGN KEY 
		(APP_SID) REFERENCES CSR.CUSTOMER(APP_SID)
);
CREATE TABLE CSR.CORE_WORKING_HOURS_DAY (
	APP_SID						NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CORE_WORKING_HOURS_ID		NUMBER(10)		NOT NULL,
	DAY							NUMBER(1)		NOT NULL,
	CONSTRAINT PK_CORE_WORKING_HOURS_DAY PRIMARY KEY (APP_SID, CORE_WORKING_HOURS_ID, DAY),
	CONSTRAINT FK_COREWKHRS_COREWKHRSDAY FOREIGN KEY 
		(APP_SID, CORE_WORKING_HOURS_ID) REFERENCES CSR.CORE_WORKING_HOURS(APP_SID, CORE_WORKING_HOURS_ID),
	CONSTRAINT CK_CORE_WORKING_HOURS_DAY CHECK (DAY IN (1,2,3,4,5,6,7))
);
CREATE TABLE CSR.CORE_WORKING_HOURS_REGION (
	APP_SID						NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	REGION_SID					NUMBER(10)		NOT NULL,
	CORE_WORKING_HOURS_ID		NUMBER(10)		NOT NULL,
	CONSTRAINT PK_CORE_WORKING_HOURS_REGION PRIMARY KEY (APP_SID, REGION_SID, CORE_WORKING_HOURS_ID),
	CONSTRAINT FK_REGION_COREWKHRS FOREIGN KEY 
		(APP_SID, REGION_SID) REFERENCES CSR.REGION(APP_SID, REGION_SID)
);
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_CORE_WORKING_HOURS (
	INHERITED_FROM_REGION_SID	NUMBER(10)		NOT NULL,
	CORE_WORKING_HOURS_ID		NUMBER(10)		NOT NULL,
	DAY							NUMBER(1)		NOT NULL,
	START_TIME					VARCHAR2(16)	NOT NULL,
	END_TIME					VARCHAR2(16)	NOT NULL,
	CONSTRAINT CK_TMP_CORE_WORKING_HOURS_DAY CHECK (DAY IN (1,2,3,4,5,6,7))
) ON COMMIT DELETE ROWS;
CREATE TABLE CSRIMP.CORE_WORKING_HOURS (
	CSRIMP_SESSION_ID			NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CORE_WORKING_HOURS_ID		NUMBER(10)		NOT NULL,
	START_TIME					VARCHAR2(16)	NOT NULL,
	END_TIME					VARCHAR2(16)	NOT NULL,
	CONSTRAINT PK_CORE_WORKING_HOURS PRIMARY KEY (CSRIMP_SESSION_ID, CORE_WORKING_HOURS_ID),
	CONSTRAINT FK_CUSTOMER_COREWKHRS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);
CREATE TABLE CSRIMP.CORE_WORKING_HOURS_DAY (
	CSRIMP_SESSION_ID			NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CORE_WORKING_HOURS_ID		NUMBER(10)		NOT NULL,
	DAY							NUMBER(1)		NOT NULL,
	CONSTRAINT PK_CORE_WORKING_HOURS_DAY PRIMARY KEY (CSRIMP_SESSION_ID, CORE_WORKING_HOURS_ID, DAY),
	CONSTRAINT FK_COREWKHRS_COREWKHRSDAY FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE,
	CONSTRAINT CK_CORE_WORKING_HOURS_DAY CHECK (DAY IN (1,2,3,4,5,6,7))
);
CREATE TABLE CSRIMP.CORE_WORKING_HOURS_REGION (
	CSRIMP_SESSION_ID			NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	REGION_SID					NUMBER(10)		NOT NULL,
	CORE_WORKING_HOURS_ID		NUMBER(10)		NOT NULL,
	CONSTRAINT PK_CORE_WORKING_HOURS_REGION PRIMARY KEY (CSRIMP_SESSION_ID, REGION_SID, CORE_WORKING_HOURS_ID),
	CONSTRAINT FK_REGION_COREWKHRS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);
CREATE TABLE CSRIMP.MAP_CORE_WORKING_HOURS  (
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_core_working_hours_id	NUMBER(10) NOT NULL,
	new_core_working_hours_id	NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CORE_WORKING_HOURS primary key (csrimp_session_id, old_core_working_hours_id) USING INDEX,
	CONSTRAINT UK_MAP_CORE_WORKING_HOURS UNIQUE (csrimp_session_id, new_core_working_hours_id) USING INDEX,
	CONSTRAINT FK_MAP_CORE_WORKING_HOURS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);


ALTER TABLE CSR.ENHESA_SITE_TYPE
  MODIFY (LABEL			VARCHAR2(256) NOT NULL);
ALTER TABLE CSR.ENHESA_SITE_TYPE_HEADING
  MODIFY (HEADING_CODE	VARCHAR2(256) NOT NULL);
		  
ALTER TABLE CSRIMP.ENHESA_SITE_TYPE
  MODIFY (LABEL			VARCHAR2(256) NOT NULL);
		  
ALTER TABLE CSRIMP.ENHESA_SITE_TYPE_HEADING
  MODIFY (HEADING_CODE	VARCHAR2(256) NOT NULL);
ALTER TABLE CSR.ENHESA_OPTIONS
  ADD (MANUAL_RUN						NUMBER(1) DEFAULT 0 NOT NULL);
ALTER TABLE CSRIMP.ENHESA_OPTIONS
  ADD (MANUAL_RUN						NUMBER(1) NOT NULL);
alter table csr.issue_type add (
    allow_urgent_alert number(1) default 1 not null,
    email_involved_users number(1) default 1 not null,
    constraint ck_issue_type_allow_urgent check (allow_urgent_alert in (0,1)),
    constraint ck_issue_type_email_inv_users check (email_involved_users in (0,1))
);
alter table csrimp.issue_type add (
    allow_urgent_alert number(1) not null,
    email_involved_users number(1) not null,
    constraint ck_issue_type_allow_urgent check (allow_urgent_alert in (0,1)),
    constraint ck_issue_type_email_inv_users check (email_involved_users in (0,1))
);
alter table CSR.TEMP_ISSUE_SEARCH add  ( ALLOW_URGENT_ALERT			NUMBER(1) );
CREATE OR REPLACE VIEW csr.v$issue AS
SELECT i.app_sid, NVL2(i.issue_ref, ist.internal_issue_ref_prefix || i.issue_ref, null) custom_issue_id, i.issue_id, i.label, i.description, i.source_label, i.is_visible, i.source_url, i.region_sid, re.description region_name, i.parent_id,
	   i.issue_escalated, i.owner_role_sid, i.owner_user_sid, cuown.user_name owner_user_name, cuown.full_name owner_full_name, cuown.email owner_email,
	   r2.name owner_role_name, i.first_issue_log_id, i.last_issue_log_id, NVL(lil.logged_dtm, i.raised_dtm) last_modified_dtm,
	   i.is_public, i.is_pending_assignment, i.rag_status_id, i.manual_completion_dtm, manual_comp_dtm_set_dtm, itrs.label rag_status_label, itrs.colour rag_status_colour,
	   raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
	   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
	   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
	   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
	   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
	   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, 
	   c.more_info_1 correspondent_more_info_1, sysdate now_dtm, due_dtm, forecast_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, 
	   ist.allow_children, ist.can_set_public, ist.show_forecast_dtm, ist.require_var_expl, ist.enable_reject_action, ist.require_due_dtm_comment, 
	   ist.enable_manual_comp_date, ist.comment_is_optional, ist.due_date_is_mandatory, ist.is_region_editable is_issue_type_region_editable, i.issue_priority_id, 
	   ip.due_date_offset, ip.description priority_description,
	   CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden, 
	   i.first_priority_set_dtm, issue_pending_val_id, i.issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id,
	   issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id, issue_meter_missing_data_id, issue_supplier_id, issue_compliance_region_id,
	   CASE WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND rejected_by_user_sid IS NULL AND SYSDATE > NVL(forecast_dtm, due_dtm) THEN 1 ELSE 0
	   END is_overdue,
	   CASE WHEN rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID') OR i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0
	   END is_owner,
	   CASE WHEN assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0 --OR #### HOW + WHERE CAN I GET THE ROLES THE USER IS PART OF??
	   END is_assigned_to_you,
	   CASE WHEN i.resolved_dtm IS NULL AND i.manual_completion_dtm IS NULL THEN 0 ELSE 1
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
	   END status,
	   CASE WHEN ist.auto_close_after_resolve_days IS NULL THEN NULL ELSE i.allow_auto_close END allow_auto_close, ist.auto_close_after_resolve_days,
	   ist.restrict_users_to_region, ist.deletable_by_administrator, ist.deletable_by_owner, ist.deletable_by_raiser, ist.send_alert_on_issue_raised,
	   ind.ind_sid, ind.description ind_name, isv.start_dtm, isv.end_dtm, ist.owner_can_be_changed, ist.show_one_issue_popup, ist.lookup_key, ist.allow_owner_resolve_and_close,
	   CASE WHEN ist.get_assignables_sp IS NULL THEN 0 ELSE 1 END get_assignables_overridden, ist.create_raw,
	   i.permit_id, i.issue_due_source_id, i.issue_due_offset_days, i.issue_due_offset_months, i.issue_due_offset_years, ids.source_description due_dtm_source_description,
	   CASE WHEN EXISTS(SELECT * 
						  FROM issue_due_source ids
						 WHERE ids.app_sid = i.app_sid 
						   AND ids.issue_type_id = i.issue_type_id)
			THEN 1 ELSE 0
	   END relative_due_dtm_enabled,
	   i.is_critical, ist.allow_critical, ist.allow_urgent_alert
  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user curej, csr_user cuass, csr_user cuown,  role r, role r2, correspondent c, issue_priority ip,
	   (SELECT * FROM region_role_member WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')) rrm, v$region re, issue_log lil, v$issue_type_rag_status itrs,
	   v$ind ind, issue_sheet_value isv, issue_due_source ids
 WHERE i.app_sid = curai.app_sid AND i.raised_by_user_sid = curai.csr_user_sid
   AND i.app_sid = ist.app_sid AND i.issue_type_Id = ist.issue_type_id
   AND i.app_sid = cures.app_sid(+) AND i.resolved_by_user_sid = cures.csr_user_sid(+)
   AND i.app_sid = cuclo.app_sid(+) AND i.closed_by_user_sid = cuclo.csr_user_sid(+)
   AND i.app_sid = curej.app_sid(+) AND i.rejected_by_user_sid = curej.csr_user_sid(+)
   AND i.app_sid = cuass.app_sid(+) AND i.assigned_to_user_sid = cuass.csr_user_sid(+)
   AND i.app_sid = cuown.app_sid(+) AND i.owner_user_sid = cuown.csr_user_sid(+)
   AND i.app_sid = r.app_sid(+) AND i.assigned_to_role_sid = r.role_sid(+)
   AND i.app_sid = r2.app_sid(+) AND i.owner_role_sid = r2.role_sid(+)
   AND i.app_sid = re.app_sid(+) AND i.region_sid = re.region_sid(+)
   AND i.app_sid = c.app_sid(+) AND i.correspondent_id = c.correspondent_id(+)
   AND i.app_sid = ip.app_sid(+) AND i.issue_priority_id = ip.issue_priority_id(+)
   AND i.app_sid = rrm.app_sid(+) AND i.region_sid = rrm.region_sid(+) AND i.owner_role_sid = rrm.role_sid(+)
   AND i.app_sid = lil.app_sid(+) AND i.last_issue_log_id = lil.issue_log_id(+)
   AND i.app_sid = itrs.app_sid(+) AND i.rag_status_id = itrs.rag_status_id(+) AND i.issue_type_id = itrs.issue_type_id(+)
   AND i.app_sid = isv.app_sid(+) AND i.issue_sheet_value_id = isv.issue_sheet_value_id(+)
   AND isv.app_sid = ind.app_sid(+) AND isv.ind_sid = ind.ind_sid(+)
   AND i.app_sid = ids.app_sid(+) AND i.issue_due_source_id = ids.issue_due_source_id(+)
   AND i.deleted = 0;
BEGIN
	-- Ethics was optional module that is being trashed.
	-- Conditionally remove packages / cross schema constraints
	FOR r IN (
		SELECT object_name
		  FROM all_objects
		 WHERE owner = 'ETHICS'
		   AND object_type = 'PACKAGE'
		   AND object_name IN ('QUESTION_PKG','PARTICIPANT_PKG','ETHICS_PKG','DEMO_PKG','COURSE_PKG','COMPANY_USER_PKG','COMPANY_PKG')
	) LOOP
		EXECUTE IMMEDIATE 'DROP PACKAGE ETHICS.'||r.object_name;
	END LOOP;
	
	FOR r IN (
		SELECT owner, table_name, constraint_name
		  FROM all_constraints
		 WHERE r_owner != 'ETHICS'
		   AND owner = 'ETHICS'
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE ETHICS.'||r.table_name||' DROP CONSTRAINT '||r.constraint_name;
	END LOOP;
END;
/
ALTER TABLE CSR.USER_PROFILE MODIFY NUMBER_HOURS NUMBER(12,2);
ALTER TABLE CSR.USER_PROFILE_STAGED_RECORD MODIFY NUMBER_HOURS NUMBER(12,2);
CREATE OR REPLACE TYPE CSR.T_USER_PROFILE_STAGED_ROW AS 
	OBJECT (
	PRIMARY_KEY						VARCHAR2(128),
	EMPLOYEE_REF					VARCHAR2(128),
	PAYROLL_REF						NUMBER(10),
	FIRST_NAME						VARCHAR2(256),
	LAST_NAME						VARCHAR2(256),
	MIDDLE_NAME						VARCHAR2(256),
	FRIENDLY_NAME					VARCHAR2(256),
	EMAIL_ADDRESS					VARCHAR2(256),
	USERNAME						VARCHAR2(256),
	WORK_PHONE_NUMBER				VARCHAR2(32),
	WORK_PHONE_EXTENSION			VARCHAR2(8),
	HOME_PHONE_NUMBER				VARCHAR2(32),
	MOBILE_PHONE_NUMBER				VARCHAR2(32),
	MANAGER_EMPLOYEE_REF			VARCHAR2(128),
	MANAGER_PAYROLL_REF				NUMBER(10),
	MANAGER_PRIMARY_KEY				VARCHAR2(128),
	EMPLOYMENT_START_DATE			DATE,
	EMPLOYMENT_LEAVE_DATE			DATE,
	PROFILE_ACTIVE					NUMBER(1),
	DATE_OF_BIRTH					DATE,
	GENDER							VARCHAR2(8),
	JOB_TITLE						VARCHAR2(128),
	CONTRACT						VARCHAR2(256),
	EMPLOYMENT_TYPE					VARCHAR2(256),
	PAY_GRADE						VARCHAR2(256),
	BUSINESS_AREA_REF				VARCHAR2(256),
	BUSINESS_AREA_CODE				NUMBER(10),
	BUSINESS_AREA_NAME				VARCHAR2(256),
	BUSINESS_AREA_DESCRIPTION		VARCHAR2(1024),
	DIVISION_REF					VARCHAR2(256),
	DIVISION_CODE					NUMBER(10),
	DIVISION_NAME					VARCHAR2(256),
	DIVISION_DESCRIPTION			VARCHAR2(1024),
	DEPARTMENT						VARCHAR2(256),
	NUMBER_HOURS					NUMBER(12,2),
	COUNTRY							VARCHAR2(128),
	LOCATION						VARCHAR2(256),
	BUILDING						VARCHAR2(256),
	COST_CENTRE_REF					VARCHAR2(256),
	COST_CENTRE_CODE				NUMBER(10),
	COST_CENTRE_NAME				VARCHAR2(256),
	COST_CENTRE_DESCRIPTION			VARCHAR2(1024),
	WORK_ADDRESS_1					VARCHAR2(256),
	WORK_ADDRESS_2					VARCHAR2(256),
	WORK_ADDRESS_3					VARCHAR2(256),
	WORK_ADDRESS_4					VARCHAR2(256),
	HOME_ADDRESS_1					VARCHAR2(256),
	HOME_ADDRESS_2					VARCHAR2(256),
	HOME_ADDRESS_3					VARCHAR2(256),
	HOME_ADDRESS_4					VARCHAR2(256),
	LOCATION_REGION_REF				VARCHAR(1024),
	INTERNAL_USERNAME				VARCHAR2(256),
	MANAGER_USERNAME				VARCHAR2(256),
	ACTIVATE_ON						DATE,
	DEACTIVATE_ON					DATE,
	INSTANCE_STEP_ID				NUMBER(10),
	LAST_UPDATED_DTM				DATE,
	LAST_UPDATED_USER_SID			NUMBER(10),
	LAST_UPDATE_METHOD				VARCHAR(256),
	ERROR_MESSAGE					VARCHAR(1024)
	);
/
ALTER TABLE CSR.METER_BUCKET ADD (
	CORE_WORKING_HOURS			NUMBER(1)		DEFAULT 0 NOT NULL,
	CONSTRAINT CK_CORE_WORKING_HOURS CHECK (CORE_WORKING_HOURS IN (0,1))
);
ALTER TABLE CSR.METER_ALARM_STATISTIC ADD (
	CORE_WORKING_HOURS			NUMBER(1)		DEFAULT 0 NOT NULL,
	POS							NUMBER(10)		DEFAULT 0 NOT NULL,
	CONSTRAINT CK_CORE_WORKING_HOURS_MAS CHECK (CORE_WORKING_HOURS IN (0,1))
);
ALTER TABLE CSR.METER_ALARM MODIFY (
	COMPARE_STATISTIC_ID		NUMBER(10)		NULL
);
ALTER TABLE CSR.METER_ALARM RENAME COLUMN COMPARISON_PCT TO COMPARISON_VAL;
ALTER TABLE CSRIMP.METER_BUCKET ADD (
	CORE_WORKING_HOURS			NUMBER(1)		NOT NULL,
	CONSTRAINT CK_CORE_WORKING_HOURS CHECK (CORE_WORKING_HOURS IN (0,1))
);
ALTER TABLE CSRIMP.METER_ALARM_STATISTIC ADD (
	CORE_WORKING_HOURS			NUMBER(1)		NOT NULL,
	POS							NUMBER(10)		NOT NULL,
	CONSTRAINT CK_CORE_WORKING_HOURS_MAS CHECK (CORE_WORKING_HOURS IN (0,1))
);
ALTER TABLE CSRIMP.METER_ALARM MODIFY (
	COMPARE_STATISTIC_ID		NUMBER(10)		NULL
);
ALTER TABLE CSRIMP.METER_ALARM RENAME COLUMN COMPARISON_PCT TO COMPARISON_VAL;
ALTER TABLE csr.compliance_item_rollout
	ADD federal_requirement_code VARCHAR2(255);
ALTER TABLE csr.compliance_item_rollout
	ADD is_federal_req NUMBER(10,0);
ALTER TABLE csrimp.compliance_item_rollout
	ADD federal_requirement_code VARCHAR2(255);
ALTER TABLE csrimp.compliance_item_rollout
	ADD is_federal_req NUMBER(10,0);


GRANT SELECT, INSERT, UPDATE ON csr.enhesa_site_type TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.enhesa_site_type_heading TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.enhesa_site_type TO tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.enhesa_site_type_heading TO tool_user;
GRANT SELECT ON csr.enhesa_site_type_id_seq TO csrimp;
GRANT SELECT ON csr.enhesa_site_typ_heading_id_seq TO csrimp;
GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.scragpp_status TO tool_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.scragpp_audit_log TO tool_user;
GRANT INSERT ON csr.scragpp_audit_log TO csrimp;
GRANT INSERT ON csr.scragpp_status TO csrimp;
CREATE OR REPLACE PACKAGE csr.scrag_pp_pkg
AS
PROCEDURE dummy;
END;
/
GRANT EXECUTE ON csr.scrag_pp_pkg TO csrimp;
grant select on csr.core_working_hours_id_seq to csrimp;
grant select, insert, update on csr.core_working_hours to csrimp;
grant select, insert, update on csr.core_working_hours_day to csrimp;
grant select, insert, update on csr.core_working_hours_region to csrimp;
grant select, insert, update on csrimp.core_working_hours to tool_user;
grant select, insert, update on csrimp.core_working_hours_day to tool_user;
grant select, insert, update on csrimp.core_working_hours_region to tool_user;




CREATE OR REPLACE VIEW csr.sheet_with_last_action AS
	SELECT sh.app_sid, sh.sheet_id, sh.delegation_sid, sh.start_dtm, sh.end_dtm, sh.reminder_dtm, sh.submission_dtm,
		   she.sheet_action_id last_action_id, she.from_user_sid last_action_from_user_sid, she.action_dtm last_action_dtm,
		   she.note last_action_note, she.to_delegation_sid last_action_to_delegation_sid,
		   CASE WHEN SYSTIMESTAMP AT TIME ZONE COALESCE(ut.timezone, a.timezone, 'Etc/GMT') >= from_tz_robust(cast(sh.submission_dtm as timestamp), COALESCE(ut.timezone, a.timezone, 'Etc/GMT'))
                 AND she.sheet_action_id IN (0,10,2)
                    THEN 1
				WHEN SYSTIMESTAMP AT TIME ZONE COALESCE(ut.timezone, a.timezone, 'Etc/GMT') >= from_tz_robust(cast(sh.reminder_dtm as timestamp), COALESCE(ut.timezone, a.timezone, 'Etc/GMT'))
                 AND she.sheet_action_id IN (0,10,2)
                    THEN 2
				ELSE 3
		   END status, sh.is_visible, sh.last_sheet_history_id, sha.colour last_action_colour, sh.is_read_only, sh.percent_complete,
		   sha.description last_action_desc, sha.downstream_description last_action_downstream_desc, sh.automatic_approval_dtm, sh.automatic_approval_status
	 FROM sheet sh
		JOIN sheet_history she ON sh.last_sheet_history_id = she.sheet_history_id AND she.sheet_id = sh.sheet_id AND sh.app_sid = she.app_sid
		JOIN sheet_action sha ON she.sheet_action_id = sha.sheet_action_id
        LEFT JOIN csr.csr_user u ON u.csr_user_sid = SYS_CONTEXT('SECURITY','SID') AND u.app_sid = sh.app_sid
        LEFT JOIN security.user_table ut ON ut.sid_id = u.csr_user_sid
        LEFT JOIN security.application a ON a.application_sid_id = u.app_sid;




INSERT INTO CSR.SCHEMA_TABLE
(OWNER, TABLE_NAME, ENABLE_EXPORT, ENABLE_IMPORT, CSRIMP_TABLE_NAME, MODULE_NAME)
VALUES
('CSR', 'ENHESA_SITE_TYPE', 1, 1, 'ENHESA_SITE_TYPE', 'Enhesa')
;
INSERT INTO CSR.SCHEMA_TABLE
(OWNER, TABLE_NAME, ENABLE_EXPORT, ENABLE_IMPORT, CSRIMP_TABLE_NAME, MODULE_NAME)
VALUES
('CSR', 'ENHESA_SITE_TYPE_HEADING', 1, 1, 'ENHESA_SITE_TYPE_HEADING', 'Enhesa')
;
INSERT INTO CSR.SCHEMA_COLUMN
(OWNER, TABLE_NAME, COLUMN_NAME, ENABLE_EXPORT, ENABLE_IMPORT, SEQUENCE_OWNER, SEQUENCE_NAME)
VALUES
('CSR', 'ENHESA_SITE_TYPE', 'SITE_TYPE_ID', 1, 1, 'CSR', 'ENHESA_SITE_TYPE_ID_SEQ')
;
INSERT INTO CSR.SCHEMA_COLUMN
(OWNER, TABLE_NAME, COLUMN_NAME, ENABLE_EXPORT, ENABLE_IMPORT, SEQUENCE_OWNER, SEQUENCE_NAME)
VALUES
('CSR', 'ENHESA_SITE_TYPE_HEADING', 'SITE_TYPE_HEADING_ID', 1, 1, 'CSR', 'ENHESA_SITE_TYP_HEADING_ID_SEQ')
;
INSERT INTO CSR.SCHEMA_COLUMN
(OWNER, TABLE_NAME, COLUMN_NAME, ENABLE_EXPORT, ENABLE_IMPORT, SEQUENCE_OWNER, SEQUENCE_NAME, IS_MAP_SOURCE)
VALUES
('CSR', 'ENHESA_SITE_TYPE_HEADING', 'SITE_TYPE_ID', 1, 1, 'CSR', 'ENHESA_SITE_TYPE_ID_SEQ', 0)
;
INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
VALUES (102, 'Chain SRM activities', 'EnableChainActivities', 'Enable SRM activities. This feature is only available for supply chain sites.', 1);
BEGIN
	UPDATE csr.customer SET helper_assembly = 'Centrica.Helper' WHERE app_sid IN (SELECT app_sid FROM csr.customer WHERE host = 'centrica.credit360.com');
END;
/
BEGIN
	security.user_pkg.LogonAdmin;
	
	DELETE FROM csr.module_param WHERE module_id = 13;
	DELETE FROM csr.module WHERE module_id = 13;
	
	FOR r IN (
		SELECT sid_id
		  FROM security.menu 
		 WHERE LOWER(action) LIKE '%/csr/site/ethics%'
	) LOOP
		security.securableobject_pkg.DeleteSO(security.security_pkg.GetAct, r.sid_id);
	END LOOP;
END;
/
INSERT INTO csr.scragpp_status (app_sid, old_scrag, scragpp_enabled)
SELECT app_sid, 1, 0
  FROM csr.customer
 WHERE unmerged_scenario_run_sid IS NULL OR merged_scenario_run_sid IS NULL;
INSERT INTO csr.scragpp_status (app_sid, old_scrag, scragpp_enabled)
SELECT app_sid, 0, 1
  FROM csr.customer
 WHERE unmerged_scenario_run_sid IS NOT NULL AND merged_scenario_run_sid IS NOT NULL;
CREATE OR REPLACE FUNCTION csr.Temp_SecurableObjectExists(
	in_path IN VARCHAR2,
	in_parent_sid_id IN Security_Pkg.T_SID_ID
)
RETURN BOOLEAN
AS
v_securableObject_sid	security.security_pkg.T_SID_ID;
BEGIN
	v_securableObject_sid := security.securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), in_parent_sid_id, in_path);
	RETURN TRUE;
	EXCEPTION
		WHEN OTHERS THEN
			RETURN FALSE;
END;
/
DECLARE
	v_app_sid					security.security_pkg.T_SID_ID;
	v_scenarios_sid				security.security_pkg.T_SID_ID;
	v_test_scenario_exists		BOOLEAN;
BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN 
	(
	SELECT host 
	  FROM csr.customer
	 WHERE (LOWER(host), app_sid) IN (
		SELECT LOWER(website_name), application_sid_id
		  FROM security.website
		)
	)
	LOOP
	BEGIN
		security.user_pkg.logonadmin(r.host);
		v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
		
		IF csr.Temp_SecurableObjectExists('Scenarios', v_app_sid) THEN
			v_scenarios_sid := security.securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), v_app_sid, 'Scenarios');
			v_test_scenario_exists := csr.Temp_SecurableObjectExists('New calc engine scenario run', v_scenarios_sid);
			
			IF v_test_scenario_exists THEN
				UPDATE csr.scragpp_status
				   SET testcube_enabled = 1
				 WHERE app_sid = v_app_sid;
			END IF;
		END IF;
	END;
	END LOOP;
	security.user_pkg.LogonAdmin;
END;
/
DROP FUNCTION csr.Temp_SecurableObjectExists;
DECLARE
	v_region_root					NUMBER(10);
	v_daily_bucket_id				NUMBER(10);
	v_hourly_bucket_id				NUMBER(10);
	v_meter_input_id				NUMBER(10);
	v_cwh_id						NUMBER(10);
BEGIN
	-- For each app with meter alarm stats
	FOR a IN (
		SELECT DISTINCT app_sid
		  FROM csr.meter_alarm_statistic
	) LOOP
	
		SELECT region_tree_root_sid
		  INTO v_region_root
		  FROM csr.region_tree
		 WHERE app_sid = a.app_sid
		   AND is_primary = 1;
		-- Set a default core working hours set that matches the old hard-coded 
		-- values if the client has any core working hours stats in use.
		FOR r IN (
			SELECT rt.region_tree_root_sid
			  FROM csr.region_tree rt
			  JOIN (
			  	SELECT s.app_sid
				  FROM csr.meter_alarm_statistic s
				 WHERE s.app_sid = a.app_sid
				   AND LOWER(s.name) LIKE '%core%'
				   AND s.all_meters = 1
				UNION
				SELECT s.app_sid
				  FROM csr.meter_alarm_statistic s
				  JOIN csr.meter_alarm ma on ma.app_sid = a.app_sid AND ma.look_at_statistic_id = s.statistic_id
				 WHERE s.app_sid = a.app_sid
				   AND LOWER(s.name) LIKE '%core%'
				UNION
				SELECT s.app_sid
				  FROM csr.meter_alarm_statistic s
				  JOIN csr.meter_alarm ma on ma.app_sid = a.app_sid AND ma.compare_statistic_id = s.statistic_id
				 WHERE s.app_sid = a.app_sid
				   AND LOWER(s.name) LIKE '%core%'
			  ) x ON x.app_sid = rt.app_sid
			 WHERE rt.app_sid = a.app_sid
			   AND rt.is_primary = 1
		) LOOP
			INSERT INTO csr.core_working_hours (app_sid, core_working_hours_id, start_time, end_time)
			VALUES (a.app_sid, csr.core_working_hours_id_seq.NEXTVAL, '0 07:00:00', '0 17:00:00')
			RETURNING core_working_hours_id INTO v_cwh_id;
			INSERT INTO csr.core_working_hours_region (app_sid, core_working_hours_id, region_sid)
			VALUES (a.app_sid, v_cwh_id, r.region_tree_root_sid);
			INSERT INTO csr.core_working_hours_day (app_sid, core_working_hours_id, day)
			VALUES(a.app_sid, v_cwh_id, 1);
			INSERT INTO csr.core_working_hours_day (app_sid, core_working_hours_id, day)
			VALUES(a.app_sid, v_cwh_id, 2);
			INSERT INTO csr.core_working_hours_day (app_sid, core_working_hours_id, day)
			VALUES(a.app_sid, v_cwh_id, 3);
			INSERT INTO csr.core_working_hours_day (app_sid, core_working_hours_id, day)
			VALUES(a.app_sid, v_cwh_id, 4);
			INSERT INTO csr.core_working_hours_day (app_sid, core_working_hours_id, day)
			VALUES(a.app_sid, v_cwh_id, 5);
			EXIT;
		END LOOP;
		-- Ensure any existing stats with the word "core" 
		-- in the name have the core_working_hours flag set.
		UPDATE csr.meter_alarm_statistic
		   SET core_working_hours = 1
		 WHERE app_sid = a.app_sid
		   AND LOWER(name) LIKE '%core%';
		-- Set the day specific stat positions
		FOR r IN (
			SELECT statistic_id, ROWNUM rn
			  FROM csr.meter_alarm_statistic
			 WHERE app_sid = a.app_sid
			   AND name IN (
				'Monday''s usage',
				'Tuesday''s usage',
				'Wednesday''s usage',
				'Thursday''s usage',
				'Friday''s usage',
				'Saturday''s usage',
				'Sunday''s usage'
			  )
			 ORDER BY statistic_id
		) LOOP
			UPDATE csr.meter_alarm_statistic
			   SET pos = 50 + r.rn -1
			 WHERE app_sid = a.app_sid
			   AND statistic_id = r.statistic_id;
		END LOOP;
		FOR r IN (
			SELECT statistic_id, ROWNUM rn
			  FROM csr.meter_alarm_statistic
			 WHERE app_sid = a.app_sid
			   AND name IN (
				'Average Monday usage',
				'Average Tuesday usage',
				'Average Wednesday usage',
				'Average Thursday usage',
				'Average Friday usage',
				'Average Saturday usage',
				'Average Sunday usage'
			   )
			 ORDER BY statistic_id
		) LOOP
			UPDATE csr.meter_alarm_statistic
			   SET pos = 57 + r.rn - 1
			 WHERE app_sid = a.app_sid
			   AND statistic_id = r.statistic_id;
		END LOOP;
		BEGIN
			-- Find consumption input
			SELECT meter_input_id
			  INTO v_meter_input_id
			  FROM csr.meter_input
			 WHERE app_sid = a.app_sid
			   AND lookup_key = 'CONSUMPTION';
			-- Add/replace the core/non-core working hours stats
			BEGIN
				-- Find the hourly bucket
				SELECT meter_bucket_id
				  INTO v_hourly_bucket_id
				  FROM csr.meter_bucket
				 WHERE app_sid = a.app_sid
				   AND is_hours = 1
				   AND duration = 24;
				UPDATE csr.meter_alarm_statistic
				   SET name = 'Core working hours - daily usage',
					   comp_proc = 'meter_alarm_core_stat_pkg.ComputeCoreDayUse',
					   pos = 100,
					   core_working_hours = 1
				 WHERE app_sid = a.app_sid
				   AND comp_proc IN (
				   	'meter_alarm_stat_pkg.ComputeWkgDayCore', 
				   	'meter_alarm_core_stat_pkg.ComputeCoreDayUse');
				IF SQL%NOTFOUND THEN
					INSERT INTO csr.meter_alarm_statistic (app_sid, statistic_id, meter_bucket_id, name, is_average, is_sum, comp_proc, meter_input_id, aggregator, pos, core_working_hours)
					VALUES (a.app_sid, csr.meter_statistic_id_seq.NEXTVAL, v_hourly_bucket_id, 'Core working hours - daily usage',  0/*<--IS AVG*/, 0, 
						'meter_alarm_core_stat_pkg.ComputeCoreDayUse', v_meter_input_id, 'SUM', 100, 1);
				END IF;
				UPDATE csr.meter_alarm_statistic
				   SET name = 'Core working hours - daily average',
					   comp_proc = 'meter_alarm_core_stat_pkg.ComputeCoreDayAvg',
					   pos = 101,
					   core_working_hours = 1
				 WHERE app_sid = a.app_sid
				   AND comp_proc IN (
				   	'meter_alarm_stat_pkg.ComputeWkgDayCoreAvg', 
				   	'meter_alarm_core_stat_pkg.ComputeCoreDayAvg');
				IF SQL%NOTFOUND THEN
					INSERT INTO csr.meter_alarm_statistic (app_sid, statistic_id, meter_bucket_id, name, is_average, is_sum, comp_proc, meter_input_id, aggregator, pos, core_working_hours)
					VALUES (a.app_sid, csr.meter_statistic_id_seq.NEXTVAL, v_hourly_bucket_id, 'Core working hours - daily average',  1/*<--IS AVG*/, 0, 
						'meter_alarm_core_stat_pkg.ComputeCoreDayAvg', v_meter_input_id, 'SUM', 101, 1);
				END IF;
				UPDATE csr.meter_alarm_statistic
				   SET name = 'Non-core working hours - daily usage',
					   comp_proc = 'meter_alarm_core_stat_pkg.ComputeNonCoreDayUse',
					   pos = 103,
					   core_working_hours = 1
				 WHERE app_sid = a.app_sid
				   AND comp_proc IN (
				   	'meter_alarm_stat_pkg.ComputeWkgDayNonCore', 
				   	'meter_alarm_core_stat_pkg.ComputeNonCoreDayUse');
				IF SQL%NOTFOUND THEN
					INSERT INTO csr.meter_alarm_statistic (app_sid, statistic_id, meter_bucket_id, name, is_average, is_sum, comp_proc, meter_input_id, aggregator, pos, core_working_hours)
					VALUES (a.app_sid, csr.meter_statistic_id_seq.NEXTVAL, v_hourly_bucket_id, 'Non-core working hours - daily usage',  0/*<--IS AVG*/, 0, 
						'meter_alarm_core_stat_pkg.ComputeNonCoreDayUse', v_meter_input_id, 'SUM', 103, 1);
				END IF;
				UPDATE csr.meter_alarm_statistic
				   SET name = 'Non-core working hours - daily average',
					   comp_proc = 'meter_alarm_core_stat_pkg.ComputeNonCoreDayAvg',
					   pos = 104,
					   core_working_hours = 1
				 WHERE app_sid = a.app_sid
				   AND comp_proc IN (
				   	'meter_alarm_stat_pkg.ComputeWkgDayNonCoreAvg', 
				   	'meter_alarm_core_stat_pkg.ComputeNonCoreDayAvg');
				IF SQL%NOTFOUND THEN
					INSERT INTO csr.meter_alarm_statistic (app_sid, statistic_id, meter_bucket_id, name, is_average, is_sum, comp_proc, meter_input_id, aggregator, pos, core_working_hours)
					VALUES (a.app_sid, csr.meter_statistic_id_seq.NEXTVAL, v_hourly_bucket_id, 'Non-core working hours - daily average',  1/*<--IS AVG*/, 0, 
						'meter_alarm_core_stat_pkg.ComputeNonCoreDayAvg', v_meter_input_id, 'SUM', 104, 1);
				END IF;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					NULL; -- Ignore missing hourly bucket
			END;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL; -- Ignore clients with no consumption input
		END;
		-- Use the hourly bucket for core working hours by default
		UPDATE csr.meter_bucket
		   SET core_working_hours = CASE WHEN is_hours = 1 AND duration = 1 THEN 1 ELSE 0 END
		 WHERE app_sid = a.app_sid;
	END LOOP; -- For each app
END;
/
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (45, 'Metering stats - same day average', 'Enable/disable the same day average meter alarm statistic feature.', 'EnableMeteringSameDayAvg', NULL);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (45, 'Enable/disable', 'Enable = 1, Disable = 0', 1, NULL);
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (46, 'Metering core working hours - same day average', 'Enable/disable the same day average meter alarm statistic feature for core working hours.', 'EnableMeteringCoreSameDayAvg', NULL);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (46, 'Enable/disable', 'Enable = 1, Disable = 0', 1, NULL);
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (47, 'Metering core working hours - day normalised values', 'Enable/disable the day normalised meter alarm statistics for core working hours.', 'EnableMeteringCoreDayNorm', NULL);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (47, 'Enable/disable', 'Enable = 1, Disable = 0', 1, NULL);
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (48, 'Metering core working hours - extended values', 'Enable/disable the extended alarm statistics set for core working hours.', 'EnableMeteringCoreExtended', NULL);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (48, 'Enable/disable', 'Enable = 1, Disable = 0', 1, NULL);
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (49, 'Metering core working hours - single day statistics', 'Enable/disable the single day alarm statistics set.', 'EnableMeteringDayStats', NULL);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (49, 'Enable/disable', 'Enable = 1, Disable = 0', 1, NULL);
END;
/
BEGIN
	UPDATE csr.meter_alarm_comparison
	   SET op_code = 'GT_PCT'
	 WHERE op_code = 'GT';
	UPDATE csr.meter_alarm_comparison
	   SET op_code = 'LT_PCT'
	 WHERE op_code = 'LT';
	FOR a IN (
		SELECT DISTINCT app_sid
		  FROM csr.meter_alarm_comparison
	) LOOP
		INSERT INTO csr.meter_alarm_comparison (app_sid, comparison_id, name, op_code)
		VALUES (a.app_sid, csr.meter_comparison_id_seq.NEXTVAL, 'Usage is more than', 'GT_ABS');
		INSERT INTO csr.meter_alarm_comparison (app_sid, comparison_id, name, op_code)
		VALUES (a.app_sid, csr.meter_comparison_id_seq.NEXTVAL, 'Usage is more than', 'GT_ADD');
		INSERT INTO csr.meter_alarm_comparison (app_sid, comparison_id, name, op_code)
		VALUES (a.app_sid, csr.meter_comparison_id_seq.NEXTVAL, 'Usage is more than', 'GT_SUB');
		INSERT INTO csr.meter_alarm_comparison (app_sid, comparison_id, name, op_code)
		VALUES (a.app_sid, csr.meter_comparison_id_seq.NEXTVAL, 'Usage is less than', 'LT_ABS');
		INSERT INTO csr.meter_alarm_comparison (app_sid, comparison_id, name, op_code)
		VALUES (a.app_sid, csr.meter_comparison_id_seq.NEXTVAL, 'Usage is less than', 'LT_ADD');
		INSERT INTO csr.meter_alarm_comparison (app_sid, comparison_id, name, op_code)
		VALUES (a.app_sid, csr.meter_comparison_id_seq.NEXTVAL, 'Usage is less than', 'LT_SUB');
	END LOOP;
END;
/
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP, WIKI_ARTICLE) VALUES (50, 'Set duplicated Enhesa items to out of scope.', 'Sets to out of scope all federal Enhesa requirements that have an unmerged duplicate in the local feed.', 'SetEnhesaDupesOutOfScope', NULL);




CREATE OR REPLACE PACKAGE csr.meter_alarm_core_stat_pkg
IS
END;
/
GRANT EXECUTE ON csr.meter_alarm_core_stat_pkg TO web_user;


@..\compliance_pkg
@..\auto_approve_pkg
@..\enable_pkg
@..\region_api_pkg
@..\issue_pkg
@..\scrag_pp_pkg
@..\meter_alarm_pkg
@..\meter_alarm_stat_pkg
@..\meter_alarm_core_stat_pkg
@..\util_script_pkg
@..\schema_pkg


@..\compliance_body
@..\enable_body
@..\csrimp\imp_body
@ ..\issue_body
@..\integration_api_body
@..\auto_approve_body
@..\quick_survey_body
@..\user_report_body
@..\region_api_body
@..\meter_monitor_body
@..\issue_body
@..\..\..\aspen2\cms\db\calc_xml_body
@..\integration_api_body.sql
@..\scrag_pp_body
@..\meter_alarm_body
@..\meter_alarm_core_stat_body
@..\meter_alarm_stat_body
@..\util_script_body
@..\schema_body
@..\meter_body



@update_tail
