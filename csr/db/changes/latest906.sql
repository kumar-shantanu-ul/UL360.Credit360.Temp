-- Please update version.sql too -- this keeps clean builds in sync
define version=906
@update_header

ALTER TABLE csr.measure MODIFY custom_field VARCHAR2(2048);

@update_tail
