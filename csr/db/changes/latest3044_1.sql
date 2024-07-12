-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../csr_data_body
@../delegation_pkg
@../delegation_body
@../supplier/audit_pkg
@../supplier/audit_body

@update_tail
