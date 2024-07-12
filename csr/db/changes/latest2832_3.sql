-- Please update version.sql too -- this keeps clean builds in sync
define version=2832
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Data changes ***
-- RLS
-- Data

-- ** New package grants **

-- *** Packages ***

@../deleg_plan_pkg
@../deleg_plan_body
@../delegation_body

@update_tail
