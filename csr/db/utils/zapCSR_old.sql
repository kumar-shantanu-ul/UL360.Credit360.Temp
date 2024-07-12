SET SERVEROUTPUT ON
PROMPT EXTREME CAUTION ADVISED! THIS WILL *DESTROY* A WHOLE CR360 SITE
PROMPT ===============================================================
PROMPT DO NOT RUN ON LIVE DURING PEAK TIMES
PROMPT TAKE THE RELEASE LOCK WHEN RUNNING ON LIVE
PROMPT THIS WILL EXCLUSIVELY LOCK TABLES AND CRITICALLY AFFECT PERFORMANCE
PROMPT IF IN DOUBT, CONTACT A SENIOR DEVELOPER
PROMPT ===============================================================
PROMPT please enter: host name to destroy
alter session set ddl_lock_timeout=180;
declare
	v_app_sid						csr.customer.app_sid%TYPE;
begin
	begin
		security.user_pkg.logonadmin('&&1');
		v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	exception
		when security.security_pkg.object_not_found then
			-- hmm, ok -- the row in website is missing.  let's try looking in csr.customer
			begin
				select app_sid
				  into v_app_sid
				  from csr.customer
				 where lower(host) = lower('&&1');
				 
				 security.user_pkg.logonAdmin;
				 security.security_pkg.setapp(v_app_sid);
			exception
				when no_data_found then
					DBMS_OUTPUT.PUT_LINE('Host not found. Nothing to do.');
					return;
			end;			 
	end;
	 
	-- destroy CMS
	DBMS_OUTPUT.PUT_LINE('destroying cms...');

	cms.tab_pkg.DropAllTables();

	DELETE FROM cms.app_schema 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	DELETE FROM cms.tag
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	-- Eek. The delete stuff all seems a bit tied up in knots. Nasty hack alert.
--	if '&&1' in ('cd.credit360.com') then
--		begin
--			execute immediate 'drop user chaindemo cascade';
--		exception
--			when others then
--				null;
--		end;
--	end if;

	DBMS_OUTPUT.PUT_LINE('destroying app...');
	csr.csr_app_pkg.DeleteApp(in_reduce_contention => 1);
	
	commit;
end;
/
PROMPT If you now want to recreate a site with the same name, please IISReset (or wait 5 minutes) AND close all browser windows
exit;
/
