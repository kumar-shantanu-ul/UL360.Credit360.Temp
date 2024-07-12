CREATE OR REPLACE PACKAGE CSR.currency_pkg AS
   
PROCEDURE GetCurrencies(
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

END;
/
