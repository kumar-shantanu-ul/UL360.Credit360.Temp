create or replace package supplier.gt_food_pkg
IS
TYPE T_ENDANGERED_SPECIES IS TABLE OF gt_fd_endangered_sp.gt_endangered_species_id%TYPE INDEX BY PLS_INTEGER;
TYPE T_INGREDIENT_IDS IS TABLE OF gt_fd_ingredient.gt_fd_ingredient_id%TYPE INDEX BY PLS_INTEGER;
TYPE T_PALM_OIL IS TABLE OF gt_pda_palm_ind.gt_palm_ingred_id%TYPE INDEX BY PLS_INTEGER;
TYPE T_SOCIAL_AMP_QUESTIONS IS TABLE OF gt_sa_question.gt_sa_question_id%TYPE INDEX BY PLS_INTEGER;


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
);

PROCEDURE GetFoodAnswers(
    in_act_id                    IN  security_pkg.T_ACT_ID,
    in_product_id                IN  all_product.product_id%TYPE,
 	in_revision_id				 IN  product_revision.revision_id%TYPE,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFdIngredients(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
   	in_revision_id				 IN product_revision.revision_id%TYPE,
    out_cur                     OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteAbsentIngredients(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN all_product.product_id%TYPE,
	in_ingredient_ids			IN gt_food_pkg.T_INGREDIENT_IDS
);

PROCEDURE DeleteIngredient(
    in_act_id						IN security_pkg.T_ACT_ID,
    in_product_id                	IN all_product.product_id%TYPE,
	in_gt_fd_ingredient_id			IN gt_fd_ingredient.gt_fd_ingredient_id%TYPE
);

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
);

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
);

PROCEDURE GetFdSchemes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
   	in_revision_id				 IN product_revision.revision_id%TYPE,
    out_cur                     OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteSchemes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN    all_product.product_id%TYPE
);

PROCEDURE AddScheme(
    in_act_id                       IN  security_pkg.T_ACT_ID,
    in_product_id                   IN  all_product.product_id%TYPE,
    in_gt_fd_scheme_id              IN  gt_fd_scheme.gt_fd_scheme_id%TYPE,
    in_percent_of_product           IN  gt_fd_answer_scheme.percent_of_product%TYPE,
	in_whole_product				IN  gt_fd_answer_scheme.whole_product%TYPE   
);

PROCEDURE GetPortionTypes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetIngredientGroups(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetIngredientTypes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProvenanceTypes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAccreditationTypes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSchemeNames(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFdAncillary(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
 	in_revision_id				 IN product_revision.revision_id%TYPE,
    out_cur                     OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFdEndangered(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
    in_revision_id               IN product_revision.revision_id%TYPE,
    out_cur                     OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFdPalmOils(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
 	in_revision_id				 IN product_revision.revision_id%TYPE,
    out_cur                     OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSAQuestions(
	in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
 	in_revision_id				 IN product_revision.revision_id%TYPE,
    out_cur                     OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE IncrementRevision(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_from_rev						IN product_revision.revision_id%TYPE
);

PROCEDURE CopyAnswers(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_from_product_id				IN all_product.product_id%TYPE,
	in_from_rev						IN product_revision.revision_id%TYPE,
	in_to_product_id				IN all_product.product_id%TYPE,
	in_to_rev						IN product_revision.revision_id%TYPE
);

END gt_food_pkg;
/