-- Please update version.sql too -- this keeps clean builds in sync
define version=3426
define minor_version=5
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
UPDATE csr.gresb_indicator SET gresb_indicator_type_id = 7 WHERE gresb_indicator_id = 1162;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
