exec user_pkg.logonadmin('&&1');

update security.user_table
   set language = 'en',
	culture = 'en-US',
	timezone = 'America/Los_Angeles'
	where sid_id in (
	select csr_user_sid from csr_user where csr_user_sid >= 100000
	 minus select csr_user_sid from superadmin 
 );
 	
 /*
select distinct language, culture, timezone
  from security.user_table ut
 where sid_id in (
	select csr_user_sid from csr_user minus select csr_user_sid from superadmin
 );
 */