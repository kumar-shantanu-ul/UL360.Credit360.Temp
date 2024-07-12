-- Please update version.sql too -- this keeps clean builds in sync
define version=2266
@update_header

create or replace procedure csr.createIndex(
	in_sql							in	varchar2
) authid current_user
as
	e_name_in_use					exception;
	pragma exception_init(e_name_in_use, -00955);
begin
	begin
		dbms_output.put_line(in_sql);
		execute immediate in_sql;
	exception
		when e_name_in_use then
			null;
	end;
end;
/

begin
	for r in (select * from all_indexes where owner='CHAIN' and index_name='IX_COMPANY_TYPE__PRIMARY_COMPA') loop
		execute immediate 'drop index '||r.owner||'.'||r.index_name;
	end loop;
	csr.createIndex('create index csr.ix_cal_event_owner_user_sid on csr.calendar_event_owner (app_sid, user_sid)');
end;
/

drop procedure csr.createIndex;

@update_tail
