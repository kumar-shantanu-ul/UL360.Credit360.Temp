whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

SET SERVEROUTPUT ON

VAR host NVARCHAR2(4000)
VAR language NVARCHAR2(4000)
VAR culture NVARCHAR2(4000)
VAR timezone NVARCHAR2(4000)

ACCEPT host CHAR PROMPT 'Host (e.g. example.credit360.com): '

begin

if '&host' is null then
	raise_application_error(-20001, 'Host must be set');
end if;

user_pkg.LogonAdmin('&host');

end;
/

select language, culture, timezone, count(*) "COUNT"
from security.user_table
where sid_id in (select csr_user_sid from csr_user where csr_user_sid >= 100000 minus select csr_user_sid from superadmin)
group by language, culture, timezone
order by language, culture, timezone;

ACCEPT language CHAR DEF '' PROMPT 'Language (e.g. en; defaults to NULL): '
ACCEPT culture CHAR DEF '' PROMPT 'Culture (e.g. en-US; note captitalization; defaults to NULL): '
ACCEPT timezone CHAR DEF '' PROMPT 'Time zone (e.g. America/Los_Angeles; defaults to NULL): '

begin

update security.user_table
set language = '&language', culture = '&culture', timezone = '&timezone'
where sid_id in (select csr_user_sid from csr_user where csr_user_sid >= 100000 minus select csr_user_sid from superadmin);

end;
/

select language, culture, timezone, count(*) "COUNT"
from security.user_table
where sid_id in (select csr_user_sid from csr_user where csr_user_sid >= 100000 minus select csr_user_sid from superadmin)
group by language, culture, timezone
order by language, culture, timezone;

PROMPT *** NOW COMMIT OR ROLLBACK ***
