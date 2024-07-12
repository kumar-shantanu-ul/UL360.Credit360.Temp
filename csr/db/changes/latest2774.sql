-- Please update version.sql too -- this keeps clean builds in sync
define version=2774
define minor_version=0
define is_combined=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Data changes ***

-- ** New package grants **

-- *** Packages ***


@..\delegation_body
@..\deleg_plan_pkg
@..\deleg_plan_body


@update_tail
