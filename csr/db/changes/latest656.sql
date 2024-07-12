-- Please update version.sql too -- this keeps clean builds in sync
define version=656
@update_header

DROP SEQUENCE csr.deleg_plan_id_seq;

ALTER TABLE csr.deleg_plan_region RENAME COLUMN deleg_plan_id TO deleg_plan_sid;
ALTER TABLE csr.deleg_plan_role RENAME COLUMN deleg_plan_id TO deleg_plan_sid;
ALTER TABLE csr.deleg_plan_deleg_region RENAME COLUMN deleg_plan_id TO deleg_plan_sid;
ALTER TABLE csr.deleg_plan_deleg RENAME COLUMN deleg_plan_id TO deleg_plan_sid;
ALTER TABLE csr.deleg_plan RENAME COLUMN deleg_plan_id TO deleg_plan_sid;

GRANT EXECUTE ON csr.deleg_plan_pkg to SECURITY;

@..\deleg_plan_pkg
@..\deleg_plan_body

@update_tail


