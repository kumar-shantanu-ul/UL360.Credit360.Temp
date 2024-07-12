-- Please update version.sql too -- this keeps clean builds in sync
define version=170
@update_header

set serveroutput on
begin
	for r in (select a.application_sid_id, so.sid_id
				from security.securable_object so, security.application a
			   where a.application_sid_id = so.parent_sid_id and lower(so.name) = 'delegations') loop
		update delegation
		   set parent_sid = r.application_sid_id
		 where parent_sid = r.sid_id;
		dbms_output.put_line('fixed '||sql%rowcount||' for '||r.application_sid_id);
	end loop;
end;
/
		 
@update_tail
