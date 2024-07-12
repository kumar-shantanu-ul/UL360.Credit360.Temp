-- Please update version.sql too -- this keeps clean builds in sync
define version=2184
@update_header

CREATE OR REPLACE VIEW CHAIN.v$chain_company_user AS
	/**********************************************************************************************************/
	/****************** any invitations from someone in my company to a user in my company  *******************/
	/**********************************************************************************************************/
	SELECT vai.app_sid, vai.to_company_sid company_sid, vcu.user_sid, vcu.visibility_id,
			vcu.user_name, vcu.email, vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title
	  FROM v$active_invite vai, v$chain_user vcu
	 WHERE vai.app_sid = vcu.app_sid
	   AND vai.from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND vai.to_company_sid = vai.from_company_sid -- an invitation to ourselves
	   AND vai.to_user_sid = vcu.user_sid
	 UNION ALL
	/****************************************************************/
	/****************** I can see all of my users *******************/
	/****************************************************************/
	SELECT cu.app_sid, cu.company_sid, vcu.user_sid, vcu.visibility_id, 
			vcu.user_name, vcu.email, vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title
	  FROM v$chain_user vcu, v$company_user cu
	 WHERE vcu.app_sid = cu.app_sid
	   AND vcu.user_sid = cu.user_sid
	   AND cu.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND (cu.company_sid, vcu.user_sid) NOT IN (
	   		SELECT to_company_sid, to_user_sid
	   		  FROM v$active_invite
	   		 WHERE from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   		   AND to_company_sid = from_company_sid
	   	   )
	 UNION ALL
	/*****************************************************************/
	/****************** I can see all of my admins *******************/
	/*****************************************************************/
	SELECT ca.app_sid, ca.company_sid, vcu.user_sid, vcu.visibility_id, 
	       vcu.user_name, vcu.email, vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title
	  FROM v$chain_user vcu, v$company_admin ca
	 WHERE vcu.app_sid = ca.app_sid
	   AND vcu.user_sid = ca.user_sid
	   AND ca.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND (ca.company_sid, vcu.user_sid) NOT IN (
			SELECT to_company_sid, to_user_sid
			  FROM v$active_invite
			 WHERE from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND to_company_sid = from_company_sid
	   	   )
	 UNION 
	/***************************************************************************************************************/
	/****************** any invitations from someone in my company to someone in another company *******************/
	/***************************************************************************************************************/
	SELECT vai.app_sid, vai.to_company_sid company_sid, vcu.user_sid, vcu.visibility_id,
			NULL user_name, vcu.email, vcu.full_name, vcu.friendly_name, -- we can always see these if there's a pending invitation as we've probably filled it in ourselves
			CASE WHEN vcu.visibility_id = 3 THEN vcu.phone_number ELSE NULL END phone_number, 
			CASE WHEN vcu.visibility_id >= 1 THEN vcu.job_title ELSE NULL END job_title			
	  FROM v$active_invite vai, v$chain_user vcu
	 WHERE vai.app_sid = vcu.app_sid
	   AND vai.from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND vai.to_company_sid <> vai.from_company_sid -- not an invitation to ourselves (handled above)
	   AND vai.to_user_sid = vcu.user_sid
	 UNION ALL
	/****************************************************/
	/****************** everyone else *******************/
	/****************************************************/
	SELECT cu.app_sid, cu.company_sid, cu.user_sid, cu.visibility_id, NULL user_name,
			CASE WHEN cu.visibility_id = 3 THEN cu.email ELSE NULL END email, 
			CASE WHEN cu.visibility_id >= 2 THEN cu.full_name ELSE NULL END full_name, 
			CASE WHEN cu.visibility_id >= 2 THEN cu.friendly_name ELSE NULL END friendly_name, 
			CASE WHEN cu.visibility_id = 3 THEN cu.phone_number ELSE NULL END phone_number, 
			cu.job_title -- we always see this as we've filtered 'hidden' users
	  FROM v$company_user cu, v$company_relationship cr
	 WHERE cu.app_sid = cr.app_sid(+)
	   AND cu.company_sid = cr.company_sid(+) -- we can see companies that we are in a relationship with
	   AND cu.visibility_id <> 0 -- don't show hidden users
	   AND NOT (cu.visibility_id = 1 AND cu.job_title IS NULL)
	   AND (cr.company_sid IS NOT NULL OR SYS_CONTEXT('SECURITY', 'CHAIN_CAN_SEE_ALL_COMPANIES') = 1 AND cu.company_sid != SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
	   AND (cu.company_sid, cu.user_sid) NOT IN (					-- minus any active questionnaire invitations as these have already been dealt with
	   			SELECT to_company_sid, to_user_sid 
	   			  FROM v$active_invite
	   			 WHERE from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   	   )
;

@../chain/company_body
@../chain/company_user_body

@update_tail
