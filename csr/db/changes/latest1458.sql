-- Please update version.sql too -- this keeps clean builds in sync
define version=1458
@update_header

Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1031,'My jobs','Credit360.Portlets.MyBatchJobs', EMPTY_CLOB(),'/csr/site/portal/Portlets/MyBatchJobs.js');

-- menu changes
declare
	v_setup_sid security.security_pkg.t_sid_id;
	v_menu_sid security.security_pkg.t_sid_id;
begin
	security.user_pkg.logonadmin;

	for r in (select host,app_sid from csr.customer) loop
		security.security_pkg.setApp(r.app_sid);

		begin
			v_setup_sid := security.securableobject_pkg.getsidfrompath(null,r.app_sid,'menu/setup');			   
			security.menu_pkg.createMenu(sys_context('security','act'),
					v_setup_sid, 'csr_admin_jobs', 'Batch jobs', '/csr/site/admin/jobs/jobs.acds', 17, null, v_menu_sid);
		exception
			when security.security_pkg.object_not_found then
				null;
		end;
	end loop;
end;
/

@../batch_job_pkg
@../batch_job_body
@../deleg_plan_body

@update_tail
