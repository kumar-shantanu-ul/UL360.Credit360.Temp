define version=???
@update_header

@..\ct\enable\hotspotter\enableHotspotter;
@..\ct\enable\valuechain\enableValueChain;

define host='&&1'

exec SECURITY.user_pkg.logonadmin('&&1');

--CREATE INDICATORS
DECLARE
	v_parent_sid			SECURITY.security_pkg.t_sid_id;
	v_result_sid			SECURITY.security_pkg.t_sid_id;
	v_ind_root_sid			SECURITY.security_pkg.t_sid_id;
	v_emissions_measure_sid SECURITY.security_pkg.t_sid_id;
BEGIN
	BEGIN
		SELECT measure_sid
		  INTO v_emissions_measure_sid
		  FROM csr.measure
		 WHERE NAME='Emissions';
		exception WHEN no_data_found THEN
		csr.measure_pkg.createmeasure(
			in_name							=> 'Emissions',
			in_description					=> 'Emissions',
			in_std_measure_conversion_id 	=> 4,
			out_measure_sid					=> v_emissions_measure_sid
		);
	END;

	SELECT ind_root_sid
	  INTO v_ind_root_sid
	  FROM csr.customer
	 WHERE app_sid = SECURITY.security_pkg.getapp;

	BEGIN
		SELECT ind_sid
		  INTO v_parent_sid
		  FROM csr.ind
		 WHERE lookup_key = 'HOTSPOT_ROOT';
	exception WHEN no_data_found THEN
		csr.indicator_pkg.createindicator(
			in_name				=> 'HOTSPOT_ROOT',
			in_description		=> 'Hotspot Indicators',
			in_lookup_key		=> 'HOTSPOT_ROOT',
			in_parent_sid_id	=> v_ind_root_sid,
			out_sid_id			=> v_parent_sid
		);
	END;
	
	BEGIN
		SELECT ind_sid
		  INTO v_result_sid
		  FROM csr.ind
		 WHERE lookup_key = 'UPSTREAM_EMISSIONS';
	exception WHEN no_data_found THEN
		csr.indicator_pkg.createindicator(
			in_name				=> 'UPSTREAM_EMISSIONS',
			in_description		=> 'Upstream emissions',
			in_lookup_key		=> 'UPSTREAM_EMISSIONS',
			in_parent_sid_id	=> v_parent_sid,
			in_measure_sid      => v_emissions_measure_sid,
			out_sid_id			=> v_result_sid
		);
	END;	
	
	BEGIN
		SELECT ind_sid
		  INTO v_result_sid
		  FROM csr.ind
		 WHERE lookup_key = 'DOWNSTREAM_EMISSIONS';
	exception WHEN no_data_found THEN
		csr.indicator_pkg.createindicator(
			in_name				=> 'DOWNSTREAM_EMISSIONS',
			in_description		=> 'Downstream emissions',
			in_lookup_key		=> 'DOWNSTREAM_EMISSIONS',
			in_parent_sid_id	=> v_parent_sid,
			in_measure_sid      => v_emissions_measure_sid,
			out_sid_id			=> v_result_sid
		);
	END;	
	
	BEGIN
		SELECT ind_sid
		  INTO v_result_sid
		  FROM csr.ind
		 WHERE lookup_key = 'BT_EMISSIONS';
	exception WHEN no_data_found THEN
		csr.indicator_pkg.createindicator(
			in_name				=> 'BT_EMISSIONS',
			in_description		=> 'BT emissions',
			in_lookup_key		=> 'BT_EMISSIONS',
			in_parent_sid_id	=> v_parent_sid,
			in_measure_sid      => v_emissions_measure_sid,
			out_sid_id			=> v_result_sid
		);
	END;	
	
	BEGIN
		SELECT ind_sid
		  INTO v_result_sid
		  FROM csr.ind
		 WHERE lookup_key = 'EC_EMISSIONS';
	exception WHEN no_data_found THEN
		csr.indicator_pkg.createindicator(
			in_name				=> 'EC_EMISSIONS',
			in_description		=> 'EC emissions',
			in_lookup_key		=> 'EC_EMISSIONS',
			in_parent_sid_id	=> v_parent_sid,
			in_measure_sid      => v_emissions_measure_sid,
			out_sid_id			=> v_result_sid
		);
	END;	
	
	BEGIN
		SELECT ind_sid
		  INTO v_result_sid
		  FROM csr.ind
		 WHERE lookup_key = 'PG_EMISSIONS';
	exception WHEN no_data_found THEN
		csr.indicator_pkg.createindicator(
			in_name				=> 'PG_EMISSIONS',
			in_description		=> 'PG emissions',
			in_lookup_key		=> 'PG_EMISSIONS',
			in_parent_sid_id	=> v_parent_sid,
			in_measure_sid      => v_emissions_measure_sid,
			out_sid_id			=> v_result_sid
		);
	END;	
	
	BEGIN
		SELECT ind_sid
		  INTO v_result_sid
		  FROM csr.ind
		 WHERE lookup_key = 'SCOPE1_EMISSIONS';
	exception WHEN no_data_found THEN
		csr.indicator_pkg.createindicator(
			in_name				=> 'SCOPE1_EMISSIONS',
			in_description		=> 'Scope 1 emissions',
			in_lookup_key		=> 'SCOPE1_EMISSIONS',
			in_parent_sid_id	=> v_parent_sid,
			in_measure_sid      => v_emissions_measure_sid,
			out_sid_id			=> v_result_sid
		);
	END;	
	
	BEGIN
		SELECT ind_sid
		  INTO v_result_sid
		  FROM csr.ind
		 WHERE lookup_key = 'SCOPE2_EMISSIONS';
	exception WHEN no_data_found THEN
		csr.indicator_pkg.createindicator(
			in_name				=> 'SCOPE2_EMISSIONS',
			in_description		=> 'Scope 2 emissions',
			in_lookup_key		=> 'SCOPE2_EMISSIONS',
			in_parent_sid_id	=> v_parent_sid,
			in_measure_sid      => v_emissions_measure_sid,
			out_sid_id			=> v_result_sid
		);
	END;	
	
	BEGIN
		SELECT ind_sid
		  INTO v_result_sid
		  FROM csr.ind
		 WHERE lookup_key = 'USE_EMISSIONS';
	exception WHEN no_data_found THEN
		csr.indicator_pkg.createindicator(
			in_name				=> 'USE_EMISSIONS',
			in_description		=> 'Use emissions',
			in_lookup_key		=> 'USE_EMISSIONS',
			in_parent_sid_id	=> v_parent_sid,
			in_measure_sid      => v_emissions_measure_sid,
			out_sid_id			=> v_result_sid
		);
	END;	
	
	BEGIN
		SELECT ind_sid
		  INTO v_result_sid
		  FROM csr.ind
		 WHERE lookup_key = 'WASTE_EMISSIONS';
	exception WHEN no_data_found THEN
		csr.indicator_pkg.createindicator(
			in_name				=> 'WASTE_EMISSIONS',
			in_description		=> 'Waste emissions',
			in_lookup_key		=> 'WASTE_EMISSIONS',
			in_parent_sid_id	=> v_parent_sid,
			in_measure_sid      => v_emissions_measure_sid,
			out_sid_id			=> v_result_sid
		);
	END;	
END;
/

--CREATE PERIODS
CREATE SEQUENCE period_id_seq
     START WITH 1
   INCREMENT BY 1
          ORDER;

DECLARE
  period_id 		NUMBER;
  gbp_currency_id 	NUMBER;
  eur_currency_id 	NUMBER;
  cny_currency_id 	NUMBER;
  aud_currency_id 	NUMBER;
  jpy_currency_id 	NUMBER;
BEGIN    
  UPDATE ct.customer_options
     SET hide_ec = 1, 
	     hide_bt = 1,
		 copy_to_indicators = 1
   WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
   
   UPDATE chain.customer_options
      SET reinvite_supplier = 1,
	WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
  
  SELECT currency_id 
    INTO :gbp_currency_id 
    FROM ct.currency 
   WHERE acronym = 'GBP';
   
   SELECT currency_id 
    INTO :eur_currency_id 
    FROM ct.currency 
   WHERE acronym = 'EUR';
   
   SELECT currency_id 
    INTO :cny_currency_id 
    FROM ct.currency 
   WHERE acronym = 'CNY';
   
   SELECT currency_id 
    INTO :aud_currency_id 
    FROM ct.currency 
   WHERE acronym = 'AUD';
   
   SELECT currency_id 
    INTO :jpy_currency_id 
    FROM ct.currency 
   WHERE acronym = 'JPY';
  
  --2002--
  SELECT period_id_seq.nextval 
    INTO :period_id 
    FROM dual;
  
  INSERT INTO ct.period(period_id, description, usd_ratio_to_base_yr, start_date, end_date, app_sid)
       VALUES (:period_id, '2002', 1, to_date('01/01/2002', 'dd/mm/yyyy'), to_date('01/01/2003', 'dd/mm/yyyy'), SYS_CONTEXT('SECURITY', 'APP'));
   
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :gbp_currency_id, 0.65, 1.492537313432836);	 
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :eur_currency_id, 0.89, 1.118600581723110);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :cny_currency_id, 4.15, 0.240963855421687);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :aud_currency_id, 1.42, 0.704225352112676);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :jpy_currency_id, 163.07, 0.006132335806709);
	   
  
  --2003--
  SELECT period_id_seq.nextval 
    INTO :period_id 
    FROM dual;
    
  INSERT INTO ct.period(period_id, description, usd_ratio_to_base_yr, start_date, end_date, app_sid)
       VALUES (:period_id, '2003', 1, to_date('01/01/2003', 'dd/mm/yyyy'), to_date('01/01/2004', 'dd/mm/yyyy'), SYS_CONTEXT('SECURITY', 'APP'));
  
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :gbp_currency_id, 0.65, 1.639344262295082);  
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :eur_currency_id, 0.90, 1.086792109244690);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :cny_currency_id, 4.10, 0.239024390243902);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :aud_currency_id, 1.46, 0.671232876712329);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :jpy_currency_id, 155.80, 0.006290115532734);	   
  
  --2004--  
   SELECT period_id_seq.nextval 
    INTO :period_id 
    FROM dual;
    
  INSERT INTO ct.period(period_id, description, usd_ratio_to_base_yr, start_date, end_date, app_sid)
       VALUES (:period_id, '2004', 1, to_date('01/01/2004', 'dd/mm/yyyy'), to_date('01/01/2005', 'dd/mm/yyyy'), SYS_CONTEXT('SECURITY', 'APP'));
       
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :gbp_currency_id, 0.64, 1.818181818181818);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :eur_currency_id, 0.90, 1.055572970701470);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :cny_currency_id, 4.15, 0.228915662650602);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :aud_currency_id, 1.44, 0.659722222222222);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :jpy_currency_id, 150.81, 0.006299317021418);	
       
  --2005--
   SELECT period_id_seq.nextval 
    INTO :period_id 
    FROM dual;
    
  INSERT INTO ct.period(period_id, description, usd_ratio_to_base_yr, start_date, end_date, app_sid)
       VALUES (:period_id, '2005', 1, to_date('01/01/2005', 'dd/mm/yyyy'), to_date('01/01/2006', 'dd/mm/yyyy'), SYS_CONTEXT('SECURITY', 'APP'));
  
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :gbp_currency_id, 0.65, 1.818181818181818);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :eur_currency_id, 0.89, 1.029213092296250);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :cny_currency_id, 4.09, 0.224938875305624);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :aud_currency_id, 1.46, 0.630136986301370);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :jpy_currency_id, 142.94, 0.006436266965160);	
       
  --2006--
  SELECT period_id_seq.nextval 
    INTO :period_id 
    FROM dual;
    
  INSERT INTO ct.period(period_id, description, usd_ratio_to_base_yr, start_date, end_date, app_sid)
       VALUES (:period_id, '2006', 1, to_date('01/01/2006', 'dd/mm/yyyy'), to_date('01/01/2007', 'dd/mm/yyyy'), SYS_CONTEXT('SECURITY', 'APP'));
  
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :gbp_currency_id, 0.65, 1.851851851851852);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :eur_currency_id, 0.88, 1.007603295651420);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :cny_currency_id, 4.02, 0.221393034825871);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :aud_currency_id, 1.50, 0.593333333333333);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :jpy_currency_id, 138.00, 0.006449275362319);	
       
  --2007--
  SELECT period_id_seq.nextval 
    INTO :period_id 
    FROM dual;
    
  INSERT INTO ct.period(period_id, description, usd_ratio_to_base_yr, start_date, end_date, app_sid)
       VALUES (:period_id, '2007', 1, to_date('01/01/2007', 'dd/mm/yyyy'), to_date('01/01/2008', 'dd/mm/yyyy'), SYS_CONTEXT('SECURITY', 'APP'));
  
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :gbp_currency_id, 0.67, 2);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :eur_currency_id, 0.88, 0.991338281749183);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :cny_currency_id, 4.09, 0.212713936430318);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :aud_currency_id, 1.50, 0.58);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :jpy_currency_id, 133.53, 0.006515389800045);	
       
  --2008--
  SELECT period_id_seq.nextval 
    INTO :period_id 
    FROM dual;
    
  INSERT INTO ct.period(period_id, description, usd_ratio_to_base_yr, start_date, end_date, app_sid)
       VALUES (:period_id, '2008', 1, to_date('01/01/2008', 'dd/mm/yyyy'), to_date('01/01/2009', 'dd/mm/yyyy'), SYS_CONTEXT('SECURITY', 'APP'));
  
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :gbp_currency_id, 0.68, 1.851851851851852);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :eur_currency_id, 0.86, 0.981223585811507);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :cny_currency_id, 4.17, 0.201438848920863);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :aud_currency_id, 1.53, 0.549019607843137);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :jpy_currency_id, 129.06, 0.006508600650860);	
       
   --2009--
  SELECT period_id_seq.nextval 
    INTO :period_id 
    FROM dual;
    
  INSERT INTO ct.period(period_id, description, usd_ratio_to_base_yr, start_date, end_date, app_sid)
       VALUES (:period_id, '2009', 1, to_date('01/01/2009', 'dd/mm/yyyy'), to_date('01/01/2010', 'dd/mm/yyyy'), SYS_CONTEXT('SECURITY', 'APP'));
  
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :gbp_currency_id, 0.69, 1.5625);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :eur_currency_id, 0.85, 0.991924084743381);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :cny_currency_id, 4.16, 0.201923076923077);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :aud_currency_id, 1.54, 0.545454545454545);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :jpy_currency_id, 124.95, 0.006722689075630);	
       
   --2010--
  SELECT period_id_seq.nextval 
    INTO :period_id 
    FROM dual;
    
  INSERT INTO ct.period(period_id, description, usd_ratio_to_base_yr, start_date, end_date, app_sid)
       VALUES (:period_id, '2010', 1, to_date('01/01/2010', 'dd/mm/yyyy'), to_date('01/01/2011', 'dd/mm/yyyy'), SYS_CONTEXT('SECURITY', 'APP'));
  
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :gbp_currency_id, 0.75, 1.538461538461538);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :eur_currency_id, 0.84, 0.991578748675406);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :cny_currency_id, 4.22, 0.196682464454976);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :aud_currency_id, 1.55, 0.535483870967742);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :jpy_currency_id, 120.84, 0.006868586560741);

   --2011--
  SELECT period_id_seq.nextval 
    INTO :period_id 
    FROM dual;
    
  INSERT INTO ct.period(period_id, description, usd_ratio_to_base_yr, start_date, end_date, app_sid)
       VALUES (:period_id, '2011', 1, to_date('01/01/2011', 'dd/mm/yyyy'), to_date('01/01/2012', 'dd/mm/yyyy'), SYS_CONTEXT('SECURITY', 'APP'));
  
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :gbp_currency_id, 0.76, 1.612903225806452);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :eur_currency_id, 0.83, 0.963656885147759);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :cny_currency_id, 4.32, 0.185185185185185);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :aud_currency_id, 1.53, 0.522875816993464);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :jpy_currency_id, 116.10, 0.006890611541774);
       
   --2012--
  SELECT period_id_seq.nextval 
    INTO :period_id 
    FROM dual;
    
  INSERT INTO ct.period(period_id, description, usd_ratio_to_base_yr, start_date, end_date, app_sid)
       VALUES (:period_id, '2012', 1, to_date('01/01/2012', 'dd/mm/yyyy'), to_date('01/01/2013', 'dd/mm/yyyy'), SYS_CONTEXT('SECURITY', 'APP'));
  
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :gbp_currency_id, 0.77, 1.587301587301587);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :eur_currency_id, 0.83, 0.938885759269691);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :cny_currency_id, 4.34, 0.179723502304147);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :aud_currency_id, 1.54, 0.506493506493507);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :jpy_currency_id, 113.33, 0.006882555369276);
       
  --2013--
  SELECT period_id_seq.nextval 
    INTO :period_id 
    FROM dual;
    
  INSERT INTO ct.period(period_id, description, usd_ratio_to_base_yr, start_date, end_date, app_sid)
       VALUES (:period_id, '2013', 1, to_date('01/01/2013', 'dd/mm/yyyy'), to_date('01/01/2014', 'dd/mm/yyyy'), SYS_CONTEXT('SECURITY', 'APP'));
  
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :gbp_currency_id, 0.77, 1.5625);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :eur_currency_id, 0.83, 0.924999369318612);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :cny_currency_id, 4.34, 0.177419354838710);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :aud_currency_id, 1.54, 0.5);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :jpy_currency_id, 113.33, 0.006794317479926);
       
  --2014--
  SELECT period_id_seq.nextval 
    INTO :period_id 
    FROM dual;
    
  INSERT INTO ct.period(period_id, description, usd_ratio_to_base_yr, start_date, end_date, app_sid)
       VALUES (:period_id, '2014', 1, to_date('01/01/2014', 'dd/mm/yyyy'), to_date('01/01/2015', 'dd/mm/yyyy'), SYS_CONTEXT('SECURITY', 'APP'));
  
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :gbp_currency_id, 0.77, 1.666666666666667);   
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :eur_currency_id, 0.83, 0.912986390496292);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :cny_currency_id, 4.34, 0.175115207373272);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :aud_currency_id, 1.54, 0.493506493506494);
  INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
       VALUES (:period_id, :jpy_currency_id, 113.33, 0.006706079590576);	   
END;
/



@..\ct\util_pkg;
@..\ct\util_body;
@..\ct\hotspot_pkg;
@..\ct\hotspot_body;
@update_tail
