CREATE OR REPLACE PACKAGE BODY SUPPLIER.country_pkg
IS

PROCEDURE GetCountryList(
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT country_code, country
		  FROM country
		 	ORDER BY country;
END;

END country_pkg;
/



