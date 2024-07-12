-- Please update version.sql too -- this keeps clean builds in sync
define version=261
@update_header

begin
	delete from ind_start_point where user_sid in (select csr_user_sid from csr_user where guid='77646D7A-A70E-E923-2FF6-2FD960873984' and csr_user_sid<>5);
	delete from csr_user where csr_user_sid in (select csr_user_sid from csr_user where guid='77646D7A-A70E-E923-2FF6-2FD960873984' and csr_user_sid<>5);
	begin
		user_pkg.logonadmin;
		securableobject_pkg.deleteso(sys_context('security','act'),
			securableobject_pkg.getsidfrompath(sys_context('security','act'), 0, '//csr/users/guest'));
	exception
		when security_pkg.object_not_found then
			null;
	end;
	delete from superadmin where guid='77646D7A-A70E-E923-2FF6-2FD960873984';
end;
/

@update_tail
