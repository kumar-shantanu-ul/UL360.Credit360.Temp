select  Calendar_month, full_name, cnt number_of_logons_for_month from
(
    select TRUNC(audit_date,'mm') Calendar_month, user_sid, full_name, count(*) cnt 
    from audit_log al, csr_user cu
    where audit_type_id = 1 -- logon
    and al.USER_SID =cu.CSR_USER_SID
    and al.app_sid = (select app_sid from customer where host = 'ica.credit360.com')
    and TRUNC(audit_date,'mm') >= '1 jul 2008' 
    group by TRUNC(audit_date,'mm'), user_sid, full_name
    order by TRUNC(audit_date,'mm'), full_name
)