-- Please update version.sql too -- this keeps clean builds in sync
define version=3143
define minor_version=30
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.CUSTOMER DROP COLUMN TPLREPORTPERIODEXTENSION;
ALTER TABLE CSR.CUSTOMER DROP COLUMN DATA_EXPLORER_PERIOD_EXTENSION;

ALTER TABLE CSRIMP.CUSTOMER DROP COLUMN TPLREPORTPERIODEXTENSION;
ALTER TABLE CSRIMP.CUSTOMER DROP COLUMN DATA_EXPLORER_PERIOD_EXTENSION;

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
@../customer_body
@../schema_body

@../csrimp/imp_body

@update_tail
