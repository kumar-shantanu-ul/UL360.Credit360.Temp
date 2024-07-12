-- Please update version.sql too -- this keeps clean builds in sync
define version=3336
define minor_version=8
@update_header

-- US23007: Null update script as change was pulled from release

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
