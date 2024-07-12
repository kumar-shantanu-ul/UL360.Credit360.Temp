-- Please update version.sql too -- this keeps clean builds in sync
define version=2754
define minor_version=0
define is_combined=1
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE ASPEN2.PAGE_ERROR_LOG (
	URL					VARCHAR(1024),
	LAST_ERROR_DTM		DATE,
	CONSTRAINT PK_PAGE_ERROR PRIMARY KEY (URL)
);

CREATE TABLE ASPEN2.PAGE_ERROR_LOG_DETAIL (
	APP_SID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	HOST				VARCHAR(1024) NOT NULL,
	URL					VARCHAR(1024) NOT NULL,
	USER_SID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','SID') NOT NULL,
	UNIQUE_ERROR_ID		VARCHAR2(1024),
	QUERY_STRING		VARCHAR2(1024),
	EXCEPTION_TYPE		VARCHAR2(1024),
	STACK_TRACE			CLOB,
	ERROR_DTM			DATE DEFAULT SYSDATE,
	CONSTRAINT PK_PAGE_ERROR_LOG_DETAIL PRIMARY KEY (UNIQUE_ERROR_ID),
	CONSTRAINT FK_PAGE_ERROR_LOG FOREIGN KEY (URL) REFERENCES ASPEN2.PAGE_ERROR_LOG(URL)
);

CREATE INDEX ASPEN2.IDX_PAGE_ERROR_LOG_DETAIL ON ASPEN2.PAGE_ERROR_LOG_DETAIL(APP_SID);

ALTER TABLE csr.issue_type ADD allow_owner_resolve_and_close NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE csrimp.issue_type ADD allow_owner_resolve_and_close NUMBER(1,0) DEFAULT 0 NOT NULL;

CREATE TABLE csr.UTIL_SCRIPT (
	UTIL_SCRIPT_ID		NUMBER(10) NOT NULL ,
	UTIL_SCRIPT_NAME	VARCHAR2(255) NOT NULL,
	DESCRIPTION			VARCHAR2(2047),
	UTIL_SCRIPT_SP		VARCHAR2(255),
	WIKI_ARTICLE		VARCHAR2(10),
	CONSTRAINT pk_util_script_id PRIMARY KEY (util_script_id)
	USING INDEX
);

CREATE TABLE CSR.UTIL_SCRIPT_PARAM (
	UTIL_SCRIPT_ID		NUMBER(10) NOT NULL,
	PARAM_NAME			VARCHAR2(1023) NOT NULL,
	PARAM_HINT			VARCHAR2(1023),
	POS					NUMBER(2) NOT NULL,
	CONSTRAINT fk_util_script_param_id FOREIGN KEY (util_script_id)
	REFERENCES CSR.UTIL_SCRIPT(util_script_id)
);

CREATE TABLE CSR.UTIL_SCRIPT_RUN_LOG (
	APP_SID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	UTIL_SCRIPT_ID		NUMBER(10) NOT NULL,
	CSR_USER_SID		NUMBER(10) NOT NULL,
	RUN_DTM				DATE NOT NULL,
	PARAMS				VARCHAR2(2048),
	CONSTRAINT fk_util_script_run_script_id FOREIGN KEY (util_script_id)
	REFERENCES CSR.UTIL_SCRIPT(util_script_id),
	CONSTRAINT fk_util_script_run_user FOREIGN KEY (app_sid, csr_user_sid)
	REFERENCES CSR.csr_user(app_sid, csr_user_sid)
);

CREATE SEQUENCE CSR.COURSE_FILE_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;

CREATE TABLE CSR.COURSE_FILE(
	APP_SID					NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP'), 
	COURSE_ID				NUMBER(10,0), 
	COURSE_FILE_DATA_ID		NUMBER(10,0)
);

CREATE TABLE CSR.COURSE_FILE_DATA(
	APP_SID 				NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP'), 
	COURSE_FILE_DATA_ID		NUMBER(10,0), 
	FILENAME				VARCHAR2(255 BYTE), 
	MIME_TYPE				VARCHAR2(255 BYTE), 
	DATA					BLOB, 
	SHA1 					RAW(20), 
	UPLOADED_DTM			DATE DEFAULT SYSDATE
);

-- Alter tables
ALTER TABLE csr.imp_session
ADD unmerged_dtm DATE;
DROP INDEX CSR.UK_EST_JOB;

CREATE UNIQUE INDEX CSR.UK_EST_JOB ON CSR.EST_JOB(APP_SID, EST_JOB_TYPE_ID, EST_ACCOUNT_SID, PM_CUSTOMER_ID, PM_BUILDING_ID, PM_SPACE_ID, PM_METER_ID, REGION_SID, PROCESSING);

ALTER TABLE cms.tab_column ADD (
	restricted_by_policy			NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_restricted_by_policy_1_0 CHECK (restricted_by_policy IN (1, 0))
);

ALTER TABLE csrimp.cms_tab_column ADD (
	restricted_by_policy			NUMBER(1) NOT NULL,
	CONSTRAINT chk_restricted_by_policy_1_0 CHECK (restricted_by_policy IN (1, 0))
);

ALTER TABLE chain.filter_value MODIFY min_num_val NUMBER(24, 10);
ALTER TABLE chain.filter_value MODIFY max_num_val NUMBER(24, 10);
ALTER TABLE csrimp.chain_filter_value MODIFY max_num_val NUMBER(24, 10);
ALTER TABLE csrimp.chain_filter_value MODIFY max_num_val NUMBER(24, 10);

ALTER TABLE csr.role ADD is_system_managed number(1) DEFAULT 0;
UPDATE csr.role SET is_system_managed = 0;
ALTER TABLE csr.role MODIFY is_system_managed NOT NULL;
ALTER TABLE csr.role ADD CONSTRAINT chk_is_system_managed_1_0 CHECK (is_system_managed IN (1, 0));

ALTER TABLE csrimp.role ADD(
	IS_USER_CREATOR   NUMBER(1),
	IS_HIDDEN         NUMBER(1),
	IS_SYSTEM_MANAGED NUMBER(1)
);

ALTER TABLE CSR.COURSE_FILE ADD CONSTRAINT PK_COURSE_FILE_CONN PRIMARY KEY (APP_SID, COURSE_ID, COURSE_FILE_DATA_ID);
ALTER TABLE CSR.COURSE_FILE_DATA ADD CONSTRAINT PK_COURSE_FILE PRIMARY KEY (APP_SID, COURSE_FILE_DATA_ID);
ALTER TABLE CSR.COURSE_FILE ADD CONSTRAINT FK_COURSE_FILE_CONN_COURSE FOREIGN KEY (APP_SID, COURSE_ID)
	REFERENCES CSR.COURSE (APP_SID, COURSE_ID);
ALTER TABLE CSR.COURSE_FILE ADD CONSTRAINT FK_COURSE_FILE_CONN_FILE FOREIGN KEY (APP_SID, COURSE_FILE_DATA_ID)
	REFERENCES CSR.COURSE_FILE_DATA (APP_SID, COURSE_FILE_DATA_ID) ON DELETE CASCADE;

ALTER TABLE chain.business_relationship_type ADD(
LOOKUP_KEY VARCHAR2(255)
);

ALTER TABLE chain.business_relationship_tier ADD(
LOOKUP_KEY VARCHAR2(255)
);

ALTER TABLE CSR.FLOW_STATE_TRANSITION_ROLE DROP CONSTRAINT FK_FL_ST_ROLE_FL_ST_TR_ROLE DROP INDEX;
ALTER TABLE CSR.FLOW_STATE_ROLE_CAPABILITY DROP CONSTRAINT FK_FLOW_STATE_RL_CAP_ROLE DROP INDEX;
ALTER TABLE CSR.FLOW_STATE_TRANSITION_ROLE DROP PRIMARY KEY DROP INDEX;
ALTER TABLE CSR.FLOW_STATE_ALERT_ROLE DROP PRIMARY KEY DROP INDEX;
ALTER TABLE CSR.FLOW_TRANSITION_ALERT_ROLE DROP PRIMARY KEY DROP INDEX;
ALTER TABLE CSR.FLOW_STATE_ROLE DROP PRIMARY KEY DROP INDEX;
ALTER TABLE CSR.FLOW_STATE_ROLE_CAPABILITY DROP CONSTRAINT UK_FLOW_STATE_ROLE_CAPABILITY DROP INDEX;
ALTER TABLE CSR.FLOW_STATE_ROLE_CAPABILITY DROP CONSTRAINT CHK_FLOW_STATE_ROLE_CAPABILITY DROP INDEX;

alter table CSR.FLOW_STATE_ALERT_ROLE modify (
	ROLE_SID	NULL
);

alter table CSR.FLOW_STATE_ROLE modify (
	ROLE_SID	NULL
);

alter table CSR.FLOW_STATE_TRANSITION_ROLE modify (
	ROLE_SID	NULL
);

ALTER TABLE CSR.FLOW_TRANSITION_ALERT_ROLE modify (
	ROLE_SID	NULL
);

alter table CSR.FLOW_STATE_ALERT_ROLE add (
	GROUP_SID NUMBER(10) NULL
);

alter table CSR.FLOW_STATE_ROLE add (
	GROUP_SID NUMBER(10) NULL
);

alter table CSR.FLOW_STATE_ROLE_CAPABILITY add (
	GROUP_SID NUMBER(10) NULL
);

alter table CSR.FLOW_STATE_TRANSITION_ROLE add (
	GROUP_SID NUMBER(10) NULL
);

alter table CSR.FLOW_TRANSITION_ALERT_ROLE add (
	GROUP_SID NUMBER(10) NULL
);

-- add constraints
ALTER TABLE CSR.FLOW_STATE_ROLE_CAPABILITY ADD CONSTRAINT UK_FLOW_STATE_ROLE_CAPABILITY UNIQUE (APP_SID, FLOW_STATE_ID, FLOW_CAPABILITY_ID, ROLE_SID, GROUP_SID, FLOW_INVOLVEMENT_TYPE_ID);
ALTER TABLE CSR.FLOW_STATE_ROLE ADD CONSTRAINT PK_FLOW_STATE_ROLE UNIQUE (APP_SID, FLOW_STATE_ID, ROLE_SID, GROUP_SID);
ALTER TABLE CSR.FLOW_STATE_TRANSITION_ROLE ADD CONSTRAINT PK_FLOW_STATE_TRANS_ROLE UNIQUE (APP_SID, FLOW_STATE_TRANSITION_ID, FROM_STATE_ID, ROLE_SID, GROUP_SID);
ALTER TABLE CSR.FLOW_STATE_ALERT_ROLE ADD CONSTRAINT PK_FLOW_STATE_ALERT_ROLE UNIQUE (APP_SID, FLOW_SID, FLOW_STATE_ALERT_ID, ROLE_SID, GROUP_SID);
ALTER TABLE CSR.FLOW_TRANSITION_ALERT_ROLE ADD CONSTRAINT PK_FLOW_TRANSITION_ALERT_ROLE UNIQUE (APP_SID, FLOW_TRANSITION_ALERT_ID, ROLE_SID, GROUP_SID);
ALTER TABLE CSR.FLOW_STATE_TRANSITION_ROLE ADD CONSTRAINT FK_FL_ST_ROLE_FL_ST_TR_ROLE 
    FOREIGN KEY (APP_SID, FROM_STATE_ID, ROLE_SID, GROUP_SID)
    REFERENCES CSR.FLOW_STATE_ROLE(APP_SID, FLOW_STATE_ID, ROLE_SID, GROUP_SID) ON DELETE CASCADE  DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE CSR.FLOW_STATE_ROLE_CAPABILITY ADD CONSTRAINT FK_FLOW_STATE_RL_CAP_ROLE FOREIGN KEY (APP_SID, FLOW_STATE_ID, ROLE_SID, GROUP_SID) REFERENCES CSR.FLOW_STATE_ROLE (APP_SID, FLOW_STATE_ID, ROLE_SID, GROUP_SID);
ALTER TABLE CSR.FLOW_STATE_ALERT_ROLE ADD CONSTRAINT CHK_FSAR_ROLE_SID_GROUP_SID CHECK ((ROLE_SID IS NULL AND GROUP_SID IS NOT NULL) OR (ROLE_SID IS NOT NULL AND GROUP_SID IS NULL));
ALTER TABLE CSR.FLOW_STATE_ROLE ADD CONSTRAINT CHK_FSR_ROLE_SID_GROUP_SID CHECK ((ROLE_SID IS NULL AND GROUP_SID IS NOT NULL) OR (ROLE_SID IS NOT NULL AND GROUP_SID IS NULL));
ALTER TABLE CSR.FLOW_STATE_ROLE_CAPABILITY ADD CONSTRAINT CHK_FLOW_STATE_ROLE_CAPABILITY CHECK (
	(ROLE_SID IS NULL AND GROUP_SID IS NOT NULL AND FLOW_INVOLVEMENT_TYPE_ID IS NULL) OR
	(ROLE_SID IS NOT NULL AND GROUP_SID IS NULL AND FLOW_INVOLVEMENT_TYPE_ID IS NULL) OR
	(ROLE_SID IS NULL AND GROUP_SID IS NULL AND FLOW_INVOLVEMENT_TYPE_ID IS NOT NULL));

ALTER TABLE CSR.FLOW_STATE_TRANSITION_ROLE ADD CONSTRAINT CHK_FSTR_ROLE_SID_GROUP_SID CHECK ((ROLE_SID IS NULL AND GROUP_SID IS NOT NULL) OR (ROLE_SID IS NOT NULL AND GROUP_SID IS NULL));
ALTER TABLE CSR.FLOW_TRANSITION_ALERT_ROLE ADD CONSTRAINT CHK_FTAR_ROLE_SID_GROUP_SID CHECK ((ROLE_SID IS NULL AND GROUP_SID IS NOT NULL) OR (ROLE_SID IS NOT NULL AND GROUP_SID IS NULL));
ALTER TABLE CSR.FLOW_STATE_ALERT_ROLE ADD CONSTRAINT FK_FSAR_GROUP FOREIGN KEY (GROUP_SID) REFERENCES SECURITY.GROUP_TABLE(SID_ID);
ALTER TABLE CSR.FLOW_STATE_ROLE ADD CONSTRAINT FK_FSR_GROUP FOREIGN KEY (GROUP_SID) REFERENCES SECURITY.GROUP_TABLE(SID_ID);
ALTER TABLE CSR.FLOW_STATE_ROLE_CAPABILITY ADD CONSTRAINT FK_FSRC_GROUP FOREIGN KEY (GROUP_SID) REFERENCES SECURITY.GROUP_TABLE(SID_ID);
ALTER TABLE CSR.FLOW_STATE_TRANSITION_ROLE ADD CONSTRAINT FK_FSTR_GROUP FOREIGN KEY (GROUP_SID) REFERENCES SECURITY.GROUP_TABLE(SID_ID);
ALTER TABLE CSR.FLOW_TRANSITION_ALERT_ROLE ADD CONSTRAINT FK_FTAR_GROUP FOREIGN KEY (GROUP_SID) REFERENCES SECURITY.GROUP_TABLE(SID_ID);

-- types
DROP TYPE CSR.T_FLOW_STATE_TABLE;
DROP TYPE CSR.T_FLOW_STATE_ROW;
DROP TYPE CSR.T_FLOW_STATE_TRANS_TABLE;
DROP TYPE CSR.T_FLOW_STATE_TRANS_ROW;

CREATE GLOBAL TEMPORARY TABLE CSR.T_FLOW_STATE
(
	FLOW_SID				NUMBER(10) NOT NULL,
	POS						NUMBER(10) NOT NULL,
	FLOW_STATE_ID			NUMBER(10) NOT NULL,
	LABEL					VARCHAR2(255) NOT NULL,
	LOOKUP_KEY				VARCHAR2(255),
	IS_FINAL				NUMBER(1) NOT NULL,
	STATE_COLOUR			NUMBER(10),
	EDITABLE_ROLE_SIDS		VARCHAR2(2000),
	NON_EDITABLE_ROLE_SIDS	VARCHAR2(2000),
	EDITABLE_COL_SIDS		VARCHAR2(2000),
	NON_EDITABLE_COL_SIDS	VARCHAR2(2000),
	INVOLVED_TYPE_IDS		VARCHAR2(2000),
	EDITABLE_GROUP_SIDS		VARCHAR2(2000),
	NON_EDITABLE_GROUP_SIDS	VARCHAR2(2000),
	ATTRIBUTES_XML			XMLTYPE
)
ON COMMIT DELETE ROWS
;

CREATE GLOBAL TEMPORARY TABLE CSR.T_FLOW_STATE_ALERT
(
	FLOW_SID					NUMBER(10) NOT NULL,
	FLOW_STATE_ID				NUMBER(10) NOT NULL,
	CUSTOMER_ALERT_TYPE_ID		NUMBER(10) NOT NULL,
	FLOW_STATE_ALERT_ID			NUMBER(10) NOT NULL,
	FLOW_ALERT_DESCRIPTION		VARCHAR2(500) NOT NULL,
	HELPER_SP					VARCHAR2(256),
	ROLE_SIDS					VARCHAR2(2000),
	GROUP_SIDS					VARCHAR2(2000),
	USER_SIDS					VARCHAR2(2000),
	RECURRENCE_XML				XMLTYPE NOT NULL
)
ON COMMIT DELETE ROWS
;

CREATE GLOBAL TEMPORARY TABLE CSR.T_FLOW_STATE_ROLE_CAP
(
	FLOW_SID					NUMBER(10) NOT NULL,
	FLOW_STATE_RL_CAP_ID 		NUMBER(10) NOT NULL,
	FLOW_STATE_ID				NUMBER(10) NOT NULL,
	FLOW_CAPABILITY_ID			NUMBER(10) NOT NULL,
	ROLE_SID					NUMBER(10),
	FLOW_INVOLVEMENT_TYPE_ID	NUMBER(10),
	PERMISSION_SET				NUMBER(10) NOT NULL,
	GROUP_SID					NUMBER(10)
)
ON COMMIT DELETE ROWS
;

CREATE GLOBAL TEMPORARY TABLE CSR.T_FLOW_STATE_TRANS
(
	FLOW_SID					NUMBER(10) NOT NULL,
	POS							NUMBER(10) NOT NULL,
	FLOW_STATE_TRANSITION_ID	NUMBER(10) NOT NULL,
	FROM_STATE_ID				NUMBER(10) NOT NULL,
	TO_STATE_ID					NUMBER(10) NOT NULL,
	ASK_FOR_COMMENT				VARCHAR2(16) NOT NULL,
	MANDATORY_FIELDS_MESSAGE	VARCHAR2(255),
	HOURS_BEFORE_AUTO_TRAN		NUMBER(10),
	BUTTON_ICON_PATH			VARCHAR2(255),
	VERB						VARCHAR2(255) NOT NULL,
	LOOKUP_KEY					VARCHAR2(255),
	HELPER_SP					VARCHAR2(255),
	ROLE_SIDS					VARCHAR2(2000),
	COLUMN_SIDS					VARCHAR2(2000),
	INVOLVED_TYPE_IDS			VARCHAR2(2000),
	GROUP_SIDS					VARCHAR2(2000),
	ATTRIBUTES_XML				XMLTYPE
)
ON COMMIT DELETE ROWS
;

CREATE GLOBAL TEMPORARY TABLE CSR.T_FLOW_TRANS_ALERT
(
	FLOW_SID					NUMBER(10) NOT NULL,
	FLOW_TRANSITION_ALERT_ID	NUMBER(10) NOT NULL,
	FLOW_STATE_TRANSITION_ID	NUMBER(10) NOT NULL,
	CUSTOMER_ALERT_TYPE_ID		NUMBER(10) NOT NULL,
	DESCRIPTION					VARCHAR2(500) NOT NULL,
	TO_INITIATOR				NUMBER(1) NOT NULL,
	HELPER_SP					VARCHAR2(256),
	FLOW_CMS_COLS				VARCHAR2(2000),
	USER_SIDS					VARCHAR2(2000),
	ROLE_SIDS					VARCHAR2(2000),
	GROUP_SIDS					VARCHAR2(2000),
	ALERT_MANAGER_FLAGS			VARCHAR2(2000),
	INVOLVED_TYPE_IDS			VARCHAR2(2000)
)
ON COMMIT DELETE ROWS
;

-- *** Grants ***
GRANT DELETE on csr.region_role_member TO chain;
GRANT SELECT ON security.act TO csr;

-- ** Cross schema constraints ***

-- *** Views ***
CREATE OR REPLACE VIEW CHAIN.v$company AS
	SELECT c.app_sid, c.company_sid, c.created_dtm, c.name, c.activated_dtm, c.active, c.address_1, 
		   c.address_2, c.address_3, c.address_4, c.town, c.state, 
		   CASE co.edit_company_use_postcode_data WHEN 1 THEN pr.name ELSE c.state END state_name,
		   c.state_id, c.city,
		   CASE co.edit_company_use_postcode_data WHEN 1 THEN pc.city_name ELSE c.city END city_name,
		   c.city_id, c.postcode, c.country_code,
		   c.phone, c.fax, c.website, c.email, c.deleted, c.details_confirmed, c.stub_registration_guid, 
		   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required, 
		   c.user_level_messaging, c.sector_id,
		   cou.name country_name, s.description sector_description, c.can_see_all_companies, c.company_type_id,
		   ct.lookup_key company_type_lookup, c.supp_rel_code_label, c.supp_rel_code_label_mand,
		   c.parent_sid, p.name parent_name, p.country_code parent_country_code, pcou.name parent_country_name,
		   c.country_is_hidden, cs.region_sid
	  FROM company c
	  JOIN customer_options co ON co.app_sid = c.app_sid
	  LEFT JOIN v$country cou ON c.country_code = cou.country_code
	  LEFT JOIN sector s ON c.sector_id = s.sector_id AND c.app_sid = s.app_sid
	  LEFT JOIN company_type ct ON c.company_type_id = ct.company_type_id
	  LEFT JOIN company p ON c.parent_sid = p.company_sid AND c.app_sid = p.app_sid
	  LEFT JOIN v$country pcou ON p.country_code = pcou.country_code
	  LEFT JOIN csr.supplier cs ON cs.company_sid = c.company_sid AND cs.app_sid = c.app_sid
	  LEFT JOIN postcode.city pc ON c.city_id = pc.city_id AND c.country_code = pc.country
	  LEFT JOIN postcode.region pr ON c.state_id = pr.region AND c.country_code = pr.country
	 WHERE c.deleted = 0
;

CREATE OR REPLACE VIEW csr.v$issue AS
SELECT i.app_sid, NVL2(i.issue_ref, ist.internal_issue_ref_prefix || i.issue_ref, null) custom_issue_id, i.issue_id, i.label, i.description, i.source_label, i.is_visible, i.source_url, i.region_sid, re.description region_name, i.parent_id,
	   i.issue_escalated, i.owner_role_sid, i.owner_user_sid, cuown.user_name owner_user_name, cuown.full_name owner_full_name, cuown.email owner_email, i.first_issue_log_id, i.last_issue_log_id, NVL(lil.logged_dtm, i.raised_dtm) last_modified_dtm,
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
   
-- *** Data changes ***
-- RLS

-- Data

INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
VALUES (50, 'Emission Factor Start Date ON', 'EnableFactorStartMonth', 'Update the Emission Factor start date to match the customer reporting period start date.', 0);
INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
VALUES (51, 'Emission Factor Start Date OFF', 'DisableFactorStartMonth', 'Turn off the Emission Factor start date match on the customer reporting period start date.', 0);

-- Setup some sensible defaults now we can chart/filter on numbers, so we don't
-- have id columns everywhere

-- turn off charting on all cms.tab_pkg.CT_AUTO_INCREMENT columns by default
UPDATE cms.tab_column
   SET show_in_breakdown = 0
 WHERE col_type = 16; 
 
-- turn off filtering/charting on all id columns that are fks to other tables
-- (filtering is handled by adapters for these)
UPDATE cms.tab_column
   SET show_in_breakdown = 0,
       show_in_filter = 0
 WHERE col_type = 0 
   AND data_type = 'NUMBER'
   AND column_sid IN (
	SELECT column_sid
	  FROM cms.fk_cons_col
	);

-- turn off filtering on auto columns for child tables by default
UPDATE cms.tab_column
   SET show_in_filter = 0
 WHERE col_type = 16
   AND tab_sid IN (
	SELECT tab_sid
	  FROM cms.tab_column tc
	  JOIN cms.fk_cons_col fcc ON tc.column_sid = fcc.column_sid
	 WHERE tc.col_type = 0
	   AND tc.data_type = 'NUMBER'
);

-- Create future sheets for delegation
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP)
	VALUES (1, 'Create future sheets for delegation', 'Creates sheets in the future for an existing delegation. Replaces CreateDelegationSheetsFuture.sql', 'CreateDelegationSheetsFuture');
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
	VALUES (1, 'Delegation sid', 'The sid of the delegation to run against', 1);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
	VALUES (1, 'Max date (YYYY-MM-DD)', 'The maximum date to create sheets for', 2);
	-- Recalcone
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP)
	VALUES (2, 'Recalc one', 'Queues recalc jobs for the current site/app. Replaces recalcOne.sql', 'RecalcOne');
	-- Create imap folder
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
	VALUES (3, 'Create IMAP folder', 'Creates an imap folder for routing client emails. See the wiki page. Replaces EnableClientImapFolder.sql', 'CreateImapFolder', 'W955');
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
	VALUES (3, 'Folder name', 'IMAP folder name to create (lower-case by convention, e.g. credit360)', 1);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
	VALUES (3, 'Suffixes (See wiki)', '(optionally comma-separated list) of email suffixes, e.g. credit360.com,credit360.co.uk', 2);
	
	--Create the menu item for all sites
	security.user_pkg.logonadmin;
	
	FOR r IN (
		SELECT app_sid, host
		  FROM csr.customer c, security.website w
		 WHERE c.host = w.website_name
	) LOOP
	
		security.user_pkg.logonadmin(r.host);
	
		DECLARE
			v_act_id 					security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
			v_app_sid 					security.security_pkg.T_SID_ID DEFAULT security.security_pkg.GetApp;
			v_menu						security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu');
			v_sa_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');
			v_setup_menu				security.security_pkg.T_SID_ID;
			v_utilscript_menu				security.security_pkg.T_SID_ID;
			
		BEGIN
			BEGIN
				v_setup_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'Setup');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(v_act_id, v_menu, 'setup',  'Setup',  '/csr/site/admin/config/global.acds',  0, null, v_setup_menu);
			END;
		
			BEGIN
				v_utilscript_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_setup_menu, 'csr_admin_utilscripts');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(v_act_id, v_setup_menu, 'csr_admin_utilscripts',  'Utility scripts',  '/csr/site/admin/UtilScripts/UtilScripts.acds',  0, null, v_utilscript_menu);
			END;
			
			-- don't inherit dacls
			security.securableobject_pkg.SetFlags(v_act_id, v_utilscript_menu, 0);
			--Remove inherited ones
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_utilscript_menu));
			-- Add SA permission
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_utilscript_menu), -1, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			
		END;
	END LOOP;
	
	commit;
END;
/
-- ** New package grants **
create or replace package csr.util_script_pkg as
procedure dummy;
end;
/
create or replace package body csr.util_script_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

GRANT EXECUTE ON mail.message_filter_pkg TO web_user;
GRANT EXECUTE ON mail.mailbox_pkg TO web_user;
GRANT EXECUTE ON mail.message_filter_pkg TO csr;
GRANT EXECUTE ON mail.mailbox_pkg TO csr;
GRANT EXECUTE ON csr.util_script_pkg TO web_user;

-- *** Packages ***
@..\enable_pkg
@..\..\..\aspen2\db\error_pkg
@..\audit_pkg
@..\chain\filter_pkg
@..\..\..\aspen2\cms\db\tab_pkg
@..\chain\company_filter_pkg
@../util_script_pkg
@../csr_data_pkg
@../role_pkg
@../training_pkg
@..\flow_pkg
@..\chem\substance_pkg
@../issue_pkg

@../issue_body
@..\chem\substance_body
@..\flow_body
@../training_body
@../chain/company_body
@../role_body
@../chain/company_user_body
@../chain/company_type_body
@../chain/scheduled_alert_body
@../schema_body
@..\chain\setup_body
@../chain/task_body
@../util_script_body
@../initiative_body
@../logistics_body
@..\chain\company_filter_body
@..\..\..\aspen2\cms\db\tab_body
@..\..\..\aspen2\cms\db\filter_body
@..\csrimp\imp_body
@..\chain\filter_body
@..\supplier_body
@..\audit_body
@..\energy_star_job_body
@../imp_body
@..\..\..\aspen2\db\error_body
@..\enable_body

@update_tail
