-- Please update version.sql too -- this keeps clean builds in sync
define version=3202
define minor_version=16
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

INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
VALUES (106, 'in_enable_guest_access', 'Guest access (y/n)', 0);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
