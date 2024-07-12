PROMPT Change the user who made a delegation

PROMPT 1) Enter host name
define host = "&&1"

PROMPT 2) Enter user name to switch from
define from_user = "&&2"

PROMPT 3) Enter user name to switch to
define to_user   = "&&3"


DECLARE
    v_from_sid  		security_pkg.T_SID_ID;
    v_to_sid    		security_pkg.T_SID_ID;
    v_act				security_pkg.T_ACT_ID;
BEGIN
	user_pkg.logonadmin('&host');
	v_act := security_pkg.GetACT;

	BEGIN
		SELECT csr_user_sid 
		  INTO v_to_Sid
		  FROM csr_user 
		 WHERE user_name = '&to_user';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'to user "&to_user" not found');
	END;
	
	BEGIN
		SELECT cu.csr_user_sid
		  INTO v_from_sid
		  FROM csr_user cu, superadmin sa
		 WHERE cu.user_name ='&from_user' 
		   AND cu.csr_user_sid = sa.csr_user_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			BEGIN
				SELECT cu.csr_user_sid
				  INTO v_from_sid
				  FROM csr_user cu
				 WHERE cu.user_name ='&from_user';
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'from user "&from_user" not found');
			END;
	END;
	
	IF v_from_sid IS NOT NULL AND v_to_sid IS NOT NULL THEN
		DBMS_OUTPUT.PUT_LINE('updating sheet_history...');
		UPDATE sheet_history
		   SET from_user_sid = v_to_sid
		 WHERE from_user_sid = v_from_sid
		   AND sheet_action_id = 0; -- 'created'
	END IF;
	
    commit;
END;
/
exit