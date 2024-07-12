CREATE OR REPLACE PACKAGE BODY DONATIONS.currency_pkg
IS

PROCEDURE GetCurrencies(
	in_act_id		IN	security_pkg.T_ACT_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT currency_code, symbol, label
		  FROM currency
		 ORDER BY label;
END;

PROCEDURE GetCurrenciesForCsrApp(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT c.currency_code, c.symbol, c.label, d.exchange_rate
		  FROM currency c, customer_default_exrate d
		 WHERE c.currency_code = d.currency_code
		   AND d.app_sid = in_app_sid
		 ORDER BY label;
END;

PROCEDURE GetCurrency(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_code			IN	currency.currency_code%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT currency_code, symbol, label
		  FROM currency
		 WHERE currency_code = in_code;
END;

PROCEDURE AddCurrency(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_code			IN	currency.currency_code%TYPE,
	in_label		IN	currency.label%TYPE,
	in_symbol		IN	currency.symbol%TYPE
)
AS
BEGIN
	INSERT INTO currency
		(currency_code, symbol, label)
	  VALUES (in_code, in_symbol, in_label);
	 
	INSERT INTO customer_default_exrate
		(app_sid, currency_code, exchange_rate)
	  	(SELECT app_sid, in_code, 1 FROM csr.customer);
END;

PROCEDURE DeleteCurrency(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_code			IN	currency.currency_code%TYPE
)
AS
BEGIN
	DELETE FROM customer_default_exrate
		WHERE currency_code = in_code;
		
	DELETE FROM currency
		WHERE currency_code = in_code;
END;

PROCEDURE SetCustomerExRate(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN 	security_pkg.T_SID_ID,
	in_code			IN	currency.currency_code%TYPE,
	in_exrate		IN	customer_default_exrate.exchange_rate%TYPE
)
AS
BEGIN
	UPDATE customer_default_exrate
	   SET exchange_rate = in_exrate
	 WHERE app_sid = in_app_sid
	   AND currency_code = in_code;
END;

PROCEDURE SetBudgetExRate(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_budget_id	IN	budget.budget_id%TYPE,
	in_exrate		IN	customer_default_exrate.exchange_rate%TYPE
)
AS
BEGIN
	UPDATE budget
	   SET exchange_rate = in_exrate
	 WHERE budget_id = in_budget_id;
END;




FUNCTION GetAppSidFromSchemeSid(
	in_act			IN	security_pkg.T_ACT_ID,
	in_scheme_sid	IN	security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
AS
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT app_sid
	  INTO v_app_sid
	  FROM scheme
	 WHERE scheme_sid = in_scheme_sid;	
	RETURN v_app_sid;
END;

FUNCTION GetDefaultExRate(
	in_act			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_code			IN	currency.currency_code%TYPE
) RETURN customer_default_exrate.exchange_rate%TYPE
AS
	v_exrate	customer_default_exrate.exchange_rate%TYPE;	
BEGIN
	SELECT exchange_rate
	  INTO v_exrate
	  FROM customer_default_exrate
	 WHERE app_sid = in_app_sid
	   AND currency_code = in_code;
	RETURN v_exrate;
END;

FUNCTION GetDefaultExRateForScheme(
	in_act			IN	security_pkg.T_ACT_ID,
	in_scheme_sid	IN	security_pkg.T_SID_ID,
	in_code			IN	currency.currency_code%TYPE
) RETURN customer_default_exrate.exchange_rate%TYPE
AS
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	v_app_sid := GetAppSidFromSchemeSid(in_act, in_scheme_sid);
	RETURN GetDefaultExRate(in_act, v_app_sid, in_code); 
END;

FUNCTION ConvertCurrencyValue(
	in_act			IN	security_pkg.T_ACT_ID,
	in_budget_id	IN	budget.budget_id%TYPE,
	in_to_code		IN	currency.currency_code%TYPE,
	in_from_value	IN	NUMBER
) RETURN NUMBER
AS
	v_scheme_sid	security_pkg.T_SID_ID;
	v_from_code		currency.currency_code%TYPE;
	v_from_rate		NUMBER;
	v_to_rate		NUMBER;
	v_to_value		NUMBER;
BEGIN
	SELECT scheme_sid, currency_code, exchange_rate
	  INTO v_scheme_sid, v_from_code, v_from_rate
	  FROM budget
	 WHERE budget_id = in_budget_id;
	 
	-- Check for same from/to currency code
	IF v_from_code = in_to_code THEN
		RETURN in_from_value;
	END IF;
	
	-- Convert to GBP (all excahange rates are relative to GBP)
	IF v_from_code != 'GBP' THEN
		v_to_value := in_from_value * v_from_rate;
	ELSE
		v_to_value := in_from_value;
	END IF;
	
	-- If converting to GBP no further action is required
	IF in_to_code = 'GBP' THEN
		RETURN v_to_value;
	END IF;
	
	-- Get the conversion rate for the target currency
	v_to_rate := GetDefaultExRateForScheme(in_act, v_scheme_sid, in_to_code);
	v_to_value := v_to_value / v_to_rate;
	
	-- Return in the target currency
	RETURN v_to_value;
	
END;


END currency_pkg;
/
