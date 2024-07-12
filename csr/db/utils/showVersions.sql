set serveroutput on
declare
	v_version	number(10);
begin
	for r in (select owner, table_name
				from all_tables 
			   where table_name='VERSION'
			order by owner) loop
		begin
			execute immediate 'select db_version into :x from '||r.owner||'.'||r.table_name
			into v_version;
		exception
			when no_data_found then
				v_version := -1;
			when others then
				dbms_output.put_line(rpad(r.owner, 32)||sqlerrm);
		end;
		dbms_output.put_line(rpad(r.owner, 32)||v_version);
	end loop;
end;
/
