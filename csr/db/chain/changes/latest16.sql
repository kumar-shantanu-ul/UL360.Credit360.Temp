define version=16
@update_header

@..\chain_pkg

BEGIN
	INSERT INTO capability (capability_name, perm_type) VALUES (chain_pkg.SPECIFY_USER_NAMES, chain_pkg.BOOLEAN_PERMISSION);

	user_pkg.logonadmin;
	
	FOR r IN (
		SELECT app_sid
		  FROM customer_options
	) LOOP
		security_pkg.SetACT(security_pkg.GetAct, r.app_sid);

		company_pkg.VerifySOStructure;
	END LOOP;
END;
/

@..\company_user_pkg
@..\company_user_body

@update_tail
