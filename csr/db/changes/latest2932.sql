-- Please update version.sql too -- this keeps clean builds in sync
define version=2932
define minor_version=0
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
INSERT INTO csr.util_script(UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
VALUES (12, 'Fix Property Company Region Tree', 'Turns supplier regions into companies and sets the new company as the management company of the child properties. Also adds users to companies based on region start points.', 'FixPropertyCompanyRegionTree', NULL);

INSERT INTO csr.util_script_param(UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS, PARAM_VALUE, PARAM_HIDDEN)
VALUES (12, 'Root region sid', 'The root of the tree to run the fix for. The root region itself will not be considered, only regions underneath in the tree.', 0, NULL, 0);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/company_pkg
@../chain/company_body

@../supplier_pkg
@../supplier_body

@../util_script_pkg
@../util_script_body

@update_tail
