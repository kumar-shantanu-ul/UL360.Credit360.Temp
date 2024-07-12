set serveroutput on
PROMPT Enter host
declare
	v_cnt number := 0;
begin
	security.user_pkg.logonadmin('&&1');

	for r in (select *
			    from (select i.ind_sid, x.sid uses_sid
						from csr.ind i, xmltable('//*' passing i.calc_xml columns sid number(10) path '@sid') x
					   where i.app_sid = sys_context('security', 'app') and sid is not null)
			   where uses_sid not in (select ind_sid from csr.ind where app_sid = sys_context('security', 'app'))) loop

		dbms_output.put_line('clearing calc referencing ind '||r.uses_sid||' from ind with sid '||r.ind_sid);

		update csr.ind
	   	   set ind_type = 0, calc_xml = null
	   	 where ind_sid = r.ind_sid;
	   	 
		delete from csr.calc_dependency
		 where calc_ind_sid = r.ind_sid;
		 
		v_cnt := v_cnt + 1;
	end loop;
	dbms_output.put_line(v_cnt || ' calcs cleared');
end;
/
	   	  