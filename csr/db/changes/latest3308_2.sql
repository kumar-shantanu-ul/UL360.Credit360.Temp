-- Please update version.sql too -- this keeps clean builds in sync
define version=3308
define minor_version=2
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
@../customer_pkg
@../customer_body
@../batch_job_body
@../stored_calc_datasource_body

@update_tail
