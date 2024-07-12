-- Please update version.sql too -- this keeps clean builds in sync
define version=3475
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.tt_audit_browse MODIFY auditor_name VARCHAR(256);

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

@update_tail
