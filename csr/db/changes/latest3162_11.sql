-- Please update version.sql too -- this keeps clean builds in sync
define version=3162
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.CUSTOMER ADD CONSTRAINT CHK_ADJ_FACTORSET_STARTMONTH CHECK (ADJ_FACTORSET_STARTMONTH IN (0,1));


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
@../enable_body
@../factor_body

@update_tail
