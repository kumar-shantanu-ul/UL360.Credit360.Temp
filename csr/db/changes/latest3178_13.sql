-- Please update version.sql too -- this keeps clean builds in sync
define version=3178
define minor_version=13
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

@../chain/bsci_2009_audit_report_body
@../chain/bsci_2014_audit_report_body

@update_tail
