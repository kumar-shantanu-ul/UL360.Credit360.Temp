-- Please update version.sql too -- this keeps clean builds in sync
define version=3139
define minor_version=28
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
@../audit_body
@../chain/supplier_audit_body

@update_tail
