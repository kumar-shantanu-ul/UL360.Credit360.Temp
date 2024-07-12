define version=18
@update_header

create table chain.lee_company_duplicates (source_sid number(10), match_sid number(10));

declare
	v_name varchar2(1024);
begin
for r in (
	select * from chain.company
)
loop
	begin
		select TRIM(REGEXP_REPLACE(TRANSLATE(substr(name, 1, instr(name, ' ', -1, 1)), '.,-()/\''', '        '), '  +', ' ') || substr(name, instr(name, ' ', -1, 1) + 1)) into v_name
		from security.securable_object
		where sid_id = r.company_sid;

		update security.securable_object
		set name = v_name
		where sid_id = r.company_sid;
	exception
		when dup_val_on_index then
			for d in (
				select * from security.securable_object
				where parent_sid_id = (select parent_sid_id from security.securable_object where sid_id = r.company_sid)
				and name = v_name
				and sid_id <> r.company_sid
			)
			loop
				insert into chain.lee_company_duplicates values (r.company_sid, d.sid_id);
			end loop;
	end;
end loop;
end;
/

begin
	update chain.company set name = replace(name, '\', '/');
end;
/

@..\company_body.sql

@update_tail
