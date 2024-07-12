-- Please update version.sql too -- this keeps clean builds in sync
define version=268
@update_header

alter table customer add allow_partial_submit number(1) default 1 not null check (allow_partial_submit in (0,1));
@..\csr_data_pkg
@..\csr_data_body
@..\pending_pkg
@..\pending_body

@update_tail

