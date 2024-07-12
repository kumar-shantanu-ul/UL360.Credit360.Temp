-- Please update version.sql too -- this keeps clean builds in sync
define version=3261
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
@../meter_body
@../meter_patch_pkg
@../meter_patch_body


@update_tail
