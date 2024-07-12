-- Please update version.sql too -- this keeps clean builds in sync
define version=3474
define minor_version=4
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

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\tag_pkg
@..\core_access_pkg


@..\tag_body
@..\core_access_body

@update_tail
