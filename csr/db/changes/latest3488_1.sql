-- Please update version.sql too -- this keeps clean builds in sync
define version=3488
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables
CREATE OR REPLACE TYPE CSR.T_REGIONS AS TABLE OF CSR.T_REGION;
/

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
@../core_access_pkg
@../core_access_body

@update_tail