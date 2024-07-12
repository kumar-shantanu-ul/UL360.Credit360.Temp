-- Please update version.sql too -- this keeps clean builds in sync
define version=3114
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
grant delete on chem.cas_restricted to csr;
grant delete on chem.cas_group_member to csr;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../csr_app_body

@update_tail
