-- Please update version.sql too -- this keeps clean builds in sync
define version=3106
define minor_version=19
@update_header

-- *** DDL ***
-- Create tables


-- Alter tables
ALTER TABLE CSR.CUSTOMER_SAML_SSO ADD USE_DEFAULT_USER_ACC NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.CUSTOMER_SAML_SSO ADD DEFAULT_LOGON_USER_SID NUMBER(10, 0);
ALTER TABLE CSR.CUSTOMER_SAML_SSO ADD CONSTRAINT FK_DEFAULT_LOGON_USER_SID FOREIGN KEY (APP_SID, DEFAULT_LOGON_USER_SID) REFERENCES CSR.CSR_USER (APP_SID, CSR_USER_SID);
ALTER TABLE CSR.CUSTOMER_SAML_SSO ADD CONSTRAINT CHK_USE_DEFAULT_USER_ACC CHECK (USE_DEFAULT_USER_ACC IN (0,1));
ALTER TABLE CSR.CUSTOMER_SAML_SSO ADD CONSTRAINT CHK_USE_DEF_USER_ACC_SET CHECK (USE_DEFAULT_USER_ACC <> 1 OR (USE_DEFAULT_USER_ACC = 1 AND DEFAULT_LOGON_USER_SID IS NOT NULL));

CREATE INDEX CSR.IX_CUST_SAML_SSO_DEF_USER_SID ON CSR.CUSTOMER_SAML_SSO (APP_SID, DEFAULT_LOGON_USER_SID);
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\saml_pkg
@..\saml_body

@update_tail
