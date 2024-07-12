-- Please update version.sql too -- this keeps clean builds in sync
define version=1714
@update_header

grant update on csr.aggregate_ind_group to csrimp;

@../csrimp/imp_body

@update_tail
