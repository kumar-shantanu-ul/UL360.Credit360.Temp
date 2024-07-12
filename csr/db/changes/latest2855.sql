-- Please update version.sql too -- this keeps clean builds in sync
define version=2855
define minor_version=0
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

UPDATE csr.module
   SET description = 'Enable frameworks (GRI G4 and CDP Climate Change only). Setup instructions: <a href="http://emu.helpdocsonline.com/frameworks" target="_blank">http://emu.helpdocsonline.com/frameworks</a>',
       license_warning = 0
 WHERE module_name = 'Frameworks';

-- ** New package grants **

-- *** Packages ***

@update_tail
