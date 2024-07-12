-- Please update version.sql too -- this keeps clean builds in sync
define version=2623
@update_header

CREATE OR REPLACE PROCEDURE CT.TempSetCurrency (
	in_period_id 				IN NUMBER, 
	in_currency_id	 			IN NUMBER, 
	in_purchse_pwr_parity_fact	IN NUMBER, 
	in_conversion_to_dollar		IN NUMBER
) 
AS
BEGIN
	BEGIN
		INSERT INTO ct.currency_period(period_id, currency_id, purchse_pwr_parity_fact, conversion_to_dollar)
			 VALUES (in_period_id, in_currency_id, in_purchse_pwr_parity_fact, in_conversion_to_dollar);	
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ct.currency_period
			   SET purchse_pwr_parity_fact = in_purchse_pwr_parity_fact,
					conversion_to_dollar = in_conversion_to_dollar
			 WHERE period_id = in_period_id
			   AND currency_id = in_currency_id;
	END;
END;
/

DECLARE
	v_period_id 		NUMBER;
	v_usd_currency_id  	NUMBER;
	v_gbp_currency_id 	NUMBER;
	v_eur_currency_id 	NUMBER;
	v_cny_currency_id 	NUMBER;
	v_aud_currency_id 	NUMBER;
	v_jpy_currency_id 	NUMBER;
BEGIN
	-- fill missing periods up to 2014
	FOR i IN 1..13
	LOOP
		BEGIN
			INSERT INTO ct.period (period_id, description, start_date, end_date) VALUES (i, TO_CHAR(2001+i),
				TO_DATE('01/01/'||TO_CHAR(2001+i), 'dd/mm/yyyy'), TO_DATE('01/01/'||TO_CHAR(2002+i), 'dd/mm/yyyy'));
		EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
			NULL;				
		END;
	END LOOP;



	SELECT currency_id 
	  INTO v_usd_currency_id 
	  FROM ct.currency 
	 WHERE acronym = 'USD';
	 
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
	
	CT.TempSetCurrency(v_period_id, v_gbp_currency_id, 0.65, 1.492537313432836);	 
	CT.TempSetCurrency(v_period_id, v_eur_currency_id, 0.89, 1.118600581723110);
	CT.TempSetCurrency(v_period_id, v_cny_currency_id, 4.15, 0.240963855421687);
	CT.TempSetCurrency(v_period_id, v_aud_currency_id, 1.42, 0.704225352112676);
	CT.TempSetCurrency(v_period_id, v_jpy_currency_id, 163.07, 0.006132335806709);
	CT.TempSetCurrency(v_period_id, v_usd_currency_id, 1, 1);
		 
	
	--2003--
	SELECT period_id 
	  INTO v_period_id 
	  FROM ct.period
	 WHERE description='2003';
	 
	CT.TempSetCurrency(v_period_id, v_gbp_currency_id, 0.65, 1.639344262295082);	
	CT.TempSetCurrency(v_period_id, v_eur_currency_id, 0.90, 1.086792109244690);
	CT.TempSetCurrency(v_period_id, v_cny_currency_id, 4.10, 0.239024390243902);
	CT.TempSetCurrency(v_period_id, v_aud_currency_id, 1.46, 0.671232876712329);
	CT.TempSetCurrency(v_period_id, v_jpy_currency_id, 155.80, 0.006290115532734);		
	CT.TempSetCurrency(v_period_id, v_usd_currency_id, 1, 1);	
	
	--2004--	
	SELECT period_id
	  INTO v_period_id
	  FROM ct.period
	 WHERE description='2004';
		
	CT.TempSetCurrency(v_period_id, v_gbp_currency_id, 0.64, 1.818181818181818);
	CT.TempSetCurrency(v_period_id, v_eur_currency_id, 0.90, 1.055572970701470);
	CT.TempSetCurrency(v_period_id, v_cny_currency_id, 4.15, 0.228915662650602);
	CT.TempSetCurrency(v_period_id, v_aud_currency_id, 1.44, 0.659722222222222);
	CT.TempSetCurrency(v_period_id, v_jpy_currency_id, 150.81, 0.006299317021418);	
	CT.TempSetCurrency(v_period_id, v_usd_currency_id, 1, 1);
		 
	--2005--
	SELECT period_id 
	  INTO v_period_id 
	  FROM ct.period
	 WHERE description='2005';

	 CT.TempSetCurrency(v_period_id, v_gbp_currency_id, 0.65, 1.818181818181818);
	 CT.TempSetCurrency(v_period_id, v_eur_currency_id, 0.89, 1.029213092296250);
	 CT.TempSetCurrency(v_period_id, v_cny_currency_id, 4.09, 0.224938875305624);
	 CT.TempSetCurrency(v_period_id, v_aud_currency_id, 1.46, 0.630136986301370);
	 CT.TempSetCurrency(v_period_id, v_jpy_currency_id, 142.94, 0.006436266965160);	
	 CT.TempSetCurrency(v_period_id, v_usd_currency_id, 1, 1);
		 
	--2006--
	SELECT period_id 
	  INTO v_period_id 
	  FROM ct.period
	 WHERE description='2006';
	
	 CT.TempSetCurrency(v_period_id, v_gbp_currency_id, 0.65, 1.851851851851852);
	 CT.TempSetCurrency(v_period_id, v_eur_currency_id, 0.88, 1.007603295651420);
	 CT.TempSetCurrency(v_period_id, v_cny_currency_id, 4.02, 0.221393034825871);
	 CT.TempSetCurrency(v_period_id, v_aud_currency_id, 1.50, 0.593333333333333);
	 CT.TempSetCurrency(v_period_id, v_jpy_currency_id, 138.00, 0.006449275362319);	
	 CT.TempSetCurrency(v_period_id, v_usd_currency_id, 1, 1);
		 
	--2007--
	SELECT period_id 
	  INTO v_period_id 
	  FROM ct.period
	 WHERE description='2007';
	
	 CT.TempSetCurrency(v_period_id, v_gbp_currency_id, 0.67, 2);
	 CT.TempSetCurrency(v_period_id, v_eur_currency_id, 0.88, 0.991338281749183);
	 CT.TempSetCurrency(v_period_id, v_cny_currency_id, 4.09, 0.212713936430318);
	 CT.TempSetCurrency(v_period_id, v_aud_currency_id, 1.50, 0.58);
	 CT.TempSetCurrency(v_period_id, v_jpy_currency_id, 133.53, 0.006515389800045);	
	 CT.TempSetCurrency(v_period_id, v_usd_currency_id, 1, 1);
		 
	--2008--
	SELECT period_id 
	  INTO v_period_id 
	  FROM ct.period
	 WHERE description='2008';

	 CT.TempSetCurrency(v_period_id, v_gbp_currency_id, 0.68, 1.851851851851852);
	 CT.TempSetCurrency(v_period_id, v_eur_currency_id, 0.86, 0.981223585811507);
	 CT.TempSetCurrency(v_period_id, v_cny_currency_id, 4.17, 0.201438848920863);
	 CT.TempSetCurrency(v_period_id, v_aud_currency_id, 1.53, 0.549019607843137);
	 CT.TempSetCurrency(v_period_id, v_jpy_currency_id, 129.06, 0.006508600650860);	
	 CT.TempSetCurrency(v_period_id, v_usd_currency_id, 1, 1);
		 
	 --2009--
	SELECT period_id 
	  INTO v_period_id 
	  FROM ct.period
	 WHERE description='2009';

	 CT.TempSetCurrency(v_period_id, v_gbp_currency_id, 0.69, 1.5625);
	 CT.TempSetCurrency(v_period_id, v_eur_currency_id, 0.85, 0.991924084743381);
	 CT.TempSetCurrency(v_period_id, v_cny_currency_id, 4.16, 0.201923076923077);
	 CT.TempSetCurrency(v_period_id, v_aud_currency_id, 1.54, 0.545454545454545);
	 CT.TempSetCurrency(v_period_id, v_jpy_currency_id, 124.95, 0.006722689075630);	
	 CT.TempSetCurrency(v_period_id, v_usd_currency_id, 1, 1);
		 
	 --2010--
	SELECT period_id 
	  INTO v_period_id 
	  FROM ct.period
	 WHERE description='2010';
	 
	DELETE FROM ct.currency_period WHERE period_id=v_period_id;
	
	 CT.TempSetCurrency(v_period_id, v_gbp_currency_id, 0.75, 1.538461538461538);
	 CT.TempSetCurrency(v_period_id, v_eur_currency_id, 0.84, 0.991578748675406);
	 CT.TempSetCurrency(v_period_id, v_cny_currency_id, 4.22, 0.196682464454976);
	 CT.TempSetCurrency(v_period_id, v_aud_currency_id, 1.55, 0.535483870967742);
	 CT.TempSetCurrency(v_period_id, v_jpy_currency_id, 120.84, 0.006868586560741);
	 CT.TempSetCurrency(v_period_id, v_usd_currency_id, 1, 1);

	 --2011--
	SELECT period_id 
	  INTO v_period_id 
	  FROM ct.period
	 WHERE description='2011';
	
	 CT.TempSetCurrency(v_period_id, v_gbp_currency_id, 0.76, 1.612903225806452);
	 CT.TempSetCurrency(v_period_id, v_eur_currency_id, 0.83, 0.963656885147759);
	 CT.TempSetCurrency(v_period_id, v_cny_currency_id, 4.32, 0.185185185185185);
	 CT.TempSetCurrency(v_period_id, v_aud_currency_id, 1.53, 0.522875816993464);
	 CT.TempSetCurrency(v_period_id, v_jpy_currency_id, 116.10, 0.006890611541774);
	 CT.TempSetCurrency(v_period_id, v_usd_currency_id, 1, 1);
		 
	 --2012--
	SELECT period_id 
	  INTO v_period_id 
	  FROM ct.period
	 WHERE description='2012';
	
	 CT.TempSetCurrency(v_period_id, v_gbp_currency_id, 0.77, 1.587301587301587);
	 CT.TempSetCurrency(v_period_id, v_eur_currency_id, 0.83, 0.938885759269691);
	 CT.TempSetCurrency(v_period_id, v_cny_currency_id, 4.34, 0.179723502304147);
	 CT.TempSetCurrency(v_period_id, v_aud_currency_id, 1.54, 0.506493506493507);
	 CT.TempSetCurrency(v_period_id, v_jpy_currency_id, 113.33, 0.006882555369276);
	 CT.TempSetCurrency(v_period_id, v_usd_currency_id, 1, 1);
	
		 
	--2013--
	SELECT period_id 
	  INTO v_period_id 
	  FROM ct.period
	 WHERE description='2013';

	CT.TempSetCurrency(v_period_id, v_gbp_currency_id, 0.77, 1.5625);
	CT.TempSetCurrency(v_period_id, v_eur_currency_id, 0.83, 0.924999369318612);
	CT.TempSetCurrency(v_period_id, v_cny_currency_id, 4.34, 0.177419354838710);
	CT.TempSetCurrency(v_period_id, v_aud_currency_id, 1.54, 0.5);
	CT.TempSetCurrency(v_period_id, v_jpy_currency_id, 113.33, 0.006794317479926);
	CT.TempSetCurrency(v_period_id, v_usd_currency_id, 1, 1);

	 
	--2014--
	SELECT period_id 
	  INTO v_period_id 
	  FROM ct.period
	 WHERE description='2014';
	 
	CT.TempSetCurrency(v_period_id, v_gbp_currency_id, 0.77, 1.666666666666667);	 
	CT.TempSetCurrency(v_period_id, v_eur_currency_id, 0.83, 0.912986390496292);
	CT.TempSetCurrency(v_period_id, v_cny_currency_id, 4.34, 0.175115207373272);
	CT.TempSetCurrency(v_period_id, v_aud_currency_id, 1.54, 0.493506493506494);
	CT.TempSetCurrency(v_period_id, v_jpy_currency_id, 113.33, 0.006706079590576);	
	CT.TempSetCurrency(v_period_id, v_usd_currency_id, 1, 1);	
	
	
END;
/

DROP PROCEDURE CT.TempSetCurrency;

grant select, references on chain.questionnaire to ct;
grant select, references on chain.questionnaire_type to ct;

@../ct/hotspot_pkg

@../ct/hotspot_body
@../ct/setup_body

@update_tail
