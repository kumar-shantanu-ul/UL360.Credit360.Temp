-- Please update version.sql too -- this keeps clean builds in sync
define version=3353
define minor_version=6
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
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
VALUES (68, 'Set calc dependencies in dataview', 'Will insert all the dependencies of a supplied calculated indicator into the supplied dataview. Useful for s++ migrations.', 'SetCalcDependenciesInDataview', 'W3736');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
VALUES (68, 'Calc ind sid', 'The sid of the calculated indicator', 0);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
VALUES (68, 'Dataview sid', 'The sid of the dataview to set indicators in', 1);


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../util_script_pkg
@../util_script_body

@update_tail
