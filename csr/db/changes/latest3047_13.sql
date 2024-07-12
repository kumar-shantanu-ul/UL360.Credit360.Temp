-- Please update version.sql too -- this keeps clean builds in sync
define version=3047
define minor_version=13
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
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (95, 'Permits', 'EnablePermits', 'Enables the compliance permits module.');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@@../enable_pkg
@@../enable_body

@update_tail
