-- Please update version.sql too -- this keeps clean builds in sync
define version=3439
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.AUTHENTICATION_SCOPE ADD (AUTH_TYPE_ID NUMBER(10, 0));

ALTER TABLE CSR.AUTHENTICATION_SCOPE ADD CONSTRAINT FK_AUTH_SCOPE_AUTH_TYPE_ID
	FOREIGN KEY (AUTH_TYPE_ID)
	REFERENCES CSR.AUTHENTICATION_TYPE(AUTH_TYPE_ID);

ALTER TABLE CSR.CREDENTIAL_MANAGEMENT MODIFY (AUTH_SCOPE_ID NULL);

create index csr.ix_authenticatio_auth_type_id on csr.authentication_scope (auth_type_id);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO CSR.AUTHENTICATION_TYPE (AUTH_TYPE_ID, AUTH_TYPE_NAME) VALUES (2, 'API Key/Access Token');
UPDATE CSR.AUTHENTICATION_SCOPE
   SET auth_type_id = 1;

ALTER TABLE CSR.AUTHENTICATION_SCOPE MODIFY (AUTH_TYPE_ID NOT NULL);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../credentials_body

@update_tail
