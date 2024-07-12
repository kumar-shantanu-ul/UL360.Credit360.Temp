CREATE OR REPLACE PACKAGE csr.excel_pkg
IS

FUNCTION CreateWorksheet (
	in_sheet_name				IN  csr.worksheet.sheet_name%TYPE,
	in_worksheet_type_id		IN  csr.worksheet.worksheet_type_id%TYPE,
	in_header_row_index			IN  csr.worksheet.header_row_index%TYPE
) RETURN NUMBER;

PROCEDURE GetValueMapperClasses (
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetValueMappers (
	in_worksheet_type_id		IN  worksheet_type.worksheet_type_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetColumnTypes (
	in_worksheet_type_id		IN  worksheet_type.worksheet_type_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetColumnTags (
	in_worksheet_id				IN  worksheet.worksheet_id%TYPE,
	in_column_type_ids			IN  chain.helper_pkg.T_NUMBER_ARRAY,
	in_column_indices			IN  chain.helper_pkg.T_NUMBER_ARRAY
);

FUNCTION GetValueMapId (
	in_column_type_id			IN  worksheet_column_type.column_type_id%TYPE,
	in_value					IN  worksheet_value_map_value.value%TYPE,
	in_create					IN  NUMBER DEFAULT 1
) RETURN NUMBER;

FUNCTION GetValueMapId (
	in_column_type_id_1			IN  worksheet_column_type.column_type_id%TYPE,
	in_value_1					IN  worksheet_value_map_value.value%TYPE,
	in_column_type_id_2			IN  worksheet_column_type.column_type_id%TYPE,
	in_value_2					IN  worksheet_value_map_value.value%TYPE,
	in_create					IN  NUMBER DEFAULT 1
) RETURN NUMBER;

FUNCTION GetValueMapId (
	in_column_type_ids			IN  chain.helper_pkg.T_NUMBER_ARRAY,
	in_values					IN  security_pkg.T_VARCHAR2_ARRAY,
	in_create					IN  NUMBER DEFAULT 1
) RETURN NUMBER;

PROCEDURE RemoveValueMap (
	in_value_map_id				IN  worksheet_value_map.value_map_id%TYPE
); 

PROCEDURE RemoveValueMap (
	in_value_map_ids			IN  chain.helper_pkg.T_NUMBER_ARRAY
); 

PROCEDURE IgnoreRow (
	in_worksheet_id				IN  worksheet_row.worksheet_id%TYPE,
	in_row_number				IN  worksheet_row.row_number%TYPE
);

PROCEDURE SaveRowNumbers (
	in_worksheet_id				IN  worksheet_row.worksheet_id%TYPE,
	in_row_numbers				IN  chain.helper_pkg.T_NUMBER_ARRAY
);

PROCEDURE DeleteWorksheet (
	in_worksheet_id				IN  worksheet_row.worksheet_id%TYPE
);

PROCEDURE DeleteValueMap (
	in_value_map_id				IN  worksheet_value_map.value_map_id%TYPE
);

PROCEDURE DeleteAllValueMaps;

END excel_pkg;
/
