CREATE OR REPLACE PACKAGE ct.admin_pkg AS

ROW_COUNTRY_CODE_ID CONSTANT NUMBER := 0; 
USA_COUNTRY_CODE CONSTANT VARCHAR2(2) := 'us';

--COMMON
PROCEDURE SetPeriodUSDBaseYearRatio(
	in_period_id 						IN	period.period_id%TYPE,
	in_usd_ratio_to_base_yr				IN period.usd_ratio_to_base_yr%TYPE
);

--HOTSPOT
PROCEDURE SetEIO (
	in_eio_id 							IN	eio.eio_id%TYPE, 
	in_description 						IN	eio.description%TYPE, 
	in_eio_group_id 					IN	eio.eio_group_id%TYPE, 
	in_emis_fctr_c_to_g_inc_use_ph		IN	eio.emis_fctr_c_to_g_inc_use_ph%TYPE, 
	in_emis_fctr_c_to_g 				IN	eio.emis_fctr_c_to_g%TYPE, 
	in_pct_elec_energy 					IN	eio.pct_elec_energy%TYPE, 
	in_pct_other_energy 				IN	eio.pct_other_energy%TYPE, 
	in_pct_use_phase 					IN	eio.pct_use_phase%TYPE, 
	in_pct_warehouse 					IN	eio.pct_warehouse%TYPE, 
	in_pct_waste	 					IN	eio.pct_waste%TYPE, 
	in_pct_upstream_trans 				IN	eio.pct_upstream_trans%TYPE, 
	in_pct_downstream_trans 			IN	eio.pct_downstream_trans%TYPE, 
	in_pct_ctfc_scope_one_two			IN	eio.pct_ctfc_scope_one_two%TYPE
);

PROCEDURE SetEIOPctRelationship (
	in_primary_eio_cat_id 				IN	eio.eio_id%TYPE, 
	in_related_eio_cat_id 				IN	eio.eio_id%TYPE, 
	in_pct								IN	eio_relationship.pct%TYPE
);

PROCEDURE SetEIOGroup (
	in_eio_group_id						IN	eio_group.eio_group_id%TYPE,
	in_eio_group						IN	eio_group.description%TYPE, 
	in_hide								IN  eio_group.hide%TYPE
);

PROCEDURE SetCurrencyPeriodData (
	in_period_id						IN currency_period.period_id%TYPE,
	in_currency_id						IN currency_period.currency_id%TYPE,
	in_purchse_pwr_parity_fact			IN currency_period.purchse_pwr_parity_fact%TYPE, 
	in_conversion_to_dollar			IN currency_period.conversion_to_dollar%TYPE
);

PROCEDURE SetHotRegion (
	in_region_id						IN hot_region.region_id%TYPE,
	in_full_lifecycle_ef				IN hot_region.full_lifecycle_ef%TYPE,
	in_combusition_ef					IN hot_region.combusition_ef%TYPE
);

--EMPLOYEE COMMUTE

FUNCTION GetManufacturerId (
	in_name							IN ec_car_manufacturer.manufacturer%TYPE
) RETURN ec_car_manufacturer.manufacturer_id%TYPE;

PROCEDURE SetEcRegion (
    in_region_id                     IN ec_region_factors.region_id%TYPE,
    in_holidays                      IN ec_region_factors.holidays%TYPE,
    in_car_avg_pct_use               IN ec_region_factors.car_avg_pct_use%TYPE,
    in_bus_avg_pct_use               IN ec_region_factors.bus_avg_pct_use%TYPE,
    in_train_avg_pct_use             IN ec_region_factors.train_avg_pct_use%TYPE,
    in_motorbike_avg_pct_use         IN ec_region_factors.motorbike_avg_pct_use%TYPE,
    in_bike_avg_pct_use              IN ec_region_factors.bike_avg_pct_use%TYPE,
    in_walk_avg_pct_use              IN ec_region_factors.walk_avg_pct_use%TYPE,
    in_car_avg_journey_km            IN ec_region_factors.car_avg_journey_km%TYPE,
    in_bus_avg_journey_km            IN ec_region_factors.bus_avg_journey_km%TYPE,
    in_train_avg_journey_km          IN ec_region_factors.train_avg_journey_km%TYPE,
    in_motorbike_avg_journey_km      IN ec_region_factors.motorbike_avg_journey_km%TYPE,
    in_bike_avg_journey_km           IN ec_region_factors.bike_avg_journey_km%TYPE,
    in_walk_avg_journey_km           IN ec_region_factors.walk_avg_journey_km%TYPE
);

PROCEDURE SetCarType (
	in_car_type_id					IN	ec_car_type.car_type_id%TYPE,
	in_description					IN	ec_car_type.description%TYPE,
	in_kg_co2_per_km_contribution	IN	ec_car_type.kg_co2_per_km_contribution%TYPE
);

PROCEDURE SetBusType (
	in_bus_type_id					IN	ec_bus_type.bus_type_id%TYPE,
	in_description					IN	ec_bus_type.description%TYPE,
	in_kg_co2_per_km_contribution	IN	ec_bus_type.kg_co2_per_km_contribution%TYPE
);

PROCEDURE SetTrainType (
	in_train_type_id				IN	ec_train_type.train_type_id%TYPE,
	in_description					IN	ec_train_type.description%TYPE,
	in_kg_co2_per_km_contribution	IN	ec_train_type.kg_co2_per_km_contribution%TYPE
);

PROCEDURE SetMotorbikeType (
	in_motorbike_type_id			IN	ec_motorbike_type.motorbike_type_id%TYPE,
	in_description					IN	ec_motorbike_type.description%TYPE,
	in_kg_co2_per_km_contribution	IN	ec_motorbike_type.kg_co2_per_km_contribution%TYPE
);

PROCEDURE SetManufacturer (
	in_manufacturer_id				IN	ec_car_manufacturer.manufacturer_id%TYPE,
	in_manufacturer					IN	ec_car_manufacturer.manufacturer%TYPE
);

PROCEDURE SetCarModel (                
    in_description                  IN ec_car_model.description%TYPE,                 
    in_manufacturer              	IN ec_car_manufacturer.manufacturer%TYPE,             
    in_efficiency_ltr_per_100km     IN ec_car_model.efficiency_ltr_per_km%TYPE, 
	in_fuel_type_id					IN ec_fuel_type.fuel_type_id%TYPE,
	in_transmission					IN ec_car_model.transmission%TYPE  
);

PROCEDURE GetTemplateKeys(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE StoreUploadedReportTemplate(
	in_lookup_key					IN  report_template.lookup_key%TYPE,
	in_cache_key					IN  aspen2.filecache.cache_key%TYPE
);

PROCEDURE GetReportTemplate(
	in_lookup_key					IN  report_template.lookup_key%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);


END admin_pkg;
/
