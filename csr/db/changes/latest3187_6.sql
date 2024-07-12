-- Please update version.sql too -- this keeps clean builds in sync
define version=3187
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
COMMENT ON TABLE CSR.USER_PROFILE
IS 'contains_pii = "yes"';

COMMENT ON TABLE CSR.USER_PROFILE_STAGED_RECORD
IS 'contains_pii = "yes"';

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
