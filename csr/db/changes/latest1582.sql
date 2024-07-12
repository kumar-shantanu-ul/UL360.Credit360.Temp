-- Please update version.sql too -- this keeps clean builds in sync
define version=1582
@update_header

CREATE OR REPLACE VIEW chain.v$chain_user_invitation_status AS
	SELECT usr.*
	  FROM (
		SELECT vcu.*, i.to_company_sid company_sid,
				NVL(DECODE(invitation_status_id,
					4, 5),--chain_pkg.PROVISIONALLY_ACCEPTED, chain_pkg.ACCEPTED
					invitation_status_id) invitation_status_id,
				ROW_NUMBER() OVER (PARTITION BY i.to_company_sid, vcu.user_sid ORDER BY DECODE(i.invitation_status_id, 
					5, 1, --chain_pkg.ACCEPTED, 1,
					4, 1, --chain_pkg.PROVISIONALLY_ACCEPTED, 1,
					1, 2, --chain_pkg.ACTIVE, 2,
					2, 3, --chain_pkg.EXPIRED, 3,
					3, 4, --chain_pkg.CANCELLED, 4,
					6, 4, --chain_pkg.REJECTED_NOT_EMPLOYEE, 4,
					7, 4, --chain_pkg.REJECTED_NOT_SUPPLIER, 4
					   5  --default
					)   
				) rn
		  FROM v$chain_user vcu
		  JOIN chain.invitation i ON (i.to_user_sid = vcu.user_sid)
		) usr
	 WHERE usr.rn = 1;

@..\chain\company_filter_body
@..\chain\company_user_body

@update_tail