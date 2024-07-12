CREATE OR REPLACE PACKAGE ct.products_services_pkg AS

PROCEDURE GetOptions(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetOptions(
	in_breakdown_type_id			IN  ps_options.breakdown_type_id%TYPE, 
	in_auto_match_thresh			IN  ps_options.auto_match_thresh%TYPE
);

PROCEDURE GetItemSummaries(
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_breakdown_id					IN  ps_item.breakdown_id%TYPE,
	in_region_id					IN  ps_item.region_id%TYPE,
	in_supplier_id					IN  supplier.supplier_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetItemSummaries(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetItems(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetItem(
	in_item_id						IN  ps_item.item_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetItemEios(
	in_item_id						IN  ps_item_eio.item_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSpendBreakdowns(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSpendBreakdown(
	in_breakdown_id					IN  ps_spend_breakdown.breakdown_id%TYPE,
	in_region_id					IN  ps_spend_breakdown.region_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetCo2(
	in_item_id						IN  ps_item.item_id%TYPE,
	in_kg_co2						IN  ps_item.kg_co2%TYPE
);

PROCEDURE SetItem(
	in_item_id						IN  ps_item.item_id%TYPE,
	in_breakdown_id					IN  breakdown_region.breakdown_id%TYPE,
	in_region_id					IN  breakdown_region.region_id%TYPE,
	in_supplier_id					IN  supplier.supplier_id%TYPE,
	in_description					IN	ps_item.description%TYPE,
	in_spend						IN	ps_item.spend%TYPE,
	in_currency_id					IN	ps_item.currency_id%TYPE,
	in_purchase_date				IN	ps_item.purchase_date%TYPE,
	out_item_id						OUT	ps_item.item_id%TYPE
);

PROCEDURE SetItem(
	in_worksheet_id					IN  ps_item.worksheet_id%TYPE,
	in_row_number					IN  ps_item.row_number%TYPE,
	in_breakdown_id					IN  breakdown_region.breakdown_id%TYPE,
	in_region_id					IN  breakdown_region.region_id%TYPE,
	in_supplier_id					IN  supplier.supplier_id%TYPE,
	in_description					IN	ps_item.description%TYPE,
	in_spend						IN	ps_item.spend%TYPE,
	in_currency_id					IN	ps_item.currency_id%TYPE,
	in_purchase_date				IN	ps_item.purchase_date%TYPE,
	in_auto_eio_id					IN	ps_item.auto_eio_id%TYPE,
	in_auto_eio_id_score			IN	ps_item.auto_eio_id_score%TYPE,
	in_auto_eio_id_two				IN	ps_item.auto_eio_id_two%TYPE,
	in_auto_eio_id_score_two		IN	ps_item.auto_eio_id_score_two%TYPE,
	in_match_auto_accepted			IN	ps_item.match_auto_accepted%TYPE,
	out_item_id						OUT	ps_item.item_id%TYPE
);

PROCEDURE SetItemEio(
	in_item_id						IN  ps_item_eio.item_id%TYPE,
	in_eio_id						IN  ps_item_eio.eio_id%TYPE,
	in_pct							IN  ps_item_eio.pct%TYPE,
	in_from_worksheet				IN  NUMBER
);

PROCEDURE SetSpendBreakdown(
	in_breakdown_id					IN  ps_spend_breakdown.breakdown_id%TYPE,
	in_region_id					IN  ps_spend_breakdown.region_id%TYPE,
	in_spend						IN  ps_spend_breakdown.spend%TYPE
);

PROCEDURE DeleteItem(
	in_item_id						IN  ps_item.item_id%TYPE
);

PROCEDURE DeleteItemEio(
	in_item_id						IN  ps_item_eio.item_id%TYPE,
	in_eio_id						IN  ps_item_eio.eio_id%TYPE
);

PROCEDURE GetItemsForBreakdownRegion(
	in_breakdown_id					IN  ps_item.breakdown_id%TYPE,
	in_region_id					IN  ps_item.region_id%TYPE,
	in_from							IN  period.start_date%TYPE,
	in_to							IN  period.end_date%TYPE,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteSpendBreakdown(
	in_breakdown_id					IN  ps_spend_breakdown.breakdown_id%TYPE,
	in_region_id					IN  ps_spend_breakdown.region_id%TYPE
);

PROCEDURE SearchItems(
	in_page							IN  NUMBER,
	in_page_size					IN  NUMBER,
	in_search_term  				IN  VARCHAR2,
	in_source_id					IN  ps_item.worksheet_id%TYPE,
	in_all_sources					IN  NUMBER,
	in_supplier_id					IN  ps_item.supplier_id%TYPE,
	in_breakdown_id					IN  ps_item.breakdown_id%TYPE,
	in_region_id					IN  ps_item.region_id%TYPE,
	in_only_show_untagged_eio		IN  NUMBER,
	in_period_id					IN  period.period_id%TYPE,
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ClearEmissionResults(
	in_calculation_source_id	IN ps_calculation_source.calculation_source_id%TYPE
);

PROCEDURE SaveEmissionResult(
    in_breakdown_id 			IN ps_emissions_all.breakdown_id%TYPE,
    in_region_id 				IN ps_emissions_all.region_id%TYPE,
    in_eio_id 					IN ps_emissions_all.eio_id%TYPE,
	in_calculation_source_id	IN ps_calculation_source.calculation_source_id%TYPE,
	in_contribution_source_id	IN ps_calculation_source.calculation_source_id%TYPE,
    in_kg_co2 					IN ps_emissions_all.kg_co2%TYPE
);

PROCEDURE GetEmissionResults(
	in_calculation_source_id		IN ps_calculation_source.calculation_source_id%TYPE, 
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE ConfirmFirstAutomatchEio (
	in_item_id		IN ps_item.item_id%TYPE
);

PROCEDURE GetEIOForSupplier(
	in_supplier_id		IN  ps_calculation_source.calculation_source_id%TYPE, 
	out_eio_id			OUT company.eio_id%TYPE
);

END products_services_pkg;
/
