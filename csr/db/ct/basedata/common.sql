SET SERVEROUTPUT ON;

-- periods
BEGIN
	FOR i IN 1..14
	LOOP
		INSERT INTO ct.period (period_id, description, start_date, end_date) VALUES (i, TO_CHAR(2001+i),
			TO_DATE('01/01/'||TO_CHAR(2001+i), 'dd/mm/yyyy'), TO_DATE('01/01/'||TO_CHAR(2002+i), 'dd/mm/yyyy'));
	END LOOP;

END;
/

BEGIN
	-- intentionally inserting X as the symbol - this is fixed in currencies_mangled.sql
	INSERT INTO ct.currency (currency_id, description, acronym, symbol) VALUES (1, 'U.S. Dollar', 'USD', 'X');
	INSERT INTO ct.currency (currency_id, description, acronym, symbol) VALUES (2, 'British Pound', 'GBP', 'X');
	INSERT INTO ct.currency (currency_id, description, acronym, symbol) VALUES (3, 'E.U. Euro', 'EUR', 'X');
	INSERT INTO ct.currency (currency_id, description, acronym, symbol) VALUES (4, 'Chinese Yuan Renminbi', 'CNY', 'X');
	INSERT INTO ct.currency (currency_id, description, acronym, symbol) VALUES (5, 'Australian Dollar', 'AUD', 'X');
	INSERT INTO ct.currency (currency_id, description, acronym, symbol) VALUES (6, 'Japanese Yen', 'JPY', 'X');
END;
/

@@currencies_mangled

BEGIN
	INSERT INTO ct.scope_3_category (scope_category_id, description) VALUES (1, 'Business Travel');
	INSERT INTO ct.scope_3_category (scope_category_id, description) VALUES (2, 'Employee Commuting');
	INSERT INTO ct.scope_3_category (scope_category_id, description) VALUES (3, 'Use of Sold Products');
	INSERT INTO ct.scope_3_category (scope_category_id, description) VALUES (4, 'Purchased Goods and Services');
	INSERT INTO ct.scope_3_category (scope_category_id, description) VALUES (5, 'Upstream Transportation and distribution');
	INSERT INTO ct.scope_3_category (scope_category_id, description) VALUES (6, 'Downstream transport and distribution');
	INSERT INTO ct.scope_3_category (scope_category_id, description) VALUES (7, 'Waste Generated in Operations');
END;
/

BEGIN
	INSERT INTO ct.template_key (lookup_key, description, position) VALUES ('hotspot_report_primary', 'Hotspot Report - Primary', 1);
	INSERT INTO ct.template_key (lookup_key, description, position) VALUES ('hotspot_report_business_sector', 'Hotspot Report - Business Sector Section', 2);
	INSERT INTO ct.template_key (lookup_key, description, position) VALUES ('hotspot_report_geographic_region', 'Hotspot Report - Geographic Region Section', 3);
	INSERT INTO ct.template_key (lookup_key, description, position) VALUES ('hotspot_report_scope12', 'Hotspot Report - Scope 1 '||chr(38)||' 2 Section', 4);
	INSERT INTO ct.template_key (lookup_key, description, position) VALUES ('hotspot_report_analysis_combined', 'Hotspot Report - Analysis - Both Sections Combined', 5);
	INSERT INTO ct.template_key (lookup_key, description, position) VALUES ('hotspot_report_analysis_business_sector', 'Hotspot Report - Analysis - Business Sector Section', 6);
	INSERT INTO ct.template_key (lookup_key, description, position) VALUES ('hotspot_report_analysis_geographic_region', 'Hotspot Report - Analysis - Geographic Region Section', 7);
	INSERT INTO ct.template_key (lookup_key, description, position) VALUES ('value_chain_report_primary', 'Value Chain Report - Primary', 8);
	INSERT INTO ct.template_key (lookup_key, description, position) VALUES ('value_chain_report_primary_no_branding', 'Value Chain Report - Primary (no branding)', 9);
END;
/

BEGIN
	-- travel modes - COMMON
	INSERT INTO ct.travel_mode (travel_mode_id, description) VALUES (1, 'Car');
	INSERT INTO ct.travel_mode (travel_mode_id, description) VALUES (2, 'Bus');
	INSERT INTO ct.travel_mode (travel_mode_id, description) VALUES (3, 'Train');
	INSERT INTO ct.travel_mode (travel_mode_id, description) VALUES (4, 'Motorbike');
	INSERT INTO ct.travel_mode (travel_mode_id, description) VALUES (5, 'Bike');
	INSERT INTO ct.travel_mode (travel_mode_id, description) VALUES (6, 'Walk');
	INSERT INTO ct.travel_mode (travel_mode_id, description) VALUES (7, 'Air');
END;
/  

BEGIN   
	-- distances -- COMMON 
	INSERT INTO ct.distance_unit (distance_unit_id, description, symbol, conversion_to_km) VALUES (1, 'Kilometre', 'km', 1);
	INSERT INTO ct.distance_unit (distance_unit_id, description, symbol, conversion_to_km) VALUES (2, 'Miles', 'Mi', 1/0.621371192);
END;
/  

BEGIN
	-- volumes -- COMMON 
	INSERT INTO ct.volume_unit (volume_unit_id, description, symbol, conversion_to_litres) VALUES (1, 'Litre', 'litre' ,1);
	INSERT INTO ct.volume_unit (volume_unit_id, description, symbol, conversion_to_litres) VALUES (2, 'US Gallon', 'gallon (US)', 3.78541178);
	INSERT INTO ct.volume_unit (volume_unit_id, description, symbol, conversion_to_litres) VALUES (3, 'Imperial gallon', 'gallon (imp)', 4.54609188);
	INSERT INTO ct.volume_unit (volume_unit_id, description, symbol, conversion_to_litres) VALUES (4, 'Cubic meter', 'm'||UNISTR('\00B3') , 1000);
	INSERT INTO ct.volume_unit (volume_unit_id, description, symbol, conversion_to_litres) VALUES (5, 'Million litres', 'ML' , 1000000);
	INSERT INTO ct.volume_unit (volume_unit_id, description, symbol, conversion_to_litres) VALUES (6, 'Cubic feet', 'ft'||UNISTR('\00B3') , 28.3168466);
END;
/

BEGIN
	-- masses -- COMMON 
	INSERT INTO ct.mass_unit (mass_unit_id, description, symbol, conversion_to_kg) VALUES (1, 'Kilogram', 'kg' ,1);
	INSERT INTO ct.mass_unit (mass_unit_id, description, symbol, conversion_to_kg) VALUES (2, 'Pound', 'lb', 0.45359237);
	INSERT INTO ct.mass_unit (mass_unit_id, description, symbol, conversion_to_kg) VALUES (3, 'Metric tonne', 'tonne', 1000);
	INSERT INTO ct.mass_unit (mass_unit_id, description, symbol, conversion_to_kg) VALUES (4, 'UK ton', 'long ton', 1016.047 );
	INSERT INTO ct.mass_unit (mass_unit_id, description, symbol, conversion_to_kg) VALUES (5, 'US ton', 'short ton', 907.18474 );
END;
/

BEGIN
	-- powers -- COMMON 
	INSERT INTO ct.power_unit (power_unit_id, description, symbol, conversion_to_watt) VALUES (1, 'Watt hour', 'Wh' ,1);
	INSERT INTO ct.power_unit (power_unit_id, description, symbol, conversion_to_watt) VALUES (2, 'Kilowatt hour', 'kWh', 1000);
	INSERT INTO ct.power_unit (power_unit_id, description, symbol, conversion_to_watt) VALUES (3, 'Megawatt hour', 'MWh', 1000000);
END;
/

BEGIN

	INSERT INTO CT.PS_CALCULATION_SOURCE (CALCULATION_SOURCE_ID, DESCRIPTION) VALUES (1, 'Turnover');
	INSERT INTO CT.PS_CALCULATION_SOURCE (CALCULATION_SOURCE_ID, DESCRIPTION) VALUES (3, 'Product');
	INSERT INTO CT.PS_CALCULATION_SOURCE (CALCULATION_SOURCE_ID, DESCRIPTION) VALUES (4, 'Apportionment');

	INSERT INTO CT.BT_CALCULATION_SOURCE (CALCULATION_SOURCE_ID, DESCRIPTION) VALUES (1, 'Turnover');
	INSERT INTO CT.BT_CALCULATION_SOURCE (CALCULATION_SOURCE_ID, DESCRIPTION) VALUES (2, 'Profile');
	INSERT INTO CT.BT_CALCULATION_SOURCE (CALCULATION_SOURCE_ID, DESCRIPTION) VALUES (3, 'Extrapolated Upload');
	INSERT INTO CT.BT_CALCULATION_SOURCE (CALCULATION_SOURCE_ID, DESCRIPTION) VALUES (4, 'Upload');
	
	INSERT INTO CT.EC_CALCULATION_SOURCE (CALCULATION_SOURCE_ID, DESCRIPTION) VALUES (1, 'Turnover');
	INSERT INTO CT.EC_CALCULATION_SOURCE (CALCULATION_SOURCE_ID, DESCRIPTION) VALUES (2, 'Profile');
	INSERT INTO CT.EC_CALCULATION_SOURCE (CALCULATION_SOURCE_ID, DESCRIPTION) VALUES (3, 'Extrapolated Survey');
	INSERT INTO CT.EC_CALCULATION_SOURCE (CALCULATION_SOURCE_ID, DESCRIPTION) VALUES (4, 'Survey');

END;
/

BEGIN
	INSERT INTO CT.SUPPLIER_STATUS (STATUS_ID, DESCRIPTION) VALUES (0, 'New');
	INSERT INTO CT.SUPPLIER_STATUS (STATUS_ID, DESCRIPTION) VALUES (1, 'HotspotterInvitationSent');
	INSERT INTO CT.SUPPLIER_STATUS (STATUS_ID, DESCRIPTION) VALUES (2, 'AcceptedHotspotterInvitation');
	INSERT INTO CT.SUPPLIER_STATUS (STATUS_ID, DESCRIPTION) VALUES (3, 'CompletedHotspotter');
	INSERT INTO CT.SUPPLIER_STATUS (STATUS_ID, DESCRIPTION) VALUES (4, 'HotspotterCompletedOnBehalfOfSupplier');
END;
/

BEGIN
	INSERT INTO CT.EXTRAPOLATION_TYPE (EXTRAPOLATION_TYPE_ID, DESCRIPTION) VALUES (0, 'No extrapolation');
	INSERT INTO CT.EXTRAPOLATION_TYPE (EXTRAPOLATION_TYPE_ID, DESCRIPTION) VALUES (1, 'Minimum response percentage');
	INSERT INTO CT.EXTRAPOLATION_TYPE (EXTRAPOLATION_TYPE_ID, DESCRIPTION) VALUES (2, 'Minimum months of data');
	INSERT INTO CT.EXTRAPOLATION_TYPE (EXTRAPOLATION_TYPE_ID, DESCRIPTION) VALUES (3, 'Minimum data percentage');
END;
/

DECLARE
	v_period_id 		NUMBER;
	v_gbp_currency_id 	NUMBER;
	v_eur_currency_id 	NUMBER;
	v_cny_currency_id 	NUMBER;
	v_aud_currency_id 	NUMBER;
	v_jpy_currency_id 	NUMBER;
BEGIN
	SELECT currency_id 
	  INTO v_gbp_currency_id 
	  FROM ct.currency 
	 WHERE acronym = 'GBP';
	 
	SELECT currency_id 
	  INTO v_eur_currency_id 
	  FROM ct.currency 
	 WHERE acronym = 'EUR';
	 
	SELECT currency_id 
	  INTO v_cny_currency_id 
	  FROM ct.currency 
	 WHERE acronym = 'CNY';
	 
	SELECT currency_id 
	  INTO v_aud_currency_id 
	  FROM ct.currency 
	 WHERE acronym = 'AUD';
	 
	SELECT currency_id 
	  INTO v_jpy_currency_id 
	  FROM ct.currency 
	 WHERE acronym = 'JPY';
	
	--2002--
	SELECT period_id 
	  INTO v_period_id 
	  FROM ct.period
	 WHERE description='2002';
	 
	DELETE FROM ct.currency_period WHERE period_id=v_period_id;
	
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_gbp_currency_id, 0.65, 1.492537313432836);	 
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_eur_currency_id, 0.89, 1.118600581723110);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_cny_currency_id, 4.15, 0.240963855421687);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_aud_currency_id, 1.42, 0.704225352112676);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_jpy_currency_id, 163.07, 0.006132335806709);
		 
	
	--2003--
	SELECT period_id 
	  INTO v_period_id 
	  FROM ct.period
	 WHERE description='2003';
	 
	DELETE FROM ct.currency_period WHERE period_id=v_period_id;
	
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_gbp_currency_id, 0.65, 1.639344262295082);	
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_eur_currency_id, 0.90, 1.086792109244690);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_cny_currency_id, 4.10, 0.239024390243902);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_aud_currency_id, 1.46, 0.671232876712329);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_jpy_currency_id, 155.80, 0.006290115532734);		 
	
	--2004--	
	SELECT period_id
	  INTO v_period_id
	  FROM ct.period
	 WHERE description='2004';
	 
	DELETE FROM ct.currency_period WHERE period_id=v_period_id;
		 
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_gbp_currency_id, 0.64, 1.818181818181818);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_eur_currency_id, 0.90, 1.055572970701470);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_cny_currency_id, 4.15, 0.228915662650602);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_aud_currency_id, 1.44, 0.659722222222222);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_jpy_currency_id, 150.81, 0.006299317021418);	
		 
	--2005--
	SELECT period_id 
	  INTO v_period_id 
	  FROM ct.period
	 WHERE description='2005';
	 
	DELETE FROM ct.currency_period WHERE period_id=v_period_id;
	
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_gbp_currency_id, 0.65, 1.818181818181818);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_eur_currency_id, 0.89, 1.029213092296250);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_cny_currency_id, 4.09, 0.224938875305624);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_aud_currency_id, 1.46, 0.630136986301370);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_jpy_currency_id, 142.94, 0.006436266965160);	
		 
	--2006--
	SELECT period_id 
	  INTO v_period_id 
	  FROM ct.period
	 WHERE description='2006';
	 
	DELETE FROM ct.currency_period WHERE period_id=v_period_id;
	
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_gbp_currency_id, 0.65, 1.851851851851852);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_eur_currency_id, 0.88, 1.007603295651420);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_cny_currency_id, 4.02, 0.221393034825871);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_aud_currency_id, 1.50, 0.593333333333333);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_jpy_currency_id, 138.00, 0.006449275362319);	
		 
	--2007--
	SELECT period_id 
	  INTO v_period_id 
	  FROM ct.period
	 WHERE description='2007';
	 
	DELETE FROM ct.currency_period WHERE period_id=v_period_id;
	
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_gbp_currency_id, 0.67, 2);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_eur_currency_id, 0.88, 0.991338281749183);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_cny_currency_id, 4.09, 0.212713936430318);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_aud_currency_id, 1.50, 0.58);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_jpy_currency_id, 133.53, 0.006515389800045);	
		 
	--2008--
	SELECT period_id 
	  INTO v_period_id 
	  FROM ct.period
	 WHERE description='2008';
	 
	DELETE FROM ct.currency_period WHERE period_id=v_period_id;
	
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_gbp_currency_id, 0.68, 1.851851851851852);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_eur_currency_id, 0.86, 0.981223585811507);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_cny_currency_id, 4.17, 0.201438848920863);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_aud_currency_id, 1.53, 0.549019607843137);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_jpy_currency_id, 129.06, 0.006508600650860);	
		 
	 --2009--
	SELECT period_id 
	  INTO v_period_id 
	  FROM ct.period
	 WHERE description='2009';
	 
	DELETE FROM ct.currency_period WHERE period_id=v_period_id;
	
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_gbp_currency_id, 0.69, 1.5625);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_eur_currency_id, 0.85, 0.991924084743381);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_cny_currency_id, 4.16, 0.201923076923077);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_aud_currency_id, 1.54, 0.545454545454545);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_jpy_currency_id, 124.95, 0.006722689075630);	
		 
	 --2010--
	SELECT period_id 
	  INTO v_period_id 
	  FROM ct.period
	 WHERE description='2010';
	 
	DELETE FROM ct.currency_period WHERE period_id=v_period_id;
	
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_gbp_currency_id, 0.75, 1.538461538461538);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_eur_currency_id, 0.84, 0.991578748675406);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_cny_currency_id, 4.22, 0.196682464454976);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_aud_currency_id, 1.55, 0.535483870967742);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_jpy_currency_id, 120.84, 0.006868586560741);

	 --2011--
	SELECT period_id 
	  INTO v_period_id 
	  FROM ct.period
	 WHERE description='2011';
	
	DELETE FROM ct.currency_period WHERE period_id= v_period_id;
	
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_gbp_currency_id, 0.76, 1.612903225806452);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_eur_currency_id, 0.83, 0.963656885147759);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_cny_currency_id, 4.32, 0.185185185185185);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_aud_currency_id, 1.53, 0.522875816993464);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_jpy_currency_id, 116.10, 0.006890611541774);
		 
	 --2012--
	SELECT period_id 
	INTO v_period_id 
	FROM ct.period
	 WHERE description='2012';
	 
	
	DELETE FROM ct.currency_period WHERE period_id= v_period_id;
	
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_gbp_currency_id, 0.77, 1.587301587301587);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_eur_currency_id, 0.83, 0.938885759269691);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_cny_currency_id, 4.34, 0.179723502304147);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_aud_currency_id, 1.54, 0.506493506493507);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		 VALUES (v_period_id, v_jpy_currency_id, 113.33, 0.006882555369276);
	
		 
	--2013--
	SELECT period_id 
	  INTO v_period_id 
	  FROM ct.period
	 WHERE description='2013';

	DELETE FROM ct.currency_period WHERE period_id= v_period_id;
	
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		VALUES (v_period_id, v_gbp_currency_id, 0.77, 1.5625);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		VALUES (v_period_id, v_eur_currency_id, 0.83, 0.924999369318612);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		VALUES (v_period_id, v_cny_currency_id, 4.34, 0.177419354838710);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		VALUES (v_period_id, v_aud_currency_id, 1.54, 0.5);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		VALUES (v_period_id, v_jpy_currency_id, 113.33, 0.006794317479926);

	 
	--2014--
	SELECT period_id 
	  INTO v_period_id 
	  FROM ct.period
	 WHERE description='2014';
	 
	DELETE FROM ct.currency_period WHERE period_id=v_period_id;
	
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		VALUES (v_period_id, v_gbp_currency_id, 0.77, 1.666666666666667);	 
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		VALUES (v_period_id, v_eur_currency_id, 0.83, 0.912986390496292);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		VALUES (v_period_id, v_cny_currency_id, 4.34, 0.175115207373272);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		VALUES (v_period_id, v_aud_currency_id, 1.54, 0.493506493506494);
	INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
		VALUES (v_period_id, v_jpy_currency_id, 113.33, 0.006706079590576);	   
END;
/


commit;