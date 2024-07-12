-- Please update version.sql too -- this keeps clean builds in sync
define version=2949
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

GRANT EXECUTE ON csr.user_report_pkg TO web_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../user_report_pkg

@../user_report_body

@update_tail
