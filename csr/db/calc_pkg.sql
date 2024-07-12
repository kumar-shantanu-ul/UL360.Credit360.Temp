CREATE OR REPLACE PACKAGE CSR.Calc_Pkg AS

-- set of dependency types (DEP_ON_INDICATOR, DEP_ON_CHILDREN, DEP_ON_MODEL) -- the value is irrelevant
TYPE IndDependencyTypes IS TABLE OF BINARY_INTEGER INDEX BY BINARY_INTEGER;
-- map of indicators depended on to dependency types
TYPE IndDependencies IS TABLE OF IndDependencyTypes INDEX BY BINARY_INTEGER;
-- set of tag ids depended on -- the value is irrelevant
TYPE TagDependencies IS TABLE OF BINARY_INTEGER INDEX BY BINARY_INTEGER;
-- set of tag ids depended on -- the value is irrelevant
TYPE BaselineDependencies IS TABLE OF BINARY_INTEGER INDEX BY BINARY_INTEGER;
-- dependencies of a calculation -- a map of indicators depended on to a list of dependency types and a set of tag ids
TYPE CalcDependencies IS RECORD (
	inds							IndDependencies,
	tags							TagDependencies,
	baselines						BaselineDependencies
);

/**
 * Get calculation dependencies and calc start date adjustments for the given calc xml node
 *
 * @param in_node					The calc xml root node
 * @param io_deps					The calc dependencies
 * @return							The calc start date adjustment
 */
FUNCTION GetCalcDependencies(
    in_node                         IN  			dbms_xmldom.domnode,
	io_deps							IN OUT NOCOPY	CalcDependencies
)
RETURN NUMBER;

/* something about this indicator as a whole has changed so 
  add in a ton of jobs for all the calculations that use its 
  values (e.g. divisible field maybe changed?) */
/**
 * AddJobsForInd
 * 
 * @param in_ind_sid	The sid of the object
 * @param add			.
 */
PROCEDURE AddJobsForInd(
	in_ind_sid		IN	security_pkg.T_SID_ID
);

/**
 * A specific value has changed, so just add in any relevant jobs for this value
 *
 * @param in_app_sid			The sid of the Application/CSR object
 * @param in_ind_sid			The indicator
 * @param in_region_sid			The region
 * @param in_start_dtm			The start of the period that the value covers
 * @param in_end_dtm			The end of the period that the value covers
 */
PROCEDURE AddJobsForVal(
	in_ind_sid			IN	ind.ind_sid%TYPE,
	in_region_sid		IN	region.region_sid%TYPE,
	in_start_dtm		IN	val.period_start_dtm%TYPE,
	in_end_dtm			IN	val.period_end_dtm%TYPE
);

/**
 * Called when something about our calculated indicator has changed 
 * to shove in bunch of jobs to recalculate it
 * 
 * @param in_calc_ind_sid		.
 */
PROCEDURE AddJobsForCalc(
	in_calc_ind_sid		IN	security_pkg.T_SID_ID
);
 
/**
 * Called when the gas factor for this factor type has changed
 * to recalculate all indicators that map to this factor type
 *
 * @param in_factor_type_id			.
 */
PROCEDURE AddJobsForFactorType(
	in_factor_type_id		IN	factor_type.factor_type_id%TYPE
);

PROCEDURE AddCalcJobsForAggregateIndGroup(
	in_aggregate_ind_group_id		aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm					aggregate_ind_calc_job.start_dtm%TYPE DEFAULT NULL,
	in_end_dtm						aggregate_ind_calc_job.end_dtm%TYPE DEFAULT NULL
);

/**
 * Called when an an oracle table has been updated that will
 * affect the value of an aggregate indicator
 *
 * @param in_aggregate_ind_group_id	The ID of the aggregate ind group
 * @param in_start_dtm				The start date of the period affected
 * @param in_end_dtm				The end date of the period affected
 */
PROCEDURE AddJobsForAggregateIndGroup(
	in_aggregate_ind_group_id		aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm					aggregate_ind_calc_job.start_dtm%TYPE DEFAULT NULL,
	in_end_dtm						aggregate_ind_calc_job.end_dtm%TYPE DEFAULT NULL
);

/**
 * Called when an an oracle table has been updated that will
 * affect the value of an aggregate indicator
 *
 * @param in_helper_proc			The helper procedure of the aggregate ind group.
 *									This will only work if the helper proc is unique to this app
 *									Useful as a handle to the group
 * @param in_start_dtm				The start date of the period affected
 * @param in_end_dtm				The end date of the period affected
 */
PROCEDURE AddJobsForAggregateIndGroup(
	in_name							aggregate_ind_group.name%TYPE,
	in_start_dtm					aggregate_ind_calc_job.start_dtm%TYPE DEFAULT NULL,
	in_end_dtm						aggregate_ind_calc_job.end_dtm%TYPE  DEFAULT NULL
);

/**
 * Set the calculation on an indicator
 * 
 * @param in_act_id						Access token
 * @param in_calc_ind_sid				The indicator to set the calculation on
 * @param in_calc_xml					The calculation
 * @param in_is_stored					1 if this is a stored calc, 0 if normal
 * @param in_period_set_id				The period set for the default interval
 * @param in_period_interval_id			The default interval
 * @param in_do_temporal_aggregation	1 to perform temporal aggregation before computing the calc	
 */
PROCEDURE SetCalcXML(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_calc_ind_sid					IN 	security_pkg.T_SID_ID,
	in_calc_xml						IN 	ind.calc_xml%TYPE,
	in_is_stored 					IN 	NUMBER, 
	in_period_set_id				IN	ind.period_set_id%TYPE,
	in_period_interval_id			IN	ind.period_interval_id%TYPE,
	in_do_temporal_aggregation		IN 	ind.do_temporal_aggregation%TYPE,
	in_calc_description				IN	ind.calc_description%TYPE
);

/**
 * Adds	a row to the calc dependency table
 *
 * @param	in_act_id		Access token
 * @param	in_calc_ind_sid		The indicator
 * @param	in_ind_sid	The region
 */ 
PROCEDURE AddCalcDependency(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_calc_ind_sid			IN security_pkg.T_SID_ID,
	in_ind_sid				IN security_pkg.T_SID_ID,
	in_dep_type				IN CALC_DEPENDENCY.dep_type%TYPE
);

PROCEDURE GetDependencies(
	in_act_id		IN security_pkg.T_ACT_ID,
	in_calc_ind_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpdateDependency(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_calc_ind_sid			IN security_pkg.T_SID_ID,
	in_ind_sid				IN security_pkg.T_SID_ID,
	in_dep_type				IN CALC_DEPENDENCY.dep_type%TYPE,
	in_new_ind_sid			IN security_pkg.T_SID_ID
);

/**
 * Removes dependencies from the first indicator on the second indicator
 * of the specified type
 *
 * @param	in_act_id			Access token
 * @param	in_calc_ind_sid		The dependind indicator
 * @param	in_ind_sid			The dependend on indicator
 * @param	in_dep_type			The type of dependency to remove
 */ 
PROCEDURE DeleteCalcDependency(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_calc_ind_sid			IN security_pkg.T_SID_ID,
	in_ind_sid				IN security_pkg.T_SID_ID,
	in_dep_type				IN CALC_DEPENDENCY.dep_type%TYPE
);

/* get which indicators are used for a given calculation  */
/**
 * GetIndsUsedByCalcAsTable
 * 
 * @param in_calc_ind_sid		.
 * @return 						.
 */
FUNCTION GetIndsUsedByCalcAsTable(
	in_calc_ind_sid	IN  security_pkg.T_SID_ID
) RETURN T_CALC_DEP_TABLE;

/**
 * GetIndsUsedByCalc
 * 
 * @param in_act_id				Access token
 * @param in_calc_ind_sid		.
 * @param out_cur				The rowset
 */
PROCEDURE GetIndsUsedByCalc(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_calc_ind_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
);
/**
 * GetAllIndsUsedByCalcAsTable
 * 
 * @param in_calc_ind_sid		.
 * @return 						.
 */
FUNCTION GetAllIndsUsedByCalcAsTable(
	in_calc_ind_sid		IN	CALC_DEPENDENCY.calc_ind_sid%TYPE
) RETURN T_DATASOURCE_DEP_TABLE;

/**
 * GetAllIndsUsedByCalc
 * 
 * @param in_calc_ind_sid		.
 * @param out_cur				The rowset
 */
PROCEDURE GetAllIndsUsedByCalc(
	in_calc_ind_sid		IN	CALC_DEPENDENCY.calc_ind_sid%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);
/**
 * GetAllIndsUsedAsTable
 * 
 * @param in_ind_list		.
 * @return 					.
 */
FUNCTION GetAllIndsUsedAsTable(
	in_ind_list				IN	security_pkg.T_SID_IDS,
	in_include_stored_calcs	IN	NUMBER
) RETURN T_DATASOURCE_DEP_TABLE;

/* get which calculations use a specific indicator  */
/**
 * GetCalcsUsingIndAsTable
 * 
 * @param in_ind_sid	The sid of the object
 * @return 				.
 */
FUNCTION GetCalcsUsingIndAsTable(
	in_ind_sid	IN  security_pkg.T_SID_ID
) RETURN T_CALC_DEP_TABLE;


/**
 * GetCalcsUsingInd
 * 
 * @param in_act_id		Access token
 * @param in_ind_sid	The sid of the object
 * @param out_cur		The rowset
 */
PROCEDURE GetCalcsUsingInd(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_ind_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
);


/**
 * GetAllCalcsUsingIndAsTable
 * 
 * @param in_ind_sid	The sid of the object
 * @return 				.
 */
FUNCTION GetAllCalcsUsingIndAsTable(
	in_ind_sid		IN	CALC_DEPENDENCY.calc_ind_sid%TYPE
) RETURN T_DATASOURCE_DEP_TABLE;

/**
 * GetAllCalcsUsingInd
 * 
 * @param in_ind_sid	The sid of the object
 * @param out_cur		The rowset
 */
PROCEDURE GetAllCalcsUsingInd(
	in_ind_sid		IN	CALC_DEPENDENCY.ind_sid%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * IsIndicatorCritical
 *
 * critical means that it's used directly by a calculation,
 * not just in a sum-children type thing 
 *
 * @param in_ind_sid	The sid of the object
 * @return 				.
 */
FUNCTION IsIndicatorCritical(
	in_ind_sid		IN security_pkg.T_SID_ID
) RETURN BOOLEAN;

PROCEDURE CheckCircularDependencies(
	in_ind_sid		IN	calc_dependency.ind_sid%TYPE
);

PROCEDURE GetTpl(
	in_ind_sid		IN	security_pkg.T_SID_ID,
	out_calc_xml	OUT	XMLTYPE
);

/**
 * GetCalcDependencies
 * 
 * @param in_calc_ind_sid	The sid of the calculated indicator
 * @param out_cur			The rowset contains indicators that the calculation depends on
 */
PROCEDURE GetCalcDependencies(
	in_calc_ind_sid					IN  security_pkg.T_SID_ID,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_calc_tag_cur				OUT	SYS_REFCURSOR,
	out_calc_baseline_config_cur	OUT	SYS_REFCURSOR
);

PROCEDURE GetAllCalcDependencies(
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	out_ind_cur						OUT	SYS_REFCURSOR
);

/**
 * Get an application sid from a host name
 *
 * @param in_host			The name of the host
 * @param out_app_sid		The sid of the application
 */
PROCEDURE GetAppSid(
	in_host					IN	customer.host%TYPE,
	out_app_sid				OUT	customer.app_sid%TYPE
);

PROCEDURE SetCalcXMLAndDeps(
	in_act_id						IN 	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
	in_calc_ind_sid					IN 	security_pkg.T_SID_ID,
	in_calc_xml						IN 	ind.calc_xml%TYPE,
	in_is_stored 					IN 	NUMBER, 
	in_period_set_id				IN	ind.period_set_id%TYPE,
	in_period_interval_id			IN	ind.period_interval_id%TYPE,	
	in_do_temporal_aggregation		IN 	ind.do_temporal_aggregation%TYPE,
	in_calc_description				IN	ind.calc_description%TYPE DEFAULT NULL
);

/**
* Return if an indicator is used in calculations
* Used in indicator_pkg.IsIndicatorUsed
*/ 
FUNCTION IsIndicatorUsed(
	in_ind_sid	IN	security_pkg.T_SID_ID	
)RETURN BOOLEAN;

END Calc_Pkg;
/
