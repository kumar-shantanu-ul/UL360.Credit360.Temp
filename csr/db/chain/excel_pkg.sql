CREATE OR REPLACE PACKAGE chain.excel_pkg
IS

PROCEDURE SaveFromCache (
	in_cache_key				IN  aspen2.filecache.cache_key%TYPE,
	in_sheet_name				IN  csr.worksheet.sheet_name%TYPE,
	in_worksheet_type_id		IN  csr.worksheet.worksheet_type_id%TYPE,
	in_header_row_index			IN  csr.worksheet.header_row_index%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteWorksheet (
	in_worksheet_id				IN  worksheet_file_upload.worksheet_id%TYPE
);

END excel_pkg;
/
