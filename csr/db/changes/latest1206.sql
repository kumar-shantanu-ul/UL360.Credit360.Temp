-- Please update version.sql too -- this keeps clean builds in sync
define version=1206
@update_header

declare
	v_exists number;
begin
	select count(*)
	  into v_exists
	  from all_indexes 
	 where owner='CSR' and index_name='IX_DELEG_IND_GROUP_DELEG';
	if v_exists = 0 then
		execute immediate 'create index csr.ix_deleg_ind_group_deleg on csr.deleg_ind_group (app_sid, delegation_sid)';
	end if;
	
	select count(*)
	  into v_exists
	  from all_indexes 
	 where owner='CSR' and index_name='IX_DELG_IND_GRP_MEM_DELG_IND';
	if v_exists = 0 then
		execute immediate 'create index csr.ix_delg_ind_grp_mem_delg_ind on csr.deleg_ind_group_member (app_sid, delegation_sid, ind_sid)';
	end if;
end;
/
	
@update_tail