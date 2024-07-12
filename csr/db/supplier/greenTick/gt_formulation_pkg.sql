create or replace package supplier.gt_formulation_pkg
IS

TYPE T_ANCILLARY_MATERIALS IS TABLE OF gt_ancillary_material.gt_ancillary_material_id%TYPE INDEX BY PLS_INTEGER;
TYPE T_CHEMICALS_PRESENT IS TABLE OF gt_hazzard_chemical.gt_hazzard_chemical_id%TYPE INDEX BY PLS_INTEGER;
TYPE T_PALM_OIL IS TABLE OF gt_fa_palm_ind.gt_palm_ingred_id%TYPE INDEX BY PLS_INTEGER;
TYPE T_ENDANGERED_SPECIES IS TABLE OF gt_fa_endangered_sp.gt_endangered_species_id%TYPE INDEX BY PLS_INTEGER;
TYPE T_WSR IS TABLE OF gt_fa_wsr.gt_water_stress_region_id%TYPE INDEX BY PLS_INTEGER;

PROCEDURE SetFormulationAnswers (
    in_act_id                                  IN  security_pkg.T_ACT_ID,
    in_product_id                              IN  all_product.product_id%TYPE,
    in_numberOfIngredients                     IN  gt_formulation_answers.ingredient_count%type,
    in_comparablePerformance                   IN  gt_formulation_answers.sf_ingredients%type,
    in_needForAdditionalMaterials              IN  gt_formulation_answers.sf_additional_materials%type,
    in_deliverConcentrate                      IN  gt_formulation_answers.concentrate%type,
    in_noHazChem                  			   IN  gt_formulation_answers.no_haz_chem%type,
    in_greenChemistry                          IN  gt_formulation_answers.sf_special_materials%type,
    in_ancillaryMaterials                      IN  gt_formulation_pkg.t_ancillary_materials,
    in_chemicalsPresent                        IN  gt_formulation_pkg.t_chemicals_present,
    in_waterPct		                           IN  gt_formulation_answers.water_pct%type,
    in_naturalCrops                            IN  gt_formulation_answers.bp_crops_pct%type,
    in_naturalFish                             IN  gt_formulation_answers.bp_fish_pct%type,
    in_naturalPalm                             IN  gt_formulation_answers.bp_palm_pct%type,
    in_naturalPalmProcessed                    IN  gt_formulation_answers.bp_palm_processed_pct%type,
    in_naturalWild                             IN  gt_formulation_answers.bp_wild_pct%type,
    in_naturalUnknown                          IN  gt_formulation_answers.bp_unknown_pct%type,
    in_naturalEndangered                       IN  gt_formulation_answers.bp_threatened_pct%type,
    in_naturalMineral                          IN  gt_formulation_answers.bp_mineral_pct%type,
    in_wsr	                                   IN  gt_formulation_pkg.t_wsr,
    in_palmOil                                 IN  gt_formulation_pkg.t_palm_oil,
    in_endangeredSpecies                       IN  gt_formulation_pkg.t_endangered_species,
    in_bioDiversitySteps                       IN  gt_formulation_answers.sf_biodiversity%type,
    in_accreditedPriority                      IN  gt_formulation_answers.bs_accredited_priority_pct%type,
    in_accreditedPrioritySource                IN  gt_formulation_answers.bs_accredited_priority_src%type,
    in_accreditedOther                         IN  gt_formulation_answers.bs_accredited_other_pct%type,
    in_accreditedOtherSource                   IN  gt_formulation_answers.bs_accredited_other_src%type,
    in_knownSource                             IN  gt_formulation_answers.bs_known_pct%type,
    in_unknownSource                           IN  gt_formulation_answers.bs_unknown_pct%type,
    in_noNatural                               IN  gt_formulation_answers.bs_no_natural_pct%type,
    in_formulationDocGroupId                   IN  gt_formulation_answers.bs_document_group%type,
	in_data_quality_type_id           		   IN gt_product_answers.data_quality_type_id%TYPE
);


PROCEDURE GetFormulationAnswers(
    in_act_id                    IN    security_pkg.T_ACT_ID,
    in_product_id                IN    all_product.product_id%TYPE,
 	in_revision_id				 IN  product_revision.revision_id%TYPE,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFormulationChemicals(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN    all_product.product_id%TYPE,
 	in_revision_id				 IN  product_revision.revision_id%TYPE,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFormulationPalmOils(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN    all_product.product_id%TYPE,
 	in_revision_id				 IN  product_revision.revision_id%TYPE,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFormulationAncillary(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN    all_product.product_id%TYPE,
 	in_revision_id				 IN  product_revision.revision_id%TYPE,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
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

PROCEDURE GetFormulationEndangered(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN    all_product.product_id%TYPE,
    in_revision_id                 IN  product_revision.revision_id%TYPE,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFormulationWSR(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
    in_revision_id               IN  product_revision.revision_id%TYPE,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAccessPackageType(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT    security_pkg.T_OUTPUT_CUR
);


END gt_formulation_pkg;
/
