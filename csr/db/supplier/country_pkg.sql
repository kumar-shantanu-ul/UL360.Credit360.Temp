CREATE OR REPLACE PACKAGE SUPPLIER.country_pkg
IS

PROCEDURE GetCountryList(
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

END country_pkg;
/

