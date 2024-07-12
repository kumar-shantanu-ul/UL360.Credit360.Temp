create or replace package body supplier.model_pkg
IS

PROCEDURE GetProductScores(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN security_pkg.T_SID_ID,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_sustainable_cur 			OUT	security_pkg.T_OUTPUT_CUR,
	out_formulation_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_supply_cur 					OUT	security_pkg.T_OUTPUT_CUR,
	out_use_at_home_cur 			OUT	security_pkg.T_OUTPUT_CUR,
	out_end_of_life_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	
	GetScoreSustainableGroup(in_act_id, in_product_id, in_revision_id, out_sustainable_cur);
	GetScoreFormulationGroup(in_act_id, in_product_id, in_revision_id, out_formulation_cur);
	GetScoreSupplyGroup(in_act_id, in_product_id, in_revision_id, out_supply_cur);
	GetScoreUseAtHomeGroup(in_act_id, in_product_id, in_revision_id, out_use_at_home_cur);
	GetScoreEndOfLifeGroup(in_act_id, in_product_id, in_revision_id, out_end_of_life_cur);
	
END;

PROCEDURE CalcProductScores(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN security_pkg.T_SID_ID
) 
AS
	v_max_revision_id				product_revision.revision_id%TYPE;
BEGIN
	SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	CalcProductScores(in_act_id, in_product_id, v_max_revision_id);
END;

PROCEDURE CalcProductScores(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN security_pkg.T_SID_ID,
	in_revision_id					IN product_revision.revision_id%TYPE
)
AS
	v_has_linked_prod				NUMBER(10);
	v_has_parent					NUMBER(10);
	v_max_revision_id				product_revision.revision_id%TYPE;
BEGIN
	
    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
	CalcScoreSustainableGroup(in_act_id, in_product_id, in_revision_id);
	CalcScoreFormulationGroup(in_act_id, in_product_id, in_revision_id);
	CalcScoreSupplyGroup(in_act_id, in_product_id, in_revision_id);
	CalcScoreUseAtHomeGroup(in_act_id, in_product_id, in_revision_id);
	CalcScoreEndOfLifeGroup(in_act_id, in_product_id, in_revision_id);
	
	SELECT COUNT(*) INTO v_has_linked_prod FROM gt_link_product WHERE product_id = in_product_id AND revision_id = in_revision_id;
	SELECT COUNT(*) INTO v_has_parent FROM gt_link_product WHERE link_product_id = in_product_id;
	
	-- is this a parent - don't do combined scores if there are no link prods
	IF v_has_linked_prod > 0 THEN
		SetCombinedScore(in_act_id, in_product_id, in_revision_id);
	END IF;
	
	-- Is this a child - if this is the latest revision and it has a parent then combined scores for that parent need recalcing
	-- Note: only the latest revision if a product is used in the combined scoring - hence the check for latest rev id
	IF (v_max_revision_id = in_revision_id) AND (v_has_parent > 0) THEN
		FOR r IN (
			SELECT product_id, revision_id FROM gt_link_product WHERE link_product_id = in_product_id
		)
		LOOP
			SetCombinedScore(in_act_id, r. product_id, r.revision_id);
		END LOOP;
	END IF;
	
	
END;

-- the targets scores are set up such that you can set a set of targets up for a product type or a type/range
-- if there are matching targets for this type/range for this product then that type/range is returned
-- if there are matching targets for this type for this product then that type is returned and -1 is returned for range
-- if there are no matching targets for this type or type/range for this product then both type and range are returned as -1
PROCEDURE GetBestMatchTargetScore (
	in_act_id						IN  security_pkg.T_ACT_ID,
	in_product_id					IN  security_pkg.T_SID_ID,
	in_revision_id					IN  product_revision.revision_id%TYPE,
	out_actual_type_id				OUT gt_product_type.gt_product_type_id%TYPE,
	out_matched_type_id				OUT gt_product_type.gt_product_type_id%TYPE,
	out_actual_range_id				OUT gt_product_answers.gt_product_range_id%TYPE,
	out_matched_range_id			OUT gt_product_answers.gt_product_range_id%TYPE
)
AS
	v_cnt						NUMBER;
	v_gt_product_type_id		gt_product_type.gt_product_type_id%TYPE;
	v_gt_product_type			gt_product_type.description%TYPE;
	v_gt_product_range_id		gt_product_answers.gt_product_range_id%TYPE;
	v_app_sid					product.app_sid%TYPE;
BEGIN

	SELECT app_sid INTO v_app_sid FROM product WHERE product_id = in_product_id;
	
	-- first get the product type for this product and revision - will be set
	product_info_pkg.GetProductTypeFromTags(in_act_id, in_product_id, in_revision_id, v_gt_product_type_id, v_gt_product_type);
	out_actual_type_id := v_gt_product_type_id;
	
	-- get the range if set
	SELECT NVL(gt_product_range_id, -1) INTO v_gt_product_range_id 
	  FROM product p, gt_product_answers pa 
	 WHERE p.product_id = pa.product_id(+) 
	   AND p.product_id = in_product_id
	   AND ((pa.revision_id IS NULL) OR (pa.revision_id = in_revision_id));
	out_actual_range_id := v_gt_product_range_id;
	
	SELECT COUNT(*) INTO v_cnt 
	  FROM gt_target_scores gts 
	 WHERE gts.gt_product_type_id = v_gt_product_type_id
	   AND gts.gt_product_range_id = v_gt_product_range_id
	   AND gts.app_sid = v_app_sid;
	   
	IF v_cnt > 0 THEN 
		-- match on range and type for target scores
		out_matched_range_id := v_gt_product_range_id;
		out_matched_type_id := v_gt_product_type_id;
	ELSE

		-- is there a score set up for type
		SELECT COUNT(*) INTO v_cnt 
		  FROM gt_target_scores gts 
		 WHERE gts.gt_product_type_id = v_gt_product_type_id
		   AND gts.gt_product_range_id IS NULL
		   AND gts.app_sid = v_app_sid;
		   
		out_matched_range_id := -1;
		   
		IF v_cnt > 0 THEN 
			-- match on type only for target scores
			out_matched_type_id := v_gt_product_type_id;	
		ELSE
			-- no matches 
			out_matched_type_id := -1;
		END IF;
	
	END IF;

END;

---------------------------------------------
-- Gift scoring - basic
---------------------------------------------

PROCEDURE SetCombinedScore(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE
)
AS
-- **Sustainably Sourced
--Naturally Derived Ingredients
--Chemicals - Environmental Risk
--Biodiversity
--Biodiversity Source / Accreditation
--Fair / Community trade
--Renewable Packaging
	v_score_nat_derived		gt_scores.score_nat_derived%TYPE;
	v_score_chemicals		gt_scores.score_chemicals%TYPE;
	v_score_source_biod		gt_scores.score_source_biod%TYPE;
	v_score_accred_biod		gt_scores.score_accred_biod%TYPE;
	v_score_fair_trade		gt_scores.score_fair_trade%TYPE;
	v_score_renew_pack		gt_scores.score_renew_pack%TYPE;
	
-- Special cases
--Biodiversity - trips if any parent / child is MAX - but this is a "MAX of parent/children" score anyway - so no special consideration needed atm
--Biodiversity Source / Accreditation -	- trips if any parent / child is MAX - normally this is a "AVG of parent/children" score - so special consideration IS needed 
--Fair / Community trade - to represent the case where the whole product is Fair Trade - if the top level product is 100% FT then use that score - else average scores


-- **Formulation Group - whats in the product
-- Impact of Materials
-- Water - Product
-- Energy - Product
-- Packaging - Impact
-- Packaging - Optimisation
-- Recycled Packaging
	v_score_whats_in_prod	gt_scores.score_whats_in_prod%TYPE;
	v_score_water_in_prod	gt_scores.score_water_in_prod%TYPE;
	v_score_energy_in_prod	gt_scores.score_energy_in_prod%TYPE;
	v_score_pack_impact		gt_scores.score_pack_impact%TYPE;
	v_score_pack_impact_raw	gt_scores.score_pack_impact%TYPE;
	v_score_pack_opt		gt_scores.score_pack_opt%TYPE;
	v_score_recycled_pack	gt_scores.score_recycled_pack%TYPE;
	
-- Special cases
-- Packaging - Impact - uses raw pkg values to calc - calc's elsewhere
	v_pkg_set_ok					NUMBER(10);
	v_prod_weight					gt_product_answers.prod_weight%TYPE;  
	v_inc_pkg						gt_product_answers.weight_inc_pkg%TYPE;
	v_concentrate_pack				gt_formulation_answers.concentrate%TYPE; 
	v_refill_pack					gt_packaging_answers.refill_pack%TYPE; 
	v_packaging_weight_total		gt_pack_item.weight_grams%TYPE;
		
	
-- **Supply Group
-- Supplier Management
-- Transport - Raw Materials
-- Transport - Product to Boots
-- Transit packaging
-- Transit Optimisation
    v_score_supp_management		gt_scores.score_supp_management%TYPE;
    v_score_trans_raw_mat		gt_scores.score_trans_raw_mat%TYPE;
    v_score_trans_to_boots		gt_scores.score_trans_to_boots%TYPE;
    v_score_trans_packaging		gt_scores.score_trans_packaging%TYPE;
    v_score_trans_opt			gt_scores.score_trans_opt%TYPE;
	v_score_energy_dist			gt_scores.score_energy_dist%TYPE;
	
-- Special cases
-- Transport - Raw Materials - Parent Pack won't have any ingredients - just calc from packging 
-- Transport - Raw Materials - Sub items no packaging won't have any packaging - just calc from ingredients  
	
-- ** Use at home 
-- Water in Use
-- Energy in Use
-- Ancillary Materials Required
    v_score_water_use			gt_scores.score_water_use%TYPE;
    v_score_energy_use			gt_scores.score_energy_use%TYPE;
    v_score_ancillary_req		gt_scores.score_ancillary_req%TYPE;

-- ** End of Life
--Product Waste
--Recyclable packaging
--Recoverable packaging
	v_score_prod_waste			gt_scores.score_prod_waste%TYPE;
    v_score_recyclable_pack		gt_scores.score_recyclable_pack%TYPE;
    v_score_recov_pack			gt_scores.score_recov_pack%TYPE;
	
	v_has_linked_prod			NUMBER(10);

	
	v_prod_class_id				gt_product_class.gt_product_class_id%TYPE;
BEGIN

	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- Not critical - but no sense calling this function with no linked child products - so not coded against that - raise an error to stop any odd scores
	SELECT COUNT(*) INTO v_has_linked_prod FROM gt_link_product WHERE product_id = in_product_id AND revision_id = in_revision_id;
	IF (v_has_linked_prod = 0) THEN 
		RAISE_APPLICATION_ERROR(model_pkg.ERR_INVALID_ARG, 'Cannot run this function on product ('||in_product_id||') with no children');
	END IF;
	
	-- find product class up front
	v_prod_class_id := product_info_pkg.GetProductClassId(in_act_id, in_product_id, in_revision_id);

	
	-- get as much up front as possible
	-- the product weight here may not be used if PARENT PACK
	SELECT MIN(packaging_set_ok) packaging_set_ok, NVL(SUM(pkg_weight),-1) pkg_weight, NVL(SUM(prod_weight_inc_pkg),-1) prod_weight_inc_pkg 
	  INTO v_pkg_set_ok, v_packaging_weight_total, v_prod_weight
	  FROM (
		SELECT  pr.product_id, pr.revision_id, has_packaging, DECODE(has_packaging, 1, NVL2(SUM(pi.weight_grams),1 ,0), 0, 1) packaging_set_ok,
				NVL(SUM(pi.weight_grams), 0) pkg_weight, pa.weight_inc_pkg, pa.prod_weight, DECODE(pa.weight_inc_pkg, 1, pa.prod_weight, 0, pa.prod_weight + NVL(SUM(pi.weight_grams),0)) prod_weight_inc_pkg 
		FROM gt_pack_item pi, gt_product_answers pa, (
			SELECT product_id, revision_id, has_packaging
			  FROM gt_product_rev pr
			 WHERE product_id = in_product_id 
			   AND revision_id = in_revision_id
			UNION 
			SELECT link_product_id product_id, pr.revision_id latest_revision_id, has_packaging
			  FROM gt_link_product_max_rev lp, (
				  SELECT product_id, revision_id, has_packaging 
					FROM gt_product_rev pr 
				   WHERE revision_id = (SELECT MAX(revision_id) FROM product_revision WHERE product_id = pr.product_id)
			  ) pr
			 WHERE pr.product_id = lp.link_product_id
			   AND lp.product_id = in_product_id 
			   AND lp.revision_id = in_revision_id
		) pr
		WHERE pr.product_id = pi.product_id(+)
		  AND pr.revision_id = pi.revision_id(+)
		  AND pr.product_id = pa.product_id(+)
		  AND pr.revision_id = pa.revision_id(+)
		GROUP BY pr.product_id, pr.revision_id, has_packaging, pa.weight_inc_pkg, pa.prod_weight 
	);
	
	-- Special cases - work out the packaging scores that look at the parent and child data	
	-- Packaging - Impact
	CASE 
		WHEN (v_prod_class_id = model_pd_pkg.PROD_CLASS_FORMULATED) OR (v_prod_class_id = model_pd_pkg.PROD_CLASS_MANUFACTURED) OR (v_prod_class_id = model_pd_pkg.PROD_CLASS_FOOD) THEN 
		
			-- combined item so have to make some assumptions
			v_refill_pack := 0;
			v_concentrate_pack := 0;
			-- we've summed prod weight to inc pkg
			v_inc_pkg := 1;
			
	  
		WHEN (v_prod_class_id = model_pd_pkg.PROD_CLASS_PARENT_PACK) THEN 
		
			-- base the weight and refill flag on the top level item only
			SELECT 
				NVL(prod_weight,-1), NVL(refill_pack,-1)
			  INTO v_prod_weight, v_refill_pack
			  FROM gt_product_answers pa, gt_packaging_answers pka, all_product p
			 WHERE p.product_id = pa.product_id(+)
			   AND p.product_id = pka.product_id(+)
			   AND p.product_id = in_product_id
			   AND ((pa.revision_id = in_revision_id) OR (pa.revision_id IS NULL))
			   AND ((pka.revision_id = in_revision_id) OR (pka.revision_id IS NULL));
			   
			-- PP always inc. packaging
			v_inc_pkg := 1;
			v_concentrate_pack := 0;
			   

		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown product class ('||v_prod_class_id||')');
	END CASE;
	
	-- do we have enough info
	IF (v_pkg_set_ok = 0) OR (v_prod_weight<0) OR (v_refill_pack<0) OR (v_packaging_weight_total<0) THEN
		v_score_pack_impact := 0;
		v_score_pack_impact_raw := 0;
	ELSE
		model_pd_pkg.CalcPackImpactScoreFromData(in_product_id, v_prod_class_id, in_revision_id, v_prod_weight, v_inc_pkg, v_concentrate_pack, v_refill_pack, v_packaging_weight_total, v_score_pack_impact, v_score_pack_impact_raw);
	END IF;

	-- Packaging - Optimisation
	v_score_pack_opt := 10;	
	
	SELECT 
		NVL(DECODE(min_score_nat_derived,       -1, -1,score_nat_derived), -1)      score_nat_derived,
		NVL(DECODE(min_score_chemicals,			-1, -1,score_chemicals), -1)		score_chemicals,
		NVL(DECODE(min_score_source_biod,		-1, -1,score_source_biod), -1)		score_source_biod,
		--Biodiversity Source / Accreditation -	- trips if any parent / child is MAX - normally this is a "AVG of parent/children" score - so special consideration IS needed 
		DECODE(max_score_accred_biod, TRIP_SCORE_BIODIVERSITY_ACC, TRIP_SCORE_BIODIVERSITY_ACC, 
		NVL(DECODE(min_score_accred_biod,		-1, -1,score_accred_biod), -1))		score_accred_biod,
        DECODE(parent_score_fair_trade, 1, 1,
        --Fair / Community trade - to represent the case where the whole product is Fair Trade - if the top level product is 100% FT (-> score = 1) then use that score - else average scores
        NVL(DECODE(min_score_fair_trade,        -1, -1,score_fair_trade_minus_parent), -1)) score_fair_trade,
		NVL(DECODE(min_score_renew_pack,		-1, -1,score_renew_pack), -1)		score_renew_pack,
		NVL(DECODE(min_score_whats_in_prod,		-1, -1,score_whats_in_prod), -1)	score_whats_in_prod,
		NVL(DECODE(min_score_water_in_prod,		-1, -1,score_water_in_prod), -1)	score_water_in_prod,
		NVL(DECODE(min_score_energy_in_prod,	-1, -1,score_energy_in_prod), -1)	score_energy_in_prod,
		NVL(DECODE(min_score_pack_opt,			-1, -1,score_pack_opt), -1)			score_pack_opt,
		-- 
		NVL(DECODE(min_score_recycled_pack,		-1, -1,score_recycled_pack), -1)	score_recycled_pack,
		NVL(DECODE(min_score_supp_management,	-1, -1,score_supp_management), -1)	score_supp_management,
		NVL(DECODE(min_score_trans_raw_mat,		-1, -1,score_trans_raw_mat), -1)	score_trans_raw_mat,
		NVL(DECODE(min_score_trans_to_boots,	-1, -1,score_trans_to_boots), -1)	score_trans_to_boots,
		NVL(DECODE(min_score_trans_packaging,	-1, -1,score_trans_packaging), -1)	score_trans_packaging,
		NVL(DECODE(min_score_trans_opt,			-1, -1,score_trans_opt), -1)		score_trans_opt,
		NVL(DECODE(min_score_energy_dist,		-1, -1,score_energy_dist), -1)		score_energy_dist,
		NVL(DECODE(min_score_water_use,			-1, -1,score_water_use), -1)		score_water_use,
		NVL(DECODE(min_score_energy_use,		-1, -1,score_energy_use), -1)		score_energy_use,
		NVL(DECODE(min_score_ancillary_req,		-1, -1,score_ancillary_req), -1)	score_ancillary_req,
		NVL(DECODE(min_score_prod_waste,		-1, -1,score_prod_waste), -1)		score_prod_waste,
		NVL(DECODE(min_score_recyclable_pack,	-1, -1,score_recyclable_pack), -1)	score_recyclable_pack,
		NVL(DECODE(min_score_recov_pack,		-1, -1,score_recov_pack), -1)		score_recov_pack
	INTO 
		v_score_nat_derived,
		v_score_chemicals,
		v_score_source_biod,
		v_score_accred_biod,
		v_score_fair_trade,
		v_score_renew_pack,
		v_score_whats_in_prod,
		v_score_water_in_prod,
		v_score_energy_in_prod,
		v_score_pack_opt,
		-- transit done above
		v_score_recycled_pack,
		v_score_supp_management,
		v_score_trans_raw_mat,
		v_score_trans_to_boots,
		v_score_trans_packaging,
		v_score_trans_opt,
		v_score_energy_dist,
		v_score_water_use,
		v_score_energy_use,
		v_score_ancillary_req,
		v_score_prod_waste,
		v_score_recyclable_pack,
		v_score_recov_pack
	FROM (
		SELECT  
			COUNT(*) items_in_tree, 
			COUNT(DECODE(is_parent, 1, NULL, 0)) children_in_tree,
			MIN(score_nat_derived) 		min_score_nat_derived,		AVG(score_nat_derived) score_nat_derived,
			MIN(score_chemicals) 		min_score_chemicals,		MAX(score_chemicals) score_chemicals,
			MIN(score_source_biod) 		min_score_source_biod,		MAX(score_source_biod) score_source_biod,
			MIN(score_accred_biod)		min_score_accred_biod,		AVG(score_accred_biod) score_accred_biod, MAX(score_accred_biod) max_score_accred_biod,
            -- we want the avg fairtrade score of the children - the parent is only used if it's score is 100% FT 
            MIN(score_fair_trade)        min_score_fair_trade,        (SUM(DECODE(is_parent, 1, NULL, score_fair_trade))/COUNT(DECODE(is_parent, 1, NULL, 0))) score_fair_trade_minus_parent, 
            MAX(parent_score_fair_trade) parent_score_fair_trade,
            -- Fairtrade score END 
			MIN(score_renew_pack)		min_score_renew_pack,		AVG(score_renew_pack) score_renew_pack,
			MIN(score_whats_in_prod)	min_score_whats_in_prod,	AVG(score_whats_in_prod) score_whats_in_prod,
			MIN(score_water_in_prod)	min_score_water_in_prod,	MAX(score_water_in_prod) score_water_in_prod,
			MIN(score_energy_in_prod)	min_score_energy_in_prod,	MAX(score_energy_in_prod) score_energy_in_prod,
			MIN(score_pack_opt)			min_score_pack_opt,			MAX(score_pack_opt) score_pack_opt,
			MIN(score_recycled_pack)	min_score_recycled_pack,	AVG(score_recycled_pack) score_recycled_pack,
			MIN(score_supp_management)	min_score_supp_management,	MAX(score_supp_management) score_supp_management,
			MIN(score_trans_raw_mat)	min_score_trans_raw_mat,	AVG(score_trans_raw_mat) score_trans_raw_mat,
			MIN(score_trans_to_boots)	min_score_trans_to_boots,	AVG(score_trans_to_boots) score_trans_to_boots,
			MIN(score_trans_packaging)	min_score_trans_packaging,	AVG(score_trans_packaging) score_trans_packaging,
			MIN(score_trans_opt)		min_score_trans_opt,		AVG(score_trans_opt) score_trans_opt,
			MIN(score_energy_dist)		min_score_energy_dist,		AVG(score_energy_dist) score_energy_dist,
			MIN(score_water_use)		min_score_water_use,		MAX(score_water_use) score_water_use,
			MIN(score_energy_use)		min_score_energy_use,		MAX(score_energy_use) score_energy_use,
			MIN(score_ancillary_req)	min_score_ancillary_req,	MAX(score_ancillary_req) score_ancillary_req,
			MIN(score_prod_waste)		min_score_prod_waste,		AVG(score_prod_waste) score_prod_waste,
			MIN(score_recyclable_pack)	min_score_recyclable_pack,	AVG(score_recyclable_pack) score_recyclable_pack,
			MIN(score_recov_pack)		min_score_recov_pack,		AVG(score_recov_pack) score_recov_pack
		FROM (
			-- the product in question 
			SELECT  gtp.product_id, gt_product_class_id, gtp.revision_id, 1 is_parent, 
					DECODE(has_ingredients, 1, score_nat_derived,		NULL) 	score_nat_derived,
					DECODE(has_ingredients, 1, score_chemicals, 		NULL)	score_chemicals,
					DECODE(has_ingredients, 1, score_source_biod, 		NULL) 	score_source_biod,
					DECODE(has_ingredients, 1, score_accred_biod, 		NULL) 	score_accred_biod,
					score_fair_trade, score_fair_trade parent_score_fair_trade,
					DECODE(has_packaging, 	1, score_renew_pack, 		NULL)	score_renew_pack,
					DECODE(has_ingredients, 1, score_whats_in_prod, 	NULL) 	score_whats_in_prod,
					DECODE(has_ingredients, 1, score_water_in_prod, 	NULL) 	score_water_in_prod,
					DECODE(has_ingredients, 1, score_energy_in_prod, 	NULL)	score_energy_in_prod,
					DECODE(has_packaging, 	1, score_pack_opt, 			NULL)	score_pack_opt,
					DECODE(has_packaging, 	1, score_recycled_pack, 	NULL) 	score_recycled_pack,
					score_supp_management,
					score_trans_raw_mat,
					score_trans_to_boots,
					score_trans_packaging,
					score_trans_opt,
					score_energy_dist,
					score_water_use,
					score_energy_use,
					DECODE(has_ingredients, 1, score_ancillary_req, 	NULL) 	score_ancillary_req,
					DECODE(has_ingredients, 1, score_prod_waste, 		NULL) 	score_prod_waste,
					DECODE(has_packaging, 	1, score_recyclable_pack, 	NULL)	score_recyclable_pack,
					DECODE(has_packaging, 	1, score_recov_pack,		NULL) 	score_recov_pack
			  FROM  gt_scores s, gt_product_rev gtp
			 WHERE gtp.product_id = s.product_id
			   AND gtp.revision_id = s.revision_id
			   AND gtp.product_id = in_product_id 
			   AND gtp.revision_id = in_revision_id
			UNION
			-- latest revision of the top level items children 
			SELECT  gtp.product_id, gt_product_class_id, gtp.revision_id, 0 is_parent, 
					DECODE(has_ingredients, 1, score_nat_derived,		NULL) 	score_nat_derived,
					DECODE(has_ingredients, 1, score_chemicals, 		NULL)	score_chemicals,
					DECODE(has_ingredients, 1, score_source_biod, 		NULL) 	score_source_biod,
					DECODE(has_ingredients, 1, score_accred_biod, 		NULL) 	score_accred_biod,
					score_fair_trade, NULL, -- FT score for parent only 
					DECODE(has_packaging, 	1, score_renew_pack, 		NULL)	score_renew_pack,
					DECODE(has_ingredients, 1, score_whats_in_prod, 	NULL) 	score_whats_in_prod,
					DECODE(has_ingredients, 1, score_water_in_prod, 	NULL) 	score_water_in_prod,
					DECODE(has_ingredients, 1, score_energy_in_prod, 	NULL)	score_energy_in_prod,
					DECODE(has_packaging, 	1, score_pack_opt, 			NULL)	score_pack_opt,
					DECODE(has_packaging, 	1, score_recycled_pack, 	NULL) 	score_recycled_pack,
					score_supp_management,
					score_trans_raw_mat,
					NULL, -- USE PARENT score_trans_to_boots,
					NULL, -- USE PARENT score_trans_packaging,
					NULL, -- USE PARENT score_trans_opt,
					NULL, -- USE PARENT score_energy_dist,
					score_water_use,
					score_energy_use,
					DECODE(has_ingredients, 1, score_ancillary_req, 	NULL) 	score_ancillary_req,
					DECODE(has_ingredients, 1, score_prod_waste, 		NULL) 	score_prod_waste,
					DECODE(has_packaging, 	1, score_recyclable_pack, 	NULL)	score_recyclable_pack,
					DECODE(has_packaging, 	1, score_recov_pack,		NULL) 	score_recov_pack
			  FROM gt_scores s, gt_product_rev gtp
			 WHERE gtp.product_id = s.product_id
			   AND gtp.revision_id = s.revision_id
			   AND (gtp.product_id, gtp.revision_id) IN (
				SELECT product_id, revision_id 
				FROM (    
					SELECT link_product_id FROM gt_link_product WHERE product_id = in_product_id AND revision_id = in_revision_id
				) lp, (
					SELECT product_id, MAX(revision_id) revision_id FROM product_revision GROUP BY product_id
				) mpr
				WHERE lp.link_product_id = mpr.product_id
			)
		) 
	);
	

	BEGIN
		INSERT INTO gt_scores_combined 
			(product_id, 
			revision_id, 
			score_nat_derived,
			score_chemicals,
			score_source_biod,			
			score_accred_biod,			
			score_fair_trade,			
			score_renew_pack,			
			score_whats_in_prod,			
			score_water_in_prod,			
			score_energy_in_prod,			
			score_pack_impact,			
			score_pack_opt,			
			score_recycled_pack,			
			score_supp_management,			
			score_trans_raw_mat,			
			score_trans_to_boots,			
			score_trans_packaging,			
			score_trans_opt,		
			score_energy_dist,			
			score_water_use,			
			score_energy_use,			
			score_ancillary_req,			
			score_prod_waste,			
			score_recyclable_pack,			
			score_recov_pack)		
		VALUES
		 	(in_product_id, 
			in_revision_id, 
			v_score_nat_derived,
			v_score_chemicals,
			v_score_source_biod,
			v_score_accred_biod,
			v_score_fair_trade,
			v_score_renew_pack,
			v_score_whats_in_prod,
			v_score_water_in_prod,
			v_score_energy_in_prod,
			v_score_pack_impact,
			v_score_pack_opt,
			v_score_recycled_pack,
			v_score_supp_management,
			v_score_trans_raw_mat,
			v_score_trans_to_boots,
			v_score_trans_packaging,
			v_score_trans_opt,
			v_score_energy_dist,
			v_score_water_use,
			v_score_energy_use,
			v_score_ancillary_req,
			v_score_prod_waste,
			v_score_recyclable_pack,
			v_score_recov_pack);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
		
			UPDATE gt_scores_combined SET
				score_nat_derived		= 	v_score_nat_derived,
				score_chemicals			=	v_score_chemicals,
				score_source_biod		=	v_score_source_biod,
				score_accred_biod		=	v_score_accred_biod,
				score_fair_trade		=	v_score_fair_trade,
				score_renew_pack		=	v_score_renew_pack,
				score_whats_in_prod		=	v_score_whats_in_prod,
				score_water_in_prod		=	v_score_water_in_prod,
				score_energy_in_prod	=	v_score_energy_in_prod,
				score_pack_impact		=	v_score_pack_impact,
				score_pack_opt			=	v_score_pack_opt,
				score_recycled_pack		=	v_score_recycled_pack,
				score_supp_management	=	v_score_supp_management,
				score_trans_raw_mat		=	v_score_trans_raw_mat,
				score_trans_to_boots	=	v_score_trans_to_boots,
				score_trans_packaging	=	v_score_trans_packaging,
				score_trans_opt			=	v_score_trans_opt,
				score_energy_dist		=	v_score_energy_dist,
				score_water_use			=	v_score_water_use,
				score_energy_use		=	v_score_energy_use,
				score_ancillary_req		=	v_score_ancillary_req,
				score_prod_waste		=	v_score_prod_waste,
				score_recyclable_pack	=	v_score_recyclable_pack,
				score_recov_pack		=	v_score_recov_pack
			WHERE product_id 		= 	in_product_id
			AND revision_id 		= 	in_revision_id;
	END;

END;
 
---------------------------------------------
-- Sustainably Sourced
---------------------------------------------

PROCEDURE GetScoreSustainableGroup(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_cnt					NUMBER;
	v_type_id				gt_product_type.gt_product_type_id%TYPE;
	v_matched_type_id		gt_product_type.gt_product_type_id%TYPE;
	v_range_id				gt_product_answers.gt_product_range_id%TYPE;
	v_matched_range_id		gt_product_answers.gt_product_range_id%TYPE;
	v_app_sid				product.app_sid%TYPE;
BEGIN
	
	--Naturally Derived Ingredients
	--Chemicals - Environmental Risk
	--Biodiversity
	--Biodiversity Source / Accreditation
	--Fair / Community trade
	--Renewable Packaging
	
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading product with id '||in_product_id);
	END IF;
	
	SELECT app_sid INTO v_app_sid FROM product WHERE product_id = in_product_id;
	
	GetBestMatchTargetScore(in_act_id, in_product_id, in_revision_id, v_type_id, v_matched_type_id, v_range_id, v_matched_range_id);

	OPEN out_cur FOR
		-- Dickie's page expects values in this form so it can be generic
		SELECT 'Sustainably Sourced' group_name, MAX_SCORE_SUSTAINABLE max_score,
		       DECODE(rn, 1, 'Naturally Derived Ingredients', 2, 'Chemicals - Environmental Risk', 3, 'Biodiversity', 4, 'Biodiversity Source / Accreditation', 5, 'Fair / Community Trade', 6, 'Renewable Packaging') score_label,
			   DECODE(rn, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 1) score_relates_to_pkg,
			   DECODE(rn, 1, 1, 2, 1, 3, 1, 4, 1, 5, 0, 6, 0) score_relates_to_ingred,
		       DECODE(rn, 1, gt.score_nat_derived, 2, gt.score_chemicals, 3, gt.score_source_biod, 4, gt.score_accred_biod, 5, gt.score_fair_trade, 6, gt.score_renew_pack) score_value,
	           DECODE(rn, 1, -1, 2, TRIP_SCORE_CHEM_HAZ, 3, TRIP_SCORE_BIODIVERSITY, 4, TRIP_SCORE_BIODIVERSITY_ACC, 5, -1, 6, -1) trip_score_value,
               NVL(DECODE(rn, 1, gtf.score_nat_derived, 2, gtf.score_chemicals, 3, gtf.score_source_biod, 4, gtf.score_accred_biod, 5, gtf.score_fair_trade, 6, gtf.score_renew_pack), -1) gift_score_value,
               NVL(decode(rn, 1, p.min_score_nat_derived, 2, p.min_score_chemicals, 3, p.min_score_source_biod, 4, p.min_score_accred_biod, 5, p.min_score_fair_trade, 6, p.min_score_renew_pack), -1) min_target_value, 
               NVL(decode(rn, 1, p.max_score_nat_derived, 2, p.max_score_chemicals, 3, p.max_score_source_biod, 4, p.max_score_accred_biod, 5, p.max_score_fair_trade, 6, p.max_score_renew_pack), -1) max_target_value,
			   DECODE(MAX(NVL(decode(rn, 1, p.min_score_nat_derived, 2, p.min_score_chemicals, 3, p.min_score_source_biod, 4, p.min_score_accred_biod, 5, p.min_score_fair_trade, 6, p.min_score_renew_pack), -1)) OVER (), -1, 0, 1) use_min_target_value, -- use if any are set (>-1)
			   DECODE(MAX(NVL(decode(rn, 1, p.max_score_nat_derived, 2, p.max_score_chemicals, 3, p.max_score_source_biod, 4, p.max_score_accred_biod, 5, p.max_score_fair_trade, 6, p.max_score_renew_pack), -1)) OVER (), -1, 0, 1) use_max_target_value
        FROM (SELECT rownum rn FROM (SELECT 1 FROM dual GROUP BY cube (1, 2, 3)) WHERE rownum <= 6) r, (
                SELECT p.product_id, gts.* FROM 
                (
                	SELECT p.product_id, v_type_id gt_product_type_id, v_matched_range_id gt_product_range_id
                      FROM product p
                     WHERE p.product_id = in_product_id
                ) p, -- gets type and range id if present  - set to -1 otherwise 
                (
                	SELECT (NVL(gts.gt_product_range_id, -1)) nullable_range, gts.* FROM gt_target_scores gts WHERE gts.app_sid = v_app_sid
                ) gts  
                WHERE p.gt_product_type_id = gts.gt_product_type_id(+)  -- this will only match on correct type
                  AND p.gt_product_range_id = gts. nullable_range(+)     -- OK for null range to match
        ) p,   (
        	SELECT * FROM gt_scores WHERE product_id = in_product_id AND revision_id = in_revision_id
        ) gt, (
        	SELECT * FROM gt_scores_combined WHERE product_id = in_product_id AND revision_id = in_revision_id
        ) gtf
    	WHERE p.product_id = gt.product_id(+)
    	AND p.product_id = gtf.product_id(+);
        	
		
END;

PROCEDURE SetScoreSustainableGroup(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	in_score_nat_derived	IN gt_scores.score_nat_derived%TYPE,
	in_score_chemicals		IN gt_scores.score_chemicals%TYPE,
	in_score_source_biod	IN gt_scores.score_source_biod%TYPE,
	in_score_accred_biod	IN gt_scores.score_accred_biod%TYPE,
	in_score_fair_trade		IN gt_scores.score_fair_trade%TYPE,
	in_score_renew_pack		IN gt_scores.score_renew_pack%TYPE
)
AS
	v_max_revision_id				product_revision.revision_id%TYPE;
BEGIN
	
	--Naturally Derived Ingredients
	--Chemicals - Environmental Risk
	--Biodiversity
	--Biodiversity Source / Accreditation
	--Fair / Community trade
	--Renewable Packaging

	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
    
    -- only log if latest revision
    IF v_max_revision_id = in_revision_id THEN 
		FOR r IN (
	        SELECT 	score_nat_derived,	
					score_chemicals,		
					score_source_biod,	
					score_accred_biod,	
					score_fair_trade,	
					score_renew_pack
 		   FROM gt_scores s, product_revision pr
	      WHERE pr.product_id=s.PRODUCT_ID (+)
	        AND pr.REVISION_ID = s.revision_id(+)
	        AND pr.product_id = in_product_id
			AND pr.revision_id = v_max_revision_id
		)
		LOOP
			-- actually only ever going to be single row as product id and revision id are PK
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_NAT_DERIVED, r.score_nat_derived, in_score_nat_derived);
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_CHEMICALS, r.score_chemicals, in_score_chemicals);
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_SOURCE_BIOD, r.score_source_biod, in_score_source_biod);		
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_ACCRED_BIOD, r.score_accred_biod, in_score_accred_biod);		
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_FAIR_TRADE, r.score_fair_trade, in_score_fair_trade);
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_RENEW_PACK, r.score_renew_pack, in_score_renew_pack);
				
		END LOOP;
	END IF;

	BEGIN
		INSERT INTO gt_scores 
			(product_id, revision_id, score_nat_derived, score_chemicals, score_source_biod, 
			score_accred_biod, score_fair_trade, score_renew_pack) 
		VALUES
		 	(in_product_id, in_revision_id, in_score_nat_derived, in_score_chemicals, in_score_source_biod, 
			in_score_accred_biod, in_score_fair_trade, in_score_renew_pack);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
		
			UPDATE gt_scores SET
				score_nat_derived	=	in_score_nat_derived,
				score_chemicals		=	in_score_chemicals,
				score_source_biod	=	in_score_source_biod,
				score_accred_biod	=	in_score_accred_biod,
				score_fair_trade	=	in_score_fair_trade,
				score_renew_pack	=	in_score_renew_pack
			WHERE product_id 		= 	in_product_id
			AND revision_id 		= 	in_revision_id;
	END;
	
END;

/*
PROCEDURE SetGiftScoreSustainableGroup(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	in_score_nat_derived	IN gt_scores.score_nat_derived%TYPE,
	in_score_chemicals		IN gt_scores.score_chemicals%TYPE,
	in_score_source_biod	IN gt_scores.score_source_biod%TYPE,
	in_score_accred_biod	IN gt_scores.score_accred_biod%TYPE,
	in_score_fair_trade		IN gt_scores.score_fair_trade%TYPE,
	in_score_renew_pack		IN gt_scores.score_renew_pack%TYPE
)
AS
BEGIN
	
	--Naturally Derived Ingredients
	--Chemicals - Environmental Risk
	--Biodiversity
	--Biodiversity Source / Accreditation
	--Fair / Community trade
	--Renewable Packaging

	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	BEGIN
		INSERT INTO gt_scores_gift 
			(product_id, revision_id, score_nat_derived, score_chemicals, score_source_biod, 
			score_accred_biod, score_fair_trade, score_renew_pack) 
		VALUES
		 	(in_product_id, in_revision_id, in_score_nat_derived, in_score_chemicals, in_score_source_biod, 
			in_score_accred_biod, in_score_fair_trade, in_score_renew_pack);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
		
			UPDATE gt_scores_gift SET
				score_nat_derived	=	in_score_nat_derived,
				score_chemicals		=	in_score_chemicals,
				score_source_biod	=	in_score_source_biod,
				score_accred_biod	=	in_score_accred_biod,
				score_fair_trade	=	in_score_fair_trade,
				score_renew_pack	=	in_score_renew_pack
			WHERE product_id 		= 	in_product_id
			AND revision_id 		= 	in_revision_id;
	END;
	
END;
*/

PROCEDURE SetProfileSustainableGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
    in_renewable_pack_pct       IN gt_profile.renewable_pack_pct%TYPE
)
AS
BEGIN
	
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	BEGIN
		INSERT INTO gt_profile 
			(product_id, revision_id, renewable_pack_pct) 
		VALUES
			(in_product_id, in_revision_id, NVL(in_renewable_pack_pct, -1)) ;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE gt_profile SET
				renewable_pack_pct		= NVL(in_renewable_pack_pct, -1)     
			WHERE product_id 			= in_product_id
			AND revision_id 			= in_revision_id;
	END;
	
END;

PROCEDURE CalcScoreSustainableGroup(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN security_pkg.T_SID_ID,
	in_revision_id			IN product_revision.revision_id%TYPE
)
AS
	v_product_class			gt_product_class.gt_product_class_id%TYPE;
	
	-- 1
	v_score_nat_derived		gt_scores.score_nat_derived%TYPE;
	-- 2
	v_score_chemicals		gt_scores.score_chemicals%TYPE;
	-- 3
	v_score_source_biod		gt_scores.score_source_biod%TYPE;
	-- 4
	v_score_accred_biod		gt_scores.score_accred_biod%TYPE;
	-- 5
	v_score_fair_trade		gt_scores.score_fair_trade%TYPE;
	v_fair_trade_total_pct	NUMBER(6,3);
	-- 6
	v_pct_renewable			NUMBER(6,3);
	v_score_renew_pack		gt_scores.score_renew_pack%TYPE;
	
	/*-- giftpack
	-- 1
	v_gift_score_nat_derived		gt_scores_gift.score_nat_derived%TYPE;
	min_gift_score_nat_derived		gt_scores_gift.score_nat_derived%TYPE;
	-- 2
	v_gift_score_chemicals			gt_scores_gift.score_chemicals%TYPE;
	min_gift_score_chemicals			gt_scores_gift.score_chemicals%TYPE;
	-- 3
	v_gift_score_source_biod		gt_scores_gift.score_source_biod%TYPE;
	min_gift_score_source_biod		gt_scores_gift.score_source_biod%TYPE;
	-- 4
	v_gift_score_accred_biod		gt_scores_gift.score_accred_biod%TYPE;
	min_gift_score_accred_biod		gt_scores_gift.score_accred_biod%TYPE;
	-- 5
	v_gift_score_fair_trade			gt_scores_gift.score_fair_trade%TYPE;
	min_gift_score_fair_trade			gt_scores_gift.score_fair_trade%TYPE;
	-- 6
	v_gift_score_renew_pack			gt_scores_gift.score_renew_pack%TYPE;
	min_gift_score_renew_pack			gt_scores_gift.score_renew_pack%TYPE;*/
	
BEGIN

	-- find product class up front
	v_product_class := product_info_pkg.GetProductClassId(in_act_id, in_product_id, in_revision_id);

	-- 1. Naturally Derived Ingredients
	-- actually gets a couple of values back here too used in 3. Biodiversity 
	model_pd_pkg.CalcNatDerivedIngScore(in_product_id, v_product_class, in_revision_id, v_score_nat_derived);

	-- 2. Chemicals - Environmental Risk
	model_pd_pkg.CalcChemRiskScore(in_product_id, v_product_class, in_revision_id, v_score_chemicals);

	
	-- 3. Biodiversity 
	-- 4. Biodiversity Source / Accreditation
		-- do together as lots of overlap

	model_pd_pkg.CalcBiodiversityScores(in_product_id, v_product_class, in_revision_id, v_score_source_biod, v_score_accred_biod);

	-- 5. Fair / Community trade
	-- LOGIC: score = sum of below
	-- 2 * %Ingredients from non independently certified community trade project / 100
	-- 1 * %Fairtrade Ingredients / 100
	-- 2 * %Ingredients product from other fair trade scheme (eg IFAT) or working to the principles of fairtrade / 100
	-- 5 * %Ingredients not covered by a fair trade or community trade scheme / 100
    SELECT 
		(NVL((2*community_trade_pct),0)+NVL((1*fairtrade_pct),0)+NVL((2*other_fair_pct),0)+NVL((5*not_fair_pct),0))/100 score_fair_trade,
		NVL(community_trade_pct,0)+NVL(fairtrade_pct,0)+NVL(other_fair_pct,0)+NVL(not_fair_pct,0) fair_trade_total_pct
    INTO v_score_fair_trade, v_fair_trade_total_pct
    FROM gt_product_answers pa, all_product p
        WHERE p.product_id = pa.product_id(+)
        AND p.product_id = in_product_id
        AND ((pa.revision_id = in_revision_id) OR (pa.revision_id IS NULL));

	 -- not set or not complete set of pct
	IF v_fair_trade_total_pct<100 THEN 
		v_score_fair_trade := -1; 
	END IF;

	-- 6. Renewable Packaging
	-- LOGIC: 
	-- weight = "sum of weight of packaging parts marked as renewable"
	-- % renewable = renewable weight / total weight of packaging * 100%
	-- % renewable=0 						-> 5
	-- % renewable<=25			 			-> 4
	-- % renewable<=50			 			-> 3
	-- % renewable<=75			 			-> 2
	-- % renewable>75			 			-> 1
    SELECT NVL(100 * SUM(DECODE(mat.renewable, 1, weight_grams, 0)) / SUM(weight_grams),-1) pct_renewable
	INTO v_pct_renewable
	FROM gt_pack_item pi,
	(
        SELECT smm.* FROM gt_pack_material_type pmt, gt_pack_shape_type pst, gt_shape_material_mapping smm
        WHERE smm.gt_pack_material_type_id = pmt.gt_pack_material_type_id
        AND smm.gt_pack_shape_type_id = pst.gt_pack_shape_type_id
	) mat
	WHERE pi.gt_pack_material_type_id = mat.gt_pack_material_type_id
	AND pi.gt_pack_shape_type_id = mat.gt_pack_shape_type_id
	AND pi.product_id = in_product_id
	AND pi.revision_id = in_revision_id;

	
	CASE 
	  WHEN v_pct_renewable<0 THEN v_score_renew_pack := -1; -- not set
	  WHEN v_pct_renewable=0 THEN v_score_renew_pack := 5;
	  WHEN  v_pct_renewable<=25 THEN v_score_renew_pack := 4;
	  WHEN v_pct_renewable<=50 THEN v_score_renew_pack := 3;
	  WHEN v_pct_renewable<=75 THEN v_score_renew_pack := 2;
	  WHEN v_pct_renewable>75 THEN v_score_renew_pack := 1;
	END CASE;

	
	SetScoreSustainableGroup(in_act_id, in_product_id, in_revision_id, v_score_nat_derived, v_score_chemicals, v_score_source_biod,	v_score_accred_biod, v_score_fair_trade, v_score_renew_pack);
	SetProfileSustainableGroup(in_act_id, in_product_id, in_revision_id, v_pct_renewable);

	
	/*-- now calculate giftpack scores (if needed
	SELECT 
		--1
		SUM(score_nat_derived * cnt)/SUM(cnt), MIN(NVL(score_nat_derived,-1)),
		--2 
		MAX(score_chemicals), MIN(NVL(score_chemicals,-1)), 
		-- 3
		MAX(score_source_biod), MIN(NVL(score_source_biod,-1)), 
		-- 4
		SUM(score_accred_biod * cnt)/SUM(cnt), MIN(NVL(score_accred_biod,-1)),	
		-- 5 
		MAX(score_fair_trade), MIN(NVL(score_fair_trade,-1)), 
		-- 6
		SUM(score_renew_pack * cnt)/SUM(cnt), MIN(NVL(score_renew_pack,-1))		
	INTO 
		v_gift_score_nat_derived, min_gift_score_nat_derived, 
		v_gift_score_chemicals, min_gift_score_chemicals,
		v_gift_score_source_biod, min_gift_score_source_biod, 
		v_gift_score_accred_biod, min_gift_score_accred_biod, 
		v_gift_score_fair_trade, min_gift_score_fair_trade, 
		v_gift_score_renew_pack, min_gift_score_renew_pack
    FROM 
    (
        SELECT p.product_id prod_id, gt.*, lp.cnt 
        FROM gt_scores gt, product p,
        (
            SELECT lp.LINK_PRODUCT_ID, count cnt 
            FROM gt_link_product lp 
            WHERE lp.PRODUCT_ID = in_product_id
            AND revision_id = in_revision_id
        ) lp
        WHERE p.product_id = gt.product_id(+)
        AND p.product_id = lp.LINK_PRODUCT_ID
        AND p.product_id IN 
        (
            SELECT link_product_id FROM gt_link_product 
            WHERE PRODUCT_ID = in_product_id
            AND revision_id = in_revision_id
        ) 
        AND ((revision_id IS NULL) OR (revision_id = (SELECT max(revision_id) FROM gt_scores WHERE product_id = p.product_id)))
        UNION
        SELECT p.product_id prod_id, gt.*, 1 cnt 
        FROM gt_scores gt, product p
        WHERE p.product_id = gt.product_id(+)
        AND p.PRODUCT_ID = in_product_id
        AND revision_id = in_revision_id
    );
	
	IF min_gift_score_nat_derived<0 THEN 
		v_gift_score_nat_derived := -1;
	END IF;
	IF min_gift_score_chemicals<0 THEN 
		v_gift_score_chemicals := -1;
	END IF;
	IF min_gift_score_source_biod<0 THEN 
		v_gift_score_source_biod := -1;
	END IF;
	IF min_gift_score_accred_biod<0 THEN 
		v_gift_score_accred_biod := -1;
	END IF;
	IF min_gift_score_fair_trade<0 THEN 
		v_gift_score_fair_trade := -1;
	END IF;
	IF min_gift_score_renew_pack<0 THEN 
		v_gift_score_renew_pack := -1;
	END IF;
	
	SetGiftScoreSustainableGroup(in_act_id, in_product_id, in_revision_id, v_gift_score_nat_derived, v_gift_score_chemicals, v_gift_score_source_biod,	v_gift_score_accred_biod, v_gift_score_fair_trade, v_gift_score_renew_pack);
	*/
	
	-- finally
--	GetScoreSustainableGroup(in_act_id, in_product_id, in_revision_id, out_cur);

END;

---------------------------------------------
-- Whats in the Product - formulation
---------------------------------------------

PROCEDURE GetScoreFormulationGroup(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_cnt					NUMBER;
	v_type_id				gt_product_type.gt_product_type_id%TYPE;
	v_matched_type_id		gt_product_type.gt_product_type_id%TYPE;
	v_range_id				gt_product_answers.gt_product_range_id%TYPE;
	v_matched_range_id		gt_product_answers.gt_product_range_id%TYPE;
	v_app_sid				product.app_sid%TYPE;
BEGIN
	
	-- Impact of Materials
	-- Water - Product
	-- Energy - Product
	-- Packaging - Impact
	-- Packaging - Optimisation
	-- Recycled Packaging

	
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading product with id '||in_product_id);
	END IF;
	
	
	SELECT app_sid INTO v_app_sid FROM product WHERE product_id = in_product_id;
	
	GetBestMatchTargetScore(in_act_id, in_product_id, in_revision_id, v_type_id, v_matched_type_id, v_range_id, v_matched_range_id);

	OPEN out_cur FOR
		-- Dickie's page expects values in this form so it can be generic
		SELECT 'Design and Manufacture' group_name, MAX_SCORE_FORMULATION max_score,
		       DECODE(rn, 1, 'Impact of Materials (Product and Packaging)', 2, 'Water - Contents Production', 3, 'Energy - Contents Production', 4, 'Packaging - Impact', 5, 'Packaging - Optimisation', 6, 'Recycled / Accredited Packaging') score_label,
			   DECODE(rn, 1, 0, 2, 0, 3, 0, 4, 1, 5, 1, 6, 1) score_relates_to_pkg,
			   DECODE(rn, 1, 1, 2, 1, 3, 1, 4, 0, 5, 0, 6, 0) score_relates_to_ingred,
		       DECODE(rn, 1, gt.score_whats_in_prod, 2, gt.score_water_in_prod, 3, gt.score_energy_in_prod, 4, gt.score_pack_impact, 5, gt.score_pack_opt, 6, gt.score_recycled_pack) score_value,
	           DECODE(rn, 1, -1, 2, -1, 3, -1, 4, TRIP_SCORE_PACK_IMPACT, 5, -1, 6, -1) trip_score_value,
		       NVL(DECODE(rn, 1, gtf.score_whats_in_prod, 2, gtf.score_water_in_prod, 3, gtf.score_energy_in_prod, 4, gtf.score_pack_impact, 5, gtf.score_pack_opt, 6, gtf.score_recycled_pack), -1) gift_score_value, 
		       NVL(decode(rn, 1, p.min_score_whats_in_prod, 2, p.min_score_water_in_prod, 3, p.min_score_energy_in_prod, 4, p.min_score_pack_impact, 5, p.min_score_pack_opt, 6, p.min_score_recycled_pack), -1) min_target_value,
		       NVL(decode(rn, 1, p.max_score_whats_in_prod, 2, p.max_score_water_in_prod, 3, p.max_score_energy_in_prod, 4, p.max_score_pack_impact, 5, p.max_score_pack_opt, 6, p.max_score_recycled_pack), -1) max_target_value,
			   DECODE(MAX(NVL(decode(rn, 1, p.min_score_whats_in_prod, 2, p.min_score_water_in_prod, 3, p.min_score_energy_in_prod, 4, p.min_score_pack_impact, 5, p.min_score_pack_opt, 6, p.min_score_recycled_pack), -1)) OVER (), -1, 0, 1) use_min_target_value, -- use if any are set (>-1)
			   DECODE(MAX(NVL(decode(rn, 1, p.max_score_whats_in_prod, 2, p.max_score_water_in_prod, 3, p.max_score_energy_in_prod, 4, p.max_score_pack_impact, 5, p.max_score_pack_opt, 6, p.max_score_recycled_pack), -1)) OVER (), -1, 0, 1) use_max_target_value
        FROM (SELECT rownum rn FROM (SELECT 1 FROM dual GROUP BY cube (1, 2, 3)) WHERE rownum <= 6) r, (
                SELECT p.product_id, gts.* FROM 
                (
                	SELECT p.product_id, v_type_id gt_product_type_id, v_matched_range_id gt_product_range_id
                      FROM product p
                     WHERE p.product_id = in_product_id
                ) p, -- gets type and range id if present  - set to -1 otherwise 
                (
                	SELECT (NVL(gts.gt_product_range_id, -1)) nullable_range, gts.* FROM gt_target_scores gts WHERE gts.app_sid = v_app_sid
                ) gts  
                WHERE p.gt_product_type_id = gts.gt_product_type_id(+)  -- this will only match on correct type
                  AND p.gt_product_range_id = gts. nullable_range(+)     -- OK for null range to match
        ) p,   (
        	SELECT * FROM gt_scores WHERE product_id = in_product_id AND revision_id = in_revision_id
        ) gt, (
        	SELECT * FROM gt_scores_combined WHERE product_id = in_product_id AND revision_id = in_revision_id
        ) gtf
    	WHERE p.product_id = gt.product_id(+)
    	AND p.product_id = gtf.product_id(+);
		
END;

PROCEDURE SetScoreFormulationGroup(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	in_score_whats_in_prod	IN gt_scores.score_whats_in_prod%TYPE,
	in_score_water_in_prod	IN gt_scores.score_water_in_prod%TYPE,
	in_score_energy_in_prod	IN gt_scores.score_energy_in_prod%TYPE,
	in_score_pack_impact	IN gt_scores.score_pack_impact%TYPE,
	in_score_pack_opt		IN gt_scores.score_pack_opt%TYPE,
	in_score_recycled_pack	IN gt_scores.score_recycled_pack%TYPE
)
AS
	v_max_revision_id				product_revision.revision_id%TYPE;
BEGIN
	
	-- Impact of Materials
	-- Water - Product
	-- Energy - Product
	-- Packaging - Impact
	-- Packaging - Optimisation
	-- Recycled Packaging
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	
	
    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
    
    -- only log if latest revision
    IF v_max_revision_id = in_revision_id THEN 
		FOR r IN (
	        SELECT 	score_whats_in_prod,	
					score_water_in_prod,	
					score_energy_in_prod,
					score_pack_impact,	
					score_pack_opt,		
					score_recycled_pack	
 		   FROM gt_scores s, product_revision pr
	      WHERE pr.product_id=s.PRODUCT_ID (+)
	        AND pr.REVISION_ID = s.revision_id(+)
	        AND pr.product_id = in_product_id
			AND pr.revision_id = v_max_revision_id
		)
		LOOP
			-- actually only ever going to be single row as product id and revision id are PK
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_WHATS_IN_PROD, r.score_whats_in_prod, in_score_whats_in_prod);
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_WATER_IN_PROD, r.score_water_in_prod, in_score_water_in_prod);
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_ENERGY_IN_PROD, r.score_energy_in_prod, in_score_energy_in_prod);
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_PACK_IMPACT, r.score_pack_impact, in_score_pack_impact);
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_PACK_OPT, r.score_pack_opt, in_score_pack_opt);		
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_RECYCLED_PACK, r.score_recycled_pack, in_score_recycled_pack);	
				
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_NON_SCORING, null, null);	
				
		END LOOP;
	END IF;

	BEGIN
		INSERT INTO gt_scores 
			(product_id, revision_id, score_whats_in_prod, score_water_in_prod, score_energy_in_prod, 
				score_pack_impact, score_pack_opt, score_recycled_pack) 
		VALUES
			(in_product_id, in_revision_id, in_score_whats_in_prod, in_score_water_in_prod, in_score_energy_in_prod, 
				in_score_pack_impact, in_score_pack_opt, in_score_recycled_pack) ;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
		
			UPDATE gt_scores SET
				score_whats_in_prod		=	in_score_whats_in_prod,
				score_water_in_prod		=	in_score_water_in_prod,
				score_energy_in_prod	=	in_score_energy_in_prod,
				score_pack_impact		=	in_score_pack_impact,
				score_pack_opt			=	in_score_pack_opt,
				score_recycled_pack		=	in_score_recycled_pack
			WHERE product_id 			= 	in_product_id
			AND 	revision_id			=   in_revision_id;
	END;
	
END;

/*PROCEDURE SetGiftScoreFormulationGroup(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	in_score_whats_in_prod	IN gt_scores.score_whats_in_prod%TYPE,
	in_score_water_in_prod	IN gt_scores.score_water_in_prod%TYPE,
	in_score_energy_in_prod	IN gt_scores.score_energy_in_prod%TYPE,
	in_score_pack_impact	IN gt_scores.score_pack_impact%TYPE,
	in_score_pack_opt		IN gt_scores.score_pack_opt%TYPE,
	in_score_recycled_pack	IN gt_scores.score_recycled_pack%TYPE
)
AS
BEGIN
	
	-- Impact of Materials
	-- Water - Product
	-- Energy - Product
	-- Packaging - Impact
	-- Packaging - Optimisation
	-- Recycled Packaging

	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	BEGIN
		INSERT INTO gt_scores_gift
			(product_id, revision_id, score_whats_in_prod, score_water_in_prod, score_energy_in_prod, 
				score_pack_impact, score_pack_opt, score_recycled_pack) 
		VALUES
			(in_product_id, in_revision_id, in_score_whats_in_prod, in_score_water_in_prod, in_score_energy_in_prod, 
				in_score_pack_impact, in_score_pack_opt, in_score_recycled_pack) ;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
		
			UPDATE gt_scores_gift SET
				score_whats_in_prod		=	in_score_whats_in_prod,
				score_water_in_prod		=	in_score_water_in_prod,
				score_energy_in_prod	=	in_score_energy_in_prod,
				score_pack_impact		=	in_score_pack_impact,
				score_pack_opt			=	in_score_pack_opt,
				score_recycled_pack		=	in_score_recycled_pack
			WHERE product_id 			= 	in_product_id
			AND 	revision_id			=   in_revision_id;
	END;
	
END;*/

PROCEDURE SetProfileFormulationGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id				IN product_revision.revision_id%TYPE,
    in_recycled_pack_cont_msg   IN gt_profile.recycled_pack_cont_msg%TYPE,
	in_score_pack_impact_raw	IN gt_scores.score_pack_impact%TYPE,
	in_pack_ei					IN gt_scores.score_whats_in_prod%TYPE,
	in_materials_ei				IN gt_scores.score_whats_in_prod%TYPE,
	in_trans_pack_ei			IN gt_scores.score_whats_in_prod%TYPE,
	in_score_water_raw_mat		IN gt_profile.score_water_raw_mat%TYPE,
	in_score_water_contained	IN gt_profile.score_water_contained%TYPE,
	in_score_water_mnfct		IN gt_profile.score_water_mnfct%TYPE,
	in_score_water_wsr 			IN gt_profile.score_water_wsr%TYPE
)
AS
	v_trans_recycled_pct			gt_profile.recycled_pct%TYPE := -1;
	v_sum_trans_weight				gt_profile.sum_trans_weight%TYPE := -1;
	v_num_packs_per_outer			NUMBER(10);
	v_num_rows						NUMBER(10);
BEGIN
	
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	BEGIN
		SELECT COUNT(*) -- find if there is an entry in the packaging answers table for this product
		INTO v_num_rows
		FROM gt_packaging_answers
		WHERE product_id = in_product_id
		AND revision_id = in_revision_id;
		
		IF v_num_rows = 1 THEN
			SELECT NVL(num_packs_per_outer, -1)
			  INTO v_num_packs_per_outer
			  FROM gt_packaging_answers
			 WHERE product_id = in_product_id
			   AND revision_id = in_revision_id;
			   
			IF v_num_packs_per_outer > 0 THEN
				SELECT COUNT(*) -- find if there are any transit packaging items for this product
				  INTO v_num_rows
				  FROM gt_trans_item
				 WHERE product_id = in_product_id
				   AND revision_id = in_revision_id;
				
				IF v_num_rows > 1 THEN
					SELECT SUM(weight_grams)
					  INTO v_sum_trans_weight
					  FROM gt_trans_item
					 WHERE product_id = in_product_id
					   AND revision_id = in_revision_id;
					   
				    SELECT SUM(weight_grams * pct_recycled) / v_sum_trans_weight
					  INTO v_trans_recycled_pct 
					  FROM gt_trans_item
					 WHERE product_id = in_product_id
					   AND revision_id = in_revision_id;
				END IF;
			END IF;
		END IF;
			   
		INSERT INTO gt_profile 
			(product_id, revision_id, recycled_pack_cont_msg, score_pack_impact_raw, pack_ei, materials_ei, trans_pack_ei, recycled_pct, sum_trans_weight, score_water_raw_mat, score_water_contained, score_water_mnfct, score_water_wsr) 
		VALUES
			(in_product_id, in_revision_id, in_recycled_pack_cont_msg, in_score_pack_impact_raw, in_pack_ei, in_materials_ei, in_trans_pack_ei, v_trans_recycled_pct, v_sum_trans_weight, in_score_water_raw_mat, in_score_water_contained, in_score_water_mnfct, in_score_water_wsr);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE gt_profile SET
				recycled_pack_cont_msg	= in_recycled_pack_cont_msg, 
				score_pack_impact_raw = in_score_pack_impact_raw,
				pack_ei = in_pack_ei,
				materials_ei = in_materials_ei,
				trans_pack_ei = in_trans_pack_ei,
				recycled_pct = v_trans_recycled_pct,
				sum_trans_weight = v_sum_trans_weight,
				score_water_raw_mat = in_score_water_raw_mat,
				score_water_mnfct = in_score_water_mnfct,
				score_water_wsr = in_score_water_wsr,
				score_water_contained = in_score_water_contained
			WHERE product_id 			= in_product_id
			AND revision_id				= in_revision_id;
	END;
	
END;

PROCEDURE CalcScoreFormulationGroup(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN security_pkg.T_SID_ID,
	in_revision_id			IN product_revision.revision_id%TYPE
)
AS

	v_product_class				gt_product_class.gt_product_class_id%TYPE;
	
	-- 1
    v_score_whats_in_prod		gt_scores.score_whats_in_prod%TYPE;
	---- some values for the gt_profile table returned by the CalcWhatsInProd procedure - the individual contributions of packaging and materials to the final whats in the product score for use in the product profile report
	v_pack_ei					gt_scores.score_whats_in_prod%TYPE;
	v_materials_ei				gt_scores.score_whats_in_prod%TYPE;
	v_trans_pack_ei				gt_scores.score_whats_in_prod%TYPE;
	v_sum_trans_weight			gt_profile.sum_trans_weight%TYPE;	
	-- 2    
    v_score_water_in_prod		gt_scores.score_water_in_prod%TYPE;
	-- 3
    v_score_energy_in_prod		gt_scores.score_energy_in_prod%TYPE;
	-- 4
	v_score_pack_impact			gt_scores.score_pack_impact%TYPE;
	v_score_pack_impact_raw		gt_scores.score_pack_impact%TYPE;
	-- 5
	v_score_pack_opt			gt_scores.score_pack_opt%TYPE;
	v_score_pack_opt_pt1		gt_scores.score_pack_opt%TYPE;
	v_score_pack_opt_pt2		gt_scores.score_pack_opt%TYPE;
	v_score_pack_opt_pt3		gt_scores.score_pack_opt%TYPE;
	v_product_volume 			gt_product_answers.product_volume%TYPE;
	v_vol_package				gt_packaging_answers.vol_package%TYPE;
	
	v_single_in_pack 			gt_packaging_answers.single_in_pack%TYPE;
	v_settle_in_transit 		gt_packaging_answers.settle_in_transit%TYPE;
	v_gt_gift_cont_type_id 		gt_packaging_answers.gt_gift_cont_type_id%TYPE;
	v_gt_pack_layers_type_id 	gt_packaging_answers.gt_pack_layers_type_id%TYPE;
	v_gt_prod_pack_occ		 	gt_packaging_answers.prod_pack_occupation%TYPE;
	
	-- 5 Ess req
	v_gt_ess_req_pack_risk		gt_packaging_answers.pack_risk%TYPE;
	v_gt_ess_req_pack_style		gt_packaging_answers.pack_style_type%TYPE;

	v_dbl_walled_jar_just				gt_packaging_answers.dbl_walled_jar_just%TYPE;
	v_contain_tablets_just				gt_packaging_answers.contain_tablets_just%TYPE;
	v_tablets_in_blis_tray_just			gt_packaging_answers.tablets_in_blister_tray%TYPE;
	v_carton_gift_box_just				gt_packaging_answers.carton_gift_box_just%TYPE;
	v_carton_gift_box_vacuum_form		gt_packaging_answers.carton_gift_box_vacuum_form%TYPE;
	v_carton_gift_box_clear_win			gt_packaging_answers.carton_gift_box_clear_win%TYPE;
	v_carton_gift_box_sleeve			gt_packaging_answers.carton_gift_box_sleeve%TYPE;
	v_just_report_exp_present 			NUMBER(1);
	
	v_ess_req_other_score		NUMBER(10,2);						
	
	v_pt2_req					NUMBER;
	
	-- 6
	v_pack_item_count			NUMBER;
	v_score_recycled_pack		gt_scores.score_recycled_pack%TYPE;
	v_recycled_pack_cont_msg 	gt_profile.recycled_pack_cont_msg%TYPE;
	
	-- water sub scores that need to get stored in the gt_profile table
	v_score_water_raw_mat		gt_profile.score_water_raw_mat%TYPE;
	v_score_water_contained		gt_profile.score_water_contained%TYPE;
	v_score_water_mnfct			gt_profile.score_water_mnfct%TYPE;
	v_score_water_wsr			gt_profile.score_water_wsr%TYPE;
BEGIN

	-- find product class up front
	v_product_class := product_info_pkg.GetProductClassId(in_act_id, in_product_id, in_revision_id);
	
    -- get as much up front as possible        
    SELECT 
    -- 5 pt 1  
    NVL(pka.single_in_pack,-1), NVL(pka.settle_in_transit,-1), NVL(pka.gt_gift_cont_type_id,-1), NVL(pka.gt_pack_layers_type_id,-1), NVL(pka.prod_pack_occupation, -1), 
	-- 5 pt3
	NVL(pack_risk, -1), NVL(pack_style_type, -1), 
	NVL(pka.dbl_walled_jar_just, 0), NVL(pka.contain_tablets_just, 0), NVL(pka.tablets_in_blister_tray, 0), NVL(pka.carton_gift_box_just, 0), NVL(pka.carton_gift_box_vacuum_form, -1), 
	NVL(pka.carton_gift_box_clear_win, -1), NVL(pka.carton_gift_box_sleeve, -1), NVL2(LENGTH(just_report_explanation),1,0),
		CASE
			WHEN (NVL2(LENGTH(other_prod_protection_just),1,0)+
				NVL2(LENGTH(other_pack_manu_proc_just),1,0)+ 
				NVL2(LENGTH(other_pack_fill_proc_just),3,0)+			
				NVL2(LENGTH(other_logistics_just),3,0)+				
				NVL2(LENGTH(other_prod_present_market_just),3,0)+	
				NVL2(LENGTH(other_consumer_accept_just),3,0)+		
				NVL2(LENGTH(other_prod_info_just),3,0)+				
				NVL2(LENGTH(other_prod_safety_just),1,0)+			
				NVL2(LENGTH(other_prod_legislation_just),2,0)+	
				NVL2(LENGTH(other_issues_just),3,0)) = 0 THEN 0 -- avoid div by 0
			ELSE 
				(NVL2(LENGTH(other_prod_protection_just),1,0)+
				NVL2(LENGTH(other_pack_manu_proc_just),1,0)+ 
				NVL2(LENGTH(other_pack_fill_proc_just),3,0)+			
				NVL2(LENGTH(other_logistics_just),3,0)+				
				NVL2(LENGTH(other_prod_present_market_just),3,0)+	
				NVL2(LENGTH(other_consumer_accept_just),3,0)+		
				NVL2(LENGTH(other_prod_info_just),3,0)+				
				NVL2(LENGTH(other_prod_safety_just),1,0)+			
				NVL2(LENGTH(other_prod_legislation_just),2,0)+	
				NVL2(LENGTH(other_issues_just),3,0)) /
				(NVL2(LENGTH(other_prod_protection_just),1,0)+
				NVL2(LENGTH(other_pack_manu_proc_just),1,0)+ 
				NVL2(LENGTH(other_pack_fill_proc_just),1,0)+			
				NVL2(LENGTH(other_logistics_just),1,0)+				
				NVL2(LENGTH(other_prod_present_market_just),1,0)+	
				NVL2(LENGTH(other_consumer_accept_just),1,0)+		
				NVL2(LENGTH(other_prod_info_just),1,0)+				
				NVL2(LENGTH(other_prod_safety_just),1,0)+			
				NVL2(LENGTH(other_prod_legislation_just),1,0)+	
				NVL2(LENGTH(other_issues_just),1,0))
		END,
	-- 5 pt 2 
    NVL(pa.product_volume,-1) product_volume, NVL(pka.vol_package,-1) vol_package
    INTO v_single_in_pack, v_settle_in_transit, v_gt_gift_cont_type_id, v_gt_pack_layers_type_id, v_gt_prod_pack_occ, v_gt_ess_req_pack_risk, v_gt_ess_req_pack_style, 
	v_dbl_walled_jar_just, v_contain_tablets_just, v_tablets_in_blis_tray_just, v_carton_gift_box_just, v_carton_gift_box_vacuum_form, v_carton_gift_box_clear_win, 
	v_carton_gift_box_sleeve, v_just_report_exp_present, v_ess_req_other_score, 
	v_product_volume, v_vol_package
    FROM gt_product_answers pa, gt_packaging_answers pka, all_product p
        WHERE p.product_id = pa.product_id(+)
        AND p.product_id = pka.product_id(+)
        AND p.product_id = in_product_id
        AND ((pa.revision_id = in_revision_id) OR (pa.revision_id IS NULL))
        AND ((pka.revision_id = in_revision_id) OR (pka.revision_id IS NULL));
    		
		
	-- 1. Impact of Materials
	model_pd_pkg.CalcWhatsInProdScore(in_product_id, v_product_class, in_revision_id, v_score_whats_in_prod, v_pack_ei, v_materials_ei, v_trans_pack_ei);

	-- 2. Water in making product 
	-- 3. Energy in making product
	model_pd_pkg.CalcWaterEnergyManfctScore(in_act_id, in_product_id, v_product_class, in_revision_id, v_score_water_in_prod, v_score_energy_in_prod, v_score_water_raw_mat, v_score_water_contained, v_score_water_mnfct, v_score_water_wsr);
	
	-- 4. Packaging impact
	model_pd_pkg.CalcPackImpactScore(in_product_id, v_product_class, in_revision_id, v_score_pack_impact, v_score_pack_impact_raw);

	-- 5. Packaging optimisation
	-- LOGIC: There are 3 components 
		-- Part 1: the gateway scores
		-- Part 2: the ratio of product volume to outer packaging volume
		-- Part 3: the essential packaging requirements score
		
	-- If the essential pack risk is Low - then score = Part 1 + Part 2
	-- If the essential pack risk is High - then score = Part 3 + Part 2
	
	-- Part 1:
	-- If any of the below are true then basic score = 1
	--		Single product = NO
	--		Settle in transit = YES - less than 25% headspace 
	--		Reusable container = YES - displayed closed
	--		Layers of packaging = 2 layers
	-- 		Product occupies less than 75% space in pack = YES
	
	-- Add 1 to Part 1 score if any of the below are true
	--		Settle in transit = YES - greater than 25% headspace 		
	--		Reusable container = YES - displayed open
	--		Layers of packaging = 3 layers or more OR double walled jar
	
	v_score_pack_opt_pt1:=-1;
	
	IF ((v_single_in_pack>=0) AND (v_settle_in_transit>=0) AND (v_gt_gift_cont_type_id>=0) AND (v_gt_pack_layers_type_id>=0) AND (v_gt_prod_pack_occ>=0)) THEN 
		v_score_pack_opt_pt1:=0;
		IF ((v_single_in_pack=0) OR (v_settle_in_transit=PACK_SETTLE_YES_LESS_25_PCT) OR (v_gt_gift_cont_type_id=PACK_REUSEABLE_YES_CLOSED) OR (v_gt_pack_layers_type_id=PACK_LAYERS_2) OR (v_gt_prod_pack_occ=1)) THEN
			v_score_pack_opt_pt1:=1;
		END IF;
		
		IF ((v_settle_in_transit=PACK_SETTLE_YES_MORE_25_PCT) OR (v_gt_gift_cont_type_id=PACK_REUSEABLE_YES_OPEN) OR (v_gt_pack_layers_type_id=PACK_LAYERS_3_OR_MORE) OR (v_gt_pack_layers_type_id=PACK_LAYERS_DOUBLE_WALL)) THEN
			v_score_pack_opt_pt1:=v_score_pack_opt_pt1 + 1;
		END IF;
	END IF;


	
	-- Part 2:
	-- Required if any of the following are true
	--		Single product = NO
	--		Settle in transit = YES - more than 25% headspace 
	--		Reusable container = YES - displayed open
	--		Layers of packaging = 2 layers, 3 layeres or Double walled 
	
	-- If required the score is worked out as follows
	-- for 100% - 200% ratio - linear scale 0-4; so 150% = 2
	-- Num>=200				 	-> 4

	v_pt2_req := -1;
	IF ((v_single_in_pack>=0) AND (v_settle_in_transit>=0) AND (v_gt_gift_cont_type_id>=0) AND (v_gt_pack_layers_type_id>=0)) THEN 
		IF ((v_single_in_pack=0) OR (v_settle_in_transit=PACK_SETTLE_YES_MORE_25_PCT) OR (v_gt_gift_cont_type_id=PACK_REUSEABLE_YES_OPEN) OR (v_gt_pack_layers_type_id >= PACK_LAYERS_2)) THEN
			v_pt2_req := 1;
		ELSE 
			v_pt2_req := 0;
		END IF;
	END IF;

	v_score_pack_opt_pt2:=-1;
	-- can we work out pt2
	IF ((v_vol_package>0) AND (v_product_volume>0) AND (v_vol_package>=v_product_volume)) THEN
			
			IF (((v_vol_package/v_product_volume)*100)>=200) THEN 
				v_score_pack_opt_pt2 := 4;
			ELSE
				v_score_pack_opt_pt2 := (((v_vol_package/v_product_volume))-1)*4;
			END IF;

	END IF;

	
	
	-- Part 3: Essential requirements risk score
	-- This is ignored unless the packaging is deemed high risk. In this case the Part 3 score overrides the Part 1 score. 
	-- Note: The risk level is calculated when the questionnaire is filled in (as needed for validations) so saved as well
	
	-- LOGIC: For the pack style in question - all Y/N justification checkboxes must be ticked (or in the case of Y/N/NA dropdowns the answer must be yes
	v_score_pack_opt_pt3:=-1;
	IF v_gt_ess_req_pack_risk = ESS_REQ_PACK_RISK_HIGH THEN 
		
			CASE v_gt_ess_req_pack_style
			WHEN ESS_REQ_PACK_TYPE_DWJAR THEN 

				IF (v_dbl_walled_jar_just=POWER(2, NUM_OF_DBL_WALLED_JAR_Q)-1) THEN 
					v_score_pack_opt_pt3 := 3; -- all boxes ticked
				ELSE
					IF (v_just_report_exp_present=1) THEN 
						v_score_pack_opt_pt3 := 4; -- not all boxes ticked and justification given
					ELSE
						v_score_pack_opt_pt3 := -1; -- incomplete
					END IF;
				END IF;

			WHEN ESS_REQ_PACK_TYPE_LOOSE_TAB THEN 

				IF (v_contain_tablets_just=POWER(2, NUM_OF_LOOSE_TABLETS_JUST_Q)-1) THEN 
					v_score_pack_opt_pt3 := 3; -- all boxes ticked
				ELSE
					IF (v_just_report_exp_present=1) THEN 
						v_score_pack_opt_pt3 := 4; -- not all boxes ticked and justification given
					ELSE
						v_score_pack_opt_pt3 := -1; -- incomplete
					END IF;
				END IF;

			WHEN ESS_REQ_PACK_TYPE_BLIS_TAB THEN 

				IF (v_tablets_in_blis_tray_just=POWER(2, NUM_OF_TABS_IN_BLISTRAY_JUST_Q)-1) THEN 
					v_score_pack_opt_pt3 := 3; -- all boxes ticked
				ELSE
					IF (v_just_report_exp_present=1) THEN 
						v_score_pack_opt_pt3 := 4; -- not all boxes ticked and justification given
					ELSE
						v_score_pack_opt_pt3 := -1; -- incomplete
					END IF;
				END IF;

			WHEN ESS_REQ_PACK_TYPE_CARTON THEN 
			
				IF (v_carton_gift_box_vacuum_form>=0) AND (v_carton_gift_box_clear_win>=0) AND (v_carton_gift_box_sleeve>=0) THEN 
					IF ((v_tablets_in_blis_tray_just=POWER(2, NUM_OF_CARTON_GIFT_BOX_JUST_Q)-1) AND 
						(v_carton_gift_box_vacuum_form>=1) AND (v_carton_gift_box_clear_win>=1) AND 
						(v_carton_gift_box_sleeve>=1)) THEN 
						v_score_pack_opt_pt3 := 3; -- all boxes ticked
					ELSE
						IF (v_just_report_exp_present=1) THEN 
							v_score_pack_opt_pt3 := 4; -- not all boxes ticked and justification given
						ELSE
							v_score_pack_opt_pt3 := -1; -- incomplete
						END IF;
					END IF;
				ELSE
					v_score_pack_opt_pt3 := -1; -- incomplete
				END IF;
			
			WHEN ESS_REQ_PACK_TYPE_OTHER THEN 
			
				IF v_ess_req_other_score > 0 THEN 
					v_score_pack_opt_pt3 := v_ess_req_other_score;
				ELSE 
					v_score_pack_opt_pt3 := -1;
				END IF;
				
			ELSE 
				NULL; -- not yet set - pt3 score stays -1
			END CASE;
		
	END IF;		


	
	v_score_pack_opt := -1;
	-- we need to know at least if part 2 and part 3 are needed to calc risk
	IF ((v_pt2_req >= 0) AND (v_gt_ess_req_pack_risk>=0)) THEN 

			-- use part 1 
			IF ((v_gt_ess_req_pack_risk = ESS_REQ_PACK_RISK_LOW) AND (v_score_pack_opt_pt1>=0)) THEN 
				v_score_pack_opt := v_score_pack_opt_pt1;
			END IF;
				
			-- use part 3
			IF ((v_gt_ess_req_pack_risk = ESS_REQ_PACK_RISK_HIGH) AND (v_score_pack_opt_pt3>=0)) THEN
				v_score_pack_opt := v_score_pack_opt_pt3;
			END IF;
	
			-- if we have a score so far and part 2 is req add it to score above. 
			IF (v_score_pack_opt >=0) THEN 
			
				IF (v_pt2_req=1) THEN 
					IF (v_score_pack_opt_pt2>=0) THEN 
						v_score_pack_opt := v_score_pack_opt + v_score_pack_opt_pt2;
					ELSE
						--Otherwise - set score back to -1 as we aren't complete
						v_score_pack_opt := -1;
					END IF;
				END IF;

				-- if pt2 is not req then pt2 score defaults to 1
				IF (v_pt2_req=0) THEN
					v_score_pack_opt := v_score_pack_opt + 1;	
				END IF;
				
			END IF;	
	
	END IF;
	-- if nothing matched then score stays unset (-1)
	
	-- 6. Recycled content
	-- LOGIC: 
	-- Basic scoring: Looks at all packaging items and the materials they are made of. Each material has an associated "recycled %threshold". 
	
	-- For items that do not contain paper
	--------------------------------------
	-- The average recycled % for each pack item is compared to the target/threshold recycled % for the material it is made out of. From this we get a recycledfactor used below
		-- "average recycled %" = 0 						THEN	recycledfactor = 5
		-- "average recycled %" < threshold for material 	THEN  	recycledfactor = 3
		-- "average recycled %" <= threshold				THEN	recycledfactor = 2
		
	-- There's an equivalent factor for non-recycled parts of an item
		-- any non recycled component of an item	 		THEN	nonrecycledfactor = 5
		
	-- For Items that do contain paper we want to give additional credit if the non-recycled part of an item is FSC pure or FSC mixed
	-- Here the nonrecycledfactor's are
		-- Normal paper													nonrecycledfactor = 5
		-- FSC mixed 													nonrecycledfactor = 2
		-- FSC pure 													nonrecycledfactor = 2

	-- For each pack item the score is (recycled % x recycledfactor) + (nonrecycled % x nonrecycledfactor)

	-- The overall score is the sum of each "pack item score" x "pct of packaging by weight that the pack item represents"

	SELECT COUNT(*) INTO v_pack_item_count FROM gt_pack_item WHERE product_id = in_product_id AND revision_id = in_revision_id;

	-- this will barf with no pack items
	IF v_pack_item_count > 0 THEN

        -- get the profile message for level of recycled content
        -- group all paper together
        SELECT DECODE(level_recycled_pack, 3, 'No recycled content in one or more predominant materials', 2, 'Recycled content below threshold in one or more predominant materials', 1, 'Recycled content at or above threshold for all predominant materials') recycled_pack_cont_msg
        INTO v_recycled_pack_cont_msg
        FROM
        (
            SELECT MAX(level_recycled_pack) level_recycled_pack FROM
            (
                SELECT gt_pack_material_type_id, sum_weight_grams, av_recycled_pct, recycled_pct_theshold,
                CASE
                    WHEN av_recycled_pct=0 THEN 3
                    WHEN av_recycled_pct < recycled_pct_theshold THEN 2
                    ELSE 1
                END level_recycled_pack
                FROM 
                (
                    -- nonFSC paper, mixed FSC paper and FSC paper pure collected together
                    SELECT DECODE(pi.gt_pack_material_type_id, MAT_ID_FSC_MIXED, MAT_ID_NON_FSC_PAPER, MAT_ID_FSC_PURE, MAT_ID_NON_FSC_PAPER, pi.gt_pack_material_type_id) gt_pack_material_type_id, pmt.RECYCLED_PCT_THESHOLD, SUM(weight_grams) sum_weight_grams, SUM(pi.pct_recycled*weight_grams/100)/SUM(weight_grams)*100 av_recycled_pct
                    FROM gt_pack_item pi, gt_pack_material_type pmt
                    WHERE pi.gt_pack_material_type_id = pmt.gt_pack_material_type_id
                    AND product_id = in_product_id
                    AND revision_id = in_revision_id
                    GROUP BY DECODE(pi.gt_pack_material_type_id, MAT_ID_FSC_MIXED, MAT_ID_NON_FSC_PAPER, MAT_ID_FSC_PURE, MAT_ID_NON_FSC_PAPER, pi.gt_pack_material_type_id), pmt.recycled_pct_theshold
                ) 
                WHERE sum_weight_grams = (SELECT MAX(SUM(weight_grams)) FROM gt_pack_item WHERE product_id=in_product_id AND revision_id = in_revision_id GROUP BY DECODE(gt_pack_material_type_id, MAT_ID_FSC_MIXED, MAT_ID_NON_FSC_PAPER, MAT_ID_FSC_PURE, MAT_ID_NON_FSC_PAPER, gt_pack_material_type_id))
            )
        );
        

		-- now calculate the actual scores. This looks at recycled content, then at the remainder
		-- if that remainder is FSC (in the case of paper) then get extra credit
		SELECT SUM(score_recycled_pack) score_recycled_pack 
		INTO v_score_recycled_pack
		FROM (
			SELECT 
		        CASE 
		            WHEN contains_paper = 0 THEN (recyc_score+non_recyc_score)*pct_total_weight
		            WHEN contains_paper = 1 THEN (recyc_score+fsc_score)*pct_total_weight
		        END score_recycled_pack
		    FROM (
		        SELECT  contains_paper,
		                pct_total_weight,
		                (base_recycled_score*recyc_pct) recyc_score,
		                ((1-contains_paper)*non_recyc_pct*5) non_recyc_score,
		                (contains_paper*base_fsc_score*non_recyc_pct) fsc_score
		                FROM (
		                    SELECT 
		                        (weight_grams/SUM(weight_grams) OVER ()) pct_total_weight,
		                        pct_recycled/100 recyc_pct, 
		                        (100-pct_recycled)/100 non_recyc_pct,
		                        CASE
		                            WHEN pct_recycled = 0 THEN 5
		                            WHEN pct_recycled < pmt.recycled_pct_theshold THEN 3
		                            WHEN pct_recycled >= pmt.recycled_pct_theshold THEN 2
		                        END base_recycled_score,
		                        DECODE(pki.gt_pack_material_type_id, MAT_ID_NON_FSC_PAPER, 5, MAT_ID_FSC_MIXED, 2, MAT_ID_FSC_PURE, 2, 5) base_fsc_score,
		                        DECODE(pki.gt_pack_material_type_id, MAT_ID_NON_FSC_PAPER, 1, MAT_ID_FSC_MIXED, 1, MAT_ID_FSC_PURE, 1, 0) contains_paper
		                    FROM gt_pack_item pki, gt_pack_material_type pmt 
		                    WHERE pki.product_id = in_product_id
		                    AND pki.gt_pack_material_type_id = pmt.gt_pack_material_type_id
		                    AND revision_id = in_revision_id
		        )
		    )
		);

	
	ELSE
		v_recycled_pack_cont_msg := CANNOT_EVALUATE;
		v_score_recycled_pack:=-1;
	END IF;
	
	
	
	SetScoreFormulationGroup(in_act_id, in_product_id, in_revision_id, v_score_whats_in_prod, v_score_water_in_prod, v_score_energy_in_prod, v_score_pack_impact, v_score_pack_opt, v_score_recycled_pack);
	SetProfileFormulationGroup(in_act_id, in_product_id, in_revision_id, v_recycled_pack_cont_msg, v_score_pack_impact_raw, v_pack_ei, v_materials_ei, v_trans_pack_ei,
		v_score_water_raw_mat, v_score_water_contained, v_score_water_mnfct, v_score_water_wsr);
	
	
/*	-- now calculate giftpack scores (if needed
	SELECT 
	--1
	SUM(score_whats_in_prod * cnt)/SUM(cnt), MIN(NVL(score_whats_in_prod,-1)),
	--2 
	SUM(score_water_in_prod * cnt)/SUM(cnt), MIN(NVL(score_water_in_prod,-1)),
	-- 3
	SUM(score_energy_in_prod * cnt)/SUM(cnt), MIN(NVL(score_energy_in_prod,-1)),
	-- 4
--
	-- 5 
--
	-- 6
	SUM(score_recycled_pack * cnt)/SUM(cnt), MIN(NVL(score_recycled_pack,-1))
	INTO 
	v_gift_score_whats_in_prod, min_score_whats_in_prod, 
	v_gift_score_water_in_prod, min_score_water_in_prod,
	v_gift_score_energy_in_prod, min_score_energy_in_prod, 
	v_gift_score_recycled_pack, min_score_recycled_pack
    FROM 
    (
        SELECT p.product_id prod_id, gt.*, lp.cnt 
        FROM gt_scores gt, product p,
        (
            SELECT lp.LINK_PRODUCT_ID, count cnt 
            FROM gt_link_product lp 
            WHERE lp.PRODUCT_ID = in_product_id
            AND revision_id = in_revision_id
        ) lp
        WHERE p.product_id = gt.product_id(+)
        AND p.product_id = lp.LINK_PRODUCT_ID
        AND p.product_id IN 
        (
            SELECT link_product_id FROM gt_link_product 
            WHERE PRODUCT_ID = in_product_id
            AND revision_id = in_revision_id
        ) 
        AND ((revision_id IS NULL) OR (revision_id = (SELECT max(revision_id) FROM gt_scores WHERE product_id = p.product_id)))
        UNION
        SELECT p.product_id prod_id, gt.*, 1 cnt 
        FROM gt_scores gt, product p
        WHERE p.product_id = gt.product_id(+)
        AND p.PRODUCT_ID = in_product_id
        AND revision_id = in_revision_id
    );

	IF min_score_whats_in_prod<0 THEN 
		v_gift_score_whats_in_prod := -1;
	END IF;
	IF min_score_water_in_prod<0 THEN 
		v_gift_score_water_in_prod := -1;
	END IF;
	IF min_score_energy_in_prod<0 THEN 
		v_gift_score_energy_in_prod := -1;
	END IF;

	IF min_score_recycled_pack<0 THEN 
		v_gift_score_recycled_pack := -1;
	END IF;
	
	-- TO DO - calculate the gift pack score from combined 
	v_gift_score_pack_impact := -1;
	
	-- 4. Packaging impact - giftpack
	-- LOGIC: 
	-- score = The % ratio of total product weight (minus retail packaging) to the retail packaging weight / 5 
	-- 	score=score-0.5 if pack is designed for concentrate
	--  score=score-1.5 if pack is designed for reuse
	-- 	The above can accumulate
	--  Max possible score is 8
	
	-- TO DO - gift scoring
	*/
	
	/*
	v_pack_weight_total:=-1;
	v_prod_weight_exc_pack:=-1;
	v_concentrate_pack:=-1;
	v_refill_pack:=-1;
	
	SELECT SUM(weight_grams*cnt) pack_weight
	INTO v_pack_weight_total
    FROM 
    (
        SELECT pi.weight_grams, lp.cnt 
        FROM gt_pack_item pi,
        (
            SELECT lp.LINK_PRODUCT_ID, count cnt 
            FROM gt_link_product lp 
            WHERE lp.PRODUCT_ID = in_product_id
            AND revision_id = in_revision_id
        ) lp
        WHERE pi.product_id = lp.link_product_id
        AND pi.product_id IN 
        (
            SELECT link_product_id FROM gt_link_product 
            WHERE PRODUCT_ID = in_product_id
            AND revision_id = in_revision_id
        ) 
        AND revision_id = (SELECT max(revision_id) FROM gt_scores WHERE product_id = pi.product_id)
        UNION
        SELECT weight_grams, 1 cnt
	    FROM gt_pack_item pi
		WHERE product_id = in_product_id
		AND revision_id = in_revision_id
    );
	
    SELECT SUM(prod_weight_exc_pack), MIN(prod_weight_exc_pack), MIN(concentrate), MIN(refill_pack)
    INTO v_prod_weight_exc_pack, min_prod_weight_exc_pack, v_concentrate_pack, v_refill_pack
    FROM
    (
     SELECT
        -- 4 
        prod_weight_exc_pack, NVL(concentrate,-1) concentrate, NVL(refill_pack,-1) refill_pack
        FROM gt_formulation_answers fa, gt_packaging_answers pka, all_product p
            WHERE p.product_id = fa.product_id(+)
            AND p.product_id = pka.product_id(+)
            AND p.product_id = in_product_id
            AND fa.revision_id = in_revision_id
            AND pka.revision_id = in_revision_id
        UNION        
        SELECT
        -- 4 
        NVL(prod_weight_exc_pack*cnt,-1), NVL(concentrate,-1) concentrate, NVL(refill_pack,-1) refill_pack
        FROM gt_formulation_answers fa, gt_packaging_answers pka, all_product p, 
            (
                SELECT lp.LINK_PRODUCT_ID, count cnt 
                FROM gt_link_product lp 
                WHERE lp.PRODUCT_ID = in_product_id
                AND revision_id = in_revision_id
            ) lp
            WHERE p.product_id = lp.LINK_PRODUCT_ID(+)
            AND p.product_id = fa.product_id(+)
            AND p.product_id = pka.product_id(+)
            AND p.product_id IN 
            (
                SELECT link_product_id FROM gt_link_product 
                WHERE PRODUCT_ID = in_product_id
                AND revision_id = in_revision_id
            )
            AND ((fa.revision_id IS NULL) OR (fa.revision_id = (SELECT max(revision_id) FROM gt_scores WHERE product_id = p.product_id)))
            AND ((pka.revision_id IS NULL) OR (pka.revision_id = (SELECT max(revision_id) FROM gt_scores WHERE product_id = p.product_id)))
    );

	-- need all these to get score
	IF (v_pack_weight_total>0) AND (v_prod_weight_exc_pack>0) AND (v_concentrate_pack>=0) AND (v_refill_pack>=0) AND (min_prod_weight_exc_pack>=0) THEN
		v_gift_score_pack_impact := (100*(v_pack_weight_total/(v_prod_weight_exc_pack)))/5;
		v_gift_score_pack_impact := v_gift_score_pack_impact - (v_concentrate_pack * 0.5);
		v_gift_score_pack_impact := v_gift_score_pack_impact - (v_refill_pack * 1.5);	
	
		IF v_gift_score_pack_impact < 0 THEN v_gift_score_pack_impact := 0; END IF;
		IF v_gift_score_pack_impact > 8 THEN v_gift_score_pack_impact := 8; END IF;
	ELSE
		v_gift_score_pack_impact := -1;
	END IF;
	

	*/
	-- pack opt score is based only on this product - not child products
	--v_gift_score_pack_opt := v_score_pack_opt;
	
  	-- TO DO - calc gift scores
  	--SetGiftScoreFormulationGroup(in_act_id, in_product_id, in_revision_id, v_gift_score_whats_in_prod, v_gift_score_water_in_prod, v_gift_score_energy_in_prod, v_gift_score_pack_impact, v_gift_score_pack_opt, v_gift_score_recycled_pack);
	
	--GetScoreFormulationGroup(in_act_id, in_product_id, in_revision_id, out_cur);

END;

---------------------------------------------
-- Product supply
---------------------------------------------

PROCEDURE GetScoreSupplyGroup(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_cnt					NUMBER;
	v_type_id				gt_product_type.gt_product_type_id%TYPE;
	v_matched_type_id		gt_product_type.gt_product_type_id%TYPE;
	v_range_id				gt_product_answers.gt_product_range_id%TYPE;
	v_matched_range_id		gt_product_answers.gt_product_range_id%TYPE;
	v_app_sid				product.app_sid%TYPE;
BEGIN
	
	-- Supplier Management
	-- Transport - Raw Materials
	-- Transport - Product to Boots
	-- Transit packaging
	-- Transit Optimisation
	
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading product with id '||in_product_id);
	END IF;
	
	SELECT app_sid INTO v_app_sid FROM product WHERE product_id = in_product_id;
	
	GetBestMatchTargetScore(in_act_id, in_product_id, in_revision_id, v_type_id, v_matched_type_id, v_range_id, v_matched_range_id);

	OPEN out_cur FOR
		-- Dickie's page expects values in this form so it can be generic
		SELECT 'Product Supply' group_name, MAX_SCORE_SUPPLY max_score,
		       decode(rn, 1, 'Supplier Management', 2, 'Transport - Raw Materials', 3, 'Transport - Product to Boots', 4, 'Transit Packaging', 5, 'Transit Optimisation', 6, 'Energy in Distribution') score_label,
			   DECODE(rn, 1, 0, 2, 0, 3, 0, 4, 1, 5, 1, 6, 0) score_relates_to_pkg,
			   DECODE(rn, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0) score_relates_to_ingred,
		       decode(rn, 1, gt.score_supp_management, 2, gt.score_trans_raw_mat, 3, gt.score_trans_to_boots, 4, gt.score_trans_packaging, 5, gt.score_trans_opt, 6, gt.score_energy_dist) score_value,
	           decode(rn, 1, TRIP_SCORE_SUPP_MAN, 2, -1, 3, -1, 4, -1, 5, -1, 6, -1) trip_score_value,
		       NVL(decode(rn, 1, gtf.score_supp_management, 2, gtf.score_trans_raw_mat, 3, gtf.score_trans_to_boots, 4, gtf.score_trans_packaging, 5, gtf.score_trans_opt, 6, gtf.score_energy_dist), -1) gift_score_value,
		       NVL(decode(rn, 1, p.min_score_supp_management, 2, p.min_score_trans_raw_mat, 3, p.min_score_trans_to_boots, 4, p.min_score_trans_packaging, 5, p.min_score_trans_opt, 6, p.min_score_energy_dist), -1) min_target_value,
		       NVL(decode(rn, 1, p.max_score_supp_management, 2, p.max_score_trans_raw_mat, 3, p.max_score_trans_to_boots, 4, p.max_score_trans_packaging, 5, p.max_score_trans_opt, 6, p.max_score_energy_dist), -1) max_target_value,
			   DECODE(MAX(NVL(decode(rn, 1, p.min_score_supp_management, 2, p.min_score_trans_raw_mat, 3, p.min_score_trans_to_boots, 4, p.min_score_trans_packaging, 5, p.min_score_trans_opt, 5, p.min_score_trans_opt, 6, p.min_score_energy_dist), -1)) OVER (), -1, 0, 1) use_min_target_value, -- use if any are set (>-1)
			   DECODE(MAX(NVL(decode(rn, 1, p.max_score_supp_management, 2, p.max_score_trans_raw_mat, 3, p.max_score_trans_to_boots, 4, p.max_score_trans_packaging, 5, p.max_score_trans_opt, 6, p.max_score_energy_dist), -1)) OVER (), -1, 0, 1) use_max_target_value
        FROM (SELECT rownum rn FROM (SELECT 1 FROM dual GROUP BY cube (1, 2, 3)) WHERE rownum <= 6) r, (
                SELECT p.product_id, gts.* FROM 
                (
                	SELECT p.product_id, v_type_id gt_product_type_id, v_matched_range_id gt_product_range_id
                      FROM product p
                     WHERE p.product_id = in_product_id
                ) p, -- gets type and range id if present  - set to -1 otherwise 
                (
                	SELECT (NVL(gts.gt_product_range_id, -1)) nullable_range, gts.* FROM gt_target_scores gts WHERE gts.app_sid = v_app_sid
                ) gts  
                WHERE p.gt_product_type_id = gts.gt_product_type_id(+)  -- this will only match on correct type
                  AND p.gt_product_range_id = gts. nullable_range(+)     -- OK for null range to match
        ) p,   (
        	SELECT * FROM gt_scores WHERE product_id = in_product_id AND revision_id = in_revision_id
        ) gt, (
        	SELECT * FROM gt_scores_combined WHERE product_id = in_product_id AND revision_id = in_revision_id
        ) gtf
    	WHERE p.product_id = gt.product_id(+)
    	AND p.product_id = gtf.product_id(+);
		
END;

PROCEDURE SetScoreSupplyGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
    in_score_supp_management	IN gt_scores.score_supp_management%TYPE,
    in_score_trans_raw_mat		IN gt_scores.score_trans_raw_mat%TYPE,
    in_score_trans_to_boots		IN gt_scores.score_trans_to_boots%TYPE,
    in_score_trans_packaging	IN gt_scores.score_trans_packaging%TYPE,
    in_score_trans_opt			IN gt_scores.score_trans_opt%TYPE,
    in_score_energy_dist		IN gt_scores.score_energy_dist%TYPE
)
AS
	v_max_revision_id					product_revision.revision_id%TYPE;
BEGIN
	
	-- Supplier Management
	-- Transport - Raw Materials
	-- Transport - Product to Boots
	-- Transit packaging
	-- Transit Optimisation
	
    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
    
    -- only log if latest revision
    IF v_max_revision_id = in_revision_id THEN 
		FOR r IN (
	        SELECT 	
	        	score_supp_management,	
				score_trans_raw_mat,		
				score_trans_to_boots,	
				score_trans_packaging,	
				score_trans_opt, 
				score_energy_dist		
 		   FROM gt_scores s, product_revision pr
	      WHERE pr.product_id=s.product_id (+)
	        AND pr.REVISION_ID = s.revision_id(+)
	        AND pr.product_id = in_product_id
			AND pr.revision_id = v_max_revision_id
		)
		LOOP
			-- actually only ever going to be single row as product id and revision id are PK
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_SUPP_MANAGEMENT, r.score_supp_management, in_score_supp_management);		
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_TRANS_RAW_MAT, r.score_trans_raw_mat, in_score_trans_raw_mat);	
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_TRANS_TO_BOOTS, r.score_trans_to_boots, in_score_trans_to_boots);	
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_TRANS_PACKAGING, r.score_trans_packaging, in_score_trans_packaging);	
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_TRANS_OPT, r.score_trans_opt, in_score_trans_opt);	
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_ENERGY_DIST, r.score_energy_dist, in_score_energy_dist);				
		END LOOP;
	END IF;

	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	BEGIN
		INSERT INTO gt_scores 
			(product_id, revision_id, score_supp_management, score_trans_raw_mat, 
				score_trans_to_boots, score_trans_packaging, score_trans_opt, score_energy_dist) 
		VALUES
			(in_product_id, in_revision_id, in_score_supp_management, in_score_trans_raw_mat, 
				in_score_trans_to_boots, in_score_trans_packaging, in_score_trans_opt, in_score_energy_dist) ;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE gt_scores SET
			    score_supp_management	=	in_score_supp_management,
			    score_trans_raw_mat		=	in_score_trans_raw_mat,
			    score_trans_to_boots	=	in_score_trans_to_boots,
			    score_trans_packaging	=	in_score_trans_packaging,
			    score_trans_opt			=	in_score_trans_opt,
				score_energy_dist		=	in_score_energy_dist
			WHERE product_id 			= 	in_product_id
			AND revision_id 			= 	in_revision_id;
	END;
	
END;

/*OCEDURE SetGiftScoreSupplyGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
    in_score_supp_management	IN gt_scores.score_supp_management%TYPE,
    in_score_trans_raw_mat		IN gt_scores.score_trans_raw_mat%TYPE,
    in_score_trans_to_boots		IN gt_scores.score_trans_to_boots%TYPE,
    in_score_trans_packaging	IN gt_scores.score_trans_packaging%TYPE,
    in_score_trans_opt			IN gt_scores.score_trans_opt%TYPE
)
AS
BEGIN
	
	-- Supplier Management
	-- Transport - Raw Materials
	-- Transport - Product to Boots
	-- Transit packaging
	-- Transit Optimisation

	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	BEGIN
		INSERT INTO gt_scores_gift
			(product_id, revision_id, score_supp_management, score_trans_raw_mat, 
				score_trans_to_boots, score_trans_packaging, score_trans_opt) 
		VALUES
			(in_product_id, in_revision_id, in_score_supp_management, in_score_trans_raw_mat, 
				in_score_trans_to_boots, in_score_trans_packaging, in_score_trans_opt) ;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE gt_scores_gift SET
			    score_supp_management	=	in_score_supp_management,
			    score_trans_raw_mat		=	in_score_trans_raw_mat,
			    score_trans_to_boots	=	in_score_trans_to_boots,
			    score_trans_packaging	=	in_score_trans_packaging,
			    score_trans_opt			=	in_score_trans_opt
			WHERE product_id 			= 	in_product_id
			AND revision_id 			= 	in_revision_id;
	END;
	
END;*/

PROCEDURE SetProfileSupplyGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id				IN product_revision.revision_id%TYPE,
	in_country_made_in_list		IN gt_profile.country_made_in_list%TYPE
)
AS
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	BEGIN
		INSERT INTO gt_profile 
			(product_id, revision_id, country_made_in_list) 
		VALUES
			(in_product_id, in_revision_id, in_country_made_in_list) ;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE gt_profile SET
				country_made_in_list	= in_country_made_in_list 
			WHERE product_id 			= in_product_id
			AND revision_id 			= in_revision_id;
	END;
END;

PROCEDURE CalcScoreSupplyGroup(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN security_pkg.T_SID_ID,
	in_revision_id			IN  product_revision.revision_id%TYPE
)
AS

	v_product_class			gt_product_class.gt_product_class_id%TYPE;

	-- 1
    v_score_supp_management		gt_scores.score_supp_management%TYPE;
	-- 2
    v_score_trans_raw_mat		gt_scores.score_trans_raw_mat%TYPE;
    v_prod_raw_mat_total_pct	NUMBER(6,3);
    v_pack_raw_mat_total_pct	NUMBER(6,3);
 	-- 3
    v_score_trans_to_boots		gt_scores.score_trans_to_boots%TYPE;
    v_cnt_no_pct				NUMBER;
    v_cntry_set_pct				NUMBER(6,3);
 	v_country_made_in_list		gt_profile.country_made_in_list%TYPE;
    -- 4 
    v_pack_meet_req				gt_packaging_answers.pack_meet_req%TYPE;
    v_pack_shelf_ready			gt_packaging_answers.pack_shelf_ready%TYPE;
	v_max_rcyld_component		gt_trans_item.pct_recycled%TYPE;
    v_pack_consum_rcyld			NUMBER(1);
    v_score_trans_packaging		gt_scores.score_trans_packaging%TYPE;
    -- 5 
	v_retail_packs_stackable	gt_packaging_answers.retail_packs_stackable%TYPE;
	v_vol_tran_pack				gt_packaging_answers.vol_tran_pack%TYPE;
	v_vol_prod_tran_pack		gt_packaging_answers.vol_prod_tran_pack%TYPE;
    v_score_trans_opt			gt_scores.score_trans_opt%TYPE;

	--6
	v_score_energy_dist			gt_scores.score_energy_dist%TYPE;
	
    
   /* -- gift scores 
    --1
	v_gift_score_supp_management	gt_scores.score_supp_management%TYPE;
	min_score_supp_management		gt_scores.score_supp_management%TYPE;
	--2
	v_gift_score_trans_raw_mat		gt_scores.score_trans_raw_mat%TYPE;
	min_score_trans_raw_mat			gt_scores.score_trans_raw_mat%TYPE;
	--3
	v_gift_score_trans_to_boots		gt_scores.score_trans_to_boots%TYPE;
	--4
	v_gift_score_trans_packaging	gt_scores.score_trans_packaging%TYPE;
	--5 
	v_gift_score_trans_opt			gt_scores.score_trans_opt%TYPE; */

	
	v_has_ingred			NUMBER(1);
	v_has_pack				NUMBER(1);
	v_num_rows				NUMBER(10);
BEGIN

	
	-- find product class up front
	v_product_class := product_info_pkg.GetProductClassId(in_act_id, in_product_id, in_revision_id);
	
	v_max_rcyld_component := -1; -- set to minus one until we can find a component of the transit packaging in the gt_trans_item table which has some post
	-- consumer recycled content...
	
	SELECT COUNT(*)
	  INTO v_num_rows
	  FROM gt_trans_item
	 WHERE product_id = in_product_id
	   AND revision_id = in_revision_id;
	
	IF v_num_rows > 0 THEN
		SELECT MAX(pct_recycled)
		  INTO v_max_rcyld_component 
		  FROM gt_trans_item
		 WHERE product_id = in_product_id
		   AND revision_id = in_revision_id;
		   
		IF v_max_rcyld_component  = 0 THEN v_pack_consum_rcyld := 0; END IF;
		IF v_max_rcyld_component  > 0 THEN v_pack_consum_rcyld := 1; END IF;
	-- all we need is for one item of transit packaging to contain material - which will be proven by the maximum recycled component being greater than one
	END IF;
	
	IF v_max_rcyld_component = -1 THEN v_pack_consum_rcyld := -1; END IF;

	SELECT has_ingredients, has_packaging 
	  INTO v_has_ingred, v_has_pack
	  FROM gt_product_rev
	 WHERE product_id = in_product_id
	   AND revision_id = in_revision_id;
	
	-- get as much as possible up front 
	SELECT 
	-- 1
	NVL(srt.gt_score,-1) score_supp_management,
	-- 2 
	CASE 
	  WHEN v_has_ingred = 0	THEN ((2*NVL(pack_in_cont_pct,0)/100)+(5*NVL(pack_btwn_cont_pct,0)/100)+(3*NVL(pack_cont_un_pct,0)/100))  -- only consider pack items if no ingred
	  WHEN v_has_pack = 0 THEN ((2*NVL(prod_in_cont_pct,0)/100)+(5*NVL(prod_btwn_cont_pct,0)/100)+(3*NVL(prod_cont_un_pct,0)/100)) -- only consider prod items if no packaging
	  ELSE  (((2*NVL(prod_in_cont_pct,0)/100)+(5*NVL(prod_btwn_cont_pct,0)/100)+(3*NVL(prod_cont_un_pct,0)/100))+((2*NVL(pack_in_cont_pct,0)/100)+(5*NVL(pack_btwn_cont_pct,0)/100)+(3*NVL(pack_cont_un_pct,0)/100)))*0.5 
	END score_trans_raw_mat,
	NVL(prod_in_cont_pct,0)+NVL(prod_btwn_cont_pct,0)+NVL(prod_cont_un_pct,0) prod_raw_mat_total_pct,
	NVL(pack_in_cont_pct,0)+NVL(pack_btwn_cont_pct,0)+NVL(pack_cont_un_pct,0) pack_raw_mat_total_pct,
	-- 4 
	NVL(pack_meet_req, -1) pack_meet_req, NVL(pack_shelf_ready, -1) pack_shelf_ready, NVL(tpt.gt_score, -1) score_trans_packaging,
	-- 5 
	NVL(retail_packs_stackable, -1) retail_packs_stackable, NVL(vol_tran_pack, -1) vol_tran_pack, NVL(vol_prod_tran_pack, -1) vol_prod_tran_pack
	INTO v_score_supp_management, v_score_trans_raw_mat, v_prod_raw_mat_total_pct, v_pack_raw_mat_total_pct, v_pack_meet_req, v_pack_shelf_ready, v_score_trans_packaging, v_retail_packs_stackable, v_vol_tran_pack, v_vol_prod_tran_pack 
	FROM 
		gt_supplier_answers sa, gt_sus_relation_type srt, gt_transport_answers ta, gt_packaging_answers pa, gt_trans_pack_type tpt, all_product p
	WHERE p.product_id = sa.product_id(+) 
	AND p.product_id = ta.product_id(+) 
	AND p.product_id = pa.product_id(+) 
	AND sa.gt_sus_relation_type_id = srt.gt_sus_relation_type_id(+)
	AND pa.gt_trans_pack_type_id = tpt.gt_trans_pack_type_id(+)
	AND p.product_id = in_product_id
	AND ((sa.revision_id = in_revision_id) OR (sa.revision_id IS NULL))
	AND ((ta.revision_id = in_revision_id) OR (ta.revision_id IS NULL))
	AND ((pa.revision_id = in_revision_id) OR (pa.revision_id IS NULL));

	-- 1. Supplier Management
	-- LOGIC: 
	-- Supplier has been selected specificially on sustainability performance 					-> 1
	-- Supplier has had SUSTAINABILITY AUDIT. Management plan in place - results signed off 	-> 2
	-- Supplier has been audited. Management plan in place - results signed off 				-> 3
	-- Supplier known to Boots, meets Boots COC on Ethical trading. Not yet audited				-> 4
	-- Supplier reputation unknown, no audit information										-> 8

	-- score is calculated in select statement at top

	-- 2. Transport - Raw Materials
	-- LOGIC:
	-- product	=	(2 x %materials obtained same continent / 100) + (5 x %materials obtained diff continent / 100) + (3 x %unknown / 100)
	-- packaging =	(2 x %materials obtained same continent / 100) + (5 x %materials obtained diff continent / 100) + (3 x %unknown / 100)
	-- score = (product + packaging) / 2 unless the product doesn't have ingred or packaging
	-- if no packaging only the product score is used
	-- if no product ingredients only the packaging score is used
	
	-- score is calculated in select statement at top

	IF (v_prod_raw_mat_total_pct<100) AND (v_has_ingred<>0) THEN 
		v_score_trans_raw_mat := -1; -- not yet enough data to calc
	END IF;

	IF (v_pack_raw_mat_total_pct<100) AND (v_has_pack<>0) THEN 
		v_score_trans_raw_mat := -1; -- not yet enough data to calc
	END IF;

	-- 3. Transport - Product to Boots
	-- LOGIC: for each country

	--Origin		Mode			
	--			Rail		Road	Sea		Air
	--BM -UK		1			1		1		1		-> actually always defaults to "onsite" which scores = 1
	--UK			2			2		2		7
	--Europe		3			4		3		8
	--ROW			4			4		4		9

	--Capture the predominant travel mode for each country individually (which makes sense) and then use the same scoring system, but proportion it up by % (if known).
	--Where there weren't percentages the division would be made equally.
	--So for:
	--Sweden - Road - 20%
	--UK - Boots Manufactured - unknown%
	--China - Air- unkown%

	--The score would be
	--(Sweden Score x 20%) + (UK score x 40%) + (China score x 40%)
	--(1 x 20%) + (0 x 40%) + (5 x 40%) = 2.2 

	v_score_trans_to_boots := -1;
	-- find how many countries we have to amortise score over
	SELECT count(*) INTO v_cnt_no_pct FROM gt_country_made_in WHERE ((pct IS NULL) OR (pct = 0) OR (pct = -1)) AND product_id = in_product_id AND revision_id = in_revision_id;
	
	-- get the countries set so far	
	SELECT csr.stragg(countries) countries 
	INTO  v_country_made_in_list
	FROM 
	(
	    SELECT NVL(DECODE(ROWNUM, 1, country, ' '||country), 'None set') countries FROM
	    (
	        SELECT DISTINCT(country) country
	        FROM gt_country_made_in cm, country c
	        WHERE cm.country_code = c.country_code
	        AND product_id = in_product_id
	        AND revision_id = in_revision_id
	    )
	);


	-- find total pct set
	SELECT SUM(pct) INTO v_cntry_set_pct 
	FROM
	(
		SELECT 
			CASE 
				WHEN ((pct IS NULL) OR (pct=0) OR (pct=-1)) THEN 0
				ELSE pct
			END pct 
		FROM gt_country_made_in WHERE product_id = in_product_id AND revision_id = in_revision_id
	);
	
	IF ((v_cntry_set_pct<100) AND (v_cnt_no_pct=0)) THEN 
		-- not a full set of countries
		v_score_trans_to_boots := -1;
	ELSE
		SELECT NVL(SUM(gt_score),-1) 
		INTO v_score_trans_to_boots
		FROM
		(
		    SELECT 
		        CASE
		            WHEN ((pct IS NULL) OR (pct=0) OR (pct=-1)) THEN ((100-v_cntry_set_pct) * gt_score/100) / v_cnt_no_pct
		            ELSE pct * gt_score/100
		        END gt_score
		    FROM gt_country_made_in cm, gt_country_region cr, gt_trans_region_scoring rs
		    WHERE cm.gt_transport_type_id = rs.gt_transport_type_id
		    AND cm.country_code = cr.country_code
		    AND cr.gt_region_id = rs.gt_region_id 
		    AND product_id = in_product_id
		    AND revision_id = in_revision_id
		);
	END IF;

	-- 4. Transit packaging
	-- LOGIC:
	--
	-- "pack score" = MAX of the 3 below conditions below (inc.default)
	--  Does the transit packaging meet Boots "Transit Packaging: Supplier Requirements" = NO 	-> 5
	--  Is the pack "Shelf Ready" = NO															-> 4
	--  Does the packaging use post consumer recycled material? = NO							-> 4	
	--  
	--  *If non of the above conditions are met - then use the scores below (the relevent score is pulled out of the select statement at the top) 
	--
	-- "level of transit packaging score" = the selected ONE of the below
	--  Bulk outers for singles to store delivery												-> 1	
	--  One layer of shipping packaging															-> 2	
	--  Inner bagged / overwrapped collations in an outer case									-> 3	
	--  Dividers / bent pieces / bubble wrap in an outer case									-> 3.5
	--  Inner case/s in an outer case															-> 4	
	--  Inner case, divisions / bubble wrap in outer case										-> 5

	IF ((v_pack_meet_req>=0) AND (v_pack_shelf_ready>=0)) THEN
		CASE 
		  WHEN v_pack_meet_req = 0 THEN v_score_trans_packaging := 5;
		  WHEN (((v_pack_shelf_ready = 1) OR (v_pack_consum_rcyld = 0)) AND (v_score_trans_packaging<4)) THEN v_score_trans_packaging := 4;
		  ELSE NULL; --*If non of the above conditions are met - then use the score calculated in select at top
		END CASE;
	ELSE 
		v_score_trans_packaging := -1;-- not enough info to detemine score
	END IF;
	
	-- 5. Transit Optimisation
	-- LOGIC:
	-- "vol ratio" = "Transit pack volume (cc)" / "Total Product Volume (cc)" * 100% 
	-- "vol ratio" < 110					-> 1
	-- "vol ratio" < 150					-> 2
	-- "vol ratio" < 200					-> 3
	-- "vol ratio" >= 200					-> 4
	-- if either the vol_tran_pack (transit pack volume) or the vol_prod_tran_pack are not provided - ie: are either <= 0 or null
	-- then the product gets a transit optimisation score (score_trans_opt in the gt_scores table) of 1
	-- (this is to accommodate for items whose volumes were not entered as this score was a function of only the retail_packs_stackable column and whose questionnaires have been approved (and hence their models assumed to be complete) 
	-- this no longer happens because it is mandatory to provide the volume data for all products)
	v_score_trans_opt := 1;
	IF ((v_vol_tran_pack>0) AND (v_vol_prod_tran_pack>0)) THEN
		CASE
			  WHEN (v_vol_tran_pack/v_vol_prod_tran_pack)*100<110 THEN v_score_trans_opt := 1;
			  WHEN (v_vol_tran_pack/v_vol_prod_tran_pack)*100<150 THEN v_score_trans_opt := 2;
			  WHEN (v_vol_tran_pack/v_vol_prod_tran_pack)*100<200 THEN v_score_trans_opt := 3;
			  WHEN (v_vol_tran_pack/v_vol_prod_tran_pack)*100>=200 THEN v_score_trans_opt := 4;
		END CASE;
	END IF;
	
	-- 6 Energy In Dist
	model_pd_pkg.CalcEnergyDist(in_act_id, in_product_id, v_product_class, in_revision_id, v_score_energy_dist);

	SetScoreSupplyGroup(in_act_id, in_product_id, in_revision_id, v_score_supp_management, v_score_trans_raw_mat, v_score_trans_to_boots, v_score_trans_packaging, v_score_trans_opt, v_score_energy_dist);	
	SetProfileSupplyGroup(in_act_id, in_product_id, in_revision_id, v_country_made_in_list);	
	
	/*
	-- now calculate giftpack scores (if needed
	SELECT 
	--1
	MAX(score_supp_management), MIN(NVL(score_supp_management,-1)),
	--2 
	SUM(score_trans_raw_mat * cnt)/SUM(cnt), MIN(NVL(score_trans_raw_mat,-1))
	-- 3
--
	-- 4
--
	-- 5 
--
	INTO 
	v_gift_score_supp_management, min_score_supp_management, 
	v_gift_score_trans_raw_mat, min_score_trans_raw_mat
    FROM 
    (
        SELECT p.product_id prod_id, gt.*, lp.cnt 
        FROM gt_scores gt, product p,
        (
            SELECT lp.LINK_PRODUCT_ID, count cnt 
            FROM gt_link_product lp 
            WHERE lp.PRODUCT_ID = in_product_id
            AND revision_id = in_revision_id
        ) lp
        WHERE p.product_id = gt.product_id(+)
        AND p.product_id = lp.LINK_PRODUCT_ID
        AND p.product_id IN 
        (
            SELECT link_product_id FROM gt_link_product 
            WHERE PRODUCT_ID = in_product_id
            AND revision_id = in_revision_id
        ) 
        AND ((revision_id IS NULL) OR (revision_id = (SELECT max(revision_id) FROM gt_scores WHERE product_id = p.product_id)))
        UNION
        SELECT p.product_id prod_id, gt.*, 1 cnt 
        FROM gt_scores gt, product p
        WHERE p.product_id = gt.product_id(+)
        AND p.PRODUCT_ID = in_product_id
        AND revision_id = in_revision_id
    );

	IF min_score_supp_management<0 THEN 
		v_gift_score_supp_management := -1;
	END IF;
	IF min_score_trans_raw_mat<0 THEN 
		v_gift_score_trans_raw_mat := -1;
	END IF;

	--3
	v_gift_score_trans_to_boots := v_score_trans_to_boots;
	--4
	v_gift_score_trans_packaging := v_score_trans_packaging;
	--5 
	v_gift_score_trans_opt := v_score_trans_opt;
	
	-- to do - do gift calc
	SetGiftScoreSupplyGroup(in_act_id, in_product_id, in_revision_id, v_gift_score_supp_management, v_gift_score_trans_raw_mat, v_gift_score_trans_to_boots, v_gift_score_trans_packaging, v_gift_score_trans_opt);
	*/
	--GetScoreSupplyGroup(in_act_id, in_product_id, in_revision_id, out_cur);
	
END;

---------------------------------------------
-- Product use at home
---------------------------------------------

PROCEDURE GetScoreUseAtHomeGroup(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_cnt					NUMBER;
	v_type_id				gt_product_type.gt_product_type_id%TYPE;
	v_matched_type_id		gt_product_type.gt_product_type_id%TYPE;
	v_range_id				gt_product_answers.gt_product_range_id%TYPE;
	v_matched_range_id		gt_product_answers.gt_product_range_id%TYPE;
	v_app_sid				product.app_sid%TYPE;
BEGIN
	
-- Water in Use
-- Energy in Use
-- Ancillary Materials Required
	
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading product with id '||in_product_id);
	END IF;	
	
	SELECT app_sid INTO v_app_sid FROM product WHERE product_id = in_product_id;

	GetBestMatchTargetScore(in_act_id, in_product_id, in_revision_id, v_type_id, v_matched_type_id, v_range_id, v_matched_range_id);

	OPEN out_cur FOR
		-- Dickie's page expects values in this form so it can be generic
		SELECT 'Use at Home' group_name, MAX_SCORE_USE_AT_HOME max_score,
		       DECODE(rn, 1, 'Water in Use', 2, 'Energy in Use', 3, 'Ancillary Materials Required') score_label,
			   DECODE(rn, 1, 0, 2, 0, 3, 0) score_relates_to_pkg,
			   DECODE(rn, 1, 0, 2, 0, 3, 1) score_relates_to_ingred,
		       DECODE(rn, 1, gt.score_water_use, 2, gt.score_energy_use, 3, gt.score_ancillary_req) score_value,
	           DECODE(rn, 1, -1, 2, -1, 3, -1) trip_score_value,
		       NVL(DECODE(rn, 1, gtf.score_water_use, 2, gtf.score_energy_use, 3, gtf.score_ancillary_req), -1) gift_score_value,
		       NVL(decode(rn, 1, min_score_water_use, 2, min_score_energy_use, 3, min_score_ancillary_req), -1) min_target_value,
		       NVL(decode(rn, 1, max_score_water_use, 2, max_score_energy_use, 3, max_score_ancillary_req), -1) max_target_value,
			   DECODE(MAX( NVL(decode(rn, 1, min_score_water_use, 2, min_score_energy_use, 3, min_score_ancillary_req), -1)) OVER (), -1, 0, 1) use_min_target_value, -- use if any are set (>-1)
			   DECODE(MAX(NVL(decode(rn, 1, max_score_water_use, 2, max_score_energy_use, 3, max_score_ancillary_req), -1)) OVER (), -1, 0, 1) use_max_target_value		     
        FROM (SELECT rownum rn FROM (SELECT 1 FROM dual GROUP BY cube (1, 2, 3)) WHERE rownum <= 3) r, (
                SELECT p.product_id, gts.* FROM 
                (
                	SELECT p.product_id, v_type_id gt_product_type_id, v_matched_range_id gt_product_range_id
                      FROM product p
                     WHERE p.product_id = in_product_id
                ) p, -- gets type and range id if present  - set to -1 otherwise 
                (
                	SELECT (NVL(gts.gt_product_range_id, -1)) nullable_range, gts.* FROM gt_target_scores gts WHERE gts.app_sid = v_app_sid
                ) gts  
                WHERE p.gt_product_type_id = gts.gt_product_type_id(+)  -- this will only match on correct type
                  AND p.gt_product_range_id = gts. nullable_range(+)     -- OK for null range to match
        ) p,   (
        	SELECT * FROM gt_scores WHERE product_id = in_product_id AND revision_id = in_revision_id
        ) gt, (
        	SELECT * FROM gt_scores_combined WHERE product_id = in_product_id AND revision_id = in_revision_id
        ) gtf
    	WHERE p.product_id = gt.product_id(+)
    	AND p.product_id = gtf.product_id(+);
		
END;

PROCEDURE SetScoreUseAtHomeGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id				IN product_revision.revision_id%TYPE,
    in_score_water_use			IN gt_scores.score_water_use%TYPE,
    in_score_energy_use			IN gt_scores.score_energy_use%TYPE,
    in_score_ancillary_req		IN gt_scores.score_ancillary_req%TYPE
)
AS
	v_max_revision_id			product_revision.revision_id%TYPE;
BEGIN
	
-- Water in Use
-- Energy in Use
-- Ancillary Materials Required

	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
    
    -- only log if latest revision
    IF v_max_revision_id = in_revision_id THEN 
		FOR r IN (
	        SELECT 	score_water_use,	
					score_energy_use,		
					score_ancillary_req	
 		   FROM gt_scores s, product_revision pr
	      WHERE pr.product_id=s.PRODUCT_ID (+)
	        AND pr.REVISION_ID = s.revision_id(+)
	        AND pr.product_id = in_product_id
			AND pr.revision_id = v_max_revision_id
		)
		LOOP
			-- actually only ever going to be single row as product id and revision id are PK
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_WATER_USE, r.score_water_use, in_score_water_use);
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_ENERGY_USE, r.score_energy_use, in_score_energy_use);
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_ANCILLARY_REQ, r.score_ancillary_req, in_score_ancillary_req);		
				
		END LOOP;
	END IF;

	BEGIN
		INSERT INTO gt_scores 
			(product_id, revision_id, score_water_use, score_energy_use, score_ancillary_req) 
		VALUES
			(in_product_id, in_revision_id, in_score_water_use, in_score_energy_use, in_score_ancillary_req) ;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE gt_scores SET
			    score_water_use		=	in_score_water_use,
			    score_energy_use	=	in_score_energy_use,
			    score_ancillary_req	=	in_score_ancillary_req
			WHERE product_id 		= 	in_product_id
			AND revision_id 		= 	in_revision_id;
	END;
	
END;

/*
PROCEDURE SetGiftScoreUseAtHomeGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id				IN product_revision.revision_id%TYPE,
    in_score_water_use			IN gt_scores.score_water_use%TYPE,
    in_score_energy_use			IN gt_scores.score_energy_use%TYPE,
    in_score_ancillary_req		IN gt_scores.score_ancillary_req%TYPE
)
AS
BEGIN
	
-- Water in Use
-- Energy in Use
-- Ancillary Materials Required

	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	BEGIN
		INSERT INTO gt_scores_gift 
			(product_id, revision_id, score_water_use, score_energy_use, score_ancillary_req) 
		VALUES
			(in_product_id, in_revision_id, in_score_water_use, in_score_energy_use, in_score_ancillary_req) ;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE gt_scores_gift SET
			    score_water_use		=	in_score_water_use,
			    score_energy_use	=	in_score_energy_use,
			    score_ancillary_req	=	in_score_ancillary_req
			WHERE product_id 		= 	in_product_id
			AND revision_id 		= 	in_revision_id;
	END;
	
END;
*/

PROCEDURE SetProfileUseAtHomeGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	in_low_anc_list				IN gt_profile.gt_low_anc_list%TYPE,
	in_med_anc_list				IN gt_profile.gt_med_anc_list%TYPE,
	in_high_anc_list			IN gt_profile.gt_high_anc_list%TYPE
)
AS
BEGIN
	
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	BEGIN
		INSERT INTO gt_profile 
			(product_id, revision_id, gt_low_anc_list, gt_med_anc_list, gt_high_anc_list) 
		VALUES
			(in_product_id, in_revision_id, in_low_anc_list, in_med_anc_list, in_high_anc_list) ;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE gt_profile SET
			    gt_low_anc_list		=	in_low_anc_list,
			    gt_med_anc_list		=	in_med_anc_list,
			    gt_high_anc_list	=	in_high_anc_list
			WHERE product_id 		= 	in_product_id
			AND revision_id 		= 	in_revision_id;
	END;
	
END;


PROCEDURE CalcScoreUseAtHomeGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id				IN product_revision.revision_id%TYPE
)
AS

	v_product_class			gt_product_class.gt_product_class_id%TYPE;
	
	--1 
	v_score_water_use			gt_scores.score_water_use%TYPE;
	--2
	v_score_energy_use			gt_scores.score_energy_use%TYPE;
	--3
	v_score_ancillary_req		gt_scores.score_ancillary_req%TYPE;
	v_gt_low_anc_list			gt_profile.gt_low_anc_list%TYPE;
	v_gt_med_anc_list			gt_profile.gt_med_anc_list%TYPE;
	v_gt_high_anc_list			gt_profile.gt_high_anc_list%TYPE;
	
	/*-- gift scores
	--1
	v_gift_score_water_use			gt_scores.score_water_use%TYPE;
	min_score_water_use			gt_scores.score_water_use%TYPE;
	-- 2
	v_gift_score_energy_use			gt_scores.score_energy_use%TYPE;
	min_score_energy_use			gt_scores.score_energy_use%TYPE;
	-- 3
	v_gift_score_ancillary_req		gt_scores.score_ancillary_req%TYPE;
	min_score_ancillary_req		gt_scores.score_ancillary_req%TYPE;
	*/
BEGIN
	
	-- find product class up front
	v_product_class := product_info_pkg.GetProductClassId(in_act_id, in_product_id, in_revision_id);
	

	-- 1. Water in Use
	-- 2. Energy in Use
	model_pd_pkg.CalcWaterEnergyUseScores(in_act_id, in_product_id, v_product_class, in_revision_id, v_score_water_use, v_score_energy_use);

	-- 3. Ancillary Materials Required
	-- need not only the max score for ancillary use but to store a list 
	-- of high, med and low acillary materials for profile page
	model_pd_pkg.CalcAncMatScore(in_product_id, v_product_class, in_revision_id, v_score_ancillary_req, v_gt_low_anc_list, v_gt_med_anc_list, v_gt_high_anc_list);
	
	
	-- NOTE - there is no way of setting this to not set - as there do not necessarily have to be any anc mat
	SetScoreUseAtHomeGroup(in_act_id, in_product_id, in_revision_id, v_score_water_use, v_score_energy_use, v_score_ancillary_req);	
	SetProfileUseAtHomeGroup(in_act_id, in_product_id, in_revision_id, v_gt_low_anc_list, v_gt_med_anc_list, v_gt_high_anc_list);
	
/*
	-- now calculate giftpack scores (if needed
	SELECT 
	--1
	SUM(score_water_use * cnt)/SUM(cnt), MIN(NVL(score_water_use,-1)),
	--2 
	SUM(score_energy_use * cnt)/SUM(cnt), MIN(NVL(score_energy_use,-1)),
	-- 3
	MAX(score_ancillary_req), MIN(NVL(score_ancillary_req,-1))	
	INTO 
	v_gift_score_water_use, min_score_water_use, 
	v_gift_score_energy_use, min_score_energy_use,
	v_gift_score_ancillary_req, min_score_ancillary_req
    FROM 
    (
        SELECT p.product_id prod_id, gt.*, lp.cnt 
        FROM gt_scores gt, product p,
        (
            SELECT lp.LINK_PRODUCT_ID, count cnt 
            FROM gt_link_product lp 
            WHERE lp.PRODUCT_ID = in_product_id
            AND revision_id = in_revision_id
        ) lp
        WHERE p.product_id = gt.product_id(+)
        AND p.product_id = lp.LINK_PRODUCT_ID
        AND p.product_id IN 
        (
            SELECT link_product_id FROM gt_link_product 
            WHERE PRODUCT_ID = in_product_id
            AND revision_id = in_revision_id
        ) 
        AND ((revision_id IS NULL) OR (revision_id = (SELECT max(revision_id) FROM gt_scores WHERE product_id = p.product_id)))
        UNION
        SELECT p.product_id prod_id, gt.*, 1 cnt 
        FROM gt_scores gt, product p
        WHERE p.product_id = gt.product_id(+)
        AND p.PRODUCT_ID = in_product_id
        AND revision_id = in_revision_id
    );

	IF min_score_water_use<0 THEN 
		v_gift_score_water_use := -1;
	END IF;
	
	IF min_score_energy_use<0 THEN 
		v_gift_score_energy_use := -1;
	END IF;
	
	IF min_score_ancillary_req<0 THEN 
		v_gift_score_ancillary_req := -1;
	END IF;
	
	SetGiftScoreUseAtHomeGroup(in_act_id, in_product_id, in_revision_id, v_gift_score_water_use, v_gift_score_energy_use, v_gift_score_ancillary_req);	
	*/
--	GetScoreUseAtHomeGroup(in_act_id, in_product_id, in_revision_id, out_cur);

END;

---------------------------------------------
-- Product end of life
---------------------------------------------


PROCEDURE GetScoreEndOfLifeGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id				IN product_revision.revision_id%TYPE,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_cnt					NUMBER;
	v_type_id				gt_product_type.gt_product_type_id%TYPE;
	v_matched_type_id		gt_product_type.gt_product_type_id%TYPE;
	v_range_id				gt_product_answers.gt_product_range_id%TYPE;
	v_matched_range_id		gt_product_answers.gt_product_range_id%TYPE;
	v_app_sid				product.app_sid%TYPE;
BEGIN
	
-- Product Waste
-- Recyclable packaging
-- Recoverable packaging

	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading product with id '||in_product_id);
	END IF;
		
	SELECT app_sid INTO v_app_sid FROM product WHERE product_id = in_product_id;
	
	GetBestMatchTargetScore(in_act_id, in_product_id, in_revision_id, v_type_id, v_matched_type_id, v_range_id, v_matched_range_id);

	OPEN out_cur FOR
		-- Dickie's page expects values in this form so it can be generic
		SELECT 'End of Life' group_name, MAX_SCORE_END_OF_LINE max_score,
		       DECODE(rn, 1, 'Product Waste', 2, 'Recyclable Packaging', 3, 'Recoverable Packaging') score_label,
			   DECODE(rn, 1, 0, 2, 1, 3, 1) score_relates_to_pkg,
			   DECODE(rn, 1, 1, 2, 0, 3, 0) score_relates_to_ingred,
		       DECODE(rn, 1, gt.score_prod_waste, 2, gt.score_recyclable_pack, 3, gt.score_recov_pack) score_value,
	           DECODE(rn, 1, -1, 2, -1, 3, -1) trip_score_value,
		       NVL(DECODE(rn, 1, gtf.score_prod_waste, 2, gtf.score_recyclable_pack, 3, gtf.score_recov_pack), -1) gift_score_value, 
		       NVL(decode(rn, 1, p.min_score_prod_waste, 2, p.min_score_recyclable_pack, 3, p.min_score_recov_pack), -1) min_target_value,
		       NVL(decode(rn, 1, p.max_score_prod_waste, 2, p.max_score_recyclable_pack, 3, p.max_score_recov_pack), -1) max_target_value,
			   DECODE(MAX(NVL(decode(rn, 1, p.min_score_prod_waste, 2, p.min_score_recyclable_pack, 3, p.min_score_recov_pack), -1)) OVER (), -1, 0, 1) use_min_target_value, -- use if any are set (>-1)
			   DECODE(MAX(NVL(decode(rn, 1, p.max_score_prod_waste, 2, p.max_score_recyclable_pack, 3, p.max_score_recov_pack), -1)) OVER (), -1, 0, 1) use_max_target_value		       
        FROM (SELECT rownum rn FROM (SELECT 1 FROM dual GROUP BY cube (1, 2, 3)) WHERE rownum <= 3) r, (
                SELECT p.product_id, gts.* FROM 
                (
                	SELECT p.product_id, v_type_id gt_product_type_id, v_matched_range_id gt_product_range_id
                      FROM product p
                     WHERE p.product_id = in_product_id
                ) p, -- gets type and range id if present  - set to -1 otherwise 
                (
                	SELECT (NVL(gts.gt_product_range_id, -1)) nullable_range, gts.* FROM gt_target_scores gts WHERE gts.app_sid = v_app_sid
                ) gts  
                WHERE p.gt_product_type_id = gts.gt_product_type_id(+)  -- this will only match on correct type
                  AND p.gt_product_range_id = gts. nullable_range(+)     -- OK for null range to match
        ) p,   (
        	SELECT * FROM gt_scores WHERE product_id = in_product_id AND revision_id = in_revision_id
        ) gt, (
        	SELECT * FROM gt_scores_combined WHERE product_id = in_product_id AND revision_id = in_revision_id
        ) gtf
    	WHERE p.product_id = gt.product_id(+)
    	AND p.product_id = gtf.product_id(+);
		
END;

PROCEDURE SetScoreEndOfLifeGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
    in_score_prod_waste			IN gt_scores.score_prod_waste%TYPE,
    in_score_recyclable_pack	IN gt_scores.score_recyclable_pack%TYPE,
    in_score_recov_pack			IN gt_scores.score_recov_pack%TYPE
)
AS
	v_max_revision_id			product_revision.revision_id%TYPE;
BEGIN
	
--Product Waste
--Recyclable packaging
--Recoverable packaging

	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
    -- only log if latest revision
    IF v_max_revision_id = in_revision_id THEN 
		FOR r IN (
	        SELECT 	score_prod_waste,	
					score_recyclable_pack,		
					score_recov_pack	
 		   FROM gt_scores s, product_revision pr
	      WHERE pr.product_id=s.PRODUCT_ID (+)
	        AND pr.REVISION_ID = s.revision_id(+)
	        AND pr.product_id = in_product_id
			AND pr.revision_id = v_max_revision_id
		)
		LOOP
			-- actually only ever going to be single row as product id and revision id are PK
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_PROD_WASTE, r.score_prod_waste, in_score_prod_waste);
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_RECYCLABLE_PACK, r.score_recyclable_pack, in_score_recyclable_pack);
			score_log_pkg.WriteToAuditFromScoreLog(in_act_id, in_product_id, score_log_pkg.ID_SCORE_RECOV_PACK, r.score_recov_pack, in_score_recov_pack);		
				
		END LOOP;
	END IF;

	BEGIN
		INSERT INTO gt_scores 
			(product_id, revision_id, score_prod_waste, score_recyclable_pack, score_recov_pack) 
		VALUES
			(in_product_id, in_revision_id, in_score_prod_waste, in_score_recyclable_pack, in_score_recov_pack) ;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE gt_scores SET
			    score_prod_waste		=	in_score_prod_waste,
			    score_recyclable_pack	=	in_score_recyclable_pack,
			    score_recov_pack		=	in_score_recov_pack
			WHERE product_id 			= 	in_product_id
			AND revision_id 			= in_revision_id;
	END;
	
END;

/*
PROCEDURE SetGiftScoreEndOfLifeGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
    in_score_prod_waste			IN gt_scores.score_prod_waste%TYPE,
    in_score_recyclable_pack	IN gt_scores.score_recyclable_pack%TYPE,
    in_score_recov_pack			IN gt_scores.score_recov_pack%TYPE
)
AS
BEGIN
	
--Product Waste
--Recyclable packaging
--Recoverable packaging

	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	BEGIN
		INSERT INTO gt_scores_gift 
			(product_id, revision_id, score_prod_waste, score_recyclable_pack, score_recov_pack) 
		VALUES
			(in_product_id, in_revision_id, in_score_prod_waste, in_score_recyclable_pack, in_score_recov_pack) ;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE gt_scores_gift SET
			    score_prod_waste		=	in_score_prod_waste,
			    score_recyclable_pack	=	in_score_recyclable_pack,
			    score_recov_pack		=	in_score_recov_pack
			WHERE product_id 			= 	in_product_id
			AND revision_id 			= in_revision_id;
	END;
	
END;
*/

PROCEDURE SetProfileEndOfLifeGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	in_ratio_prod_pck_wght_pct  IN gt_profile.ratio_prod_pck_wght_pct%TYPE,
    in_biopolymer_used          IN gt_profile.biopolymer_used%TYPE, 
    in_biopolymer_list          IN gt_profile.biopolymer_list%TYPE,
    in_recyclable_pack_pct      IN gt_profile.recyclable_pack_pct%TYPE,  
    in_recoverable_pack_pct     IN gt_profile.recoverable_pack_pct%TYPE
)
AS
BEGIN
	
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	BEGIN
		INSERT INTO gt_profile 
			(product_id, revision_id, ratio_prod_pck_wght_pct, biopolymer_used, biopolymer_list, 
				recyclable_pack_pct, recoverable_pack_pct) 
		VALUES
			(in_product_id, in_revision_id, in_ratio_prod_pck_wght_pct, in_biopolymer_used, in_biopolymer_list, 
				in_recyclable_pack_pct, in_recoverable_pack_pct) ;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE gt_profile SET
				ratio_prod_pck_wght_pct		= in_ratio_prod_pck_wght_pct,
				biopolymer_used				= in_biopolymer_used,        
				biopolymer_list				= in_biopolymer_list,        
				recyclable_pack_pct			= in_recyclable_pack_pct,    
				recoverable_pack_pct		= in_recoverable_pack_pct
			WHERE product_id 		= 	in_product_id
			AND	revision_id		= in_revision_id;
	END;
	
END;


PROCEDURE CalcScoreEndOfLifeGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id				IN product_revision.revision_id%TYPE
)
AS
	v_product_class			gt_product_class.gt_product_class_id%TYPE;	

	--1 
	v_score_prod_waste			gt_scores.score_prod_waste%TYPE;
	--2
	v_pack_recyclable_weight	gt_pack_item.weight_grams%TYPE;
	v_pack_weight_total			gt_pack_item.weight_grams%TYPE;	
	v_score_recyclable_pack		gt_scores.score_recyclable_pack%TYPE;
	v_correct_biopolymer_use	gt_packaging_answers.correct_biopolymer_use%TYPE;
	v_pack_recyclable_pct		NUMBER(6,3);
	v_on_pack_recycling_adv		gt_product_answers.on_pack_recycling_adv%TYPE;
	--3
	v_pack_recoverable_weight	gt_pack_item.weight_grams%TYPE;
	v_score_recov_pack			gt_scores.score_recov_pack%TYPE;
	v_pack_recoverable_pct		NUMBER(6,3);

	-- profile 
	v_prod_weight				gt_product_answers.prod_weight%TYPE;
	v_prod_weight_exc_pack		gt_product_answers.prod_weight%TYPE;
	v_inc_pkg					gt_product_answers.prod_weight%TYPE;	

    v_biopolymer_used          	gt_profile.biopolymer_used%TYPE; 
    v_biopolymer_list          	gt_profile.biopolymer_list%TYPE; 

    v_ratio_prod_pck_wght_pct  	gt_profile.ratio_prod_pck_wght_pct%TYPE;
    
	-- gift score
	-- 1
	v_gift_score_prod_waste			gt_scores.score_prod_waste%TYPE;
	min_score_prod_waste			gt_scores.score_prod_waste%TYPE;
	-- 2
	v_gift_score_recyclable_pack	gt_scores.score_recyclable_pack%TYPE;
	min_score_recyclable_pack		gt_scores.score_recyclable_pack%TYPE;
	-- 3
	v_gift_score_recov_pack			gt_scores.score_recov_pack%TYPE;
	min_score_recov_pack			gt_scores.score_recov_pack%TYPE;
	
BEGIN
	-- find product class up front
	v_product_class := product_info_pkg.GetProductClassId(in_act_id, in_product_id, in_revision_id);
	
	-- get as much up front as possible
	SELECT 
		-- used in calcs for 2 and 3
		NVL(pa.correct_biopolymer_use,-1) correct_biopolymer_use, 
		NVL(prod_weight,-1) prod_weight,
		weight_inc_pkg, 
		NVL(prda.on_pack_recycling_adv, -1)
	 INTO v_correct_biopolymer_use, v_prod_weight, v_inc_pkg, v_on_pack_recycling_adv
	 FROM all_product p, gt_packaging_answers pa, gt_product_answers prda
	WHERE p.product_id = pa.product_id(+)
	  AND p.product_id = prda.product_id(+)
	  AND p.product_id = in_product_id
	  AND ((pa.revision_id = in_revision_id) OR (pa.revision_id IS NULL))
	  AND ((prda.revision_id = in_revision_id) OR (prda.revision_id IS NULL));
	
    SELECT  
			-- 2 
			NVL(SUM(pack_recyclable_weight),-1) pack_recyclable_weight, 
			NVL(SUM(pack_weight_total),-1) pack_weight_total, 
			NVL(SUM(pack_recoverable_weight),-1) pack_recoverable_weight,
			NVL(MAX(biopolymer),-1) biopolymer_used,
			csr.stragg(DECODE(biopolymer,1,material_desc || ' ' || shape_desc,null)) biopolymer_list
     INTO v_pack_recyclable_weight, v_pack_weight_total, v_pack_recoverable_weight, v_biopolymer_used, v_biopolymer_list
     FROM 
    (
        SELECT weight_grams pack_weight_total, biopolymer, material_desc, shape_desc, 
        CASE
            WHEN ((v_correct_biopolymer_use=1) AND ((recyclable=1)OR(biopolymer=1))) THEN weight_grams
            WHEN (recyclable=1) THEN weight_grams
            ELSE 0
        END pack_recyclable_weight,
        CASE
            WHEN (recoverable=1) THEN weight_grams
            ELSE 0
        END pack_recoverable_weight
        FROM gt_pack_item pi,
        (
            SELECT smm.gt_pack_shape_type_id, smm.gt_pack_material_type_id, recyclable, recoverable, biopolymer, pmt.description material_desc, pst.description shape_desc 
                FROM gt_pack_material_type pmt, gt_pack_shape_type pst, gt_shape_material_mapping smm
                WHERE smm.gt_pack_material_type_id = pmt.gt_pack_material_type_id
        		AND smm.gt_pack_shape_type_id = pst.gt_pack_shape_type_id
        ) mat
            WHERE pi.gt_pack_material_type_id = mat.gt_pack_material_type_id
            AND pi.gt_pack_shape_type_id = mat.gt_pack_shape_type_id
            AND pi.product_id = in_product_id
            AND pi.revision_id = in_revision_id
    );
	
	
	
	-- Now we need to make sure the prod weight is adjusted to be exc packging
	IF v_inc_pkg = 1 THEN
		IF (v_prod_weight < 0) OR (v_pack_weight_total < 0) THEN
			-- can't calc this yet
			v_prod_weight_exc_pack := -1;
		ELSE
			v_prod_weight_exc_pack := v_prod_weight - v_pack_weight_total;
		END IF;
		
		-- if the packaging weighs more that the product they can't calc score at the moment
		IF v_prod_weight_exc_pack < 0 THEN 
			v_prod_weight_exc_pack := -1; -- not set 
		END IF;
	ELSE
		v_prod_weight_exc_pack := v_prod_weight; -- don't have to consider what is or isn't set
	END IF;

	-- 1. Product Waste
	model_pd_pkg.CalcProductWaste(in_act_id, in_product_id, v_product_class, in_revision_id, v_score_prod_waste);

	
	-- 2. Recyclable packaging
	-- weight = "sum of weight of packaging parts marked as recyclable"
	-- if ("biopolymer use correct" = true) weight=weight+ "sum of weight of packaging parts marked as biopolymer")
	-- % recyclable = recyclable weight / total weight of packaging * 100%
	-- % recyclable=0 					-> 5
	-- % recyclable<=25			 		-> 4
	-- % recyclable<=75			 		-> 3
	-- % recyclable>75			 		-> 2
	
	v_score_recyclable_pack := -1;
	v_pack_recyclable_pct := -1;
	IF ((v_pack_recyclable_weight>=0) AND (v_pack_weight_total>=0)) THEN
		CASE
			WHEN ((v_pack_recyclable_weight=0) AND (v_pack_weight_total=0)) THEN v_score_recyclable_pack :=5;
			WHEN (v_pack_weight_total=0) THEN v_score_recyclable_pack := 2;
			ELSE	
				v_pack_recyclable_pct:=100*(v_pack_recyclable_weight/v_pack_weight_total);
				CASE 
				  WHEN v_pack_recyclable_pct<=0 THEN v_score_recyclable_pack := 5;
				  WHEN v_pack_recyclable_pct<=25 THEN v_score_recyclable_pack := 4;
				  WHEN v_pack_recyclable_pct<=75 THEN v_score_recyclable_pack := 3;
				  WHEN v_pack_recyclable_pct>75 THEN v_score_recyclable_pack := 2;
				  ELSE v_score_recyclable_pack := -1;
				END CASE;
		END CASE;
	END IF;
	
	--Final modifier: On the Product Info questionnaire if the answer to “Recycling the product packaging” is Yes then the score gets a credit of -1 (though the score may never be less that 0)	
	IF v_score_recyclable_pack >= 0 THEN
		IF v_on_pack_recycling_adv >= 0 THEN 
			--gets credit if v_on_pack_recycling_adv = YES (1)
			v_score_recyclable_pack := v_score_recyclable_pack - (1 * v_on_pack_recycling_adv);
			-- but can't be made less than 0
			IF v_score_recyclable_pack < 0 THEN 
				v_score_recyclable_pack := 0;
			END IF;
		ELSE
			-- if the recycling packaging advice question is not answered (1 or 0) we can't score - reset to -1
			v_score_recyclable_pack := -1;			
		END IF;
	END IF;
	

	-- 3. Recoverable packaging
	-- LOGIC: 
	-- weight = "sum of weight of packaging parts marked as Recoverable"
	-- %Recoverable = Recoverable weight / total weight of packaging * 100%
	-- %Recoverable <= 99			-> 5
	-- %Recoverable > 99			-> 3
	v_score_recov_pack := -1;
	v_pack_recoverable_pct := -1;
	IF ((v_pack_recyclable_weight>=0) AND (v_pack_weight_total>=0)) THEN
		CASE
			WHEN ((v_pack_recoverable_weight=0) AND (v_pack_weight_total=0)) THEN v_score_recov_pack :=5;
			WHEN (v_pack_weight_total=0) THEN v_score_recov_pack := 3;
			ELSE
				v_pack_recoverable_pct := 100*(v_pack_recoverable_weight/v_pack_weight_total);
				CASE 
				  WHEN v_pack_recoverable_pct<=99 THEN v_score_recov_pack := 5;
				  WHEN v_pack_recoverable_pct>99 THEN v_score_recov_pack := 3;
				  ELSE v_score_recov_pack := -1;
				END CASE;
		END CASE;
	END IF;
	
	SetScoreEndOfLifeGroup(in_act_id, in_product_id, in_revision_id, v_score_prod_waste, v_score_recyclable_pack, v_score_recov_pack);	

	v_ratio_prod_pck_wght_pct := -1;
	IF ((v_pack_weight_total>=0) AND (v_prod_weight_exc_pack>=0)) THEN
		CASE 
			WHEN ((v_pack_weight_total=0) OR (v_prod_weight_exc_pack=0)) THEN v_ratio_prod_pck_wght_pct := -1;
			WHEN (v_prod_weight_exc_pack) = 0 THEN v_ratio_prod_pck_wght_pct := -1;
			ELSE
				v_ratio_prod_pck_wght_pct := 100*(v_pack_weight_total/(v_prod_weight_exc_pack));
		END CASE;
	END IF;

	SetProfileEndOfLifeGroup(in_act_id, in_product_id, in_revision_id, v_ratio_prod_pck_wght_pct, v_biopolymer_used, v_biopolymer_list, v_pack_recyclable_pct, v_pack_recoverable_pct);

	/*
	-- now calculate giftpack scores (if needed
	SELECT 
	--1
	SUM(score_prod_waste * cnt)/SUM(cnt), MIN(NVL(score_prod_waste,-1)),
	--2 
	SUM(score_recyclable_pack * cnt)/SUM(cnt), MIN(NVL(score_recyclable_pack,-1)),
	-- 3
	SUM(score_recov_pack * cnt)/SUM(cnt), MIN(NVL(score_recov_pack,-1))	
	INTO 
	v_gift_score_prod_waste, min_score_prod_waste, 
	v_gift_score_recyclable_pack, min_score_recyclable_pack,
	v_gift_score_recov_pack, min_score_recov_pack
    FROM 
    (
        SELECT p.product_id prod_id, gt.*, lp.cnt 
        FROM gt_scores gt, product p,
        (
            SELECT lp.LINK_PRODUCT_ID, count cnt 
            FROM gt_link_product lp 
            WHERE lp.PRODUCT_ID = in_product_id
            AND revision_id = in_revision_id
        ) lp
        WHERE p.product_id = gt.product_id(+)
        AND p.product_id = lp.LINK_PRODUCT_ID
        AND p.product_id IN 
        (
            SELECT link_product_id FROM gt_link_product 
            WHERE PRODUCT_ID = in_product_id
            AND revision_id = in_revision_id
        ) 
        AND ((revision_id IS NULL) OR (revision_id = (SELECT max(revision_id) FROM gt_scores WHERE product_id = p.product_id)))
        UNION
        SELECT p.product_id prod_id, gt.*, 1 cnt 
        FROM gt_scores gt, product p
        WHERE p.product_id = gt.product_id(+)
        AND p.PRODUCT_ID = in_product_id
        AND revision_id = in_revision_id
    );


	IF min_score_prod_waste<0 THEN 
		v_gift_score_prod_waste := -1;
	END IF;
	
	IF min_score_recyclable_pack<0 THEN 
		v_gift_score_recyclable_pack := -1;
	END IF;
	
	IF min_score_recov_pack<0 THEN 
		v_gift_score_recov_pack := -1;
	END IF;

	SetGiftScoreEndOfLifeGroup(in_act_id, in_product_id, in_revision_id, v_gift_score_prod_waste, v_gift_score_recyclable_pack, v_gift_score_recov_pack);
	*/
	
--	GetScoreEndOfLifeGroup(in_act_id, in_product_id, in_revision_id, out_cur);
	
END;

FUNCTION IsLastRevisionModelComplete(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE
) RETURN NUMBER
AS
	v_max_revision_id				product_revision.revision_id%TYPE;
BEGIN
    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;	
	
	RETURN IsModelComplete(in_act_id, in_product_id, v_max_revision_id);
END;

FUNCTION IsModelComplete(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE
) RETURN NUMBER
AS
	v_complete 				   NUMBER;
	v_score_nat_derived        NUMBER;
	v_score_chemicals          NUMBER;
	v_score_source_biod        NUMBER;
	v_score_accred_biod        NUMBER;
	v_score_fair_trade         NUMBER;
	v_score_renew_pack         NUMBER;
	v_score_whats_in_prod      NUMBER;
	v_score_water_in_prod      NUMBER;
	v_score_energy_in_prod     NUMBER;
	v_score_pack_impact        NUMBER;
	v_score_pack_opt           NUMBER;
	v_score_recycled_pack      NUMBER;
	v_score_supp_management    NUMBER;
	v_score_trans_raw_mat      NUMBER;
	v_score_trans_to_boots     NUMBER;
	v_score_trans_packaging    NUMBER;
	v_score_trans_opt          NUMBER;
	v_score_energy_dist        NUMBER;
	v_score_water_use          NUMBER;
	v_score_energy_use         NUMBER;
	v_score_ancillary_req      NUMBER;
	v_score_prod_waste         NUMBER;
	v_score_recyclable_pack    NUMBER;
	v_score_recov_pack 		   NUMBER;
	v_is_no_packaging		   NUMBER;
	v_prod_class_id		   	   NUMBER;
BEGIN
	
	SELECT COUNT(*)
		INTO v_complete 
	FROM gt_scores gts, product p
		WHERE p.product_id = gts.product_id (+) 
		AND p.product_id = in_product_id
		AND gts.revision_id = in_revision_id;
	
	IF (v_complete=0) THEN 
		RETURN v_complete;
	END IF;
	
	SELECT 
	    score_nat_derived       ,
	    score_chemicals          ,
	    score_source_biod        ,
	    score_accred_biod        ,
	    score_fair_trade         ,
	    score_renew_pack         ,
	    score_whats_in_prod      ,
	    score_water_in_prod      ,
	    score_energy_in_prod     ,
	    score_pack_impact        ,
	    score_pack_opt           ,
	    score_recycled_pack      ,
	    score_supp_management    ,
	    score_trans_raw_mat      ,
	    score_trans_to_boots     ,
	    score_trans_packaging    ,
	    score_trans_opt          ,
	    score_energy_dist        ,
	    score_water_use          ,
	    score_energy_use         ,
	    score_ancillary_req      ,
	    score_prod_waste         ,
	    score_recyclable_pack    ,
	    score_recov_pack
	INTO 
		v_score_nat_derived       ,
	    v_score_chemicals          ,
	    v_score_source_biod        ,
	    v_score_accred_biod        ,
	    v_score_fair_trade         ,
	    v_score_renew_pack         ,
	    v_score_whats_in_prod      ,
	    v_score_water_in_prod      ,
	    v_score_energy_in_prod     ,
	    v_score_pack_impact        ,
	    v_score_pack_opt           ,
	    v_score_recycled_pack      ,
	    v_score_supp_management    ,
	    v_score_trans_raw_mat      ,
	    v_score_trans_to_boots     ,
	    v_score_trans_packaging    ,
	    v_score_trans_opt          ,
		v_score_energy_dist		   ,
	    v_score_water_use          ,
	    v_score_energy_use         ,
	    v_score_ancillary_req      ,
	    v_score_prod_waste         ,
	    v_score_recyclable_pack    ,
	    v_score_recov_pack
	FROM gt_scores gts, product p
	WHERE p.product_id = gts.product_id (+) 
	AND p.product_id = in_product_id
	AND gts.revision_id = in_revision_id;
	
	
	-- After phase III, we could have more than one combination of set of questionnaires
	-- > Formulation - normal product (PI, F, PK, T, S)
	-- > Manufactured - normal product (PI, PD, PK, T, S)
	-- > Formulation - sub product (PI, F, PK, T, S)
	-- > Manufactured - sub product (PI, PD, PK, T, S)
	-- > Formulation - normal product - wrapper (no GTFormulation) (PI, PK, T, S)
	-- > Manufactured - normal product - wrapper (no GTProductDesign) (PI, PK, T, S)
	-- > Formulation - sub product - no packaging (PI, F, T, S)
	-- > Manufactured - sub product - no packaging (PI, PD, T, S)
	
	-- First, test common questionnaire (PI, T, S) scores:  
	IF NOT (( v_score_fair_trade      	>=0) AND
			( v_score_supp_management	>=0) AND
			( v_score_trans_raw_mat     >=0) AND
			( v_score_trans_to_boots    >=0) AND
			( v_score_water_use  		>=0) AND
			( v_score_energy_dist  		>=0) AND
			( v_score_energy_use    	>=0))
	THEN 
	  RETURN 0;
	END IF;
	
	
	-- Is no packaging?
	SELECT COUNT(pt.product_id) INTO v_is_no_packaging 
	  FROM product_tag pt, tag t 
	 WHERE pt.tag_id = t.tag_id 
	   AND t.tag = 'withoutPackaging'
       AND pt.product_id = in_product_id;

	   
	-- Second, test packaging questionnaire (if relevant),
	IF (v_is_no_packaging = 0) THEN
		IF NOT (( v_score_renew_pack    	>=0) AND
				( v_score_pack_opt     		>=0) AND
				( v_score_pack_impact		>=0) AND
				( v_score_recycled_pack 	>=0) AND
				( v_score_trans_packaging	>=0) AND
				( v_score_trans_opt     	>=0) AND
				( v_score_recyclable_pack 	>=0) AND
				( v_score_recov_pack    	>=0))
		THEN 
		  RETURN 0;
		END IF;
	END IF;
		   
	-- get product class
	v_prod_class_id := product_info_pkg.GetProductClassId(in_act_id, in_product_id, in_revision_id);
	
	IF (v_prod_class_id = model_pd_pkg.PROD_CLASS_FORMULATED OR v_prod_class_id = model_pd_pkg.PROD_CLASS_MANUFACTURED OR v_prod_class_id = model_pd_pkg.PROD_CLASS_FOOD) THEN 	-- Formulated,Manufactured
		IF NOT (( v_score_nat_derived   	>=0) AND
				( v_score_chemicals     	>=0) AND
				( v_score_source_biod 		>=0) AND
				( v_score_accred_biod		>=0) AND
				( v_score_water_in_prod     >=0) AND
				( v_score_energy_in_prod   	>=0) AND
				( v_score_whats_in_prod 	>=0) AND
				( v_score_prod_waste	 	>=0) AND
				( v_score_ancillary_req 	>=0))
		THEN 
		  RETURN 0;
		END IF;
	END IF;
	
	-- if all relevant scores are present, the model is complete
	RETURN 1;
END;

PROCEDURE GetSocialAmplificationScores (
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN security_pkg.T_SID_ID,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_sustainable_cur 			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_sustainable_cur FOR
		SELECT i.description issue, q.default_gt_sa_score score
		  FROM gt_sa_issue i, gt_sa_question q, gt_food_sa_q p 
		 WHERE p.gt_sa_question_id = q.gt_sa_question_id
		   AND i.gt_sa_issue_id = q.gt_sa_issue_id
		   AND p.product_id = in_product_id
		   AND p.revision_id = in_revision_id;	
END;

PROCEDURE GetSAFootprint (
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN security_pkg.T_SID_ID,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_socamp_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_socamp_cur FOR
		SELECT q.default_gt_sa_score score, i.description issue, csr.stragg(q.question_name || '###') questions
		FROM gt_sa_question q, gt_sa_issue i, gt_food_sa_q p 
		WHERE i.gt_sa_issue_id = q.gt_sa_issue_id 
		AND p.gt_sa_question_id = q.gt_sa_question_id 
		AND p.product_id = in_product_id
		AND p.revision_id = in_revision_id
		GROUP BY i.description, q.default_gt_sa_score
		UNION
		SELECT fit.default_gt_sa_score, 'Ingredients' issue, csr.stragg('Contains ' || fit.description || '###') questions
		FROM (
			SELECT DISTINCT gt_fd_ingred_type_id ingred_type_id
			FROM gt_fd_ingredient fi
			WHERE product_id = in_product_id
			AND revision_id = in_revision_id
		) ingred_type_list, gt_sa_ingred_prod_type saipt, gt_product_rev gtp, gt_fd_ingred_type fit
		WHERE fit.gt_fd_ingred_type_id = ingred_type_list.ingred_type_id
		AND saipt.gt_fd_ingred_type_id = ingred_type_list.ingred_type_id
		AND gtp.gt_product_type_id = saipt.gt_product_type_id
		AND gtp.product_id = in_product_id
		AND gtp.revision_id = in_revision_id
		GROUP BY fit.default_gt_sa_score;
END;

PROCEDURE GetSAChildFootprint (
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN security_pkg.T_SID_ID,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_socamp_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_socamp_cur FOR
		SELECT MAX(q.default_gt_sa_score) score, pr.product_id product_id, pr.description questions, pr.product_code product_code
		FROM gt_sa_question q, gt_food_sa_q p, gt_link_product lp, product pr
		WHERE lp.product_id = in_product_id
		AND lp.revision_id = in_revision_id
		AND p.product_id = lp.link_product_id
		AND pr.product_id = p.product_id
		AND p.revision_id IN (SELECT MAX(revision_id) FROM product_revision WHERE product_id = pr.product_id)
		AND p.gt_sa_question_id = q.gt_sa_question_id
		GROUP BY pr.description, pr.product_id, pr.product_code;
END;

PROCEDURE GetSAProfile (
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN security_pkg.T_SID_ID,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_socamp_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_socamp_cur FOR
		SELECT csr.stragg(default_gt_sa_score || '###') score, csr.stragg(question_name || '###') question_name, csr.stragg(NVL(help_text, ' ') || '###') explanation --using the help text for the explanation column in the social amp profile report - might need new column
		FROM (
			SELECT q.default_gt_sa_score, q.question_name, q.help_text
			FROM gt_sa_question q, gt_food_sa_q p
			WHERE p.gt_sa_question_id = q.gt_sa_question_id 
			AND p.product_id = in_product_id
			AND p.revision_id = in_revision_id
			UNION
			SELECT fit.default_gt_sa_score, fit.description question_name, ' ' help_text
			FROM (
				SELECT DISTINCT gt_fd_ingred_type_id ingred_type_id
				FROM gt_fd_ingredient fi
				WHERE product_id = in_product_id
				AND revision_id = in_revision_id
			) ingred_type_list, gt_fd_ingred_type fit, gt_sa_ingred_prod_type saipt, gt_product_rev gtp
			WHERE fit.gt_fd_ingred_type_id = saipt.gt_fd_ingred_type_id
			AND saipt.gt_product_type_id = gtp.gt_product_type_id
			AND gtp.product_id = in_product_id
			AND gtp.revision_id = in_revision_id
			AND fit.gt_fd_ingred_type_id = ingred_type_list.ingred_type_id
		);
END;


END model_pkg;
/
