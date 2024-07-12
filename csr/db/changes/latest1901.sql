-- Please update version.sql too -- this keeps clean builds in sync
define version=1901
@update_header

update csr.region set geo_country = 'xk' where geo_country = 'ko';
delete from postcode.country where country = 'ko';

@update_tail