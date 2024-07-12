-- Please update version.sql too -- this keeps clean builds in sync
define version=788
@update_header

ALTER TABLE csr.customer ADD propagate_deleg_values_down NUMBER(1, 0) DEFAULT 0 NOT NULL;

@update_tail
