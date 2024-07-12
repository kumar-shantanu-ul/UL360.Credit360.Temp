-- Please update version.sql too -- this keeps clean builds in sync
define version=3370
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.non_compliance_type_flow_cap(
    app_sid                   NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    non_compliance_type_id    NUMBER(10, 0)    NOT NULL,
    flow_capability_id        NUMBER(10, 0)    NOT NULL,
    base_flow_capability_id   NUMBER(10 ,0)    NOT NULL,
    CONSTRAINT pk_non_compliance_typ_flow_cap PRIMARY KEY (app_sid, non_compliance_type_id, flow_capability_id),
    CONSTRAINT uk_nc_type_base_flow_cap UNIQUE (app_sid, non_compliance_type_id, base_flow_capability_id)
)
;

ALTER TABLE CSR.NON_COMPLIANCE_TYPE_FLOW_CAP ADD CONSTRAINT FK_NON_COMP_FC_NON_COMP_TYPE
    FOREIGN KEY (APP_SID, NON_COMPLIANCE_TYPE_ID)
    REFERENCES CSR.NON_COMPLIANCE_TYPE(APP_SID, NON_COMPLIANCE_TYPE_ID)
;

ALTER TABLE CSR.NON_COMPLIANCE_TYPE_FLOW_CAP ADD CONSTRAINT FK_NON_COMP_FC_CFC
    FOREIGN KEY (APP_SID, FLOW_CAPABILITY_ID)
    REFERENCES CSR.CUSTOMER_FLOW_CAPABILITY(APP_SID, FLOW_CAPABILITY_ID)
;

ALTER TABLE CSR.NON_COMPLIANCE_TYPE_FLOW_CAP ADD CONSTRAINT FK_NON_COMP_FC_FC
    FOREIGN KEY (BASE_FLOW_CAPABILITY_ID)
    REFERENCES CSR.FLOW_CAPABILITY(FLOW_CAPABILITY_ID)
;

CREATE INDEX CSR.IX_NON_COMP_FC_NON_COMP_TYPE ON CSR.NON_COMPLIANCE_TYPE_FLOW_CAP(APP_SID, NON_COMPLIANCE_TYPE_ID);
CREATE INDEX CSR.IX_NON_COMP_FC_CFC ON CSR.NON_COMPLIANCE_TYPE_FLOW_CAP(APP_SID, FLOW_CAPABILITY_ID);
CREATE INDEX CSR.IX_NON_COMP_FC_FC ON CSR.NON_COMPLIANCE_TYPE_FLOW_CAP(BASE_FLOW_CAPABILITY_ID);

ALTER TABLE csr.non_compliance_type RENAME COLUMN flow_capability_id TO xxx_flow_capability_id;

CREATE TABLE csrimp.non_compliance_type_flow_cap(
    csrimp_session_id         NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    non_compliance_type_id    NUMBER(10, 0)    NOT NULL,
    flow_capability_id        NUMBER(10, 0)    NOT NULL,
	base_flow_capability_id   NUMBER(10 ,0)    NOT NULL,
    CONSTRAINT pk_non_compliance_typ_flow_cap PRIMARY KEY (csrimp_session_id, non_compliance_type_id, flow_capability_id),
	CONSTRAINT uk_nc_type_base_flow_cap UNIQUE (csrimp_session_id, non_compliance_type_id, base_flow_capability_id),
    CONSTRAINT fk_non_com_typ_flow_cap_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
)
;

-- Alter tables

-- *** Grants ***
grant select,insert on csr.non_compliance_type_flow_cap to csrimp;

grant select,insert,update,delete on csrimp.non_compliance_type_flow_cap to tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_id NUMBER(10);
BEGIN
	INSERT INTO csr.flow_capability (flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
	VALUES (23, 'audit', 'Finding tags', 0, security.security_pkg.PERMISSION_READ);
		
	INSERT INTO csr.flow_state_role_capability
	(app_sid, flow_state_rl_cap_id, flow_capability_id, flow_involvement_type_id, flow_state_id, group_sid, permission_set, role_sid)
	SELECT app_sid, csr.flow_state_rl_cap_id_seq.NEXTVAL, 23 /*FLOW_CAP_AUDIT_NC_TAGS*/, flow_involvement_type_id, flow_state_id, group_sid, permission_set, role_sid
	  FROM csr.flow_state_role_capability
	 WHERE flow_capability_id = 3; -- FLOW_CAP_AUDIT_NON_COMPL	
 
	FOR r IN (
		SELECT app_sid, non_compliance_type_id, xxx_flow_capability_id flow_capability_id, label
		  FROM csr.non_compliance_type
		 WHERE xxx_flow_capability_id IS NOT NULL
	) LOOP  
		v_id := csr.customer_flow_cap_id_seq.NEXTVAL;
		
		INSERT INTO csr.customer_flow_capability (app_sid, flow_capability_id, flow_alert_class, description, perm_type, default_permission_set, is_system_managed) 
		VALUES (r.app_sid, v_id, 'audit', r.label || ' tags', 1, 0, 1);
		
		INSERT INTO csr.non_compliance_type_flow_cap (app_sid, non_compliance_type_id, flow_capability_id, base_flow_capability_id)
		VALUES (r.app_sid, r.non_compliance_type_id, r.flow_capability_id, 3); -- FLOW_CAP_AUDIT_NON_COMPL 

		INSERT INTO csr.non_compliance_type_flow_cap (app_sid, non_compliance_type_id, flow_capability_id, base_flow_capability_id)
		VALUES (r.app_sid, r.non_compliance_type_id, v_id, 23); -- FLOW_CAP_AUDIT_NC_TAGS
		
		INSERT INTO csr.flow_state_role_capability
		(app_sid, flow_state_rl_cap_id, flow_capability_id, flow_involvement_type_id, flow_state_id, group_sid, permission_set, role_sid)
		SELECT app_sid, csr.flow_state_rl_cap_id_seq.NEXTVAL, v_id, flow_involvement_type_id, flow_state_id, group_sid, permission_set, role_sid
		  FROM csr.flow_state_role_capability
		 WHERE flow_capability_id = r.flow_capability_id;	
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\audit_pkg
@..\csr_data_pkg
@..\schema_pkg

@..\audit_body
@..\enable_body
@..\flow_body
@..\non_compliance_report_body
@..\schema_body
@..\csrimp\imp_body

@update_tail
