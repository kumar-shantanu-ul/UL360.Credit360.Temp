CREATE OR REPLACE PACKAGE ct.consumption_pkg AS

MASS_UNIT						CONSTANT NUMBER := 1; 
POWER_UNIT						CONSTANT NUMBER := 2; 
VOLUME_UNIT						CONSTANT NUMBER := 3; 

FUEL							CONSTANT NUMBER := 1;
FUGITIVE                        CONSTANT NUMBER := 2;
ELECTRICITY                     CONSTANT NUMBER := 3;
WATER                    		CONSTANT NUMBER := 4;
WASTE                     		CONSTANT NUMBER := 5;

CUBIC_METER_ID					CONSTANT NUMBER := 4;

--Water and waste consumption types used in VC charts
/* WATER_CONSUMPTION				CONSTANT NUMBER := 1;
WASTEWATER						CONSTANT NUMBER := 2;
NON_HAZ							CONSTANT NUMBER := 1;
HAZ								CONSTANT NUMBER := 2; */

--Consumption source (breakdown) ids used in VC charts
--water consumption
MAINS_WATER						CONSTANT NUMBER := 1; 
SURFACE_WATER					CONSTANT NUMBER := 2; 
GROUNDWATER						CONSTANT NUMBER := 3;
RAINWATER						CONSTANT NUMBER := 4;
OTHER_WATER						CONSTANT NUMBER := 5;		

--wastewater
DOMESTIC_WASTEWATER				CONSTANT NUMBER := 6;		
TRADE_EFFLUENT					CONSTANT NUMBER := 7;		
SURFACE_DRAINAGE				CONSTANT NUMBER := 8;		
DISCHARGE_TO_SURFACE_WATER		CONSTANT NUMBER := 9;		
EVAPORATION						CONSTANT NUMBER := 10;		
WATER_IN_PRODUCT				CONSTANT NUMBER := 11;		
WATER_IN_WASTE					CONSTANT NUMBER := 12;		
OTHER_WATER_LOSSES				CONSTANT NUMBER := 13;		

--hon haz
NH_RECYCLING					CONSTANT NUMBER := 14;		
NH_INCLUDING_ENERGY_RECOVERY	CONSTANT NUMBER := 15;		
NH_EXCLUDING_ENERGY_RECOVERY	CONSTANT NUMBER := 16;		
NH_LANDFILL						CONSTANT NUMBER := 17;		
NH_OTHER_NON_HAZ				CONSTANT NUMBER := 18;		

--haz	
H_RECYCLING						CONSTANT NUMBER := 19;		
H_INCLUDING_ENERGY_RECOVERY		CONSTANT NUMBER := 20;		
H_EXCLUDING_ENERGY_RECOVERY		CONSTANT NUMBER := 21;		
H_LANDFILL						CONSTANT NUMBER := 22;		
H_OTHER_HAZ						CONSTANT NUMBER := 23;		

PROCEDURE DeleteConsSourceBreakdown(
	in_consumption_type_id			IN  ht_cons_source_breakdown.ht_consumption_type_id%TYPE,
	in_consumption_category_id		IN  ht_cons_source_breakdown.ht_consumption_category_id%TYPE,
	in_cons_source_id				IN  ht_cons_source_breakdown.ht_cons_source_id%TYPE
);

PROCEDURE SetConsSourceBreakdown(
	in_consumption_type_id			IN  ht_cons_source_breakdown.ht_consumption_type_id%TYPE,
	in_consumption_category_id		IN  ht_cons_source_breakdown.ht_consumption_category_id%TYPE,
	in_cons_source_id				IN  ht_cons_source_breakdown.ht_cons_source_id%TYPE,
	in_amount						IN  ht_cons_source_breakdown.amount%TYPE
);

PROCEDURE DeleteConsumptionRegion(
	in_consumption_type_id			IN  ht_consumption_region.ht_consumption_type_id%TYPE,
	in_region_id					IN  ht_consumption_region.region_id%TYPE,
	in_consumption_category_id		IN  ht_consumption_region.ht_consumption_category_id%TYPE
);

PROCEDURE SetConsumptionRegion(
	in_consumption_type_id			IN  ht_consumption_region.ht_consumption_type_id%TYPE,
	in_region_id					IN  ht_consumption_region.region_id%TYPE,
	in_consumption_category_id		IN  ht_consumption_region.ht_consumption_category_id%TYPE,
	in_amount						IN  ht_consumption_region.amount%TYPE
);

PROCEDURE DeleteConsumption(
	in_consumption_type_id 			IN ht_consumption_type.ht_consumption_type_id%TYPE,
	in_consumption_category_id 		IN ht_consumption_type.ht_consumption_category_id%TYPE
);

PROCEDURE SetConsumption(
	in_consumption_type_id 			IN ht_consumption_type.ht_consumption_type_id%TYPE,
	in_consumption_category_id 		IN ht_consumption_type.ht_consumption_category_id%TYPE,	
	in_amount						IN ht_consumption.amount%TYPE,	
	in_mass_unit_id					IN ht_consumption.mass_unit_id%TYPE,	
	in_power_unit_id				IN ht_consumption.power_unit_id%TYPE,	
	in_volume_unit_id				IN ht_consumption.volume_unit_id%TYPE
);

PROCEDURE GetConsumptionsByTypeAndCat(
	in_consumption_type_id 			IN ht_consumption_type.ht_consumption_type_id%TYPE,	
	in_consumption_category_id 		IN ht_consumption_type.ht_consumption_category_id%TYPE,		
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetConsumptionsByCategory(
	in_consumption_category_id 		IN ht_consumption_type.ht_consumption_category_id%TYPE,	
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetConsumptionTypesByCategory(
	in_consumption_category_id 		IN ht_consumption_type.ht_consumption_category_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetConsumptionTypeUnitsByCat (
	in_consumption_category_id 		IN ht_consumption_type.ht_consumption_category_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetConsumptionTypeUnits(
	in_consumption_type_id 			IN ht_consumption_type.ht_consumption_type_id%TYPE,
	in_consumption_category_id 		IN ht_consumption_type.ht_consumption_category_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetConsumptionsRegionsByCateg(
	in_consumption_category_id 		IN ht_consumption_type.ht_consumption_category_id%TYPE,	
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetConsumptionSources(
	in_consumption_category_id 		IN ht_cons_source.ht_consumption_category_id%TYPE,	
	in_consumption_type_id			IN ht_cons_source.ht_consumption_type_id%TYPE,  	
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetConsumptionSourceBreakdowns( 
	in_consumption_category_id 		IN ht_cons_source.ht_consumption_category_id%TYPE,	
	in_consumption_type_id			IN ht_cons_source.ht_consumption_type_id%TYPE,  	
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

END consumption_pkg;
/