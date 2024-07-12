-- Please update version.sql too -- this keeps clean builds in sync
define version=1019
@update_header

/* ec_region with any regions not in the ec_region table "fallen back" to the R.o.t.W factors/figures*/
CREATE OR REPLACE VIEW ct.v$ec_region (
		region_id, description, country, parent_id, holidays, 
		car_avg_pct_use, bus_avg_pct_use, train_avg_pct_use, motorbike_avg_pct_use, bike_avg_pct_use, walk_avg_pct_use, 
		car_avg_journey_km, bus_avg_journey_km, train_avg_journey_km, motorbike_avg_journey_km, bike_avg_journey_km, walk_avg_journey_km   
)
AS		
SELECT  r.region_id, description, country, parent_id, holidays, 
		car_avg_pct_use, bus_avg_pct_use, train_avg_pct_use, motorbike_avg_pct_use, bike_avg_pct_use, walk_avg_pct_use, 
		car_avg_journey_km, bus_avg_journey_km, train_avg_journey_km, motorbike_avg_journey_km, bike_avg_journey_km, walk_avg_journey_km         
	   FROM ct.region r
       JOIN ct.ec_region ec ON r.region_id = ec.region_id 
 -----
 UNION
 -----
SELECT  r.region_id, description, country, parent_id, holidays, 
		car_avg_pct_use, bus_avg_pct_use, train_avg_pct_use, motorbike_avg_pct_use, bike_avg_pct_use, walk_avg_pct_use, 
		car_avg_journey_km, bus_avg_journey_km, train_avg_journey_km, motorbike_avg_journey_km, bike_avg_journey_km, walk_avg_journey_km          
  FROM ct.region r
  JOIN ct.ec_region ec ON ec.region_id = 0
 WHERE r.region_id NOT IN (SELECT region_id FROM ec_region);
 
 /* bt_region with any regions not in the bt_region table "fallen back" to the R.o.t.W factors/figures*/
CREATE OR REPLACE VIEW ct.v$bt_region (
		region_id, description, country, parent_id, temp_emission_factor  
)
AS
SELECT  r.region_id, description, country, parent_id, temp_emission_factor         
  FROM ct.region r
  JOIN ct.bt_region bt ON r.region_id = bt.region_id 
 -----
 UNION
 -----
SELECT  r.region_id, description, country, parent_id, temp_emission_factor 
  FROM ct.region r
  JOIN ct.bt_region bt ON bt.region_id = 0
 WHERE r.region_id NOT IN (SELECT region_id FROM bt_region);

@update_tail
