-- Please update version.sql too -- this keeps clean builds in sync
define version=3500
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
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, description) VALUES ('Target Planning', 0, 'Under development, do not use: Allows user to add historical data, regions, dates and a future target. The system calculates a trendline.');

INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (129, 'Target Planning', 'EnableTargetPlanning', 'Under development, do not use: Enable Target Planning module.');
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (129, 'State', 1, '0 (disable) or 1 (enable)');
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (129, 'Menu Position', 2, '-1=end, or 1 based position');


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../target_planning_pkg

@../enable_body
@../target_planning_body

@update_tail

