CREATE OR REPLACE PACKAGE CSR.Sheet_Pkg AS

/**
 * Check whether currently logged in user has permissions to access the specified
 * sheet id.
 *
 * @param 		The sheet id
 * @param   	The permission set to check (defaults to READ)
 */
PROCEDURE CheckSheetAccessAllowed(
	in_sheet_id			IN	sheet.sheet_id%TYPE,
	in_permission_set	IN	NUMBER DEFAULT delegation_pkg.DELEG_PERMISSION_READ
);

-- ============================
-- Create or alter sheets
-- ============================

/**
 * CreateSheet
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param in_start_dtm			The start date
 * @param in_submission_dtm		.
 * @param out_sheet_id			.
 * @param out_end_dtm			.
 */
PROCEDURE CreateSheet(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_start_dtm			IN	DELEGATION.START_DTM%TYPE,
	in_submission_dtm		IN	SHEET.SUBMISSION_DTM%TYPE,
	out_sheet_id			OUT SHEET.SHEET_ID%TYPE,
	out_end_dtm				OUT	SHEET.END_DTM%TYPE
);

/**
 * CreateSheet
 * 
 * @param in_act_id					Access token
 * @param in_delegation_sid			The sid of the object
 * @param in_start_dtm				The start date
 * @param in_submission_dtm			.
 * @param in_require_active_regions	If 1 only copy sheets if it has at least one region active.
 * @param out_sheet_id				.
 * @param out_end_dtm				.
 */
PROCEDURE CreateSheet(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_delegation_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	DELEGATION.START_DTM%TYPE,
	in_submission_dtm			IN	SHEET.SUBMISSION_DTM%TYPE,
	in_require_active_regions	IN	NUMBER DEFAULT 0,
	out_sheet_id				OUT SHEET.SHEET_ID%TYPE,
	out_end_dtm					OUT	SHEET.END_DTM%TYPE
);

PROCEDURE SetSheetStatusAccordingParent(
	in_sheet_id					IN	sheet_value.sheet_value_id%TYPE,
	in_created_by_sid			IN	security_pkg.T_SID_ID,
	in_delegation_sid			IN	security_pkg.T_SID_ID,
	in_parent_sheet_id			IN	security_pkg.T_SID_ID
);

-- return summary info about sheets that exist for a delegation
/**
 * Change the dates for the sheet
 * 
 * @param in_act_id				Access token
 * @param in_sheet_id			The sheet id
 * @param in_submission_dtm		Submission date
 * @param in_reminder_dtm		Reminder date
 * @param in_propagate_down		Whether to propagate the changes to child delegs
 */
PROCEDURE AmendDates(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_id				IN	csr_data_pkg.T_SHEET_ID,
	in_submission_dtm		IN	sheet.submission_dtm%TYPE,
	in_reminder_dtm			IN	sheet.reminder_dtm%TYPE,
	in_propagate_down		IN	NUMBER	DEFAULT 1
);

PROCEDURE INTERNAL_DeleteSheetValue(
	in_sheet_value_id		IN	sheet_value.sheet_value_id%TYPE);

/**
 * DeleteSheet
 * 
 * @param in_sheet_id		.
 */
PROCEDURE DeleteSheet(
	in_sheet_id		IN	csr_data_pkg.T_SHEET_ID
);



-- ========================================
-- Get sheet and other information about it
-- ========================================

/**
 * GetSheet
 * 
 * @param in_act_id			Access token
 * @param in_sheet_id		.
 * @param out_cur			The rowset
 */
PROCEDURE GetSheet(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_sheet_id			IN	csr_data_pkg.T_SHEET_ID,
	out_cur				OUT	SYS_REFCURSOR
);


/**
 * Returns exteded info about a sheet
 * 
 * @param in_act_id			Access token
 * @param in_sheet_id		Sheet id
 * @return 					a T_SHEET_INFO object
 */
FUNCTION GetSheetInfo(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_id				IN	security_pkg.T_SID_ID
) RETURN T_SHEET_INFO;

/**
 * GetMessages
 * 
 * @param in_act_id			Access token
 * @param in_sheet_id		The sheet id
 * @param out_cur			The rowset
 */
PROCEDURE GetMessages(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.sheet_id%TYPE,
	out_cur					OUT SYS_REFCURSOR
);


PROCEDURE SetVisibility(
	in_sheet_id				IN	sheet.sheet_id%TYPE,
	in_is_visible			IN	sheet.is_visible%TYPE
);

PROCEDURE GetSheetFileUploads(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.sheet_id%TYPE,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetValuesAndFilesAndIssues(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.sheet_id%TYPE,
	out_cur_vals			OUT SYS_REFCURSOR,
	out_cur_files			OUT SYS_REFCURSOR,
	out_cur_issues			OUT SYS_REFCURSOR,
	out_cur_var_expls		OUT SYS_REFCURSOR,
	out_cur_prev_values		OUT SYS_REFCURSOR
);

/**
 * GetValues
 * 
 * @param in_act_id			Access token
 * @param in_sheet_id		The sheet id
 * @param out_cur			The rowset
 */
PROCEDURE GetValues(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.sheet_id%TYPE,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetVarExpl(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.sheet_id%TYPE,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetValuesSingleFile(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.sheet_id%TYPE,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetValueNoteAndFiles(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	sheet_value.sheet_id%TYPE,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur_val				OUT SYS_REFCURSOR,
	out_cur_files			OUT SYS_REFCURSOR
);

PROCEDURE GetValueNote(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	sheet_value.sheet_id%TYPE,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur_val				OUT SYS_REFCURSOR
);

PROCEDURE GetValueFileUploads(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	sheet_value.sheet_id%TYPE,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur_files			OUT SYS_REFCURSOR
);

PROCEDURE AddFileUpload(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_value_id		IN	sheet_value.sheet_value_id%TYPE,
	in_file_upload_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE AddFileUpload(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid				IN 	security_pkg.T_SID_ID,
	in_region_sid			IN 	security_pkg.T_SID_ID,
	in_file_upload_sid		IN	security_pkg.T_SID_ID,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	out_file_upload_sid 	OUT security_pkg.T_SID_ID
);

PROCEDURE AddFileUpload(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_value_id		IN	sheet_value.sheet_value_id%TYPE,
	in_file_upload_sid		IN	security_pkg.T_SID_ID,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	out_file_upload_sid 	OUT security_pkg.T_SID_ID
);

PROCEDURE RemoveFileUpload(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid				IN 	security_pkg.T_SID_ID,
	in_region_sid			IN 	security_pkg.T_SID_ID,
	in_file_upload_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE RemoveFileUpload (
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_value_id		IN	sheet_value.sheet_value_id%TYPE,
	in_file_upload_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE RemoveAllFileUploads (
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_value_id		IN	sheet_value.sheet_value_id%TYPE
);

/**
 * GetPreviousValues
 * 
 * @param in_act_id			Access token
 * @param in_sheet_id		The sheet id
 * @param out_cur			The rowset
 */
PROCEDURE GetPreviousValues(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.sheet_id%TYPE,
	out_cur					OUT SYS_REFCURSOR
);



/**
 * Returns a list of things that will block submission of the sheet
 * 
 * @param in_sheet_id		The sheet id
 * @param out_cur			The rowset
 */
PROCEDURE GetBlockers(
	in_sheet_id			IN 	SHEET.SHEET_ID%TYPE,
    out_cur				OUT	SYS_REFCURSOR
);


/**
 * GetDelegationFromSheetId
 * 
 * @param in_sheet_id		The sheet id
 * @param out_cur			The rowset
 */
PROCEDURE GetDelegationFromSheetId(
	in_sheet_id		IN  sheet.sheet_id%TYPE,
	out_cur			OUT	SYS_REFCURSOR
);


/**
 * GetParentSheetId
 * 
 * @param in_sheet_id		.
 */
FUNCTION GetParentSheetId(
	in_sheet_id		IN	csr_data_pkg.T_SHEET_ID
) RETURN csr_data_pkg.T_SHEET_ID;

/**
 * GetParentSheetIdSameDate
 * 
 * @param in_sheet_id		.
 */
FUNCTION GetParentSheetIdSameDate(
	in_sheet_id		IN	csr_data_pkg.T_SHEET_ID
) RETURN csr_data_pkg.T_SHEET_ID;


FUNCTION GetSheetId(
	in_delegation_sid	security_pkg.T_SID_ID,
	in_start_dtm		sheet.start_dtm%TYPE,
	in_end_dtm			sheet.end_dtm%TYPE
) RETURN csr_data_pkg.T_SHEET_ID;




-- ===================
-- Change sheet status
-- ===================

/**
 * Accept
 * 
 * @param in_act_id			Access token
 * @param in_sheet_id		.
 * @param in_note			.
 */
PROCEDURE Accept(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_id				IN	security_pkg.t_sid_id,
	in_note					IN	SHEET_HISTORY.NOTE%TYPE,
	in_skip_check			IN	NUMBER DEFAULT 0 -- new 'sheet2' delegations do checks themselves because of conditionals...
);


PROCEDURE ActionChangeRequest(
	in_sheet_change_req_id  IN	sheet_change_req.sheet_change_req_id%TYPE,
	in_is_approved			IN	sheet_change_req.is_approved%TYPE,
	in_note					IN	sheet_change_req.processed_note%TYPE,
	in_is_system_note		IN	sheet_history.is_system_note%TYPE DEFAULT 0
);

PROCEDURE ChangeRequest(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_id				IN	security_pkg.t_sid_id,
	in_note					IN	SHEET_HISTORY.NOTE%TYPE
);

-- a delegee wants to submit data
/**
 * Submit
 * 
 * @param in_act_id			Access token
 * @param in_sheet_id		.
 * @param in_note			.
 */
PROCEDURE Submit(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_id				IN	security_pkg.t_sid_id,
	in_note					IN	SHEET_HISTORY.NOTE%TYPE,
	in_skip_check			IN	NUMBER DEFAULT 0 -- new 'sheet2' delegations do checks themselves because of conditionals...
);

-- delegator is sending data back for more tweaks
/**
 * ReturnToDelegees
 * 
 * @param in_act_id			Access token
 * @param in_sheet_id		.
 * @param in_note			.
 * @param in_is_system		1 if automated by system bypassing user sheet permissions.
 */
PROCEDURE ReturnToDelegees(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_id				IN	security_pkg.t_sid_id,
	in_note					IN	SHEET_HISTORY.NOTE%TYPE,
	in_is_system			IN	NUMBER DEFAULT 0
);

/**
 * (Unsecured) Merge data at the lowest level of the delegation chain possible (only made impossible
 * if edits are made at a higher level). THIS IS UNSECURED - CALL MergeLowest instead
 * unless you are doing all security checks yourself. Also note that this doesn't
 * write to the sheet history table -- see MergeLowest for what it does.
 * 
 * @param in_act_id					Access token
 * @param in_sheet_id				The top level sheet to merge
 * @param in_note					A note about the merge
 */
PROCEDURE UNSEC_MergeLowest(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_id				IN	security_pkg.t_sid_id,
	in_note					IN	SHEET_HISTORY.NOTE%TYPE
);

/**
 * Merge data at the lowest level of the delegation chain possible (only made impossible
 * if edits are made at a higher level).
 * 
 * @param in_act_id					Access token
 * @param in_sheet_id				The top level sheet to merge
 * @param in_note					A note about the merge
 * @param in_provisional_data		Flag set if the merge is provisional
 */
PROCEDURE MergeLowest(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_id				IN	security_pkg.t_sid_id,
	in_note					IN	SHEET_HISTORY.NOTE%TYPE,
	in_provisional_data		IN	NUMBER DEFAULT 0,
	in_skip_check			IN	NUMBER DEFAULT 0
);

PROCEDURE MakeEditable(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_sheet_id		IN	sheet.sheet_id%TYPE,
	in_message		IN	sheet_history.note%TYPE
);

/**
 * Write a history row for the sheet
 * 
 * @param in_sheet_id				The sheet id
 * @param in_operation_id			The new sheet_action_id
 * @param in_user_from				Sid of user who has made this change
 * @param in_to_delegation_sid		The delegation sid for the sheet
 * @param in_note					Note explaining the change
 */
PROCEDURE CreateHistory(
	in_sheet_id				IN	sheet.SHEET_ID%TYPE,
	in_operation_id			IN	SHEET_HISTORY.SHEET_ACTION_ID%TYPE,
	in_user_from			IN	security_pkg.T_SID_ID,
	in_to_delegation_sid	IN	security_pkg.T_SID_ID,
	in_note					IN	sheet_history.NOTE%TYPE,
	in_is_system_note		IN	sheet_history.IS_SYSTEM_NOTE%TYPE DEFAULT 0
);

/**
 * Rollback
 * 
 * @param in_act_id				Access token
 * @param in_sheet_id			The sheet id
 * @param in_sheet_action_id	The sheet action id to move to
 */
PROCEDURE RollbackHistory(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.sheet_id%TYPE,
	in_sheet_action_id		IN	SHEET_ACTION.sheet_action_id%TYPE
);


/**
 * Utility function for use by PostMerge handlers to write a cursor to the Val table
 *
 * @param	Access token
 * @param	Input rowset -- ind_sid, region_sid, start_dtm, end_dtm, val
 */
PROCEDURE WriteCursorToVal(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_cur				IN	SYS_REFCURSOR
);

/**
 * Utility function for use by PostSubmit handlers to write a cursor to a sheet
 *
 * @param	Access token
 * @param	Delegation Sid
 * @param	Start date of sheet
 * @param	End date of sheet
 * @param	Input rowset -- ind_sid, region_sid, start_dtm, end_dtm, val
 */
PROCEDURE WriteCursorToSheet(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	delegation.start_dtm%TYPE,
	in_end_dtm			IN	delegation.end_dtm%TYPE,
	in_cur				IN	SYS_REFCURSOR
);

/** 
 * Get sheet reminders to be sent
 *
 * @param out_cur				Reminder details
 */
PROCEDURE GetReminderAlerts(
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Mark the sheet/user has having had a reminder sent
 * 
 * @param in_sheet_id		The sheet
 * @param in_user_sid		The user
 */
PROCEDURE RecordReminderSent(
	in_sheet_id						IN	sheet_alert.sheet_id%TYPE,
	in_user_sid						IN	sheet_alert.user_sid%TYPE
);

/** 
 * Get sheet overdue notifications to be sent
 *
 * @param out_cur				Reminder details
 */
PROCEDURE GetOverdueAlerts(
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Mark the sheet/user has having had an overdue notification sent
 * 
 * @param in_sheet_id		The sheet
 * @param in_user_sid		The user
 */
PROCEDURE RecordOverdueSent(
	in_sheet_id						IN	sheet_alert.sheet_id%TYPE,
	in_user_sid						IN	sheet_alert.user_sid%TYPE
);

/** 
 * Get sheet edited alerts to be sent
 *
 * @param out_cur				Alert details
 */
PROCEDURE GetSheetEditedAlerts(
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Mark the sheet/user as having had a reminder sent
 * 
 * @param in_sheet_id		The sheet
 * @param in_user_sid		The user
 */
PROCEDURE RecordSheetEditedAlertSent(
	in_alert_id						IN	delegation_edited_alert.delegation_edit_alert_id%TYPE,
	in_user_sid						IN	delegation_edited_alert.notify_user_sid%TYPE
);




-- ===========
-- DataSources
-- ===========

/**
 * ClearDataSources
 * 
 * @param in_act_id				Access token
 * @param in_sheet_value_id		.
 */
PROCEDURE ClearDataSources(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_sheet_value_id	IN	SHEET_VALUE.SHEET_VALUE_ID%TYPE
);

/**
 * AddDataSource
 * 
 * @param in_act_id				Access token
 * @param in_sheet_value_id		.
 * @param in_accuracy_type_option_id		.
 * @param in_pct				.
 */
PROCEDURE AddDataSource(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_sheet_value_id	IN	SHEET_VALUE.SHEET_VALUE_ID%TYPE,
	in_accuracy_type_option_id	IN	accuracy_type_option.accuracy_type_option_id%TYPE,
	in_pct				IN	sheet_value_accuracy.pct%TYPE
);

/**
 * GetDataSources
 * 
 * @param in_act_id			Access token
 * @param in_sheet_id		.
 * @param out_cur			The rowset
 */
PROCEDURE GetDataSources(
	in_act_id		IN  security_pkg.T_ACT_ID,
	in_sheet_id		IN	SHEET.SHEET_ID%TYPE,
    out_cur			OUT	SYS_REFCURSOR
);


PROCEDURE GetDataSources(
	in_act_id		IN  security_pkg.T_ACT_ID,
	in_sheet_id		IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid		IN	security_pkg.T_SID_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
    out_cur_q		OUT	SYS_REFCURSOR,
    out_cur_c		OUT	SYS_REFCURSOR
);

PROCEDURE GetIndicatorAccuracyTypes(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_ind_sid		IN	security_pkg.T_SID_ID,
	out_cur_q		OUT	SYS_REFCURSOR,
    out_cur_c		OUT	SYS_REFCURSOR
);

FUNCTION GetOrSetSheetValueId(
	in_sheet_id				IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid				IN 	security_pkg.T_SID_ID,
	in_region_sid			IN 	security_pkg.T_SID_ID
) RETURN sheet_value.sheet_value_Id%TYPE;

/**
 * PropagateValuesToParentSheet
 * 
 * @param in_act_id			Access token
 * @param in_sheet_id		.
 */
PROCEDURE PropagateValuesToParentSheet(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET_VALUE.SHEET_VALUE_ID%TYPE
);

/**
 * CopyValuesFromParentSheet
 * 
 * @param in_act_id			Access token
 * @param in_sheet_id		Child sheet id
 */
PROCEDURE CopyValuesFromParentSheet(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET_VALUE.SHEET_VALUE_ID%TYPE
);

/**
 * Moves a file from the file upload table, and creates
 * a FileUpload object for it under the parent delegation.
 * 
 * @param in_act_id					Access token
 * @param in_sheet_id				The sheet id
 * @param in_cache_key				File upload cache key
 * @param out_file_upload_sid		The sid of the new file upload object
 */
PROCEDURE CreateFileUploadFromCache(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_sheet_id			IN  security_pkg.T_SID_ID,
	in_cache_key		IN  VARCHAR2,
	out_file_upload_sid OUT security_pkg.T_SID_ID
);

PROCEDURE UNSEC_SetVarExpl(
	in_sheet_value_id		IN	SHEET_VALUE.sheet_value_id%TYPE,
	in_var_expl_ids			IN	security_pkg.T_SID_IDS,
	in_var_expl_note		IN	sheet_value.var_expl_note%TYPE
);

/**
 * Returns a list of calculations that need to be carried out
 * based on an indicator that has changed on a sheet.
 * 
 * @param in_act_id			Access token
 * @param in_sheet_id		The sheet id
 * @param in_ind_sid		The sid of the object
 * @param out_cur			The rowset
 */
PROCEDURE GetCalculationsToRecalculate(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_sheet_id			IN	sheet.sheet_id%TYPE,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

/**
 * GetSheetIdForSheetValueId
 * 
 * @param in_sheet_value_id		.
 * @return 						.
 */
FUNCTION GetSheetIdForSheetValueId(
	in_sheet_value_id				IN	SHEET_VALUE.SHEET_VALUE_ID%TYPE
) RETURN SHEET.SHEET_ID%TYPE;

/**
 * GetSheetValueId
 * 
 * @param in_sheet_id		The sheet id
 * @param in_ind_sid		The sid of the indicator
 * @param in_region_sid		The sid of the region
 * @return 					.
 */
FUNCTION GetSheetValueId(
	in_sheet_id				IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid				IN	security_pkg.t_sid_id,
	in_region_sid			IN	security_pkg.t_sid_id
) RETURN SHEET_VALUE.SHEET_VALUE_ID%TYPE;


PROCEDURE GetValues(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_region_list		IN	VARCHAR2,
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE,
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE internal_GetRawBaseValues(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE
);

PROCEDURE GetRawBaseValues(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE,
	out_cur				OUT SYS_REFCURSOR
);

-- this gets values regardless of whether or not you
-- can see the delegations involved
PROCEDURE GetAnyRawBaseValues(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE,
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE UNSECURED_SetAlert(
    in_alert            IN  sheet_value.alert%TYPE,
    in_sheet_value_id   IN  sheet_value.sheet_value_id%TYPE
);

PROCEDURE GetNoteForSheetValue(
    in_sheet_value_id    IN    sheet_value.sheet_value_Id%TYPE,
    out_cur              OUT   SYS_REFCURSOR 
);

PROCEDURE UNSEC_GetIndsToRecalculate(
	in_delegation_sid				IN		sheet.delegation_sid%TYPE,
	in_ind_sids						IN		security_pkg.T_SID_IDS,
	out_cur							OUT		SYS_REFCURSOR
);

-- This mirrors a similar function in pending_pkg
FUNCTION GetSheetQueryString(
	in_app_sid						IN	customer.app_sid%TYPE,
    in_ind_sid						IN	security_pkg.T_SID_ID,
    in_region_sid					IN	security_pkg.T_SID_ID,
    in_start_dtm					IN	sheet.start_dtm%TYPE,
    in_end_dtm						IN	sheet.end_dtm%TYPE,
    in_user_sid 					IN	security_pkg.T_SID_ID
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(GetSheetQueryString, WNDS, WNPS);

FUNCTION GetSheetQueryString(
    in_ind_sid       IN	security_pkg.T_SID_ID,
    in_region_sid    IN	security_pkg.T_SID_ID,
    in_start_dtm     IN	sheet.start_dtm%TYPE,
    in_end_dtm		 IN sheet.end_dtm%TYPE,
    in_user_sid      IN	security_pkg.T_SID_ID
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(GetSheetQueryString, WNDS, WNPS);

/**
 * Copy merged values from the previous period onto the given sheet
 *
 * @param in_sheet_id		The sheet to copy to
 * @param out_cnt			The numbers of values copied
 */
PROCEDURE CopyForward(
	in_sheet_id				IN	sheet.sheet_id%TYPE,
	out_cnt					OUT	NUMBER
);

/**
 * Mark a sheet as "copied forward". This will prevent future attempts 
 * to copy forward.
 *
 * @param in_sheet_id		The sheet to mark 
 */
PROCEDURE MarkAsCopiedForward(
	in_sheet_id				IN	sheet.sheet_id%TYPE
);

/**
 * Copy merged values from the current period onto the given sheet
 *
 * @param in_sheet_id		The sheet to copy to
 * @param out_cnt			The numbers of values copied
 */
PROCEDURE CopyCurrent(
	in_sheet_id				IN	sheet.sheet_id%TYPE,
	out_cnt					OUT	NUMBER
);


/**
 * Figure out which grids need cloning when cloning a sheet
 *
 * @param in_sheet_id		The sheet to copy to
 * @param out_cnt			The stuff to clone
 */
PROCEDURE GetGridsToClone(
	in_sheet_id		IN	sheet.sheet_id%TYPE,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE SetPostIt(
	in_sheet_Id		IN	sheet.sheet_id%TYPE,
	in_postit_id	IN	postit.postit_id%TYPE,
	out_postit_id	OUT	postit.postit_id%TYPE
);


PROCEDURE GetPostIts(
	in_sheet_id		IN	sheet.sheet_id%TYPE,
	out_cur			OUT	SYS_REFCURSOR,
	out_cur_files	OUT	SYS_REFCURSOR
);

/**
 * Send a notification of a new sheet to the users assigned to the sheet
 *
 * @param in_sheet_id		The sheet to send the alerts for
 */
PROCEDURE RaiseNewSheetAlert(
	in_sheet_id						IN	sheet.sheet_id%TYPE
);

/**
 * Raise a sheet changed alert for the given sheet
 *
 * @param in_sheet_id				The sheet to raise alerts for
 * @param in_alert_to				csr_data_pkg.ALERT_TO_DELEGATOR or csr_data_pkg.ALERT_TO_DELEGEE
 */
PROCEDURE RaiseSheetChangeAlert(
	in_sheet_id						IN	sheet.sheet_id%TYPE,
	in_alert_to						IN	NUMBER
);

/**
 * Raise a sheet edited alert for the given sheet
 *
 * @param in_sheet_id				The sheet to raise alerts for
 */
PROCEDURE RaiseSheetEditedAlert(
	in_sheet_id			IN	sheet.sheet_id%TYPE,
	in_user_sid 		IN	security_pkg.T_SID_ID
);

/**
 * Raise a sheet Data changed alert for the given sheet
 *
 * @param in_sheet_id				The sheet to raise alerts for
 */
PROCEDURE RaiseSheetDataChangeAlert(
	in_sheet_id			IN	sheet.sheet_id%TYPE
);

/**
 * Raise a sheet data changed alert for the given sheets
 *
 * @param in_sheet_ids				The sheets to raise alerts for
 */
PROCEDURE RaiseSheetDataChangeAlerts(
	in_sheet_ids					IN	security_pkg.T_SID_IDS
);

/**
 * Send a notification of an updated sheet from a plan to the users assigned to the sheet
 *
 * @param in_sheet_id		The sheet to send the alerts for
 */
PROCEDURE RaisePlanSheetUpdatedAlert(
	in_sheet_id						IN	sheet.sheet_id%TYPE
);

/**
 * Send a notification of a new sheet from a plan to the users assigned to the sheet
 *
 * @param in_sheet_id		The sheet to send the alerts for
 */
PROCEDURE RaisePlanSheetNewAlert(
	in_sheet_id						IN	sheet.sheet_id%TYPE
);


/**
 * Get change requests for the sheet
 *
 * @param in_sheet_id		The sheet to raise alerts for
 * @param out_cur			Rowset		
 */
PROCEDURE GetChangeRequests(
	in_sheet_id		IN	sheet.sheet_id%TYPE,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetChangedValuesSinceReSub(
	in_sheet_id		IN	sheet.sheet_id%TYPE,
	out_cur			OUT	SYS_REFCURSOR
);

/**
 * Get a list of values edited since the sheet was last submitted
 *
 * @param in_sheet_id		The sheet id to check
 * @param out_cur			Rowset
 */
PROCEDURE GetEditedValuesSinceSub(
	in_sheet_id		IN	sheet.sheet_id%TYPE,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetValueChanges(
	in_sheet_id		IN	sheet.sheet_id%TYPE,
	in_ind_sid		IN	security_pkg.T_SID_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_order_dir	IN	NUMBER,
	out_cur			OUT	SYS_REFCURSOR
);

/**
* Return if an indicator is used in a Sheet Value
* Used in indicator_pkg.IsIndicatorUsed
*/ 
FUNCTION IsIndicatorUsed(
	in_ind_sid	IN	security_pkg.T_SID_ID	
)
RETURN BOOLEAN;

PROCEDURE GetSheetExportValues(
	in_start_dtm					IN	sheet.start_dtm%TYPE,
	in_end_dtm						IN	sheet.end_dtm%TYPE,
	in_all_values					IN	NUMBER,
	in_values_with_notes			IN	NUMBER,
	in_values_with_files			IN	NUMBER,
	in_values_with_var_expl			IN	NUMBER,
	out_val_cur						OUT	SYS_REFCURSOR,
	out_file_cur					OUT	SYS_REFCURSOR,
	out_var_expl_cur				OUT	SYS_REFCURSOR
);

PROCEDURE SetReadOnly(
	in_sheet_id				IN	sheet.sheet_id%TYPE,
	in_is_read_only			IN	sheet.is_read_only%TYPE
);

FUNCTION SheetIsReadOnly(
	in_sheet_id			IN	sheet.sheet_id%TYPE
) 
RETURN BOOLEAN;

PROCEDURE SetCompleteness(
	in_sheet_id			IN	sheet.sheet_id%TYPE,
	in_percent_complete	IN	sheet.percent_complete%TYPE
);

PROCEDURE GetAnnualSummarySheets(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_sheet_id			IN	csr_data_pkg.T_SHEET_ID,
	out_cur				OUT	SYS_REFCURSOR
);

FUNCTION GetLastParentSheetAction (
	in_sheet_id IN VARCHAR2
) RETURN NUMBER;

PROCEDURE GetActiveSheetAndLevel(
	in_sheet_id				IN	sheet.sheet_id%TYPE,
	out_sheet_id			OUT sheet.sheet_id%TYPE,
	out_action_id			OUT sheet_action.sheet_action_id%TYPE,
	out_level				OUT	NUMBER
);

FUNCTION GetMaxDelegationLevel(
	in_delegation_sid		IN	delegation.delegation_sid%TYPE
) RETURN NUMBER;

FUNCTION GetBottomDelegationId(
	in_delegation_sid		IN	delegation.delegation_sid%TYPE
) RETURN NUMBER;
PRAGMA RESTRICT_REFERENCES(GetBottomDelegationId, WNDS, WNPS);

FUNCTION GetBottomSheetQueryString(
    in_ind_sid						IN	security_pkg.T_SID_ID,
    in_region_sid					IN	security_pkg.T_SID_ID,
    in_start_dtm					IN	sheet.start_dtm%TYPE,
    in_end_dtm						IN	sheet.end_dtm%TYPE,
    in_user_sid 					IN	security_pkg.T_SID_ID
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(GetBottomSheetQueryString, WNDS, WNPS);

PROCEDURE GetFilesForSheets(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_ids			IN	security_pkg.T_SID_IDS,
	out_cur					OUT	SYS_REFCURSOR,
	out_cur_postit			OUT SYS_REFCURSOR
);

PROCEDURE CountSheetsForIndRegPer(
	in_ind_sid				IN	delegation_ind.ind_sid%TYPE,
	in_region_sid			IN	delegation_region.region_sid%TYPE,
	in_start_dtm			IN	sheet.start_dtm%TYPE,
	in_end_dtm				IN	sheet.end_dtm%TYPE,
	out_sheet_count			OUT	NUMBER
);

PROCEDURE AddCompletenessJobs(
	in_sheet_ids					IN	security_pkg.T_SID_IDS
);

PROCEDURE QueueCompletenessJobs;

PROCEDURE GetCompletenessSheets(
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE RemoveSheetCompletenessJob(
	in_sheet_id				IN	sheet.sheet_id%TYPE
);

PROCEDURE GetOverdueSheetInfo(
	in_sheet_id				IN	sheet.sheet_id%TYPE,
	out_sheet_cur			OUT	SYS_REFCURSOR,
	out_child_sheet_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetSheetCreatedAlerts(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE RaiseSheetCreatedAlert(
	in_sheet_id						IN	sheet.sheet_id%TYPE
);

PROCEDURE RecordSheetCreatedAlertSent(
	in_alert_id						IN	delegation_edited_alert.delegation_edit_alert_id%TYPE,
	in_user_sid						IN	delegation_edited_alert.notify_user_sid%TYPE
);

END;
/
