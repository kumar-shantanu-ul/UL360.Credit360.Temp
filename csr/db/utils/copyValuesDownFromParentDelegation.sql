-- copy values down from parent delegation
declare
	v_id number(10);
begin
	for r in (
		select sc.sheet_id, svp.ind_sid, svp.region_sid, svp.val_number, svp.note, svp.entry_measure_conversion_id, svp.entry_val_number, svp.is_inherited, svp.status, svp.last_sheet_value_change_id, svp.alert, svp.flag
		 from delegation dp
			join delegation dc on dc.parent_sid = dp.delegation_sid
			join sheet sp on dp.delegation_sid = sp.delegation_sid
			join sheet sc on dc.delegation_sid = sc.delegation_sid and sp.start_dtm = sc.start_dtm
			join sheet_value svp on sp.sheet_id = svp.sheet_id
			left join sheet_value svc on sc.sheet_Id = svc.sheet_Id and svc.ind_sid = svp.ind_sid and svc.region_sid = svp.region_Sid
		where dp.delegation_Sid = 10336004
	)
	loop
		sheet_pkg.SaveValue(
			in_act_id				=> security_pkg.getact, 
			in_sheet_id				=> r.sheet_id,
			in_ind_sid				=> r.ind_sid, 
			in_region_sid			=> r.region_sid, 
			in_val_number			=> r.val_number, 
			in_entry_conversion_id	=> r.entry_measure_conversion_id, 
			in_entry_val_number		=> r.entry_val_number,
			in_note					=> r.note,
			in_reason				=> 'Copied down from parent', 
			in_status				=> r.status, 
			in_file_count			=> 0, 
			in_flag					=> r.flag, 
			in_write_history		=> 1,
			out_val_id				=> v_id);
	end loop;
end;
/
