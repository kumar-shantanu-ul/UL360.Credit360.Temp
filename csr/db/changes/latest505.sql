-- Please update version.sql too -- this keeps clean builds in sync
define version=505
@update_header

alter table imp_val modify val null;

@..\imp_pkg
@..\imp_body
 
@update_tail
