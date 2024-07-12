-- Please update version.sql too -- this keeps clean builds in sync
define version=3106
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.USER_PROFILE_DEFAULT_ROLE (
	APP_SID								NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	ROLE_SID							NUMBER(10)	NOT NULL,
	AUTOMATED_IMPORT_CLASS_SID			NUMBER(10),
	STEP_NUMBER							NUMBER(10),
	CONSTRAINT PK_USER_PROFILE_DEFAULT_ROLE PRIMARY KEY (APP_SID, ROLE_SID, AUTOMATED_IMPORT_CLASS_SID, STEP_NUMBER),
	CONSTRAINT FK_USER_PROFILE_DEFAULT_ROLE FOREIGN KEY (APP_SID, ROLE_SID) REFERENCES CSR.ROLE (APP_SID, ROLE_SID),
	CONSTRAINT CK_USER_PROFILE_DEFAULT_ROLE CHECK (AUTOMATED_IMPORT_CLASS_SID IS NULL OR STEP_NUMBER IS NOT NULL)
)
;

create index csr.ix_user_profile_role_auto_imp on csr.user_profile_default_role (app_sid, automated_import_class_sid, step_number)
;
-- Alter tables

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
@../automated_import_pkg

@../automated_import_body
@../user_profile_body
@update_tail
