-- Please update version.sql too -- this keeps clean builds in sync
define version=3496
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.temp_deleg_plan_overlap ADD (
	overlapping_region_sid	NUMBER(10, 0)
);

UPDATE csr.temp_deleg_plan_overlap SET overlapping_region_sid = applied_to_region_sid;

ALTER TABLE csr.temp_deleg_plan_overlap MODIFY (
	overlapping_region_sid NOT NULL,
	applied_to_region_sid  NULL
);

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
@../deleg_plan_body

@update_tail
