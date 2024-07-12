CREATE OR REPLACE PACKAGE ct.hotspot_pkg AS

HOTSPOTTER_QNR_CLASS			CONSTANT VARCHAR(255) := 'HotspotterQuestionnaire';

BUSINESS_TRAVEL					CONSTANT NUMBER := 1; 
EMPLOYEE_COMMUTING				CONSTANT NUMBER := 2; 
USE_OF_SOLD_PRODUCTS			CONSTANT NUMBER := 3; 
PURCHASED_GOODS_AND_SERVICES	CONSTANT NUMBER := 4; 
UPSTREAM_TRANSPORTATION			CONSTANT NUMBER := 5; 
DOWNSTREAM_TRANSPORT			CONSTANT NUMBER := 6; 
WASTE							CONSTANT NUMBER := 7; 

-- scope 1 and 2 input type
ENTER_SCOPE_12_DIRECTLY			CONSTANT NUMBER := 1; 
ENTER_SCOPE_12_CONSUMP			CONSTANT NUMBER := 2; 
ENTER_SCOPE_12_CALC				CONSTANT NUMBER := 3; 

FUNCTION HasCompletedHotspotter RETURN NUMBER;

FUNCTION HasCompletedHotspotter (
	in_company_sid					IN  security_pkg.T_SID_ID
) RETURN NUMBER;

FUNCTION HasSupplierCompletedHotspotter (
	in_supplier_id					IN  supplier.supplier_id%TYPE
) RETURN NUMBER;

FUNCTION HasCompletedHotspotterPeriod (
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_period_id					IN	company.period_id%TYPE
) RETURN NUMBER;

PROCEDURE GetEios(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetEio(
	in_eio_id						IN  eio.eio_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetGroups(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCountries(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPeriods(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPeriod(
	in_period_id					IN currency_period.period_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCurrencies(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCurrency(
	in_currency_id					IN  currency.currency_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCurrencyForPeriod(
	in_currency_id					IN currency_period.currency_id%TYPE,
	in_period_id					IN currency_period.period_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBusinessTypes(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveHotspotResult(
	in_breakdown_id              IN hotspot_result.breakdown_id%TYPE, 
	in_region_id                 IN hotspot_result.region_id%TYPE,                           
	in_eio_id                    IN hotspot_result.eio_id%TYPE,    
	in_company_sid				 IN hotspot_result.company_sid%TYPE,     	
	in_pg_emissions              IN hotspot_result.pg_emissions%TYPE,             
	in_scope_one_two_emissions   IN hotspot_result.scope_one_two_emissions%TYPE,   
	in_upstream_emissions        IN hotspot_result.upstream_emissions%TYPE,        
	in_downstream_emissions      IN hotspot_result.downstream_emissions%TYPE,      
	in_use_emissions             IN hotspot_result.use_emissions%TYPE,             
	in_waste_emissions           IN hotspot_result.waste_emissions%TYPE,           
	in_emp_comm_emissions        IN hotspot_result.emp_comm_emissions%TYPE,        
	in_business_travel_emissions IN hotspot_result.business_travel_emissions%TYPE
);

PROCEDURE GetHotRegionsForBreakdown(
	in_breakdown_id					IN breakdown.breakdown_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetHotResults(
	in_company_sid 					company.company_sid%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetScopeData (
	in_company_sid 					IN company.company_sid%TYPE,
	in_breakdown_type_id			IN breakdown_type.breakdown_type_id%TYPE,
	in_breakdown					IN NUMBER,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
) ;

PROCEDURE GetScopeData (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS,
	in_breakdown					IN NUMBER,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetScopeData (
	in_company_sid 					company.company_sid%TYPE,
	in_breakdown_ids				IN  security_pkg.T_SID_IDS,
	in_breakdown					IN NUMBER,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetScopeEIOData (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetEIOByBreakdown (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetEmissionBreakdownByRank (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS,
	in_show_scope_three_categ		IN NUMBER,
	in_show_pg_as_breakdown			IN NUMBER,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetEmissionByCategory (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS,
	in_breakdown					IN NUMBER,
	in_stack_PG						IN NUMBER,
	in_get_pct						NUMBER,
	in_scope_category_id			scope_3_category.scope_category_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetHotECTransportData (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetHotBTTransportData (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- only for future proofing
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetResultCountForBreakdowns (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS
) RETURN NUMBER;

FUNCTION SaveBreakdownAsRegion(
	in_region_name				IN	ct.breakdown.description%TYPE,
	in_breakdown_id				IN  breakdown.breakdown_id%TYPE,
	in_parent_region_sid		IN  security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID;

END hotspot_pkg;
/
