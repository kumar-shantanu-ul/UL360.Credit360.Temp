CREATE OR REPLACE PACKAGE BODY SUPPLIER.currency_pkg
IS

PROCEDURE GetCurrencies (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	
	-- nothing too secure about a list of world currencies is there?
	
	OPEN out_cur FOR
		SELECT currency_code, label
		  FROM currency;		   
END;

END currency_pkg;
/