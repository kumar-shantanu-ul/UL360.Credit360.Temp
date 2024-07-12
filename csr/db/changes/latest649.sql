-- Please update version.sql too -- this keeps clean builds in sync
define version=649
@update_header

begin
	for r in (select 1 from all_objects where owner='CSR' and object_type='PACKAGE' and object_name='DELEG_MANAGE_PKG') loop
		execute immediate 'DROP PACKAGE csr.deleg_manage_pkg';
	end loop;
end;
/

@..\deleg_plan_pkg
@..\deleg_plan_body
@..\role_body

grant execute on csr.deleg_plan_pkg to web_user;

@update_tail
