-- Please update version.sql too -- this keeps clean builds in sync
define version=650
@update_header

ALTER TABLE csr.deleg_plan_deleg_region
RENAME COLUMN map_to_deleg_sid TO maps_to_deleg_sid;

@..\deleg_plan_pkg
@..\deleg_plan_body
@..\delegation_body

@update_tail
