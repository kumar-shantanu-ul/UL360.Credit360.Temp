-- Please update version.sql too -- this keeps clean builds in sync
define version=653
@update_header

ALTER TABLE csr.deleg_plan MODIFY name VARCHAR2(1023);

@update_tail


