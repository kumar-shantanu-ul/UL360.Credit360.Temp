prompt Enter host
begin
	security.user_pkg.logonadmin('&&1');
	for r in (select ind_sid from csr.v$ind 
		where ( description like 'CO2 of CO2 of%' or
			    description like 'CO2e of CO2 of%' or
				description like 'CH4 of CO2 of%' or
				description like 'N2O of CO2 of%' or
				
			    description like 'CO2 of CO2e of%' or
			    description like 'CO2e of CO2e of%' or
				description like 'CH4 of CO2e of%' or
				description like 'N2O of CO2e of%' or
				
			    description like 'CO2 of CH4 of%' or
			    description like 'CO2e of CH4 of%' or
				description like 'CH4 of CH4 of%' or
				description like 'N2O of CH4 of%' or
			    
				description like 'CO2 of N2O of%' or
			    description like 'CO2e of N2O of%' or
				description like 'CH4 of N2O of%' or
				description like 'N2O of N2O of%' )) loop
		security.securableobject_pkg.deleteso(sys_context('security','act'), r.ind_sid);
	end loop;
end;
/
