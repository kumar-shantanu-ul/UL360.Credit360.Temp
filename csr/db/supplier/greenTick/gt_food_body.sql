create or replace package body supplier.gt_food_pkg
IS

PROCEDURE SetFoodAnswers (
    in_act_id                               IN security_pkg.T_ACT_ID,
    in_product_id                           IN all_product.product_id%TYPE,
	in_pct_added_water						IN gt_food_answers.pct_added_water%TYPE,
	in_pct_high_risk						IN gt_food_answers.pct_high_risk%TYPE,
	in_gt_fd_portion_type_id				IN gt_food_answers.gt_fd_portion_type_id%TYPE,
	in_ancillary_materials					IN gt_formulation_pkg.T_ANCILLARY_MATERIALS,
	in_social_amp_questions					IN gt_food_pkg.T_SOCIAL_AMP_QUESTIONS,
	in_endangered_species					IN T_ENDANGERED_SPECIES,
	in_palm_materials						IN T_PALM_OIL,
	in_data_quality_type_id           	    IN gt_product_answers.data_quality_type_id%TYPE,
	in_gt_water_stress_region_id			IN gt_food_answers.gt_water_stress_region_id%TYPE
)
AS
	v_max_revision_id					product_revision.revision_id%TYPE;
	v_old_ancillary_list				VARCHAR(2048);
	v_new_ancillary_list				VARCHAR(2048);
	v_old_endangered_list				VARCHAR(2048);
	v_new_endangered_list				VARCHAR(2048);
	v_old_palm_list						VARCHAR(2048);
	v_new_palm_list						VARCHAR(2048);
BEGIN

    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;

    BEGIN
		INSERT INTO gt_food_answers (
		   product_id, revision_id, pct_added_water, pct_high_risk, gt_fd_portion_type_id, data_quality_type_id, gt_water_stress_region_id) 
		VALUES (in_product_id, v_max_revision_id, in_pct_added_water, in_pct_high_risk, in_gt_fd_portion_type_id, in_data_quality_type_id, in_gt_water_stress_region_id);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
			UPDATE gt_food_answers 
			   SET 
					pct_added_water = in_pct_added_water,
					pct_high_risk = in_pct_high_risk,
					gt_fd_portion_type_id = in_gt_fd_portion_type_id,
					data_quality_type_id = in_data_quality_type_id,
					gt_water_stress_region_id = in_gt_water_stress_region_id
             WHERE product_id = in_product_id
               AND revision_id = v_max_revision_id;
    END;
	
	SELECT NVL(csr.stragg(description), 'None selected') INTO v_old_palm_list FROM 
	(
		SELECT pm.description 
		  FROM (SELECT plm.description, pm.product_id, pm.revision_id FROM gt_fd_palm_ind pm, gt_palm_ingred plm WHERE plm.gt_palm_ingred_id = pm.gt_palm_ingred_id) pm, product_revision pr
		WHERE pr.product_id = pm.product_id (+)
		  AND pr.revision_id = pm.revision_id(+)
		  AND pr.product_id = in_product_id
		  AND pr.revision_id = v_max_revision_id
		ORDER BY LOWER(pm.description)
	);
    
    DELETE FROM gt_fd_palm_ind WHERE product_id = in_product_id AND revision_id = v_max_revision_id;
    
	IF ((in_palm_materials.COUNT>0) AND (in_palm_materials(1) IS NOT NULL)) THEN
        FOR i IN in_palm_materials.FIRST .. in_palm_materials.LAST LOOP
            INSERT INTO gt_fd_palm_ind (gt_palm_ingred_id, product_id, revision_id) VALUES (in_palm_materials(i), in_product_id, v_max_revision_id);
        END LOOP;
    END IF;

	SELECT NVL(csr.stragg(description), 'None selected') INTO v_new_palm_list FROM 
	(
		SELECT pm.description 
		  FROM (SELECT plm.description, pm.product_id, pm.revision_id FROM gt_fd_palm_ind pm, gt_palm_ingred plm WHERE plm.gt_palm_ingred_id = pm.gt_palm_ingred_id) pm, product_revision pr
		WHERE pr.product_id = pm.product_id (+)
		  AND pr.revision_id = pm.revision_id(+)
		  AND pr.product_id = in_product_id
		  AND pr.revision_id = v_max_revision_id
		ORDER BY LOWER(pm.description)
	);
	
	SELECT NVL(csr.stragg(description), 'None selected') INTO v_old_ancillary_list FROM 
	(
		SELECT anc.description 
		  FROM (SELECT am.description, anc.product_id, anc.revision_id FROM gt_food_anc_mat anc, gt_ancillary_material am WHERE am.gt_ancillary_material_id = anc.gt_ancillary_material_id) anc, product_revision pr
		WHERE pr.product_id = anc.product_id (+)
		  AND pr.revision_id = anc.revision_id(+)
		  AND pr.product_id = in_product_id
		  AND pr.revision_id = v_max_revision_id
		ORDER BY LOWER(anc.description)
	);
    
    DELETE FROM gt_food_anc_mat WHERE product_id = in_product_id AND revision_id = v_max_revision_id;
	
	IF ((in_ancillary_materials.COUNT>0) AND (in_ancillary_materials(1) IS NOT NULL)) THEN
        FOR i IN in_ancillary_materials.FIRST .. in_ancillary_materials.LAST LOOP
            INSERT INTO gt_food_anc_mat (gt_ancillary_material_id, product_id, revision_id) VALUES (in_ancillary_materials(i), in_product_id, v_max_revision_id);
        END LOOP;
    END IF;
	
	SELECT NVL(csr.stragg(description), 'None selected') INTO v_new_ancillary_list FROM 
	(
		SELECT anc.description 
		  FROM (SELECT am.description, anc.product_id, anc.revision_id FROM gt_food_anc_mat anc, gt_ancillary_material am WHERE am.gt_ancillary_material_id = anc.gt_ancillary_material_id) anc, product_revision pr
		WHERE pr.product_id = anc.product_id (+)
		  AND pr.revision_id = anc.revision_id(+)
		  AND pr.product_id = in_product_id
		  AND pr.revision_id = v_max_revision_id
		ORDER BY LOWER(anc.description)
	);
	
	-- start of the social amp questions processing...
	-- TODO: audit log for entries for food - and also for product design
    DELETE FROM gt_food_sa_q WHERE product_id = in_product_id AND revision_id = v_max_revision_id;
	
	IF ((in_social_amp_questions.COUNT>0) AND (in_social_amp_questions(1) IS NOT NULL)) THEN
        FOR i IN in_social_amp_questions.FIRST .. in_social_amp_questions.LAST LOOP
            INSERT INTO gt_food_sa_q (gt_sa_question_id, product_id, revision_id) VALUES (in_social_amp_questions(i), in_product_id, v_max_revision_id);
        END LOOP;
    END IF;
	
	--- end of the social amp questions processing...
	
	SELECT NVL(csr.stragg(description), 'None selected') INTO v_old_endangered_list FROM 
	(
		SELECT en.description 
		  FROM (SELECT en.description, el.product_id, el.revision_id FROM gt_fd_endangered_sp el, gt_endangered_species en WHERE en.gt_endangered_species_id = el.gt_endangered_species_id) en, product_revision pr
		WHERE pr.product_id = en.product_id (+)
		  AND pr.revision_id = en.revision_id(+)
		  AND pr.product_id = in_product_id
		  AND pr.revision_id = v_max_revision_id
		ORDER BY LOWER(en.description)
	);
	
	DELETE FROM gt_fd_endangered_sp WHERE product_id = in_product_id AND revision_id = v_max_revision_id;

		
	IF ((in_endangered_species.count>0) AND (in_endangered_species(1) IS NOT NULL)) THEN
        FOR i IN in_endangered_species.FIRST .. in_endangered_species.LAST LOOP
            INSERT INTO gt_fd_endangered_sp (gt_endangered_species_id, product_id, revision_id) VALUES (in_endangered_species(i), in_product_id, v_max_revision_id);
        END LOOP;
    END IF;
	
	SELECT NVL(csr.stragg(description), 'None selected') INTO v_new_endangered_list FROM 
	(
		SELECT en.description 
		  FROM (SELECT en.description, el.product_id, el.revision_id FROM gt_fd_endangered_sp el, gt_endangered_species en WHERE en.gt_endangered_species_id = el.gt_endangered_species_id) en, product_revision pr
		WHERE pr.product_id = en.product_id (+)
		  AND pr.revision_id = en.revision_id(+)
		  AND pr.product_id = in_product_id
		  AND pr.revision_id = v_max_revision_id
		ORDER BY LOWER(en.description)
	);  	
    --score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_ANCILLARY_REQ, null, 'Ancillary Materials', v_old_ancillary_list, v_new_ancillary_list);
	--score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_NON_SCORING, null, 'Palm Oil Materials', v_old_palm_list, v_new_palm_list);
 	--score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_NON_SCORING, null, 'Endangered Species', v_old_endangered_list, v_new_endangered_list); 
	--
	--model_pkg.CalcProductScores(in_act_id, in_product_id, v_max_revision_id);
	
END;

PROCEDURE GetFoodAnswers(
    in_act_id                    IN  security_pkg.T_ACT_ID,
    in_product_id                IN  all_product.product_id%TYPE,
 	in_revision_id				 IN  product_revision.revision_id%TYPE,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_gt_product_type_id		gt_product_type.gt_product_type_id%TYPE;
	v_gt_product_type			gt_product_type.description%TYPE;
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading product with id '||in_product_id);
    END IF;

	product_info_pkg.GetProductTypeFromTags(in_act_id, in_product_id, in_revision_id, v_gt_product_type_id, v_gt_product_type);
	
    OPEN out_cur FOR
        SELECT 	NVL(fa.revision_id, 1) revision_id, p.description product_name, p.product_id, p.product_code, pct_added_water, pct_high_risk, 
				gt_fd_portion_type_id, data_quality_type_id, gt_water_stress_region_id, 
				DECODE(pq.questionnaire_status_id, questionnaire_pkg.QUESTIONNAIRE_CLOSED, pq.last_saved_by, null) last_saved_by
		  FROM gt_food_answers fa, product p, product_questionnaire pq
         WHERE p.product_id = in_product_id 
		   AND p.product_id = pq.product_id
		   AND pq.questionnaire_id = model_pd_pkg.QUESTION_GT_FOOD
		   AND p.product_id = fa.product_id (+)
           AND ((fa.revision_id IS NULL) OR (fa.revision_id = in_revision_id));
END;

------------------ Procedures for ingredients

PROCEDURE GetFdIngredients(
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
       SELECT 	fi.gt_fd_ingredient_id, fi.product_id, fi.revision_id, fi.gt_fd_ingred_type_id, fi.pct_of_product, fi.seasonal, 
				fi.gt_fd_ingred_prov_type_id, fi.gt_ingred_accred_type_id, g.gt_fd_ingred_group_id, fi.gt_water_stress_region_id, fi.accred_scheme_name, fi.contains_gm
         FROM gt_fd_ingredient fi, gt_fd_ingred_type it, gt_fd_ingred_group g
        WHERE fi.gt_fd_ingred_type_id = it.gt_fd_ingred_type_id
		  AND it.gt_fd_ingred_group_id = g.gt_fd_ingred_group_id
		  AND product_id = in_product_id
          AND revision_id = in_revision_id;
END;

PROCEDURE DeleteAbsentIngredients(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN all_product.product_id%TYPE,
	in_ingredient_ids			IN gt_food_pkg.T_INGREDIENT_IDS
)
AS
	v_current_ids				gt_food_pkg.T_INGREDIENT_IDS;
	v_max_revision_id			product_revision.revision_id%TYPE;
	v_idx					NUMBER;
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to product with id '||in_product_id);
	END IF;
	
	SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;

	-- Get current ids
	FOR r IN (
		SELECT gt_fd_ingredient_id
			FROM gt_fd_ingredient
		 WHERE product_id = in_product_id
		 AND revision_id = v_max_revision_id
	) LOOP
		v_current_ids(r.gt_fd_ingredient_id) := r.gt_fd_ingredient_id ;
	END LOOP;

	-- Remove any part ids present in the input array
	IF ((in_ingredient_ids.count>0) AND (in_ingredient_ids(1) IS NOT NULL)) THEN
		FOR i IN in_ingredient_ids.FIRST .. in_ingredient_ids.LAST
		LOOP
			IF v_current_ids.EXISTS(in_ingredient_ids(i)) THEN
				v_current_ids.DELETE(in_ingredient_ids(i));
			END IF;
		END LOOP;
	END IF;
	
	-- Delete any ids remaining	
	IF v_current_ids.COUNT > 0 THEN -- can't use FIRST ... LAST as sparse array 
		  v_idx := v_current_ids.FIRST;
		  WHILE (v_idx IS NOT NULL) 
		  LOOP		
			DeleteIngredient(in_act_id, in_product_id, v_current_ids(v_idx));
			v_idx := v_current_ids.NEXT(v_idx);
		END LOOP;
	END IF;
	
END;

PROCEDURE DeleteIngredient(
    in_act_id						IN security_pkg.T_ACT_ID,
    in_product_id                	IN all_product.product_id%TYPE,
	in_gt_fd_ingredient_id			IN gt_fd_ingredient.gt_fd_ingredient_id%TYPE
)
AS
	v_max_revision_id			product_revision.revision_id%TYPE;
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	-- always on latest revision
    DELETE FROM gt_fd_ingredient WHERE product_id = in_product_id AND gt_fd_ingredient_id = in_gt_fd_ingredient_id AND revision_id = v_max_revision_id;
END; 

PROCEDURE AddIngredient(
    in_act_id                       IN security_pkg.T_ACT_ID,
    in_product_id                   IN all_product.product_id%TYPE,
	in_gt_fd_ingred_type_id			IN gt_fd_ingredient.gt_fd_ingred_type_id%TYPE,
	in_pct_of_product				IN gt_fd_ingredient.pct_of_product%TYPE,
	in_seasonal						IN gt_fd_ingredient.seasonal%TYPE,
	in_gt_fd_ingred_prov_type_id	IN gt_fd_ingredient.gt_fd_ingred_prov_type_id%TYPE,
	in_gt_ingred_accred_type_id		IN gt_fd_ingredient.gt_ingred_accred_type_id%TYPE,
	in_accred_scheme_name			IN gt_fd_ingredient.accred_scheme_name%TYPE,
	in_gt_water_stress_region_id	IN gt_fd_ingredient.gt_water_stress_region_id%TYPE,
	in_contains_gm					IN gt_fd_ingredient.contains_gm%TYPE,
	out_gt_fd_ingredient_id				OUT gt_fd_ingredient.gt_fd_ingredient_id%TYPE
) 
AS
	v_max_revision_id				product_revision.revision_id%TYPE;
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
	SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
	SELECT gt_fd_ingredient_id_seq.nextval INTO out_gt_fd_ingredient_id FROM DUAL;
	
	INSERT INTO gt_fd_ingredient(
		gt_fd_ingredient_id,
		product_id,
		revision_id,
		gt_fd_ingred_type_id,			
		pct_of_product,				
		seasonal,				
		gt_fd_ingred_prov_type_id,	
		gt_ingred_accred_type_id,
		accred_scheme_name,
		gt_water_stress_region_id,
		contains_gm
	) VALUES (
		out_gt_fd_ingredient_id,
		in_product_id,
		v_max_revision_id,
		in_gt_fd_ingred_type_id,			
		in_pct_of_product,				
		in_seasonal,				
		in_gt_fd_ingred_prov_type_id,	
		in_gt_ingred_accred_type_id,
		in_accred_scheme_name,
		in_gt_water_stress_region_id,
		in_contains_gm
	);
	
END;

PROCEDURE UpdateIngredient(
    in_act_id                       IN security_pkg.T_ACT_ID,
    in_product_id                   IN all_product.product_id%TYPE,
	in_gt_fd_ingredient_id			IN gt_fd_ingredient.gt_fd_ingredient_id%TYPE,	
	in_gt_fd_ingred_type_id			IN gt_fd_ingredient.gt_fd_ingred_type_id%TYPE,
	in_pct_of_product				IN gt_fd_ingredient.pct_of_product%TYPE,
	in_seasonal						IN gt_fd_ingredient.seasonal%TYPE,
	in_gt_fd_ingred_prov_type_id	IN gt_fd_ingredient.gt_fd_ingred_prov_type_id%TYPE,
	in_gt_ingred_accred_type_id		IN gt_fd_ingredient.gt_ingred_accred_type_id%TYPE,
	in_accred_scheme_name			IN gt_fd_ingredient.accred_scheme_name%TYPE,
	in_gt_water_stress_region_id	IN gt_fd_ingredient.gt_water_stress_region_id%TYPE,
	in_contains_gm					IN gt_fd_ingredient.contains_gm%TYPE
)
AS
	v_max_revision_id			product_revision.revision_id%TYPE;
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
	SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
	UPDATE gt_fd_ingredient
	   SET 
		gt_fd_ingred_type_id = in_gt_fd_ingred_type_id,		
		pct_of_product = in_pct_of_product,				
		seasonal = in_seasonal,				
		gt_fd_ingred_prov_type_id = in_gt_fd_ingred_prov_type_id,	
		gt_ingred_accred_type_id = in_gt_ingred_accred_type_id,
		accred_scheme_name = in_accred_scheme_name, 
		gt_water_stress_region_id = in_gt_water_stress_region_id,
		contains_gm = in_contains_gm
	 WHERE product_id = in_product_id
	   AND revision_id = v_max_revision_id
	   AND gt_fd_ingredient_id = in_gt_fd_ingredient_id;
	
END;

---------------- Procedures for animal welfare schemes

PROCEDURE GetFdSchemes(
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
       SELECT fas.gt_fd_scheme_id, fas.percent_of_product, fas.whole_product
	   FROM gt_fd_answer_scheme fas
        WHERE product_id = in_product_id
          AND revision_id = in_revision_id;
END;

PROCEDURE DeleteSchemes(
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
    DELETE FROM gt_fd_answer_scheme where product_id = in_product_id AND revision_id = v_max_revision_id;
END;


PROCEDURE AddScheme(
    in_act_id                       IN  security_pkg.T_ACT_ID,
    in_product_id                   IN  all_product.product_id%TYPE,
    in_gt_fd_scheme_id              IN  gt_fd_scheme.gt_fd_scheme_id%TYPE,
    in_percent_of_product           IN  gt_fd_answer_scheme.percent_of_product%TYPE,
	in_whole_product				IN  gt_fd_answer_scheme.whole_product%TYPE   
) IS
	v_max_revision_id			product_revision.revision_id%TYPE;
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
     SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
    
    INSERT INTO gt_fd_answer_scheme(
            product_id,
            revision_id,
            gt_fd_answer_scheme_id,
            gt_fd_scheme_id,
            percent_of_product,
            whole_product
        ) VALUES (
            in_product_id,
            v_max_revision_id,
            gt_fd_answer_scheme_id_seq.NEXTVAL,
			in_gt_fd_scheme_id,
            in_percent_of_product,
            in_whole_product
        );
END;


--------------- Getting data for form combos

PROCEDURE GetPortionTypes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT gt_fd_portion_type_id, description
          FROM gt_fd_portion_type;
END;

PROCEDURE GetIngredientGroups(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT ig.gt_fd_ingred_group_id, ig.description
          FROM gt_fd_ingred_group ig;
END;

PROCEDURE GetIngredientTypes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- mapping is one to one group / type
    OPEN out_cur FOR
        SELECT it.gt_fd_ingred_type_id, ig.gt_fd_ingred_group_id, it.description, ig.description group_description
          FROM gt_fd_ingred_type it, gt_fd_ingred_group ig
         WHERE it.gt_fd_ingred_group_id = ig.gt_fd_ingred_group_id
		 ORDER BY ig.gt_fd_ingred_group_id, LOWER(description);
END;

PROCEDURE GetProvenanceTypes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT p.gt_fd_ingred_prov_type_id, p.description
          FROM gt_fd_ingred_prov_type p;
END;

PROCEDURE GetAccreditationTypes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT a.gt_ingred_accred_type_id, a.description, a.needs_note
          FROM gt_ingred_accred_type a;
END;

PROCEDURE GetSchemeNames(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT fds.gt_fd_scheme_id, fds.description
          FROM gt_fd_scheme fds;
END;
-------------- Ancillary materials

PROCEDURE GetFdAncillary(
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
          FROM gt_ancillary_material m, (SELECT * FROM gt_food_anc_mat am WHERE product_id = in_product_id AND revision_id = in_revision_id) am, gt_anc_mat_prod_class_map pcm
          WHERE m.gt_ancillary_material_id = am.gt_ancillary_material_id (+) 
		  AND pcm.gt_ancillary_material_id = m.gt_ancillary_material_id
		  AND pcm.gt_product_class_id = 4
          ORDER BY m.pos ASC;
END;

------------- Endangered species
PROCEDURE GetFdEndangered(
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
           FROM gt_endangered_species es, gt_endangered_prod_class_map ecp, (SELECT * FROM gt_fd_endangered_sp WHERE product_id = in_product_id AND revision_id = in_revision_id) pes
          WHERE es.gt_endangered_species_id = ecp.gt_endangered_species_id
            AND es.gt_endangered_species_id = pes.gt_endangered_species_id (+)
            AND ecp.gt_product_class_id = model_pd_pkg.PROD_CLASS_FOOD
          ORDER BY LOWER(es.description);
END;

--------- Palm oils

PROCEDURE GetFdPalmOils(
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
          FROM gt_palm_ingred p, gt_fd_palm_ind pi
         WHERE p.gt_palm_ingred_id = pi.gt_palm_ingred_id (+)
           AND (pi.product_id = in_product_id OR pi.product_id IS NULL)
           AND ((pi.revision_id = in_revision_id) OR (pi.revision_id IS NULL))
         ORDER BY p.gt_palm_ingred_id;
END;

PROCEDURE GetSAQuestions(
	in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
 	in_revision_id				 IN product_revision.revision_id%TYPE,
    out_cur                     OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_gt_product_type_id		gt_product_type.gt_product_type_id%TYPE;
BEGIN
		--here question default is returned only if the question has no entry in the gt_sa_question_product type table 
	v_gt_product_type_id := product_info_pkg.GetProductTypeId(in_act_id, in_product_id, in_revision_id);
	
	OPEN out_cur FOR
        SELECT  saq.gt_sa_question_id, 
		sai.description gt_issue,
		CASE WHEN ptsaq.question_text IS NULL THEN saq.default_question_text ELSE ptsaq.question_text END AS question_text, 
		CASE WHEN fsaq.product_id IS NULL THEN 0 ELSE 1 END AS included_boo
          FROM gt_sa_question saq, gt_sa_issue sai, gt_sa_q_prod_type ptsaq, (SELECT * FROM gt_food_sa_q WHERE product_id = in_product_id AND revision_id = in_revision_id) fsaq
          WHERE saq.gt_sa_question_id = fsaq.gt_sa_question_id (+)
		  AND sai.gt_sa_issue_id = saq.gt_sa_issue_id
		  AND ptsaq.gt_sa_question_id = saq.gt_sa_question_id
		  AND ptsaq.gt_product_type_id = v_gt_product_type_id;
           
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
	v_gt_fd_ingredient_id				gt_fd_ingredient.gt_fd_ingredient_id%TYPE;
BEGIN

	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_to_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

	-- we always want to overwrite so lets just get rid of the row
	DELETE FROM gt_fd_answer_scheme WHERE product_id = in_to_product_id AND revision_id = in_to_rev;
	DELETE FROM gt_fd_endangered_sp WHERE product_id = in_to_product_id AND revision_id = in_to_rev;
	DELETE FROM gt_fd_ingredient WHERE product_id = in_to_product_id AND revision_id = in_to_rev;
	DELETE FROM gt_fd_palm_ind WHERE product_id = in_to_product_id AND revision_id = in_to_rev;
	DELETE FROM gt_food_anc_mat WHERE product_id = in_to_product_id AND revision_id = in_to_rev;
	DELETE FROM gt_food_sa_q WHERE product_id = in_to_product_id AND revision_id = in_to_rev;
	DELETE FROM gt_food_answers WHERE product_id = in_to_product_id AND revision_id = in_to_rev;
	
	INSERT INTO gt_food_answers (
		product_id, revision_id, pct_added_water, pct_high_risk, gt_fd_portion_type_id, data_quality_type_id, gt_water_stress_region_id)
	SELECT
	   in_to_product_id, in_to_rev, pct_added_water, pct_high_risk, gt_fd_portion_type_id, data_quality_type_id, gt_water_stress_region_id
	FROM gt_food_answers
		WHERE product_id = in_from_product_id
		AND revision_id =  in_from_rev;

	INSERT INTO gt_fd_answer_scheme (
   		gt_fd_answer_scheme_id, gt_fd_scheme_id, product_id, revision_id, percent_of_product, whole_product)
	SELECT
		gt_fd_answer_scheme_id_seq.nextval, gt_fd_scheme_id, in_to_product_id, in_to_rev, percent_of_product, whole_product
	FROM gt_fd_answer_scheme
		WHERE product_id  = in_from_product_id
		  AND revision_id = in_from_rev;

	INSERT INTO gt_fd_endangered_sp (
	  	gt_endangered_species_id, product_id, revision_id)
	SELECT
		gt_endangered_species_id, in_to_product_id, in_to_rev
	FROM gt_fd_endangered_sp
		WHERE product_id = in_from_product_id
		AND revision_id =  in_from_rev;

	INSERT INTO gt_fd_palm_ind (
	   gt_palm_ingred_id, product_id, revision_id)
	SELECT
		gt_palm_ingred_id, in_to_product_id, in_to_rev
	FROM gt_fd_palm_ind
		WHERE product_id = in_from_product_id
		AND revision_id =  in_from_rev;

	INSERT INTO gt_food_anc_mat (
	   gt_ancillary_material_id, product_id, revision_id)
	SELECT
		gt_ancillary_material_id, in_to_product_id, in_to_rev
	FROM gt_food_anc_mat
		WHERE product_id = in_from_product_id
		AND revision_id =  in_from_rev;

		
	INSERT INTO gt_food_sa_q (
		product_id, revision_id, gt_sa_question_id
	)
	SELECT 
		in_to_product_id, in_to_rev, gt_sa_question_id
	FROM gt_food_sa_q
		WHERE product_id = in_from_product_id
		AND revision_id =  in_from_rev;


	FOR r IN (
		SELECT * FROM gt_fd_ingredient
		 WHERE product_id = in_from_product_id
		   AND revision_id =  in_from_rev
	)
	LOOP

		SELECT gt_fd_ingredient_id_seq.nextval INTO v_gt_fd_ingredient_id FROM DUAL;

		INSERT INTO gt_fd_ingredient (product_id, revision_id, gt_fd_ingredient_id, gt_fd_ingred_type_id, pct_of_product, seasonal, 
		gt_fd_ingred_prov_type_id, gt_ingred_accred_type_id, accred_scheme_name, 
		gt_water_stress_region_id, contains_gm)
			 VALUES(in_to_product_id, in_to_rev, v_gt_fd_ingredient_id, r.gt_fd_ingred_type_id, r.pct_of_product, 
			 r.seasonal, r.gt_fd_ingred_prov_type_id, r.gt_ingred_accred_type_id, r.accred_scheme_name, 
			 r.gt_water_stress_region_id, r.contains_gm);
			 
	END LOOP;
			
END;


END gt_food_pkg;
/
