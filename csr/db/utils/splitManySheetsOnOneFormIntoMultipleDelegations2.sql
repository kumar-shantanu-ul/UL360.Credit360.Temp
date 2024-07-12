

declare
	TYPE t_map IS TABLE OF number(10) INDEX BY BINARY_INTEGER;
	map t_map;
	v_new_deleg_sid		security_pkg.T_SID_ID;
	v_act				security_pkg.T_ACT_ID;
begin
	user_pkg.LogonAuthenticatedPath(0, '//csr/users/richard', 10000, v_act);
	for r in (
		select d.delegation_sid, d.parent_sid, d.app_sid, level lvl, name, dr.description region_description, dr.aggregate_to_region_sid, dr.region_sid, 
			connect_by_root region_sid root_region_sid, connect_by_root d.delegation_sid root_delegation_sid
		  from delegation d, delegation_region dr
		 where d.delegation_sid = dr.delegation_Sid
		 start with d.delegation_sid = 9112069
		connect by prior d.delegation_sid = d.parent_sid
		   and prior region_sid = dr.aggregate_to_region_sid 
	)
	loop
		IF r.parent_sid = r.app_sid THEN
			-- top
			delegation_pkg.CopyDelegation(v_act, r.delegation_sid, r.name||' - '||r.region_Description, v_new_deleg_sid);
			dbms_output.put_line('New top deleg '||r.name||' - '||r.region_Description);
		ELSE
			delegation_pkg.CopyNonTopDelegation(v_act, r.delegation_sid, map(r.parent_sid), null, v_new_deleg_sid);
		END IF;
		map(r.delegation_sid) := v_new_deleg_sid;
		INSERT INTO DELEGATION_REGION (delegation_sid, region_sid, pos, description, aggregate_to_region_sid)
			VALUES (v_new_deleg_sid, r.region_sid, 1, r.region_description, r.aggregate_to_region_sid);
		dbms_output.put_line('Copied '||r.delegation_sid||' for '||r.region_description||' as '||v_new_deleg_sid);
	end loop;
end;