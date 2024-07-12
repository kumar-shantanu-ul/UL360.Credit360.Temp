--Please update version.sql too -- this keeps clean builds in sync
define version=2604
@update_header

begin
	update csr.region r
	set    region_type = csr.csr_data_pkg.REGION_TYPE_PROPERTY
	where  r.region_sid in (
		select region_sid
		from   csr.property_division
	);
end;
/

@../division_body
	
@update_tail
