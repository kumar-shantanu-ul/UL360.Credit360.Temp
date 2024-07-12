-- Please update version.sql too -- this keeps clean builds in sync
define version=3342
define minor_version=6
@update_header

-- UD-165: Null update script as change was pulled from release

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
