-- Please update version.sql too -- this keeps clean builds in sync
define version=3405
define minor_version=1
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
@../../../aspen2/db/aspenapp_pkg
@../csr_app_pkg
@../customer_pkg

@../../../aspen2/db/aspenapp_body
@../csr_app_body
@../customer_body

@update_tail
