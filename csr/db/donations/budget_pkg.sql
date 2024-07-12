CREATE OR REPLACE PACKAGE DONATIONS.budget_Pkg
IS

PROCEDURE AmendBudget(
	in_budget_id					IN	budget.budget_id%TYPE,
	in_scheme_sid	 				IN	budget.scheme_sid%TYPE,
	in_description		 		IN	budget.description%TYPE,
	in_management_cost		IN	budget.management_cost%TYPE,
	in_budget_amount			IN	budget.budget_amount%TYPE,
	in_cur_code						IN	budget.currency_code%TYPE,
	in_exrate							IN	budget.exchange_rate%TYPE,
	in_compare_field_num  IN	budget.compare_field_num%TYPE
);

-- 
-- PROCEDURE: AddBudgets
--
PROCEDURE SetBudgets (
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_scheme_sid	 		IN	budget.scheme_sid%TYPE,
	in_region_group_sids	IN	VARCHAR2,
	in_start_dtm			IN	budget.start_dtm%TYPE,
	in_end_dtm				IN	budget.start_dtm%TYPE,
	in_description	 		IN	budget.description%TYPE,
	in_management_cost		IN	budget.management_cost%TYPE,
	in_budget_amount		IN	budget.budget_amount%TYPE,
	in_cur_code				IN	budget.currency_code%TYPE,
	in_exrate				IN	budget.exchange_rate%TYPE,
	in_compare_field_num    IN	budget.compare_field_num%TYPE
);


PROCEDURE AmendDetails (
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_scheme_sid	 		IN	budget.scheme_sid%TYPE,
	in_region_group_sids	IN	VARCHAR2,
	in_start_dtm			IN	budget.start_dtm%TYPE,
	in_end_dtm				IN	budget.start_dtm%TYPE,
	in_description		 	IN	budget.description%TYPE,
	in_management_cost		IN	budget.management_cost%TYPE,
	in_budget_amount		IN	budget.budget_amount%TYPE,
	in_cur_code				IN	budget.currency_code%TYPE,
	in_exrate				IN	budget.exchange_rate%TYPE,
	in_compare_field_num    IN	budget.compare_field_num%TYPE
);


PROCEDURE SetBudgetsActive(
	in_scheme_sid	 		IN	budget.scheme_sid%TYPE,
	in_region_group_sids	IN	VARCHAR2,
	in_start_dtm			IN	budget.start_dtm%TYPE,
	in_end_dtm				IN	budget.start_dtm%TYPE,
	in_is_active			IN  budget.is_active%TYPE
);

PROCEDURE GetBudgetListForRegionGroups(
	in_act_id							IN	security_pkg.T_ACT_ID,
	in_app_sid                      IN security_pkg.T_SID_ID,
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	in_region_group_sids	IN	VARCHAR2,
	out_cur								OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE DeleteBudget( 
	in_act_id							IN	security_pkg.T_ACT_ID,
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	in_region_group_sids	IN	VARCHAR2,
	in_start_dtm					IN	budget.start_dtm%TYPE,
	in_end_dtm						IN	budget.end_dtm%TYPE
);

PROCEDURE GetBudget(
	in_act_id							IN	security_pkg.T_ACT_ID,
	in_budget_id					IN	budget.budget_id%TYPE,
	out_cur								OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBudgetList(
	in_act_id							IN	security_pkg.T_ACT_ID,
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	in_region_group_sid		IN	security_pkg.T_SID_ID,
	out_cur								OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBudgetsByName(
	in_act_id							IN	security_pkg.T_ACT_ID,
	in_description						IN	budget.description%TYPE,
	in_scheme_sids						IN csr.utils_pkg.T_NUMBERS,
	out_cur								OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMyBudgetIDs(
	in_act_id	IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBudgetId(
	in_act_id							IN	security_pkg.T_ACT_ID,
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	in_region_group_sid		IN	security_pkg.T_SID_ID,
	in_start_dtm					IN	budget.start_dtm%TYPE,
	out_budget_id					OUT	budget.budget_id%TYPE
);


PROCEDURE GetBudgetIdAndDetails(
	in_act_id							IN	security_pkg.T_ACT_ID,
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	in_region_group_sid		IN	security_pkg.T_SID_ID,
	in_start_dtm					IN	budget.start_dtm%TYPE,
	out_cur								OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMyBudgets(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_permission_set	IN	security_pkg.T_PERMISSION,
	in_all_years			IN	NUMBER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMyBudgetsNoFormat(
	in_act_id					IN	security_pkg.T_ACT_ID,
  in_app_sid				IN	security_pkg.T_SID_ID,
	in_permission_set	IN	security_pkg.T_PERMISSION,
	in_all_years			IN	NUMBER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllSchemeData(
	in_act_id					IN	security_pkg.T_ACT_ID,
  in_app_sid				IN	security_pkg.T_SID_ID,
  out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSchemeData(
	in_act_id			IN	security_pkg.T_ACT_ID,
  in_app_sid		IN	security_pkg.T_SID_ID,
  in_scheme_sid			IN	security_pkg.T_SID_ID,
  out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSchemeList(
    in_act_id			IN	security_pkg.T_ACT_ID,
    in_app_sid		    IN	security_pkg.T_SID_ID,
    out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBudgetsForRegionGroup(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_region_group_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBudgetsForScheme(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_scheme_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBudgetsForApp(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetBudgetAndConstants(
	in_act_id							IN	security_pkg.T_ACT_ID,
	in_budget_id						IN	budget.budget_id%TYPE,
	out_cur								OUT	security_pkg.T_OUTPUT_CUR,
	out_constants						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetConstantsForBudget(
	in_act_id							IN	security_pkg.T_ACT_ID,
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	in_region_group_sids	IN	VARCHAR2,
	in_start_dtm					IN	budget.start_dtm%TYPE,
	in_end_dtm						IN	budget.end_dtm%TYPE,
  out_cur				        OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetConstantForBudgets(
	in_act_id							IN	security_pkg.T_ACT_ID,
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	in_region_group_sids	IN	VARCHAR2,
	in_start_dtm					IN	budget.start_dtm%TYPE,
	in_end_dtm						IN	budget.end_dtm%TYPE,
	in_constant_id        IN  constant.constant_id%TYPE,
	in_val                IN  budget_constant.val%TYPE
);

PROCEDURE GetConstants(
  out_cur OUT security_pkg.T_OUTPUT_CUR
);

END budget_Pkg;
/
