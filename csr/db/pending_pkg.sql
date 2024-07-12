CREATE OR REPLACE PACKAGE CSR.pending_pkg AS

PERMISSION_SUBMIT	CONSTANT security_pkg.T_PERMISSION := 65536;

ERR_DUPLICATE_STEP_USER CONSTANT NUMBER := -20300;

TYPE T_PENDING_IND_IDS      IS TABLE OF pending_ind.pending_ind_id%TYPE         INDEX BY PLS_INTEGER;
TYPE T_PENDING_REGION_IDS   IS TABLE OF pending_region.pending_region_id%TYPE   INDEX BY PLS_INTEGER;
TYPE T_APPROVAL_STEP_IDS    IS TABLE OF approval_step.approval_step_id%TYPE     INDEX BY PLS_INTEGER;
TYPE T_PENDING_VAL_IDS      IS TABLE OF pending_val.pending_val_id%TYPE         INDEX BY PLS_INTEGER;
  

LAYOUT_IND					CONSTANT NUMBER(10) := 0; -- all ind - user chooses period + region
LAYOUT_REGION				CONSTANT NUMBER(10) := 1; -- all region - user chooses ind + period
LAYOUT_PERIOD				CONSTANT NUMBER(10) := 2; -- all period - user chooses ind + region
LAYOUT_IND_X_REGION			CONSTANT NUMBER(10) := 3; -- all ind x all region (or region x ind) - user chooses period
LAYOUT_IND_X_PERIOD         CONSTANT NUMBER(10) := 4; -- all ind x all period (or period x ind) - user chooses region
LAYOUT_REGION_X_PERIOD      CONSTANT NUMBER(10) := 5; -- all region x all period (or period x region) - user chooses ind

TYPE PENDING_VAL_ID_ARRAY is table of NUMBER(10) index by binary_integer;

cms_trigger_rows    PENDING_VAL_ID_ARRAY;
cms_trigger_empty   PENDING_VAL_ID_ARRAY; 

PROCEDURE CreateDataset(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_reporting_period_sid		IN	security_pkg.T_SID_ID,
	in_label					IN	pending_dataset.label%TYPE,
	out_pending_dataset_id		OUT	pending_dataset.pending_dataset_Id%TYPE
);


PROCEDURE GetDataset(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id	IN	pending_dataset.pending_dataset_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetOverdueAlerts(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE RecordOverdueSent(
	in_approval_step_id				IN 	approval_step_sheet_alert.approval_step_id%TYPE,
	in_sheet_key					IN	approval_step_sheet_alert.sheet_key%TYPE,
	in_user_sid						IN	approval_step_sheet_alert.user_sid%TYPE
);

PROCEDURE GetReminderAlerts(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE RecordReminderSent(
	in_approval_step_id				IN 	approval_step_sheet_alert.approval_step_id%TYPE,
	in_sheet_key					IN	approval_step_sheet_alert.sheet_key%TYPE,
	in_user_sid						IN	approval_step_sheet_alert.user_sid%TYPE
);

PROCEDURE GetAllDatasetsInReportPeriod(
	in_act_id				 IN	security_pkg.T_ACT_ID,	
	in_reporting_period_sid	 IN security_pkg.T_SID_ID,
	out_cur					 OUT SYS_REFCURSOR
);

PROCEDURE AmendDataset(
	in_act_Id					IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id		IN 	pending_dataset.pending_dataset_Id%TYPE,
	in_label					IN	pending_dataset.label%TYPE
);

PROCEDURE DeleteDataset(
	in_act_Id					IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id		IN	pending_dataset.pending_dataset_Id%TYPE,
	in_ignore_warnings			IN	NUMBER
);

PROCEDURE GetMySimilarSheets(
	in_act_Id		    IN	security_pkg.T_ACT_ID,
	in_approval_step_id IN  approval_step.approval_step_Id%TYPE,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetMyApprovalSteps(
	in_act_Id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
);


PROCEDURE GetMyApprovalStepSheets(
	in_act_Id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetMyStepSheetSummary(
	out_cur_summary	OUT	SYS_REFCURSOR,
	out_cur_users	OUT	SYS_REFCURSOR
);

PROCEDURE GetSheetLog(
	in_act_Id			IN	security_pkg.T_ACT_ID,
	in_approval_step_id IN	approval_step.approval_step_id%TYPE,
	in_sheet_key    	IN	approval_step_sheet.sheet_key%TYPE,
	out_cur			    OUT	SYS_REFCURSOR
);

PROCEDURE GetSheetLogInclChildren(
	in_act_Id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id 	IN	approval_step.approval_step_id%TYPE,
	in_sheet_key    		IN	approval_step_sheet.sheet_key%TYPE,
	in_pending_region_id	IN	pending_region.pending_region_id%TYPE,
	in_pending_period_id	IN	pending_period.pending_period_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);


FUNCTION SubtractWorkingDays(
	in_date		IN	DATE,
	in_days		IN	NUMBER
) RETURN DATE;

FUNCTION AddWorkingDays(
	in_date		IN	DATE,
	in_days		IN	NUMBER
) RETURN DATE;


PROCEDURE GetApprovalStep(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_Step_id 	IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetApprovalStepMaintenanceData(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_approval_step_id IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

-- hardwired for specific layout (i.e. single region, single period)
PROCEDURE GetRejectableApprovalSheets(
	in_act_Id				IN	security_pkg.T_ACT_ID,
	in_parent_step_id		IN	approval_step.approval_step_id%TYPE,
	in_pending_region_Id	IN	pending_region.pending_region_id%TYPE,
	in_pending_period_Id	IN	pending_period.pending_period_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetSheet(
	in_act_Id			IN	security_pkg.T_ACT_ID,
	in_approval_step_id IN	approval_step.approval_step_id%TYPE,
	in_sheet_key    	IN	approval_step_sheet.sheet_key%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetAncestorApprovalSteps(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_Step_id 	IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetChildApprovalSteps(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_Step_id 	IN	security_pkg.T_SID_ID,
	out_aps					OUT	SYS_REFCURSOR,
	out_regions				OUT	SYS_REFCURSOR
);

PROCEDURE GetDescendantApprovalSteps(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_Step_id 	IN	security_pkg.T_SID_ID,
	out_aps					OUT	SYS_REFCURSOR,
	out_regions				OUT	SYS_REFCURSOR
);

PROCEDURE INTERNAL_DeleteVal(
	in_pending_val_id		IN	pending_val.pending_Val_id%TYPE
);

PROCEDURE GetPeriods(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id 	IN	pending_dataset.pending_dataset_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE CreatePeriod(
	in_act_Id				IN	security_pkg.T_ACT_ID,
	in_pending_dataset_Id	IN	pending_dataset.pending_dataset_id%TYPE,
	in_start_dtm			IN	pending_period.start_Dtm%TYPE,
	in_end_dtm				IN	pending_period.end_dtm%TYPE,
	in_default_due_dtm		IN	pending_period.default_due_dtm%TYPE,
	in_label				IN	pending_period.label%TYPE,
	out_pending_period_id	OUT	pending_period.pending_period_id%TYPE
);

PROCEDURE DeletePeriod(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_pending_period_id	IN	pending_period.pending_period_id%TYPE,
	in_ignore_warnings		IN	NUMBER
);

PROCEDURE DeleteAllPeriods(
	in_act_Id					IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id		IN	pending_dataset.pending_dataset_Id%TYPE,
	in_ignore_warnings			IN	NUMBER
);

PROCEDURE GetPeriodRange(
	in_act_id				  IN  security_pkg.T_ACT_ID,
	in_pending_dataset_id 	  IN  pending_dataset.pending_dataset_id%TYPE,
    out_start_dtm             OUT DATE,
    out_end_dtm               OUT DATE,
    out_interval_in_months    OUT NUMBER
);

PROCEDURE INTERNAL_CreatePeriods(
    in_act_Id				 IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id 	 IN  pending_dataset.pending_dataset_id%TYPE,
    in_start_dtm             IN DATE,
    in_end_dtm               IN DATE,
    in_interval_in_months    IN NUMBER 
);


-- called by triggers on CMS tables (e.g. for 2012)
PROCEDURE SetRelatedPendingVal(
	in_pending_val_id           pending_val.pending_val_id%TYPE,
	in_related_ind_lookup_key	pending_ind.lookup_key%TYPE,
	in_new_val_number           pending_val.val_number%TYPE
);
/*PRAGMA RESTRICT_REFERENCES(SetRelatedPendingVal);*/

PROCEDURE SetPeriodRange(
	in_act_Id				 IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id 	 IN  pending_dataset.pending_dataset_id%TYPE,
    in_start_dtm             IN DATE,
    in_end_dtm               IN DATE,
    in_interval_in_months    IN NUMBER 
);

PROCEDURE GetApprovalStepPeriods(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_Step_id 	IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetApprovalStepUsers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_Step_id 	IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetRootApprovalSteps(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id 	IN	pending_dataset.pending_Dataset_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);


PROCEDURE AddRootApprovalStep(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id		IN  pending_dataset.pending_Dataset_id%TYPE, -- nullable (get from parent approval step)
    in_new_label				IN	approval_step.label%TYPE,
    in_ind_ids			        IN	security_pkg.T_SID_IDS,
    in_region_ids   			IN	T_PENDING_REGION_IDS, -- nullable (all regions),
    in_user_sids                IN  security_pkg.T_SID_IDS,
    in_layout_type				IN	approval_step.layout_type%TYPE,
	out_new_approval_step_id	OUT	approval_step.approval_step_id%TYPE
);


PROCEDURE AddApprovalStep(
	in_act_id					    IN	security_pkg.T_ACT_ID,
	in_parent_approval_step_id	    IN	approval_step.approval_step_id%TYPE,
	in_new_label				    IN	approval_step.label%TYPE,
    in_working_day_Offset_from_due  IN  approval_step.working_day_Offset_from_due%TYPE,
    in_ind_ids			            IN	security_pkg.T_SID_IDS, -- nullable (all inds of parent)
    in_region_ids			        IN	T_PENDING_REGION_IDS,
    in_user_sids                    IN  security_pkg.T_SID_IDS,
	out_new_approval_step_id	    OUT	approval_step.approval_step_id%TYPE
);


PROCEDURE AddApprovalStep(
	in_act_id					    IN	security_pkg.T_ACT_ID,
	in_parent_approval_step_id	    IN	approval_step.approval_step_id%TYPE,
	in_new_label				    IN	approval_step.label%TYPE,
    in_working_day_Offset_from_due  IN  approval_step.working_day_Offset_from_due%TYPE,
	in_ind_ids			            IN	security_pkg.T_SID_IDS, -- nullable (all inds of parent)
    in_region_ids   			    IN	T_PENDING_REGION_IDS,
    in_user_sids                    IN  security_pkg.T_SID_IDS,
	out_cur						    OUT	SYS_REFCURSOR
);


PROCEDURE CopyApprovalStepChangeRegions(
	in_act_id					    IN	security_pkg.T_ACT_ID,
	in_copy_approval_step_id	    IN  approval_step.approval_step_id%TYPE, 
    in_region_ids   		    	IN	T_PENDING_REGION_IDS,
    in_user_sids                    IN  security_pkg.T_SID_IDS,
    out_new_approval_step_id	    OUT	approval_step.approval_step_id%TYPE
);
/*
PROCEDURE AddApprovalStep(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_parent_approval_step_id	IN	approval_step.approval_step_id%TYPE,
	in_new_label				IN	approval_step.label%TYPE,
    in_deadline_offset			IN	NUMBER,
    in_ind_ids		    	    IN	T_PENDING_IND_IDS,
    in_region_ids   	    	IN	T_PENDING_REGION_IDS,
	out_new_approval_step_id	OUT	approval_step.approval_step_id%TYPE
);
*/

PROCEDURE AmendApprovalStep(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_approval_step_id			IN	approval_step.approval_step_id%TYPE,
	in_label					IN	approval_step.label%TYPE
);

PROCEDURE DeleteApprovalStep(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE
);

PROCEDURE DeleteAllApprovalStepUsers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE
);

PROCEDURE DeleteApprovalStepUser(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	in_user_sid             IN  approval_step_user.user_sid%TYPE
);

PROCEDURE AddApprovalStepUsers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	in_user_sids            IN  security_pkg.T_SID_IDS
);

PROCEDURE AddIndToApprovalStep(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_Step_id%TYPE,
	in_pending_ind_id		IN	pending_ind.pending_ind_id%TYPE,
	in_propagate_down		IN  NUMBER
);

PROCEDURE RemoveIndFromApprovalStep(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_Step_id%TYPE,
	in_pending_ind_id		IN	pending_ind.pending_ind_id%TYPE,
	in_ignore_warnings		IN	NUMBER
);

PROCEDURE AddRegionToApprovalStep(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_Step_id%TYPE,
	in_pending_region_id	IN	pending_region.pending_region_id%TYPE
);

PROCEDURE RemoveRegionFromApprovalStep(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_Step_id%TYPE,
	in_pending_region_id	IN	pending_region.pending_region_id%TYPE,
	in_ignore_warnings		IN	NUMBER
);

PROCEDURE GetWhatCannotBeSubdelegated(
    in_approval_step_Id     IN  approval_step.approval_step_id%TYPE,
    out_cur                 OUT SYS_REFCURSOR
);

PROCEDURE SubdivideApprovalRegion(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id	IN	approval_step.approval_step_id%TYPE,
	in_child_region_id	IN	pending_region.pending_region_id%TYPE
);


PROCEDURE MergeApprovalRegions(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_approval_step_id			IN	approval_step.approval_step_id%TYPE,
    in_merge_to_region_id		IN	pending_region.pending_region_id%TYPE
);


PROCEDURE AddFileFromCache(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_pending_val_id	IN	pending_val.pending_val_id%TYPE,
	in_cache_key		IN	aspen2.filecache.cache_key%type,
	out_file_upload_sid	OUT	security_pkg.T_SID_ID
);


PROCEDURE AddFileFromCache(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	pending_val.approval_step_id%TYPE,
	in_pending_ind_id		IN	pending_val.pending_ind_id%TYPE,
	in_pending_region_id	IN	pending_val.pending_region_id%TYPE,
	in_pending_period_id	IN	pending_val.pending_period_id%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%type,
	out_file_upload_sid		OUT	security_pkg.T_SID_ID
);

PROCEDURE AddExistingFile(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_pending_val_id	IN	pending_val.pending_val_id%TYPE,
	in_file_upload_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE AddExistingFile(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	pending_val.approval_step_id%TYPE,
	in_pending_ind_id		IN	pending_val.pending_ind_id%TYPE,
	in_pending_region_id	IN	pending_val.pending_region_id%TYPE,
	in_pending_period_id	IN	pending_val.pending_period_id%TYPE,
	in_file_upload_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE RemoveFile(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_pending_val_id	IN	pending_val.pending_val_id%TYPE,
	in_file_upload_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE RemoveFile(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	pending_val.approval_step_id%TYPE,
	in_pending_ind_id		IN	pending_val.pending_ind_id%TYPE,
	in_pending_region_id	IN	pending_val.pending_region_id%TYPE,
	in_pending_period_id	IN	pending_val.pending_period_id%TYPE,
	in_file_upload_sid		IN	security_pkg.T_SID_ID
);


PROCEDURE GetFilesForApprovalStep(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE CreateInd(
	in_act_id					IN	security_pkg.T_ACT_ID					DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_pending_dataset_id		IN	pending_ind.pending_dataset_id%TYPE,
	in_description				IN	pending_ind.description%TYPE,
	in_val_mandatory			IN	pending_ind.val_mandatory%TYPE			DEFAULT 0,
	in_note_mandatory			IN	pending_ind.note_mandatory%TYPE			DEFAULT 0 ,
	in_file_upload_mandatory	IN	pending_ind.file_upload_mandatory%TYPE	DEFAULT 0,
	in_measure_sid				IN	security_pkg.T_SID_ID					DEFAULT null,
	in_parent_ind_id			IN	pending_ind.pending_ind_id%TYPE,
	in_element_type				IN	pending_ind.element_type%TYPE,
	in_maps_to_ind_sid			IN	security_pkg.T_SID_ID					DEFAULT null,
	in_tolerance_type			IN  pending_ind.tolerance_type%type			DEFAULT 0,
    in_pct_upper_tolerance		IN  pending_ind.pct_upper_tolerance%type	DEFAULT 1,
    in_pct_lower_tolerance		IN  pending_ind.pct_lower_tolerance%type	DEFAULT 1,
    in_format_xml				IN  pending_ind.format_xml%type				DEFAULT null,
    in_link_to_ind_id			IN  pending_ind.link_to_ind_id%type			DEFAULT null, -- ?? what does this do?
    in_read_only				IN  pending_ind.read_only%type				DEFAULT 0,
    in_info_xml					IN  pending_ind.info_xml%type				DEFAULT null,
    in_dp						IN  pending_ind.dp%type						DEFAULT 2,
    in_default_val_number		IN  pending_ind.default_val_number%type		DEFAULT null,
    in_default_val_string		IN  pending_ind.default_val_string%type		DEFAULT null,
    in_lookup_key				IN  pending_ind.lookup_key%type				DEFAULT null,
	out_pending_ind_id			OUT	pending_ind.pending_ind_id%TYPE
);

PROCEDURE CreateInd(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id		IN	pending_ind.pending_dataset_id%TYPE,
	in_description				IN	pending_ind.description%TYPE,
	in_val_mandatory			IN	pending_ind.val_mandatory%TYPE,
	in_note_mandatory			IN	pending_ind.note_mandatory%TYPE,
	in_file_upload_mandatory	IN	pending_ind.file_upload_mandatory%TYPE,
	in_measure_sid				IN	security_pkg.T_SID_ID,
	in_parent_ind_id			IN	pending_ind.pending_ind_id%TYPE,
	in_element_type				IN	pending_ind.element_type%TYPE,
	in_maps_to_ind_sid			IN	security_pkg.T_SID_ID,
	in_tolerance_type			IN  pending_ind.tolerance_type%type,
    in_pct_upper_tolerance		IN  pending_ind.pct_upper_tolerance%type,
    in_pct_lower_tolerance		IN  pending_ind.pct_lower_tolerance%type,
    in_format_xml				IN  pending_ind.format_xml%type,
    in_link_to_ind_id			IN  pending_ind.link_to_ind_id%type,
    in_read_only				IN  pending_ind.read_only%type,
    in_info_xml					IN  pending_ind.info_xml%type,
    in_dp						IN  pending_ind.dp%type,
    in_default_val_number		IN  pending_ind.default_val_number%type,
    in_default_val_string		IN  pending_ind.default_val_string%type,
    in_lookup_key				IN  pending_ind.lookup_key%type,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE DeleteInd(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_pending_ind_id				IN	pending_ind.pending_ind_id%TYPE,
	in_ignore_warnings				IN	NUMBER DEFAULT 0, 
	in_set_sheet_max_value_count	IN	NUMBER DEFAULT 1 -- faster if you set this to 0
);


PROCEDURE UNSEC_AddRegionToPending(
	in_region_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE CreateRegion(
	in_act_Id					IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id		IN	pending_dataset.pending_dataset_Id%TYPE,
	in_parent_region_Id			IN	pending_region.pending_region_id%TYPE,
	in_description				IN	pending_region.description%TYPE,
	in_maps_to_region_sid		IN	security_pkg.T_SID_ID,
	out_pending_region_Id		OUT	pending_region.pending_region_id%TYPE
);

PROCEDURE CreateRegion(
	in_act_Id					IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id		IN	pending_dataset.pending_dataset_Id%TYPE,
	in_parent_region_Id			IN	pending_region.pending_region_id%TYPE,
	in_description				IN	pending_region.description%TYPE,
	in_maps_to_region_sid		IN	security_pkg.T_SID_ID,
	out_cur		                OUT	SYS_REFCURSOR
);

PROCEDURE CreateRegionTree(
    in_act_id			        IN  security_pkg.T_ACT_ID,
	in_app_sid			    IN  security_pkg.T_SID_ID,
	in_pending_dataset_id	    IN  pending_dataset.pending_dataset_Id%TYPE
);


PROCEDURE CreateRegionTree(
    in_act_id			        IN  security_pkg.T_ACT_ID,
	in_app_sid			    IN  security_pkg.T_SID_ID,
	in_region_tree_root_sid		IN  security_pkg.T_SID_ID,
	in_pending_dataset_id	    IN  pending_dataset.pending_dataset_Id%TYPE
);

PROCEDURE GetAps(
	in_ind_sid						IN	security_pkg.T_SID_ID,
	in_reg_sid						IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	out_deleg_cur					OUT	SYS_REFCURSOR,
	out_sheet_cur					OUT	SYS_REFCURSOR,
	out_users_cur					OUT	SYS_REFCURSOR
);

PROCEDURE PruneRegionTree(
    in_act_id                   IN  security_pkg.T_ACT_ID,
	in_pending_dataset_id	    IN  pending_dataset.pending_dataset_Id%TYPE
);

PROCEDURE GetRegion(
	in_act_Id					IN	security_pkg.T_ACT_ID,
	in_pending_region_Id		IN	pending_region.pending_region_id%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);


PROCEDURE GetInd(
	in_act_Id				IN	security_pkg.T_ACT_ID,
	in_pending_ind_Id		IN	pending_ind.pending_ind_id%TYPE,
	out_cur	                OUT	SYS_REFCURSOR
);

PROCEDURE GetRootRegions(
	in_act_id				IN	security_pkg.T_ACT_ID,
    in_pending_dataset_id	IN	pending_region.pending_dataset_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetRegionTrees(
	in_act_id				IN	security_pkg.T_ACT_ID,
    in_pending_dataset_id	IN	pending_region.pending_dataset_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE DeleteRegion(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_pending_region_id			IN	pending_region.pending_region_id%TYPE,
	in_ignore_warnings				IN	NUMBER DEFAULT 0,
	in_set_sheet_max_value_count	IN	NUMBER DEFAULT 1 -- faster if you set this to 0
);

PROCEDURE MovePendingRegion(
    in_act_Id                   IN  security_pkg.T_ACT_ID,
    in_pending_region_id           IN  PENDING_REGION.PENDING_REGION_ID%TYPE,
    in_parent_region_id            IN  PENDING_REGION.PARENT_REGION_ID%TYPE
);
    

PROCEDURE AmendPendingRegion(
    in_act_Id                   IN  security_pkg.T_ACT_ID,
    in_pending_region_id        IN  PENDING_REGION.PENDING_REGION_ID%TYPE,
    in_description              IN  PENDING_REGION.DESCRIPTION%TYPE,
	in_pos						IN	PENDING_REGION.POS%TYPE
);

PROCEDURE BindAccuracyToInd(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_pending_ind_id	IN	pending_ind.pending_ind_id%TYPE,
	in_accuracy_type_id	IN	accuracy_type.accuracy_type_id%TYPE
);

PROCEDURE UnbindAccuracyFromInd(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_pending_ind_id	IN	pending_ind.pending_ind_id%TYPE,
	in_accuracy_type_id	IN	accuracy_type.accuracy_type_id%TYPE
);


PROCEDURE GetAccuracyTypes(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_approval_step_id	IN	approval_Step.approval_step_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);


PROCEDURE GetAccuracyTypeOptions(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_approval_step_id	IN	approval_Step.approval_step_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);


PROCEDURE GetIndAccuracyTypes(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_approval_step_id	IN	approval_Step.approval_step_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);


PROCEDURE ClearAccuracyTypeOptions(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_pending_val_id	IN	pending_val.pending_val_id%TYPE,
	in_accuracy_type_id	IN	accuracy_type.accuracy_type_id%TYPE
);

PROCEDURE SetAccuracyTypeOption(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_pending_val_id			IN	pending_val.pending_val_id%TYPE,
	in_accuracy_type_option_id	IN	accuracy_type_option.accuracy_type_option_id%TYPE,
	in_pct						IN	pending_val_accuracy_type_opt.pct%TYPE
);


PROCEDURE MapInd(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_pending_ind_id	IN	pending_ind.pending_ind_id%TYPE,
	in_ind_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE AmendPendingInd(
    in_act_Id                   IN  security_pkg.t_act_id,
    in_pending_ind_id           IN  pending_ind.pending_ind_id%TYPE,     
    in_description              IN  pending_ind.description%TYPE,        
    in_val_mandatory            IN  pending_ind.val_mandatory%TYPE,      
    in_note_mandatory           IN  pending_ind.note_mandatory%TYPE,
    in_file_upload_mandatory	IN	pending_ind.file_upload_mandatory%TYPE,
    in_measure_sid              IN  pending_ind.measure_sid%TYPE,        
    in_element_type             IN  pending_ind.element_type%TYPE,       
    in_tolerance_type           IN  pending_ind.tolerance_type%TYPE,     
    in_pct_upper_tolerance      IN  pending_ind.pct_upper_tolerance%TYPE,
    in_pct_lower_tolerance      IN  pending_ind.pct_lower_tolerance%TYPE,
    in_format_xml               IN  pending_ind.format_xml%TYPE,         
    in_link_to_ind_id           IN  pending_ind.link_to_ind_id%TYPE,     
    in_read_only                IN  pending_ind.read_only%TYPE,          
    in_info_xml                 IN  pending_ind.info_xml%TYPE,           
    in_dp                       IN  pending_ind.dp%TYPE,                 
    in_default_val_number       IN  pending_ind.default_val_number%TYPE, 
    in_default_val_string       IN  pending_ind.default_val_string%TYPE, 
    in_lookup_key               IN  pending_ind.lookup_key%TYPE,
    in_pos						IN	pending_ind.pos%TYPE,
    in_allow_file_upload		IN	pending_ind.allow_file_upload%TYPE
);

PROCEDURE MovePendingInd(
    in_act_Id                   IN  security_pkg.T_ACT_ID,
    in_pending_ind_id           IN  PENDING_IND.PENDING_IND_ID%TYPE,
    in_parent_ind_id            IN  PENDING_IND.PARENT_IND_ID%TYPE
);



PROCEDURE MapRegion(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_pending_region_id	IN	pending_region.pending_region_id%TYPE,
	in_region_sid			IN	security_pkg.T_SID_ID
);

FUNCTION GetPostMergeAggrBlockers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id	IN pending_dataset.pending_dataset_id%TYPE
) RETURN T_PENDING_MERGE_BLOCKER_TABLE;


PROCEDURE GetOrSetPendingValId(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	in_pending_ind_id		IN	pending_ind.pending_ind_id%TYPE,
	in_pending_region_id	IN	pending_region.pending_region_id%TYPE,
	in_pending_period_id	IN	pending_period.pending_period_id%TYPE,
	out_pending_val_id		OUT	pending_val.pending_val_id%TYPE
);

PROCEDURE GetOrSetPendingVal(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	in_pending_ind_id		IN	pending_ind.pending_ind_id%TYPE,
	in_pending_region_id	IN	pending_region.pending_region_id%TYPE,
	in_pending_period_id	IN	pending_period.pending_period_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE SetValueNote(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_approval_step_id				IN	pending_val.approval_step_id%TYPE,
	in_pending_ind_id				IN	pending_val.pending_ind_id%TYPE,
	in_pending_region_id			IN	pending_val.pending_region_id%TYPE,
	in_pending_period_id			IN	pending_val.pending_period_id%TYPE,
	in_note							IN	pending_val.note%TYPE
);



PROCEDURE GetPendingValLog(
	in_act_id		        IN	security_pkg.T_ACT_ID,
    in_pending_ind_id       IN  pending_val.pending_ind_Id%TYPE,
    in_pending_region_id    IN  pending_val.pending_region_Id%TYPE,
    in_pending_period_id    IN  pending_val.pending_period_Id%TYPE,
    out_cur                 OUT SYS_REFCURSOR
);




PROCEDURE SetValue(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_pending_ind_id				IN	pending_val.pending_ind_id%TYPE,
	in_pending_region_id			IN	pending_val.pending_region_id%TYPE,
	in_pending_period_id			IN	pending_val.pending_period_id%TYPE,
	in_approval_step_id				IN	pending_val.approval_step_id%TYPE,
	in_from_val_number				IN	pending_val.from_val_number%TYPE,
	in_from_measure_conversion_id	IN	pending_val.from_measure_conversion_id%TYPE,
	in_write_sc_jobs				IN	NUMBER, -- write stored calc recalc jobs? 1 = true, 0 = false
	out_pending_val_Id				OUT	pending_val.pending_val_id%TYPE
);


PROCEDURE GetStoredCalcJobs(
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetStoredCalcJobsForPD(
	in_pending_dataset_id	IN	pending_dataset.pending_dataset_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE DeleteProcessedCalcIndJobs(
	in_calc_pending_ind_id		IN	pending_ind.pending_ind_id%TYPE
);

PROCEDURE SetStringValue(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_approval_step_id				IN	pending_val.approval_step_id%TYPE,
	in_pending_ind_id				IN	pending_val.pending_ind_id%TYPE,
	in_pending_region_id			IN	pending_val.pending_region_id%TYPE,
	in_pending_period_id			IN	pending_val.pending_period_id%TYPE,
	in_val_string					IN	pending_val.val_string%TYPE
);

PROCEDURE GetValue(
	in_act_Id			IN	security_pkg.T_ACT_ID,
	in_pending_val_Id	IN	pending_val.pending_val_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);


FUNCTION GetLeafPointsAsTable(
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE
) RETURN T_PENDING_LEAF_TABLE;


PROCEDURE GetLeafPoints(
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetApprovalStepRegions(
	in_act_id				IN	security_pkg.T_ACT_ID,
    in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetApprovalStepFullRegions(
	in_act_id				IN	security_pkg.T_ACT_ID,
    in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetApprovalStepRegionTree(
	in_act_id				IN	security_pkg.T_ACT_ID,
    in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
    out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetApprovalStepIndTree(
	in_act_id				IN	security_pkg.T_ACT_ID,
    in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetPendingIndTree(
	in_act_id				IN	security_pkg.T_ACT_ID,
    in_top_PendingInd_id    IN	PENDING_IND.pending_ind_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetChildPendingInds(
	in_act_id				IN	security_pkg.T_ACT_ID,
    in_pending_dataset_id   IN	PENDING_IND.pending_dataset_id%TYPE,
    in_parent_ind_id    	IN	PENDING_IND.pending_ind_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
);


PROCEDURE InitDataSource(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	in_include_stored_calcs	IN	NUMBER
);

PROCEDURE GetAllIndDetails(
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetDataSourceValues(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
    out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetApprovalStepModels(
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE ClearApprovalStepModels(
	in_approval_step_sid	IN	approval_step_model.approval_step_id%TYPE
);

PROCEDURE AddApprovalStepModel(
	in_approval_step_sid	IN	approval_step_model.approval_step_id%TYPE,
	in_model_sid			IN	approval_step_model.model_sid%TYPE,
	in_link_description		IN	approval_step_model.link_description%TYPE,
	in_icon_cls				IN	approval_step_model.icon_cls%TYPE
);

PROCEDURE GetApprovalStepValues(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetApprovalStepVariances(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE SetVarianceExplanation(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_approval_step_id				IN	pending_val.approval_step_id%TYPE,
	in_pending_ind_id				IN	pending_val.pending_ind_id%TYPE,
	in_pending_region_id			IN	pending_val.pending_region_id%TYPE,
	in_pending_period_id			IN	pending_val.pending_period_id%TYPE,
	in_explanation					IN	pending_val_variance.explanation%TYPE
);

PROCEDURE SetDefaultValue(
    in_pending_dataset_id   IN  pending_Dataset.pending_dataset_id%TYPE,
    in_ind_sid              IN  security_pkg.T_SID_ID,
    in_default_value        IN  pending_val.val_number%TYPE
);

PROCEDURE SetSheetMaxValueCount(
	in_approval_Step_id		IN	approval_step.approval_step_id%TYPE
);


PROCEDURE SetValueAction(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_approval_step_id				IN	pending_val.approval_step_id%TYPE,
	in_pending_ind_ids				IN	T_PENDING_IND_IDS,
	in_pending_region_id			IN	pending_val.pending_region_id%TYPE,
	in_pending_period_id			IN	pending_val.pending_period_id%TYPE,	
	in_action   					IN	pending_val.action%TYPE
);

PROCEDURE AddComment(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_approval_step_id				IN	pending_val.approval_step_id%TYPE,
	in_pending_ind_id				IN	pending_val.pending_ind_id%TYPE,
	in_pending_region_id			IN	pending_val.pending_region_id%TYPE,
	in_pending_period_id			IN	pending_val.pending_period_id%TYPE,
	in_comment_text					IN	issue_log.message%TYPE,
	out_issue_id					OUT	issue.issue_id%TYPE	
);


PROCEDURE MarkCommentAsRead(
    in_act_id         IN  security_pkg.T_ACT_ID,
    in_issue_log_id   IN  issue_log.issue_log_id%TYPE
);

PROCEDURE DeleteComment(
    in_act_id         IN  security_pkg.T_ACT_ID,
    in_issue_log_id   IN  issue_log.issue_log_id%TYPE
);

PROCEDURE GetNewRootApprovalStepInfo(
    in_user_sid				IN  security_pkg.T_SID_ID,
    in_pending_dataset_Id	IN	security_pkg.T_SID_ID,
    out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetSubdelegationAlertInfo(
    in_approval_step_ids			IN  security_pkg.T_SID_IDS,
    out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetSubmitAlertInfo(
    in_approval_step_id    			IN  approval_step.approval_step_id%TYPE,
    in_sheet_key					IN  approval_step_sheet.sheet_key%TYPE,
    out_cur                			OUT SYS_REFCURSOR
);

PROCEDURE GetSubmitThankYouAlertInfo(
    in_approval_step_id				IN  approval_step.approval_step_id%TYPE,
    out_cur                			OUT SYS_REFCURSOR
);

PROCEDURE TakeControlOfValues(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	pending_val.approval_step_id%TYPE,
	in_pending_ind_ids		IN	T_PENDING_IND_IDS,
	in_region_id			IN	pending_val.pending_region_id%TYPE,
	in_period_id			IN	pending_val.pending_period_id%TYPE
);

PROCEDURE AddToPendingValLog(
	in_act_id		    IN	security_pkg.T_ACT_ID,
    in_pending_val_id   IN  pending_val.pending_val_Id%TYPE,
    in_description      IN  pending_val_Log.DESCRIPTION%TYPE,
    in_param_1          IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          IN  audit_log.param_3%TYPE DEFAULT NULL
);

PROCEDURE GetApprovalThankYouAlertInfo(
    in_approval_step_id    IN  approval_step.approval_step_id%TYPE,
    out_cur                OUT SYS_REFCURSOR
);

PROCEDURE GetIndicatorsThatHaveValues(
	in_act_id				IN	security_pkg.T_ACT_ID,
    in_pending_dataset_id	IN	pending_region.pending_dataset_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetRegionsThatHaveValues(
	in_act_id				IN	security_pkg.T_ACT_ID,
    in_pending_dataset_id	IN	pending_region.pending_dataset_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetPathsForAllRegionsMappedTo(
	in_act_id				IN	security_pkg.T_ACT_ID,
    in_app_sid         IN  security.securable_object.sid_id%TYPE,
    in_pending_dataset_id	IN	pending_region.pending_dataset_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
);

FUNCTION ConcatApsRegions(
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	in_max_regions			IN  NUMBER DEFAULT 100
) RETURN VARCHAR2;

FUNCTION ConcatApsUsers(
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	in_max_users			IN  NUMBER DEFAULT 100
) RETURN VARCHAR2;

FUNCTION ConcatApsUserEmails(
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	in_max_users			IN  NUMBER DEFAULT 100
) RETURN VARCHAR2;

PROCEDURE RekeyApprovalStepSheet(
	in_approval_step_id		IN	approval_step.approval_Step_id%TYPE
);

-- XXX: ported from web code, no security
PROCEDURE GetValueFromIRP_INSECURE(
	in_pending_ind_id		IN	pending_val.pending_ind_id%TYPE,
	in_pending_region_id	IN	pending_region.pending_region_id%TYPE,
	in_pending_period_id	IN	pending_period.pending_period_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetAllowPartialSubmit(
	out_allow_partial_submit	OUT	customer.allow_partial_submit%TYPE
);

PROCEDURE GetCascadeReject(
	out_cascade_reject			OUT	customer.cascade_reject%TYPE
);

PROCEDURE SetApprovalStepSheetsVisible(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	pending_val.approval_step_id%TYPE,
	in_visible				IN	NUMBER
);

FUNCTION GetSheetQueryString(
	in_app_sid				IN	customer.app_sid%TYPE,
    in_pending_ind_id       IN	pending_val.pending_ind_id%TYPE,
    in_pending_region_id    IN	pending_val.pending_region_id%TYPE,
    in_pending_period_id    IN	pending_val.pending_period_id%TYPE,
    in_user_sid             IN	security_pkg.T_SID_ID
) RETURN VARCHAR2;

FUNCTION GetSheetQueryString(
    in_pending_ind_id       IN	pending_val.pending_ind_id%TYPE,
    in_pending_region_id    IN	pending_val.pending_region_id%TYPE,
    in_pending_period_id    IN	pending_val.pending_period_id%TYPE,
    in_user_sid             IN	security_pkg.T_SID_ID
) RETURN VARCHAR2;

FUNCTION GetSheetQueryString(
	in_pending_val_Id		IN	pending_val.pending_val_id%TYPE,
    in_user_sid             IN	security_pkg.T_SID_ID
) RETURN VARCHAR2;

PROCEDURE InsertParentApprovalStep(
	in_approval_step_id			IN	approval_step.approval_step_id%TYPE,
	in_template_step_id			IN	approval_step.approval_step_id%TYPE,
	in_copy_users				IN	NUMBER,
	out_new_approval_step_id	OUT	approval_step.approval_step_id%TYPE
);

PROCEDURE FilterUsers(
	in_filter			IN	VARCHAR2,
	in_approval_step_id	IN	NUMBER,
	out_cur				OUT SYS_REFCURSOR,
	out_total_num_users	OUT SYS_REFCURSOR
);

PROCEDURE FilterRegions(  
	in_filter				IN	VARCHAR2,
	in_approval_step_id		IN	NUMBER,
	in_addingOrRemoving		IN	NUMBER,
	out_cur					OUT SYS_REFCURSOR
);

FUNCTION CreateApprovalStepSID(
	in_parent_sid security_pkg.T_SID_ID
)
RETURN security_pkg.T_SID_ID;

END pending_Pkg;
/
