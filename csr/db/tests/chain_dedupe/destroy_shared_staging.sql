BEGIN
	security.user_pkg.logonadmin(:bv_site_name);
	
	-- Unregister table if there is one
	FOR r IN (
		SELECT oracle_table
		  FROM cms.tab 
		 WHERE oracle_schema = 'RAG' 
		   AND oracle_table IN ('COMPANY_STAGING')
	)
	LOOP
		cms.tab_pkg.UnregisterTable(
			in_oracle_schema => 'RAG',
			in_oracle_table	 => r.oracle_table
		);
	END LOOP;

	-- Drop table if there is one
	FOR r IN (SELECT TABLE_NAME FROM ALL_TABLES WHERE OWNER = 'RAG' AND TABLE_NAME IN ('COMPANY_STAGING'))
	LOOP
		EXECUTE IMMEDIATE 'DROP TABLE rag.'||r.TABLE_NAME;
	END LOOP;
END;
/