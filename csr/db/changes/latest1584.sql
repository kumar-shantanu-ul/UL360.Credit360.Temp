-- Please update version.sql too -- this keeps clean builds in sync
define version=1584
@update_header

CREATE OR REPLACE VIEW chain.v$chain_user_invitation_status AS
	SELECT usr.app_sid, usr.user_sid, usr.email, usr.user_name, usr.full_name, usr.friendly_name, usr.phone_number, usr.job_title, usr.visibility_id, usr.registration_status_id, 
		usr.next_scheduled_alert_dtm, usr.receive_scheduled_alerts, usr.details_confirmed, usr.company_sid, usr.invitation_id, usr.invitation_sent_dtm, usr.invitation_status_id
	  FROM (
		SELECT vcu.app_sid, vcu.user_sid, vcu.email, vcu.user_name, vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title, vcu.visibility_id, vcu.registration_status_id, 
			vcu.next_scheduled_alert_dtm, vcu.receive_scheduled_alerts, vcu.details_confirmed, i.to_company_sid company_sid, i.invitation_id, i.sent_dtm invitation_sent_dtm,
			NVL(DECODE(invitation_status_id,
				4, 5),--chain_pkg.PROVISIONALLY_ACCEPTED, chain_pkg.ACCEPTED
				invitation_status_id) invitation_status_id,
			ROW_NUMBER() OVER (PARTITION BY i.to_company_sid, vcu.user_sid ORDER BY DECODE(i.invitation_status_id, 
				5, 1, --chain_pkg.ACCEPTED, 1,
				4, 1, --chain_pkg.PROVISIONALLY_ACCEPTED, 1,
				1, 2, --chain_pkg.ACTIVE, 2,
				2, 3, --chain_pkg.EXPIRED, 3,
				3, 4, --chain_pkg.CANCELLED, 4,
				6, 5, --chain_pkg.REJECTED_NOT_EMPLOYEE, 5,
				7, 5, --chain_pkg.REJECTED_NOT_SUPPLIER, 5
				   6  --default
				)   
			) rn
		  FROM v$chain_user vcu
		  JOIN chain.invitation i ON (i.to_user_sid = vcu.user_sid)
		) usr
	 WHERE usr.rn = 1;

@..\chain\company_user_pkg
@..\chain\company_user_body

@update_tail