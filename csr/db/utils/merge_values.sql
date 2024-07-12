declare
	cursor c is
		select v.val_id, v.ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm,
			   v.source_type_id, v.val_number, v.error_code, v.entry_val_number, v.entry_measure_conversion_id,
			   v.changed_dtm, v.changed_by_sid
		  from csr.val v, csr.ind i
		 where i.app_sid = v.app_sid and v.ind_sid = i.ind_sid
		   and i.divisible != csr.csr_data_pkg.divisibility_divisible
		   and nvl(length(v.note),0) = 0
		   and not exists (select 1
		   					 from csr.val_file vf
		   					where vf.app_sid = v.app_sid and vf.val_id = v.val_id)
--		   and source_type_id not in (csr.csr_data_pkg.source_type_stored_calc, csr.csr_data_pkg.source_type_aggregator)
		   and source_type_id in (csr.csr_data_pkg.source_type_energy_star, csr.csr_data_pkg.source_type_rolled_forward)
		 order by v.region_sid, v.ind_sid, v.period_start_dtm;
	r c%rowtype;
	l c%rowtype;
	n number := 0;
	v_last_region_sid number;
begin
	security.user_pkg.logonadmin('&&1');
	open c;
	loop
		fetch c into r;
		exit when c%notfound;

		if v_last_region_sid != r.region_sid then
			commit;
		end if;
		v_last_region_sid := r.region_sid;
		
		if l.ind_sid = r.ind_sid and l.region_sid = r.region_sid and l.period_end_dtm = r.period_start_dtm and
		   (l.source_type_id = r.source_type_id or (
		   		l.source_type_id in (csr.csr_data_pkg.source_type_energy_star, csr.csr_data_pkg.source_type_rolled_forward) and
		   	  	r.source_type_id in (csr.csr_data_pkg.source_type_energy_star, csr.csr_data_pkg.source_type_rolled_forward)))
		   and csr.null_pkg.eq(l.val_number, r.val_number) and
		   csr.null_pkg.eq(l.error_code, r.error_code) and csr.null_pkg.eq(l.entry_val_number, r.entry_val_number) and
		   csr.null_pkg.eq(l.entry_measure_conversion_id, r.entry_measure_conversion_id) and
		   l.changed_dtm = r.changed_dtm and l.changed_by_sid = r.changed_by_sid then
		   
			-- values can be merged
			l.period_end_dtm := r.period_end_dtm;

			--if r.source_type_id not in (csr.csr_data_pkg.source_type_energy_star, csr.csr_data_pkg.source_type_rolled_forward) then
			--	raise_application_error(-20001, 'value '||r.val_id||' needs checking as we are trying to merge a value with source type '||r.source_type_id);
			--end if;

			--dbms_output.put_line('deleting merged value with id '||r.val_id||' starting '||r.period_start_dtm||' and ending '||
			--	r.period_end_dtm||' with value of '||r.val_number);
			delete from csr.val
			 where val_id = r.val_id;
			n := n + 1;
		else
			if n > 0 then
				--dbms_output.put_line('expanding value with id '||l.val_id||' which has merged '||n||' values and now starts '||l.period_start_dtm||' and ends '||
				--	l.period_end_dtm||' with value of '||l.val_number);
				update csr.val
				   set period_end_dtm = l.period_end_dtm
				 where val_id = l.val_id;
			end if;
			n := 0;
			l := r;
		end if;
	end loop;
	if n > 0 then
		--dbms_output.put_line('expanding value with id '||l.val_id||' which has merged '||n||' values and now starts '||l.period_start_dtm||' and ends '||
		--	l.period_end_dtm||' with value of '||l.val_number);
		update csr.val
		   set period_end_dtm = l.period_end_dtm
		 where val_id = l.val_id;
	end if;
	close c;
end;
/
commit;
