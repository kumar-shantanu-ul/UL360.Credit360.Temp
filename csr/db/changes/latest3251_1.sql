-- Please update version.sql too -- this keeps clean builds in sync
define version=3251
define minor_version=1
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
VALUES (108, 'Branding', 'EnableBranding', 'Enable branding tool');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../enable_body

@update_tail
