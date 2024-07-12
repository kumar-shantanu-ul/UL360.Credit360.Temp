-- Please update version.sql too -- this keeps clean builds in sync
define version=655
@update_header

ALTER TABLE csr.deleg_plan_deleg_region DROP CONSTRAINT PK893;
ALTER TABLE csr.deleg_plan_deleg_region ADD CONSTRAINT PK893 PRIMARY KEY (app_sid, deleg_plan_id, delegation_sid, region_sid);

@update_tail


