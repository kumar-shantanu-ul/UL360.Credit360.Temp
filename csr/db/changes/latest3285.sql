-- Please update version.sql too -- this keeps clean builds in sync
define version=3285
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.COMPLIANCE_ITEM_VERSION_LOG
 DROP CONSTRAINT UK_CIVL_I;

ALTER TABLE CSR.COMPLIANCE_ITEM_VERSION_LOG
  ADD CONSTRAINT UK_CIVL_I UNIQUE (APP_SID, COMPLIANCE_ITEM_ID, MAJOR_VERSION, MINOR_VERSION, IS_MAJOR_CHANGE, LANG_ID);

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
@../compliance_body

@update_tail
