CREATE OR REPLACE PACKAGE CSR.Deleg_Plan_Pkg AS

-- delegation page
FUNCTION IsTemplate(
	in_delegation_sid	IN	security_pkg.T_SID_ID
) RETURN NUMBER;

FUNCTION HasChildTemplates(
	in_delegation_sid	IN	security_pkg.T_SID_ID
) RETURN NUMBER;

PROCEDURE SetAsTemplate(
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_is_template		IN	NUMBER
);

PROCEDURE IsDelegationPartOfPlan(
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	out_cur 			OUT SYS_REFCURSOR
);

PROCEDURE GetMasterDelegations(
	out_cur							OUT	SYS_REFCURSOR
);

-- Securable object callbacks

PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

-- delete everything in the tree where we have no user entered data
FUNCTION SafeDeleteDelegation(
	in_delegation_sid		IN	security_pkg.T_SID_ID
)
RETURN BOOLEAN;

-- delegation plan
PROCEDURE GetDelegPlanGroups(
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetActiveDelegPlans(
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetHiddenDelegPlans(
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetFolderPlans(
	in_parent_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION NewDelegPlan(
	in_name							IN	deleg_plan.name%TYPE,
	in_start_date					IN	deleg_plan.start_dtm%TYPE,
	in_end_date						IN	deleg_plan.end_dtm%TYPE,
	in_reminder_offset				IN	deleg_plan.reminder_offset%TYPE,
	in_period_set_id				IN	deleg_plan.period_set_id%TYPE,
	in_period_interval_id			IN	deleg_plan.period_interval_id%TYPE,
	in_schedule_xml					IN	deleg_plan.schedule_xml%TYPE,
	in_dynamic						IN	deleg_plan.dynamic%TYPE,
	in_parent_sid					IN	security.security_pkg.T_SID_ID DEFAULT NULL
) RETURN NUMBER;

PROCEDURE NewDelegPlanReturnDto(
	in_name							IN	deleg_plan.name%TYPE,
	in_start_date					IN	deleg_plan.start_dtm%TYPE,
	in_end_date						IN	deleg_plan.end_dtm%TYPE,
	in_reminder_offset				IN	deleg_plan.reminder_offset%TYPE,
	in_period_set_id				IN	deleg_plan.period_set_id%TYPE,
	in_period_interval_id			IN	deleg_plan.period_interval_id%TYPE,
	in_schedule_xml					IN	deleg_plan.schedule_xml%TYPE,
	in_dynamic						IN	deleg_plan.dynamic%TYPE,
	in_parent_sid					IN	security.security_pkg.T_SID_ID DEFAULT NULL,
	out_cur							OUT	SYS_REFCURSOR
);

FUNCTION CopyDelegPlan(
	in_deleg_plan_sid				IN	deleg_plan.deleg_plan_sid%TYPE,
	in_name							IN	deleg_plan.name%TYPE,
	in_start_dtm					IN	deleg_plan.start_dtm%TYPE,
	in_end_dtm						IN	deleg_plan.end_dtm%TYPE,
	in_reminder_offset				IN	deleg_plan.reminder_offset%TYPE,
	in_period_set_id				IN	deleg_plan.period_set_id%TYPE,
	in_period_interval_id			IN	deleg_plan.period_interval_id%TYPE,
	in_schedule_xml					IN	deleg_plan.schedule_xml%TYPE,
	in_parent_sid					IN	security.security_pkg.T_SID_ID DEFAULT NULL
) RETURN NUMBER;

FUNCTION CopyDelegPlan(
	in_deleg_plan_sid				IN	deleg_plan.deleg_plan_sid%TYPE,
	in_name							IN	deleg_plan.name%TYPE,
	in_start_dtm					IN	deleg_plan.start_dtm%TYPE,
	in_end_dtm						IN	deleg_plan.end_dtm%TYPE,
	in_reminder_offset				IN	deleg_plan.reminder_offset%TYPE,
	in_period_set_id				IN	deleg_plan.period_set_id%TYPE,
	in_period_interval_id			IN	deleg_plan.period_interval_id%TYPE,
	in_schedule_xml					IN	deleg_plan.schedule_xml%TYPE,
	in_copy_template				IN	NUMBER,
	in_template_delegation_sids		IN	security.security_pkg.T_SID_IDS,
	in_template_labels				IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_parent_sid					IN	security.security_pkg.T_SID_ID DEFAULT NULL
) RETURN NUMBER;

PROCEDURE AmendDelegPlan(
	in_deleg_plan_sid				IN	deleg_plan.deleg_plan_sid%TYPE,
	in_dynamic						IN	deleg_plan.dynamic%TYPE,
	in_last_applied_dynamic         IN  deleg_plan.last_applied_dynamic%TYPE DEFAULT NULL
);

PROCEDURE DeleteDelegPlan(
	in_deleg_plan_sid	IN	security_pkg.T_SID_ID,
	in_all				IN  NUMBER
);

PROCEDURE AddDelegToPlan(
	in_deleg_plan_sid			IN	security_pkg.T_SID_ID,
	in_delegation_sid			IN	security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE DeleteDelegPlanCol(	
	in_deleg_plan_col_Id	IN	deleg_plan_col.deleg_plan_col_id%TYPE,
	in_all					IN	NUMBER
);

PROCEDURE UpdateDelegPlanColRegion(
	in_deleg_plan_col_id		IN	deleg_plan_col.deleg_plan_col_id%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_region_selection			IN	deleg_plan_deleg_region.region_selection%TYPE,
	in_tag_id					IN	deleg_plan_deleg_region.tag_id%TYPE,
	in_region_type				IN	region.region_type%TYPE
);

PROCEDURE SetPlanRegions(
	in_deleg_plan_sid	IN	security_pkg.T_SID_ID,
	in_region_sids		IN	security_pkg.T_SID_IDS
);

PROCEDURE GetPlanUsers(
	in_deleg_plan_sid	IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetChildRegions(
	in_deleg_plan_sid	IN	security_pkg.T_SID_ID,
	in_parent_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetPlanDetails(
	in_deleg_plan_sid				IN	security_pkg.T_SID_ID,
	out_plan_cur					OUT	SYS_REFCURSOR,
	out_col_cur						OUT	SYS_REFCURSOR,
	out_root_regions_cur 			OUT	SYS_REFCURSOR,
	out_roles_cur					OUT	SYS_REFCURSOR,
	out_regions_cur					OUT	SYS_REFCURSOR,
	out_users_cur					OUT	SYS_REFCURSOR,
	out_dates_cur					OUT	SYS_REFCURSOR
);

FUNCTION CopyDelegation(
	in_deleg_plan_sid				IN	security_pkg.T_SID_ID,
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_region_selection				IN	deleg_plan_deleg_region.region_selection%TYPE,
	in_tag_id						IN	deleg_plan_deleg_region.tag_id%TYPE,
	in_region_type					IN	region.region_type%TYPE,
	out_overlapping_sid				OUT	security_pkg.T_SID_ID,
	out_overlap_reg_cur 			OUT	delegation_pkg.T_OVERLAP_DELEG_REGIONS_CUR
) RETURN security_pkg.T_SID_ID;


PROCEDURE SetPlanRoles(
	in_deleg_plan_sid				IN	security_pkg.T_SID_ID,
	in_role_sids					IN	security_pkg.T_SID_IDS
);

PROCEDURE AddSyncDelegWithMasterJob(
	in_delegation_sid				IN	deleg_plan_job.delegation_sid%TYPE DEFAULT NULL,
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE AddApplyPlanJob(
	in_deleg_plan_sid				IN	deleg_plan_job.deleg_plan_sid%TYPE DEFAULT NULL,
	in_is_dynamic_plan				IN	deleg_plan_job.is_dynamic_plan%TYPE DEFAULT 1,
	in_overwrite_dates				IN	deleg_plan_job.overwrite_dates%TYPE DEFAULT 0,
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE AddJob(
	in_delegation_sid				IN	deleg_plan_job.delegation_sid%TYPE DEFAULT NULL,
	in_deleg_plan_sid				IN	deleg_plan_job.deleg_plan_sid%TYPE DEFAULT NULL,
	in_is_dynamic_plan				IN	deleg_plan_job.is_dynamic_plan%TYPE DEFAULT 1,
	in_overwrite_dates				IN	deleg_plan_job.overwrite_dates%TYPE DEFAULT 0,
	in_dynamic_change				IN  BOOLEAN DEFAULT FALSE,
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE SetFile (
	in_batch_job_id				IN	batch_job.batch_job_id%TYPE,
	in_blob						IN 	BLOB,
	in_file_name				IN	batch_job_batched_export.file_name%TYPE
);

PROCEDURE GetFile (
	in_batch_job_id				IN	batch_job.batch_job_id%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE ProcessJob(
	in_batch_job_id				IN	batch_job.batch_job_id%TYPE,
	out_result					OUT	batch_job.result%TYPE,
	out_result_url				OUT	batch_job.result_url%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE ApplyDynamicPlans(
	in_region_sid					IN	region.region_sid%TYPE,
	in_source_msg					IN	VARCHAR2
);

PROCEDURE GetPlanStatus(	
	in_deleg_plan_sid				IN	security_pkg.T_SID_ID,
	in_root_region_sid				IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_exclude_not_due				IN	NUMBER DEFAULT 0,
	in_exclude_after				IN	DATE DEFAULT SYSDATE,
	in_active_regions_only			IN	NUMBER DEFAULT 0,
	out_deleg_plan_cur				OUT	SYS_REFCURSOR,
	out_region_role_members_cur		OUT	SYS_REFCURSOR,
	out_roles_cur					OUT	SYS_REFCURSOR,
	out_deleg_plan_col_cur 			OUT	SYS_REFCURSOR,
	out_regions_cur					OUT	SYS_REFCURSOR,
	out_sheets_cur 					OUT	SYS_REFCURSOR,
	out_deleg_user_cur				OUT	SYS_REFCURSOR
);

PROCEDURE CopyPlanRoles(
	in_old_deleg_plan_sid	IN	deleg_plan.deleg_plan_sid%TYPE,
	in_new_deleg_plan_sid	IN	deleg_plan.deleg_plan_sid%TYPE
);

PROCEDURE ApplyPlanToRegion(
	in_deleg_plan_sid				IN	deleg_plan.deleg_plan_sid%TYPE,
	in_is_dynamic_plan				IN	NUMBER,
	in_name_template				IN	deleg_plan.name_template%TYPE,
	in_deleg_plan_col_deleg_id		IN	deleg_plan_col_deleg.deleg_plan_col_deleg_id%TYPE,
	in_master_delegation_name		IN	delegation.name%TYPE,
	in_maps_to_root_deleg_sid		IN	deleg_plan_deleg_region_deleg.maps_to_root_deleg_sid%TYPE,
	in_apply_to_region_sid			IN	deleg_plan_deleg_region_deleg.applied_to_region_sid%TYPE,
	in_apply_to_region_lookup_key	IN	region.lookup_key%TYPE,
	in_apply_to_region_desc			IN	region_description.description%TYPE,	
	in_plan_region_sid				IN	deleg_plan_deleg_region.region_sid%TYPE,
	in_tpl_delegation_sid			IN	deleg_plan_col_deleg.delegation_sid%TYPE,
	in_region_selection				IN	deleg_plan_deleg_region.region_selection%TYPE,
	in_region_type					IN	region.region_type%TYPE,
	in_tag_id						IN	deleg_plan_deleg_region.tag_id%TYPE,
	in_overwrite_dates				IN	NUMBER DEFAULT 0,
	out_created						IN OUT NUMBER
);

PROCEDURE DeleteDelegPlanDateSchedules(	
	in_deleg_plan_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE AddDelegPlanDateSchedule(
	in_deleg_plan_sid		IN security_pkg.T_SID_ID,
	in_role_sid				IN deleg_plan_date_schedule.role_sid%type,
	in_deleg_plan_col_id   	IN deleg_plan_date_schedule.deleg_plan_col_id%type,
    in_schedule_xml			IN deleg_plan_date_schedule.schedule_xml%type,
	in_reminder_offset		IN deleg_plan_date_schedule.reminder_offset%type
);

PROCEDURE AddDelegPlanDateScheduleEntry(
	in_deleg_plan_sid		IN security_pkg.T_SID_ID,
	in_role_sid				IN deleg_plan_date_schedule.role_sid%type,
	in_deleg_plan_col_id   	IN deleg_plan_date_schedule.deleg_plan_col_id%type,
	in_start_dtm 			IN DATE,
	in_creation_dtm			IN DATE,
	in_submission_dtm		IN DATE,
	in_reminder_dtm			IN DATE
);

PROCEDURE GetPlanCols(
	in_deleg_plan_sid	IN	security.security_pkg.T_SID_ID,
	out_col_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetPlanColsDelegs(
	in_deleg_plan_sid	IN	security.security_pkg.T_SID_ID,
	out_col_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetChangesSinceLastApplied(
	in_deleg_plan_sid     IN  deleg_plan.deleg_plan_sid%TYPE,
	in_limit_count        IN  NUMBER,
	out_cur               OUT SYS_REFCURSOR,
	out_count             OUT SYS_REFCURSOR
);

/*
  TestOnly_ProcessApplyPlanJob is only used for testing
*/
PROCEDURE TestOnly_ProcessApplyPlanJob(	
	in_deleg_plan_sid   	    	IN	security_pkg.T_SID_ID,
	in_is_dynamic_plan      		IN	NUMBER DEFAULT 1,
	in_overwrite_dates				IN	NUMBER DEFAULT 0,
	out_created						OUT	NUMBER
);

PROCEDURE TickDelegPlanRegions_Append(
	in_deleg_plan_sid		IN	security.security_pkg.T_SID_ID,
	in_deleg_sid			IN	security.security_pkg.T_SID_ID,
	in_region_sids			IN	security.security_pkg.T_SID_IDS
);

PROCEDURE TickDelegPlanRegions_NonAppend(
	in_deleg_plan_sid		IN	security.security_pkg.T_SID_ID,
	in_deleg_sid			IN	security.security_pkg.T_SID_ID,
	in_region_sids			IN	security.security_pkg.T_SID_IDS
);

PROCEDURE UNSEC_GetAllDelegPlanForExport(
	out_plan_cur				OUT	SYS_REFCURSOR,
	out_col_cur					OUT	SYS_REFCURSOR,
	out_template_cur			OUT	SYS_REFCURSOR,
	out_template_desc_cur		OUT	SYS_REFCURSOR,
	out_template_ind_cur		OUT	SYS_REFCURSOR,
	out_template_ind_desc_cur	OUT	SYS_REFCURSOR,
	out_form_expr_cur			OUT	SYS_REFCURSOR,
	out_form_expr_map_cur		OUT	SYS_REFCURSOR
);

PROCEDURE OnRegionMove(
	in_region_sid		IN	security.security_pkg.T_SID_ID,
	in_old_parent_sid 	IN 	security.security_pkg.T_SID_ID
);

FUNCTION HasSelectedChildren(
	in_deleg_plan_sid			IN	security_pkg.T_SID_ID,
	in_deleg_plan_col_id		IN	security_pkg.T_SID_ID,
	in_region_sid				IN	security_pkg.T_SID_ID
)
RETURN NUMBER;

END;
/
