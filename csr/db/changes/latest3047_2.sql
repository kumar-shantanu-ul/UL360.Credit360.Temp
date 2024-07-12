-- Please update version.sql too -- this keeps clean builds in sync
define version=3047
define minor_version=2
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

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\..\..\aspen2\cms\db\export_body
@..\..\..\aspen2\cms\db\tab_body
@..\..\..\aspen2\cms\db\testdata_body

@..\chain\activity_body
@..\chain\activity_report_body
@..\chain\bsci_body
@..\chain\company_dedupe_body
@..\chain\filter_pkg
@..\chain\filter_body
@..\chain\higg_setup_body

@..\csrimp\imp_body

@..\delegation_body
@..\deleg_plan_body
@..\doc_body
@..\doc_folder_body
@..\enable_body
@..\flow_report_body
@..\indicator_body
@..\quick_survey_body
@..\region_body
@..\region_report_body
@..\section_root_pkg
@..\section_root_body
@..\testdata_body
@..\trash_body
@..\user_report_body
@..\util_script_body

@update_tail
