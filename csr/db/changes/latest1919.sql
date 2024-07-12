-- Please update version.sql too -- this keeps clean builds in sync
define version=1919
@update_header

-- Delete overlapping factors
delete from csr.std_factor where std_factor_id = 184325122;
delete from csr.std_factor where std_factor_id = 184325125;
delete from csr.std_factor where std_factor_id = 184325127;
delete from csr.std_factor where std_factor_id = 184325129;

@update_tail