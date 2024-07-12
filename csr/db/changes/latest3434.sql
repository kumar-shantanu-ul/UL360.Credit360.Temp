-- Please update version.sql too -- this keeps clean builds in sync
define version=3434
define minor_version=0
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
UPDATE CSR.UTIL_SCRIPT_PARAM
   SET PARAM_HINT = 'Sid of trashed indicator from which to delete calc xml, or -1 to process all trashed inds with trashed calc ind check, or -2 to process all trashed inds.'
 WHERE UTIL_SCRIPT_ID = 62
   AND PARAM_NAME = 'Indicator sid';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../indicator_pkg
@../unit_test_pkg

@../indicator_body
@../unit_test_body
@../util_script_body

@update_tail
