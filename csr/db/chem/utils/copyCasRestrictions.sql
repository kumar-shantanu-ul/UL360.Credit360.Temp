DECLARE
	v_from			NUMBER;
	v_to			NUMBER;
	v_region_sid	NUMBER;
BEGIN
	SELECT app_sid
	  INTO v_from
	  FROM csr.customer
	 WHERE host = '&&from';
	 
	SELECT app_sid
	  INTO v_to
	  FROM csr.customer
	 WHERE host = '&&to';
	 
	SELECT MIN(region_sid)
	  INTO v_region_sid
	  FROM csr.v$region
	 WHERE description = '&&region'
	   AND app_sid = v_to;
	
	FOR r IN (
		SELECT *
		  FROM chem.cas_restricted
		 WHERE app_sid = v_from
	) LOOP
		BEGIN
			INSERT INTO chem.cas_restricted (app_sid, cas_code, root_region_sid, start_dtm, end_dtm, category, remarks, source, clp_table_3_1, clp_table_3_2)
			VALUES (v_to, r.cas_code, v_region_sid, r.start_dtm, r.end_dtm, r.category, r.remarks, r.source, r.clp_table_3_1, r.clp_table_3_2);
			  
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
	
	security.user_pkg.logonadmin('&&to');
	
	FOR r IN (
		SELECT substance_id
		  FROM chem.substance
	) LOOP
		chem.substance_pkg.INTERNAL_CheckCasRestriction(r.substance_id, v_region_sid);
	END LOOP;
END;
/