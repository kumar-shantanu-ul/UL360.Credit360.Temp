--Please update version.sql too -- this keeps clean builds in sync
define version=2613
@update_header

CREATE TABLE csr.flow_state_audit_ind (
	app_sid							NUMBER(10) 			DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	ind_sid							NUMBER(10) 			NOT NULL,
	flow_state_id					NUMBER(10) 			NOT NULL,
	flow_state_audit_ind_type_id	NUMBER(10)			NOT NULL,
	internal_audit_type_id			NUMBER(10) 			NOT NULL,
	CONSTRAINT pk_flow_state_audit_ind PRIMARY KEY (app_sid, ind_sid)
);

CREATE TABLE csr.flow_state_audit_ind_type (
	flow_state_audit_ind_type_id	NUMBER(10)			NOT NULL,
	description						VARCHAR2(255)		NOT NULL,
	CONSTRAINT pk_flow_state_audit_ind_type PRIMARY KEY (flow_state_audit_ind_type_id)
);

	ALTER TABLE csr.flow_state_audit_ind
 ADD CONSTRAINT fk_fsai_ind FOREIGN KEY (app_sid, ind_sid)
	 REFERENCES csr.ind(app_sid, ind_sid);
	 
	ALTER TABLE csr.flow_state_audit_ind
 ADD CONSTRAINT fk_fsai_state FOREIGN KEY (app_sid, flow_state_id)
	 REFERENCES csr.flow_state(app_sid, flow_state_id);

	ALTER TABLE csr.flow_state_audit_ind
 ADD CONSTRAINT fk_fsai_audit FOREIGN KEY (app_sid, internal_audit_type_id)
	 REFERENCES csr.internal_audit_type(app_sid, internal_audit_type_id);

	ALTER TABLE csr.flow_state_audit_ind
 ADD CONSTRAINT fk_fsai_ind_type FOREIGN KEY (flow_state_audit_ind_type_id)
	 REFERENCES csr.flow_state_audit_ind_type(flow_state_audit_ind_type_id);
	 
	ALTER TABLE csr.flow_state_audit_ind
 ADD CONSTRAINT uk_flow_state_aud_ind_state_at UNIQUE (app_sid, flow_state_id, internal_audit_type_id, flow_state_audit_ind_type_id);

CREATE TABLE CSRIMP.FLOW_STATE_AUDIT_IND (
	CSRIMP_SESSION_ID 				NUMBER(10) 			DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	IND_SID							NUMBER(10) 			NOT NULL,
	FLOW_STATE_ID					NUMBER(10) 			NOT NULL,
	FLOW_STATE_AUDIT_IND_TYPE_ID	NUMBER(10)			NOT NULL,
	INTERNAL_AUDIT_TYPE_ID			NUMBER(10) 			NOT NULL,
	CONSTRAINT PK_FLOW_STATE_AUDIT_IND PRIMARY KEY (CSRIMP_SESSION_ID, IND_SID),
	CONSTRAINT FK_FLOW_STATE_AUDIT_IND_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.flow_state_audit_ind TO web_user;
GRANT INSERT ON csr.flow_state_audit_ind TO csrimp;

-- BASE DATA

INSERT INTO csr.flow_state_audit_ind_type (flow_state_audit_ind_type_id, description)
     VALUES (1, 'Audit workflow state count');
	 
INSERT INTO csr.flow_state_audit_ind_type (flow_state_audit_ind_type_id, description)
     VALUES (2, 'Audit workflow - time spent in state');

/*	 
 For existing audit flow indicators, we need to add records to csr.flow_state_audit_ind. We're still keeping flow_state.ind_sid
 for non-audit flows, and there's no point changing this value for the audit flow indicators we find here (this means the
 scrag job won't fail in between this data update and updating audit_pkg, and once audit_pkg is updated, flow_state.ind_sid
 will simply not get used for audit flows).
 
 Since the whole point of this change is that the indicators for the same flow state under two different audit types using 
 can't both link to flow_state.ind_sid, it may be difficult to tell which indicators need to link to which audit types and
 workflows. We can try to use lookup keys for this, but before doing this update it's worth making a note of which sites
 are affected and checking after the update to see if there are any sites that need to be handled manually. Probably we need
 to find sites that have indicators in an audits AIG that are linked to flow states where the join below (on lookup keys)
 doesn't match and create the link records manually.
*/ 
BEGIN
	security.user_pkg.logonadmin;
	
	INSERT INTO csr.flow_state_audit_ind (app_sid, ind_sid, flow_state_id, internal_audit_type_id, flow_state_audit_ind_type_id)
	SELECT f.app_sid, i.ind_sid, fs.flow_state_id, iat.internal_audit_type_id, 1
	  FROM csr.flow f
	  JOIN csr.flow_state fs ON fs.flow_sid = f.flow_sid AND fs.app_sid = f.app_sid
	  JOIN csr.internal_audit_type iat ON f.flow_sid = iat.flow_sid AND f.app_sid = iat.app_sid
	  JOIN csr.ind i ON i.lookup_key = 'IAT_' || iat.internal_audit_type_id || '_A_STATE_' || fs.lookup_key AND i.app_sid = iat.app_sid
	 WHERE f.flow_alert_class = 'audit';
END;
/

@..\flow_pkg
@..\flow_body
@..\audit_pkg
@..\audit_body
@..\aggregate_ind_pkg
@..\aggregate_ind_body
@..\supplier_body

@update_tail
