-- Please update version.sql too -- this keeps clean builds in sync
define version=301
@update_header

declare
	found number;
begin
	select count(*) into found from all_tables where owner = 'CSR' and table_name = 'PENDING_ENTRY_IND';

	if found = 0 then
		execute immediate('CREATE GLOBAL TEMPORARY TABLE pending_entry_ind (pending_ind_id NUMBER(10,0)) ON COMMIT DELETE ROWS');
	end if;
end;
/

@..\pending_pkg
@..\pending_body

@update_tail
