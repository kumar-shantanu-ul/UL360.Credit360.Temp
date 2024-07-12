create or replace package body supplier.gt_packaging_pkg
IS

PROCEDURE SetPackagingAnswers (
    in_act_id                       IN  security_pkg.T_ACT_ID,
    in_product_id                   IN  all_product.product_id%TYPE,
    in_gt_access_pack_type_id       IN  gt_packaging_answers.gt_access_pack_type_id%TYPE,
    in_prod_volume         			IN  gt_product_answers.product_volume%TYPE, -- can be set from eiher PI or Pk questionnaire
    in_prod_weight         			IN  gt_product_answers.prod_weight%TYPE,-- can be set from eiher PI or Pk questionnaire
	in_prod_volume_declared 		IN  gt_product_answers.product_volume_declared%TYPE, -- can be set from eiher PI or Pk questionnaire
    in_prod_weight_declared  		IN  gt_product_answers.prod_weight_declared%TYPE,-- can be set from eiher PI or Pk questionnaire
    in_weight_inc_pkg         		IN  gt_product_answers.weight_inc_pkg%TYPE, -- can be set from eiher PI or Pk questionnaire
    in_refill_pack                  IN  gt_packaging_answers.refill_pack%TYPE,
    in_sf_innovation                IN  gt_packaging_answers.sf_innovation%TYPE,
    in_sf_novel_refill              IN  gt_packaging_answers.sf_novel_refill%TYPE,
    in_single_in_pack               IN  gt_packaging_answers.single_in_pack%TYPE,
    in_settle_in_transit            IN  gt_packaging_answers.settle_in_transit%TYPE,
    in_gt_gift_cont_type_id         IN  gt_packaging_answers.gt_gift_cont_type_id%TYPE,
    in_gt_pack_layers_type_id       IN  gt_packaging_answers.gt_pack_layers_type_id%TYPE,
    in_vol_package                  IN  gt_packaging_answers.vol_package%TYPE,
    in_retail_packs_stackable       IN  gt_packaging_answers.retail_packs_stackable%TYPE,
    in_num_packs_per_outer       	IN  gt_packaging_answers.num_packs_per_outer%TYPE,
    in_vol_prod_tran_pack           IN  gt_packaging_answers.vol_prod_tran_pack%TYPE,
    in_vol_tran_pack                IN  gt_packaging_answers.vol_tran_pack%TYPE,
    in_correct_biopolymer_use       IN  gt_packaging_answers.correct_biopolymer_use%TYPE,
    in_sf_recycled_threshold        IN  gt_packaging_answers.sf_recycled_threshold%TYPE,
    in_sf_novel_material            IN  gt_packaging_answers.sf_novel_material%TYPE,
    in_pack_meet_req                IN  gt_packaging_answers.pack_meet_req%TYPE,
    in_pack_shelf_ready             IN  gt_packaging_answers.pack_shelf_ready%TYPE,
    in_gt_trans_pack_type_id        IN  gt_packaging_answers.gt_trans_pack_type_id%TYPE,
    in_sf_innovation_transit        IN  gt_packaging_answers.sf_innovation_transit%TYPE,
	in_prod_pack_occupation 		IN  gt_packaging_answers.prod_pack_occupation%TYPE,
	in_pack_style_type	 			IN  gt_packaging_answers.pack_style_type%TYPE, 
	in_dbl_walled_jar_just 			IN  gt_packaging_answers.dbl_walled_jar_just%TYPE,
    in_contain_tablets_just   		IN  gt_packaging_answers.contain_tablets_just%TYPE,
	in_tablets_in_blister_tray 		IN  gt_packaging_answers.tablets_in_blister_tray%TYPE,
	in_carton_gift_box_just			IN  gt_packaging_answers.carton_gift_box_just%TYPE,
	in_carton_gift_box_vacuum_form	IN  gt_packaging_answers.carton_gift_box_vacuum_form%TYPE,
	in_carton_gift_box_clear_win	IN  gt_packaging_answers.carton_gift_box_clear_win%TYPE,
	in_carton_gift_box_sleeve		IN  gt_packaging_answers.carton_gift_box_sleeve%TYPE,
	in_other_prod_protection_just	IN  gt_packaging_answers.other_prod_protection_just%TYPE, 
	in_other_pack_manu_proc_just	IN  gt_packaging_answers.other_pack_manu_proc_just%TYPE,  
	in_other_pack_fill_proc_just	IN  gt_packaging_answers.other_pack_fill_proc_just%TYPE,  
	in_other_logistics_just			IN  gt_packaging_answers.other_logistics_just%TYPE,
	in_other_prod_pres_market_just  IN  gt_packaging_answers.other_prod_present_market_just%TYPE,
	in_other_consumer_accept_just	IN  gt_packaging_answers.other_consumer_accept_just%TYPE,
	in_other_prod_info_just			IN  gt_packaging_answers.other_prod_info_just%TYPE,
	in_other_prod_safety_just		IN  gt_packaging_answers.other_prod_safety_just%TYPE,
	in_other_prod_legislation_just	IN  gt_packaging_answers.other_prod_legislation_just%TYPE,
	in_other_issues_just			IN  gt_packaging_answers.other_issues_just%TYPE,
	in_just_report_explanation		IN  gt_packaging_answers.just_report_explanation%TYPE,
	in_pack_risk					IN  gt_packaging_answers.pack_risk%TYPE,
	in_data_quality_type_id         IN  gt_product_answers.data_quality_type_id%TYPE
)
AS
	v_max_revision_id				product_revision.revision_id%TYPE;
BEGIN

	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	FOR r IN (
		SELECT 
                pr.product_id,
                pr.revision_id, 
                gt_access_pack_type_id,
                prod_weight,
				weight_inc_pkg,
                refill_pack,
                single_in_pack,
                settle_in_transit,
                gt_gift_cont_type_id,
                gt_pack_layers_type_id,
                vol_package,
                retail_packs_stackable,
				num_packs_per_outer,
                vol_prod_tran_pack,
                vol_tran_pack,
                correct_biopolymer_use,
                pack_meet_req,
                pack_shelf_ready,
                gt_trans_pack_type_id,
				in_prod_pack_occupation,
				in_pack_style_type
		FROM gt_packaging_answers pa, gt_product_answers prda, product_revision pr
            WHERE pr.product_id=pa.product_id (+)
            AND pr.revision_id = pa.revision_id(+)
			AND pr.product_id=prda.product_id (+)
            AND pr.revision_id = prda.revision_id(+)
			AND pr.product_id = in_product_id
			AND pr.revision_id = v_max_revision_id
	) 
	LOOP
		-- actually only ever going to be single row as product id and revision id are PK
		score_log_pkg.LogSimpleTypeValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_PROD_WASTE, null, 'Packaging type', r.gt_access_pack_type_id, in_gt_access_pack_type_id,
			'gt_access_pack_type', 'description', 'gt_access_pack_type_id');

		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_PACK_IMPACT, null, 'Actual Weight of product (g)', r.prod_weight, in_prod_weight);
		score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_PACK_IMPACT, null, 'Weight inc. or exc. packaging', r.weight_inc_pkg, in_weight_inc_pkg);
		
		score_log_pkg.LogYesNoValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_PACK_IMPACT, null, 'Packaging designed to be refilled', r.refill_pack, in_refill_pack);
		
		score_log_pkg.LogYesNoValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_PACK_OPT, null, 'Single item in pack', r.single_in_pack, in_single_in_pack);
		score_log_pkg.LogYesNoValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_PACK_OPT, null, 'Settle in transit', r.settle_in_transit, in_settle_in_transit);
		score_log_pkg.LogSimpleTypeValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_PACK_OPT, null, 'Gift container type', r.gt_gift_cont_type_id, in_gt_gift_cont_type_id,
			'gt_gift_cont_type', 'description', 'gt_gift_cont_type_id');
		score_log_pkg.LogSimpleTypeValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_PACK_OPT, null, 'Packaging layers', r.gt_pack_layers_type_id, in_gt_pack_layers_type_id,
			'gt_pack_layers_type', 'description', 'gt_pack_layers_type_id');
			
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_PACK_OPT, null, 'Packaging volume (cm3 / ml)', r.vol_package, in_vol_package);	
		
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_NON_SCORING, null, 'Number of packs per outer', r.num_packs_per_outer, in_num_packs_per_outer);
		
		score_log_pkg.LogYesNoValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_TRANS_OPT, null, 'Retail packs are stackable', r.retail_packs_stackable, in_retail_packs_stackable);	
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_TRANS_OPT, null, 'Volume of an individual retail pack x the number of products per case (cc)', r.vol_prod_tran_pack, in_vol_prod_tran_pack);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_TRANS_OPT, null, 'Volume of the transit outer (cc)', r.vol_tran_pack, in_vol_tran_pack);		

		score_log_pkg.LogYesNoValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_RECYCLABLE_PACK, null, 'Correct bioploymer use', r.correct_biopolymer_use, in_correct_biopolymer_use);
		
		score_log_pkg.LogYesNoValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_TRANS_PACKAGING, null, 'Transit packaging meets Boots requirements', r.pack_meet_req, in_pack_meet_req);
		score_log_pkg.LogYesNoValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_TRANS_PACKAGING, null, 'Shelf ready packaging used', r.pack_shelf_ready, in_pack_shelf_ready);

		score_log_pkg.LogSimpleTypeValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_TRANS_PACKAGING, null, 'Level of transit packaging is used', r.gt_trans_pack_type_id, in_gt_trans_pack_type_id,
			'gt_trans_pack_type', 'description', 'gt_trans_pack_type_id');
			
		-- TODO: add logs to hish risk justification report variables
		
		
	END LOOP;
	
	BEGIN
	   	INSERT INTO gt_packaging_answers (
                product_id,
                revision_id, 
                gt_access_pack_type_id,
                refill_pack,
                sf_innovation,
                sf_novel_refill,
                single_in_pack,
                settle_in_transit,
                gt_gift_cont_type_id,
                gt_pack_layers_type_id,
                vol_package,
                retail_packs_stackable,
				num_packs_per_outer,
                vol_prod_tran_pack,
                vol_tran_pack,
                correct_biopolymer_use,
                sf_recycled_threshold,
                sf_novel_material,
                pack_meet_req,
                pack_shelf_ready,
                gt_trans_pack_type_id,
                sf_innovation_transit,
				prod_pack_occupation, 		
				pack_style_type,	 			
				dbl_walled_jar_just, 			
				contain_tablets_just,   		
				tablets_in_blister_tray, 		
				carton_gift_box_just,			
				carton_gift_box_vacuum_form,	
				carton_gift_box_clear_win,	
				carton_gift_box_sleeve,		
				other_prod_protection_just,	
				other_pack_manu_proc_just,	
				other_pack_fill_proc_just,	
				other_logistics_just,			
				other_prod_present_market_just,
				other_consumer_accept_just,	
				other_prod_info_just,			
				other_prod_safety_just,		
				other_prod_legislation_just,	
				other_issues_just,			
				just_report_explanation,
				pack_risk,
				data_quality_type_id
            ) values (
                in_product_id,
                v_max_revision_id,
                in_gt_access_pack_type_id,
                in_refill_pack,
                in_sf_innovation,
                in_sf_novel_refill,
                in_single_in_pack,
                in_settle_in_transit,
                in_gt_gift_cont_type_id,
                in_gt_pack_layers_type_id,
                in_vol_package,
                in_retail_packs_stackable,
				in_num_packs_per_outer,
                in_vol_prod_tran_pack,
                in_vol_tran_pack,
                in_correct_biopolymer_use,
                in_sf_recycled_threshold,
                in_sf_novel_material,
                in_pack_meet_req,
                in_pack_shelf_ready,
                in_gt_trans_pack_type_id,
                in_sf_innovation_transit,
				in_prod_pack_occupation, 		
				in_pack_style_type,	 			
				in_dbl_walled_jar_just, 			
				in_contain_tablets_just,   		
				in_tablets_in_blister_tray, 		
				in_carton_gift_box_just,			
				in_carton_gift_box_vacuum_form,	
				in_carton_gift_box_clear_win,	
				in_carton_gift_box_sleeve,		
				in_other_prod_protection_just,	
				in_other_pack_manu_proc_just,	
				in_other_pack_fill_proc_just,	
				in_other_logistics_just,			
				in_other_prod_pres_market_just,
				in_other_consumer_accept_just,	
				in_other_prod_info_just,			
				in_other_prod_safety_just,		
				in_other_prod_legislation_just,	
				in_other_issues_just,			
				in_just_report_explanation,
				in_pack_risk,
				in_data_quality_type_id
            );
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE gt_packaging_answers SET
                gt_access_pack_type_id			= in_gt_access_pack_type_id,
                refill_pack						= in_refill_pack,
                sf_innovation					= in_sf_innovation,
                sf_novel_refill					= in_sf_novel_refill,
                single_in_pack					= in_single_in_pack,
                settle_in_transit				= in_settle_in_transit,
                gt_gift_cont_type_id			= in_gt_gift_cont_type_id,
                gt_pack_layers_type_id			= in_gt_pack_layers_type_id,
                vol_package						= in_vol_package,
                retail_packs_stackable			= in_retail_packs_stackable,
				num_packs_per_outer				= in_num_packs_per_outer,
                vol_prod_tran_pack				= in_vol_prod_tran_pack,
                vol_tran_pack					= in_vol_tran_pack,
                correct_biopolymer_use			= in_correct_biopolymer_use,
                sf_recycled_threshold			= in_sf_recycled_threshold,
                sf_novel_material				= in_sf_novel_material,
                pack_meet_req					= in_pack_meet_req,
                pack_shelf_ready				= in_pack_shelf_ready,
                gt_trans_pack_type_id			= in_gt_trans_pack_type_id,
                sf_innovation_transit			= in_sf_innovation_transit,
				prod_pack_occupation			= in_prod_pack_occupation, 		 		
				pack_style_type	 			    = in_pack_style_type,	 			
				dbl_walled_jar_just 			= in_dbl_walled_jar_just, 			
				contain_tablets_just   		    = in_contain_tablets_just,   		
				tablets_in_blister_tray 		= in_tablets_in_blister_tray, 		
				carton_gift_box_just			= in_carton_gift_box_just,			
				carton_gift_box_vacuum_form	    = in_carton_gift_box_vacuum_form,	
				carton_gift_box_clear_win	    = in_carton_gift_box_clear_win,	
				carton_gift_box_sleeve		    = in_carton_gift_box_sleeve,		
				other_prod_protection_just	    = in_other_prod_protection_just,	
				other_pack_manu_proc_just	    = in_other_pack_manu_proc_just,	
				other_pack_fill_proc_just	    = in_other_pack_fill_proc_just,	
				other_logistics_just			= in_other_logistics_just,			
				other_prod_present_market_just  = in_other_prod_pres_market_just,
				other_consumer_accept_just	    = in_other_consumer_accept_just,	
				other_prod_info_just			= in_other_prod_info_just,			
				other_prod_safety_just		    = in_other_prod_safety_just,		
				other_prod_legislation_just	    = in_other_prod_legislation_just,	
				other_issues_just			    = in_other_issues_just,			
				just_report_explanation		    = in_just_report_explanation,
				pack_risk						= in_pack_risk,
				data_quality_type_id		= in_data_quality_type_id
			WHERE product_id = in_product_id
			AND revision_id = v_max_revision_id;
	END;
	
	product_info_pkg.UpdateProdVolumeWeight(in_act_id, in_product_id, in_prod_volume, in_prod_volume_declared, in_prod_weight, in_prod_weight_declared, in_weight_inc_pkg);
	  
	model_pkg.CalcProductScores(in_act_id, in_product_id, v_max_revision_id);

END;


PROCEDURE GetPackagingAnswers(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id				IN  product_revision.revision_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
    v_volume        	gt_product_answers.product_volume%TYPE;
    v_prod_weight   	gt_product_answers.prod_weight%TYPE;
	v_volume_declared        	gt_product_answers.product_volume_declared%TYPE;
    v_prod_weight_declared   	gt_product_answers.prod_weight_declared%TYPE;
    v_weight_inc_pkg	gt_product_answers.weight_inc_pkg%TYPE;
    v_pack_weight   	number(10, 2);
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading product with id '||in_product_id);
	END IF;

    begin
        SELECT product_volume, product_volume_declared, prod_weight, prod_weight_declared, weight_inc_pkg
		  INTO v_volume, v_volume_declared, v_prod_weight, v_prod_weight_declared, v_weight_inc_pkg
		  FROM gt_product_answers
		 WHERE product_id=in_product_id
		  AND revision_id = in_revision_id;
    exception
        when NO_DATA_FOUND then
            v_volume := -1;
    end;

    begin
        SELECT  SUM(weight_grams) into v_pack_weight
                    FROM gt_pack_item
                    WHERE product_id = in_product_id
                    AND revision_id = in_revision_id;
    exception
        when NO_DATA_FOUND then
            v_pack_weight := 0;
    end;
    
	OPEN out_cur FOR
		SELECT 	NVL(a.revision_id, 1) revision_id, p.description product_name, p.product_id, p.product_code,
				a.*, v_volume as product_volume, v_volume_declared as product_volume_declared, v_pack_weight as pack_weight, 
				v_prod_weight_declared as prod_weight_declared, v_prod_weight as prod_weight, v_weight_inc_pkg as prod_weight_inc_pkg, 
				data_quality_type_id, DECODE(pq.questionnaire_status_id, questionnaire_pkg.QUESTIONNAIRE_CLOSED, pq.last_saved_by, null) last_saved_by
		  FROM gt_packaging_answers a, product p, product_questionnaire pq
		 WHERE p.product_id = in_product_id
		   AND p.product_id = pq.product_id
		   AND pq.questionnaire_id = model_pd_pkg.QUESTION_GT_PACKAGING
		   AND p.product_id = pq.product_id
		   AND ((a.revision_id IS NULL) OR (a.revision_id = in_revision_id))
		   AND a.product_id(+) = p.product_id;
END;

PROCEDURE GetAccessPackageType(
    in_act_id                    IN security_pkg.T_ACT_ID,
	in_gt_product_type_id		 IN gt_product_type.gt_product_type_id%TYPE,
    out_cur                      OUT    security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- we need to limit this by the viscocity type of the product which is linked to the (now mandatory) product type
	
    OPEN out_cur FOR
       SELECT pat.gt_access_pack_type_id, pat.description
          FROM gt_access_pack_type pat, gt_access_pack_mapping pam, gt_product_type pt
         WHERE pat.gt_access_pack_type_id = pam.gt_access_pack_type_id
           AND pam.gt_access_visc_type_id = pt.gt_access_visc_type_id
           AND pt.gt_product_type_id = in_gt_product_type_id
              ORDER BY LOWER(pat.description) ASC;
END;

PROCEDURE GetTransitPackType(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT    security_pkg.T_OUTPUT_CUR
)
as
BEGIN
    OPEN out_cur FOR
        SELECT gt_trans_pack_type_id, description
          FROM gt_trans_pack_type
              ORDER BY pos ASC;
END;



PROCEDURE GetPackMaterial(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT    security_pkg.T_OUTPUT_CUR
)as
BEGIN
    OPEN out_cur FOR
        SELECT gt_pack_material_type_id, description
          FROM gt_pack_material_type
              ORDER BY pos ASC;
END;

PROCEDURE GetPackMaterial(
    in_act_id                    IN security_pkg.T_ACT_ID,
	in_shape_id					 IN gt_pack_shape_type.gt_pack_shape_type_id%TYPE,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT pmt.gt_pack_material_type_id, pmt.description
          FROM gt_pack_material_type pmt, gt_shape_material_mapping smm
          WHERE pmt.gt_pack_material_type_id = smm.gt_pack_material_type_id
          AND smm.gt_pack_shape_type_id = in_shape_id
              ORDER BY pmt.pos ASC;
END;

PROCEDURE GetTransMaterial(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT    security_pkg.T_OUTPUT_CUR
)as
BEGIN
    OPEN out_cur FOR
        SELECT gt_trans_material_type_id, description
          FROM gt_trans_material_type
              ORDER BY pos ASC;
END;

/*
PROCEDURE GetPackMaterial(
    in_act_id                    IN security_pkg.T_ACT_ID,
	in_shape_id					 IN gt_pack_shape_type.description%TYPE,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT pmt.gt_pack_material_type_id, pmt.description
          FROM gt_pack_material_type pmt, gt_shape_material_mapping smm, gt_pack_shape_type pst
          WHERE pmt.gt_pack_material_type_id = smm.gt_pack_material_type_id
          AND smm.gt_pack_shape_type_id = pst.gt_pack_shape_type_id
          AND LOWER(pst.description) = LOWER(in_shape_id)
              ORDER BY pmt.pos ASC;
END;*/

PROCEDURE GetPackShape(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT    security_pkg.T_OUTPUT_CUR
)as
BEGIN
    OPEN out_cur FOR
        SELECT gt_pack_shape_type_id, description
          FROM gt_pack_shape_type
              ORDER BY pos ASC;
END;

PROCEDURE GetProductPackItems(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN    all_product.product_id%TYPE,
   	in_revision_id				 IN  product_revision.revision_id%TYPE,
    out_cur                      OUT    security_pkg.T_OUTPUT_CUR
) AS
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading product with id '||in_product_id);
    END IF;

    OPEN out_cur FOR
        SELECT product_id, gt_pack_item_id, revision_id, gt_pack_shape_type_id, gt_pack_material_type_id, weight_grams, pct_recycled, contains_biopolymer
          FROM gt_pack_item
         WHERE product_id = in_product_id
           AND revision_id = in_revision_id;
END;

PROCEDURE GetProductTransPackItems(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN    all_product.product_id%TYPE,
   	in_revision_id				 IN  product_revision.revision_id%TYPE,
    out_cur                      OUT    security_pkg.T_OUTPUT_CUR
) AS
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading product with id '||in_product_id);
    END IF;

    OPEN out_cur FOR
        SELECT gt_trans_item_id, weight_grams, pct_recycled, product_id, revision_id, gt_trans_material_type_id
          FROM gt_trans_item
         WHERE product_id = in_product_id
           AND revision_id = in_revision_id;
END;

-- This isn't elegant but avoids having to rewrite the pack items mechanism just for audit
FUNCTION GetPackItemsString
(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE
) RETURN VARCHAR2
AS
	v_max_revision_id			product_revision.revision_id%TYPE;
	v_pack_list					VARCHAR2(2048);
BEGIN

	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
	SELECT NVL(csr.stragg(description), 'None set') INTO v_pack_list FROM (
        SELECT pi.description 
			FROM (SELECT mt.description || ' ' || st.description || ', ' || weight_grams || 'g, ' || pct_recycled || '% recycled' description, revision_id, product_id 
				    FROM gt_pack_item pi, gt_pack_material_type mt, gt_pack_shape_type st
			       WHERE pi.gt_pack_material_type_id = mt.gt_pack_material_type_id
			         AND pi.gt_pack_shape_type_id = st.gt_pack_shape_type_id) pi, 
			product_revision pr
        WHERE pr.product_id=pi.PRODUCT_ID (+)
        AND pr.REVISION_ID = pi.revision_id(+)
		AND pr.product_id = in_product_id
		AND pr.revision_id = v_max_revision_id
		ORDER BY LOWER(pi.description)
	);
	
	RETURN v_pack_list;
	
END;

FUNCTION GetTransPackItemsString
(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE
) RETURN VARCHAR2
AS
	v_max_revision_id			product_revision.revision_id%TYPE;
	v_pack_list					VARCHAR2(2048);
BEGIN

	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
	SELECT NVL(csr.stragg(description), 'None set') INTO v_pack_list FROM (
        SELECT pi.description 
			FROM (SELECT mt.description || ', ' || weight_grams || 'g, ' || pct_recycled || '% recycled' description, revision_id, product_id 
				    FROM gt_trans_item pi, gt_trans_material_type mt
			       WHERE pi.gt_trans_material_type_id = mt.gt_trans_material_type_id) pi, 
			product_revision pr
        WHERE pr.product_id=pi.PRODUCT_ID (+)
        AND pr.REVISION_ID = pi.revision_id(+)
		AND pr.product_id = in_product_id
		AND pr.revision_id = v_max_revision_id
		ORDER BY LOWER(pi.description)
	);
	
	RETURN v_pack_list;
	
END;


PROCEDURE DoPackItemsAudit
(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE, 
	in_old_pack_list			 IN VARCHAR2,
	in_new_pack_list			 IN VARCHAR2    
)
AS
	v_max_revision_id			product_revision.revision_id%TYPE;
BEGIN
	SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	    
	score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_RECYCLED_PACK, null, 'Packaging Items', in_old_pack_list, in_new_pack_list);
	score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_PACK_IMPACT, null, 'Packaging Items', in_old_pack_list, in_new_pack_list);
	score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_RECYCLABLE_PACK, null, 'Packaging Items', in_old_pack_list, in_new_pack_list);
	score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_RECOV_PACK, null, 'Packaging Items', in_old_pack_list, in_new_pack_list);
	score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_RENEW_PACK, null, 'Packaging Items', in_old_pack_list, in_new_pack_list);	

END;

PROCEDURE DoTransPackItemsAudit
(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE, 
	in_old_transit_pack_list			 IN VARCHAR2,
	in_new_transit_pack_list			 IN VARCHAR2    
)
AS
	v_max_revision_id			product_revision.revision_id%TYPE;
BEGIN
	SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	    
	score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_RECYCLED_PACK, null, 'Transit Packaging Items', in_old_transit_pack_list, in_new_transit_pack_list);
	score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_PACK_IMPACT, null, 'Transit Packaging Items', in_old_transit_pack_list, in_new_transit_pack_list);
	score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_RECYCLABLE_PACK, null, 'Transit Packaging Items', in_old_transit_pack_list, in_new_transit_pack_list);
	score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_RECOV_PACK, null, 'Transit Packaging Items', in_old_transit_pack_list, in_new_transit_pack_list);
	score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_RENEW_PACK, null, 'Transit Packaging Items', in_old_transit_pack_list, in_new_transit_pack_list);	

END;
----------------------

PROCEDURE DeletePackItems(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN    all_product.product_id%TYPE
) AS
	v_max_revision_id			product_revision.revision_id%TYPE;
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
    
    -- always on latest revision
    DELETE FROM gt_pack_item where product_id = in_product_id AND revision_id = v_max_revision_id;
END;

PROCEDURE DeleteTransPackItems(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN    all_product.product_id%TYPE
) AS
	v_max_revision_id			product_revision.revision_id%TYPE;
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
    
    -- always on latest revision
    DELETE FROM gt_trans_item where product_id = in_product_id AND revision_id = v_max_revision_id;
END;


PROCEDURE AddPackItem(
    in_act_id                       IN  security_pkg.T_ACT_ID,
    in_product_id                   IN  all_product.product_id%TYPE,
    in_gt_pack_item_id              in  gt_pack_item.gt_pack_item_id%TYPE,
    in_gt_pack_shape_type_id        in  gt_pack_item.gt_pack_shape_type_id%TYPE,
    in_gt_pack_material_type_id     in  gt_pack_item.gt_pack_material_type_id%TYPE,
    in_weight_grams                 in  gt_pack_item.weight_grams%TYPE,
    in_pct_recycled                 in  gt_pack_item.pct_recycled%TYPE,
    in_contains_biopolymer          in  gt_pack_item.contains_biopolymer%TYPE
) is
	v_max_revision_id			product_revision.revision_id%TYPE;
begin
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
     SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
    
    insert into gt_pack_item(
            product_id,
            revision_id,
            gt_pack_item_id,
            gt_pack_shape_type_id,
            gt_pack_material_type_id,
            weight_grams,
            pct_recycled,
            contains_biopolymer
        ) values (
            in_product_id,
            v_max_revision_id,
            gt_pack_item_id_seq.nextval,
            in_gt_pack_shape_type_id,
            in_gt_pack_material_type_id,
            in_weight_grams,
            in_pct_recycled,
            in_contains_biopolymer
        );
END;

PROCEDURE AddTransPackItem(
    in_act_id                       IN  security_pkg.T_ACT_ID,
    in_product_id                   IN  all_product.product_id%TYPE,
    in_gt_trans_item_id              IN  gt_trans_item.gt_trans_item_id%TYPE,
    in_gt_trans_material_type_id     IN  gt_trans_item.gt_trans_material_type_id%TYPE,
    in_weight_grams                 IN  gt_trans_item.weight_grams%TYPE,
    in_pct_recycled                 IN  gt_pack_item.pct_recycled%TYPE
) IS
	v_max_revision_id			product_revision.revision_id%TYPE;
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
    
    INSERT INTO gt_trans_item(
            product_id,
            revision_id,
            gt_trans_item_id,
            gt_trans_material_type_id,
            weight_grams,
            pct_recycled
        ) VALUES (
            in_product_id,
            v_max_revision_id,
            gt_trans_item_id_seq.nextval,  
            in_gt_trans_material_type_id,
            in_weight_grams,
            in_pct_recycled
        );
END;

PROCEDURE IncrementRevision(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_from_rev						IN product_revision.revision_id%TYPE
)
AS
BEGIN
	CopyAnswers(in_act_id, in_product_id, in_from_rev, in_product_id, in_from_rev+1);
END;


PROCEDURE CopyAnswers(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_from_product_id				IN all_product.product_id%TYPE,
	in_from_rev						IN product_revision.revision_id%TYPE,
	in_to_product_id				IN all_product.product_id%TYPE,
	in_to_rev						IN product_revision.revision_id%TYPE
)
AS
BEGIN
	
	-- we always want to overwrite so lets just get rid of the row
	DELETE FROM gt_pack_item WHERE product_id = in_to_product_id AND revision_id = in_to_rev;
	DELETE FROM gt_trans_item WHERE product_id = in_to_product_id AND revision_id = in_to_rev;

	DELETE FROM gt_packaging_answers WHERE product_id = in_to_product_id AND revision_id = in_to_rev;
	
	INSERT INTO gt_packaging_answers (
		product_id, 
		revision_id, 
		gt_access_pack_type_id, 
		refill_pack, 
		sf_innovation, 
		sf_novel_refill, 
		single_in_pack, 
		settle_in_transit, 
		gt_gift_cont_type_id, 
		gt_pack_layers_type_id, 
		vol_package, 
		retail_packs_stackable, 
		num_packs_per_outer,
		vol_prod_tran_pack, 
		vol_tran_pack, 
		correct_biopolymer_use, 
		sf_recycled_threshold, 
		sf_novel_material, 
		pack_meet_req, 
		pack_shelf_ready, 
		gt_trans_pack_type_id, 
		sf_innovation_transit,
		prod_pack_occupation,
		pack_style_type,
		dbl_walled_jar_just,
		contain_tablets_just,
		tablets_in_blister_tray,
		carton_gift_box_just,
		carton_gift_box_vacuum_form,
		carton_gift_box_clear_win,
		carton_gift_box_sleeve,
		other_prod_protection_just,
		other_pack_manu_proc_just,
		other_pack_fill_proc_just,
		other_logistics_just,
		other_prod_present_market_just,
		other_consumer_accept_just,
		other_prod_info_just,
		other_prod_safety_just,
		other_prod_legislation_just,
		other_issues_just,
		just_report_explanation,
		pack_risk,
		data_quality_type_id
	   ) 
	SELECT 
		in_to_product_id, 
		in_to_rev, 
		gt_access_pack_type_id, 
		refill_pack, 
		sf_innovation, 
		sf_novel_refill, 
		single_in_pack, 
		settle_in_transit, 
		gt_gift_cont_type_id, 
		gt_pack_layers_type_id, 
		vol_package, 
		retail_packs_stackable, 
		num_packs_per_outer,
		vol_prod_tran_pack, 
		vol_tran_pack, 
		correct_biopolymer_use, 
		sf_recycled_threshold, 
		sf_novel_material, 
		pack_meet_req, 
		pack_shelf_ready, 
		gt_trans_pack_type_id, 
		sf_innovation_transit,
		prod_pack_occupation,
		pack_style_type,
		dbl_walled_jar_just,
		contain_tablets_just,
		tablets_in_blister_tray,
		carton_gift_box_just,
		carton_gift_box_vacuum_form,
		carton_gift_box_clear_win,
		carton_gift_box_sleeve,
		other_prod_protection_just,
		other_pack_manu_proc_just,
		other_pack_fill_proc_just,
		other_logistics_just,
		other_prod_present_market_just,
		other_consumer_accept_just,
		other_prod_info_just,
		other_prod_safety_just,
		other_prod_legislation_just,
		other_issues_just,
		just_report_explanation,
		pack_risk,
		data_quality_type_id
		FROM gt_packaging_answers
	WHERE product_id = in_from_product_id
	AND revision_id =  in_from_rev;
		
	INSERT INTO gt_trans_item (
	   product_id, gt_trans_item_id, revision_id, weight_grams, 
	   pct_recycled, gt_trans_material_type_id
	) 
	SELECT 
	   in_to_product_id, gt_trans_item_id, in_to_rev, weight_grams, 
	   pct_recycled, gt_trans_material_type_id
	FROM gt_trans_item
	WHERE product_id = in_from_product_id
	AND revision_id =  in_from_rev;
	
	INSERT INTO gt_pack_item (
	   product_id, gt_pack_item_id, revision_id, 
	   gt_pack_shape_type_id, gt_pack_material_type_id, weight_grams, 
	   pct_recycled, contains_biopolymer) 
	  SELECT 
	   in_to_product_id, gt_pack_item_id, in_to_rev, 
	   gt_pack_shape_type_id, gt_pack_material_type_id, weight_grams, 
	   pct_recycled, contains_biopolymer
	FROM gt_pack_item
	WHERE product_id = in_from_product_id
	AND revision_id =  in_from_rev;

END;


END gt_packaging_pkg;
/
