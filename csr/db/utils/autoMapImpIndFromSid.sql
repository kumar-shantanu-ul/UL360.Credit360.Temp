PROMPT imp_session_Sid, host
declare
	v_imp_session_sid	security.security_pkg.T_SID_ID := &&1; 
begin
	user_pkg.logonadmin('&&2');
	for r in (
		select distinct ii.imp_ind_id, ii.description
		  from imp_val iv
			join imp_ind ii on iv.imp_ind_id = ii.imp_ind_id
		 where imp_session_sid = v_imp_session_sid
	)
	loop
		update imp_ind set maps_to_ind_sid = TO_NUMBER(description) where imp_ind_Id = r.imp_ind_id;
	end loop;

	imp_pkg.insertConflicts(security.security_pkg.getact, v_imp_session_sid);
end;
/