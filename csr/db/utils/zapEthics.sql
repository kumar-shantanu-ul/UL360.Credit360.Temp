whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

PROMPT >> Enter a site to cleanup (e.g. test.credit360.com);

begin
	user_pkg.logonadmin('&&1');
	delete from QUESTION_SENT_LOG where app_sid = SYS_CONTEXT('SECURITY', 'APP');
	delete from COURSE_PARTICIPANT where app_sid = SYS_CONTEXT('SECURITY', 'APP');
	delete from TEST_PARTICIPANT where app_sid = SYS_CONTEXT('SECURITY', 'APP');
	delete from PARTICIPANT where app_sid = SYS_CONTEXT('SECURITY', 'APP');
	delete from COURSE_QUESTION where app_sid = SYS_CONTEXT('SECURITY', 'APP');
	delete from COURSE where app_sid = SYS_CONTEXT('SECURITY', 'APP');
	delete from COMPANY_QUESTION where app_sid = SYS_CONTEXT('SECURITY', 'APP');
	delete from QUESTION_ANSWER where app_sid = SYS_CONTEXT('SECURITY', 'APP');
	delete from QUESTION_TAG where app_sid = SYS_CONTEXT('SECURITY', 'APP');
	delete from TAG where app_sid = SYS_CONTEXT('SECURITY', 'APP');
	delete from QUESTION where app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	for r in (
		select * 
		  from company
		 where app_sid = SYS_CONTEXT('SECURITY', 'APP')
	) loop
		securableobject_pkg.DeleteSO(security_pkg.GetACT(), r.company_sid);
	end loop;	
end;
/

commit;

exit

