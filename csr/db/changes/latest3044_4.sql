-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=4
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

-- fix bad value from latest2752_14
UPDATE csr.util_script
   SET util_script_sp = 'RecalcOne'
 WHERE util_script_id = 2
   AND util_script_name = 'Recalc one'
   AND util_script_sp = 'CreateDelegationSheetsFuture';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
