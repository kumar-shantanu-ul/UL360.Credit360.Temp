-- Please update version.sql too -- this keeps clean builds in sync
define version=661
@update_header

ALTER TABLE csr.deleg_plan_deleg RENAME COLUMN hidden TO is_hidden;
ALTER TABLE csr.deleg_plan_deleg ADD CONSTRAINT CHK_DPD_IS_HIDDEN CHECK (IS_HIDDEN in (0, 1));
ALTER TABLE csr.deleg_plan_role ADD CONSTRAINT PK891 PRIMARY KEY (APP_SID, DELEG_PLAN_SID, ROLE_SID);

@..\deleg_plan_body

@update_tail
