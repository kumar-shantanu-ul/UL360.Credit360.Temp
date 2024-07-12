-- Please update version.sql too -- this keeps clean builds in sync
define version=2764
define minor_version=0
define is_combined=1
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.std_alert_type_group (
	std_alert_type_group_id						NUMBER(10)		NOT NULL,
	description									VARCHAR(255)	NOT NULL,
	CONSTRAINT pk_std_alert_type_group 			PRIMARY KEY (std_alert_type_group_id)
);

CREATE TABLE csr.user_inactive_sys_alert (
	app_sid										NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	user_inactive_sys_alert_id					NUMBER(10)		NOT NULL,
	notify_user_sid								NUMBER(10)		NOT NULL,
	sent_dtm									DATE,
	CONSTRAINT pk_user_inactive_sys_alert 		PRIMARY KEY (app_sid, user_inactive_sys_alert_id)
);

CREATE TABLE csr.user_inactive_man_alert (
	app_sid										NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	user_inactive_man_alert_id					NUMBER(10)		NOT NULL,
	notify_user_sid								NUMBER(10)		NOT NULL,
	sent_dtm									DATE,
	CONSTRAINT pk_user_inactive_man_alert 		PRIMARY KEY (app_sid, user_inactive_man_alert_id)
);

CREATE TABLE csr.user_inactive_rem_alert (
	app_sid										NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	user_inactive_rem_alert_id					NUMBER(10)		NOT NULL,
	notify_user_sid								NUMBER(10)		NOT NULL,
	sent_dtm									DATE,
	CONSTRAINT pk_user_inactive_rem_alert 		PRIMARY KEY (app_sid, user_inactive_rem_alert_id)
);

CREATE TABLE CSRIMP.MAP_ASPEN2_TRANSLATED (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_TRANSLATED_ID				NUMBER(10) NOT NULL,
	NEW_TRANSLATED_ID				NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_ASPEN2_TRANSLATED PRIMARY KEY (CSRIMP_SESSION_ID, OLD_TRANSLATED_ID),
	CONSTRAINT UK_MAP_ASPEN2_TRANSLATED UNIQUE (CSRIMP_SESSION_ID, NEW_TRANSLATED_ID),
    CONSTRAINT FK_MAP_ASPEN2_TRANSLATED_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.ASPEN2_TRANSLATED
(
	CSRIMP_SESSION_ID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	LANG            				VARCHAR2(10) NOT NULL,
	ORIGINAL_HASH   				RAW(20) NOT NULL,
	TRANSLATED      				VARCHAR2(4000) NOT NULL,
	TRANSLATED_ID           		NUMBER(10) NOT NULL,
    CONSTRAINT PK_ASPEN2_TRANSLATED PRIMARY KEY (LANG, ORIGINAL_HASH),
    CONSTRAINT FK_ASPEN2_TRANSLATED_IS FOREIGN KEY (CSRIMP_SESSION_ID)
	REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.ASPEN2_TRANSLATION
(
	CSRIMP_SESSION_ID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ORIGINAL_HASH					RAW(20) NOT NULL,
	ORIGINAL						VARCHAR2(4000) NOT NULL,
    CONSTRAINT PK_ASPEN2_TRANSLATION PRIMARY KEY (ORIGINAL_HASH),
    CONSTRAINT FK_ASPEN2_TRANSLATION_IS FOREIGN KEY (CSRIMP_SESSION_ID)
	REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.ASPEN2_TRANSLATION_APP
(
	CSRIMP_SESSION_ID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	BASE_LANG               		VARCHAR2(10) NOT NULL,
	STATIC_TRANSLATION_PATH			VARCHAR2(1000),
    CONSTRAINT PK_ASPEN2_TRANSLATION_APP PRIMARY KEY (CSRIMP_SESSION_ID),
    CONSTRAINT FK_ASPEN2_TRANSLATION_APP_IS FOREIGN KEY (CSRIMP_SESSION_ID)
	REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.ASPEN2_TRANSLATION_SET
(
	CSRIMP_SESSION_ID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	LANG							VARCHAR2(10) NOT NULL,
	REVISION						NUMBER(10) NOT NULL,
	HIDDEN							NUMBER(1) NOT NULL,
    CONSTRAINT PK_ASPEN2_TRANSLATION_SET PRIMARY KEY (LANG),
    CONSTRAINT FK_ASPEN2_TRANSLATION_SET_IS FOREIGN KEY (CSRIMP_SESSION_ID)
	REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.ASPEN2_TRANSLATION_SET_INCL
(
	CSRIMP_SESSION_ID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	LANG							VARCHAR2(10) NOT NULL,
	POS								NUMBER(10) NOT NULL,
	TO_APPLICATION					VARCHAR2(4000),
	TO_LANG							VARCHAR2(10) NOT NULL,
    CONSTRAINT PK_ASPEN2_TRANS_SET_INCL PRIMARY KEY (LANG, POS),
    CONSTRAINT FK_ASPEN2_TRANS_SET_INCL_IS FOREIGN KEY (CSRIMP_SESSION_ID)
	REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables
alter table CSR.QS_ANSWER_LOG ADD (
	VERSION_STAMP NUMBER(10,0) DEFAULT(0) NOT NULL
);

alter table CSRIMP.QS_ANSWER_LOG ADD (
	VERSION_STAMP NUMBER(10,0) DEFAULT(0) NOT NULL
);

ALTER TABLE csr.issue_type DROP CONSTRAINT CHK_PUBLIC_BY_DEFAULT;
ALTER TABLE csr.issue_type DROP CONSTRAINT CHK_CAN_BE_PUBLIC;
ALTER TABLE csr.issue_type RENAME COLUMN can_be_public TO can_set_public;
ALTER TABLE csr.issue_type ADD CONSTRAINT CHK_PUBLIC_BY_DEFAULT CHECK (public_by_default IN (0,1));
ALTER TABLE csr.issue_type ADD CONSTRAINT CHK_CAN_SET_PUBLIC CHECK (can_set_public IN (0,1));

ALTER TABLE csrimp.issue_type RENAME COLUMN can_be_public TO can_set_public;

alter table aspen2.translation_application add static_translation_path varchar2(1000) default '/resource/tr.xml';
ALTER TABLE CSR.IMP_VAL DROP CONSTRAINT FK_REG_MET_VAL_IMP_VAL;

ALTER TABLE CSR.IMP_VAL ADD CONSTRAINT FK_REG_MET_VAL_IMP_VAL 
FOREIGN KEY (APP_SID, SET_REGION_METRIC_VAL_ID)
 REFERENCES CSR.REGION_METRIC_VAL(APP_SID, REGION_METRIC_VAL_ID);

ALTER TABLE csr.user_inactive_sys_alert
  ADD CONSTRAINT fk_inactive_sys_alert_csr_user FOREIGN KEY (app_sid, notify_user_sid)
	  REFERENCES csr.csr_user (app_sid, csr_user_sid);

ALTER TABLE csr.user_inactive_man_alert
  ADD CONSTRAINT fk_inactive_man_alert_csr_user FOREIGN KEY (app_sid, notify_user_sid)
	  REFERENCES csr.csr_user (app_sid, csr_user_sid);

ALTER TABLE csr.user_inactive_rem_alert
  ADD CONSTRAINT fk_inactive_rem_alert_csr_user FOREIGN KEY (app_sid, notify_user_sid)
	  REFERENCES csr.csr_user (app_sid, csr_user_sid);

ALTER TABLE csr.alert_template
 DROP CONSTRAINT CK_ALERT_TEMPLATE_SEND_TYPE;

ALTER TABLE csr.alert_template
  ADD CONSTRAINT CK_ALERT_TEMPLATE_SEND_TYPE
	  CHECK (SEND_TYPE IN ('manual', 'automatic', 'inactive'));

ALTER TABLE csr.customer
  ADD ntfy_days_before_user_inactive NUMBER(10) DEFAULT 15 NOT NULL;

ALTER TABLE csrimp.customer
  ADD ntfy_days_before_user_inactive NUMBER(10) NULL;

ALTER TABLE csr.std_alert_type
  ADD std_alert_type_group_id NUMBER(10) NULL;

ALTER TABLE csr.std_alert_type
  ADD override_template_send_type NUMBER(1) DEFAULT 0 NOT NULL;
  
ALTER TABLE csr.std_alert_type
  ADD CONSTRAINT fk_std_alert_type_alert_group FOREIGN KEY (std_alert_type_group_id)
	  REFERENCES csr.std_alert_type_group (std_alert_type_group_id);

ALTER TABLE csr.default_alert_template
  DROP CONSTRAINT CK_DEF_ALRT_TEMPLATE_SEND_TYPE;

ALTER TABLE csr.default_alert_template
  ADD CONSTRAINT CK_DEF_ALRT_TEMPLATE_SEND_TYPE
	  CHECK (SEND_TYPE IN ('manual', 'automatic', 'inactive'));

drop table csrimp.translation_application;
drop table csrimp.translation_set;

alter table aspen2.translated modify translated_id not null;

ALTER TABLE csr.quick_survey_type ADD (
	show_answer_set_dtm		NUMBER(1,0)
);
UPDATE csr.quick_survey_type SET show_answer_set_dtm = 0;
ALTER TABLE csr.quick_survey_type MODIFY (
	show_answer_set_dtm		DEFAULT 0 NOT NULL
);

ALTER TABLE csrimp.quick_survey_type ADD (
	show_answer_set_dtm		NUMBER(1,0)
);
UPDATE csrimp.quick_survey_type SET show_answer_set_dtm = 0;
ALTER TABLE csrimp.quick_survey_type MODIFY (
	show_answer_set_dtm		DEFAULT 0 NOT NULL
);

CREATE SEQUENCE csr.user_inactive_sys_alert_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    NOCACHE
    NOORDER
;

CREATE SEQUENCE csr.user_inactive_man_alert_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    NOCACHE
    NOORDER
;

CREATE SEQUENCE csr.user_inactive_rem_alert_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    NOCACHE
    NOORDER
;

ALTER TABLE CHAIN.QUESTIONNAIRE_TYPE ADD ENABLE_STATUS_LOG NUMBER(1);
UPDATE CHAIN.QUESTIONNAIRE_TYPE SET ENABLE_STATUS_LOG = 0;
ALTER TABLE CHAIN.QUESTIONNAIRE_TYPE MODIFY ENABLE_STATUS_LOG DEFAULT 0 NOT NULL;
ALTER TABLE CHAIN.QUESTIONNAIRE_TYPE ADD CONSTRAINT CHK_ENABLE_STATUS_LOG_0_1 CHECK (ENABLE_STATUS_LOG IN (0, 1));

ALTER TABLE CHAIN.QUESTIONNAIRE_TYPE ADD ENABLE_TRANSITION_ALERT NUMBER(1);
UPDATE CHAIN.QUESTIONNAIRE_TYPE SET ENABLE_TRANSITION_ALERT = 0;
ALTER TABLE CHAIN.QUESTIONNAIRE_TYPE MODIFY ENABLE_TRANSITION_ALERT DEFAULT 0 NOT NULL;
ALTER TABLE CHAIN.QUESTIONNAIRE_TYPE ADD CONSTRAINT CHK_ENABLE_TRANSITION_ALRT_0_1 CHECK (ENABLE_TRANSITION_ALERT IN (0, 1));

ALTER TABLE CHAIN.QUESTIONNAIRE ADD REJECTED NUMBER(1);
UPDATE CHAIN.QUESTIONNAIRE SET REJECTED = 0;
ALTER TABLE CHAIN.QUESTIONNAIRE MODIFY REJECTED DEFAULT 0 NOT NULL;
ALTER TABLE CHAIN.QUESTIONNAIRE ADD CONSTRAINT CHK_REJECTED_0_1 CHECK (REJECTED IN (0, 1));

ALTER TABLE CSRIMP.CHAIN_QUESTIONNAIRE_TYPE ADD ENABLE_STATUS_LOG NUMBER(1);
ALTER TABLE CSRIMP.CHAIN_QUESTIONNAIRE_TYPE ADD ENABLE_TRANSITION_ALERT NUMBER(1);
ALTER TABLE CSRIMP.CHAIN_QUESTIONNAIRE ADD REJECTED NUMBER(1);

DECLARE
  v_exists NUMBER;
  v_sql VARCHAR2(1024);
BEGIN
    SELECT COUNT(*) 
      INTO v_exists 
      FROM all_tab_cols 
     WHERE column_name = 'NAME' 
       AND table_name = 'DELEGATION_LAYOUT'
       AND owner = 'CSR';
     
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE q'{
            ALTER TABLE CSR.DELEGATION_LAYOUT ADD (
                NAME VARCHAR2(255) DEFAULT 'New Layout' NOT NULL)}';
    END IF;
END;
/

create unique index csr.ux_supplier_cmp_surv_response on csr.supplier_survey_response (app_sid, supplier_sid, component_id, survey_response_id);
create index csr.ix_qs_answer_log_date on csr.qs_answer_log (app_sid, survey_response_id, set_dtm desc, set_by_user_sid);

-- *** Grants ***
GRANT SELECT ON aspen2.translation_set_include TO csr;
grant insert on aspen2.translated to csrimp;
grant insert on aspen2.translation to csrimp;
grant insert on aspen2.translation_application to csrimp;
grant insert on aspen2.translation_set to csrimp;
grant insert on aspen2.translation_set_include to csrimp;
grant select on aspen2.translated_id_seq to csrimp;
grant insert,select,update,delete on csrimp.aspen2_translated to web_user;
grant insert,select,update,delete on csrimp.aspen2_translation to web_user;
grant insert,select,update,delete on csrimp.aspen2_translation_app to web_user;
grant insert,select,update,delete on csrimp.aspen2_translation_set to web_user;
grant insert,select,update,delete on csrimp.aspen2_translation_set_incl to web_user;
GRANT SELECT ON csr.qs_answer_log TO CHAIN;

-- ** Cross schema constraints ***

-- *** Views ***
CREATE OR REPLACE VIEW csr.v$issue AS
SELECT i.app_sid, NVL2(i.issue_ref, ist.internal_issue_ref_prefix || i.issue_ref, null) custom_issue_id, i.issue_id, i.label, i.description, i.source_label, i.is_visible, i.source_url, i.region_sid, re.description region_name, i.parent_id,
	   i.issue_escalated, i.owner_role_sid, i.owner_user_sid, cuown.user_name owner_user_name, cuown.full_name owner_full_name, cuown.email owner_email, i.first_issue_log_id, i.last_issue_log_id, NVL(lil.logged_dtm, i.raised_dtm) last_modified_dtm,
	   i.is_public, i.is_pending_assignment, i.rag_status_id, itrs.label rag_status_label, itrs.colour rag_status_colour, raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
	   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
	   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
	   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
	   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
	   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, c.more_info_1 correspondent_more_info_1,
	   sysdate now_dtm, due_dtm, forecast_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, ist.allow_children, ist.can_set_public, ist.show_forecast_dtm, ist.require_var_expl, ist.enable_reject_action,
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
	   ist.restrict_users_to_region, ist.deletable_by_administrator, ist.deletable_by_owner, ist.deletable_by_raiser, ist.send_alert_on_issue_raised,
	   ind.ind_sid, ind.description ind_name, isv.start_dtm, isv.end_dtm, ist.owner_can_be_changed, ist.show_one_issue_popup, ist.lookup_key, ist.allow_owner_resolve_and_close
  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user curej, csr_user cuass, csr_user cuown,  role r, correspondent c, issue_priority ip,
	   (SELECT * FROM region_role_member WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')) rrm, v$region re, issue_log lil, v$issue_type_rag_status itrs,
	   v$ind ind, issue_sheet_value isv
 WHERE i.app_sid = curai.app_sid AND i.raised_by_user_sid = curai.csr_user_sid
   AND i.app_sid = ist.app_sid AND i.issue_type_Id = ist.issue_type_id
   AND i.app_sid = cures.app_sid(+) AND i.resolved_by_user_sid = cures.csr_user_sid(+)
   AND i.app_sid = cuclo.app_sid(+) AND i.closed_by_user_sid = cuclo.csr_user_sid(+)
   AND i.app_sid = curej.app_sid(+) AND i.rejected_by_user_sid = curej.csr_user_sid(+)
   AND i.app_sid = cuass.app_sid(+) AND i.assigned_to_user_sid = cuass.csr_user_sid(+)
   AND i.app_sid = cuown.app_sid(+) AND i.owner_user_sid = cuown.csr_user_sid(+)
   AND i.app_sid = r.app_sid(+) AND i.assigned_to_role_sid = r.role_sid(+)
   AND i.app_sid = re.app_sid(+) AND i.region_sid = re.region_sid(+)
   AND i.app_sid = c.app_sid(+) AND i.correspondent_id = c.correspondent_id(+)
   AND i.app_sid = ip.app_sid(+) AND i.issue_priority_id = ip.issue_priority_id(+)
   AND i.app_sid = rrm.app_sid(+) AND i.region_sid = rrm.region_sid(+) AND i.owner_role_sid = rrm.role_sid(+)
   AND i.app_sid = lil.app_sid(+) AND i.last_issue_log_id = lil.issue_log_id(+)
   AND i.app_sid = itrs.app_sid(+) AND i.rag_status_id = itrs.rag_status_id(+) AND i.issue_type_id = itrs.issue_type_id(+)
   AND i.app_sid = isv.app_sid(+) AND i.issue_sheet_value_id = isv.issue_sheet_value_id(+)
   AND isv.app_sid = ind.app_sid(+) AND isv.ind_sid = ind.ind_sid(+)
   AND i.deleted = 0;

CREATE OR REPLACE VIEW CSR.V$AUDIT_CAPABILITY AS
	SELECT ia.app_sid, ia.internal_audit_sid, fsrc.flow_capability_id,
		   MAX(BITAND(fsrc.permission_set, 1)) + -- security_pkg.PERMISSION_READ
		   MAX(BITAND(fsrc.permission_set, 2)) permission_set -- security_pkg.PERMISSION_WRITE
	  FROM internal_audit ia
	  JOIN flow_item fi ON ia.app_sid = fi.app_sid AND ia.flow_item_id = fi.flow_item_id
	  JOIN flow_state_role_capability fsrc ON fi.app_sid = fsrc.app_sid AND fi.current_state_id = fsrc.flow_state_id
	  LEFT JOIN region_role_member rrm ON ia.app_sid = rrm.app_sid AND ia.region_sid = rrm.region_sid
	   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND rrm.role_sid = fsrc.role_sid
	 WHERE ((fsrc.flow_involvement_type_id = 1 -- csr_data_pkg.FLOW_INV_TYPE_AUDITOR
	   AND (ia.auditor_user_sid = SYS_CONTEXT('SECURITY', 'SID')
		OR ia.auditor_user_sid IN (SELECT user_being_covered_sid FROM v$current_user_cover)))
		OR (ia.auditor_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND fsrc.flow_involvement_type_id = 2) -- csr_data_pkg.FLOW_INV_TYPE_AUDIT_COMPANY
		OR rrm.role_sid IS NOT NULL
		OR security.security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits'), 16) = 1) -- security.security_pkg.PERMISSION_TAKE_OWNERSHIP
	 GROUP BY ia.app_sid, ia.internal_audit_sid, fsrc.flow_capability_id;

CREATE OR REPLACE VIEW CHAIN.v$questionnaire AS
	SELECT q.app_sid, q.questionnaire_id, q.company_sid, q.component_id, c.description component_description, q.questionnaire_type_id, q.created_dtm,
		   qt.view_url, qt.edit_url, qt.owner_can_review, qt.class, qt.name, NVL(q.description, qt.name) description, qt.db_class, qt.group_name, qt.position, qt.security_scheme_id, 
		   qsle.status_log_entry_index, qsle.questionnaire_status_id, qs.description questionnaire_status_name, qsle.entry_dtm status_update_dtm,
		   qt.enable_status_log, qt.enable_transition_alert, q.rejected
	  FROM questionnaire q, questionnaire_type qt, qnr_status_log_entry qsle, questionnaire_status qs, component c
	 WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND q.app_sid = qt.app_sid
	   AND q.app_sid = qsle.app_sid
       AND q.questionnaire_type_id = qt.questionnaire_type_id
       AND qsle.questionnaire_status_id = qs.questionnaire_status_id
       AND q.questionnaire_id = qsle.questionnaire_id
       AND q.component_id = c.component_id(+)
       AND (qsle.questionnaire_id, qsle.status_log_entry_index) IN (   
			SELECT questionnaire_id, MAX(status_log_entry_index)
			  FROM qnr_status_log_entry
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 GROUP BY questionnaire_id
			)
;

CREATE OR REPLACE VIEW chain.v$qnr_action_capability
AS
	SELECT questionnaire_action_id, description,
		CASE WHEN questionnaire_action_id = 1 THEN 'Questionnaire'
			 WHEN questionnaire_action_id = 2 THEN 'Questionnaire'
			 WHEN questionnaire_action_id = 3 THEN 'Submit questionnaire'
			 WHEN questionnaire_action_id = 4 THEN 'Approve questionnaire' 
			 WHEN questionnaire_action_id = 5 THEN 'Manage questionnaire security' 
			 WHEN questionnaire_action_id = 6 THEN 'Reject questionnaire' 
		END capability_name,
		CASE WHEN questionnaire_action_id = 1 THEN 1 --security_pkg.PERMISSION_READ -- SPECIFIC
			 WHEN questionnaire_action_id = 2 THEN 2 --security_pkg.PERMISSION_WRITE -- SPECIFIC
			 WHEN questionnaire_action_id = 3 THEN 2 --security_pkg.PERMISSION_WRITE -- BOOLEAN
			 WHEN questionnaire_action_id = 4 THEN 2 --security_pkg.PERMISSION_WRITE -- BOOLEAN
			 WHEN questionnaire_action_id = 5 THEN 2 --security_pkg.PERMISSION_WRITE -- BOOLEAN
			 WHEN questionnaire_action_id = 6 THEN 2 --security_pkg.PERMISSION_WRITE -- BOOLEAN
		END permission_set,
		CASE WHEN questionnaire_action_id = 1 THEN 0 -- SPECIFIC
			 WHEN questionnaire_action_id = 2 THEN 0 -- SPECIFIC
			 WHEN questionnaire_action_id = 3 THEN 1 -- BOOLEAN
			 WHEN questionnaire_action_id = 4 THEN 1 -- BOOLEAN
			 WHEN questionnaire_action_id = 5 THEN 1 -- BOOLEAN
			 WHEN questionnaire_action_id = 6 THEN 1 -- BOOLEAN
		END permission_type
		  FROM chain.questionnaire_action;

-- *** Data changes ***
-- RLS
DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
	POLICY_DOES_NOT_EXIST EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_DOES_NOT_EXIST, -28102);
BEGIN
	BEGIN
		dbms_rls.add_policy(
			object_schema   => 'CSR',
			object_name     => 'USER_INACTIVE_SYS_ALERT',
			policy_name     => 'USER_INACTIVE_SYS_ALERT_POLICY',
			function_schema => 'CSR',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.context_sensitive
		);
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists');
	END;

	BEGIN
		dbms_rls.add_policy(
			object_schema   => 'CSR',
			object_name     => 'USER_INACTIVE_MAN_ALERT',
			policy_name     => 'USER_INACTIVE_MAN_ALERT_POLICY',
			function_schema => 'CSR',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.context_sensitive
		);
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists');
	END;
	
	BEGIN
		dbms_rls.add_policy(
			object_schema   => 'CSR',
			object_name     => 'USER_INACTIVE_REM_ALERT',
			policy_name     => 'USER_INACTIVE_REM_ALERT_POLICY',
			function_schema => 'CSR',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.context_sensitive
		);
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists');
	END;
EXCEPTION
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');
END;
/

-- Data
UPDATE csr.plugin
   SET cs_class = 'Credit360.Plugins.InitiativesPlugin'
 WHERE js_include = '/csr/site/teamroom/controls/InitiativesPanel.js'
   AND js_class = 'Teamroom.InitiativesPanel'
   AND app_sid IS NULL;

BEGIN  
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (1, 'Users');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (2, 'Delegations');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (3, 'Actions');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (4, 'Templated reports');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (5, 'Document Library');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (6, 'Corporate Reporter');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (7, 'Audits');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (8, 'Supply Chain');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (9, 'SRM');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (10, 'Teamroom');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (11, 'Initiatives');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (12, 'Ethics');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (13, 'CMS');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (14, 'Other');
END;
/

DECLARE
	ALERT_GROUP_USERS			NUMBER(10) := 1;
	ALERT_GROUP_DELEGTIONS		NUMBER(10) := 2;
	ALERT_GROUP_ACTIONS			NUMBER(10) := 3;
	ALERT_GROUP_TPLREPORTS		NUMBER(10) := 4;
	ALERT_GROUP_DOCLIBRARY		NUMBER(10) := 5;
	ALERT_GROUP_CORPREPORTER	NUMBER(10) := 6;
	ALERT_GROUP_AUDITS			NUMBER(10) := 7;
	ALERT_GROUP_SUPPLYCHAIN		NUMBER(10) := 8;
	ALERT_GROUP_SRM				NUMBER(10) := 9;
	ALERT_GROUP_TEAMROOM		NUMBER(10) := 10;
	ALERT_GROUP_INITIATIVES		NUMBER(10) := 11;
	ALERT_GROUP_ETHICS			NUMBER(10) := 12;
	ALERT_GROUP_CMS				NUMBER(10) := 13;
	ALERT_GROUP_OTHER			NUMBER(10) := 14;
BEGIN  
	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_USERS
	 WHERE std_alert_type_id IN (1, 20, 25, 26, 38, 72, 73, 74);

	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_DELEGTIONS
	 WHERE std_alert_type_id IN (2, 3, 4, 5, 7, 8, 9, 10, 11, 12,
		13, 14, 15, 16, 27, 28, 29, 30, 39, 57, 58, 59, 62, 68
	);

	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_ACTIONS
	WHERE std_alert_type_id IN (17, 18, 32, 33, 34, 35, 36, 47, 60, 61);

	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_TPLREPORTS
	 WHERE std_alert_type_id IN (64, 65);

	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_DOCLIBRARY
	 WHERE std_alert_type_id IN (19);

	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_CORPREPORTER
	 WHERE std_alert_type_id IN (44, 48, 49, 52, 53, 56, 63);

	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_AUDITS
	 WHERE std_alert_type_id IN (45, 46, 67);

	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_SUPPLYCHAIN
	 WHERE std_alert_type_id IN (21, 22, 23, 24, 1000, 1001, 1002, 1003, 5000,
		5002, 5003, 5004, 5005, 5006, 5007, 5008, 5010, 5011, 5012, 5013, 5014,
		5015, 5016, 5017, 5018, 5019, 5020, 5021, 5022, 5025, 5026 
	);

	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_SRM
	 WHERE std_alert_type_id IN (5023, 5024);

	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_TEAMROOM
	 WHERE std_alert_type_id IN (54, 55);

	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_INITIATIVES
	 WHERE std_alert_type_id IN (2000, 2001, 2002, 2003, 2005, 2006, 2007, 2008, 2009,
		2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2050, 2051, 2052 
	);

	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_ETHICS
	 WHERE std_alert_type_id IN (3000, 3001);

	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_OTHER
	 WHERE std_alert_type_id IN (31, 37, 40, 41, 42, 43, 50, 51, 66, 69, 70, 71, 72, 2004);
END;
/

BEGIN
	UPDATE csr.std_alert_type
	   SET override_template_send_type = 1
	 WHERE std_alert_type_id = 25;
END;
/

BEGIN
	INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, override_user_send_setting, std_alert_type_group_id) VALUES (73, 'User account – pending deactivation', 
		 'A user account will soon be deactivated automatically because the user has not logged in for a specified number of days.  The alert is sent each of the 15 last days before the account is due to be deactivated.',
		 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).',
		 1, 1
	); 

	INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, override_user_send_setting, std_alert_type_group_id) VALUES (74, 'User account deactivated (system)', 
		 'A user account is deactivated automatically because the user has not logged in for a specified number of days.',
		 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).',
		 1, 1
	); 

	INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, override_user_send_setting, std_alert_type_group_id) VALUES (75, 'User account deactivated (manually)', 
		 'A user account is deactivated manually by another user.',
		 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).',
		 1, 1
	); 
END;
/

DECLARE
	v_alert_id NUMBER(10);
BEGIN
	-- User account - pending deactivation
	v_alert_id := 73;
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
  
	-- User account disabled (system)
	v_alert_id := 74;
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
  
	-- User account disabled (manually)
	v_alert_id := 75;
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5); 
END;
/

DECLARE
   v_daf_id NUMBER(2);
BEGIN
	SELECT MAX(default_alert_frame_id) INTO v_daf_id FROM csr.default_alert_frame;

	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type)
	VALUES (73, v_daf_id, 'inactive');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type)
	VALUES (74, v_daf_id, 'inactive');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type)
	VALUES (75, v_daf_id, 'inactive');
END;
/

declare
	v_new_www_sid           security.security_pkg.T_SID_ID;
    v_old_www_sid 		    security.security_pkg.T_SID_ID;
    v_www_csr_site			security.security_pkg.T_SID_ID;
    v_wwwroot_sid			security.security_pkg.T_SID_ID;
    v_act                   security.security_pkg.T_ACT_ID;
begin
	for r in (select c.host
				from csr.customer c, security.website w
			   where lower(c.host) = lower(w.website_name)) loop
			   	
		security.user_pkg.logonadmin(r.host);
		v_act := sys_context('security','act');

		begin
			v_old_www_sid := security.securableobject_pkg.getsidfrompath(v_act, security.security_pkg.getapp,'wwwroot/csr/site/dataExplorer4');
		exception
			when security.security_pkg.object_not_found then		
				v_old_www_sid := null;
		end;
		
		if v_old_www_sid is not null then
			v_wwwroot_sid := security.securableobject_pkg.GetSidFromPath(v_act, sys_context('security','app'), 'wwwroot');
			v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act, v_wwwroot_sid, 'csr/site');
			BEGIN
				security.web_pkg.CreateResource(v_act, v_wwwroot_sid, v_www_csr_site, 'dataExplorer5', v_new_www_sid);
				
				security.acl_pkg.DeleteAllACEs(v_act, security.acl_pkg.GetDACLIDForSID(v_new_www_sid));
				FOR r IN (
					SELECT a.acl_id, a.acl_index, a.ace_type, a.ace_flags, a.permission_set, a.sid_id
					  FROM security.securable_object so
					  JOIN security.acl a ON so.dacl_id = a.acl_id
					 WHERE so.sid_id = v_old_www_sid
					 ORDER BY acl_index      
				)
				LOOP
					security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_new_www_sid), r.acl_index, 
						r.ace_type, r.ace_flags, r.sid_id, r.permission_Set);
				END LOOP;
			EXCEPTION
				WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
					NULL;
			END;
		end if;
	end loop;
	security.security_pkg.setapp(null);
	update security.menu set action='/csr/site/dataExplorer5/dataNavigator/rawExplorer.acds'
	where lower(action)=lower('/csr/site/dataExplorer4/dataNavigator/rawexplorer.acds');
	update security.menu set action='/csr/site/dataExplorer5/dataNavigator/dataBrowser.acds'
	where lower(action)=lower('/csr/site/dataExplorer4/dataNavigator/dataBrowser.acds');
	update security.menu set action='/csr/site/dataExplorer5/dataNavigator/rawExplorer.acds'
	where lower(action)=lower('/csr/site/dataExplorer4/dataNavigator/rawExplorer.acds');
end;
/

CREATE OR REPLACE PROCEDURE chain.Temp_RegisterCapability (
	in_capability_type			IN  NUMBER,
	in_capability				IN  VARCHAR2, 
	in_perm_type				IN  NUMBER,
	in_is_supplier				IN  NUMBER DEFAULT 0
)
AS
	v_count						NUMBER(10);
	v_ct						NUMBER(10);
BEGIN
	IF in_capability_type = 3 /*chain_pkg.CT_COMPANIES*/ THEN
		Temp_RegisterCapability(1 /*chain_pkg.CT_COMPANY*/, in_capability, in_perm_type);
		Temp_RegisterCapability(2 /*chain_pkg.CT_SUPPLIERS*/, in_capability, in_perm_type, 1);
		RETURN;	
	END IF;
	
	IF in_capability_type = 1 AND in_is_supplier <> 0 /* chain_pkg.IS_NOT_SUPPLIER_CAPABILITY */ THEN
		RAISE_APPLICATION_ERROR(-20001, 'Company capabilities cannot be supplier centric');
	ELSIF in_capability_type = 2 /* chain_pkg.CT_SUPPLIERS */ AND in_is_supplier <> 1 /* chain_pkg.IS_SUPPLIER_CAPABILITY */ THEN
		RAISE_APPLICATION_ERROR(-20001, 'Supplier capabilities must be supplier centric');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;
	
	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND (
			(capability_type_id = 0 /*chain_pkg.CT_COMMON*/ AND (in_capability_type = 0 /*chain_pkg.CT_COMPANY*/ OR in_capability_type = 2 /*chain_pkg.CT_SUPPLIERS*/))
	   		 OR (in_capability_type = 0 /*chain_pkg.CT_COMMON*/ AND (capability_type_id = 1 /*chain_pkg.CT_COMPANY*/ OR capability_type_id = 2 /*chain_pkg.CT_SUPPLIERS*/))
	   	   );
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;
	
	INSERT INTO chain.capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(chain.capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type, in_is_supplier);
END;
/

BEGIN
	chain.Temp_RegisterCapability(
		in_capability_type	=> 0,  		/* CT_COMMON*/
		in_capability	=> 'Reject questionnaire' /* chain.chain_pkg.REJECT_QUESTIONNAIRE */, 
		in_perm_type	=> 1, 			/* BOOLEAN_PERMISSION */
		in_is_supplier 	=> 1
	);
	
END;
/

--TODO: using create actions

DROP PROCEDURE chain.Temp_RegisterCapability;

BEGIN
	UPDATE chain.questionnaire
	   SET rejected = 1
	 WHERE questionnaire_id IN (
		SELECT DISTINCT questionnaire_id
		  FROM chain.questionnaire_share qs
		  JOIN chain.qnr_share_log_entry qsle ON qs.questionnaire_share_id = qsle.questionnaire_share_id
		 WHERE qsle.share_status_id = 15 --rejected	 
	 );
END;
/

-- returned questionnaire notification
BEGIN
	INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from) VALUES (5027,
	'Returned questionnaire notification',
	'A questionnaire is returned.',
	'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).');
EXCEPTION
	WHEN dup_val_on_index THEN
		UPDATE csr.std_alert_type SET
			description = 'Returned questionnaire notification',
			send_trigger = 'A questionnaire is returned.',
			sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
		WHERE std_alert_type_id = 5027;
END;
/

--add reject questionnaire as action

BEGIN
	INSERT INTO CHAIN.QUESTIONNAIRE_ACTION (QUESTIONNAIRE_ACTION_ID, DESCRIPTION) VALUES (6, 'Cancel questionnaire');
	
	/* only procurer can reject/cancel questionnaire */
	INSERT INTO CHAIN.COMPANY_FUNC_QNR_ACTION (COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (1, 6); -- PROCURER, CANCEL
	
	--add a new scheme
	INSERT INTO CHAIN.QUESTIONNAIRE_SECURITY_SCHEME (SECURITY_SCHEME_ID, DESCRIPTION) VALUES (4, 'PROCURER: USER VIEW, USER EDIT, USER SUBMIT, USER APPROVE, USER GRANT, USER REJECT; SUPPLIER: USER VIEW, USER EDIT, USER SUBMIT');
	
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (4, 2, 1, 1); /* PROCURER: USER VIEW   */
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (4, 2, 1, 2); /* PROCURER: USER EDIT   */
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (4, 2, 1, 3); /* PROCURER: USER SUBMIT */
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (4, 2, 1, 4); /* PROCURER: USER APPROVE*/
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (4, 2, 1, 5); /* PROCURER: USER GRANT*/
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (4, 2, 1, 6); /* PROCURER: USER REJECT*/

	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (4, 2, 2, 1); /* SUPPLIER: USER VIEW   */
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (4, 2, 2, 2); /* SUPPLIER: USER EDIT   */
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (4, 2, 2, 3); /* SUPPLIER: USER SUBMIT */
END;
/


INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'FROM_JOBTITLE', 'From jobtitle', 'The job title of the user the alert is being sent from', 8);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'FROM_COMPANY', 'From company', 'The company of the user the alert is being sent from', 9);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'SUBJECT', 'Subject', 'The subject', 10);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'QUESTIONNAIRE_NAME', 'Questionnaire name', 'The questionnaire name', 11);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'QUESTIONNAIRE_LINK', 'Questionnaire link', 'A hyperlink to the questionnaire', 12);	
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'USER_NOTES', 'Transition comments', 'Notes added by the user that returned the questionnaire', 13);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 14);

BEGIN
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from) VALUES (5028,
		'Questionnaire user added',
		'A new user added to a questionnaire.',
		'The user who changed the permission.');
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Questionnaire user added',
				send_trigger = 'A new user added to a questionnaire.',
				sent_from = 'The user who changed the permission.'
			WHERE std_alert_type_id = 5028;
	END;
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5028, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5028, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5028, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5028, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5028, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5028, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5028, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5028, 0, 'FROM_USER_NAME', 'From user name', 'The user name of the user the alert is being sent from', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5028, 0, 'QUESTIONNAIRE_NAME', 'Questionnaire name', 'The questionnaire name', 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5028, 0, 'LINK', 'Link', 'A hyperlink to the questionnaire', 10);
END;
/

UPDATE csr.plugin SET cs_class='Credit360.Issues.IssueCalendarDto' WHERE js_class='Credit360.Calendars.Issues';
UPDATE csr.plugin SET cs_class='Credit360.Chain.Activities.ActivityCalendarDto' WHERE js_class='Credit360.Calendars.Activities';
UPDATE csr.plugin SET cs_class='Credit360.Audit.AuditCalendarDto' WHERE js_class='Credit360.Calendars.Audits';

-- Scheduled job
BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
	job_name        => 'csr.RaiseUserInactiveRemAlerts',
	job_type        => 'PLSQL_BLOCK',
	job_action      => 'csr.csr_user_pkg.RaiseUserInactiveRemAlerts();',
	job_class       => 'LOW_PRIORITY_JOB',
	start_date      => to_timestamp_tz('2015/07/01 03:15 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
	repeat_interval => 'FREQ=DAILY',
	enabled         => TRUE,
	auto_drop       => FALSE,
	comments        => 'Generates reminder alerts for inactive user account which are about to be disabled automatically becuase of account policy');
END;
/

-- Enable alerts for existing sites
BEGIN
	security.user_pkg.LogOnAdmin();
	FOR r IN (
		SELECT DISTINCT w.website_name host, c.app_sid 
		  FROM csr.customer c
		  JOIN security.website w
		    ON c.app_sid = w.application_sid_id
	)
	LOOP
		security.user_pkg.LogOnAdmin(r.host);
		-- Add new user alerts
		BEGIN
		  INSERT INTO csr.customer_alert_type (customer_alert_type_id, std_alert_type_id)
			SELECT csr.customer_alert_type_id_seq.NEXTVAL, std_alert_type_id
			  FROM csr.std_alert_type
			 WHERE std_alert_type_id IN (
				73,
				74,
				75
			);
		EXCEPTION
		  WHEN DUP_VAL_ON_INDEX THEN
			NULL;
		END;
	END LOOP;
END;
/

-- ** New package grants **
create or replace package csr.initiative_export_pkg as end;
/
grant execute on csr.initiative_export_pkg to web_user;

-- *** Packages ***
@../issue_pkg
@../issue_report_pkg
@..\initiative_import_pkg
@..\initiative_export_pkg
@../csr_data_pkg
@../alert_pkg
@../csr_user_pkg
@../scenario_run_pkg
@..\val_pkg
@../chain/questionnaire_pkg
@..\quick_survey_pkg
@../chain/chain_pkg
@../chain/questionnaire_security_pkg
@..\delegation_pkg
@../schema_pkg
@../section_pkg

@..\delegation_body
@../schema_body
@../csrimp/imp_body
@../chain/questionnaire_body
@../chain/invitation_body
@../quick_survey_body
@../chain/questionnaire_security_body
@..\audit_body
@..\calendar_body
@..\issue_body
@..\val_body
@../indicator_body
@../csr_user_body
@../scenario_run_body
@../csr_app_body
@../sheet_body
@../section_body
@../alert_body
@../csr_data_body
@..\chain\report_body
@..\initiative_import_body
@..\initiative_export_body
@../region_body
@../region_metric_body
@../enable_body
@../issue_report_body
@..\batch_job_body
@..\division_body
@../../../aspen2/NPSL.Translation/db/tr_pkg
@../../../aspen2/NPSL.Translation/db/tr_body

@update_tail
