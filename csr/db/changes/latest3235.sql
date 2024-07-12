-- Please update version.sql too -- this keeps clean builds in sync
define version=3235
define minor_version=0
@update_header
/*
 NULL update script to replace long-running data script to be run outside
 of the main deployment.
 */
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

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
