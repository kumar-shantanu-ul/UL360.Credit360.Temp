-- Please update version.sql too -- this keeps clean builds in sync
define version=371
@update_header

@..\sqlreport_body

begin
	for r in (select host from customer) loop
		begin
			user_pkg.logonAdmin(r.host);
			--dbms_output.put_line(r.host);
			sqlreport_pkg.EnableReport('csr.delegation_pkg.GetReportSubmissionPromptness');
			security_pkg.setapp(null);
		exception
			when security_pkg.object_not_found then
				null;
		end;
	end loop;
end;
/

@update_tail
