declare
	v_sid		security.security_pkg.T_SID_ID;
begin
	security.user_pkg.logonadmin('&&1');

	csr.measure_pkg.CreateMeasure(
		in_name					    	=> 'usd',
		in_description		    		=> 'USD',
		in_scale						=> 2,
		in_format_mask		    		=> '#,##0',
		in_std_measure_conversion_id	=> 1,
		in_pct_ownership_applies    	=> 0,
		out_measure_sid			    	=> v_sid
	);
	
	csr.measure_pkg.CreateMeasure(
		in_name					    	=> 'kwh',
		in_description		    		=> 'kWh',
		in_scale						=> 2,
		in_format_mask		    		=> '#,##0',
		in_std_measure_conversion_id	=> 1,
		in_pct_ownership_applies    	=> 0,
		out_measure_sid			    	=> v_sid
	);

	csr.measure_pkg.CreateMeasure(
		in_name					    	=> 'tonnes',
		in_description		    		=> 'Tonnes',
		in_scale						=> 2,
		in_format_mask		    		=> '#,##0',
		in_std_measure_conversion_id	=> 1,
		in_pct_ownership_applies    	=> 0,
		out_measure_sid			    	=> v_sid
	);

	csr.measure_pkg.CreateMeasure(
		in_name					    	=> 'miles',
		in_description		    		=> 'Miles',
		in_scale						=> 2,
		in_format_mask		    		=> '#,##0',
		in_std_measure_conversion_id	=> 1,
		in_pct_ownership_applies    	=> 0,
		out_measure_sid			    	=> v_sid
	);

	csr.measure_pkg.CreateMeasure(
		in_name					    	=> 'm3',
		in_description		    		=> 'm3',
		in_scale						=> 2,
		in_format_mask		    		=> '#,##0',
		in_std_measure_conversion_id	=> 1,
		in_pct_ownership_applies    	=> 0,
		out_measure_sid			    	=> v_sid
	);

	csr.measure_pkg.CreateMeasure(
		in_name					    	=> 'gallons',
		in_description		    		=> 'Gallons',
		in_scale						=> 2,
		in_format_mask		    		=> '#,##0',
		in_std_measure_conversion_id	=> 1,
		in_pct_ownership_applies    	=> 0,
		out_measure_sid			    	=> v_sid
	);
end;
/
