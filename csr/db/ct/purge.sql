-- This file contains everything to revert a system to normal before running clean 

PROMPT > Dropping old CARBONTRUST user...
PROMPT ====================================================

-- drop the company constraint as it's going to get destroyed anyways
ALTER TABLE CT.COMPANY DROP CONSTRAINT CHAIN_COMPANY_COMPANY;

DECLARE
	v_last_app_sid NUMBER(10) DEFAULT 0;
BEGIN
	user_pkg.logonadmin;
	
	FOR r IN (
		SELECT c.app_sid, c.company_sid, cu.host 
		  FROM ct.company c, csr.customer cu
		 WHERE c.app_sid = cu.app_sid
		 ORDER BY c.app_sid
	) LOOP
		IF v_last_app_sid <> r.app_sid THEN
			v_last_app_sid := r.app_sid;
			user_pkg.logonadmin(r.host);
			UPDATE chain.customer_options SET company_helper_sp = NULL;
		END IF;
		
		security.securableobject_pkg.DeleteSO(security_pkg.GetAct, r.company_sid);
		
	END LOOP;
	
	user_pkg.LogonAdmin;
END;
/

commit;

drop user CT cascade;


exit;
