-- Please update version.sql too -- this keeps clean builds in sync
define version=196
@update_header

create index ix_ind_aggr_est_ind_sid on ind(aggr_estimate_with_ind_sid)
tablespace indx;

@update_tail

