-- Please update version.sql too -- this keeps clean builds in sync
define version=3303
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.deleg_plan_deleg_region ADD (
  REGION_TYPE 		NUMBER(10,0)
);

ALTER TABLE csrimp.deleg_plan_deleg_region ADD (
  REGION_TYPE 		NUMBER(10,0)
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.
CREATE OR REPLACE VIEW csr.V$DELEG_PLAN_DELEG_REGION AS
	SELECT dpc.app_sid, dpc.deleg_plan_sid, dpdr.deleg_plan_col_deleg_id, dpc.deleg_plan_col_id, dpc.is_hidden,
		   dpcd.delegation_sid, dpdr.region_sid, dpdr.pending_deletion, dpdr.region_selection,
		   dpdr.tag_id, dpdr.region_type
	  FROM deleg_plan_deleg_region dpdr
	  JOIN deleg_plan_col_deleg dpcd ON dpdr.app_sid = dpcd.app_sid AND dpdr.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
	  JOIN deleg_plan_col dpc ON dpcd.app_sid = dpc.app_sid AND dpcd.deleg_plan_col_deleg_id = dpc.deleg_plan_col_deleg_id;

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../deleg_plan_pkg
@../unit_test_pkg

@../deleg_plan_body
@../schema_body
@../unit_test_body

@../campaigns/campaign_body

@../csrimp/imp_body

@update_tail
