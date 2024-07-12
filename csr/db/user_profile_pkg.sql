CREATE OR REPLACE PACKAGE CSR.user_profile_pkg IS

FUNCTION CanViewAvatar(
	in_user_sid		IN 	 security_pkg.T_SID_ID
) RETURN NUMBER;

PROCEDURE GetAvatar(
	in_user_sid		IN 	 security_pkg.T_SID_ID,
	out_cur			OUT  SYS_REFCURSOR
);

PROCEDURE GetProfilePanels (
	out_cur				OUT  SYS_REFCURSOR
);

PROCEDURE GetMyFeed(
	in_start_idx		IN   NUMBER,
	in_items			IN   NUMBER,
	out_cur				OUT  SYS_REFCURSOR
);

PROCEDURE WriteToUserFeed(
	in_user_feed_action_id	IN	user_feed_action.user_feed_action_id%TYPE,
	in_target_user_sid		IN	security_pkg.T_SID_ID DEFAULT NULL, 
	in_target_activity_id	IN	activity.activity_id%TYPE DEFAULT NULL, 
	in_target_param_1		IN  user_feed.target_param_1%TYPE DEFAULT NULL,
	in_target_param_2		IN  user_feed.target_param_2%TYPE DEFAULT NULL,
	in_target_param_3		IN  user_feed.target_param_3%TYPE DEFAULT NULL
);

PROCEDURE SetTermCondDocs (
	in_company_type_id	IN	chain.company_type.company_type_id%TYPE,
	in_docs_to_keep		IN	security_pkg.T_SID_IDS
);

PROCEDURE GetTermCondDocsForCompanyType (
	in_company_type_id	IN chain.company.company_type_id%TYPE DEFAULT 0,
	out_docs			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTermCondDocsForUser (
	in_user_sid			IN security_pkg.T_SID_ID,
	in_only_not_accepted int DEFAULT 0,
	out_docs			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE AcceptTermCondDocsForUser (
	in_user_sid			IN csr_user.csr_user_sid%TYPE
);

PROCEDURE ProcessStagedRowUpdate(
	in_primary_key					IN	csr.user_profile_staged_record.primary_key%TYPE,
	in_first_name					IN	csr.user_profile_staged_record.first_name%TYPE DEFAULT NULL,
	in_last_name					IN	csr.user_profile_staged_record.last_name%TYPE DEFAULT NULL,
	in_email_address				IN	csr.user_profile_staged_record.email_address%TYPE DEFAULT NULL,
	in_username						IN	csr.user_profile_staged_record.username%TYPE DEFAULT NULL,
	in_instance_step_id				IN	csr.user_profile_staged_record.instance_step_id%TYPE DEFAULT NULL,	
	out_result						OUT	VARCHAR2
);

PROCEDURE ProcessIncomingRow(
	in_primary_key					IN	csr.user_profile_staged_record.primary_key%TYPE,
	in_employee_ref					IN	csr.user_profile_staged_record.employee_ref%TYPE DEFAULT NULL,
	in_payroll_ref					IN	csr.user_profile_staged_record.payroll_ref%TYPE DEFAULT NULL,
	in_first_name					IN	csr.user_profile_staged_record.first_name%TYPE DEFAULT NULL,
	in_last_name					IN	csr.user_profile_staged_record.last_name%TYPE DEFAULT NULL,
	in_middle_name					IN	csr.user_profile_staged_record.middle_name%TYPE DEFAULT NULL,
	in_friendly_name				IN	csr.user_profile_staged_record.friendly_name%TYPE DEFAULT NULL,
	in_email_address				IN	csr.user_profile_staged_record.email_address%TYPE DEFAULT NULL,
	in_username						IN	csr.user_profile_staged_record.username%TYPE DEFAULT NULL,
	in_work_phone_number			IN	csr.user_profile_staged_record.work_phone_number%TYPE DEFAULT NULL,
	in_work_phone_extension			IN	csr.user_profile_staged_record.work_phone_extension%TYPE DEFAULT NULL,
	in_home_phone_number			IN	csr.user_profile_staged_record.home_phone_number%TYPE DEFAULT NULL,
	in_mobile_phone_number			IN	csr.user_profile_staged_record.mobile_phone_number%TYPE DEFAULT NULL,
	in_manager_employee_ref			IN	csr.user_profile_staged_record.manager_employee_ref%TYPE DEFAULT NULL,
	in_manager_payroll_ref			IN	csr.user_profile_staged_record.manager_payroll_ref%TYPE DEFAULT NULL,
	in_manager_primary_key			IN	csr.user_profile_staged_record.manager_primary_key%TYPE DEFAULT NULL,
	in_employment_start_date		IN	csr.user_profile_staged_record.employment_start_date%TYPE DEFAULT NULL,
	in_employment_leave_date		IN	csr.user_profile_staged_record.employment_leave_date%TYPE DEFAULT NULL,
	in_profile_active				IN	csr.user_profile_staged_record.profile_active%TYPE DEFAULT NULL,
	in_date_of_birth				IN	csr.user_profile_staged_record.date_of_birth%TYPE DEFAULT NULL,
	in_gender						IN	csr.user_profile_staged_record.gender%TYPE DEFAULT NULL,
	in_job_title					IN	csr.user_profile_staged_record.job_title%TYPE DEFAULT NULL,
	in_contract						IN	csr.user_profile_staged_record.contract%TYPE DEFAULT NULL,
	in_employment_type				IN	csr.user_profile_staged_record.employment_type%TYPE DEFAULT NULL,
	in_pay_grade					IN	csr.user_profile_staged_record.pay_grade%TYPE DEFAULT NULL,
	in_business_area_ref			IN	csr.user_profile_staged_record.business_area_ref%TYPE DEFAULT NULL,
	in_business_area_code			IN	csr.user_profile_staged_record.business_area_code%TYPE DEFAULT NULL,
	in_business_area_name			IN	csr.user_profile_staged_record.business_area_name%TYPE DEFAULT NULL,
	in_business_area_description	IN	csr.user_profile_staged_record.business_area_description%TYPE DEFAULT NULL,
	in_division_ref					IN	csr.user_profile_staged_record.division_ref%TYPE DEFAULT NULL,
	in_division_code				IN	csr.user_profile_staged_record.division_code%TYPE DEFAULT NULL,
	in_division_name				IN	csr.user_profile_staged_record.division_name%TYPE DEFAULT NULL,
	in_division_description			IN	csr.user_profile_staged_record.division_description%TYPE DEFAULT NULL,
	in_department					IN	csr.user_profile_staged_record.department%TYPE DEFAULT NULL,
	in_number_hours					IN	csr.user_profile_staged_record.number_hours%TYPE DEFAULT NULL,
	in_country						IN	csr.user_profile_staged_record.country%TYPE DEFAULT NULL,
	in_location						IN	csr.user_profile_staged_record.location%TYPE DEFAULT NULL,
	in_building						IN	csr.user_profile_staged_record.building%TYPE DEFAULT NULL,
	in_cost_centre_ref				IN	csr.user_profile_staged_record.cost_centre_ref%TYPE DEFAULT NULL,
	in_cost_centre_code				IN	csr.user_profile_staged_record.cost_centre_code%TYPE DEFAULT NULL,
	in_cost_centre_name				IN	csr.user_profile_staged_record.cost_centre_name%TYPE DEFAULT NULL,
	in_cost_centre_description		IN	csr.user_profile_staged_record.cost_centre_description%TYPE DEFAULT NULL,
	in_work_address_1				IN	csr.user_profile_staged_record.work_address_1%TYPE DEFAULT NULL,
	in_work_address_2				IN	csr.user_profile_staged_record.work_address_2%TYPE DEFAULT NULL,
	in_work_address_3				IN	csr.user_profile_staged_record.work_address_3%TYPE DEFAULT NULL,
	in_work_address_4				IN	csr.user_profile_staged_record.work_address_4%TYPE DEFAULT NULL,
	in_home_address_1				IN	csr.user_profile_staged_record.home_address_1%TYPE DEFAULT NULL,
	in_home_address_2				IN	csr.user_profile_staged_record.home_address_2%TYPE DEFAULT NULL,
	in_home_address_3				IN	csr.user_profile_staged_record.home_address_3%TYPE DEFAULT NULL,
	in_home_address_4				IN	csr.user_profile_staged_record.home_address_4%TYPE DEFAULT NULL,
	in_location_region_ref			IN	csr.user_profile_staged_record.location_region_ref%TYPE DEFAULT NULL,
	in_use_loc_region_as_start_pt	IN	csr.auto_imp_user_imp_settings.use_loc_region_as_start_pt%TYPE DEFAULT NULL,
	in_internal_username			IN	csr.user_profile_staged_record.internal_username%TYPE DEFAULT NULL,
	in_manager_username				IN	csr.user_profile_staged_record.manager_username%TYPE DEFAULT NULL,
	in_activate_on					IN	csr.user_profile_staged_record.activate_on%TYPE DEFAULT NULL,
	in_deactivate_on				IN	csr.user_profile_staged_record.deactivate_on%TYPE DEFAULT NULL,
	in_instance_step_id				IN	csr.user_profile_staged_record.instance_step_id%TYPE DEFAULT NULL,
	out_result						OUT	VARCHAR2,
	out_csr_user_sid				OUT	csr.csr_user.csr_user_sid%TYPE
);

PROCEDURE WriteStagedUserProfileRow(
	in_row					IN	CSR.T_USER_PROFILE_STAGED_ROW
);

FUNCTION GetLocationRegionSid(
	v_location_region_ref		IN	csr.user_profile_staged_record.location_region_ref%TYPE
) RETURN NUMBER;

PROCEDURE UpdateProfile(
	in_row					IN	CSR.T_USER_PROFILE_STAGED_ROW,
	out_csr_user_sid		OUT	csr.user_profile.csr_user_sid%TYPE
);

PROCEDURE CreateUserAndProfile(
	in_row							IN	CSR.T_USER_PROFILE_STAGED_ROW,
	in_use_loc_region_as_start_pt	IN	csr.auto_imp_user_imp_settings.use_loc_region_as_start_pt%TYPE,
	out_csr_user_sid				OUT	csr.user_profile.csr_user_sid%TYPE
);

PROCEDURE CreateProfile(
	in_row							IN	CSR.T_USER_PROFILE_STAGED_ROW,
	in_csr_user_sid					IN	csr.user_profile.csr_user_sid%TYPE,
	in_region_sid					IN	csr.user_profile.location_region_sid%TYPE
);

PROCEDURE CreateProfilesForUsers;

PROCEDURE GetStagedUserRows(
	in_start_row			IN  NUMBER,
	in_page_size			IN  NUMBER,
	in_search_string		IN  VARCHAR2,
	in_order_by			 	IN  VARCHAR2,
	in_order_dir			IN  VARCHAR2,
	out_cur				 	OUT	SYS_REFCURSOR
);

PROCEDURE GetStagedRows(
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE DeleteStagedRow(
	in_primary_key			IN	csr.user_profile_staged_record.primary_key%TYPE
);

PROCEDURE DeleteAllStagedRows;

PROCEDURE GetProfile(
	in_user_sid			IN csr_user.csr_user_sid%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE UserHasProfile(					
	in_user_sid 		IN 	security_pkg.T_SID_ID,
	out_result			OUT	BINARY_INTEGER
);

PROCEDURE UserImportClassExists(
	out_result			OUT	BINARY_INTEGER
);

PROCEDURE IsUserImportClass(					
	in_class_sid 		IN 	csr.automated_import_class.automated_import_class_sid%TYPE,
	out_result			OUT	BINARY_INTEGER
);

PROCEDURE CreateLineManagerLinks;

PROCEDURE CreateLineManagerLinksForUser(
	in_csr_user_sid			IN	csr.user_profile.csr_user_sid%TYPE
);

PROCEDURE GetUserProfile(
	in_csr_user_sid		IN	csr.user_profile.csr_user_sid%TYPE,
	out_user_profile	OUT	csr.T_USER_PROFILE
);

PROCEDURE UNSEC_GetUserProfile(
	in_csr_user_sid		IN	csr.user_profile.csr_user_sid%TYPE,
	out_user_profile	OUT	csr.T_USER_PROFILE
);

END;
/