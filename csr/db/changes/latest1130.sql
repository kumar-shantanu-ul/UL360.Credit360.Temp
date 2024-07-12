-- Please update version.sql too -- this keeps clean builds in sync
define version=1130
@update_header

ALTER TABLE CHAIN.COMPANY ADD(
    CAN_SEE_ALL_COMPANIES        NUMBER(1, 0)      DEFAULT 0 NOT NULL,
    CONSTRAINT CHK_COMP_SEE_ALL_0_OR_1 CHECK (CAN_SEE_ALL_COMPANIES IN (0,1))
)
;

CREATE OR REPLACE VIEW CHAIN.v$company AS
	SELECT c.app_sid, c.company_sid, c.created_dtm, c.name, c.activated_dtm, c.active, c.address_1, 
		   c.address_2, c.address_3, c.address_4, c.town, c.state, c.postcode, c.country_code, 
		   c.phone, c.fax, c.website, c.deleted, c.details_confirmed, c.stub_registration_guid, 
		   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required, 
		   c.user_level_messaging, c.sector_id, c.reference_id_1, c.reference_id_2, c.reference_id_3,
		   cou.name country_name, s.description sector_description, c.can_see_all_companies
	  FROM company c
	  LEFT JOIN v$country cou ON c.country_code = cou.country_code
	  LEFT JOIN sector s ON c.sector_id = s.sector_id AND c.app_sid = s.app_sid
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND c.deleted = 0
;

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
	SELECT cu.app_sid, cu.company_sid, vcu.user_sid, vcu.visibility_id, NULL user_name,
			CASE WHEN vcu.visibility_id = 3 THEN vcu.email ELSE NULL END email, 
			CASE WHEN vcu.visibility_id >= 2 THEN vcu.full_name ELSE NULL END full_name, 
			CASE WHEN vcu.visibility_id >= 2 THEN vcu.friendly_name ELSE NULL END friendly_name, 
			CASE WHEN vcu.visibility_id = 3 THEN vcu.phone_number ELSE NULL END phone_number, 
			vcu.job_title -- we always see this as we've filtered 'hidden' users
	  FROM v$chain_user vcu, v$company_user cu, v$company_relationship cr, company my_c
	 WHERE my_c.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND vcu.app_sid = cu.app_sid
	   AND cu.app_sid = cr.app_sid(+)
	   AND vcu.user_sid = cu.user_sid
	   AND cu.company_sid = cr.company_sid(+) -- we can see companies that we are in a relationship with
	   AND vcu.visibility_id <> 0 -- don't show hidden users
	   AND NOT (vcu.visibility_id = 1 AND vcu.job_title IS NULL)
	   AND (cr.company_sid IS NOT NULL OR my_c.can_see_all_companies = 1)
	   AND (cu.company_sid, cu.user_sid) NOT IN (					-- minus any active questionnaire invitations as these have already been dealt with
	   			SELECT to_company_sid, to_user_sid 
	   			  FROM v$active_invite
	   			 WHERE from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   	   )
;

INSERT INTO chain.default_message_param (message_definition_id, param_name, lower_param_name, value)
SELECT message_definition_id, 'fromCompanySid', 'fromcompanysid', CASE WHEN secondary_lookup_id=1 THEN '{toCompanySid}' ELSE '{reCompanySid}' END
  FROM chain.message_definition_lookup
 WHERE primary_lookup_id in (300, 301)
   AND message_definition_id NOT IN (
	SELECT message_definition_id
	  FROM chain.default_message_param
	 WHERE param_name='fromCompanySid'
);

@..\chain\company_body
@..\chain\company_user_body
@..\chain\company_filter_body
@..\chain\capability_body

@update_tail
