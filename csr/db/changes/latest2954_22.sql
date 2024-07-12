-- Please update version.sql too -- this keeps clean builds in sync
define version=2954
define minor_version=22
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.ftp_default_profile DROP PRIMARY KEY;
ALTER TABLE csr.ftp_default_profile RENAME COLUMN id TO default_profile_id;
ALTER TABLE csr.ftp_default_profile ADD CONSTRAINT pk_default_profile_id PRIMARY KEY (default_profile_id);

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
@../automated_export_pkg
@../automated_export_body
@../automated_export_import_pkg
@../automated_export_import_body

@update_tail
