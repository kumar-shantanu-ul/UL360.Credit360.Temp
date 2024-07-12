-- Please update version.sql too -- this keeps clean builds in sync
define version=1057
@update_header

alter table csr.customer rename column calc_priority to calc_job_priority;

@update_tail
