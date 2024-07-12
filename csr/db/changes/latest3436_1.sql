-- Please update version.sql too -- this keeps clean builds in sync
define version=3436
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
INSERT INTO csr.capability (name, allow_by_default, description)
VALUES ('Baseline calculations', 0, 'Enables configuration of baseline calcuations for scrag++.');

INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (125, 'Baseline calculations', 'EnableBaselineCalculations', 'Enable the Baseline calculations settings pages');

INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
VALUES (125, 'State', '0 (disable) or 1 (enable)', 0);
INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
VALUES (125, 'Menu Postion', '-1 (end) or 1 based position', 1);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../enable_body

@update_tail
