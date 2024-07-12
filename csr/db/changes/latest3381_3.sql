-- Please update version.sql too -- this keeps clean builds in sync
define version=3381
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
DELETE FROM csr.module_param
 WHERE module_id = 65;
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint, allow_blank)
VALUES (65, 'Select GRESB environment (sandbox or live)', 0, '(sandbox|live)', 1);
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint, allow_blank)
VALUES (65, 'Floor Area Measure Type', 1, '(m^2|ft^2)', 1);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../enable_body

@update_tail
