CREATE OR REPLACE PACKAGE SUPPLIER.currency_pkg
IS

PROCEDURE GetCurrencies (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);


END currency_pkg;
/