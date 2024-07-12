CREATE OR REPLACE PACKAGE ct.breakdown_pkg AS

PROCEDURE GetBreakdown(
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_breakdown_id				IN  breakdown.breakdown_id%TYPE,
	out_cur 					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRegionBreakdowns(
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur 					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBreakdowns(
	in_breakdown_type			IN  breakdown.breakdown_type_id%TYPE,
	out_cur 					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBreakdowns(
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_breakdown_type			IN  breakdown.breakdown_type_id%TYPE,
	out_cur 					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBreakdowns(
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_breakdown_id				IN  breakdown.breakdown_id%TYPE,
	in_breakdown_type			IN  breakdown.breakdown_type_id%TYPE,
	out_cur 					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetHSBreakdownRegions(
	out_cur 					OUT security_pkg.T_OUTPUT_CUR
); 

PROCEDURE GetBreakdownRegions(
	out_cur 					OUT security_pkg.T_OUTPUT_CUR
); 

PROCEDURE GetBreakdownRegions(
	in_breakdown_id				IN  breakdown_region.breakdown_id%TYPE,
	out_cur 					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBreakdownEios(
	in_breakdown_id				IN  breakdown.breakdown_id%TYPE,
	in_region_id				IN  breakdown_region_eio.region_id%TYPE,
	out_cur 					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTotalFteTravel(
	out_total_fte_travel		OUT breakdown.fte_travel%TYPE
);

PROCEDURE UpdateAllGroupRegionEios;

PROCEDURE SetBreakdownRegion (
	in_breakdown_id				IN  breakdown_region.breakdown_id%TYPE,
	in_region_id				IN  breakdown_region.region_id%TYPE,
	in_pct						IN  breakdown_region.pct%TYPE
);

PROCEDURE SetBreakdown (
	in_breakdown_id				IN  breakdown.breakdown_id%TYPE,
	in_breakdown_type_id		IN  breakdown.breakdown_type_id%TYPE,
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_description				IN  breakdown.description%TYPE,
	in_fte						IN  breakdown.fte%TYPE,
	in_turnover					IN  breakdown.turnover%TYPE,
	in_fte_travel				IN  breakdown.fte_travel%TYPE,
	in_is_remainder				IN  breakdown.is_remainder%TYPE,
	in_region_id				IN  breakdown.region_id%TYPE,
	out_breakdown_id			OUT breakdown.breakdown_id%TYPE
);

PROCEDURE SetBreakdownEio(
	in_breakdown_id				IN  breakdown.breakdown_id%TYPE,
	in_eio_id					IN  breakdown_region_eio.eio_id%TYPE,
	in_region_id				IN  breakdown_region_eio.region_id%TYPE,		
	in_pct						IN  breakdown_region_eio.pct%TYPE
);

PROCEDURE DeleteBreakdown(
	in_breakdown_id				IN breakdown.breakdown_id%TYPE
);

PROCEDURE DeleteBreakdown(
	in_breakdown_id				IN breakdown.breakdown_id%TYPE,
	in_do_recalc				IN  NUMBER
);

PROCEDURE DeleteBreakdownRegion(
	in_breakdown_id				IN  breakdown.breakdown_id%TYPE,
	in_region_id				IN  breakdown_region_eio.region_id%TYPE
);

PROCEDURE DeleteBreakdownRegion(
	in_breakdown_id				IN  breakdown.breakdown_id%TYPE,
	in_region_id				IN  breakdown_region_eio.region_id%TYPE,
	in_do_recalc				IN  NUMBER
);

PROCEDURE DeleteBreakdownEio(
	in_breakdown_id				IN  breakdown.breakdown_id%TYPE,
	in_eio_id					IN  breakdown_region_eio.eio_id%TYPE,
	in_region_id				IN  breakdown_region_eio.region_id%TYPE
);

PROCEDURE DeleteBreakdownEio(
	in_breakdown_id				IN  breakdown.breakdown_id%TYPE,
	in_eio_id					IN  breakdown_region_eio.eio_id%TYPE,
	in_region_id				IN  breakdown_region_eio.region_id%TYPE,
	in_do_recalc				IN  NUMBER
);

PROCEDURE UpdateBreakdownRegionsAndEio(
	in_breakdown_id				IN  breakdown.breakdown_id%TYPE
);

PROCEDURE UpdateGroupBreakdownTurnover(
	in_turnover_change			IN  breakdown.turnover%TYPE
);

PROCEDURE UpdateGroupBreakdownFte(
	in_fte_change				IN  breakdown.fte%TYPE
);

END breakdown_pkg;
/