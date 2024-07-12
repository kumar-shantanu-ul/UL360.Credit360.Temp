-- Please update version.sql too -- this keeps clean builds in sync
define version=3449
define minor_version=1
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
-- metlife est_meter update
UPDATE csr.est_meter 
   SET pm_space_id = 1298329
 WHERE pm_meter_id = 6010863
   AND app_sid = 26111897;



-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
