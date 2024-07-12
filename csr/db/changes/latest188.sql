-- Please update version.sql too -- this keeps clean builds in sync
define version=188
@update_header

alter table ind add constraint ck_ind_type check (ind_type in (0,1,2));

@update_tail
