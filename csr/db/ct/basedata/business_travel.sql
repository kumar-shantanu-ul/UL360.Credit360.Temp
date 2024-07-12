SET SERVEROUTPUT ON;

SET DEFINE $;

	-- Estimate Type
	INSERT INTO ct.bt_estimate_type (bt_estimate_type_id, description) VALUES (1, 'Use Fuel');  
	INSERT INTO ct.bt_estimate_type (bt_estimate_type_id, description) VALUES (2, 'Use Distance');
	INSERT INTO ct.bt_estimate_type (bt_estimate_type_id, description) VALUES (3, 'Use Time');
	INSERT INTO ct.bt_estimate_type (bt_estimate_type_id, description) VALUES (4, 'Use Spend');

  -- bt fuel (TO DO - finish) 
   INSERT INTO ct.bt_fuel (bt_fuel_id, description) VALUES (1, 'Petrol');
   INSERT INTO ct.bt_fuel (bt_fuel_id, description) VALUES (2, 'Diesel');
   INSERT INTO ct.bt_fuel (bt_fuel_id, description) VALUES (3, 'PetrolDieselAverage');
   INSERT INTO ct.bt_fuel (bt_fuel_id, description) VALUES (4, 'LPG');

	-- 0 = R.O.W
	INSERT INTO ct.BT_REGION_FACTORS
	(
		region_id,
		temp_emission_factor,
		car_use_pct,
		car_avg_dist_km,
		car_avg_speed_km,
		car_occupancy_rate,
		bus_use_pct,
		bus_avg_dist_km,
		bus_avg_speed_km,
		train_use_pct,
		train_avg_dist_km,
		train_avg_speed_km,
		motorbike_use_pct,
		motorbike_avg_dist_km,
		motorbike_avg_speed_km,
		bike_use_pct,
		bike_avg_dist_km,
		bike_avg_speed_km,
		walk_use_pct,
		walk_avg_dist_km,
		walk_avg_speed_km,
		air_use_pct,
		air_avg_dist_km,
		air_avg_speed_km,
		air_radiative_forcing,
		avg_num_trips_yr
	) VALUES (
		0, 
		950.9254615598, 
		-- car
		66.2119654884092, 30.6184431804587, 45.9055138217822, 1.2,
		-- bus
		4.30157858315628, 7.79820075759278, 20.8045066666667,
		-- train
		4.57077732695799, 79.1498071748709, 68.2396342857143,
		-- motorbike
		0, 0, 47.6376446732673,
		-- bike
		1.72934848388814, 7.04824721941331, 18.00,
		-- walk
		7.18633011758843, 1.84620349211769, 5,
		--air
		16.000, 1313.22, 855.427456, 1.9,
		-- av num business trips
		30	
	);
	
	-- bt travel mode types
	INSERT INTO CT.BT_TRAVEL_MODE_TYPE (BT_TRAVEL_MODE_TYPE_ID, TRAVEL_MODE_ID, DESCRIPTION) VALUES (1, 1, 'Car');
	INSERT INTO CT.BT_TRAVEL_MODE_TYPE (BT_TRAVEL_MODE_TYPE_ID, TRAVEL_MODE_ID, DESCRIPTION) VALUES (2, 1, 'Cab');
	INSERT INTO CT.BT_TRAVEL_MODE_TYPE (BT_TRAVEL_MODE_TYPE_ID, TRAVEL_MODE_ID, DESCRIPTION) VALUES (3, 2, 'Bus');
	INSERT INTO CT.BT_TRAVEL_MODE_TYPE (BT_TRAVEL_MODE_TYPE_ID, TRAVEL_MODE_ID, DESCRIPTION) VALUES (4, 3, 'Train');
	INSERT INTO CT.BT_TRAVEL_MODE_TYPE (BT_TRAVEL_MODE_TYPE_ID, TRAVEL_MODE_ID, DESCRIPTION) VALUES (5, 4, 'Motorbike');
	INSERT INTO CT.BT_TRAVEL_MODE_TYPE (BT_TRAVEL_MODE_TYPE_ID, TRAVEL_MODE_ID, DESCRIPTION) VALUES (6, 7, 'Air');
	
    -- bt travel modes 
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Small petrol car',1,0.1983,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Medium petrol car',1,0.24927,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Large petrol car',1,0.35773,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average petrol car',1,0.24234,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Small diesel car',1,0.17137,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Medium diesel car',1,0.21291,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Large diesel car',1,0.28267,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average diesel car',1,0.22428,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Small car - unknown fuel',1,0.17,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Medium car - unknown fuel',1,0.2,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Large car - unknown fuel',1,0.27,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average car - unknown fuel',1,0.2,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Medium petrol hybrid car',1,0.13984,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Large petrol hybrid car',1,0.2481,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average petrol hybrid car',1,0.1617,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Medium LPG car',1,0.21373,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Large LPG car',1,0.30626,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average LPG car',1,0.24142,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Medium CNG car',1,0.19636,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Large CNG car',1,0.28116,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average CNG car',1,0.22173,6.42143649912795);    
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Petrol van (Class I)',1,0.23963,3.17107975265578);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Petrol van (Class II)',1,0.25521,3.17107975265578);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Petrol van (Class III)',1,0.31079,3.17107975265578);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average petrol van ',1,0.25646,3.17107975265578);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Diesel van (Class I)',1,0.18579,3.17107975265578);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Diesel van (Class II)',1,0.27402,3.17107975265578);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Diesel van (Class III)',1,0.32302,3.17107975265578);
	INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average diesel van ',1,0.30193,3.17107975265578);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average LPG van ',1,0.29599,3.17107975265578);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average CNG van ',1,0.27602,3.17107975265578);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average van - unknown fuel',1,0.25,3.17107975265578);
	
	INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Regular taxi',2,0.233268571428571,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'London cab',2,0.28267,6.42143649912795);
	
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'London local bus',3,0.10005,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average local bus',3,0.13552,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Coach ',3,0.03471,6.42143649912795);
	
	INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'International rail ',4,0.01715,1.74409386396068);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Domestic rail',4,0.06715,1.74409386396068);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Light rail and tram ',4,0.07659,1.74409386396068);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Metro',4,0.08154,1.74409386396068);
	
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Small petrol motorbike',5,0.10482,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Medium petrol motorbike',5,0.12717,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Large petrol motorbike',5,0.16742,6.42143649912795);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average petrol motorbike',5,0.14238,6.42143649912795);
	
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'UK domestic air travel - average',6,0.20124,4.74076423022039);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Short haul air travel - economy class',6,0.10946,4.74076423022039);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Short haul air travel - business class',6,0.16419,4.74076423022039);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Short haul air travel - average',6,0.11486,4.74076423022039);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Long haul air travel - economy class',6,0.09594,4.74076423022039);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Long haul air travel - premium economy class',6,0.15351,4.74076423022039);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Long haul air travel- Business class',6,0.27823,4.74076423022039);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Long haul air travel - First class',6,0.38378,4.74076423022039);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Long haul air travel - average',6,0.13143,4.74076423022039);
    INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, bt_travel_mode_type_id, ef_kg_co2_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average air travel',6,0.13,3.56964);
	
	--- Set travel mode defaults
	UPDATE ct.bt_travel_mode SET is_default = 1 WHERE description = 'Average petrol car';
	UPDATE ct.bt_travel_mode SET is_default = 1 WHERE description = 'Average petrol motorbike';
	UPDATE ct.bt_travel_mode SET is_default = 1 WHERE description = 'Average local bus';
	UPDATE ct.bt_travel_mode SET is_default = 1 WHERE description = 'Domestic rail';
	UPDATE ct.bt_travel_mode SET is_default = 1 WHERE description = 'Average air travel';    

DECLARE
    v_id    NUMBER;
BEGIN
   -- data sources 
   
   -- average travel pattern
   INSERT INTO ct.data_source (data_source_id, key, source_description) VALUES (ct.data_source_id_seq.nextval, 'avg_business_travel_region_0', 'Average business travel patterns (sources {0}, {1})') RETURNING data_source_id INTO v_id;
   INSERT INTO ct.data_source_url (data_source_id, url_pos_id, text, url) VALUES(v_id, 0, '1', 'http://www.dft.gov.uk/statistics/series/national-travel-survey/');
   INSERT INTO ct.data_source_url (data_source_id, url_pos_id, text, url) VALUES(v_id, 1, '2', 'http://assets.dft.gov.uk/statistics/series/national-travel-survey/commuting.xls');
   
   -- travel per person 
   INSERT INTO ct.data_source (data_source_id, key, source_description) VALUES (ct.data_source_id_seq.nextval, 'avg_num_business_trips_region_0', 'Average number of business trips per year per person ({0})') RETURNING data_source_id INTO v_id;
   INSERT INTO ct.data_source_url (data_source_id, url_pos_id, text, url) VALUES(v_id, 0, 'source', 'http://assets.dft.gov.uk/statistics/series/national-travel-survey/commuting.pdf');

    -- radiative forcing 
   INSERT INTO ct.data_source (data_source_id, key, source_description) VALUES (ct.data_source_id_seq.nextval, 'radiative_forcing_region_0', 'Radiative forcing factor ({0})') RETURNING data_source_id INTO v_id;
   INSERT INTO ct.data_source_url (data_source_id, url_pos_id, text, url) VALUES(v_id, 0, 'source', 'http://www.epa.gov/climateleaders/documents/resources/commute_travel_product.pdf');

   -- car occupancy
   INSERT INTO ct.data_source (data_source_id, key, source_description) VALUES (ct.data_source_id_seq.nextval, 'car_occupancy_rate_region_0', 'Car occupancy rate ({0})') RETURNING data_source_id INTO v_id;
   INSERT INTO ct.data_source_url (data_source_id, url_pos_id, text, url) VALUES(v_id, 0, 'source', 'http://www.defra.gov.uk/publications/files/pb13773-ghg-conversion-factors-2012.pdf');

END;
/
	
SET DEFINE &;

commit;
