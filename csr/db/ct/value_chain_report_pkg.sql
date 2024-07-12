CREATE OR REPLACE PACKAGE ct.value_chain_report_pkg AS



PROCEDURE GetBTEmissionsByMode (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- only for future proofing
	in_calculation_source_id		IN bt_emissions.calculation_source_id%TYPE, 
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBTByModeAndBreakdown (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- only for future proofing
	in_calculation_source_id		IN bt_emissions.calculation_source_id%TYPE, 
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetECEmissionsByMode (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- only for future proofing
	in_calculation_source_id		IN  v$ec_emissions.calculation_source_id%TYPE, 
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetECByModeAndBreakdown (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- only for future proofing
	in_calculation_source_id		IN  v$ec_emissions.calculation_source_id%TYPE, 
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPSEmissions (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- only for future proofing
	in_calculation_source_id		IN  v$ps_emissions.calculation_source_id%TYPE, 
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPSEmissionsDQ (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- only for future proofing
	in_calculation_source_id		IN  v$ps_emissions.calculation_source_id%TYPE, 
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPSEmissionsByEio (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, 
	in_calculation_source_id		IN ps_emissions_all.calculation_source_id%TYPE, 
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPSSpendAndEmissionsByEio (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, 
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPSEmissionsBySupplier (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, 
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPSEmissForEioBySupp (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS,  
	in_eio_id						IN  ps_item_eio.eio_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPSEmissForSupplierByEio (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, 
	in_supplier_id					supplier.supplier_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPSEmissByGroupList (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, 
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetScope123Emissions (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, 
	in_breakdown_by_region			IN NUMBER,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetScope3EmissionsByDQ (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, 
	in_normalised					IN  NUMBER,
	in_unstacked					IN  NUMBER,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetECEmissionsDQ (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- only for future proofing
	in_calculation_source_id		IN  v$ec_emissions.calculation_source_id%TYPE, 
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION ConvertToCubicMeter(
	in_amount		IN	ht_consumption.amount%TYPE,
	in_unit_id      IN  volume_unit.volume_unit_id%TYPE,
	in_unit_type    IN  NUMBER
) RETURN ht_consumption.amount%TYPE;

PROCEDURE GetConsumptionSourceBreakdowns( 
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- not used - just for consistency of report interface
	in_consumption_category_id 		IN ht_cons_source.ht_consumption_category_id%TYPE,	
	in_consumption_type_id			IN ht_cons_source.ht_consumption_type_id%TYPE,  	
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTotalWasteBreakdowns( 
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- not used - just for consistency of report interface
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION SumProductsBySupplier(
	in_supplier_id      IN  supplier.supplier_id%TYPE
) RETURN v$ps_item.spend_in_dollars%TYPE;

/*Returns (suppliers consumption source amount) * (sumOfProducts from this Supplier) / (supplier's turnover in dollars) PER consumptionSource id */
FUNCTION ApportionSupplierBreakdown(
	in_cons_source_id			IN  ht_cons_source.ht_cons_source_id%TYPE,
	in_suppplier_company_sid	IN  company.company_sid%TYPE,
	in_supplier_id				IN	supplier.supplier_id%TYPE, 
	in_turnover					IN  company.turnover%TYPE,
	in_currency_id				IN  company.currency_id%TYPE,
	in_period_id				IN  company.period_id%TYPE	
) RETURN NUMBER;

PROCEDURE GetWaterApportBySupplier( 
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- not used - just for consistency of report interface
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetWasteWaterApportBySupplier( 
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- not used - just for consistency of report interface
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetWasteApportBySupplier( 
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- not used - just for consistency of report interface
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

END value_chain_report_pkg;
/
