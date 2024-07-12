CREATE OR REPLACE PACKAGE DONATIONS.currency_pkg
IS

PROCEDURE GetCurrencies(
	in_act_id		IN	security_pkg.T_ACT_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetCurrenciesForCsrApp(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetCurrency(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_code			IN	currency.currency_code%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE AddCurrency(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_code			IN	currency.currency_code%TYPE,
	in_label		IN	currency.label%TYPE,
	in_symbol		IN	currency.symbol%TYPE
);

PROCEDURE DeleteCurrency(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_code			IN	currency.currency_code%TYPE
);

PROCEDURE SetCustomerExRate(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN 	security_pkg.T_SID_ID,
	in_code			IN	currency.currency_code%TYPE,
	in_exrate		IN	customer_default_exrate.exchange_rate%TYPE
);

PROCEDURE SetBudgetExRate(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_budget_id	IN	budget.budget_id%TYPE,
	in_exrate		IN	customer_default_exrate.exchange_rate%TYPE
);


FUNCTION GetAppSidFromSchemeSid(
	in_act			IN	security_pkg.T_ACT_ID,
	in_scheme_sid	IN	security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID;
PRAGMA RESTRICT_REFERENCES(GetAppSidFromSchemeSid, WNDS, WNPS);

FUNCTION GetDefaultExRate(
	in_act			IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	in_code			IN	currency.currency_code%TYPE
) RETURN customer_default_exrate.exchange_rate%TYPE;
PRAGMA RESTRICT_REFERENCES(GetDefaultExRate, WNDS, WNPS);

FUNCTION GetDefaultExRateForScheme(
	in_act			IN	security_pkg.T_ACT_ID,
	in_scheme_sid	IN	security_pkg.T_SID_ID,
	in_code			IN	currency.currency_code%TYPE
) RETURN customer_default_exrate.exchange_rate%TYPE;
PRAGMA RESTRICT_REFERENCES(GetDefaultExRateForScheme, WNDS, WNPS);

FUNCTION ConvertCurrencyValue(
	in_act			IN	security_pkg.T_ACT_ID,
	in_budget_id	IN	budget.budget_id%TYPE,
	in_to_code		IN	currency.currency_code%TYPE,
	in_from_value	IN	NUMBER
) RETURN NUMBER;
PRAGMA RESTRICT_REFERENCES(ConvertCurrencyValue, WNDS, WNPS);

END currency_pkg;
/
