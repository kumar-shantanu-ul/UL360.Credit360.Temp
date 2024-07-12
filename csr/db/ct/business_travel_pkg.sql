CREATE OR REPLACE PACKAGE ct.business_travel_pkg AS


PROCEDURE GetRegionFactors(
    in_region_id            		IN bt_region_factors.region_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR 
);

PROCEDURE GetTravelDefaults(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetEstimateType(
	in_bt_estimate_type_id			IN  bt_estimate_type.bt_estimate_type_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetEstimateTypes(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProfile(
	in_breakdown_group_id			IN  bt_profile.breakdown_group_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetOptions(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetResults(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetResult(
	in_breakdown_group_id			IN  ct.bt_profile.breakdown_group_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetProfile(
	in_breakdown_group_id			IN  bt_profile.breakdown_group_id%TYPE,
	in_fte_who_travel_pct			IN  bt_profile.fte_who_travel_pct%TYPE,
	in_car_trips					IN  bt_profile.car_trips_ppy%TYPE,
	in_car_use_pct					IN  bt_profile.car_use_pct%TYPE,
	in_car_trip_time_min			IN  bt_profile.car_trip_time_min%TYPE,
	in_car_trip_dist				IN  bt_profile.car_trip_dist%TYPE,
	in_car_occupancy_rate			IN  bt_profile.car_occupancy_rate%TYPE,
	in_car_distance_unit_id			IN  bt_profile.car_distance_unit_id%TYPE,
	in_car_estimate_type_id			IN  bt_profile.car_estimate_type_id%TYPE,
	in_bus_trips					IN  bt_profile.bus_trips_ppy%TYPE,
	in_bus_use_pct					IN  bt_profile.bus_use_pct%TYPE,
	in_bus_trip_time_min			IN  bt_profile.bus_trip_time_min%TYPE,
	in_bus_trip_dist				IN  bt_profile.bus_trip_dist%TYPE,
	in_bus_distance_unit_id			IN  bt_profile.bus_distance_unit_id%TYPE,
	in_bus_estimate_type_id			IN  bt_profile.bus_estimate_type_id%TYPE,
	in_train_trips					IN  bt_profile.train_trips_ppy%TYPE,
	in_train_use_pct				IN  bt_profile.train_use_pct%TYPE,
	in_train_trip_time_min			IN  bt_profile.train_trip_time_min%TYPE,
	in_train_trip_dist				IN  bt_profile.train_trip_dist%TYPE,
	in_train_distance_unit_id		IN  bt_profile.train_distance_unit_id%TYPE,
	in_train_estimate_type_id		IN  bt_profile.train_estimate_type_id%TYPE,
	in_motorbike_trips				IN  bt_profile.motorbike_trips_ppy%TYPE,
	in_motorbike_use_pct			IN  bt_profile.motorbike_use_pct%TYPE,
	in_motorbike_trip_time_min		IN  bt_profile.motorbike_trip_time_min%TYPE,
	in_motorbike_trip_dist			IN  bt_profile.motorbike_trip_dist%TYPE,
	in_motorbike_distance_unit_id	IN  bt_profile.motorbike_distance_unit_id%TYPE,
	in_motorbike_estimate_type_id	IN  bt_profile.motorbike_estimate_type_id%TYPE,
	in_bike_trips					IN  bt_profile.bike_trips_ppy%TYPE,
	in_bike_use_pct					IN  bt_profile.bike_use_pct%TYPE,
	in_bike_trip_time_min			IN  bt_profile.bike_trip_time_min%TYPE,
	in_bike_trip_dist				IN  bt_profile.bike_trip_dist%TYPE,
	in_bike_distance_unit_id		IN  bt_profile.bike_distance_unit_id%TYPE,
	in_bike_estimate_type_id		IN  bt_profile.bike_estimate_type_id%TYPE,
	in_walk_trips					IN  bt_profile.walk_trips_ppy%TYPE,
	in_walk_use_pct					IN  bt_profile.walk_use_pct%TYPE,
	in_walk_trip_time_min			IN  bt_profile.walk_trip_time_min%TYPE,
	in_walk_trip_dist				IN  bt_profile.walk_trip_dist%TYPE,
	in_walk_distance_unit_id		IN  bt_profile.walk_distance_unit_id%TYPE,
	in_walk_estimate_type_id		IN  bt_profile.walk_estimate_type_id%TYPE,
	in_air_trips					IN  bt_profile.air_trips_ppy%TYPE,
	in_air_use_pct					IN  bt_profile.air_use_pct%TYPE,
	in_air_trip_time_min			IN  bt_profile.air_trip_time_min%TYPE,
	in_air_trip_dist				IN  bt_profile.air_trip_dist%TYPE,
	in_air_distance_unit_id			IN  bt_profile.air_distance_unit_id%TYPE,
	in_air_estimate_type_id			IN  bt_profile.air_estimate_type_id%TYPE, 
	in_is_default					IN 	NUMBER
);

PROCEDURE GetModesOfTransport(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTravelModeTypes(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetOptions(
	in_include_hotel_stays			IN  bt_options.include_hotel_stays%TYPE,
	in_breakdown_type_id			IN  bt_options.breakdown_type_id%TYPE,
	in_temp_extrapolation_type_id	IN  bt_options.temporal_extrapolation_type_id%TYPE,
	in_temp_extrapolation_months	IN  bt_options.temporal_extrapolation_months%TYPE,
	in_emp_extrapolation_type_id	IN  bt_options.employee_extrapolation_type_id%TYPE,
	in_emp_extrapolation_pct		IN  bt_options.employee_extrapolation_pct%TYPE
);

PROCEDURE SaveResult(
    in_breakdown_id 			IN bt_emissions.breakdown_id%TYPE,
    in_region_id 				IN bt_emissions.region_id%TYPE,
	in_calculation_source_id	IN bt_calculation_source.calculation_source_id%TYPE,
    in_car_kg_co2 				IN bt_emissions.car_kg_co2%TYPE,
    in_bus_kg_co2 				IN bt_emissions.bus_kg_co2%TYPE,
    in_train_kg_co2 			IN bt_emissions.train_kg_co2%TYPE,
    in_motorbike_kg_co2			IN bt_emissions.motorbike_kg_co2%TYPE,
    in_bike_kg_co2 				IN bt_emissions.bike_kg_co2%TYPE,
    in_walk_kg_co2 				IN bt_emissions.walk_kg_co2%TYPE,
    in_air_kg_co2 				IN bt_emissions.air_kg_co2%TYPE
);

END business_travel_pkg;
/
