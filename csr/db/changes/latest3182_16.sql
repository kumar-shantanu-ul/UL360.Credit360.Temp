-- Please update version.sql too -- this keeps clean builds in sync
define version=3182
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.delegation_date_schedule DROP CONSTRAINT CK_DATES;
ALTER TABLE csr.delegation_date_schedule ADD CONSTRAINT CK_DATES CHECK (END_DTM > START_DTM) ENABLE NOVALIDATE;
ALTER TABLE csrimp.delegation_date_schedule DROP CONSTRAINT CK_DATES;
ALTER TABLE csrimp.delegation_date_schedule ADD CONSTRAINT CK_DATES CHECK (END_DTM > START_DTM) ENABLE NOVALIDATE;

ALTER TABLE csr.sheet_date_schedule DROP CONSTRAINT CK_START_DTM;
ALTER TABLE csrimp.sheet_date_schedule DROP CONSTRAINT CK_START_DTM;

ALTER TABLE csr.deleg_plan DROP CONSTRAINT CK_DELEG_TPL_DATES;
ALTER TABLE csr.deleg_plan ADD CONSTRAINT CK_DELEG_TPL_DATES CHECK (END_DTM > START_DTM) ENABLE NOVALIDATE;
ALTER TABLE csrimp.deleg_plan DROP CONSTRAINT CK_DELEG_TPL_DATES;
ALTER TABLE csrimp.deleg_plan ADD CONSTRAINT CK_DELEG_TPL_DATES CHECK (END_DTM > START_DTM) ENABLE NOVALIDATE;

ALTER TABLE csr.delegation DROP CONSTRAINT CK_DELEGATION_DATES;
ALTER TABLE csr.delegation ADD CONSTRAINT CK_DELEGATION_DATES CHECK (END_DTM > START_DTM) ENABLE NOVALIDATE;
ALTER TABLE csrimp.delegation DROP CONSTRAINT CK_DELEGATION_DATES;
ALTER TABLE csrimp.delegation ADD CONSTRAINT CK_DELEGATION_DATES CHECK (END_DTM > START_DTM) ENABLE NOVALIDATE;

ALTER TABLE csr.sheet DROP CONSTRAINT CK_SHEET_DATES;
ALTER TABLE csr.sheet ADD CONSTRAINT CK_SHEET_DATES CHECK (END_DTM > START_DTM) ENABLE NOVALIDATE;
ALTER TABLE csrimp.sheet DROP CONSTRAINT CK_SHEET_DATES;
ALTER TABLE csrimp.sheet ADD CONSTRAINT CK_SHEET_DATES CHECK (END_DTM > START_DTM) ENABLE NOVALIDATE;

ALTER TABLE csr.sheet_val_change_log DROP CONSTRAINT CK_SHEET_VAL_CHANGE_LOG_DATES;
ALTER TABLE csr.sheet_val_change_log ADD CONSTRAINT CK_SHEET_VAL_CHANGE_LOG_DATES CHECK (END_DTM > START_DTM) ENABLE NOVALIDATE;

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

@../deleg_plan_pkg
@../unit_test_pkg

@../deleg_plan_body
@../unit_test_body

@update_tail
