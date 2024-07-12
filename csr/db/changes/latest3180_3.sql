-- Please update version.sql too -- this keeps clean builds in sync
define version=3180
define minor_version=3
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
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (79, 'Create default campaign and campaign workflow?', 2, '(Y/N)');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../enable_pkg

@../enable_body

@update_tail
