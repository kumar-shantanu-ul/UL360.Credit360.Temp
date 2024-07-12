CREATE OR REPLACE PACKAGE BODY CSR.structure_import_pkg AS

PROCEDURE SetBatchJob(
	in_workbook					IN batch_job_structure_import.workbook%TYPE,
	in_sheet_number				IN batch_job_structure_import.sheet_number%TYPE,
	in_type						IN batch_job_structure_import.import_type%TYPE,
	in_input					IN batch_job_structure_import.input%TYPE,
	in_start_row 				IN batch_job_structure_import.start_row%TYPE,
	in_allow_move				IN batch_job_structure_import.allow_move%TYPE,
	in_trash_old				IN batch_job_structure_import.trash_old%TYPE,
	in_allow_null_overwrite		IN batch_job_structure_import.allow_null_overwrite%TYPE,
	in_rmove_roles_inactivatd	IN batch_job_structure_import.remove_from_roles_inactivated%TYPE,
	in_create_users_blank_pwd	IN batch_job_structure_import.create_users_with_blank_pwd%TYPE,
	in_company_sid				IN batch_job_structure_import.company_sid%TYPE
)
AS
	v_batch_job_id		batch_job.batch_job_id%TYPE;
BEGIN
	batch_job_pkg.Enqueue(
		in_batch_job_type_id => batch_job_pkg.JT_STRUCTURE_IMPORT,
		out_batch_job_id => v_batch_job_id);

	INSERT INTO batch_job_structure_import 
	  (batch_job_id, workbook, sheet_number, import_type, input, start_row, allow_move, trash_old,
		allow_null_overwrite, lang, company_sid, remove_from_roles_inactivated, create_users_with_blank_pwd)
	  VALUES 
      (v_batch_job_id, in_workbook, in_sheet_number, in_type, in_input, in_start_row, in_allow_move, in_trash_old, 
		in_allow_null_overwrite, SYS_CONTEXT('SECURITY', 'LANGUAGE'), SYS_CONTEXT('SECURITY','CHAIN_COMPANY'),
		in_rmove_roles_inactivatd, in_create_users_blank_pwd);
END;

PROCEDURE GetBatchJob(
	in_batch_job_id		IN batch_job.batch_job_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_lang				batch_job_structure_import.lang%TYPE;
BEGIN
	OPEN out_cur FOR
		SELECT app_sid, batch_job_id, workbook, sheet_number, import_type, input, start_row, allow_move, trash_old,
			allow_null_overwrite, lang, company_sid, remove_from_roles_inactivated, create_users_with_blank_pwd
	  	  FROM batch_job_structure_import
		 WHERE batch_job_id = in_batch_job_id;
	
	SELECT lang
	  INTO v_lang
	  FROM batch_job_structure_import
	 WHERE batch_job_id = in_batch_job_id;
	 
	DELETE FROM batch_job_structure_import
	 WHERE batch_job_id = in_batch_job_id;
	 
	security.security_pkg.SetContext('LANGUAGE', v_lang);
END;

PROCEDURE FindUsers(	
	in_search_term		IN	VARCHAR2,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_users_sid	security_pkg.T_SID_ID;
BEGIN
	-- find /users
	v_users_sid := securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, security_pkg.GetAPP, 'Users');

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_users_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading users');
	END IF;

	OPEN out_cur FOR
		SELECT cu.csr_user_sid, cu.csr_user_sid user_sid, cu.user_name, cu.full_name, cu.email
		  FROM csr.csr_user cu, security.user_table ut
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ut.sid_id = cu.csr_user_sid
		   AND cu.hidden = 0
		   AND ut.account_enabled = 1
		   AND (UPPER(TRIM(in_search_term)) = UPPER(cu.user_name) OR
				UPPER(TRIM(in_search_term)) = UPPER(cu.full_name) OR
				UPPER(TRIM(in_search_term)) = UPPER(cu.email));
END;

END;
/
