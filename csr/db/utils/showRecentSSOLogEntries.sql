col saml_log_host format a25 trunc heading HOST
col saml_log_msg format a48 heading MESSAGE
col saml_log_data format a50 heading DATA

select c.host saml_log_host,
	log.log_dtm,
	log.saml_request_id,
	log.message_sequence,
	log.message saml_log_msg,
	dbms_lob.substr(d.saml_assertion, 500) || case when dbms_lob.getlength(d.saml_assertion) > 500 then '...' else '' end saml_log_data
from
csr.customer c
join csr.saml_log log
on c.app_sid = log.app_sid
join
(
select saml_request_id, log_dtm
from
(
select saml_request_id, log_dtm
from csr.saml_log
where message_sequence = 1
order by log_dtm desc
)
where rownum < 10
) s
on s.saml_request_id = log.saml_request_id
left join csr.saml_assertion_log d
on log.saml_request_id = d.saml_request_id and log.message_sequence = 1
order by s.log_dtm, log.saml_request_id, log.message_sequence
;
