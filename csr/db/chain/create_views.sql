/***********************************************************************
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
MISC VIEWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
***********************************************************************/

/***********************************************************************
	v$country - a dummy country lookup
***********************************************************************/
PROMPT >> Creating v$country

CREATE OR REPLACE VIEW CHAIN.v$country AS
	SELECT country country_code, name
	  FROM postcode.country
	 WHERE latitude IS NOT NULL AND longitude IS NOT NULL
	   AND is_standard = 1
;

/***********************************************************************
	v$active_invite
***********************************************************************/
PROMPT >> Creating v$active_invite

CREATE OR REPLACE VIEW CHAIN.v$active_invite AS
	SELECT app_sid, invitation_id, from_company_sid, from_user_sid, to_company_sid, to_user_sid, sent_dtm, guid, expiration_grace,
	       expiration_dtm, invitation_status_id, invitation_type_id, cancelled_by_user_sid, cancelled_dtm, reinvitation_of_invitation_id,
	       accepted_reg_terms_vers, accepted_dtm, on_behalf_of_company_sid, lang, batch_job_id
	  FROM invitation
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND invitation_status_id = 1
;

/***********************************************************************
	v$chain_host - gives the app_sid, host and chain implementation
***********************************************************************/
PROMPT >> Creating v$chain_host
CREATE OR REPLACE VIEW CHAIN.v$chain_host AS
	SELECT c.app_sid, c.host, i.name
	  FROM csr.customer c, chain.customer_options co, chain.implementation i
	 WHERE c.app_sid = co.app_sid
	   AND c.app_sid = i.app_sid
;

/***********************************************************************
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
COMPANY RELATIONSHIPS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
***********************************************************************/

/***********************************************************************
	v$supplier_relationship - a view of all active supplier relationships

***********************************************************************/
PROMPT >> Creating v$supplier_relationship

CREATE OR REPLACE VIEW CHAIN.v$supplier_relationship AS
	SELECT app_sid, purchaser_company_sid, supplier_company_sid, active, deleted, virtually_active_until_dtm, virtually_active_key, supp_rel_code, flow_item_id
	  FROM supplier_relationship 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND deleted = 0
-- either the relationship is active, or it is virtually active for a very short period so that we can send invitations
	   AND (active = 1 OR SYSDATE < virtually_active_until_dtm)
;

/***********************************************************************
	v$current_raw_sup_rel_score - the current non-overridden (raw) supplier relationship score
***********************************************************************/
CREATE OR REPLACE VIEW chain.v$current_raw_sup_rel_score AS
	SELECT 
		   supplier_company_sid, purchaser_company_sid, score_type_id, 
		   supplier_relationship_score_id, score_threshold_id, score, is_override, set_dtm, valid_until_dtm, 
		   comment_text, changed_by_user_sid, score_source_type, score_source_id, 
		   CASE WHEN valid_until_dtm IS NULL OR valid_until_dtm >= SYSDATE THEN 1 ELSE 0 END valid
	  FROM chain.supplier_relationship_score srs
	 WHERE srs.set_dtm <= SYSDATE
	   AND is_override = 0
	   AND NOT EXISTS (
			SELECT *
			  FROM chain.supplier_relationship_score srs2
			 WHERE srs.purchaser_company_sid = srs2.purchaser_company_sid
			   AND srs.supplier_company_sid = srs2.supplier_company_sid
			   AND srs.score_type_id = srs2.score_type_id
			   AND is_override = 0
			   AND srs2.set_dtm > srs.set_dtm
			   AND srs2.set_dtm <= SYSDATE
		)
;

/***********************************************************************
	v$current_ovr_sup_rel_score - the current overridden supplier relationship score
***********************************************************************/
CREATE OR REPLACE VIEW chain.v$current_ovr_sup_rel_score AS
	SELECT 
		   supplier_company_sid, purchaser_company_sid, score_type_id, 
		   supplier_relationship_score_id, score_threshold_id, score, is_override, set_dtm, valid_until_dtm, 
		   comment_text, changed_by_user_sid, score_source_type, score_source_id, 
		   CASE WHEN valid_until_dtm IS NULL OR valid_until_dtm >= SYSDATE THEN 1 ELSE 0 END valid
	  FROM chain.supplier_relationship_score srs
	 WHERE srs.set_dtm <= SYSDATE
	   AND is_override = 1
	   AND NOT EXISTS (
			SELECT *
			  FROM chain.supplier_relationship_score srs2
			 WHERE srs.purchaser_company_sid = srs2.purchaser_company_sid
			   AND srs.supplier_company_sid = srs2.supplier_company_sid
			   AND srs.score_type_id = srs2.score_type_id
			   AND is_override = 1
			   AND srs2.set_dtm > srs.set_dtm
			   AND srs2.set_dtm <= SYSDATE
		)
;

/***********************************************************************
	v$current_sup_rel_score_all - the current raw supplier relationship score and corresponding overrides
***********************************************************************/
CREATE OR REPLACE VIEW chain.v$current_sup_rel_score_all AS
	SELECT 
		   supplier_company_sid, purchaser_company_sid, score_type_id, 
		   --
		   MAX(supplier_relationship_score_id) raw_sup_relationship_score_id, 
		   MAX(score_threshold_id) raw_score_threshold_id, 
		   MAX(score) raw_score, 
		   MAX(set_dtm) raw_set_dtm, 
		   MAX(valid_until_dtm) raw_valid_until_dtm, 
		   MAX(changed_by_user_sid) raw_changed_by_user_sid, 
		   MAX(score_source_type) raw_score_source_type, 
		   MAX(score_source_id) raw_score_source_id, 
		   MAX(valid) raw_valid, 
		   --
		   MAX(ovr_sup_relationship_score_id) ovr_sup_relationship_score_id, 
		   MAX(ovr_score_threshold_id) ovr_score_threshold_id, 
		   MAX(ovr_score) ovr_score, 
		   MAX(ovr_set_dtm) ovr_set_dtm, 
		   MAX(ovr_valid_until_dtm) ovr_valid_until_dtm,  
		   MAX(ovr_changed_by_user_sid) ovr_changed_by_user_sid, 
		   MAX(ovr_score_source_type) ovr_score_source_type, 
		   MAX(ovr_score_source_id) ovr_score_source_id, 
		   MAX(valid) ovr_valid
	  FROM (
			SELECT 
				   supplier_company_sid, purchaser_company_sid, score_type_id, 
				   --
				   supplier_relationship_score_id, score_threshold_id, score, is_override, set_dtm, valid_until_dtm, 
				   changed_by_user_sid, score_source_type, score_source_id, valid,
				   --
				   NULL ovr_sup_relationship_score_id, NULL ovr_score_threshold_id, NULL ovr_score, NULL ovr_is_override, NULL ovr_set_dtm, NULL ovr_valid_until_dtm, 
				   NULL ovr_changed_by_user_sid, NULL ovr_score_source_type, NULL ovr_score_source_id, NULL ovr_valid
			  FROM chain.v$current_raw_sup_rel_score
			  UNION ALL
			SELECT 
				   supplier_company_sid, purchaser_company_sid, score_type_id, 
				   --
				   NULL supplier_relationship_score_id, NULL score_threshold_id, score, NULL is_override, NULL set_dtm, NULL valid_until_dtm, 
				   NULL changed_by_user_sid, NULL score_source_type, NULL score_source_id, NULL valid,
				   --
				   supplier_relationship_score_id ovr_sup_relationship_score_id, score_threshold_id ovr_score_threshold_id, score ovr_score, is_override ovr_is_override, set_dtm ovr_set_dtm, valid_until_dtm ovr_valid_until_dtm, 
				   changed_by_user_sid ovr_changed_by_user_sid, score_source_type ovr_score_source_type, score_source_id ovr_score_source_id, valid ovr_valid
			  FROM chain.v$current_ovr_sup_rel_score
	)
	GROUP BY supplier_company_sid, purchaser_company_sid, score_type_id
; 
	
/***********************************************************************
	v$current_sup_rel_score - the current supplier relationship score - returns overridden if set / raw if not
***********************************************************************/
CREATE OR REPLACE VIEW chain.v$current_sup_rel_score AS
	SELECT 
		   supplier_company_sid, purchaser_company_sid, score_type_id, 
		   --
		   NVL(ovr_score_threshold_id, raw_score_threshold_id) score_threshold_id, 
		   NVL(ovr_score, raw_score) score, 
		   NVL2(ovr_score_threshold_id, ovr_set_dtm, raw_set_dtm) set_dtm, 
		   NVL2(ovr_score_threshold_id, ovr_valid_until_dtm, raw_valid_until_dtm) valid_until_dtm, 
		   NVL2(ovr_score_threshold_id, ovr_changed_by_user_sid, raw_changed_by_user_sid) changed_by_user_sid, 
		   NVL2(ovr_score_threshold_id, ovr_score_source_type, raw_score_source_type) score_source_type, 
		   NVL2(ovr_score_threshold_id, ovr_score_source_id, raw_score_source_id) score_source_id, 
		   NVL2(ovr_score_threshold_id, ovr_valid, raw_valid) valid
	  FROM v$current_sup_rel_score_all
;

/***********************************************************************
	v$company_relationship - a view of all companies that I
	am in a relationship with, whether it be as a purchaser or a supplier 
***********************************************************************/
PROMPT >> Creating v$company_relationship

CREATE OR REPLACE VIEW CHAIN.v$company_relationship AS
	SELECT UNIQUE app_sid, company_sid
	  FROM (  
			SELECT app_sid, purchaser_company_sid company_sid 
			  FROM v$supplier_relationship 
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			 UNION ALL
			SELECT app_sid,  supplier_company_sid company_sid 
			  FROM v$supplier_relationship 
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			)
	 WHERE company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
;
 
 

/***********************************************************************
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
COMPANY AND USER VIEWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
***********************************************************************/

/***********************************************************************
	v$company = all companies that have not been flagged as deleted or pending
***********************************************************************/
PROMPT >> Creating v$company

CREATE OR REPLACE VIEW CHAIN.v$company AS
	SELECT c.app_sid, c.company_sid, c.created_dtm, c.name, c.active, c.activated_dtm, c.deactivated_dtm,
		   c.address_1, c.address_2, c.address_3, c.address_4, c.state, c.city, c.postcode, c.country_code,
		   c.phone, c.fax, c.website, c.email, c.deleted, c.details_confirmed, c.stub_registration_guid, 
		   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required, 
		   c.user_level_messaging, c.sector_id,
		   cou.name country_name, s.description sector_description, c.can_see_all_companies, c.company_type_id,
		   ct.lookup_key company_type_lookup, ct.singular company_type_description, c.supp_rel_code_label, c.supp_rel_code_label_mand,
		   c.parent_sid, p.name parent_name, p.country_code parent_country_code, pcou.name parent_country_name,
		   c.country_is_hidden, cs.region_sid
	  FROM company c
	  LEFT JOIN postcode.country cou ON c.country_code = cou.country
	  LEFT JOIN sector s ON c.sector_id = s.sector_id AND c.app_sid = s.app_sid
	  LEFT JOIN company_type ct ON c.company_type_id = ct.company_type_id
	  LEFT JOIN company p ON c.parent_sid = p.company_sid AND c.app_sid = p.app_sid
	  LEFT JOIN postcode.country pcou ON p.country_code = pcou.country
	  LEFT JOIN csr.supplier cs ON cs.company_sid = c.company_sid AND cs.app_sid = c.app_sid
	 WHERE c.deleted = 0
	   AND c.pending = 0
;


/***********************************************************************
	v$chain_user - a combined view of csr_user and chain_user
	with defaults set where the entry does not exist in chain_user
***********************************************************************/
PROMPT >> Creating v$chain_user

CREATE OR REPLACE VIEW CHAIN.v$chain_user AS
	SELECT csru.app_sid, csru.csr_user_sid user_sid, csru.email, csru.user_name,                  -- CSR_USER data
		   csru.full_name, csru.friendly_name, csru.phone_number, csru.job_title, csru.user_ref,  -- CSR_USER data
		   cu.visibility_id, cu.registration_status_id,	cu.default_company_sid, 	              -- CHAIN_USER data
		   cu.receive_scheduled_alerts, cu.details_confirmed, ut.account_enabled, csru.send_alerts
	  FROM csr.csr_user csru, chain_user cu, security.user_table ut
	 WHERE csru.app_sid = cu.app_sid
	   AND csru.csr_user_sid = cu.user_sid
	   AND cu.user_sid = ut.sid_id
	   AND cu.registration_status_id <> 2 -- not rejected 
	   AND cu.registration_status_id <> 3 -- not merged 
	   AND cu.deleted = 0
;

/***********************************************************************
	v$company_request - a view of company
	or where an entry exists in company_request_action
***********************************************************************/
PROMPT >> Creating v$company_request

CREATE OR REPLACE VIEW chain.v$company_request AS
	SELECT c.app_sid, c.company_sid, c.name, c.address_1, c.address_2, c.address_3, c.address_4,
		   c.state, c.city, c.postcode, c.country_code, c.phone, c.fax, c.website, c.email,
		   c.requested_by_user_sid, c.requested_by_company_sid
	  FROM company c
	 WHERE c.pending = 1
	    OR EXISTS (
			SELECT 1
			  FROM company_request_action
			 WHERE company_sid = c.company_sid
		   );

/***********************************************************************
	v$company_user_group - a simple view of app_sid, company_sid, 
	user_group_sid
***********************************************************************/
PROMPT >> Creating v$company_user_group

CREATE OR REPLACE VIEW CHAIN.v$company_user_group AS
	SELECT app_sid, company_sid, group_sid user_group_sid
	  FROM chain.company_group
	 WHERE company_group_type_id=2 -- users
	   AND group_sid IS NOT NULL
;   


/***********************************************************************
	v$company_pending_group - a simple view of app_sid, company_sid, 
	pending_group_sid
***********************************************************************/
PROMPT >> Creating v$company_pending_group

CREATE OR REPLACE VIEW CHAIN.v$company_pending_group AS
	SELECT app_sid, company_sid, group_sid pending_group_sid
	  FROM chain.company_group
	 WHERE company_group_type_id=3 -- pending users
	   AND group_sid IS NOT NULL
;  


/***********************************************************************
	v$company_admin_group - a simple view of app_sid, company_sid, 
	admin_group_sid
***********************************************************************/
PROMPT >> Creating v$company_admin_group

CREATE OR REPLACE VIEW CHAIN.v$company_admin_group AS
	SELECT app_sid, company_sid, group_sid admin_group_sid
	  FROM chain.company_group
	 WHERE company_group_type_id=1 -- admins
	   AND group_sid IS NOT NULL
;  


/***********************************************************************
	v$company_user - a simple view of all direct users for all companies
	app_sid, company_sid, user_sid
***********************************************************************/
PROMPT >> Creating v$company_user

CREATE OR REPLACE VIEW CHAIN.v$company_user AS
	SELECT cug.app_sid, cug.company_sid, vcu.user_sid, vcu.email, vcu.user_name, 
		   vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title,   
		   vcu.visibility_id, vcu.registration_status_id, vcu.details_confirmed,
		   vcu.account_enabled, vcu.user_ref, vcu.default_company_sid
	  FROM v$company_user_group cug, v$chain_user vcu, security.group_members gm
	 WHERE cug.app_sid = vcu.app_sid
	   AND cug.user_group_sid = gm.group_sid_id
	   AND vcu.user_sid = gm.member_sid_id
;


/***********************************************************************
	v$company_pending_user - a simple view of all direct pending users 
	for all companies - app_sid, company_sid, user_sid
***********************************************************************/
PROMPT >> Creating v$company_pending_user

CREATE OR REPLACE VIEW CHAIN.v$company_pending_user AS        
  SELECT cpg.app_sid, cpg.company_sid, vcu.user_sid, vcu.email, vcu.user_name, 
		vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title,   
		vcu.visibility_id, vcu.registration_status_id, vcu.details_confirmed
    FROM v$company_pending_group cpg, v$chain_user vcu, security.group_members gm
   WHERE cpg.app_sid = vcu.app_sid
     AND cpg.pending_group_sid = gm.group_sid_id
     AND vcu.user_sid = gm.member_sid_id
;


/***********************************************************************
	v$company_admin - a simple view of all direct admins for all companies
	app_sid, company_sid, user_sid
***********************************************************************/
PROMPT >> Creating v$company_admin

CREATE OR REPLACE VIEW CHAIN.v$company_admin AS
  SELECT cag.app_sid, cag.company_sid, vcu.user_sid, vcu.email, vcu.user_name, 
		vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title,   
		vcu.visibility_id, vcu.registration_status_id, vcu.details_confirmed, vcu.account_enabled
    FROM v$company_admin_group cag, v$chain_user vcu, security.group_members gm
   WHERE cag.app_sid = vcu.app_sid
     AND cag.admin_group_sid = gm.group_sid_id
     AND vcu.user_sid = gm.member_sid_id
;


/***********************************************************************
	v$company_member - a simple view of all direct amdmin, user and pending users
	for all companies - app_sid, company_sid, user_sid
***********************************************************************/
PROMPT >> Creating v$company_member

CREATE OR REPLACE VIEW CHAIN.v$company_member AS        
	SELECT DISTINCT app_sid, company_sid, user_sid
	  FROM (
		SELECT app_sid, company_sid, user_sid
		  FROM v$company_admin
		 UNION ALL
		SELECT app_sid, company_sid, user_sid
		  FROM v$company_user
		 UNION ALL
		SELECT app_sid, company_sid, user_sid
		  FROM v$company_pending_user
			)
;


/***********************************************************************
	v$chain_company_user - a view which restricts which system users 
	the currently logged in user is allowed to see.
	
	The view follows four "I am allowed to see" rules:
	
	1. the details of any user that my company currently has an "active invitation" with
	2. all details of all users of my company
	3. all details of all administrators of my company
	4. the details of users of my existing supplier AND purchaser companies
		who have chosen to share details with users of other companies
		
	Where applicable, the rules of the "visibility" table are implemented.
***********************************************************************/
PROMPT >> Creating v$chain_company_user

CREATE OR REPLACE VIEW CHAIN.v$chain_company_user AS
	/**********************************************************************************************************/
	/****************** any invitations from someone in my company to a user in my company  *******************/
	/**********************************************************************************************************/
	SELECT vai.app_sid, vai.to_company_sid company_sid, vcu.user_sid, vcu.visibility_id,
			vcu.user_name, vcu.email, vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title, vcu.account_enabled
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
			vcu.user_name, vcu.email, vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title, vcu.account_enabled
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
	       vcu.user_name, vcu.email, vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title, vcu.account_enabled
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
			CASE WHEN vcu.visibility_id >= 1 THEN vcu.job_title ELSE NULL END job_title, vcu.account_enabled
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
			cu.job_title, cu.account_enabled -- we always see this as we've filtered 'hidden' users
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

/***********************************************************************
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CAPABILITIES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
***********************************************************************/

/***********************************************************************
	v$group_capability_permission
***********************************************************************/
PROMPT >> Creating v$group_capability_permission

CREATE OR REPLACE VIEW CHAIN.v$group_capability_permission AS
	SELECT gc.group_capability_id, cgt.name company_group_name, gc.capability_id, ps.permission_set
	  FROM group_capability gc, company_group_type cgt, (
			SELECT group_capability_id, 0 hide_group_capability, permission_set
			  FROM group_capability
			 WHERE group_capability_id NOT IN (
					SELECT group_capability_id
					  FROM group_capability_override
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				)
			UNION ALL
			SELECT group_capability_id, hide_group_capability, permission_set_override permission_set
			  FROM group_capability_override
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			) ps
	 WHERE ps.hide_group_capability = 0
	   AND ps.group_capability_id = gc.group_capability_id
	   AND gc.company_group_type_id = cgt.company_group_type_id
;
	  

/***********************************************************************
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
COMPONENTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
***********************************************************************/

/***********************************************************************
	v$ccomponent_type - all activated components types in the application
***********************************************************************/
PROMPT >> Creating v$component_type
CREATE OR REPLACE VIEW CHAIN.v$component_type AS
	SELECT ct.app_sid, act.component_type_id, act.handler_class, act.handler_pkg, 
			act.node_js_path, act.description, act.editor_card_group_id
	  FROM component_type ct, all_component_type act
	 WHERE ct.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND ct.component_type_id = act.component_type_id
;

/***********************************************************************
	v$product_last_revision - effective revision of all products
***********************************************************************/
PROMPT >> Creating v$product_last_revision
CREATE OR REPLACE VIEW CHAIN.v$product_last_revision AS
SELECT x.app_sid, x.product_id, x.supplier_root_component_id, x.active, x.code2, x.code3, x.need_review, x.notes, x.published, 
	x.last_published_dtm, x.last_published_by_user_sid, x.validated_root_component_id, x.validation_status_id, x.validation_status_description, x.previous_end_dtm, x.previous_rev_number, x.revision_start_dtm, x.revision_end_dtm, x.revision_num
  FROM (
		SELECT app_sid, product_id, supplier_root_component_id, active, code2, code3, need_review, notes, published, last_published_dtm, 
		last_published_by_user_sid, validated_root_component_id, pr.validation_status_id, vs.description validation_status_description, previous_end_dtm, previous_rev_number, revision_start_dtm, 
		revision_end_dtm, revision_num, 
		ROW_NUMBER() OVER (PARTITION BY app_sid, product_id ORDER BY revision_num DESC) rn
		  FROM product_revision pr
		  JOIN validation_status vs ON pr.validation_status_id = vs.validation_status_id
	 )x
 WHERE x.rn = 1;

/***********************************************************************
	v$product - all products bound with underlying component 
***********************************************************************/
PROMPT >> Creating v$product
CREATE OR REPLACE VIEW CHAIN.v$product AS
 SELECT cmp.app_sid, p.product_id, p.supplier_root_component_id, p.validated_root_component_id, cmp.component_id root_component_id,
   p.active, cmp.component_code code1, p.code2, p.code3, p.notes, p.need_review,
   cmp.description, cmp.component_code, cmp.deleted,
   cmp.company_sid, cmp.created_by_sid, cmp.created_dtm,
   p.published, p.last_published_dtm, p.last_published_by_user_sid, p.validation_status_id, p.validation_status_description,
   p.revision_num, p.revision_start_dtm
   FROM v$product_last_revision p
   JOIN component cmp ON p.app_sid = cmp.app_sid AND DECODE(p.validation_status_id, 5 /* 'Validated' */, p.validated_root_component_id, p.supplier_root_component_id) = cmp.component_id
  WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
;

/*******************************************************************************************************************
	v$product_all_revisions - all products bound with underlying component, not restricted by the last revision
*******************************************************************************************************************/
CREATE OR REPLACE VIEW CHAIN.v$product_all_revisions AS
 SELECT cmp.app_sid, p.product_id, p.supplier_root_component_id, p.validated_root_component_id, cmp.component_id root_component_id,
   p.active, cmp.component_code code1, p.code2, p.code3, p.notes, p.need_review,
   cmp.description, cmp.component_code, cmp.deleted,
   cmp.company_sid, cmp.created_by_sid, cmp.created_dtm,
   p.published, p.last_published_dtm, p.last_published_by_user_sid, p.validation_status_id, vs.description validation_status_description,
   p.revision_num, p.revision_start_dtm, revision_end_dtm
   FROM product_revision p
   JOIN component cmp ON p.app_sid = cmp.app_sid AND DECODE(p.validation_status_id, 5 /* 'VALIDATED' */, p.validated_root_component_id, p.supplier_root_component_id) = cmp.component_id
   JOIN validation_status vs ON p.validation_status_id = vs.validation_status_id
  WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
;

/***********************************************************************
	v$purchased_component - all purchased components bound with underlying component 
***********************************************************************/
PROMPT >> Creating v$purchased_component

CREATE OR REPLACE VIEW CHAIN.v$purchased_component AS
	SELECT cmp.app_sid, cmp.component_id, 
			cmp.description, cmp.component_code, cmp.component_notes, cmp.deleted,
			cmp.company_sid, cmp.created_by_sid, cmp.created_dtm,
			pc.component_supplier_type_id, pc.acceptance_status_id,
			pc.supplier_company_sid, supp.name supplier_name, supp.country_code supplier_country_code, supp_c.name supplier_country_name, 
			pc.company_sid purchaser_company_sid, pur.name purchaser_name, pur.country_code purchaser_country_code, pur_c.name purchaser_country_name, 
			pc.uninvited_supplier_sid, unv.name uninvited_name, unv.country_code uninvited_country_code, NULL uninvited_country_name, 
			pc.supplier_product_id, NVL2(pc.supplier_product_id, 1, 0) mapped, mapped_by_user_sid, mapped_dtm,
			p.description supplier_product_description, p.code1 supplier_product_code1, p.code2 supplier_product_code2, p.code3 supplier_product_code3, 
			p.published supplier_product_published, p.last_published_dtm supplier_product_published_dtm, pc.purchases_locked, p.validation_status_id, p.validation_status_description,
			p.supplier_root_component_id
	  FROM purchased_component pc
	  JOIN component cmp ON pc.app_sid = cmp.app_sid AND pc.component_id = cmp.component_id
	  LEFT JOIN (
		SELECT app_sid, component_id --, parent_component_id, level
		FROM chain.component
		START WITH component_id IN (
			SELECT supplier_root_component_id
			FROM CHAIN.product_revision
			UNION ALL
			SELECT validated_root_component_id
			FROM CHAIN.product_revision
		)
		CONNECT BY PRIOR component_id = parent_component_id AND PRIOR app_sid = app_sid
	  ) ct on pc.app_sid = ct.app_sid and pc.component_id = ct.component_id
	  LEFT JOIN v$product p ON pc.app_sid = p.app_sid AND pc.supplier_product_id = p.product_id
	  LEFT JOIN company supp ON pc.app_sid = supp.app_sid AND pc.supplier_company_sid = supp.company_sid AND supp.deleted = 0
	  LEFT JOIN v$country supp_c ON supp.country_code = supp_c.country_code
	  LEFT JOIN company pur ON pc.app_sid = pur.app_sid AND pc.company_sid = pur.company_sid AND pur.deleted = 0
	  LEFT JOIN v$country pur_c ON pur.country_code = pur_c.country_code
	  LEFT JOIN uninvited_supplier unv ON pc.app_sid = unv.app_sid AND pc.uninvited_supplier_sid = unv.uninvited_supplier_sid AND pc.company_sid = unv.company_sid
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND (cmp.parent_component_id IS NULL OR ct.component_id IS NOT NULL)
;

/***********************************************************************
	v$purchased_component_supplier - purchased component -> supplier data 
***********************************************************************/
PROMPT >> Creating v$purchased_component_supplier
CREATE OR REPLACE VIEW CHAIN.v$purchased_component_supplier AS
	--
	--SUPPLIER_NOT_SET (basic data, nulled supplier data)
	--
	SELECT app_sid, component_id, component_supplier_type_id, 
			NULL supplier_company_sid, NULL uninvited_supplier_sid, 
			NULL supplier_name, NULL supplier_country_code, NULL supplier_country_name
	  FROM purchased_component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_supplier_type_id = 0 -- SUPPLIER_NOT_SET
	--
	 UNION
	--
	--EXISTING_SUPPLIER
	--
	SELECT pc.app_sid, pc.component_id, pc.component_supplier_type_id, 
			pc.supplier_company_sid, NULL uninvited_supplier_sid, 
			c.name supplier_name, c.country_code supplier_country_code, coun.name supplier_country_name
	  FROM purchased_component pc, company c, v$country coun
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = c.app_sid
	   AND pc.component_supplier_type_id = 1 -- EXISTING_SUPPLIER
	   AND pc.supplier_company_sid = c.company_sid
	   AND c.country_code = coun.country_code(+)
	--
	 UNION
	--
	--EXISTING_PURCHASER
	--
	SELECT pc.app_sid, pc.component_id, pc.component_supplier_type_id, 
			pc.company_sid supplier_company_sid, NULL uninvited_supplier_sid, 
			c.name supplier_name, c.country_code supplier_country_code, coun.name supplier_country_name
	  FROM purchased_component pc, company c, v$country coun
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = c.app_sid
	   AND pc.component_supplier_type_id = 2 -- EXISTING_PURCHASER
	   AND pc.company_sid = c.company_sid
	   AND c.country_code = coun.country_code(+)
	--
	 UNION
	--
	--UNINVITED_SUPPLIER (basic data, uninvited supplier data bound)
	--
	SELECT pc.app_sid, pc.component_id, pc.component_supplier_type_id, 
			NULL supplier_company_sid, us.uninvited_supplier_sid, 
			us.name supplier_name, us.country_code supplier_country_code, coun.name supplier_country_name
	  FROM purchased_component pc, uninvited_supplier us, v$country coun
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = us.app_sid
	   AND pc.component_supplier_type_id = 3 -- UNINVITED_SUPPLIER
	   AND pc.uninvited_supplier_sid = us.uninvited_supplier_sid
	   AND us.country_code = coun.country_code(+)
;


/***********************************************************************
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
QUESTIONNAIRES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
***********************************************************************/

/***********************************************************************
	v$questionnaire_status_log - a view of all questionnaire status log entries in an app
***********************************************************************/
PROMPT >> Creating v$questionnaire_status_log

CREATE OR REPLACE VIEW CHAIN.v$questionnaire_status_log AS
  SELECT q.app_sid, q.questionnaire_id, q.company_sid, q.questionnaire_type_id, q.created_dtm, qsle.status_log_entry_index, 
  		 qsle.entry_dtm, qsle.questionnaire_status_id, qs.description status_description, qsle.user_sid entry_by_user_sid, qsle.user_notes user_entry_notes
    FROM questionnaire q, qnr_status_log_entry qsle, questionnaire_status qs
   WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
     AND q.app_sid = qsle.app_sid
     AND q.questionnaire_id = qsle.questionnaire_id
     AND qs.questionnaire_status_id = qsle.questionnaire_status_id
   ORDER BY q.questionnaire_id, qsle.status_log_entry_index
;

/***********************************************************************
	v$questionnaire_share_log - a view of all questionnaire share log entries in an app
***********************************************************************/
PROMPT >> Creating v$questionnaire_share_log

CREATE OR REPLACE VIEW CHAIN.v$questionnaire_share_log AS
  SELECT q.app_sid, q.questionnaire_id, q.company_sid, q.questionnaire_type_id, q.created_dtm, qs.due_by_dtm,
         qs.share_with_company_sid, qsle.share_log_entry_index, qsle.entry_dtm, qsle.share_status_id, 
         ss.description share_description, qsle.company_sid entry_by_company_sid, qsle.user_sid entry_by_user_sid, qsle.user_notes
    FROM questionnaire q, questionnaire_share qs, qnr_share_log_entry qsle, share_status ss
   WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
     AND q.app_sid = qs.app_sid
     AND q.app_sid = qsle.app_sid
     AND q.company_sid = qs.qnr_owner_company_sid
     AND q.questionnaire_id = qs.questionnaire_id
     AND qs.questionnaire_share_id = qsle.questionnaire_share_id
     AND qsle.share_status_id = ss.share_status_id
   ORDER BY q.questionnaire_id, qsle.share_log_entry_index
;

/***********************************************************************
	v$questionnaire - a view of all questionnaires with their current status ids exposed
***********************************************************************/
PROMPT >> Creating v$questionnaire

CREATE OR REPLACE VIEW CHAIN.v$questionnaire AS
	SELECT q.app_sid, q.questionnaire_id, q.company_sid, q.component_id, c.description component_description, q.questionnaire_type_id, q.created_dtm,
		   qt.view_url, qt.edit_url, qt.owner_can_review, qt.class, qt.name, NVL(q.description, qt.name) description, qt.db_class, qt.group_name, qt.position, qt.security_scheme_id, 
		   qsle.status_log_entry_index, qsle.questionnaire_status_id, qs.description questionnaire_status_name, qsle.entry_dtm status_update_dtm,
		   qt.enable_status_log, qt.enable_transition_alert, q.rejected
	  FROM questionnaire q, questionnaire_type qt, qnr_status_log_entry qsle, questionnaire_status qs, component c
	 WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND q.app_sid = qt.app_sid
	   AND q.app_sid = qsle.app_sid
       AND q.questionnaire_type_id = qt.questionnaire_type_id
       AND qsle.questionnaire_status_id = qs.questionnaire_status_id
       AND q.questionnaire_id = qsle.questionnaire_id
       AND q.component_id = c.component_id(+)
       AND (qsle.questionnaire_id, qsle.status_log_entry_index) IN (   
			SELECT questionnaire_id, MAX(status_log_entry_index)
			  FROM qnr_status_log_entry
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 GROUP BY questionnaire_id
			)
;


/***********************************************************************
	v$questionnaire_share - a view of all supplier questionnaires by current status
	also a heap of crap by the looks of it - or maybe an attept to write some really slow views
***********************************************************************/
PROMPT >> Creating v$questionnaire_share

CREATE OR REPLACE VIEW CHAIN.v$questionnaire_share AS
	SELECT q.app_sid, q.questionnaire_id, q.component_id, q.questionnaire_type_id, q.created_dtm,
		   qs.due_by_dtm, qs.overdue_events_sent, qs.qnr_owner_company_sid, qs.share_with_company_sid,
		   qsle.share_log_entry_index, qsle.entry_dtm, qs.questionnaire_share_id, qs.reminder_sent_dtm,
		   qs.overdue_sent_dtm, qsle.share_status_id, ss.description share_status_name,
		   qsle.company_sid entry_by_company_sid, qsle.user_sid entry_by_user_sid, qsle.user_notes,
		   qt.class qt_class, qt.name questionnaire_name, qs.expiry_dtm,
		   CASE WHEN qs.expiry_dtm < SYSDATE THEN 1 ELSE 0 END has_expired,
		   q.rejected questionnaire_rejected,
		   CASE WHEN qsle.entry_dtm < qstle.entry_dtm THEN qstle.entry_dtm ELSE qsle.entry_dtm END status_entry_dtm
	  FROM questionnaire q
	  JOIN questionnaire_share qs ON q.app_sid = qs.app_sid AND q.questionnaire_id = qs.questionnaire_id
	  JOIN qnr_share_log_entry qsle ON qs.app_sid = qsle.app_sid AND qs.questionnaire_share_id = qsle.questionnaire_share_id
	  JOIN qnr_status_log_entry qstle ON q.app_sid = qstle.app_sid AND q.questionnaire_id = qstle.questionnaire_id
	  JOIN share_status ss ON qsle.share_status_id = ss.share_status_id
	  JOIN company s ON q.app_sid = s.app_sid AND q.company_sid = s.company_sid
	  JOIN questionnaire_type qt ON q.app_sid = qt.app_sid AND q.questionnaire_type_id = qt.questionnaire_type_id	 
	 WHERE s.deleted = 0
	   AND (								-- allows builtin admin to see relationships as well for debugging purposes
	   			qs.share_with_company_sid = NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), qs.share_with_company_sid)
	   		 OR qs.qnr_owner_company_sid = NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), qs.qnr_owner_company_sid)
	   	   )
	   AND (qsle.app_sid, qsle.questionnaire_share_id, qsle.share_log_entry_index) IN (   
	   			SELECT app_sid, questionnaire_share_id, MAX(share_log_entry_index)
	   			  FROM qnr_share_log_entry
	   			 GROUP BY app_sid, questionnaire_share_id
			)
	   AND qstle.status_log_entry_index = (   
	   			SELECT MAX(status_log_entry_index)
	   			  FROM qnr_status_log_entry
				 WHERE app_sid = qstle.app_sid
				   AND questionnaire_id = qstle.questionnaire_id
			)
;

/***********************************************************************
	v$qnr_action_security_mask - a view of questionnaire type security mask with default values
***********************************************************************/
CREATE OR REPLACE VIEW CHAIN.v$qnr_action_security_mask AS
    SELECT app_sid, questionnaire_type_id, company_function_id, questionnaire_action_id, action_security_type_id,
		   CASE WHEN  security.bitwise_pkg.bitand(action_security_type_id, 1) = 1 THEN 1 ELSE 0 END capability_check, -- CAPABILITY
		   CASE WHEN  security.bitwise_pkg.bitand(action_security_type_id, 2) = 2 THEN 1 ELSE 0 END user_check	      -- USER
--		   CASE WHEN  security.bitwise_pkg.bitand(action_security_type_id, 4) = 4 THEN 1 ELSE 0 END other_check	      -- OTHER
	  FROM (
			SELECT x.app_sid, x.questionnaire_type_id, x.company_function_id, x.questionnaire_action_id, NVL(m.action_security_type_id, x.action_security_type_id) action_security_type_id
			  FROM chain.qnr_action_security_mask m, (
					SELECT qt.app_sid, qt.questionnaire_type_id, cfqa.company_function_id, cfqa.questionnaire_action_id, ast.action_security_type_id
					  FROM chain.company_func_qnr_action cfqa, chain.questionnaire_type qt, chain.action_security_type ast
					 WHERE ast.action_security_type_id = 1 -- chain_pkg.AST_CAPABILITIES
					   AND NVL(SYS_CONTEXT('SECURITY', 'APP'), qt.app_sid) = qt.app_sid
				  ) x
			 WHERE x.app_sid = m.app_sid(+)
			   AND x.questionnaire_type_id = m.questionnaire_type_id(+)
			   AND x.company_function_id = m.company_function_id(+)
			   AND x.questionnaire_action_id = m.questionnaire_action_id(+)
			);

/***********************************************************************
	v$qnr_action_capability - questionnaire_action -> capability mapping
***********************************************************************/
CREATE OR REPLACE VIEW chain.v$qnr_action_capability
AS
	SELECT questionnaire_action_id, description,
		CASE WHEN questionnaire_action_id = 1 THEN 'Questionnaire'
			 WHEN questionnaire_action_id = 2 THEN 'Questionnaire'
			 WHEN questionnaire_action_id = 3 THEN 'Submit questionnaire'
			 WHEN questionnaire_action_id = 4 THEN 'Approve questionnaire' 
			 WHEN questionnaire_action_id = 5 THEN 'Manage questionnaire security' 
			 WHEN questionnaire_action_id = 6 THEN 'Reject questionnaire' 
		END capability_name,
		CASE WHEN questionnaire_action_id = 1 THEN 1 --security_pkg.PERMISSION_READ -- SPECIFIC
			 WHEN questionnaire_action_id = 2 THEN 2 --security_pkg.PERMISSION_WRITE -- SPECIFIC
			 WHEN questionnaire_action_id = 3 THEN 2 --security_pkg.PERMISSION_WRITE -- BOOLEAN
			 WHEN questionnaire_action_id = 4 THEN 2 --security_pkg.PERMISSION_WRITE -- BOOLEAN
			 WHEN questionnaire_action_id = 5 THEN 2 --security_pkg.PERMISSION_WRITE -- BOOLEAN
			 WHEN questionnaire_action_id = 6 THEN 2 --security_pkg.PERMISSION_WRITE -- BOOLEAN
		END permission_set,
		CASE WHEN questionnaire_action_id = 1 THEN 0 -- SPECIFIC
			 WHEN questionnaire_action_id = 2 THEN 0 -- SPECIFIC
			 WHEN questionnaire_action_id = 3 THEN 1 -- BOOLEAN
			 WHEN questionnaire_action_id = 4 THEN 1 -- BOOLEAN
			 WHEN questionnaire_action_id = 5 THEN 1 -- BOOLEAN
			 WHEN questionnaire_action_id = 6 THEN 1 -- BOOLEAN
		END permission_type
		  FROM chain.questionnaire_action;
			
/***********************************************************************
	v$company_action_capability - company -> questionnaire_action -> capability mapping
***********************************************************************/
CREATE OR REPLACE VIEW chain.v$company_action_capability
AS
    SELECT c.capability_id, x.company_function_id, x.company_sid, x.id company_group_type_id, ctr.role_sid, qa.questionnaire_action_id, x.action_security_type_id, qa.permission_set
	  FROM (
			 SELECT company_sid, company_function_id, action_security_type_id, id, CASE WHEN company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') AND company_function_id = 1 THEN 1 ELSE 0 END is_supplier
			   FROM (
				SELECT DISTINCT action_security_type_id, id, company_sid, company_function_id 
				  FROM TT_QNR_SECURITY_ENTRY 
				 WHERE action_security_type_id = 1
				 )
		   ) x
	  JOIN company_func_qnr_action cfqa ON x.company_function_id = cfqa.company_function_id
	  JOIN chain.v$qnr_action_capability qa ON qa.questionnaire_action_id = cfqa.questionnaire_action_id 
	  JOIN capability c ON x.is_supplier = c.is_supplier AND qa.capability_name = c.capability_name
	  LEFT JOIN chain.company_type_role ctr ON x.id = ctr.role_sid
	 WHERE qa.capability_name = c.capability_name
	   AND qa.questionnaire_action_id = cfqa.questionnaire_action_id
	   AND x.company_function_id = cfqa.company_function_id
	   AND x.is_supplier = c.is_supplier;
			
/***********************************************************************
	v$qnr_security_scheme_summary
***********************************************************************/
CREATE OR REPLACE VIEW chain.v$qnr_security_scheme_summary
AS
	SELECT NVL(p.security_scheme_id, s.security_scheme_id) security_scheme_id, 
       NVL(p.action_security_type_id, s.action_security_type_id) action_security_type_id,
       CASE WHEN p.company_function_id > 0 THEN 1 ELSE 0 END has_procurer_config, 
       CASE WHEN s.company_function_id > 0 THEN 1 ELSE 0 END has_supplier_config
	  FROM (
			  SELECT security_scheme_id, action_security_type_id, company_function_id
				FROM qnr_security_scheme_config
			   WHERE company_function_id = 1
			   GROUP BY security_scheme_id, action_security_type_id, company_function_id
		   ) p
	 FULL JOIN (           
			  SELECT security_scheme_id, action_security_type_id, company_function_id
				FROM qnr_security_scheme_config
			   WHERE company_function_id = 2
			   GROUP BY security_scheme_id, action_security_type_id, company_function_id
		   ) s
	   ON p.security_scheme_id = s.security_scheme_id AND p.action_security_type_id = s.action_security_type_id;
	   
/***********************************************************************
	v$questionnaire_type_status
***********************************************************************/
CREATE OR REPLACE VIEW CHAIN.v$questionnaire_type_status AS
	SELECT questionnaire_type_id, component_id, questionnaire_name, company_sid, status_id 
	  FROM (
		SELECT qt.questionnaire_type_id, qt.name questionnaire_name, qs.component_id, c.company_sid,
			CASE 
				WHEN qs.has_expired = 1 THEN 20	 					--SHARED_DATA_EXPIRED
				WHEN qs.share_status_id IN (14, 19) THEN 14 		--SHARED_DATA_ACCEPTED, SHARED_DATA_RESENT -> SHARED_DATA_ACCEPTED
				WHEN qs.share_status_id = 12 THEN 12 				--SHARING_DATA
				WHEN qs.share_status_id = 11 AND qs.due_by_dtm >= SYSDATE THEN 16	--NOT_SHARED -> NOT_SHARED_PENDING
				WHEN qs.share_status_id = 11 AND qs.due_by_dtm < SYSDATE THEN 17	--NOT_SHARED -> NOT_SHARED_OVERDUE
				WHEN qs.share_status_id = 13 THEN 13				--SHARED_DATA_RETURNED
				WHEN qs.share_status_id = 15 THEN 15				--SHARED_DATA_REJECTED
				WHEN i.invitation_status_id = 1 THEN 21				--ACTIVE-> QNR_INVITATION_NOT_ACCEPTED
				WHEN i.invitation_status_id = 5 THEN 16				--ACCEPTED-> NOT_SHARED_PENDING
				WHEN i.invitation_status_id IN (6,7,9,11,12) THEN 22 --REJECTED_NOT_EMPLOYEE, REJECTED_NOT_SUPPLIER, CANNOT_ACCEPT_TERMS, REJECTED_NOT_PARTNER, REJECTED_QNNAIRE_REQ-> QNR_INVITATION_DECLINED
				WHEN i.invitation_status_id = 2 THEN 23				--EXPIRED-> QNR_INVITATION_EXPIRED
				ELSE NULL
			END status_id
		  FROM company c
		  LEFT JOIN invitation i ON c.company_sid = i.to_company_sid
		  LEFT JOIN invitation_qnr_type iqt ON i.invitation_id = iqt.invitation_id
		  LEFT JOIN v$questionnaire_share qs 
			ON NVL(iqt.questionnaire_type_id, qs.questionnaire_type_id) = qs.questionnaire_type_id 
		   AND c.company_sid = qs.qnr_owner_company_sid 
		   AND (NVL(i.on_behalf_of_company_sid, i.from_company_sid) IS NULL OR qs.share_with_company_sid IN (i.on_behalf_of_company_sid, i.from_company_sid))
		  JOIN questionnaire_type qt ON NVL(iqt.questionnaire_type_id,qs.questionnaire_type_id) = qt.questionnaire_type_id
		 WHERE (qs.share_with_company_sid IS NULL OR qs.share_with_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
		   AND (NVL(i.on_behalf_of_company_sid, i.from_company_sid) IS NULL OR SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') IN (i.on_behalf_of_company_sid, i.from_company_sid))
	  ) 
	 WHERE status_id IS NOT NULL
	 GROUP BY questionnaire_type_id, component_id, questionnaire_name, company_sid, status_id;
	   
/***********************************************************************
	v$card_manager - utility view to see which cards are used in each card manager
***********************************************************************/
CREATE OR REPLACE VIEW CHAIN.v$card_manager AS
	SELECT cgc.app_sid, cg.card_group_id, cg.name card_group_name, c.js_class_type, c.class_type, cgc.position
	  FROM card_group cg, card_group_card cgc, card c
	 WHERE cgc.app_sid = NVL(SYS_CONTEXT('SECURITY', 'APP'), cgc.app_sid)
	   AND cgc.card_group_id = cg.card_group_id
	   AND cgc.card_id = c.card_id
	 ORDER BY cgc.card_group_id, cgc.app_sid, cgc.position
;

CREATE OR REPLACE VIEW CHAIN.v$message_definition AS
	SELECT dmd.message_definition_id,  
	       NVL(md.message_template, dmd.message_template) message_template,
	       NVL(md.message_priority_id, dmd.message_priority_id) message_priority_id,
	       dmd.repeat_type_id,
	       dmd.addressing_type_id,
	       NVL(md.completion_type_id, dmd.completion_type_id) completion_type_id,
	       NVL(md.completed_template, dmd.completed_template) completed_template,
	       NVL(md.helper_pkg, dmd.helper_pkg) helper_pkg,
	       NVL(md.css_class, dmd.css_class) css_class
	  FROM default_message_definition dmd, (
	          SELECT app_sid, message_definition_id, message_template, message_priority_id, completed_template, helper_pkg, css_class, completion_type_id
	            FROM message_definition
	           WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	       ) md
	 WHERE dmd.message_definition_id = md.message_definition_id(+)
;

CREATE OR REPLACE VIEW CHAIN.v$message_param AS
	SELECT dmp.message_definition_id,  
		   dmp.param_name,
		   NVL(mp.value, dmp.value) value,
		   NVL(mp.href, dmp.href) href,
		   NVL(mp.css_class, dmp.css_class) css_class
	  FROM default_message_param dmp, (
	  		SELECT app_sid, message_definition_id, param_name, value, href, css_class
	  		  FROM message_param 
	  		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	  	   ) mp
	 WHERE dmp.message_definition_id = mp.message_definition_id(+)
	   AND dmp.param_name = mp.param_name(+)
;

CREATE OR REPLACE VIEW CHAIN.v$message AS
	SELECT m.app_sid, m.message_id, m.message_definition_id, 
			m.re_company_sid, m.re_secondary_company_sid, m.re_user_sid,
			m.re_questionnaire_type_id, m.re_component_id, m.re_invitation_id, m.re_audit_request_id,
			m.due_dtm, m.completed_dtm, m.completed_by_user_sid,
			mrl0.refresh_dtm created_dtm, mrl.refresh_dtm last_refreshed_dtm, mrl.refresh_user_sid last_refreshed_by_user_sid
	  FROM message m, message_refresh_log mrl0, message_refresh_log mrl,
		(
			SELECT message_id, MAX(refresh_index) max_refresh_index
			  FROM message_refresh_log 
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 GROUP BY message_id
		) mlr
	 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND m.app_sid = mrl0.app_sid
	   AND m.app_sid = mrl.app_sid
	   AND m.message_id = mrl0.message_id
	   AND m.message_id = mrl.message_id
	   AND mrl0.refresh_index = 0
	   AND mlr.message_id = mrl.message_id
	   AND mlr.max_refresh_index = mrl.refresh_index
;

-- how to make your SQL views perform really badly....
CREATE OR REPLACE VIEW CHAIN.v$message_recipient AS
	SELECT m.app_sid, m.message_id, m.message_definition_id, 
			m.re_company_sid, m.re_secondary_company_sid, m.re_invitation_id,
			m.re_user_sid, m.re_questionnaire_type_id, m.re_component_id, 
			m.re_audit_request_id, m.completed_dtm, m.completed_by_user_sid,
			r.recipient_id, r.to_company_sid, r.to_user_sid, 
			mrl.refresh_dtm last_refreshed_dtm, mrl.refresh_user_sid last_refreshed_by_user_sid
	  FROM message_recipient mr, message m, recipient r, message_refresh_log mrl,
		(
			SELECT message_id, MAX(refresh_index) max_refresh_index
			  FROM message_refresh_log 
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 GROUP BY message_id
		) mlr
	 WHERE mr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND mr.app_sid = m.app_sid
	   AND mr.app_sid = r.app_sid
	   AND mr.app_sid = mrl.app_sid
	   AND mr.message_id = m.message_id
	   AND mr.message_id = mrl.message_id
	   AND mr.recipient_id = r.recipient_id
	   AND mlr.message_id = mrl.message_id
	   AND mlr.max_refresh_index = mrl.refresh_index
;

CREATE OR REPLACE VIEW chain.v$company_invitation_status AS
SELECT i.company_sid, i.invitation_status_id, st.filter_description invitation_status_description, i.invitation_id
  FROM (
	SELECT to_company_sid company_sid, invitation_status_id, invitation_id FROM (
		SELECT to_company_sid,
				NVL(DECODE(invitation_status_id,
					6, 7,--chain_pkg.REJECTED_NOT_SUPPLIER, chain_pkg.REJECTED_NOT_EMPLOYEE
					4, 5),--chain_pkg.PROVISIONALLY_ACCEPTED, chain_pkg.ACCEPTED
					invitation_status_id) invitation_status_id,
				ROW_NUMBER() OVER (PARTITION BY to_company_sid ORDER BY DECODE(invitation_status_id, 
					5, 1,--chain_pkg.ACCEPTED, 1,
					4, 1,--chain_pkg.PROVISIONALLY_ACCEPTED, 1,
					1, 2,--chain_pkg.ACTIVE, 2,
					2, 3, --chain_pkg.EXPIRED, 3,
					3, 3, --chain_pkg.CANCELLED, 3,
					6, 3, --chain_pkg.REJECTED_NOT_EMPLOYEE, 3,
					7, 3 --chain_pkg.REJECTED_NOT_SUPPLIER, 3
				), sent_dtm DESC) rn,
				invitation_id
		  FROM invitation
		 WHERE from_company_sid = NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), from_company_sid)
		)
	 WHERE rn = 1
	 UNION
	SELECT company_sid, 10 /* chain_pkg.NOT_INVITED */, NULL invitation_id
	  FROM v$company
	 WHERE company_sid NOT IN (
		SELECT to_company_sid
		  FROM invitation
		 WHERE from_company_sid = NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), from_company_sid)
		)
	) i
  JOIN invitation_status st on i.invitation_status_id = st.invitation_status_id;

  
CREATE OR REPLACE VIEW chain.v$chain_user_invitation_status AS
	SELECT usr.app_sid, usr.user_sid, usr.email, usr.user_name, usr.full_name, usr.friendly_name, usr.phone_number, usr.job_title, usr.visibility_id, usr.registration_status_id, usr.receive_scheduled_alerts, usr.details_confirmed, usr.company_sid, usr.invitation_id, usr.invitation_sent_dtm, usr.invitation_status_id, usr.from_user_sid, usr.from_company_sid
	  FROM (
		SELECT vcu.app_sid, vcu.user_sid, vcu.email, vcu.user_name, vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title, vcu.visibility_id, vcu.registration_status_id, 
			vcu.receive_scheduled_alerts, vcu.details_confirmed, i.to_company_sid company_sid, i.invitation_id, i.sent_dtm invitation_sent_dtm, i.from_user_sid, i.from_company_sid,
			NVL(DECODE(invitation_status_id,
				4, 5),--chain_pkg.PROVISIONALLY_ACCEPTED, chain_pkg.ACCEPTED
				invitation_status_id) invitation_status_id,
			ROW_NUMBER() OVER (PARTITION BY i.to_company_sid, vcu.user_sid ORDER BY DECODE(i.invitation_status_id, 
				5, 1, --chain_pkg.ACCEPTED, 1,
				4, 1, --chain_pkg.PROVISIONALLY_ACCEPTED, 1,
				1, 2, --chain_pkg.ACTIVE, 2,
				2, 3, --chain_pkg.EXPIRED, 3,
				3, 3, --chain_pkg.CANCELLED, 3,
				   4  --default
				), 
				sent_dtm DESC  --let sent_dtm determine the precedence of EXPIRED, CANCELLED AS in v$company_invitation_status
			) rn
		  FROM v$chain_user vcu
		  JOIN chain.invitation i ON (i.to_user_sid = vcu.user_sid)
		) usr
	 WHERE usr.rn = 1;

CREATE OR REPLACE VIEW CHAIN.v$filter_type AS
	SELECT f.filter_type_id, f.helper_pkg, c.js_include, c.js_class_type, f.description
	  FROM filter_type f
	  JOIN card c ON f.card_id = c.card_id;

CREATE OR REPLACE VIEW chain.v$filter_value AS
       SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, fv.filter_value_id, fv.str_value,
			fv.num_value, fv.min_num_val, fv.max_num_val, fv.start_dtm_value, fv.end_dtm_value, fv.region_sid, fv.user_sid,
			fv.compound_filter_id_value, fv.saved_filter_sid_value, fv.pos,
			COALESCE(
				fv.description,
				CASE fv.user_sid WHEN -1 THEN 'Me' WHEN -2 THEN 'My roles' WHEN -3 THEN 'My staff' END,
				r.description,
				cu.full_name,
				cr.name,
				fv.str_value
			) description,
			ff.group_by_index,
			f.compound_filter_id, ff.show_all, ff.period_set_id, ff.period_interval_id, fv.start_period_id, 
			fv.filter_type, fv.null_filter, fv.colour, ff.comparator, ff.row_or_col
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id
	  JOIN filter_value fv ON ff.app_sid = fv.app_sid AND ff.filter_field_id = fv.filter_field_id
	  LEFT JOIN csr.v$region r ON fv.region_sid = r.region_sid AND fv.app_sid = r.app_sid
	  LEFT JOIN csr.csr_user cu ON fv.user_sid = cu.csr_user_sid AND fv.app_sid = cu.app_sid
	  LEFT JOIN csr.role cr ON fv.user_sid = cr.role_sid AND fv.app_sid = cr.app_sid;

CREATE OR REPLACE VIEW CHAIN.v$filter_field AS
	SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, ff.show_all, ff.group_by_index,
		   f.compound_filter_id, ff.top_n, ff.bottom_n, ff.column_sid, ff.period_set_id,
		   ff.period_interval_id, ff.show_other, ff.comparator, ff.row_or_col
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id;

/***********************************************************************
v$alert_entry_type - used to get alert_entry_type information including app specific overrides
***********************************************************************/
CREATE OR REPLACE VIEW CHAIN.v$alert_entry_type AS
	SELECT co.app_sid, 
		   aet.alert_entry_type_id, 
		   aet.std_alert_type_id,
		   aet.description, 
       NVL(caet.important_section_template, aet.important_section_template) important_section_template,
       NVL(caet.company_section_template, aet.company_section_template) company_section_template,
       NVL(caet.user_section_template, aet.user_section_template) user_section_template,
	   NVL(caet.generator_sp, aet.generator_sp) generator_sp,
       NVL(caet.schedule_xml, aet.schedule_xml) schedule_xml,
	DECODE(DECODE(caet.force_disable, NULL, aet.force_disable, 1, 1, 0, aet.force_disable), 0, NVL(caet.enabled, aet.enabled), 1, 0) enabled,
	DECODE(caet.force_disable, NULL, aet.force_disable, 1, 1, 0, aet.force_disable) force_disable	
	  FROM chain.alert_entry_type aet
	  JOIN chain.customer_options co
		ON SYS_CONTEXT('SECURITY','APP') = co.app_sid OR SYS_CONTEXT('SECURITY','APP') IS NULL
	  LEFT JOIN chain.customer_alert_entry_type caet
		ON aet.alert_entry_type_id = caet.alert_entry_type_id
	   AND caet.app_sid = co.app_sid;   
	   
/***********************************************************************
v$alert_entry_template - used to get alert_entry_template information including app specific overrides
***********************************************************************/
CREATE OR REPLACE VIEW CHAIN.v$alert_entry_template AS
SELECT * FROM (
    SELECT co.app_sid, 
           aet.alert_entry_type_id,
           NVL(caet.template_name, aet.template_name) template_name,
           NVL(caet.template, aet.template) template
      FROM chain.alert_entry_template aet
      JOIN chain.customer_options co
        ON SYS_CONTEXT('SECURITY','APP') = co.app_sid OR SYS_CONTEXT('SECURITY','APP') IS NULL  
      LEFT JOIN chain.customer_alert_entry_template caet
        ON aet.alert_entry_type_id = caet.alert_entry_type_id
       AND aet.template_name = caet.template_name
       AND caet.app_sid = co.app_sid
    UNION
    SELECT app_sid, alert_entry_type_id, template_name, template
      FROM chain.customer_alert_entry_template
    );
	
CREATE OR REPLACE VIEW chain.v$activity AS
SELECT a.activity_id, a.description, a.target_company_sid, a.created_by_company_sid, 
	   a.project_id, p.name project_name,
       a.activity_type_id, at.label activity_type_label, at.lookup_key activity_type_lookup_key,
	   a.assigned_to_user_sid, acu.full_name assigned_to_user_name,
	   a.assigned_to_role_sid, acr.name assigned_to_role_name,
	   CASE WHEN a.assigned_to_role_sid IS NOT NULL THEN acr.name ELSE acu.full_name END assigned_to_name,
	   a.target_user_sid, tcu.full_name target_user_name, 
	   a.target_role_sid, tcr.name target_role_name, 
	   CASE WHEN a.target_role_sid IS NOT NULL THEN tcr.name ELSE tcu.full_name END target_name,
	   a.activity_dtm, a.original_activity_dtm, 
	   a.created_dtm, a.created_by_activity_id, a.created_by_sid, ccu.full_name created_by_user_name,
	   a.outcome_type_id, ot.label outcome_type_label, ot.is_success, ot.is_failure, ot.is_deferred,
	   a.outcome_reason, a.location, a.location_type,
	   CASE WHEN at.can_share = 1 AND a.share_with_target = 1 THEN 1 ELSE 0 END share_with_target,
	   CASE WHEN a.activity_dtm <= SYSDATE AND a.outcome_type_id IS NULL THEN 'Overdue'
	   WHEN a.activity_dtm > SYSDATE AND a.outcome_type_id IS NULL THEN 'Up-coming'
	   ELSE 'Completed' END status, tc.name target_company_name
  FROM activity a
  JOIN activity_type at ON at.activity_type_id = a.activity_type_id
  LEFT JOIN project p ON p.project_id = a.project_id
  LEFT JOIN outcome_type ot ON ot.outcome_type_id = a.outcome_type_id
  LEFT JOIN csr.csr_user acu ON acu.csr_user_sid = a.assigned_to_user_sid
  LEFT JOIN csr.role acr ON acr.role_sid = a.assigned_to_role_sid
  LEFT JOIN csr.csr_user tcu ON tcu.csr_user_sid = a.target_user_sid
  LEFT JOIN csr.role tcr ON tcr.role_sid = a.target_role_sid
  JOIN csr.csr_user ccu ON ccu.csr_user_sid = a.created_by_sid
  JOIN company tc ON a.target_company_sid = tc.company_sid;
	
CREATE OR REPLACE VIEW chain.v$activity_log AS
SELECT al.activity_log_id, al.activity_id, al.message, al.logged_dtm, al.is_system_generated,
       al.logged_by_user_sid, al.param_1, al.param_2, al.param_3, al.is_visible_to_supplier,
	   al.reply_to_activity_log_id, NVL(al.correspondent_name,cu.full_name) logged_by_full_name,
	   cu.email logged_by_email, al.is_from_email
  FROM activity_log al
  JOIN activity a ON al.activity_id = a.activity_id
  JOIN csr.csr_user cu ON al.logged_by_user_sid = cu.csr_user_sid
 WHERE a.app_sid = SYS_CONTEXT('SECURITY', 'APP')
   AND (a.created_by_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		OR (al.is_visible_to_supplier = 1
			AND a.target_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		)
	);

CREATE OR REPLACE VIEW CHAIN.v$company_tag AS
	SELECT c.app_sid, c.company_sid, c.name company_name, ct.source, tg.name tag_group_name, t.tag, tg.tag_group_id, t.tag_id, t.lookup_key tag_lookup_key, c.active
	  FROM company c
	  JOIN (
		SELECT s.app_sid, s.company_sid, rt.tag_id, 'Supplier region tag' source
		  FROM csr.supplier s
		  JOIN csr.region_tag rt ON s.region_sid = rt.region_sid AND s.app_sid = rt.app_sid
		 UNION
		SELECT cpt.app_sid, cpt.company_sid, ptt.tag_id, 'Product type tag' source
		  FROM company_product_type cpt
		  JOIN product_type_tag ptt ON cpt.product_type_id = ptt.product_type_id AND cpt.app_sid = ptt.app_sid
	  ) ct ON c.company_sid = ct.company_sid AND c.app_sid = ct.app_sid
	  JOIN csr.v$tag t ON ct.tag_id = t.tag_id AND ct.app_sid = t.app_sid
	  JOIN csr.tag_group_member tgm ON t.tag_id = tgm.tag_id AND t.app_sid = tgm.app_sid
	  JOIN csr.v$tag_group tg ON tgm.tag_group_id = tg.tag_group_id AND tgm.app_sid = tg.app_sid
;

CREATE OR REPLACE VIEW chain.v$purchaser_involvement AS
	SELECT sit.flow_involvement_type_id, sr.supplier_company_sid
	  FROM supplier_relationship sr
	  JOIN company pc ON pc.company_sid = sr.purchaser_company_sid
	  LEFT JOIN csr.supplier ps ON ps.company_sid = pc.company_sid
	  JOIN company sc ON sc.company_sid = sr.supplier_company_sid
	  JOIN supplier_involvement_type sit
		ON (sit.user_company_type_id IS NULL OR sit.user_company_type_id = pc.company_type_id)
	   AND (sit.page_company_type_id IS NULL OR sit.page_company_type_id = sc.company_type_id)
	   AND (sit.purchaser_type = 1 /*chain_pkg.PURCHASER_TYPE_ANY*/
		OR (sit.purchaser_type = 2 /*chain_pkg.PURCHASER_TYPE_PRIMARY*/ AND sr.is_primary = 1)
		OR (sit.purchaser_type = 3 /*chain_pkg.PURCHASER_TYPE_OWNER*/ AND pc.company_sid = sc.parent_sid)
	   )
	  LEFT JOIN csr.region_role_member rrm
	    ON rrm.region_sid = ps.region_sid
	   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND rrm.role_sid = sit.restrict_to_role_sid
	 WHERE pc.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND pc.deleted = 0
	   AND sc.deleted = 0
	   AND sr.deleted = 0
	   AND (sit.restrict_to_role_sid IS NULL OR rrm.user_sid IS NOT NULL);

CREATE OR REPLACE VIEW CHAIN.v$supplier_capability AS
	SELECT sr.supplier_company_sid,
		   fsrc.flow_capability_id,
		   MAX(BITAND(fsrc.permission_set, 1)) + --security_pkg.PERMISSION_READ
		   MAX(BITAND(fsrc.permission_set, 2)) permission_set --security_pkg.PERMISSION_WRITE
	  FROM v$supplier_relationship sr
	  JOIN csr.flow_item fi ON fi.flow_item_id = sr.flow_item_id
	  JOIN csr.flow_state_role_capability fsrc ON fsrc.flow_state_id = fi.current_state_id
	  JOIN csr.supplier s ON s.company_sid = sr.supplier_company_sid
	  LEFT JOIN csr.region_role_member rrm
			 ON rrm.region_sid = s.region_sid
			AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
			AND rrm.role_sid = fsrc.role_sid
	  LEFT JOIN v$purchaser_involvement inv
		ON inv.flow_involvement_type_id = fsrc.flow_involvement_type_id
	   AND inv.supplier_company_sid = sr.supplier_company_sid
	 WHERE (sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			OR sr.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
	   AND (inv.flow_involvement_type_id IS NOT NULL
	    OR (fsrc.flow_involvement_type_id = 1002 /*csr.csr_data_pkg.FLOW_INV_TYPE_SUPPLIER*/
			AND sr.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
	    OR rrm.role_sid IS NOT NULL)
	GROUP BY sr.supplier_company_sid, fsrc.flow_capability_id;
		
CREATE OR REPLACE VIEW chain.v$company_reference AS
	SELECT cr.app_sid, cr.company_reference_id, cr.company_sid, cr.value, cr.reference_id, r.lookup_key, r.label
	  FROM chain.company_reference cr
	  JOIN chain.reference r ON r.app_sid = cr.app_sid AND r.reference_id = cr.reference_id;
	  
CREATE OR REPLACE VIEW chain.v$debug_log AS
	SELECT app_sid, debug_log_id, end_dtm - start_dtm duration, label, object_id, start_dtm, end_dtm
	  FROM chain.debug_log
	 ORDER BY debug_log_id DESC;

CREATE OR REPLACE VIEW chain.v$higg_response AS
	SELECT *
	  FROM (
		SELECT hr.app_sid, hr.higg_response_id, hr.higg_module_id, hp.higg_profile_id, hr.last_updated_dtm,
		       hr.response_year, hr.verification_status, max(hr.last_updated_dtm) OVER (PARTITION BY hp.higg_profile_id, higg_module_id, hr.response_year) max_date
		  FROM CHAIN.higg_profile hp
		  JOIN CHAIN.higg_response hr 
		    ON hr.higg_profile_id = hp.higg_profile_id 
		   AND hr.response_year = hp.response_year
		   AND hr.app_sid = hp.app_sid
		)
	 WHERE last_updated_dtm = max_date;


CREATE OR REPLACE VIEW chain.v$grid_extension AS
	WITH enabled_card_groups AS 
	(
		SELECT DISTINCT cgc.app_sid, cgc.card_group_id
		  FROM chain.card_group_card cgc
		  JOIN chain.filter_type ft ON cgc.card_id = ft.card_id
	)
	SELECT grid_extension_id, 
		   base_card_group_id, 
		   cg1.name base_card_group_name, 
		   extension_card_group_id, 
		   cg2.name extension_card_group_name, 
		   record_name,
		   cg1.name  || ' -> ' || cg2.name name
	  FROM chain.grid_extension ge
	  JOIN chain.card_group cg1 ON cg1.card_group_id = ge.base_card_group_id
	  JOIN chain.card_group cg2 ON cg2.card_group_id = ge.extension_card_group_id
	 WHERE cg1.card_group_id IN (SELECT card_group_id FROM enabled_card_groups)
	   AND cg2.card_group_id IN (SELECT card_group_id FROM enabled_card_groups);	

CREATE OR REPLACE VIEW chain.v$product_type AS
	SELECT pt.app_sid, pt.product_type_id, pt.parent_product_type_id, pttr.description, pt.lookup_key, pt.node_type, pt.active
	  FROM product_type pt, product_type_tr pttr
	 WHERE pt.app_sid = pttr.app_sid AND pt.product_type_id = pttr.product_type_id
	   AND pttr.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');	   
	
CREATE OR REPLACE VIEW chain.v$company_product AS
	SELECT cp.app_sid, cp.product_id, tr.description product_name, cp.company_sid, cp.product_type_id,
		   cp.product_ref, cp.lookup_key, cp.is_active
	  FROM chain.company_product cp
	  JOIN chain.company_product_tr tr ON tr.product_id = cp.product_id AND tr.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');


/***********************************************************************
v$supplier_certification - gets certification data for suppliers
***********************************************************************/

CREATE OR REPLACE VIEW chain.v$supplier_certification AS
	SELECT cat.app_sid, cat.certification_type_id, ia.internal_audit_sid certification_id,
		   ia.internal_audit_sid, s.company_sid, ia.internal_audit_type_id, ia.audit_dtm valid_from_dtm,
		   CASE (atct.re_audit_due_after_type)
				WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
				WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
				WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
				WHEN 'y' THEN nvl(ia.ovw_validity_dtm, add_months(ia.audit_dtm, atct.re_audit_due_after*12))
				ELSE ia.ovw_validity_dtm 
			END expiry_dtm, atct.audit_closure_type_id 
	FROM chain.cert_type_audit_type cat 
	JOIN csr.internal_audit ia ON ia.internal_audit_type_id = cat.internal_audit_type_id
	 AND cat.app_sid = ia.app_sid
	 AND ia.deleted = 0
	JOIN csr.supplier s  ON ia.region_sid = s.region_sid AND s.app_sid = ia.app_sid
	LEFT JOIN csr.audit_type_closure_type atct ON ia.audit_closure_type_id = atct.audit_closure_type_id 
	 AND ia.internal_audit_type_id = atct.internal_audit_type_id
	 AND ia.app_sid = atct.app_sid
	LEFT JOIN csr.audit_closure_type act ON atct.audit_closure_type_id = act.audit_closure_type_id 
	 AND act.app_sid = atct.app_sid
   WHERE NVL(act.is_failure, 0) = 0
	 AND (ia.flow_item_id IS NULL 
	  OR EXISTS(
			SELECT fi.flow_item_id 
			  FROM csr.flow_item fi 
			  JOIN csr.flow_state fs ON fs.flow_state_id = fi.current_state_id AND fs.is_final = 1 
			 WHERE fi.flow_item_id = ia.flow_item_id));

CREATE OR REPLACE VIEW chain.v$bsci_supplier AS
	SELECT bs.app_sid, bs.bsci_supplier_id, bs.company_sid, bs.bsci_factory_id, bsd.version_number, bs.last_updated_dtm,
		   bsd.address,
		   bsd.city,
		   bsd.industry,
		   bsd.country,
		   bsd.postcode,
		   bsd.region,
		   bsd.territory,
		   bsd.address_location_type,
		   bsd.audit_announcement_method,
		   bsd.factory_contact,
		   bsd.audit_expiration_dtm,
		   bsd.audit_in_progress,
		   bsd.audit_result,
		   bsd.bsci_comments,
		   bsd.linked_participants,
		   bsd.in_commitments,
		   bsd.in_supply_chain,
		   bsd.legal_status,
		   bsd.name,
		   bsd.number_of_associates,
		   bsd.number_of_buildings,
		   bsd.participant_name,
		   bsd.product_group,
		   bsd.product_type,
		   bsd.code_of_conduct_accepted,
		   bsd.code_of_conduct_signed,
		   bsd.audit_dtm,
		   bsd.sector,
		   bsd.website,
		   bsd.year_founded,
		   bsd.audit_type,
		   bsd.rsp_id,
		   bsd.is_audit_in_progress,
		   bsd.audit_in_progress_dtm,
		   bsd.code_of_conduct_sign_int,
		   bsd.sa8000_certified,
		   bsd.audit_certification,
		   bsd.address_type,
		   bsd.alias,
		   bsd.brands,
		   bsd.business_unit,
		   bsd.email_address,
		   s.region_sid
    FROM chain.bsci_supplier bs
    JOIN chain.bsci_supplier_det bsd ON bs.bsci_supplier_id = bsd.bsci_supplier_id AND bs.latest_version = bsd.version_number
    JOIN csr.supplier s ON s.company_sid = bs.company_sid
;

CREATE OR REPLACE VIEW chain.v$bsci_2009_audit AS
	SELECT ba.app_sid, ba.bsci_audit_id bsci_2009_audit_id, ba.internal_audit_sid, bad.version_number, ba.last_updated_dtm,
		   bad.audit_ref,
		   bad.dtm,
		   bad.expiry_dtm,
		   bad.score,
		   bad.audit_announced,
		   bad.audit_stage,
		   bad.audit_methodology,
		   bad.man_days,
		   bad.cycle,
		   bad.total_turnover,
		   bad.interview_essentials,
		   bad.lead_auditor_name,
		   bad.b_1,
		   bad.b_2,
		   bad.b_3,
		   bad.b_4,
		   bad.b_5_1,
		   bad.b_5_2,
		   bad.b_6,
		   bad.b_7,
		   bad.b_8,
		   bad.b_9,
		   bad.b_10,
		   bad.b_11,
		   bad.b_12,
		   bad.b_13,
		   ia.region_sid
    FROM chain.bsci_audit ba
    JOIN chain.bsci_2009_audit bad ON ba.bsci_audit_id = bad.bsci_audit_id AND ba.latest_version = bad.version_number
    JOIN csr.internal_audit ia ON ia.internal_audit_sid = ba.internal_audit_sid
;

CREATE OR REPLACE VIEW chain.v$bsci_2014_audit AS
	SELECT ba.app_sid, ba.bsci_audit_id bsci_2014_audit_id, ba.internal_audit_sid, bad.version_number, ba.last_updated_dtm,
		   bad.audit_ref,
		   bad.dtm,
		   bad.expiry_dtm,
		   bad.score,
		   bad.audit_announced,
		   bad.audit_stage,
		   bad.audit_environment,
		   bad.auditing_company,
		   bad.auditing_company_branch,
		   bad.man_days,
		   bad.need_follow_up,
		   bad.auditor_comments,
		   bad.executive_summary_audit_rpt,
		   bad.interview_essentials,
		   bad.lead_auditor_name,
		   bad.pa1,
		   bad.pa2,
		   bad.pa3,
		   bad.pa4,
		   bad.pa5,
		   bad.pa6,
		   bad.pa7,
		   bad.pa8,
		   bad.pa9,
		   bad.pa10,
		   bad.pa11,
		   bad.pa12,
		   bad.pa13,
		   ia.region_sid
    FROM chain.bsci_audit ba
    JOIN chain.bsci_2014_audit bad ON ba.bsci_audit_id = bad.bsci_audit_id AND ba.latest_version = bad.version_number
    JOIN csr.internal_audit ia ON ia.internal_audit_sid = ba.internal_audit_sid
;

CREATE OR REPLACE VIEW chain.v$bsci_ext_audit AS
	SELECT ba.app_sid, ba.bsci_audit_id bsci_ext_audit_id, ba.internal_audit_sid, bad.version_number, ba.last_updated_dtm,
		   bad.audit_ref,
		   bad.dtm,
		   bad.expiry_dtm,
		   bad.audit_score,
		   bad.audit_type,
		   bad.external_audit_type,
		   bad.auditing_company,
		   bad.sequence_number,
		   ia.region_sid
    FROM chain.bsci_audit ba
    JOIN chain.bsci_ext_audit bad ON ba.bsci_audit_id = bad.bsci_audit_id AND ba.latest_version = bad.version_number
    JOIN csr.internal_audit ia ON ia.internal_audit_sid = ba.internal_audit_sid
;

/***********************************************************************
v$current_country_risk_level - gets latest country risk level
***********************************************************************/
CREATE OR REPLACE VIEW chain.v$current_country_risk_level AS
	SELECT crl.app_sid, crl.country, rl.risk_level_id, rl.label, rl.lookup_key
	  FROM chain.country_risk_level crl
	  JOIN chain.risk_level rl ON rl.risk_level_id = crl.risk_level_id
	 WHERE crl.start_dtm <= SYSDATE
	   AND NOT EXISTS (
			SELECT *
			  FROM chain.country_risk_level crl2
			 WHERE crl2.country = crl.country
			   AND crl2.start_dtm > crl.start_dtm
			   AND crl2.start_dtm <= SYSDATE
		);
