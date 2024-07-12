/***********************************************************************
	v$country - a dummy country lookup
***********************************************************************/
PROMPT >> Creating v$country

CREATE OR REPLACE VIEW v$country AS
	SELECT country country_code, name
	  FROM postcode.country
	 WHERE latitude IS NOT NULL AND longitude IS NOT NULL
;


/***********************************************************************
	v$company = all companies that have not been flagged as deleted
***********************************************************************/
PROMPT >> Creating v$company

CREATE OR REPLACE VIEW v$company AS
	SELECT c.*, cou.name country_name
	  FROM company c, v$country cou
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND c.country_code = cou.country_code(+)
	   AND c.deleted = 0
;


/***********************************************************************
	v$chain_user - a combined view of csr_user and chain_user
	with defaults set where the entry does not exist in chain_user
***********************************************************************/
PROMPT >> Creating v$chain_user

CREATE OR REPLACE VIEW v$chain_user AS
	SELECT csru.app_sid, csru.csr_user_sid user_sid, csru.email,                    -- CSR_USER data
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


/***********************************************************************
	v$company_user_group - a simple view of app_sid, company_sid, 
	user_group_sid
***********************************************************************/
PROMPT >> Creating v$company_user_group

CREATE OR REPLACE VIEW v$company_user_group AS
	SELECT c.app_sid, c.company_sid, so.sid_id user_group_sid
	  FROM security.securable_object so, company c
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND c.app_sid = so.application_sid_id
	   AND so.parent_sid_id = c.company_sid
	   AND so.name = 'Users'
;   


/***********************************************************************
	v$company_pending_group - a simple view of app_sid, company_sid, 
	pending_group_sid
***********************************************************************/
PROMPT >> Creating v$company_pending_group

CREATE OR REPLACE VIEW v$company_pending_group AS
	SELECT c.app_sid, c.company_sid, so.sid_id pending_group_sid
	  FROM security.securable_object so, company c
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND c.app_sid = so.application_sid_id
	   AND so.parent_sid_id = c.company_sid
	   AND so.name = 'Pending Users'
;   


/***********************************************************************
	v$company_admin_group - a simple view of app_sid, company_sid, 
	admin_group_sid
***********************************************************************/
PROMPT >> Creating v$company_admin_group

CREATE OR REPLACE VIEW v$company_admin_group AS
	SELECT c.app_sid, c.company_sid, so.sid_id admin_group_sid
	  FROM security.securable_object so, company c
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND c.app_sid = so.application_sid_id
	   AND so.parent_sid_id = c.company_sid
	   AND so.name = 'Administrators'
;   


/***********************************************************************
	v$company_user - a simple view of all direct users for all companies
	app_sid, company_sid, user_sid
***********************************************************************/
PROMPT >> Creating v$company_user

CREATE OR REPLACE VIEW v$company_user AS
  SELECT cug.app_sid, cug.company_sid, vcu.user_sid
    FROM v$company_user_group cug, v$chain_user vcu, security.group_members gm
   WHERE cug.app_sid = SYS_CONTEXT('SECURITY', 'APP')
     AND cug.app_sid = vcu.app_sid
     AND cug.user_group_sid = gm.group_sid_id
     AND vcu.user_sid = gm.member_sid_id
;


/***********************************************************************
	v$company_pending_user - a simple view of all direct pending users 
	for all companies - app_sid, company_sid, user_sid
***********************************************************************/
PROMPT >> Creating v$company_pending_user

CREATE OR REPLACE VIEW v$company_pending_user AS        
  SELECT cpg.app_sid, cpg.company_sid, vcu.user_sid
    FROM v$company_pending_group cpg, v$chain_user vcu, security.group_members gm
   WHERE cpg.app_sid = SYS_CONTEXT('SECURITY', 'APP')
     AND cpg.app_sid = vcu.app_sid
     AND cpg.pending_group_sid = gm.group_sid_id
     AND vcu.user_sid = gm.member_sid_id
;


/***********************************************************************
	v$company_admin - a simple view of all direct admins for all companies
	app_sid, company_sid, user_sid
***********************************************************************/
PROMPT >> Creating v$company_admin

CREATE OR REPLACE VIEW v$company_admin AS
  SELECT cag.app_sid, cag.company_sid, vcu.user_sid
    FROM v$company_admin_group cag, v$chain_user vcu, security.group_members gm
   WHERE cag.app_sid = SYS_CONTEXT('SECURITY', 'APP')
     AND cag.app_sid = vcu.app_sid
     AND cag.admin_group_sid = gm.group_sid_id
     AND vcu.user_sid = gm.member_sid_id
;


/***********************************************************************
	v$company_member - a simple view of all direct amdmin, user and pending users
	for all companies - app_sid, company_sid, user_sid
***********************************************************************/
PROMPT >> Creating v$company_member

CREATE OR REPLACE VIEW v$company_member AS        
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
	v$active_invite
***********************************************************************/
PROMPT >> Creating v$active_invite

CREATE OR REPLACE VIEW v$active_invite AS
	SELECT *
	  FROM invitation
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND invitation_status_id = 1
;


/***********************************************************************
	v$supplier_relationship - a view of all active supplier relationships

***********************************************************************/
PROMPT >> Creating v$supplier_relationship

CREATE OR REPLACE VIEW v$supplier_relationship AS
	SELECT *
	  FROM supplier_relationship 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
-- either the relationship is active, or it is virtually active for a very short period so that we can send invitations
	   AND (active = 1 OR SYSDATE < virtually_active_until_dtm)
;


/***********************************************************************
	v$company_relationship - a view of all companies that I
	am in a relationship with, whether it be as a purchaser or a supplier 
***********************************************************************/
PROMPT >> Creating v$company_relationship

CREATE OR REPLACE VIEW v$company_relationship AS
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

CREATE OR REPLACE VIEW v$chain_company_user AS
	/**********************************************************************************************************/
	/****************** any invitations from someone in my company to a user in my company  *******************/
	/**********************************************************************************************************/
	SELECT vai.app_sid, vai.to_company_sid company_sid, vcu.user_sid, vcu.visibility_id,
			vcu.email, vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title
	  FROM v$active_invite vai, v$chain_user vcu
	 WHERE vai.app_sid = vcu.app_sid
	   AND vai.from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND vai.to_company_sid = vai.from_company_sid -- an invitation to ourselves
	   AND vai.to_user_sid = vcu.user_sid
	 UNION ALL
	/****************************************************************/
	/****************** I can see all of my users *******************/
	/****************************************************************/
	SELECT cu.app_sid, cu.company_sid, vcu.user_sid, vcu.visibility_id, vcu.email, 
	       vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title
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
	       vcu.email, vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title
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
			vcu.email, vcu.full_name, vcu.friendly_name, -- we can always see these if there's a pending invitation as we've probably filled it in ourselves
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
	SELECT cu.app_sid, cu.company_sid, vcu.user_sid, vcu.visibility_id, 
			CASE WHEN vcu.visibility_id = 3 THEN vcu.email ELSE NULL END email, 
			CASE WHEN vcu.visibility_id >= 2 THEN vcu.full_name ELSE NULL END full_name, 
			CASE WHEN vcu.visibility_id >= 2 THEN vcu.friendly_name ELSE NULL END friendly_name, 
			CASE WHEN vcu.visibility_id = 3 THEN vcu.phone_number ELSE NULL END phone_number, 
			vcu.job_title -- we always see this as we've filtered 'hidden' users
	  FROM v$chain_user vcu, v$company_user cu, v$company_relationship cr
	 WHERE vcu.app_sid = cu.app_sid
	   AND vcu.app_sid = cr.app_sid
	   AND vcu.user_sid = cu.user_sid
	   AND cu.company_sid = cr.company_sid -- we can see companies that we are in a relationship with
	   AND vcu.visibility_id <> 0 -- don't show hidden users
	   AND NOT (vcu.visibility_id = 1 AND vcu.job_title IS NULL)
	   AND (cu.company_sid, cu.user_sid) NOT IN (					-- minus any active questionnaire invitations as these have already been dealt with
	   			SELECT to_company_sid, to_user_sid 
	   			  FROM v$active_invite
	   			 WHERE from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   	   )
;

/***********************************************************************
	v$event = all event's with all join data (users, companies, questionnaires) needed
***********************************************************************/
PROMPT >> Creating v$event

CREATE OR REPLACE VIEW v$event AS
	SELECT 
		e.app_sid,
		-- for company
		for_company_sid, c1.name for_company_name, et.for_company_url,
		-- for user
		for_user_sid, cu1.full_name for_user_full_name, cu1.friendly_name for_user_friendly_name, et.for_user_url,
		-- related company
		related_company_sid, c2.name related_company_name, et.related_company_url,
		-- related user
		related_user_sid, cu2.full_name related_user_full_name, cu2.friendly_name related_user_friendly_name, et.related_user_url,
		-- related questionnaire
		related_questionnaire_id, q.name related_questionnaire_name, et.related_questionnaire_url,
		-- other data
		e.event_id, e.created_dtm, 
		et.other_url_1, et.other_url_2, et.other_url_3, 
		-- event type
		et.event_type_id, message_template, priority,
		-- who is the event for
		NVL2(for_user_sid, cu1.full_name, c1.name) for_whom,
		NVL2(for_user_sid, 1, 0) is_for_user,
		css_class
	FROM 
		event e, event_type et, 
		csr.csr_user cu1, csr.csr_user cu2, 
		company c1, company c2,
		(
			SELECT q.app_sid, q.questionnaire_id, q.questionnaire_type_id, qt.name
			  FROM questionnaire q, questionnaire_type qt 
			 WHERE q.app_sid = qt.app_sid
			   AND q.questionnaire_type_id = qt.questionnaire_type_id
		) q
	WHERE e.app_sid = NVL(SYS_CONTEXT('SECURITY', 'APP'), e.app_sid)
	  --
	  AND e.app_sid = et.app_sid
	  AND e.event_type_id = et.event_type_id
	  --
	  AND e.app_sid = c1.app_sid
	  AND e.for_company_sid = c1.company_sid
	  --
	  AND e.app_sid = c2.app_sid(+)
	  AND e.related_company_sid = c2.company_sid(+)
	  --
	  AND e.app_sid = cu1.app_sid(+)
	  AND e.for_user_sid = cu1.csr_user_sid(+)
	  --
	  AND e.app_sid = cu2.app_sid(+)
	  AND e.related_user_sid = cu2.csr_user_sid(+)
	  --
	  AND e.app_sid = q.app_sid(+)
	  AND e.related_questionnaire_id = q.questionnaire_id(+)
;

/***********************************************************************
	v$action = all actions with all join data (users, companies, questionnaires) needed
***********************************************************************/
PROMPT >> Creating v$action

CREATE OR REPLACE VIEW v$action AS
	SELECT
		a.app_sid,
		-- for company
		for_company_sid, c1.name for_company_name, at.for_company_url,
		-- for user
		for_user_sid, cu1.full_name for_user_full_name, cu1.friendly_name for_user_friendly_name, at.for_user_url,
		-- related company
		related_company_sid, c2.name related_company_name, at.related_company_url,
		-- related user
		related_user_sid, cu2.full_name related_user_full_name, cu2.friendly_name related_user_friendly_name, at.related_user_url,
		-- related questionnaire
		related_questionnaire_id, q.name related_questionnaire_name, 
		REPLACE(
			REPLACE(at.related_questionnaire_url,'{viewQuestionnaireUrl}',q.view_url), 
			'{editQuestionnaireUrl}', q.edit_url
		) related_questionnaire_url,
		-- other data
		action_id, A.created_dtm, due_date, is_complete, completion_dtm,
		at.other_url_1, at.other_url_2, at.other_url_3,
		-- reason for action
		ra.reason_for_action_id, reason_name reason_for_action_name, reason_description reason_for_action_description,
		-- to do - fill this in later
		-- action type
		at.action_type_id, message_template, priority,
		-- who is the action for
		NVL2(for_user_sid, cu1.full_name, c1.name) for_whom,
		NVL2(for_user_sid, 1, 0) is_for_user,
		css_class
	  FROM
		action a, action_type at, reason_for_action ra,
		csr.csr_user cu1, csr.csr_user cu2,
		company c1, company c2,
		(
			  SELECT q.app_sid, q.questionnaire_id, q.questionnaire_type_id, qt.name, qt.view_url, qt.edit_url
				FROM questionnaire q, questionnaire_type qt
			   WHERE q.app_sid = qt.app_sid
			     AND q.questionnaire_type_id = qt.questionnaire_type_id
		) q
	 WHERE a.app_sid = NVL(SYS_CONTEXT('SECURITY', 'APP'), a.app_sid)
	   --
	   AND a.app_sid = at.app_sid
	   AND ra.action_type_id = at.action_type_id
	   --
	   AND a.app_sid = ra.app_sid
	   AND a.reason_for_action_id = ra.reason_for_action_id
	   --
	   AND a.app_sid = c1.app_sid
	   AND a.for_company_sid = c1.company_sid
	   --	   
	   AND a.app_sid = c2.app_sid(+)
	   AND a.related_company_sid = c2.company_sid(+)
	   --
	   AND a.app_sid = cu1.app_sid(+)
	   AND a.for_user_sid = cu1.csr_user_sid(+)
	   --
	   AND a.app_sid = cu2.app_sid(+)
	   AND a.related_user_sid = cu2.csr_user_sid(+)
	   --
	   AND a.app_sid = q.app_sid(+)
	   AND a.related_questionnaire_id = q.questionnaire_id(+)
;

/***********************************************************************
	v$capability
***********************************************************************/
PROMPT >> Creating v$capability

CREATE OR REPLACE VIEW v$capability AS
	SELECT capability_id, capability_name, perm_type, capability_type_id
	  FROM capability
	 WHERE app_sid IS NULL
	    OR app_sid = SYS_CONTEXT('SECURITY', 'APP')
;
	    
/***********************************************************************
	v$group_capability_permission
***********************************************************************/
PROMPT >> Creating v$group_capability_permission

CREATE OR REPLACE VIEW v$group_capability_permission AS
	SELECT gc.group_capability_id, gc.company_group_name, gc.capability_id, ps.permission_set
	  FROM group_capability gc, (
			SELECT group_capability_id, 0 hide_group_capability, permission_set
			  FROM group_capability_perm
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
;
	  
/***********************************************************************
	v$company_product - a simple view of all products with company and created by data
***********************************************************************/
PROMPT >> Creating v$company_product
CREATE OR REPLACE VIEW v$company_product AS
SELECT product_id, p.app_sid, p.company_sid, c.name company_name, p.created_by_sid, cu.full_name created_by, p.created_dtm, p.description, p.active, 
        code_label1, code1, code_label2, code2, code_label3, code3, need_review, p.deleted, p.root_component_id, p.product_builder_component_id
      FROM product p, product_code_type pct, v$company c, csr.csr_user cu
     WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
       AND p.company_sid = pct.company_sid
       AND p.app_sid = pct.app_sid
       AND p.company_sid = c.company_sid
       AND p.app_sid = c.app_sid
       AND p.created_by_sid = cu.csr_user_sid
       AND p.app_sid = cu.app_sid
;

/***********************************************************************
	v$company_component - a simple view of all components with company and created by data
***********************************************************************/
PROMPT >> Creating v$company_component
CREATE OR REPLACE VIEW v$company_component AS
SELECT component_id, cmp.app_sid, c.company_sid, c.name company_name, cmp.created_by_sid, cu.full_name created_by, cmp.created_dtm, cmp.description, cmp.component_code,
	   component_type_id, cmp.deleted
      FROM component cmp, v$company c, csr.csr_user cu
     WHERE cmp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
       AND cmp.company_sid = c.company_sid
       AND cmp.app_sid = c.app_sid
       AND cmp.created_by_sid = cu.csr_user_sid
       AND cmp.app_sid = cu.app_sid
;

/***********************************************************************
	v$product - a simple view of active products
***********************************************************************/
PROMPT >> Creating v$product
CREATE OR REPLACE VIEW v$product AS
	SELECT product_id, app_sid, company_sid, company_name, created_by_sid, created_by, created_dtm, description, active, 
        code_label1, code1, code_label2, code2, code_label3, code3, need_review, root_component_id, product_builder_component_id
	  FROM v$company_product
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND deleted = 0
;

/***********************************************************************
	v$component - a simple view of active components 
***********************************************************************/
PROMPT >> Creating v$component
CREATE OR REPLACE VIEW v$component AS
	SELECT app_sid, component_id, company_sid, created_by_sid, created_dtm, description, component_type_id, component_code
	  FROM component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND deleted = 0
;

/***********************************************************************
	v$product_relationship - a simple view of product_relationships with company and users - shows deleted prods too
***********************************************************************/
PROMPT >> Creating v$product_relationship
CREATE OR REPLACE VIEW v$product_relationship AS
SELECT 
    -- purchaser 
        pr.purchaser_component_id p_component_id, 
        cp.company_sid p_company_sid, 
        cp.company_name p_company_name, 
        cp.created_by_sid p_component_created_by_sid, 
        cp.created_by p_component_created_by, 
        cp.created_dtm p_component_created_dtm, 
        cp.description p_component_description, 
    -- supplier 
        pr.supplier_product_id s_product_id, 
        sp.company_sid s_company_sid, 
        sp.company_name s_company_name, 
        sp.created_by_sid s_product_created_by_sid, 
        sp.created_by s_product_created_by, 
        sp.created_dtm s_product_created_dtm, 
        sp.description s_product_description, 
        sp.active s_product_active, 
        sp.code_label1 s_code_label1, sp.code1 s_product_code1, 
        sp.code_label2 s_code_label2, sp.code2 s_product_code2, 
        sp.code_label3 s_code_label3, sp.code3 s_product_code3, 
        sp.need_review  s_product_need_review, 
        sp.deleted s_product_deleted, sp.root_component_id s_root_component_id      
  FROM cmpnt_prod_relationship pr, v$company_component cp, v$company_product sp
 WHERE pr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
   AND pr.purchaser_component_id = cp.component_id 
   AND pr.app_sid = cp.app_sid 
   AND pr.supplier_product_id = sp.product_id 
   AND pr.app_sid = sp.app_sid 
;

/***********************************************************************
	v$product_rel_pending - a simple view of product_rel_pending with company and users - shows deleted prods too
***********************************************************************/
PROMPT >> Creating v$product_rel_pending
CREATE OR REPLACE VIEW v$product_rel_pending AS
SELECT 
    -- purchaser 
        pr.purchaser_component_id p_component_id, 
		NVL2(cp.company_sid, cp.company_sid, pc.company_sid) p_company_sid,
        --NVL2(cp.company_sid, cp.company_name, pc.name||'*') p_company_name, 
        NVL2(cp.company_sid, cp.company_name, pc.name) p_company_name, 
        cp.created_by_sid p_component_created_by_sid, 
        cp.created_by p_component_created_by, 
        cp.created_dtm p_component_created_dtm, 
        cp.description p_component_description, 
    -- supplier 
        pr.supplier_product_id s_product_id, 
        NVL2(sp.company_sid, sp.company_sid, sc.company_sid) s_company_sid, 
        --NVL2(sp.company_sid, sp.company_name, sc.name||'*') s_company_name, 
        NVL2(sp.company_sid, sp.company_name, sc.name) s_company_name, 
        sp.created_by_sid s_product_created_by_sid, 
        sp.created_by s_product_created_by, 
        sp.created_dtm s_product_created_dtm, 
        sp.description s_product_description, 
        sp.active s_product_active, 
        sp.code_label1 s_code_label1, sp.code1 s_product_code1, 
        sp.code_label2 s_code_label2, sp.code2 s_product_code2, 
        sp.code_label3 s_code_label3, sp.code3 s_product_code3, 
        sp.need_review  s_product_need_review, 
        sp.deleted s_product_deleted, sp.root_component_id s_root_component_id      
  FROM cmpnt_prod_rel_pending pr, v$company_component cp, v$company_product sp, company sc, company pc
 WHERE pr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
   AND pr.purchaser_component_id = cp.component_id(+) 
   AND pr.app_sid = cp.app_sid (+)
   AND pr.supplier_product_id = sp.product_id(+)
   AND pr.app_sid = sp.app_sid (+)
   AND pr.supplier_company_sid = sc.company_sid
   AND pr.purchaser_company_sid = pc.company_sid
;

/***********************************************************************
	v$company_product_extended - a view of all products with extended "search" details - shows deleted prods too
***********************************************************************/
PROMPT >> Creating v$company_product_extended
CREATE OR REPLACE VIEW v$company_product_extended AS
/*SELECT p.product_id, app_sid, company_sid, company_name, created_by_sid, created_by, created_dtm, description, active, 
        code_label1, code1, code_label2, code2, code_label3, code3, need_review, deleted,
        NVL(supplier_count, 0) supplier_count, DECODE(NVL(supplier_count, 0), 1, s_company_sid, -1) supplier_company_sid, DECODE(NVL(supplier_count, 0), 1, s_company_name, 0, 'None', 'Multiple') supplier_company_name,
        NVL(purchaser_count, 0) purchaser_count, DECODE(NVL(purchaser_count, 0), 1, p_company_sid, -1) purchaser_company_sid, DECODE(NVL(purchaser_count, 0), 1, p_company_name, 0, 'None', 'Multiple') purchaser_company_name
  FROM v$company_product p, 
   (
       -- who buys this from company 
       SELECT s_product_id product_id, COUNT(*) purchaser_count, MIN(p_company_sid) p_company_sid, MIN(p_company_name) p_company_name -- company details only used when count = 1 so MIN makes sense 
         FROM v$product_relationship pr
        GROUP BY s_product_id 
		UNION
       SELECT s_product_id product_id, COUNT(*) purchaser_count, MIN(p_company_sid) p_company_sid, MIN(p_company_name) p_company_name -- company details only used when count = 1 so MIN makes sense 
         FROM v$product_rel_pending pr
        GROUP BY s_product_id 
   ) pr, (
       -- who sells this to company 
       SELECT p_component_id component_id, COUNT(*) supplier_count, MIN(s_company_sid) s_company_sid, MIN(s_company_name) s_company_name -- company details only used when count = 1 so MIN makes sense 
         FROM v$product_relationship pr
        GROUP BY p_component_id  
		UNION
       SELECT p_component_id component_id, COUNT(*) supplier_count, MIN(s_company_sid) s_company_sid, MIN(s_company_name) s_company_name -- company details only used when count = 1 so MIN makes sense 
         FROM v$product_rel_pending pr
        GROUP BY p_component_id 
   ) sp
   WHERE p.product_id = pr.product_id(+)
     AND p.product_id = sp.component_id(+)
; IN CASE NEED TO FLIP BACK FOR DEMO*/
SELECT p.product_id, app_sid, company_sid, company_name, created_by_sid, created_by, created_dtm, description, active, 
        code_label1, code1, code_label2, code2, code_label3, code3, need_review, deleted,
        NVL(supplier_count, 0) supplier_count, DECODE(NVL(supplier_count, 0), 1, s_company_sid, -1) supplier_company_sid, DECODE(NVL(supplier_count, 0), 1, s_company_name, 0, 'None', 'Multiple') supplier_company_name,
        NVL(purchaser_count, 0) purchaser_count, DECODE(NVL(purchaser_count, 0), 1, p_company_sid, -1) purchaser_company_sid, DECODE(NVL(purchaser_count, 0), 1, p_company_name, 0, 'None', 'Multiple') purchaser_company_name
  FROM v$company_product p, 
   (
       -- who buys this from company 
       SELECT s_product_id product_id, COUNT(*) purchaser_count, MIN(p_company_sid) p_company_sid, MIN(p_company_name) p_company_name -- company details only used when count = 1 so MIN makes sense 
         FROM v$product_relationship pr
        GROUP BY s_product_id 
		UNION
       SELECT s_product_id product_id, COUNT(*) purchaser_count, MIN(p_company_sid) p_company_sid, MIN(p_company_name) p_company_name -- company details only used when count = 1 so MIN makes sense 
         FROM v$product_rel_pending pr
        GROUP BY s_product_id 
   ) pr, (
       -- who sells this to company 
        SELECT product_id, COUNT(DISTINCT s_company_sid) supplier_count, MIN(s_company_name) s_company_name, MIN(s_company_sid) s_company_sid -- company details only used when count = 1 so MIN makes sense 
          FROM 
        (        
            SELECT p.product_id, s_company_name, s_company_sid 
              FROM (
                    SELECT component_id, CONNECT_BY_ROOT parent_component_id root 
                      FROM cmpnt_cmpnt_relationship 
                   CONNECT BY PRIOR component_id = parent_component_id
                    ) c, 
             product p, component cmp, v$product_rel_pending pr
            WHERE p.root_component_id = c.root
              and cmp.component_id = c.component_id
              AND component_type_id = 3 --TO DO flip in constants
              AND c.component_id = pr.p_component_id
          UNION
            SELECT p.product_id, s_company_name, s_company_sid 
              FROM (
                    SELECT component_id, CONNECT_BY_ROOT parent_component_id root FROM cmpnt_cmpnt_relationship 
                   CONNECT BY PRIOR component_id = parent_component_id
                   ) c, 
              product p, component cmp, v$product_relationship pr
            WHERE p.root_component_id = c.root
              and cmp.component_id = c.component_id
              AND component_type_id = 3 --TO DO flip in constants
              AND c.component_id = pr.p_component_id
        )
       GROUP BY product_id
   ) sp
   WHERE p.product_id = pr.product_id(+)
     AND p.product_id = sp.product_id(+)
;		  
-- TO DO - but of a quick change - look over and flip in constants

/***********************************************************************
	v$questionnaire_status_log - a view of all questionnaire status log entries in an app
***********************************************************************/
PROMPT >> Creating v$questionnaire_status_log

CREATE OR REPLACE VIEW v$questionnaire_status_log AS
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

CREATE OR REPLACE VIEW v$questionnaire_share_log AS
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

CREATE OR REPLACE VIEW v$questionnaire AS
	SELECT q.app_sid, q.questionnaire_id, q.company_sid, q.questionnaire_type_id, q.created_dtm, 
		   qt.view_url, qt.edit_url, qt.owner_can_review, qt.class, qt.name, qt.db_class, qt.group_name, qt.position, 
		   qsle.status_log_entry_index, qsle.questionnaire_status_id, qs.description questionnaire_status_name, qsle.entry_dtm status_update_dtm
	  FROM questionnaire q, questionnaire_type qt, qnr_status_log_entry qsle, questionnaire_status qs
	 WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND q.app_sid = qt.app_sid
	   AND q.app_sid = qsle.app_sid
       AND q.questionnaire_type_id = qt.questionnaire_type_id
       AND qsle.questionnaire_status_id = qs.questionnaire_status_id
       AND q.questionnaire_id = qsle.questionnaire_id
       AND (qsle.questionnaire_id, qsle.status_log_entry_index) IN (   
			SELECT questionnaire_id, MAX(status_log_entry_index)
			  FROM qnr_status_log_entry
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 GROUP BY questionnaire_id
			)
;

/***********************************************************************
	v$questionnaire_share - a view of all supplier questionnaires by current status
***********************************************************************/
PROMPT >> Creating v$questionnaire_share

CREATE OR REPLACE VIEW v$questionnaire_share AS
	SELECT q.app_sid, q.questionnaire_id, q.questionnaire_type_id, q.created_dtm, qs.due_by_dtm, qs.overdue_events_sent,
		   qs.qnr_owner_company_sid, qs.share_with_company_sid, qsle.share_log_entry_index, qsle.entry_dtm, 
		   qs.questionnaire_share_id, qsle.share_status_id, ss.description share_status_name,
           qsle.company_sid entry_by_company_sid, qsle.user_sid entry_by_user_sid, qsle.user_notes
	  FROM questionnaire q, questionnaire_share qs, qnr_share_log_entry qsle, share_status ss
	 WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND q.app_sid = qs.app_sid
	   AND q.app_sid = qsle.app_sid
	   AND q.company_sid = qs.qnr_owner_company_sid
	   AND (								-- allows builtin admin to see relationships as well for debugging purposes
	   			qs.share_with_company_sid = NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), qs.share_with_company_sid)
	   		 OR qs.qnr_owner_company_sid = NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), qs.qnr_owner_company_sid)
	   	   )
	   AND q.questionnaire_id = qs.questionnaire_id
	   AND qs.questionnaire_share_id = qsle.questionnaire_share_id
	   AND qsle.share_status_id = ss.share_status_id
	   AND (qsle.questionnaire_share_id, qsle.share_log_entry_index) IN (   
	   			SELECT questionnaire_share_id, MAX(share_log_entry_index)
	   			  FROM qnr_share_log_entry
	   			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   			 GROUP BY questionnaire_share_id
			)
;


/***********************************************************************
	v$chain_host - gives the app_sid, host and chain implmentation
***********************************************************************/
PROMPT >> Creating v$chain_host
CREATE OR REPLACE VIEW v$chain_host AS
	SELECT c.app_sid, c.host, co.chain_implementation
	  FROM csr.customer c, customer_options co
	 WHERE c.app_sid = co.app_sid
;

















	  