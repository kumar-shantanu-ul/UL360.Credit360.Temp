CREATE OR REPLACE PACKAGE CSR.Form_Pkg AS

-- Securable object callbacks

/**
 * CreateObject
 *
 * @param in_act_id				Access token
 * @param in_sid_id				The sid of the object
 * @param in_class_id			The class Id of the object
 * @param in_name				The name
 * @param in_parent_sid_id		The sid of the parent object
 */
PROCEDURE CreateObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_class_id						IN	security_pkg.T_CLASS_ID,
	in_name							IN	security_pkg.T_SO_NAME,
	in_parent_sid_id				IN	security_pkg.T_SID_ID
);

/**
 * RenameObject
 *
 * @param in_act_id			Access token
 * @param in_sid_id			The sid of the object
 * @param in_new_name		The name
 */
PROCEDURE RenameObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_name						IN	security_pkg.T_SO_NAME
);

/**
 * DeleteObject
 *
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 */
PROCEDURE DeleteObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID
);

/**
 * MoveObject
 *
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 * @param in_new_parent_sid_id		.
 */
PROCEDURE MoveObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN	security_pkg.T_SID_ID,
	in_old_parent_sid_id			IN security_pkg.T_SID_ID
);

/**
 * TrashObject
 *
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 */
PROCEDURE TrashObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN  security_pkg.T_SID_ID
);

/**
 * CreateForm
 *
 * @param in_act_id				Access token
 * @param in_parent_sid			The sid of the parent object
 * @param in_app_sid			The sid of the application
 * @param in_name				The name
 * @param in_start_dtm			The start date
 * @param in_end_dtm			The end date
 * @param in_period_set_id		The period set
 * @param in_period_interval_id	The period interval (m|q|h|y)
 * @param in_note				A note for the form
 * @param in_group_by			Display order for the form
 * @param in_tab_direction		Direction for the TAB key to move the data entry cell in
 * @param out_form_sid_id		The sid of the created form
 */
PROCEDURE CreateForm(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_app_sid 						IN	security_pkg.T_SID_ID,
	in_name							IN	form.name%TYPE,
	in_start_dtm					IN	form.start_dtm%TYPE,
	in_end_dtm						IN	form.end_dtm%TYPE,
	in_period_set_id				IN	form.period_set_id%TYPE,
	in_period_interval_id			IN	form.period_interval_id%TYPE,
	in_note							IN	form.note%TYPE,
	in_group_by						IN	form.group_by%TYPE,
	in_tab_direction				IN	form.tab_direction%TYPE,
	out_form_sid_id					OUT	security_pkg.T_SID_ID
);

/**
 * AmendForm
 *
 * @param in_act_id				Access token
 * @param in_form_sid			The sid of the form to amend
 * @param in_app_sid			The sid of the application
 * @param in_name				The name
 * @param in_start_dtm			The start date
 * @param in_end_dtm			The end date
 * @param in_period_set_id		The period set
 * @param in_period_interval_id	The period interval (m|q|h|y)
 * @param in_note				A note for the form
 * @param in_group_by			Display order for the form
 * @param in_tab_direction		Direction for the TAB key to move the data entry cell in
 */
PROCEDURE AmendForm(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_form_sid						IN	security_pkg.T_SID_ID,
	in_name							IN	form.name%TYPE,
	in_start_dtm					IN	form.start_dtm%TYPE,
	in_end_dtm						IN	form.end_dtm%TYPE,
	in_period_set_id				IN	form.period_set_id%TYPE,
	in_period_interval_id			IN	form.period_interval_id%TYPE,
	in_note							IN	form.note%TYPE,
	in_group_by						IN	form.group_by%TYPE,
	in_tab_direction				IN	form.tab_direction%TYPE
);


/**
 * CopyForm
 *
 * @param in_act_id				Access token
 * @param in_form_sid			.
 * @param out_new_form_sid		.
 */
PROCEDURE CopyForm(
	in_act_id 						IN	security_pkg.T_ACT_ID,
	in_form_sid						IN	security_pkg.T_SID_ID,
	out_new_form_sid				OUT	security_pkg.T_SID_ID
);

/**
 * SetIndicators
 *
 * @param in_act_id				Access token
 * @param in_form_sid			.
 * @param in_indicator_list		.
 */
PROCEDURE SetIndicators(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_form_sid						IN	security_pkg.T_SID_ID,
	in_indicator_list				IN	VARCHAR2
);

/**
 * SetRegions
 *
 * @param in_act_id			Access token
 * @param in_form_sid		.
 * @param in_region_list	.
 */
PROCEDURE SetRegions(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_form_sid						IN	security_pkg.T_SID_ID,
	in_region_list					IN	VARCHAR2
);

/**
 * Set details for an indicator on the form
 *
 * @param in_act_id					The access token
 * @param in_form_sid				The form
 * @param in_ind_sid				The indicator
 * @param in_description			The indicator description
 * @param in_format_mask			The indicator form mask
 * @param in_scale					The indicator scale
 * @param in_measure_description	The indicator's measure description
 */
PROCEDURE AmendIndicator(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_form_sid				IN security_pkg.T_SID_ID,
	in_ind_sid				IN security_pkg.T_SID_ID,
	in_description			IN VARCHAR2,
	in_format_mask			IN ind.format_mask%TYPE,
	in_scale				IN ind.scale%TYPE,
	in_measure_description	IN measure.description%TYPE
);

/**
 * Set details for a region on the form
 *
 * @param in_act_id					The access token
 * @param in_form_sid				The form
 * @param in_region_sid				The region
 * @param in_description			The region description
 */
PROCEDURE AmendRegion(
	in_act_id		IN security_pkg.T_ACT_ID,
	in_form_sid		IN security_pkg.T_SID_ID,
	in_region_sid	IN security_pkg.T_SID_ID,
	in_description	IN VARCHAR2
);

/**
 * SetAllocateUsersTo
 *
 * @param in_act_id					Access token
 * @param in_form_sid				.
 * @param in_allocate_users_to		.
 */
PROCEDURE SetAllocateUsersTo(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_form_sid						IN 	security_pkg.T_SID_ID,
	in_allocate_users_to			IN	form.allocate_users_to%TYPE
);

/**
 * GetForm
 *
 * @param in_act_id			Access token
 * @param in_form_sid		.
 * @param out_cur			The rowset
 */
PROCEDURE GetForm(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_form_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * Get regions on the given form
 * 
 * @param in_act_id			Access token
 * @param in_form_sid		The form
 * @param out_cur			The regions
 */
PROCEDURE GetRegions(
	in_act_id		IN 	security_pkg.T_ACT_ID,
	in_form_sid		IN 	security_pkg.T_SID_ID,
	out_cur			OUT SYS_REFCURSOR
);

/**
 * Get indicators on the given form
 * 
 * @param in_act_id			Access token
 * @param in_form_sid		The form
 * @param out_cur			The indicators
 */
PROCEDURE GetIndicators(
	in_act_id		IN 	security_pkg.T_ACT_ID,
	in_form_sid		IN 	security_pkg.T_SID_ID,
	out_cur			OUT SYS_REFCURSOR
);

/**
 * GetFormsList
 *
 * @param in_act_id			Access token
 * @param in_parent_sid		The sid of the parent object
 * @param in_order_by		.
 * @param out_cur			The rowset
 */
PROCEDURE GetFormsList(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_order_by						IN	VARCHAR2,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * ConcatFormAllocationUsers
 *
 * @param in_form_allocation_id		.
 * @return 							.
 */
FUNCTION ConcatFormAllocationUsers(
	in_form_allocation_id			IN	security_pkg.T_SID_ID
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(ConcatFormAllocationUsers, WNDS, WNPS);

/**
 * ConcatFormAllocationRegions
 *
 * @param in_form_allocation_id		.
 * @return 							.
 */
FUNCTION ConcatFormAllocationRegions(
	in_form_allocation_id			IN	security_pkg.T_SID_ID
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(ConcatFormAllocationRegions, WNDS, WNPS);

/**
 * ConcatFormAllocationIndicators
 *
 * @param in_form_allocation_id		.
 * @return 							.
 */
FUNCTION ConcatFormAllocationIndicators(
	in_form_allocation_id			IN	security_pkg.T_SID_ID
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(ConcatFormAllocationIndicators, WNDS, WNPS);

/**
 * GetFormAllocationList
 *
 * @param in_act_id			Access token
 * @param in_form_sid		.
 * @param in_order_by		.
 * @param out_cur			The rowset
 */
PROCEDURE GetFormAllocationList(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_form_sid						IN	security_pkg.T_SID_ID,
	in_order_by						IN	VARCHAR2,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * GetUnallocatedFormItems
 *
 * @param in_act_id			Access token
 * @param in_form_sid		.
 * @param out_cur			The rowset
 */
PROCEDURE GetUnallocatedFormItems(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_form_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * GetAllocatedFormItems
 *
 * @param in_act_id					Access token
 * @param in_form_sid				.
 * @param in_form_allocation_id		.
 * @param out_cur					The rowset
 */
PROCEDURE GetAllocatedFormItems(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_form_sid						IN	security_pkg.T_SID_ID,
	in_form_allocation_id			IN	FORM_ALLOCATION.form_allocation_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * GetAllocatedFormUsers
 *
 * @param in_act_id					Access token
 * @param in_form_sid				.
 * @param in_form_allocation_id		.
 * @param out_cur					The rowset
 */
PROCEDURE GetAllocatedFormUsers(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_form_sid						IN	security_pkg.T_SID_ID,
	in_form_allocation_id			IN	FORM_ALLOCATION.form_allocation_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * SetFormAllocation
 *
 * @param in_act_id					Access token
 * @param in_form_sid				.
 * @param in_form_allocation_id		.
 * @param in_user_list				.
 * @param in_item_list				.
 */
PROCEDURE SetFormAllocation(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_form_sid						IN security_pkg.T_SID_ID,
	in_form_allocation_id			IN FORM_ALLOCATION.FORM_ALLOCATION_ID%TYPE,
	in_user_list					IN VARCHAR2,
	in_item_list					IN VARCHAR2
);

/**
 * DeleteAllFormAllocations
 *
 * @param in_act_id			Access token
 * @param in_form_sid		.
 */
PROCEDURE DeleteAllFormAllocations(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_form_sid	 					IN  security_pkg.T_SID_ID
);

/**
 * DeleteFormAllocation
 *
 * @param in_act_id					Access token
 * @param in_form_sid				.
 * @param in_form_allocation_id		.
 */
PROCEDURE DeleteFormAllocation(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_form_sid	 					IN  security_pkg.T_SID_ID,
	in_form_allocation_id			IN	FORM_ALLOCATION.form_allocation_id%TYPE
);

/**
 * GetMyForms
 *
 * @param in_act_id				Access token
 * @param in_app_sid		The sid of the Application/CSR object
 * @param out_cur				The rowset
 */
PROCEDURE GetMyForms(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_app_sid						IN 	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * GetMyFormRegions
 *
 * @param in_act_id			Access token
 * @param in_form_sid		.
 * @param out_cur			The rowset
 */
PROCEDURE GetMyFormRegions(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_form_sid	 					IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * FilterMyFormRegions
 *
 * @param in_act_id			Access token
 * @param in_form_sid		.
 * @param in_filter			.
 * @param out_cur			The rowset
 */
PROCEDURE FilterMyFormRegions(
	in_form_sid	 					IN  security_pkg.T_SID_ID,
	in_filter						IN	VARCHAR2,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * GetMyFormMeasures
 *
 * @param in_act_id			Access token
 * @param in_form_sid		.
 * @param out_cur			The rowset
 */
PROCEDURE GetMyFormMeasures(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_form_sid	 					IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * GetMyFormIndicators
 *
 * @param in_act_id			Access token
 * @param in_form_sid		.
 * @param out_cur			The rowset
 */
PROCEDURE GetMyFormIndicators(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_form_sid	 					IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * GetMyFormValues
 *
 * @param in_act_id			Access token
 * @param in_form_sid		.
 * @param out_cur			The rowset
 */
PROCEDURE GetMyFormValues(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_form_sid	 					IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * GetMyFormNotes
 * 
 * @param in_act_id			Access token
 * @param in_form_sid		.
 * @param out_cur			The rowset
 */
PROCEDURE GetMyFormNotes( 
	in_act_id						IN 	security_pkg.T_ACT_ID,	 
	in_form_sid	 					IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * GetMyFormComments
 * 
 * @param in_act_id			Access token
 * @param in_form_sid		.
 * @param in_z_key			.
 * @param out_cur			The rowset
 */
PROCEDURE GetMyFormComments( 
	in_act_id						IN 	security_pkg.T_ACT_ID,	 
	in_form_sid	 					IN  security_pkg.T_SID_ID,
	in_z_key						IN	form_comment.z_key%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * SetFormComment
 * 
 * @param in_act_id					Access token
 * @param in_form_sid				.
 * @param in_z_key					.
 * @param in_form_allocation_id		.
 * @param in_form_comment			.
 */
PROCEDURE SetFormComment( 
	in_act_id						IN 	security_pkg.T_ACT_ID,	 
	in_form_sid	 					IN  security_pkg.T_SID_ID,
	in_z_key						IN	form_comment.z_key%TYPE,
	in_form_allocation_id			IN	form_comment.form_allocation_id%TYPE,
	in_form_comment					IN	form_comment.form_comment%TYPE
);

PROCEDURE GetGroups(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_parent_sid					IN 	security_pkg.T_ACT_ID,
	out_cur							OUT	SYS_REFCURSOR
);

END Form_Pkg;
/
