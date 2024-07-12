begin
	for r in (select company_sid from company where app_sid=security_pkg.getapp and company_sid not in (select top_company_sid from customer_options))
	loop
		chain_link_pkg.updatecompany(r.company_sid);
	end loop;
end;
/