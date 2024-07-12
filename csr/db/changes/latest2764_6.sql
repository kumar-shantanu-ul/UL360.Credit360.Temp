-- Please update version.sql too -- this keeps clean builds in sync
define version=2764
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

CREATE SEQUENCE csr.flow_involvement_type_id_seq
    START WITH 10000
    INCREMENT BY 1
    MINVALUE 10000
    NOMAXVALUE
    CACHE 20
    NOORDER
;


CREATE SEQUENCE csr.audit_type_flw_inv_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE csr.flow_item_involvement (
	app_sid							NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	flow_involvement_type_id		NUMBER(10)	NOT NULL,
	flow_item_id					NUMBER(10)	NOT NULL,
	user_sid						NUMBER(10)	NOT NULL,
	CONSTRAINT chk_fii_fit CHECK (flow_involvement_type_id >= 10000)
);

CREATE TABLE csr.audit_type_flow_inv_type (
	app_sid							NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	audit_type_flow_inv_type_id		NUMBER(10)	NOT NULL,
	flow_involvement_type_id		NUMBER(10)	NOT NULL,
	internal_audit_type_id			NUMBER(10)	NOT NULL,
	min_users						NUMBER(10)	NOT NULL,
	max_users						NUMBER(10)	NULL,
	CONSTRAINT pk_audit_type_flow_inv_type PRIMARY KEY (app_sid, audit_type_flow_inv_type_id),
	CONSTRAINT uk_audit_type_flow_inv_type UNIQUE (app_sid, flow_involvement_type_id, internal_audit_type_id),
	CONSTRAINT chk_atfit_min_max CHECK ((0 = min_users AND (max_users IS NULL OR max_users > 0)) OR (0 < min_users AND (max_users IS NULL OR min_users <= max_users)))
);

CREATE TABLE CSRIMP.FLOW_INVOLVEMENT_TYPE
(
	CSRIMP_SESSION_ID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	FLOW_INVOLVEMENT_TYPE_ID		NUMBER(10) NOT NULL,
	FLOW_ALERT_CLASS				VARCHAR2(256) NOT NULL,
	LABEL							VARCHAR2(256) NOT NULL,
	CSS_CLASS						VARCHAR2(256) NOT NULL,
	CONSTRAINT PK_FLOW_INV_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, FLOW_INVOLVEMENT_TYPE_ID),
	CONSTRAINT FK_FLOW_INV_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID)
	REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.FLOW_ITEM_INVOLVEMENT
(
	CSRIMP_SESSION_ID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	FLOW_INVOLVEMENT_TYPE_ID		NUMBER(10) NOT NULL,
	FLOW_ITEM_ID					NUMBER(10) NOT NULL,
	USER_SID						NUMBER(10) NOT NULL,
	CONSTRAINT PK_FLOW_ITEM_INV PRIMARY KEY (CSRIMP_SESSION_ID, FLOW_INVOLVEMENT_TYPE_ID, FLOW_ITEM_ID, USER_SID),
	CONSTRAINT FK_FLOW_ITEM_INV_IS FOREIGN KEY (CSRIMP_SESSION_ID)
	REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.AUDIT_TYPE_FLOW_INV_TYPE
(
	CSRIMP_SESSION_ID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	AUDIT_TYPE_FLOW_INV_TYPE_ID		NUMBER(10) NOT NULL,
	FLOW_INVOLVEMENT_TYPE_ID		NUMBER(10) NOT NULL,
	INTERNAL_AUDIT_TYPE_ID			NUMBER(10) NOT NULL,
	MIN_USERS						NUMBER(10) NOT NULL,
	MAX_USERS						NUMBER(10),
	CONSTRAINT PK_ADT_T_FL_INV_T PRIMARY KEY (CSRIMP_SESSION_ID, AUDIT_TYPE_FLOW_INV_TYPE_ID),
	CONSTRAINT FK_ADT_T_FL_INV_T_IS FOREIGN KEY (CSRIMP_SESSION_ID)
	REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_FLOW_INVOLVEMENT_TYPE (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_FLOW_INVOLVEMENT_TYPE_ID	NUMBER(10)	NOT NULL,
	NEW_FLOW_INVOLVEMENT_TYPE_ID	NUMBER(10)	NOT NULL,
	CONSTRAINT PK_MAP_FLOW_INV_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_FLOW_INVOLVEMENT_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_FLOW_INV_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_FLOW_INVOLVEMENT_TYPE_ID) USING INDEX,
    CONSTRAINT FK_MAP_FLOW_INV_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_AUD_TP_FLOW_INV_TP (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_AUD_TP_FLOW_INV_TP_ID		NUMBER(10)	NOT NULL,
	NEW_AUD_TP_FLOW_INV_TP_ID		NUMBER(10)	NOT NULL,
	CONSTRAINT PK_MAP_AUD_TP_FLOW_INV_TP PRIMARY KEY (CSRIMP_SESSION_ID, OLD_AUD_TP_FLOW_INV_TP_ID) USING INDEX,
	CONSTRAINT UK_MAP_AUD_TP_FLOW_INV_TP UNIQUE (CSRIMP_SESSION_ID, NEW_AUD_TP_FLOW_INV_TP_ID) USING INDEX,
    CONSTRAINT FK_MAP_AUD_TP_FLOW_INV_TP_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);


-- Alter tables

-- csr.flow_involvement_type --
ALTER TABLE csr.flow_involvement_type
ADD app_sid NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NULL;

ALTER TABLE csr.flow_state_involvement
DROP CONSTRAINT fk_flow_state_inv_inv_id;

ALTER TABLE csr.flow_transition_alert_inv
DROP CONSTRAINT fk_flow_trans_alert_inv_inv;

ALTER TABLE csr.flow_involvement_type
DROP CONSTRAINT pk_flow_involvement_type DROP INDEX;

ALTER TABLE csr.flow_involvement_type
DROP CONSTRAINT fk_flow_involv_typ_alt_cls;

BEGIN
	security.user_pkg.logonadmin;
	FOR r IN (
		SELECT cfac.app_sid, cfac.flow_alert_class, fit.flow_involvement_type_id, fit.label, fit.css_class
		  FROM csr.customer_flow_alert_class cfac
		  JOIN csr.flow_involvement_type fit 
		    ON fit.app_sid IS NULL
		   AND fit.flow_alert_class = cfac.flow_alert_class
		   AND fit.flow_involvement_type_id < 10000
	)
	LOOP
		INSERT INTO csr.flow_involvement_type (app_sid, flow_involvement_type_id, flow_alert_class, label, css_class)
		VALUES (r.app_sid, r.flow_involvement_type_id, r.flow_alert_class, r.label, r.css_class);
	END LOOP;
	
	DELETE
	  FROM csr.flow_involvement_type
	 WHERE app_sid IS NULL;
END;
/

ALTER TABLE csr.flow_involvement_type
MODIFY app_sid NOT NULL;

ALTER TABLE csr.flow_involvement_type
ADD CONSTRAINT pk_flow_involvement_type PRIMARY KEY (app_sid, flow_involvement_type_id);

ALTER TABLE csr.flow_state_involvement
ADD CONSTRAINT fk_flow_state_inv_inv_id FOREIGN KEY (app_sid, flow_involvement_type_id)
REFERENCES csr.flow_involvement_type (app_sid, flow_involvement_type_id);

ALTER TABLE csr.flow_transition_alert_inv
ADD CONSTRAINT fk_flow_trans_alert_inv_inv FOREIGN KEY (app_sid, flow_involvement_type_id)
REFERENCES csr.flow_involvement_type (app_sid, flow_involvement_type_id);

ALTER TABLE csr.flow_involvement_type
ADD CONSTRAINT fk_flow_involv_typ_alt_cls FOREIGN KEY (app_sid, flow_alert_class)
REFERENCES csr.customer_flow_alert_class (app_sid, flow_alert_class);

-- Label should be unique within each app and flow type
ALTER TABLE csr.flow_involvement_type
ADD CONSTRAINT uk_label UNIQUE (app_sid, label, flow_alert_class);

-- csr.flow_item_involvement --

ALTER TABLE csr.flow_item_involvement
ADD CONSTRAINT fk_fii_flow_inv_type FOREIGN KEY (app_sid, flow_involvement_type_id)
REFERENCES csr.flow_involvement_type (app_sid, flow_involvement_type_id);

ALTER TABLE csr.flow_item_involvement
ADD CONSTRAINT fk_fii_flow_item FOREIGN KEY (app_sid, flow_item_id)
REFERENCES csr.flow_item (app_sid, flow_item_id);

ALTER TABLE csr.flow_item_involvement
ADD CONSTRAINT fk_fii_csr_user FOREIGN KEY (app_sid, user_sid)
REFERENCES csr.csr_user (app_sid, csr_user_sid);

-- csr.audit_type_flow_inv_type --

ALTER TABLE csr.audit_type_flow_inv_type
ADD CONSTRAINT fk_atfit_flow_inv_type FOREIGN KEY (app_sid, flow_involvement_type_id)
REFERENCES csr.flow_involvement_type (app_sid, flow_involvement_type_id);

ALTER TABLE csr.audit_type_flow_inv_type
ADD CONSTRAINT internal_audit_type_id FOREIGN KEY (app_sid, internal_audit_type_id)
REFERENCES csr.internal_audit_type (app_sid, internal_audit_type_id);

-- *** Grants ***

GRANT INSERT ON csr.flow_involvement_type TO chain;

GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.audit_type_flow_inv_type TO web_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.flow_item_involvement TO web_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.flow_involvement_type TO web_user;
GRANT INSERT ON csr.audit_type_flow_inv_type TO csrimp;
GRANT INSERT ON csr.flow_item_involvement TO csrimp;
GRANT INSERT ON csr.flow_involvement_type TO csrimp;
grant select on csr.audit_type_flw_inv_type_id_seq TO csrimp;
grant select on csr.flow_involvement_type_id_seq to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

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
	 WHERE ((fsrc.flow_involvement_type_id = 1 -- csr_data_pkg.FLOW_INV_TYPE_AUDITOR
	   AND (ia.auditor_user_sid = SYS_CONTEXT('SECURITY', 'SID')
		OR ia.auditor_user_sid IN (SELECT user_being_covered_sid FROM v$current_user_cover)))
		OR (ia.auditor_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND fsrc.flow_involvement_type_id = 2)	   -- csr_data_pkg.FLOW_INV_TYPE_AUDIT_COMPANY
	    OR finv.flow_involvement_type_id IS NOT NULL
		OR rrm.role_sid IS NOT NULL
		OR security.security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits'), 16) = 1) -- security.security_pkg.PERMISSION_TAKE_OWNERSHIP
	 GROUP BY ia.app_sid, ia.internal_audit_sid, fsrc.flow_capability_id;

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***

@..\flow_pkg
@..\flow_body
@..\audit_pkg
@..\audit_body
@..\csr_app_body
@..\schema_pkg
@..\schema_body
@..\csrimp\imp_body

@update_tail
