-- Please update version.sql too -- this keeps clean builds in sync
define version=1198
@update_header

@latest1198_packages

begin
	security.user_pkg.logonadmin;
	for r in (select distinct app_sid from cms.tab) loop
		security.security_pkg.debugmsg('doing '||r.app_sid);
		security.security_pkg.setapp(r.app_sid);
		cms.tab_pkg.refreshunmanaged(sys_context('security','app'));
		commit;
	end loop;
end;
/
       
@update_tail
