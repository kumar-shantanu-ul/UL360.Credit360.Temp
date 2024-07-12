whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

PROMPT >> Enter a host name
define _x = '&&1'

PROMPT >> Enter the state to set ([0|1][on|off])
define _y = '&&2'

PROMPT >> Enter a company name or sid (or leave empty to set state for all app users)
define _z = '&&3'

set serveroutput on

PROMPT ****************************************
PROMPT >> Setting scheduled alerts state...
DECLARE
	v_app_sid			security_pkg.T_SID_ID;
	v_to_state			number(10) DEFAULT CASE WHEN LOWER('&&2') = 'on' OR '&&2' = '1' THEN 1 WHEN LOWER('&&2') = 'off' OR '&&2' = '0' THEN 0 ELSE -1 END;
	v_company_name		company.name%TYPE DEFAULT '&&3';
	v_company_sid		security_pkg.T_SID_ID;
BEGIN
	
	IF v_to_state = -1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Invalid state - '||'&&2');
	END IF;
	
	IF LOWER(v_company_name) = 'null' THEN
		v_company_name := NULL;
	ELSE
		BEGIN
			v_company_sid := TO_NUMBER(v_company_name);
		EXCEPTION
			WHEN OTHERS THEN
				NULL;
		END;
	END IF;
		
	user_pkg.LogonAdmin;

	SELECT app_sid
	  INTO v_app_sid
	  FROM csr.customer
	 WHERE LOWER(host) = LOWER(TRIM('&&1')); 
	 
	security_pkg.SetApp(v_app_sid);
 
	FOR r IN (
		SELECT *
		  FROM company
		 WHERE app_sid = v_app_sid
		   AND (v_company_name IS NULL OR (v_company_name IS NOT NULL AND (LOWER(name) = LOWER(v_company_name) OR company_sid = v_company_sid)))
	) LOOP
		dbms_output.put_line('Setting receive_scheduled_alerts to '||v_to_state||' for '||r.name||'...');
		
		UPDATE chain_user
		   SET receive_scheduled_alerts = v_to_state
		 WHERE (app_sid, user_sid) IN (
		 			SELECT app_sid, user_sid
		 			  FROM v$company_member
		 			 WHERE app_sid = v_app_sid
		 			   AND company_sid = r.company_sid
		 	   );		
	END LOOP;
	
	-- gets any users that are NOT direct members
	IF v_company_name IS NULL THEN
		UPDATE chain_user
		   SET receive_scheduled_alerts = v_to_state
		 WHERE app_sid = v_app_sid
		   AND (app_sid, user_sid) NOT IN (
					SELECT app_sid, user_sid
					  FROM v$company_member
					 WHERE app_sid = v_app_sid
			   );		
	
	END IF;

END;
/

commit;

exit;
	
