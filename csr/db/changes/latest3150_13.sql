-- Please update version.sql too -- this keeps clean builds in sync
define version=3150
define minor_version=13
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
GRANT EXECUTE ON csr.user_report_pkg TO web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@../user_report_pkg
@../user_report_body

@update_tail
