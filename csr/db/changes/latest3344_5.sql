-- Please update version.sql too -- this keeps clean builds in sync
define version=3344
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.MSAL_USER_TOKEN_CACHE (
	APP_SID						NUMBER(10,0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	LOGIN_HINT					VARCHAR2(500)		NOT NULL,
	CACHE_KEY					VARCHAR2(1024)		NOT NULL,
	TOKEN						BLOB				NOT NULL,
	CONSTRAINT PK_MSAL_USR_TKN_CACHE PRIMARY KEY (APP_SID, CACHE_KEY)
);

CREATE TABLE CSR.MSAL_USER_CONSENT_FLOW (
	ACT_ID						CHAR(36 BYTE)		NOT NULL,
	REDIRECT_URL				VARCHAR2(1024)		NOT NULL,
	PKCE						VARCHAR2(1024)		NOT NULL,
	CONSTRAINT UK_MSAL_USR_CF_ACT_RED UNIQUE (ACT_ID, REDIRECT_URL)
);

-- Alter tables
ALTER TABLE CSR.CREDENTIAL_MANAGEMENT ADD (
	CACHE_KEY					VARCHAR2(1024)
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- Please paste the content of the view.
-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.authentication_type
SET auth_type_name = 'Azure Active Directory (User based authentication)'
WHERE auth_type_id = 1;

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.msal_user_token_cache_pkg AS
	PROCEDURE DUMMY;
END;
/
CREATE OR REPLACE PACKAGE BODY csr.msal_user_token_cache_pkg AS
	PROCEDURE DUMMY
AS
	BEGIN
		NULL;
	END;
END;
/

GRANT EXECUTE ON csr.msal_user_token_cache_pkg TO web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@../msal_user_token_cache_pkg
@../credentials_pkg

@../msal_user_token_cache_body
@../credentials_body


@update_tail
