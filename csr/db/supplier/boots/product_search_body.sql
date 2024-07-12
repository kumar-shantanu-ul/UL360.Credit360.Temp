CREATE OR REPLACE PACKAGE BODY supplier.product_search_pkg
IS

PROCEDURE SearchProductCount(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_product_code			IN product.product_code%TYPE,
	in_description			IN product.description%TYPE,
	in_supplier_name		IN company.name%TYPE,
	in_product_type_tag_id	IN product_tag.tag_id%TYPE,
	in_sale_type_tag_id		IN product_tag.tag_id%TYPE,
	in_active				IN product.active%TYPE,
	in_end_user_name		IN VARCHAR2,
	in_cert_expiry_months	IN NUMBER,
	in_gt_product_type_id	IN gt_product_type.gt_product_type_id%TYPE,
	in_gt_product_range_id	IN gt_product_range.gt_product_range_id%TYPE,
	in_is_sub_product		IN NUMBER,	
	in_min_vol				IN NUMBER,
	in_max_vol				IN NUMBER,
	in_questionnaire_class	IN questionnaire.class_name%TYPE,
	out_count				OUT	NUMBER
)
IS
	v_product_code			VARCHAR2(1024) := utils_pkg.RegexpEscape(in_product_code);
	v_description			VARCHAR2(1024) := utils_pkg.RegexpEscape(in_description);
	v_supplier_name			VARCHAR2(1024) := utils_pkg.RegexpEscape(in_supplier_name);
	v_end_user_name			VARCHAR2(1024) := utils_pkg.RegexpEscape(in_end_user_name);
	v_companies_sid 		security_pkg.T_SID_ID;
BEGIN	
	-- Check read permission on companies folder in security
	-- Products are not secured objects so effectively we are saying if you're allowed to read  companies you're allowed to read their products
	v_companies_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Supplier/Companies');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_companies_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
    
 	SELECT COUNT(*) INTO out_count FROM (
   	SELECT DISTINCT p.app_sid, p.product_id FROM (
     	SELECT DISTINCT p.app_sid, p.product_id
     		FROM product p, company c, gt_product gtprd,
     		(
     			SELECT product_id, gt_product_range_id, product_volume FROM gt_product_answers gtp
					WHERE revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = gtp.product_id)
     		) gtp,
  			(
				SELECT product_id, MAX(questionnairegt) questionnairegt, MAX(questionnairewood) questionnairewood, MAX(questionnairenp) questionnairenp
				FROM 
				(
				    SELECT p.product_id,
				    DECODE(LOWER(class_name), 'gtproductinfo', 1, 'gtformulation', 1, 'gtpackaging', 1, 'gtsupplier', 1, 'gttransport', 1, 0) questionnairegt,
				    DECODE(LOWER(class_name), 'wood', 1, 0) questionnairewood,
				    DECODE(LOWER(class_name), 'naturalproduct', 1, 0) questionnairenp
				    from product p, product_questionnaire pq, questionnaire q
				    WHERE p.product_id = pq.product_id
				    AND pq.questionnaire_id = q.questionnaire_id
					 AND p.app_sid = in_app_sid 
				)
				GROUP BY product_id
  			) pqa,
			(
                SELECT product_id, NVL(MAX(q_group_status_gt),0) q_group_status_gt, NVL(MAX(q_group_status_ss),0) q_group_status_ss
                FROM 
                (
                    SELECT p.product_id,
                    DECODE(LOWER(name), 'green tick', pqg.group_status_id, NULL) q_group_status_gt,
                    DECODE(LOWER(name), 'sustainable sourcing', pqg.group_status_id, NULL) q_group_status_ss
                    FROM product p, product_questionnaire_group pqg, questionnaire_group qg
                    WHERE p.product_id = pqg.product_id
                      AND pqg.group_id = qg.group_id
					   AND p.app_sid = in_app_sid 
                )
                GROUP BY product_id
			) pqgs
	       WHERE p.product_id = gtprd.product_id(+) 
			 --AND p.product_id = pt.product_id(+) 
	         AND p.product_id = gtp.product_id(+)
	         AND p.product_id = pqa.product_id 
			 AND p.product_id = pqgs.product_id
	         AND p.supplier_company_sid = c.company_sid 
	         AND p.app_sid = in_app_sid 
			 AND (in_product_code IS NULL OR REGEXP_LIKE(p.product_code, v_product_code, 'i'))
			 AND (in_description IS NULL OR REGEXP_LIKE(p.description, v_description, 'i'))
			 AND (in_supplier_name IS NULL OR REGEXP_LIKE(c.name, v_supplier_name, 'i'))
	         AND (in_product_type_tag_id IS NULL OR p.product_id IN (SELECT product_id FROM product_tag WHERE tag_id = in_product_type_tag_id)) 
	         AND (in_sale_type_tag_id IS NULL OR p.product_id IN (SELECT product_id FROM product_tag WHERE tag_id = in_sale_type_tag_id)) 
	         AND ((in_min_vol IS NULL) OR (pqa.questionnairegt = 1 AND gtp.product_volume>=in_min_vol)) --all gt specific things require that the product be a gt product as they questinnaires are not destroyed if somone unassigns)
	    	 AND ((in_max_vol IS NULL) OR (pqa.questionnairegt = 1 AND gtp.product_volume<=in_max_vol))
	    	 AND ((in_questionnaire_class IS NULL) OR 
	    	 	((DECODE(LOWER(in_questionnaire_class), 'gtproductinfo', 1, -1) = pqa.questionnairegt) OR -- we pass in gtproductinfo if Green Tick - as all 5 questionnaires get assigned together
	    	 	(DECODE(LOWER(in_questionnaire_class), 'wood', 1, -1) = pqa.questionnairewood) OR
	    	 	(DECODE(LOWER(in_questionnaire_class), 'naturalproduct', 1, -1) = pqa.questionnairenp)))
	    	 AND ((in_gt_product_type_id IS NULL) OR (pqa.questionnairegt = 1 AND gtprd.gt_product_type_id = in_gt_product_type_id))
	    	 AND ((in_gt_product_range_id IS NULL) OR (pqa.questionnairegt = 1 AND gtp.gt_product_range_id = in_gt_product_range_id))
	         AND p.active = NVL(in_active, p.active) 
	) p, 
    (
              SELECT /*+ ALL_ROWS */ pq.product_id, u.csr_user_sid, u.user_name, u.friendly_name, u.full_name
              FROM product_questionnaire pq, product_questionnaire_provider pqp, csr.csr_user u
              WHERE pq.product_id = pqp.product_id
              AND pq.questionnaire_id = pqp.questionnaire_id
              AND pqp.provider_sid = u.csr_user_sid
			  AND u.APP_SID = in_app_sid
    ) prv,
	--subprod
    (
		  SELECT p.product_id, NVL(sub_prod.is_sub_product,0) is_sub_product 
			FROM product p, ( 
				SELECT DISTINCT pt.product_id, 1 is_sub_product  
				  FROM product_tag pt, tag t 
				 WHERE pt.tag_id = t.tag_id 
				   AND t.tag = 'Sub Product' 
				) sub_prod 
		   WHERE p.product_id = sub_prod.product_id (+)
			 AND p.app_sid = in_app_sid		   
    ) sub_prod, 	
    (
              SELECT /*+ ALL_ROWS */ pq.product_id, u.csr_user_sid, u.user_name, u.friendly_name, u.full_name
              FROM product_questionnaire pq, product_questionnaire_approver pqa, csr.csr_user u
              WHERE pq.product_id = pqa.product_id
              AND pq.questionnaire_id = pqa.questionnaire_id
              AND pqa.approver_sid = u.csr_user_sid
			  AND u.APP_SID = in_app_sid
    ) app
    WHERE p.product_id = prv.product_id(+)
    AND  p.product_id = app.product_id(+)
--subprod	
	AND  p.product_id = sub_prod.product_id
	AND p.APP_SID = in_app_sid
	AND (in_is_sub_product IS NULL OR sub_prod.is_sub_product = in_is_sub_product)
		AND ((in_end_user_name IS NULL) OR 
			(REGEXP_LIKE(prv.user_name, v_end_user_name, 'i')) OR
			(REGEXP_LIKE(prv.full_name, v_end_user_name, 'i')) OR
			(REGEXP_LIKE(prv.friendly_name, v_end_user_name, 'i')) OR
			(REGEXP_LIKE(app.user_name, v_end_user_name, 'i')) OR
			(REGEXP_LIKE(app.full_name, v_end_user_name, 'i')) OR
			(REGEXP_LIKE(app.friendly_name, v_end_user_name, 'i')))
		AND (in_cert_expiry_months IS NULL OR product_pkg.GetMinCertExpiryDate(p.product_id) < sysdate + (in_cert_expiry_months * 30))	
	);
	   
END;


PROCEDURE SearchProduct(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_product_code			IN product.product_code%TYPE,
	in_description			IN product.description%TYPE,
	in_supplier_name		IN company.name%TYPE,
	in_product_type_tag_id	IN product_tag.tag_id%TYPE,
	in_sale_type_tag_id		IN product_tag.tag_id%TYPE,
	in_active				IN product.active%TYPE,
	in_end_user_name		IN VARCHAR2,
	in_cert_expiry_months	IN NUMBER,	
	in_gt_product_type_id	IN gt_product_type.gt_product_type_id%TYPE,
	in_gt_product_range_id	IN gt_product_range.gt_product_range_id%TYPE,
	in_is_sub_product		IN NUMBER,	
	in_min_vol				IN NUMBER,
	in_max_vol				IN NUMBER,
	in_questionnaire_class	IN questionnaire.class_name%TYPE,
	in_order_by				IN VARCHAR2,
	in_order_direction		IN VARCHAR2,
	in_start				IN NUMBER,
	in_page_size			IN NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
IS
	v_product_code			VARCHAR2(1024) := utils_pkg.RegexpEscape(in_product_code);
	v_description			VARCHAR2(1024) := utils_pkg.RegexpEscape(in_description);
	v_supplier_name			VARCHAR2(1024) := utils_pkg.RegexpEscape(in_supplier_name);
	v_end_user_name			VARCHAR2(1024) := utils_pkg.RegexpEscape(in_end_user_name);
	v_companies_sid 		security_pkg.T_SID_ID;
	v_SQL					VARCHAR2(32000);
	v_order_by				VARCHAR2(100);
BEGIN

	-- Check read permission on companies folder in security
	-- Products are not secured objects so effectively we are saying if you're allowed to read  companies you're allowed to read their products
	v_companies_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Supplier/Companies');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_companies_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	

	IF LOWER(in_order_by) NOT IN ('product_id', 'description', 'productcode', 'active', 'companyname', 
		'sale_type_tag_id', 'merchant_type_tag_id', 'category', 
		'questionnairewood ' || LOWER(in_order_direction) ||  ', q_group_status_ss',  
		'questionnairenp ' || LOWER(in_order_direction) ||  ', q_group_status_ss', 
		'questionnairegt ' || LOWER(in_order_direction) ||  ', q_group_status_gt') THEN
		RAISE_APPLICATION_ERROR(-20001, 'in_order_by not in the allowed list');
	END IF;
	
	v_order_by := in_order_by;
	IF LOWER(in_order_by) IN ('description', 'productcode', 'companyname', 'category') THEN
		v_order_by := 'LOWER(' || in_order_by || ')';
	END IF;
	
	IF LOWER(in_order_direction) NOT IN ('asc', 'desc') THEN
		RAISE_APPLICATION_ERROR(-20001, 'in_order_direction not asc or desc');
	END IF;	

	v_SQL := '';

    v_SQL := v_SQL || 		'  (SELECT * FROM ';
    v_SQL := v_SQL || 		'  ( ';
    v_SQL := v_SQL || 		'     SELECT rownum rn, total_rows, product_id, description, productcode, active, companyname, category, ';
	v_SQL := v_SQL || 		'     		 questionnairegt, DECODE(questionnairegt, 1, ''Yes'', ''No'') questionnairegt_desc,  questionnairewood, DECODE(questionnairewood, 1, ''Yes'', ''No'') questionnairewood_desc, questionnairenp, DECODE(questionnairenp, 1, ''Yes'', ''No'') questionnairenp_desc, earliest_q_due_date, ';
	v_SQL := v_SQL || 		'  			 q_group_status_gt, q_group_status_gt_desc, q_group_status_ss, q_group_status_ss_desc FROM   ';
    v_SQL := v_SQL || 		'     (   ';
   v_SQL := v_SQL || 		'	     SELECT COUNT(*) OVER() total_rows, app_sid, product_id, description, productcode, active, companyname, sale_type_tag_id, merchant_type_tag_id, category, questionnairegt, questionnairewood, questionnairenp, q_group_status_gt, q_group_status_gt_desc, q_group_status_ss, q_group_status_ss_desc, earliest_q_due_date FROM ';	
    v_SQL := v_SQL || 		'		 ( ';
   v_SQL := v_SQL || 		'	        SELECT DISTINCT p.app_sid, p.product_id, description, productcode, active, companyname, sale_type_tag_id, merchant_type_tag_id, category, questionnairegt,  questionnairewood, questionnairenp, q_group_status_gt, q_group_status_gt_desc, q_group_status_ss, q_group_status_ss_desc, earliest_q_due_date FROM ';
    v_SQL := v_SQL || 		'			( ';
    v_SQL := v_SQL || 		'	            	SELECT DISTINCT p.app_sid, p.product_id, p.description, p.product_code productcode, p.active, c.name companyname, ';
    v_SQL := v_SQL || 		'	                st_tag.tag_id sale_type_tag_id, ';
    v_SQL := v_SQL || 		'	                m_tag.tag_id merchant_type_tag_id, '; 
    v_SQL := v_SQL || 		'	                m_tag.tag category, ';
	v_SQL := v_SQL || 		'	                questionnairegt,  questionnairewood, questionnairenp,  q_group_status_gt, q_group_status_ss, q_group_status_gt_desc, q_group_status_ss_desc, earliest_q_due_date ';    
    v_SQL := v_SQL || 		'	                FROM product p, company c, gt_product gtprd, ';
		
	-- sales type tag	
    v_SQL := v_SQL || 		'	                	(SELECT p.product_id, pt.tag_id FROM product_tag pt, tag_group tg, tag_group_member tm, product p ';
    v_SQL := v_SQL || 		'	                		WHERE pt.tag_id = tm.tag_id AND p.product_id = pt.product_id AND tm.tag_group_sid = tg.tag_group_sid AND tg.app_sid = p.app_sid AND tg.name = ''sale_type'' AND tg.app_sid = :in_app_sid) st_tag, ';
	
	-- mercchant type 	
    v_SQL := v_SQL || 		'	                	(SELECT p.product_id, pt.tag_id, t.tag FROM product_tag pt, tag t, tag_group tg, tag_group_member tm, product p ';
    v_SQL := v_SQL || 		'	                		WHERE pt.tag_id = tm.tag_id AND pt.tag_id = t.tag_id AND p.product_id = pt.product_id AND tm.tag_group_sid = tg.tag_group_sid AND tg.app_sid = p.app_sid AND tg.name = ''merchant_type'' AND tg.app_sid = :in_app_sid) m_tag, ';
	
		
    v_SQL := v_SQL || 		'	                	(SELECT product_id, gt_product_range_id, product_volume FROM gt_product_answers gtp ';
    v_SQL := v_SQL || 		'	                	WHERE revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = gtp.product_id)) gtp, ';
		
    v_SQL := v_SQL || 		'	                  (SELECT product_id, MAX(questionnairegt) questionnairegt, MAX(questionnairewood) questionnairewood, MAX(questionnairenp) questionnairenp, MIN(due_date) earliest_q_due_date ';
    v_SQL := v_SQL || 		'	                  FROM  ';
    v_SQL := v_SQL || 		'	                  ( ';
    v_SQL := v_SQL || 		'	                      SELECT p.product_id, due_date, ';
    v_SQL := v_SQL || 		'	                      DECODE(LOWER(class_name), ''gtproductinfo'', 1, ''gtformulation'', 1, ''gtpackaging'', 1, ''gtsupplier'', 1, ''gttransport'', 1, 0) questionnairegt, ';
    v_SQL := v_SQL || 		'	                      DECODE(LOWER(class_name), ''wood'', 1, 0) questionnairewood, ';
    v_SQL := v_SQL || 		'	                      DECODE(LOWER(class_name), ''naturalproduct'', 1, 0) questionnairenp ';
    v_SQL := v_SQL || 		'	                      FROM product p, product_questionnaire pq, questionnaire q ';
    v_SQL := v_SQL || 		'	                      WHERE p.product_id = pq.product_id ';
    v_SQL := v_SQL || 		'	                      AND pq.questionnaire_id = q.questionnaire_id  AND p.APP_SID = :in_app_sid ';
    v_SQL := v_SQL || 		'	                  ) ';
    v_SQL := v_SQL || 		'	                  GROUP BY product_id) pqa, ';
		
    v_SQL := v_SQL || 		'	                  ( ';
    v_SQL := v_SQL || 		'	                  		SELECT product_id, q_group_status_gt, g.description q_group_status_gt_desc, q_group_status_ss, g2.description q_group_status_ss_desc FROM ';
    v_SQL := v_SQL || 		'							( ';
    v_SQL := v_SQL || 		'	                  			SELECT product_id, NVL(MAX(q_group_status_gt),0) q_group_status_gt, NVL(MAX(q_group_status_ss),0) q_group_status_ss ';
    v_SQL := v_SQL || 		'	                  			FROM  ';
    v_SQL := v_SQL || 		'	                  			( ';
    v_SQL := v_SQL || 		'	                  				SELECT p.product_id, ';
    v_SQL := v_SQL || 		'	                  				DECODE(LOWER(name), ''green tick'', pqg.group_status_id, NULL) q_group_status_gt, ';
    v_SQL := v_SQL || 		'	                  				DECODE(LOWER(name), ''sustainable sourcing'', pqg.group_status_id, NULL) q_group_status_ss ';
    v_SQL := v_SQL || 		'	                  				FROM product p, product_questionnaire_group pqg, questionnaire_group qg ';
    v_SQL := v_SQL || 		'	                  				WHERE p.product_id = pqg.product_id ';
    v_SQL := v_SQL || 		'	                  				  AND pqg.group_id = qg.group_id AND p.APP_SID = :in_app_sid ';
    v_SQL := v_SQL || 		'	                  			) ';
    v_SQL := v_SQL || 		'	                  			GROUP BY product_id ';
    v_SQL := v_SQL || 		'							) x, group_status g, group_status g2 ';	
    v_SQL := v_SQL || 		'							WHERE x.q_group_status_gt = g.group_status_id AND x.q_group_status_ss = g2.group_status_id ';
    v_SQL := v_SQL || 		'	                  ) pqgs  ';
		
    v_SQL := v_SQL || 		'	                  WHERE p.product_id = gtprd.product_id(+) '; 
   -- v_SQL := v_SQL || 			'                     AND p.product_id = pt.product_id(+) '; 
    v_SQL := v_SQL || 		'	                     AND p.product_id = pqa.product_id ';
    v_SQL := v_SQL || 		'	                     AND p.product_id = pqgs.product_id ';
    v_SQL := v_SQL || 		'	                     AND p.supplier_company_sid = c.company_sid ';
		
    v_SQL := v_SQL || 		'	                     AND p.product_id = gtp.product_id(+) ';
    v_SQL := v_SQL || 		'	                     AND p.product_id = st_tag.product_id(+) ';
    v_SQL := v_SQL || 		'	                     AND p.product_id = m_tag.product_id(+) ';
		
    v_SQL := v_SQL || 		'	                     AND p.app_sid = :in_app_sid  ';
	v_SQL := v_SQL || 		'	                     AND (:in_product_code IS NULL OR REGEXP_LIKE(p.product_code, :v_product_code, ''i'')) ';
	v_SQL := v_SQL || 		'	                     AND (:in_description IS NULL OR REGEXP_LIKE(p.description, :v_description, ''i'')) ';
	v_SQL := v_SQL || 		'	                     AND (:in_supplier_name IS NULL OR REGEXP_LIKE(c.name, :v_supplier_name, ''i'')) ';
    v_SQL := v_SQL || 		'	                     AND (:in_product_type_tag_id IS NULL OR p.product_id IN (SELECT product_id FROM product_tag WHERE tag_id = :in_product_type_tag_id))  ';
    v_SQL := v_SQL || 		'	                     AND (:in_sale_type_tag_id IS NULL OR p.product_id IN (SELECT product_id FROM product_tag WHERE tag_id = :in_sale_type_tag_id))  ';
		
    v_SQL := v_SQL || 		'	                	  AND ((:in_min_vol IS NULL) OR (pqa.questionnairegt = 1 AND gtp.product_volume>=:in_min_vol)) ';
    v_SQL := v_SQL || 		'	                     AND ((:in_max_vol IS NULL) OR (pqa.questionnairegt = 1 AND gtp.product_volume<=:in_max_vol)) ';
    v_SQL := v_SQL || 		'	                     AND ((:in_questionnaire_class IS NULL) OR  ';
    v_SQL := v_SQL || 		'	                     ((DECODE(LOWER(:in_questionnaire_class), ''gtproductinfo'', 1, -1) = pqa.questionnairegt) OR  ';
    v_SQL := v_SQL || 		'	                     (DECODE(LOWER(:in_questionnaire_class), ''wood'', 1, -1) = pqa.questionnairewood) OR ';
    v_SQL := v_SQL || 		'	                     (DECODE(LOWER(:in_questionnaire_class), ''naturalproduct'', 1, -1) = pqa.questionnairenp))) ';
    v_SQL := v_SQL || 		'	                     AND ((:in_gt_product_type_id IS NULL) OR (pqa.questionnairegt = 1 AND gtprd.gt_product_type_id = :in_gt_product_type_id)) ';
    v_SQL := v_SQL || 		'	                     AND ((:in_gt_product_range_id IS NULL) OR (pqa.questionnairegt = 1 AND gtp.gt_product_range_id = :in_gt_product_range_id)) ';
		
    v_SQL := v_SQL || 		'	                     AND p.active = NVL(:in_active, p.active)  ';
	
    v_SQL := v_SQL || 		'	       ) p,  ';
    v_SQL := v_SQL || 		'			( ';
    v_SQL := v_SQL || 		'			          SELECT pq.product_id, u.csr_user_sid, u.user_name, u.friendly_name, u.full_name ';
    v_SQL := v_SQL || 		'			          FROM product_questionnaire pq, product_questionnaire_provider pqp, csr.csr_user u ';
    v_SQL := v_SQL || 		'			          WHERE pq.product_id = pqp.product_id  ';
    v_SQL := v_SQL || 		'			          AND pq.questionnaire_id = pqp.questionnaire_id ';
    v_SQL := v_SQL || 		'			          AND pqp.provider_sid = u.csr_user_sid ';
    v_SQL := v_SQL || 		'			          AND u.app_sid = :in_app_sid ';
    v_SQL := v_SQL || 		'			) prv, ';
	
--subprod	
    v_SQL := v_SQL || 		'			( ';
	v_SQL := v_SQL || 		'			          SELECT p.product_id, NVL(sub_prod.is_sub_product,0) is_sub_product ';
    v_SQL := v_SQL || 		'			          	FROM product p, ( ';
    v_SQL := v_SQL || 		'			          		SELECT pt.product_id, 1 is_sub_product  ';
    v_SQL := v_SQL || 		'			          		  FROM product_tag pt, tag t ';
    v_SQL := v_SQL || 		'			          		 WHERE pt.tag_id = t.tag_id ';
	v_SQL := v_SQL || 		'			          		   AND t.tag = ''Sub Product'' ';
	v_SQL := v_SQL || 		'			          		) sub_prod ';
	v_SQL := v_SQL || 		'			           WHERE p.product_id = sub_prod.product_id (+) AND p.app_sid = :in_app_sid ';
    v_SQL := v_SQL || 		'			) sub_prod, ';
	
	v_SQL := v_SQL || 		'			( ';
    v_SQL := v_SQL || 		'			          SELECT pq.product_id, u.csr_user_sid, u.user_name, u.friendly_name, u.full_name ';
    v_SQL := v_SQL || 		'			          FROM product_questionnaire pq, product_questionnaire_approver pqa, csr.csr_user u ';
    v_SQL := v_SQL || 		'			          WHERE pq.product_id = pqa.product_id  ';
    v_SQL := v_SQL || 		'			          AND pq.questionnaire_id = pqa.questionnaire_id ';
    v_SQL := v_SQL || 		'			          AND pqa.approver_sid = u.csr_user_sid ';
    v_SQL := v_SQL || 		'			          AND u.app_sid = :in_app_sid ';
    v_SQL := v_SQL || 		'			) app ';
    v_SQL := v_SQL || 		'					WHERE p.product_id = prv.product_id(+) ';
    v_SQL := v_SQL || 		'					AND  p.product_id = app.product_id(+) ';
	v_SQL := v_SQL || 		'					AND  p.product_id = sub_prod.product_id ';
	v_SQL := v_SQL || 		'					AND ((:in_end_user_name IS NULL) OR  ';
	v_SQL := v_SQL || 		'						(REGEXP_LIKE(prv.user_name, :v_end_user_name, ''i'')) OR ';
	v_SQL := v_SQL || 		'						(REGEXP_LIKE(prv.full_name, :v_end_user_name, ''i'')) OR ';
	v_SQL := v_SQL || 		'						(REGEXP_LIKE(prv.friendly_name, :v_end_user_name, ''i'')) OR ';
	v_SQL := v_SQL || 		'						(REGEXP_LIKE(app.user_name, :v_end_user_name, ''i'')) OR ';
	v_SQL := v_SQL || 		'						(REGEXP_LIKE(app.full_name, :v_end_user_name, ''i'')) OR ';
	v_SQL := v_SQL || 		'						(REGEXP_LIKE(app.friendly_name, :v_end_user_name, ''i''))) ';
    v_SQL := v_SQL || 		'	               AND (:in_cert_expiry_months IS NULL OR product_pkg.GetMinCertExpiryDate(p.product_id) < sysdate + (:in_cert_expiry_months * 30)) ';
	
--subprod   	
	v_SQL := v_SQL || 		'	               AND (:in_is_sub_product IS NULL OR sub_prod.is_sub_product = :in_is_sub_product) AND p.APP_SID = :in_app_sid ';
	
	
	v_SQL := v_SQL || 		'	     	ORDER BY ' || v_order_by || ' ' || in_order_direction ;
    v_SQL := v_SQL || 		'     	) ';
	v_SQL := v_SQL || 		'	     ORDER BY ' || v_order_by || ' ' || in_order_direction ;
    v_SQL := v_SQL || 		'     ) ';
    v_SQL := v_SQL || 		'     WHERE rownum <= NVL(:in_end, rownum) ';
	v_SQL := v_SQL || 		'	  ORDER BY ' || v_order_by || ' ' || in_order_direction ;
    v_SQL := v_SQL || 		'  ) WHERE rn > NVL(:in_start, 0) ) ';
	v_SQL := v_SQL || 		'  ORDER BY ' || v_order_by || ' ' || in_order_direction ;
    
	OPEN out_cur FOR v_SQL
		USING in_app_sid, in_app_sid, in_app_sid, in_app_sid, in_app_sid, in_product_code, v_product_code, in_description, v_description, in_supplier_name, v_supplier_name, in_product_type_tag_id, 
			in_product_type_tag_id, in_sale_type_tag_id, in_sale_type_tag_id, 
			in_min_vol, in_min_vol, in_max_vol, in_max_vol, in_questionnaire_class, in_questionnaire_class, in_questionnaire_class, in_questionnaire_class,
			in_gt_product_type_id, in_gt_product_type_id, in_gt_product_range_id, in_gt_product_range_id, 
			in_active, in_app_sid, in_app_sid, in_app_sid,
			in_end_user_name, v_end_user_name, v_end_user_name, v_end_user_name, v_end_user_name, v_end_user_name, v_end_user_name,
			in_cert_expiry_months, in_cert_expiry_months, 
			in_is_sub_product, in_is_sub_product, in_app_sid,
			(in_start + in_page_size), in_start; 
			
END;



END product_search_pkg;
/




