create or replace package supplier.gt_product_design_pkg
IS

TYPE T_MAT_HAZ_CHEMS IS TABLE OF gt_pda_haz_chem.gt_pda_haz_chem_id%TYPE INDEX BY PLS_INTEGER;
TYPE T_PALM_OIL IS TABLE OF gt_pda_palm_ind.gt_palm_ingred_id%TYPE INDEX BY PLS_INTEGER;
TYPE T_ENDANGERED_SPECIES IS TABLE OF gt_pda_endangered_sp.gt_endangered_species_id%TYPE INDEX BY PLS_INTEGER;
TYPE T_MATERIAL_ITEM_IDS IS TABLE OF gt_pda_material_item.gt_pda_material_item_id%TYPE INDEX BY PLS_INTEGER;

TYPE T_BATTERY_ITEM_IDS IS TABLE OF gt_pda_battery.gt_pda_battery_id%TYPE INDEX BY PLS_INTEGER;
TYPE T_MAINS_POWER_ITEM_IDS IS TABLE OF gt_pda_main_power.gt_pda_main_power_id%TYPE INDEX BY PLS_INTEGER;



-- provenance types
MAT_PROV_THREATENED		CONSTANT NUMBER(1) := 7;
-- accred types
MAT_ACCRED_UNKNOWN		CONSTANT NUMBER(1) := 4;

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
	in_gt_durability_type_id       			IN gt_pdesign_answers.GT_PDA_DURABILITY_TYPE_ID%TYPE,
	in_data_quality_type_id          		IN gt_product_answers.data_quality_type_id%TYPE
);

PROCEDURE GetProductDesignAnswers(
    in_act_id                    			IN security_pkg.T_ACT_ID,
    in_product_id               			IN all_product.product_id%TYPE,
 	in_revision_id							IN product_revision.revision_id%TYPE,
    out_cur                        			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPDMaterialItems(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
   	in_revision_id				 IN product_revision.revision_id%TYPE,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPDMatItemHazChems(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
   	in_revision_id				 IN product_revision.revision_id%TYPE,
    out_cur                     OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteAbsentMaterialItems(
	in_act_id								IN security_pkg.T_ACT_ID,
	in_product_id							IN all_product.product_id%TYPE,
	in_material_item_ids					IN gt_product_design_pkg.T_MATERIAL_ITEM_IDS
);

PROCEDURE DeleteMaterialItem(
    in_act_id               			     IN security_pkg.T_ACT_ID,
    in_product_id           			     IN all_product.product_id%TYPE,
	in_material_item_id						 IN gt_pda_material_item.gt_pda_material_item_id%TYPE
);

PROCEDURE AddMaterialItem(
    in_act_id                     			IN security_pkg.T_ACT_ID,
    in_product_id                 			IN all_product.product_id%TYPE,
	in_gt_material_id						IN gt_pda_material_item.gt_material_id%TYPE,
	in_pct_of_product						IN gt_pda_material_item.pct_of_product%TYPE,
	in_pct_recycled							IN gt_pda_material_item.pct_recycled%TYPE,
	in_gt_pda_provenance_type_id			IN gt_pda_material_item.gt_pda_provenance_type_id%TYPE,
	in_gt_pda_accred_type_id				IN gt_pda_material_item.gt_pda_accred_type_id%TYPE,
	in_gt_manufac_type_id					IN gt_pda_material_item.gt_manufac_type_id%TYPE,
	in_accreditation_note					IN gt_pda_material_item.accreditation_note%TYPE,
	in_gt_water_stress_region_id			IN gt_pda_material_item.gt_water_stress_region_id%TYPE,
	in_mat_haz_chems						IN T_MAT_HAZ_CHEMS,
	out_gt_material_id						OUT gt_pda_material_item.gt_material_id%TYPE
);

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
	in_gt_water_stress_region_id	IN gt_pda_material_item.gt_water_stress_region_id%TYPE,
	in_mat_haz_chems				IN T_MAT_HAZ_CHEMS
);
------------ Procedures for adding Battery items

PROCEDURE DeleteAbsentBatteryItems(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
	in_battery_ids	     		 IN gt_product_design_pkg.T_BATTERY_ITEM_IDS
) ;

PROCEDURE DeleteBatteryItem(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
	in_pda_battery_id			 IN gt_pda_battery.gt_pda_battery_id%TYPE
) ;

PROCEDURE AddBatteryItem(
    in_act_id                       IN security_pkg.T_ACT_ID,
    in_product_id                   IN all_product.product_id%TYPE,
	in_gt_battery_type_id			IN gt_pda_battery.gt_battery_type_id%TYPE,
	in_gt_battery_code_id			IN gt_pda_battery.gt_battery_code_id%TYPE,
	in_count						IN gt_pda_battery.count%TYPE,
	in_gt_battery_use_id			IN gt_battery_use.gt_battery_use_id%TYPE,
	in_use_desc						IN gt_pda_battery.use_desc%TYPE,
	out_gt_pda_battery_id			OUT gt_pda_battery.gt_pda_battery_id%TYPE
);

PROCEDURE UpdateBatteryItem(
    in_act_id                       IN security_pkg.T_ACT_ID,
    in_product_id                   IN all_product.product_id%TYPE,
	in_gt_battery_type_id			IN gt_pda_battery.gt_battery_type_id%TYPE,
	in_gt_pda_battery_id			IN gt_pda_battery.gt_pda_battery_id%TYPE,
	in_gt_battery_code_id			IN gt_pda_battery.gt_battery_code_id%TYPE,
	in_count						IN gt_pda_battery.count%TYPE,
	in_gt_battery_use_id			IN gt_battery_use.gt_battery_use_id%TYPE,
	in_use_desc						IN gt_pda_battery.use_desc%TYPE
);

------------ Procedures for adding Mains power items

PROCEDURE DeleteAbsentMPItems(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
	in_mains_power_ids	     		 IN gt_product_design_pkg.T_MAINS_POWER_ITEM_IDS
) ;

PROCEDURE DeleteMPItem(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
	in_pda_main_power_id		 IN gt_pda_main_power.gt_pda_main_power_id%TYPE
) ;

PROCEDURE AddMPItem(
    in_act_id                       IN security_pkg.T_ACT_ID,
    in_product_id                   IN all_product.product_id%TYPE,
	in_standby						IN gt_pda_main_power.standby%TYPE,
	in_wattage						IN gt_pda_main_power.wattage%TYPE,
	out_gt_pda_main_power_id		OUT gt_pda_main_power.gt_pda_main_power_id%TYPE
) ;

PROCEDURE UpdateMPItem(
    in_act_id                       IN security_pkg.T_ACT_ID,
    in_product_id                   IN all_product.product_id%TYPE,
	in_gt_pda_main_power_id			IN gt_pda_main_power.gt_pda_main_power_id%TYPE,
	in_standby						IN gt_pda_main_power.standby%TYPE,
	in_wattage						IN gt_pda_main_power.wattage%TYPE
) ;

-----------------

PROCEDURE GetPDEndangered(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
    in_revision_id               IN product_revision.revision_id%TYPE,
    out_cur                     OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPDPalmOils(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
 	in_revision_id				 IN product_revision.revision_id%TYPE,
    out_cur                     OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPDAncillary(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN    all_product.product_id%TYPE,
 	in_revision_id				 IN  product_revision.revision_id%TYPE,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPDBatteries(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
    in_revision_id               IN product_revision.revision_id%TYPE,
    out_cur                     OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPDMainsPower(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
    in_revision_id               IN product_revision.revision_id%TYPE,
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

-- Lists
PROCEDURE GetDurabilityTypes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMaterialGroups(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMaterialTypes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMatHazChemMappings(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMatProvMappings(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProvAccredMappings(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMatTypeManufacMappings(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetManufacturingTypes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAccreditationTypes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProvenanceTypes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetWSRegions(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBatteryTypes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBatteryUseTypes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBatteryCodes(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBatteryTypeBatteryMappings(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);



END gt_product_design_pkg;
/
