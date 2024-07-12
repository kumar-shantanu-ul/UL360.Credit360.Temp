-- Please update version.sql too -- this keeps clean builds in sync
define version=8
@update_header

alter table csrimp.val modify aggr_est_number number(10);
alter table csrimp.val rename column aggr_est_number to error_code;

@../imp_body.sql

@update_tail
