
/* ec_region_factors with any regions not in the ec_region_factors table "fallen back" to the R.o.t.W factors/figures*/
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
       JOIN ct.ec_region_factors ec ON r.region_id = ec.region_id 
 -----
 UNION
 -----
SELECT  r.region_id, description, country, parent_id, holidays, 
		car_avg_pct_use, bus_avg_pct_use, train_avg_pct_use, motorbike_avg_pct_use, bike_avg_pct_use, walk_avg_pct_use, 
		car_avg_journey_km, bus_avg_journey_km, train_avg_journey_km, motorbike_avg_journey_km, bike_avg_journey_km, walk_avg_journey_km          
  FROM ct.region r
  JOIN ct.ec_region_factors ec ON ec.region_id = 0
 WHERE r.region_id NOT IN (SELECT region_id FROM ct.ec_region_factors);
 
 /* bt_region_factors with any regions not in the bt_region_factors table "fallen back" to the R.o.t.W factors/figures*/
CREATE OR REPLACE VIEW ct.v$bt_region_factors (
		region_id, description, country, parent_id, temp_emission_factor  
)
AS
SELECT  r.region_id, description, country, parent_id, temp_emission_factor         
  FROM ct.region r
  JOIN ct.bt_region_factors bt ON r.region_id = bt.region_id 
 -----
 UNION
 -----
SELECT  r.region_id, description, country, parent_id, temp_emission_factor 
  FROM ct.region r
  JOIN ct.bt_region_factors bt ON bt.region_id = 0
 WHERE r.region_id NOT IN (SELECT region_id FROM ct.bt_region_factors);

/* v$hs_breakdown_type - breakdown types used in the hotspotter only*/
CREATE OR REPLACE VIEW ct.v$hs_breakdown_type (
    app_sid, breakdown_type_id, company_sid, singular, plural, by_turnover, by_fte, is_region, rest_of
)
AS
SELECT
    app_sid,
    breakdown_type_id,
    company_sid,
    singular,
    plural,
    by_turnover,
    by_fte,
    is_region,
    rest_of
 FROM breakdown_type
WHERE is_hotspot = 1;

/* v$breakdown_type - breakdown types used in the main tool only*/
CREATE OR REPLACE VIEW ct.v$breakdown_type (
    app_sid, breakdown_type_id, company_sid, singular, plural, by_turnover, by_fte, is_region, rest_of
)
AS
SELECT
    app_sid,
    breakdown_type_id,
    company_sid,
    singular,
    plural,
    by_turnover,
    by_fte,
    is_region,
    rest_of
 FROM breakdown_type
WHERE is_hotspot = 0;
 
/* v$ps_item - all of the ps_item data, with extra spend_in_usd, used when ordering/aggregating spend values*/
-- FORCE because this won't compile during clean build -- the packages don't exist at creation time
CREATE OR REPLACE FORCE VIEW ct.v$ps_item (
    app_sid, company_sid, supplier_id, breakdown_id, region_id, item_id, description,
	spend, currency_id, purchase_date, created_by_sid, created_dtm, modified_by_sid,
	last_modified_dtm, row_number, worksheet_id, 
	auto_eio_id, auto_eio_id_score, auto_eio_id_two, auto_eio_id_score_two, match_auto_accepted, kg_co2,
	spend_in_company_currency, spend_in_dollars, company_currency_id
)
AS
SELECT
    i.app_sid, 
	i.company_sid, 
	i.supplier_id, 
	i.breakdown_id, 
	i.region_id, 
	i.item_id, 
	i.description,
	i.spend, 
	i.currency_id, 
	i.purchase_date, 
	i.created_by_sid, 
	i.created_dtm, 
	i.modified_by_sid,
	i.last_modified_dtm, 
	row_number, 
	i.worksheet_id,
	i.auto_eio_id, i.auto_eio_id_score, i.auto_eio_id_two, i.auto_eio_id_score_two, i.match_auto_accepted,
	i.kg_co2,
	ROUND(i.spend * util_pkg.GetConversionToDollar(i.currency_id, i.purchase_date) * util_pkg.GetConversionFromDollar(c.currency_id, i.purchase_date),2) spend_in_company_currency,
	ROUND(i.spend * util_pkg.GetConversionToDollar(i.currency_id, i.purchase_date), 2) spend_in_dollars,
	c.currency_id company_currency_id
 FROM ct.ps_item i, company c
WHERE i.app_sid = c.app_sid
  AND c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
  AND c.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
 
CREATE OR REPLACE VIEW ct.v$ps_flat_tree
(
	ps_category_id,
    ps_category,
	ps_segment_id,
    ps_segment,
	ps_family_id, 
    ps_family,    
	ps_class_id,
    ps_class,    
	ps_brick_id,
    ps_brick,  
	eio_id,
	eio,
	eio_long
)
AS
SELECT 
	psct.ps_category_id,
    psct.description ps_category,
	pss.ps_segment_id,   
    pss.description ps_segment,
	psf.ps_family_id, 
    psf.description ps_family,    
	psc.ps_class_id,  
    psc.description ps_class,    
	psb.ps_brick_id,
    psb.description ps_brick,  
	eio.eio_id,
	eio.description eio, 
	eio.old_description eio_long
FROM 
    ps_segment pss 
    JOIN ps_family psf ON pss.ps_segment_id = psf.ps_segment_id 
    JOIN ps_class psc ON psf.ps_family_id = psc.ps_family_id
    JOIN ps_brick psb ON psc.ps_class_id = psb.ps_class_id
    JOIN ps_category psct ON psb.ps_category_id = psct.ps_category_id
    JOIN eio eio ON psb.eio_id = eio.eio_id;



	
	
CREATE OR REPLACE VIEW ct.v$ps_emissions
(app_sid, breakdown_id, region_id, eio_id, calculation_source_id, kg_co2)
AS
	 SELECT 
			p.app_sid,               
			breakdown_id,          
			region_id,             
			eio_id,                
			calculation_source_id, 
			SUM(kg_co2) kg_co2
	  FROM ct.ps_emissions_all p
	  JOIN ct.ps_options o ON p.app_sid = o.app_sid
	 WHERE p.breakdown_id IN (SELECT breakdown_id FROM ct.breakdown b WHERE b.breakdown_type_id = o.breakdown_type_id)	
	 GROUP BY p.app_sid, breakdown_id, region_id, eio_id, calculation_source_id;
	
CREATE OR REPLACE VIEW ct.v$ps_level_contributions
(app_sid, calculation_source_id, contribution_source_id, kg_co2)
AS 
	SELECT
			p.app_sid,
			calculation_source_id,
			contribution_source_id,
			SUM(kg_co2) kg_co2
	  FROM ct.ps_emissions_all p
	  JOIN ct.ps_options o ON p.app_sid = o.app_sid
	 WHERE p.breakdown_id IN (SELECT breakdown_id FROM ct.breakdown b WHERE b.breakdown_type_id = o.breakdown_type_id)	
	 GROUP BY p.app_sid, calculation_source_id, contribution_source_id;
	
	

	
CREATE OR REPLACE VIEW ct.v$ec_emissions
(app_sid, breakdown_id, region_id, calculation_source_id, car_kg_co2, bus_kg_co2, train_kg_co2, motorbike_kg_co2, bike_kg_co2, walk_kg_co2)
AS
	SELECT 
		e.app_sid,               
		e.breakdown_id,          
		region_id,                          
		calculation_source_id, 
		SUM(car_kg_co2) car_kg_co2, 
		SUM(bus_kg_co2) bus_kg_co2, 
		SUM(train_kg_co2) train_kg_co2, 
		SUM(motorbike_kg_co2) motorbike_kg_co2, 
		SUM(bike_kg_co2) bike_kg_co2, 
		SUM(walk_kg_co2) walk_kg_co2
	FROM ct.ec_emissions_all e
	JOIN ct.ec_options o ON e.app_sid = o.app_sid
   WHERE e.breakdown_id IN (SELECT breakdown_id FROM ct.breakdown b WHERE b.breakdown_type_id = o.breakdown_type_id)
   GROUP BY e.app_sid, e.breakdown_id, region_id, calculation_source_id;
	
CREATE OR REPLACE VIEW ct.v$ec_level_contributions
(app_sid, calculation_source_id, contribution_source_id, car_kg_co2, bus_kg_co2, train_kg_co2, motorbike_kg_co2, bike_kg_co2, walk_kg_co2)
AS 
	SELECT
		e.app_sid,
		calculation_source_id,
		contribution_source_id,
		SUM(car_kg_co2) car_kg_co2, 
		SUM(bus_kg_co2) bus_kg_co2, 
		SUM(train_kg_co2) train_kg_co2, 
		SUM(motorbike_kg_co2) motorbike_kg_co2, 
		SUM(bike_kg_co2) bike_kg_co2, 
		SUM(walk_kg_co2) walk_kg_co2
	FROM ct.ec_emissions_all e
	JOIN ct.ec_options o ON e.app_sid = o.app_sid
   WHERE e.breakdown_id IN (SELECT breakdown_id FROM ct.breakdown b WHERE b.breakdown_type_id = o.breakdown_type_id)
   GROUP BY e.app_sid, calculation_source_id, contribution_source_id;

			
/*v$ht_water_waste - water and waste consumption breakdown values UNION consumption default value (when breakdowns do not exist)*/
CREATE OR REPLACE VIEW ct.v$ht_water_waste (
    app_sid, company_sid, category_id, type_id, source_id, source_description, amount, unit_id, unit_type
)
AS
SELECT c.app_sid, c.company_sid, c.ht_consumption_category_id, c.ht_consumption_type_id, cs.ht_cons_source_id, cs.description, c.amount, NVL(c.volume_unit_id, c.mass_unit_id), DECODE(c.volume_unit_id, NULL, 1, 2) -- (consumption_pkg.MASS_UNIT, consumption_pkg.VOLUME_UNIT) 
  FROM ct.ht_consumption c
  JOIN ct.ht_cons_source cs ON (c.ht_consumption_category_id = cs.ht_consumption_category_id AND c.ht_consumption_type_id = cs.ht_consumption_type_id)
 WHERE c.ht_consumption_category_id IN (4, 5) -- (ct.consumption_pkg.WATER, ct.consumption_pkg.WASTE)
   AND cs.is_remainder = 1
   AND NOT EXISTS(
	SELECT 1
      FROM ct.ht_cons_source_breakdown csb   
     WHERE csb.app_sid = c.app_sid
       AND csb.company_sid = c.company_sid
       AND csb.ht_consumption_category_id = c.ht_consumption_category_id
       AND csb.ht_consumption_type_id = c.ht_consumption_type_id
   )
UNION
SELECT c.app_sid, c.company_sid, c.ht_consumption_category_id, c.ht_consumption_type_id, cs.ht_cons_source_id, cs.description, csb.amount, NVL(c.volume_unit_id, c.mass_unit_id), DECODE(c.volume_unit_id, NULL, 1, 2)
  FROM ct.ht_cons_source_breakdown csb 
  JOIN ct.ht_consumption c ON (c.ht_consumption_type_id = csb.ht_consumption_type_id AND c.ht_consumption_category_id = csb.ht_consumption_category_id AND c.app_sid = csb.app_sid AND c.company_sid = csb.company_sid)
  JOIN ct.ht_cons_source cs ON (cs.ht_cons_source_id = csb.ht_cons_source_id);
  
/* Just joins hc consumption to the co2 factors for the unit for that entry*/
CREATE OR REPLACE VIEW ct.v$ht_consumption (
    app_sid, company_sid, ht_consumption_type_id, ht_consumption_category_id, mass_unit_id, power_unit_id, volume_unit_id, amount, co2_factor
)
AS
SELECT hc.app_sid, hc.company_sid, hc.ht_consumption_type_id, hc.ht_consumption_category_id, hc.mass_unit_id, hc.power_unit_id, hc.volume_unit_id, hc.amount, co2_factor
  FROM ht_consumption hc 
  JOIN ht_consumption_type_mass_unit u 
    ON hc.ht_consumption_type_id = u.ht_consumption_type_id 
   AND hc.ht_consumption_category_id = u.ht_consumption_category_id 
   AND hc.mass_unit_id = u.mass_unit_id
UNION
SELECT hc.*, co2_factor
  FROM ht_consumption hc 
  JOIN ht_consumption_type_power_unit u
    ON hc.ht_consumption_type_id = u.ht_consumption_type_id 
   AND hc.ht_consumption_category_id = u.ht_consumption_category_id 
   AND hc.power_unit_id = u.power_unit_id 
UNION
SELECT hc.*, co2_factor
  FROM ht_consumption hc 
  JOIN ht_consumption_type_vol_unit u
    ON hc.ht_consumption_type_id = u.ht_consumption_type_id 
   AND hc.ht_consumption_category_id = u.ht_consumption_category_id 
   AND hc.volume_unit_id = u.volume_unit_id ;