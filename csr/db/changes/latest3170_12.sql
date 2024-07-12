-- Please update version.sql too -- this keeps clean builds in sync
define version=3170
define minor_version=12
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
   SET PARAM_NAME = 'Group Name',
       PARAM_HINT = 'The name of the group to add/remove'
 WHERE UTIL_SCRIPT_ID = 36
   AND POS = 1;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../util_script_pkg
@../util_script_body

@update_tail
