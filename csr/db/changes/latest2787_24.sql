-- Please update version.sql too -- this keeps clean builds in sync
define version=2787
define minor_version=24
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

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- From C:\cvs\csr\db\create_views.sql
-- I have only added internal_audit_type_id
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
	 
-- In C:\cvs\csr\db\create_views.sql
-- this one is new
CREATE OR REPLACE VIEW csr.v$flow_capability AS
	SELECT NULL app_sid, flow_capability_id, flow_alert_class, description,
		   perm_type, default_permission_set, NULL lookup_key
	  FROM flow_capability
	 UNION
	SELECT app_sid, flow_capability_id, flow_alert_class, description,
		   perm_type, default_permission_set, lookup_key
	  FROM customer_flow_capability;

GRANT SELECT on csr.v$flow_capability TO CHAIN;

-- *** Data changes ***
-- RLS

-- Data
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

-- If the module ID needs changing here, please also chenage it in basedata.sql
INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
VALUES (54, 'Multiple audit surveys', 'EnableMultipleAuditSurveys', 'Enables multiple audit surveys.  NOTE: This is not included in the standard licence for the Audits module; a separate license is required for this feature.', 1);

-- ** New package grants **

-- *** Packages ***
@../audit_pkg
@../audit_report_pkg
@../flow_pkg
@../quick_survey_pkg
@../schema_pkg
@../csr_data_pkg

@../approval_dashboard_body
@../audit_body
@../audit_report_body
@../csr_app_body
@../flow_body
@../quick_survey_body
@../schema_body
@../csrimp/imp_body

@update_tail
