-- Please update version.sql too -- this keeps clean builds in sync
define version=3143
define minor_version=42
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
@../audit_pkg
@../chain/supplier_flow_pkg

@../audit_body
@../chain/supplier_flow_body
@../chain/company_body

@update_tail
