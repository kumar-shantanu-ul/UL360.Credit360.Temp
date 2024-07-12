PROMPT Completely deletes a delegation and all merged values
PROMPT Enter host name, delegation sid

define host = "&&1"
define sid  = "&&2"

declare
	v_cnt 				number(10) :=0;
	v_app_sid			security_pkg.T_SID_ID;
	v_deleg_sid			number(10) := &sid;
begin
    security.user_pkg.LogonAdmin('&host');
    v_app_sid := SYS_CONTEXT('SECURITY','APP');
	for r in (
		select ind_sid, region_sid,start_dtm,end_dtm 
		  from csr.delegation d, csr.delegation_ind di, csr.delegation_region dr 
		 where d.delegation_sid = v_deleg_sid 
		   and di.delegation_sid =v_deleg_sid 
		   and dr.delegation_sid = v_deleg_sid
		   and d.delegation_Sid = di.delegation_sid
		   and d.delegation_sid = dr.delegation_sid
		   and d.app_sid = v_app_sid
	)
	loop
		for v in (
			select val_id 
			  from csr.val
			 where ind_sid = r.ind_sid 
			   and region_sid = r.region_sid 
			   and period_start_dtm >= r.start_dtm 
			   and period_end_dtm <=r.end_dtm 
			   and app_sid = v_app_sid
		)
		loop	
			v_cnt := v_cnt + 1;
			csr.indicator_pkg.deleteval(sys_context('SECURITY','ACT'), v.val_id, 'Terminated delegation');
		end loop;
	end loop;
	dbms_output.put_line('deleted '||v_cnt||' values');
	security.securableobject_pkg.deleteso(sys_context('SECURITY','ACT'), v_deleg_sid);
end;
/
