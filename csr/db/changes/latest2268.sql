-- Please update version.sql too -- this keeps clean builds in sync
define version=2268
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
	for r in (select * from all_indexes where owner='CHAIN' and index_name='IX_ALERT_ENTRY_ALERT_ENTRY_T') loop
		execute immediate 'drop index '||r.owner||'.'||r.index_name;
	end loop;
	csr.createIndex('create index chain.ix_alert_entry_alrt_en_type on chain.alert_entry (alert_entry_type_id)');
end;
/

drop procedure csr.createIndex;

@update_tail
