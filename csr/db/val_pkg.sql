CREATE OR REPLACE PACKAGE CSR.VAL_PKG AS

/**
 * Works out the duration of a period in terms of
 * m)onth, d)ay, q)uarter, w)eek, y)ear
 *
 * @param	in_start_dtm	Start datetime
 * @param	in_end_dtm		End datetime
 */
FUNCTION GetIntervalFromRange(
	in_start_dtm	IN	VAL.period_start_dtm%TYPE,
	in_end_dtm		IN	VAL.period_end_dtm%TYPE
) RETURN CHAR;
PRAGMA RESTRICT_REFERENCES(GetIntervalFromRange, WNDS, RNDS, WNPS);

/**
 * GetPeriod
 * 
 * @param in_start_dtm		The start date
 * @param in_end_dtm		The end date
 * @param in_inc			.
 * @param out_start_dtm		.
 * @param out_end_dtm		.
 */
PROCEDURE GetPeriod(
	in_start_dtm	IN  VAL.period_start_dtm%TYPE,
	in_end_dtm		IN  VAL.period_end_dtm%TYPE,
	in_inc			IN  INTEGER,
	out_start_dtm	OUT VAL.period_start_dtm%TYPE,
	out_end_dtm		OUT VAL.period_end_dtm%TYPE
);

/**
 * Normalise set of values with arbitrary start/end dates for multiple
 * regions and output a set of data per month/quarter etc with values
 * apportioned accordingly.
 *
 * @param in_cur				Cursor: region_sid, start_dtm, end_dtm, val
 * @param in_start_dtm			Start date of period
 * @param in_end_dtm			End date of period
 * @param in_interval_duration	Interval duration in months (defaults to 1)
 * @param in_divisibility		Divisibility of data (defaults to Divisible)
 */
FUNCTION NormaliseToPeriodSpan(
	in_cur					IN	SYS_REFCURSOR,
	in_start_dtm 			IN	DATE,
	in_end_dtm				IN	DATE,
    in_interval_duration	IN	NUMBER DEFAULT 1,
	in_divisibility			IN	NUMBER DEFAULT csr_data_pkg.DIVISIBILITY_DIVISIBLE
) RETURN T_NORMALISED_VAL_TABLE;

/**
 * GetValueActualAndPrevious
 * 
 * @param in_act_id					Access token
 * @param in_period_start_dtm		.
 * @param in_period_end_dtm			.
 * @param in_ind_sid				The sid of the object
 * @param in_region_sid				The sid of the object
 * @param in_interval				The period interval (m|q|h|y)
 * @param out_cur					The rowset
 */
PROCEDURE GetValueActualAndPrevious(
	in_act_id						IN	security_pkg.t_Act_id,
	in_period_start_dtm	IN	val.PERIOD_START_DTM%TYPE,
	in_period_end_dtm		IN	val.PERIOD_END_DTM%TYPE,
	in_ind_sid					IN 	security_pkg.T_SID_ID,
	in_region_sid				IN	security_pkg.T_SID_ID,
  in_interval					IN 	VARCHAR2, --IND.default_interval%TYPE,
	out_cur						 OUT	SYS_REFCURSOR
);

/**
 * GetAndCompareValue
 * 
 * @param in_act_id						Access token
 * @param in_period_start_dtm			.
 * @param in_period_end_dtm				.
 * @param in_ind_sid					The sid of the object
 * @param in_region_sid					The sid of the object
 * @param in_comparison_val_number		.
 * @param out_cur						The rowset
 */
PROCEDURE GetAndCompareValue(
	in_act_id					IN	security_pkg.t_Act_id,
	in_period_start_dtm			IN	val.PERIOD_START_DTM%TYPE,
	in_period_end_dtm			IN	val.PERIOD_END_DTM%TYPE,
	in_ind_sid					IN 	security_pkg.T_SID_ID,
	in_region_sid				IN	security_pkg.T_SID_ID,
    in_comparison_val_number	IN 	sheet_value.val_number%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

/**
 * GetAggregateDetails
 * 
 * @param in_ind_sid			The indicator to fetch details for
 * @param in_region_sid		    The region to fetch data for
 * @param in_start_dtm		    The start date to fetch from
 * @param in_end_dtm			The start date to fetch to
 * @param out_val_cur			The values
 * @param out_child_cur		    Child region sids, and whether they are links
 */
PROCEDURE GetAggregateDetails(
	in_ind_sid						IN	val.ind_sid%TYPE,
	in_region_sid					IN	val.region_sid%TYPE,
	in_start_dtm					IN	val.period_start_dtm%TYPE,
	in_end_dtm						IN	val.period_end_dtm%TYPE,
	out_val_cur						OUT	SYS_REFCURSOR,
	out_child_cur					OUT	SYS_REFCURSOR
);

/**
 * GetParentValues
 * 
 * @param in_act_id		Access token
 * @param in_val_id		The parent value
 * @param out_cur		The rowset
 */
PROCEDURE GetParentValues(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_val_id			IN	val.val_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);

/**
 * GetChildValues
 *
 * Get child values (those that contributed to an aggregate)
 *
 * @param in_act_id		Access token
 * @param in_val_id		The parent value
 * @param out_cur		The rowset
 */
PROCEDURE GetChildValues(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_val_id			IN	val.val_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);

/**
 * GetValue
 * 
 * @param in_act_id			Access token
 * @param in_val_id			.
 * @param in_check_due		.
 * @param out_cur			The rowset
 */
PROCEDURE GetValue(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_val_id			IN	val.val_id%TYPE,
	in_check_due	IN	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
);




/**
 * RollbackToValChangeId
 * 
 * @param in_act_id				Access token
 * @param in_val_change_id		.
 * @param out_val_id			.
 */
PROCEDURE RollbackToValChangeId(
	in_act_id				IN  security_pkg.T_ACT_ID,
	in_val_change_id		IN  val_change.val_change_id%TYPE,
	out_val_id				OUT VAL.val_id%TYPE
);


/**
 * GetBaseDataForInd
 * 
 * @param in_act_id			Access token
 * @param in_ind_sid		The sid of the object
 * @param in_from_dtm		.
 * @param in_to_dtm			.
 * @param in_order_by		.
 * @param out_cur			The rowset
 */
PROCEDURE GetBaseDataForInd(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_ind_sid			IN security_pkg.T_SID_ID,
	in_from_dtm			IN VAL.period_start_dtm%TYPE,
	in_to_dtm			IN VAL.period_end_dtm%TYPE,
	in_order_by			IN	VARCHAR2,
	out_cur				OUT SYS_REFCURSOR
);

/**
 * GetBaseDataForRegion
 * 
 * @param in_act_id			Access token
 * @param in_region_sid		The sid of the object
 * @param in_from_dtm		.
 * @param in_to_dtm			.
 * @param in_order_by		.
 * @param out_cur			The rowset
 */
PROCEDURE GetBaseDataForRegion(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_region_sid		IN security_pkg.T_SID_ID,
	in_from_dtm			IN VAL.period_start_dtm%TYPE,
	in_to_dtm			IN VAL.period_end_dtm%TYPE,
	in_order_by			IN	VARCHAR2,
	out_cur				OUT SYS_REFCURSOR
);

/**
 * GetBaseData
 * 
 * @param in_act_id				Access token
 * @param in_ind_or_region		.
 * @param in_sid				The sid of the object
 * @param in_from_dtm			.
 * @param in_to_dtm				.
 * @param in_order_by			.
 * @param out_cur				The rowset
 */
PROCEDURE GetBaseData(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_ind_or_region	IN VARCHAR2,
	in_sid				IN security_pkg.T_SID_ID,
	in_from_dtm			IN VAL.period_start_dtm%TYPE,
	in_to_dtm			IN VAL.period_end_dtm%TYPE,
	in_order_by			IN	VARCHAR2,
	out_cur				OUT SYS_REFCURSOR
);

/**
 * Get data from val filtered by ind/region/time
 * 
 * @param in_ind_or_region			'ind' for filter by indicator, 'region' for filter by region
 * @param in_sid					ind/region tree root
 * @param in_from_dtm				Start date to filter by
 * @param in_to_dtm					End date to filter by
 * @param in_filter_by				ind/region to restrict to
 * @param in_get_aggregates			1 to fetch aggregates
 * @param out_cur					The filtered data
 */
PROCEDURE GetBaseDataFiltered(
	in_ind_or_region				IN	VARCHAR2,
	in_sid							IN	security_pkg.T_SID_ID,
	in_from_dtm						IN	val.period_start_dtm%TYPE,
	in_to_dtm						IN	val.period_end_dtm%TYPE,
	in_filter_by      				IN	security_pkg.T_SID_ID,
	in_get_aggregates               IN  NUMBER,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * Get data from val filtered by ind/region/time
 * 
 * @param in_ind_or_region			'ind' for filter by indicator, 'region' for filter by region
 * @param in_sid					ind/region tree root
 * @param in_from_dtm				Start date to filter by
 * @param in_to_dtm					End date to filter by
 * @param in_filter_by				ind/region to restrict to
 * @param in_get_aggregates			1 to fetch aggregates
 * @param in_get_stored_calc_values	1 to fetch stored calc values
 * @param out_cur					The filtered data
 */
PROCEDURE GetBaseDataFiltered2(
	in_ind_or_region				IN	VARCHAR2,
	in_sid							IN	security_pkg.T_SID_ID,
	in_from_dtm						IN	val.period_start_dtm%TYPE,
	in_to_dtm						IN	val.period_end_dtm%TYPE,
	in_filter_by      				IN	security_pkg.T_SID_ID,
	in_get_aggregates               IN  NUMBER,
	in_get_stored_calc_values		IN	NUMBER,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * Returns any values which overlap (i.e. would cause some form of conflict)
 * if we were to copy data from one indicator to another for a specific
 * period of time.
 * 
 * @param in_act_id				Access token
 * @param in_from_ind_sid		Check data that exists in this indicator sid...
 * @param in_to_ind_sid			...to see if it will intersect with data in this indicator sid
 * @param in_start_dtm			The start date
 * @param in_end_dtm			The end date
 * @param out_cur				The output rowset	
 */
PROCEDURE GetConflictsForInds(
	in_src_ind_sid					IN	security_pkg.T_SID_ID,
	in_dest_ind_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm					IN	val.period_start_dtm%TYPE DEFAULT NULL,
	in_end_dtm						IN	val.period_end_dtm%TYPE DEFAULT NULL,
	in_filter_by_region_sid 		IN	security_pkg.T_SID_ID DEFAULT NULL,
	out_cur							OUT	SYS_REFCURSOR
);

/**
* Return if an indicator has a value
* Used in indicator_pkg.IsIndicatorUsed
*/ 
FUNCTION IsIndicatorUsed(
	in_ind_sid	IN	security_pkg.T_SID_ID	
)RETURN BOOLEAN;

FUNCTION SQL_IsIndicatorUsed(
	in_ind_sid	IN	security_pkg.T_SID_ID	
)RETURN NUMBER;

/**
 * Get files attached to a value/file upload value
 * 
 * @param in_act_id			Access token
 * @param in_val_id			.
 * @param out_cur			Files
 */
PROCEDURE GetFilesForValue(
	in_act_id			IN	security.security_pkg.T_ACT_ID,
	in_val_id			IN	val.val_id%TYPE,
	out_cur_files		OUT	security.security_pkg.T_OUTPUT_CUR
);

END VAL_PKG;
/
