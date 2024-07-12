CREATE OR REPLACE PACKAGE CSR.structure_import_pkg AS

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
);

PROCEDURE GetBatchJob(
	in_batch_job_id		IN batch_job.batch_job_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE FindUsers(	
	in_search_term		IN	VARCHAR2,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

END;
/