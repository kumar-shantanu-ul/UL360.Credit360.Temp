-- Please update version.sql too -- this keeps clean builds in sync
define version=1804
@update_header

begin
	update csr.std_factor set geo_country = 'ko' where geo_country = 'xk';
	delete from postcode.country where name = 'Kosovo' and country = 'xk';
end;
/

@update_tail