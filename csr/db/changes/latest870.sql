-- Please update version.sql too -- this keeps clean builds in sync
define version=870
@update_header

alter table csrimp.ind add calc_fixed_start_dtm date;
alter table csrimp.ind add calc_fixed_end_dtm date;

@update_tail