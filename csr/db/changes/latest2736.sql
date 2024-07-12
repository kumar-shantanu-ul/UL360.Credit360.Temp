-- Please update version.sql too -- this keeps clean builds in sync
define version=2736
@update_header

alter table csr.non_comp_default modify label varchar2(2048);
alter table csrimp.non_comp_default modify label varchar2(2048);

@update_tail
