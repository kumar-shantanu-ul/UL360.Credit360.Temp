CREATE OR REPLACE PACKAGE BODY chain.excel_pkg
IS

PROCEDURE SaveFromCache (
	in_cache_key				IN  aspen2.filecache.cache_key%TYPE,
	in_sheet_name				IN  csr.worksheet.sheet_name%TYPE,
	in_worksheet_type_id		IN  csr.worksheet.worksheet_type_id%TYPE,
	in_header_row_index			IN  csr.worksheet.header_row_index%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_file_upload_sid			security_pkg.T_SID_ID DEFAULT chain.upload_pkg.SecureFile(in_cache_key);
	v_worksheet_id				csr.worksheet.worksheet_id%TYPE DEFAULT csr.excel_pkg.CreateWorksheet(in_sheet_name, in_worksheet_type_id, in_header_row_index);
BEGIN	
	
	INSERT INTO worksheet_file_upload
	(worksheet_id, file_upload_sid)
	VALUES
	(v_worksheet_id, v_file_upload_sid);
	
	OPEN out_cur FOR
		SELECT worksheet_id, file_upload_sid 
		--SELECT 6 worksheet_id, file_upload_sid 
		  FROM worksheet_file_upload
		 WHERE worksheet_id = v_worksheet_id;
END;

PROCEDURE DeleteWorksheet (
	in_worksheet_id				IN  worksheet_file_upload.worksheet_id%TYPE
)
AS
BEGIN
	FOR r IN (
		SELECT file_upload_sid FROM worksheet_file_upload WHERE worksheet_id = in_worksheet_id
	) LOOP
		upload_pkg.DeleteObject(security_pkg.GetAct, r.file_upload_sid);
	END LOOP;
	
	csr.excel_pkg.DeleteWorksheet(in_worksheet_id);
	
END;

END excel_pkg;
/
