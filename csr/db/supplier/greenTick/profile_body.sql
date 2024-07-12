create or replace package body supplier.profile_pkg
IS

PROCEDURE GetProductProfile (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id		IN product_revision.revision_id%TYPE,
	out_profile			OUT	security_pkg.T_OUTPUT_CUR,
	out_biodiv			OUT	security_pkg.T_OUTPUT_CUR,
	out_source			OUT	security_pkg.T_OUTPUT_CUR,
	out_transport		OUT	security_pkg.T_OUTPUT_CUR,
	out_scores			OUT	security_pkg.T_OUTPUT_CUR,
	out_socamp			OUT security_pkg.T_OUTPUT_CUR
) 
AS
BEGIN
	-- Recalc scores
	model_pkg.CalcProductScores(in_act_id, in_product_id, in_revision_id);
	
	GetProductProfileData(in_act_id, in_product_id, in_revision_id, out_profile);
	GetBiodiversityChartData(in_act_id, in_product_id, in_revision_id, out_biodiv);
	GetSourceChartData(in_act_id, in_product_id, in_revision_id, out_source);
	GetTransportToBootsData(in_act_id, in_product_id, in_revision_id, out_transport);
	model_pkg.GetSAProfile(in_act_id, in_product_id, in_revision_id, out_socamp);
	
	-- Get the score data
	OPEN out_scores FOR
		SELECT product_id, revision_id,
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
			score_recov_pack
		FROM gt_scores
	   WHERE product_id = in_product_id
	     AND revision_id = in_revision_id;
END;


PROCEDURE GetProductProfileData (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id		IN product_revision.revision_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
) 
AS
	v_number_ingredients 	NUMBER(10);
	v_am_required			VARCHAR2(6);
	v_natural_derived_pct	NUMBER(6,3);
	v_threatened_pct		NUMBER(6,3);
	v_product_class_id	gt_product_class.gt_product_class_id%TYPE;
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	v_product_class_id := product_info_pkg.GetProductClassId(in_act_id, in_product_id, in_revision_id);
	
	-- there are a few values that are class dependant as to how they are calc'd	
	CASE 
		WHEN v_product_class_id = model_pd_pkg.PROD_CLASS_FORMULATED THEN 
		
				SELECT ingredient_count,
					  (SELECT DECODE(COUNT(*), 0, 'No', 'Yes') 
						 FROM gt_fa_anc_mat 
						WHERE product_id = in_product_id
						  AND revision_id = in_revision_id
						  AND gt_ancillary_material_id <> 1) 
					   am_required,
						(fa.bp_crops_pct + 
						fa.bp_fish_pct +
						fa.bp_palm_pct +
						fa.bp_palm_processed_pct +
						fa.bp_wild_pct)
						natural_derived_pct, 
						fa.bp_threatened_pct
				  INTO
					  v_number_ingredients, 
					  v_am_required,		
					  v_natural_derived_pct,
					  v_threatened_pct
				  FROM product p, gt_formulation_answers fa
				 WHERE p.product_id = fa.product_id(+)
				   AND p.product_id = in_product_id
				   AND ((fa.revision_id IS NULL) OR (revision_id = in_revision_id));

	  
		WHEN v_product_class_id = model_pd_pkg.PROD_CLASS_MANUFACTURED THEN
				  SELECT   ingredient_count, natural_derived_pct, 
						(SELECT DECODE(COUNT(*), 0, 'No', 'Yes') 
						 FROM gt_pda_anc_mat 
						WHERE product_id = in_product_id
						  AND revision_id = in_revision_id
						  AND gt_ancillary_material_id <> 1) 
					   am_required  
				  INTO
					  v_number_ingredients, 	
					  v_natural_derived_pct,
					  v_am_required					  
				  FROM (
					  SELECT SUM(NVL2(gt_pda_material_item_id, 1, 0)) ingredient_count,
							 SUM(DECODE(mi.natural, 1, mi.pct_of_product, 0)) natural_derived_pct
						FROM product p, (
							SELECT * 
							  FROM gt_pda_material_item mi, gt_material m
							 WHERE mi.gt_material_id = m.gt_material_id) mi 
					   WHERE p.product_ID = mi.product_id(+)
						 AND p.product_id = in_product_id
						 AND ((mi.revision_id IS NULL) OR (mi.revision_id = in_revision_id))
					);
					
					-- add one if endagered materials
					SELECT DECODE(endangered_pct, NULL, 0, 0, 0, 1) + v_number_ingredients, NVL(endangered_pct,0)
					  INTO v_number_ingredients , v_threatened_pct
					  FROM product p, (
						SELECT product_id, revision_id, endangered_pct 
						  FROM gt_pdesign_answers
						 WHERE product_id = in_product_id 
						   AND revision_id = in_revision_id
						 )
						 pda 
					  WHERE p.product_id = pda.product_id(+)
					    AND p.product_id = in_product_id 
					    AND ((pda.revision_id IS NULL) OR (pda.revision_id = in_revision_id));
					
		WHEN v_product_class_id = model_pd_pkg.PROD_CLASS_FOOD THEN
				  SELECT ingredient_count,
						(SELECT DECODE(COUNT(*), 0, 'No', 'Yes') 
						 FROM gt_food_anc_mat 
						WHERE product_id = in_product_id
						  AND revision_id = in_revision_id
						  AND gt_ancillary_material_id <> 1) am_required  
				  INTO
					  v_number_ingredients, 	
					  v_am_required					  
				  FROM (
					  SELECT SUM(NVL2(gt_fd_ingredient_id, 1, 0)) ingredient_count
							 
						FROM product p, (
							SELECT * 
							  FROM gt_fd_ingredient fi, gt_fd_ingred_type ft
							 WHERE fi.gt_fd_ingred_type_id = ft.gt_fd_ingred_type_id) fi 
					   WHERE p.product_id = fi.product_id(+)
						 AND p.product_id = in_product_id
						 AND ((fi.revision_id IS NULL) OR (fi.revision_id = in_revision_id))
					);
					
					-- add one if endagered materials
					SELECT DECODE(pct_high_risk, NULL, 0, 0, 0, 1) + v_number_ingredients, NVL(pct_high_risk,0)
					  INTO v_number_ingredients , v_threatened_pct
					  FROM product p, (
						SELECT product_id, revision_id, pct_high_risk 
						  FROM gt_food_answers
						 WHERE product_id = in_product_id 
						   AND revision_id = in_revision_id
						 )
						 fooda
					  WHERE p.product_id = fooda.product_id(+)
					    AND p.product_id = in_product_id 
					    AND ((fooda.revision_id IS NULL) OR (fooda.revision_id = in_revision_id));
						
		WHEN v_product_class_id = model_pd_pkg.PROD_CLASS_PARENT_PACK THEN 
		
			-- do nothing
			NULL;

		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown product class ('||v_product_class_id||')');
	END CASE;

	OPEN out_cur FOR
		SELECT 
			product_code,
			product_name,
			prod_weight_desc,
			pack_risk_desc,
			pack_risk_colour,
			v_number_ingredients number_ingredients, 
			v_am_required am_required, 
			low_impact_am_used,
			medium_impact_am_used,
			high_impact_am_used,
			water_content,
			water_in_use,
			available_product_waste,
			energy_in_production,
			energy_in_use,
			v_natural_derived_pct natural_derived_pct,
			v_threatened_pct threatened_pct,
			envio_risk_level,	
			pct_pkg_to_product,
			score_pack_impact_raw,
			-- get individual packaging and materials environmental impact score out of the gt_profile_report view
			pack_ei,
			materials_ei,
			trans_pack_ei,
			score_water_raw_mat,
			score_water_mnfct,
			score_water_wsr,
			score_water_contained,
			refillable_reusable,
			concentrates,
			materials_from_renewable_pct,
			biopolimers_used,
			recyclable_pct,
			total_trans_pack_weight,
			recoverable_pct,
			pkg_recycled_content,
			boots_transit_pkg_requirements,
			shelf_ready_pkg,
			tm_recycled_content,
			num_packs_per_outer, 
			rmdt_product_within_pct,
			rmdt_product_between_pct,
			rmdt_product_unknown_pct,
			rmdt_pkg_within_pct,
			rmdt_pkg_between_pct,
			rmdt_pkg_unknown_pct,
			management_status,
			fair_trade_status,
			DECODE(community_trade_pct, -1, 0, community_trade_pct) community_trade_pct,
			DECODE(fairtrade_pct, -1, 0, fairtrade_pct) fairtrade_pct,
			DECODE(other_fair_pct, -1, 0, other_fair_pct) other_fair_pct,
			DECODE(not_fair_pct, -1, 0, not_fair_pct) not_fair_pct,
			reduce_energy_use_adv,
			reduce_water_use_adv,
			reduce_waste_adv, 
			on_pack_recycling_adv,
			country_of_origin,
		--
			merchant_type,
			gt_product_range,
			gt_product_type,
			prod_total_weight,
			retail_packaging_weight,
			packaging_volume,
			product_volume,
			product_volume_declared,
			ratio_pack_product,
			total_prod_vol_per_outer,
			transit_pack_volume,
			transit_pack_vol_ratio,
		--
			pack_material_summary,
		--
			trans_pack_material_summary,
		--
			sold_in_countries,
		--  for convenience
			product_id, 
			revision_id,
			revision_description,
			fadq formulated_data_quality,
			pkadq packaging_data_quality,
			tradq transport_data_quality,
			suadq supplier_data_quality,
			gtpdadq manufactured_data_quality,
			gtpadq product_info_data_quality,
			gtfooddq food_data_quality
		FROM gt_profile_report
	   WHERE product_id = in_product_id
	   AND revision_id = in_revision_id;
END;

-- Provenace
PROCEDURE GetBiodiversityChartData (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id		IN product_revision.revision_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_product_class_id	gt_product_class.gt_product_class_id%TYPE;
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	v_product_class_id := product_info_pkg.GetProductClassId(in_act_id, in_product_id, in_revision_id);
	
	CASE  v_product_class_id
		WHEN model_pd_pkg.PROD_CLASS_FORMULATED THEN 
		
			OPEN out_cur FOR
				SELECT
				  DECODE(lvl-1, 
					0, 'Water',
					1, 'Agricultural', 
					2, 'Fish', 
					3, 'Palm', 
					4, 'Processed Palm', 
					5, 'Wild', 
					6, 'Unknown',
					7, 'Mineral') 
						label,
				  DECODE(lvl-1,
					0, water_pct,		  
					1, bp_crops_pct, 
					2, bp_fish_pct, 
					3, bp_palm_pct, 
					4, bp_palm_processed_pct, 
					5, bp_wild_pct, 
					6, bp_unknown_pct, 
					7, bp_mineral_pct) 
						value
				FROM 
				  (SELECT LEVEL lvl FROM dual CONNECT BY LEVEL <= 8) x,
				  (SELECT 
						water_pct,
						bp_crops_pct, 
						bp_fish_pct, 
						bp_palm_pct, 
						bp_palm_processed_pct, 
						bp_wild_pct, 
						bp_unknown_pct, 
						bp_mineral_pct 
					 FROM gt_formulation_answers
					WHERE product_id = in_product_id
					AND revision_id = in_revision_id) y;
	  
		WHEN model_pd_pkg.PROD_CLASS_MANUFACTURED THEN 
		
			OPEN out_cur FOR
				SELECT
				  DECODE(lvl-1, 
					0, 'Water',
					  1, 'Agricultural', 
					  2, 'Intensive Farming', 
					  3, 'Palm', 
					  4, 'Processed Palm', 
					  5, 'Wild', 
					  6, 'Unknown',
					  7, 'Mineral') 
						  label, value
				FROM 
				  (SELECT LEVEL lvl FROM dual CONNECT BY LEVEL <= 8) x, 
				  (
					SELECT pt.gt_pda_provenance_type_id, pt.description, NVL(SUM(mi.pct_of_product),0) value 
					  FROM gt_pda_material_item mi, gt_pda_provenance_type pt 
					 WHERE product_id = in_product_id 
					  AND revision_id = in_revision_id
					  AND pt.gt_pda_provenance_type_id = mi.gt_pda_provenance_type_id(+)
					GROUP BY pt.gt_pda_provenance_type_id, pt.description
					ORDER BY pt.gt_pda_provenance_type_id
				   ) mi 
				 WHERE x.lvl-1 = mi.gt_pda_provenance_type_id;
				 
		WHEN model_pd_pkg.PROD_CLASS_PARENT_PACK THEN 
			OPEN out_cur FOR
				SELECT
				  DECODE(lvl-1, 
					0, 'Water',
					  1, 'Agricultural', 
					  2, 'Intensive Farming', 
					  3, 'Palm', 
					  4, 'Processed Palm', 
					  5, 'Wild', 
					  6, 'Unknown',
					  7, 'Mineral') 
						  label, 0 value
				FROM 
				  (SELECT LEVEL lvl FROM dual CONNECT BY LEVEL <= 8);
	    WHEN model_pd_pkg.PROD_CLASS_FOOD THEN 
			OPEN out_cur FOR
				SELECT
				  DECODE(lvl-1, 
				     9, 'Water',
					11, 'Intensive Farming',
					12, 'Palm oil',
					10, 'Mixed Agricultural',
					18, 'Unknown',
					13, 'Processed Veg oils',
					14, 'Wild Harvested',
					15, 'Fishing - Pole and line',
					16, 'Fishing - Nets',
					17, 'Fishing - Long line',
					19, 'Mineral/syntetic',
					20, 'Processed Ingredient')
						label, value
				  FROM 
				  (SELECT LEVEL lvl FROM dual CONNECT BY LEVEL <= 21) x, 
				  (
					SELECT fi.gt_fd_ingred_prov_type_id, NVL(SUM(fi.pct_of_product),0) value 
					  FROM (
							SELECT gt_fd_ingred_prov_type_id, pct_of_product 
							  FROM gt_fd_ingredient fi 
							 WHERE product_id = in_product_id 
							   AND revision_id = in_revision_id
						    UNION
                            SELECT 9 gt_fd_ingred_prov_type_id, NVL(pda.pct_added_water,0) pct_of_product 
                              FROM gt_food_answers pda
                       		 WHERE product_id = in_product_id
                             AND revision_id = in_revision_id
						) fi--, gt_pda_accred_type pt
					--WHERE pt.gt_fd_ingred_prov_type_id = fi.gt_fd_ingred_prov_type_id(+)
					GROUP BY fi.gt_fd_ingred_prov_type_id
					ORDER BY fi.gt_fd_ingred_prov_type_id
				   ) fi 
				 WHERE x.lvl-1 = fi.gt_fd_ingred_prov_type_id;
				--FROM 
				--  (SELECT LEVEL lvl FROM dual CONNECT BY LEVEL <= 18) x, 
				--  (
				--	SELECT pt.gt_fd_ingred_prov_type_id, pt.description, NVL(SUM(fi.pct_of_product),0) value 
				--	  FROM gt_fd_ingredient fi, gt_fd_ingred_prov_type pt 
				--	 WHERE product_id = in_product_id 
				--	  AND revision_id = in_revision_id
				--	  AND pt.gt_fd_ingred_prov_type_id = fi.gt_fd_ingred_prov_type_id(+)
				--	GROUP BY pt.gt_fd_ingred_prov_type_id, pt.description
				--	ORDER BY pt.gt_fd_ingred_prov_type_id
				--	
				--   ) fi 
				-- WHERE x.lvl-1 = fi.gt_fd_ingred_prov_type_id;
				 
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown product class ('||v_product_class_id||')');
	END CASE;	

END;


PROCEDURE GetSourceChartData (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_product_class_id	gt_product_class.gt_product_class_id%TYPE;
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	v_product_class_id := product_info_pkg.GetProductClassId(in_act_id, in_product_id, in_revision_id);
	
	CASE v_product_class_id
		WHEN model_pd_pkg.PROD_CLASS_FORMULATED THEN 
		
			OPEN out_cur FOR
				SELECT
				  DECODE(lvl-1, 
					0, 'Water',
					1, '3rd party', 
					2, 'Other', 
					3, 'Known', 
					4, 'Unknown', 
					5, 'Not natural') 
						label,
				  DECODE(lvl-1, 
					0, water_pct,
					1, bs_accredited_priority_pct, 
					2, bs_accredited_other_pct, 
					3, bs_known_pct, 
					4, bs_unknown_pct, 
					5, bs_no_natural_pct) 
						value
				FROM 
				  (SELECT LEVEL lvl FROM dual CONNECT BY LEVEL <= 6) x,
				  (SELECT 
						water_pct,
						bs_accredited_priority_pct, 
						bs_accredited_other_pct, 
						bs_known_pct, 
						bs_unknown_pct, 
						bs_no_natural_pct
					 FROM gt_formulation_answers
					WHERE product_id = in_product_id
					AND revision_id = in_revision_id) y;
	  
		WHEN model_pd_pkg.PROD_CLASS_MANUFACTURED THEN 
		
			OPEN out_cur FOR
				SELECT
				  DECODE(lvl-1, 
					0, 'Water',
					1, '3rd party', 
					2, 'Other', 
					3, 'Known', 
					4, 'Unknown', 
					5, 'Not natural')
						  label, value
				FROM 
				  (SELECT LEVEL lvl FROM dual CONNECT BY LEVEL <= 6) x, 
				  (
					SELECT ac.gt_pda_accred_type_id, NVL(SUM(mi.pct_of_product),0) value 
					  FROM (
							SELECT gt_pda_accred_type_id, pct_of_product 
							  FROM gt_pda_material_item mi 
							 WHERE product_id = in_product_id 
							   AND revision_id = in_revision_id
						    UNION
                            SELECT 4 gt_pda_accred_type_id, NVL(pda.endangered_pct,0) pct_of_product 
                              FROM gt_pdesign_answers pda
                       		 WHERE product_id = in_product_id
                             AND revision_id = in_revision_id
						) mi, gt_pda_accred_type ac
					WHERE ac.gt_pda_accred_type_id = mi.gt_pda_accred_type_id(+)
					GROUP BY ac.gt_pda_accred_type_id
					ORDER BY ac.gt_pda_accred_type_id
				   ) mi 
				 WHERE x.lvl-1 = mi.gt_pda_accred_type_id;
		WHEN model_pd_pkg.PROD_CLASS_PARENT_PACK THEN 
			OPEN out_cur FOR
				SELECT
				  DECODE(lvl-1, 
					0, 'Water',
					1, '3rd party', 
					2, 'Other', 
					3, 'Known', 
					4, 'Unknown', 
					5, 'Not natural')
						  label, 0 value
				FROM 
				  (SELECT LEVEL lvl FROM dual CONNECT BY LEVEL <= 6);
		WHEN model_pd_pkg.PROD_CLASS_FOOD THEN
		OPEN out_cur FOR

				SELECT
				  DECODE(lvl-1, 
					6, 'Acc. source (priority)',
					2, 'Acc. source (other)', 
					4, 'Known souce', 
					3, 'Water',
					5, 'Unknown source',
					7, 'Not available')
						  label, value
				FROM 
				  (SELECT LEVEL lvl FROM dual CONNECT BY LEVEL <= 8) x, 
				  (
					SELECT fi.gt_ingred_accred_type_id, NVL(SUM(fi.pct_of_product),0) value 
					  FROM (
							SELECT gt_ingred_accred_type_id, pct_of_product 
							  FROM gt_fd_ingredient fi 
							 WHERE product_id = in_product_id 
							   AND revision_id = in_revision_id
						    UNION
                            SELECT 3 gt_ingred_accred_type_id, NVL(fda.pct_added_water,0) pct_of_product 
                              FROM gt_food_answers fda
                       		 WHERE product_id = in_product_id
                             AND revision_id = in_revision_id
						) fi--, gt_ingred_accred_type ac
					--WHERE ac.gt_ingred_accred_type_id = fi.gt_ingred_accred_type_id(+)
					GROUP BY fi.gt_ingred_accred_type_id
					ORDER BY fi.gt_ingred_accred_type_id
				   ) fi 
				 WHERE x.lvl-1 = fi.gt_ingred_accred_type_id;
			
			--OPEN out_cur FOR
			--	SELECT
			--	  DECODE(lvl-1, 
			--		0, 'Water',
			--		1, '3rd party', 
			--		2, 'Other', 
			--		3, 'Known', 
			--		4, 'Unknown', 
			--		5, 'Not natural', 'wha')
			--			  label, value
			--	FROM 
			--	  (SELECT LEVEL lvl FROM dual CONNECT BY LEVEL <= 6) x, 
			--	  (
			--		SELECT ac.gt_ingred_accred_type_id, NVL(SUM(fi.pct_of_product),0) value 
			--		  FROM (
			--				SELECT gt_ingred_accred_type_id, pct_of_product 
			--				  FROM gt_fd_ingredient fi 
			--				 WHERE product_id = in_product_id 
			--				   AND revision_id = in_revision_id
			--			    UNION
            --                SELECT 4 gt_fd_accred_type_id, NVL(fda.pct_high_risk,0) pct_of_product 
            --                  FROM gt_food_answers fda
            --           		 WHERE product_id = in_product_id
            --                 AND revision_id = in_revision_id
			--			) fi, gt_ingred_accred_type ac
			--		WHERE ac.gt_ingred_accred_type_id = fi.gt_ingred_accred_type_id(+)
			--		GROUP BY ac.gt_ingred_accred_type_id
			--		ORDER BY ac.gt_ingred_accred_type_id
			--	   ) fi 
			--	 WHERE x.lvl-1 = fi.gt_ingred_accred_type_id;
			--	
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown product class ('||v_product_class_id||')');
	END CASE;

END;

PROCEDURE GetTransportToBootsData (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id		IN product_revision.revision_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT start_desc || mid_desc || end_desc description FROM
		(
		    SELECT country || ' (' || tti.description start_desc, 
		    CASE
		        WHEN ((pct IS NOT NULL) AND (pct > 0)) THEN ', ' || pct || '%'
		        ELSE NULL
		    END mid_desc, ')' end_desc
		     FROM gt_country_made_in cmi, gt_transport_type tti, country c 
		    WHERE cmi.gt_transport_type_id = tti.gt_transport_type_id
		    AND cmi.country_code = c.country_code
		    AND product_id = in_product_id
		    AND cmi.revision_id = in_revision_id
		);

END;

PROCEDURE GetHazChemData (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id		IN product_revision.revision_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_product_class_id	gt_product_class.gt_product_class_id%TYPE;
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	v_product_class_id := product_info_pkg.GetProductClassId(in_act_id, in_product_id, in_revision_id);
	
	CASE  v_product_class_id
		WHEN model_pd_pkg.PROD_CLASS_FORMULATED THEN 
		
			OPEN out_cur FOR
			   SELECT hc.description hc_description 
				 FROM gt_fa_haz_chem fahc, gt_hazzard_chemical hc  
				WHERE hc.gt_hazzard_chemical_id = fahc.gt_hazzard_chemical_id
				  AND product_id = in_product_id
				  AND revision_id = in_revision_id;	
	  
		WHEN model_pd_pkg.PROD_CLASS_MANUFACTURED THEN 
		
			OPEN out_cur FOR
               SELECT DISTINCT(hc.description) hc_description 
    			 FROM gt_pda_hc_item hci, gt_pda_haz_chem hc  
				WHERE hc.gt_pda_haz_chem_id = hci.gt_pda_haz_chem_id
				  AND product_id = in_product_id
				  AND revision_id = in_revision_id;
				 
		WHEN model_pd_pkg.PROD_CLASS_FOOD THEN 
			OPEN out_cur FOR
				SELECT NULL hc_description FROM dual WHERE 1=0;
	 
				 
		WHEN model_pd_pkg.PROD_CLASS_PARENT_PACK THEN 
			OPEN out_cur FOR
				SELECT NULL hc_description FROM dual WHERE 1=0;

		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown product class ('||v_product_class_id||')');
	END CASE;
	
END;

PROCEDURE GetEndangeredData (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id		IN product_revision.revision_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_product_class_id	gt_product_class.gt_product_class_id%TYPE;
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	v_product_class_id := product_info_pkg.GetProductClassId(in_act_id, in_product_id, in_revision_id);
	
	CASE  v_product_class_id
		WHEN model_pd_pkg.PROD_CLASS_FORMULATED THEN 
		
			OPEN out_cur FOR
               SELECT es.description species 
    			 FROM gt_fa_endangered_sp esi, gt_endangered_species es  
				WHERE esi.gt_endangered_species_id = es.gt_endangered_species_id
				  AND product_id = in_product_id
				  AND revision_id = in_revision_id;		
	  
		WHEN model_pd_pkg.PROD_CLASS_MANUFACTURED THEN 
		
			OPEN out_cur FOR
               SELECT es.description species 
    			 FROM gt_pda_endangered_sp esi, gt_endangered_species es  
				WHERE esi.gt_endangered_species_id = es.gt_endangered_species_id
				  AND product_id = in_product_id
				  AND revision_id = in_revision_id;	
				 
		WHEN model_pd_pkg.PROD_CLASS_FOOD THEN 
		
			OPEN out_cur FOR
               SELECT es.description species 
    			 FROM gt_fd_endangered_sp esi, gt_endangered_species es  
				WHERE esi.gt_endangered_species_id = es.gt_endangered_species_id
				  AND product_id = in_product_id
				  AND revision_id = in_revision_id;	
				 
				 
				 
		WHEN model_pd_pkg.PROD_CLASS_PARENT_PACK THEN 
			OPEN out_cur FOR
				SELECT NULL species FROM dual WHERE 1=0;

		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown product class ('||v_product_class_id||')');
	END CASE;
	
END;

PROCEDURE GetPalmData (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id		IN product_revision.revision_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_product_class_id	gt_product_class.gt_product_class_id%TYPE;
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	v_product_class_id := product_info_pkg.GetProductClassId(in_act_id, in_product_id, in_revision_id);
	
	CASE  v_product_class_id
		WHEN model_pd_pkg.PROD_CLASS_FORMULATED THEN 
		
			OPEN out_cur FOR
	           SELECT plm.description palm 
    			 FROM gt_fa_palm_ind pi, gt_palm_ingred plm  
				WHERE pi.gt_palm_ingred_id = plm.gt_palm_ingred_id 
				  AND product_id = in_product_id
				  AND revision_id = in_revision_id;	
	  
	  WHEN model_pd_pkg.PROD_CLASS_FOOD THEN 
		
			OPEN out_cur FOR
	           SELECT plm.description palm 
    			 FROM gt_fd_palm_ind pi, gt_palm_ingred plm  
				WHERE pi.gt_palm_ingred_id = plm.gt_palm_ingred_id 
				  AND product_id = in_product_id
				  AND revision_id = in_revision_id;	
	  
		WHEN model_pd_pkg.PROD_CLASS_MANUFACTURED THEN 		
			-- palm not recorded in same way
			OPEN out_cur FOR
				SELECT NULL palm FROM dual WHERE 1=0;

		WHEN model_pd_pkg.PROD_CLASS_PARENT_PACK THEN 
			OPEN out_cur FOR
				SELECT NULL palm FROM dual WHERE 1=0;

		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown product class ('||v_product_class_id||')');
	END CASE;
	
END;

PROCEDURE GetAccredNoteData (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id		IN product_revision.revision_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_product_class_id	gt_product_class.gt_product_class_id%TYPE;
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	v_product_class_id := product_info_pkg.GetProductClassId(in_act_id, in_product_id, in_revision_id);
	
	CASE  v_product_class_id
		WHEN model_pd_pkg.PROD_CLASS_FORMULATED THEN 
		
			OPEN out_cur FOR
		       SELECT fa.bs_accredited_priority_src accreditation_note
    			 FROM gt_formulation_answers fa
				WHERE product_id = in_product_id
				  AND revision_id = in_revision_id
               UNION
               SELECT fa.bs_accredited_other_src accreditation_note
    			 FROM gt_formulation_answers fa
				WHERE product_id = in_product_id
				  AND revision_id = in_revision_id;	

	  
		WHEN model_pd_pkg.PROD_CLASS_MANUFACTURED THEN 		
			OPEN out_cur FOR
			   SELECT accreditation_note
    			 FROM gt_pda_material_item mi
				WHERE product_id = in_product_id
				  AND revision_id = in_revision_id
                  AND accreditation_note IS NOT NULL;

		WHEN model_pd_pkg.PROD_CLASS_FOOD THEN 		
			OPEN out_cur FOR
			   SELECT accred_scheme_name accreditation_note
    			 FROM gt_fd_ingredient fi
				WHERE product_id = in_product_id
				  AND revision_id = in_revision_id
                  AND accred_scheme_name IS NOT NULL;

		WHEN model_pd_pkg.PROD_CLASS_PARENT_PACK THEN 
			OPEN out_cur FOR
				SELECT NULL accreditation_note FROM dual WHERE 1=0;

		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown product class ('||v_product_class_id||')');
	END CASE;
	
END;

PROCEDURE CopyProfilesFromRevision(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_from_rev						IN product_revision.revision_id%TYPE
)
AS
BEGIN
	
	INSERT INTO gt_profile (
	   product_id, revision_id, gt_low_anc_list, 
	   gt_med_anc_list, gt_high_anc_list, ratio_prod_pck_wght_pct, 
	   renewable_pack_pct, biopolymer_used, biopolymer_list, 
	   recycled_pack_cont_msg, recyclable_pack_pct, recoverable_pack_pct, 
	   country_made_in_list, origin_type, pack_ei, materials_ei, trans_pack_ei, recycled_pct, sum_trans_weight) 
	SELECT 
		product_id, revision_id+1, gt_low_anc_list, 
	   gt_med_anc_list, gt_high_anc_list, ratio_prod_pck_wght_pct, 
	   renewable_pack_pct, biopolymer_used, biopolymer_list, 
	   recycled_pack_cont_msg, recyclable_pack_pct, recoverable_pack_pct, 
	   country_made_in_list, origin_type, pack_ei, materials_ei, trans_pack_ei, recycled_pct, sum_trans_weight
	FROM gt_profile
		WHERE product_id = in_product_id
		AND revision_id =  in_from_rev;
	
END;

END profile_pkg;
/
