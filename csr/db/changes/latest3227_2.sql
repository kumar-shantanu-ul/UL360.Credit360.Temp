-- Please update version.sql too -- this keeps clean builds in sync
define version=3227
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.ftp_profile
ADD use_username_password_auth NUMBER(1) default 0 NOT NULL;

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
@../automated_export_import_pkg

@../automated_export_import_body
@../automated_import_body
@../automated_export_body

@update_tail
