-- Please update version.sql too -- this keeps clean builds in sync
define version=3148
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DROP INDEX CSR.UK_FACTOR_2;
CREATE UNIQUE INDEX CSR.UK_FACTOR_2 ON CSR.FACTOR (APP_SID, NVL(STD_FACTOR_ID, -FACTOR_ID), REGION_SID, START_DTM);

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
@../factor_body

@update_tail
