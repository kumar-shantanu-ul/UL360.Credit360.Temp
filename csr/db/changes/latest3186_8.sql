-- Please update version.sql too -- this keeps clean builds in sync
define version=3186
define minor_version=8
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
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (57, 'Enable Scrag++ test cube', 
  'Enables the Scrag++ test cube', 'EnableTestCube', NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (58, 'Enable Scrag++ merged scenario', 
  'Migrates the test cube to the Scrag++ merged scenario and creates the unmerged scenario', 'EnableScragPP', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (58, 'Reference/comment', 'Reference/comment for approval of Scrag++ migration', 1, NULL);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\util_script_pkg
@..\util_script_body
@..\scrag_pp_pkg
@..\scrag_pp_body

@update_tail
