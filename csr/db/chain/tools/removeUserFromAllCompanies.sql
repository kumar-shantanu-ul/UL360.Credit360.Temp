PROMPT >> host
PROMPT >> user sid

DECLARE
	v_user_sid 		security_pkg.T_SID_ID;
BEGIN

	user_pkg.logonadmin('&&1');
	
	-- confirm that the user exists in this app
	SELECT csr_user_sid
	  INTO v_user_sid
	  FROM csr.csr_user
	 WHERE app_sid = security_pkg.GetApp
	   AND csr_user_sid = &&2;
	
	-- remove the user from all company groups
	FOR r IN (
		SELECT group_sid
		  FROM chain.company_group
	) LOOP
		security.group_pkg.DeleteMember(security_pkg.GetAct, v_user_sid, r.group_sid);
	END LOOP;

END;
/

commit;
exit
