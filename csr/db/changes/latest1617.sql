-- Please update version.sql too -- this keeps clean builds in sync
define version=1617
@update_header

declare
	v_cnt number;
begin
	select count(*) into v_cnt from all_ind_columns where table_owner='CSR' and table_name='DELEGATION' and column_name='PARENT_SID';
	if v_cnt = 0 then
		execute immediate 'create index csr.idx_delegation_parent on csr.DELEGATION(app_sid, parent_sid)';
	end if;
end;
/

@update_tail
