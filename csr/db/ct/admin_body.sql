CREATE OR REPLACE PACKAGE BODY ct.admin_pkg AS

--COMMON
PROCEDURE SetPeriodUSDBaseYearRatio(
	in_period_id 						IN	period.period_id%TYPE,
	in_usd_ratio_to_base_yr				IN period.usd_ratio_to_base_yr%TYPE
)AS
BEGIN
	-- the period must exist
	UPDATE period 
	   SET usd_ratio_to_base_yr = in_usd_ratio_to_base_yr
	 WHERE period_id = in_period_id;
END;

--HOTSPOT
PROCEDURE SetEIO (
	in_eio_id 							IN	eio.eio_id%TYPE, 
	in_description 						IN	eio.description%TYPE, 
	in_eio_group_id 					IN	eio.eio_group_id%TYPE, 
	in_emis_fctr_c_to_g_inc_use_ph	IN	eio.emis_fctr_c_to_g_inc_use_ph%TYPE, 
	in_emis_fctr_c_to_g 				IN	eio.emis_fctr_c_to_g%TYPE, 
	in_pct_elec_energy 					IN	eio.pct_elec_energy%TYPE, 
	in_pct_other_energy 				IN	eio.pct_other_energy%TYPE, 
	in_pct_use_phase 					IN	eio.pct_use_phase%TYPE, 
	in_pct_warehouse 					IN	eio.pct_warehouse%TYPE, 
	in_pct_waste	 					IN	eio.pct_waste%TYPE, 
	in_pct_upstream_trans 				IN	eio.pct_upstream_trans%TYPE, 
	in_pct_downstream_trans				IN	eio.pct_downstream_trans%TYPE, 
	in_pct_ctfc_scope_one_two			IN	eio.pct_ctfc_scope_one_two%TYPE
)AS
BEGIN

	BEGIN
		INSERT INTO eio
		(
			eio_id, 				
			description, 				
			eio_group_id, 				
			emis_fctr_c_to_g_inc_use_ph, 			
			emis_fctr_c_to_g, 			
			pct_elec_energy, 			
			pct_other_energy, 			
			pct_use_phase, 				
			pct_warehouse, 		
			pct_waste,			
			pct_upstream_trans, 			
			pct_downstream_trans, 		
			pct_ctfc_scope_one_two				
		) VALUES (
			in_eio_id, 				
			in_description, 		
			in_eio_group_id, 		
			in_emis_fctr_c_to_g_inc_use_ph, 	
			in_emis_fctr_c_to_g, 	
			in_pct_elec_energy, 	
			in_pct_other_energy, 	
			in_pct_use_phase, 		
			in_pct_warehouse, 		
			in_pct_waste,
			in_pct_upstream_trans, 	
			in_pct_downstream_trans, 
			in_pct_ctfc_scope_one_two
		);	
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE eio
			SET    eio_id                 = in_eio_id,
				   description            = in_description,
				   eio_group_id           = in_eio_group_id,
				   emis_fctr_c_to_g_inc_use_ph = in_emis_fctr_c_to_g_inc_use_ph,
				   emis_fctr_c_to_g       = in_emis_fctr_c_to_g,
				   pct_elec_energy        = in_pct_elec_energy,
				   pct_other_energy       = in_pct_other_energy,
				   pct_use_phase          = in_pct_use_phase,
				   pct_warehouse          = in_pct_warehouse,
				   pct_waste			  = in_pct_waste,
				   pct_upstream_trans     = in_pct_upstream_trans,
				   pct_downstream_trans   = in_pct_downstream_trans,
				   pct_ctfc_scope_one_two = in_pct_ctfc_scope_one_two
			WHERE  eio_id                 = in_eio_id;
	END;

END;

PROCEDURE SetEIOPctRelationship (
	in_primary_eio_cat_id 					IN	eio.eio_id%TYPE, 
	in_related_eio_cat_id 					IN	eio.eio_id%TYPE, 
	in_pct								IN	eio_relationship.pct%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO eio_relationship(
			primary_eio_cat_id,		
			related_eio_cat_id, 		
			pct					
		)
		VALUES(
			in_primary_eio_cat_id, 	
			in_related_eio_cat_id, 			
			in_pct						
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE eio_relationship
			SET    
				pct  = in_pct
			WHERE  primary_eio_cat_id = in_primary_eio_cat_id
			  AND  related_eio_cat_id = in_related_eio_cat_id;
	END;
END;

PROCEDURE SetEIOGroup (
	in_eio_group_id					IN	eio_group.eio_group_id%TYPE,
	in_eio_group					IN	eio_group.description%TYPE, 
	in_hide							IN  eio_group.hide%TYPE
)AS
BEGIN

	BEGIN
		INSERT INTO eio_group(
			eio_group_id,
			description, 
			hide
		)
		VALUES(
			in_eio_group_id, 
			in_eio_group, 
			in_hide
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE eio_group
			SET    
				description  	= in_eio_group, 
				hide 			= in_hide
			WHERE  eio_group_id = in_eio_group_id;
	END;

END;

PROCEDURE SetCurrencyPeriodData (
	in_period_id					IN currency_period.period_id%TYPE,
	in_currency_id					IN currency_period.currency_id%TYPE,
	in_purchse_pwr_parity_fact		IN currency_period.purchse_pwr_parity_fact%TYPE, 
	in_conversion_to_dollar			IN currency_period.conversion_to_dollar%TYPE
)AS
BEGIN

	BEGIN
		INSERT INTO currency_period(
			period_id,				
			currency_id,						
			purchse_pwr_parity_fact, 
			conversion_to_dollar
		)
		VALUES(
			in_period_id,				
			in_currency_id,						
			in_purchse_pwr_parity_fact, 
			in_conversion_to_dollar			
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE	currency_period
			   SET 
					purchse_pwr_parity_fact = in_purchse_pwr_parity_fact, 
					conversion_to_dollar = in_conversion_to_dollar
			 WHERE period_id = in_period_id
			   AND currency_id = in_currency_id;
	END;

END;

PROCEDURE SetHotRegion (
	in_region_id					IN hot_region.region_id%TYPE,
	in_full_lifecycle_ef			IN hot_region.full_lifecycle_ef%TYPE,
	in_combusition_ef				IN hot_region.combusition_ef%TYPE
)AS
BEGIN

	BEGIN
		INSERT INTO hot_region(
			region_id,				
			full_lifecycle_ef,						
			combusition_ef
		)
		VALUES(
			in_region_id,				
			in_full_lifecycle_ef,						
			in_combusition_ef		
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE	hot_region
			   SET 
					full_lifecycle_ef = in_full_lifecycle_ef,
					combusition_ef = in_combusition_ef
			 WHERE region_id = in_region_id;
	END;
		
END;

--EMPLOYEE COMMUTE

FUNCTION GetManufacturerId (
	in_name							IN ec_car_manufacturer.manufacturer%TYPE
) RETURN ec_car_manufacturer.manufacturer_id%TYPE
AS
	v_id	ec_car_manufacturer.manufacturer_id%TYPE;
BEGIN
	SELECT manufacturer_id
	  INTO v_id
	  FROM ec_car_manufacturer
	 WHERE LOWER(TRIM(manufacturer)) = LOWER(TRIM(in_name));
	 
	 RETURN v_id;
END;

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
)AS
BEGIN

	BEGIN
		INSERT INTO ec_region_factors(
			region_id,
			holidays,
			car_avg_pct_use,
			bus_avg_pct_use,
			train_avg_pct_use,
			motorbike_avg_pct_use,
			bike_avg_pct_use,
			walk_avg_pct_use,
			car_avg_journey_km,
			bus_avg_journey_km,
			train_avg_journey_km,
			motorbike_avg_journey_km,
			bike_avg_journey_km,
			walk_avg_journey_km
		) VALUES (
			in_region_id,
			in_holidays,
			in_car_avg_pct_use,
			in_bus_avg_pct_use,
			in_train_avg_pct_use,
			in_motorbike_avg_pct_use,
			in_bike_avg_pct_use,
			in_walk_avg_pct_use,
			in_car_avg_journey_km,
			in_bus_avg_journey_km,
			in_train_avg_journey_km,
			in_motorbike_avg_journey_km,
			in_bike_avg_journey_km,
			in_walk_avg_journey_km
		);		
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ec_region_factors
			   SET 
				   holidays                      = in_holidays,
				   car_avg_pct_use               = in_car_avg_pct_use,
				   bus_avg_pct_use               = in_bus_avg_pct_use,
				   train_avg_pct_use             = in_train_avg_pct_use,
				   motorbike_avg_pct_use         = in_motorbike_avg_pct_use,
				   bike_avg_pct_use              = in_bike_avg_pct_use,
				   walk_avg_pct_use              = in_walk_avg_pct_use,
				   car_avg_journey_km            = in_car_avg_journey_km,
				   bus_avg_journey_km            = in_bus_avg_journey_km,
				   train_avg_journey_km          = in_train_avg_journey_km,
				   motorbike_avg_journey_km      = in_motorbike_avg_journey_km,
				   bike_avg_journey_km           = in_bike_avg_journey_km,
				   walk_avg_journey_km           = in_walk_avg_journey_km
			 WHERE region_id = in_region_id;
	END;

END;

PROCEDURE SetCarType (
	in_car_type_id					IN	ec_car_type.car_type_id%TYPE,
	in_description					IN	ec_car_type.description%TYPE,
	in_kg_co2_per_km_contribution	IN	ec_car_type.kg_co2_per_km_contribution%TYPE
)AS
BEGIN

	BEGIN
		INSERT INTO ec_car_type(car_type_id,
							 description, 
							 kg_co2_per_km_contribution)
		VALUES(in_car_type_id,
			   in_description,
			   in_kg_co2_per_km_contribution);		
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ec_car_type
			   SET description              		= in_description,
				   kg_co2_per_km_contribution      	= in_kg_co2_per_km_contribution
			 WHERE car_type_id 						= in_car_type_id;			
	END;

END;

PROCEDURE SetBusType (
	in_bus_type_id					IN	ec_bus_type.bus_type_id%TYPE,
	in_description					IN	ec_bus_type.description%TYPE,
	in_kg_co2_per_km_contribution	IN	ec_bus_type.kg_co2_per_km_contribution%TYPE
)AS
BEGIN

	BEGIN
		INSERT INTO ec_bus_type(bus_type_id,
							 description,
							 kg_co2_per_km_contribution)
		VALUES(in_bus_type_id,
			   in_description,
			   in_kg_co2_per_km_contribution);		
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ec_bus_type
			   SET description                    	= in_description,
				   kg_co2_per_km_contribution      	= in_kg_co2_per_km_contribution
			 WHERE bus_type_id 						= in_bus_type_id;			
	END;

END;

PROCEDURE SetTrainType (
	in_train_type_id				IN	ec_train_type.train_type_id%TYPE,
	in_description					IN	ec_train_type.description%TYPE,
	in_kg_co2_per_km_contribution	IN	ec_train_type.kg_co2_per_km_contribution%TYPE
)AS
BEGIN

	BEGIN
		INSERT INTO ec_train_type(train_type_id,
							 description,
							 kg_co2_per_km_contribution)
		VALUES(in_train_type_id,
			   in_description,
			   in_kg_co2_per_km_contribution);		
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ec_train_type
			   SET description                     	= in_description,
				   kg_co2_per_km_contribution      	= in_kg_co2_per_km_contribution
			 WHERE train_type_id 					= in_train_type_id;			
	END;

END;

PROCEDURE SetMotorbikeType (
	in_motorbike_type_id			IN	ec_motorbike_type.motorbike_type_id%TYPE,
	in_description					IN	ec_motorbike_type.description%TYPE,
	in_kg_co2_per_km_contribution	IN	ec_motorbike_type.kg_co2_per_km_contribution%TYPE
)AS
BEGIN

	BEGIN
		INSERT INTO ec_motorbike_type(motorbike_type_id,
							 description,
							 kg_co2_per_km_contribution)
		VALUES(in_motorbike_type_id,
			   in_description,
			   in_kg_co2_per_km_contribution);		
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ec_motorbike_type
			   SET description                   	= in_description,
				   kg_co2_per_km_contribution    	= in_kg_co2_per_km_contribution
			 WHERE motorbike_type_id 				= in_motorbike_type_id;			
	END;

END;

PROCEDURE SetManufacturer (
	in_manufacturer_id				IN	ec_car_manufacturer.manufacturer_id%TYPE,
	in_manufacturer					IN	ec_car_manufacturer.manufacturer%TYPE
)AS
BEGIN

	BEGIN
		INSERT INTO ec_car_manufacturer(manufacturer_id,
								 manufacturer)
		VALUES(in_manufacturer_id,
			   in_manufacturer);		
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ec_car_manufacturer
			   SET manufacturer         = in_manufacturer
			 WHERE manufacturer_id 		= in_manufacturer_id;			
	END;

END;

PROCEDURE SetCarModel (                
    in_description                  IN ec_car_model.description%TYPE,                 
    in_manufacturer              	IN ec_car_manufacturer.manufacturer%TYPE,             
    in_efficiency_ltr_per_100km     IN ec_car_model.efficiency_ltr_per_km%TYPE, 
	in_fuel_type_id					IN ec_fuel_type.fuel_type_id%TYPE,
	in_transmission					IN ec_car_model.transmission%TYPE         
)AS				
BEGIN

	INSERT INTO ec_car_model(
		car_id,
		description,
		manufacturer_id,
		efficiency_ltr_per_km,
		fuel_type_id,
		transmission
	) VALUES (
		ec_car_id_seq.nextval,
		in_description,
		GetManufacturerId(in_manufacturer),
		in_efficiency_ltr_per_100km/100,
		in_fuel_type_id,
		in_transmission
	);	
END;

PROCEDURE GetTemplateKeys(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability('Manage CT Templates') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied Managing CT Templates');
	END IF;

	OPEN out_cur FOR
		SELECT t.lookup_key, t.description, r.filename, r.mime_type, length(r.data) file_size, r.last_modified_dtm
		  FROM template_key t, report_template r
		 WHERE t.lookup_key = r.lookup_key(+)
		 ORDER BY t.position;

END;

PROCEDURE StoreUploadedReportTemplate(
	in_lookup_key					IN  report_template.lookup_key%TYPE,
	in_cache_key					IN  aspen2.filecache.cache_key%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability('Manage CT Templates') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied Managing CT Templates');
	END IF;

	DELETE FROM report_template WHERE lookup_key = in_lookup_key;
	
	INSERT INTO report_template (lookup_key, filename, mime_type, data, last_modified_dtm) 
		 SELECT in_lookup_key, filename, mime_type, object, last_modified_dtm
		   FROM aspen2.filecache 
		  WHERE cache_key = in_cache_key;

	aspen2.filecache_pkg.DeleteEntry(in_cache_key);
END;

PROCEDURE GetReportTemplate(
	in_lookup_key					IN  report_template.lookup_key%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT lookup_key, filename, mime_type, data, last_modified_dtm
		  FROM report_template
		 WHERE lookup_key = in_lookup_key;
END;

END  admin_pkg;
/
