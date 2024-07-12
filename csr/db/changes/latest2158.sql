-- Please update version.sql too -- this keeps clean builds in sync
define version=2158
@update_header

DECLARE
	v_new_g1_id NUMBER(10);
	v_new_g2_id NUMBER(10);
	v_new_g3_id NUMBER(10);
	v_new_g4_id NUMBER(10);
	v_old_g1_id NUMBER(10);
	v_old_g2_id NUMBER(10);
	v_old_g3_id NUMBER(10);
	v_old_g4_id NUMBER(10);
	v_new_g1_val NUMBER(10);
	v_new_g2_val NUMBER(10);
	v_new_g3_val NUMBER(10);
	v_new_g4_val NUMBER(10);
BEGIN
	SELECT std_factor_id, value
	  INTO v_new_g1_id, v_new_g1_val
	  FROM csr.std_factor
	 WHERE factor_type_id = 8063
	   AND start_dtm = '01-JAN-2011'
	   AND end_dtm = '01-JAN-2012'
	   AND gas_type_id = 1;
	
	SELECT std_factor_id
	  INTO v_old_g1_id
	  FROM csr.std_factor
	 WHERE factor_type_id = 8063
	   AND start_dtm = '01-JAN-1990'
	   AND end_dtm = '01-JAN-2013'
	   AND gas_type_id = 1;
	
	SELECT std_factor_id, value
	  INTO v_new_g2_id, v_new_g2_val
	  FROM csr.std_factor
	 WHERE factor_type_id = 8063
	   AND start_dtm = '01-JAN-2011'
	   AND end_dtm = '01-JAN-2012'
	   AND gas_type_id = 2;
	   
	SELECT std_factor_id
	  INTO v_old_g2_id
	  FROM csr.std_factor
	 WHERE factor_type_id = 8063
	   AND start_dtm = '01-JAN-1990'
	   AND end_dtm = '01-JAN-2013'
	   AND gas_type_id = 2;
	   
	SELECT std_factor_id, value
	  INTO v_new_g3_id, v_new_g3_val
	  FROM csr.std_factor
	 WHERE factor_type_id = 8063
	   AND start_dtm = '01-JAN-2011'
	   AND end_dtm = '01-JAN-2012'
	   AND gas_type_id = 3;
	
	SELECT std_factor_id
	  INTO v_old_g3_id
	  FROM csr.std_factor
	 WHERE factor_type_id = 8063
	   AND start_dtm = '01-JAN-1990'
	   AND end_dtm = '01-JAN-2013'
	   AND gas_type_id = 3;
	
	SELECT std_factor_id, value
	  INTO v_new_g4_id, v_new_g4_val
	  FROM csr.std_factor
	 WHERE factor_type_id = 8063
	   AND start_dtm = '01-JAN-2011'
	   AND end_dtm = '01-JAN-2012'
	   AND gas_type_id = 4;
	   
	SELECT std_factor_id
	  INTO v_old_g4_id
	  FROM csr.std_factor
	 WHERE factor_type_id = 8063
	   AND start_dtm = '01-JAN-1990'
	   AND end_dtm = '01-JAN-2013'
	   AND gas_type_id = 4;
	   
	UPDATE csr.std_factor 
	   SET value = v_new_g1_val
	 WHERE std_factor_id = v_old_g1_id;
	
	UPDATE csr.std_factor 
	   SET value = v_new_g2_val
	 WHERE std_factor_id = v_old_g2_id;
	 
	UPDATE csr.std_factor 
	   SET value = v_new_g3_val
	 WHERE std_factor_id = v_old_g3_id;
	
	UPDATE csr.std_factor 
	   SET value = v_new_g4_val
	 WHERE std_factor_id = v_old_g4_id;
	 
	-- these aren't being used by anyone AFAICT.. should be OK to delete.
	DELETE FROM csr.std_factor 
	 WHERE std_factor_id = v_new_g1_id
	    OR std_factor_id = v_new_g2_id
		OR std_factor_id = v_new_g3_id
		OR std_factor_id = v_new_g4_id;
	
	BEGIN
	FOR r IN (
		SELECT app_sid,host
		  FROM csr.customer
		 WHERE use_carbon_emission = 1
	)
	LOOP
		security.user_pkg.logonadmin(r.host);
		security.security_pkg.SetApp(r.app_sid);
		csr.calc_pkg.AddJobsForFactorType(8063);
	END LOOP;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL; -- "problem" factor not found ...  do nothing.
END;
/

@update_tail