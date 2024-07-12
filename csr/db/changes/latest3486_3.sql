-- Please update version.sql too -- this keeps clean builds in sync
define version=3486
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
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE)
VALUES (84, 'Recalc one Restricted', 'Resets the calc dates and queues recalc jobs for the current site/app.', 'RecalcOneRestricted', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE,PARAM_HIDDEN)
VALUES (84, 'Start Year',' The start year.', 0, NULL, 0);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE,PARAM_HIDDEN)
VALUES (84, 'End Year', 'The end year.', 1, NULL, 0);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../util_script_pkg
@../util_script_body


@update_tail
