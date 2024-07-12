create or replace package body supplier.gt_data_lists_pkg
IS

PROCEDURE ListGTFormulatedTypes(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT 
			gt_product_type_id "id",
			pt.description "description",
			unit "unit",
			ptg.DESCRIPTION "product type class",
			wut.DESCRIPTION "water use type",
			DECODE(water_usage_factor, -1, 'all',water_usage_factor) "prod use per application ml/g",
			DECODE(mnfct_energy_score, 2, 'low', 3, 'medium', 4, 'high') "manufac energy score",
			mnfct_energy_score "manufac energy score value", 
			use_energy_score "use energy score", 
			pc.GT_PRODUCT_CLASS_DESC "gt product class",
			vt.DESCRIPTION "viscocity type", 
			mnfct_water_score  "manufac water score value",
			pt.energy_in_dist_score "Energy in distribution"
		FROM gt_product_type pt, gt_product_type_group ptg, gt_water_use_type wut, gt_product_class pc, gt_access_visc_type vt
		WHERE 
			pt.GT_PRODUCT_TYPE_GROUP_ID = ptg.GT_PRODUCT_TYPE_GROUP_ID 
		AND    pt.GT_WATER_USE_TYPE_ID = wut.GT_WATER_USE_TYPE_ID
		AND    pt.GT_PRODUCT_CLASS_ID = pc.GT_PRODUCT_CLASS_ID
		AND    pt.GT_ACCESS_VISC_TYPE_ID = vt.GT_ACCESS_VISC_TYPE_ID
		AND    pt.gt_product_class_id = 1
		ORDER BY ptg.gt_product_type_group_id, pt.gt_product_type_id;
END;

PROCEDURE ListGTManufacturedTypes(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT 
			gt_product_type_id "id",
			pt.description  "description",
			unit "unit",
			ptg.DESCRIPTION "product type class",
			DECODE(mains_powered, 1, 'X', '') "mains powered",
			DECODE(water_usage_factor, -1, 'all',water_usage_factor) "water use score",
			use_energy_score "use energy score",
			hrs_used_per_month "Usage Hours / month",
			pc.GT_PRODUCT_CLASS_DESC "gt product class",
			vt.DESCRIPTION "viscocity type",
			water_in_prod_pd "water in product score",
			pt.energy_in_dist_score "Energy in distribution"
		FROM gt_product_type pt, gt_product_type_group ptg,  gt_product_class pc, gt_access_visc_type vt
		WHERE 
			pt.GT_PRODUCT_TYPE_GROUP_ID = ptg.GT_PRODUCT_TYPE_GROUP_ID 
		AND    pt.GT_PRODUCT_CLASS_ID = pc.GT_PRODUCT_CLASS_ID
		AND    pt.GT_ACCESS_VISC_TYPE_ID = vt.GT_ACCESS_VISC_TYPE_ID
		AND    pt.gt_product_class_id = 2
		ORDER BY ptg.gt_product_type_group_id, pt.gt_product_type_id;
END;

PROCEDURE ListGTFoodTypes(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT 
			gt_product_type_id "id",
			pt.description  "description",
			unit "unit",
			ptg.DESCRIPTION "product type class",
			DECODE(water_usage_factor, -1, 'all',water_usage_factor) "water use score",
			use_energy_score "use energy score",
			pc.GT_PRODUCT_CLASS_DESC "gt product class",
			vt.DESCRIPTION "viscocity type",
			water_in_prod_pd "water in product score",
			pt.energy_in_dist_score "Energy in distribution"
		FROM gt_product_type pt, gt_product_type_group ptg,  gt_product_class pc, gt_access_visc_type vt
		WHERE 
			pt.GT_PRODUCT_TYPE_GROUP_ID = ptg.GT_PRODUCT_TYPE_GROUP_ID 
		AND    pt.GT_PRODUCT_CLASS_ID = pc.GT_PRODUCT_CLASS_ID
		AND    pt.GT_ACCESS_VISC_TYPE_ID = vt.GT_ACCESS_VISC_TYPE_ID
		AND    pt.gt_product_class_id = 4
		ORDER BY ptg.gt_product_type_group_id, pt.gt_product_type_id;
END;

PROCEDURE ListManfProdMatGroups(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT gt_material_group_id ID, description
		FROM gt_material_group;
END;

PROCEDURE ListManfProdMatTypes(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT m.gt_material_id ID, m.description, g.description, DECODE(m.natural, 1, 'Yes', 0, 'No', 'Unknown') natural, m.env_impact_score env_impact_score, m.water_impact_score water_impact_score, CSR.stragg(mt.description) manufacturing_types
		FROM gt_material m, gt_material_group g, gt_mat_man_mappiing mmm, gt_manufac_type mt
		WHERE m.gt_material_group_id = g.gt_material_group_id
		AND m.gt_material_id = mmm.gt_material_id
		AND mt.gt_manufac_type_id = mmm.gt_manufac_type_id
		GROUP BY m.gt_material_id, m.description, g.description, m.natural, m.env_impact_score, m.water_impact_score;
END;

PROCEDURE ListManfProdManfTypes(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT gt_manufac_type_id ID, description, water_req_score, energy_req_score, waste_score
		FROM gt_manufac_type;
END;

PROCEDURE ListManfHighRiskSp(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sp.gt_endangered_species_id ID, sp.description description, sp.risk_score, sp.risk_level
		FROM gt_endangered_species sp, gt_endangered_prod_class_map m
		WHERE sp.gt_endangered_species_id = m.gt_endangered_species_id
		AND m.gt_product_class_id = 2;
END;

PROCEDURE ListPackMaterials(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT gt_pack_material_type_id ID, description, recycled_pct_theshold, env_impact_score
		FROM gt_pack_material_type;
END;

PROCEDURE ListFormulatedHighRiskSp(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sp.description description, sp.risk_score, sp.risk_level
		FROM gt_endangered_species sp, gt_endangered_prod_class_map m
		WHERE sp.gt_endangered_species_id = m.gt_endangered_species_id
		AND m.gt_product_class_id = 1;
END;

PROCEDURE ListTransPackMaterials(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
	SELECT gt_trans_material_type_id ID, description, recycled_pct_theshold, env_impact_score
	FROM gt_trans_material_type;
END;

PROCEDURE ListPackShapes(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
	SELECT gt_pack_shape_type_id, description
	FROM gt_pack_shape_type;
END;

PROCEDURE ListBatteries(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
	SELECT b.gt_battery_code_id ID, b.gt_battery_code code, c.gt_battery_chem_id chemical_id, c.description chemical, b.average_weight_g "Average Weight (g)", b.voltage "Voltage (V)", DECODE(b.recharchable, 1, 'Yes', 'No') rechargeable
	FROM gt_battery b, gt_battery_chem c
	WHERE b.gt_battery_chem_id = c.gt_battery_chem_id;
END;

PROCEDURE ListBatteryTypes(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
	SELECT gt_battery_type_id ID, description, waste_score, env_score, energy_home_score, DECODE(rechargable, 1, 'Yes', 'No') rechargeable
	FROM gt_battery_type;
END;

PROCEDURE ListFoodIngredTypes(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ft.gt_fd_ingred_type_id ID, ft.description, fg.description, ft.env_impact_score, ft.water_impact_score, ft.pesticide_score, ft.default_gt_sa_score
		FROM gt_fd_ingred_type ft, gt_fd_ingred_group fg
		WHERE ft.gt_fd_ingred_group_id = fg.gt_fd_ingred_group_id;
		
END;

PROCEDURE ListFoodPortionTypes(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT gt_fd_portion_type_id, description, score
		FROM gt_fd_portion_type;
		
END;

PROCEDURE ListFoodHighRiskSp(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sp.gt_endangered_species_id ID, sp.description description, sp.risk_score, sp.risk_level
		FROM gt_endangered_species sp, gt_endangered_prod_class_map m
		WHERE sp.gt_endangered_species_id = m.gt_endangered_species_id
		AND m.gt_product_class_id = 4;
END;

PROCEDURE ListSocialAmpQuestions(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT q.gt_sa_question_id ID, q.question_name name_of_issue, i.description issue_type, q.default_question_text question_text, q.default_gt_sa_score issue_score, q.help_text explanation
		FROM gt_sa_question q, gt_sa_issue i
		WHERE q.gt_sa_issue_id = i.gt_sa_issue_id;
END;

PROCEDURE ListAnimalWelfareSchemes(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT gt_fd_scheme_id ID, description, score
		FROM gt_fd_scheme;
END;

PROCEDURE ListWaterStressedRegions(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT gt_water_stress_region_id ID, description
		FROM gt_water_stress_region;
END;

PROCEDURE ListAncillaryMaterials(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT gt_ancillary_material_id ID, description, gt_score
		FROM gt_ancillary_material;
END;



END gt_data_lists_pkg;
/
