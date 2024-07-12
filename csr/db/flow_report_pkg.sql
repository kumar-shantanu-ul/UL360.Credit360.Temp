CREATE OR REPLACE PACKAGE CSR.flow_report_pkg AS

ERR_AGGREGATION_DOESNT_EXIST	CONSTANT NUMBER := -20001;
ERR_AGGREGATE_GROUP_CLASH		CONSTANT NUMBER := -20002;

FUNCTION CleanLabel (
	in_label	VARCHAR2
)
RETURN VARCHAR2;

/*
 * Handy function to replace all non-alphanumeric characters with underscores and return string in upper case
**/
FUNCTION CleanLookupKey (
	in_label	VARCHAR2
)
RETURN VARCHAR2;

/*
 * Set-up procedure to allow client to record the time flow items spend in given flow states.
 * Indicators are set up and linked to each flow state
 * 
 * @param in_flow_sid			Workflow to capture time in states
 * @param in_parent_ind_sid		Parent Indicator/Container under which we should create the workflow container and state indicators 
 */
PROCEDURE RecordTimeInFlowStates(
	in_flow_sid			IN flow.flow_sid%TYPE,
	in_parent_ind_sid	IN ind.parent_sid%TYPE,
	in_recalc_all		IN NUMBER DEFAULT 0
);


/*
 * Internal procedure to get a cursor of aggregate values. Each type of workflow has to
 * populate temp_flow_item_region with flow_item_id and region SID then they can call this
 * procedure to get the time spent in the workflow states 
 * 
 * @param in_aggregate_ind_group_id		Aggregate Ind Group ID
 * @param in_start_dtm					Start of reporting periods range (month start)
 * @param in_end_dtm					End of reporting periods range (month start of proceeding month)
 */
PROCEDURE INTERNAL_GetFlowStateValues(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	values_cur					OUT security.security_pkg.T_OUTPUT_CUR
);

/*
 * Get Supplier workflow statistics for aggregate ind job. Standard interface.
 *
 * @param in_aggregate_ind_group_id		Aggregate Ind Group ID
 * @param in_start_dtm					Start of reporting periods range (month start)
 * @param in_end_dtm					End of reporting periods range (month start of proceeding month)
 */
PROCEDURE GetSupplierFlowValues(
	in_aggregate_ind_group_id	IN aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm				IN DATE,
	in_end_dtm					IN DATE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

/*
 * Get Campaign workflow statistics for aggregate ind job. Standard interface.
 *
 * @param in_aggregate_ind_group_id		Aggregate Ind Group ID
 * @param in_start_dtm					Start of reporting periods range (month start)
 * @param in_end_dtm					End of reporting periods range (month start of proceeding month)
 */
PROCEDURE GetCampaignFlowValues(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

END;
/