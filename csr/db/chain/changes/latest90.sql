define version=90
@update_header

/***********************************************************************
	v$chain_user - a combined view of csr_user and chain_user
	with defaults set where the entry does not exist in chain_user
***********************************************************************/
PROMPT >> Creating v$chain_user

@..\chain_link_pkg
@..\company_pkg
@..\dashboard_pkg
@..\task_pkg
@..\chain_link_body
@..\company_body
@..\company_user_body
@..\dashboard_body
@..\task_body

CREATE OR REPLACE VIEW chain.v$chain_user AS
	SELECT csru.app_sid, csru.csr_user_sid user_sid, csru.email, csru.user_name,   -- CSR_USER data
		   csru.full_name, csru.friendly_name, csru.phone_number, csru.job_title,   -- CSR_USER data
		   cu.visibility_id, cu.registration_status_id,								-- CHAIN_USER data
		   cu.next_scheduled_alert_dtm, cu.receive_scheduled_alerts, cu.details_confirmed
	  FROM csr.csr_user csru, chain_user cu
	 WHERE csru.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND csru.app_sid = cu.app_sid
	   AND csru.csr_user_sid = cu.user_sid
	   AND cu.registration_status_id <> 2 -- not rejected 
	   AND cu.registration_status_id <> 3 -- not merged 
	   AND cu.deleted = 0
;

@update_tail

