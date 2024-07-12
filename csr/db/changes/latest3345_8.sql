-- Please update version.sql too -- this keeps clean builds in sync
define version=3345
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables
CREATE INDEX CSR.IX_EXTERNAL_TARG_CREDENTIAL_PR ON CSR.EXTERNAL_TARGET_PROFILE (APP_SID, CREDENTIAL_PROFILE_ID);

-- Alter tables
ALTER TABLE CSR.EXTERNAL_TARGET_PROFILE ADD CONSTRAINT FK_CREDENTIAL_ID
FOREIGN KEY (APP_SID, CREDENTIAL_PROFILE_ID)
 REFERENCES CSR.CREDENTIAL_MANAGEMENT (APP_SID, CREDENTIAL_ID);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.target_profile_pkg AS PROCEDURE DUMMY;
END;
/
CREATE OR REPLACE PACKAGE BODY csr.target_profile_pkg AS PROCEDURE DUMMY
AS
	BEGIN
		NULL;
	END;
END;
/
GRANT EXECUTE ON csr.target_profile_pkg TO web_user;
-- *** Conditional Packages ***

-- *** Packages ***
@..\automated_export_import_pkg
@..\automated_export_import_body
@..\credentials_pkg
@..\credentials_body
@..\target_profile_pkg
@..\target_profile_body
@update_tail