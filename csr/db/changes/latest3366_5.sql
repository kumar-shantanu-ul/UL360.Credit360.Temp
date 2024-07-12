-- Please update version.sql too -- this keeps clean builds in sync
define version=3366
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.non_compliance DROP COLUMN lookup_key;

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

@../audit_body

@update_tail
