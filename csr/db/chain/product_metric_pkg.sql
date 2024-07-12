CREATE OR REPLACE PACKAGE CHAIN.product_metric_pkg AS

PROCEDURE GetProductMetricIcons(
	out_cur						out		security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductMetrics(
	in_product_type_id			IN		product_metric_product_type.product_type_id%TYPE,
	out_cur						out		security_pkg.T_OUTPUT_CUR,
	out_product_types_cur		out		security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveProductMetric(
	in_ind_sid					IN	product_metric.ind_sid%TYPE,
	in_applies_to_product		IN	product_metric.applies_to_product%TYPE,
	in_applies_to_prod_supplier	IN	product_metric.applies_to_prod_supplier%TYPE,
	in_product_metric_icon_id	IN	product_metric.product_metric_icon_id%TYPE,
	in_is_mandatory				IN	product_metric.is_mandatory%TYPE,
	in_show_measure				IN	product_metric.show_measure%TYPE,
	in_product_types			IN	security_pkg.T_SID_IDS,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR,
	out_product_types_cur		OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductMetricCalcs(
	out_cur						out		security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveProductMetricCalc(
	in_product_metric_calc_id	IN	product_metric_calc.product_metric_calc_id%TYPE,
	in_destination_ind_sid		IN	product_metric_calc.destination_ind_sid%TYPE,
	in_applies_to_products		IN	product_metric_calc.applies_to_products%TYPE,
	in_applies_to_prod_comps	IN	product_metric_calc.applies_to_product_companies%TYPE,
	in_applies_to_prod_supps	IN	product_metric_calc.applies_to_product_suppliers%TYPE,
	in_applies_to_ps_purchasers	IN	product_metric_calc.applies_to_prod_sup_purchasers%TYPE,
	in_applies_to_ps_suppliers	IN	product_metric_calc.applies_to_prod_sup_suppliers%TYPE,
	in_calc_type				IN	product_metric_calc.calc_type%TYPE,
	in_operator					IN	product_metric_calc.operator%TYPE,
	in_source_ind_sid_1			IN	product_metric_calc.source_ind_sid_1%TYPE,
	in_source_ind_sid_2			IN	product_metric_calc.source_ind_sid_2%TYPE,
	in_source_argument_2		IN	product_metric_calc.source_argument_2%TYPE,
	in_user_values_only			IN	product_metric_calc.user_values_only%TYPE,
	out_cur						out	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteProductMetricCalc(
	in_product_metric_calc_id	IN	product_metric_calc.product_metric_calc_id%TYPE
);

PROCEDURE SetProductMetric(
	in_product_id				IN	product_metric_val.product_id%TYPE,
	in_ind_sid					IN	product_metric_val.ind_sid%TYPE,
	in_start_date				IN	product_metric_val.start_dtm%TYPE,
	in_end_date					IN	product_metric_val.end_dtm%TYPE,
	in_val						IN	product_metric_val.val_number%TYPE,
	in_measure_conversion_id	IN	product_metric_val.measure_conversion_id%TYPE,
	in_note						IN	product_metric_val.note%TYPE
);

PROCEDURE UNSEC_PropagateProductMetrics(
	in_product_id				IN	product_metric_val.product_id%TYPE
);

PROCEDURE SetProductSupplierMetric(
	in_product_supplier_id		IN	product_supplier_metric_val.product_supplier_id%TYPE,
	in_ind_sid					IN	product_supplier_metric_val.ind_sid%TYPE,
	in_start_date				IN	product_supplier_metric_val.start_dtm%TYPE,
	in_end_date					IN	product_supplier_metric_val.end_dtm%TYPE,
	in_val						IN	product_supplier_metric_val.val_number%TYPE,
	in_measure_conversion_id	IN	product_supplier_metric_val.measure_conversion_id%TYPE,
	in_note						IN	product_supplier_metric_val.note%TYPE
);

PROCEDURE UNSEC_PropagateProdSupMetrics(
	in_product_supplier_id		IN	product_supplier_metric_val.product_supplier_id%TYPE
);

END product_metric_pkg;
/
