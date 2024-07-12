-- Please update version.sql too -- this keeps clean builds in sync
define version=3488
define minor_version=7
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

UPDATE csr.csr_user
SET send_alerts = 0
WHERE anonymised = 1;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_user_body

@update_tail
