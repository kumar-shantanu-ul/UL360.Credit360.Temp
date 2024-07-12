create or replace package supplier.report_gt_pkg 
IS

PROCEDURE RunGTProductInfoReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RunGTFormulationReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RunGTProductDesignReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,-- not used
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RunGTFoodReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,-- not used
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RunGTPackagingReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,-- not used
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RunGTTransportReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,-- not used
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RunGTSupplierReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,-- not used
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RunGTPackagingItemReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,-- not used
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RunGTTransPackItemReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,-- not used
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RunGTWaterImpactReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,-- not used
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RunGTScoreReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,-- not used
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetReportSettings(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_type_groups	IN tag_pkg.T_TAG_IDS,
	in_product_types		IN tag_pkg.T_TAG_IDS,
	in_product_ranges		IN tag_pkg.T_TAG_IDS
);

PROCEDURE ClearReportSettings(
	in_act_id				IN security_pkg.T_ACT_ID
);

PROCEDURE GetReportProductTypes(
	in_act_id			IN security_pkg.T_ACT_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetReportProductTypeGroups(
	in_act_id			IN security_pkg.T_ACT_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetReportProductRanges(
	in_act_id			IN security_pkg.T_ACT_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetFootPrintScore (
    in_act_id       IN security_pkg.T_ACT_ID,
    in_product_id   IN product.product_id%TYPE,
    in_revision_id  IN product_revision.revision_id%TYPE
) RETURN NUMBER;

END report_gt_pkg;
/
