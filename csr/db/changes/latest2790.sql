-- Please update version.sql too -- this keeps clean builds in sync
define version=2790
define minor_version=0
define is_combined=1
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE csr.ia_type_survey_group_id_seq;
CREATE SEQUENCE csr.ia_type_survey_id_seq;
CREATE SEQUENCE csr.customer_flow_cap_id_seq MINVALUE 1000001;

CREATE TABLE csr.customer_flow_capability (
	app_sid									NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	flow_capability_id						NUMBER(10,0) NOT NULL,
    flow_alert_class						VARCHAR2(256 BYTE) NOT NULL,
    description								VARCHAR2(256 BYTE) NOT NULL,
    perm_type								NUMBER(1) NOT NULL,
    default_permission_set					NUMBER(10,0) DEFAULT 0 NOT NULL,
	lookup_key								VARCHAR2(256),
    CONSTRAINT pk_cust_flow_capability		PRIMARY KEY (app_sid, flow_capability_id),
    CONSTRAINT ck_cust_flow_capability		CHECK (flow_capability_id > 1000000),
    CONSTRAINT ck_cust_flow_cap_perm_type	CHECK (perm_type IN (0, 1)),
    CONSTRAINT fk_cust_flow_cap_alert_class	FOREIGN KEY (flow_alert_class) REFERENCES csr.flow_alert_class (flow_alert_class)
);

CREATE UNIQUE INDEX csr.ux_cust_flow_capability_lk ON csr.customer_flow_capability (CASE WHEN lookup_key IS NOT NULL THEN app_sid END, LOWER(lookup_key));

CREATE TABLE csr.ia_type_survey_group (
	app_sid									NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	ia_type_survey_group_id					NUMBER(10, 0) NOT NULL,
	label									VARCHAR2(1024) NOT NULL,
	lookup_key								VARCHAR2(256),
	survey_capability_id					NUMBER(10, 0) NOT NULL,
	change_survey_capability_id				NUMBER(10, 0) NOT NULL,
	CONSTRAINT pk_iatsg						PRIMARY KEY (app_sid, ia_type_survey_group_id),
	CONSTRAINT ck_iatsg_survey_cap			FOREIGN KEY (app_sid, survey_capability_id) REFERENCES csr.customer_flow_capability (app_sid, flow_capability_id),
	CONSTRAINT ck_iatsg_chng_survey_cap		FOREIGN KEY (app_sid, change_survey_capability_id) REFERENCES csr.customer_flow_capability (app_sid, flow_capability_id)
);

CREATE UNIQUE INDEX csr.ux_iatsg_label	ON csr.ia_type_survey_group (app_sid, LOWER(label));
CREATE UNIQUE INDEX csr.ux_iatsg_lookup_key	ON csr.ia_type_survey_group (CASE WHEN lookup_key IS NOT NULL THEN app_sid END, LOWER(lookup_key));

CREATE TABLE csr.internal_audit_type_survey (
	app_sid									NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	internal_audit_type_survey_id			NUMBER(10, 0) NOT NULL,
	internal_audit_type_id					NUMBER(10, 0) NOT NULL,
	active									NUMBER(1, 0) DEFAULT 1 NOT NULL,
	label									VARCHAR2(1024) NOT NULL,
	ia_type_survey_group_id					NUMBER(10, 0),
	default_survey_sid						NUMBER(10, 0),
	mandatory								NUMBER(1, 0) DEFAULT 0 NOT NULL,
	survey_fixed							NUMBER(1, 0) DEFAULT 0 NOT NULL,
	survey_group_key						VARCHAR2(256),
	CONSTRAINT pk_iats						PRIMARY KEY (app_sid, internal_audit_type_survey_id),
	CONSTRAINT fk_iats_audit_type			FOREIGN KEY (app_sid, internal_audit_type_id)	REFERENCES csr.internal_audit_type (app_sid, internal_audit_type_id),
	CONSTRAINT fk_iats_group				FOREIGN KEY (app_sid, ia_type_survey_group_id)	REFERENCES csr.ia_type_survey_group (app_sid, ia_type_survey_group_id),
	CONSTRAINT fk_iats_default_survey		FOREIGN KEY (app_sid, default_survey_sid)		REFERENCES csr.quick_survey (app_sid, survey_sid),
	CONSTRAINT ck_iats_active				CHECK (active IN (0, 1)),
	CONSTRAINT ck_iats_mandatory			CHECK (mandatory IN (0, 1)),
	CONSTRAINT ck_iats_survey_fixed			CHECK (survey_fixed IN (0, 1))
);

CREATE UNIQUE INDEX csr.ux_iats_label	ON csr.internal_audit_type_survey (app_sid, internal_audit_type_id, LOWER(label));
CREATE UNIQUE INDEX csr.ux_iats_iatsg	ON csr.internal_audit_type_survey (CASE WHEN ia_type_survey_group_id IS NOT NULL THEN app_sid END,
																		   CASE WHEN ia_type_survey_group_id IS NOT NULL THEN internal_audit_type_id END,
																		   ia_type_survey_group_id);

CREATE TABLE csr.internal_audit_survey (
	app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	internal_audit_sid				NUMBER(10, 0) NOT NULL,
	internal_audit_type_survey_id	NUMBER(10, 0) NOT NULL,
	survey_sid						NUMBER(10, 0) NOT NULL,
	survey_response_id				NUMBER(10, 0),
	CONSTRAINT pk_ias				PRIMARY KEY (app_sid, internal_audit_sid, internal_audit_type_survey_id),
	CONSTRAINT fk_ias_audit			FOREIGN KEY (app_sid, internal_audit_sid)				REFERENCES csr.internal_audit (app_sid, internal_audit_sid),
	CONSTRAINT fk_ias_iats			FOREIGN KEY (app_sid, internal_audit_type_survey_id)	REFERENCES csr.internal_audit_type_survey (app_sid, internal_audit_type_survey_id),
	CONSTRAINT fk_ias_survey		FOREIGN KEY (app_sid, survey_sid)						REFERENCES csr.quick_survey (app_sid, survey_sid),
	CONSTRAINT fk_ias_response		FOREIGN KEY (app_sid, survey_response_id)				REFERENCES csr.quick_survey_response (app_sid, survey_response_id)
);

CREATE TABLE CSRIMP.CUSTOMER_FLOW_CAPABILITY (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	FLOW_CAPABILITY_ID NUMBER(10,0) NOT NULL,
	DEFAULT_PERMISSION_SET NUMBER(10,0) NOT NULL,
	DESCRIPTION VARCHAR2(256) NOT NULL,
	FLOW_ALERT_CLASS VARCHAR2(256) NOT NULL,
	LOOKUP_KEY VARCHAR2(256),
	PERM_TYPE NUMBER(1) NOT NULL,
	CONSTRAINT PK_CUSTOMER_FLOW_CAPABILITY PRIMARY KEY (CSRIMP_SESSION_ID, FLOW_CAPABILITY_ID),
	CONSTRAINT FK_CUSTOMER_FLOW_CAPABILITY_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.IA_TYPE_SURVEY_GROUP (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	IA_TYPE_SURVEY_GROUP_ID NUMBER(10,0) NOT NULL,
	SURVEY_CAPABILITY_ID NUMBER(10, 0) NOT NULL,
	CHANGE_SURVEY_CAPABILITY_ID NUMBER(10, 0) NOT NULL,
	LABEL VARCHAR2(1024) NOT NULL,
	LOOKUP_KEY VARCHAR2(256),
	CONSTRAINT PK_IA_TYPE_SURVEY_GROUP PRIMARY KEY (CSRIMP_SESSION_ID, IA_TYPE_SURVEY_GROUP_ID),
	CONSTRAINT FK_IA_TYPE_SURVEY_GROUP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.IA_TYPE_SURVEY (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	INTERNAL_AUDIT_TYPE_SURVEY_ID NUMBER(10,0) NOT NULL,
	ACTIVE NUMBER(1,0) NOT NULL,
	DEFAULT_SURVEY_SID NUMBER(10,0),
	IA_TYPE_SURVEY_GROUP_ID NUMBER(10,0),
	INTERNAL_AUDIT_TYPE_ID NUMBER(10,0) NOT NULL,
	LABEL VARCHAR2(1024) NOT NULL,
	MANDATORY NUMBER(1,0) NOT NULL,
	SURVEY_FIXED NUMBER(1,0) NOT NULL,
	SURVEY_GROUP_KEY VARCHAR2(256),
	CONSTRAINT PK_INTERN_AUDIT_TYPE_SURVEY PRIMARY KEY (CSRIMP_SESSION_ID, INTERNAL_AUDIT_TYPE_SURVEY_ID),
	CONSTRAINT FK_INTERN_AUDIT_TYPE_SURVEY_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.INTERNAL_AUDIT_SURVEY (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	INTERNAL_AUDIT_SID NUMBER(10,0) NOT NULL,
	INTERNAL_AUDIT_TYPE_SURVEY_ID NUMBER(10,0) NOT NULL,
	SURVEY_RESPONSE_ID NUMBER(10,0),
	SURVEY_SID NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_INTERNAL_AUDIT_SURVEY PRIMARY KEY (CSRIMP_SESSION_ID, INTERNAL_AUDIT_SID, INTERNAL_AUDIT_TYPE_SURVEY_ID),
	CONSTRAINT FK_INTERNAL_AUDIT_SURVEY_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CUSTOMER_FLOW_CAP (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CUSTOMER_FLOW_CAP_ID NUMBER(10) NOT NULL,
	NEW_CUSTOMER_FLOW_CAP_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CUSTOMER_FLOW_CAP PRIMARY KEY (OLD_CUSTOMER_FLOW_CAP_ID) USING INDEX,
	CONSTRAINT UK_MAP_CUSTOMER_FLOW_CAP UNIQUE (NEW_CUSTOMER_FLOW_CAP_ID) USING INDEX,
	CONSTRAINT FK_MAP_CUSTOMER_FLOW_CAP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_IA_TYPE_SURVEY_GROUP (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_IA_TYPE_SURVEY_GROUP_ID NUMBER(10) NOT NULL,
	NEW_IA_TYPE_SURVEY_GROUP_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_IA_TYPE_SURVEY_GROUP PRIMARY KEY (OLD_IA_TYPE_SURVEY_GROUP_ID) USING INDEX,
	CONSTRAINT UK_MAP_IA_TYPE_SURVEY_GROUP UNIQUE (NEW_IA_TYPE_SURVEY_GROUP_ID) USING INDEX,
	CONSTRAINT FK_MAP_IA_TYPE_SURVEY_GROUP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_IA_TYPE_SURVEY (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_IA_TYPE_SURVEY_ID NUMBER(10) NOT NULL,
	NEW_IA_TYPE_SURVEY_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_IA_TYPE_SURVEY PRIMARY KEY (OLD_IA_TYPE_SURVEY_ID) USING INDEX,
	CONSTRAINT UK_MAP_IA_TYPE_SURVEY UNIQUE (NEW_IA_TYPE_SURVEY_ID) USING INDEX,
	CONSTRAINT FK_MAP_IA_TYPE_SURVEY_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE csr.issue_type ADD (
	get_assignables_sp				VARCHAR2(255)
);

ALTER TABLE csrimp.issue_type ADD (
	get_assignables_sp				VARCHAR2(255)
);

DROP INDEX csr.plugin_js_class;
CREATE UNIQUE INDEX csr.plugin_js_class ON csr.plugin (app_sid, js_class, form_path, group_key, saved_filter_sid, result_mode);

ALTER TABLE CSR.QUICK_SURVEY_ANSWER ADD (
	LOG_ITEM CLOB
);
ALTER TABLE CSR.QS_ANSWER_LOG ADD (
	LOG_ITEM CLOB
);
ALTER TABLE CSR.QS_ANSWER_LOG RENAME COLUMN DESCRIPTION TO XXX_DESCRIPTION;
ALTER TABLE CSR.QS_ANSWER_LOG RENAME COLUMN PARAM_1 TO XXX_PARAM_1;
ALTER TABLE CSR.QS_ANSWER_LOG RENAME COLUMN PARAM_2 TO XXX_PARAM_2;
ALTER TABLE CSR.QS_ANSWER_LOG RENAME COLUMN PARAM_3 TO XXX_PARAM_3;
ALTER TABLE CSR.QS_ANSWER_LOG MODIFY XXX_DESCRIPTION VARCHAR2(255) NULL;

ALTER TABLE CSRIMP.QS_ANSWER_LOG ADD (
	LOG_ITEM CLOB
);
ALTER TABLE CSRIMP.QS_ANSWER_LOG DROP COLUMN DESCRIPTION;
ALTER TABLE CSRIMP.QS_ANSWER_LOG DROP COLUMN PARAM_1;
ALTER TABLE CSRIMP.QS_ANSWER_LOG DROP COLUMN PARAM_2;
ALTER TABLE CSRIMP.QS_ANSWER_LOG DROP COLUMN PARAM_3;

ALTER TABLE CSR.FLOW_STATE_TRANSITION ADD GROUP_SID_CAN_SET NUMBER(10, 0);
ALTER TABLE CSRIMP.FLOW_STATE_TRANSITION ADD GROUP_SID_CAN_SET NUMBER(10, 0);

ALTER TABLE csr.customer ADD (
	multiple_audit_surveys NUMBER(1)
);
UPDATE csr.customer SET multiple_audit_surveys = 0 WHERE multiple_audit_surveys IS NULL;
ALTER TABLE csr.customer MODIFY (
	multiple_audit_surveys DEFAULT 0 NOT NULL
);
ALTER TABLE csr.customer ADD (
	CONSTRAINT ck_multiple_audit_surveys CHECK (multiple_audit_surveys IN (0, 1))
);

ALTER TABLE csr.flow_capability ADD (
	CONSTRAINT chk_flow_capability CHECK (flow_capability_id < 1000000)
);

ALTER TABLE csr.internal_audit_type ADD (
	show_primary_survey_in_header	NUMBER(1, 0),
	primary_survey_active			NUMBER(1, 0),
	primary_survey_label			VARCHAR2(1024),
	primary_survey_mandatory		NUMBER(1, 0),
	primary_survey_fixed			NUMBER(1, 0),
	primary_survey_group_key		VARCHAR2(256)
);
UPDATE csr.internal_audit_type SET show_primary_survey_in_header = 1 WHERE show_primary_survey_in_header IS NULL;
UPDATE csr.internal_audit_type SET primary_survey_active = 1 WHERE primary_survey_active IS NULL;
UPDATE csr.internal_audit_type SET primary_survey_mandatory = 0 WHERE primary_survey_mandatory IS NULL;
UPDATE csr.internal_audit_type SET primary_survey_fixed = 0 WHERE primary_survey_fixed IS NULL;
ALTER TABLE csr.internal_audit_type MODIFY (
	show_primary_survey_in_header	DEFAULT 1 NOT NULL,
	primary_survey_active			DEFAULT 1 NOT NULL,
	primary_survey_mandatory		DEFAULT 0 NOT NULL,
	primary_survey_fixed			DEFAULT 0 NOT NULL
);
ALTER TABLE csr.internal_audit_type ADD (
	CONSTRAINT ck_iat_ps_in_header			CHECK (show_primary_survey_in_header IN (0, 1)),
	CONSTRAINT ck_iat_ps_active				CHECK (primary_survey_active IN (0, 1)),
	CONSTRAINT ck_iat_ps_mandatory			CHECK (primary_survey_mandatory IN (0, 1)),
	CONSTRAINT ck_iat_ps_fixed				CHECK (primary_survey_fixed IN (0, 1))
);

ALTER TABLE csr.quick_survey ADD (
	group_key						VARCHAR2(256)
);

ALTER TABLE csrimp.customer ADD (
	multiple_audit_surveys NUMBER(1)
);

ALTER TABLE csrimp.internal_audit_type ADD (
	show_primary_survey_in_header	NUMBER(1, 0),
	primary_survey_active			NUMBER(1, 0),
	primary_survey_label			VARCHAR2(1024),
	primary_survey_mandatory		NUMBER(1, 0),
	primary_survey_fixed			NUMBER(1, 0),
	primary_survey_group_key		VARCHAR2(256)
);

ALTER TABLE csrimp.quick_survey ADD (
	group_key						VARCHAR2(256)
);

-- *** Grants ***
grant select, insert, update, delete on csrimp.customer_flow_capability to web_user;
grant select, insert, update, delete on csrimp.ia_type_survey_group to web_user;
grant select, insert, update, delete on csrimp.IA_TYPE_SURVEY to web_user;
grant select, insert, update, delete on csrimp.internal_audit_survey to web_user;
grant select, insert, update on csr.customer_flow_capability to csrimp;
grant select, insert, update on csr.ia_type_survey_group to csrimp;
grant select, insert, update on csr.internal_audit_type_survey to csrimp;
grant select, insert, update on csr.internal_audit_survey to csrimp;
grant select on csr.customer_flow_cap_id_seq to csrimp;
grant select on csr.ia_type_survey_group_id_seq to csrimp;
grant select on csr.ia_type_survey_id_seq to csrimp;

-- ** Cross schema constraints ***
ALTER TABLE CSR.FLOW_STATE_TRANSITION ADD CONSTRAINT FK_FST_GROUP 
	FOREIGN KEY (GROUP_SID_CAN_SET) REFERENCES SECURITY.GROUP_TABLE(SID_ID);

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.
CREATE OR REPLACE VIEW CHAIN.v$company AS
	SELECT c.app_sid, c.company_sid, c.created_dtm, c.name, c.activated_dtm, c.active, c.address_1, 
		   c.address_2, c.address_3, c.address_4, c.town, c.state, 
		   NVL(pr.name, c.state) state_name, c.state_id, c.city, NVL(pc.city_name, c.city) city_name,
		   c.city_id, c.postcode, c.country_code,
		   c.phone, c.fax, c.website, c.email, c.deleted, c.details_confirmed, c.stub_registration_guid, 
		   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required, 
		   c.user_level_messaging, c.sector_id,
		   cou.name country_name, s.description sector_description, c.can_see_all_companies, c.company_type_id,
		   ct.lookup_key company_type_lookup, ct.singular company_type_description, c.supp_rel_code_label, c.supp_rel_code_label_mand,
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

CREATE OR REPLACE VIEW CSR.V$AUDIT_CAPABILITY AS
	SELECT ia.app_sid, ia.internal_audit_sid, ia.internal_audit_type_id, fsrc.flow_capability_id,
		   MAX(BITAND(fsrc.permission_set, 1)) + -- security_pkg.PERMISSION_READ
		   MAX(BITAND(fsrc.permission_set, 2)) permission_set -- security_pkg.PERMISSION_WRITE
	  FROM internal_audit ia
	  JOIN flow_item fi ON ia.app_sid = fi.app_sid AND ia.flow_item_id = fi.flow_item_id
	  JOIN flow_state_role_capability fsrc ON fi.app_sid = fsrc.app_sid AND fi.current_state_id = fsrc.flow_state_id
	  LEFT JOIN region_role_member rrm ON ia.app_sid = rrm.app_sid AND ia.region_sid = rrm.region_sid
	   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND rrm.role_sid = fsrc.role_sid
	  LEFT JOIN (
		SELECT fii.flow_involvement_type_id, fii.flow_item_id, fsi.flow_state_id
		  FROM flow_item_involvement fii
		  JOIN flow_state_involvement fsi 
	        ON fsi.flow_involvement_type_id = fii.flow_involvement_type_id
		 WHERE fii.user_sid = SYS_CONTEXT('SECURITY','SID')
		) finv 
		ON finv.flow_item_id = fi.flow_item_id 
	   AND finv.flow_involvement_type_id = fsrc.flow_involvement_type_id 
	   AND finv.flow_state_id = fi.current_state_id
	 WHERE ia.deleted = 0
	   AND ((fsrc.flow_involvement_type_id = 1 -- csr_data_pkg.FLOW_INV_TYPE_AUDITOR
	   AND (ia.auditor_user_sid = SYS_CONTEXT('SECURITY', 'SID')
		OR ia.auditor_user_sid IN (SELECT user_being_covered_sid FROM v$current_user_cover)))
		OR (ia.auditor_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND fsrc.flow_involvement_type_id = 2)	   -- csr_data_pkg.FLOW_INV_TYPE_AUDIT_COMPANY
	    OR finv.flow_involvement_type_id IS NOT NULL
		OR rrm.role_sid IS NOT NULL
		OR security.security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits'), 16) = 1) -- security.security_pkg.PERMISSION_TAKE_OWNERSHIP
	 GROUP BY ia.app_sid, ia.internal_audit_sid, ia.internal_audit_type_id, fsrc.flow_capability_id;

CREATE OR REPLACE VIEW csr.v$flow_capability AS
	SELECT NULL app_sid, flow_capability_id, flow_alert_class, description,
		   perm_type, default_permission_set, NULL lookup_key
	  FROM flow_capability
	 UNION
	SELECT app_sid, flow_capability_id, flow_alert_class, description,
		   perm_type, default_permission_set, lookup_key
	  FROM customer_flow_capability;

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
	   ind.ind_sid, ind.description ind_name, isv.start_dtm, isv.end_dtm, ist.owner_can_be_changed, ist.show_one_issue_popup, ist.lookup_key, ist.allow_owner_resolve_and_close,
	   CASE WHEN ist.get_assignables_sp IS NULL THEN 0 ELSE 1 END get_assignables_overridden
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

GRANT SELECT on csr.v$flow_capability TO CHAIN;

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.std_alert_type
   SET description = 'New sub-delegation',
       send_trigger = 'You manually sub-delegate a form and choose to notify users by clicking ''Yes – send e-mails'''
 WHERE std_alert_type_id = 2;

BEGIN
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (45, 'INITIATIVE_SID', 'Initiative Sid', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (45, 'NAME', 'Name', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (45, 'REF', 'Reference', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (45, 'PROJECT_START_DTM', 'Project start date', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (45, 'PROJECT_END_DTM', 'Project end date', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (45, 'RUNNING_START_DTM', 'Running start date', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (45, 'RUNNING_END_DTM', 'Running end date', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (45, 'REGIONS', 'Region descriptions', 1, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (45, 'SAVING_TYPE', 'Saving type', 1, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (45, 'INITIATIVE_LINK', 'Initiative link', 0, 'View initiative');

	UPDATE chain.saved_filter_alert_param
	   SET link_text = 'View property'
	 WHERE card_group_id = 44
	   AND field_name = 'PROPERTY_LINK';
END;
/

BEGIN
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (41 /*chain.filter_pkg.FILTER_TYPE_AUDITS*/, 7 /*csr.audit_report_pkg.AGG_TYPE_COUNT_CLOSED_ISSUES*/, 'Number of closed actions');

	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (42 /*chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES*/, 7 /*csr.non_compliance_report_pkg.AGG_TYPE_COUNT_CLOSED_ISSUES*/, 'Number of closed actions');
END;
/

-- New table for the specific FTP protocols
CREATE TABLE csr.ftp_protocol (
	PROTOCOL_ID				NUMBER(10) NOT NULL,
	LABEL					VARCHAR(128),
	CONSTRAINT pk_ftp_protocol PRIMARY KEY (protocol_id)
);
INSERT INTO csr.ftp_protocol (protocol_id, label) VALUES (0, 'FTP');
INSERT INTO csr.ftp_protocol (protocol_id, label) VALUES (1, 'FTPS');
INSERT INTO csr.ftp_protocol (protocol_id, label) VALUES (2, 'SFTP');

-- Make FTP profiles specify an FTP protocol, rather than a cms_imp_protocol
ALTER TABLE csr.ftp_profile
ADD ftp_protocol_id NUMBER(10);

ALTER TABLE csr.ftp_profile
ADD CONSTRAINT fk_ftp_protocol_id FOREIGN KEY (ftp_protocol_id) REFERENCES csr.ftp_protocol(protocol_id);

-- Move across existing settings
UPDATE csr.ftp_profile fp
   SET fp.ftp_protocol_id = (
			SELECT fp2.cms_imp_protocol_id
			  FROM csr.ftp_profile fp2
			 WHERE fp.ftp_profile_id = fp2.ftp_profile_id);

ALTER TABLE csr.ftp_profile MODIFY ftp_protocol_id NOT NULL;

-- Drop the old column
ALTER TABLE csr.ftp_profile
DROP COLUMN cms_imp_protocol_id;

-- Move the payload path to the class so the profile can be used for multiple jobs on the site
ALTER TABLE csr.automated_export_class
ADD payload_path VARCHAR2(1024);

UPDATE csr.automated_export_class aec
   SET aec.payload_path = (
		SELECT payload_path 
		  FROM csr.ftp_profile fp 
		 WHERE fp.ftp_profile_id = aec.ftp_profile_id);

ALTER TABLE csr.ftp_profile
DROP COLUMN payload_path;

-- Create FTP profiles from cms_imp jobs so that we can move it across to using profiles
ALTER TABLE csr.cms_imp_class_step
ADD ftp_profile_id NUMBER(10);

ALTER TABLE csr.cms_imp_class_step
ADD CONSTRAINT FK_cms_imp_step_ftp_prof FOREIGN KEY (app_sid, ftp_profile_id) REFERENCES csr.ftp_profile(app_sid, ftp_profile_id);

DECLARE
		v_seq_start INTEGER;
BEGIN
	SELECT NVL(MAX(ftp_profile_id) + 1, 1)
	  INTO v_seq_start
	  FROM csr.ftp_profile;

	EXECUTE IMMEDIATE 'Create sequence csr.ftp_profile_id_seq
						start with ' || v_seq_start || ' increment by 1 NOMINVALUE NOMAXVALUE CACHE 20 NOORDER';
END;
/

DECLARE
	v_ftp_profile_id	NUMBER;
BEGIN
	FOR r IN (
		SELECT cic.app_sid, cics.cms_imp_class_sid, step_number, cms_imp_protocol_id, ftp_url, ftp_secure_creds, ftp_fingerprint, ftp_username, ftp_password, ftp_port_number,
			   CASE step_number WHEN 1 THEN cic.label ELSE cic.label||' ('||step_number||')' END profile_name
		  FROM csr.cms_imp_class_step cics
		  JOIN csr.cms_imp_class cic ON cics.cms_imp_class_sid = cic.cms_imp_class_sid
		 WHERE cms_imp_protocol_id IN (0, 1, 2)
		   AND cics.ftp_profile_id IS NULL
		   AND cics.ftp_url IS NOT NULL
	)
	LOOP
		SELECT csr.ftp_profile_id_seq.NEXTVAL
		  INTO v_ftp_profile_id
		  FROM dual;
			
		-- Create the new profile
		INSERT INTO csr.ftp_profile
			(app_sid, ftp_profile_id, label, host_name, secure_credentials, fingerprint, username, password, port_number, ftp_protocol_id)
		VALUES
			(r.app_sid, v_ftp_profile_id, r.profile_name, r.ftp_url, r.ftp_secure_creds, r.ftp_fingerprint, r.ftp_username, r.ftp_password, r.ftp_port_number, r.cms_imp_protocol_id);
		
		-- Update the record
		UPDATE csr.cms_imp_class_step
		   SET ftp_profile_id 		= v_ftp_profile_id
		 WHERE cms_imp_class_sid 	= r.cms_imp_class_sid
		   AND step_number			= r.step_number;
		
	END LOOP;
END;
/

--Add a constraint so that any step using FTP must have an FTP profile
ALTER TABLE csr.cms_imp_class_step
ADD CONSTRAINT ck_cms_imp_step_ftp_prof CHECK (cms_imp_protocol_id != 0 OR ftp_profile_id IS NOT NULL);

-- Update cms_imp_protocols to have a single FTP entry, with the FTP type defined by the ftp_protocol on the ftp_profile
-- This requires altering data;
--	 CURRENT ->	 NEW
-- 0 FTP		 ->	 FTP
-- 1 FTPS		->	 DB_BLOB
-- 2 SFTP		->	 LOCAL
-- 3 DB_BLOB ->	 not used
-- 4 LOCAL	 ->	 not used

-- So, 0 stays the same, 1 & 2 become 0. Then we can make 3s into 1s and 4s into 2s
UPDATE csr.cms_imp_class_step
   SET cms_imp_protocol_id = 0
 WHERE cms_imp_protocol_id IN (0, 1, 2);

UPDATE csr.cms_imp_class_step
   SET cms_imp_protocol_id = 1
 WHERE cms_imp_protocol_id = 3;
 
UPDATE csr.cms_imp_class_step
   SET cms_imp_protocol_id = 2
 WHERE cms_imp_protocol_id = 4;

-- Now update the protocol table
UPDATE csr.cms_imp_protocol
   SET label = 'DB_BLOB'
 WHERE cms_imp_protocol_id = 1;

UPDATE csr.cms_imp_protocol
   SET label = 'LOCAL'
 WHERE cms_imp_protocol_id = 2;
 
-- Rename cms_imp_protocol; crap name
ALTER TABLE csr.cms_imp_protocol RENAME TO import_protocol;
ALTER TABLE csr.import_protocol RENAME COLUMN cms_imp_protocol_id to import_protocol_id;


/* EXPORT PLUGINS */
CREATE TABLE csr.auto_exp_exporter_plugin (
	plugin_id			NUMBER NOT NULL,
	label				VARCHAR2(128) NOT NULL,
	exporter_assembly			  VARCHAR2(255) NOT NULL,
  outputter_assembly			VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_auto_exp_exporter_plugin_id PRIMARY KEY (plugin_id),
	CONSTRAINT uk_auto_exp_exporter_label UNIQUE (label),
	CONSTRAINT uk_auto_exp_exporter_assembly UNIQUE (exporter_assembly, outputter_assembly)	
);

INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
VALUES (1, 'Dataview - Dsv',   'Credit360.AutomatedExportImport.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.AutomatedExportImport.Export.Exporters.PeriodicData.CsvOutputter');
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
VALUES (2, 'Dataview - Excel', 'Credit360.AutomatedExportImport.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.AutomatedExportImport.Export.Exporters.PeriodicData.ExcelOutputter');
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
VALUES (3, 'Dataview - XML',   'Credit360.AutomatedExportImport.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.AutomatedExportImport.Export.Exporters.PeriodicData.XmlOutputter');
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
VALUES (4, 'Nestle - Dsv',   'Credit360.AutomatedExportImport.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.AutomatedExportImport.Export.Exporters.PeriodicData.NestleDsvOutputter');


ALTER TABLE csr.automated_export_class
ADD exporter_plugin_id NUMBER NOT NULL;

ALTER TABLE csr.automated_export_class
ADD CONSTRAINT fk_auto_exp_cls_exp_plugin FOREIGN KEY (exporter_plugin_id) REFERENCES csr.auto_exp_exporter_plugin(plugin_id);

/* FILE WRITER PLUGINS */
CREATE TABLE csr.auto_exp_file_writer_plugin (
	plugin_id				NUMBER NOT NULL,
	label					VARCHAR2(128) NOT NULL,
	assembly				VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_auto_exp_file_wri_plugin_id PRIMARY KEY (plugin_id),
	CONSTRAINT uk_auto_exp_file_wri_label UNIQUE (label),
	CONSTRAINT uk_auto_exp_file_wri_assembly UNIQUE (assembly)	
);

INSERT INTO csr.auto_exp_file_writer_plugin (plugin_id, label, assembly)
VALUES (1, 'FTP', 'Credit360.AutomatedExportImport.Export.FileWrite.FtpWriter');
INSERT INTO csr.auto_exp_file_writer_plugin (plugin_id, label, assembly)
VALUES (2, 'Document library', 'Credit360.AutomatedExportImport.Export.FileWrite.DocLibWriter');
INSERT INTO csr.auto_exp_file_writer_plugin (plugin_id, label, assembly)
VALUES (3, 'Email document', 'Credit360.AutomatedExportImport.Export.FileWrite.EmailDocWriter');
INSERT INTO csr.auto_exp_file_writer_plugin (plugin_id, label, assembly)
VALUES (4, 'Email (link)', 'Credit360.AutomatedExportImport.Export.FileWrite.EmailLinkWriter');
INSERT INTO csr.auto_exp_file_writer_plugin (plugin_id, label, assembly)
VALUES (5, 'Manual download', 'Credit360.AutomatedExportImport.Export.FileWrite.ManualDownloadWriter');
INSERT INTO csr.auto_exp_file_writer_plugin (plugin_id, label, assembly)
VALUES (6, 'Save to DB', 'Credit360.AutomatedExportImport.Export.FileWrite.DbWriter');

ALTER TABLE csr.automated_export_class
ADD file_writer_plugin_id NUMBER NOT NULL;
ALTER TABLE csr.automated_export_class
ADD CONSTRAINT fk_auto_exp_cls_filewri_plugin FOREIGN KEY (file_writer_plugin_id) REFERENCES CSR.auto_exp_file_writer_plugin(plugin_id);

ALTER TABLE csr.automated_export_class 
DROP COLUMN export_file_format;
ALTER TABLE csr.automated_export_class 
DROP COLUMN export_type;
ALTER TABLE csr.automated_export_class 
DROP COLUMN db_data_exporter_function;
ALTER TABLE csr.automated_export_class 
DROP COLUMN data_exporter_class;
ALTER TABLE csr.automated_export_class
DROP CONSTRAINT fk_automated_export_class;
ALTER TABLE csr.automated_export_class
DROP COLUMN ftp_profile_id;

ALTER TABLE csr.automated_export_class
ADD include_headings NUMBER(1) DEFAULT 1 NOT NULL;
ALTER TABLE csr.automated_export_class
ADD CONSTRAINT ck_include_headings CHECK (include_headings IN (0, 1));
ALTER TABLE csr.automated_export_class
ADD output_empty_as VARCHAR2(16);
ALTER TABLE csr.automated_export_class
ADD file_mask_date_format VARCHAR2(128);

---------------
-- MESSAGING
---------------
-- Unify the messaging framework between imports and exports. The basic idea here is to share the messaging framework between the two as the messaging is the same

-- Convert the current imports framework into a generic one, by renaming and removing the import instance id, etc

CREATE TABLE csr.auto_import_message_map (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	import_instance_id				NUMBER(10) NOT NULL,
	import_instance_step_id			NUMBER(10), -- Can be nullable so you can write messages against the instance itself
	message_id						NUMBER(10) NOT NULL,
	CONSTRAINT pk_auto_import_mes_map PRIMARY KEY (app_sid, message_id)
);

CREATE TABLE csr.auto_export_message_map (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	export_instance_id				NUMBER(10) NOT NULL,
	message_id						NUMBER(10) NOT NULL,
	CONSTRAINT pk_auto_export_mes_map PRIMARY KEY (app_sid, message_id)
);

-- We now need to migrate both sets of existing messages into a single table, containg msg_id, message, severity. The import table is most appropriate
-- for this so we'll move that table in this direction and then push the export messages across afterwards and then drop it.
-- Create map entries for import messages
INSERT INTO csr.auto_import_message_map (app_sid, import_instance_id, import_instance_step_id, message_id)
	SELECT s.app_sid, s.cms_imp_instance_id, m.cms_imp_instance_step_id, m.cms_imp_instance_step_msg_id
	  FROM csr.cms_imp_instance_step_msg m
	  JOIN csr.cms_imp_instance_step s ON m.cms_imp_instance_step_id = s.cms_imp_instance_step_id;

-- Tidy up the table
ALTER TABLE csr.cms_imp_instance_step_msg
RENAME TO auto_impexp_instance_msg;

ALTER TABLE csr.auto_impexp_instance_msg
RENAME COLUMN cms_imp_instance_step_msg_id TO message_id;

ALTER TABLE csr.auto_impexp_instance_msg
DROP CONSTRAINT fk_cms_imp_inst_stp_msg;

ALTER TABLE csr.auto_impexp_instance_msg
DROP COLUMN cms_imp_instance_step_id;

DECLARE
		v_seq_start INTEGER;
BEGIN
	SELECT csr.cms_imp_instance_step_msg_seq.NEXTVAL
	  INTO v_seq_start
	  FROM dual;

	EXECUTE IMMEDIATE 'Create sequence csr.auto_impexp_instance_msg_seq
						start with ' || v_seq_start || ' increment by 1 NOMINVALUE NOMAXVALUE CACHE 20 NOORDER';
END;
/

DROP SEQUENCE csr.cms_imp_instance_step_msg_SEQ;

-- Add 'info' severity to messaging
ALTER TABLE csr.auto_impexp_instance_msg
DROP CONSTRAINT chk_cms_imp_inst_stp_sev;
ALTER TABLE csr.auto_impexp_instance_msg
ADD CONSTRAINT ck_auto_impexp_inst_msg_sev CHECK (severity IN ('W', 'X', 'I'));

DESC csr.auto_impexp_instance_msg;

-- We now need to move over the export messages.	We'll do this via a loop because we need to update the message ids and update the message
-- map. 

DECLARE
	v_new_msg_id	NUMBER;
BEGIN

	FOR r IN (
		SELECT app_sid, instance_message_id, automated_export_instance_id, message, CASE result WHEN 'Failure' THEN 'X' WHEN 'Success' THEN 'I' ELSE 'I' END severity
		  FROM csr.AUTOMATED_EXPORT_INST_MESSAGE
	)
	LOOP
	
		SELECT csr.auto_impexp_instance_msg_seq.NEXTVAL
		  INTO v_new_msg_id
		  FROM DUAl;
		  
		--Insert the message
		INSERT INTO csr.auto_impexp_instance_msg (app_sid, message_id, message, severity)
		VALUES (r.app_sid, v_new_msg_id, r.message, r.severity);
		--Insert into the message map
		INSERT INTO csr.auto_export_message_map (app_sid, export_instance_id, message_id)
		VALUES (r.app_sid, r.automated_export_instance_id, v_new_msg_id); 
		
	
	END LOOP;
END;
/

DROP TABLE csr.automated_export_inst_message;



-- Update the import plugins; THe assemblies have moved

UPDATE csr.cms_imp_class_step
   SET plugin = REPLACE(plugin, '.CmsDataImport.', '.AutomatedExportImport.Import.')
 WHERE plugin IS NOT NULL;
 
UPDATE csr.cms_imp_class
   SET import_plugin = REPLACE(import_plugin, '.CmsDataImport.', '.AutomatedExportImport.Import.')
 WHERE import_plugin IS NOT NULL;
 
 
/* Setting specific tables */
/* DATA RETRIEVAL */
/* Dataview */
CREATE TABLE csr.auto_exp_retrieval_dataview (
	app_sid								NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	auto_exp_retrieval_dataview_id		NUMBER(10) NOT NULL,
	dataview_sid						NUMBER(10) NOT NULL,
	ignore_null_values					NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT pk_auto_exp_retrieval_dataview PRIMARY KEY (app_sid, auto_exp_retrieval_dataview_id),
	CONSTRAINT fk_auto_exp_rtrvl_dview_sid FOREIGN KEY (app_sid, dataview_sid) REFERENCES csr.dataview(app_sid, dataview_sid),
	CONSTRAINT ck_auto_exp_rtrvl_ignore_na CHECK (ignore_null_values IN (0, 1))
);

CREATE SEQUENCE csr.auto_exp_rtrvl_dataview_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20;
	
ALTER TABLE csr.automated_export_class
ADD auto_exp_retrieval_dataview_id NUMBER(10);

/* FILE CREATION */
/* CSV */

CREATE TABLE csr.auto_exp_imp_dsv_delimiters (
	delimiter_id				NUMBER(10) NOT NULL,
	label						VARCHAR2(32),
	CONSTRAINT pk_auto_exp_imp_dsv_delim PRIMARY KEY (delimiter_id),
	CONSTRAINT uk_auto_exp_imp_dsv_delim UNIQUE (label)
);
INSERT INTO csr.auto_exp_imp_dsv_delimiters (delimiter_id, label) VALUES (0, 'Comma');
INSERT INTO csr.auto_exp_imp_dsv_delimiters (delimiter_id, label) VALUES (1, 'Pipe');
INSERT INTO csr.auto_exp_imp_dsv_delimiters (delimiter_id, label) VALUES (2, 'Tab');

CREATE TABLE csr.auto_exp_filecreate_dsv (
	app_sid								NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	auto_exp_filecreate_dsv_id			NUMBER(10) NOT NULL,
	delimiter_id						NUMBER(10) NOT NULL,
	quotes_as_literals					NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT pk_auto_exp_filecreate_dsv PRIMARY KEY (app_sid, auto_exp_filecreate_dsv_id),
	CONSTRAINT fk_auto_exp_delimiter FOREIGN KEY (delimiter_id) REFERENCES csr.auto_exp_imp_dsv_delimiters(delimiter_id),
	CONSTRAINT ck_auto_exp_filecre_quotes CHECK (quotes_as_literals IN (0, 1))
);

CREATE SEQUENCE csr.auto_exp_filecre_dsv_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20;
	
ALTER TABLE csr.automated_export_class
ADD auto_exp_filecre_dsv_id NUMBER(10);

/* FILE WRITING */
/* FTP */
CREATE TABLE csr.auto_exp_filewrite_ftp (
	app_sid								NUMBER(10) DEFAULT SYS_CONTEXT('security', 'app') NOT NULL,
	auto_exp_filewrite_ftp_id			NUMBER(10) NOT NULL,
	ftp_profile_id						NUMBER(10) NOT NULL,
	output_path							VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_auto_exp_filewrite_ftp PRIMARY KEY (app_sid, auto_exp_filewrite_ftp_id),
	CONSTRAINT fk_auto_exp_filewri_ftp_prof FOREIGN KEY (app_sid, ftp_profile_id) REFERENCES csr.ftp_profile(app_sid, ftp_profile_id)
);

CREATE SEQUENCE csr.auto_exp_filecre_ftp_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20;

ALTER TABLE csr.automated_export_class
ADD auto_exp_filewri_ftp_id NUMBER(10);

ALTER TABLE csr.automated_export_class
ADD CONSTRAINT ck_auto_exp_cls_ftp_id CHECK (file_writer_plugin_id != 1 OR auto_exp_filewri_ftp_id IS NOT NULL);

ALTER TABLE csr.automated_export_class
ADD CONSTRAINT fk_auto_exp_cls_ftp_id FOREIGN KEY (app_sid, auto_exp_filewri_ftp_id) REFERENCES csr.auto_exp_filewrite_ftp(app_sid, auto_exp_filewrite_ftp_id);

/* PERIOD SPAN PATTERNS */

CREATE TABLE csr.period_span_pattern_type (
	period_span_pattern_type_id				NUMBER(10) NOT NULL,
	label									VARCHAR2(128) NOT NULL,
	CONSTRAINT pk_period_span_pattern_type PRIMARY KEY (period_span_pattern_type_id),
	CONSTRAINT uk_period_span_pattern_label UNIQUE (label)
);

INSERT INTO csr.period_span_pattern_type (period_span_pattern_type_id, label)
VALUES (0, 'Fixed');
INSERT INTO csr.period_span_pattern_type (period_span_pattern_type_id, label)
VALUES (1, 'Fixed to now');
INSERT INTO csr.period_span_pattern_type (period_span_pattern_type_id, label)
VALUES (2, 'Rolling to now');
INSERT INTO csr.period_span_pattern_type (period_span_pattern_type_id, label)
VALUES (3, 'Offset to now');

CREATE TABLE csr.period_span_pattern (
	app_sid									NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	period_span_pattern_id					NUMBER(10) NOT NULL,
	period_span_pattern_type_id				NUMBER(10) NOT NULL,
	period_set_id							NUMBER(10) NOT NULL,
	period_interval_id						NUMBER(10) NOT NULL,
	date_from								DATE,
	date_to									DATE,
	periods_offset_from_now					NUMBER(2) DEFAULT 0 NOT NULL,
	number_rolling_periods					NUMBER(2) DEFAULT 0 NOT NULL,
	period_in_year							NUMBER(2) DEFAULT 0 NOT NULL,
	year_offset								NUMBER(2) DEFAULT 0 NOT NULL,
	CONSTRAINT pk_period_span_pattern PRIMARY KEY (app_sid, period_span_pattern_id),
	CONSTRAINT fk_prd_span_ptrn_type FOREIGN KEY (period_span_pattern_type_id) REFERENCES csr.period_span_pattern_type(period_span_pattern_type_id),
	CONSTRAINT fk_prd_span_ptrn_prd_set FOREIGN KEY (app_sid, period_set_id) REFERENCES csr.period_set(app_sid, period_set_id),
	CONSTRAINT fk_prd_span_ptrn_prd_int FOREIGN KEY (app_sid, period_set_id, period_interval_id) REFERENCES csr.period_interval(app_sid, period_set_id, period_interval_id)
);

CREATE SEQUENCE csr.period_span_pattern_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20;

ALTER TABLE csr.automated_export_class
ADD period_span_pattern_id NUMBER(10) NOT NULL;
ALTER TABLE csr.automated_export_class
ADD CONSTRAINT fk_auto_exp_cl_per_span_pat_id FOREIGN KEY (app_sid, period_span_pattern_id) REFERENCES csr.period_span_pattern(app_sid, period_span_pattern_id);

INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
VALUES (53, 'Automated exports', 'EnableAutomatedExport', 'Enables the automated export framework.', 0);

/* 
Remove obsolete 'Check conditional indicators on delegation import' capability from:
abinbev.credit360.com
centrica-epr-test.credit360.com
centrica.credit360.com
sabmiller.credit360.com
cewe.credit360.com
aegon.credit360.com
sabmillersam.credit360.com
*/
DELETE FROM security.securable_object 
 WHERE class_id = (SELECT class_id FROM security.securable_object_class WHERE class_name = 'CSRCapability') AND
       name = 'Check conditional indicators on delegation import';

DELETE FROM csr.capability 
 WHERE NAME='Check conditional indicators on delegation import';

create table aspen2.profile
(
	profile_id						number(10) not null,
	dtm								date not null,
	app_sid							number(10) not null,
	url								varchar2(4000) not null,
	elapsed_ms						number(10) not null,
	constraint pk_profile primary key (profile_id)
);

create sequence aspen2.profile_id_seq;

create table aspen2.profile_step
(
	profile_id						number(10) not null,
	profile_step_id					number(10) not null,
	parent_step_id					number(10),
	depth							number(10) not null,
	step							varchar2(4000) not null,
	elapsed_ms						number(10) not null,
	constraint pk_profile_step primary key (profile_id, profile_step_id),
	constraint fk_profile_step_parent_id foreign key (profile_id, parent_step_id)
	references aspen2.profile_step (profile_id, profile_step_id),
	constraint fk_profile_step_profile foreign key (profile_id)
	references aspen2.profile (profile_id) on delete cascade
);

create or replace package aspen2.profile_pkg as end;
/

grant execute on aspen2.profile_pkg to web_user;

CREATE TABLE CSR.SHEET_CHANGE_LOG (
    APP_SID      NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SHEET_ID	 NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_CHANGE_LOG PRIMARY KEY (APP_SID, SHEET_ID),
    CONSTRAINT FK_SHEET_CHANGE_LOG_SHEET FOREIGN KEY (APP_SID, SHEET_ID)
    REFERENCES CSR.SHEET (APP_SID, SHEET_ID)
);

INSERT INTO CSR.BATCH_JOB_TYPE (BATCH_JOB_TYPE_ID, DESCRIPTION, PLUGIN_NAME, ONE_AT_A_TIME)
VALUES (18, 'Sheet completeness calculation', 'sheet-completeness', 1);

CREATE TABLE CSR.SHEET_COMPLETENESS_JOB (
    APP_SID      	NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    BATCH_JOB_ID    NUMBER(10, 0)    NOT NULL,
    SHEET_ID	 	NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_SHEET_COMPLETENESS_JOB PRIMARY KEY (APP_SID, BATCH_JOB_ID, SHEET_ID),
    CONSTRAINT FK_SHEET_COMPLET_JOB_BTCH_JOB FOREIGN KEY (APP_SID, BATCH_JOB_ID)
    REFERENCES CSR.BATCH_JOB (APP_SID, BATCH_JOB_ID),
    CONSTRAINT FK_SHEET_COMPLET_JOB_SHEET FOREIGN KEY (APP_SID, SHEET_ID)
    REFERENCES CSR.SHEET (APP_SID, SHEET_ID)
);
CREATE INDEX CSR.IX_SHEET_COMPLETE_JOB_SHEET ON CSR.SHEET_COMPLETENESS_JOB (APP_SID, SHEET_ID);

DECLARE
    job BINARY_INTEGER;
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.QueueSheetCompletenessJobs',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'csr.sheet_pkg.QueueCompletenessJobs;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=SECONDLY;INTERVAL=120',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Scan sheet change logs and produce sheet completeness batch jobs');
END;
/

UPDATE csr.plugin 
   SET js_class = 'Chain.ManageCompany.SupplierListTab',
       js_include = '/csr/site/chain/managecompany/controls/SupplierListTab.js'
 WHERE js_class = 'Chain.ManageCompany.SupplierList';

 CREATE OR REPLACE PROCEDURE chain.temp_RegisterCapability (
	in_capability_type			IN  NUMBER,
	in_capability				IN  VARCHAR2,
	in_perm_type				IN  NUMBER,
	in_is_supplier				IN  NUMBER
)
AS
	v_count						NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;

	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND (
				(capability_type_id = 0 /*chain_pkg.CT_COMMON*/ AND (in_capability_type = 1 /*chain_pkg.CT_COMPANY*/ OR in_capability_type = 2 /*chain_pkg.CT_SUPPLIERS*/))
			 OR (in_capability_type = 0 /*chain_pkg.CT_COMMON*/ AND (capability_type_id = 1 /*chain_pkg.CT_COMPANY*/ OR capability_type_id = 2 /*chain_pkg.CT_SUPPLIERS*/))
		   );

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;

	INSERT INTO capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type, in_is_supplier);

END;
/
-- New chain capabilities
BEGIN
	chain.temp_RegisterCapability(0 /*chain.chain_pkg.CT_COMMON*/, 'Create relationship with supplier' /*chain.chain_pkg.CREATE_RELATIONSHIP*/, 1 /*chain.chain_pkg.BOOLEAN_PERMISSION*/, 1 /*chain.chain_pkg.IS_SUPPLIER_CAPABILITY*/);
END;
/

DROP PROCEDURE chain.temp_RegisterCapability;

CREATE INDEX CSR.IX_QAL_TEMP_RC19 ON CSR.QS_ANSWER_LOG
(APP_SID, SURVEY_RESPONSE_ID, QUESTION_ID, SET_DTM, SET_BY_USER_SID, XXX_PARAM_3, SUBMISSION_ID);

CREATE INDEX CSR.IX_QSR_TEMP_RC19 ON CSR.QUICK_SURVEY_RESPONSE
(APP_SID, SURVEY_SID, SURVEY_VERSION, SURVEY_RESPONSE_ID);

BEGIN
	--deal with most questions
	update csr.qs_answer_log
	set log_item = xxx_param_3
	where (app_sid, survey_response_id, question_id) in (
		select qsq.app_sid, qsa.survey_response_id, qsq.question_id
		from CSR.quick_survey_question qsq
		join csr.quick_survey_answer qsa on qsq.app_sid = qsa.app_sid and qsq.question_id = qsa.question_id
		where qsq.question_type in ('note','rtquestion','richtext','custom','number','slider')
	)
	and xxx_param_3 is not null;

	--deal with dates
	update csr.qs_answer_log
	set log_item =  to_date('18991230','yyyyMMdd') + cast(xxx_param_3 as number)
	where (app_sid, survey_response_id, question_id) in (
		select qsq.app_sid, qsa.survey_response_id, qsq.question_id
		from CSR.quick_survey_question qsq
		join csr.quick_survey_answer qsa on qsq.app_sid = qsa.app_sid and qsq.question_id = qsa.question_id
		where qsq.question_type in ('date')
	)
	and xxx_param_3 is not null;

	--partly deal with radio buttons
	update csr.qs_answer_log
	set log_item = 'Other: ' || xxx_param_3
	where (app_sid, survey_response_id, question_id) in (
		select qsq.app_sid, qsa.survey_response_id, qsq.question_id
		from CSR.quick_survey_question qsq
		join csr.quick_survey_answer qsa on qsq.app_sid = qsa.app_sid and qsq.question_id = qsa.question_id
		where qsq.question_type in ('radio')
	)
	and xxx_param_3 is not null;
	
	--partly deal with matrixes
	--matrixes step 1: insert missing answers
	--might be long-running
	insert into csr.quick_survey_answer (app_sid, survey_response_id, question_id, log_item, version_stamp, submission_id, survey_version)
	select c.app_sid, c.survey_response_id, c.checkboxgroup_question_id, c.new_param_3, c.version_stamp, c.submission_id, c.survey_version
	from (
		select qal.app_sid, qal.survey_response_id, qsq.parent_id checkboxgroup_question_id, 
			'?' new_param_3, -1 version_stamp, submission_id, qsr.survey_version
		from csr.qs_answer_log qal
		join csr.quick_survey_question qsq on qal.app_sid = qsq.app_sid and qal.question_id = qsq.question_id
		join csr.quick_survey_response qsr on qsq.app_sid = qsr.app_sid and qsq.survey_sid = qsr.survey_sid and qal.survey_response_id = qsr.survey_response_id and qsq.survey_version = qsr.survey_version
		where qsq.question_type in ('radiorow') --to merge into matrix
		group by qal.app_sid, qal.survey_response_id, qsq.parent_id, submission_id, qsr.survey_version
	) c
	left join csr.quick_survey_answer a
		 on a.app_sid = c.app_sid
		and a.survey_response_id = c.survey_response_id
		and a.question_id = c.checkboxgroup_question_id
		and a.submission_id = c.submission_id
		and a.survey_version = c.survey_version
	where a.app_sid is null;

	--matrixes step 2: upsert qs_answer_log from child questions
	--might be long-running
	merge into csr.qs_answer_log a
	using (
		select qal.app_sid, qal.survey_response_id, qsq.parent_id checkboxgroup_question_id,
			trunc(qal.set_dtm, 'MI') + trunc(to_char(qal.set_dtm, 'ss')/4)*4/(24 * 60 * 60) new_set_date,
			'?' new_param_3,
			submission_id, set_by_user_sid
		from csr.qs_answer_log qal
		join csr.quick_survey_question qsq on qal.app_sid = qsq.app_sid and qal.question_id = qsq.question_id
		join csr.quick_survey_response qsr on qsq.app_sid = qsr.app_sid and qsq.survey_sid = qsr.survey_sid and qal.survey_response_id = qsr.survey_response_id and qsq.survey_version = qsr.survey_version
		where qsq.question_type in ('radiorow') --to merge into matrix
		group by qal.app_sid, qal.survey_response_id, qsq.parent_id, trunc(qal.set_dtm, 'MI') + trunc(to_char(qal.set_dtm, 'ss')/4)*4/(24 * 60 * 60), submission_id, set_by_user_sid
	) c on (a.app_sid = c.app_sid
	   and a.survey_response_id = c.survey_response_id
	   and a.question_id = c.checkboxgroup_question_id
	   and trunc(a.set_dtm, 'MI') + trunc(to_char(a.set_dtm, 'ss')/4)*4/(24 * 60 * 60) = c.new_set_date)
	when matched then
		update
		   set a.log_item = c.new_param_3
	when not matched then
		insert (a.app_sid, a.qs_answer_log_id, a.survey_response_id, a.question_id, a.version_stamp, a.submission_id, a.set_by_user_sid, a.set_dtm, a.log_item)
		values (c.app_sid, csr.qs_answer_log_id_seq.NEXTVAL, c.survey_response_id, c.checkboxgroup_question_id, 0, c.submission_id, c.set_by_user_sid, c.new_set_date, c.new_param_3)
	;

	--deal with checkboxes
	--checkboxes part 1: insert missing answers
	--might be long-running
	insert into csr.quick_survey_answer (app_sid, survey_response_id, question_id, log_item, version_stamp, submission_id, survey_version)
	select c.app_sid, c.survey_response_id, c.checkboxgroup_question_id, c.new_param_3, c.version_stamp, c.submission_id, c.survey_version
	from (
		select qal.app_sid, qal.survey_response_id, qsq.parent_id checkboxgroup_question_id, 
			replace(csr.stragg2(
				case
					when xxx_param_3 is null or xxx_param_3 = '0' then ''
					when xxx_param_3 = '1' then qsq.label || chr(10)
					else qsq.label || ': ' || xxx_param_3 || chr(10)
				end
			),chr(10)||',',chr(10)) new_param_3,
			-1 version_stamp, submission_id, qsr.survey_version
		from csr.qs_answer_log qal
		join csr.quick_survey_question qsq on qal.app_sid = qsq.app_sid and qal.question_id = qsq.question_id
		join csr.quick_survey_response qsr on qsq.app_sid = qsr.app_sid and qsq.survey_sid = qsr.survey_sid and qal.survey_response_id = qsr.survey_response_id and qsq.survey_version = qsr.survey_version
		where qsq.question_type in ('checkbox') --to merge into checkboxgroup
		group by qal.app_sid, qal.survey_response_id, qsq.parent_id, submission_id, qsr.survey_version
	) c
	left join csr.quick_survey_answer a
		 on a.app_sid = c.app_sid
		and a.survey_response_id = c.survey_response_id
		and a.question_id = c.checkboxgroup_question_id
		and a.submission_id = c.submission_id
		and a.survey_version = c.survey_version
	where a.app_sid is null;

	--might be long-running
	--checkboxes part 2: upsert qs_answer_log
	merge into csr.qs_answer_log a
	using (
		select qal.app_sid, qal.survey_response_id, qsq.parent_id checkboxgroup_question_id,
			trunc(qal.set_dtm, 'MI') + trunc(to_char(qal.set_dtm, 'ss')/4)*4/(24 * 60 * 60) new_set_date,
			replace(csr.stragg2(
				case
					when xxx_param_3 is null or xxx_param_3 = '0' then ''
					when xxx_param_3 = '1' then qsq.label || chr(10)
					else qsq.label || ': ' || xxx_param_3 || chr(10)
				end
			),chr(10)||',',chr(10)) new_param_3,
			submission_id, set_by_user_sid
		from csr.qs_answer_log qal
		join csr.quick_survey_question qsq on qal.app_sid = qsq.app_sid and qal.question_id = qsq.question_id
		join csr.quick_survey_response qsr on qsq.app_sid = qsr.app_sid and qsq.survey_sid = qsr.survey_sid and qal.survey_response_id = qsr.survey_response_id and qsq.survey_version = qsr.survey_version
		where qsq.question_type in ('checkbox') --to merge into checkboxgroup
		group by qal.app_sid, qal.survey_response_id, qsq.parent_id, trunc(qal.set_dtm, 'MI') + trunc(to_char(qal.set_dtm, 'ss')/4)*4/(24 * 60 * 60), submission_id, set_by_user_sid
	) c on (a.app_sid = c.app_sid
	   and a.survey_response_id = c.survey_response_id
	   and a.question_id = c.checkboxgroup_question_id
	   and trunc(a.set_dtm, 'MI') + trunc(to_char(a.set_dtm, 'ss')/4)*4/(24 * 60 * 60) = c.new_set_date)
	when matched then
		update
		   set a.log_item = c.new_param_3
	when not matched then
		insert (a.app_sid, a.qs_answer_log_id, a.survey_response_id, a.question_id, a.version_stamp, a.submission_id, a.set_by_user_sid, a.set_dtm, a.log_item)
		values (c.app_sid, csr.qs_answer_log_id_seq.NEXTVAL, c.survey_response_id, c.checkboxgroup_question_id, 0, c.submission_id, c.set_by_user_sid, c.new_set_date, c.new_param_3)
	;
END;
/

DROP INDEX CSR.IX_QAL_TEMP_RC19;
DROP INDEX CSR.IX_QSR_TEMP_RC19;

BEGIN
	BEGIN
		INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
			VALUES (19, 'audit', 'Change survey', 1, 0);

		INSERT INTO csr.flow_state_role_capability(app_sid, flow_state_rl_cap_id, flow_state_id, flow_capability_id,
												   role_sid, flow_involvement_type_id, permission_set, group_sid)
		SELECT app_sid, csr.flow_state_rl_cap_id_seq.NEXTVAL flow_state_rl_cap_id, flow_state_id, 19 flow_capability_id,
													role_sid, flow_involvement_type_id, 2 permission_set, group_sid
		FROM csr.flow_state_role_capability WHERE flow_capability_id = 1 AND permission_set = 3;
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;

	BEGIN
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
			 VALUES (NULL, csr.plugin_id_seq.nextval, 13, 'Survey List',  '/csr/site/audit/controls/SurveysTab.js', 'Audit.Controls.SurveysTab',
			         'Credit360.Audit.Plugins.SurveysTab', 'This tab shows a list of surveys against an audit.  It is intended for customers who have purchased the "multiple audit surveys" feature.');
	EXCEPTION WHEN dup_val_on_index THEN
		UPDATE csr.plugin
		   SET description = 'Survey List',
		   	   js_include = '/csr/site/audit/controls/SurveysTab.js',
			   cs_class = 'Credit360.Audit.Plugins.SurveysTab',
		   	   details = 'This tab shows a list of surveys against an audit.  It is intended for customers who have purchased the "multiple audit surveys" feature.'
		 WHERE plugin_type_id = 13
		   AND js_class = 'Audit.Controls.SurveysTab'
		   AND app_sid IS NULL;
	END;
END;
/

INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
VALUES (54, 'Multiple audit surveys', 'EnableMultipleAuditSurveys', 'Enables multiple audit surveys.  NOTE: This is not included in the standard licence for the Audits module; a separate license is required for this feature.', 1);

-- ** New package grants **

-- *** Packages ***
@..\indicator_pkg
@../initiative_pkg
@../initiative_report_pkg
@..\audit_report_pkg
@..\non_compliance_report_pkg
@..\chain\company_user_pkg
@../automated_export_import_pkg
@../enable_pkg
@../cms_data_imp_pkg
@../batch_job_pkg
@../csr_data_pkg
@../../../aspen2/db/profile_pkg
@../delegation_pkg
@../sheet_pkg
@..\chain\chain_pkg
@..\chain\company_pkg
@..\chain\company_type_pkg
@../quick_survey_pkg
@..\..\..\aspen2\cms\db\tab_pkg
@../audit_pkg
@../flow_pkg
@../schema_pkg
@..\feed_pkg
@..\property_report_pkg

@..\issue_body
@..\csrimp\imp_body
@..\feed_body
@../approval_dashboard_body
@../audit_body
@../audit_report_body
@../csr_app_body
@../flow_body
@../quick_survey_body
@../schema_body
@..\chain\company_user_body
@..\csr_user_body
@..\region_body
@..\supplier_body
@..\..\..\aspen2\cms\db\tab_body
@..\chain\company_body
@..\chain\company_type_body
@..\chain\company_filter_body
@..\chain\supplier_audit_body
@..\chain\type_capability_body
@..\chain\plugin_body
@..\plugin_body
@../csr_data_body
@../delegation_body
@../sheet_body
@../stored_calc_datasource_body
@../../../aspen2/db/profile_body
@../automated_export_import_body
@../cms_data_imp_body
@../enable_body
@../chain/filter_body
@..\non_compliance_report_body
@../initiative_body
@../initiative_report_body
@../property_report_body
@..\indicator_body

@update_tail
