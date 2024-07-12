-- Please update version.sql too -- this keeps clean builds in sync
define version=3143
define minor_version=23
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
CREATE UNIQUE INDEX CSR.IDX_USER_PROFILE_PK ON CSR.USER_PROFILE(APP_SID, UPPER(PRIMARY_KEY))
;

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

@../user_profile_body

@update_tail
