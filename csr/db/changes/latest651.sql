-- Please update version.sql too -- this keeps clean builds in sync
define version=651
@update_header

ALTER TABLE csr.deleg_plan_deleg
DROP COLUMN map_to_deleg_sid CASCADE CONSTRAINTS;

@..\deleg_plan_pkg
@..\deleg_plan_body
@..\delegation_body

@update_tail
