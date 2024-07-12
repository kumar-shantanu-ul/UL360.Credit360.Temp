-- Please update version.sql too -- this keeps clean builds in sync
define version=700
@update_header

ALTER TABLE csr.CUSTOMER ADD (FOGBUGZ_SAREA VARCHAR2(50));

@update_tail
