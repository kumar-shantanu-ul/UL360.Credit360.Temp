PROMPT >> host
PROMPT >> user sid
PROMPT >> company sid

DECLARE
	v_user_sid 		security_pkg.T_SID_ID;
	v_company_sid	security_pkg.T_SID_ID;
BEGIN

	user_pkg.logonadmin('&&1');
	
	-- confirm that the user exists in this app
	SELECT csr_user_sid
	  INTO v_user_sid
	  FROM csr.csr_user
	 WHERE app_sid = security_pkg.GetApp
	   AND csr_user_sid = &&2;
	
	SELECT company_sid
	  INTO v_company_sid
	  FROM chain.company
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = &&3;
	   
	company_user_pkg.AddUserToCompany(v_company_sid, v_user_sid);
END;
/

commit;
exit
