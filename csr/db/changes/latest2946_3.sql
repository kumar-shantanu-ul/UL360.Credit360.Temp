-- Please update version.sql too -- this keeps clean builds in sync
define version=2946
define minor_version=3
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
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (73, 'Like for like', 'EnableLikeforlike', 'Consult with DEV before enable this! Enables the like for like module.', 1);
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../like_for_like_pkg
@../like_for_like_body
@../enable_pkg
@../enable_body

@update_tail
