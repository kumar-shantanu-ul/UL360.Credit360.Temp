-- Please update version.sql too -- this keeps clean builds in sync
define version=657
@update_header

ALTER TABLE csr.deleg_plan_deleg
	ADD HIDDEN NUMBER(1, 0) DEFAULT 0 NOT NULL;

@update_tail


