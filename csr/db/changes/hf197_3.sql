-- Please update version.sql too -- this keeps clean builds in sync
define version=0
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.internal_audit MODIFY auditor_name VARCHAR2(256);
ALTER TABLE csrimp.internal_audit MODIFY auditor_name VARCHAR2(256);

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
