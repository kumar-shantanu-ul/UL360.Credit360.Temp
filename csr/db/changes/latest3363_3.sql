-- Please update version.sql too -- this keeps clean builds in sync
define version=3363
define minor_version=3
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
@../indicator_pkg
@../indicator_body
@../managed_content_body

@update_tail
