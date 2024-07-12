-- Please update version too -- this keeps clean builds in sync
define version=1807
@update_header

update csr.std_factor set geo_country = 'xk' where geo_country = 'ko';

@update_tail