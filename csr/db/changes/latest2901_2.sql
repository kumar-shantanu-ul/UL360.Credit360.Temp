-- Please update version.sql too -- this keeps clean builds in sync
define version=2901
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.internal_audit_type_carry_fwd (
	app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	from_internal_audit_type_id		NUMBER(10, 0) NOT NULL,
	to_internal_audit_type_id		NUMBER(10, 0) NOT NULL,
	CONSTRAINT pk_iatcf				PRIMARY KEY (app_sid, from_internal_audit_type_id, to_internal_audit_type_id),
	CONSTRAINT fk_iatcf_from_iat	FOREIGN KEY (app_sid, from_internal_audit_type_id) REFERENCES csr.internal_audit_type (app_sid, internal_audit_type_id),
	CONSTRAINT fk_iatcf_to_iat		FOREIGN KEY (app_sid, to_internal_audit_type_id) REFERENCES csr.internal_audit_type (app_sid, internal_audit_type_id)
);

CREATE TABLE csrimp.internal_audit_type_carry_fwd (
	csrimp_session_id				NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID'),
	from_internal_audit_type_id		NUMBER(10, 0) NOT NULL,
	to_internal_audit_type_id		NUMBER(10, 0) NOT NULL,
	CONSTRAINT pk_iatcf				PRIMARY KEY (csrimp_session_id, from_internal_audit_type_id, to_internal_audit_type_id),
    CONSTRAINT fk_iatcf_is			FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

-- Alter tables

-- *** Grants ***
grant select,insert,update,delete on csrimp.internal_audit_type_carry_fwd to web_user;
grant insert on csr.internal_audit_type_carry_fwd to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.internal_audit_type_carry_fwd (app_sid, from_internal_audit_type_id, to_internal_audit_type_id)
	 SELECT app_sid, internal_audit_type_id, internal_audit_type_id
	   FROM csr.internal_audit_type;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../audit_pkg
@../schema_pkg

@../audit_body
@../csr_app_body
@../schema_body
@../csrimp/imp_body

@update_tail
