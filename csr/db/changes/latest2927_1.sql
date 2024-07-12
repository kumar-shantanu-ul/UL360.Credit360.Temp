-- Please update version.sql too -- this keeps clean builds in sync
define version=2927
define minor_version=1
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

UPDATE CSR.UTIL_SCRIPT 
   SET UTIL_SCRIPT_SP = 'SetAutoPCSheetStatusFlag'
 WHERE UTIL_SCRIPT_ID = 9;

DELETE FROM CSR.UTIL_SCRIPT_PARAM
 WHERE UTIL_SCRIPT_ID=9;
 
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE,PARAM_HIDDEN) 
VALUES (9,'Setting value (0 off, 1 on)','The setting to use.',0,null,0);



-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\util_script_pkg
@..\util_script_body

@update_tail
