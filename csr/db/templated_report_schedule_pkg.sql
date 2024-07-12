CREATE OR REPLACE PACKAGE CSR.Templated_Report_Schedule_Pkg AS

/**
 * CreateObject helper
 * 
 * @param in_act_id			Access token
 * @param in_sid_id			The sid of the object
 * @param in_class_id		The class Id of the object
 * @param in_name			The name
 * @param in_parent_sid_id	The sid of the parent object
 */
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

/**
 * RenameObject helper
 * 
 * @param in_act_id			Access token
 * @param in_sid_id			The sid of the object
 * @param in_new_name		The name
 */
PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);


/**
 * DeleteObject helper
 * 
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 */
PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

/**
 * MoveObject helper
 * 
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 * @param in_new_parent_sid_id		.
 */
PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

/**
 * CreateSchedule
 * 
 * @param in_act_id						Access token
 * @param in_tpl_report_sid				Sid of the linked templated report
 * @param in_owner_user_sid				Sid of the schedule owner
 * @param in_name						The schedule name
 * @param in_region_selection_type_id	The region selection type id
 * @param in_region_selection_tag_id	The region selection tag id
 * @param in_include_inactive_regions	Whether to include inactive regions
 * @param in_on_report_per_region		Whether to generate one report per region, or one report for all
 * @param in_schedule_xml				Schedule Xml block
 * @param in_offset						Number of periods to offset by
 * @param in_use_unmerged				Whether to use unmerged data in the report
 * @param in_output_as_pdf				0 = word/powerpoint, 1 = pdf
 * @param in_role_sid					Sid of the role to run the reports as/for
 * @param in_email_owner_on_complete	Whether to email the owner when the reports complete (only applies when using a role)
 * @param in_doc_folder					Sid of doc folder to save the report to (null = don't save to doc lib)
 * @param in_overwrite_existing			Whether to overwrite existing report or create new version
 * @param out_schedule_sid				Sid of the new SO for the schedule
 */
PROCEDURE CreateSchedule(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tpl_report_sid			IN	TPL_REPORT_SCHEDULE.TPL_REPORT_SID%TYPE,
	in_owner_user_sid			IN	TPL_REPORT_SCHEDULE.OWNER_USER_SID%TYPE,
	in_name						IN	TPL_REPORT_SCHEDULE.NAME%TYPE,
	in_region_selection_type_id	IN	TPL_REPORT_SCHEDULE.REGION_SELECTION_TYPE_ID%TYPE,
	in_region_selection_tag_id	IN	TPL_REPORT_SCHEDULE.REGION_SELECTION_TAG_ID%TYPE,
	in_include_inactive_regions	IN	TPL_REPORT_SCHEDULE.INCLUDE_INACTIVE_REGIONS%TYPE,
	in_one_report_per_region	IN	TPL_REPORT_SCHEDULE.ONE_REPORT_PER_REGION%TYPE,
	in_schedule_xml				IN	TPL_REPORT_SCHEDULE.SCHEDULE_XML%TYPE,
	in_offset					IN	TPL_REPORT_SCHEDULE.OFFSET%TYPE,
	in_use_unmerged				IN	TPL_REPORT_SCHEDULE.USE_UNMERGED%TYPE,
	in_output_as_pdf			IN	TPL_REPORT_SCHEDULE.OUTPUT_AS_PDF%TYPE,
	in_role_sid					IN	TPL_REPORT_SCHEDULE.ROLE_SID%TYPE,
	in_email_owner_on_complete	IN	TPL_REPORT_SCHEDULE.EMAIL_OWNER_ON_COMPLETE%TYPE,
	in_doc_folder				IN	TPL_REPORT_SCHEDULE.DOC_FOLDER_SID%TYPE,
	in_overwrite_existing		IN	TPL_REPORT_SCHEDULE.OVERWRITE_EXISTING%TYPE,
	in_scenario_run_sid			IN	TPL_REPORT_SCHEDULE.SCENARIO_RUN_SID%TYPE,
	in_publish_to_prop_doc_lib	IN	TPL_REPORT_SCHEDULE.PUBLISH_TO_PROP_DOC_LIB%TYPE,
	out_schedule_sid			OUT security_pkg.T_SID_ID
);

/**
 * UpdateSchedule
 * 
 * @param in_schedule_sid				The schedule to update
 * @param in_region_selection_type_id	The region selection type id
 * @param in_region_selection_tag_id	The region selection tag id
 * @param in_include_inactive_regions	Whether to include inactive regions
 * @param in_on_report_per_region		Whether to generate one report per region, or one report for all
 * @param in_schedule_xml				Schedule Xml block
 * @param in_offset						Number of periods to offset by
 * @param in_use_unmerged				Whether to use unmerged data in the report
 * @param in_output_as_pdf				0 = word/powerpoint, 1 = pdf
 * @param in_role_sid					Sid of the role to run the reports as/for
 * @param in_email_owner_on_complete	Whether to email the owner when the reports complete (only applies when using a role)
 * @param in_doc_folder					Sid of doc folder to save the report to (null = don't save to doc lib)
 * @param in_overwrite_existing			0 = true, 1 = false - Whether to overwrite existing report or create new version
 */
PROCEDURE UpdateSchedule(
	in_schedule_sid				IN	TPL_REPORT_SCHEDULE.SCHEDULE_SID%TYPE,
	in_region_selection_type_id	IN	TPL_REPORT_SCHEDULE.REGION_SELECTION_TYPE_ID%TYPE,
	in_region_selection_tag_id	IN	TPL_REPORT_SCHEDULE.REGION_SELECTION_TAG_ID%TYPE,
	in_include_inactive_regions	IN	TPL_REPORT_SCHEDULE.INCLUDE_INACTIVE_REGIONS%TYPE,
	in_one_report_per_region	IN	TPL_REPORT_SCHEDULE.ONE_REPORT_PER_REGION%TYPE,
	in_schedule_xml				IN	TPL_REPORT_SCHEDULE.SCHEDULE_XML%TYPE,
	in_offset					IN	TPL_REPORT_SCHEDULE.OFFSET%TYPE,
	in_use_unmerged				IN	TPL_REPORT_SCHEDULE.USE_UNMERGED%TYPE,
	in_output_as_pdf			IN	TPL_REPORT_SCHEDULE.OUTPUT_AS_PDF%TYPE,
	in_role_sid					IN	TPL_REPORT_SCHEDULE.ROLE_SID%TYPE,
	in_email_owner_on_complete	IN	TPL_REPORT_SCHEDULE.EMAIL_OWNER_ON_COMPLETE%TYPE,
	in_doc_folder				IN	TPL_REPORT_SCHEDULE.DOC_FOLDER_SID%TYPE,
	in_overwrite_existing		IN	TPL_REPORT_SCHEDULE.OVERWRITE_EXISTING%TYPE,
	in_publish_to_prop_doc_lib	IN	TPL_REPORT_SCHEDULE.PUBLISH_TO_PROP_DOC_LIB%TYPE,
	in_scenario_run_sid			IN	TPL_REPORT_SCHEDULE.SCENARIO_RUN_SID%TYPE
);

/**
 * UpdateScheduleByName
 * 
 * @param in_existing_name				The name of the schedule to update
 * @param in_existing_tpl_report_sid	The sid of the associated report
 * @param in_region_selection_type_id	The region selection type id
 * @param in_region_selection_tag_id	The region selection tag id
 * @param in_include_inactive_regions	Whether to include inactive regions
 * @param in_on_report_per_region		Whether to generate one report per region, or one report for all
 * @param in_schedule_xml				Schedule Xml block
 * @param in_offset						Number of periods to offset by
 * @param in_use_unmerged				Whether to use unmerged data in the report
 * @param in_output_as_pdf				0 = word/powerpoint, 1 = pdf
 * @param in_role_sid					Sid of the role to run the reports as/for
 * @param in_email_owner_on_complete	Whether to email the owner when the reports complete (only applies when using a role)
 * @param in_doc_folder					Sid of doc folder to save the report to (null = don't save to doc lib)
 * @param in_overwrite_existing			0 = true, 1 = false - Whether to overwrite existing report or create new version
 */
PROCEDURE UpdateScheduleByName(
	in_existing_name			IN	TPL_REPORT_SCHEDULE.NAME%TYPE,
	in_existing_tpl_report_sid	IN	TPL_REPORT_SCHEDULE.TPL_REPORT_SID%TYPE,
	in_region_selection_type_id	IN	TPL_REPORT_SCHEDULE.REGION_SELECTION_TYPE_ID%TYPE,
	in_region_selection_tag_id	IN	TPL_REPORT_SCHEDULE.REGION_SELECTION_TAG_ID%TYPE,
	in_include_inactive_regions	IN	TPL_REPORT_SCHEDULE.INCLUDE_INACTIVE_REGIONS%TYPE,
	in_one_report_per_region	IN	TPL_REPORT_SCHEDULE.ONE_REPORT_PER_REGION%TYPE,
	in_schedule_xml				IN	TPL_REPORT_SCHEDULE.SCHEDULE_XML%TYPE,
	in_offset					IN	TPL_REPORT_SCHEDULE.OFFSET%TYPE,
	in_use_unmerged				IN	TPL_REPORT_SCHEDULE.USE_UNMERGED%TYPE,
	in_output_as_pdf			IN	TPL_REPORT_SCHEDULE.OUTPUT_AS_PDF%TYPE,
	in_role_sid					IN	TPL_REPORT_SCHEDULE.ROLE_SID%TYPE,
	in_email_owner_on_complete	IN	TPL_REPORT_SCHEDULE.EMAIL_OWNER_ON_COMPLETE%TYPE,
	in_doc_folder				IN	TPL_REPORT_SCHEDULE.DOC_FOLDER_SID%TYPE,
	in_overwrite_existing		IN	TPL_REPORT_SCHEDULE.OVERWRITE_EXISTING%TYPE,
	in_scenario_run_sid			IN	TPL_REPORT_SCHEDULE.SCENARIO_RUN_SID%TYPE,
	in_publish_to_prop_doc_lib	IN	TPL_REPORT_SCHEDULE.PUBLISH_TO_PROP_DOC_LIB%TYPE,
	out_schedule_sid			OUT security_pkg.T_SID_ID
);

/**
 * SetScheduleRegions
 * 
 * @param in_schedule_sid			The schedule sid
 * @param in_regions_list			List of regions to set
 */
PROCEDURE SetScheduleRegions(
	in_schedule_sid			IN	TPL_REPORT_SCHEDULE.schedule_sid%TYPE,
	in_regions				IN	security_pkg.T_SID_IDS
);

/**
 * GetSchedule
 * 
 * @param in_schedule_sid			The schedule sid
 * @param out_cur					The schedule details
 */
PROCEDURE GetSchedule(
	in_schedule_sid			IN	TPL_REPORT_SCHEDULE.schedule_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

/**
 * GetScheduleByName
 * 
 * @param in_schedule_name			The name of the schedule
 * @param in_tpl_report_sid			The sid of the report
 * @param out_cur					The schedule details
 */
PROCEDURE GetScheduleByName(
	in_schedule_name		IN	tpl_report_schedule.name%TYPE,
	in_tpl_report_sid		IN	tpl_report_schedule.tpl_report_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

/**
 * UpdateScheduleName
 * 
 * @param in_act_id					The act
 * @param in_schedule_sid			The schedule sid
 * @param in_new_name				The new name for the schedule
 */
PROCEDURE UpdateScheduleName(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_schedule_sid			IN	TPL_REPORT_SCHEDULE.schedule_sid%TYPE,
	in_new_name				IN	TPL_REPORT_SCHEDULE.name%TYPE
);


PROCEDURE GetScheduleEntries(
	in_tpl_report_sid		IN	TPL_REPORT_SCHEDULE.tpl_report_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetReportsToRun(
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetRegions(
	in_schedule_sid			IN	TPL_REPORT_SCHEDULE.schedule_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE UpdateScheduleFireTime(
	in_schedule_sid			IN	TPL_REPORT_SCHED_BATCH_RUN.schedule_sid%TYPE,
	in_new_fire_date		IN	TPL_REPORT_SCHED_BATCH_RUN.next_fire_time%TYPE
);

PROCEDURE ClearScheduleFireTime(
	in_schedule_sid			IN	TPL_REPORT_SCHED_BATCH_RUN.schedule_sid%TYPE
);

PROCEDURE UpdateSavedDocId(
	in_schedule_sid			IN TPL_REPORT_SCHED_SAVED_DOC.schedule_sid%TYPE,
	in_doc_id				IN TPL_REPORT_SCHED_SAVED_DOC.doc_id%TYPE,
	in_region_sid			IN TPL_REPORT_SCHED_SAVED_DOC.region_sid%TYPE
);

PROCEDURE GetSavedDocId(
	in_schedule_sid			IN TPL_REPORT_SCHED_SAVED_DOC.schedule_sid%TYPE,
	in_region_sid			IN TPL_REPORT_SCHED_SAVED_DOC.region_sid%TYPE,
	out_doc_id				OUT TPL_REPORT_SCHED_SAVED_DOC.doc_id%TYPE 
);

PROCEDURE GetScheduleAndTemplateName(
	in_schedule_sid			IN TPL_REPORT_SCHEDULE.schedule_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetSchedulesByRole(
	in_role_sid				IN TPL_REPORT_SCHEDULE.role_sid%TYPE,
	out_report_cur			OUT SYS_REFCURSOR,
	out_region_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetSchedulesByOwner(
	in_owner_sid			IN TPL_REPORT_SCHEDULE.owner_user_sid%TYPE,
	out_report_cur			OUT SYS_REFCURSOR,
	out_region_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetRegionNames(
	in_regions				IN	security_pkg.T_SID_IDS,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetUserScheduleHistory(
	in_schedule_sid			IN TPL_REPORT_SCHEDULE.schedule_sid%TYPE,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetOwnerScheduleHistory(
	in_schedule_sid			IN TPL_REPORT_SCHEDULE.schedule_sid%TYPE,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE ChangeScheduleOwner(
	in_schedule_sid			IN TPL_REPORT_SCHEDULE.schedule_sid%TYPE,
	in_new_owner_sid		IN TPL_REPORT_SCHEDULE.owner_user_sid%TYPE
);

PROCEDURE GetRoleMemberships(
	in_user_sid				IN	NUMBER,
	out_cur					OUT SYS_REFCURSOR
);

END;
/
