-- Please update version.sql too -- this keeps clean builds in sync
define version=3088
define minor_version=12
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
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('View user profiles', 0, 'User Management: Allows viewing of User Profile information');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../user_profile_pkg

@../user_profile_body

@update_tail
