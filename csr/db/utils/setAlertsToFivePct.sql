declare
	v_act varchar(38);
begin
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	for r in (select ind_sid from ind)
    loop 
		indicator_pkg.setWindow(v_act, r.ind_sid, 'y', .95, 1.05);
		indicator_pkg.setWindow(v_act, r.ind_sid, 'q', .95, 1.05);
		indicator_pkg.setWindow(v_act, r.ind_sid, 'm', .95, 1.05);    
    end loop;
end;
