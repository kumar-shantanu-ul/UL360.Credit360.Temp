define host='&&1'
declare
	v_n number := 0;
begin
	security.user_pkg.logonadmin('&host');
	for r in (
		select region_Sid
		  from csr.region 
		  where link_to_region_sid in (select region_sid from csr.region start with parent_sid = (select trash_sid from csr.customer) connect by prior region_sid = parent_sid)
			   start with parent_sid = app_sid connect by prior app_sid = app_sid and prior region_sid  = parent_sid) loop
		security.securableobject_pkg.deleteso(sys_context('security','act'), r.region_sid);
		v_n := v_n+1;
	end loop;
	dbms_output.put_line('deleted '||v_n||' dead links');
	commit;
end;
/
