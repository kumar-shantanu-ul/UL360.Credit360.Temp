-- Please update version.sql too -- this keeps clean builds in sync
define version=2877
define minor_version=3
@update_header

-- *** DDL ***

--Create types

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
@../chain/company_type_pkg
@../chain/company_type_body

@update_tail
