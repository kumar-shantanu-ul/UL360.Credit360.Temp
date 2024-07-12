-- Please update version.sql too -- this keeps clean builds in sync
define version=2219
@update_header

begin
	for r in (select * from all_constraints where owner='CSRIMP' and table_name='DELEG_GRID_VARIANCE' and constraint_name='FK_DEL_GRID_VAR_IND') loop
		dbms_output.put_line('alter table csrimp.deleg_grid_variance drop constraint fk_del_grid_var_ind');
	end loop;
end;
/

grant select,insert,update,delete on csrimp.deleg_grid_variance to web_user;

@update_tail
