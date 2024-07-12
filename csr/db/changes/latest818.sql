-- Please update version.sql too -- this keeps clean builds in sync
define version=818
@update_header

alter table csr.aggregate_ind_calc_job modify processing number(1) default 0;

@update_tail