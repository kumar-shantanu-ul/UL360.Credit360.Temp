-- Please update version.sql too -- this keeps clean builds in sync
define version=607
@update_header

-- removes trashed gas inds which break the calc engine -- the bug that left these in the trash has been fixed (mostly, customers can still delete them manually)
begin
	for s in (select host from csr.customer where use_carbon_emission=1) loop
		dbms_output.put_line('doing '||s.host);
		user_pkg.logonadmin(s.host);
		for r in (select ind_sid, description from csr.ind where parent_sid = securableobject_pkg.getsidfrompath(sys_context('security','act'), sys_context('security','app'), 'Trash') and gas_type_id is not null) loop
			dbms_output.put_line('deleting trashed ind '||r.description||' ('||r.ind_sid||')');
			securableobject_pkg.deleteso(sys_context('security','act'), r.ind_sid);
		end loop;
	end loop;
end;
/

@update_tail

