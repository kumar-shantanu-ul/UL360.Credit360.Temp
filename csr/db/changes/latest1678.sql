-- Please update version.sql too -- this keeps clean builds in sync
define version=1678
@update_header

grant select, references on security.user_table to chain WITH GRANT OPTION;

-- include account enabled details .
CREATE OR REPLACE VIEW CHAIN.v$chain_user AS
	SELECT csru.app_sid, csru.csr_user_sid user_sid, csru.email, csru.user_name,   -- CSR_USER data
		   csru.full_name, csru.friendly_name, csru.phone_number, csru.job_title,   -- CSR_USER data
		   cu.visibility_id, cu.registration_status_id,								-- CHAIN_USER data
		   cu.next_scheduled_alert_dtm, cu.receive_scheduled_alerts, cu.details_confirmed, ut.account_enabled
	  FROM csr.csr_user csru, chain_user cu, security.user_table ut
	 WHERE csru.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND csru.app_sid = cu.app_sid
	   AND csru.csr_user_sid = cu.user_sid
	   AND cu.user_sid = ut.sid_id
	   AND cu.registration_status_id <> 2 -- not rejected 
	   AND cu.registration_status_id <> 3 -- not merged 
	   AND cu.deleted = 0
;

@..\chain\chain_link_pkg
@..\chain\chain_link_body
@..\chain\company_type_body
@..\chain\company_user_pkg
@..\chain\company_user_body


@update_tail
