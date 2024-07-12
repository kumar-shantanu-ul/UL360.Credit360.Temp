create or replace package body supplier.model_pd_pkg
IS

-------------------------------------
--Scores that differ between classes
-------------------------------------

------------------------------
--	Sustainable Sourcing
------------------------------
--1
PROCEDURE CalcNatDerivedIngScore(
	in_product_id					IN product.product_id%TYPE, 
	in_prod_class_id				IN gt_product_class.gt_product_class_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_score						OUT gt_scores.score_nat_derived%TYPE
)
AS
	v_bp_natural_pct				NUMBER(6, 3) := 0;
	v_bp_total_pct					NUMBER(6, 3) := 0;
	v_water_pct						NUMBER(6, 3) := 0;
	v_num_rows						NUMBER(10);
BEGIN

	out_score := -1;

	CASE in_prod_class_id
	  WHEN PROD_CLASS_FORMULATED THEN 
	  
		SELECT 
			NVL(bp_crops_pct,0)+NVL(bp_fish_pct,0)+NVL(bp_palm_pct,0)+NVL(bp_wild_pct,0) bp_natural_pct, 
			NVL(water_pct,0)+NVL(bp_crops_pct,0)+NVL(bp_fish_pct,0)+NVL(bp_palm_pct,0)+NVL(bp_palm_processed_pct,0)+NVL(bp_wild_pct,0)+NVL(bp_unknown_pct,0)+NVL(bp_mineral_pct,0) bp_total_pct,
			NVL(water_pct,-1) water_pct
		  INTO v_bp_natural_pct, v_bp_total_pct, v_water_pct
		  FROM gt_formulation_answers fa, all_product p
		 WHERE p.product_id = fa.product_id(+)
	       AND p.product_id = in_product_id
		   AND ((fa.revision_id = in_revision_id) OR (fa.revision_id IS NULL));
	  
	  WHEN PROD_CLASS_MANUFACTURED THEN 
	  
        SELECT 	
			NVL(SUM(DECODE(mi.natural, 1, pct_of_product, 0)),0) bp_natural_pct, 
			NVL(SUM(pct_of_product),0) bp_total_pct     
		  INTO v_bp_natural_pct, v_bp_total_pct
          FROM all_product p, 
          (
           SELECT pmi.product_id, pmi.revision_id, m.gt_material_id, pct_of_product, natural, gt_pda_provenance_type_id
             FROM gt_material m, gt_pda_material_item pmi 
            WHERE m.gt_material_id = pmi.gt_material_id
          ) mi
         WHERE p.product_id = mi.product_id(+)
           AND p.product_id = in_product_id
           AND ((mi.revision_id = in_revision_id) OR (mi.revision_id IS NULL));		
		
	  WHEN PROD_CLASS_PARENT_PACK THEN 
		NULL; 
	  WHEN PROD_CLASS_FOOD THEN 
	    -- LOGIC: same as for product design - find the total percentage natural the product is by finding a weighted sum of the composition of constituent ingredients
		SELECT COUNT(*)
		INTO v_num_rows
		FROM gt_food_answers
		WHERE product_id = in_product_id
		AND revision_id = in_revision_id;
		IF v_num_rows = 1 THEN
		
			SELECT 	
				NVL(SUM(DECODE(fi.natural, 1, pct_of_product, 0)),0) bp_natural_pct, 
				NVL(SUM(pct_of_product),0) bp_total_pct     
			  INTO v_bp_natural_pct, v_bp_total_pct
			  FROM all_product p, 
			  (
			   SELECT fi.product_id, fi.revision_id, fi.gt_fd_ingredient_id, fi.pct_of_product, pt.natural, fi.gt_fd_ingred_prov_type_id
				 FROM gt_fd_ingredient fi, gt_fd_ingred_prov_type pt
				WHERE pt.gt_fd_ingred_prov_type_id = fi.gt_fd_ingred_prov_type_id
			  ) fi
			 WHERE p.product_id = fi.product_id(+)
			   AND p.product_id = in_product_id
			   AND ((fi.revision_id = in_revision_id) OR (fi.revision_id IS NULL));		
			   
			   
			SELECT pct_added_water
			INTO v_water_pct 
			FROM gt_food_answers
			WHERE product_id = in_product_id
			AND revision_id = in_revision_id;
			v_bp_total_pct := v_bp_total_pct + v_water_pct;
			
		ELSE
			v_water_pct := -1;
			v_bp_total_pct := -1;
			v_bp_natural_pct := -1;
		END IF;
	  ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Unknown product class ('||in_prod_class_id||')');
	END CASE;
	
	-- LOGIC: Based on %natural derived entered
	-- %natural=0			-> 5
	-- %natural<=10 		-> 4
	-- %natural<=25 		-> 3
	-- %natural<=75 		-> 2
	-- %natural>75 			-> 1
	CASE 
	  WHEN (v_bp_total_pct<0) OR (v_bp_total_pct<100) OR (v_water_pct<0) THEN out_score := -1;  -- not set or not complete set of pct
	  WHEN (v_water_pct>=100) THEN out_score := 1;  -- bottled water could validly be set
	  WHEN 100*(v_bp_natural_pct/(100-v_water_pct))=0 THEN out_score := 5;
	  WHEN 100*(v_bp_natural_pct/(100-v_water_pct))<=10 THEN out_score := 4;
	  WHEN 100*(v_bp_natural_pct/(100-v_water_pct))<=25 THEN out_score := 3;
	  WHEN 100*(v_bp_natural_pct/(100-v_water_pct))<=75 THEN out_score := 2;
	  WHEN 100*(v_bp_natural_pct/(100-v_water_pct))>75 THEN out_score := 1;
	END CASE; 
	
END;

--2
PROCEDURE CalcChemRiskScore(
	in_product_id					IN product.product_id%TYPE, 
	in_prod_class_id				IN gt_product_class.gt_product_class_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_score						OUT gt_scores.score_chemicals%TYPE
)AS
	v_red_chem_count		NUMBER;
	v_orange_chem_count		NUMBER;
	v_fa_row_exists			NUMBER;
	
	-- Manufactured only
	v_score_hc				gt_scores.score_chemicals%TYPE;
	v_total_pct				NUMBER(10);
	v_ingredients_have_gm 	NUMBER(10);
	
	v_num_rows				NUMBER(10);
BEGIN

	out_score := -1;

	CASE in_prod_class_id
	  WHEN PROD_CLASS_FORMULATED THEN 
	  
		-- LOGIC: Based on Red/Orange List chemicals
		-- >=1 red chemical				-> 10
		-- >2 orange chemicales 		-> 5
		-- 1 or 2 orange chemicals 		-> 4
		-- no orange or red chem 		-> 1
		-- no FA row 					-> -1

		SELECT COUNT(*) 
		INTO v_fa_row_exists
		FROM gt_formulation_answers fa 
		WHERE fa.product_id = in_product_id
		AND fa.revision_id = in_revision_id;

		SELECT COUNT(*) 
		INTO v_orange_chem_count
		FROM gt_formulation_answers fa, gt_fa_haz_chem fhc, gt_hazzard_chemical hc
			WHERE fa.product_id = fhc.product_id
			AND fhc.gt_hazzard_chemical_id = hc.gt_hazzard_chemical_id
			AND hc.colour = 'O'
			AND fa.product_id = in_product_id
			AND fhc.revision_id = in_revision_id
			AND fa.revision_id = in_revision_id;

		SELECT COUNT(*) 
		INTO v_red_chem_count
		FROM gt_formulation_answers fa, gt_fa_haz_chem fhc, gt_hazzard_chemical hc
			WHERE fa.product_id = fhc.product_id
			AND fhc.gt_hazzard_chemical_id = hc.gt_hazzard_chemical_id
			AND hc.colour = 'R'
			AND fa.product_id = in_product_id
			AND fhc.revision_id = in_revision_id
			AND fa.revision_id = in_revision_id;

		CASE 
		  WHEN v_fa_row_exists = 0 THEN out_score := -1;  -- not set
		  WHEN v_red_chem_count >= 1 THEN out_score := 10;
		  WHEN v_orange_chem_count > 2 THEN out_score := 5;
		  WHEN v_orange_chem_count >= 1 THEN out_score := 4;
		  ELSE out_score := 1;
		END CASE;
	  
	  WHEN PROD_CLASS_MANUFACTURED THEN 	
	  
	  
			SELECT NVL(SUM(mi.pct_of_product), -1) 
			  INTO v_total_pct
			  FROM product p, gt_pda_material_item mi 
				WHERE p.product_id = mi.product_id(+)
				  AND p.product_id = in_product_id
				  AND ((mi.revision_id = in_revision_id) OR (mi.revision_id IS NULL));
	  
	  		-- LOGIC : For each material look at the highest scoring haz chem (if any) and amortize by % of product
			-- Note: there must be at least one material   for a valid product
				-- will get ch_score = -1 if no materials 
				-- will get score of 0 if materials but no chemicals (valid case)
			SELECT NVL(SUM((pct_of_product*hc_score)/100), -1) pct_score
			  INTO v_score_hc
			  FROM 
			(
				SELECT mi.product_id, mi.gt_material_id, mi.pct_of_product, MAX(NVL(hc_score, 0)) hc_score
				  FROM gt_pda_material_item mi,
					(
						SELECT product_id, revision_id, gt_pda_material_item_id, hc.gt_pda_haz_chem_id, score hc_score
						  FROM gt_pda_hc_item hci, gt_pda_haz_chem hc 
						 WHERE hci.gt_pda_haz_chem_id = hc.gt_pda_haz_chem_id
					) hc
				WHERE mi.gt_pda_material_item_id = hc.gt_pda_material_item_id(+)
				  AND mi.product_id = in_product_id
				  AND mi.revision_id = in_revision_id
				GROUP BY mi.product_id, mi.gt_material_id, mi.pct_of_product
			) mi, product p
			WHERE p.product_id = mi.product_id(+) -- make sure there's row even if no data
			  AND p.product_id = in_product_id;
			
			IF (v_total_pct=100) THEN 
				out_score := v_score_hc; 
			ELSE
				out_score := -1;
			END IF;
			
			IF out_score > 10 THEN 
				out_score := 10;
			END IF;
			
			IF out_score < 1 THEN 
				out_score := 1;
			END IF;
	
	  WHEN PROD_CLASS_PARENT_PACK THEN 
		NULL; -- no formulation / PD
      WHEN PROD_CLASS_FOOD THEN 
		--first check there is a row in the database for the food answers...
		SELECT COUNT(*)
		INTO v_num_rows
		FROM gt_food_answers
		WHERE product_id = in_product_id
		AND revision_id = in_revision_id;
		IF v_num_rows = 1 THEN
		
		
		  --LOGIC - there are no hazardous chemicals for food, so the only factor affecting the chem risk score is the contains gm food indicator.
			-- if food has at least one item of food with gm content then the food product gets a score of 3, otherwise set to nothing.
			SELECT NVL(MAX(CONTAINS_GM), -1) * 3 -- 3 is the chosen score for how bad gm is
			INTO v_ingredients_have_gm
			FROM gt_fd_ingredient fi
			WHERE fi.product_id = in_product_id
			AND fi.revision_id = in_revision_id;
			IF v_ingredients_have_gm < 0 THEN
				out_score := -1;
			ELSE
				out_score := v_ingredients_have_gm;
			END IF;
		ELSE 
			out_score := -1;
		END IF;
	  ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Unknown product class ('||in_prod_class_id||')');
	END CASE;

END;

--3
PROCEDURE CalcBiodiversityScores(
	in_product_id					IN product.product_id%TYPE, 
	in_prod_class_id				IN gt_product_class.gt_product_class_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_bio_prov_score				OUT gt_scores.score_source_biod%TYPE,
	out_bio_accred_score			OUT gt_scores.score_accred_biod%TYPE
)
AS
	-- 3
	v_bp_threatened_pct				NUMBER(6, 3) := 0;
	v_bp_total_pct					NUMBER(6, 3) := 0;
	-- 4
	v_bs_unknown_pct				NUMBER(6,3) := 0;
	v_bs_total_pct					NUMBER(6,3) := 0;
	v_water_pct						NUMBER(6,3) := 0;
	

	v_max_threatened_score			NUMBER(6,3) := 0;
	v_food_seasonal					NUMBER(10);
	v_food_pct_added_water			gt_food_answers.pct_added_water%TYPE;
	v_food_prov_total				gt_fd_ingred_prov_type.score%TYPE;
	v_food_scheme_credit			gt_fd_scheme.score%TYPE;
	
	v_num_rows						NUMBER(10);
BEGIN

	out_bio_prov_score := -1;
	out_bio_accred_score := -1;
	
	-- 3. Biodiversity 
	-- LOGIC: score = sum of below
	-- 2 * %Crops grown on established agricultural land / 100
	-- 4 * %Fish (non MSC) European intensive farming  / 100
	-- 4 * %Palm Oil and close derivatives (one processing step from natural material).   / 100
	-- 4 * %Processed materials derived from palm or vegetable oils.   / 100
	-- 3 * %Wild Harvested  / 100 
	-- 5 * %Unknown Sources  / 100
	-- 1 * %Mineral derived / synthetic materials  / 100
	
	-- Modifier: If the “Threatened %” is > 0 and the max score for for any selected endangered item is used as the score

	-- 4. Biodiversity Source / Accreditation
	-- LOGIC:
	-- 1 * %Accredited source (priority) FSC, RSPO MSC (fish). Organic 3rd Party Accredited (Ecocert, BDIH, Soil Assoc, USDA)
	-- 2 * %Accredited source (other) PEFC, SFI, RSPO member
	-- 4 * %Known source (species and country) - no 3rd party accreditation
	-- 5 * %Unknown source
	-- 0 * %No natural ingredients 

	
	CASE in_prod_class_id
	  WHEN PROD_CLASS_FORMULATED THEN 

		-- find the max threatened item score
		SELECT NVL(MAX(risk_score), -1) max_risk_score
		  INTO v_max_threatened_score
		  FROM gt_endangered_species es, gt_fa_endangered_sp gtes
		 WHERE es.gt_endangered_species_id = gtes.gt_endangered_species_id
		   AND product_id = in_product_id
		   AND revision_id = in_revision_id;		


		SELECT 
			-- 3
			(NVL((2*bp_crops_pct),0) + NVL((4*bp_fish_pct),0) + NVL((4*bp_palm_pct),0) + NVL((4*bp_palm_processed_pct),0) + NVL((3*bp_wild_pct),0) + NVL((5*bp_unknown_pct),0) + NVL((1*bp_mineral_pct),0)) score_source_biod, 
			NVL(water_pct,0)+NVL(bp_crops_pct,0)+NVL(bp_fish_pct,0)+NVL(bp_palm_pct,0)+NVL(bp_palm_processed_pct,0)+NVL(bp_wild_pct,0)+NVL(bp_unknown_pct,0)+NVL(bp_mineral_pct,0) bp_total_pct,
			NVL(bp_threatened_pct,-1) bp_threatened_pct,
			-- 4
			(NVL((1*bs_accredited_priority_pct),0)+NVL((2*bs_accredited_other_pct),0)+NVL((4*bs_known_pct),0)+NVL((5*bs_unknown_pct),0)+NVL((1*bs_no_natural_pct),0)) score_accred_biod,
			NVL(water_pct,0)+NVL(bs_accredited_priority_pct,0)+NVL(bs_accredited_other_pct,0)+NVL(bs_known_pct,0)+NVL(bs_unknown_pct,0)+NVL(bs_no_natural_pct,0) bs_total_pct,
			NVL(bs_unknown_pct,0),
			--
			NVL(water_pct,-1) water_pct
		  INTO 
			out_bio_prov_score, v_bp_total_pct, v_bp_threatened_pct,
			out_bio_accred_score, v_bs_total_pct, v_bs_unknown_pct,
			v_water_pct
		  FROM gt_formulation_answers fa, all_product p
		 WHERE p.product_id = fa.product_id(+)
	       AND p.product_id = in_product_id
		   AND ((fa.revision_id = in_revision_id) OR (fa.revision_id IS NULL));
		
		-- If water % is not set then can't score
		IF v_water_pct<0 THEN 
			out_bio_prov_score := -1; 
			out_bio_accred_score := -1; 
		ELSE
			-- could happen - e.g. a bottle of water
			IF v_water_pct = 100 THEN
				out_bio_prov_score := 1;
				out_bio_accred_score := 1;
			ELSE
				out_bio_prov_score := out_bio_prov_score / (100-v_water_pct);
				out_bio_accred_score := out_bio_accred_score / (100-v_water_pct);
			END IF;	
		END IF;
		
		-- if there is a threatened percentage but we don't have any endangered items selected (therefore 
		-- no max endangered score for items) we can't return a score and the score calc'd will be incomplete
		IF (v_max_threatened_score < 0) AND (v_bp_threatened_pct > 0) THEN
			out_bio_prov_score := -1;
		END IF;
	  
	  WHEN PROD_CLASS_MANUFACTURED THEN 
	  
		-- find the max threatened item score
		SELECT NVL(MAX(risk_score), -1) max_risk_score
		  INTO v_max_threatened_score
		  FROM gt_endangered_species es, gt_pda_endangered_sp gtes
		 WHERE es.gt_endangered_species_id = gtes.gt_endangered_species_id
		   AND product_id = in_product_id
		   AND revision_id = in_revision_id;	
	  
		-- get the separate endangered pct value if any
		SELECT NVL(endangered_pct,0) 
		  INTO v_bp_threatened_pct
		  FROM all_product p, gt_pdesign_answers pd
		 WHERE p.product_id = pd.product_id(+)
		   AND p.product_id = in_product_id
		   AND ((pd.revision_id = in_revision_id) OR (pd.revision_id IS NULL));	
	  
        SELECT 	
			NVL(SUM(pct_of_product),0) bp_total_pct, 
			NVL(SUM(pct_of_product),0) bp_total_pct, -- repeated for convenience
			-- 3
			NVL(SUM(prov_score*pct_of_product)/100, 0) bp_score, 
			-- 4
			NVL(SUM(DECODE (gt_pda_accred_type_id, gt_product_design_pkg.MAT_ACCRED_UNKNOWN, pct_of_product, 0)),0) bs_unknown_pct, 
			NVL(SUM(accred_score*pct_of_product)/100, 0) bs_score
		  INTO 	v_bp_total_pct, v_bs_total_pct, 
				out_bio_prov_score, 
				v_bs_unknown_pct, out_bio_accred_score
          FROM all_product p, 
          (
           SELECT pmi.product_id, pmi.revision_id, m.gt_material_id, pmi.pct_of_product, m.natural, pmi.gt_pda_provenance_type_id, pmi.gt_pda_accred_type_id, NVL(pt.score, 0) prov_score, NVL(pa.score, 1) accred_score 
             FROM gt_material m, gt_pda_material_item pmi, gt_pda_provenance_type pt, gt_pda_accred_type pa
            WHERE m.gt_material_id = pmi.gt_material_id
			  AND pmi.gt_pda_provenance_type_id = pt.gt_pda_provenance_type_id(+)
			  AND pmi.gt_pda_accred_type_id = pa.gt_pda_accred_type_id(+)
		  ) mi
         WHERE p.product_id = mi.product_id(+)
           AND p.product_id = in_product_id
           AND ((mi.revision_id = in_revision_id) OR (mi.revision_id IS NULL));		
		
		-- as we do use the same score
		IF (v_max_threatened_score < 0) AND (v_bp_threatened_pct > 0) THEN
			out_bio_prov_score := -1;
			out_bio_accred_score := -1; 
		END IF;   
		
		
	  WHEN PROD_CLASS_PARENT_PACK THEN 
		NULL; -- no formulation / PD
	  WHEN PROD_CLASS_FOOD THEN 
		v_bs_unknown_pct := 0;
		v_bp_threatened_pct := 0;
		v_max_threatened_score := 0;
		out_bio_prov_score := 0;
		out_bio_accred_score := 0;
		
		--- first make sure there is one row
		SELECT COUNT(*)
		INTO v_num_rows
		FROM gt_food_answers
		WHERE product_id = in_product_id
		AND revision_id = in_revision_id;
		IF v_num_rows = 1 THEN
			
			--LOGIC - SUM(has seasonal ingredient, worst endangered species score) 
			SELECT NVL(MAX(risk_score), 0) max_risk_score
			  INTO v_max_threatened_score
			  FROM gt_endangered_species es, gt_fd_endangered_sp gtes
			 WHERE es.gt_endangered_species_id = gtes.gt_endangered_species_id
			   AND product_id = in_product_id
			   AND revision_id = in_revision_id;		

			
			SELECT NVL(MAX(SEASONAL), 0)
			INTO v_food_seasonal
			FROM gt_fd_ingredient fi
			WHERE fi.product_id = in_product_id
			AND fi.revision_id = in_revision_id;
			
			SELECT NVL(SUM(fi.pct_of_product * prov.score / 100), -1)
			INTO v_food_prov_total
			FROM gt_fd_ingredient fi, gt_fd_ingred_prov_type prov
			WHERE fi.product_id = in_product_id
			AND fi.revision_id = in_revision_id
			AND prov.gt_fd_ingred_prov_type_id = fi.gt_fd_ingred_prov_type_id;
			
			IF v_food_prov_total > 0 THEN
				out_bio_prov_score := v_food_seasonal + v_max_threatened_score + v_food_prov_total;
			ELSE
				out_bio_prov_score := -1;
			END IF;
			
			
			SELECT NVL(SUM(fi.pct_of_product * act.score / 100), - 1), NVL(SUM(fi.pct_of_product), -1)
			INTO out_bio_accred_score, v_bp_total_pct
			FROM gt_fd_ingredient fi, gt_ingred_accred_type act
			WHERE fi.product_id = in_product_id
			AND fi.revision_id = in_revision_id
			AND act.gt_ingred_accred_type_id = fi.gt_ingred_accred_type_id;
			SELECT NVL(pct_added_water, 0)
			INTO v_food_pct_added_water
			FROM gt_food_answers
			WHERE product_id = in_product_id
			AND revision_id = in_revision_id;
			
			SELECT NVL(SUM(fas.percent_of_product * fs.score / 100), -1)
			INTO v_food_scheme_credit
			FROM gt_fd_scheme fs, gt_fd_answer_scheme fas
			WHERE fas.product_id = in_product_id
			AND fas.revision_id = in_revision_id
			AND fs.gt_fd_scheme_id = fas.gt_fd_scheme_id;
			
			IF v_food_scheme_credit > 0 THEN 
				out_bio_accred_score := out_bio_accred_score - v_food_scheme_credit;
				IF out_bio_accred_score < 0 THEN
					out_bio_accred_score := 0;
				END IF;
			END IF;

			
			v_bp_total_pct := v_food_pct_added_water + v_bp_total_pct;
			v_bs_total_pct := 100;
		END IF;
	  ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Unknown product class ('||in_prod_class_id||')');
	END CASE;
	
	-- Score modifiers
	
	-- 3
	-- score = v_max_threatened_score if %Threatened or endangered species > 0 
	IF v_bp_threatened_pct > 0 THEN 
		out_bio_prov_score := v_max_threatened_score; 
	END IF;
	
	-- not set or not complete set of pct
	IF v_bp_total_pct<100 THEN 
		out_bio_prov_score := -1; 
	END IF;
	
	-- 4
	IF (v_bs_unknown_pct>0) THEN
		out_bio_accred_score := 5; 
	END IF;

	 -- not set or not complete set of pct
	IF v_bs_total_pct<100  THEN 
		out_bio_accred_score := -1; 
	END IF;
	
END;

------------------------------
--	What's in the product
------------------------------

--1


PROCEDURE CalcWhatsInProdScore(
	in_product_id					IN product.product_id%TYPE, 
	in_prod_class_id				IN gt_product_class.gt_product_class_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_whats_in_prod_score			OUT gt_scores.score_whats_in_prod%TYPE,
	out_pack_ei						OUT gt_scores.score_whats_in_prod%TYPE,
	out_materials_ei				OUT gt_scores.score_whats_in_prod%TYPE,
	out_trans_pack_ei				OUT gt_scores.score_whats_in_prod%TYPE
)
AS
	-- 1
	v_ingredient_count				NUMBER(10);
	
	-- manufactured only
	-- Part 2a
	v_env_impact_score				gt_scores.score_whats_in_prod%TYPE := -1;
	v_total_pct						NUMBER(10);
	--v_endangered_pct				gt_pdesign_answers.endangered_pct%TYPE;	
	
	-- Part 2b
	v_food_added_water				gt_food_answers.pct_added_water%TYPE := -1;
	v_battery_env_impact_score		gt_scores.score_whats_in_prod%TYPE := -1;	
	v_num_batteries					NUMBER(10);
	v_num_mains						NUMBER(10);
	v_electrical_power				NUMBER(1);
	v_pesticide_score				gt_fd_ingred_type.pesticide_score%TYPE;
	v_packaging_ei_score			gt_scores.score_whats_in_prod%TYPE := -1;
	v_product_weight				gt_product_answers.prod_weight%TYPE;
	v_packaging_weight				gt_product_answers.prod_weight%TYPE := 0;
	v_weight_inc_pkg				gt_product_answers.weight_inc_pkg%TYPE;
	v_num_pack_items				NUMBER(10);
	v_number_trans_items			NUMBER(10);
	v_num_packs_per_outer			gt_packaging_answers.num_packs_per_outer%TYPE;
	v_trans_pack_weight				gt_profile.sum_trans_weight%TYPE := 0;
	v_num_rows						NUMBER(10);	-- used to check exists single rows when "select into " a variable is needed
	v_final_total_weight			NUMBER(10);
	v_prod_weight_no_pkg			gt_product_answers.prod_weight%TYPE;
BEGIN
	
	out_whats_in_prod_score := -1;
	out_pack_ei	:= -1;			
	out_materials_ei := -1;	
	out_trans_pack_ei := 0;
	
	--firstly lets try and escape from this procedure if we can...
	
	SELECT COUNT(*)
	  INTO v_num_rows
	  FROM gt_product_answers
	 WHERE revision_id = in_revision_id
	   AND product_id = in_product_id;
	
	IF v_num_rows <> 1 THEN 
		RETURN; -- if we don't have the prod weight there is no point in continuing - we can't calc a score
	END IF;
	
	SELECT COUNT(*)
	  INTO v_num_rows
	  FROM gt_packaging_answers
	 WHERE revision_id = in_revision_id
	   AND product_id = in_product_id;
	
	IF v_num_rows <> 1 THEN 
		RETURN; -- if we don't have the pack answers - we can't calc a score
	END IF;	
	
	
	SELECT prod_weight 
	  INTO v_product_weight
	  FROM gt_product_answers
	 WHERE revision_id = in_revision_id
	   AND product_id = in_product_id;

	IF NVL(v_product_weight, -1) = -1 THEN RETURN; -- if the product weight is null then cant calculate score
	END IF;
	SELECT weight_inc_pkg
	  INTO v_weight_inc_pkg
	  FROM gt_product_answers
	 WHERE revision_id = in_revision_id
	   AND product_id = in_product_id;  -- this field is not null so we must find it as there is definitely a row here... otherwise it would have returned earlier
		
	SELECT COUNT(*)
	  INTO v_num_pack_items
	  FROM gt_pack_item
	 WHERE revision_id = in_revision_id
	   AND product_id = in_product_id;
	
	IF v_num_pack_items > 0 THEN
		SELECT SUM(weight_grams)
		  INTO v_packaging_weight
		  FROM gt_pack_item
		 WHERE product_id = in_product_id
		   AND revision_id = in_revision_id;
		   
		   
	END IF;
	
	IF v_weight_inc_pkg = 0 THEN
		IF v_num_pack_items = 0 THEN RETURN; -- cant know the total weight, get out of here!
		ELSE -- if we have at least one packaging item we assume we have all of them, so lets calculate the weight, because by reaching this point - we must be know the total weight
			v_prod_weight_no_pkg := v_product_weight;
			v_product_weight := v_product_weight + v_packaging_weight;
		
		END IF;
	ELSE v_prod_weight_no_pkg := v_product_weight - v_packaging_weight;
	END IF;
		--if there are no transit packaging items we are allowed to assume that there are none .....
		--so first lets find out 1. are there any transit packaging items 2. what their total mass is
	SELECT COUNT(*)
	  INTO v_number_trans_items
	  FROM gt_trans_item
	 WHERE product_id = in_product_id
	   AND revision_id = in_revision_id;
	
	SELECT NVL(num_packs_per_outer, -1)
	  INTO v_num_packs_per_outer
	  FROM gt_packaging_answers
	 WHERE product_id = in_product_id
	   AND revision_id = in_revision_id;
	
	IF (v_number_trans_items > 0) AND (v_num_packs_per_outer > 0) THEN
		SELECT SUM(weight_grams)
		  INTO v_trans_pack_weight
		  FROM gt_trans_item
		 WHERE product_id = in_product_id
		   AND revision_id = in_revision_id;
	    
		v_final_total_weight := v_product_weight + v_trans_pack_weight / v_num_packs_per_outer;-- dividing the total mass of the transit packaging items by the number of products in each container
		-- now product weight is the sum of the transit packaging and the original weight
		-- going to store the trans pack ei score UN-NORMALISED HERE because we know there are a postive number of trans_items
		-- the out going score for trans pack is still -1
		SELECT SUM(gti.weight_grams * tmt.env_impact_score) / (v_final_total_weight * v_num_packs_per_outer)
		  INTO out_trans_pack_ei -- this score is final and should only be included in the total ei score if it is greater or equal to zero
		  FROM gt_trans_item gti, gt_trans_material_type tmt
		 WHERE gti.product_id = in_product_id
		   AND gti.gt_trans_material_type_id = tmt.gt_trans_material_type_id
		   AND gti.revision_id = in_revision_id;
    ELSE v_final_total_weight := v_product_weight;
	END IF;
	-- now we know the final total weight... 
	-- but remember - there is still a chance we might not be able to calculate the total score because there could be no packaging items even though we know what the total weight is...
	
	-- calculating the final packaging score...
	IF v_num_pack_items > 0 THEN
	    SELECT SUM(gtp.weight_grams * pmt.env_impact_score) / v_final_total_weight
		  INTO out_pack_ei -- this score is final and should only be included in the total ei score if it is greater or equal to zero
		  FROM gt_pack_item gtp, gt_pack_material_type pmt
		 WHERE gtp.product_id = in_product_id
		   AND gtp.gt_pack_material_type_id = pmt.gt_pack_material_type_id
		   AND gtp.revision_id = in_revision_id;
	END IF;	
	-- even if v_num_pack_items is zero (in which case we cant calculate the final score - we still want to endure because we might get the materials ei score out.
	
	CASE in_prod_class_id
	  WHEN PROD_CLASS_FORMULATED THEN 
	  
		SELECT NVL(ingredient_count, -1) ingredient_count
		  INTO v_ingredient_count
		  FROM gt_formulation_answers fa, all_product p
		 WHERE p.product_id = fa.product_id(+)
		   AND p.product_id = in_product_id
		   AND ((fa.revision_id = in_revision_id) OR (fa.revision_id IS NULL));

		
		v_env_impact_score := 0;
		IF out_trans_pack_ei > 0 THEN v_env_impact_score := v_env_impact_score+ out_trans_pack_ei;
		END IF;
		--   IF  (v_packaging_ei_score > 0) AND (out_trans_pack_ei > 0)
		--   		v_env_impact_score := 1 + v_packaging_ei_score + out_trans_pack_ei;
		--	ELSE 
		--		v_env_impact_score : -1;
		--   END IF;
		out_materials_ei := 1;
		v_env_impact_score := v_env_impact_score + out_materials_ei;
		IF out_pack_ei >= 0 THEN v_env_impact_score := v_env_impact_score + out_pack_ei;
		ELSE RETURN; -- can safely exit here - just returning the materials and trans packaging contribution to the ei score
		END IF;
	   v_total_pct := 100;
		   
	  WHEN PROD_CLASS_MANUFACTURED THEN 
		--Part 1 - Num = num of ingredients
		-- treating materials as the same - even if diff items
		SELECT 
			NVL(COUNT(DISTINCT(gt_material_id)), -1) 
		  INTO v_ingredient_count
		  FROM gt_pda_material_item mi, product p
		 WHERE p.product_id = mi.product_id(+) -- ensures we have a row - even if no mat items
		   AND p.product_id = in_product_id
		   AND revision_id = in_revision_id;
		   
		   
		SELECT NVL(SUM(mi.pct_of_product), -1) 
		  INTO v_total_pct
		  FROM product p, gt_pda_material_item mi 
			WHERE p.product_id = mi.product_id(+)
              AND p.product_id = in_product_id
              AND ((mi.revision_id = in_revision_id) OR (mi.revision_id IS NULL));
		

		
		-- Part 2a - Env impact score 
		-- Note: there must be at least one material for a valid product
		-- will get score = -1 if no materials 
        SELECT NVL(SUM((pct_of_product*env_impact_score)/100), -1) pct_score
        INTO v_env_impact_score
          FROM
        (
           SELECT mi.product_id, mi.gt_material_id, mi.pct_of_product, MAX(NVL(m.env_impact_score, 0)) env_impact_score
             FROM gt_pda_material_item mi, gt_material m
            WHERE mi.gt_material_id = m.gt_material_id
              AND mi.product_id = in_product_id
              AND mi.revision_id = in_revision_id
            GROUP BY mi.product_id, mi.gt_material_id, mi.pct_of_product
        ) mi, product p
        WHERE p.product_id = mi.product_id(+) -- make sure there's row even if no data
          AND p.product_id = in_product_id;
		
		--first rescale the materials ei score... the v_packaging_weight is zero here if gt_product_answers.prod_weight included packaging so this line below will always be right.
		out_materials_ei := v_env_impact_score * v_prod_weight_no_pkg / v_final_total_weight;
		
		v_env_impact_score := out_materials_ei;
		IF out_trans_pack_ei > 0 THEN v_env_impact_score := v_env_impact_score + out_trans_pack_ei;
		END IF;
		IF out_pack_ei > 0 THEN v_env_impact_score := v_env_impact_score + out_pack_ei;
		ELSE RETURN; --- get out because cant calculate the score without the packaging contribution
		END IF;
		
		-- Part 2b - battery score -- may not be batteries
		
		-- does this prod use batteries / power
	    SELECT NVL(electric_powered,-1) 
		  INTO v_electrical_power
		  FROM gt_pdesign_answers pda, product p
		 WHERE p.product_id = pda.product_id(+)
		   AND ((pda.revision_id = in_revision_id) OR (pda.revision_id IS NULL))
		   AND p.product_id = in_product_id;
		
		-- what's the worst env score for batteries (the env_impact score is linked to battery type byt can fall back to a score linked to the chemistry if the type env score = -1)
		SELECT NVL(DECODE(MAX(bt.env_score), -1, MAX(bc.env_score), MAX(bt.env_score)),-1) env_score, COUNT(*) num_batteries  
		  INTO v_battery_env_impact_score, v_num_batteries
		  FROM gt_pda_battery pb, gt_battery b, gt_battery_type bt, gt_battery_chem bc, product p
		 WHERE p.product_id = pb.product_id
		   AND pb.gt_battery_code_id = b.gt_battery_code_id
		   AND pb.gt_battery_type_id = bt.gt_battery_type_id
		   AND b.gt_battery_chem_id = bc.gt_battery_chem_id
		   AND pb.revision_id = in_revision_id
		   AND pb.product_id = in_product_id;
		   
		 -- are there any mains items
		SELECT COUNT(*) 
		  INTO v_num_mains
		  FROM gt_pda_main_power mp, product p
		 WHERE p.product_id = mp.product_id
		   AND mp.revision_id = in_revision_id
		   AND mp.product_id = in_product_id;
		   
		-- now caclulate the env inpact part of the score based on materials and batteries
		-- if the pt2a score is -1 (e.g. can't be calculated) or the product doesn't use electrical power - then no need to calc pt2b
		IF (v_env_impact_score >= 0) AND (v_electrical_power = 1) THEN
		
			-- if we have batteries then calc the score
			IF (v_num_batteries > 0) THEN 
				v_env_impact_score := v_env_impact_score + v_battery_env_impact_score;
			END IF;
			
			-- if there are mains present and no batteries - nothing required
			
			-- if no batteries od mains added then can't calc score
			IF ((v_num_batteries = 0) AND (v_num_mains=0)) THEN
				v_env_impact_score := -1; -- not enough info to score properly - so reset
			END IF;
			
		END IF;

	  WHEN PROD_CLASS_PARENT_PACK THEN 
		v_ingredient_count :=-1; -- no formulation / PD
	  WHEN PROD_CLASS_FOOD THEN 
		SELECT NVL(COUNT(DISTINCT(gt_fd_ingred_type_id)), -1) 
		  INTO v_ingredient_count
		  FROM gt_fd_ingredient fi, product p
		 WHERE p.product_id = fi.product_id(+) -- ensures we have a row - even ingredient items
		   AND p.product_id = in_product_id
		   AND revision_id = in_revision_id;
		   
		   
		SELECT NVL(SUM(fi.pct_of_product), -1) 
		  INTO v_total_pct
		  FROM product p, gt_fd_ingredient fi 
			WHERE p.product_id = fi.product_id(+)
              AND p.product_id = in_product_id
              AND ((fi.revision_id = in_revision_id) OR (fi.revision_id IS NULL));
		
		SELECT NVL(pct_added_water, -1)
		  INTO v_food_added_water
		  FROM product p, gt_food_answers f
		 WHERE p.product_id = f.product_id(+)
           AND p.product_id = in_product_id
           AND ((f.revision_id = in_revision_id) OR (f.revision_id IS NULL));
	    
		v_total_pct := v_food_added_water + v_total_pct;
		
		SELECT NVL(SUM((pct_of_product*env_impact_score)/100), -1) env_score, NVL(SUM((pct_of_product*pesticide_score)/100), -1) pest_score
        INTO v_env_impact_score, v_pesticide_score
          FROM
        (
           SELECT fi.product_id, fi.gt_fd_ingred_type_id, fi.pct_of_product, MAX(NVL(ft.env_impact_score, 0)) env_impact_score, MAX(NVL(ft.env_impact_score, 0)) pesticide_score
             FROM gt_fd_ingredient fi, gt_fd_ingred_type ft
            WHERE fi.gt_fd_ingred_type_id = ft.gt_fd_ingred_type_id
              AND fi.product_id = in_product_id
              AND fi.revision_id = in_revision_id
            GROUP BY fi.product_id, fi.gt_fd_ingred_type_id, fi.pct_of_product
        ) fi, product p
        WHERE p.product_id = fi.product_id(+) -- make sure there's row even if no data
          AND p.product_id = in_product_id;
		  
		--first rescale the materials ei score... the v_packaging_weight is zero here if gt_product_answers.prod_weight included packaging so this line below will always be right.
		out_materials_ei := v_env_impact_score * v_prod_weight_no_pkg / v_final_total_weight; -- get just the environmental impact score, as this is desired for the profile page
		v_env_impact_score := out_materials_ei + v_pesticide_score *  v_prod_weight_no_pkg / v_final_total_weight; -- then add the pesticide score separately
		
		IF out_trans_pack_ei > 0 THEN v_env_impact_score := v_env_impact_score + out_trans_pack_ei;
		END IF;
		IF out_pack_ei > 0 THEN v_env_impact_score := v_env_impact_score + out_pack_ei;
		ELSE RETURN; --- get out because cant calculate the score without the packaging contribution
		END IF;
		
		
	  ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Unknown product class ('||in_prod_class_id||')');
	END CASE;

	CASE 
	  WHEN v_ingredient_count<=0 THEN out_whats_in_prod_score := -1; -- can't have no ingredients - so not yet set
	  WHEN v_ingredient_count<=10 THEN out_whats_in_prod_score := 1;
	  WHEN v_ingredient_count<=19 THEN out_whats_in_prod_score := 2;
	  WHEN v_ingredient_count<=29 THEN out_whats_in_prod_score := 3;
	  WHEN v_ingredient_count<=39 THEN out_whats_in_prod_score := 4;
	  WHEN v_ingredient_count>=40 THEN out_whats_in_prod_score := 5;
	END CASE;
	
	IF ((out_whats_in_prod_score>=0) AND (v_env_impact_score>=0) AND (v_total_pct=100)) THEN
		out_whats_in_prod_score := out_whats_in_prod_score + v_env_impact_score;
	ELSE out_whats_in_prod_score := -1;
	END IF;
	
END;

-- 2 and 3
PROCEDURE CalcWaterEnergyManfctScore(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_product_id					IN product.product_id%TYPE, 
	in_prod_class_id				IN gt_product_class.gt_product_class_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_score_water_in_prod			OUT gt_scores.score_water_in_prod%TYPE,
	out_score_energy_in_prod		OUT gt_scores.score_energy_in_prod%TYPE,
	out_score_water_raw_mat			OUT gt_profile.score_water_raw_mat%TYPE,
	out_score_water_contained		OUT gt_profile.score_water_contained%TYPE,
	out_score_water_mnfct			OUT gt_profile.score_water_mnfct%TYPE,
	out_score_water_wsr				OUT gt_profile.score_water_wsr%TYPE
)
AS
	v_av_water_content_pct			gt_formulation_answers.water_pct%TYPE;
	v_food_added_water				gt_food_answers.pct_added_water%TYPE;
	v_score_water_raw_mat			gt_profile.score_water_raw_mat%TYPE;
	v_score_water_wsr				gt_water_stress_region.score%TYPE;
	v_score_water_mnfct				gt_formulation_answers.water_pct%TYPE;
	v_score_water_in_prod			gt_scores.score_water_in_prod%TYPE := -1;
	v_score_water_in_manufac		gt_product_type.mnfct_water_score%TYPE := -1;
	v_score_energy_in_prod			gt_scores.score_energy_in_prod%TYPE := -1;
	v_water_in_prod_pd				gt_product_type.water_in_prod_pd%TYPE;
	v_total_pct						NUMBER(6, 3);
	v_num_rows						NUMBER(10);
	v_has_water_stress				NUMBER(10);
	v_gt_product_type_id			gt_product_type.gt_product_type_id%TYPE;
BEGIN
	out_score_water_in_prod := -1;
	out_score_energy_in_prod := -1;
	out_score_water_raw_mat := -1;
	out_score_water_contained := -1;
	out_score_water_mnfct := -1;
	out_score_water_wsr := -1;
	
	v_gt_product_type_id := product_info_pkg.GetProductTypeId(in_act_id, in_product_id, in_revision_id);
	
	CASE in_prod_class_id
		WHEN PROD_CLASS_FORMULATED THEN 
	  
			
			--Calculated in 3 parts
			-----------------------
			--****************************************************
			-- PART 1 % Water in product - entered directly
			-- PART 2 From Prvenance % times factors
			-- PART 3 Water used in manufacturing - look up straight from prod type

			SELECT NVL(mnfct_water_score, -1) INTO v_score_water_in_manufac FROM gt_product_type WHERE gt_product_type_id = v_gt_product_type_id;
			-----------------------
			--****************************************************
			
			--- THEN SUM 3 parts ID all > 0!!!!
			
			-- get as much up front as possible        
			SELECT 
				-- 2 
				NVL(fa.water_pct, -1) av_water_content_pct
			INTO v_av_water_content_pct 
			FROM gt_formulation_answers fa, all_product p
				WHERE p.product_id = fa.product_id(+)
				AND p.product_id = in_product_id
				AND ((fa.revision_id = in_revision_id) OR (fa.revision_id IS NULL));
				
			-- LOGIC ENERGY: A factor set directly based on product type
			-- LOGIC WATER: sum of three parts and a modifier - representing: water contained in the product, water used to prepare the raw materials, water used in the process of manufacture - and a modifier based on 
			-- whether the water comes from a water stressed region
			--Based on % water content which comes from product type + sum of biodiversity provenance percentages times provenance type scores + water used in the manufacturing process of this type of product

				-- Num = % water content
				-- Num=0 						-> 1
				-- Num<25				 		-> 2
				-- Num<75				 		-> 3
				-- Num<=100				 		-> 4
			CASE 
				WHEN v_av_water_content_pct < 0 THEN v_score_water_in_prod := -1; -- not set
				WHEN v_av_water_content_pct=0 THEN v_score_water_in_prod := 1;
				WHEN v_av_water_content_pct<25 THEN v_score_water_in_prod := 2;
				WHEN v_av_water_content_pct<75 THEN v_score_water_in_prod := 3;
				WHEN v_av_water_content_pct<=100 THEN v_score_water_in_prod := 4;
			END CASE;
			out_score_water_contained := v_score_water_in_prod; -- can definitely assert this sub score, "water contained in product score" here...
			
			-- 3 
			SELECT NVL(mnfct_energy_score, -1) INTO v_score_energy_in_prod FROM gt_product_type WHERE gt_product_type_id = v_gt_product_type_id;
			

			-- part 2: finding the water used in getting the raw materials...
			SELECT COUNT(*)
			INTO v_num_rows
			FROM gt_formulation_answers
			WHERE product_id = in_product_id
			AND revision_id = in_revision_id;
			
			IF v_num_rows = 1 THEN
				SELECT (NVL(bp_crops_pct, 0) * 2 + NVL(bp_fish_pct, 0) * 3 + NVL(bp_palm_pct, 0) * 2 + NVL(bp_palm_processed_pct, 0) * 2
				+ NVL(bp_wild_pct, 0) * 1 + NVL(bp_unknown_pct, 0) * 4 + NVL(bp_mineral_pct, 0) * 4) / 100, 
				NVL(bp_crops_pct, 0) + NVL(bp_fish_pct, 0) + NVL(bp_palm_pct, 0) + NVL(bp_wild_pct, 0) + NVL(water_pct, 0) +
				NVL(bp_unknown_pct, 0) + NVL(bp_palm_processed_pct, 0) + NVL(bp_mineral_pct, 0)
				  INTO v_score_water_raw_mat, v_total_pct
				  FROM gt_formulation_answers
				 WHERE product_id = in_product_id
				   AND revision_id = in_revision_id;
			
				-- Water SCORES AS TAKEN FROM ANDREW'S EXCEL DOC...
				--Mixed Agricultural	2  BP_CROPS_PCT
				--Intensive farming	3  BP_FISH_PCT
				--Palm oil			2  BP_PALM_PCT
				--Processed Veg oils	2  BP_PALM_PROCESSED_PCT
				--Wild Harvested		1  BP_WILD_PCT
				--THREATENED				1  BP_THREATENED_PCT
				--Unknown				4  BP_UNKNOWN_PCT
				--Mineral / synthetic	4  BP_MINERAL_PCT
				
				IF v_total_pct = 100 THEN
					v_score_water_in_prod := v_score_water_in_prod + v_score_water_raw_mat;
					out_score_water_raw_mat := v_score_water_raw_mat;
				ELSE v_score_water_in_prod := -1;
				END IF;
			END IF;
			--part 3: finding the water used in the manufacturing process
			SELECT NVL(mnfct_water_score, -1)
			  INTO v_score_water_mnfct
			  FROM gt_product_type
			 WHERE gt_product_type.gt_product_type_id = v_gt_product_type_id;
			
			IF (v_score_water_mnfct < 0) AND (v_score_water_in_prod < 0) THEN
				v_score_water_in_prod := -1;
			ELSE 
				v_score_water_in_prod := v_score_water_in_prod + v_score_water_mnfct;
				out_score_water_mnfct := v_score_water_mnfct;
			END IF;
			
			-- here the maximum water stressed region score out of the associated wsr's is taken...
			SELECT NVL(MAX(wsr.score), -1)
			INTO v_score_water_wsr
			FROM gt_fa_wsr fa, gt_water_stress_region wsr
			WHERE wsr.gt_water_stress_region_id = fa.gt_water_stress_region_id
			AND fa.product_id = in_product_id
			AND fa.revision_id = in_revision_id;
			
			IF (v_score_water_wsr > -1) AND (v_score_water_in_prod > 0) THEN 
				v_score_water_in_prod := v_score_water_in_prod + v_score_water_wsr;
				out_score_water_wsr := v_score_water_wsr;
			ELSE 
				v_score_water_in_prod := -1; -- refuse to calculate score without modifier		
			END IF;
		WHEN PROD_CLASS_MANUFACTURED THEN 
		
			SELECT NVL(SUM(mi.pct_of_product), -1) 
			  INTO v_total_pct
			  FROM product p, gt_pda_material_item mi 
				WHERE p.product_id = mi.product_id(+)
				  AND p.product_id = in_product_id
				  AND ((mi.revision_id = in_revision_id) OR (mi.revision_id IS NULL));
			
			-- LOGIC: Water and energy score for each material's manufacturing type ammortized over the pct in product -- WATER SCORE WILL ALSO NEED SOME MORE CONTRIBUTIONS...
			SELECT NVL(SUM((pct_of_product*energy_score)/100), -1), NVL(SUM((pct_of_product*water_score)/100), -1)
			  INTO v_score_energy_in_prod, v_score_water_in_prod
			  FROM
			(
			   SELECT mi.product_id, mi.gt_manufac_type_id, mi.pct_of_product, MAX(NVL(m.energy_req_score, 0)) energy_score, MAX(NVL(m.water_req_score, 0)) water_score 
				 FROM gt_pda_material_item mi, gt_manufac_type m
				WHERE mi.gt_manufac_type_id = m.gt_manufac_type_id
				  AND mi.product_id = in_product_id
				  AND mi.revision_id = in_revision_id
				GROUP BY mi.product_id, mi.gt_manufac_type_id, mi.pct_of_product
			) mi, product p
			WHERE p.product_id = mi.product_id(+) -- make sure there's row even if no data
			  AND p.product_id = in_product_id;
			IF (v_total_pct<100) THEN
				v_score_water_in_prod := -1;
				v_score_energy_in_prod := -1;
			END IF;
			
			out_score_water_mnfct := v_score_water_in_prod;-- at this stage have just calculated the water impact from the manufacturing process
			
			--NOW NEED TO WORK OUT "WATER IN THE PRODUCT" - to get returned individually as out_score_water_contained - 
			--FOR MANUFACTURED PRODUCT DERIVED FROM PRODUCT TYPE (AND WILL BE 0 IN MOST CASES)
			
			SELECT water_in_prod_pd
			  INTO v_water_in_prod_pd
			  FROM gt_product_type
			 WHERE gt_product_type.gt_product_type_id = v_gt_product_type_id;
			
			-- this score must exist so can just safely add it...
			IF v_score_water_in_prod >= 0 THEN 
				v_score_water_in_prod := v_score_water_in_prod + v_water_in_prod_pd; 
				out_score_water_contained := v_water_in_prod_pd;
			END IF;
			
			--now get the water used in making the raw materials... contributions from every material item in the product, weighted by the "thirst" of each material...
			--find if we have material items by counting them...
			SELECT COUNT(*)
			INTO v_num_rows
			FROM gt_pda_material_item
			WHERE product_id = in_product_id
			AND revision_id = in_revision_id;
			
			IF v_num_rows > 0 THEN 
				SELECT NVL(SUM(mt.water_impact_score * mi.pct_of_product)/100, -1)
				INTO v_score_water_raw_mat
				FROM gt_pda_material_item mi, gt_material mt
				WHERE mi.gt_material_id = mt.gt_material_id
				AND mi.product_id = in_product_id
				AND mi.revision_id = in_revision_id;
				
				IF (v_score_water_raw_mat >= 0) AND (v_score_water_in_prod >= 0) THEN
					out_score_water_raw_mat := v_score_water_raw_mat;
					v_score_water_in_prod := v_score_water_in_prod + v_score_water_raw_mat;
				ELSE v_score_water_in_prod := -1; -- refuse to calculate score if raw materials score could not be calculated
				END IF;
				--ADD WATER STRESS REGION MODIFIER
				SELECT NVL(SUM(wsr.score * mi.pct_of_product)/100, -1)
				INTO v_score_water_wsr
				FROM gt_water_stress_region wsr, gt_pda_material_item mi
				WHERE mi.gt_water_stress_region_id = wsr.gt_water_stress_region_id
				AND mi.product_id = in_product_id
				AND mi.revision_id = in_revision_id;

				IF (v_score_water_wsr >= 0) AND (v_score_water_in_prod >= 0) THEN
					out_score_water_wsr := v_score_water_wsr;
					v_score_water_in_prod := v_score_water_in_prod + v_score_water_wsr;
				ELSE 
					v_score_water_in_prod := -1; -- refuse to calculate score if raw materials score could not be calculated
				END IF;
			ELSE v_score_water_in_prod := -1;
			END IF;	
			
		WHEN PROD_CLASS_PARENT_PACK THEN 
			NULL; -- no formulation / PD
		WHEN PROD_CLASS_FOOD THEN 
			SELECT COUNT(*)
			INTO v_num_rows
			FROM gt_food_answers
			WHERE revision_id = in_revision_id
			AND product_id = in_product_id;
			IF v_num_rows = 1 THEN
			
				-- 3 components (no mention of wsr for food)
				--		water in product (from the % added water field)
				--		water in production
				-- 		water in manufacture - just the score associated with the product type
				
				--LOGIC ENERGY - just tehe score associated with the product type
				SELECT NVL(mnfct_energy_score, -1) INTO v_score_energy_in_prod FROM gt_product_type WHERE gt_product_type_id = v_gt_product_type_id;
				
				-- also doing energy but that will be the same as for the other 2:
				SELECT pct_added_water / 100 INTO v_food_added_water FROM gt_food_answers WHERE product_id = in_product_id AND revision_id = in_revision_id;
				out_score_water_contained := v_food_added_water;
				SELECT water_in_prod_pd INTO out_score_water_mnfct FROM gt_product_type WHERE gt_product_type_id = v_gt_product_type_id;
				SELECT SUM(fi.pct_of_product * ft.water_impact_score / 100)
				INTO out_score_water_raw_mat
				FROM gt_fd_ingredient fi, gt_fd_ingred_type ft
				WHERE fi.gt_fd_ingred_type_id = ft.gt_fd_ingred_type_id
				AND fi.product_id = in_product_id
				AND fi.revision_id = in_revision_id;
				
				out_score_water_wsr := 0;
				SELECT COUNT(*) 
				INTO v_has_water_stress
				FROM gt_food_answers fa
				WHERE NOT fa.gt_water_stress_region_id IS NULL
				AND fa.product_id = in_product_id
				AND fa.revision_id = in_revision_id;
				IF v_has_water_stress > 0 THEN
					SELECT DECODE(description, 'None of the regions listed', 0, 0.2)
					INTO out_score_water_wsr
					FROM gt_water_stress_region ws, gt_food_answers fa
					WHERE fa.gt_water_stress_region_id(+) = ws.gt_water_stress_region_id
					AND fa.product_id = in_product_id
					AND fa.revision_id = in_revision_id;
				END IF;
				v_score_water_in_prod := out_score_water_wsr + out_score_water_mnfct + out_score_water_raw_mat + out_score_water_contained;
			END IF;
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown product class ('||in_prod_class_id||')');
	END CASE;
	
	out_score_water_in_prod := v_score_water_in_prod;
	out_score_energy_in_prod := v_score_energy_in_prod;
	
	--out_score_water_in_prod := 0;
	--out_score_water_raw_mat := 0;
	--out_score_water_contained := 0;
	--out_score_water_mnfct := 0;
	--out_score_water_wsr	:= 0;
END;

-- 4
-- broken out as then can use same func for 
PROCEDURE CalcPackImpactScoreFromData(
	in_product_id					IN 	product.product_id%TYPE, 
	in_prod_class_id				IN 	gt_product_class.gt_product_class_id%TYPE,
	in_revision_id					IN 	product_revision.revision_id%TYPE,
	in_prod_weight					IN	gt_product_answers.prod_weight%TYPE,
	in_inc_pkg						IN	gt_product_answers.weight_inc_pkg%TYPE,
	in_concentrate_pack				IN	gt_formulation_answers.concentrate%TYPE, 
	in_refill_pack					IN	gt_packaging_answers.refill_pack%TYPE,
	in_pack_weight_total			IN	gt_pack_item.weight_grams%TYPE, 
	out_score_pack_impact			OUT gt_scores.score_pack_impact%TYPE, 
	out_score_pack_impact_raw		OUT gt_scores.score_pack_impact%TYPE
) 
AS
	v_score_pack_impact_raw			gt_scores.score_pack_impact%TYPE;
	v_concentrate_pack				gt_formulation_answers.concentrate%TYPE;
	v_prod_weight_exc_pack			gt_product_answers.prod_weight%TYPE;
BEGIN

	v_concentrate_pack := in_concentrate_pack;

	
	CASE in_prod_class_id
	  WHEN PROD_CLASS_FORMULATED THEN 
		NULL; -- have all info
	  WHEN PROD_CLASS_MANUFACTURED THEN 
		v_concentrate_pack := 0; -- concentrate doesn't apply to manufactured items
	  WHEN PROD_CLASS_PARENT_PACK THEN 
		v_concentrate_pack := 0; 
	  WHEN PROD_CLASS_FOOD THEN 
		v_concentrate_pack := 0; -- concentrate doesn't apply to PP items
		-- no formulation / PD
	  ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Unknown product class ('||in_prod_class_id||')');
	END CASE;
	
	-- Now we need to make sure the prod weight is adjusted to be exc packging
	IF in_inc_pkg = 1 THEN
		IF (in_prod_weight < 0) OR (in_pack_weight_total < 0) THEN
			-- can't calc this yet
			v_prod_weight_exc_pack := -1;
		ELSE
			v_prod_weight_exc_pack := in_prod_weight - in_pack_weight_total;
		END IF;
		
		-- if the packaging weighs more that the product they can't calc score at the moment
		IF v_prod_weight_exc_pack < 0 THEN 
			v_prod_weight_exc_pack := -1; -- not set 
		END IF;
	ELSE
		v_prod_weight_exc_pack := in_prod_weight; -- don't have to consider what is or isn't set
	END IF;

	-- LOGIC: 
	-- score = The % ratio of totaL product weight (exc retail packaging) to the retail packaging weight / 5 
	-- 	score=score-0.5 if pack is designed for concentrate
	--  score=score-1.5 if pack is designed for reuse
	-- 	The above can accumulate
	--  Max possible score is 8

	-- need all these to get score
	IF (in_pack_weight_total>0) AND (v_prod_weight_exc_pack>0) AND (v_concentrate_pack>=0) AND (in_refill_pack>=0) THEN
		v_score_pack_impact_raw := (100*(in_pack_weight_total/(v_prod_weight_exc_pack)))/5;
		v_score_pack_impact_raw := v_score_pack_impact_raw - (v_concentrate_pack * 0.5);
		v_score_pack_impact_raw := v_score_pack_impact_raw - (in_refill_pack * 1.5);
	
		IF v_score_pack_impact_raw < 0 THEN v_score_pack_impact_raw := 0; END IF;
			
		-- store the raw score (can be more than 8)
		out_score_pack_impact_raw := v_score_pack_impact_raw;
		
		--  Max possible score is 8
		IF v_score_pack_impact_raw > 8 THEN v_score_pack_impact_raw := 8; END IF;
		
		-- store the adjusted score
		out_score_pack_impact := v_score_pack_impact_raw;		
		
	ELSE
		out_score_pack_impact := -1;
		out_score_pack_impact_raw := -1;
	END IF;

END;


PROCEDURE CalcPackImpactScore(
	in_product_id					IN product.product_id%TYPE, 
	in_prod_class_id				IN gt_product_class.gt_product_class_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_score_pack_impact			OUT gt_scores.score_pack_impact%TYPE,
	out_score_pack_impact_raw		OUT gt_scores.score_pack_impact%TYPE
)
AS
	v_prod_weight					gt_product_answers.prod_weight%TYPE;  
	v_inc_pkg						gt_product_answers.weight_inc_pkg%TYPE;
	v_concentrate_pack				gt_formulation_answers.concentrate%TYPE; 
	v_refill_pack					gt_packaging_answers.refill_pack%TYPE; 
	v_packaging_weight_total		gt_pack_item.weight_grams%TYPE;
BEGIN

	out_score_pack_impact := -1;
	out_score_pack_impact_raw := -1;
	      
    SELECT 
			NVL(prod_weight,-1), NVL(weight_inc_pkg, -1), NVL(concentrate,-1), NVL(refill_pack,-1)
      INTO v_prod_weight, v_inc_pkg, v_concentrate_pack, v_refill_pack
      FROM gt_formulation_answers fa, gt_product_answers pa, gt_packaging_answers pka, all_product p
     WHERE p.product_id = fa.product_id(+)
       AND p.product_id = pa.product_id(+)
       AND p.product_id = pka.product_id(+)
       AND p.product_id = in_product_id
       AND ((fa.revision_id = in_revision_id) OR (fa.revision_id IS NULL))
       AND ((pa.revision_id = in_revision_id) OR (pa.revision_id IS NULL))
       AND ((pka.revision_id = in_revision_id) OR (pka.revision_id IS NULL));
 
	SELECT 
		   NVL(SUM(weight_grams),-1) pack_weight 
	  INTO v_packaging_weight_total
	  FROM gt_pack_item pi
	 WHERE product_id = in_product_id
	   AND revision_id = in_revision_id;

	CalcPackImpactScoreFromData(in_product_id, in_prod_class_id, in_revision_id, v_prod_weight, v_inc_pkg, v_concentrate_pack, v_refill_pack, v_packaging_weight_total, out_score_pack_impact, out_score_pack_impact_raw);

END;

------------------------------
--	Product Supply
------------------------------
-- 6
PROCEDURE CalcEnergyDist(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_product_id					IN product.product_id%TYPE, 
	in_prod_class_id				IN gt_product_class.gt_product_class_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_score_energy_dist			OUT gt_scores.score_energy_dist%TYPE
)
AS
	
BEGIN

	-- always 1 for All classes except FOOD

	out_score_energy_dist := -1;
	
--	CASE in_prod_class_id
--	  WHEN PROD_CLASS_FORMULATED THEN 
--
--		out_score_energy_dist := 1;
--		
--	  WHEN PROD_CLASS_MANUFACTURED THEN 
--	  
--		out_score_energy_dist := 1;		
--
--		
--	  WHEN PROD_CLASS_PARENT_PACK THEN 
--		
--		out_score_energy_dist := 1;
--	  
--	  WHEN PROD_CLASS_FOOD THEN 
--		
--		out_score_energy_dist := 1;
--	  
--	  ELSE
--		RAISE_APPLICATION_ERROR(-20001, 'Unknown product class ('||in_prod_class_id||')');
--	END CASE;	
	SELECT energy_in_dist_score INTO out_score_energy_dist FROM gt_product_type WHERE gt_product_type_id = product_info_pkg.GetProductTypeId(in_act_id, in_product_id, in_revision_id);
END;

------------------------------
--	Use at home
------------------------------

PROCEDURE CalcAncMatScore(
	in_product_id					IN product.product_id%TYPE, 
	in_prod_class_id				IN gt_product_class.gt_product_class_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_score_ancillary_req			OUT gt_scores.score_ancillary_req%TYPE, 
	out_gt_low_anc_list				OUT gt_profile.gt_low_anc_list%TYPE,
	out_gt_med_anc_list				OUT gt_profile.gt_med_anc_list%TYPE,
	out_gt_high_anc_list			OUT gt_profile.gt_high_anc_list%TYPE	
)
AS
BEGIN

	out_score_ancillary_req := -1;
	
	-- LOGIC: check list of ancilaries needed and take worst (highest) score from the below
	-- No additional materials (other than water)								  	-> 1
	-- Yes, materials such as cotton wool, wipes, tissue, disposable applicators  	-> 2
	-- Yes, formulated products such as soaps, surfactants, cleansers				-> 3
	-- Yes, solvents (nail polish remover)											-> 5
	
	CASE in_prod_class_id
		WHEN PROD_CLASS_FORMULATED THEN 
	  
			SELECT 
				MAX(DECODE(s.gt_score, 2, NVL(anc_list, 'None'), null)) low_list, 
				MAX(DECODE(s.gt_score, 3, NVL(anc_list, 'None'), null)) med_list, 
				MAX(DECODE(s.gt_score, 5, NVL(anc_list, 'None'), null)) high_list,
				NVL(MAX(a.gt_score), -1) gt_score
			INTO out_gt_low_anc_list, out_gt_med_anc_list, out_gt_high_anc_list, out_score_ancillary_req
			FROM 
			(
				SELECT gt_score, csr.stragg(description) anc_list
				  FROM gt_fa_anc_mat fam, gt_ancillary_material am
				 WHERE fam.gt_ancillary_material_id = am.gt_ancillary_material_id
				   AND fam.product_id = in_product_id
				   AND fam.revision_id = in_revision_id
				GROUP BY gt_score
			) a, 
			(
				SELECT DISTINCT(gt_score) gt_score FROM gt_ancillary_material
			) s
			WHERE s.gt_score = a.gt_score(+);
	  
		WHEN PROD_CLASS_MANUFACTURED THEN 
	  
			SELECT 
				MAX(DECODE(s.gt_score, 2, NVL(anc_list, 'None'), null)) low_list, 
				MAX(DECODE(s.gt_score, 3, NVL(anc_list, 'None'), null)) med_list, 
				MAX(DECODE(s.gt_score, 5, NVL(anc_list, 'None'), null)) high_list,
				NVL(MAX(a.gt_score), -1) gt_score
			INTO out_gt_low_anc_list, out_gt_med_anc_list, out_gt_high_anc_list, out_score_ancillary_req
			FROM 
			(
				SELECT gt_score, csr.stragg(description) anc_list
				  FROM gt_pda_anc_mat pda, gt_ancillary_material am
				 WHERE  pda.gt_ancillary_material_id = am.gt_ancillary_material_id
				   AND  pda.product_id = in_product_id
				   AND  pda.revision_id = in_revision_id
				GROUP BY gt_score
			) a, 
			(
				SELECT DISTINCT(gt_score) gt_score FROM gt_ancillary_material
			) s
			WHERE s.gt_score = a.gt_score(+);

		WHEN PROD_CLASS_PARENT_PACK THEN 
			NULL; -- no formulation / PD
		WHEN PROD_CLASS_FOOD THEN 
			SELECT 
				MAX(DECODE(s.gt_score, 2, NVL(anc_list, 'None'), null)) low_list, 
				MAX(DECODE(s.gt_score, 3, NVL(anc_list, 'None'), null)) med_list, 
				MAX(DECODE(s.gt_score, 5, NVL(anc_list, 'None'), null)) high_list,
				NVL(MAX(a.gt_score), -1) gt_score
			INTO out_gt_low_anc_list, out_gt_med_anc_list, out_gt_high_anc_list, out_score_ancillary_req
			FROM 
			(
				SELECT gt_score, csr.stragg(description) anc_list
				  FROM gt_food_anc_mat fda, gt_ancillary_material am
				 WHERE  fda.gt_ancillary_material_id = am.gt_ancillary_material_id
				   AND  fda.product_id = in_product_id
				   AND  fda.revision_id = in_revision_id
				GROUP BY gt_score
			) a, 
			(
				SELECT DISTINCT(gt_score) gt_score FROM gt_ancillary_material
			) s
			WHERE s.gt_score = a.gt_score(+);
		
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown product class ('||in_prod_class_id||')');
	END CASE;	

END;

-- done energy at the same time as same query
PROCEDURE CalcWaterEnergyUseScores(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_product_id					IN product.product_id%TYPE, 
	in_prod_class_id				IN gt_product_class.gt_product_class_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_score_water_use				OUT gt_scores.score_water_use%TYPE,
	out_score_energy_use			OUT gt_scores.score_energy_use%TYPE
)
AS
	--1 
	v_water_capacity_ltr		gt_water_use_type.water_capacity_ltr%TYPE;
	v_water_usage_factor		gt_product_type.water_usage_factor%TYPE;
	v_raw_water_usage_factor	gt_product_type.water_usage_factor%TYPE;
	v_product_volume			gt_product_answers.product_volume%TYPE;
	v_reduce_water_use_adv		gt_product_answers.reduce_water_use_adv%TYPE;

	--2
	-- batteries
	v_score_energy_use			gt_scores.score_energy_use%TYPE;
	v_score_energy_battery		gt_scores.score_energy_use%TYPE;
	v_score_energy_mains		gt_scores.score_energy_use%TYPE;
	v_electrical_power			NUMBER(1);
	v_num_mains					NUMBER(10);
	v_num_batteries				NUMBER(10);
	--2
	-- mains
	v_hours_use_month			gt_product_type.hrs_used_per_month%TYPE;
	v_wattage					gt_pda_main_power.wattage%TYPE;
	v_standby					gt_pda_main_power.standby%TYPE;
	v_kwH_month					NUMBER(15,5);	
	v_reduce_energy_use_adv		gt_product_answers.reduce_energy_use_adv%TYPE;
	
	v_gt_product_type_id		gt_product_type.gt_product_type_id%TYPE;
BEGIN

	out_score_water_use := -1;
	out_score_energy_use := -1;
	
	v_gt_product_type_id := product_info_pkg.GetProductTypeId(in_act_id, in_product_id, in_revision_id);
	
	SELECT 
	   -- 1
	   NVL(wut.water_capacity_ltr,-1) water_capacity_ltr, 
	   NVL(pt.water_usage_factor, -1) water_usage_factor, 
	   pt.water_usage_factor raw_water_usage_factor,
	   -- 2 
	  NVL(pt.use_energy_score, -1) use_energy_score
	 INTO v_water_capacity_ltr, v_water_usage_factor, v_raw_water_usage_factor, v_score_energy_use
	  FROM gt_product_type pt, gt_water_use_type wut 
	 WHERE pt.gt_water_use_type_id = wut.gt_water_use_type_id(+) 
	   AND gt_product_type_id = v_gt_product_type_id;
	
	SELECT  

		-- 1 
		-- 2
	  NVL(pa.product_volume, -1) product_volume, NVL(reduce_water_use_adv, -1), NVL(reduce_energy_use_adv, -1)
	 INTO v_product_volume, v_reduce_water_use_adv, v_reduce_energy_use_adv
	 FROM gt_product_answers pa, all_product p
	WHERE p.product_id = pa.product_id(+)
	  AND p.product_id = in_product_id
	  AND ((pa.revision_id = in_revision_id) OR (pa.revision_id IS NULL));
	  
	 -- todo modify score based on advice if score > 0 PRODUCT ADVICE
	  
	-- Pt 1 Energy A factor set directly based on product type
	out_score_energy_use := v_score_energy_use;
	
	CASE in_prod_class_id
		WHEN PROD_CLASS_FORMULATED THEN 
			-- 1 Water	
			-- FORMULATED
			-- This is based on the ratio of the: 

			-- 
			-- Ratio = (Water cap. of typical use (ltr)) x (Vol. of Prod ml/ Amount used per app)
			
			-- in DB Amount used per app = useage factor
			
			-- Should only apply to FORMULATED  -> one case where the use per app ml is "use the whole product" (hair dye). The use per app ml is -1 in the product type table
			-- in this case the use per app ml is the product volume (if set)
			IF (v_raw_water_usage_factor=-1) THEN
				v_water_usage_factor:=v_product_volume;
			END IF;
			-- 
			-- Final scoring
			-- Once this ratio is calculated the score is:
			-- •	Ratio<0.000001		THEN score = 1
			-- •	Ratio <0.5			THEN score = 2
			-- •	Ratio <1			THEN score = 3
			-- •	Ratio <=2			THEN score = 4
			-- •	Ratio >2			THEN score = 5			

			IF ((v_water_capacity_ltr>=0) AND (v_water_usage_factor>=0)) THEN
				CASE
					WHEN (v_water_capacity_ltr=0) THEN out_score_water_use := 0; -- no water use
					WHEN (v_water_usage_factor=0) THEN  out_score_water_use := 5; -- something used ad infinutum as not "used up"
					ELSE
						CASE 
						  WHEN v_water_capacity_ltr*(v_product_volume/v_water_usage_factor)<200 		THEN out_score_water_use := 2;
						  WHEN v_water_capacity_ltr*(v_product_volume/v_water_usage_factor)<500			THEN out_score_water_use := 3;
						  WHEN v_water_capacity_ltr*(v_product_volume/v_water_usage_factor)<=1200 		THEN out_score_water_use := 4;
						  WHEN v_water_capacity_ltr*(v_product_volume/v_water_usage_factor)>1200 		THEN out_score_water_use := 5; 
						END CASE;
				END CASE;
			END IF;	
			
		WHEN PROD_CLASS_MANUFACTURED THEN 
			-- WATER
			-- This is the useage factor only 
			out_score_water_use := v_water_usage_factor;
			
			--ENERGY
			SELECT NVL(hrs_used_per_month,-1) INTO v_hours_use_month FROM gt_product_type WHERE gt_product_type_id = v_gt_product_type_id;
			
			-- is it electrically powered
			SELECT NVL(electric_powered,-1) 
			  INTO v_electrical_power
			  FROM gt_pdesign_answers pda, product p
			 WHERE p.product_id = pda.product_id(+)
			   AND ((pda.revision_id = in_revision_id) OR (pda.revision_id IS NULL))
			   AND p.product_id = in_product_id;
			
			-- what's the worst energy home score for batteries 
			SELECT NVL(MAX(bt.energy_home_score), -1) energy_home_score, COUNT(*) num_batteries  
			  INTO v_score_energy_battery, v_num_batteries
			  FROM gt_pda_battery pb, gt_battery b, gt_battery_type bt, product p
			 WHERE p.product_id = pb.product_id
			   AND pb.gt_battery_code_id = b.gt_battery_code_id
			   AND pb.gt_battery_type_id = bt.gt_battery_type_id
			   AND pb.revision_id = in_revision_id
			   AND pb.product_id = in_product_id;
			   
			-- what's the higest wattage for mains 
			SELECT NVL(MAX(wattage),-1) wattage, COUNT(*) 
			  INTO v_wattage, v_num_mains
			  FROM gt_pda_main_power mp, product p
			 WHERE p.product_id = mp.product_id 
			   AND mp.revision_id = in_revision_id
			   AND mp.product_id = in_product_id;

			-- whats the worst case standby score for mains with the highest wattage (technically could be several)
			SELECT NVL(MIN(standby),-1) standby
			  INTO v_standby
			  FROM gt_pda_main_power mp, product p
			 WHERE p.product_id = mp.product_id 
			   AND mp.revision_id = in_revision_id
			   AND mp.product_id = in_product_id
			   AND mp.wattage = v_wattage;			
			
			-- Pt2a if the product has batteries
			IF ((v_electrical_power=0)OR((v_electrical_power=1) AND ((v_num_mains>0) OR ((v_num_batteries>0))))) THEN
				
				IF (v_electrical_power=1) THEN
				
					-- are there batteries - we use the v_score_energy_battery above
					
					-- if it mains
					v_score_energy_mains := -1;
					IF v_num_mains>0 THEN
					
						v_kwH_month := v_wattage * v_hours_use_month / 1000;
					
						-- kwH score
						CASE 
						  WHEN v_kwH_month<=0.1999 	THEN v_score_energy_mains := 1; -- this case accounts for "occasional" as use hrs for occasional = -1
						  WHEN v_kwH_month<=0.99 	THEN v_score_energy_mains := 2;
						  WHEN v_kwH_month<=4.99	THEN v_score_energy_mains := 3;
						  WHEN v_kwH_month<=10 		THEN v_score_energy_mains := 4;
						  WHEN v_kwH_month>10 		THEN v_score_energy_mains := 5; 
						END CASE;
						
						-- add modifer for 
						IF v_standby = 1 THEN 
							IF v_wattage > 1 THEN 
								v_score_energy_mains := v_score_energy_mains + 2;
							ELSE
								v_score_energy_mains := v_score_energy_mains + 1;
							END IF;
						END IF;
						
					END IF;
					
					-- add worst if usees batter and  mains
					IF v_score_energy_battery > v_score_energy_mains THEN 
						out_score_energy_use := out_score_energy_use + v_score_energy_battery;
					ELSE
						out_score_energy_use := out_score_energy_use + v_score_energy_mains;
					END IF;
				
				END IF;
				
			ELSE
				-- we don't have enough electrical info to complate score so reset the score to -1
				out_score_energy_use := -1;
			END IF;			
 			
			
		WHEN PROD_CLASS_PARENT_PACK THEN 
			out_score_water_use := v_water_usage_factor;
		
		WHEN PROD_CLASS_FOOD THEN 
			out_score_water_use := v_water_usage_factor;
		
	  
			-- no formulation / PD
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown product class ('||in_prod_class_id||')');
	END CASE;	
	
	
	-- Final modifier: On the Product Info questionnaire if the answer to “Reducing product energy use" and “Reducing product energy use" are Yes then the 
	-- relevant score gets a credit of -1 (though the score may never be less that 0)
	IF out_score_energy_use >= 0 THEN
		IF v_reduce_energy_use_adv >= 0 THEN 
			--gets credit if v_reduce_energy_use_adv = YES (1)
			out_score_energy_use := out_score_energy_use - (1 * v_reduce_energy_use_adv);
			-- but can't be made less than 0
			IF out_score_energy_use < 0 THEN 
				out_score_energy_use := 0;
			END IF;
		ELSE
			-- if the energy advice question is not answered (1 or 0) we can't score - reset to -1
			out_score_energy_use := -1;			
		END IF;
	END IF;	
	IF out_score_water_use >= 0 THEN
		IF v_reduce_water_use_adv >= 0 THEN 
			--gets credit if v_reduce_water_use_adv = YES (1)
			out_score_water_use := out_score_water_use - (1 * v_reduce_water_use_adv);
			-- but can't be made less than 0
			IF out_score_water_use < 0 THEN 
				out_score_water_use := 0;
			END IF;
		ELSE
			-- if the water advice question is not answered (1 or 0) we can't score - reset to -1
			out_score_water_use := -1;			
		END IF;
	END IF;	


END;

------------------------------
--	End of life
------------------------------

PROCEDURE CalcProductWaste(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_product_id					IN product.product_id%TYPE, 
	in_prod_class_id				IN gt_product_class.gt_product_class_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_score_prod_waste			OUT gt_scores.score_prod_waste%TYPE
)
AS
	v_score_prod_waste_pt1			gt_scores.score_prod_waste%TYPE;
	v_score_prod_waste_pt2			gt_scores.score_prod_waste%TYPE;
	v_score_prod_waste_pt3			gt_scores.score_prod_waste%TYPE;
	v_score_prod_waste_pt4			gt_scores.score_prod_waste%TYPE;

	v_reduce_waste_adv				gt_product_answers.reduce_waste_adv%TYPE;


	v_durability_type_id			gt_pdesign_answers.gt_pda_durability_type_id%TYPE;
	v_materials_separate			gt_pdesign_answers.materials_separate%TYPE;
	v_leaves_residue				gt_pdesign_answers.leaves_residue%TYPE;	
	
	v_total_pct						NUMBER(10);
	
	v_gt_product_type_id			gt_product_type.gt_product_type_id%TYPE;
	v_gt_access_visc_type_id		gt_product_type.gt_access_visc_type_id%TYPE;
	
	--v_endangered_pct				gt_pdesign_answers.endangered_pct%TYPE;
	v_num_rows						NUMBER(10);
	v_num_batteries					NUMBER(10);
	v_num_mains						NUMBER(10);
	v_electrical_power				NUMBER(1);	
	
		
BEGIN

	out_score_prod_waste := -1;
	
	v_gt_product_type_id := product_info_pkg.GetProductTypeId(in_act_id, in_product_id, in_revision_id);
	SELECT gt_access_visc_type_id INTO v_gt_access_visc_type_id FROM gt_product_type WHERE gt_product_type_id = v_gt_product_type_id;
	
	-- get waste advice modifier
	SELECT  
	  NVL(reduce_waste_adv, -1)
	 INTO v_reduce_waste_adv
	 FROM gt_product_answers pa, all_product p
	WHERE p.product_id = pa.product_id(+)
	  AND p.product_id = in_product_id
	  AND ((pa.revision_id = in_revision_id) OR (pa.revision_id IS NULL));
	
	-- get score for pack type / visc type here as potentially used for FORMULATED and MANUACTURED	
	-- get as much up front as possible
	SELECT 
	  NVL(apm.gt_access_score,-1) score_prod_waste
	 INTO v_score_prod_waste_pt3
	 FROM gt_access_pack_mapping apm, product p, gt_packaging_answers pa
	WHERE p.product_id = pa.product_id(+)
	  AND v_gt_access_visc_type_id = apm.gt_access_visc_type_id(+)
	  AND pa.gt_access_pack_type_id = apm.gt_access_pack_type_id(+)
	  AND p.product_id = in_product_id
	  AND ((pa.revision_id = in_revision_id) OR (pa.revision_id IS NULL));

	CASE in_prod_class_id
	  WHEN PROD_CLASS_FORMULATED THEN 
		
		-- FORMULATED - based on viscocity type and pack type only. Direct lookup from gt_access_pack_mapping done above
		-- +1 modifier used to represent DURABILITY - balance with Manufactured
		out_score_prod_waste := v_score_prod_waste_pt3 + 1;
		
	  WHEN PROD_CLASS_MANUFACTURED THEN 
	  
		-- MANUFACTURED-  complex - 4 parts plus seperability modifier
		-- Pt1 - Manufacturing waste - material data has a manufacturing waste score for each manufacturing process - amortize by % across material items
		-- Note: there must be at least one material for a valid product
			-- will get score = -1 if no materials 
		SELECT NVL(SUM(mi.pct_of_product), -1)
		  INTO v_total_pct
		  FROM product p, gt_pda_material_item mi 
			WHERE p.product_id = mi.product_id(+)
			  AND p.product_id = in_product_id
			  AND ((mi.revision_id = in_revision_id) OR (mi.revision_id IS NULL));
			
        SELECT NVL(SUM((pct_of_product*mnf_score)/100), -1) pct_score
		  INTO v_score_prod_waste_pt1
          FROM
        (
           SELECT mi.product_id, mi.gt_manufac_type_id, mi.pct_of_product, MAX(NVL(m.waste_score, 0)) mnf_score
             FROM gt_pda_material_item mi, gt_manufac_type m
            WHERE mi.gt_manufac_type_id = m.gt_manufac_type_id
              AND mi.product_id = in_product_id
              AND mi.revision_id = in_revision_id
            GROUP BY mi.product_id, mi.gt_manufac_type_id, mi.pct_of_product
        ) mi, product p
		WHERE p.product_id = mi.product_id(+) -- make sure there's row even if no data
		  AND p.product_id = in_product_id;
		  
		  
		
		-- Pt2 - Durability - more durable products last longer - score based directly on durability type
		-- Pt3 - Residue - if there is no residue in product score = 1, else it is looked up from gt_access_pack_mapping as for FORMULATED
		SELECT DECODE(pda.leaves_residue, 0, 1, 1, v_score_prod_waste_pt3, -1), pda.gt_pda_durability_type_id, pda.dt_score,  pda.materials_separate, leaves_residue
		  INTO v_score_prod_waste_pt3, v_durability_type_id, v_score_prod_waste_pt2, v_materials_separate, v_leaves_residue
		  FROM all_product p, 
				(SELECT product_id, revision_id, NVL(pda.gt_pda_durability_type_id, -1) gt_pda_durability_type_id, NVL(dt.score, -1) dt_score, 
						NVL(materials_separate, -1) materials_separate, NVL(leaves_residue, -1) leaves_residue
				   FROM gt_pdesign_answers pda, gt_pda_durability_type dt 
				  WHERE pda.gt_pda_durability_type_id = dt.gt_pda_durability_type_id(+)) pda
		 WHERE p.product_id = pda.product_id(+)
	   	   AND p.product_id = in_product_id
		   AND ((pda.revision_id = in_revision_id) OR (pda.revision_id IS NULL));
		   
		-- Pt4 - battery waste score
		-- does this prod use batteries / power
		v_score_prod_waste_pt4 := -1;
		
	    SELECT NVL(electric_powered,-1) 
		  INTO v_electrical_power
		  FROM gt_pdesign_answers pda, product p
		 WHERE p.product_id = pda.product_id(+)
		   AND ((pda.revision_id = in_revision_id) OR (pda.revision_id IS NULL))
		   AND p.product_id = in_product_id;
		
		-- what's the worst waste score for batteries (the waste score is linked to battery type byt can fall back to a score linked to the use pattern if the type waste score = -1)
		SELECT NVL(DECODE(MAX(bt.waste_score), -1, MAX(bu.waste_score), MAX(bt.waste_score)),-1) waste_score, COUNT(*) num_batteries  
		  INTO v_score_prod_waste_pt4, v_num_batteries
          FROM gt_pda_battery pb, gt_battery b, gt_battery_type bt, gt_battery_use bu, product p
         WHERE p.product_id = pb.product_id
           AND pb.gt_battery_code_id = b.gt_battery_code_id
           AND pb.gt_battery_type_id = bt.gt_battery_type_id
           AND pb.gt_battery_use_id = bu.gt_battery_use_id(+)
		   AND pb.revision_id = in_revision_id
		   AND pb.product_id = in_product_id;
		   
		 -- are there any mains items
		SELECT COUNT(*) 
		  INTO v_num_mains
		  FROM gt_pda_main_power mp, product p
		 WHERE p.PRODUCT_ID = mp.PRODUCT_ID
		   AND mp.revision_id = in_revision_id
		   AND mp.product_id = in_product_id;
		
		 
		IF ((v_score_prod_waste_pt1>=0) AND 
			(v_score_prod_waste_pt2>=0) AND 
			(v_score_prod_waste_pt3>=0) AND 
			(v_durability_type_id>=0) AND 
			(v_materials_separate>=0) AND
			((v_electrical_power=0)OR((v_electrical_power=1) AND ((v_num_mains>0) OR ((v_num_batteries>0) AND (v_score_prod_waste_pt4>0))))) AND 
			(v_total_pct=100)) 
		THEN -- we can get a score
		
			IF v_num_batteries = 0 THEN
				-- Step 1: No Batteries - Average of Pt1, Pt2, Pt3	
				out_score_prod_waste := (v_score_prod_waste_pt1 + v_score_prod_waste_pt2 + v_score_prod_waste_pt3)/3;
			ELSE 
				-- Step 1: Batteries - Average of (Pt1, Pt2, Pt3)	+ Pt4
				out_score_prod_waste := (v_score_prod_waste_pt1 + v_score_prod_waste_pt2 + v_score_prod_waste_pt3)/3 + v_score_prod_waste_pt4;			
			END IF;
			
			-- Step 2: modifiers - if materials are seperable, and there's no residue and the durability type is not formulated - the get 0.5 credit
			IF ((v_materials_separate>0) AND (v_leaves_residue=0) AND (v_durability_type_id != FORMULATED_DURABILITY_TYPE)) THEN 
				out_score_prod_waste := out_score_prod_waste - 0.5;
			END IF;
			
			-- just in case modifier takes below 0
			IF out_score_prod_waste < 0 THEN 
				out_score_prod_waste := 0; 
			END IF;
		ELSE 
			out_score_prod_waste := -1;
		END IF;
		
	  WHEN PROD_CLASS_PARENT_PACK THEN 
		NULL; -- no formulation / PD
	  WHEN PROD_CLASS_FOOD THEN 
		-- logic: sum the manufacturing waste score (from the product type) and the portion type score
		SELECT COUNT(*)
		INTO v_num_rows
		FROM gt_food_answers
		WHERE product_id = in_product_id
		AND revision_id = in_revision_id;
		
		IF v_num_rows = 1 THEN
			SELECT NVL(pt.score, -1)
			INTO out_score_prod_waste
			FROM gt_food_answers fa, gt_fd_portion_type pt
			WHERE fa.product_id = in_product_id
			AND fa.revision_id = in_revision_id
			AND fa.gt_fd_portion_type_id = pt.gt_fd_portion_type_id;
		END IF;
		--v_gt_product_type_id := product_info_pkg.GetProductTypeId(in_act_id, in_product_id, in_revision_id);
	
			--SELECT NVL(mnfct_water_score, -1) INTO v_score_water_in_manufac FROM gt_product_type WHERE gt_product_type_id = v_gt_product_type_id;

		
	  ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Unknown product class ('||in_prod_class_id||')');
	END CASE;	
	
	--Final modifier: On the Product Info questionnaire if the answer to “Reducing product waste" is Yes then the score gets a credit of -1 (though the score may never be less that 0)
	IF out_score_prod_waste >= 0 THEN
		IF v_reduce_waste_adv >= 0 THEN 
			--gets credit if v_reduce_waste_adv = YES (1)
			out_score_prod_waste := out_score_prod_waste - (1 * v_reduce_waste_adv);
			-- but can't be made less than 0
			IF out_score_prod_waste < 0 THEN 
				out_score_prod_waste := 0;
			END IF;
		ELSE
			-- if the waste advice question is not answered (1 or 0) we can't score - reset to -1
			out_score_prod_waste := -1;			
		END IF;
	END IF;	

END;

END model_pd_pkg;
/
