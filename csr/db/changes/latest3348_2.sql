-- Please update version.sql too -- this keeps clean builds in sync
define version=3348
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.credential_management ADD (
	login_hint	VARCHAR2(500) 
);

ALTER TABLE csr.credential_management DROP CONSTRAINT UK_CREDENTIAL_MANAGEMENT_LABEL;
ALTER TABLE csr.credential_management ADD CONSTRAINT UK_CREDENTIAL_MANAGEMENT_LABEL UNIQUE (app_sid, label);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../credentials_pkg

@../credentials_body

@update_tail
