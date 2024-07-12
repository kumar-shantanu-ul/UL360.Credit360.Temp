-- Please update version.sql too -- this keeps clean builds in sync
define version=3338
define minor_version=2
@update_header

-- *** DDL ***


-- Create tables
CREATE TABLE CSR.AUTHENTICATION_TYPE(
	AUTH_TYPE_ID			NUMBER(10, 0) NOT NULL,
	AUTH_TYPE_NAME			VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_AUTHENTICATION_ID PRIMARY KEY (AUTH_TYPE_ID),
	CONSTRAINT UK_AUTH_TYPE UNIQUE (AUTH_TYPE_NAME)
);


CREATE TABLE CSR.CREDENTIAL_MANAGEMENT (
	APP_SID						NUMBER(10, 0) 		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CREDENTIAL_ID				NUMBER(10, 0)		NOT NULL,
	LABEL						VARCHAR2(255)       NOT NULL,
    AUTH_TYPE_ID                NUMBER(10, 0)		NOT NULL,
    CREATED_DTM                 DATE                DEFAULT SYSDATE NOT NULL,
    UPDATED_DTM                 DATE                DEFAULT SYSDATE NOT NULL,
	CONSTRAINT PK_CREDENTIAL_MANAGEMENT PRIMARY KEY (APP_SID, CREDENTIAL_ID),
	CONSTRAINT UK_CREDENTIAL_MANAGEMENT_LABEL UNIQUE (LABEL),
    CONSTRAINT FK_AUTH_TYPE_ID FOREIGN KEY (AUTH_TYPE_ID) REFERENCES CSR.AUTHENTICATION_TYPE(AUTH_TYPE_ID)
)
;


CREATE SEQUENCE CSR.CREDENTIAL_MANAGEMENT_ID_SEQ START WITH 1 INCREMENT BY 1 NOCYCLE CACHE 5;


CREATE INDEX csr.ix_credential_ma_auth_type_id ON csr.credential_management (auth_type_id);

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO CSR.AUTHENTICATION_TYPE (AUTH_TYPE_ID, AUTH_TYPE_NAME) VALUES (1, 'Placeholder 1');

-- For Audit
INSERT INTO CSR.AUDIT_TYPE_GROUP (AUDIT_TYPE_GROUP_ID, DESCRIPTION) VALUES (6, 'Application object');
INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (304,'Credential Management',6);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../automated_export_import_pkg
@../automated_export_import_body

@../csr_app_body

@../schema_pkg
@../schema_body

@../csr_data_pkg
@../csr_data_body

@update_tail
