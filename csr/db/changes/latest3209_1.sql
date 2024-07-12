-- Please update version.sql too -- this keeps clean builds in sync
define version=3209
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE CSR.AUDIT_TYPE_CLOSURE_TYPE
  ADD MANUAL_EXPIRY_DATE NUMBER(1) DEFAULT 0 NOT NULL;

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
