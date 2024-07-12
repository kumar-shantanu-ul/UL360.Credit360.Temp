CREATE OR REPLACE PACKAGE ct.excel_pkg
IS

PROCEDURE GetCurrencyMaps (
	in_column_type_id			IN  csr.worksheet_column_type.column_type_id%TYPE,
	in_values					IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveCurrencyMaps (
	in_column_type_id			IN  csr.worksheet_column_type.column_type_id%TYPE,
	in_values					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_currency_ids				IN  chain.helper_pkg.T_NUMBER_ARRAY
);

PROCEDURE GetRegionMaps (
	in_column_type_id			IN  csr.worksheet_column_type.column_type_id%TYPE,
	in_values					IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveRegionMaps (
	in_column_type_id			IN  csr.worksheet_column_type.column_type_id%TYPE,
	in_values					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_region_ids				IN  chain.helper_pkg.T_NUMBER_ARRAY
);

PROCEDURE GetBreakdownMaps (
	in_column_type_id			IN  csr.worksheet_column_type.column_type_id%TYPE,
	in_values					IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveBreakdownMaps (
	in_column_type_id			IN  csr.worksheet_column_type.column_type_id%TYPE,
	in_values					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_breakdown_ids				IN  chain.helper_pkg.T_NUMBER_ARRAY
);

PROCEDURE GetSupplierMaps (
	in_supplier_id_ct_id		IN  csr.worksheet_column_type.column_type_id%TYPE,
	in_supplier_name_ct_id		IN  csr.worksheet_column_type.column_type_id%TYPE,
	in_supplier_id_values		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_supplier_name_values		IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveSupplierMaps (
	in_supplier_id_ct_id		IN  csr.worksheet_column_type.column_type_id%TYPE,
	in_supplier_name_ct_id		IN  csr.worksheet_column_type.column_type_id%TYPE,
	in_supplier_id_values		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_supplier_name_values		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_supplier_ids				IN  chain.helper_pkg.T_NUMBER_ARRAY
);

PROCEDURE GetDistanceMaps (
	in_column_type_id			IN  csr.worksheet_column_type.column_type_id%TYPE,
	in_values					IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveDistanceMaps (
	in_column_type_id			IN  csr.worksheet_column_type.column_type_id%TYPE,
	in_values					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_distance_unit_ids		IN  chain.helper_pkg.T_NUMBER_ARRAY
);

PROCEDURE GetWorksheets (
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetWorksheet (
	in_worksheet_id				IN  csr.worksheet.worksheet_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchPSWorksheets(
	in_page							IN  NUMBER,
	in_page_size					IN  NUMBER,
	in_breakdown_id					IN  ps_item.breakdown_id%TYPE,
	in_region_id					IN  ps_item.region_id%TYPE,
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteWorksheet (
	in_worksheet_id					csr.worksheet.worksheet_id%TYPE
);

PROCEDURE DeleteAllValueMaps;

END excel_pkg;
/
