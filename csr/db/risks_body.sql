CREATE OR REPLACE PACKAGE BODY CSR.RISKS_PKG AS

FUNCTION GetOracleUser
RETURN VARCHAR2
AS
	v_oracle_user	RISKS.ORACLE_USER%TYPE;
BEGIN
	SELECT oracle_user
	  INTO v_oracle_user
	  FROM risks
	 WHERE app_sid = security_pkg.getApp;
	
	RETURN v_oracle_user;
END;

END;
/
