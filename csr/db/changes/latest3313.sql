-- Please update version.sql too -- this keeps clean builds in sync
define version=3313
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
revoke select on csr.v$csr_user from campaigns;
grant select on security.user_table to campaigns;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../campaigns/campaign_body

@update_tail
