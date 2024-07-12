-- Please update version.sql too -- this keeps clean builds in sync
define version=2886
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.module_param SET param_hint = 'Site name' where param_name = 'siteName' AND module_id = 7;
UPDATE csr.module_param SET param_hint = 'Company name' where param_name = 'in_company_name' AND module_id = 13;
UPDATE csr.module_param SET param_hint = 'User name' where param_name = 'in_user' AND module_id = 15;
UPDATE csr.module_param SET param_hint = 'Password' where param_name = 'in_password' AND module_id = 15;
UPDATE csr.module_param SET param_hint = 'The path to the client''s Urjanet folder on our SFTP server (cyanoxantha): "client_name.urjanet"' WHERE param_name = 'in_ftp_path' AND module_id = 60;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
