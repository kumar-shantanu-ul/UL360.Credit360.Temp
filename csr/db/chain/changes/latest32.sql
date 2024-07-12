define version=32
@update_header

BEGIN
	FOR r IN (
		SELECT app_sid FROM customer_options
	)
	LOOP
	
		-- INSERT default prod codes allowed
		INSERT INTO product_code_type (app_sid, company_sid) 
			SELECT r.app_sid, company_sid FROM company WHERE app_sid = r.app_sid;
			
		-- INSERT the single default component type
		INSERT INTO component_type (component_type_id, app_sid, description) 
			VALUES (1, r.app_sid, 'Default');		
	
	END LOOP;
END;
/

@update_tail
