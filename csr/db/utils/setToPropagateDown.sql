begin
	user_pkg.logonadmin('worldbank.credit360.com');
	for r in (
		select ind_sid, description, active, measure_sid, multiplier, 
			scale, format_mask, target_direction, gri, pos, info_xml, divisible, start_month,
			ind_type, 'DOWN', factor_set_id, core
		  from ind 
		 start with ind_sid = 8311709 
		connect by parent_sid = prior ind_sid
	)
	loop
		indicator_pkg.AmendIndicator(security_pkg.getact, r.ind_sid, r.description, r.active, r.measure_sid, r.multiplier, 
			r.scale, r.format_mask, r.target_direction, r.gri, r.pos, r.info_xml, r.divisible, r.start_month,
			r.ind_type, 'DOWN', r.factor_set_id, r.core);
	end loop;
end;
/
