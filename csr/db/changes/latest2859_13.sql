-- Please update version.sql too -- this keeps clean builds in sync
define version=2859
define minor_version=13
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.util_script (util_script_id, util_script_name, description, util_script_sp, wiki_article)
	 VALUES (10, 'Map Survey Questions to Indicators', 'Will create indicators for anything that has single input values (Radio buttons, dropdown, matrix) under the supply Chain Questionnaires folder for the supplied survey sid', 'MapIndicatorsFromSurvey', 'W1915');

INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint , pos)
	 VALUES (10, 'Survey SID', 'Survey sid to map question from', 1);

INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint , pos)
	 VALUES (10, 'Score type', 'The score type of the survey (Optional, defaults to NULL)', 2);

-- ** New package grants **

-- *** Packages ***
@..\quick_survey_pkg
@..\quick_survey_body

@update_tail
