-- Please update version.sql too -- this keeps clean builds in sync
define version=2982
define minor_version=23
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
UPDATE csr.module
   SET module_name = 'Properties - GRESB',
       description = 'Enables GRESB integration for property module. See http://emu.helpdocsonline.com/GRESB for instructions.'
 WHERE module_id = 65;
 
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
