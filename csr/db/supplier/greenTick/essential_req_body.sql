create or replace package body supplier.essential_req_pkg
IS

PROCEDURE GetProductEssentialReq (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id		IN 	product_revision.revision_id%TYPE,
	out_prod_data		OUT	security_pkg.T_OUTPUT_CUR,
	out_pack_details	OUT	security_pkg.T_OUTPUT_CUR,
	out_assessment		OUT	security_pkg.T_OUTPUT_CUR
) 
AS			
BEGIN
	GetProductData(in_act_id, in_product_id, in_revision_id, out_prod_data);
	GetPackDetails(in_act_id, in_product_id, in_revision_id, out_pack_details);
	
	-- Get the assessment data
	OPEN out_assessment FOR
		SELECT pr.product_id, pr.revision_id,
			   single_in_pack, 
			   settle_in_transit, 
			   gt_gift_cont_type_id, 
			   gt_pack_layers_type_id, 
			   prod_pack_occupation,
			   pack_style_type,
			   NVL(pst.description, 'No data') pack_style_desc,
			   dbl_walled_jar_just, 
			   contain_tablets_just, 
			   tablets_in_blister_tray, 
			   carton_gift_box_clear_win,
			   carton_gift_box_just,
			   carton_gift_box_sleeve,
			   carton_gift_box_vacuum_form,
			   just_report_explanation,
			   other_consumer_accept_just,
			   other_issues_just, 
			   other_logistics_just, 
			   other_pack_fill_proc_just, 
			   other_pack_manu_proc_just, 
			   other_prod_info_just,
			   other_prod_legislation_just, 
			   other_prod_present_market_just, 
			   other_prod_protection_just, 
			   other_prod_safety_just,
			   pack_risk
		 FROM gt_packaging_answers gpa, product p, product_revision pr, gt_pack_style_type pst
		WHERE p.product_id = pr.product_id
		  AND gpa.product_id (+) = pr.product_id
          AND gpa.revision_id (+) = pr.revision_id
          AND gpa.pack_style_type = pst.gt_pack_style_type_id(+)
          AND pr.product_id = in_product_id
	      AND pr.revision_id = in_revision_id;
END;


PROCEDURE GetProductData (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id		IN 	product_revision.revision_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
) 
AS
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT 
			p.product_id,
			gtpr.revision_id, 
			p.description  	product_name,
			p.product_code  product_code,
			t.tag 			merchant_type,
			r.description	gt_product_range,
			c.name 			company_name,
			prov.providers,
			gtpr.prod_weight_desc,
			gtpr.gt_product_type
		  FROM product p, tag t, tag_group tg, tag_group_member tgm, product_tag pt, company c, gt_profile_report gtpr,
			   (SELECT gpa.product_id, gpa.revision_id, gpr.description 
				  FROM gt_product_answers gpa, gt_product_range gpr
				 WHERE gpa.gt_product_range_id = gpr.gt_product_range_id
				   AND gpa.revision_id = in_revision_id) r,
			   (SELECT pqp.product_id, csr.STRAGG(cu.full_name) providers
				  FROM product_questionnaire_provider pqp, csr.csr_user cu 
				 WHERE questionnaire_id = questionnaire_pkg.getquestionnaireidbyclass('gtPackaging')
				   AND cu.csr_user_sid = pqp.provider_sid
				 GROUP BY pqp.product_id) prov 
		 WHERE t.tag_id = tgm.tag_id 
		   AND tgm.tag_group_sid = tg.tag_group_sid
		   AND pt.tag_id = t.tag_id
		   AND p.product_id = pt.product_id (+)
		   AND p.product_id = r.product_id (+)
		   AND p.product_id = prov.product_id (+)
		   AND p.product_id  = gtpr.product_id (+)
		   AND gtpr.revision_id = in_revision_id
		   AND tg.name = 'merchant_type'
		   AND p.supplier_company_sid = c.company_sid
		   AND p.product_id = in_product_id;
END;

PROCEDURE GetPackDetails (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id		IN  product_revision.revision_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT p.product_id, pr.revision_id, pack_info.description
		  FROM product p, 
			   product_revision pr,
			   (SELECT pki.product_id, pki.revision_id, 
						(pkst.description || ', ' || pkmt.description || ' (' || pkmt.recycled_pct_theshold || '% recycled)') description
				  FROM gt_pack_item pki, gt_pack_shape_type pkst, gt_pack_material_type pkmt
				 WHERE pkst.gt_pack_shape_type_id = pki.gt_pack_shape_type_id
				   AND pkmt.gt_pack_material_type_id = pki.gt_pack_material_type_id) pack_info
		 WHERE p.product_id = pr.product_id
		   AND pack_info.product_id(+) = pr.product_id
		   AND pack_info.revision_id(+) = pr.revision_id
		   AND p.product_id = in_product_id
		   AND pr.revision_id = in_revision_id;
END;

END essential_req_pkg;
/
