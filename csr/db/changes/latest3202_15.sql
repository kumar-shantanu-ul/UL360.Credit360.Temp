-- Please update version.sql too -- this keeps clean builds in sync
define version=3202
define minor_version=15
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (106, 'Droid API', 'EnableDroidAPI', 'Enable Droid API');

-- ** New package grants **

@..\enable_pkg
@..\enable_body

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
