-- Please update version.sql too -- this keeps clean builds in sync
define version=1278
@update_header

begin
	for r in (select 1 from all_constraints where owner='CSRIMP' and table_name='DATAVIEW' and constraint_name='CHK_DATAVIEW_INCL_PAR_REG') loop
		execute immediate 'alter table csrimp.dataview drop constraint chk_dataview_incl_par_reg';
	end loop;
end;
/

@../csrimp/imp_body

@update_tail
