-- Please update version.sql too -- this keeps clean builds in sync
define version=3468
define minor_version=10
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
@../factor_body
@../tests/test_emission_factors_pkg
@../tests/test_emission_factors_body

@update_tail
