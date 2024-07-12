declare
	v_sheet_id		sheet.sheet_id%TYPE;
	v_end_dtm   	sheet.end_dtm%TYPE;
	v_act			security_pkg.T_ACT_ID;
begin
	user_pkg.LogonAuthenticatedPath(0, '//csr/users/richard', 10000, v_act);
	-- do all sub delegations
	for c in (
		select delegation_sid from delegation start with delegation_sid = &&DELEGATION_SID connect by prior delegation_sid = parent_sid
	)
	loop
		update delegation set start_dtm = '&&START_DTM' where delegation_sid = c.delegation_sid;
		for r in (
			select d.delegation_sid, d.start_dtm, min(s.start_dtm) sheet_start_dtm
			  from delegation d, sheet s 
			 where d.delegation_sid = c.delegation_sid
			   and d.delegation_sid = s.delegation_sid
			 group by d.delegation_sid, d.start_dtm, d.end_dtm
		)
		loop
			v_end_dtm := r.start_dtm;
			loop
				exit when v_end_dtm >= r.sheet_start_dtm; 
				sheet_pkg.CreateSheet(v_act, r.delegation_sid, v_end_dtm, SYSDATE, v_sheet_id, v_end_dtm);
			end loop;
		end loop;
	end loop;
	commit;
end;
/
