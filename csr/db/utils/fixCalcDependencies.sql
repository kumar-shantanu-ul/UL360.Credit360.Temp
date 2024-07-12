declare
	v_cnt	number(10) := 0;
begin
	user_pkg.logonadmin('&&host');
	for r in (
		select ind_sid, calc_xml, do_temporal_aggregation, calc_description, default_interval, case when ind_type = 2 then 1 else 0 end is_stored 
		  from ind 
		 where ind_type IN (1,2)
	)
	loop
		calc_pkg.SetCalcXMLAndDeps(
			in_act_id						=> security_pkg.getact,
			in_calc_ind_sid					=> r.ind_sid,
			in_calc_xml						=> r.calc_xml,
			in_is_stored 					=> r.is_stored, 
			in_default_interval				=> r.default_interval,
			in_do_temporal_aggregation		=> r.do_temporal_aggregation,
			in_calc_description				=> r.calc_description
		);
		v_cnt := v_cnt + 1;
	end loop;
	dbms_output.put_line(v_cnt||' calcs fixed');
end;
/
