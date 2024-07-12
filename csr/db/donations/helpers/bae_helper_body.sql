CREATE OR REPLACE PACKAGE BODY donations.bae_helper_pkg
IS


/**
 * 	FB8182, FB8643
 */
PROCEDURE AfterSave(
    in_donation_id			IN	security_pkg.T_SID_ID
)
AS
	v_act_id				security_pkg.T_ACT_ID;
	v_field_num				security_pkg.T_SID_ID;
	v_donation_status_sid	security_pkg.T_SID_ID;
	v_budget_id				security_pkg.T_SID_ID;
	v_cash_value			donation.custom_1%TYPE;
	v_region_sid			security_pkg.T_SID_ID;
	v_donation_cur			budget.currency_code%TYPE;
	v_compare_cur			budget.currency_code%TYPE;
	v_converted_value		donation.custom_1%TYPE;
BEGIN
	v_act_id := sys_context('security', 'act');
	
	-- find field_num to compare
	SELECT field_num
	  INTO v_field_num
	 FROM custom_field
	WHERE lookup_key = 'sponsorhip'		-- Company Giving amount
	  AND app_sid = sys_context('security', 'app');
	
	-- fetch infos
	EXECUTE IMMEDIATE  
		'SELECT donation_status_sid, region_sid, d.budget_id, b.currency_code, custom_' || v_field_num ||' FROM donation d, budget b WHERE d.budget_id = b.budget_id AND donation_id = :1'
	INTO v_donation_status_sid, v_region_sid, v_budget_id, v_donation_cur, v_cash_value USING in_donation_id;
	
	-- determine currency to compare value against
	SELECT CASE v_donation_cur
	        WHEN 'USD' THEN 'USD'
			WHEN 'SEK' THEN 'USD'
			WHEN 'ZAR' THEN 'USD'
			ELSE 'GBP' 
			END
	  INTO v_compare_cur
	  FROM dual;
	
	/*
	IF v_compare_cur IS NULL THEN
		RAISE_APPLICATION_ERROR(scheme_pkg.ERR_HELPER_PKG, 'Unknown region mapping for region sid: ' || v_region_sid || '. Contact administrator.');
	END IF;
	*/
	
	
	/*
		Entered and approved (less than UK L10k for PSI or less than USD $25k for Inc)		9581252
		Entered (between UK L10k - L100k for PSI or between USD $25k - $180k for Inc)		9581253
		Entered (Over UK L100k for PSI or over USD $180k for Inc)							9581256
	*/
	
	-- convert value
	v_converted_value := currency_pkg.ConvertCurrencyValue(v_act_id, v_budget_id, v_compare_cur, v_cash_value);
	
	-- check for errors
	/*** Entered and approved (less than or equal to UK L10k for PSI or less than or equal to USD $25k for Inc)	9581252 ***/
	IF v_donation_status_sid = 9581252 AND v_compare_cur = 'USD' AND v_converted_value > 25000 THEN
		RAISE_APPLICATION_ERROR(scheme_pkg.ERR_HELPER_PKG, 'Selected status determines the cash value to be less than 25000$. Your value is: '|| v_converted_value ||'. Please correct form.');
	ELSIF v_donation_status_sid = 9581252 AND v_compare_cur != 'USD' AND v_converted_value > 10000 THEN
		RAISE_APPLICATION_ERROR(scheme_pkg.ERR_HELPER_PKG, 'Selected status determines the cash value to be less than 10000GBP. Your value is: '|| v_converted_value ||'. Please correct form.');
	END IF;
	
	/*** Entered (between UK L10k - L100k for PSI or between USD $25k - $180k for Inc)	9581253 ***/
	IF v_donation_status_sid = 9581253 AND v_compare_cur = 'USD' AND (v_converted_value < 25000 OR v_converted_value > 180000) THEN
		RAISE_APPLICATION_ERROR(scheme_pkg.ERR_HELPER_PKG, 'Selected status determines the cash value to be between 25000$ and 180000$. Your value is: '|| v_converted_value ||'. Please correct form.');
	ELSIF v_donation_status_sid = 9581253 AND v_compare_cur != 'USD' AND (v_converted_value < 10000 OR v_converted_value > 100000) THEN
		RAISE_APPLICATION_ERROR(scheme_pkg.ERR_HELPER_PKG, 'Selected status determines the cash value to be between 10k GBP and 100k GBP. Your value is: '|| v_converted_value ||'. Please correct form.');
	END IF;
	
	/*** Entered (Over UK L100k for PSI or over USD $180k for Inc)	9581256 ***/
	IF v_donation_status_sid = 9581256 AND v_compare_cur = 'USD' AND v_converted_value <= 180000 THEN
		RAISE_APPLICATION_ERROR(scheme_pkg.ERR_HELPER_PKG, 'Selected status determines the cash value to be greater than 180000$. Your value is: '|| v_converted_value ||'. Please correct form.');
	ELSIF v_donation_status_sid = 9581256 AND v_compare_cur != 'USD' AND v_converted_value <= 100000 THEN
		RAISE_APPLICATION_ERROR(scheme_pkg.ERR_HELPER_PKG, 'Selected status determines the cash value to be greater than 100000 GBP. Your value is: '|| v_converted_value ||'. Please correct form.');
	END IF;
	
END;

PROCEDURE GetFieldMappings(
	out_cur		OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT * FROM DUAL WHERE 1=0;
END;

END bae_helper_pkg;
/

