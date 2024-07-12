CREATE OR REPLACE PACKAGE BODY ct.business_travel_pkg AS

PROCEDURE GetRegionFactors(
    in_region_id            		IN bt_region_factors.region_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR 
)
AS
	v_cnt							NUMBER := 0;
BEGIN

	SELECT COUNT(*) INTO v_cnt
	  FROM bt_region_factors 
	 WHERE region_id = in_region_id;
	
	-- if the region doesn't exist fall back to Rest Of World figure
	IF v_cnt > 0 THEN
		OPEN out_cur FOR
			SELECT 	   region_id, temp_emission_factor, car_use_pct, 
					   car_avg_dist_km, car_avg_speed_km, car_occupancy_rate, 
					   bus_use_pct, bus_avg_dist_km, bus_avg_speed_km, 
					   train_use_pct, train_avg_dist_km, train_avg_speed_km, 
					   motorbike_use_pct, motorbike_avg_dist_km, motorbike_avg_speed_km, 
					   bike_use_pct, bike_avg_dist_km, bike_avg_speed_km, 
					   walk_use_pct, walk_avg_dist_km, walk_avg_speed_km, 
					   air_use_pct, air_avg_dist_km, air_avg_speed_km, 
					   air_radiative_forcing, avg_num_trips_yr, 0 is_row 
			  FROM bt_region_factors 
			 WHERE region_id = in_region_id;
	ELSE
		OPEN out_cur FOR
			SELECT region_id, temp_emission_factor, car_use_pct, 
					   car_avg_dist_km, car_avg_speed_km, car_occupancy_rate, 
					   bus_use_pct, bus_avg_dist_km, bus_avg_speed_km, 
					   train_use_pct, train_avg_dist_km, train_avg_speed_km, 
					   motorbike_use_pct, motorbike_avg_dist_km, motorbike_avg_speed_km, 
					   bike_use_pct, bike_avg_dist_km, bike_avg_speed_km, 
					   walk_use_pct, walk_avg_dist_km, walk_avg_speed_km, 
					   air_use_pct, air_avg_dist_km, air_avg_speed_km, 
					   air_radiative_forcing, avg_num_trips_yr, 1 is_row 
			  FROM bt_region_factors 
			 WHERE region_id = admin_pkg.ROW_COUNTRY_CODE_ID;
	END IF;
		
END;

PROCEDURE GetTravelDefaults(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_car_kg_co2e_per_km NUMBER := 0.0;
	v_bus_kg_co2e_per_km NUMBER := 0.0;
	v_train_kg_co2e_per_km NUMBER := 0.0;
	v_motorbike_kg_co2e_per_km NUMBER := 0.0;
	v_air_kg_co2e_per_km NUMBER := 0.0;
BEGIN

    SELECT ef_kg_co2_per_km 
	  INTO v_car_kg_co2e_per_km
      FROM bt_travel_mode btm
      JOIN bt_travel_mode_type btmt ON btm.bt_travel_mode_type_id = btmt.bt_travel_mode_type_id
      JOIN travel_mode tm ON btmt.travel_mode_id = tm.travel_mode_id      
     WHERE is_default = 1 
       AND tm.travel_mode_id = ct_pkg.CAR_TRAVEL_MODE;
	   
    SELECT ef_kg_co2_per_km 
	  INTO v_bus_kg_co2e_per_km
      FROM bt_travel_mode btm
      JOIN bt_travel_mode_type btmt ON btm.bt_travel_mode_type_id = btmt.bt_travel_mode_type_id
      JOIN travel_mode tm ON btmt.travel_mode_id = tm.travel_mode_id      
     WHERE is_default = 1 
       AND tm.travel_mode_id = ct_pkg.BUS_TRAVEL_MODE;
	
    SELECT ef_kg_co2_per_km 
	  INTO v_train_kg_co2e_per_km
      FROM bt_travel_mode btm
      JOIN bt_travel_mode_type btmt ON btm.bt_travel_mode_type_id = btmt.bt_travel_mode_type_id
      JOIN travel_mode tm ON btmt.travel_mode_id = tm.travel_mode_id      
     WHERE is_default = 1 
       AND tm.travel_mode_id = ct_pkg.TRAIN_TRAVEL_MODE;	
	   
    SELECT ef_kg_co2_per_km 
	  INTO v_motorbike_kg_co2e_per_km
      FROM bt_travel_mode btm
      JOIN bt_travel_mode_type btmt ON btm.bt_travel_mode_type_id = btmt.bt_travel_mode_type_id
      JOIN travel_mode tm ON btmt.travel_mode_id = tm.travel_mode_id      
     WHERE is_default = 1 
       AND tm.travel_mode_id = ct_pkg.MBIKE_TRAVEL_MODE;	
	   
    SELECT ef_kg_co2_per_km 
	  INTO v_air_kg_co2e_per_km
      FROM bt_travel_mode btm
      JOIN bt_travel_mode_type btmt ON btm.bt_travel_mode_type_id = btmt.bt_travel_mode_type_id
      JOIN travel_mode tm ON btmt.travel_mode_id = tm.travel_mode_id      
     WHERE is_default = 1 
       AND tm.travel_mode_id = ct_pkg.AIR_TRAVEL_MODE;	
	
	OPEN out_cur FOR
		SELECT 
			v_car_kg_co2e_per_km car_kg_co2e_per_km, 
			v_bus_kg_co2e_per_km bus_kg_co2e_per_km, 
			v_train_kg_co2e_per_km train_kg_co2e_per_km, 
			v_motorbike_kg_co2e_per_km motorbike_kg_co2e_per_km, 
			v_air_kg_co2e_per_km air_kg_co2e_per_km
		  FROM dual;
END;

PROCEDURE GetEstimateType(
	in_bt_estimate_type_id			IN  bt_estimate_type.bt_estimate_type_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT bt_estimate_type_id id,
		       description
		  FROM bt_estimate_type
		 WHERE bt_estimate_type_id = in_bt_estimate_type_id;
END;

PROCEDURE GetEstimateTypes(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT bt_estimate_type_id id,
		       description
		  FROM bt_estimate_type;
END;

PROCEDURE GetProfile(
	in_breakdown_group_id			IN  bt_profile.breakdown_group_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_BUSINESS_TRAVEL) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify business travel data');
	END IF;

	OPEN out_cur FOR
		SELECT breakdown_group_id, 
		       fte_who_travel_pct, 
		       car_trips_ppy car_trips, 
		       car_use_pct, 
		       car_trip_time_min, 
		       car_trip_dist, 
		       car_distance_unit_id, 
		       car_estimate_type_id, 
		       bus_trips_ppy bus_trips, 
		       bus_use_pct, 
		       bus_trip_time_min, 
		       bus_trip_dist, 
		       bus_distance_unit_id, 
		       bus_estimate_type_id, 
		       train_trips_ppy train_trips, 
		       train_use_pct, 
		       train_trip_time_min, 
		       train_trip_dist, 
		       train_distance_unit_id, 
		       train_estimate_type_id, 
		       motorbike_trips_ppy motorbike_trips, 
		       motorbike_use_pct, 
		       motorbike_trip_time_min, 
		       motorbike_trip_dist, 
		       motorbike_distance_unit_id, 
		       motorbike_estimate_type_id, 
		       bike_trips_ppy bike_trips, 
		       bike_use_pct, 
		       bike_trip_time_min, 
		       bike_trip_dist, 
		       bike_distance_unit_id, 
		       bike_estimate_type_id, 
		       walk_trips_ppy walk_trips, 
		       walk_use_pct, 
		       walk_trip_time_min, 
		       walk_trip_dist, 
		       walk_distance_unit_id, 
		       walk_estimate_type_id, 
		       air_trips_ppy air_trips, 
		       air_use_pct, 
		       air_trip_time_min, 
		       air_trip_dist, 
		       air_distance_unit_id, 
		       air_estimate_type_id, 
			   car_occupancy_rate,
			   DECODE(modified_by_sid, NULL, 1, 0) is_default
		  FROM bt_profile
		 WHERE app_sid = security_pkg.getApp
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND breakdown_group_id = in_breakdown_group_id;
END;

PROCEDURE GetOptions(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	--IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_BUSINESS_TRAVEL) THEN
	--	RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify business travel data');
	--END IF;
	
	-- TO DO - review this - needed in hotspotter model
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to read Business Travel options');
	END IF;
	
	OPEN out_cur FOR
		SELECT include_hotel_stays,
		       breakdown_type_id,
			   temporal_extrapolation_type_id,
	           temporal_extrapolation_months,
	           employee_extrapolation_type_id,
	           employee_extrapolation_pct
		  FROM bt_options
		 WHERE app_sid = security_pkg.getApp
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
END;

PROCEDURE GetResults(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetResult(null, out_cur);
END;

PROCEDURE GetResult(
	in_breakdown_group_id			IN  ct.bt_profile.breakdown_group_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_BUSINESS_TRAVEL) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify business travel data');
	END IF;
	
	-- emissions in kg Co2 
	OPEN out_cur FOR
        SELECT  e.breakdown_group_id, total_fte,
                ROUND(total_emissions/1000, 0) total_emissions_tonnes, 
                ROUND(DECODE(total_fte, 0, 0, total_emissions/total_fte) /10, 0)*10 emissions_per_fte, 
                ROUND(DECODE(total_fte, 0, 0, total_emissions/total_fte)/365,1) emissions_per_fte_per_day, 
                NVL2(modified_by_sid, 0, 1) is_default, modified_by_sid
        FROM
        (
            SELECT bg.breakdown_group_id,
                   SUM(car_kg_co2 + bus_kg_co2 + train_kg_co2 + motorbike_kg_co2 + bike_kg_co2 + walk_kg_co2 + air_kg_co2) total_emissions, 
                   SUM(b.fte) total_fte
              FROM bt_emissions bte
              JOIN breakdown_region_group brg ON bte.breakdown_id = brg.breakdown_id AND bte.region_id = brg.region_id AND bte.app_sid = brg.app_sid
              JOIN breakdown b ON b.breakdown_id = bte.breakdown_id AND b.app_sid = bte.app_sid
              JOIN breakdown_group bg ON brg.breakdown_group_id = bg.breakdown_group_id AND brg.app_sid = bg.app_sid
			  JOIN bt_options o ON bte.app_sid = o.app_sid
             WHERE bg.breakdown_group_id = NVL(in_breakdown_group_id, bg.breakdown_group_id)
               AND bg.group_key = 'BT'
			   AND bte.app_sid = security_pkg.getApp
			   AND bte.breakdown_id IN (SELECT breakdown_id FROM breakdown WHERE breakdown_type_id = o.breakdown_type_id)
               AND bte.calculation_source_id = ct_pkg.BT_DS_PROFILE
			GROUP BY bg.breakdown_group_id
        ) e, bt_profile btp
         WHERE e.breakdown_group_id = btp.breakdown_group_id(+)
           AND btp.app_sid = security_pkg.getApp
           AND btp.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
		
	
END;

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
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_BUSINESS_TRAVEL) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify business travel data');
	END IF;
	
	BEGIN
		INSERT INTO bt_profile (app_sid, company_sid, breakdown_group_id, fte_who_travel_pct, car_trips_ppy, car_use_pct, 
								car_trip_time_min, car_trip_dist, car_distance_unit_id, car_estimate_type_id, car_occupancy_rate,
								bus_trips_ppy, bus_use_pct, bus_trip_time_min, bus_trip_dist, bus_distance_unit_id,
								bus_estimate_type_id, train_trips_ppy, train_use_pct, train_trip_time_min, 
								train_trip_dist, train_distance_unit_id, train_estimate_type_id, motorbike_trips_ppy,
								motorbike_use_pct, motorbike_trip_time_min, motorbike_trip_dist, motorbike_distance_unit_id,
								motorbike_estimate_type_id, bike_trips_ppy, bike_use_pct, bike_trip_time_min,
								bike_trip_dist, bike_distance_unit_id, bike_estimate_type_id, walk_trips_ppy,
								walk_use_pct, walk_trip_time_min, walk_trip_dist, walk_distance_unit_id, 
								walk_estimate_type_id, air_trips_ppy, air_use_pct, air_trip_time_min, air_trip_dist,
								air_distance_unit_id, air_estimate_type_id, modified_by_sid, last_modified_dtm)
		VALUES (security_pkg.getApp, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_breakdown_group_id, in_fte_who_travel_pct, 
				in_car_trips, in_car_use_pct, in_car_trip_time_min, in_car_trip_dist, in_car_distance_unit_id, 
				in_car_estimate_type_id, in_car_occupancy_rate, in_bus_trips, in_bus_use_pct, in_bus_trip_time_min, in_bus_trip_dist, 
				in_bus_distance_unit_id, in_bus_estimate_type_id, in_train_trips, in_train_use_pct, in_train_trip_time_min, 
				in_train_trip_dist, in_train_distance_unit_id, in_train_estimate_type_id, in_motorbike_trips, 
				in_motorbike_use_pct, in_motorbike_trip_time_min, in_motorbike_trip_dist, in_motorbike_distance_unit_id, 
				in_motorbike_estimate_type_id, in_bike_trips, in_bike_use_pct, in_bike_trip_time_min, in_bike_trip_dist, 
				in_bike_distance_unit_id, in_bike_estimate_type_id, in_walk_trips, in_walk_use_pct, in_walk_trip_time_min, 
				in_walk_trip_dist, in_walk_distance_unit_id, in_walk_estimate_type_id, in_air_trips, in_air_use_pct, 
				in_air_trip_time_min, in_air_trip_dist, in_air_distance_unit_id, in_air_estimate_type_id, 
				DECODE(in_is_default, 1, null, SYS_CONTEXT('SECURITY', 'SID')), DECODE(in_is_default, 1, null, SYSDATE));
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN	
		UPDATE bt_profile
		   SET fte_who_travel_pct = in_fte_who_travel_pct,
			   car_trips_ppy = in_car_trips,
			   car_use_pct = in_car_use_pct,
			   car_trip_time_min = in_car_trip_time_min,
			   car_trip_dist = in_car_trip_dist,
			   car_distance_unit_id = in_car_distance_unit_id,
			   car_estimate_type_id = in_car_estimate_type_id,
			   bus_trips_ppy = in_bus_trips,
			   bus_use_pct = in_bus_use_pct,
			   bus_trip_time_min = in_bus_trip_time_min,
			   bus_trip_dist = in_bus_trip_dist,
			   bus_distance_unit_id = in_bus_distance_unit_id,
			   bus_estimate_type_id = in_bus_estimate_type_id,
			   train_trips_ppy = in_train_trips,
			   train_use_pct = in_train_use_pct,
			   train_trip_time_min = in_train_trip_time_min,
			   train_trip_dist = in_train_trip_dist,
			   train_distance_unit_id = in_train_distance_unit_id,
			   train_estimate_type_id = in_train_estimate_type_id,
			   motorbike_trips_ppy = in_motorbike_trips,
			   motorbike_use_pct = in_motorbike_use_pct,
			   motorbike_trip_time_min = in_motorbike_trip_time_min,
			   motorbike_trip_dist = in_motorbike_trip_dist,
			   motorbike_distance_unit_id = in_motorbike_distance_unit_id,
			   motorbike_estimate_type_id = in_motorbike_estimate_type_id,
			   bike_trips_ppy = in_bike_trips,
			   bike_use_pct = in_bike_use_pct,
			   bike_trip_time_min = in_bike_trip_time_min,
			   bike_trip_dist = in_bike_trip_dist,
			   bike_distance_unit_id = in_bike_distance_unit_id,
			   bike_estimate_type_id = in_bike_estimate_type_id,
			   walk_trips_ppy = in_walk_trips,
			   walk_use_pct = in_walk_use_pct,
			   walk_trip_time_min = in_walk_trip_time_min,
			   walk_trip_dist = in_walk_trip_dist,
			   walk_distance_unit_id = in_walk_distance_unit_id,
			   walk_estimate_type_id = in_walk_estimate_type_id,
			   air_trips_ppy = in_air_trips,
			   air_use_pct = in_air_use_pct,
			   air_trip_time_min = in_air_trip_time_min,
			   air_trip_dist = in_air_trip_dist,
			   air_distance_unit_id = in_air_distance_unit_id,
			   air_estimate_type_id = in_air_estimate_type_id,
			   modified_by_sid = DECODE(in_is_default, 1, null, SYS_CONTEXT('SECURITY', 'SID')), -- don't set for default profile
			   last_modified_dtm = DECODE(in_is_default, 1, null, SYSDATE) -- don't set for default profile
		 WHERE app_sid = security_pkg.getApp
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND breakdown_group_id = in_breakdown_group_id;
	END;
END;

PROCEDURE GetModesOfTransport(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT bt_travel_mode_id id,
		       bt_travel_mode_type_id travel_mode_type_id,
		       description,
		       ef_kg_co2_per_km,
		       eio_kg_co2_per_gbp
		  FROM bt_travel_mode;
END;

PROCEDURE GetTravelModeTypes(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT bt_travel_mode_type_id id,
		       travel_mode_id,
		       description
		  FROM bt_travel_mode_type;
END;

PROCEDURE SetOptions(
	in_include_hotel_stays			IN  bt_options.include_hotel_stays%TYPE,
	in_breakdown_type_id			IN  bt_options.breakdown_type_id%TYPE,
	in_temp_extrapolation_type_id	IN  bt_options.temporal_extrapolation_type_id%TYPE,
	in_temp_extrapolation_months	IN  bt_options.temporal_extrapolation_months%TYPE,
	in_emp_extrapolation_type_id	IN  bt_options.employee_extrapolation_type_id%TYPE,
	in_emp_extrapolation_pct		IN  bt_options.employee_extrapolation_pct%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.ADMIN_BUSINESS_TRAVEL) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify business travel data');
	END IF;
	
	BEGIN
		INSERT INTO bt_options (app_sid, company_sid, include_hotel_stays, breakdown_type_id, temporal_extrapolation_type_id, 
		                        temporal_extrapolation_months, employee_extrapolation_type_id, employee_extrapolation_pct)
		     VALUES (security_pkg.getApp, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_include_hotel_stays, in_breakdown_type_id,
			         in_temp_extrapolation_type_id, in_temp_extrapolation_months, in_emp_extrapolation_type_id, in_emp_extrapolation_pct); 
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE bt_options
			   SET include_hotel_stays = in_include_hotel_stays,
			       breakdown_type_id = in_breakdown_type_id,
				   temporal_extrapolation_type_id = in_temp_extrapolation_type_id,
			       temporal_extrapolation_months = in_temp_extrapolation_months,
			       employee_extrapolation_type_id = in_emp_extrapolation_type_id,
			       employee_extrapolation_pct = in_emp_extrapolation_pct
			 WHERE app_sid = security_pkg.getApp
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');	
	END;
END;

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
)
AS
BEGIN

	-- used in hotspotter - so this isn't a mistake
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing hotspot results data');
	END IF;
	
	DELETE FROM bt_emissions 
	 WHERE breakdown_id = in_breakdown_id
	   AND region_id = in_region_id
	   AND calculation_source_id = in_calculation_source_id
	   AND app_sid = security_pkg.GetApp;


	INSERT INTO bt_emissions
	(
		breakdown_id,
		region_id,
		calculation_source_id,
		car_kg_co2,
		bus_kg_co2,
		train_kg_co2,
		motorbike_kg_co2,
		bike_kg_co2,
		walk_kg_co2,
		air_kg_co2
	)VALUES
	(
		in_breakdown_id,
		in_region_id,
		in_calculation_source_id,
		in_car_kg_co2,
		in_bus_kg_co2,
		in_train_kg_co2,
		in_motorbike_kg_co2,
		in_bike_kg_co2,
		in_walk_kg_co2,
		in_air_kg_co2
	);

	
END;



END  business_travel_pkg;
/
