-- Please update version.sql too -- this keeps clean builds in sync
define version=6
@update_header

alter table delegation_ind drop column delegation_grid_id;

@../imp_body.sql

@update_tail
