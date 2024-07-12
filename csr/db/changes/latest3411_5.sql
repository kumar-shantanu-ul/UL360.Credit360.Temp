-- Please update version.sql too -- this keeps clean builds in sync
define version=3411
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

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../../../security/db/oracle/accountpolicy_pkg
@../../../security/db/oracle/accountpolicy_body

@update_tail
