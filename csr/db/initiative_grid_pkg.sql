CREATE OR REPLACE PACKAGE CSR.initiative_grid_pkg
IS

PROCEDURE INTERNAL_GetMyInitiatives(
	out_cur 	OUT  SYS_REFCURSOR,
	out_regions OUT  SYS_REFCURSOR,
	out_tags	OUT  SYS_REFCURSOR,
	out_users	OUT  SYS_REFCURSOR,
	out_metrics OUT  SYS_REFCURSOR
);

PROCEDURE GetBaseData(
	out_flow_states			OUT SYS_REFCURSOR,
	out_rag_statuses		OUT SYS_REFCURSOR,
	out_metrics         	OUT SYS_REFCURSOR,
	out_metric_conversions	OUT SYS_REFCURSOR
);

PROCEDURE GetMyInitiatives(
	out_cur 	OUT  SYS_REFCURSOR,
	out_regions OUT  SYS_REFCURSOR,
	out_tags	OUT  SYS_REFCURSOR,
	out_users	OUT  SYS_REFCURSOR,
	out_metrics OUT  SYS_REFCURSOR
);

PROCEDURE GetMyInitiativesForMetrics(
	in_metric_ids				IN	security_pkg.T_SID_IDS,
	in_measure_conversion_ids	IN	security_pkg.T_SID_IDS,
	in_start_dtm 				IN  DATE,
	in_end_dtm					IN  DATE,
	out_cur 					OUT SYS_REFCURSOR,
	out_regions 				OUT SYS_REFCURSOR,
	out_tags					OUT SYS_REFCURSOR,
	out_users					OUT SYS_REFCURSOR,
	out_metrics					OUT SYS_REFCURSOR,
	out_vals					OUT SYS_REFCURSOR
);

PROCEDURE GetMyTeamroomInitiatives(
	out_cur 			OUT	 SYS_REFCURSOR,
	out_regions 		OUT  SYS_REFCURSOR,
	out_tags			OUT  SYS_REFCURSOR,
	out_users			OUT  SYS_REFCURSOR,
	out_metrics			OUT  SYS_REFCURSOR
);

PROCEDURE GetTeamroomInitiatives(
	in_teamroom_sid		IN	 security_pkg.T_SID_ID,
	out_cur 			OUT	 SYS_REFCURSOR,
	out_regions 		OUT  SYS_REFCURSOR,
	out_tags			OUT  SYS_REFCURSOR,
	out_users			OUT  SYS_REFCURSOR,
	out_metrics			OUT  SYS_REFCURSOR
);

PROCEDURE GetPropertyInitiatives(
	in_property_sid		IN	security_pkg.T_SID_ID,
	out_cur 			OUT  SYS_REFCURSOR,
	out_regions 		OUT  SYS_REFCURSOR,
	out_tags			OUT  SYS_REFCURSOR,
	out_users			OUT  SYS_REFCURSOR,
	out_metrics			OUT  SYS_REFCURSOR
);

PROCEDURE GetMyPropInitiativesForMetrics(
	in_property_sid				IN	security_pkg.T_SID_ID,
	in_metric_ids				IN	security_pkg.T_SID_IDS,
	in_measure_conversion_ids	IN	security_pkg.T_SID_IDS, -- -1 == null as nullable arrays not supported by NPSL.DataAccess
	in_start_dtm 				IN  DATE,
	in_end_dtm					IN  DATE,
	out_cur 					OUT SYS_REFCURSOR,
	out_regions 				OUT SYS_REFCURSOR,
	out_tags					OUT SYS_REFCURSOR,
	out_users					OUT SYS_REFCURSOR,
	out_metrics					OUT SYS_REFCURSOR,
	out_vals					OUT SYS_REFCURSOR
);

PROCEDURE GetMyInitiativesWithProps(
	out_cur 	OUT  SYS_REFCURSOR,
	out_regions OUT  SYS_REFCURSOR,
	out_tags	OUT  SYS_REFCURSOR,
	out_users	OUT  SYS_REFCURSOR,
	out_metrics	OUT  SYS_REFCURSOR,
	out_props	OUT  SYS_REFCURSOR
);

PROCEDURE GetMyInitForMetricsWithProps(
	in_metric_ids				IN	security_pkg.T_SID_IDS,
	in_measure_conversion_ids	IN	security_pkg.T_SID_IDS,
	in_start_dtm 				IN  DATE,
	in_end_dtm					IN  DATE,
	out_cur 					OUT SYS_REFCURSOR,
	out_regions 				OUT SYS_REFCURSOR,
	out_tags					OUT SYS_REFCURSOR,
	out_users					OUT SYS_REFCURSOR,
	out_metrics					OUT SYS_REFCURSOR,
	out_vals					OUT SYS_REFCURSOR,
	out_props					OUT SYS_REFCURSOR
);

END initiative_grid_pkg;
/