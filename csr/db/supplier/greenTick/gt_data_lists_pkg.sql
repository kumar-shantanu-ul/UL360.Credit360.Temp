create or replace package supplier.gt_data_lists_pkg
IS

PROCEDURE ListGTFormulatedTypes(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ListGTManufacturedTypes(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ListGTFoodTypes(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ListManfProdMatGroups(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ListManfProdMatTypes(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ListManfProdManfTypes(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ListManfHighRiskSp(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ListPackMaterials(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ListFormulatedHighRiskSp(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ListTransPackMaterials(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ListPackShapes(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ListBatteries(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ListBatteryTypes(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ListFoodIngredTypes(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ListFoodPortionTypes(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ListFoodHighRiskSp(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ListSocialAmpQuestions(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ListAnimalWelfareSchemes(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ListWaterStressedRegions(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ListAncillaryMaterials(
	in_act_id				IN security_pkg.T_ACT_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

END gt_data_lists_pkg;
/