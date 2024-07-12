-- Please update version.sql too -- this keeps clean builds in sync
define version=358
@update_header

alter table customer add allow_val_edit number(1) default 0 not null check (allow_val_edit in (0,1));
-- keep old behaviour for existing customers
update customer set allow_val_edit = 1; 

@..\csr_app_body

@update_tail
