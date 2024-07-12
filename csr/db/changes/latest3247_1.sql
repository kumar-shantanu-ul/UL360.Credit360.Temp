-- Please update version.sql too -- this keeps clean builds in sync
define version=3247
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
		  
-- Updating a 120Million record table would take too long within the release and cause down time so moved out to seperate script.

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
