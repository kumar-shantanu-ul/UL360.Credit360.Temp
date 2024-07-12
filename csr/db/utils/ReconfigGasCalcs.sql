begin
    security.user_pkg.logonadmin('&&1', 86400);
	for r in (select ind_sid from csr.ind where factor_type_id is not null and gas_type_id is null) loop
		csr.indicator_pkg.CreateGasIndicators(r.ind_sid);
	end loop;
end;
/
