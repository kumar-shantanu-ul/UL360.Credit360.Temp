set feedback off
set serveroutput on
begin
if '&&1' is null then
	dbms_output.put_line(chr(10));
else
	dbms_output.put_line('&1');
end if;
end;
/
set feedback &&feedback