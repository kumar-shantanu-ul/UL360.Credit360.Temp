-- Please update version.sql too -- this keeps clean builds in sync
define version=3165
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE CSR.ENHESA_OPTIONS
  ADD (MANUAL_RUN						NUMBER(1) DEFAULT 0 NOT NULL);

ALTER TABLE CSRIMP.ENHESA_OPTIONS
  ADD (MANUAL_RUN						NUMBER(1) NOT NULL);

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
@../compliance_pkg
@../compliance_body
@../csrimp/imp_body

@update_tail
