-- Please update version.sql too -- this keeps clean builds in sync
define version=3356
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.AUTHENTICATION_SCOPE(
	AUTH_SCOPE_ID 			NUMBER(10, 0) NOT NULL,
	AUTH_SCOPE_NAME 		VARCHAR2(255) NOT NULL,
	AUTH_SCOPE 				VARCHAR2(4000) NOT NULL,
	HIDDEN 					NUMBER(1) NOT NULL,
	CONSTRAINT PK_AUTH_SCOPE PRIMARY KEY (AUTH_SCOPE_ID),
	CONSTRAINT UK_AUTH_SCOPE UNIQUE (AUTH_SCOPE_NAME)
);
INSERT INTO CSR.AUTHENTICATION_SCOPE (AUTH_SCOPE_ID, AUTH_SCOPE_NAME, AUTH_SCOPE, HIDDEN) VALUES (1, 'Legacy',
'https://graph.microsoft.com/offline_access,https://graph.microsoft.com/openid,https://graph.microsoft.com/User.Read,https://graph.microsoft.com/Files.ReadWrite.All,https://graph.microsoft.com/Sites.ReadWrite.All', 1);

-- Alter tables
ALTER TABLE CSR.EXTERNAL_TARGET_PROFILE ADD (
	STORAGE_ACC_NAME			VARCHAR2(400),
	STORAGE_ACC_CONTAINER		VARCHAR2(400)
);

ALTER TABLE CSR.CREDENTIAL_MANAGEMENT ADD (
	AUTH_SCOPE_ID				NUMBER(10, 0)	DEFAULT 1 NOT NULL
);

ALTER TABLE CSR.CREDENTIAL_MANAGEMENT ADD CONSTRAINT FK_AUTH_SCOPE_ID
	FOREIGN KEY (AUTH_SCOPE_ID)
	REFERENCES CSR.AUTHENTICATION_SCOPE(AUTH_SCOPE_ID);

CREATE INDEX csr.ix_credential_ma_auth_scope_id ON csr.credential_management(auth_scope_id);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO CSR.EXTERNAL_TARGET_PROFILE_TYPE (PROFILE_TYPE_ID, LABEL)
VALUES (3, 'Azure Blob Storage');

INSERT INTO CSR.AUTHENTICATION_SCOPE (AUTH_SCOPE_ID, AUTH_SCOPE_NAME, AUTH_SCOPE, HIDDEN) VALUES (2, 'Sharepoint',
'https://graph.microsoft.com/offline_access,https://graph.microsoft.com/openid,https://graph.microsoft.com/User.Read,https://graph.microsoft.com/Files.ReadWrite', 0);
INSERT INTO CSR.AUTHENTICATION_SCOPE (AUTH_SCOPE_ID, AUTH_SCOPE_NAME, AUTH_SCOPE, HIDDEN) VALUES (3, 'Onedrive',
'https://graph.microsoft.com/offline_access,https://graph.microsoft.com/openid,https://graph.microsoft.com/User.Read,https://graph.microsoft.com/Files.ReadWrite', 0);
INSERT INTO CSR.AUTHENTICATION_SCOPE (AUTH_SCOPE_ID, AUTH_SCOPE_NAME, AUTH_SCOPE, HIDDEN) VALUES (4, 'Azure Storage Account', 'https://storage.azure.com/user_impersonation', 0);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../credentials_pkg
@../target_profile_pkg

@../automated_export_body
@../credentials_body
@../target_profile_body

@update_tail
