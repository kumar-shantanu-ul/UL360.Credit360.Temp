	create or replace package body supplier.gt_product_design_pkg
IS

PROCEDURE SetProdDesignAnswers (
    in_act_id                               IN security_pkg.T_ACT_ID,
    in_product_id                           IN all_product.product_id%TYPE,
    in_materials_note	        			IN gt_pdesign_answers.materials_note%TYPE,
    in_materials_separate        			IN gt_pdesign_answers.materials_separate%TYPE,
	in_palm_materials						IN T_PALM_OIL,
	in_endangered_species					IN T_ENDANGERED_SPECIES,
	in_endangered_pct						IN gt_pdesign_answers.endangered_pct%TYPE,
	in_ancillary_materials					IN gt_formulation_pkg.T_ANCILLARY_MATERIALS,
    in_electric_powered        				IN gt_pdesign_answers.electric_powered%TYPE,
    in_leaves_residue            			IN gt_pdesign_answers.leaves_residue%TYPE,
	in_gt_durability_type_id       			IN gt_pdesign_answers.gt_pda_durability_type_id%TYPE,
	in_data_quality_type_id           	    IN gt_product_answers.data_quality_type_id%TYPE
)
AS
	v_max_revision_id					product_revision.revision_id%TYPE;

	v_old_ancillary_list				VARCHAR(2048);
	v_old_palm_list						VARCHAR(2048);
	v_old_endangered_list				VARCHAR(2048);
	v_new_ancillary_list				VARCHAR(2048);
	v_new_palm_list						VARCHAR(2048);
	v_new_endangered_list				VARCHAR(2048);
	
BEGIN

    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
	--// TO DO - when the waste questionnaire has been moved for formulation do this
	/*FOR r IN (
		SELECT 
			   pr.product_id, pr.revision_id, 
		FROM gt_formulation_answers fa, product_revision pr
            WHERE pr.product_id=fa.product_id (+)
            AND pr.revision_id = fa.revision_id(+)
			AND pr.product_id = in_product_id
			AND pr.revision_id = v_max_revision_id
	) 
	LOOP
		-- actually only ever going to be single row as product id and revision id are PK
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_WHATS_IN_PROD, null, 'Number of ingredients', r.ingredient_count, in_numberOfIngredients);

		score_log_pkg.LogYesNoValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_PACK_IMPACT, null, 'Is the formulation a concentrate', r.concentrate, in_deliverConcentrate);
		
		score_log_pkg.LogYesNoValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_NON_SCORING, null, 'No hazardous chemicals from list present', r.no_haz_chem, in_noHazChem);

		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_SOURCE_BIOD, null, 'Grown on established mixed agricultural land %', r.bp_crops_pct, in_naturalCrops);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_SOURCE_BIOD, null, 'Intensively farmed materials %', r.bp_fish_pct, in_naturalFish);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_SOURCE_BIOD, null, 'Palm Oil and close derivatives %', r.bp_palm_pct, in_naturalPalm);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_SOURCE_BIOD, null, 'Processed materials derived from palm oil %', r.bp_palm_processed_pct, in_naturalPalmProcessed);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_SOURCE_BIOD, null, 'Wild Harvested %', r.bp_wild_pct, in_naturalWild);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_SOURCE_BIOD, null, 'Unknown Sources %', r.bp_unknown_pct, in_naturalUnknown);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_SOURCE_BIOD, null, 'Threatened or endangered species %', r.bp_threatened_pct, in_naturalEndangered);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_SOURCE_BIOD, null, 'Mineral derived %', r.bp_mineral_pct, in_naturalMineral);

		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_ACCRED_BIOD, null, 'Accredited source (priority) %', r.bs_accredited_priority_pct, in_accreditedPriority);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_ACCRED_BIOD, null, 'Accredited source (other) %', r.bs_accredited_other_pct, in_accreditedOther);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_ACCRED_BIOD, null, 'Known source %', r.bs_known_pct, in_knownSource);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_ACCRED_BIOD, null, 'Unknown source %', r.bs_unknown_pct, in_unknownSource);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_ACCRED_BIOD, null, 'No natural ingredients  %', r.bs_no_natural_pct, in_noNatural);

	END LOOP;*/

    BEGIN
		INSERT INTO gt_pdesign_answers (
		   product_id, revision_id, materials_separate, materials_note, endangered_pct, 
		   electric_powered, leaves_residue, gt_pda_durability_type_id, data_quality_type_id) 
		VALUES (in_product_id, v_max_revision_id, in_materials_separate, in_materials_note, in_endangered_pct, 
			in_electric_powered, in_leaves_residue, in_gt_durability_type_id, in_data_quality_type_id);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
			UPDATE gt_pdesign_answers 
			   SET 
					materials_note = in_materials_note,
					materials_separate = in_materials_separate,
					endangered_pct = in_endangered_pct,
					electric_powered = in_electric_powered,
					leaves_residue = in_leaves_residue,
					gt_pda_durability_type_id = in_gt_durability_type_id,
					data_quality_type_id = in_data_quality_type_id
             WHERE product_id = in_product_id
               AND revision_id = v_max_revision_id;
    END;
    
	SELECT NVL(csr.stragg(description), 'None selected') INTO v_old_ancillary_list FROM 
	(
		SELECT anc.description 
		  FROM (SELECT am.description, anc.product_id, anc.revision_id FROM gt_pda_anc_mat anc, gt_ancillary_material am WHERE am.gt_ancillary_material_id = anc.gt_ancillary_material_id) anc, product_revision pr
		WHERE pr.product_id = anc.product_id (+)
		  AND pr.revision_id = anc.revision_id(+)
		  AND pr.product_id = in_product_id
		  AND pr.revision_id = v_max_revision_id
		ORDER BY LOWER(anc.description)
	);
    
    DELETE FROM gt_pda_anc_mat WHERE product_id = in_product_id AND revision_id = v_max_revision_id;

	SELECT NVL(csr.stragg(description), 'None selected') INTO v_old_palm_list FROM 
	(
		SELECT pm.description 
		  FROM (SELECT plm.description, pm.product_id, pm.revision_id FROM gt_pda_palm_ind pm, gt_palm_ingred plm WHERE plm.gt_palm_ingred_id = pm.gt_palm_ingred_id) pm, product_revision pr
		WHERE pr.product_id = pm.product_id (+)
		  AND pr.revision_id = pm.revision_id(+)
		  AND pr.product_id = in_product_id
		  AND pr.revision_id = v_max_revision_id
		ORDER BY LOWER(pm.description)
	);
    
    DELETE FROM gt_pda_palm_ind WHERE product_id = in_product_id AND revision_id = v_max_revision_id;
    
	SELECT NVL(csr.stragg(description), 'None selected') INTO v_old_endangered_list FROM 
	(
		SELECT en.description 
		  FROM (SELECT en.description, el.product_id, el.revision_id FROM gt_pda_endangered_sp el, gt_endangered_species en WHERE en.gt_endangered_species_id = el.gt_endangered_species_id) en, product_revision pr
		WHERE pr.product_id = en.product_id (+)
		  AND pr.revision_id = en.revision_id(+)
		  AND pr.product_id = in_product_id
		  AND pr.revision_id = v_max_revision_id
		ORDER BY LOWER(en.description)
	);

    DELETE FROM gt_pda_endangered_sp WHERE product_id = in_product_id AND revision_id = v_max_revision_id;

	IF ((in_ancillary_materials.COUNT>0) AND (in_ancillary_materials(1) IS NOT NULL)) THEN
        FOR i IN in_ancillary_materials.FIRST .. in_ancillary_materials.LAST LOOP
            INSERT INTO gt_pda_anc_mat (gt_ancillary_material_id, product_id, revision_id) VALUES (in_ancillary_materials(i), in_product_id, v_max_revision_id);
        END LOOP;
    END IF;

    IF ((in_palm_materials.COUNT>0) AND (in_palm_materials(1) IS NOT NULL)) THEN
        FOR i IN in_palm_materials.FIRST .. in_palm_materials.LAST LOOP
            INSERT INTO gt_pda_palm_ind (gt_palm_ingred_id, product_id, revision_id) VALUES (in_palm_materials(i), in_product_id, v_max_revision_id);
        END LOOP;
    END IF;

    IF ((in_endangered_species.count>0) AND (in_endangered_species(1) IS NOT NULL)) THEN
        FOR i IN in_endangered_species.FIRST .. in_endangered_species.LAST LOOP
            INSERT INTO gt_pda_endangered_sp (gt_endangered_species_id, product_id, revision_id) VALUES (in_endangered_species(i), in_product_id, v_max_revision_id);
        END LOOP;
    END IF;

	SELECT NVL(csr.stragg(description), 'None selected') INTO v_new_ancillary_list FROM 
	(
		SELECT anc.description 
		  FROM (SELECT am.description, anc.product_id, anc.revision_id FROM gt_pda_anc_mat anc, gt_ancillary_material am WHERE am.gt_ancillary_material_id = anc.gt_ancillary_material_id) anc, product_revision pr
		WHERE pr.product_id = anc.product_id (+)
		  AND pr.revision_id = anc.revision_id(+)
		  AND pr.product_id = in_product_id
		  AND pr.revision_id = v_max_revision_id
		ORDER BY LOWER(anc.description)
	);
    
	SELECT NVL(csr.stragg(description), 'None selected') INTO v_new_palm_list FROM 
	(
		SELECT pm.description 
		  FROM (SELECT plm.description, pm.product_id, pm.revision_id FROM gt_pda_palm_ind pm, gt_palm_ingred plm WHERE plm.gt_palm_ingred_id = pm.gt_palm_ingred_id) pm, product_revision pr
		WHERE pr.product_id = pm.product_id (+)
		  AND pr.revision_id = pm.revision_id(+)
		  AND pr.product_id = in_product_id
		  AND pr.revision_id = v_max_revision_id
		ORDER BY LOWER(pm.description)
	);
    
	SELECT NVL(csr.stragg(description), 'None selected') INTO v_new_endangered_list FROM 
	(
		SELECT en.description 
		  FROM (SELECT en.description, el.product_id, el.revision_id FROM gt_pda_endangered_sp el, gt_endangered_species en WHERE en.gt_endangered_species_id = el.gt_endangered_species_id) en, product_revision pr
		WHERE pr.product_id = en.product_id (+)
		  AND pr.revision_id = en.revision_id(+)
		  AND pr.product_id = in_product_id
		  AND pr.revision_id = v_max_revision_id
		ORDER BY LOWER(en.description)
	);  	
	
	score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_ANCILLARY_REQ, null, 'Ancillary Materials', v_old_ancillary_list, v_new_ancillary_list);
	score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_NON_SCORING, null, 'Palm Oil Materials', v_old_palm_list, v_new_palm_list);
 	score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_NON_SCORING, null, 'Endangered Species', v_old_endangered_list, v_new_endangered_list); 
	
	model_pkg.CalcProductScores(in_act_id, in_product_id, v_max_revision_id);
	
END;

PROCEDURE GetProductDesignAnswers(
    in_act_id                    IN  security_pkg.T_ACT_ID,
    in_product_id                IN  all_product.product_id%TYPE,
 	in_revision_id				 IN  product_revision.revision_id%TYPE,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_gt_product_type_id		gt_product_type.gt_product_type_id%TYPE;
	v_gt_product_type			gt_product_type.description%TYPE;
	v_mains_powered				gt_product_type.mains_powered%TYPE;
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading product with id '||in_product_id);
    END IF;

	product_info_pkg.GetProductTypeFromTags(in_act_id, in_product_id, in_revision_id, v_gt_product_type_id, v_gt_product_type);
	SELECT mains_powered INTO v_mains_powered FROM gt_product_type WHERE gt_product_type_id = v_gt_product_type_id;
	
    OPEN out_cur FOR
        SELECT 	NVL(pda.revision_id, 1) revision_id, p.description product_name, p.product_id, p.product_code, v_gt_product_type product_type, v_mains_powered mains_powered,
				materials_separate, materials_note, electric_powered, endangered_pct, leaves_residue, gt_pda_durability_type_id, data_quality_type_id, 
				DECODE(pq.questionnaire_status_id, questionnaire_pkg.QUESTIONNAIRE_CLOSED, pq.last_saved_by, null) last_saved_by
		  FROM gt_pdesign_answers pda, product p,  product_questionnaire pq
         WHERE p.product_id = in_product_id 
		   AND p.product_id = pq.product_id
		   AND pq.questionnaire_id = model_pd_pkg.QUESTION_GT_PROD_DESIGN
		   AND p.product_id = pda.product_id (+)
           AND ((pda.revision_id IS NULL) OR (pda.revision_id = in_revision_id));
END;

PROCEDURE GetPDMaterialItems(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
   	in_revision_id				 IN product_revision.revision_id%TYPE,
    out_cur                     OUT security_pkg.T_OUTPUT_CUR
) 
AS
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading product with id '||in_product_id);
    END IF;

    OPEN out_cur FOR
       SELECT 	mi.gt_pda_material_item_id, mi.product_id, mi.revision_id, mi.gt_material_id, mi.pct_of_product, mi.pct_recycled, 
				mi.gt_pda_provenance_type_id, mi.gt_pda_accred_type_id, g.gt_material_group_id, mi.gt_manufac_type_id, mi.gt_water_stress_region_id, mi.accreditation_note
         FROM gt_pda_material_item mi, gt_material m, gt_material_group g
        WHERE mi.gt_material_id = m.gt_material_id
		  AND m.gt_material_group_id = g.gt_material_group_id
		  AND product_id = in_product_id
          AND revision_id = in_revision_id;
END;

PROCEDURE GetPDMatItemHazChems(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
   	in_revision_id				 IN product_revision.revision_id%TYPE,
    out_cur                     OUT security_pkg.T_OUTPUT_CUR
) 
AS
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading product with id '||in_product_id);
    END IF;

    OPEN out_cur FOR
		SELECT gt_pda_material_item_id, gt_pda_haz_chem_id 
		  FROM gt_pda_hc_item 
		 WHERE product_id = in_product_id
           AND revision_id = in_revision_id
		 ORDER BY gt_pda_material_item_id;
END;

PROCEDURE GetPDBatteries(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
    in_revision_id               IN product_revision.revision_id%TYPE,
    out_cur                     OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading product with id '||in_product_id);
    END IF;

    OPEN out_cur FOR
        SELECT pb.gt_pda_battery_id, pb.gt_battery_code_id, b.gt_battery_code, gt_battery_type_id, count, NVL(gt_battery_use_id, -1) gt_battery_use_id, use_desc,
			   	count || ' x ' || gt_battery_code power_desc 
          FROM gt_pda_battery pb, gt_battery b
		 WHERE pb.gt_battery_code_id = b.gt_battery_code_id
		   AND product_id = in_product_id 
		   AND revision_id = in_revision_id
         ORDER BY gt_battery_code DESC;
END;

PROCEDURE GetPDMainsPower(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
    in_revision_id               IN product_revision.revision_id%TYPE,
    out_cur                     OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading product with id '||in_product_id);
    END IF;

    OPEN out_cur FOR
		SELECT gt_pda_main_power_id, standby, wattage, wattage || 'W ' || DECODE(standby, 1, 'with standby', 'no standby') power_desc 
		  FROM gt_pda_main_power
		  WHERE product_id = in_product_id
		    AND revision_id = in_revision_id
		 ORDER BY gt_pda_main_power_id;
	
END;

------------ Procedures for adding material items

PROCEDURE DeleteAbsentMaterialItems(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN all_product.product_id%TYPE,
	in_material_item_ids		IN gt_product_design_pkg.T_MATERIAL_ITEM_IDS
)
AS
	v_current_ids				gt_product_design_pkg.T_MATERIAL_ITEM_IDS;
	v_max_revision_id			product_revision.revision_id%TYPE;
	v_idx					NUMBER;
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to product with id '||in_product_id);
	END IF;
	
	SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;

	-- Get current ids
	FOR r IN (
		SELECT gt_pda_material_item_id
			FROM gt_pda_material_item
		 WHERE product_id = in_product_id
		 AND revision_id = v_max_revision_id
	) LOOP
		v_current_ids(r.gt_pda_material_item_id) := r.gt_pda_material_item_id ;
	END LOOP;

	-- Remove any part ids present in the input array
	IF ((in_material_item_ids.count>0) AND (in_material_item_ids(1) IS NOT NULL)) THEN
		FOR i IN in_material_item_ids.FIRST .. in_material_item_ids.LAST
		LOOP
			IF v_current_ids.EXISTS(in_material_item_ids(i)) THEN
				v_current_ids.DELETE(in_material_item_ids(i));
			END IF;
		END LOOP;
	END IF;
	
	-- Delete any ids remaining	
	IF v_current_ids.COUNT > 0 THEN -- can't use FIRST ... LAST as sparse array 
		  v_idx := v_current_ids.FIRST;
		  WHILE (v_idx IS NOT NULL) 
		  LOOP		
			DeleteMaterialItem(in_act_id, in_product_id, v_current_ids(v_idx));
			v_idx := v_current_ids.NEXT(v_idx);
		END LOOP;
	END IF;
	
END;

PROCEDURE DeleteMaterialItem(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
	in_material_item_id			 IN gt_pda_material_item.gt_pda_material_item_id%TYPE
) 
AS
	v_max_revision_id			product_revision.revision_id%TYPE;
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
    
    
	DELETE FROM gt_pda_hc_item 
	 WHERE product_id = in_product_id
	   AND revision_id = v_max_revision_id
	   AND gt_pda_material_item_id = in_material_item_id;
	
	-- always on latest revision
    DELETE FROM gt_pda_material_item WHERE product_id = in_product_id AND gt_pda_material_item_id = in_material_item_id AND revision_id = v_max_revision_id;
END; 

PROCEDURE AddMaterialItem(
    in_act_id                       IN security_pkg.T_ACT_ID,
    in_product_id                   IN all_product.product_id%TYPE,
	in_gt_material_id				IN gt_pda_material_item.gt_material_id%TYPE,
	in_pct_of_product				IN gt_pda_material_item.pct_of_product%TYPE,
	in_pct_recycled					IN gt_pda_material_item.pct_recycled%TYPE,
	in_gt_pda_provenance_type_id	IN gt_pda_material_item.gt_pda_provenance_type_id%TYPE,
	in_gt_pda_accred_type_id		IN gt_pda_material_item.gt_pda_accred_type_id%TYPE,
	in_gt_manufac_type_id			IN gt_pda_material_item.gt_manufac_type_id%TYPE,
	in_accreditation_note			IN gt_pda_material_item.accreditation_note%TYPE,
	in_gt_water_stress_region_id		IN gt_pda_material_item.gt_water_stress_region_id%TYPE,
	in_mat_haz_chems				IN T_MAT_HAZ_CHEMS,
	out_gt_material_id				OUT gt_pda_material_item.gt_material_id%TYPE
) 
AS
	v_max_revision_id				product_revision.revision_id%TYPE;
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
	SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
	SELECT gt_pda_material_item_id_seq.nextval INTO out_gt_material_id FROM DUAL;
	
	INSERT INTO gt_pda_material_item(
		gt_pda_material_item_id,
		product_id,
		revision_id,
		gt_material_id,			
		pct_of_product,				
		pct_recycled,				
		gt_pda_provenance_type_id,	
		gt_pda_accred_type_id,
		gt_manufac_type_id,
		accreditation_note,
		gt_water_stress_region_id		
	) VALUES (
		out_gt_material_id,
		in_product_id,
		v_max_revision_id,
		in_gt_material_id,			
		in_pct_of_product,				
		in_pct_recycled,				
		in_gt_pda_provenance_type_id,	
		in_gt_pda_accred_type_id,
		in_gt_manufac_type_id,
		in_accreditation_note,
		in_gt_water_stress_region_id
	);
	
	IF ((in_mat_haz_chems.count>0) AND (in_mat_haz_chems(1) IS NOT NULL)) THEN
        FOR i IN in_mat_haz_chems.FIRST .. in_mat_haz_chems.LAST LOOP
            INSERT INTO gt_pda_hc_item (gt_pda_material_item_id, gt_pda_haz_chem_id, product_id, revision_id) 
				 VALUES (out_gt_material_id, in_mat_haz_chems(i), in_product_id, v_max_revision_id);
        END LOOP;
    END IF;

END;

PROCEDURE UpdateMaterialItem(
    in_act_id                       IN security_pkg.T_ACT_ID,
    in_product_id                   IN all_product.product_id%TYPE,
	in_gt_pda_material_item_id		IN gt_pda_material_item.gt_pda_material_item_id%TYPE,	
	in_gt_material_id				IN gt_pda_material_item.gt_material_id%TYPE,
	in_pct_of_product				IN gt_pda_material_item.pct_of_product%TYPE,
	in_pct_recycled					IN gt_pda_material_item.pct_recycled%TYPE,
	in_gt_pda_provenance_type_id	IN gt_pda_material_item.gt_pda_provenance_type_id%TYPE,
	in_gt_pda_accred_type_id		IN gt_pda_material_item.gt_pda_accred_type_id%TYPE,
	in_gt_manufac_type_id			IN gt_pda_material_item.gt_manufac_type_id%TYPE,
	in_accreditation_note			IN gt_pda_material_item.accreditation_note%TYPE,
	in_gt_water_stress_region_id		IN gt_pda_material_item.gt_water_stress_region_id%TYPE,
	in_mat_haz_chems				IN T_MAT_HAZ_CHEMS
) 
AS
	v_max_revision_id			product_revision.revision_id%TYPE;
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
	SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
	UPDATE gt_pda_material_item
	   SET 
		gt_material_id = in_gt_material_id,		
		pct_of_product = in_pct_of_product,				
		pct_recycled = in_pct_recycled,				
		gt_pda_provenance_type_id = in_gt_pda_provenance_type_id,	
		gt_pda_accred_type_id = in_gt_pda_accred_type_id,
		gt_manufac_type_id = in_gt_manufac_type_id,
		accreditation_note = in_accreditation_note, 
		gt_water_stress_region_id = in_gt_water_stress_region_id
	 WHERE product_id = in_product_id
	   AND revision_id = v_max_revision_id
	   AND gt_pda_material_item_id = in_gt_pda_material_item_id;
	   
	DELETE FROM gt_pda_hc_item 
	 WHERE product_id = in_product_id
	   AND revision_id = v_max_revision_id
	   AND gt_pda_material_item_id = in_gt_pda_material_item_id;
	   
	IF ((in_mat_haz_chems.count>0) AND (in_mat_haz_chems(1) IS NOT NULL)) THEN
        FOR i IN in_mat_haz_chems.FIRST .. in_mat_haz_chems.LAST LOOP
            INSERT INTO gt_pda_hc_item (gt_pda_material_item_id, gt_pda_haz_chem_id, product_id, revision_id) 
				 VALUES (in_gt_pda_material_item_id, in_mat_haz_chems(i), in_product_id, v_max_revision_id);
        END LOOP;
    END IF;
	
END;

------------ Procedures for adding Battery items

PROCEDURE DeleteAbsentBatteryItems(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
	in_battery_ids	     		 IN gt_product_design_pkg.T_BATTERY_ITEM_IDS
) 
AS
	v_max_revision_id			product_revision.revision_id%TYPE;
	v_current_ids				gt_product_design_pkg.T_BATTERY_ITEM_IDS;
	v_idx					NUMBER;
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
	-- Get current ids
	FOR r IN (
		SELECT gt_pda_battery_id
			FROM gt_pda_battery
		 WHERE product_id = in_product_id
		 AND revision_id = v_max_revision_id
	) LOOP
		v_current_ids(r.gt_pda_battery_id) := r.gt_pda_battery_id ;
	END LOOP;

	-- Remove any part ids present in the input array
	IF ((in_battery_ids.count>0) AND (in_battery_ids(1) IS NOT NULL)) THEN
		FOR i IN in_battery_ids.FIRST .. in_battery_ids.LAST
		LOOP
			IF v_current_ids.EXISTS(in_battery_ids(i)) THEN
				v_current_ids.DELETE(in_battery_ids(i));
			END IF;
		END LOOP;
	END IF;

	-- Delete any ids remaining	
	IF v_current_ids.COUNT > 0 THEN -- can't use FIRST ... LAST as sparse array 
		  v_idx := v_current_ids.FIRST;
		  WHILE (v_idx IS NOT NULL) 
		  LOOP		
			DeleteBatteryItem(in_act_id, in_product_id, v_current_ids(v_idx));
			v_idx := v_current_ids.NEXT(v_idx);
		END LOOP;
	END IF;
	
END;

PROCEDURE DeleteBatteryItem(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
	in_pda_battery_id			 IN gt_pda_battery.gt_pda_battery_id%TYPE
) 
AS
	v_max_revision_id			product_revision.revision_id%TYPE;
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
    
	-- always on latest revision
    DELETE FROM gt_pda_battery WHERE product_id = in_product_id AND gt_pda_battery_id = in_pda_battery_id AND revision_id = v_max_revision_id;
END; 

PROCEDURE AddBatteryItem(
    in_act_id                       IN security_pkg.T_ACT_ID,
    in_product_id                   IN all_product.product_id%TYPE,
	in_gt_battery_type_id			IN gt_pda_battery.gt_battery_type_id%TYPE,
	in_gt_battery_code_id			IN gt_pda_battery.gt_battery_code_id%TYPE,
	in_count						IN gt_pda_battery.count%TYPE,
	in_gt_battery_use_id			IN gt_battery_use.gt_battery_use_id%TYPE,
	in_use_desc						IN gt_pda_battery.use_desc%TYPE,
	out_gt_pda_battery_id			OUT gt_pda_battery.gt_pda_battery_id%TYPE
) 
AS
	v_max_revision_id			product_revision.revision_id%TYPE;
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
	SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
	SELECT gt_pda_battery_id_seq.nextval INTO out_gt_pda_battery_id FROM DUAL;
	
	INSERT INTO gt_pda_battery(
		product_id,
		revision_id,
		gt_pda_battery_id,
		gt_battery_type_id,
		gt_battery_code_id,
		count,
		gt_battery_use_id,
		use_desc
	) VALUES (
		in_product_id,
		v_max_revision_id,
		out_gt_pda_battery_id,
		in_gt_battery_type_id,
		in_gt_battery_code_id,
		in_count,
		in_gt_battery_use_id,
		in_use_desc
	);
END;

PROCEDURE UpdateBatteryItem(
    in_act_id                       IN security_pkg.T_ACT_ID,
    in_product_id                   IN all_product.product_id%TYPE,
	in_gt_battery_type_id			IN gt_pda_battery.gt_battery_type_id%TYPE,
	in_gt_pda_battery_id			IN gt_pda_battery.gt_pda_battery_id%TYPE,
	in_gt_battery_code_id			IN gt_pda_battery.gt_battery_code_id%TYPE,
	in_count						IN gt_pda_battery.count%TYPE,
	in_gt_battery_use_id			IN gt_battery_use.gt_battery_use_id%TYPE,
	in_use_desc						IN gt_pda_battery.use_desc%TYPE
) 
AS
	v_max_revision_id			product_revision.revision_id%TYPE;
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
	SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
	UPDATE gt_pda_battery
	  SET
		gt_battery_type_id = in_gt_battery_type_id,
		gt_battery_code_id = in_gt_battery_code_id,
		count = in_count,
		gt_battery_use_id = in_gt_battery_use_id,
		use_desc = in_use_desc
	WHERE product_id = in_product_id
	  AND revision_id = v_max_revision_id
	  AND gt_pda_battery_id = in_gt_pda_battery_id;
	
END;

------------ Procedures for adding Mains power items

PROCEDURE DeleteAbsentMPItems(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
	in_mains_power_ids	     		 IN gt_product_design_pkg.T_MAINS_POWER_ITEM_IDS
) 
AS
	v_max_revision_id			product_revision.revision_id%TYPE;
	v_current_ids				gt_product_design_pkg.T_BATTERY_ITEM_IDS;
	v_idx					NUMBER;
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
	-- Get current ids
	FOR r IN (
		SELECT gt_pda_main_power_id
			FROM gt_pda_main_power
		 WHERE product_id = in_product_id
		 AND revision_id = v_max_revision_id
	) LOOP
		v_current_ids(r.gt_pda_main_power_id) := r.gt_pda_main_power_id ;
	END LOOP;

	-- Remove any part ids present in the input array
	IF ((in_mains_power_ids.count>0) AND (in_mains_power_ids(1) IS NOT NULL)) THEN
		FOR i IN in_mains_power_ids.FIRST .. in_mains_power_ids.LAST
		LOOP
			IF v_current_ids.EXISTS(in_mains_power_ids(i)) THEN
				v_current_ids.DELETE(in_mains_power_ids(i));
			END IF;
		END LOOP;
	END IF;

	-- Delete any ids remaining	
	IF v_current_ids.COUNT > 0 THEN -- can't use FIRST ... LAST as sparse array 
		  v_idx := v_current_ids.FIRST;
		  WHILE (v_idx IS NOT NULL) 
		  LOOP		
			DeleteMPItem(in_act_id, in_product_id, v_current_ids(v_idx));
			v_idx := v_current_ids.NEXT(v_idx);
		END LOOP;
	END IF;

END;

PROCEDURE DeleteMPItem(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
	in_pda_main_power_id		 IN gt_pda_main_power.gt_pda_main_power_id%TYPE
) 
AS
	v_max_revision_id			product_revision.revision_id%TYPE;
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
    
	-- always on latest revision
    DELETE FROM gt_pda_main_power WHERE product_id = in_product_id AND gt_pda_main_power_id = in_pda_main_power_id AND revision_id = v_max_revision_id;
END; 

PROCEDURE AddMPItem(
    in_act_id                       IN security_pkg.T_ACT_ID,
    in_product_id                   IN all_product.product_id%TYPE,
	in_standby						IN gt_pda_main_power.standby%TYPE,
	in_wattage						IN gt_pda_main_power.wattage%TYPE,
	out_gt_pda_main_power_id		OUT gt_pda_main_power.gt_pda_main_power_id%TYPE
) 
AS
	v_max_revision_id			product_revision.revision_id%TYPE;
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
	SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
	SELECT gt_pda_main_power_id_seq.nextval INTO out_gt_pda_main_power_id FROM DUAL;
	
	INSERT INTO gt_pda_main_power(
		product_id,
		revision_id,
		gt_pda_main_power_id,
		standby,
		wattage
	) VALUES (
		in_product_id,
		v_max_revision_id,
		out_gt_pda_main_power_id,
		in_standby,
		in_wattage
	);
END;

PROCEDURE UpdateMPItem(
    in_act_id                       IN security_pkg.T_ACT_ID,
    in_product_id                   IN all_product.product_id%TYPE,
	in_gt_pda_main_power_id			IN gt_pda_main_power.gt_pda_main_power_id%TYPE,
	in_standby						IN gt_pda_main_power.standby%TYPE,
	in_wattage						IN gt_pda_main_power.wattage%TYPE
) 
AS
	v_max_revision_id			product_revision.revision_id%TYPE;
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
	SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
	UPDATE gt_pda_main_power
	  SET
		gt_pda_main_power_id = in_gt_pda_main_power_id,
		standby = in_standby,
		wattage = in_wattage
	WHERE product_id = in_product_id
	  AND revision_id = v_max_revision_id
	  AND gt_pda_main_power_id = in_gt_pda_main_power_id;
	
END;

-----------------------


PROCEDURE GetPDPalmOils(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
 	in_revision_id				 IN product_revision.revision_id%TYPE,
    out_cur                     OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT  p.gt_palm_ingred_id, p.description, p.palm_confirmed,
                CASE WHEN product_id IS NULL THEN 0 ELSE 1 END included_boo
          FROM gt_palm_ingred p, gt_pda_palm_ind pi
         WHERE p.gt_palm_ingred_id = pi.gt_palm_ingred_id (+)
           AND (pi.product_id = in_product_id OR pi.product_id IS NULL)
           AND ((pi.revision_id = in_revision_id) OR (pi.revision_id IS NULL))
         ORDER BY p.gt_palm_ingred_id;
END;


PROCEDURE GetPDAncillary(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
 	in_revision_id				 IN product_revision.revision_id%TYPE,
    out_cur                     OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT  m.gt_ancillary_material_id, m.description, m.pos,
                CASE WHEN am.product_id IS NULL THEN 0 ELSE 1 END AS included_boo
          FROM gt_ancillary_material m, (SELECT * FROM gt_pda_anc_mat am WHERE product_id = in_product_id AND revision_id = in_revision_id) am, gt_anc_mat_prod_class_map pcm
          WHERE m.gt_ancillary_material_id = am.gt_ancillary_material_id (+)
		  AND pcm.gt_ancillary_material_id = m.gt_ancillary_material_id
		  AND pcm.gt_product_class_id = 2
          ORDER BY m.pos ASC;
END;

PROCEDURE GetPDEndangered(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
    in_revision_id               IN product_revision.revision_id%TYPE,
    out_cur                     OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
          SELECT    es.gt_endangered_species_id, es.description || DECODE(es.details, NULL, NULL, ' (' || es.details || ')') || ' - Risk: ' || es.risk_level as description, 
                    REPLACE(es.notes, '#', '') as notes , 
                    CASE WHEN pes.product_id IS NULL THEN 0 ELSE 1 END AS included_boo
           FROM gt_endangered_species es, gt_endangered_prod_class_map ecp, (SELECT * FROM gt_pda_endangered_sp WHERE product_id = in_product_id AND revision_id = in_revision_id) pes
          WHERE es.gt_endangered_species_id = ecp.gt_endangered_species_id
            AND es.gt_endangered_species_id = pes.gt_endangered_species_id (+)
            AND ecp.gt_product_class_id = model_pd_pkg.PROD_CLASS_MANUFACTURED
          ORDER BY LOWER(es.description);
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
	v_gt_material_id				gt_pda_material_item.gt_material_id%TYPE;
BEGIN

	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_to_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

	-- we always want to overwrite so lets just get rid of the row

	DELETE FROM gt_pda_main_power WHERE product_id = in_to_product_id AND revision_id = in_to_rev;
	DELETE FROM gt_pda_battery WHERE product_id = in_to_product_id AND revision_id = in_to_rev;
	DELETE FROM gt_pda_endangered_sp WHERE product_id = in_to_product_id AND revision_id = in_to_rev;
	DELETE FROM gt_pda_hc_item WHERE product_id = in_to_product_id AND revision_id = in_to_rev;
	DELETE FROM gt_pda_material_item WHERE product_id = in_to_product_id AND revision_id = in_to_rev;
	DELETE FROM gt_pda_palm_ind WHERE product_id = in_to_product_id AND revision_id = in_to_rev;
	DELETE FROM gt_pda_anc_mat WHERE product_id = in_to_product_id AND revision_id = in_to_rev;

	DELETE FROM gt_pdesign_answers WHERE product_id = in_to_product_id AND revision_id = in_to_rev;


	INSERT INTO gt_pdesign_answers (
		product_id, revision_id, materials_note, materials_separate, endangered_pct,
		electric_powered, leaves_residue, gt_pda_durability_type_id, data_quality_type_id)
	SELECT
	   in_to_product_id, in_to_rev, materials_note, materials_separate, endangered_pct,
		electric_powered, leaves_residue, gt_pda_durability_type_id, data_quality_type_id
	FROM gt_pdesign_answers
		WHERE product_id = in_from_product_id
		AND revision_id =  in_from_rev;

	INSERT INTO gt_pda_battery (
   		gt_pda_battery_id, count, gt_battery_use_id, use_desc, gt_battery_type_id, gt_battery_code_id, product_id, revision_id)
	SELECT
		gt_pda_battery_id, count, gt_battery_use_id, use_desc, gt_battery_type_id, gt_battery_code_id, in_to_product_id, in_to_rev
	FROM gt_pda_battery
		WHERE product_id  = in_from_product_id
		  AND revision_id = in_from_rev;

	INSERT INTO gt_pda_endangered_sp (
	  	gt_endangered_species_id, product_id, revision_id)
	SELECT
		gt_endangered_species_id, in_to_product_id, in_to_rev
	FROM gt_pda_endangered_sp
		WHERE product_id = in_from_product_id
		AND revision_id =  in_from_rev;

	INSERT INTO gt_pda_palm_ind (
	   gt_palm_ingred_id, product_id, revision_id)
	SELECT
		gt_palm_ingred_id, in_to_product_id, in_to_rev
	FROM gt_pda_palm_ind
		WHERE product_id = in_from_product_id
		AND revision_id =  in_from_rev;

	INSERT INTO gt_pda_anc_mat (
	   gt_ancillary_material_id, product_id, revision_id)
	SELECT
		gt_ancillary_material_id, in_to_product_id, in_to_rev
	FROM gt_pda_anc_mat
		WHERE product_id = in_from_product_id
		AND revision_id =  in_from_rev;


	FOR r IN (
		SELECT * FROM gt_pda_material_item
		 WHERE product_id = in_from_product_id
		   AND revision_id =  in_from_rev
	)
	LOOP

		SELECT gt_pda_material_item_id_seq.nextval INTO v_gt_material_id FROM DUAL;

		INSERT INTO gt_pda_material_item (gt_pda_material_item_id, gt_material_id, pct_of_product, pct_recycled,
										  gt_pda_provenance_type_id, gt_pda_accred_type_id, gt_manufac_type_id, gt_water_stress_region_id,
										 accreditation_note, product_id, revision_id)
			 VALUES(v_gt_material_id,r.gt_material_id,r.pct_of_product,r.pct_recycled,
					r.gt_pda_provenance_type_id, r.gt_pda_accred_type_id, r.gt_manufac_type_id, r.gt_water_stress_region_id,
					r.accreditation_note, in_to_product_id, in_to_rev);


		INSERT INTO gt_pda_hc_item (
			gt_pda_material_item_id, gt_pda_haz_chem_id, product_id, revision_id)
		SELECT
			v_gt_material_id, gt_pda_haz_chem_id, in_to_product_id, in_to_rev
		   FROM gt_pda_hc_item
		  WHERE product_id = in_from_product_id
			AND revision_id =  in_from_rev
			AND gt_pda_material_item_id = r.gt_pda_material_item_id;

	END LOOP;
			
END;

-- Lists
PROCEDURE GetDurabilityTypes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT gt_pda_durability_type_id, description
          FROM gt_pda_durability_type;
END;

PROCEDURE GetMaterialGroups(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT mg.gt_material_group_id, mg.description
          FROM gt_material_group mg;
END;

PROCEDURE GetMaterialTypes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- mapping is one to one group / type
    OPEN out_cur FOR
        SELECT m.gt_material_id, mg.gt_material_group_id, m.description, mg.description group_description, natural
          FROM gt_material m, gt_material_group mg
         WHERE m.gt_material_group_id = mg.gt_material_group_id
		 ORDER BY mg.gt_material_group_id, LOWER(description);
END;

PROCEDURE GetMatHazChemMappings(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- mapping is many to many chem / material type
    OPEN out_cur FOR
        SELECT m.gt_material_id, m.description material_description, h.description chem_description, hm.gt_pda_haz_chem_id
          FROM gt_pda_haz_chem h, gt_pda_hc_mat_map hm, gt_material m
         WHERE m.gt_material_id = hm.gt_material_id
           AND hm.gt_pda_haz_chem_id = h.gt_pda_haz_chem_id
         ORDER BY m.gt_material_id, LOWER(h.description);

END;

PROCEDURE GetMatProvMappings(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- mapping is many to many chem / material type
    OPEN out_cur FOR
        SELECT m.gt_material_id, m.description material_description, p.description provenance_description, p.gt_pda_provenance_type_id
          FROM gt_pda_provenance_type p, GT_PDA_MAT_PROV_MAPPING mpm, gt_material m
         WHERE m.gt_material_id =  mpm.gt_material_id
           AND  mpm.gt_pda_provenance_type_id = p.gt_pda_provenance_type_id
         ORDER BY m.gt_material_id, LOWER(p.description);

END;

PROCEDURE GetProvAccredMappings(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- mapping is many to many chem / material type
    OPEN out_cur FOR
		SELECT p.gt_pda_provenance_type_id, p.description provenance_description, a.gt_pda_accred_type_id, a.description accred_description
		  FROM gt_pda_prov_acc_mapping pam, gt_pda_provenance_type p, gt_pda_accred_type a
		 WHERE pam.gt_pda_accred_type_id = a.gt_pda_accred_type_id
		   AND pam.gt_pda_provenance_type_id = p.gt_pda_provenance_type_id
		 ORDER BY LOWER(p.description), LOWER(a.description);

END;

PROCEDURE GetMatTypeManufacMappings(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- mapping is many to many manufacturing / material type
    OPEN out_cur FOR
        SELECT m.gt_material_id, m.description material_description, mf.gt_manufac_type_id, mf.description manufac_description
          FROM gt_manufac_type mf, gt_mat_man_mappiing mm, gt_material m
         WHERE m.gt_material_id = mm.gt_material_id
           AND mm.gt_manufac_type_id = mf.gt_manufac_type_id
         ORDER BY m.gt_material_id, LOWER(mf.description);
END;

PROCEDURE GetManufacturingTypes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT mf.gt_manufac_type_id, mf.description
          FROM gt_manufac_type mf;
END;

PROCEDURE GetAccreditationTypes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT a.gt_pda_accred_type_id, a.description, a.needs_note
          FROM gt_pda_accred_type a;
END;

PROCEDURE GetProvenanceTypes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT p.gt_pda_provenance_type_id, p.description
          FROM gt_pda_provenance_type p;
END;

PROCEDURE GetWSRegions(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT  gt_water_stress_region_id, description
		  FROM  gt_water_stress_region 
		  ORDER BY pos;
END;

PROCEDURE GetBatteryCodes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT b.gt_battery_code_id, b.gt_battery_code, b.gt_battery_chem_id, bc.description chemistry, average_weight_g, voltage, recharchable, 
			-- summary - this is to avoid doing multiple lookups to get a summary of the battery 
			gt_battery_code||' '||bc.description||' '||voltage||'V '||'('||average_weight_g||'g) ' summary -- ||DECODE(recharchable, 1, 'Rechargable', 0, 'Not rechargable') summary
          FROM gt_battery b, gt_battery_chem bc
		 WHERE b.gt_battery_chem_id = bc.gt_battery_chem_id;
END;

PROCEDURE GetBatteryTypes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT  bt.gt_battery_type_id, bt.description gt_battery_type_desc, rechargable
		  FROM  gt_battery_type bt
		  ORDER BY gt_battery_type_id;
END;

PROCEDURE GetBatteryUseTypes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT  bu.gt_battery_use_id, bu.description gt_battery_use_desc
		  FROM  gt_battery_use bu;
END;

PROCEDURE GetBatteryTypeBatteryMappings(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
    SELECT  bt.gt_battery_type_id, bt.description gt_battery_type_desc, b.gt_battery_code_id, 
        gt_battery_code||' '||bc.description||' '||voltage||'V '||'('||average_weight_g||'g) '  summary -- ||DECODE(recharchable, 1, 'Rechargable', 0, 'Not rechargable') summary
	  FROM gt_battery_type bt, gt_battery b, gt_battery_chem bc, gt_battery_battery_type bbt
	 WHERE bt.gt_battery_type_id = bbt.gt_battery_type_id
       AND bbt.gt_battery_code_id = b.gt_battery_code_id	 
	   AND b.gt_battery_chem_id = bc.gt_battery_chem_id
	 ORDER BY bt.gt_battery_type_id, LOWER(summary);
END;



END gt_product_design_pkg;
/
