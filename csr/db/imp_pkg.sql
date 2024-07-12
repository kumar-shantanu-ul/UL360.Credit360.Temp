CREATE OR REPLACE PACKAGE CSR.Imp_Pkg AS

FUNCTION autoMapRegion(
	in_act				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	imp_session.app_sid%TYPE,
	in_description		IN	imp_region.description%TYPE
)
RETURN region.region_sid%TYPE;
/**
 * CreateObject helper
 * 
 * @param in_act_id				Access token
 * @param in_sid_id				The sid of the object
 * @param in_class_id			The class Id of the object
 * @param in_name				The name
 * @param in_parent_sid_id		The sid of the parent object
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
 * MoveObject
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
 * Create a new import session
 * 
 * @param in_act_id				Access token
 * @param in_parent_sid_id		The sid of the parent object
 * @param in_app_sid		The sid of the Application/CSR object
 * @param in_name				The name
 * @param in_file_path			.
 * @param out_sid_id			.
 */
PROCEDURE CreateImpSession(
	in_act_id 				IN security_pkg.T_ACT_ID, 
	in_parent_sid_id 		IN security_pkg.T_SID_ID,
	in_app_sid 		IN security_pkg.T_SID_ID,
	in_name 				IN IMP_SESSION.NAME%TYPE,
	in_file_path 			IN IMP_SESSION.file_path%TYPE,
	out_sid_id				OUT security_pkg.T_SID_ID
);


/**
 * Looks for a pending import parse job and if there is one, this
 * marks the parse job as started and returns an output 
 * cursor containing details.
 * 	
 * @param in_act_id				Access token
 * @param in_imp_session_sid	The Import Session sid
 * @param out_cur				The rowset
 *
 * The output rowset IS OF THE FORM:
 * imp_session_sid, file_path, name
 */
PROCEDURE GetAndStartParseJob(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_imp_session_sid		IN imp_session.imp_session_sid%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);	

/**
 * Marks the importSession parse job as started 
 
 * @param in_act_id				Access token
 * @param in_imp_session_sid	The Import Session sid
 */
PROCEDURE StartParseJob(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_imp_session_sid		IN imp_session.imp_session_sid%TYPE
);

/**
 * Called by val_pkg.setValue to allow us to unhook anything
 * e.g. if we keep a pointer to a val_id
 * 	
 * @param in_val_id				The Val Id being changed
 * @param in_imp_val_Id			The Imp Val Id
 */ 
PROCEDURE OnValChange(
	in_val_id		IN imp_val.set_val_id%TYPE,
	in_imp_val_id	IN imp_val.imp_val_id%TYPE
);

/**
 * SynchImpMeasures
 * 
 * @param in_act_id				Access token
 * @param in_app_sid		The sid of the Application/CSR object
 */
PROCEDURE SynchImpMeasures(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID	
);


/**
 * Marks the parse as completed
 * 
 * @param in_act_id				Access token
 * @param in_imp_session_sid	.
 * @param in_result_code		.
 * @param in_message			.
 */
PROCEDURE MarkParseJobCompleted(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_imp_session_sid		IN security_pkg.T_SID_ID,
	in_result_code			IN IMP_SESSION.result_code%TYPE,
	in_message				IN IMP_SESSION.message%TYPE
);

/**
 * Return the list of import sessions
 * 
 * @param in_act_id			Access token
 * @param in_parent_sid		The sid of the parent object
 * @param in_order_by		Order by clause
 * @param out_cur			The rowset
 */
PROCEDURE GetSessionList(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_parent_sid	IN	security_pkg.T_SID_ID,	 
	in_order_by		IN	VARCHAR2,
	out_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPagedSessionList(
	in_parent_sid	IN	security_pkg.T_SID_ID,	 
	in_start		IN	NUMBER,
	in_page_size	IN	NUMBER,
	out_count		OUT NUMBER,
	out_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSession(
	in_imp_session_sid	IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

/**
 * AddValueUnsecured
 * 
 * @param in_imp_session_sid		The import session sid
 * @param in_app_sid			The sid of the Application/CSR object
 * @param in_ind_description		The indicator description
 * @param in_region_description		The region description
 * @param in_measure_description	The measure description
 * @param in_unknown				Any unknown text
 * @param in_start_dtm				The start date
 * @param in_end_dtm				The end date
 * @param in_val					The value number
 * @param in_file_sid				The Sid of the file being imported
 * @param out_imp_val_id			Returns the new imp_val_id
 */
PROCEDURE AddValueUnsecured(
	in_imp_session_sid		IN	security_pkg.T_SID_ID,	
	in_app_sid			IN	security_pkg.T_SID_ID,	 
	in_ind_description		IN	IMP_IND.description%TYPE,	 
	in_region_description	IN	IMP_REGION.description%TYPE,
	in_measure_description	IN	IMP_MEASURE.description%TYPE,
	in_unknown				IN 	IMP_VAL.unknown%TYPE,
	in_start_dtm			IN 	IMP_VAL.start_dtm%TYPE,
	in_end_dtm				IN 	IMP_VAL.end_dtm%TYPE,
	in_val					IN 	IMP_VAL.VAL%TYPE,
	in_note					IN 	IMP_VAL.NOTE%TYPE,
	in_file_sid				IN 	IMP_VAL.file_sid%TYPE,
	out_imp_val_id			OUT	IMP_VAL.imp_val_id%TYPE
);	

	
/**
 * AddValueUnsecured
 * 
 * @param in_imp_session_sid		The import session sid
 * @param in_app_sid			The sid of the Application/CSR object
 * @param in_ind_description		The imp indicator id
 * @param in_region_description		The imp region id
 * @param in_measure_description	The imp measure id
 * @param in_unknown				Any unknown text
 * @param in_start_dtm				The start date
 * @param in_end_dtm				The end date
 * @param in_val					The value number
 * @param in_file_sid				The Sid of the file being imported
 * @param out_imp_val_id			Returns the new imp_val_id
 */
PROCEDURE AddValueUnsecuredFromIds(
	in_imp_session_sid		IN	security_pkg.T_SID_ID,	
	in_app_sid				IN	security_pkg.T_SID_ID,	 
	in_imp_ind_id			IN	imp_ind.imp_ind_id%TYPE,	 
	in_imp_region_id		IN	imp_region.imp_region_id%TYPE,
	in_imp_measure_id		IN	imp_measure.imp_measure_id%TYPE,
	in_unknown				IN 	imp_val.unknown%TYPE,
	in_start_dtm			IN 	imp_val.start_dtm%TYPE,
	in_end_dtm				IN 	imp_val.end_dtm%TYPE,
	in_val					IN 	imp_val.val%TYPE,
	in_note					IN 	imp_val.note%TYPE,
	in_file_sid				IN 	imp_val.file_sid%TYPE,
	out_imp_val_id			OUT	imp_val.imp_val_id%TYPE
);

PROCEDURE CreateImpIndUnsec(	 
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_description			IN	imp_ind.description%TYPE,	
	out_imp_ind_id			OUT	imp_ind.imp_ind_id%TYPE
);

PROCEDURE CreateImpRegionUnsec(	
	in_app_sid					IN	security_pkg.T_SID_ID,	 
	in_description				IN	imp_region.description%TYPE,	
	out_imp_region_id			OUT	imp_region.imp_region_id%TYPE
);

PROCEDURE CreateImpMeasureUnsec(	
	in_app_sid					IN	security_pkg.T_SID_ID,	 
	in_description				IN	imp_measure.description%TYPE,	
	in_imp_ind_id				IN  imp_measure.imp_ind_id%TYPE,
	out_imp_measure_id			OUT	imp_measure.imp_measure_id%TYPE
);

/**
 * getSessionIndicators
 * 
 * @param in_act_id					Access token
 * @param in_session_sid			.
 * @param in_imp_ind_id				.
 * @param in_comp_direction			.
 * @param in_sort_direction			.
 * @param in_show_only_unmapped		.
 * @param out_cur					The rowset
 */
PROCEDURE getSessionIndicators(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_session_sid			IN	security_pkg.T_SID_ID,			
	in_imp_ind_id			IN	IMP_IND.imp_ind_id%TYPE,
	in_comp_direction		IN  NUMBER,
	in_sort_direction		IN  NUMBER,		
	in_show_only_unmapped	IN  NUMBER,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Get all indicators for a session
 *
 * @param in_session_sid			The import session
 * @param out_cur					The rowset
 */
PROCEDURE getSessionIndicators(
	in_session_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

/**
 * getSessionRegions
 * 
 * @param in_act_id					Access token
 * @param in_session_sid			.
 * @param in_imp_region_id			.
 * @param in_comp_direction			.
 * @param in_sort_direction			.
 * @param in_show_only_unmapped		.
 * @param out_cur					The rowset
 */
PROCEDURE getSessionRegions(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_session_sid			IN	security_pkg.T_SID_ID,			
	in_imp_region_id		IN	IMP_REGION.imp_region_id%TYPE,
	in_comp_direction		IN  NUMBER,
	in_sort_direction		IN  NUMBER,
	in_show_only_unmapped	IN  NUMBER,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Get all regions for a session
 *
 * @param in_session_sid			The import session
 * @param out_cur					The rowset
 */
PROCEDURE getSessionRegions(
	in_session_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

-- Legacy version
PROCEDURE getValuesForImpIndId(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_session_sid		IN	security_pkg.T_SID_ID,			
	in_imp_ind_id		IN	IMP_IND.imp_ind_id%TYPE,   
	in_order_by			IN	VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

/**
 * getValuesForImpIndId
 * 
 * @param in_act_id			Access token
 * @param in_session_sid	Import session id
 * @param in_imp_ind_id		Import indicator id
 * @param in_order_by		Row order
 * @param in_start_row		First row, zero based
 * @param in_page_size		Maximum rows to fetch
 * @param out_total_rows	Total rows
 * @param out_cur			The rowset
 */
PROCEDURE getValuesForImpIndId(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_session_sid		IN	security_pkg.T_SID_ID,			
	in_imp_ind_id		IN	IMP_IND.imp_ind_id%TYPE,   
	in_order_by			IN	VARCHAR2,
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	out_total_rows		OUT	NUMBER,	
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

-- Legacy version
PROCEDURE getValuesForImpRegionId(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_session_sid		IN	security_pkg.T_SID_ID,			
	in_imp_region_id	IN	imp_region.imp_region_id%TYPE,   
	in_order_by			IN	VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

/**
 * getValuesForImpRegionId
 * 
 * @param in_act_id			Access token
 * @param in_session_sid	Import session id
 * @param in_imp_reigon_id	Import regionid
 * @param in_order_by		Row order
 * @param in_start_row		First row, zero based
 * @param in_page_size		Maximum rows to fetch
 * @param out_total_rows	Total rows
 * @param out_cur			The rowset
 */
PROCEDURE getValuesForImpRegionId(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_session_sid		IN	security_pkg.T_SID_ID,			
	in_imp_region_id	IN	imp_region.imp_region_id%TYPE,   
	in_order_by			IN	VARCHAR2,
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	out_total_rows		OUT	NUMBER,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

/**
 * mapImpIndToSid
 * 
 * @param in_act_id			Access token
 * @param in_imp_ind_id		.
 * @param in_maps_to_sid	.
 */
PROCEDURE mapImpIndToSid(	
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_ind_id		IN	IMP_IND.imp_ind_id%TYPE,
	in_maps_to_sid		IN	IMP_IND.maps_to_ind_sid%TYPE   
);		   

/**
 * IgnoreImpInd
 * 
 * @param in_act_id			Access token
 * @param in_imp_ind_id		.
 */
PROCEDURE IgnoreImpInd(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_imp_ind_id	IN	IMP_IND.imp_ind_id%TYPE
);

/**
 * mapImpRegionToSid
 * 
 * @param in_act_id				Access token
 * @param in_imp_region_id		.
 * @param in_maps_to_sid		.
 */
PROCEDURE mapImpRegionToSid(	
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_region_id	IN	IMP_REGION.imp_region_id%TYPE,
	in_maps_to_sid		IN	IMP_REGION.maps_to_region_sid%TYPE   
);

/**
 * IgnoreImpRegion
 * 
 * @param in_act_id				Access token
 * @param in_imp_region_id		.
 */
PROCEDURE IgnoreImpRegion(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_region_id	IN	IMP_REGION.imp_region_id%TYPE
);
	 
/**
 * getMappingsToIndicator
 * 
 * @param in_act_id				Access token
 * @param in_ind_sid			The sid of the object
 * @param in_imp_session_sid	.
 * @param out_cur				The rowset
 */
PROCEDURE getMappingsToIndicator( 
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_imp_session_sid	IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * getMappingsToRegion
 * 
 * @param in_act_id				Access token
 * @param in_region_sid			The sid of the object
 * @param in_imp_session_sid	.
 * @param out_cur				The rowset
 */
PROCEDURE getMappingsToRegion( 
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_imp_session_sid	IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * deleteFileData
 * 
 * @param in_act_id			Access token
 * @param in_file_sid		.
 */
PROCEDURE deleteFileData( 
	in_act_id	IN	security_pkg.T_ACT_ID,
	in_file_sid	IN	security_pkg.T_SID_ID
);

/**
 * insertConflicts
 * 
 * @param in_act_id				Access token
 * @param in_imp_session_sid	.
 */
PROCEDURE insertConflicts(	
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_session_sid	IN	security_pkg.T_SID_ID   
);

/**
 * getConflictList
 * 
 * @param in_act_id			Access token
 * @param in_session_sid	.
 * @param in_order_by		.
 * @param out_cur			The rowset
 */
PROCEDURE getConflictList(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_session_sid		IN	security_pkg.T_SID_ID,			
	in_order_by			IN	VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);
		
/**
 * getConflict
 * 
 * @param in_act_id				Access token
 * @param in_imp_conflict_id	.
 * @param out_cur				The rowset
 */
PROCEDURE getConflict(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_conflict_id	IN	IMP_CONFLICT.imp_conflict_id%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

/**
 * getConflictDetailList
 * 
 * @param in_act_id				Access token
 * @param in_imp_conflict_id	.
 * @param in_order_by			.
 * @param out_cur				The rowset
 */
PROCEDURE getConflictDetailList(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_conflict_id	IN	security_pkg.T_SID_ID,			
	in_order_by			IN	VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);
	 
/**
 * acceptConflict
 * 
 * @param in_act_id				Access token
 * @param in_imp_conflict_id	.
 * @param in_imp_val_id			.
 * @param in_accept				.
 */
PROCEDURE acceptConflict(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_conflict_id	IN	IMP_CONFLICT_VAL.imp_conflict_id%TYPE,			
	in_imp_val_id		IN	IMP_CONFLICT_VAL.imp_val_id%TYPE,			
	in_accept			IN	IMP_CONFLICT_VAL.ACCEPT%TYPE
);
	 
/**
 * getSessionFilesList
 * 
 * @param in_act_id				Access token
 * @param in_imp_session_sid	.
 * @param in_order_by			.
 * @param out_cur				The rowset
 */
PROCEDURE getSessionFilesList( 
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_session_sid	IN	security_pkg.T_SID_ID,
	in_order_by			IN	VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE getSessionFilesList( 
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_session_sid	IN	security_pkg.T_SID_ID,			
	in_order_by			IN	VARCHAR2,
	out_conflicts		OUT NUMBER,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

-- get region + indicator info incl mapping as list
/**
 * getFileInfoList
 * 
 * @param in_act_id			Access token
 * @param in_file_sid		.
 * @param in_info_type		.
 * @param in_order_by		.
 * @param out_cur			The rowset
 */
PROCEDURE getFileInfoList(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_file_sid			IN	security_pkg.T_SID_ID,
	in_info_type		IN	VARCHAR2,			
	in_order_by			IN	VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

/**
 * previewMerge
 * 
 * @param in_act_id			Access token
 * @param in_file_sid		.
 * @param out_cur			The rowset
 */
PROCEDURE previewMerge(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_file_sid				IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RemoveMergedData(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_imp_session_sid			IN	security_pkg.T_SID_ID
);

/**
 * mergeWithMainData
 * 
 * @param in_act_id				Access token
 * @param in_imp_session_sid	.
 */
PROCEDURE mergeWithMainData(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_imp_session_sid			IN	security_pkg.T_SID_ID
);

/**
 * Returns a list of unmapped imp_ind_ids
 * 
 * @param in_act_id				Access token
 * @param in_imp_session_sid	THe import session Sid
 */
PROCEDURE GetUnmappedValues  (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_imp_session_sid			IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * getFileUpload
 * 
 * @param in_act_id			Access token
 * @param in_imp_val_id		.
 * @param out_cur			The rowset
 */
PROCEDURE getFileUpload(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_val_id		IN	imp_val.imp_val_id%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

/**
 * autoMapRegions
 * 
 * @param in_act_id				Access token
 * @param in_imp_session_sid	.
 * @param out_auto_mapped		.
 */
PROCEDURE autoMapRegions(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_session_sid	IN	security_pkg.T_SID_ID,
	out_auto_mapped		OUT NUMBER
);

/**
 * autoMapInds
 * 
 * @param in_act_id				Access token
 * @param in_imp_session_sid	.
 * @param out_auto_mapped		.
 */
PROCEDURE autoMapInds(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_session_sid	IN	security_pkg.T_SID_ID,
	out_auto_mapped		OUT NUMBER
);

PROCEDURE SumConflicts(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_session_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE RemoveDupeValConflicts(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_session_sid	IN	security_pkg.T_SID_ID
);
/**
 * Finds where values in an import session will affect existing
 * values in the database if merged.
 *
 * @param in_act_Id				Access token
 * @param in_imp_session_Sid	Session SID
 *
 * Returns cursor
 */
PROCEDURE GetDifferences(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_session_sid	IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Delete values from the import session
 */

PROCEDURE DeleteImportValue(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_session_sid	IN	security_pkg.T_SID_ID,
	in_imp_val_ids		IN	security_pkg.T_SID_IDS
);

/**
 * Find the mapped indicator name
 *
 * @param in_raw_ind_name	Original indicator name
 *
 * Returns out_ind_name		Mapped indicator name
 */

TYPE T_VARCHAR2_ARRAY	IS TABLE OF VARCHAR2(100) INDEX BY PLS_INTEGER;


FUNCTION Varchar2ArrayToTable(
	in_varchars				IN T_VARCHAR2_ARRAY
) RETURN T_VARCHAR2_TABLE;

PROCEDURE GetIndName(
	dummy				IN security_pkg.T_ACT_ID,
	in_raw_ind_names	IN T_VARCHAR2_ARRAY,
	out_ind_name		OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Find the mapped region name
 *
 * @param in_raw_region_name	Original region name
 *
 * Returns out_region_name		Mapped region name
 */

PROCEDURE GetRegionName(
	dummy				IN security_pkg.T_ACT_ID,
	in_raw_region_names	IN T_VARCHAR2_ARRAY,
	out_region_name		OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Update mapped indicator
 *
 * @param in_ind_description	indicator description
 * @param in_ind_sid			indicator sid
 *
 */

PROCEDURE AddNewImportIndicator(
	in_ind_description		IN VARCHAR2,
	in_ind_sid				IN security_pkg.T_SID_ID
);

/**
 * Update mapped region
 *
 * @param in_region_description	region description
 * @param in_region_sid			region sid
 *
 */

PROCEDURE AddNewImportRegion(
	in_region_description		IN VARCHAR2,
	in_region_sid				IN security_pkg.T_SID_ID
);

/**
 * Update mapped measure
 *
 * @param in_measure_description	measure description
 * @param in_measure_sid			measure sid
 * @param in_measure_conversion_id	measure conversion id
 * @param in_indicator_description	indicator description
 *
 */

PROCEDURE AddNewImportMeasure(
	in_measure_description		IN VARCHAR2,
	in_measure_sid				IN security_pkg.T_SID_ID,
	in_measure_conversion_id	IN security_pkg.T_SID_ID,
	in_indicator_description	IN VARCHAR2
);

/**
 * AddNewValue
 * 
 * @param in_imp_session_sid		The import session sid
 * @param in_app_sid				The sid of the Application/CSR object
 * @param in_ind_description		The indicator description
 * @param in_region_description		The region description
 * @param in_measure_description	The measure description
 * @param in_unknown				Any unknown text
 * @param in_start_dtm				The start date
 * @param in_end_dtm				The end date
 * @param in_file_sid				Import File Sid
 * @param in_val					The value number
 */

PROCEDURE AddNewValue(
	in_imp_session_sid			IN	security_pkg.T_SID_ID,
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_ind_description			IN	VARCHAR2,
	in_region_description		IN	VARCHAR2,
	in_measure_description		IN	VARCHAR2,
	in_unknown					IN 	IMP_VAL.unknown%TYPE,
	in_start_dtm				IN 	IMP_VAL.start_dtm%TYPE,
	in_end_dtm					IN 	IMP_VAL.end_dtm%TYPE,
	in_file_sid					IN 	IMP_VAL.file_sid%TYPE,
	in_val						IN 	IMP_VAL.VAL%TYPE
);

/**
 * GetMeasures
 * 
 * @param in_ind_sids		Indicator sids
 * @param out_cur			List of measures
 
 */

PROCEDURE GetMeasures(
	in_ind_sids			IN security_pkg.T_SID_IDS,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * Auto-parse import session for web-imports
 * 
 * @param in_act_id				Access token
 * @param in_imp_session_sid	Import session sid
 */

PROCEDURE AutoParseSession(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_imp_session_sid		IN imp_session.imp_session_sid%TYPE
);

PROCEDURE RefreshAllConflicts;

PROCEDURE GetMatchingDelegations(
	in_imp_session_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE MergeWithTopDelegSheets(
	in_imp_session_sid	IN	security_pkg.T_SID_ID,
	in_delegation_sids	IN	security_pkg.T_SID_IDS
);

PROCEDURE GetVocab(
	in_all_user_vocab				IN NUMBER,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ClearUserVocab(
	in_csr_user_sid					IN csr_user.csr_user_sid%TYPE
);

PROCEDURE SetUserVocab(
	in_csr_user_sid					IN csr_user.csr_user_sid%TYPE,
	in_tag_type_id					IN imp_tag_type.imp_tag_type_id%TYPE,
	in_phrase						IN imp_vocab.phrase%TYPE
);

PROCEDURE GetMeasureSidFromIndicatorId(
	in_imp_ind_id					IN  imp_ind.imp_ind_id%TYPE,
	out_measure_sid					OUT	imp_measure.maps_to_measure_sid%TYPE
);

PROCEDURE UpdateImpValsForCustomMeasures(
	in_imp_session_id				IN imp_session.imp_session_sid%TYPE
);

PROCEDURE UploadImage(
	in_cache_key	IN	aspen2.filecache.cache_key%type,
	out_logo_id		OUT	security_pkg.T_SID_ID
);

PROCEDURE GetImage(
	in_img_id	IN	NUMBER,
	out_cur		OUT	SYS_REFCURSOR
);

END Imp_Pkg;
/
