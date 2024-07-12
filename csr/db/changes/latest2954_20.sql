-- Please update version.sql too -- this keeps clean builds in sync
define version=2954
define minor_version=20
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

INSERT INTO csr.capability (name,allow_by_default) VALUES ('Can manage group membership list page', 1);
INSERT INTO csr.capability (name,allow_by_default) VALUES ('Can deactivate users list page', 1);

INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
VALUES (78, 'Enable capabilities user list page', 'EnableCapabilitiesUserListPage', 'Allow user to perform bulk actions via the new user list page.', 0);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../enable_pkg
@../enable_body

@update_tail
