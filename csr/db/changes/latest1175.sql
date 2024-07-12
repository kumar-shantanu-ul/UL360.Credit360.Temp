-- Please update version.sql too -- this keeps clean builds in sync
define version=1175
@update_header

alter table csrimp.measure modify custom_field varchar2(4000);

@update_tail
