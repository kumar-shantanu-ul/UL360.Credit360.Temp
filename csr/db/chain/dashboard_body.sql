CREATE OR REPLACE PACKAGE BODY chain.dashboard_pkg
IS

PROCEDURE GetInvitationSummary (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid				security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID');
	v_my_companies			security.T_SID_TABLE;
	v_available_companies	security.T_SID_TABLE;
	v_score_perm_sids		security.T_SID_TABLE DEFAULT type_capability_pkg.GetPermissibleCompanySids(chain_pkg.COMPANY_SCORES, security_pkg.PERMISSION_READ);
BEGIN
	
	company_pkg.GetFollowingSupplierSids(v_user_sid, FALSE, v_my_companies);
	
	SELECT supplier_company_sid
	   BULK COLLECT INTO v_available_companies
	  FROM v$supplier_relationship
	 WHERE purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	
	OPEN out_cur FOR
		SELECT 'REGISTERED' as Total_Type,
			    'Registered' as Total_Description,
			    COUNT(*) "All",
			    COUNT(CASE WHEN T1.column_value IS NOT NULL THEN 1 ELSE NULL END) My,
			    NULL as score_threshold_id, NULL bar_colour, NULL score_type_id
		  FROM v$company c
		  JOIN TABLE(v_available_companies) sr ON c.company_sid = sr.column_value
		  LEFT JOIN TABLE(v_my_companies) T1 ON c.company_sid = T1.column_value
		 WHERE c.active=1
		
		UNION ALL
		
		SELECT * FROM (
			SELECT 'CUSTOM_'||st.score_threshold_id, MIN(st.description) description,
					COUNT(DISTINCT sr.column_value) "All",
					COUNT(DISTINCT T1.column_value) My,
					MIN(CASE WHEN dashboard_image IS NOT NULL THEN st.score_threshold_id ELSE NULL END),
					MIN(st.bar_colour) bar_colour, t.score_type_id
			  FROM csr.score_threshold st
			  JOIN csr.score_type t ON st.score_type_id = t.score_type_id
			  LEFT JOIN csr.v$supplier_score s ON s.score_threshold_id = st.score_threshold_id
			  LEFT JOIN (SELECT column_value FROM TABLE(v_score_perm_sids) order by column_value) cts ON s.company_sid = cts.column_value
			  LEFT JOIN company c ON s.company_sid = c.company_sid AND c.deleted = 0 AND c.pending = 0
			  LEFT JOIN (SELECT column_value FROM TABLE(v_available_companies) order by column_value) sr ON c.company_sid = sr.column_value
			  LEFT JOIN (SELECT column_value FROM TABLE(v_my_companies) order by column_value) T1 ON sr.column_value = T1.column_value
			 WHERE (st.dashboard_image IS NOT NULL OR st.bar_colour IS NOT NULL)
			   AND t.applies_to_supplier = 1
			 GROUP BY st.score_threshold_id, st.max_value, t.pos, t.score_type_id
			 ORDER BY t.pos, st.max_value DESC
		)
		
		UNION ALL
		
		SELECT DECODE(s.invitation_status_id, chain_pkg.ACTIVE, 'CURRENT_INVITATIONS', chain_pkg.EXPIRED, 'OVERDUE_INVITATIONS'),
			    DECODE(s.invitation_status_id, chain_pkg.ACTIVE, 'Current Invitations', chain_pkg.EXPIRED, 'Expired Invitations'),
			    COUNT(i.to_company_sid) "All",
			    COUNT(T1.column_value) My,
			    NULL as score_threshold_id, NULL bar_colour, NULL score_type_id
		  FROM invitation_status s
		  LEFT JOIN (
				SELECT MIN(i.invitation_status_id) invitation_status_id, i.to_company_sid
				  FROM invitation i 
				  JOIN v$company c ON i.to_company_sid = c.company_sid AND i.app_sid = c.app_sid AND c.active = chain_pkg.INACTIVE
				  JOIN csr.csr_user u ON i.from_user_sid = u.csr_user_sid AND i.app_sid = u.app_sid AND u.email NOT LIKE '%@credit360.com'
				 WHERE i.invitation_status_id IN (chain_pkg.ACTIVE, chain_pkg.EXPIRED)
				   AND i.from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
				   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				 GROUP BY to_company_sid
				) i ON s.invitation_status_id = i.invitation_status_id
		  LEFT JOIN TABLE(v_my_companies) T1 ON i.to_company_sid = T1.column_value
		  LEFT JOIN supplier_relationship sr ON i.to_company_sid = sr.supplier_company_sid AND sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') AND sr.active=chain_pkg.ACTIVE AND sr.deleted = chain_pkg.NOT_DELETED
		 WHERE s.invitation_status_id IN (chain_pkg.ACTIVE, chain_pkg.EXPIRED)
		   AND sr.supplier_company_sid IS NULL
		 GROUP BY s.invitation_status_id
		
		UNION ALL
		
		SELECT 'OVERDUE_REGISTRATIONS', 'Overdue Questionnaires',
			    COUNT(DISTINCT sr.column_value) "All",
			    COUNT(DISTINCT T1.column_value) My,
			    NULL as score_threshold_id, NULL bar_colour, NULL score_type_id
		  FROM v$questionnaire_share q
		  LEFT JOIN v$company c ON q.qnr_owner_company_sid = c.company_sid AND q.app_sid = c.app_sid
		  LEFT JOIN TABLE(v_available_companies) sr ON c.company_sid = sr.column_value
		  LEFT JOIN TABLE(v_my_companies) T1 ON sr.column_value = T1.column_value
		 WHERE share_status_id IN (chain_pkg.NOT_SHARED, chain_pkg.SHARED_DATA_RETURNED)
		   AND share_with_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND due_by_dtm < SYSDATE
		;

END;

PROCEDURE GetProductWorkSummary (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_total				NUMBER :=100;
	v_mapped			NUMBER :=20;
	v_published			NUMBER :=2;
	v_total_desc		VARCHAR2(50);
	v_mapped_desc		VARCHAR2(50);
	v_published_desc	VARCHAR2(50);
BEGIN
	
	IF helper_pkg.IsTopCompany = 1 THEN 
	
		SELECT COUNT(*), NVL(SUM(mapped-NVL(published,0)),0), NVL(SUM(published),0) 
		  INTO v_total, v_mapped, v_published
		  FROM v$purchased_component pc, (SELECT * FROM v$product p WHERE deleted = 0) p
		 WHERE pc.app_sid = p.app_sid(+)
		   AND pc.supplier_product_id = p.product_id(+)
		   AND pc.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') 
		   AND pc.deleted = chain_pkg.NOT_DELETED
		   AND pc.app_sid = SYS_CONTEXT('SECURITY', 'APP');	
		   
		v_total_desc		:= 'Products you purchase';
		v_mapped_desc		:= 'Direct supplier entering data';
		v_published_desc	:= 'Data completed by direct supplier';
		   
	ELSE

		SELECT COUNT(*), NVL(SUM(mapped-NVL(published,0)),0), NVL(SUM(published),0) 
		  INTO v_total, v_mapped, v_published
		  FROM v$purchased_component pc, (SELECT * FROM v$product p WHERE deleted = 0) p
		 WHERE pc.app_sid = p.app_sid(+)
		   AND pc.supplier_product_id = p.product_id(+)
		   AND pc.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') 
		   AND pc.deleted = chain_pkg.NOT_DELETED
		   AND pc.app_sid = SYS_CONTEXT('SECURITY', 'APP');				
	
		v_total_desc		:= 'Products you have been asked about';
		v_mapped_desc		:= 'Data entry in progress';
		v_published_desc	:= 'Data entry finished';
	
	END IF;
	
	OPEN out_cur FOR
		SELECT colour_key, description, amount, total FROM
		(
			SELECT 'BLUE' colour_key, v_total_desc description, v_total amount, v_total total, 1 pos FROM dual
				UNION
			SELECT 'PURPLE' colour_key, v_mapped_desc description, v_mapped amount, v_total total, 2 pos FROM dual
				UNION
			SELECT 'GREEN' colour_key, v_published_desc description, v_published amount, v_total total, 3 pos FROM dual
		) 
		ORDER BY pos ASC;

END;

PROCEDURE GetQuestionnaireSummary (
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- security handled by view
	OPEN out_cur FOR
		SELECT questionnaire_type_id, questionnaire_name, status_id,
			CASE 
				WHEN status_id = chain_pkg.SHARED_DATA_EXPIRED THEN 'Questionnaire expired'
				WHEN status_id = chain_pkg.SHARED_DATA_ACCEPTED THEN 'Questionnaire accepted'
				WHEN status_id = chain_pkg.SHARING_DATA THEN 'Questionnaire submitted'
				WHEN status_id = chain_pkg.NOT_SHARED_PENDING THEN 'Pending questionnaire submission'
				WHEN status_id = chain_pkg.NOT_SHARED_OVERDUE THEN 'Questionnaire overdue'
				WHEN status_id = chain_pkg.SHARED_DATA_RETURNED THEN 'Questionnaire returned'
				WHEN status_id = chain_pkg.QNR_INVITATION_NOT_ACCEPTED THEN 'Invitation not yet accepted'
				WHEN status_id = chain_pkg.QNR_INVITATION_DECLINED THEN 'Invitation actively declined'
				WHEN status_id = chain_pkg.QNR_INVITATION_EXPIRED THEN 'Invitation expired'
				ELSE NULL
			END status,
			CASE 
				WHEN status_id = chain_pkg.SHARED_DATA_EXPIRED THEN 8000363
				WHEN status_id = chain_pkg.SHARED_DATA_ACCEPTED THEN 1276462
				WHEN status_id = chain_pkg.SHARING_DATA THEN 2790878
				WHEN status_id = chain_pkg.NOT_SHARED_PENDING THEN 14605098
				WHEN status_id = chain_pkg.NOT_SHARED_OVERDUE THEN 14574378
				WHEN status_id = chain_pkg.SHARED_DATA_RETURNED THEN 1265786
				WHEN status_id = chain_pkg.QNR_INVITATION_NOT_ACCEPTED THEN 14593066
				WHEN status_id = chain_pkg.QNR_INVITATION_DECLINED THEN 8005651
				WHEN status_id = chain_pkg.QNR_INVITATION_EXPIRED THEN 14563114
				ELSE NULL
			END colour, 
			CASE 
				WHEN status_id = chain_pkg.SHARED_DATA_EXPIRED THEN 1
				WHEN status_id = chain_pkg.SHARED_DATA_ACCEPTED THEN 2
				WHEN status_id = chain_pkg.SHARED_DATA_RETURNED THEN 3
				WHEN status_id = chain_pkg.SHARING_DATA THEN 4
				WHEN status_id = chain_pkg.NOT_SHARED_PENDING THEN  5
				WHEN status_id = chain_pkg.NOT_SHARED_OVERDUE THEN 6
				WHEN status_id = chain_pkg.QNR_INVITATION_NOT_ACCEPTED THEN 7
				WHEN status_id = chain_pkg.QNR_INVITATION_EXPIRED THEN 8
				WHEN status_id = chain_pkg.QNR_INVITATION_DECLINED THEN 9
				ELSE NULL
			END pos, COUNT(*) count
		  FROM v$questionnaire_type_status
		 GROUP BY questionnaire_type_id, questionnaire_name, status_id
		 ORDER BY LOWER(questionnaire_name), pos;
END;

END dashboard_pkg;
/
