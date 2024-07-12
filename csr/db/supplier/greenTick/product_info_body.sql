create or replace package body supplier.product_info_pkg
IS

PROCEDURE SetProductAnswers (
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_gt_scope_notes 				IN gt_product_answers.gt_scope_notes%TYPE,
	in_gt_product_range_id 			IN gt_product_answers.gt_product_range_id%TYPE,
--	in_gt_product_type_id 			IN gt_product_type.gt_product_type_id%TYPE,
	in_product_volume 				IN gt_product_answers.product_volume%TYPE,
	in_product_volume_declared		IN gt_product_answers.product_volume_declared%TYPE,
    in_prod_weight         			IN gt_product_answers.prod_weight%TYPE,
	in_prod_weight_declared 		IN gt_product_answers.prod_weight_declared%TYPE,
    in_weight_inc_pkg         		IN gt_product_answers.weight_inc_pkg%TYPE,
	in_community_trade_pct 			IN gt_product_answers.community_trade_pct%TYPE,
	in_ct_doc_group_id 				IN gt_product_answers.ct_doc_group_id%TYPE,
	in_fairtrade_pct 				IN gt_product_answers.fairtrade_pct%TYPE,
	in_other_fair_pct 				IN gt_product_answers.other_fair_pct%TYPE,
	in_not_fair_pct 				IN gt_product_answers.not_fair_pct%TYPE,
	in_reduce_energy_use_adv		IN gt_product_answers.reduce_energy_use_adv%TYPE,
	in_reduce_water_use_adv			IN gt_product_answers.reduce_water_use_adv%TYPE,
	in_reduce_waste_adv				IN gt_product_answers.reduce_waste_adv%TYPE,
	in_on_pack_recycling_adv		IN gt_product_answers.on_pack_recycling_adv%TYPE,
	in_consumer_advice_3 			IN gt_product_answers.consumer_advice_3%TYPE,
	in_consumer_advice_3_dg 		IN gt_product_answers.consumer_advice_3_dg%TYPE,
	in_consumer_advice_4 			IN gt_product_answers.consumer_advice_4%TYPE,
	in_consumer_advice_4_dg 		IN gt_product_answers.consumer_advice_4_dg%TYPE,
	in_sustain_assess_1 			IN gt_product_answers.sustain_assess_1%TYPE,
	in_sustain_assess_1_dg 			IN gt_product_answers.sustain_assess_1_dg%TYPE,
	in_sustain_assess_2 			IN gt_product_answers.sustain_assess_2%TYPE,
	in_sustain_assess_2_dg 			IN gt_product_answers.sustain_assess_2_dg%TYPE,
	in_sustain_assess_3 			IN gt_product_answers.sustain_assess_3%TYPE,
	in_sustain_assess_3_dg 			IN gt_product_answers.sustain_assess_3_dg%TYPE,
	in_sustain_assess_4				IN gt_product_answers.sustain_assess_4%TYPE,
	in_sustain_assess_4_dg			IN gt_product_answers.sustain_assess_4_dg%TYPE,
	in_data_quality_type_id         IN gt_product_answers.data_quality_type_id%TYPE
)
AS
	v_max_revision_id				product_revision.revision_id%TYPE;
	v_gt_product_range_id		gt_product_answers.gt_product_range_id%TYPE;
	--v_gt_product_type_id		gt_product_type.gt_product_type_id%TYPE;
	v_ct_doc_group_id			gt_product_answers.ct_doc_group_id%TYPE;
	v_consumer_advice_3_dg		gt_product_answers.consumer_advice_3_dg%TYPE;
	v_consumer_advice_4_dg		gt_product_answers.consumer_advice_4_dg%TYPE;
	v_sustain_assess_1_dg		gt_product_answers.sustain_assess_1_dg%TYPE;
	v_sustain_assess_2_dg		gt_product_answers.sustain_assess_2_dg%TYPE;
	v_sustain_assess_3_dg		gt_product_answers.sustain_assess_3_dg%TYPE;
	v_sustain_assess_4_dg		gt_product_answers.sustain_assess_4_dg%TYPE;
	
	v_gt_product_type_id		gt_product_type.gt_product_type_id%TYPE;
	v_gt_product_type			gt_product_type.description%TYPE;
	v_product_class_id			gt_product_class.gt_product_class_id%TYPE;
	v_product_class				gt_product_class.gt_product_class_name%TYPE;
	v_product_type_unit			gt_product_type.unit%TYPE;
BEGIN

	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	GetProductDataFromTags(in_act_id, in_product_id, v_gt_product_type_id, v_gt_product_type, v_product_class_id, v_product_class, v_product_type_unit);

	-- Map -1 to NULL for IDs
	SELECT DECODE(in_gt_product_range_id, -1, NULL, in_gt_product_range_id) INTO v_gt_product_range_id FROM dual;
--	SELECT DECODE(in_gt_product_type_id, -1, NULL, in_gt_product_type_id) INTO v_gt_product_type_id FROM dual;
	SELECT DECODE(in_ct_doc_group_id, -1, NULL, in_ct_doc_group_id) INTO v_ct_doc_group_id FROM dual;
	SELECT DECODE(in_consumer_advice_3_dg, -1, NULL, in_consumer_advice_3_dg) INTO v_consumer_advice_3_dg FROM dual;
	SELECT DECODE(in_consumer_advice_4_dg, -1, NULL, in_consumer_advice_4_dg) INTO v_consumer_advice_4_dg FROM dual;
	SELECT DECODE(in_sustain_assess_1_dg, -1, NULL, in_sustain_assess_1_dg) INTO v_sustain_assess_1_dg FROM dual;
	SELECT DECODE(in_sustain_assess_2_dg, -1, NULL, in_sustain_assess_2_dg) INTO v_sustain_assess_2_dg FROM dual;
	SELECT DECODE(in_sustain_assess_3_dg, -1, NULL, in_sustain_assess_3_dg) INTO v_sustain_assess_3_dg FROM dual;
	SELECT DECODE(in_sustain_assess_4_dg, -1, NULL, in_sustain_assess_4_dg) INTO v_sustain_assess_4_dg FROM dual;
	
    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	FOR r IN (
		SELECT 
				pr.revision_id, pr.product_id, 
			   gt_product_range_id, 
			   --gt_product_type_id,
			   product_volume, product_volume_declared, prod_weight, prod_weight_declared, weight_inc_pkg, community_trade_pct,
			   reduce_energy_use_adv, reduce_water_use_adv, reduce_waste_adv, on_pack_recycling_adv,	
			   fairtrade_pct, other_fair_pct, not_fair_pct
		FROM gt_product_answers pa, product_revision pr
            WHERE pr.product_id=pa.product_id (+)
            AND pr.REVISION_ID = pa.revision_id(+)
			AND pr.product_id = in_product_id
			AND pr.revision_id = v_max_revision_id
	) 
	LOOP

		-- actually only ever going to be single row as product id and revision id are PK
					
		score_log_pkg.LogSimpleTypeValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_NON_SCORING, null, 'Product range', r.gt_product_range_id, v_gt_product_range_id,
					'gt_product_range', 'description', 'gt_product_range_id');
				
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_PACK_OPT, null, 'Actual Product volume', r.product_volume, in_product_volume);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_WATER_USE, null, 'Actual Product volume', r.product_volume, in_product_volume);
		
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_PACK_IMPACT, null, 'Actual Weight of product (g)', r.prod_weight, in_prod_weight);
		score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_PACK_IMPACT, null, 'Weight inc. or exc. packaging', r.weight_inc_pkg, in_weight_inc_pkg);
				
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_FAIR_TRADE, null, 'Faitrade %', r.fairtrade_pct, in_fairtrade_pct);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_FAIR_TRADE, null, 'Other fair trade %', r.other_fair_pct, in_other_fair_pct);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_FAIR_TRADE, null, 'Community trade %', r.community_trade_pct, in_community_trade_pct);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_FAIR_TRADE, null, 'Not covered by fair trade %', r.not_fair_pct, in_not_fair_pct);
		
		score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_ENERGY_USE, null, 'Reduce energy use advice', r.reduce_energy_use_adv, in_reduce_energy_use_adv);
		score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_WATER_USE, null, 'Reduce water use advice', r.reduce_water_use_adv, in_reduce_water_use_adv);
		score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_PROD_WASTE, null, 'Reduce waste advice', r.reduce_waste_adv, in_reduce_waste_adv);
		score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_RECYCLABLE_PACK, null, 'Recycling information on packaging', r.on_pack_recycling_adv, in_on_pack_recycling_adv);

	END LOOP;

	-- upsert
	BEGIN
	
		INSERT INTO GT_PRODUCT_ANSWERS (
		   product_id, revision_id, gt_scope_notes,
		   gt_product_range_id, product_volume, prod_weight, weight_inc_pkg,
		   community_trade_pct, ct_doc_group_id, fairtrade_pct,
		   other_fair_pct, not_fair_pct, 
		   reduce_energy_use_adv, reduce_water_use_adv, reduce_waste_adv, on_pack_recycling_adv,
		   consumer_advice_3, consumer_advice_3_dg, consumer_advice_4,
		   consumer_advice_4_dg, sustain_assess_1, sustain_assess_1_dg,
		   sustain_assess_2, sustain_assess_2_dg, sustain_assess_3,
		   sustain_assess_3_dg, sustain_assess_4, sustain_assess_4_dg, data_quality_type_id,
		   prod_weight_declared, product_volume_declared)
		VALUES (
		   in_product_id, v_max_revision_id, in_gt_scope_notes,
		   v_gt_product_range_id, in_product_volume, in_prod_weight, in_weight_inc_pkg,
		   in_community_trade_pct, v_ct_doc_group_id, in_fairtrade_pct,
		   in_other_fair_pct, in_not_fair_pct,
		   in_reduce_energy_use_adv, in_reduce_water_use_adv, in_reduce_waste_adv, in_on_pack_recycling_adv,
		   in_consumer_advice_3, v_consumer_advice_3_dg, in_consumer_advice_4,
		   v_consumer_advice_4_dg, in_sustain_assess_1, v_sustain_assess_1_dg,
		   in_sustain_assess_2, v_sustain_assess_2_dg, in_sustain_assess_3,
		   v_sustain_assess_3_dg, in_sustain_assess_4, v_sustain_assess_4_dg,
		   in_data_quality_type_id, in_prod_weight_declared, in_product_volume_declared
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN

			UPDATE gt_product_answers SET
					gt_scope_notes 			=	in_gt_scope_notes,
					gt_product_range_id 	=	v_gt_product_range_id,
					product_volume 			=	in_product_volume,
					prod_weight				=	in_prod_weight,
					weight_inc_pkg			= 	in_weight_inc_pkg,
					community_trade_pct 	=	in_community_trade_pct,
					ct_doc_group_id 		=	v_ct_doc_group_id,
					fairtrade_pct 			=	in_fairtrade_pct,
					other_fair_pct 			=	in_other_fair_pct,
					not_fair_pct 			=	in_not_fair_pct,
					reduce_energy_use_adv 	= 	in_reduce_energy_use_adv,
					reduce_water_use_adv	= 	in_reduce_water_use_adv,					
					reduce_waste_adv		= 	in_reduce_waste_adv,						
					on_pack_recycling_adv 	= 	in_on_pack_recycling_adv,					
					consumer_advice_3 		=	in_consumer_advice_3,
					consumer_advice_3_dg 	=	v_consumer_advice_3_dg,
					consumer_advice_4 		=	in_consumer_advice_4,
					consumer_advice_4_dg 	=	v_consumer_advice_4_dg,
					sustain_assess_1 		=	in_sustain_assess_1,
					sustain_assess_1_dg 	=	v_sustain_assess_1_dg,
					sustain_assess_2 		=	in_sustain_assess_2,
					sustain_assess_2_dg 	=	v_sustain_assess_2_dg,
					sustain_assess_3 		=	in_sustain_assess_3,
					sustain_assess_3_dg 	=	v_sustain_assess_3_dg,
					sustain_assess_4		=	in_sustain_assess_4,
					sustain_assess_4_dg		=	v_sustain_assess_4_dg,
					data_quality_type_id	=	in_data_quality_type_id,
					prod_weight_declared	=	in_prod_weight_declared,
					product_volume_declared	=	in_product_volume_declared
			WHERE product_id = in_product_id
			AND revision_id = v_max_revision_id;
	END;

	model_pkg.CalcProductScores(in_act_id, in_product_id, v_max_revision_id);

END;

PROCEDURE GetGTProductRevision (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id				IN	product_revision.revision_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading product with id '||in_product_id);
	END IF;
	
	OPEN out_cur FOR
		SELECT 	pr.product_id, pr.revision_id, pr.product_code, pr.description, supplier_company_sid, 
				active, deleted, app_sid, pr.gt_product_type_id, pr.gt_product_type_group_id, 
				gt_water_use_type_id, pr.water_usage_factor, pr.mnfct_energy_score, pr.gt_product_class_id, pr.gt_access_visc_type_id, 
				pr.unit, gt_product_info_used, gt_packaging_used, gt_formulation_used, gt_transport_used, 
				gt_supplier_used, gt_product_design_used, has_ingredients, has_packaging,  
				-- profile bits
				prod_weight_desc, pack_risk_desc, pack_risk_colour, gt_product_type
		 FROM gt_product_rev pr, gt_profile_report prof
		WHERE pr.product_id = prof.product_id
		  AND pr.revision_id = prof.revision_id
		  AND pr.product_id = in_product_id
		  AND pr.revision_id = in_revision_id;
	
END;


FUNCTION IsSubProduct (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id				IN  product_revision.revision_id%TYPE
) RETURN NUMBER
AS
	v_max_revision_id	 		product_revision.revision_id%TYPE; 
	v_is_sub	 					NUMBER(10); 
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading product with id '||in_product_id);
	END IF;
	
	SELECT NVL(MAX(revision_id),1) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;

	IF (v_max_revision_id = NVL(in_revision_id,1)) THEN 
		SELECT COUNT(*)
		  INTO v_is_sub
		  FROM product_tag pt, tag t 
		 WHERE pt.tag_id = t.tag_id 
		   AND LOWER(t.tag) = 'sub product'
		   AND pt.product_id = in_product_id;	
	ELSE
		SELECT COUNT(*)
		  INTO v_is_sub
		  FROM product_revision_tag pt, tag t 
		 WHERE pt.tag_id = t.tag_id 
		   AND LOWER(t.tag) = 'sub product'
		   AND pt.product_id = in_product_id
		   AND pt.revision_id = in_revision_id;
	END IF;
	
	IF v_is_sub > 0 THEN 
		v_is_sub := 1;
	END IF;
	
	RETURN v_is_sub;
	
END;

-- get for latest revision - type, class, units etc.
PROCEDURE GetProductDataFromTags (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	out_product_type_id			OUT	gt_product_type.gt_product_type_id%TYPE,
	out_product_type			OUT	gt_product_type.description%TYPE,
	out_product_class_id		OUT	gt_product_class.gt_product_class_id%TYPE,
	out_product_class			OUT	gt_product_class.gt_product_class_name%TYPE,
	out_product_type_unit		OUT	gt_product_type.unit%TYPE
)
AS
	v_max_revision_id	 		product_revision.revision_id%TYPE;
BEGIN

	SELECT NVL(MAX(revision_id),1) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
	GetProductDataFromTags(in_act_id, in_product_id, v_max_revision_id, out_product_type_id, out_product_type, out_product_class_id, out_product_class, out_product_type_unit);

END;

-- get for any revision -  type, class, units etc.
PROCEDURE GetProductDataFromTags (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id				IN  product_revision.revision_id%TYPE, 
	out_product_type_id			OUT	gt_product_type.gt_product_type_id%TYPE,
	out_product_type			OUT	gt_product_type.description%TYPE,
	out_product_class_id		OUT	gt_product_class.gt_product_class_id%TYPE,
	out_product_class			OUT	gt_product_class.gt_product_class_name%TYPE,
	out_product_type_unit		OUT	gt_product_type.unit%TYPE
)
AS
	v_max_revision_id	 		product_revision.revision_id%TYPE; 
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading product with id '||in_product_id);
	END IF;
	
	SELECT NVL(MAX(revision_id),1) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
	IF (v_max_revision_id = NVL(in_revision_id,1)) THEN 
		-- get from the product tag table - as current revision
		SELECT gpt.gt_product_type_id, gpt.description, gpc.gt_product_class_id, gpc.gt_product_class_name, gpt.unit
		  INTO out_product_type_id, out_product_type, out_product_class_id, out_product_class, out_product_type_unit
		  FROM product_tag pt, gt_tag_product_type tpt, gt_product_type gpt, gt_product_class gpc
		 WHERE pt.tag_id = tpt.tag_id 
		   AND tpt.gt_product_type_id = gpt.gt_product_type_id
		   AND gpt.gt_product_class_id = gpc.gt_product_class_id
		   AND pt.product_id = in_product_id;
	ELSE
		-- get from the product revision tag table - as prev revision
		SELECT gpt.gt_product_type_id, gpt.description, gpc.gt_product_class_id, gpc.gt_product_class_name, gpt.unit
		  INTO out_product_type_id, out_product_type, out_product_class_id, out_product_class, out_product_type_unit
		  FROM product_revision_tag prt, gt_tag_product_type tpt, gt_product_type gpt, gt_product_class gpc
		 WHERE prt.tag_id = tpt.tag_id 
		   AND tpt.gt_product_type_id = gpt.gt_product_type_id
		   AND gpt.gt_product_class_id = gpc.gt_product_class_id
		   AND prt.product_id = in_product_id
		   AND revision_id = in_revision_id; 
	END IF;
	
END;

PROCEDURE GetProductDataFromTags (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id				IN  product_revision.revision_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_max_revision_id	 		product_revision.revision_id%TYPE; 
	v_gt_product_type_id		gt_product_type.gt_product_type_id%TYPE;
	v_gt_product_type			gt_product_type.description%TYPE;
	v_gt_product_class_id		gt_product_class.gt_product_class_id%TYPE;
	v_gt_product_class			gt_product_class.gt_product_class_name%TYPE;
	v_gt_product_type_unit		gt_product_type.unit%TYPE;
BEGIN

	GetProductDataFromTags(in_act_id, in_product_id, NVL(in_revision_id, 1), v_gt_product_type_id, v_gt_product_type, v_gt_product_class_id, v_gt_product_class, v_gt_product_type_unit);
	
	-- wrap up as a cursor
	OPEN out_cur FOR 
		SELECT v_gt_product_type_id gt_product_type_id, v_gt_product_type gt_product_type, v_gt_product_class_id gt_product_class_id, v_gt_product_class gt_product_class, v_gt_product_type_unit unit 
			FROM dual;
	
END;

-- get for any revision -  type, class, units etc.
PROCEDURE GetProductTypeFromTags (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id				IN  product_revision.revision_id%TYPE, 
	out_product_type_id			OUT	gt_product_type.gt_product_type_id%TYPE,
	out_product_type			OUT	gt_product_type.description%TYPE
)
AS
	v_gt_product_class_id		gt_product_class.gt_product_class_id%TYPE;
	v_gt_product_class			gt_product_class.gt_product_class_name%TYPE;
	v_gt_product_type_unit		gt_product_type.unit%TYPE;
BEGIN
	
	GetProductDataFromTags(in_act_id, in_product_id, in_revision_id, out_product_type_id, out_product_type, v_gt_product_class_id, v_gt_product_class, v_gt_product_type_unit);
	
END;

-- get type for max revision
PROCEDURE GetProductTypeFromTags (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	out_product_type_id			OUT	gt_product_type.gt_product_type_id%TYPE,
	out_product_type			OUT	gt_product_type.description%TYPE
)
AS
	v_gt_product_class_id		gt_product_class.gt_product_class_id%TYPE;
	v_gt_product_class			gt_product_class.gt_product_class_name%TYPE;
	v_gt_product_type_unit		gt_product_type.unit%TYPE;
	v_max_revision_id	 		product_revision.revision_id%TYPE; 
BEGIN
	SELECT NVL(MAX(revision_id),1) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	GetProductDataFromTags(in_act_id, in_product_id, v_max_revision_id, out_product_type_id, out_product_type, v_gt_product_class_id, v_gt_product_class, v_gt_product_type_unit);
END;

FUNCTION GetProductTypeId(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id				IN  product_revision.revision_id%TYPE
) RETURN NUMBER
AS
	v_gt_product_type_id		gt_product_type.gt_product_type_id%TYPE;
	v_gt_product_type			gt_product_type.description%TYPE;
BEGIN
	product_info_pkg.GetProductTypeFromTags(in_act_id, in_product_id, in_revision_id, v_gt_product_type_id, v_gt_product_type);
	RETURN v_gt_product_type_id;
END;

PROCEDURE GetProductClassFromTags (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id				IN  product_revision.revision_id%TYPE, 
	out_product_class_id		OUT	gt_product_class.gt_product_class_id%TYPE,
	out_product_class			OUT	gt_product_class.gt_product_class_name%TYPE
)
AS
	v_gt_product_type_id		gt_product_type.gt_product_type_id%TYPE;
	v_gt_product_type			gt_product_type.description%TYPE;
	v_gt_product_type_unit		gt_product_type.unit%TYPE;
BEGIN
	
	GetProductDataFromTags(in_act_id, in_product_id, in_revision_id, v_gt_product_type_id, v_gt_product_type, out_product_class_id, out_product_class, v_gt_product_type_unit);
	
END;

FUNCTION GetProductClassId(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id				IN  product_revision.revision_id%TYPE
) RETURN NUMBER
AS
	v_gt_product_class_id		gt_product_class.gt_product_class_id%TYPE;
	v_gt_product_class			gt_product_class.gt_product_class_name%TYPE;
BEGIN
	product_info_pkg.GetProductClassFromTags(in_act_id, in_product_id, in_revision_id, v_gt_product_class_id, v_gt_product_class);
	RETURN v_gt_product_class_id;
END;


PROCEDURE GetProductAnswers(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id				IN  product_revision.revision_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_gt_product_type_id		gt_product_type.gt_product_type_id%TYPE;
	v_gt_product_type			gt_product_type.description%TYPE;
	v_gt_product_class_id		gt_product_class.gt_product_class_id%TYPE;
	v_gt_product_class			gt_product_class.gt_product_class_name%TYPE;
	v_gt_product_type_unit		gt_product_type.unit%TYPE;
	v_is_sub					NUMBER(1);
	v_is_parent_pack			NUMBER(1) := 0;
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading product with id '||in_product_id);
	END IF;
	
	GetProductDataFromTags(in_act_id, in_product_id, in_revision_id, v_gt_product_type_id, v_gt_product_type, v_gt_product_class_id, v_gt_product_class, v_gt_product_type_unit);
	
	-- is this a sub product
	v_is_sub := IsSubProduct(in_act_id, in_product_id, in_revision_id);
	
	-- is this a parent pack
	IF v_gt_product_class_id = model_pd_pkg.PROD_CLASS_PARENT_PACK THEN 
		v_is_parent_pack := 1;
	END IF;

	OPEN out_cur FOR
		SELECT NVL(a.revision_id, 1) revision_id, p.description product_name, p.product_id, p.product_code, gt_scope_notes,
		   a.gt_product_range_id, pr.description gt_product_range_name, 
		   v_gt_product_type_id gt_product_type_id, v_gt_product_type gt_product_type_name, pt.unit gt_product_type_unit,
		   product_volume, prod_weight, weight_inc_pkg, community_trade_pct, ct_doc_group_id,
		   fairtrade_pct, other_fair_pct, not_fair_pct,
		   reduce_energy_use_adv, reduce_water_use_adv, reduce_waste_adv, on_pack_recycling_adv,
		   consumer_advice_3, consumer_advice_3_dg,
		   consumer_advice_4, consumer_advice_4_dg,
		   sustain_assess_1, sustain_assess_1_dg,
		   sustain_assess_2, sustain_assess_2_dg,
		   sustain_assess_3, sustain_assess_3_dg,
		   sustain_assess_4, sustain_assess_4_dg,
		   data_quality_type_id,	   
		   v_is_sub is_sub_product,
		   v_is_parent_pack is_parent_pack, prod_weight_declared, product_volume_declared,
		   DECODE(pq.questionnaire_status_id, questionnaire_pkg.QUESTIONNAIRE_CLOSED, pq.last_saved_by, null) last_saved_by
		  FROM gt_product_answers a, product p, product_questionnaire pq,
		  	gt_product_range pr, gt_product_type pt
		 WHERE p.product_id = in_product_id
		   AND p.product_id = pq.product_id
		   AND pq.questionnaire_id = model_pd_pkg.QUESTION_GT_PROD_INFO
		   AND a.product_id(+) = p.product_id
		   AND ((a.revision_id IS NULL) OR (a.revision_id = in_revision_id))
		   AND pr.gt_product_range_id(+) = a.gt_product_range_id
		   AND pt.gt_product_type_id(+) = v_gt_product_type_id;
END;

PROCEDURE DeleteAbsentLinkedProducts(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN all_product.product_id%TYPE,
	in_product_ids				IN product_pkg.T_PRODUCT_IDS
)
AS
	v_current_ids				product_pkg.T_PRODUCT_IDS;
	v_max_revision_id			product_revision.revision_id%TYPE;
	v_idx						NUMBER;
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to product with id '||in_product_id);
	END IF;
	
	SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;

	-- Get current ids
	FOR r IN (
		SELECT link_product_id
			FROM gt_link_product
		 WHERE product_id = in_product_id
		 AND revision_id = v_max_revision_id
	) LOOP
		v_current_ids(r.link_product_id) := r.link_product_id ;
	END LOOP;

	-- Remove any part ids present in the input array
	IF ((in_product_ids.count>0) AND (in_product_ids(1) IS NOT NULL)) THEN
		FOR i IN in_product_ids.FIRST .. in_product_ids.LAST
		LOOP
			IF v_current_ids.EXISTS(in_product_ids(i)) THEN
				v_current_ids.DELETE(in_product_ids(i));
			END IF;
		END LOOP;
	END IF;
	
	-- Delete any ids remaining	
	IF v_current_ids.COUNT > 0 THEN -- can't use FIRST ... LAST as sparse array 
		  v_idx := v_current_ids.FIRST;
		  WHILE (v_idx IS NOT NULL) 
		  LOOP		
			DeleteLinkedProduct(in_act_id, in_product_id, v_current_ids(v_idx));
			v_idx := v_current_ids.NEXT(v_idx);
		END LOOP;
	END IF;
	
END;

PROCEDURE GetLinkedProducts(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN all_product.product_id%TYPE,
	in_revision_id				IN  product_revision.revision_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading product with id '||in_product_id);
	END IF;

	OPEN out_cur FOR
		SELECT link_product_id, p.description link_product_name, count, p.product_code link_product_code
		  FROM gt_link_product l, product p
		 WHERE l.product_id = in_product_id
		   AND l.link_product_id = p.product_id
		   AND l.revision_id = in_revision_id
		   	ORDER BY p.description ASC;

END;

PROCEDURE AddLinkedProduct(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN all_product.product_id%TYPE,
	in_link_product_id			IN gt_link_product.link_product_id%TYPE,
	in_count					IN gt_link_product.count%TYPE
)
AS
	v_max_revision_id				product_revision.revision_id%TYPE;
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to product with id '||in_product_id);
	END IF;
	
	-- always saving to latest
	SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;

	-- upsert
	BEGIN

		INSERT INTO gt_link_product (product_id, revision_id, link_product_id, count)
		   VALUES (in_product_id, v_max_revision_id, in_link_product_id, in_count);

	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN

		UPDATE gt_link_product
		   SET count = in_count
		 WHERE product_id = in_product_id
		 	 AND revision_id = v_max_revision_id
		 	 AND link_product_id = in_link_product_id;

	END;

END;

PROCEDURE UpdateLinkedProduct(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN all_product.product_id%TYPE,
	in_link_product_id			IN gt_link_product.link_product_id%TYPE,
	in_count					IN gt_link_product.count%TYPE
)
AS
	v_max_revision_id				product_revision.revision_id%TYPE;
BEGIN
		IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to product with id '||in_product_id);
	END IF;
	
	-- always saving to latest
	SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
	UPDATE gt_link_product
	   SET count = in_count
	 WHERE product_id = in_product_id
	 	 AND revision_id = v_max_revision_id
	 	 AND link_product_id = in_link_product_id;

END;

PROCEDURE DeleteLinkedProduct(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN all_product.product_id%TYPE,
	in_link_product_id			IN gt_link_product.link_product_id%TYPE
)
AS
	v_max_revision_id				product_revision.revision_id%TYPE;
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to product with id '||in_product_id);
	END IF;
	
	-- always saving to latest
	SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
	DELETE FROM gt_link_product
	 WHERE link_product_id = in_link_product_id
	   AND revision_id = v_max_revision_id
	   AND product_id = in_product_id;
END;

PROCEDURE GetProductTypes(
	in_act_id					IN security_pkg.T_ACT_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT gt_product_type_id, description
		  FROM gt_product_type
		 ORDER BY LOWER(description) ASC;	
END;

PROCEDURE GetProductTypesByGroupId(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_group_id					IN gt_product_type_group.gt_product_type_group_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT pt.gt_product_type_id, pt.description, pt.gt_product_type_group_id
		  FROM gt_product_type pt, gt_product_type_group ptg
		 WHERE pt.gt_product_type_group_id = ptg.gt_product_type_group_id
		   AND ptg.gt_product_type_group_id = in_group_id
		 ORDER BY LOWER(description) ASC;
END;

PROCEDURE GetProductTypeGroups(
	in_act_id					IN security_pkg.T_ACT_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT gt_product_type_group_id,description
		  FROM gt_product_type_group
		 ORDER BY LOWER(description) ASC;
			
END;

PROCEDURE GetProductTypes(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN all_product.product_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT gt_product_type_id, description
		  FROM gt_product_type
		  	ORDER BY LOWER(description) ASC;

		
END;

/*PROCEDURE GetProductClass(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN all_product.product_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
     	SELECT pc.gt_product_class_id, pc.gt_product_class_name
		  FROM product_tag pt, gt_product_class pc 
		 WHERE pt.gt_product_class_id = pc.gt_product_class_id
		   AND pt.product_id = in_product_id;
END;
*/

PROCEDURE GetProductRanges(
	in_act_id					IN security_pkg.T_ACT_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT gt_product_range_id, description
		  FROM gt_product_range
		  	ORDER BY description ASC;
END;


PROCEDURE SearchProduct(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_app_sid					IN security_pkg.T_SID_ID,
	in_name						IN all_product.description%TYPE,
	in_code						IN all_product.product_code%TYPE,
	in_product_id				IN all_product.product_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_is_admin				NUMBER(1) := 0;
	v_user_company_sid		security_pkg.T_SID_ID;
	v_user_sid				security_pkg.T_SID_ID := SYS_CONTEXT('security', 'sid');
BEGIN

	-- if not an admin/approver (write access on "companies" SO) only return the products for user company
	IF security_pkg.IsAccessAllowedSID(in_act_id, securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Supplier/Companies'), security_pkg.PERMISSION_WRITE) THEN
		v_is_admin := 1; -- admins get everything
		v_user_company_sid := -1;
	ELSE
		SELECT NVL(company_sid,-1) INTO v_user_company_sid FROM company_user WHERE app_sid = in_app_sid AND csr_user_sid = v_user_sid;
	END IF;

	OPEN out_cur FOR
		-- Output params defined like this so we can use the link product object for data transfer
		SELECT p.product_id link_product_id, description link_product_name, 0 count, NVL(is_sub_product,0) is_sub_product
		  FROM gt_product p, (
				SELECT pt.product_id, 1 is_sub_product 
				  FROM product_tag pt, tag t 
				 WHERE pt.tag_id = t.tag_id 
				   AND t.tag = 'Sub Product'
			   ) isSubProdTbl
		 WHERE app_sid = in_app_sid
		   AND p.product_id = isSubProdTbl.product_id (+)
		   AND LOWER(description) LIKE('%' || LOWER(in_name) || '%')
		   AND LOWER(product_code) LIKE('%' || LOWER(in_code) || '%')
		   AND p.product_id <> in_product_id -- can't link self
		   AND gt_product_class_id <> model_pd_pkg.PROD_CLASS_PARENT_PACK -- parent packs can't be children
		   AND ((v_is_admin = 1) OR (p.supplier_company_sid = v_user_company_sid))  	
		   AND p.product_id NOT IN(
			  SELECT DISTINCT product_id
				FROM gt_link_product
			   START WITH link_product_id = in_product_id
			 CONNECT BY link_product_id = PRIOR product_id 
			 ) -- can't select own parents
			ORDER BY description ASC;
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
	v_old_ct_doc_group_id					document_group.document_group_id%TYPE;
	v_new_ct_doc_group_id					document_group.document_group_id%TYPE;
	
	v_old_CONSUMER_ADVICE_3_DG				document_group.document_group_id%TYPE;
	v_new_CONSUMER_ADVICE_3_DG				document_group.document_group_id%TYPE;
	v_old_CONSUMER_ADVICE_4_DG				document_group.document_group_id%TYPE;
	v_new_CONSUMER_ADVICE_4_DG				document_group.document_group_id%TYPE;
	
	v_old_SUSTAIN_ASSESS_1_DG				document_group.document_group_id%TYPE;
	v_new_SUSTAIN_ASSESS_1_DG				document_group.document_group_id%TYPE;
	v_old_SUSTAIN_ASSESS_2_DG				document_group.document_group_id%TYPE;
	v_new_SUSTAIN_ASSESS_2_DG				document_group.document_group_id%TYPE;
	v_old_SUSTAIN_ASSESS_3_DG				document_group.document_group_id%TYPE;
	v_new_SUSTAIN_ASSESS_3_DG				document_group.document_group_id%TYPE;
	v_old_SUSTAIN_ASSESS_4_DG				document_group.document_group_id%TYPE;
	v_new_SUSTAIN_ASSESS_4_DG				document_group.document_group_id%TYPE;

BEGIN
	
	-- copy the sust doc group
	document_pkg.CreateDocumentGroup(in_act_id, v_new_ct_doc_group_id);
	BEGIN 
		SELECT ct_doc_group_id INTO v_old_ct_doc_group_id FROM gt_product_answers WHERE product_id = in_from_product_id AND revision_id = in_from_rev;
		document_pkg.CopyDocumentsToNewGroup(in_act_id, v_old_ct_doc_group_id, v_new_ct_doc_group_id);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- do nothing
			NULL;
	END;
		
	document_pkg.CreateDocumentGroup(in_act_id, v_new_CONSUMER_ADVICE_3_DG);
	BEGIN
		SELECT CONSUMER_ADVICE_3_DG INTO v_old_CONSUMER_ADVICE_3_DG FROM gt_product_answers WHERE product_id = in_from_product_id AND revision_id = in_from_rev;
		document_pkg.CopyDocumentsToNewGroup(in_act_id, v_old_CONSUMER_ADVICE_3_DG, v_new_CONSUMER_ADVICE_3_DG);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- do nothing
			NULL;
	END;
	
	document_pkg.CreateDocumentGroup(in_act_id, v_new_CONSUMER_ADVICE_4_DG);
	BEGIN	
		SELECT CONSUMER_ADVICE_4_DG INTO v_old_CONSUMER_ADVICE_4_DG FROM gt_product_answers WHERE product_id = in_from_product_id AND revision_id = in_from_rev;
		document_pkg.CopyDocumentsToNewGroup(in_act_id, v_old_CONSUMER_ADVICE_4_DG, v_new_CONSUMER_ADVICE_4_DG);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- do nothing
			NULL;
	END;
	
	document_pkg.CreateDocumentGroup(in_act_id, v_new_SUSTAIN_ASSESS_1_DG);
	BEGIN
		SELECT SUSTAIN_ASSESS_1_DG INTO v_old_SUSTAIN_ASSESS_1_DG FROM gt_product_answers WHERE product_id = in_from_product_id AND revision_id = in_from_rev;
		document_pkg.CopyDocumentsToNewGroup(in_act_id, v_old_SUSTAIN_ASSESS_1_DG, v_new_SUSTAIN_ASSESS_1_DG);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- do nothing
			NULL;
	END;
	
	document_pkg.CreateDocumentGroup(in_act_id, v_new_SUSTAIN_ASSESS_2_DG);
	BEGIN	
		SELECT SUSTAIN_ASSESS_2_DG INTO v_old_SUSTAIN_ASSESS_2_DG FROM gt_product_answers WHERE product_id = in_from_product_id AND revision_id = in_from_rev;
		document_pkg.CopyDocumentsToNewGroup(in_act_id, v_old_SUSTAIN_ASSESS_2_DG, v_new_SUSTAIN_ASSESS_2_DG);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- do nothing
			NULL;
	END;
	
	document_pkg.CreateDocumentGroup(in_act_id, v_new_SUSTAIN_ASSESS_3_DG);
	BEGIN	
		SELECT SUSTAIN_ASSESS_3_DG INTO v_old_SUSTAIN_ASSESS_3_DG FROM gt_product_answers WHERE product_id = in_from_product_id AND revision_id = in_from_rev;
		document_pkg.CopyDocumentsToNewGroup(in_act_id, v_old_SUSTAIN_ASSESS_3_DG, v_new_SUSTAIN_ASSESS_3_DG);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- do nothing
			NULL;
	END;

	document_pkg.CreateDocumentGroup(in_act_id, v_new_SUSTAIN_ASSESS_4_DG);
	BEGIN		
		SELECT SUSTAIN_ASSESS_4_DG INTO v_old_SUSTAIN_ASSESS_4_DG FROM gt_product_answers WHERE product_id = in_from_product_id AND revision_id = in_from_rev;
		document_pkg.CopyDocumentsToNewGroup(in_act_id, v_old_SUSTAIN_ASSESS_4_DG, v_new_SUSTAIN_ASSESS_4_DG);	
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- do nothing
			NULL;
	END;
		
	DELETE FROM gt_link_product
	 WHERE product_id = in_to_product_id
	   AND revision_id = in_to_rev;

	DELETE FROM gt_country_sold_in
	 WHERE product_id = in_to_product_id
	   AND revision_id =  in_to_rev;

	DELETE FROM gt_product_answers
	 WHERE product_id = in_to_product_id
	   AND revision_id = in_to_rev;

	INSERT INTO gt_product_answers (
	   product_id, revision_id, gt_scope_notes, 
	   gt_product_range_id, product_volume, prod_weight, product_volume_declared, prod_weight_declared, 
	   weight_inc_pkg, community_trade_pct, ct_doc_group_id, fairtrade_pct, 
	   other_fair_pct, not_fair_pct, 
	   reduce_energy_use_adv, reduce_water_use_adv, reduce_waste_adv, on_pack_recycling_adv,
	   consumer_advice_3, consumer_advice_3_dg, consumer_advice_4, 
	   consumer_advice_4_dg, sustain_assess_1, sustain_assess_1_dg, 
	   sustain_assess_2, sustain_assess_2_dg, sustain_assess_3, 
	   sustain_assess_3_dg, sustain_assess_4, sustain_assess_4_dg, data_quality_type_id
   ) 
	SELECT 
		in_to_product_id, in_to_rev, gt_scope_notes, 
	   gt_product_range_id, product_volume, prod_weight, product_volume_declared, prod_weight_declared, 
	   weight_inc_pkg, community_trade_pct, v_new_ct_doc_group_id, fairtrade_pct, 
	   other_fair_pct, not_fair_pct, 
	   reduce_energy_use_adv, reduce_water_use_adv, reduce_waste_adv, on_pack_recycling_adv,
	   consumer_advice_3, v_new_consumer_advice_3_dg, consumer_advice_4, 
	   v_new_consumer_advice_4_dg, sustain_assess_1, v_new_sustain_assess_1_dg, 
	   sustain_assess_2, v_new_sustain_assess_2_dg, sustain_assess_3, 
	   v_new_sustain_assess_3_dg, sustain_assess_4, v_new_sustain_assess_4_dg, data_quality_type_id
	FROM gt_product_answers
			WHERE product_id = in_from_product_id
			AND revision_id =  in_from_rev;
			
	INSERT INTO gt_link_product (product_id, link_product_id, revision_id, count) 
	SELECT in_to_product_id, link_product_id, in_to_rev, count
		FROM gt_link_product
				WHERE product_id = in_from_product_id
				AND revision_id =  in_from_rev;
				
	INSERT INTO gt_country_sold_in (product_id, country_code, revision_id) 
	SELECT in_to_product_id, country_code, in_to_rev
		FROM gt_country_sold_in
			WHERE product_id = in_from_product_id
			AND revision_id =  in_from_rev;
END;



--product tree procedures
PROCEDURE GetTreeWithDepth(
	in_act_id   	IN security_pkg.T_ACT_ID,
	in_product_id	IN product.product_id%TYPE,
	in_fetch_depth	IN NUMBER,
	in_group_id	IN product_questionnaire_group.group_id%TYPE,
	out_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	product_allow_t 		security.T_SID_TABLE;
BEGIN
	
	OPEN out_cur FOR
		SELECT qlp.link_product_id sid_id, qlp.product_id parent_sid_id, p.product_code || ' - ' || p.description || ' (' || qlp.count || ')' name, LEVEL so_level, 
               CASE WHEN LEVEL = in_fetch_depth THEN 1 ELSE 0 END is_leaf, 1 is_match, 
			   (
                    SELECT DISTINCT pqg.group_status_id 
					  FROM product_questionnaire_group pqg, product_questionnaire pq, questionnaire_group_membership qgm
				     WHERE qgm.group_id = pqg.group_id
					   AND pq.questionnaire_id = qgm.questionnaire_id
					   AND pqg.product_id = qlp.link_product_id
					   AND pq.product_id = pqg.product_id
					   AND pqg.group_id = in_group_id
                ) class_name
		  FROM gt_link_product_max_rev qlp, product p
         WHERE qlp.link_product_id = p.product_id 
           AND LEVEL <= in_fetch_depth 
	     START WITH qlp.product_id = in_product_id
	   CONNECT BY PRIOR qlp.link_product_id = qlp.product_id
	   ORDER SIBLINGS BY p.description;

END;



PROCEDURE GetTreeTextFiltered(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_product_id	IN	product.product_id%TYPE,
	in_search_phrase	IN	VARCHAR2,
	in_group_id			IN product_questionnaire_group.group_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	
	
	OPEN out_cur FOR
		SELECT qlp.link_product_id sid_id, qlp.product_id parent_sid_id, p.product_code || ' - ' || p.description || ' (' || qlp.count || ')' name, LEVEL so_level, 
			   CONNECT_BY_ISLEAF is_leaf,  NVL(tm.is_match,0) is_match, 
			   (
					SELECT DISTINCT pqg.group_status_id 
					  FROM product_questionnaire_group pqg, product_questionnaire pq, questionnaire_group_membership qgm
					 WHERE qgm.group_id = pqg.group_id
					   AND pq.questionnaire_id = qgm.questionnaire_id
					   AND pqg.product_id = qlp.link_product_id
					   AND pq.product_id = pqg.product_id
					   AND pqg.group_id = in_group_id
				) class_name
		  FROM gt_link_product_max_rev qlp, product p, 
		  (
			SELECT DISTINCT gt_link_product_max_rev.link_product_id 
			  FROM gt_link_product_max_rev
			 START WITH gt_link_product_max_rev.link_product_id IN (
				SELECT DISTINCT p2.product_id 
				  FROM gt_link_product_max_rev glp2, product p2
				 WHERE glp2.link_product_id = p2.product_id
				   AND LOWER(p2.description) LIKE '%'||LOWER(in_search_phrase)||'%'
				 START WITH glp2.product_id = in_product_id
			   CONNECT BY PRIOR glp2.link_product_id = glp2.product_id
			   )
		   CONNECT BY gt_link_product_max_rev.link_product_id =  PRIOR gt_link_product_max_rev.product_id
		 ) t,
		 (
			SELECT DISTINCT p2.product_id, 1 is_match 
			  FROM gt_link_product_max_rev glp2, product p2
			 WHERE glp2.link_product_id = p2.product_id
			   AND LOWER(p2.description) LIKE '%'||LOWER(in_search_phrase)||'%'
		     START WITH glp2.product_id = in_product_id
		   CONNECT BY PRIOR glp2.link_product_id = glp2.product_id
		 ) tm
		WHERE qlp.link_product_id = p.product_id
		  AND qlp.link_product_id = t.link_product_id
		  AND qlp.link_product_id = tm.product_id (+) 
		START WITH qlp.product_id = in_product_id
	  CONNECT BY PRIOR qlp.link_product_id = qlp.product_id
		ORDER SIBLINGS BY p.description;
	 
END;


PROCEDURE GetList(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_root_sid			IN	security_pkg.T_SID_ID,
	in_limit			IN	NUMBER,
	in_group_id			IN product_questionnaire_group.group_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	
	OPEN out_cur FOR
		SELECT qlp.link_product_id sid_id, qlp.product_id parent_sid_id, p.description name, LEVEL so_level, 
               CONNECT_BY_ISLEAF is_leaf, 1 is_match, 
			   LTRIM(SYS_CONNECT_BY_PATH(p.description, ' > '),' > ') path,
			   (
                    SELECT DISTINCT pqg.group_status_id 
					  FROM product_questionnaire_group pqg, product_questionnaire pq, questionnaire_group_membership qgm
				     WHERE qgm.group_id = pqg.group_id
					   AND pq.questionnaire_id = qgm.questionnaire_id
					   AND pqg.product_id = qlp.link_product_id
					   AND pq.product_id = pqg.product_id
					   AND pqg.group_id = in_group_id
                ) class_name
		  FROM gt_link_product_max_rev qlp, product p
         WHERE qlp.link_product_id = p.product_id
		   AND rownum <= in_limit		 
	     START WITH qlp.product_id = in_root_sid
	   CONNECT BY PRIOR qlp.link_product_id = qlp.product_id
	   ORDER SIBLINGS BY p.description;
END;


PROCEDURE GetListTextFiltered(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_root_sid	IN	security_pkg.T_SID_ID,
	in_search_phrase	IN	VARCHAR2,
	in_limit			IN	NUMBER,
	in_group_id			IN product_questionnaire_group.group_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT qlp.link_product_id sid_id, qlp.product_id parent_sid_id, p.description name, LEVEL so_level, 
               CONNECT_BY_ISLEAF is_leaf, 1 is_match, 
			   LTRIM(SYS_CONNECT_BY_PATH(p.description, ' > '),' > ') path,
			   (
                    SELECT DISTINCT pqg.group_status_id 
					  FROM product_questionnaire_group pqg, product_questionnaire pq, questionnaire_group_membership qgm
				     WHERE qgm.group_id = pqg.group_id
					   AND pq.questionnaire_id = qgm.questionnaire_id
					   AND pqg.product_id = qlp.link_product_id
					   AND pq.product_id = pqg.product_id
					   AND pqg.group_id = in_group_id
                ) class_name
		  FROM gt_link_product_max_rev qlp, product p
         WHERE qlp.link_product_id = p.product_id
		   AND rownum <= in_limit
		   AND LOWER(p.description) LIKE '%'||LOWER(in_search_phrase)||'%'
	     START WITH qlp.product_id = in_root_sid
	   CONNECT BY PRIOR qlp.link_product_id = qlp.product_id
	   ORDER SIBLINGS BY p.description;
END;

PROCEDURE UpdateProdVolumeWeight(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_product_volume				IN gt_product_answers.product_volume%TYPE,
	in_product_volume_declared		IN gt_product_answers.product_volume_declared%TYPE,
    in_prod_weight         			IN gt_product_answers.prod_weight%TYPE,
	in_prod_weight_declared  			IN gt_product_answers.prod_weight_declared%TYPE,
    in_weight_inc_pkg         		IN gt_product_answers.weight_inc_pkg%TYPE
)
AS
	v_max_revision_id			product_revision.revision_id%TYPE;
	v_ct_doc_group_id			gt_product_answers.ct_doc_group_id%TYPE;
	
	v_consumer_advice_3_dg		gt_product_answers.consumer_advice_3_dg%TYPE;
	v_consumer_advice_4_dg		gt_product_answers.consumer_advice_4_dg%TYPE;
	v_sustain_assess_1_dg		gt_product_answers.sustain_assess_1_dg%TYPE;
	v_sustain_assess_2_dg		gt_product_answers.sustain_assess_2_dg%TYPE;
	v_sustain_assess_3_dg		gt_product_answers.sustain_assess_3_dg%TYPE;
	v_sustain_assess_4_dg		gt_product_answers.sustain_assess_4_dg%TYPE;
	
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
    --fetch max revision id
	SELECT NVL(MAX(revision_id),-1) INTO v_max_revision_id 
	  FROM gt_product_answers 
	 WHERE product_id = in_product_id;
	  
	IF v_max_revision_id = -1 THEN
		
		document_pkg.CreateDocumentGroup(in_act_id, v_ct_doc_group_id);

		document_pkg.CreateDocumentGroup(in_act_id, v_consumer_advice_3_dg);
		document_pkg.CreateDocumentGroup(in_act_id, v_consumer_advice_4_dg);
		document_pkg.CreateDocumentGroup(in_act_id, v_sustain_assess_1_dg);
		document_pkg.CreateDocumentGroup(in_act_id, v_sustain_assess_2_dg);
		document_pkg.CreateDocumentGroup(in_act_id, v_sustain_assess_3_dg);
		document_pkg.CreateDocumentGroup(in_act_id, v_sustain_assess_4_dg);
		
		--insert empty row
		SetProductAnswers (
			in_act_id,
			in_product_id,
			NULL ,
			NULL ,
			in_product_volume ,
			in_product_volume_declared ,
			in_prod_weight,
			in_prod_weight_declared,	
			in_weight_inc_pkg,
			NULL ,
			v_ct_doc_group_id ,
			NULL ,
			NULL ,
			NULL ,
			NULL ,
			NULL ,
			NULL ,
			NULL ,
			NULL ,
			v_consumer_advice_3_dg ,
			NULL ,
			v_consumer_advice_4_dg ,
			NULL ,
			v_sustain_assess_1_dg ,
			NULL ,
			v_sustain_assess_2_dg ,
			NULL ,
			v_sustain_assess_3_dg ,
			NULL,
			v_sustain_assess_4_dg,
			NULL
		);
	ELSE
		--update current row
		UPDATE gt_product_answers 
		   SET  product_volume 			= NVL(in_product_volume, product_volume),
		   		prod_weight				= NVL(in_prod_weight, prod_weight), 
				product_volume_declared = NVL(in_product_volume, product_volume_declared),
		   		prod_weight_declared	= NVL(in_prod_weight, prod_weight_declared), 
				weight_inc_pkg 			= NVL(in_weight_inc_pkg, weight_inc_pkg)
		 WHERE revision_id = v_max_revision_id
		   AND product_id = in_product_id; 
	END IF;

END;

PROCEDURE GetDataQualityTypes(
    in_act_id                   IN security_pkg.T_ACT_ID,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT data_quality_type_id, description, score
		  FROM data_quality_type
		  	ORDER BY score ASC;
END;

PROCEDURE GetFilteredProductTypes(
    in_act_id                   IN security_pkg.T_ACT_ID,
	in_group_filter				IN gt_product_group.gt_product_group_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT t.tag, t.tag_id
		FROM tag t, tag_group_filter f, tag_group_member tgm, tag_group tg
		WHERE f.gt_product_group_id = in_group_filter
		AND t.tag_id = f.tag_id
		AND t.tag_id = tgm.tag_id
		AND tgm.tag_group_sid = tg.tag_group_sid
		ORDER BY t.tag DESC;
END;

PROCEDURE GetProductGroupData(
    in_act_id                   IN security_pkg.T_ACT_ID,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT gt_product_group_id, description
		FROM gt_product_group
		ORDER BY description DESC;
END;

END product_info_pkg;
/
