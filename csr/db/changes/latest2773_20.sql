-- Please update version.sql too -- this keeps clean builds in sync
define version=2773
define minor_version=20
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
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
	VALUES (5, 'Add Indicator Quality Flags', 'Adds quality flags for indicators. See the wiki page. Replaces QualityFlagsToIndSelections.sql', 'AddQualityFlags', 'W1917');
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
	VALUES (6, 'Set Start Month', 'Sets the start month for reporting. See the wiki page. Replaces setStartMonth.sql', 'SetStartMonth', 'W177');
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
	VALUES (6, 'Start Month', 'The number of the new start month (For Jan: 1, Feb: 2 etc)', 0);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
	VALUES (6, 'Start Year', 'first year of current reporting period (four digits)', 1);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
	VALUES (6, 'End Year', 'last year of current reporting period (four digits)', 2);
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
	VALUES (7, 'Add Missing Alert', 'Adds a missng standard alert', 'AddMissingAlert', '');
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
	VALUES (7, 'Standard alert ID', 'The ID of the standard alert to add', 0);
END;
/

-- ** New package grants **

-- *** Packages ***

@update_tail
