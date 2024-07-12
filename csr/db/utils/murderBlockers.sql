begin
	for r in (
		select s2.sid,s2.serial#,s2.username,s2.status,s2.osuser,s2.machine,
			   s2.program, s1.sid blocked_sid,s1.serial# blocked_serial,    
			   s1.username blocked_username,s1.status blocked_status,       
			   s1.osuser blocked_osuser,s1.machine blocked_machine,         
			   s1.program blocked_program                                   
		  from v$session s1, v$session s2                                   
		 where s1.blocking_session is not null                              
		   and s1.blocking_session = s2.sid) loop
   
		begin
			execute immediate 'ALTER SYSTEM KILL SESSION '''||r.sid||','||r.serial#||''' IMMEDIATE';
		exception
			when others then null;
		end;
	end loop;
end;
/
