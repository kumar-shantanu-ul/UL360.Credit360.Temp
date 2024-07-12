-- Please update version.sql too -- this keeps clean builds in sync
define version=1357
@update_header

grant select,insert,update on csr.quick_survey to csrimp;

@../csrimp/imp_body
@../csr_data_body

@update_tail
