-- Please update version.sql too -- this keeps clean builds in sync
define version=1275
@update_header

grant execute on cms.tab_pkg to security, csr, web_user;
alter table csr.dataview modify include_parent_region_names number(10);
begin
	for r in (select 1 from all_constraints where owner='CSR' and table_name='DATAVIEW' and constraint_name='CHK_DATAVIEW_INCL_PAR_REG') loop
		execute immediate 'alter table csr.dataview drop constraint chk_dataview_incl_par_reg';
	end loop;
end;
/
alter table csrimp.dataview modify include_parent_region_names number(10);

@update_tail
	