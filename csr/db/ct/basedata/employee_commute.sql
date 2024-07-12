SET SERVEROUTPUT ON;

SET DEFINE $;

INSERT INTO ct.EC_FUEL_TYPE (FUEL_TYPE_ID, DESCRIPTION, KG_CO2_PER_LITRE) VALUES (1,'Petrol', 2.72309600614439);
INSERT INTO ct.EC_FUEL_TYPE (FUEL_TYPE_ID, DESCRIPTION, KG_CO2_PER_LITRE) VALUES (2, 'Diesel', 3.17561631336406);
INSERT INTO ct.EC_FUEL_TYPE (FUEL_TYPE_ID, DESCRIPTION, KG_CO2_PER_LITRE) VALUES (3, 'Biodiesel',0.5);

-- car, bus, motorbike, train type
BEGIN

	--="INSERT INTO ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'"&D4&"',"&E4&");"
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Small petrol car',0.1983);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Medium petrol car',0.24927);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Large petrol car',0.35773);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution, is_default) VALUES (ct.ec_transport_id_seq.nextval,'Average petrol car',0.24234,1);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Small diesel car',0.17137);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Medium diesel car',0.21291);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Large diesel car',0.28267);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Average diesel car',0.22428);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Medium petrol hybrid car',0.13984);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Large petrol hybrid car',0.2481);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Average petrol hybrid car',0.1617);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Medium LPG car',0.21373);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Large LPG car',0.30626);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Average LPG car',0.24142);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Medium CNG car',0.19636);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Large CNG car',0.28116);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Average CNG car',0.22173);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Petrol van (Class I)',0.23963);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Petrol van (Class II)',0.25521);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Petrol van (Class III)',0.31079);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Diesel van (Class I)',0.18579);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Diesel van (Class II)',0.27402);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Diesel van (Class III)',0.32302);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Average diesel van ',0.30193);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Average LPG van ',0.29599);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Average CNG van ',0.27602);
	INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Average petrol van ',0.25646);

	--="INSERT INTO ct.ec_bus_type (bus_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'"&D37&"',"&E37&");"
	INSERT INTO ct.ec_bus_type (bus_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'London local bus',0.10005);
	INSERT INTO ct.ec_bus_type (bus_type_id, description, kg_co2_per_km_contribution, is_default) VALUES (ct.ec_transport_id_seq.nextval,'Average local bus',0.13552,1);
	INSERT INTO ct.ec_bus_type (bus_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Coach ',0.03471);

	--="INSERT INTO ct.ec_motorbike_type(motorbike_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'"&D31&"',"&E31&");"	
	INSERT INTO ct.ec_motorbike_type(motorbike_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Small petrol motorbike',0.10482);
	INSERT INTO ct.ec_motorbike_type(motorbike_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Medium petrol motorbike',0.12717);
	INSERT INTO ct.ec_motorbike_type(motorbike_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Large petrol motorbike',0.16742);
	INSERT INTO ct.ec_motorbike_type(motorbike_type_id, description, kg_co2_per_km_contribution, is_default) VALUES (ct.ec_transport_id_seq.nextval,'Average petrol motorbike',0.14238, 1);

	--="INSERT INTO ct.ec_train_type (train_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'"&D40&"',"&E40&");"
	INSERT INTO ct.ec_train_type (train_type_id, description, kg_co2_per_km_contribution, is_default) VALUES (ct.ec_transport_id_seq.nextval,'Domestic rail',0.06715, 1);
	INSERT INTO ct.ec_train_type (train_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'International rail ',0.01715);
	INSERT INTO ct.ec_train_type (train_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Light rail and tram ',0.07659);
	INSERT INTO ct.ec_train_type (train_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Metro',0.08154);

END;
/

PROMPT manufacturer
BEGIN

	--="INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'"&B4&"');"
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer, is_dont_know) VALUES (ct.ec_manufacturer_id_seq.nextval,'DON''T KNOW', 1);
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'ABARTH');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'ALFA ROMEO');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'ASTON MARTIN LAGONDA');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'AUDI');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'BENTLEY MOTORS');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'BMW');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'CHEVROLET');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'CHRYSLER JEEP');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'CITROEN');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'FERRARI');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'FIAT');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'FORD');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'HONDA');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'HYUNDAI');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'INFINITI');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'JAGUAR CARS');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'KIA');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'LAMBORGHINI');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'LAND ROVER');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'LEXUS');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'LOTUS');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'LTI');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'MASERATI');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'MAZDA');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'MERCEDES-BENZ');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'MG MOTORS UK');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'MINI');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'MITSUBISHI');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'MORGAN MOTOR COMPANY');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'NISSAN');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'PERODUA');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'PEUGEOT');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'PORSCHE');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'PROTON');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'RENAULT');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'ROLLS-ROYCE');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'SAAB');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'SEAT');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'SKODA');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'SMART');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'SSANGYONG');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'SUBARU');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'SUZUKI');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'TOYOTA');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'VAUXHALL');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'VOLKSWAGEN');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'VOLKSWAGEN C.V.');
	INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'VOLVO');
	
END;
/

-- car's uploaded in separate script due to character encoding



CREATE FUNCTION ct.GetRegionIdFromName (
    in_description                   IN ct.region.description%TYPE
) RETURN ct.region.region_id%TYPE
AS
	v_region_id		ct.region.region_id%TYPE;
BEGIN
	SELECT region_id INTO v_region_id FROM ct.region WHERE LOWER(description) = LOWER(in_description); 
	RETURN v_region_id;
END;
/

-- regions 
BEGIN
	--- =="INSERT INTO ct.ec_region_factors (description,holidays,CAR_AVG_PCT_USE,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km"&",bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (GetRegionIdFromName('"&B4&"'),"&I4&","&C4&"*100,"&D4&"*100,"&E4&"*100,"&F4&"*100,"&G4&"*100,"&H4&"*100,"&J4&","&K4&","&L4&","&M4&","&N4&","&O4&");"

	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United States'),22,0.894*100,0.025*100,0.025*100,0.015*100,0.015*100,0.03*100,20.7605,16.3831,38.6,20.7605,10,1.57715);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United Kingdom'),29,0.7*100,0.08*100,0.08*100,0.01*100,0.03*100,0.1*100,15.13379,8.25954,37.70134,15.13379,5.29366,1.471501);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United Kingdom - North East'),29,0.74*100,0.1*100,0.02*100,0*100,0.02*100,0.1*100,15.13379,8.25954,37.70134,15.13379,5.29366,1.471501);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United Kingdom - North West'),29,0.77*100,0.06*100,0.03*100,0*100,0.02*100,0.1*100,15.13379,8.25954,37.70134,15.13379,5.29366,1.471501);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United Kingdom - Yorkshire and the Humber'),29,0.73*100,0.08*100,0.02*100,0.01*100,0.03*100,0.12*100,15.13379,8.25954,37.70134,15.13379,5.29366,1.471501);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United Kingdom - East Midlands'),29,0.77*100,0.06*100,0.01*100,0.01*100,0.03*100,0.11*100,15.13379,8.25954,37.70134,15.13379,5.29366,1.471501);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United Kingdom - East of England'),29,0.73*100,0.03*100,0.09*100,0.01*100,0.04*100,0.09*100,15.13379,8.25954,37.70134,15.13379,5.29366,1.471501);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United Kingdom - London'),29,0.37*100,0.15*100,0.33*100,0.01*100,0.04*100,0.09*100,15.13379,8.25954,37.70134,15.13379,5.29366,1.471501);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United Kingdom - South East'),29,0.74*100,0.03*100,0.07*100,0.01*100,0.04*100,0.12*100,15.13379,8.25954,37.70134,15.13379,5.29366,1.471501);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United Kingdom - South West'),29,0.77*100,0.03*100,0.02*100,0.01*100,0.04*100,0.13*100,15.13379,8.25954,37.70134,15.13379,5.29366,1.471501);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United Kingdom - England'),29,0.7*100,0.07*100,0.08*100,0.01*100,0.03*100,0.11*100,15.13379,8.25954,37.70134,15.13379,5.29366,1.471501);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United Kingdom - Wales'),29,0.89*100,0.05*100,0.02*100,0*100,0.02*100,0.11*100,15.13379,8.25954,37.70134,15.13379,5.29366,1.471501);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United Kingdom - Scotland'),29,0.72*100,0.11*100,0.04*100,0*100,0.01*100,0.12*100,15.13379,8.25954,37.70134,15.13379,5.29366,1.471501);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('Australia'),30,0.81*100,0.06*100,0.07*100,0.09*100,0.03*100,0.03*100,20.7605,16.3831,38.6,20.7605,10,1.57715);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('Australia - NSW'),30,0.76*100,0.07*100,0.1*100,0*100,0.03*100,0.03*100,20.7605,16.3831,38.6,20.7605,10,1.57715);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('Australia - VIC'),30,0.84*100,0.04*100,0.07*100,0*100,0.025*100,0.025*100,20.7605,16.3831,38.6,20.7605,10,1.57715);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('Australia - QLD'),30,0.85*100,0.05*100,0.04*100,0*100,0.03*100,0.03*100,20.7605,16.3831,38.6,20.7605,10,1.57715);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('Australia - SA'),30,0.88*100,0.05*100,0.02*100,0*100,0.025*100,0.025*100,20.7605,16.3831,38.6,20.7605,10,1.57715);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('Australia - WA'),30,0.87*100,0.06*100,0.02*100,0*100,0.025*100,0.025*100,20.7605,16.3831,38.6,20.7605,10,1.57715);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('Australia - TAS'),30,0.88*100,0.04*100,0*100,0*100,0.04*100,0.04*100,20.7605,16.3831,38.6,20.7605,10,1.57715);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('Australia - ACT'),30,0.87*100,0.06*100,0*100,0*100,0.035*100,0.035*100,20.7605,16.3831,38.6,20.7605,10,1.57715);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('Australia - NT'),30,0.76*100,0.06*100,0*100,0*100,0.09*100,0.09*100,20.7605,16.3831,38.6,20.7605,10,1.57715);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (0,15,0.774727272727273*100,0.0620454545454546*100,0.0525*100,0.00840909090909091*100,0.0315909090909091*100,0.0754545454545455*100,17.6913854545455,11.9520672727273,38.1098218181818,17.6913854545455,7.43290545454546,1.51952327272727);

END;
/

DROP FUNCTION ct.GetRegionIdFromName;


SET DEFINE &;

commit;