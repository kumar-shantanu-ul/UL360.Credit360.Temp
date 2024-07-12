declare
	v_move				NUMBER(1) := -- 1;
	v_val_id			val.val_id%TYPE;
	v_old_ind_sid		security_pkg.T_SID_ID := --9910674;
	v_new_ind_sid		security_pkg.T_SID_ID := --10186348;
	v_file_uploads		security_pkg.T_SID_IDS;
	v_host				VARCHAR2(200) := -- 'experian.credit360.com';
	v_period_start_dtm	DATE := --;
	v_period_end_dtm	DATE := --;
	v_delete_reason		VARCHAR2(1000) := --'Moved to new indicator to account for unit change';
begin
    user_pkg.logonadmin(v_host);
	for r in (
		select vc.changed_by_sid user_sid, v_new_ind_sid ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm,
			   v.val_number, v.error_code, v.flags, v.source_type_id, v.source_id, v.entry_measure_conversion_id,
			   v.entry_val_number, vc.reason, v.note, v.val_id
		  from val_converted v, val_change vc 
		 where v.LAST_VAL_CHANGE_ID = vc.val_change_id
		   and v.ind_sid = v_old_ind_sid
		   and v.source_type_id != 5
           and (v_period_start_dtm IS NULL OR v.period_start_dtm >= v_period_start_dtm) 
           and (v_period_end_dtm IS NULL OR v.period_end_dtm <= v_period_end_dtm)
	)
	loop
        v_file_uploads.delete;
        select file_upload_sid
          bulk collect into v_file_uploads
          from val_file
         where val_id = r.val_id;
		indicator_pkg.SetValueWithReasonWithSid(r.user_sid, r.ind_sid, r.region_sid, r.period_start_dtm, r.period_end_dtm, 
			  r.val_number, r.flags, r.source_type_id, r.source_id, r.entry_measure_conversion_id,
			  r.entry_val_number, r.error_code, 0, r.reason, r.note, 1, v_file_uploads, v_val_id);
		if v_move = 1 then
			indicator_pkg.DeleteVal(sys_context('security','act'), r.val_id, v_delete_reason);
		end if;
	end loop;
end;
/
