CREATE OR REPLACE PACKAGE ct.breakdown_type_pkg AS

FUNCTION GetHSRegionBreakdownTypeId (
	in_company_sid					IN  security_pkg.T_SID_ID
) RETURN NUMBER;

FUNCTION GetVCRegionBreakdownTypeId (
	in_company_sid					IN  security_pkg.T_SID_ID
) RETURN NUMBER;

PROCEDURE GetHSBreakdownTypes(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetHSBreakdownTypes(
	in_company_sid					IN  company.company_sid%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetHSBreakdownTypes(
	in_company_sid					IN  company.company_sid%TYPE,
	in_ignore_region				IN  NUMBER,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetHSRegionBreakdownType(
	in_company_sid					IN  company.company_sid%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetHSBreakdownType(
	in_breakdown_type_id			IN  breakdown.breakdown_type_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBreakdownType(
	in_breakdown_type_id			IN  breakdown.breakdown_type_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBreakdownTypes(
	in_ignore_region				IN  NUMBER,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetHSBreakdownType(
	in_breakdown_type_id			IN  v$hs_breakdown_type.breakdown_type_id%TYPE,
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_singular						IN  v$hs_breakdown_type.singular%TYPE,
	in_plural						IN  v$hs_breakdown_type.plural%TYPE,
	in_by_turnover					IN  v$hs_breakdown_type.by_turnover%TYPE,
	in_by_fte						IN  v$hs_breakdown_type.by_fte%TYPE,
	in_is_region					IN  v$hs_breakdown_type.is_region%TYPE,
	in_rest_of						IN  v$hs_breakdown_type.rest_of%TYPE,
	out_breakdown_type_id			OUT v$hs_breakdown_type.breakdown_type_id%TYPE
);

PROCEDURE DeleteBreakdownType(
	in_breakdown_type_id		IN v$hs_breakdown_type.breakdown_type_id%TYPE
);

END breakdown_type_pkg;
/