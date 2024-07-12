begin
	user_pkg.logonadmin('worldbank.credit360.com');
	for r in (
		select ind_sid, description, active, measure_sid, multiplier, 
			scale, format_mask, target_direction, gri, pos, info_xml, csr_data_pkg.DIVISIBILITY_DIVISIBLE divisible, start_month,
			ind_type, aggregate, factor_type_id, gas_measure_sid, gas_type_id, map_to_ind_sid,
			core, roll_forward, normalize, prop_down_region_tree_sid
		  from ind 
		  where ind_sid in (8376502,8376504,8376505,8376503,8376501,9096688,10191351,10191353,10191354,10191352,10191350,10115713,10115714,10115715,10115716,10115717,10115718,10115719,10115720,10115697,10115698,10115699,10115700,10115701,10115702,10115703,10115704,10115705,10115706,10115707,10115708,10115709,10115710,10115711,10115712,10115721,10115722,10115723,10115724,10115725,10115726,10115727,10115728,10115729)
	)
	loop
		indicator_pkg.AmendIndicator(security_pkg.getact, r.ind_sid, r.description, r.active, r.measure_sid, r.multiplier, 
			r.scale, r.format_mask, r.target_direction, r.gri, r.pos, r.info_xml, r.divisible, r.start_month,
			r.ind_type, r.aggregate, r.factor_type_id, r.gas_measure_sid, r.gas_type_id, r.core, r.roll_forward, r.normalize,
			r.prop_down_region_tree_sid);
	end loop;
end;
/
