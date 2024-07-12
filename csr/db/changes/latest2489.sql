define version=2489
@update_header

--this table has RLS. not sure if this will work
ALTER TABLE ct.customer_options ADD hide_ec NUMBER(1); 
ALTER TABLE ct.customer_options ADD hide_bt NUMBER(1); 
ALTER TABLE ct.customer_options ADD copy_to_indicators NUMBER(1); 
ALTER TABLE ct.customer_options ADD reinvite_supplier NUMBER(1); 

UPDATE ct.customer_options 
   SET hide_ec = 0, 
	   hide_bt = 0, 
	   copy_to_indicators= 0, 
	   reinvite_supplier = 0;

ALTER TABLE ct.customer_options MODIFY hide_ec DEFAULT 0 NOT NULL; 
ALTER TABLE ct.customer_options MODIFY hide_bt DEFAULT 0 NOT NULL; 
ALTER TABLE ct.customer_options MODIFY copy_to_indicators DEFAULT 0 NOT NULL; 
ALTER TABLE ct.customer_options MODIFY reinvite_supplier DEFAULT 0 NOT NULL; 

ALTER TABLE ct.customer_options
ADD CONSTRAINT CHK_HIDE_BT CHECK (HIDE_BT IN (0,1))
ADD CONSTRAINT CHK_HIDE_EC CHECK (HIDE_EC IN (0,1))
ADD CONSTRAINT CHK_REINVITE_SUPPLIER CHECK (REINVITE_SUPPLIER IN (0,1))
ADD CONSTRAINT CHK_COPY_TO_IND CHECK (COPY_TO_INDICATORS IN (0,1));

DECLARE
	v_period_id 		NUMBER;
	v_gbp_currency_id 	NUMBER;
	v_eur_currency_id 	NUMBER;
	v_cny_currency_id 	NUMBER;
	v_aud_currency_id 	NUMBER;
	v_jpy_currency_id 	NUMBER;
BEGIN		
	-- periods
	FOR i IN 12..14
	LOOP
		INSERT INTO ct.period (period_id, description, start_date, end_date) VALUES (i, TO_CHAR(2001+i),
			TO_DATE('01/01/'||TO_CHAR(2001+i), 'dd/mm/yyyy'), TO_DATE('01/01/'||TO_CHAR(2002+i), 'dd/mm/yyyy'));
	END LOOP;

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
	
	FOR r IN (
		SELECT period_id
		  FROM ct.currency_period
		 WHERE period_id=v_period_id AND NOT EXISTS (SELECT 1 FROM ct.company WHERE period_id = v_period_id)
	) LOOP 
		DELETE FROM ct.currency_period WHERE period_id= r.period_id;
		
		INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
			 VALUES (r.period_id, v_gbp_currency_id, 0.76, 1.612903225806452);
		INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
			 VALUES (r.period_id, v_eur_currency_id, 0.83, 0.963656885147759);
		INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
			 VALUES (r.period_id, v_cny_currency_id, 4.32, 0.185185185185185);
		INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
			 VALUES (r.period_id, v_aud_currency_id, 1.53, 0.522875816993464);
		INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
			 VALUES (r.period_id, v_jpy_currency_id, 116.10, 0.006890611541774);
	END LOOP;			 
		 
	 --2012--
	SELECT period_id 
	INTO v_period_id 
	FROM ct.period
	 WHERE description='2012';
	 
	FOR r IN (
		SELECT period_id
		  FROM ct.currency_period
		 WHERE period_id=v_period_id AND NOT EXISTS (SELECT 1 FROM ct.company WHERE period_id = v_period_id)
	) LOOP 
		DELETE FROM ct.currency_period WHERE period_id= r.period_id;
		
		INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
			 VALUES (r.period_id, v_gbp_currency_id, 0.77, 1.587301587301587);
		INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
			 VALUES (r.period_id, v_eur_currency_id, 0.83, 0.938885759269691);
		INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
			 VALUES (r.period_id, v_cny_currency_id, 4.34, 0.179723502304147);
		INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
			 VALUES (r.period_id, v_aud_currency_id, 1.54, 0.506493506493507);
		INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
			 VALUES (r.period_id, v_jpy_currency_id, 113.33, 0.006882555369276);
	END LOOP;
		 
	--2013--
	SELECT period_id 
	INTO v_period_id 
	FROM ct.period
	 WHERE description='2013';

	FOR r IN (
		SELECT period_id
		  FROM ct.currency_period
		 WHERE period_id=v_period_id AND NOT EXISTS (SELECT 1 FROM ct.company WHERE period_id = v_period_id)

	) LOOP	 
		DELETE FROM ct.currency_period WHERE period_id= r.period_id;
		
		INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
			VALUES (r.period_id, v_gbp_currency_id, 0.77, 1.5625);
		INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
			VALUES (r.period_id, v_eur_currency_id, 0.83, 0.924999369318612);
		INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
			VALUES (r.period_id, v_cny_currency_id, 4.34, 0.177419354838710);
		INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
			VALUES (r.period_id, v_aud_currency_id, 1.54, 0.5);
		INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
			VALUES (r.period_id, v_jpy_currency_id, 113.33, 0.006794317479926);
	END LOOP;
	 
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

@..\ct\util_pkg;
@..\ct\util_body;
@..\ct\hotspot_pkg;
@..\ct\hotspot_body;

@update_tail
