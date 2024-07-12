-- Please update version.sql too -- this keeps clean builds in sync
define version=3188
define minor_version=27
@update_header

ALTER TABLE csrimp.scenario ADD DONT_RUN_AGGREGATE_INDICATORS NUMBER(1) NOT NULL;
-- *** DDL ***
-- Create tables

-- Alter tables

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

@../csrimp/imp_body

@update_tail
