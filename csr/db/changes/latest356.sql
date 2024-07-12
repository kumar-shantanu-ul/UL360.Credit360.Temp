-- Please update version.sql too -- this keeps clean builds in sync
define version=356
@update_header

alter table csr.pending_val_log modify (param_1 varchar2(4000), param_2 varchar2(4000), param_3 varchar2(4000));

@update_tail
