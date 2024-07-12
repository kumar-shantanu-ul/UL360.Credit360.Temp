-- Run using LogOnMethoReport.cmd - run with no arguments for syntax.

exec user_pkg.LogonAdmin('&1');

col report format a2000
set feedback off
set heading off
set trimspool on
set newpage none
set termout off

spool &2

select '"User Name","Email","Last Password Logon","Last SSO Logon"' report
from dual
union all
select '"' || replace(user_name, '"', '""') || '","' || replace(email, '"', '""') || '","' || to_char(pass_date, 'yyyy-mm-dd') || '","' || to_char(sso_date, 'yyyy-mm-dd') || '"'
from
(
select user_name, email,
(
select max(user_logon.audit_date)
from csr.audit_log user_logon
left join csr.audit_log superuser_logon				-- Exclude audit events caused by superadmins impersonating
on user_logon.app_sid = superuser_logon.app_sid			-- other users.
and user_logon.object_sid = superuser_logon.object_sid
and user_logon.audit_date = superuser_logon.audit_date
and superuser_logon.audit_type_id = 3
where user_logon.object_sid = u.csr_user_sid
and user_logon.audit_type_id = 1
and superuser_logon.user_sid is null
) pass_date,
(
select max(audit_date)
from csr.audit_log
where object_sid = u.csr_user_sid
and audit_type_id = 19
) sso_date
from csr.csr_user u
where email not like '%@credit360.com'
and email not like '%@npsl.co.uk'
)
;

spool off
quit
