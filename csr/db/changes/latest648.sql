-- Please update version.sql too -- this keeps clean builds in sync
define version=648
@update_header

RENAME csr.deleg_tpl_id_seq TO deleg_plan_id_seq;

ALTER TABLE csr.deleg_tpl RENAME TO deleg_plan;
ALTER TABLE csr.deleg_tpl_role RENAME TO deleg_plan_role;
ALTER TABLE csr.deleg_tpl_region RENAME TO deleg_plan_region;
ALTER TABLE csr.deleg_tpl_deleg RENAME TO deleg_plan_deleg;
ALTER TABLE csr.deleg_tpl_deleg_region RENAME TO deleg_plan_deleg_region;
ALTER TABLE csr.deleg_for_tpl RENAME TO master_deleg;

ALTER TABLE csr.deleg_plan RENAME COLUMN deleg_tpl_id TO deleg_plan_id;
ALTER TABLE csr.deleg_plan_role RENAME COLUMN deleg_tpl_id TO deleg_plan_id;
ALTER TABLE csr.deleg_plan_region RENAME COLUMN deleg_tpl_id TO deleg_plan_id;
ALTER TABLE csr.deleg_plan_deleg RENAME COLUMN deleg_tpl_id TO deleg_plan_id;
ALTER TABLE csr.deleg_plan_deleg_region RENAME COLUMN deleg_tpl_id TO deleg_plan_id;

-- This script will fail because deleg_manage_pkg was renamed: ignore it
whenever oserror continue
@..\delegation_body
@..\deleg_manage_pkg
@..\deleg_manage_body

@update_tail
