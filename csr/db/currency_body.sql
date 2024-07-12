CREATE OR REPLACE PACKAGE BODY CSR.currency_pkg AS
    
PROCEDURE GetCurrencies(
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN	
	OPEN out_cur FOR
		SELECT sc.currency_code, sc.label
		  FROM std_currency sc
		  JOIN currency c
		    ON sc.currency_code = c.currency_code
		   AND c.app_sid = security_pkg.GetApp;		  
END;	

END;
/
