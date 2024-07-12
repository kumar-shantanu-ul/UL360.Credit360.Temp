-- Please update version.sql too -- this keeps clean builds in sync
define version=967
@update_header

alter table csr.measure modify custom_field varchar2(4000);

@update_tail
