-- Please update version.sql too -- this keeps clean builds in sync
define version=3162
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
GRANT EXECUTE ON csr.branding_pkg TO tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../branding_pkg
@../branding_body


@update_tail
